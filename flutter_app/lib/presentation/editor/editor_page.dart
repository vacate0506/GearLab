import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/app_preferences.dart';
import '../../design/components.dart';
import '../../design/theme.dart';
import '../../design/tokens.dart';
import '../../domain/catalog.dart';
import '../../domain/models.dart';
import '../../domain/poster_renderer.dart';
import '../../l10n/generated/app_localizations.dart';
import 'camera_panel.dart';
import 'color_picker_dialog.dart';
import 'editor_controller.dart';
import 'export_dialog.dart';
import 'preferences_dialog.dart';

class EditorPage extends StatefulWidget {
  const EditorPage({super.key, required this.controller});

  final GearLabController controller;

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _subtitleController;
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _subtitleFocus = FocusNode();
  int _tab = 0;
  String? _fieldPath;

  GearLabController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: controller.currentStyle.title);
    _subtitleController = TextEditingController(
      text: controller.currentStyle.subtitle,
    );
    controller.addListener(_onControllerChanged);
    controller.preferences.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerChanged);
    controller.preferences.removeListener(_onControllerChanged);
    _titleController.dispose();
    _subtitleController.dispose();
    _titleFocus.dispose();
    _subtitleFocus.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    _syncTextFields();
    setState(() {});
  }

  void _syncTextFields() {
    final StyleSettings style = controller.currentStyle;
    final String? path = controller.selectedPhoto?.path;
    final bool selectionChanged = path != _fieldPath;
    _fieldPath = path;
    if (selectionChanged ||
        (!_titleFocus.hasFocus && _titleController.text != style.title)) {
      _titleController.text = style.title;
    }
    if (selectionChanged ||
        (!_subtitleFocus.hasFocus && _subtitleController.text != style.subtitle)) {
      _subtitleController.text = style.subtitle;
    }
  }

  Future<void> _import() async {
    if (controller.busy) return;
    try {
      final int count = await controller.pickImages();
      if (!mounted || count <= 0) return;
      _announce(
        count == 1
            ? AppLocalizations.of(context).savedCountOne
            : AppLocalizations.of(context).savedCount(count),
      );
    } catch (error) {
      if (!mounted) return;
      _announce('$error');
    }
  }

  Future<void> _openExport(ExportScope scope) async {
    if (controller.busy) return;
    if (controller.photos.isEmpty) {
      _announce(AppLocalizations.of(context).emptyExport);
      return;
    }
    final ExportOptions? options = await showDialog<ExportOptions>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) =>
          ExportDialog(controller: controller, initialScope: scope),
    );
    if (options == null || !mounted) return;
    final NavigatorState navigator = Navigator.of(context, rootNavigator: true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) =>
          ExportProgressDialog(controller: controller),
    );
    final ExportResult result;
    try {
      result = await controller.export(options);
    } finally {
      if (mounted) navigator.pop();
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) => ExportResultDialog(
        result: result,
        controller: controller,
      ),
    );
  }

  Future<void> _confirmReset() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool? yes = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => _ConfirmDialog(
        title: l10n.resetConfirmTitle,
        message: l10n.resetConfirmBody,
        confirmLabel: l10n.reset,
      ),
    );
    if (yes == true) controller.resetStyle();
  }

  Future<void> _confirmClear() async {
    if (controller.photos.isEmpty) return;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool? yes = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => _ConfirmDialog(
        title: l10n.clearConfirmTitle,
        message: l10n.clearConfirmBody,
        confirmLabel: l10n.clearPhotos,
        destructive: true,
      ),
    );
    if (yes == true) controller.clearPhotos();
  }

  Future<void> _showPreferences() async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) =>
          PreferencesDialog(controller: controller),
    );
  }

  void _announce(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _selectRelative(int delta) {
    if (controller.photos.isEmpty) return;
    final int total = controller.photos.length;
    final int index = controller.selectedIndex < 0
        ? 0
        : (controller.selectedIndex + delta).clamp(0, total - 1);
    controller.selectPhoto(index);
  }

  void _removeSelected() {
    if (controller.selectedIndex >= 0) {
      controller.removePhoto(controller.selectedIndex);
    }
  }

  Map<ShortcutActivator, VoidCallback> _shortcuts(bool touch) {
    return <ShortcutActivator, VoidCallback>{
      const SingleActivator(LogicalKeyboardKey.keyO, control: true): _import,
      const SingleActivator(LogicalKeyboardKey.keyE, control: true): () {
        _openExport(ExportScope.all);
      },
      const SingleActivator(LogicalKeyboardKey.keyS, control: true): () {
        controller.persistNow();
      },
      const SingleActivator(LogicalKeyboardKey.arrowLeft): () {
        if (!_titleFocus.hasFocus && !_subtitleFocus.hasFocus) {
          _selectRelative(-1);
        }
      },
      const SingleActivator(LogicalKeyboardKey.arrowRight): () {
        if (!_titleFocus.hasFocus && !_subtitleFocus.hasFocus) {
          _selectRelative(1);
        }
      },
      const SingleActivator(LogicalKeyboardKey.delete): () {
        if (!_titleFocus.hasFocus && !_subtitleFocus.hasFocus) {
          _removeSelected();
        }
      },
      const SingleActivator(LogicalKeyboardKey.backspace): () {
        if (!_titleFocus.hasFocus && !_subtitleFocus.hasFocus) {
          _removeSelected();
        }
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    final GlPalette p = context.gl;
    final bool touch = context.isTouchPlatform;
    final double width = MediaQuery.sizeOf(context).width;
    final bool compact = width < 720;
    final bool medium = width < 1100;
    return CallbackShortcuts(
      bindings: _shortcuts(touch),
      child: Focus(
        autofocus: !touch,
        child: Scaffold(
          backgroundColor: p.canvas,
          body: Column(
            children: <Widget>[
              ColoredBox(
                color: p.surface,
                child: Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.paddingOf(context).top,
                  ),
                  child: _TopBar(
                    controller: controller,
                    compact: compact,
                    onImport: _import,
                    onExport: _openExport,
                    onPreferences: _showPreferences,
                  ),
                ),
              ),
              Expanded(
                child: compact
                    ? _CompactLayout(
                        controller: controller,
                        titleController: _titleController,
                        subtitleController: _subtitleController,
                        titleFocus: _titleFocus,
                        subtitleFocus: _subtitleFocus,
                        tab: _tab,
                        onTab: (int value) => setState(() => _tab = value),
                        onImport: _import,
                        onExport: _openExport,
                        onReset: _confirmReset,
                        onClear: _confirmClear,
                      )
                    : _DesktopLayout(
                        controller: controller,
                        titleController: _titleController,
                        subtitleController: _subtitleController,
                        titleFocus: _titleFocus,
                        subtitleFocus: _subtitleFocus,
                        medium: medium,
                        onImport: _import,
                        onExport: _openExport,
                        onReset: _confirmReset,
                        onClear: _confirmClear,
                        onPreferences: _showPreferences,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shell
// ---------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.controller,
    required this.compact,
    required this.onImport,
    required this.onExport,
    required this.onPreferences,
  });

  final GearLabController controller;
  final bool compact;
  final VoidCallback onImport;
  final ValueChanged<ExportScope> onExport;
  final VoidCallback onPreferences;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final GlPalette p = context.gl;
    final double width = MediaQuery.sizeOf(context).width;
    final bool showNote = width >= 960;
    final bool showMenus = !compact;
    return Container(
      height: compact ? GlSize.topBarCompact : GlSize.topBar,
      padding: EdgeInsets.symmetric(horizontal: compact ? GlSpace.md : GlSpace.xl),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(bottom: BorderSide(color: p.line)),
      ),
      child: Row(
        children: <Widget>[
          _Brand(compact: compact),
          if (showNote) ...<Widget>[
            const SizedBox(width: GlSpace.xl),
            Expanded(
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.lock_outline, size: 13, color: p.ink3),
                    const SizedBox(width: 5),
                    Text(
                      l10n.localOnlyNote,
                      style: GlType.caption.copyWith(color: p.ink3),
                    ),
                  ],
                ),
              ),
            ),
          ] else
            const Spacer(),
          if (showMenus) ...<Widget>[
            _ThemeMenu(controller: controller),
            const SizedBox(width: 2),
            _LanguageMenu(controller: controller),
            const SizedBox(width: 2),
            GlIconButton(
              icon: Icons.tune,
              tooltip: l10n.preferences,
              onPressed: onPreferences,
            ),
            const SizedBox(width: GlSpace.sm),
          ] else
            GlIconButton(
              icon: Icons.more_horiz,
              tooltip: l10n.preferences,
              onPressed: onPreferences,
            ),
          if (compact)
            GlIconButton(
              icon: Icons.add_photo_alternate_outlined,
              tooltip: l10n.importPhotos,
              onPressed: onImport,
            )
          else ...<Widget>[
            GlButton(
              label: l10n.importPhotos,
              icon: Icons.add_photo_alternate_outlined,
              onPressed: onImport,
            ),
            const SizedBox(width: GlSpace.sm),
            GlButton(
              label: l10n.exportWork,
              icon: Icons.download_outlined,
              onPressed: controller.photos.isEmpty ? null : () => onExport(ExportScope.all),
            ),
          ],
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final GlPalette p = context.gl;
    final double iconSize = compact ? 24 : 28;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(GlRadius.sm),
          child: Image.asset(
            'assets/app_icon.png',
            width: iconSize,
            height: iconSize,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: GlSpace.sm),
        Text(
          'GEARLAB',
          style: GlType.wordmark.copyWith(
            color: p.ink,
            fontSize: compact ? 13 : 15,
          ),
        ),
        if (!compact) ...<Widget>[
          const SizedBox(width: GlSpace.md),
          Container(width: 1, height: 13, color: p.line),
          const SizedBox(width: GlSpace.md),
          Text(
            l10n.brandSubtitle,
            style: GlType.caption.copyWith(color: p.ink3),
          ),
        ],
      ],
    );
  }
}

class _ThemeMenu extends StatelessWidget {
  const _ThemeMenu({required this.controller});

  final GearLabController controller;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final GlPalette p = context.gl;
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return PopupMenuButton<GlThemePreference>(
      tooltip: l10n.theme,
      padding: EdgeInsets.zero,
      onSelected: controller.setThemePreference,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<GlThemePreference>>[
        CheckedPopupMenuItem<GlThemePreference>(
          value: GlThemePreference.system,
          checked: controller.preferences.value.theme == GlThemePreference.system,
          child: Text(l10n.themeSystem),
        ),
        CheckedPopupMenuItem<GlThemePreference>(
          value: GlThemePreference.light,
          checked: controller.preferences.value.theme == GlThemePreference.light,
          child: Text(l10n.themeLight),
        ),
        CheckedPopupMenuItem<GlThemePreference>(
          value: GlThemePreference.dark,
          checked: controller.preferences.value.theme == GlThemePreference.dark,
          child: Text(l10n.themeDark),
        ),
      ],
      child: SizedBox(
        width: 32,
        height: 32,
        child: Icon(
          dark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
          size: 18,
          color: p.ink2,
        ),
      ),
    );
  }
}

