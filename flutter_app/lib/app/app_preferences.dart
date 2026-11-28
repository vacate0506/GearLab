import 'package:material_ui/material_ui.dart';

enum GlThemePreference { system, light, dark }

@immutable
class AppPreferences {
  const AppPreferences({
    this.theme = GlThemePreference.light,
    this.localeCode = 'zh',
  });

  final GlThemePreference theme;

  /// `null` follows the operating system. Only `zh` and `en` are supported.
  final String? localeCode;

  AppPreferences copyWith({
    GlThemePreference? theme,
    String? localeCode,
    bool clearLocale = false,
  }) {
    return AppPreferences(
      theme: theme ?? this.theme,
      localeCode: clearLocale ? null : (localeCode ?? this.localeCode),
    );
  }

  Brightness resolveBrightness(Brightness systemBrightness) {
    return switch (theme) {
      GlThemePreference.system => systemBrightness,
      GlThemePreference.light => Brightness.light,
      GlThemePreference.dark => Brightness.dark,
    };
  }

  Locale resolveLocale(Locale systemLocale) {
    final String? override = localeCode;
    if (override != null) return Locale(override);
    return systemLocale.languageCode.toLowerCase() == 'zh'
        ? const Locale('zh')
        : const Locale('en');
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'theme': theme.name,
    // 'system' keeps the follow-the-OS choice distinct from an absent key.
    'locale': localeCode ?? 'system',
  };

  static AppPreferences fromJson(dynamic raw) {
    if (raw is! Map) return const AppPreferences();
    final Map<dynamic, dynamic> map = raw;
    final GlThemePreference theme = GlThemePreference.values.firstWhere(
      (GlThemePreference value) => value.name == map['theme'],
      orElse: () => GlThemePreference.light,
    );
    final Object? locale = map['locale'];
    return AppPreferences(
      theme: theme,
      localeCode: locale == 'zh' || locale == 'en' ? locale as String : null,
    );
  }
}
