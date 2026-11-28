import 'package:material_ui/material_ui.dart';

import 'tokens.dart';

/// Platform density is separate from colour theme. Windows runs a compact
/// pointer-first layout; Android gets comfortable 40/44dp controls.
@immutable
class GlDensity extends ThemeExtension<GlDensity> {
  const GlDensity({required this.touch});

  final bool touch;

  double get controlHeight => touch ? 40 : GlSize.action;
  double get iconButtonSize => touch ? 44 : 36;
  double get tapTarget => touch ? 48 : 36;
  double get topBarHeight => touch ? GlSize.topBarCompact : GlSize.topBar;
  double get sectionGap => touch ? GlSpace.xl : 20;
  double get pagePadding => touch ? GlSpace.md : 0;
  double get panePadding => touch ? GlSpace.md : GlSpace.lg;

  static GlDensity of(BuildContext context) =>
      Theme.of(context).extension<GlDensity>() ?? const GlDensity(touch: false);

  @override
  GlDensity copyWith({bool? touch}) => GlDensity(touch: touch ?? this.touch);

  @override
  GlDensity lerp(covariant GlDensity? other, double t) =>
      t < 0.5 ? this : (other ?? this);
}

extension GlThemeContext on BuildContext {
  GlPalette get gl => Theme.of(this).extension<GlPalette>()!;
  GlDensity get density => GlDensity.of(this);

  TextStyle glStyle(TextStyle base, {Color? color, FontWeight? weight}) =>
      base.copyWith(color: color ?? gl.ink, fontWeight: weight);

  bool get isCompactLayout => MediaQuery.sizeOf(this).width < 720;

  bool get isTouchPlatform =>
      Theme.of(this).platform == TargetPlatform.android ||
      Theme.of(this).platform == TargetPlatform.iOS;
}

