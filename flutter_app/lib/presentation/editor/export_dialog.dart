import 'package:material_ui/material_ui.dart';

import '../../design/components.dart';
import '../../design/theme.dart';
import '../../design/tokens.dart';
import '../../domain/models.dart';
import '../../l10n/generated/app_localizations.dart';
import 'editor_controller.dart';

class ExportDialog extends StatefulWidget {
  const ExportDialog({super.key, required this.controller, this.initialScope});

  final GearLabController controller;

  /// Preselected scope. Defaults to [ExportScope.all] when photos exist.
  final ExportScope? initialScope;

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  late ExportScope _scope;
  int _width = 2160;
  ExportFormat _format = ExportFormat.jpg;
  double _quality = 100;

  @override
  void initState() {
    super.initState();
    _scope = widget.initialScope ??
        (widget.controller.photos.isEmpty
            ? ExportScope.current
            : ExportScope.all);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final GlPalette p = context.gl;
    final GearLabController controller = widget.controller;
    return GlDialogFrame(
      title: l10n.exportTitle,
      description: controller.platform.usesGallery ? null : l10n.exportSubtitle,
      maxWidth: 540,
      onClose: () => Navigator.pop(context),
      actions: <Widget>[
        GlButton(
          label: l10n.cancel,
          onPressed: () => Navigator.pop(context),
        ),
        GlButton(
          label: l10n.startExport,
          icon: Icons.download_outlined,
          variant: GlButtonVariant.primary,
          onPressed: () {
            Navigator.pop(
              context,
              ExportOptions(
                scope: _scope,
                width: _width,
                format: _format,
                quality: _quality.round(),
                folder: controller.exportFolder,
              ),
            );
          },
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _DialogLabel(l10n.scope),
          Row(
            children: <Widget>[
              Expanded(
                child: GlChoiceTile(
                  label: l10n.scopeCurrent,
                  selected: _scope == ExportScope.current,
                  onTap: () => setState(() => _scope = ExportScope.current),
                ),
              ),
              const SizedBox(width: GlSpace.sm),
              Expanded(
                child: GlChoiceTile(
                  label: controller.photos.length == 1
                      ? l10n.scopeAllOne
                      : l10n.scopeAll(controller.photos.length),
                  selected: _scope == ExportScope.all,
                  onTap: controller.photos.isEmpty
                      ? () {}
                      : () => setState(() => _scope = ExportScope.all),
                ),
              ),
            ],
          ),
          const SizedBox(height: GlSpace.lg),
          _DialogLabel(l10n.outputSize),
          Row(
            children: <Widget>[
              Expanded(
                child: GlChoiceTile(
                  value: '1080',
                  label: l10n.size1080,
                  selected: _width == 1080,
                  onTap: () => setState(() => _width = 1080),
                ),
              ),
              const SizedBox(width: GlSpace.sm),
              Expanded(
                child: GlChoiceTile(
                  value: '1440',
                  label: l10n.size1440,
                  selected: _width == 1440,
                  onTap: () => setState(() => _width = 1440),
                ),
              ),
              const SizedBox(width: GlSpace.sm),
              Expanded(
                child: GlChoiceTile(
                  value: '2160',
                  label: l10n.size2160,
                  selected: _width == 2160,
                  onTap: () => setState(() => _width = 2160),
                ),
              ),
            ],
          ),
          const SizedBox(height: GlSpace.lg),
          _DialogLabel(l10n.format),
          Row(
            children: <Widget>[
              Expanded(
                child: GlChoiceTile(
                  label: _firstLine(l10n.formatJpg),
                  caption: _secondLine(l10n.formatJpg),
                  selected: _format == ExportFormat.jpg,
                  onTap: () => setState(() => _format = ExportFormat.jpg),
                ),
              ),
              const SizedBox(width: GlSpace.sm),
              Expanded(
                child: GlChoiceTile(
                  label: _firstLine(l10n.formatPng),
                  caption: _secondLine(l10n.formatPng),
                  selected: _format == ExportFormat.png,
                  onTap: () => setState(() => _format = ExportFormat.png),
                ),
              ),
            ],
          ),
          if (_format == ExportFormat.jpg) ...<Widget>[
            const SizedBox(height: GlSpace.md),
            GlSliderRow(
              label: l10n.quality,
              value: _quality,
              min: 60,
              max: 100,
              divisions: 40,
              valueLabel: _quality.round().toString(),
              supporting: controller.platform.usesGallery ? null : l10n.qualityHint,
              onChanged: (double value) => setState(() => _quality = value),
            ),
          ],
          const SizedBox(height: GlSpace.lg),
          _DialogLabel(
            controller.platform.usesGallery ? l10n.saveToGallery : l10n.saveTo,
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: GlSpace.md,
              vertical: GlSpace.sm,
            ),
            decoration: BoxDecoration(
              color: p.sunken,
              borderRadius: BorderRadius.circular(GlRadius.sm),
              border: Border.all(color: p.line),
            ),
            child: Row(
              children: <Widget>[
                Icon(Icons.folder_outlined, size: 15, color: p.ink3),
                const SizedBox(width: GlSpace.sm),
                Expanded(
                  child: Text(
                    controller.platform.usesGallery
                        ? l10n.galleryFolder
                        : controller.exportFolder,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GlType.caption.copyWith(color: p.ink2),
                  ),
                ),
              ],
            ),
          ),
          if (controller.platform.usesGallery) ...<Widget>[
            const SizedBox(height: 5),
            Text(
              l10n.galleryNote,
              style: GlType.micro.copyWith(color: p.ink3),
            ),
          ],
        ],
      ),
    );
  }

  static String _firstLine(String value) => value.split('\n').first;

  static String _secondLine(String value) {
    final List<String> lines = value.split('\n');
    return lines.length > 1 ? lines[1] : '';
  }
}

