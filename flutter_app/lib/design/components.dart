import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import 'theme.dart';
import 'tokens.dart';

/// Button variants used by the application. Primary is the only accent-filled
/// control on a screen; everything else is a hairline or text action.
enum GlButtonVariant { primary, secondary, ghost, danger }

class GlButton extends StatelessWidget {
  const GlButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = GlButtonVariant.secondary,
    this.expand = false,
    this.tooltip,
    this.busy = false,
    this.autofocus = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final GlButtonVariant variant;
  final bool expand;
  final String? tooltip;
  final bool busy;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final GlPalette p = context.gl;
    final Widget iconWidget = busy
        ? SizedBox.square(
            dimension: 14,
            child: CircularProgressIndicator(
              strokeWidth: 1.8,
              color: variant == GlButtonVariant.primary ? p.onAccent : p.ink2,
            ),
          )
        : Icon(icon, size: 16);
    final Widget child = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (icon != null || busy) ...<Widget>[iconWidget, const SizedBox(width: 6)],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GlType.button.copyWith(
              color: variant == GlButtonVariant.primary ? p.onAccent : null,
            ),
          ),
        ),
      ],
    );

    final Widget button;
    switch (variant) {
      case GlButtonVariant.primary:
        button = FilledButton(
          autofocus: autofocus,
          onPressed: busy ? null : onPressed,
          child: child,
        );
      case GlButtonVariant.secondary:
        button = OutlinedButton(
          autofocus: autofocus,
          onPressed: busy ? null : onPressed,
          child: child,
        );
      case GlButtonVariant.ghost:
        button = TextButton(
          autofocus: autofocus,
          onPressed: busy ? null : onPressed,
          child: child,
        );
      case GlButtonVariant.danger:
        button = FilledButton(
          autofocus: autofocus,
          style: FilledButton.styleFrom(
            backgroundColor: p.danger,
            foregroundColor: p.dangerInk,
          ),
          onPressed: busy ? null : onPressed,
          child: child,
        );
    }

    final Widget sized = expand
        ? SizedBox(width: double.infinity, child: button)
        : button;
    return tooltip == null ? sized : Tooltip(message: tooltip!, child: sized);
  }
}

class GlIconButton extends StatelessWidget {
  const GlIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.size = 18,
    this.selected = false,
    this.badge,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final double size;
  final bool selected;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final GlPalette p = context.gl;
    final Widget button = IconButton(
      onPressed: onPressed,
      iconSize: size,
      tooltip: tooltip,
      icon: Icon(icon, color: selected ? p.accent : p.ink2),
    );
    if (badge == null) return Semantics(button: true, label: tooltip, child: button);
    return Semantics(
      button: true,
      label: tooltip,
      child: Badge(
        label: Text(badge!, style: GlType.micro.copyWith(color: p.onAccent)),
        backgroundColor: p.accent,
        child: button,
      ),
    );
  }
}

/// A flat pane separated by a hairline instead of a rounded card.
class GlPane extends StatelessWidget {
  const GlPane({super.key, required this.child, this.header, this.width});

  final Widget child;
  final Widget? header;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final GlPalette p = context.gl;
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(right: BorderSide(color: p.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ?header,
          Expanded(child: child),
        ],
      ),
    );
  }
}

class GlPaneHeader extends StatelessWidget {
  const GlPaneHeader({
    super.key,
    required this.title,
    this.meta,
    this.actions = const <Widget>[],
    this.subtitle,
  });

  final String title;
  final String? meta;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final GlPalette p = context.gl;
    final GlDensity d = context.density;
    return Container(
      height: 44,
      padding: EdgeInsets.symmetric(horizontal: d.panePadding),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: p.line)),
      ),
      child: Row(
        children: <Widget>[
          Container(width: 4, height: 4, color: p.accent),
          const SizedBox(width: 6),
          Text(title, style: GlType.paneTitle.copyWith(color: p.ink)),
          if (subtitle != null) ...<Widget>[
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GlType.caption.copyWith(color: p.ink3),
              ),
            ),
          ],
          const Spacer(),
          if (meta != null)
            Text(meta!, style: GlType.numeric.copyWith(color: p.ink2)),
          ...actions.map(
            (Widget action) => Padding(
              padding: const EdgeInsets.only(left: 4),
              child: action,
            ),
          ),
        ],
      ),
    );
  }
}

