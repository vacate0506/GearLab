import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import '../../app/app_preferences.dart';
import '../../domain/catalog.dart';
import '../../domain/export_naming.dart';
import '../../domain/models.dart';
import '../../domain/poster_renderer.dart';
import '../../platform/app_platform.dart';
import 'recent_cameras.dart';

class GearLabController extends ChangeNotifier {
  GearLabController(this.platform);

  final AppPlatform platform;

  final List<PhotoItem> photos = <PhotoItem>[];
  int selectedIndex = -1;
  bool syncAll = true;
  bool busy = false;
  String busyMessage = '';
  ExportProgress progress = const ExportProgress();
  StyleSettings currentStyle = StyleSettings();
  String? message;
  String exportFolder = '';

  final ValueNotifier<AppPreferences> preferences =
      ValueNotifier<AppPreferences>(const AppPreferences());

  /// Bodies that finished an export, newest first.
  final ValueNotifier<List<String>> recentCameras =
      ValueNotifier<List<String>>(const <String>[]);

  /// Bodies the user pinned for quick access.
  final ValueNotifier<List<String>> favoriteCameras =
      ValueNotifier<List<String>>(const <String>[]);

  Timer? _saveTimer;
  File? _stateFile;
  Directory? _libraryDir;
  bool _restoring = false;
  bool _writingState = false;
  bool _stateDirty = false;

  CameraTemplate get template => CameraCatalog.find(currentStyle.cameraId);

  PhotoItem? get selectedPhoto =>
      selectedIndex >= 0 && selectedIndex < photos.length
      ? photos[selectedIndex]
      : null;

  int get selectedCount =>
      photos.where((PhotoItem item) => item.exportSelected).length;

  ui.Image? get currentPhotoImage => selectedPhoto?.image;