abstract final class GlTheme {
  static ThemeData build({
    required Brightness brightness,
    required bool touch,
  }) {
    final GlPalette p = brightness == Brightness.dark
        ? GlPalette.dark
        : GlPalette.light;
    final GlDensity density = GlDensity(touch: touch);
    final ColorScheme scheme = ColorScheme(
      brightness: brightness,
      primary: p.accent,
      onPrimary: p.onAccent,
      primaryContainer: p.accentSoft,
      onPrimaryContainer: p.accentText,
      secondary: p.ink,
      onSecondary: p.surface,
      secondaryContainer: p.sunken,
      onSecondaryContainer: p.ink,
      tertiary: p.accentText,
      onTertiary: p.surface,
      error: p.danger,
      onError: p.dangerInk,
      surface: p.surface,
      onSurface: p.ink,
      surfaceContainerHighest: p.raised,
      surfaceContainerHigh: p.raised,
      surfaceContainer: p.surface,
      surfaceContainerLow: p.canvas,
      surfaceContainerLowest: p.sunken,
      onSurfaceVariant: p.ink2,
      outline: p.lineStrong,
      outlineVariant: p.line,
      shadow: p.shadow,
      scrim: p.scrim,
      inverseSurface: p.ink,
      onInverseSurface: p.surface,
      inversePrimary: p.accentText,
    );

    final TextTheme textTheme = TextTheme(
      displayLarge: GlType.display.copyWith(color: p.ink),
      displayMedium: GlType.title.copyWith(color: p.ink),
      displaySmall: GlType.heading.copyWith(color: p.ink),
      headlineLarge: GlType.title.copyWith(color: p.ink),
      headlineMedium: GlType.heading.copyWith(color: p.ink),
      headlineSmall: GlType.section.copyWith(color: p.ink),
      titleLarge: GlType.heading.copyWith(color: p.ink),
      titleMedium: GlType.section.copyWith(color: p.ink),
      titleSmall: GlType.bodyStrong.copyWith(color: p.ink),
      bodyLarge: GlType.body.copyWith(color: p.ink),
      bodyMedium: GlType.body.copyWith(color: p.ink2),
      bodySmall: GlType.caption.copyWith(color: p.ink3),
      labelLarge: GlType.button.copyWith(color: p.ink),
      labelMedium: GlType.label.copyWith(color: p.ink2),
      labelSmall: GlType.micro.copyWith(color: p.ink3),
    );

    final ButtonStyle filledButton = ButtonStyle(
      elevation: const WidgetStatePropertyAll<double>(0),
      backgroundColor: WidgetStateProperty.resolveWith<Color?>((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.disabled)) return p.sunken;
        if (states.contains(WidgetState.pressed)) return p.accentPressed;
        if (states.contains(WidgetState.hovered)) return p.accentHover;
        return p.accent;
      }),
      foregroundColor: WidgetStateProperty.resolveWith<Color?>((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.disabled)) return p.ink3;
        return p.onAccent;
      }),
      overlayColor: WidgetStatePropertyAll<Color>(
        p.onAccent.withValues(alpha: 0.08),
      ),
      minimumSize: WidgetStatePropertyAll<Size>(
        Size(0, density.controlHeight),
      ),
      padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
        EdgeInsets.symmetric(horizontal: 14),
      ),
      textStyle: WidgetStatePropertyAll<TextStyle>(GlType.button),
      shape: WidgetStatePropertyAll<OutlinedBorder>(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(GlRadius.sm)),
      ),
      tapTargetSize: density.touch
          ? MaterialTapTargetSize.padded
          : MaterialTapTargetSize.shrinkWrap,
    );

    final ButtonStyle outlinedButton = ButtonStyle(
      elevation: const WidgetStatePropertyAll<double>(0),
      backgroundColor: WidgetStateProperty.resolveWith<Color?>((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.pressed)) return p.sunken;
        if (states.contains(WidgetState.hovered)) return p.raised;
        return Colors.transparent;
      }),
      foregroundColor: WidgetStateProperty.resolveWith<Color?>((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.disabled)) return p.ink3;
        return p.ink;
      }),
      side: WidgetStateProperty.resolveWith<BorderSide?>((
        Set<WidgetState> states,
      ) {
        final Color color = states.contains(WidgetState.disabled)
            ? p.line
            : (states.contains(WidgetState.focused) ? p.focus : p.lineStrong);
        return BorderSide(color: color, width: 1);
      }),
      minimumSize: WidgetStatePropertyAll<Size>(
        Size(0, density.controlHeight),
      ),
      padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
        EdgeInsets.symmetric(horizontal: 14),
      ),
      textStyle: WidgetStatePropertyAll<TextStyle>(GlType.button),
      shape: WidgetStatePropertyAll<OutlinedBorder>(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(GlRadius.sm)),
      ),
      tapTargetSize: density.touch
          ? MaterialTapTargetSize.padded
          : MaterialTapTargetSize.shrinkWrap,
    );

    final ButtonStyle textButton = ButtonStyle(
      elevation: const WidgetStatePropertyAll<double>(0),
      foregroundColor: WidgetStateProperty.resolveWith<Color?>((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.disabled)) return p.ink3;
        return p.ink2;
      }),
      overlayColor: WidgetStatePropertyAll<Color>(
        p.ink.withValues(alpha: 0.06),
      ),
      minimumSize: WidgetStatePropertyAll<Size>(
        Size(0, density.controlHeight),
      ),
      padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
        EdgeInsets.symmetric(horizontal: 10),
      ),
      textStyle: WidgetStatePropertyAll<TextStyle>(GlType.button),
      shape: WidgetStatePropertyAll<OutlinedBorder>(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(GlRadius.sm)),
      ),
      tapTargetSize: density.touch
          ? MaterialTapTargetSize.padded
          : MaterialTapTargetSize.shrinkWrap,
    );

    final ButtonStyle iconButton = ButtonStyle(
      foregroundColor: WidgetStateProperty.resolveWith<Color?>((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.disabled)) return p.ink3;
        if (states.contains(WidgetState.selected)) return p.accent;
        return p.ink2;
      }),
      overlayColor: WidgetStatePropertyAll<Color>(
        p.ink.withValues(alpha: 0.06),
      ),
      backgroundColor: WidgetStateProperty.resolveWith<Color?>((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.pressed)) return p.sunken;
        return Colors.transparent;
      }),
      minimumSize: WidgetStatePropertyAll<Size>(
        Size(density.iconButtonSize, density.iconButtonSize),
      ),
      maximumSize: WidgetStatePropertyAll<Size>(
        Size(density.iconButtonSize, density.iconButtonSize),
      ),
      shape: WidgetStatePropertyAll<OutlinedBorder>(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(GlRadius.md)),
      ),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    OutlineInputBorder border(Color color, {double width = 1}) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(GlRadius.sm),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.canvas,
      canvasColor: p.surface,
      cardColor: p.surface,
      dividerColor: p.line,
      splashColor: p.ink.withValues(alpha: 0.05),
      highlightColor: p.ink.withValues(alpha: 0.04),
      hoverColor: p.ink.withValues(alpha: 0.04),
      focusColor: p.focus.withValues(alpha: 0.18),
      disabledColor: p.ink3,
      visualDensity: density.touch ? VisualDensity.standard : VisualDensity.compact,
      materialTapTargetSize: density.touch
          ? MaterialTapTargetSize.padded
          : MaterialTapTargetSize.shrinkWrap,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[p, density],
      filledButtonTheme: FilledButtonThemeData(style: filledButton),
      outlinedButtonTheme: OutlinedButtonThemeData(style: outlinedButton),
      textButtonTheme: TextButtonThemeData(style: textButton),
      iconButtonTheme: IconButtonThemeData(style: iconButton),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.raised,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        hintStyle: GlType.body.copyWith(color: p.ink3),
        helperStyle: GlType.caption.copyWith(color: p.ink3),
        errorStyle: GlType.caption.copyWith(color: p.danger),
        border: border(p.line),
        enabledBorder: border(p.line),
        focusedBorder: border(p.accent, width: 1.5),
        disabledBorder: border(p.lineSoft),
        errorBorder: border(p.danger),
        focusedErrorBorder: border(p.danger, width: 1.5),
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 2,
        activeTrackColor: p.accent,
        inactiveTrackColor: p.line,
        disabledActiveTrackColor: p.line,
        disabledInactiveTrackColor: p.lineSoft,
        thumbColor: p.accent,
        overlayColor: p.accent.withValues(alpha: 0.12),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
        valueIndicatorColor: p.ink,
        valueIndicatorTextStyle: GlType.numeric.copyWith(color: p.surface),
        showValueIndicator: ShowValueIndicator.onlyForDiscrete,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          return states.contains(WidgetState.selected) ? p.raised : p.ink2;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.disabled)) return p.sunken;
          return states.contains(WidgetState.selected) ? p.accent : p.lineStrong;
        }),
        trackOutlineColor: const WidgetStatePropertyAll<Color>(
          Colors.transparent,
        ),
        overlayColor: WidgetStatePropertyAll<Color>(
          p.accent.withValues(alpha: 0.10),
        ),
      ),
      dividerTheme: DividerThemeData(color: p.line, thickness: 1, space: 1),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll<Color>(p.raised),
          surfaceTintColor: const WidgetStatePropertyAll<Color>(
            Colors.transparent,
          ),
          shape: WidgetStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(GlRadius.lg),
              side: BorderSide(color: p.line),
            ),
          ),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: p.raised,
        surfaceTintColor: Colors.transparent,
        textStyle: GlType.body.copyWith(color: p.ink),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GlRadius.lg),
          side: BorderSide(color: p.line),
        ),
        elevation: 8,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.raised,
        surfaceTintColor: Colors.transparent,
        elevation: 18,
        shadowColor: p.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GlRadius.lg),
          side: BorderSide(color: p.lineSoft),
        ),
        titleTextStyle: GlType.heading.copyWith(color: p.ink),
        contentTextStyle: GlType.body.copyWith(color: p.ink2),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.raised,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: p.raised,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(GlRadius.lg)),
        ),
        dragHandleColor: p.lineStrong,
        showDragHandle: false,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.ink,
        contentTextStyle: GlType.body.copyWith(color: p.surface),
        actionTextColor: p.accentText,
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GlRadius.lg),
        ),
        insetPadding: const EdgeInsets.symmetric(
          horizontal: GlSpace.lg,
          vertical: GlSpace.md,
        ),
      ),
      tooltipTheme: TooltipThemeData(
        textStyle: GlType.caption.copyWith(color: p.surface),
        decoration: BoxDecoration(
          color: p.ink,
          borderRadius: BorderRadius.circular(GlRadius.sm),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: GlSpace.sm,
          vertical: GlSpace.xs,
        ),
        waitDuration: const Duration(milliseconds: 450),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll<Color>(p.lineStrong),
        trackColor: WidgetStatePropertyAll<Color>(
          p.ink.withValues(alpha: 0.04),
        ),
        thickness: const WidgetStatePropertyAll<double>(6),
        radius: const Radius.circular(GlRadius.pill),
        crossAxisMargin: 2,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.accent,
        linearTrackColor: p.line,
        circularTrackColor: p.line,
        linearMinHeight: 4,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      platform: touch ? TargetPlatform.android : TargetPlatform.windows,
    );
  }
}