class GlSection extends StatelessWidget {
  const GlSection({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.subtitle,
    this.padding,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final GlPalette p = context.gl;
    final GlDensity d = context.density;
    return Container(
      padding:
          padding ??
          EdgeInsets.fromLTRB(d.panePadding, GlSpace.lg, d.panePadding, GlSpace.lg),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: p.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(width: 2, height: 12, color: p.ink2),
              const SizedBox(width: 7),
              Text(title, style: GlType.section.copyWith(color: p.ink)),
              if (subtitle != null) ...<Widget>[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GlType.caption.copyWith(color: p.ink3),
                  ),
                ),
              ],
              const Spacer(),
              ?trailing,
            ],
          ),
          const SizedBox(height: GlSpace.md),
          child,
        ],
      ),
    );
  }
}

class GlField extends StatelessWidget {
  const GlField({
    super.key,
    this.label,
    required this.child,
    this.trailing,
    this.supporting,
  });

  final String? label;
  final Widget child;
  final Widget? trailing;
  final String? supporting;

  @override
  Widget build(BuildContext context) {
    final GlPalette p = context.gl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (label != null) ...<Widget>[
          Row(
            children: <Widget>[
              Text(label!, style: GlType.label.copyWith(color: p.ink2)),
              const Spacer(),
              ?trailing,
            ],
          ),
          const SizedBox(height: 5),
        ],
        child,
        if (supporting != null) ...<Widget>[
          const SizedBox(height: 5),
          Text(supporting!, style: GlType.caption.copyWith(color: p.ink3)),
        ],
      ],
    );
  }
}

class GlTextField extends StatelessWidget {
  const GlTextField({
    super.key,
    required this.controller,
    this.hint,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.maxLength,
    this.textInputAction,
    this.focusNode,
  });

  final TextEditingController controller;
  final String? hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final int? maxLength;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        maxLength: maxLength,
        textInputAction: textInputAction,
        style: GlType.body.copyWith(color: context.gl.ink),
        decoration: InputDecoration(
          hintText: hint,
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        ),
      ),
    );
  }
}

class GlSegmentedOption<T> {
  const GlSegmentedOption({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

class GlSegmentedControl<T> extends StatelessWidget {
  const GlSegmentedControl({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.expand = true,
  });

  final List<GlSegmentedOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final GlPalette p = context.gl;
    final Widget row = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      children: options.map((GlSegmentedOption<T> option) {
        final bool selected = option.value == value;
        final Widget child = InkWell(
          onTap: () => onChanged(option.value),
          borderRadius: BorderRadius.circular(GlRadius.sm),
          child: AnimatedContainer(
            duration: GlDuration.fast,
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: selected ? p.raised : Colors.transparent,
              borderRadius: BorderRadius.circular(GlRadius.sm),
              border: Border.all(
                color: selected ? p.lineStrong : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (option.icon != null) ...<Widget>[
                  Icon(
                    option.icon,
                    size: 14,
                    color: selected ? p.ink : p.ink3,
                  ),
                  const SizedBox(width: 5),
                ],
                Text(
                  option.label,
                  style: GlType.label.copyWith(
                    color: selected ? p.ink : p.ink3,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
        return expand
            ? Expanded(child: Center(child: child))
            : Padding(
                padding: const EdgeInsets.only(right: 2),
                child: child,
              );
      }).toList(growable: false),
    );
    return Container(
      height: 32,
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: p.sunken,
        borderRadius: BorderRadius.circular(GlRadius.md),
        border: Border.all(color: p.line),
      ),
      child: row,
    );
  }
}

class GlSwitchRow extends StatelessWidget {
  const GlSwitchRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.supporting,
    this.enabled = true,
  });

  final String label;
  final String? supporting;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final GlPalette p = context.gl;
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: GlType.label.copyWith(
                  color: enabled ? p.ink2 : p.ink3,
                ),
              ),
              if (supporting != null)
                Text(
                  supporting!,
                  style: GlType.caption.copyWith(color: p.ink3),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 28,
          child: FittedBox(
            fit: BoxFit.contain,
            child: Switch(
              value: value,
              onChanged: enabled ? onChanged : null,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ],
    );
  }
}

class GlSliderRow extends StatelessWidget {
  const GlSliderRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.valueLabel,
    this.supporting,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final int? divisions;
  final String? valueLabel;
  final String? supporting;

  @override
  Widget build(BuildContext context) {
    final GlPalette p = context.gl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(label, style: GlType.label.copyWith(color: p.ink2)),
            const Spacer(),
            Text(
              valueLabel ?? value.toStringAsFixed(2),
              style: GlType.numeric.copyWith(color: p.ink),
            ),
          ],
        ),
        SizedBox(
          height: 26,
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
        if (supporting != null)
          Text(supporting!, style: GlType.caption.copyWith(color: p.ink3)),
      ],
    );
  }
}

