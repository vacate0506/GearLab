import 'package:material_ui/material_ui.dart';

import 'app_platform.dart';

/// Deterministic platform double used by widget and controller tests.
class FakeAppPlatform implements AppPlatform {
  FakeAppPlatform({
    this.isAndroid = false,
    this.isWindows = true,
    this.usesGallery = false,
    this.supportShare = false,
    this.supportsDrop = false,
    this.supportsOpenFolder = false,
    this.dataDirectory = '/tmp/gearlab-test',
    this.exportDirectory = '/tmp/gearlab-test/exports',
  });

  @override
  final bool isAndroid;

  @override
  final bool isWindows;

  @override
  final bool usesGallery;

  final bool supportShare;

  @override
  final bool supportsDrop;

  @override
  final bool supportsOpenFolder;

  final String dataDirectory;
  final String exportDirectory;

  final List<int> gallerySaves = <int>[];
  final List<List<String>> sharedFiles = <List<String>>[];
  final List<String> openedFolders = <String>[];
  final List<bool> windowAppearance = <bool>[];

  @override
  bool get supportsShare => supportShare;

  @override
  Future<String> appDataDirectory() async => dataDirectory;

  @override
  Future<String> defaultExportFolder() async => exportDirectory;

  @override
  Future<bool> canWriteFolder(String path) async => true;

  @override
  Future<List<String>> pickImagePaths() async => const <String>[];

  @override
  Future<void> listenForDrops(ValueChanged<List<String>> onPaths) async {}

  @override
  Future<int> saveToGallery(String path) async {
    gallerySaves.add(1);
    return 1;
  }

  @override
  Future<void> shareFiles(
    List<String> paths, {
    required String subject,
    required String text,
  }) async {
    sharedFiles.add(paths);
  }

  @override
  Future<bool> openFolder(String path) async {
    openedFolders.add(path);
    return true;
  }

  @override
  Future<void> applyWindowAppearance({required bool dark}) async {
    windowAppearance.add(dark);
  }

  @override
  Future<void> applySystemBars({
    required Brightness brightness,
    required bool edgeToEdge,
  }) async {}
}
