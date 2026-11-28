import 'dart:io';

import 'android_app_platform.dart';
import 'app_platform.dart';
import 'windows_app_platform.dart';

AppPlatform createAppPlatform() {
  if (Platform.isWindows) return WindowsAppPlatform();
  if (Platform.isAndroid) return AndroidAppPlatform();
  // Desktop development on macOS/Linux still uses the Windows-like portable
  // storage behaviour, but no native window channel.
  return WindowsAppPlatform();
}