class GlColorSwatches extends StatelessWidget {
  const GlColorSwatches({
    super.key,
    required this.colors,
    required this.value,
    required this.onChanged,
    this.size = 22,
  });

  final List<Color> colors;
  final Color value;
  final ValueChanged<Color> onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    final GlPalette p = context.gl;
    return Wrap(
      spacing: GlSpace.sm,
      runSpacing: GlSpace.sm,
      children: colors.map((Color color) {
        final bool selected = color.toARGB32() == value.toARGB32();
        return Semantics(
          button: true,
          selected: selected,
          label: _hex(color),
          child: Tooltip(
            message: _hex(color),
            child: InkResponse(
              onTap: () => onChanged(color),
              radius: size,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? p.ink : p.lineStrong,
                    width: selected ? 2 : 1,
                  ),
                  boxShadow: selected
                      ? <BoxShadow>[
                          BoxShadow(
                            color: p.surface,
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: p.ink,
                            spreadRadius: 3,
                            blurRadius: 0,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ),
        );
      }).toList(growable: false),
    );
  }

  static String _hex(Color color) {
    final int argb = color.toARGB32();
    return '#${argb.toRadixString(16).substring(2).toUpperCase()}';
  }
}

class GlCameraCard extends StatefulWidget {
  const GlCameraCard({
    super.key,
    required this.image,
    required this.brand,
    required this.model,
    required this.selected,
    required this.onTap,
    this.width = 76,
  });

  final ui.Image? image;
  final String brand;
  final String model;
  final bool selected;
  final VoidCallback onTap;
  final double width;

