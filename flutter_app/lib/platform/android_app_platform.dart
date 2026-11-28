import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'app_platform.dart';

/// Android implementation. Export files are staged in the app cache and then
/// copied into the system gallery album `GearLab`.
class AndroidAppPlatform implements AppPlatform {
  @override
  bool get isAndroid => true;

  @override
  bool get isWindows => false;

  @override
  bool get usesGallery => true;

  @override
  bool get supportsShare => true;

  @override
  bool get supportsDrop => false;

  @override
  bool get supportsOpenFolder => false;

  @override
  Future<String> appDataDirectory() async {
    try {
      final Directory directory = await getApplicationSupportDirectory();
      return directory.path;
    } catch (_) {
      try {
        return (await getApplicationDocumentsDirectory()).path;
      } catch (_) {
        return Directory.current.path;
      }
    }
  }

  @override
  Future<String> defaultExportFolder() async {
    final Directory base = await getTemporaryDirectory();
    final Directory target = Directory(p.join(base.path, 'GearLab'));
    await target.create(recursive: true);
    return target.path;
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
  Future<void> listenForDrops(ValueChanged<List<String>> onPaths) async {}

  @override
  Future<int> saveToGallery(String path) async {
    try {
      await Gal.putImage(path, album: 'GearLab');
      return 1;
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<void> shareFiles(
    List<String> paths, {
    required String subject,
    required String text,
  }) async {
    if (paths.isEmpty) return;
    await SharePlus.instance.share(
      ShareParams(
        files: paths.map((String path) => XFile(path)).toList(growable: false),
        subject: subject,
        text: text,
      ),
    );
  }

  @override
  Future<bool> openFolder(String path) async => false;

  @override
  Future<void> applyWindowAppearance({required bool dark}) async {}

  @override
  Future<void> applySystemBars({
    required Brightness brightness,
    required bool edgeToEdge,
  }) async {
    await SystemChrome.setEnabledSystemUIMode(
      edgeToEdge ? SystemUiMode.edgeToEdge : SystemUiMode.manual,
      overlays: edgeToEdge
          ? const <SystemUiOverlay>[]
          : SystemUiOverlay.values,
    );
    final Brightness iconBrightness = brightness == Brightness.dark
        ? Brightness.light
        : Brightness.dark;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: iconBrightness,
        statusBarBrightness: brightness,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: iconBrightness,
        systemNavigationBarDividerColor: Colors.transparent,
        systemStatusBarContrastEnforced: false,
        systemNavigationBarContrastEnforced: false,
      ),
    );
  }
}
