import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import 'models.dart';

class PosterPlan {
  const PosterPlan({required this.width, required this.height, required this.band});

  final double width;
  final double height;
  final double band;

  static PosterPlan forWidth(double width, double aspect) {
    final int w = math.max(1, width.round());
    final double safeAspect = aspect.isFinite && aspect > 0.01 ? aspect : 1.5;
    final int band = math.max(1, (w / safeAspect).round());
    return PosterPlan(width: w.toDouble(), height: (band * 2).toDouble(), band: band.toDouble());
  }

  double get aspect => width / height;
}

Color inkOn(Color background) =>
    background.computeLuminance() > 0.56 ? const Color(0xFF16181A) : Colors.white;

Color mutedInkOn(Color background) => inkOn(background).withValues(alpha: 0.58);

void paintPoster(
  Canvas canvas,
  PosterPlan plan,
  StyleSettings style,
  CameraTemplate template,
  ui.Image? camera,
  ui.Image? photo,
) {
  final double w = plan.width;
  final double band = plan.band;
  final Color background = style.topColor;
  final Color ink = inkOn(background);

  canvas.drawRect(Rect.fromLTWH(0, 0, w, band), Paint()..color = background);

  final String title = style.resolvedTitle(template);
  final String subtitle = style.subtitle.trim().toUpperCase();
  final double margin = w * 0.026;
  final double titleSize = math.max(8, w * 0.0335);
  final double subtitleSize = math.max(5, w * 0.0118);
  final double gap = w * 0.012;

  final TextPainter titlePainter = TextPainter(
    text: TextSpan(
      text: title,
      style: TextStyle(
        color: ink,
        fontSize: titleSize,
        height: 1.05,
        fontWeight: FontWeight.w700,
        letterSpacing: -w * 0.00035,
      ),
    ),
    maxLines: 1,
    ellipsis: '…',
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: w * 0.92);

  final TextPainter subtitlePainter = TextPainter(
    text: TextSpan(
      text: subtitle,
      style: TextStyle(
        color: mutedInkOn(background),
        fontSize: subtitleSize,
        height: 1.0,
        fontWeight: FontWeight.w500,
        letterSpacing: w * 0.0025,
      ),
    ),
    maxLines: 1,
    ellipsis: '…',
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: w * 0.9);

  final double titleBlock = style.showTitle
      ? titlePainter.height + (subtitle.isEmpty ? 0 : gap * 0.55 + subtitlePainter.height)
      : 0;
  final double topPadding = margin;
  final double titleReserve = style.showTitle ? titleBlock + gap * 1.2 : 0;
  final double maxArtH = math.max(w * 0.12, band - topPadding * 2 - titleReserve);
  double artW = w * style.cameraScale.clamp(0.34, 0.72);
  double artH = artW / math.max(0.1, template.aspect);
  if (artH > maxArtH) {
    artH = maxArtH;
    artW = artH * template.aspect;
  }

  final double contentH = artH + titleReserve;
  final double startY = topPadding + math.max(0, (band - topPadding * 2 - contentH) / 2);
  final Rect artRect = Rect.fromLTWH((w - artW) / 2, startY, artW, artH);

  // Soft studio shadow under the cutout.
  final Rect shadowRect = Rect.fromCenter(
    center: Offset(w / 2, artRect.bottom - artH * 0.035),
    width: artW * 0.72,
    height: math.max(2, artH * 0.085),
  );
  canvas.drawOval(
    shadowRect,
    Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, math.max(1, artW * 0.018)),
  );

  if (camera != null) {
    canvas.drawImageRect(
      camera,
      Rect.fromLTWH(0, 0, camera.width.toDouble(), camera.height.toDouble()),
      artRect,
      Paint()..filterQuality = FilterQuality.high,
    );
  } else {
    final RRect fallback = RRect.fromRectAndRadius(artRect, Radius.circular(artW * 0.02));
    canvas.drawRRect(fallback, Paint()..color = const Color(0xFF24262A));
    final TextPainter fallbackText = TextPainter(
      text: TextSpan(
        text: template.displayName,
        style: TextStyle(color: Colors.white70, fontSize: artW * 0.045),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    fallbackText.paint(
      canvas,
      Offset(artRect.center.dx - fallbackText.width / 2, artRect.center.dy - fallbackText.height / 2),
    );
  }

  final Rect screen = Rect.fromLTWH(
    artRect.left + template.screen.left * artW,
    artRect.top + template.screen.top * artH,
    template.screen.width * artW,
    template.screen.height * artH,
  );
  final RRect screenRRect = RRect.fromRectAndRadius(screen, Radius.circular(artW * 0.006));
  canvas.drawRRect(screenRRect, Paint()..color = Colors.black);
  canvas.save();
  canvas.clipRRect(screenRRect);
  if (photo != null) {
    _drawScreenPhoto(canvas, photo, screen, style.screenFit);
  } else {
    canvas.drawRect(
      screen,
      Paint()
        ..shader = ui.Gradient.linear(screen.topLeft, screen.bottomRight, <Color>[
          const Color(0xFF1F2124),
          const Color(0xFF0C0D0E),
        ]),
    );
  }
  if (style.screenGlare) {
    final Paint glare = Paint()
      ..shader = ui.Gradient.linear(
        screen.topLeft,
        screen.bottomRight,
        <Color>[
          Colors.white.withValues(alpha: 0.20),
          Colors.white.withValues(alpha: 0.015),
          Colors.white.withValues(alpha: 0.08),
        ],
        <double>[0.0, 0.52, 1.0],
      );
    canvas.drawRect(screen, glare);
  }
  canvas.restore();

  if (style.showTitle) {
    final double titleY = artRect.bottom + gap;
    titlePainter.paint(canvas, Offset((w - titlePainter.width) / 2, titleY));
    if (subtitle.isNotEmpty) {
      subtitlePainter.paint(
        canvas,
        Offset((w - subtitlePainter.width) / 2, titleY + titlePainter.height + gap * 0.55),
      );
    }
  }

  if (photo != null) {
    final Rect photoRect = Rect.fromLTWH(0, band, w, band);
    canvas.drawImageRect(
      photo,
      Rect.fromLTWH(0, 0, photo.width.toDouble(), photo.height.toDouble()),
      photoRect,
      Paint()..filterQuality = FilterQuality.high,
    );
  } else {
    canvas.drawRect(
      Rect.fromLTWH(0, band, w, band),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, band),
          Offset(w, plan.height),
          <Color>[const Color(0xFF202327), const Color(0xFF101113)],
        ),
    );
  }
}