class _LanguageMenu extends StatelessWidget {
  const _LanguageMenu({required this.controller});

  final GearLabController controller;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final GlPalette p = context.gl;
    final String? code = controller.preferences.value.localeCode;
    return PopupMenuButton<String>(
      tooltip: l10n.language,
      padding: EdgeInsets.zero,
      onSelected: (String value) {
        controller.setLocaleCode(value == 'system' ? null : value);
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        CheckedPopupMenuItem<String>(
          value: 'system',
          checked: code == null,
          child: Text(l10n.languageSystem),
        ),
        CheckedPopupMenuItem<String>(
          value: 'zh',
          checked: code == 'zh',
          child: Text(l10n.languageZh),
        ),
        CheckedPopupMenuItem<String>(
          value: 'en',
          checked: code == 'en',
          child: Text(l10n.languageEn),
        ),
      ],
      child: SizedBox(
        width: 32,
        height: 32,
        child: Icon(Icons.translate, size: 18, color: p.ink2),
      ),
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({
    required this.controller,
    required this.titleController,
    required this.subtitleController,
    required this.titleFocus,
    required this.subtitleFocus,
    required this.medium,
    required this.onImport,
    required this.onExport,
    required this.onReset,
    required this.onClear,
    required this.onPreferences,
  });

  final GearLabController controller;
  final TextEditingController titleController;
  final TextEditingController subtitleController;
  final FocusNode titleFocus;
  final FocusNode subtitleFocus;
  final bool medium;
  final VoidCallback onImport;
  final ValueChanged<ExportScope> onExport;
  final VoidCallback onReset;
  final VoidCallback onClear;
  final VoidCallback onPreferences;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final double libraryWidth = width >= 1440 ? GlSize.libraryLarge : GlSize.library;
    final double inspectorWidth = width >= 1440
        ? GlSize.inspectorLarge
        : (medium ? GlSize.inspectorMedium : GlSize.inspector);
    Widget inspector() => _InspectorPane(
      controller: controller,
      titleController: titleController,
      subtitleController: subtitleController,
      titleFocus: titleFocus,
      subtitleFocus: subtitleFocus,
      onReset: onReset,
      onExport: onExport,
      onPreferences: onPreferences,
    );
    if (medium) {
      return Row(
        children: <Widget>[
          Expanded(
            child: Column(
              children: <Widget>[
                _PhotoStripHeader(
                  controller: controller,
                  onImport: onImport,
                  onClear: onClear,
                ),
                _PhotoStrip(controller: controller),
                Expanded(child: _StagePane(controller: controller)),
              ],
            ),
          ),
          SizedBox(width: inspectorWidth, child: inspector()),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(
          width: libraryWidth,
          child: _LibraryPane(
            controller: controller,
            onImport: onImport,
            onClear: onClear,
          ),
        ),
        Expanded(child: _StagePane(controller: controller)),
        SizedBox(width: inspectorWidth, child: inspector()),
      ],
    );
  }
}

class _CompactLayout extends StatelessWidget {
  const _CompactLayout({
    required this.controller,
    required this.titleController,
    required this.subtitleController,
    required this.titleFocus,
    required this.subtitleFocus,
    required this.tab,
    required this.onTab,
    required this.onImport,
    required this.onExport,
    required this.onReset,
    required this.onClear,
  });

