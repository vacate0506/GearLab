import 'package:material_ui/material_ui.dart';

import '../../design/components.dart';
import '../../design/theme.dart';
import '../../design/tokens.dart';
import '../../domain/catalog.dart';
import '../../domain/models.dart';
import '../../l10n/generated/app_localizations.dart';
import 'camera_search.dart';
import 'editor_controller.dart';

/// Opens the full camera body picker.
///
/// The inspector strip only shows a handful of bodies at a time; this panel
/// lists all of them at once, with brand filters, search, recents and
/// favorites for people who shoot the same two or three bodies over and over.
Future<void> showCameraPanel(
  BuildContext context,
  GearLabController controller,
) {
  // On a phone the keyboard would slide up over half the grid the moment the
  // panel opens, so only the desktop build drops the caret into search.
  final bool autofocusSearch = !context.isTouchPlatform;
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) => CameraPanel(
      controller: controller,
      autofocusSearch: autofocusSearch,
    ),
  );
}

class CameraPanel extends StatefulWidget {
  const CameraPanel({
    super.key,
    required this.controller,
    this.autofocusSearch = true,
  });

  final GearLabController controller;
  final bool autofocusSearch;

  @override
  State<CameraPanel> createState() => _CameraPanelState();
}

class _CameraPanelState extends State<CameraPanel> {
  static const String _recentKey = '__recent';
  static const String _favoriteKey = '__favorites';

  final TextEditingController _search = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _filter = '';
  String _query = '';

  @override
  void initState() {
    super.initState();
    if (!widget.autofocusSearch) return;
    // Land in the search box so a query can be typed straight away.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchFocus.dispose();
    _search.dispose();
    super.dispose();
  }