void _drawScreenPhoto(Canvas canvas, ui.Image photo, Rect screen, ScreenFitMode mode) {
  final double iw = photo.width.toDouble();
  final double ih = photo.height.toDouble();
  final double scale = mode == ScreenFitMode.fill
      ? math.max(screen.width / iw, screen.height / ih)
      : math.min(screen.width / iw, screen.height / ih);
  final double dw = iw * scale;
  final double dh = ih * scale;
  final Rect dst = Rect.fromLTWH(
    screen.center.dx - dw / 2,
    screen.center.dy - dh / 2,
    dw,
    dh,
  );
  canvas.drawImageRect(
    photo,
    Rect.fromLTWH(0, 0, iw, ih),
    dst,
    Paint()..filterQuality = FilterQuality.high,
  );
}

Future<ui.Image> renderPoster({
  required PosterPlan plan,
  required StyleSettings style,
  required CameraTemplate template,
  required ui.Image? camera,
  required ui.Image? photo,
}) async {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(recorder);
  paintPoster(canvas, plan, style, template, camera, photo);
  final ui.Picture picture = recorder.endRecording();
  final ui.Image image = await picture.toImage(plan.width.round(), plan.height.round());
  picture.dispose();
  return image;
}

class PosterPainter extends CustomPainter {
  PosterPainter({
    required this.style,
    required this.template,
    required this.photo,
    required this.camera,
  });

  final StyleSettings style;
  final CameraTemplate template;
  final ui.Image? photo;
  final ui.Image? camera;

  @override
  void paint(Canvas canvas, Size size) {
    final double aspect = photo == null ? 1.5 : photo!.width / photo!.height;
    final PosterPlan plan = PosterPlan.forWidth(size.width, aspect);
    paintPoster(canvas, plan, style, template, camera, photo);
  }

  @override
  bool shouldRepaint(covariant PosterPainter oldDelegate) => true;
}
