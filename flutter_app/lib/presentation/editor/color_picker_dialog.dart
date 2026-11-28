import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../design/components.dart';
import '../../design/theme.dart';
import '../../design/tokens.dart';
import '../../l10n/generated/app_localizations.dart';

class GlColorPickerDialog extends StatefulWidget {
  const GlColorPickerDialog({super.key, required this.initial});

  final Color initial;

  @override
  State<GlColorPickerDialog> createState() => _GlColorPickerDialogState();
}

class _GlColorPickerDialogState extends State<GlColorPickerDialog> {
  late HSVColor _hsv;
  late double _alpha;
  late final TextEditingController _hexController;

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.initial);
    _alpha = widget.initial.a;
    _hexController = TextEditingController(text: _hex(widget.initial));
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  Color get _color => _hsv.withAlpha(_alpha).toColor();

  void _setColor(Color color, {bool syncHex = true}) {
    setState(() {
      _hsv = HSVColor.fromColor(color);
      _alpha = color.a;
      if (syncHex) _hexController.text = _hex(color);
    });
  }

  void _setHsv(HSVColor value) {
    setState(() {
      _hsv = value;
      _hexController.text = _hex(_color);
    });
  }

  void _setAlpha(double value) {
    setState(() {
      _alpha = value.clamp(0, 1);
      _hexController.text = _hex(_color);
    });
  }

  void _onHexSubmitted(String value) {
    final String raw = value.replaceAll('#', '').trim();
    if (raw.length != 6 && raw.length != 8) return;
    final int? parsed = int.tryParse(raw, radix: 16);
    if (parsed == null) return;
    final int argb = raw.length == 6 ? (0xFF000000 | parsed) : parsed;
    _setColor(Color(argb));
    _hexController.text = _hex(Color(argb));
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final GlPalette p = context.gl;
    return GlDialogFrame(
      title: l10n.backgroundLabel,
      maxWidth: 390,
      onClose: () => Navigator.pop(context),
      actions: <Widget>[
        GlButton(
          label: l10n.cancel,
          onPressed: () => Navigator.pop(context),
        ),
        GlButton(
          label: l10n.done,
          variant: GlButtonVariant.primary,
          onPressed: () => Navigator.pop(context, _color),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            height: 150,
            child: _SaturationValueField(
              hue: _hsv.hue,
              saturation: _hsv.saturation,
              value: _hsv.value,
              onChanged: (double s, double v) {
                _setHsv(
                  HSVColor.fromAHSV(1, _hsv.hue, s.clamp(0, 1), v.clamp(0, 1)),
                );
              },
            ),
          ),
          const SizedBox(height: GlSpace.md),
          _SliderField(
            height: 14,
            painter: _HuePainter(_hsv.hue),
            onChanged: (double value) {
              _setHsv(
                HSVColor.fromAHSV(
                  1,
                  value.clamp(0, 1),
                  _hsv.saturation,
                  _hsv.value,
                ),
              );
            },
          ),
          const SizedBox(height: GlSpace.sm),
          _SliderField(
            height: 14,
            painter: _AlphaPainter(_hsv.withAlpha(1).toColor(), _alpha),
            onChanged: _setAlpha,
          ),
          const SizedBox(height: GlSpace.lg),
          Row(
            children: <Widget>[
              Container(
                width: 34,
                height: 32,
                decoration: BoxDecoration(
                  color: _color,
                  borderRadius: BorderRadius.circular(GlRadius.sm),
                  border: Border.all(color: p.lineStrong),
                ),
              ),
              const SizedBox(width: GlSpace.sm),
              Expanded(
                child: GlTextField(
                  controller: _hexController,
                  hint: '#FFFFFF',
                  textInputAction: TextInputAction.done,
                  onSubmitted: _onHexSubmitted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _hex(Color color) {
    final int argb = color.toARGB32();
    final int alpha = (argb >> 24) & 0xFF;
    final String rgb = (argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0');
    return alpha == 0xFF
        ? '#${rgb.toUpperCase()}'
        : '#${alpha.toRadixString(16).padLeft(2, '0')}${rgb.toUpperCase()}';
  }
}

class _SaturationValueField extends StatelessWidget {
  const _SaturationValueField({
    required this.hue,
    required this.saturation,
    required this.value,
    required this.onChanged,
  });

  final double hue;
  final double saturation;
  final double value;
  final void Function(double saturation, double value) onChanged;

  void _update(Offset position, Size size) {
    onChanged(
      (position.dx / size.width).clamp(0.0, 1.0),
      1 - (position.dy / size.height).clamp(0.0, 1.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final GlPalette p = context.gl;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size size = Size(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          onPanDown: (DragDownDetails details) =>
              _update(details.localPosition, size),
          onPanUpdate: (DragUpdateDetails details) =>
              _update(details.localPosition, size),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(GlRadius.sm),
            child: CustomPaint(
              painter: _SaturationValuePainter(
                hue: hue,
                saturation: saturation,
                value: value,
                border: p.line,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        );
      },
    );
  }
}

class _SliderField extends StatelessWidget {
  const _SliderField({
    required this.height,
    required this.painter,
    required this.onChanged,
  });

  final double height;
  final CustomPainter painter;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final GlPalette p = context.gl;
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return GestureDetector(
            onPanDown: (DragDownDetails details) =>
                onChanged((details.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0)),
            onPanUpdate: (DragUpdateDetails details) =>
                onChanged((details.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(GlRadius.pill),
              child: CustomPaint(
                painter: painter,
                foregroundPainter: null,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: p.line),
                    borderRadius: BorderRadius.circular(GlRadius.pill),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SaturationValuePainter extends CustomPainter {
  const _SaturationValuePainter({
    required this.hue,
    required this.saturation,
    required this.value,
    required this.border,
  });

  final double hue;
  final double saturation;
  final double value;
  final Color border;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Color hueColor = HSVColor.fromAHSV(1, hue, 1, 1).toColor();
    final Paint paint = Paint()
      ..shader = LinearGradient(
        colors: <Color>[Colors.white, hueColor],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
    final Paint black = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[Colors.transparent, Colors.black],
      ).createShader(rect);
    canvas.drawRect(rect, black);
    final Offset handle = Offset(
      saturation.clamp(0, 1) * size.width,
      (1 - value.clamp(0, 1)) * size.height,
    );
    canvas.drawCircle(
      handle,
      7,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white,
    );
    canvas.drawCircle(
      handle,
      8.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.black54,
    );
  }

  @override
  bool shouldRepaint(covariant _SaturationValuePainter oldDelegate) =>
      oldDelegate.hue != hue ||
      oldDelegate.saturation != saturation ||
      oldDelegate.value != value;
}

class _HuePainter extends CustomPainter {
  const _HuePainter(this.hue);

  final double hue;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Paint paint = Paint()
      ..shader = LinearGradient(
        colors: <Color>[
          for (int i = 0; i <= 6; i++)
            HSVColor.fromAHSV(1, i * 60.0, 1, 1).toColor(),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
    _drawHandle(canvas, size, hue);
  }

  @override
  bool shouldRepaint(covariant _HuePainter oldDelegate) => oldDelegate.hue != hue;
}

class _AlphaPainter extends CustomPainter {
  const _AlphaPainter(this.color, this.alpha);

  final Color color;
  final double alpha;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    const double cell = 7;
    final Paint check = Paint()..color = Colors.white;
    canvas.drawRect(rect, check);
    check.color = const Color(0xFFBFBFBF);
    for (double y = 0; y < size.height; y += cell) {
      for (double x = 0; x < size.width; x += cell) {
        final int ix = (x / cell).floor();
        final int iy = (y / cell).floor();
        if ((ix + iy).isEven) {
          canvas.drawRect(Rect.fromLTWH(x, y, cell, cell), check);
        }
      }
    }
    final Paint alphaPaint = Paint()
      ..shader = LinearGradient(
        colors: <Color>[color.withValues(alpha: 0), color],
      ).createShader(rect);
    canvas.drawRect(rect, alphaPaint);
    _drawHandle(canvas, size, alpha);
  }

  @override
  bool shouldRepaint(covariant _AlphaPainter oldDelegate) =>
      oldDelegate.alpha != alpha || oldDelegate.color != color;
}

void _drawHandle(Canvas canvas, Size size, double fraction) {
  final double x = fraction.clamp(0, 1) * size.width;
  final double y = size.height / 2;
  final Paint white = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..color = Colors.white;
  final Paint black = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..color = Colors.black54;
  final double radius = math.max(5, size.height / 2 - 2);
  canvas.drawCircle(Offset(x, y), radius, white);
  canvas.drawCircle(Offset(x, y), radius + 1, black);
}
