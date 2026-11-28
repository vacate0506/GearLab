import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:gearlab/domain/models.dart';
import 'package:gearlab/domain/poster_renderer.dart';
import 'package:material_ui/material_ui.dart';

Future<ui.Image> _solidImage(int width, int height, Color color) async {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(recorder);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = color,
  );
  final ui.Picture picture = recorder.endRecording();
  final ui.Image image = await picture.toImage(width, height);
  picture.dispose();
  return image;
}

/// FNV-1a 64-bit. Stable across runs and platforms, and captures any change in
/// the rendered RGBA bytes without requiring a binary golden file.
int _fnv1a(List<int> bytes) {
  int hash = 0xcbf29ce484222325;
  for (final int byte in bytes) {
    hash ^= byte;
    hash = (hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
  }
  return hash;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('poster pixels stay byte-identical', (WidgetTester tester) async {
    await tester.runAsync(() async {
      final ui.Image camera = await _solidImage(600, 400, const Color(0xFF9AA0A6));
      final ui.Image photo = await _solidImage(300, 300, const Color(0xFF2F6F9F));
      const CameraTemplate template = CameraTemplate(
        id: 'test-camera',
        asset: 'unused',
        brand: 'TEST',
        model: 'X1',
        displayName: 'Test X1',
        aspect: 1.5,
        screen: Rect.fromLTWH(0.1, 0.2, 0.6, 0.5),
        screenInset: 0.06,
      );
      final StyleSettings style = StyleSettings(
        cameraId: 'test-camera',
        cameraScale: 0.5,
        title: 'Test X1',
        subtitle: 'Shanghai · 2026',
      );
      final ui.Image rendered = await renderPoster(
        plan: PosterPlan.forWidth(1080, 1),
        style: style,
        template: template,
        camera: camera,
        photo: photo,
      );
      final ByteData? data = await rendered.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      expect(data, isNotNull);
      final Uint8List rgba = data!.buffer.asUint8List();
      final int hash = _fnv1a(rgba);
      // ignore: avoid_print
      print('POSTER_GOLDEN_FNV1A=0x${hash.toRadixString(16).padLeft(16, '0')}');
      expect(
        hash,
        0x480345d7b80091b5,
        reason: 'The poster renderer is a business invariant; pixels must not '
            'change during UI-only refactors.',
      );
      rendered.dispose();
      camera.dispose();
      photo.dispose();
    });
  });
}