  final GearLabController controller;
  final TextEditingController titleController;
  final TextEditingController subtitleController;
  final FocusNode titleFocus;
  final FocusNode subtitleFocus;
  final int tab;
  final ValueChanged<int> onTab;
  final VoidCallback onImport;
  final ValueChanged<ExportScope> onExport;
  final VoidCallback onReset;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final double height = MediaQuery.sizeOf(context).height;
    final double previewHeight = (height * 0.34).clamp(210.0, 286.0);
    return Column(
      children: <Widget>[
        SizedBox(
          height: previewHeight,
          child: _StagePane(controller: controller, compact: true),
        ),
        _PhotoStripHeader(
          controller: controller,
          onImport: onImport,
          onClear: onClear,
        ),
        _PhotoStrip(controller: controller),
        _CompactToolbar(
          controller: controller,
          onReset: onReset,
        ),
        _CompactTabs(tab: tab, onTab: onTab),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              GlSpace.md,
              GlSpace.sm,
              GlSpace.md,
              GlSpace.xl,
            ),
            child: _SectionContent(
              index: tab,
              controller: controller,
              titleController: titleController,
              subtitleController: subtitleController,
              titleFocus: titleFocus,
              subtitleFocus: subtitleFocus,
              compact: true,
            ),
          ),
        ),
        _CompactActionBar(
          controller: controller,
          onExport: onExport,
          labels: l10n,
        ),
      ],
    );
  }
}

class _CompactToolbar extends StatelessWidget {
  const _CompactToolbar({required this.controller, required this.onReset});

  final GearLabController controller;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final GlPalette p = context.gl;
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: GlSpace.md),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(
          top: BorderSide(color: p.line),
          bottom: BorderSide(color: p.line),
        ),
      ),
      child: Row(
        children: <Widget>[
          Text(
            l10n.layoutSettings,
            style: GlType.section.copyWith(color: p.ink),
          ),
          const Spacer(),
          Text(l10n.syncAll, style: GlType.label.copyWith(color: p.ink3)),
          Transform.scale(
            scale: 0.78,
            child: Switch(
              value: controller.syncAll,
              onChanged: controller.setSyncAll,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 2),
          IconButton(
            onPressed: onReset,
            tooltip: l10n.reset,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: Icon(Icons.restart_alt, size: 17, color: p.ink2),
          ),
        ],
      ),
    );
  }
}

class _CompactTabs extends StatelessWidget {
  const _CompactTabs({required this.tab, required this.onTab});

