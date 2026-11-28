import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app_platform.dart';

/// Windows implementation. Portable builds keep `userdata/` and `exports/`
/// beside the executable; every OS-specific operation is contained here.
class WindowsAppPlatform implements AppPlatform {
  static const MethodChannel _dropChannel = MethodChannel('gearlab/drag_drop');

  bool _dropInstalled = false;

  @override
  bool get isAndroid => false;

  @override
  bool get isWindows => true;

  @override
  bool get usesGallery => false;

  @override
  bool get supportsShare => false;

  @override
  bool get supportsDrop => true;

  @override
  bool get supportsOpenFolder => true;

  @override
  Future<String> appDataDirectory() async {
    final Directory exeDir = File(Platform.resolvedExecutable).parent;
    final Directory portable = Directory(p.join(exeDir.path, 'userdata'));
    if (await canWriteFolder(portable.path)) return portable.path;
    for (final String? root in <String?>[
      Platform.environment['LOCALAPPDATA'],
      Platform.environment['APPDATA'],
    ]) {
      if (root != null) {
        final Directory fallback = Directory(p.join(root, 'GearLab'));
        if (await canWriteFolder(fallback.path)) return fallback.path;
      }
    }
    return Directory.current.path;
  }

  @override
  Future<String> defaultExportFolder() async {
    final Directory exeDir = File(Platform.resolvedExecutable).parent;
    final Directory root = _outermostExportRoot(exeDir);
    final Directory preferred = Directory(p.join(root.path, 'exports'));
    if (await canWriteFolder(preferred.path)) return preferred.path;
    final Directory docs = await getApplicationDocumentsDirectory();
    final Directory fallback = Directory(p.join(docs.path, 'GearLab', 'exports'));
    await fallback.create(recursive: true);
    return fallback.path;
  }

  Directory _outermostExportRoot(Directory exeDir) {
    Directory cursor = exeDir;
    for (int i = 0; i < 8; i++) {
      if (File(p.join(cursor.path, 'pubspec.yaml')).existsSync()) {
        return cursor;
      }
      final Directory parent = cursor.parent;
      if (parent.path == cursor.path) break;
      cursor = parent;
    }
    final String folderName = p.basename(exeDir.path).toLowerCase();
    if (folderName.startsWith('gearlab') && exeDir.parent.path != exeDir.path) {
      return exeDir.parent;
    }
    return exeDir;
  }

  @override
  Future<bool> canWriteFolder(String path) async {
    try {
      final Directory directory = Directory(path);
      await directory.create(recursive: true);
      final File probe = File(
        p.join(
          directory.path,
          '.gearlab-write-${DateTime.now().microsecondsSinceEpoch}',
        ),
      );
      await probe.writeAsString('ok', flush: true);
      await probe.delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<String>> pickImagePaths() async {
    final List<PlatformFile> result = await FilePicker.pickFiles(
      type: FileType.image,
      dialogTitle: 'Import photos',
    );
    return result
        .map((PlatformFile file) => file.path)
        .whereType<String>()
        .toList(growable: false);
  }

  @override
  Future<void> listenForDrops(ValueChanged<List<String>> onPaths) async {
    if (_dropInstalled) return;
    _dropInstalled = true;
    _dropChannel.setMethodCallHandler((MethodCall call) async {
      if (call.method != 'drop') return;
      final Object? arguments = call.arguments;
      if (arguments is! List) return;
      final List<String> paths = arguments.whereType<String>().toList(
        growable: false,
      );
      if (paths.isNotEmpty) onPaths(paths);
    });
  }

  @override
  Future<int> saveToGallery(String path) async => 0;

  @override
  Future<void> shareFiles(
    List<String> paths, {
    required String subject,
    required String text,
  }) async {}

  @override
  Future<bool> openFolder(String path) async {
    try {
      final bool? opened = await _dropChannel.invokeMethod<bool>(
        'openFolder',
        path,
      );
      return opened ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> applyWindowAppearance({required bool dark}) async {
    try {
      await _dropChannel.invokeMethod<void>('setDarkMode', dark);
    } catch (_) {
      // Older runner builds do not implement the channel method yet.
    }
  }

  @override
  Future<void> applySystemBars({
    required Brightness brightness,
    required bool edgeToEdge,
  }) async {}
}