  Future<void> initialize() async {
    await CameraCatalog.load();
    await _restoreState();
    try {
      exportFolder = await platform.defaultExportFolder();
    } catch (_) {
      exportFolder = await platform.appDataDirectory();
    }
    await platform.listenForDrops(addPaths);
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
      'version': 2,
      'preferences': preferences.value.toJson(),
      'recentCameras': recentCameras.value,
      'favoriteCameras': favoriteCameras.value,
      'syncAll': syncAll,
      'selectedIndex': selectedIndex,
      'currentStyle': _styleToJson(currentStyle),
      'photos': photos
          .map(
            (PhotoItem photo) => <String, dynamic>{
              'path': photo.path,
              'name': photo.name,
              'managed': photo.managed,
              'style': _styleToJson(photo.style),
            },
          )
          .toList(),
    };
  }

  void setThemePreference(GlThemePreference value) {
    preferences.value = preferences.value.copyWith(theme: value);
    notifyListeners();
  }

  void setLocaleCode(String? code) {
    preferences.value = preferences.value.copyWith(
      localeCode: code,
      clearLocale: code == null,
    );
    notifyListeners();
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
    if (map['cameraScale'] is num) {
      style.cameraScale = (map['cameraScale'] as num).toDouble();
    }
    if (map['showTitle'] is bool) style.showTitle = map['showTitle'] as bool;
    if (map['title'] is String) style.title = map['title'] as String;
    if (map['subtitle'] is String) style.subtitle = map['subtitle'] as String;
    if (map['screenFit'] == 'fit') style.screenFit = ScreenFitMode.fit;
    if (map['screenGlare'] is bool) {
      style.screenGlare = map['screenGlare'] as bool;
    }
    if (map['topColor'] is num) {
      style.topColor = Color((map['topColor'] as num).toInt());
    }
    style.clamp();
    return style;
  }

  Future<Directory> _appDataDirectory() async {
    return Directory(await platform.appDataDirectory());
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
      preferences.value = AppPreferences.fromJson(state['preferences']);
      recentCameras.value = _cameraIdsFrom(state['recentCameras'])
          .take(kRecentCameraLimit)
          .toList(growable: false);
      favoriteCameras.value = _cameraIdsFrom(state['favoriteCameras']);
      syncAll = state['syncAll'] is bool ? state['syncAll'] as bool : true;
      currentStyle = _styleFromJson(state['currentStyle']);
      final List<PhotoItem> restored = <PhotoItem>[];
      if (state['photos'] is List) {
        for (final dynamic rawPhoto in state['photos'] as List) {
          if (rawPhoto is! Map) continue;
          final String? path = rawPhoto['path'] as String?;
          if (path == null || !await File(path).exists()) continue;
          try {
            final ui.Image image = await _decode(
              await File(path).readAsBytes(),
            );
            final PhotoItem photo = PhotoItem(
              path: path,
              name: rawPhoto['name'] is String
                  ? rawPhoto['name'] as String
                  : p.basename(path),
              image: image,
              style: _styleFromJson(rawPhoto['style']),
            );
            photo.managed = rawPhoto['managed'] is bool
                ? rawPhoto['managed'] as bool
                : false;
            restored.add(photo);
          } catch (_) {
            // Skip missing or corrupt image files.
          }
        }
      }
      photos
        ..clear()
        ..addAll(restored);
      final int savedIndex = state['selectedIndex'] is num
          ? (state['selectedIndex'] as num).toInt()
          : -1;
      selectedIndex = photos.isEmpty
          ? -1
          : savedIndex.clamp(0, photos.length - 1).toInt();
      if (syncAll) {
        // State written by older builds may contain per-photo styles while
        // "sync all" is enabled. Align them with the global style on load so
        // the library metadata and the stage agree.
        _copyStyleToAll();
      } else if (selectedPhoto != null) {
        currentStyle = selectedPhoto!.style.clone();
      }
    } catch (_) {
      // A corrupt state file should not prevent the app from starting.
    } finally {
      _restoring = false;
    }
  }

  Future<int> pickImages() async {
    final List<String> paths = await platform.pickImagePaths();
    if (paths.isEmpty) return 0;
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
      final String base = safeFilePart(p.basenameWithoutExtension(source));
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
        final List<File> found =
            directory
                .listSync(recursive: true, followLinks: false)
                .whereType<File>()
                .where((File file) => _isSupportedImage(file.path))
                .toList()
              ..sort(
                (File a, File b) =>
                    a.path.toLowerCase().compareTo(b.path.toLowerCase()),
              );
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
    final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(
      bytes,
    );
    final ui.ImageDescriptor descriptor = await ui.ImageDescriptor.encoded(
      buffer,
    );
    final int? targetWidth = descriptor.width > 2600 ? 2600 : null;
    final ui.Codec codec = await descriptor.instantiateCodec(
      targetWidth: targetWidth,
    );
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
    if (!syncAll && selectedPhoto != null) {
      currentStyle.copyFrom(selectedPhoto!.style);
    }
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

  /// Records the bodies that actually made it onto disk, so 最近 only ever
  /// lists templates the user has produced a poster with.
  void _rememberExportedCameras(Iterable<String> ids) {
    final List<String> next = mergeRecentCameras(recentCameras.value, ids);
    if (next.length == recentCameras.value.length &&
        next.every((String id) => recentCameras.value.contains(id))) {
      return;
    }
    recentCameras.value = List<String>.unmodifiable(next);
  }

  void toggleFavoriteCamera(String id) {
    final String resolved = CameraCatalog.find(id).id;
    final List<String> next = favoriteCameras.value.toList();
    if (!next.remove(resolved)) next.insert(0, resolved);
    favoriteCameras.value = List<String>.unmodifiable(next);
    notifyListeners();
  }

  static List<String> _cameraIdsFrom(dynamic raw) {
    if (raw is! List) return const <String>[];
    final List<String> ids = <String>[];
    for (final dynamic value in raw) {
      if (value is! String) continue;
      final bool known = CameraCatalog.all.any(
        (CameraTemplate template) => template.id == value,
      );
      if (known && !ids.contains(value)) ids.add(value);
    }
    return List<String>.unmodifiable(ids);
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
    return platform.defaultExportFolder();
  }

  Future<ExportResult> export(ExportOptions options) async {
    busy = true;
    busyMessage = '';
    progress = const ExportProgress(total: 0);
    notifyListeners();

    final List<_ExportJob> jobs = <_ExportJob>[];
    if (options.scope == ExportScope.current) {
      final PhotoItem? photo = selectedPhoto;
      if (photo != null) {
        jobs.add(_ExportJob(photo, currentStyle.clone()));
      }
    } else {
      for (final PhotoItem photo in photos) {
        if (options.scope == ExportScope.selected && !photo.exportSelected) {
          continue;
        }
        jobs.add(_ExportJob(photo, photo.style.clone()));
      }
    }

    String activeFolder = options.folder;
    String? notice;
    if (!platform.usesGallery && !await platform.canWriteFolder(activeFolder)) {
      final String fallback = await defaultExportFolder();
      if (fallback != activeFolder && await platform.canWriteFolder(fallback)) {
        notice = fallback;
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
        errors: <String>['create folder: $e'],
        notice: notice,
      );
    }
    final List<String> files = <String>[];
    final List<String> errors = <String>[];
    final List<String> exportedCameras = <String>[];
    int gallerySaved = 0;
    for (int i = 0; i < jobs.length; i++) {
      final _ExportJob job = jobs[i];
      progress = ExportProgress(
        done: i,
        total: jobs.length,
        message: '',
        currentFile: job.photo.name,
      );
      busyMessage = progress.message;
      notifyListeners();
      try {
        final CameraTemplate cameraTemplate = CameraCatalog.find(
          job.style.cameraId,
        );
        final PosterPlan plan = PosterPlan.forWidth(
          options.width.toDouble(),
          job.photo.aspect,
        );
        final ui.Image rendered = await renderPoster(
          plan: plan,
          style: job.style,
          template: cameraTemplate,
          camera: CameraCatalog.images[cameraTemplate.id],
          photo: job.photo.image,
        );
        final String extension = options.format == ExportFormat.jpg
            ? 'jpg'
            : 'png';
        final String stem = exportFileStem(
          index: i,
          photoName: job.photo.name,
          cameraModel: cameraTemplate.model,
        );
        File targetFor(String folderPath) {
          return File(
            p.join(
              folderPath,
              uniqueExportFileName(
                stem: stem,
                extension: extension,
                exists: (String name) =>
                    File(p.join(folderPath, name)).existsSync(),
              ),
            ),
          );
        }

        final Uint8List bytes;
        if (options.format == ExportFormat.png) {
          final ByteData? data = await rendered.toByteData(
            format: ui.ImageByteFormat.png,
          );
          if (data == null) throw StateError('PNG encoding failed');
          bytes = data.buffer.asUint8List();
        } else {
          final ByteData? data = await rendered.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          if (data == null) throw StateError('Pixel read failed');
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
          if (platform.usesGallery) rethrow;
          final String fallback = await defaultExportFolder();
          if (fallback == activeFolder || !await platform.canWriteFolder(fallback)) {
            rethrow;
          }
          notice ??= fallback;
          activeFolder = fallback;
          folder = Directory(activeFolder);
          target = targetFor(activeFolder);
          await target.writeAsBytes(bytes, flush: true);
        }
        rendered.dispose();
        files.add(target.path);
        if (platform.usesGallery) {
          final int saved = await platform.saveToGallery(target.path);
          gallerySaved += saved;
          if (saved == 0) {
            errors.add('${job.photo.name}: gallery save failed');
          } else {
            exportedCameras.add(cameraTemplate.id);
          }
        } else {
          exportedCameras.add(cameraTemplate.id);
        }
      } catch (e) {
        errors.add('${job.photo.name}: $e');
      }
    }
    progress = ExportProgress(
      done: jobs.length,
      total: jobs.length,
      message: '',
    );
    _rememberExportedCameras(exportedCameras);
    busy = false;
    busyMessage = '';
    notifyListeners();
    return ExportResult(
      files: files,
      folder: platform.usesGallery ? 'GearLab' : folder.path,
      errors: errors,
      gallerySaved: gallerySaved,
      notice: notice,
    );
  }

  Future<void> shareFiles(List<String> files) async {
    if (!platform.supportsShare || files.isEmpty) return;
    await platform.shareFiles(
      files,
      subject: 'GearLab',
      text: 'GearLab',
    );
  }

  Future<bool> openExportFolder() {
    return platform.openFolder(exportFolder);
  }

  static bool _isSupportedImage(String path) {
    final String ext = p.extension(path).toLowerCase();
    return const <String>{
      '.jpg',
      '.jpeg',
      '.png',
      '.bmp',
      '.tif',
      '.tiff',
    }.contains(ext);
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