  final int tab;
  final ValueChanged<int> onTab;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final GlPalette p = context.gl;
    final List<String> labels = <String>[
      l10n.tabCamera,
      l10n.tabText,
      l10n.tabLayout,
      l10n.tabBackground,
      l10n.tabScreen,
    ];
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(bottom: BorderSide(color: p.line)),
      ),
      child: Row(
        children: List<Widget>.generate(labels.length, (int index) {
          final bool selected = index == tab;
          return Expanded(
            child: InkWell(
              onTap: () => onTab(index),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: selected ? p.accent : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  labels[index],
                  style: GlType.label.copyWith(
                    color: selected ? p.ink : p.ink3,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _CompactActionBar extends StatelessWidget {
  const _CompactActionBar({
    required this.controller,
    required this.onExport,
    required this.labels,
  });

  final GearLabController controller;
  final ValueChanged<ExportScope> onExport;
  final AppLocalizations labels;

  @override
  Widget build(BuildContext context) {
    final GlPalette p = context.gl;
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.line)),
      ),
      padding: EdgeInsets.fromLTRB(
        GlSpace.md,
        GlSpace.sm,
        GlSpace.md,
        GlSpace.sm + MediaQuery.paddingOf(context).bottom,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 2,
            child: GlButton(
              label: labels.exportCurrent,
              onPressed: controller.selectedPhoto == null ? null : () => onExport(ExportScope.current),
            ),
          ),
          const SizedBox(width: GlSpace.sm),
          Expanded(
            flex: 3,
            child: GlButton(
              label: controller.photos.length == 1
                  ? labels.exportAllOne
                  : labels.exportAll(controller.photos.length),
              icon: Icons.download_outlined,
              variant: GlButtonVariant.primary,
              onPressed: controller.photos.isEmpty ? null : () => onExport(ExportScope.all),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Panes
// ---------------------------------------------------------------------------

class _LibraryPane extends StatelessWidget {
  const _LibraryPane({
    required this.controller,
    required this.onImport,
    required this.onClear,
  });

  final GearLabController controller;
  final VoidCallback onImport;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final GlPalette p = context.gl;
    return GlPane(
      header: GlPaneHeader(
        title: l10n.library,
        meta: controller.photos.length == 1
            ? l10n.allPhotosOne
            : l10n.allPhotos(controller.photos.length),
        actions: <Widget>[
          GlIconButton(
            icon: Icons.delete_sweep_outlined,
            tooltip: l10n.clearPhotos,
            size: 16,
            onPressed: controller.photos.isEmpty ? null : onClear,
          ),
          GlIconButton(
            icon: Icons.add,
            tooltip: l10n.importPhotos,
            size: 16,
            onPressed: onImport,
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Expanded(
            child: controller.photos.isEmpty
                ? GlEmptyState(
                    icon: Icons.photo_library_outlined,
                    title: l10n.emptyLibraryTitle,
                    message: l10n.emptyLibraryBody,
                    action: GlButton(
                      label: l10n.importPhotos,
                      icon: Icons.add_photo_alternate_outlined,
                      onPressed: onImport,
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: controller.photos.length,
                    itemBuilder: (BuildContext context, int index) {
                      final PhotoItem photo = controller.photos[index];
                      return GlPhotoRow(
                        index: index,
                        name: photo.name,
                        meta: l10n.photoMeta(
                          CameraCatalog.find(photo.style.cameraId).model,
                          photo.image.height,
                          photo.image.width,
                        ),
                        thumbnail: RawImage(
                          image: photo.image,
                          fit: BoxFit.cover,
                        ),
                        selected: index == controller.selectedIndex,
                        onTap: () => controller.selectPhoto(index),
                        onRemove: () => controller.removePhoto(index),
                        removeTooltip: l10n.deletePhoto,
                      );
                    },
                  ),
          ),
          if (controller.platform.supportsDrop)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: GlSpace.lg,
                vertical: GlSpace.sm,
              ),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: p.lineSoft)),
              ),
              child: Row(
                children: <Widget>[
                  Icon(Icons.file_download_outlined, size: 13, color: p.ink3),
                  const SizedBox(width: 5),
                  Text(
                    l10n.dropHint,
                    style: GlType.caption.copyWith(color: p.ink3),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

enum _LibraryAction { removeCurrent, clearAll }

class _PhotoStripHeader extends StatelessWidget {
  const _PhotoStripHeader({
    required this.controller,
    required this.onImport,
    this.onClear,
  });

  final GearLabController controller;
  final VoidCallback onImport;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final GlPalette p = context.gl;
    return Container(
      height: 38,
      padding: const EdgeInsets.only(left: GlSpace.lg, right: GlSpace.sm),
      color: p.surface,
      child: Row(
        children: <Widget>[
          Text(
            l10n.library,
            style: GlType.section.copyWith(color: p.ink),
          ),
          const SizedBox(width: 6),
          Text(
            controller.photos.length.toString().padLeft(2, '0'),
            style: GlType.numeric.copyWith(color: p.ink3),
          ),
          const Spacer(),
          if (controller.photos.isNotEmpty)
            PopupMenuButton<_LibraryAction>(
              tooltip: l10n.deletePhoto,
              padding: EdgeInsets.zero,
              onSelected: (_LibraryAction action) {
                switch (action) {
                  case _LibraryAction.removeCurrent:
                    if (controller.selectedPhoto != null) {
                      controller.removePhoto(controller.selectedIndex);
                    }
                  case _LibraryAction.clearAll:
                    onClear?.call();
                }
              },
              itemBuilder: (BuildContext context) =>
                  <PopupMenuEntry<_LibraryAction>>[
                    PopupMenuItem<_LibraryAction>(
                      value: _LibraryAction.removeCurrent,
                      enabled: controller.selectedPhoto != null,
                      child: Text(l10n.deletePhoto),
                    ),
                    if (onClear != null)
                      PopupMenuItem<_LibraryAction>(
                        value: _LibraryAction.clearAll,
                        child: Text(l10n.clearPhotos),
                      ),
                  ],
              child: SizedBox(
                width: 32,
                height: 32,
                child: Icon(
                  Icons.delete_outline,
                  size: 16,
                  color: controller.photos.isEmpty ? p.ink3 : p.ink2,
                ),
              ),
            ),
          GlIconButton(
            icon: Icons.add,
            tooltip: l10n.importPhotos,
            size: 16,
            onPressed: onImport,
          ),
        ],
      ),
    );
  }
}

class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({required this.controller});

  final GearLabController controller;

  @override
  Widget build(BuildContext context) {
    final GlPalette p = context.gl;
    if (controller.photos.isEmpty) {
      return Container(
        height: 70,
        color: p.surface,
        padding: const EdgeInsets.symmetric(horizontal: GlSpace.lg),
        alignment: Alignment.centerLeft,
        child: Text(
          AppLocalizations.of(context).emptyLibraryBody,
          style: GlType.caption.copyWith(color: p.ink3),
        ),
      );
    }
    return Container(
      height: 70,
      color: p.surface,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: GlSpace.lg, vertical: 6),
        scrollDirection: Axis.horizontal,
        itemCount: controller.photos.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(width: GlSpace.sm),
        itemBuilder: (BuildContext context, int index) {
          final PhotoItem photo = controller.photos[index];
          return GlPhotoStripCard(
            index: index,
            thumbnail: RawImage(image: photo.image, fit: BoxFit.cover),
            selected: index == controller.selectedIndex,
            onTap: () => controller.selectPhoto(index),
            label: photo.name,
          );
        },
      ),
    );
  }
}

class _StagePane extends StatelessWidget {
  const _StagePane({required this.controller, this.compact = false});

  final GearLabController controller;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final GlPalette p = context.gl;
    final PhotoItem? photo = controller.selectedPhoto;
    final String dimensions = photo == null
        ? '—'
        : '${photo.image.width} × ${photo.image.height}';
    return Container(
      color: p.canvas,
      child: Column(
        children: <Widget>[
          Container(
            height: compact ? 38 : 44,
            padding: const EdgeInsets.symmetric(horizontal: GlSpace.lg),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: p.line),
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(width: 5, height: 5, color: p.accent),
                const SizedBox(width: 6),
                Text(
                  l10n.preview,
                  style: GlType.section.copyWith(color: p.ink),
                ),
                const Spacer(),
                Text(
                  dimensions,
                  style: GlType.numeric.copyWith(color: p.ink2),
                ),
              ],
            ),
          ),
          Expanded(
            child: photo == null
                ? GlEmptyState(
                    icon: Icons.camera_outlined,
                    title: l10n.emptyStageTitle,
                    message: l10n.emptyStageBody,
                    action: GlButton(
                      label: l10n.importPhotos,
                      icon: Icons.add_photo_alternate_outlined,
                      variant: GlButtonVariant.primary,
                      onPressed: _importFromStage(context),
                    ),
                  )
                : _PosterStage(controller: controller, compact: compact),
          ),
          if (photo != null)
            Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: GlSpace.lg),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: p.lineSoft)),
              ),
              child: Row(
                children: <Widget>[
                  Text(
                    l10n.currentOf(
                      controller.selectedIndex + 1,
                      controller.photos.length,
                    ),
                    style: GlType.numeric.copyWith(color: p.ink2),
                  ),
                  const SizedBox(width: GlSpace.md),
                  if (!compact)
                    Expanded(
                      child: Text(
                        photo.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GlType.caption.copyWith(color: p.ink3),
                      ),
                    )
                  else
                    const Spacer(),
                  if (!compact) ...<Widget>[
                    Text(
                      l10n.stageFooterSplit,
                      style: GlType.caption.copyWith(color: p.ink3),
                    ),
                    const SizedBox(width: GlSpace.md),
                    Text(
                      l10n.stageFooterFormat,
                      style: GlType.numeric.copyWith(color: p.ink3),
                    ),
                    const SizedBox(width: GlSpace.md),
                    Text(
                      l10n.stageFooterWidth(2160),
                      style: GlType.numeric.copyWith(color: p.ink3),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  VoidCallback _importFromStage(BuildContext context) {
    final _EditorPageState? state =
        context.findAncestorStateOfType<_EditorPageState>();
    return state != null ? state._import : () {};
  }
}

class _PosterStage extends StatefulWidget {
  const _PosterStage({required this.controller, required this.compact});

  final GearLabController controller;
  final bool compact;

  @override
  State<_PosterStage> createState() => _PosterStageState();
}

class _PosterStageState extends State<_PosterStage> {
  bool _hover = false;

  void _step(int delta) {
    final int total = widget.controller.photos.length;
    if (total == 0) return;
    final int current = widget.controller.selectedIndex;
    final int next = (current + delta).clamp(0, total - 1);
    if (next == current) return;
    widget.controller.selectPhoto(next);
  }

  @override
  Widget build(BuildContext context) {
    final GlPalette p = context.gl;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final PhotoItem? photo = widget.controller.selectedPhoto;
    if (photo == null) return const SizedBox.shrink();
    final double aspect = photo.aspect;
    final bool touch = context.isTouchPlatform;
    final int index = widget.controller.selectedIndex;
    final int total = widget.controller.photos.length;
    final bool showArrows = total > 1;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double horizontalMargin = widget.compact ? 56 : 120;
        final double verticalMargin = widget.compact ? 32 : 74;
        final double maxWidth = math.max(80, constraints.maxWidth - horizontalMargin);
        final double maxHeight = math.max(120, constraints.maxHeight - verticalMargin);
        final double width = math.min(maxWidth, maxHeight * aspect / 2);
        final double height = 2 * width / aspect;
        return MouseRegion(
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: GlCropMarks(
                  color: p.lineStrong.withValues(alpha: 0.5),
                  inset: 18,
                ),
              ),
              Center(
                child: RepaintBoundary(
                  child: Container(
                    width: width,
                    height: height,
                    decoration: BoxDecoration(
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: p.shadow,
                          blurRadius: 28,
                          spreadRadius: -8,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: CustomPaint(
                      painter: PosterPainter(
                        style: widget.controller.currentStyle,
                        template: widget.controller.template,
                        photo: photo.image,
                        camera: CameraCatalog.images[widget.controller.template.id],
                      ),
                    ),
                  ),
                ),
              ),
              if (showArrows) ...<Widget>[
                Positioned(
                  left: 6,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _StageArrow(
                      icon: Icons.chevron_left,
                      tooltip: '${l10n.previousPhoto} (←)',
                      enabled: index > 0,
                      visible: _hover || touch,
                      onPressed: () => _step(-1),
                    ),
                  ),
                ),
                Positioned(
                  right: 6,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _StageArrow(
                      icon: Icons.chevron_right,
                      tooltip: '${l10n.nextPhoto} (→)',
                      enabled: index >= 0 && index < total - 1,
                      visible: _hover || touch,
                      onPressed: () => _step(1),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _StageArrow extends StatefulWidget {
  const _StageArrow({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.visible,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool enabled;
  final bool visible;
  final VoidCallback onPressed;

  @override
  State<_StageArrow> createState() => _StageArrowState();
}

class _StageArrowState extends State<_StageArrow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final GlPalette p = context.gl;
    final bool shown = widget.visible && widget.enabled;
    return IgnorePointer(
      ignoring: !shown,
      child: AnimatedOpacity(
        opacity: shown ? 1 : 0,
        duration: GlDuration.fast,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: Tooltip(
            message: widget.tooltip,
            waitDuration: const Duration(milliseconds: 450),
            child: GestureDetector(
              onTap: widget.onPressed,
              child: AnimatedContainer(
                duration: GlDuration.fast,
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: p.raised,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _hover ? p.lineStrong : p.line,
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: p.shadow,
                      blurRadius: 12,
                      spreadRadius: -4,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  widget.icon,
                  size: 18,
                  color: _hover ? p.ink : p.ink2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InspectorPane extends StatelessWidget {
  const _InspectorPane({
    required this.controller,
    required this.titleController,
    required this.subtitleController,
    required this.titleFocus,
    required this.subtitleFocus,
    required this.onReset,
    required this.onExport,
    required this.onPreferences,
  });

  final GearLabController controller;
  final TextEditingController titleController;
  final TextEditingController subtitleController;
  final FocusNode titleFocus;
  final FocusNode subtitleFocus;
  final VoidCallback onReset;
  final ValueChanged<ExportScope> onExport;
  final VoidCallback onPreferences;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final GlPalette p = context.gl;
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(left: BorderSide(color: p.line)),
      ),
      child: Column(
        children: <Widget>[
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: GlSpace.lg),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: p.line)),
            ),
            child: Row(
              children: <Widget>[
                Text(
                  l10n.layoutSettings,
                  style: GlType.section.copyWith(color: p.ink),
                ),
                const Spacer(),
                Text(
                  l10n.syncAll,
                  style: GlType.caption.copyWith(color: p.ink3),
                ),
                Transform.scale(
                  scale: 0.78,
                  child: Switch(
                    value: controller.syncAll,
                    onChanged: controller.setSyncAll,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                IconButton(
                  onPressed: onReset,
                  tooltip: l10n.reset,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: Icon(Icons.restart_alt, size: 17, color: p.ink2),
                ),
              ],
            ),
          ),
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              child: ListView(
                padding: const EdgeInsets.only(bottom: GlSpace.lg),
                children: <Widget>[
                  _SectionContent(
                    index: 0,
                    controller: controller,
                    titleController: titleController,
                    subtitleController: subtitleController,
                    titleFocus: titleFocus,
                    subtitleFocus: subtitleFocus,
                  ),
                  _SectionContent(
                    index: 1,
                    controller: controller,
                    titleController: titleController,
                    subtitleController: subtitleController,
                    titleFocus: titleFocus,
                    subtitleFocus: subtitleFocus,
                  ),
                  _SectionContent(
                    index: 2,
                    controller: controller,
                    titleController: titleController,
                    subtitleController: subtitleController,
                    titleFocus: titleFocus,
                    subtitleFocus: subtitleFocus,
                  ),
                  _SectionContent(
                    index: 3,
                    controller: controller,
                    titleController: titleController,
                    subtitleController: subtitleController,
                    titleFocus: titleFocus,
                    subtitleFocus: subtitleFocus,
                  ),
                  _SectionContent(
                    index: 4,
                    controller: controller,
                    titleController: titleController,
                    subtitleController: subtitleController,
                    titleFocus: titleFocus,
                    subtitleFocus: subtitleFocus,
                  ),
                ],
              ),
            ),
          ),
          _DesktopActionBar(controller: controller, onExport: onExport),
        ],
      ),
    );
  }
}

class _DesktopActionBar extends StatelessWidget {
  const _DesktopActionBar({required this.controller, required this.onExport});

  final GearLabController controller;
  final ValueChanged<ExportScope> onExport;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return GlActionBar(
      padding: const EdgeInsets.fromLTRB(
        GlSpace.lg,
        GlSpace.md,
        GlSpace.lg,
        GlSpace.md,
      ),
      children: <Widget>[
        GlButton(
          label: l10n.exportCurrent,
          onPressed: controller.selectedPhoto == null ? null : () => onExport(ExportScope.current),
        ),
        const SizedBox(width: GlSpace.sm),
        Expanded(
          flex: 2,
          child: GlButton(
            label: controller.photos.length == 1
                ? l10n.exportAllOne
                : l10n.exportAll(controller.photos.length),
            icon: Icons.download_outlined,
            variant: GlButtonVariant.primary,
            onPressed: controller.photos.isEmpty ? null : () => onExport(ExportScope.all),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Inspector sections
// ---------------------------------------------------------------------------

class _SectionContent extends StatelessWidget {
  const _SectionContent({
    required this.index,
    required this.controller,
    required this.titleController,
    required this.subtitleController,
    required this.titleFocus,
    required this.subtitleFocus,
    this.compact = false,
  });

  final int index;
  final GearLabController controller;
  final TextEditingController titleController;
  final TextEditingController subtitleController;
  final FocusNode titleFocus;
  final FocusNode subtitleFocus;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final EdgeInsets padding = compact
        ? const EdgeInsets.fromLTRB(GlSpace.md, GlSpace.md, GlSpace.md, GlSpace.md)
        : const EdgeInsets.fromLTRB(
            GlSpace.lg,
            GlSpace.md,
            GlSpace.lg,
            GlSpace.md,
          );
    switch (index) {
      case 0:
        return _CameraSection(
          controller: controller,
          padding: padding,
        );
      case 1:
        return _TextSection(
          controller: controller,
          titleController: titleController,
          subtitleController: subtitleController,
          titleFocus: titleFocus,
          subtitleFocus: subtitleFocus,
          padding: padding,
        );
      case 2:
        return _LayoutSection(controller: controller, padding: padding);
      case 3:
        return _BackgroundSection(controller: controller, padding: padding);
      default:
        return _ScreenSection(controller: controller, padding: padding);
    }
  }
}

class _CameraSection extends StatelessWidget {
  const _CameraSection({required this.controller, required this.padding});

  final GearLabController controller;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return GlSection(
      title: l10n.sectionCamera,
      padding: padding,
      trailing: TextButton(
        onPressed: () => showCameraPanel(context, controller),
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 26),
          padding: const EdgeInsets.symmetric(horizontal: GlSpace.sm),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          foregroundColor: context.gl.ink2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              l10n.browseAllCameras(CameraCatalog.all.length),
              style: GlType.caption.copyWith(color: context.gl.ink2),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.chevron_right,
              size: 14,
              color: context.gl.ink3,
            ),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _CameraStrip(controller: controller),
        ],
      ),
    );
  }
}

class _CameraStrip extends StatefulWidget {
  const _CameraStrip({required this.controller});

  final GearLabController controller;

  @override
  State<_CameraStrip> createState() => _CameraStripState();
}

class _CameraStripState extends State<_CameraStrip> {
  final ScrollController _scroll = ScrollController();
  bool _canBack = false;
  bool _canForward = true;
  String _cameraId = '';

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _cameraId = widget.controller.currentStyle.cameraId;
    widget.controller.addListener(_onControllerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onScroll();
      _scrollToSelected();
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    final String id = widget.controller.currentStyle.cameraId;
    if (id == _cameraId) return;
    _cameraId = id;
    _scrollToSelected();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final bool back = _scroll.offset > 2;
    final bool forward =
        _scroll.offset < _scroll.position.maxScrollExtent - 2;
    if (back != _canBack || forward != _canForward) {
      setState(() {
        _canBack = back;
        _canForward = forward;
      });
    }
  }

  void _page(double direction) {
    if (!_scroll.hasClients) return;
    final double target = (_scroll.offset + direction * 240).clamp(
      0.0,
      _scroll.position.maxScrollExtent,
    );
    _scroll.animateTo(
      target,
      duration: GlDuration.normal,
      curve: Curves.easeOutCubic,
    );
  }

  void _scrollToSelected() {
    if (!_scroll.hasClients) return;
    final int index = CameraCatalog.all.indexWhere(
      (CameraTemplate template) =>
          template.id == widget.controller.currentStyle.cameraId,
    );
    if (index < 0) return;
    final double target = (index * 80.0 - 80).clamp(
      0.0,
      _scroll.position.maxScrollExtent,
    );
    _scroll.jumpTo(target);
  }

  void _select(String id) {
    widget.controller.setCamera(id);
    _cameraId = widget.controller.currentStyle.cameraId;
    final int index = CameraCatalog.all.indexWhere(
      (CameraTemplate template) => template.id == id,
    );
    if (index < 0 || !_scroll.hasClients) return;
    final double target = (index * 80.0 - 80).clamp(
      0.0,
      _scroll.position.maxScrollExtent,
    );
    _scroll.animateTo(
      target,
      duration: GlDuration.normal,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String selected = widget.controller.currentStyle.cameraId;
    return SizedBox(
      height: GlSize.cameraStrip + 24,
      child: Column(
        children: <Widget>[
          SizedBox(
            height: GlSize.cameraStrip,
            child: Listener(
              onPointerSignal: (PointerSignalEvent event) {
                if (event is PointerScrollEvent && _scroll.hasClients) {
                  _scroll.jumpTo(
                    (_scroll.offset + event.scrollDelta.dy).clamp(
                      0.0,
                      _scroll.position.maxScrollExtent,
                    ),
                  );
                }
              },
              child: ListView.separated(
                controller: _scroll,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(vertical: 2),
                itemCount: CameraCatalog.all.length,
                separatorBuilder: (BuildContext context, int index) =>
                    const SizedBox(width: 6),
                itemBuilder: (BuildContext context, int index) {
                  final CameraTemplate template = CameraCatalog.all[index];
                  return GlCameraCard(
                    image: CameraCatalog.images[template.id],
                    brand: template.brand,
                    model: template.model,
                    selected: template.id == selected,
                    width: 74,
                    onTap: () => _select(template.id),
                  );
                },
              ),
            ),
          ),
          SizedBox(
            height: 24,
            child: Row(
              children: <Widget>[
                _StripArrow(
                  icon: Icons.chevron_left,
                  enabled: _canBack,
                  onPressed: () => _page(-1),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      l10n.cameraHint,
                      style: GlType.caption.copyWith(color: context.gl.ink3),
                    ),
                  ),
                ),
                _StripArrow(
                  icon: Icons.chevron_right,
                  enabled: _canForward,
                  onPressed: () => _page(1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StripArrow extends StatelessWidget {
  const _StripArrow({
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final GlPalette p = context.gl;
    return SizedBox(
      width: 24,
      height: 24,
      child: IconButton(
        onPressed: enabled ? onPressed : null,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
        icon: Icon(
          icon,
          size: 16,
          color: enabled ? p.ink2 : p.lineStrong,
        ),
      ),
    );
  }
}

class _TextSection extends StatelessWidget {
  const _TextSection({
    required this.controller,
    required this.titleController,
    required this.subtitleController,
    required this.titleFocus,
    required this.subtitleFocus,
    required this.padding,
  });

  final GearLabController controller;
  final TextEditingController titleController;
  final TextEditingController subtitleController;
  final FocusNode titleFocus;
  final FocusNode subtitleFocus;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final StyleSettings style = controller.currentStyle;
    return GlSection(
      title: l10n.sectionText,
      padding: padding,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(l10n.showTitle, style: GlType.label.copyWith(color: context.gl.ink3)),
          Transform.scale(
            scale: 0.74,
            child: Switch(
              value: style.showTitle,
              onChanged: controller.setShowTitle,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          GlField(
            label: l10n.titleLabel,
            child: GlTextField(
              controller: titleController,
              focusNode: titleFocus,
              hint: l10n.titleHint,
              enabled: style.showTitle,
              maxLength: 80,
              textInputAction: TextInputAction.next,
              onChanged: controller.setTitle,
            ),
          ),
          const SizedBox(height: GlSpace.md),
          GlField(
            label: l10n.subtitleLabel,
            child: GlTextField(
              controller: subtitleController,
              focusNode: subtitleFocus,
              hint: l10n.subtitleHint,
              maxLength: 120,
              onChanged: controller.setSubtitle,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.titleHelper,
            style: GlType.caption.copyWith(color: context.gl.ink3),
          ),
        ],
      ),
    );
  }
}

class _LayoutSection extends StatelessWidget {
  const _LayoutSection({required this.controller, required this.padding});

  final GearLabController controller;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final StyleSettings style = controller.currentStyle;
    return GlSection(
      title: l10n.sectionLayout,
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          GlInfoRow(label: l10n.photoRatio, value: l10n.photoRatioValue),
          GlInfoRow(label: l10n.split, value: l10n.splitValue),
          const SizedBox(height: GlSpace.sm),
          GlSliderRow(
            label: l10n.cameraSize,
            value: style.cameraScale,
            min: 0.34,
            max: 0.72,
            divisions: 38,
            valueLabel: '${(style.cameraScale * 100).round()}%',
            supporting: l10n.layoutNote,
            onChanged: controller.setCameraScale,
          ),
        ],
      ),
    );
  }
}

class _BackgroundSection extends StatelessWidget {
  const _BackgroundSection({required this.controller, required this.padding});

  final GearLabController controller;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final GlPalette p = context.gl;
    final Color color = controller.currentStyle.topColor;
    return GlSection(
      title: l10n.sectionBackground,
      padding: padding,
      trailing: InkWell(
        onTap: () => _pickColor(context),
        borderRadius: BorderRadius.circular(GlRadius.sm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(GlRadius.sm),
            border: Border.all(color: p.line),
          ),
          child: Text(
            _hex(color),
            style: GlType.numeric.copyWith(color: _labelOn(color)),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          GlColorSwatches(
            colors: GlBackdrops.all,
            value: color,
            size: 24,
            onChanged: controller.setTopColor,
          ),
          const SizedBox(height: GlSpace.md),
          Row(
            children: <Widget>[
              GlIconButton(
                icon: Icons.colorize_outlined,
                tooltip: l10n.backgroundLabel,
                size: 16,
                onPressed: () => _pickColor(context),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  l10n.backgroundNote,
                  style: GlType.caption.copyWith(color: p.ink3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickColor(BuildContext context) async {
    final Color? color = await showDialog<Color>(
      context: context,
      builder: (BuildContext context) => GlColorPickerDialog(
        initial: controller.currentStyle.topColor,
      ),
    );
    if (color != null) controller.setTopColor(color);
  }

  static String _hex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }

  /// The swatch IS the selected band colour, so the label has to stay readable
  /// on it. That colour comes from the photo, not from the theme, which is why
  /// the absolute ink/paper pair is used instead of the active palette.
  static Color _labelOn(Color background) {
    return background.computeLuminance() > 0.5
        ? GlPalette.light.ink
        : GlPalette.light.raised;
  }
}

class _ScreenSection extends StatelessWidget {
  const _ScreenSection({required this.controller, required this.padding});

  final GearLabController controller;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final StyleSettings style = controller.currentStyle;
    return GlSection(
      title: l10n.sectionScreen,
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          GlSegmentedControl<ScreenFitMode>(
            value: style.screenFit,
            onChanged: controller.setScreenFit,
            options: <GlSegmentedOption<ScreenFitMode>>[
              GlSegmentedOption<ScreenFitMode>(
                value: ScreenFitMode.fill,
                label: l10n.fill,
              ),
              GlSegmentedOption<ScreenFitMode>(
                value: ScreenFitMode.fit,
                label: l10n.fit,
              ),
            ],
          ),
          const SizedBox(height: GlSpace.sm),
          GlSwitchRow(
            label: l10n.glare,
            value: style.screenGlare,
            onChanged: controller.setScreenGlare,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.screenNote,
            style: GlType.caption.copyWith(color: context.gl.ink3),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dialogs shared by the editor
// ---------------------------------------------------------------------------

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.destructive = false,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return GlDialogFrame(
      title: title,
      description: message,
      maxWidth: 420,
      onClose: () => Navigator.pop(context, false),
      actions: <Widget>[
        GlButton(
          label: l10n.cancel,
          onPressed: () => Navigator.pop(context, false),
        ),
        GlButton(
          label: confirmLabel,
          variant: destructive ? GlButtonVariant.danger : GlButtonVariant.primary,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
      child: const SizedBox.shrink(),
    );
  }
}
