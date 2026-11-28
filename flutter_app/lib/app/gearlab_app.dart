import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../app/app_preferences.dart';
import '../design/theme.dart';
import '../l10n/generated/app_localizations.dart';
import '../platform/app_platform.dart';
import '../presentation/editor/editor_controller.dart';
import '../presentation/editor/editor_page.dart';

class GearLabApp extends StatefulWidget {
  const GearLabApp({super.key, required this.controller});

  final GearLabController controller;

  @override
  State<GearLabApp> createState() => _GearLabAppState();
}

class _GearLabAppState extends State<GearLabApp> with WidgetsBindingObserver {
  AppPreferences _preferences = const AppPreferences();
  bool _lastDark = false;
  bool _chromeApplied = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _preferences = widget.controller.preferences.value;
    widget.controller.preferences.addListener(_syncPreferences);
  }

  @override
  void dispose() {
    widget.controller.preferences.removeListener(_syncPreferences);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _syncPreferences() {
    if (!mounted) return;
    setState(() => _preferences = widget.controller.preferences.value);
  }

  @override
  void didChangePlatformBrightness() => setState(() {});

  @override
  void didChangeAccessibilityFeatures() => setState(() {});

  @override
  void didChangeLocales(List<Locale>? locales) => setState(() {});

  @override
  Widget build(BuildContext context) {
    final WidgetsBinding binding = WidgetsBinding.instance;
    final PlatformDispatcher dispatcher = binding.platformDispatcher;
    final Brightness systemBrightness = dispatcher.platformBrightness;
    final Locale systemLocale = dispatcher.locale;
    final TargetPlatform target = defaultTargetPlatform;
    final bool touch =
        target == TargetPlatform.android || target == TargetPlatform.iOS;
    final Brightness brightness = _preferences.resolveBrightness(systemBrightness);
    final Locale locale = _preferences.resolveLocale(systemLocale);
    final ThemeData theme = GlTheme.build(brightness: brightness, touch: touch);

    _applyChrome(brightness: brightness, touch: touch);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GearLab',
      theme: theme,
      darkTheme: theme,
      themeMode: ThemeMode.system,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      onGenerateTitle: (BuildContext context) =>
          AppLocalizations.of(context).appTitle,
      home: EditorPage(controller: widget.controller),
    );
  }

  void _applyChrome({required Brightness brightness, required bool touch}) {
    final bool dark = brightness == Brightness.dark;
    if (_chromeApplied && _lastDark == dark) {
      return;
    }
    _chromeApplied = true;
    _lastDark = dark;
    final AppPlatform platform = widget.controller.platform;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      platform.applyWindowAppearance(dark: dark);
      platform.applySystemBars(brightness: brightness, edgeToEdge: touch);
      if (touch) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    });
  }
}
