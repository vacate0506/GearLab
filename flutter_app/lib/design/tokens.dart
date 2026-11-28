import 'package:material_ui/material_ui.dart';

/// Semantic colour roles used by every GearLab surface and control.
///
/// Ratios in the design specification were checked against [surface]:
/// light ink 15.84, ink2 7.58, ink3 4.70, accent 3.47, accentText 4.77,
/// onAccent 4.79; dark ink 16.64, ink2 11.60, ink3 7.24, accent 6.60,
/// accentText 9.07, onAccent 6.78.
@immutable
class GlPalette extends ThemeExtension<GlPalette> {
  const GlPalette({
    required this.brightness,
    required this.canvas,
    required this.surface,
    required this.raised,
    required this.sunken,
    required this.line,
    required this.lineSoft,
    required this.lineStrong,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.accent,
    required this.accentHover,
    required this.accentPressed,
    required this.accentSoft,
    required this.accentText,
    required this.onAccent,
    required this.focus,
    required this.stage,
    required this.danger,
    required this.dangerInk,
    required this.success,
    required this.warning,
    required this.brand,
    required this.scrim,
    required this.shadow,
  });

  final Brightness brightness;
  final Color canvas;
  final Color surface;
  final Color raised;
  final Color sunken;
  final Color line;
  final Color lineSoft;
  final Color lineStrong;
  final Color ink;
  final Color ink2;
  final Color ink3;
  final Color accent;
  final Color accentHover;
  final Color accentPressed;
  final Color accentSoft;
  final Color accentText;
  final Color onAccent;
  final Color focus;
  final Color stage;
  final Color danger;
  final Color dangerInk;
  final Color success;
  final Color warning;
  final Color brand;
  final Color scrim;
  final Color shadow;

  bool get isLight => brightness == Brightness.light;

  static const GlPalette light = GlPalette(
    brightness: Brightness.light,
    canvas: Color(0xFFEAE5D8),
    surface: Color(0xFFF2EEE4),
    raised: Color(0xFFFBF8F0),
    sunken: Color(0xFFE5DED0),
    line: Color(0xFFD6CFC0),
    lineSoft: Color(0xFFE2DBCC),
    lineStrong: Color(0xFF8B8476),
    ink: Color(0xFF171411),
    ink2: Color(0xFF4F4A42),
    ink3: Color(0xFF6F695E),
    accent: Color(0xFFE24A10),
    accentHover: Color(0xFFD0420C),
    accentPressed: Color(0xFFB93B0A),
    accentSoft: Color(0xFFF9E1D4),
    accentText: Color(0xFFB9400F),
    onAccent: Color(0xFF190B04),
    focus: Color(0xFFB9400F),
    stage: Color(0xFFE4DED0),
    danger: Color(0xFFB3261E),
    dangerInk: Color(0xFFFFFFFF),
    success: Color(0xFF1F7A5A),
    warning: Color(0xFF9A6210),
    brand: Color(0xFFFF5A1F),
    scrim: Color(0x990B0907),
    shadow: Color(0x2E120D08),
  );

  static const GlPalette dark = GlPalette(
    brightness: Brightness.dark,
    canvas: Color(0xFF0B0C0D),
    surface: Color(0xFF101214),
    raised: Color(0xFF191C1F),
    sunken: Color(0xFF070808),
    line: Color(0xFF282C30),
    lineSoft: Color(0xFF1E2226),
    lineStrong: Color(0xFF737A83),
    ink: Color(0xFFF4F1EA),
    ink2: Color(0xFFCFCBC2),
    ink3: Color(0xFF9EA29B),
    accent: Color(0xFFFF6A3D),
    accentHover: Color(0xFFFF815A),
    accentPressed: Color(0xFFE8551F),
    accentSoft: Color(0xFF3A211A),
    accentText: Color(0xFFFF9A78),
    onAccent: Color(0xFF1A0A04),
    focus: Color(0xFFFFB59C),
    stage: Color(0xFF060707),
    danger: Color(0xFFE9A29A),
    dangerInk: Color(0xFF1A0A04),
    success: Color(0xFF7BC8A4),
    warning: Color(0xFFE7BE78),
    brand: Color(0xFFFF6A3D),
    scrim: Color(0xB3000000),
    shadow: Color(0x80000000),
  );

