import 'package:flutter_test/flutter_test.dart';
import 'package:gearlab/app/app_preferences.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test('defaults to the light theme', () {
    const AppPreferences prefs = AppPreferences();
    expect(prefs.theme, GlThemePreference.light);
    expect(prefs.resolveBrightness(Brightness.dark), Brightness.light);
    expect(prefs.resolveBrightness(Brightness.light), Brightness.light);
  });

  test('an explicit theme overrides the platform', () {
    const AppPreferences dark = AppPreferences(theme: GlThemePreference.dark);
    expect(dark.resolveBrightness(Brightness.light), Brightness.dark);

    const AppPreferences system = AppPreferences(theme: GlThemePreference.system);
    expect(system.resolveBrightness(Brightness.dark), Brightness.dark);
    expect(system.resolveBrightness(Brightness.light), Brightness.light);
  });

  test('defaults to Chinese whatever the system language is', () {
    const AppPreferences prefs = AppPreferences();
    expect(prefs.localeCode, 'zh');
    expect(prefs.resolveLocale(const Locale('en', 'US')), const Locale('zh'));
    expect(prefs.resolveLocale(const Locale('ja')), const Locale('zh'));
  });

  test('the system locale follows the platform language', () {
    const AppPreferences prefs = AppPreferences(localeCode: null);
    expect(prefs.resolveLocale(const Locale('zh', 'CN')), const Locale('zh'));
    expect(prefs.resolveLocale(const Locale('en', 'US')), const Locale('en'));
    expect(prefs.resolveLocale(const Locale('ja')), const Locale('en'));
  });

  test('a manual locale overrides the system language', () {
    const AppPreferences prefs = AppPreferences(localeCode: 'en');
    expect(prefs.resolveLocale(const Locale('zh')), const Locale('en'));
  });

  test('json round-trips and tolerates missing/unknown values', () {
    const AppPreferences prefs = AppPreferences(
      theme: GlThemePreference.dark,
      localeCode: 'en',
    );
    final AppPreferences restored = AppPreferences.fromJson(prefs.toJson());
    expect(restored.theme, prefs.theme);
    expect(restored.localeCode, 'en');

    // Following the OS survives the round trip instead of collapsing to zh.
    const AppPreferences system = AppPreferences(localeCode: null);
    expect(system.toJson()['locale'], 'system');
    expect(AppPreferences.fromJson(system.toJson()).localeCode, isNull);

    final AppPreferences legacy = AppPreferences.fromJson(null);
    expect(legacy.theme, GlThemePreference.light);
    expect(legacy.localeCode, 'zh');

    final AppPreferences unknown = AppPreferences.fromJson(<String, dynamic>{
      'theme': 'sepia',
      'contrast': 'maybe',
      'locale': 'fr',
    });
    expect(unknown.theme, GlThemePreference.light);
    expect(unknown.localeCode, isNull);
  });
}
