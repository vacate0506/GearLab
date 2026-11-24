import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';
import 'package:material_ui/material_ui.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'catalog.dart';
import 'models.dart';
import 'renderer.dart';

class GearLabController extends ChangeNotifier {
  GearLabController();

  final List<PhotoItem> photos = <PhotoItem>[];
  int selectedIndex = -1;
  bool syncAll = true;
  bool busy = false;
  String busyMessage = '';
  ExportProgress progress = const ExportProgress();
  StyleSettings currentStyle = StyleSettings();
  String? message;

  Timer? _saveTimer;
  File? _stateFile;
  Directory? _libraryDir;
  bool _restoring = false;
  bool _writingState = false;
  bool _stateDirty = false;

  CameraTemplate get template => CameraCatalog.find(currentStyle.cameraId);

  PhotoItem? get selectedPhoto =>
      selectedIndex >= 0 && selectedIndex < photos.length ? photos[selectedIndex] : null;

  int get selectedCount => photos.where((PhotoItem item) => item.exportSelected).length;

  ui.Image? get currentPhotoImage => selectedPhoto?.image;

  Future<void> initialize() async {
    await CameraCatalog.load();
    await _restoreState();
    notifyListeners();
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
    if (_restoring) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 350), persistNow);
  }

  Future<void> persistNow() async {
    _saveTimer?.cancel();
    if (_stateFile == null) return;
    if (_writingState) {
      _stateDirty = true;
      return;
    }
    _writingState = true;
    try {
      final String json = jsonEncode(_stateToJson());
      await _stateFile!.parent.create(recursive: true);
      final File temp = File('${_stateFile!.path}.tmp');
      await temp.writeAsString(json, flush: true);
      if (await _stateFile!.exists()) {
        await _stateFile!.delete();
      }
      await temp.rename(_stateFile!.path);
    } catch (e) {
      debugPrint('GEARLAB state save error: $e');
    } finally {
      _writingState = false;
      if (_stateDirty) {
        _stateDirty = false;
        unawaited(persistNow());
      }
    }
  }

  void _persistStateSync() {
    if (_stateFile == null) return;
    try {
      _stateFile!.parent.createSync(recursive: true);
      _stateFile!.writeAsStringSync(jsonEncode(_stateToJson()), flush: true);
    } catch (_) {
      // Ignore shutdown persistence failures.
    }
  }

  Map<String, dynamic> _stateToJson() {
    return <String, dynamic>{
      'version': 1,
      'syncAll': syncAll,
      'selectedIndex': selectedIndex,
      'currentStyle': _styleToJson(currentStyle),
      'photos': photos
          .map((PhotoItem photo) => <String, dynamic>{
                'path': photo.path,
                'name': photo.name,
                'managed': photo.managed,
                'style': _styleToJson(photo.style),
              })
          .toList(),
    };
  }

  Map<String, dynamic> _styleToJson(StyleSettings style) {
    return <String, dynamic>{
      'cameraId': style.cameraId,
      'cameraScale': style.cameraScale,
      'showTitle': style.showTitle,
      'title': style.title,
      'subtitle': style.subtitle,
      'screenFit': style.screenFit == ScreenFitMode.fit ? 'fit' : 'fill',
      'screenGlare': style.screenGlare,
      'topColor': style.topColor.toARGB32(),
    };
  }

  StyleSettings _styleFromJson(dynamic raw) {
    final StyleSettings style = StyleSettings();
    if (raw is! Map) return style;
    final Map map = raw;
    if (map['cameraId'] is String) {
      style.cameraId = CameraCatalog.find(map['cameraId'] as String).id;
    }
    if (map['cameraScale'] is num) style.cameraScale = (map['cameraScale'] as num).toDouble();
    if (map['showTitle'] is bool) style.showTitle = map['showTitle'] as bool;
    if (map['title'] is String) style.title = map['title'] as String;
    if (map['subtitle'] is String) style.subtitle = map['subtitle'] as String;
    if (map['screenFit'] == 'fit') style.screenFit = ScreenFitMode.fit;
    if (map['screenGlare'] is bool) style.screenGlare = map['screenGlare'] as bool;
    if (map['topColor'] is num) style.topColor = Color((map['topColor'] as num).toInt());
    style.clamp();
    return style;
  }

  Future<Directory> _appDataDirectory() async {
    if (Platform.isWindows) {
      // Portable builds keep their edit state next to the app. This avoids
      // restricted AppData policies that can block unsigned portable apps.
      final Directory exeDir = File(Platform.resolvedExecutable).parent;
      final Directory portable = Directory(p.join(exeDir.path, 'userdata'));
      if (await _canWriteFolder(portable.path)) return portable;
      for (final String? root in <String?>[
        Platform.environment['LOCALAPPDATA'],
        Platform.environment['APPDATA'],
      ]) {
        if (root != null) {
          final Directory fallback = Directory(p.join(root, 'GearLab'));
          if (await _canWriteFolder(fallback.path)) return fallback;
        }
      }
      return Directory.current;
    }
    try {
      final Directory directory = await getApplicationSupportDirectory();
      debugPrint('GEARLAB support directory: ${directory.path}');
      return directory;
    } catch (e) {
      debugPrint('GEARLAB support directory error: $e');
      try {
        return await getApplicationDocumentsDirectory();
      } catch (_) {
        return Directory.current;
      }
    }
  }

  Future<void> _restoreState() async {
    _restoring = true;
    try {
      final Directory support = await _appDataDirectory();
      _stateFile = File(p.join(support.path, 'state.json'));
      _libraryDir = Directory(p.join(support.path, 'photos'));
      debugPrint('GEARLAB state file: ${_stateFile!.path}');
      if (!await _stateFile!.exists()) return;
      final dynamic decoded = jsonDecode(await _stateFile!.readAsString());
      if (decoded is! Map) return;
      final Map state = decoded;
      syncAll = state['syncAll'] is bool ? state['syncAll'] as bool : true;
      currentStyle = _styleFromJson(state['currentStyle']);
      final List<PhotoItem> restored = <PhotoItem>[];
      if (state['photos'] is List) {
        for (final dynamic rawPhoto in state['photos'] as List) {
          if (rawPhoto is! Map) continue;
          final String? path = rawPhoto['path'] as String?;
          if (path == null || !await File(path).exists()) continue;
          try {
            final ui.Image image = await _decode(await File(path).readAsBytes());
            final PhotoItem photo = PhotoItem(
              path: path,
              name: rawPhoto['name'] is String ? rawPhoto['name'] as String : p.basename(path),
              image: image,
              style: _styleFromJson(rawPhoto['style']),
            );
            photo.managed = rawPhoto['managed'] is bool ? rawPhoto['managed'] as bool : false;
            restored.add(photo);
          } catch (_) {
            // Skip missing or corrupt image files.
          }
        }
      }
      photos
        ..clear()
        ..addAll(restored);
      final int savedIndex =
          state['selectedIndex'] is num ? (state['selectedIndex'] as num).toInt() : -1;
      selectedIndex = photos.isEmpty
          ? -1
          : savedIndex.clamp(0, photos.length - 1).toInt();
      if (!syncAll && selectedPhoto != null) {
        currentStyle = selectedPhoto!.style.clone();
      }
    } catch (_) {
      // A corrupt state file should not prevent the app from starting.
    } finally {
      _restoring = false;
    }
  }

  Future<int> pickImages() async {
    final List<PlatformFile> result = await FilePicker.pickFiles(
      type: FileType.image,
      dialogTitle: '导入照片',
    );
    if (result.isEmpty) return 0;
    final List<String> paths = result
        .map((PlatformFile f) => f.path)
        .whereType<String>()
        .toList(growable: false);
    return addPaths(paths);
  }

  Future<Directory> _libraryDirectory() async {
    final Directory? cached = _libraryDir;
    if (cached != null) {
      await cached.create(recursive: true);
      return cached;
    }
    final Directory support = await _appDataDirectory();
    final Directory directory = Directory(p.join(support.path, 'photos'));
    await directory.create(recursive: true);
    _libraryDir = directory;
    return directory;
  }

  Future<String?> _copyToLibrary(String source) async {
    try {
      final Directory library = await _libraryDirectory();
      final String extension = p.extension(source);
      final String base = _safeName(p.basenameWithoutExtension(source));
      final String name =
          '${DateTime.now().microsecondsSinceEpoch}_${base.length > 48 ? base.substring(0, 48) : base}$extension';
      final File destination = File(p.join(library.path, name));
      await File(source).copy(destination.path);
      return destination.path;
    } catch (_) {
      return null;
    }
  }

  Future<int> addPaths(List<String> paths) async {
    final List<String> expanded = <String>[];
    for (final String path in paths) {
      final Directory directory = Directory(path);
      if (directory.existsSync()) {
        final List<File> found = directory
            .listSync(recursive: true, followLinks: false)
            .whereType<File>()
            .where((File file) => _isSupportedImage(file.path))
            .toList()
          ..sort((File a, File b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()));
        expanded.addAll(found.map((File file) => file.path));
      } else {
        expanded.add(path);
      }
    }
    final List<PhotoItem> added = <PhotoItem>[];
    for (final String path in expanded) {
      try {
        final Uint8List bytes = await File(path).readAsBytes();
        final ui.Image image = await _decode(bytes);
        final String? stored = await _copyToLibrary(path);
        final PhotoItem item = PhotoItem(
          path: stored ?? path,
          name: p.basename(path),
          image: image,
          style: currentStyle.clone(),
        );
        item.managed = stored != null;
        added.add(item);
      } catch (_) {
        // Skip unreadable images; the UI reports the count that worked.
      }
    }
    if (added.isEmpty) return 0;
    photos.addAll(added);
    selectedIndex = photos.length - added.length;
    if (!syncAll) currentStyle.copyFrom(selectedPhoto!.style);
    notifyListeners();
    return added.length;
  }

  Future<ui.Image> _decode(Uint8List bytes) async {
    final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    final ui.ImageDescriptor descriptor = await ui.ImageDescriptor.encoded(buffer);
    final int? targetWidth = descriptor.width > 2600 ? 2600 : null;
    final ui.Codec codec = await descriptor.instantiateCodec(targetWidth: targetWidth);
    final ui.FrameInfo frame = await codec.getNextFrame();
    codec.dispose();
    descriptor.dispose();
    buffer.dispose();
    return frame.image;
  }

  void selectPhoto(int index) {
    if (index < 0 || index >= photos.length) return;
    selectedIndex = index;
    if (!syncAll) currentStyle.copyFrom(photos[index].style);
    notifyListeners();
  }

  void removePhoto(int index) {
    if (index < 0 || index >= photos.length) return;
    final PhotoItem removed = photos.removeAt(index);
    _deleteManagedFile(removed);
    removed.dispose();
    if (photos.isEmpty) {
      selectedIndex = -1;
    } else if (selectedIndex >= photos.length) {
      selectedIndex = photos.length - 1;
    } else if (index < selectedIndex) {
      selectedIndex -= 1;
    }
    if (!syncAll && selectedPhoto != null) currentStyle.copyFrom(selectedPhoto!.style);
    notifyListeners();
  }

  void clearPhotos() {
    for (final PhotoItem photo in photos) {
      _deleteManagedFile(photo);
      photo.dispose();
    }
    photos.clear();
    selectedIndex = -1;
    notifyListeners();
  }

  void _deleteManagedFile(PhotoItem photo) {
    if (!photo.managed) return;
    try {
      final File file = File(photo.path);
      if (file.existsSync()) file.deleteSync();
    } catch (_) {
      // A locked library file can be cleaned up on a later run.
    }
  }

  void toggleSelected(int index) {
    if (index < 0 || index >= photos.length) return;
    photos[index].exportSelected = !photos[index].exportSelected;
    notifyListeners();
  }

  void selectAll(bool value) {
    for (final PhotoItem photo in photos) {
      photo.exportSelected = value;
    }
    notifyListeners();
  }

  void setSyncAll(bool value) {
    if (syncAll == value) return;
    syncAll = value;
    if (value) {
      _copyStyleToAll();
    } else {
      _copyStyleToSelected();
    }
    notifyListeners();
  }

  void setCamera(String id) {
    currentStyle.cameraId = CameraCatalog.find(id).id;
    _commitStyle();
  }

  void setCameraScale(double value) {
    currentStyle.cameraScale = value;
    _commitStyle();
  }

  void setShowTitle(bool value) {
    currentStyle.showTitle = value;
    _commitStyle();
  }

  void setTitle(String value) {
    currentStyle.title = value;
    _commitStyle();
  }

  void setSubtitle(String value) {
    currentStyle.subtitle = value;
    _commitStyle();
  }

  void setTopColor(Color value) {
    currentStyle.topColor = value;
    _commitStyle();
  }

  void setScreenFit(ScreenFitMode value) {
    currentStyle.screenFit = value;
    _commitStyle();
  }

  void setScreenGlare(bool value) {
    currentStyle.screenGlare = value;
    _commitStyle();
  }

  void resetStyle() {
    currentStyle = StyleSettings();
    _commitStyle();
  }

  void _copyStyleToAll() {
    for (final PhotoItem photo in photos) {
      photo.style = currentStyle.clone();
    }
  }

  void _copyStyleToSelected() {
    final PhotoItem? photo = selectedPhoto;
    if (photo != null) photo.style = currentStyle.clone();
  }

  void _commitStyle() {
    currentStyle.clamp();
    if (syncAll) {
      _copyStyleToAll();
    } else {
      _copyStyleToSelected();
    }
    notifyListeners();
  }

  Future<String> defaultExportFolder() async {
    if (Platform.isAndroid) {
      // Files are staged here for sharing, then copied into the system gallery.
      final Directory base = await getTemporaryDirectory();
      final Directory target = Directory(p.join(base.path, 'GearLab'));
      await target.create(recursive: true);
      return target.path;
    }
    final Directory exeDir = File(Platform.resolvedExecutable).parent;
    final Directory root = _outermostExportRoot(exeDir);
    final Directory preferred = Directory(p.join(root.path, 'exports'));
    try {
      await preferred.create(recursive: true);
      final File probe = File(p.join(preferred.path, '.write-test'));
      await probe.writeAsString('ok');
      await probe.delete();
      return preferred.path;
    } catch (_) {
      final Directory docs = await getApplicationDocumentsDirectory();
      final Directory fallback = Directory(p.join(docs.path, 'GearLab', 'exports'));
      await fallback.create(recursive: true);
      return fallback.path;
    }
  }

  Directory _outermostExportRoot(Directory exeDir) {
    // In a development build walk up to the Flutter project root so exports
    // do not land inside build\windows\...\Release.
    Directory cursor = exeDir;
    for (int i = 0; i < 8; i++) {
      if (File(p.join(cursor.path, 'pubspec.yaml')).existsSync()) {
        return cursor;
      }
      final Directory parent = cursor.parent;
      if (parent.path == cursor.path) break;
      cursor = parent;
    }
    // A packaged build lives in a folder such as GearLab-Windows-2.0.3;
    // place exports beside that folder, at the outermost extraction level.
    final String folderName = p.basename(exeDir.path).toLowerCase();
    if (folderName.startsWith('gearlab') && exeDir.parent.path != exeDir.path) {
      return exeDir.parent;
    }
    return exeDir;
  }

  Future<bool> _canWriteFolder(String path) async {
    try {
      final Directory directory = Directory(path);
      await directory.create(recursive: true);
      final File probe = File(p.join(
        directory.path,
        '.gearlab-write-${DateTime.now().microsecondsSinceEpoch}',
      ));
      await probe.writeAsString('ok', flush: true);
      await probe.delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<ExportResult> export(ExportOptions options) async {
    busy = true;
    busyMessage = '准备导出…';
    progress = const ExportProgress(message: '准备导出…');
    notifyListeners();

    final List<_ExportJob> jobs = <_ExportJob>[];
    if (options.scope == ExportScope.current) {
      final PhotoItem? photo = selectedPhoto;
      if (photo != null) {
        jobs.add(_ExportJob(photo, currentStyle.clone()));
      }
    } else {
      for (final PhotoItem photo in photos) {
        if (options.scope == ExportScope.selected && !photo.exportSelected) continue;
        jobs.add(_ExportJob(photo, photo.style.clone()));
      }
    }

    String activeFolder = options.folder;
    String? notice;
    if (!Platform.isAndroid && !await _canWriteFolder(activeFolder)) {
      final String fallback = await defaultExportFolder();
      if (fallback != activeFolder && await _canWriteFolder(fallback)) {
        notice = '所选目录不可写，已改存到 $fallback';
        activeFolder = fallback;
      }
    }
    Directory folder = Directory(activeFolder);
    try {
      await folder.create(recursive: true);
    } catch (e) {
      busy = false;
      busyMessage = '';
      notifyListeners();
      return ExportResult(
        files: const <String>[],
        folder: activeFolder,
        errors: <String>['无法创建导出目录：$e'],
        notice: notice,
      );
    }
    final List<String> files = <String>[];
    final List<String> errors = <String>[];
    int gallerySaved = 0;
    for (int i = 0; i < jobs.length; i++) {
      final _ExportJob job = jobs[i];
      progress = ExportProgress(
        done: i,
        total: jobs.length,
        message: '正在渲染 ${i + 1} / ${jobs.length}',
        currentFile: job.photo.name,
      );
      busyMessage = progress.message;
      notifyListeners();
      try {
        final CameraTemplate cameraTemplate = CameraCatalog.find(job.style.cameraId);
        final PosterPlan plan = PosterPlan.forWidth(options.width.toDouble(), job.photo.aspect);
        final ui.Image rendered = await renderPoster(
          plan: plan,
          style: job.style,
          template: cameraTemplate,
          camera: CameraCatalog.images[cameraTemplate.id],
          photo: job.photo.image,
        );
        final String extension = options.format == ExportFormat.jpg ? 'jpg' : 'png';
        final String base = _safeName(p.basenameWithoutExtension(job.photo.name));
        final String model = _safeName(cameraTemplate.model.replaceAll(' ', ''));
        final String stem =
            'GearLab_${(i + 1).toString().padLeft(2, '0')}_${base}_$model';
        File targetFor(String folderPath) {
          File candidate = File(p.join(folderPath, '$stem.$extension'));
          int duplicate = 2;
          while (candidate.existsSync()) {
            candidate = File(p.join(folderPath, '${stem}_$duplicate.$extension'));
            duplicate += 1;
          }
          return candidate;
        }

        final Uint8List bytes;
        if (options.format == ExportFormat.png) {
          final ByteData? data = await rendered.toByteData(format: ui.ImageByteFormat.png);
          if (data == null) throw StateError('PNG 编码失败');
          bytes = data.buffer.asUint8List();
        } else {
          final ByteData? data = await rendered.toByteData(format: ui.ImageByteFormat.rawRgba);
          if (data == null) throw StateError('像素读取失败');
          final Uint8List rgba = data.buffer.asUint8List();
          bytes = await compute(
            _encodeJpeg,
            _JpegJob(rgba, rendered.width, rendered.height, options.quality),
          );
        }
        File target = targetFor(activeFolder);
        try {
          await target.writeAsBytes(bytes, flush: true);
        } catch (e) {
          if (Platform.isAndroid) rethrow;
          final String fallback = await defaultExportFolder();
          if (fallback == activeFolder || !await _canWriteFolder(fallback)) rethrow;
          notice ??= '所选目录不可写，已改存到 $fallback';
          activeFolder = fallback;
          folder = Directory(activeFolder);
          target = targetFor(activeFolder);
          await target.writeAsBytes(bytes, flush: true);
        }
        rendered.dispose();
        files.add(target.path);
        if (Platform.isAndroid) {
          try {
            await Gal.putImage(target.path, album: 'GearLab');
            gallerySaved += 1;
          } catch (e) {
            errors.add('${job.photo.name} 保存到相册失败: $e');
          }
        }
      } catch (e) {
        errors.add('${job.photo.name}: $e');
      }
    }
    progress = ExportProgress(done: jobs.length, total: jobs.length, message: '完成');
    busy = false;
    busyMessage = '';
    notifyListeners();
    return ExportResult(
      files: files,
      folder: Platform.isAndroid ? '系统相册 · GearLab' : folder.path,
      errors: errors,
      gallerySaved: gallerySaved,
      notice: notice,
    );
  }

  Future<void> shareFiles(List<String> files) async {
    if (!Platform.isAndroid || files.isEmpty) return;
    await SharePlus.instance.share(
      ShareParams(
        files: files.map((String path) => XFile(path)).toList(growable: false),
        subject: 'GearLab 导出',
        text: 'GearLab 相机故事',
      ),
    );
  }

  static bool _isSupportedImage(String path) {
    final String ext = p.extension(path).toLowerCase();
    return const <String>{'.jpg', '.jpeg', '.png', '.bmp', '.tif', '.tiff'}.contains(ext);
  }

  static String _safeName(String value) {
    final String cleaned = value
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned.isEmpty ? 'photo' : cleaned;
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _persistStateSync();
    for (final PhotoItem photo in photos) {
      photo.dispose();
    }
    super.dispose();
  }
}

class _ExportJob {
  _ExportJob(this.photo, this.style);
  final PhotoItem photo;
  final StyleSettings style;
}

class _JpegJob {
  const _JpegJob(this.rgba, this.width, this.height, this.quality);
  final Uint8List rgba;
  final int width;
  final int height;
  final int quality;
}

Uint8List _encodeJpeg(_JpegJob job) {
  final img.Image image = img.Image.fromBytes(
    width: job.width,
    height: job.height,
    bytes: job.rgba.buffer,
    numChannels: 4,
    order: img.ChannelOrder.rgba,
  );
  return Uint8List.fromList(img.encodeJpg(image, quality: job.quality));
}