  @override
  GlPalette copyWith({
    Brightness? brightness,
    Color? canvas,
    Color? surface,
    Color? raised,
    Color? sunken,
    Color? line,
    Color? lineSoft,
    Color? lineStrong,
    Color? ink,
    Color? ink2,
    Color? ink3,
    Color? accent,
    Color? accentHover,
    Color? accentPressed,
    Color? accentSoft,
    Color? accentText,
    Color? onAccent,
    Color? focus,
    Color? stage,
    Color? danger,
    Color? dangerInk,
    Color? success,
    Color? warning,
    Color? brand,
    Color? scrim,
    Color? shadow,
  }) {
    return GlPalette(
      brightness: brightness ?? this.brightness,
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      raised: raised ?? this.raised,
      sunken: sunken ?? this.sunken,
      line: line ?? this.line,
      lineSoft: lineSoft ?? this.lineSoft,
      lineStrong: lineStrong ?? this.lineStrong,
      ink: ink ?? this.ink,
      ink2: ink2 ?? this.ink2,
      ink3: ink3 ?? this.ink3,
      accent: accent ?? this.accent,
      accentHover: accentHover ?? this.accentHover,
      accentPressed: accentPressed ?? this.accentPressed,
      accentSoft: accentSoft ?? this.accentSoft,
      accentText: accentText ?? this.accentText,
      onAccent: onAccent ?? this.onAccent,
      focus: focus ?? this.focus,
      stage: stage ?? this.stage,
      danger: danger ?? this.danger,
      dangerInk: dangerInk ?? this.dangerInk,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      brand: brand ?? this.brand,
      scrim: scrim ?? this.scrim,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  GlPalette lerp(covariant GlPalette? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return GlPalette(
      brightness: t < 0.5 ? brightness : other.brightness,
      canvas: mix(canvas, other.canvas),
      surface: mix(surface, other.surface),
      raised: mix(raised, other.raised),
      sunken: mix(sunken, other.sunken),
      line: mix(line, other.line),
      lineSoft: mix(lineSoft, other.lineSoft),
      lineStrong: mix(lineStrong, other.lineStrong),
      ink: mix(ink, other.ink),
      ink2: mix(ink2, other.ink2),
      ink3: mix(ink3, other.ink3),
      accent: mix(accent, other.accent),
      accentHover: mix(accentHover, other.accentHover),
      accentPressed: mix(accentPressed, other.accentPressed),
      accentSoft: mix(accentSoft, other.accentSoft),
      accentText: mix(accentText, other.accentText),
      onAccent: mix(onAccent, other.onAccent),
      focus: mix(focus, other.focus),
      stage: mix(stage, other.stage),
      danger: mix(danger, other.danger),
      dangerInk: mix(dangerInk, other.dangerInk),
      success: mix(success, other.success),
      warning: mix(warning, other.warning),
      brand: mix(brand, other.brand),
      scrim: mix(scrim, other.scrim),
      shadow: mix(shadow, other.shadow),
    );
  }
}

/// Product type scale. Colours are applied at the call site so the same scale
/// works for every theme and for poster-independent surfaces.
abstract final class GlType {
  static const FontFeature tabular = FontFeature.tabularFigures();

  static const TextStyle display = TextStyle(
    fontSize: 28,
    height: 1.22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
  );
  static const TextStyle title = TextStyle(
    fontSize: 22,
    height: 1.28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );
  static const TextStyle heading = TextStyle(
    fontSize: 17,
    height: 1.41,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
  );
  /// Pane titles are the only level above the section rhythm on the editor
  /// screen; they need more weight than [section] to structure three columns.
  static const TextStyle paneTitle = TextStyle(
    fontSize: 15,
    height: 1.33,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.1,
  );
  static const TextStyle section = TextStyle(
    fontSize: 13,
    height: 1.38,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );
  static const TextStyle body = TextStyle(fontSize: 13, height: 1.54);
  static const TextStyle bodyStrong = TextStyle(
    fontSize: 13,
    height: 1.54,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle label = TextStyle(
    fontSize: 12,
    height: 1.33,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle caption = TextStyle(fontSize: 12, height: 1.45);
  static const TextStyle micro = TextStyle(
    fontSize: 10,
    height: 1.4,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
  );
  static const TextStyle button = TextStyle(
    fontSize: 13,
    height: 1.38,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle numeric = TextStyle(
    fontSize: 12,
    height: 1.33,
    fontWeight: FontWeight.w600,
    fontFeatures: <FontFeature>[tabular],
  );
  static const TextStyle numericLarge = TextStyle(
    fontSize: 15,
    height: 1.3,
    fontWeight: FontWeight.w700,
    fontFeatures: <FontFeature>[tabular],
  );
  static const TextStyle wordmark = TextStyle(
    fontSize: 15,
    height: 1.3,
    fontWeight: FontWeight.w700,
    letterSpacing: 2.4,
  );
}

/// 4px spacing scale. Values are logical pixels.
abstract final class GlSpace {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

abstract final class GlRadius {
  static const double xs = 2;
  static const double sm = 4;
  static const double md = 6;
  static const double lg = 8;
  static const double xl = 12;
  static const double pill = 999;
}

abstract final class GlDuration {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 180);
  static const Duration slow = Duration(milliseconds: 240);
}

abstract final class GlSize {
  static const double topBar = 56;
  static const double topBarCompact = 52;
  static const double action = 32;
  static const double actionCompact = 30;
  static const double field = 32;
  static const double icon = 18;
  static const double library = 276;
  static const double libraryLarge = 288;
  static const double inspector = 352;
  static const double inspectorLarge = 368;
  static const double inspectorMedium = 320;
  static const double mediumStrip = 118;
  static const double cameraCard = 74;
  static const double cameraStrip = 104;
  static const double libraryRow = 64;
  static const double photoStripCard = 64;
  static const double posterMin = 220;
}

abstract final class GlBackdrops {
  static const List<Color> all = <Color>[
    Color(0xFFFFFFFF),
    Color(0xFFF3EEE4),
    Color(0xFFEDE4D8),
    Color(0xFFE2E8EE),
    Color(0xFFE3E8DF),
    Color(0xFFF1E6E3),
    Color(0xFFD8D2C8),
    Color(0xFF393B3D),
  ];
}
