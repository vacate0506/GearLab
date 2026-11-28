import 'package:flutter_test/flutter_test.dart';
import 'package:gearlab/design/tokens.dart';
import 'package:material_ui/material_ui.dart';

double _contrast(Color a, Color b) {
  final double l1 = a.computeLuminance();
  final double l2 = b.computeLuminance();
  final double lighter = l1 > l2 ? l1 : l2;
  final double darker = l1 > l2 ? l2 : l1;
  return (lighter + 0.05) / (darker + 0.05);
}

void _expectPalette(String name, GlPalette p) {
  expect(_contrast(p.ink, p.surface), greaterThanOrEqualTo(7.0),
      reason: '$name ink/surface');
  expect(_contrast(p.ink2, p.surface), greaterThanOrEqualTo(4.5),
      reason: '$name ink2/surface');
  expect(_contrast(p.ink3, p.surface), greaterThanOrEqualTo(4.5),
      reason: '$name ink3/surface');
  expect(_contrast(p.accent, p.surface), greaterThanOrEqualTo(3.0),
      reason: '$name accent/surface');
  expect(_contrast(p.onAccent, p.accent), greaterThanOrEqualTo(4.5),
      reason: '$name onAccent/accent');
  expect(_contrast(p.accentText, p.surface), greaterThanOrEqualTo(4.5),
      reason: '$name accentText/surface');
  expect(_contrast(p.focus, p.surface), greaterThanOrEqualTo(3.0),
      reason: '$name focus/surface');
  expect(_contrast(p.lineStrong, p.surface), greaterThanOrEqualTo(3.0),
      reason: '$name lineStrong/surface');
}

void main() {
  test('light and dark palettes meet WCAG AA for text and controls', () {
    _expectPalette('light', GlPalette.light);
    _expectPalette('dark', GlPalette.dark);
  });

  test('palettes interpolate without dropping extension identity', () {
    final GlPalette mid = GlPalette.light.lerp(GlPalette.dark, 0.5);
    expect(mid.brightness, Brightness.dark);
    expect(mid.ink, isNot(GlPalette.light.ink));
  });
}