class _DialogLabel extends StatelessWidget {
  const _DialogLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GlType.label.copyWith(color: context.gl.ink2),
      ),
    );
  }
}

class ExportProgressDialog extends StatelessWidget {
  const ExportProgressDialog({super.key, required this.controller});

  final GearLabController controller;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final GlPalette p = context.gl;
    return Dialog(
      child: SizedBox(
        width: 340,
        child: Padding(
          padding: const EdgeInsets.all(GlSpace.xl),
          child: AnimatedBuilder(
            animation: controller,
            builder: (BuildContext context, Widget? child) {
              final ExportProgress progress = controller.progress;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    l10n.exporting,
                    style: GlType.heading.copyWith(color: p.ink),
                  ),
                  const SizedBox(height: GlSpace.lg),
                  LinearProgressIndicator(
                    value: progress.total <= 0 ? null : progress.value,
                    minHeight: 4,
                    backgroundColor: p.sunken,
                    color: p.accent,
                  ),
                  const SizedBox(height: GlSpace.md),
                  Text(
                    progress.currentFile.isEmpty
                        ? (progress.total == 0 ? l10n.preparingExport : '')
                        : progress.currentFile,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GlType.caption.copyWith(color: p.ink2),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      l10n.exportProgress(progress.done, progress.total),
                      style: GlType.numeric.copyWith(color: p.ink3),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class ExportResultDialog extends StatelessWidget {
  const ExportResultDialog({
    super.key,
    required this.result,
    required this.controller,
  });

  final ExportResult result;
  final GearLabController controller;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final GlPalette p = context.gl;
    final bool hasErrors = result.errors.isNotEmpty;
    return GlDialogFrame(
      title: l10n.exportDone,
      description: controller.platform.usesGallery
          ? l10n.galleryFolder
          : result.folder,
      maxWidth: 460,
      onClose: () => Navigator.pop(context),
      actions: <Widget>[
        if (controller.platform.supportsOpenFolder)
          GlButton(
            label: l10n.exportOpenFolder,
            icon: Icons.folder_open_outlined,
            onPressed: () async {
              await controller.openExportFolder();
            },
          ),
        if (controller.platform.supportsShare)
          GlButton(
            label: l10n.exportShare,
            icon: Icons.ios_share,
            onPressed: () async {
              await controller.shareFiles(result.files);
            },
          ),
        GlButton(
          label: l10n.exportClose,
          variant: GlButtonVariant.primary,
          onPressed: () => Navigator.pop(context),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                hasErrors ? Icons.error_outline : Icons.check_circle_outline,
                size: 18,
                color: hasErrors ? p.warning : p.success,
              ),
              const SizedBox(width: GlSpace.sm),
              Expanded(
                child: Text(
                  hasErrors
                      ? l10n.exportFailed(result.errors.length)
                      : result.files.length == 1
                      ? l10n.exportDoneBodyOne
                      : l10n.exportDoneBody(result.files.length),
                  style: GlType.body.copyWith(color: p.ink2),
                ),
              ),
            ],
          ),
          if (controller.platform.usesGallery && result.gallerySaved > 0) ...<Widget>[
            const SizedBox(height: GlSpace.sm),
            Text(
              l10n.exportGallerySaved,
              style: GlType.caption.copyWith(color: p.ink3),
            ),
          ],
          if (result.notice != null) ...<Widget>[
            const SizedBox(height: GlSpace.sm),
            Text(
              l10n.exportFolderFallback(result.notice!),
              style: GlType.caption.copyWith(color: p.warning),
            ),
          ],
          if (hasErrors) ...<Widget>[
            const SizedBox(height: GlSpace.md),
            for (final String error in result.errors.take(4))
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  error,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GlType.caption.copyWith(color: p.danger),
                ),
              ),
            if (result.errors.length > 4)
              Text(
                '…',
                style: GlType.caption.copyWith(color: p.ink3),
              ),
          ],
        ],
      ),
    );
  }
}