  List<CameraTemplate> _items(
    List<String> recent,
    List<String> favorites,
    AppLocalizations l10n,
  ) {
    final Map<String, CameraTemplate> index = <String, CameraTemplate>{
      for (final CameraTemplate template in CameraCatalog.all)
        template.id: template,
    };
    Iterable<CameraTemplate> list;
    switch (_filter) {
      case _recentKey:
        list = recent.map((String id) => index[id]).whereType<CameraTemplate>();
      case _favoriteKey:
        list = favorites
            .map((String id) => index[id])
            .whereType<CameraTemplate>();
      case '':
        list = CameraCatalog.all;
      default:
        list = CameraCatalog.all.where(
          (CameraTemplate template) => template.brand == _filter,
        );
    }
    return searchCameras(
      list,
      _query,
      aliases: <String, String>{
        'FUJIFILM': l10n.cameraAliasFujifilm,
        'NIKON': l10n.cameraAliasNikon,
        'CANON': l10n.cameraAliasCanon,
        'SONY': l10n.cameraAliasSony,
        'LUMIX': l10n.cameraAliasLumix,
        'RICOH': l10n.cameraAliasRicoh,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final GlPalette p = context.gl;
    return GlDialogFrame(
      title: l10n.sectionCamera,
      description: l10n.cameraPanelNote,
      maxWidth: 640,
      onClose: () => Navigator.pop(context),
      actions: <Widget>[
        GlButton(
          label: l10n.done,
          onPressed: () => Navigator.pop(context),
        ),
      ],
      child: AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[
          widget.controller.recentCameras,
          widget.controller.favoriteCameras,
        ]),
        builder: (BuildContext context, Widget? child) {
          final List<String> recent = widget.controller.recentCameras.value;
          final List<String> favorites =
              widget.controller.favoriteCameras.value;
          final List<CameraTemplate> items = _items(recent, favorites, l10n);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              GlTextField(
                controller: _search,
                focusNode: _searchFocus,
                hint: l10n.cameraSearchHint,
                onChanged: (String value) =>
                    setState(() => _query = value.trim()),
              ),
              const SizedBox(height: GlSpace.md),
              Wrap(
                spacing: GlSpace.xs + 2,
                runSpacing: GlSpace.xs + 2,
                children: <Widget>[
                  _FilterChip(
                    label: l10n.filterAll,
                    selected: _filter.isEmpty,
                    onTap: () => setState(() => _filter = ''),
                  ),
                  if (favorites.isNotEmpty)
                    _FilterChip(
                      label: '${l10n.filterFavorites} ${favorites.length}',
                      icon: Icons.star_rounded,
                      selected: _filter == _favoriteKey,
                      onTap: () => setState(() => _filter = _favoriteKey),
                    ),
                  if (recent.isNotEmpty)
                    _FilterChip(
                      label: '${l10n.filterRecent} ${recent.length}',
                      icon: Icons.history,
                      selected: _filter == _recentKey,
                      onTap: () => setState(() => _filter = _recentKey),
                    ),
                  for (final String brand in _brands)
                    _FilterChip(
                      label: brand,
                      selected: _filter == brand,
                      onTap: () => setState(() => _filter = brand),
                    ),
                ],
              ),
              const SizedBox(height: GlSpace.md),
              SizedBox(
                height: 356,
                child: items.isEmpty
                    ? Center(
                        child: Text(
                          l10n.noCameraMatch,
                          style: GlType.caption.copyWith(color: p.ink3),
                        ),
                      )
                    : GridView.builder(
                        padding: EdgeInsets.zero,
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 88,
                              mainAxisExtent: 88,
                              crossAxisSpacing: GlSpace.sm,
                              mainAxisSpacing: GlSpace.sm,
                            ),
                        itemCount: items.length,
                        itemBuilder: (BuildContext context, int index) {
                          final CameraTemplate template = items[index];
                          return _PanelCard(
                            template: template,
                            favorite: favorites.contains(template.id),
                            selected:
                                widget.controller.currentStyle.cameraId ==
                                template.id,
                            favoriteTooltip: favorites.contains(template.id)
                                ? l10n.unfavoriteCamera
                                : l10n.favoriteCamera,
                            onTap: () {
                              widget.controller.setCamera(template.id);
                              Navigator.pop(context);
                            },
                            onToggleFavorite: () => widget
                                .controller
                                .toggleFavoriteCamera(template.id),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  static final List<String> _brands = <String>[
    ...<String>{
      for (final CameraTemplate template in CameraCatalog.all) template.brand,
    },
  ];
}

class _FilterChip extends StatefulWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final GlPalette p = context.gl;
    final Color border = widget.selected
        ? p.accent
        : (_hover ? p.lineStrong : p.line);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: GlDuration.fast,
          height: 26,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: widget.selected ? p.accentSoft : p.raised,
            borderRadius: BorderRadius.circular(GlRadius.pill),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (widget.icon != null) ...<Widget>[
                Icon(
                  widget.icon,
                  size: 12,
                  color: widget.selected ? p.accentText : p.ink3,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                widget.label,
                style: GlType.caption.copyWith(
                  color: widget.selected ? p.accentText : p.ink2,
                  fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PanelCard extends StatefulWidget {
  const _PanelCard({
    required this.template,
    required this.selected,
    required this.favorite,
    required this.favoriteTooltip,
    required this.onTap,
    required this.onToggleFavorite,
  });

  final CameraTemplate template;
  final bool selected;
  final bool favorite;
  final String favoriteTooltip;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  @override
  State<_PanelCard> createState() => _PanelCardState();
}

class _PanelCardState extends State<_PanelCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final GlPalette p = context.gl;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Center(
            child: GlCameraCard(
              image: CameraCatalog.images[widget.template.id],
              brand: widget.template.brand,
              model: widget.template.model,
              selected: widget.selected,
              onTap: widget.onTap,
            ),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: AnimatedOpacity(
              opacity: (_hover || widget.favorite) ? 1 : 0,
              duration: GlDuration.fast,
              child: IgnorePointer(
                ignoring: !(_hover || widget.favorite),
                child: Tooltip(
                  message: widget.favoriteTooltip,
                  waitDuration: const Duration(milliseconds: 400),
                  child: GestureDetector(
                    onTap: widget.onToggleFavorite,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: p.raised,
                        shape: BoxShape.circle,
                        border: Border.all(color: p.line),
                      ),
                      child: Icon(
                        widget.favorite
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        size: 13,
                        color: widget.favorite ? p.accent : p.ink3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
