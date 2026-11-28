import 'package:material_ui/material_ui.dart';

/// Everything that differs between the Windows desktop build and the Android
/// build is expressed through this interface. Presentation and domain code
/// never call `Platform`, file_picker, gal or share_plus directly.
abstract interface class AppPlatform {
  bool get isAndroid;
  bool get isWindows;
  bool get usesGallery;
  bool get supportsShare;
  bool get supportsDrop;
  bool get supportsOpenFolder;

  Future<String> appDataDirectory();
  Future<String> defaultExportFolder();
  Future<bool> canWriteFolder(String path);
  Future<List<String>> pickImagePaths();
  Future<void> listenForDrops(ValueChanged<List<String>> onPaths);
  Future<int> saveToGallery(String path);
  Future<void> shareFiles(
    List<String> paths, {
    required String subject,
    required String text,
  });
  Future<bool> openFolder(String path);
  Future<void> applyWindowAppearance({required bool dark});
  Future<void> applySystemBars({
    required Brightness brightness,
    required bool edgeToEdge,
  });
}