  @override
  State<GlCameraCard> createState() => _GlCameraCardState();
}

class _GlCameraCardState extends State<GlCameraCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final GlPalette p = context.gl;
    final bool active = widget.selected || _hover;
    return Semantics(
      button: true,
      selected: widget.selected,
      label: '${widget.brand} ${widget.model}',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: GlDuration.fast,
            width: widget.width,
            padding: const EdgeInsets.fromLTRB(6, 6, 6, 5),
            decoration: BoxDecoration(
              color: widget.selected ? p.accentSoft : p.raised,
              borderRadius: BorderRadius.circular(GlRadius.sm),
              border: Border.all(
                color: widget.selected
                    ? p.accent
                    : (_hover ? p.lineStrong : p.line),
                width: widget.selected ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  height: 38,
                  child: Center(
                    child: widget.image == null
                        ? Icon(Icons.photo_camera_outlined, size: 20, color: p.ink3)
                        : RawImage(
                            image: widget.image,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.medium,
                          ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.brand.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GlType.micro.copyWith(
                    color: widget.selected ? p.accentText : p.ink3,
                    letterSpacing: 0.6,
                  ),
                ),
                Text(
                  widget.model,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GlType.caption.copyWith(
                    color: active ? p.ink : p.ink2,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GlPhotoRow extends StatefulWidget {
  const GlPhotoRow({
    super.key,
    required this.index,
    required this.name,
    required this.meta,
    required this.thumbnail,
    required this.selected,
    required this.onTap,
    required this.onRemove,
    required this.removeTooltip,
  });

  final int index;
  final String name;
  final String meta;
  final Widget thumbnail;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final String removeTooltip;

  @override
  State<GlPhotoRow> createState() => _GlPhotoRowState();
}

class _GlPhotoRowState extends State<GlPhotoRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final GlPalette p = context.gl;
    final GlDensity d = context.density;
    return Semantics(
      button: true,
      selected: widget.selected,
      label: '${(widget.index + 1).toString().padLeft(2, '0')} ${widget.name}',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            height: GlSize.libraryRow,
            decoration: BoxDecoration(
              color: widget.selected ? p.accentSoft : Colors.transparent,
              border: Border(
                left: BorderSide(
                  color: widget.selected ? p.accent : Colors.transparent,
                  width: 2,
                ),
                bottom: BorderSide(color: p.lineSoft),
              ),
            ),
            padding: EdgeInsets.only(left: d.panePadding - 2, right: GlSpace.sm),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 20,
                  child: Text(
                    (widget.index + 1).toString().padLeft(2, '0'),
                    style: GlType.numeric.copyWith(
                      color: widget.selected ? p.accentText : p.ink3,
                    ),
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(GlRadius.xs),
                  child: SizedBox(width: 46, height: 38, child: widget.thumbnail),
                ),
                const SizedBox(width: GlSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        widget.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GlType.bodyStrong.copyWith(
                          color: widget.selected ? p.ink : p.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GlType.caption.copyWith(color: p.ink3),
                      ),
                    ],
                  ),
                ),
                if (_hover || widget.selected)
                  GlIconButton(
                    icon: Icons.close,
                    tooltip: widget.removeTooltip,
                    size: 14,
                    onPressed: widget.onRemove,
                  )
                else
                  const SizedBox(width: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GlPhotoStripCard extends StatelessWidget {
  const GlPhotoStripCard({
    super.key,
    required this.index,
    required this.thumbnail,
    required this.selected,
    required this.onTap,
    required this.label,
  });

  final int index;
  final Widget thumbnail;
  final bool selected;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    final GlPalette p = context.gl;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 78,
          height: 58,
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? p.accent : p.line,
              width: selected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(GlRadius.xs),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(GlRadius.xs - 1),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                thumbnail,
                Positioned(
                  left: 3,
                  top: 3,
                  child: Container(
                    color: p.canvas.withValues(alpha: 0.82),
                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                    child: Text(
                      (index + 1).toString().padLeft(2, '0'),
                      style: GlType.micro.copyWith(color: p.ink2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GlEmptyState extends StatelessWidget {
  const GlEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final GlPalette p = context.gl;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                border: Border.all(color: p.lineStrong),
                borderRadius: BorderRadius.circular(GlRadius.md),
              ),
              child: Icon(icon, size: 20, color: p.ink3),
            ),
            const SizedBox(height: GlSpace.md),
            Text(title, style: GlType.bodyStrong.copyWith(color: p.ink)),
            const SizedBox(height: GlSpace.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GlType.caption.copyWith(color: p.ink3),
            ),
            if (action != null) ...<Widget>[
              const SizedBox(height: GlSpace.md),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class GlActionBar extends StatelessWidget {
  const GlActionBar({super.key, required this.children, this.padding});

  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final GlPalette p = context.gl;
    return Container(
      padding:
          padding ??
          const EdgeInsets.symmetric(
            horizontal: GlSpace.lg,
            vertical: GlSpace.md,
          ),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.line)),
      ),
      child: Row(children: children),
    );
  }
}

class GlDialogFrame extends StatelessWidget {
  const GlDialogFrame({
    super.key,
    required this.title,
    required this.child,
    this.actions = const <Widget>[],
    this.maxWidth = 520,
    this.onClose,
    this.description,
  });

  final String title;
  final String? description;
  final Widget child;
  final List<Widget> actions;
  final double maxWidth;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final GlPalette p = context.gl;
    final bool compact = context.isCompactLayout;
    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: compact ? GlSpace.md : 40,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: 760),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                GlSpace.xl,
                GlSpace.lg,
                GlSpace.md,
                GlSpace.md,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          style: GlType.heading.copyWith(color: p.ink),
                        ),
                        if (description != null) ...<Widget>[
                          const SizedBox(height: 3),
                          Text(
                            description!,
                            style: GlType.caption.copyWith(color: p.ink3),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (onClose != null)
                    GlIconButton(
                      icon: Icons.close,
                      tooltip: MaterialLocalizations.of(context).closeButtonLabel,
                      onPressed: onClose,
                    ),
                ],
              ),
            ),
            Divider(height: 1, color: p.line),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(GlSpace.xl),
                child: child,
              ),
            ),
            if (actions.isNotEmpty) ...<Widget>[
              Divider(height: 1, color: p.line),
              Padding(
                padding: const EdgeInsets.all(GlSpace.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions
                      .map(
                        (Widget action) => Padding(
                          padding: const EdgeInsets.only(left: GlSpace.sm),
                          child: action,
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class GlCropMarks extends StatelessWidget {
  const GlCropMarks({super.key, required this.color, this.inset = 8});

  final Color color;
  final double inset;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _CropMarksPainter(color: color, inset: inset),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _CropMarksPainter extends CustomPainter {
  const _CropMarksPainter({required this.color, required this.inset});

  final Color color;
  final double inset;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    const double length = 10;
    final double l = inset;
    final double r = size.width - inset;
    final double t = inset;
    final double b = size.height - inset;
    final Path path = Path()
      ..moveTo(l, t + length)
      ..lineTo(l, t)
      ..lineTo(l + length, t)
      ..moveTo(r - length, t)
      ..lineTo(r, t)
      ..lineTo(r, t + length)
      ..moveTo(l, b - length)
      ..lineTo(l, b)
      ..lineTo(l + length, b)
      ..moveTo(r - length, b)
      ..lineTo(r, b)
      ..lineTo(r, b - length);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CropMarksPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.inset != inset;
}

class GlDivider extends StatelessWidget {
  const GlDivider({super.key, this.vertical = false, this.inset = 0});

  final bool vertical;
  final double inset;

  @override
  Widget build(BuildContext context) {
    final Color color = context.gl.line;
    return vertical
        ? VerticalDivider(width: 1, thickness: 1, color: color, indent: inset)
        : Divider(height: 1, thickness: 1, color: color, indent: inset);
  }
}

/// A large selectable option used by export and preference dialogs.
class GlChoiceTile extends StatelessWidget {
  const GlChoiceTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.value,
    this.caption,
    this.icon,
  });

  final String label;
  final String? caption;
  final String? value;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final GlPalette p = context.gl;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GlRadius.sm),
        child: AnimatedContainer(
          duration: GlDuration.fast,
          padding: const EdgeInsets.symmetric(
            horizontal: GlSpace.md,
            vertical: GlSpace.sm,
          ),
          decoration: BoxDecoration(
            color: selected ? p.accentSoft : p.sunken,
            borderRadius: BorderRadius.circular(GlRadius.sm),
            border: Border.all(
              color: selected ? p.accent : p.line,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 16, color: selected ? p.accentText : p.ink3),
                const SizedBox(width: GlSpace.sm),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (value != null)
                      Text(
                        value!,
                        style: GlType.numericLarge.copyWith(
                          color: selected ? p.accentText : p.ink,
                        ),
                      ),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GlType.label.copyWith(
                        color: selected ? p.accentText : p.ink2,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                    if (caption != null)
                      Text(
                        caption!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GlType.micro.copyWith(color: p.ink3),
                      ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check, size: 15, color: p.accentText),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small read-only key/value line used inside inspector sections.
class GlInfoRow extends StatelessWidget {
  const GlInfoRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final GlPalette p = context.gl;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: <Widget>[
          Text(label, style: GlType.label.copyWith(color: p.ink2)),
          const Spacer(),
          Text(value, style: GlType.numeric.copyWith(color: p.ink)),
        ],
      ),
    );
  }
}

