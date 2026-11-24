import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'catalog.dart';
import 'controller.dart';
import 'models.dart';
import 'renderer.dart';

const Color kBg = Color(0xFF0C0D0E);
const Color kPanel = Color(0xFF141619);
const Color kCard = Color(0xFF1B1E21);
const Color kCardSoft = Color(0xFF202327);
const Color kLine = Color(0xFF2A2E33);
const Color kText = Color(0xFFF4F1EA);
const Color kMuted = Color(0xFFD0CEC8);
const Color kFaint = Color(0xFFA7ABB0);
const Color kAccent = Color(0xFFFF6A3D);
const Color kAccentSoft = Color(0xFF3A211A);

const List<Color> kBackdrops = <Color>[
  Color(0xFFFFFFFF),
  Color(0xFFF3EEE4),
  Color(0xFFEDE4D8),
  Color(0xFFE2E8EE),
  Color(0xFFE3E8DF),
  Color(0xFFF1E6E3),
  Color(0xFFD8D2C8),
  Color(0xFF393B3D),
];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final GearLabController controller = GearLabController();
  await controller.initialize();
  runApp(GearLabApp(controller: controller));
}

class GearLabApp extends StatelessWidget {
  const GearLabApp({super.key, required this.controller});

  final GearLabController controller;

  @override
  Widget build(BuildContext context) {
    final ThemeData dark = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: kBg,
      colorScheme: const ColorScheme.dark(
        primary: kAccent,
        secondary: kAccent,
        surface: kCard,
        onSurface: kText,
      ),
      textSelectionTheme: const TextSelectionThemeData(cursorColor: kAccent),
      sliderTheme: const SliderThemeData(
        activeTrackColor: kAccent,
        inactiveTrackColor: kLine,
        thumbColor: kAccent,
        overlayColor: Color(0x33FF6A3D),
        trackHeight: 2,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          return states.contains(WidgetState.selected) ? Colors.white : kFaint;
        }),
        trackColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          return states.contains(WidgetState.selected) ? kAccent : kLine;
        }),
        trackOutlineColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: kCardSoft,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: kFaint, fontSize: 14),
      ),
      dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF191B1D)),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF2A2D31),
        contentTextStyle: TextStyle(color: kText),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return MaterialApp(
      title: 'GearLab 器材研究所',
      debugShowCheckedModeBanner: false,
      theme: dark,
      home: HomePage(controller: controller),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.controller});
  final GearLabController controller;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  static const MethodChannel _dropChannel = MethodChannel('gearlab/drag_drop');

  GearLabController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _dropChannel.setMethodCallHandler(_handleDrop);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      c.persistNow();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dropChannel.setMethodCallHandler(null);
    super.dispose();
  }

  Future<void> _handleDrop(MethodCall call) async {
    if (call.method != 'drop') return;
    final List<dynamic> raw = call.arguments is List<dynamic>
        ? call.arguments as List<dynamic>
        : const <dynamic>[];
    final List<String> paths = raw
        .map((dynamic item) => item.toString())
        .where((String path) => path.isNotEmpty)
        .toList(growable: false);
    if (paths.isEmpty) return;
    final int count = await c.addPaths(paths);
    if (!mounted) return;
    _toast(count == 0 ? '未找到可导入的照片' : '已通过拖拽导入 $count 张照片');
  }

  Future<void> _import() async {
    try {
      final int count = await c.pickImages();
      if (!mounted) return;
      if (count > 0) {
        _toast('已导入 $count 张照片');
      }
    } catch (e) {
      if (mounted) _toast('导入失败：$e');
    }
  }

  Future<void> _openExport({ExportScope initialScope = ExportScope.all}) async {
    if (c.selectedPhoto == null) {
      _toast('先导入照片');
      return;
    }
    try {
      final String folder = await c.defaultExportFolder();
      if (!mounted) return;
      final ExportOptions? options = await showDialog<ExportOptions>(
        context: context,
        builder: (BuildContext context) => ExportDialog(
          controller: c,
          initialFolder: folder,
          initialScope: initialScope,
        ),
      );
      if (options == null || !mounted) return;
      await _runExport(options);
    } catch (e, stack) {
      debugPrint('GEARLAB export dialog error: $e\n$stack');
      if (mounted) _toast('无法打开导出面板：$e');
    }
  }

  Future<void> _runExport(ExportOptions options) async {
    try {
      final ExportResult result = await c.export(options);
      if (!mounted) return;
      if (result.files.isEmpty) {
        _toast('导出失败${result.errors.isEmpty ? '' : '：${result.errors.first}'}');
        return;
      }
      await _showExportDone(result);
    } catch (e) {
      if (mounted) _toast('导出失败：$e');
    }
  }

  Future<void> _showExportDone(ExportResult result) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        final bool android = Platform.isAndroid;
        return AlertDialog(
          backgroundColor: const Color(0xFF191B1D),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: <Widget>[
              const Icon(Icons.check_circle, color: Color(0xFF7BC8A4), size: 22),
              const SizedBox(width: 8),
              Text(
                android && result.gallerySaved > 0 ? '已保存到相册' : '导出完成',
                style: const TextStyle(fontSize: 17),
              ),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  android && result.gallerySaved > 0
                      ? '已保存 ${result.gallerySaved} 张到系统相册 · GearLab'
                      : '已生成 ${result.files.length} 个文件',
                  style: const TextStyle(color: kText),
                ),
                if (!android) ...<Widget>[
                  const SizedBox(height: 8),
                  SelectableText(
                    result.folder,
                    style: const TextStyle(color: kMuted, fontSize: 14, height: 1.4),
                  ),
                ],
                if (result.notice != null) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(
                    result.notice!,
                    style: const TextStyle(color: Color(0xFFE7BE78), fontSize: 14, height: 1.4),
                  ),
                ],
                if (android && result.gallerySaved == 0) ...<Widget>[
                  const SizedBox(height: 8),
                  const Text(
                    '相册权限可能未开启；文件仍保留在应用缓存中，可先分享。',
                    style: TextStyle(color: kMuted, fontSize: 14, height: 1.4),
                  ),
                ],
                if (result.errors.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 10),
                  Text(
                    '${result.errors.length} 张失败：${result.errors.first}',
                    style: const TextStyle(color: Color(0xFFE09A8F), fontSize: 14),
                  ),
                ],
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭'),
            ),
            if (android)
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  c.shareFiles(result.files);
                },
                icon: const Icon(Icons.ios_share, size: 16),
                label: const Text('分享'),
              ),
          ],
        );
      },
    );
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text), duration: const Duration(seconds: 2)));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: c,
      builder: (BuildContext context, Widget? _) {
        final bool desktop = MediaQuery.sizeOf(context).width >= 1000;
        final Widget page = CallbackShortcuts(
          bindings: <ShortcutActivator, VoidCallback>{
            const SingleActivator(LogicalKeyboardKey.keyO, control: true): _import,
            const SingleActivator(LogicalKeyboardKey.keyE, control: true): () => _openExport(),
            const SingleActivator(LogicalKeyboardKey.keyS, control: true): () => _openExport(),
            const SingleActivator(LogicalKeyboardKey.arrowLeft): () {
              if (c.selectedIndex > 0) c.selectPhoto(c.selectedIndex - 1);
            },
            const SingleActivator(LogicalKeyboardKey.arrowRight): () {
              if (c.selectedIndex >= 0 && c.selectedIndex < c.photos.length - 1) {
                c.selectPhoto(c.selectedIndex + 1);
              }
            },
            const SingleActivator(LogicalKeyboardKey.delete): () {
              if (c.selectedIndex >= 0) c.removePhoto(c.selectedIndex);
            },
          },
          child: Focus(
            autofocus: true,
            child: Scaffold(
              backgroundColor: kBg,
              body: SafeArea(
                child: Stack(
                  children: <Widget>[
                    desktop ? _buildDesktop() : _buildMobile(),
                    if (c.busy) _ExportProgressOverlay(progress: c.progress, message: c.busyMessage),
                  ],
                ),
              ),
            ),
          ),
        );
        return page;
      },
    );
  }

  Widget _buildDesktop() {
    return Column(
      children: <Widget>[
        TopBar(controller: c, onImport: _import, onExport: () => _openExport(), desktop: true),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 14, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SizedBox(
                  width: 286,
                  child: PhotoRail(controller: c, onImport: _import),
                ),
                const SizedBox(width: 12),
                Expanded(child: PreviewPane(controller: c, onImport: _import)),
                const SizedBox(width: 12),
                SizedBox(
                  width: MediaQuery.sizeOf(context).width >= 1300 ? 468 : 420,
                  child: SettingsPanel(
                    controller: c,
                    onExport: (ExportScope scope) => _openExport(initialScope: scope),
                    embedded: false,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobile() {
    return Column(
      children: <Widget>[
        TopBar(controller: c, onImport: _import, onExport: () => _openExport(), desktop: false),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 96),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.48,
                  child: PreviewPane(controller: c, onImport: _import, compact: true),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 158,
                  child: PhotoRail(
                    controller: c,
                    onImport: _import,
                    horizontal: true,
                  ),
                ),
                const SizedBox(height: 12),
                SettingsPanel(
                  controller: c,
                  onExport: (ExportScope scope) => _openExport(initialScope: scope),
                  embedded: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class TopBar extends StatelessWidget {
  const TopBar({
    super.key,
    required this.controller,
    required this.onImport,
    required this.onExport,
    required this.desktop,
  });

  final GearLabController controller;
  final VoidCallback onImport;
  final VoidCallback onExport;
  final bool desktop;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: desktop ? 68 : 58,
      padding: EdgeInsets.symmetric(horizontal: desktop ? 18 : 12),
      decoration: const BoxDecoration(
        color: kPanel,
        border: Border(bottom: BorderSide(color: kLine)),
      ),
      child: Row(
        children: <Widget>[
          Image.asset('assets/app_icon.png', width: 28, height: 28),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'GEARLAB',
                style: TextStyle(
                  color: kText,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                ),
              ),
              if (desktop)
                const Text(
                  '器材研究所  /  CAMERA STORY',
                  style: TextStyle(color: kFaint, fontSize: 14, letterSpacing: 0.5),
                ),
            ],
          ),
          if (desktop) ...<Widget>[
            const Spacer(),
            const Row(
              children: <Widget>[
                Icon(Icons.shield_outlined, size: 12, color: kFaint),
                SizedBox(width: 5),
                Text('本地处理 · 照片不离开设备', style: TextStyle(color: kMuted, fontSize: 14)),
              ],
            ),
            const Spacer(),
          ] else
            const Spacer(),
          _TopAction(
            icon: Icons.add_photo_alternate_outlined,
            label: desktop ? '导入照片' : '导入',
            onTap: onImport,
          ),
          const SizedBox(width: 8),
          _TopAction(
            icon: Icons.download_rounded,
            label: desktop ? '导出作品' : '导出',
            primary: true,
            onTap: controller.selectedPhoto == null ? null : onExport,
          ),
        ],
      ),
    );
  }
}

class _TopAction extends StatelessWidget {
  const _TopAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;
    return Material(
      color: primary ? (enabled ? kAccent : kLine) : kCard,
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        borderRadius: BorderRadius.circular(7),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 14, color: primary ? Colors.white : kMuted),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: primary ? Colors.white : kMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PhotoRail extends StatelessWidget {
  const PhotoRail({
    super.key,
    required this.controller,
    required this.onImport,
    this.horizontal = false,
  });

  final GearLabController controller;
  final VoidCallback onImport;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final Widget content = horizontal ? _horizontal(context) : _vertical(context);
    if (horizontal) return content;
    return Container(
      decoration: BoxDecoration(
        color: kPanel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kLine),
      ),
      child: content,
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 13, 10, 8),
      child: Row(
        children: <Widget>[
          const Text('照片库', style: TextStyle(color: kText, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          Text(controller.photos.length.toString().padLeft(2, '0'),
              style: const TextStyle(color: kFaint, fontSize: 14)),
          const Spacer(),
          if (controller.photos.isNotEmpty)
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _confirmClear(context),
              child: Container(
                width: 26,
                height: 26,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(color: kCardSoft, borderRadius: BorderRadius.circular(7)),
                child: const Icon(Icons.delete_sweep_outlined, size: 16, color: kMuted),
              ),
            ),
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onImport,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(color: kCardSoft, borderRadius: BorderRadius.circular(7)),
              child: const Icon(Icons.add, size: 16, color: kMuted),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: const Color(0xFF191B1D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('清空照片库', style: TextStyle(fontSize: 18)),
        content: Text(
          '将移除全部 ${controller.photos.length} 张照片（不会删除原图）。',
          style: const TextStyle(fontSize: 14, color: kMuted),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: kAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('清空'),
          ),
        ],
      ),
    );
    if (confirmed == true) controller.clearPhotos();
  }

  Widget _vertical(BuildContext context) {
    return Column(
      children: <Widget>[
        _header(context),
        Expanded(
          child: controller.photos.isEmpty
              ? _emptyRail(context)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(10, 2, 10, 8),
                  itemCount: controller.photos.length,
                  itemBuilder: (BuildContext context, int index) => _PhotoTile(
                    controller: controller,
                    index: index,
                  ),
                ),
        ),
        const Divider(height: 1, color: kLine),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 9, 12, 10),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  controller.selectedPhoto?.name ?? '尚未选择照片',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: kMuted, fontSize: 14),
                ),
              ),
              Text(
                controller.photos.isEmpty ? '本地照片' : '共 ${controller.photos.length} 张',
                style: const TextStyle(color: kFaint, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _horizontal(BuildContext context) {
    return Column(
      children: <Widget>[
        _header(context),
        Expanded(
          child: controller.photos.isEmpty
              ? _emptyRail(context)
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(2, 2, 12, 8),
                  itemCount: controller.photos.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (BuildContext context, int index) => _PhotoTile(
                    controller: controller,
                    index: index,
                    compact: true,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _emptyRail(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.photo_library_outlined, color: kFaint, size: 26),
          const SizedBox(height: 8),
          const Text('还没有照片', style: TextStyle(color: kMuted, fontSize: 14)),
        ],
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.controller,
    required this.index,
    this.compact = false,
  });

  final GearLabController controller;
  final int index;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final PhotoItem item = controller.photos[index];
    final bool selected = controller.selectedIndex == index;
    final CameraTemplate camera = CameraCatalog.find(item.style.cameraId);
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 0 : 8),
      child: Material(
        color: selected ? kAccentSoft : kCard,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
            controller.selectPhoto(index);
          },
          child: Container(
            width: compact ? 170 : null,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: selected ? kAccent : kLine, width: selected ? 1.2 : 1),
            ),
            child: Row(
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: SizedBox(
                    width: compact ? 48 : 72,
                    height: compact ? 48 : 58,
                    child: RawImage(image: item.image, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: kText, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.image.width} × ${item.image.height}  ·  ${camera.model}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: kFaint, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(width: 26, height: 26),
                  tooltip: '删除这张照片',
                  onPressed: () => controller.removePhoto(index),
                  icon: const Icon(Icons.close, size: 16, color: kFaint),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PreviewPane extends StatelessWidget {
  const PreviewPane({
    super.key,
    required this.controller,
    required this.onImport,
    this.compact = false,
  });

  final GearLabController controller;
  final VoidCallback onImport;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final PhotoItem? photo = controller.selectedPhoto;
    return Container(
      decoration: BoxDecoration(
        color: kPanel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kLine),
      ),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 14, 10),
            child: Row(
              children: <Widget>[
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(color: kAccent, shape: BoxShape.circle),
                ),
                const SizedBox(width: 7),
                const Text('预览', style: TextStyle(color: kText, fontSize: 14, fontWeight: FontWeight.w600)),
                if (!Platform.isAndroid) ...<Widget>[
                  const SizedBox(width: 9),
                  const Text('LIVE COMPOSITION', style: TextStyle(color: kFaint, fontSize: 14, letterSpacing: 1.2)),
                ],
                const Spacer(),
                if (photo != null)
                  Text(
                    '完整照片 · ${photo.image.width} × ${photo.image.height}',
                    style: const TextStyle(color: kFaint, fontSize: 14),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: kLine),
          Expanded(
            child: photo == null
                ? _emptyPreview()
                : LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints constraints) {
                      final double aspect = photo.aspect / 2;
                      double width = constraints.maxWidth - (compact ? 20 : 40);
                      double height = width / aspect;
                      final double maxH = constraints.maxHeight - (compact ? 16 : 30);
                      if (height > maxH) {
                        height = maxH;
                        width = height * aspect;
                      }
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.all(compact ? 8 : 14),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  blurRadius: 26,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: SizedBox(
                              width: width,
                              height: height,
                              child: CustomPaint(
                                painter: PosterPainter(
                                  style: controller.currentStyle,
                                  template: controller.template,
                                  photo: photo.image,
                                  camera: CameraCatalog.images[controller.template.id],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _emptyPreview() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: kCardSoft,
                shape: BoxShape.circle,
                border: Border.all(color: kLine),
              ),
              child: const Icon(Icons.camera_outlined, color: kMuted, size: 25),
            ),
            const SizedBox(height: 14),
            const Text(
              '让器材，成为照片的一部分',
              textAlign: TextAlign.center,
              style: TextStyle(color: kText, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 0.5),
            ),
            const SizedBox(height: 7),
            const Text(
              '照片完整展开不裁切；相机区与照片区上下各占一半。',
              textAlign: TextAlign.center,
              style: TextStyle(color: kMuted, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: kAccent),
              onPressed: onImport,
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 16),
              label: const Text('导入照片'),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsPanel extends StatelessWidget {
  const SettingsPanel({
    super.key,
    required this.controller,
    required this.onExport,
    required this.embedded,
  });

  final GearLabController controller;
  final ValueChanged<ExportScope> onExport;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _panelHeader(),
        _section(
          '01',
          '相机模板',
          controller.syncAll ? '全部照片同步' : '仅当前照片',
          _CameraStrip(controller: controller),
        ),
        _divider(),
        _section('02', '标题与文字', null, _TitleFields(controller: controller)),
        _divider(),
        _section('03', '版面', null, _LayoutFields(controller: controller)),
        _divider(),
        _section('04', '相机背景', null, _BackgroundFields(controller: controller)),
        _divider(),
        _section('05', '相机屏幕', null, _ScreenFields(controller: controller)),
        if (embedded) ...<Widget>[
          const SizedBox(height: 14),
          _ExportButtons(controller: controller, onExport: onExport, vertical: true),
          const SizedBox(height: 8),
        ],
      ],
    );
    if (!embedded) {
      return Container(
        decoration: BoxDecoration(
          color: kPanel,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kLine),
        ),
        child: Column(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: content,
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: kLine)),
              ),
              child: _ExportButtons(controller: controller, onExport: onExport),
            ),
          ],
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: kPanel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kLine),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: content,
    );
  }

  Widget _panelHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 13, bottom: 4),
      child: Row(
        children: <Widget>[
          const Text('版面设置', style: TextStyle(color: kText, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          const Text('STYLE', style: TextStyle(color: kFaint, fontSize: 14, letterSpacing: 1.2)),
          const Spacer(),
          const Text('同步全部', style: TextStyle(color: kMuted, fontSize: 14)),
          const SizedBox(width: 6),
          SizedBox(
            height: 22,
            child: FittedBox(
              fit: BoxFit.fill,
              child: Switch(
                value: controller.syncAll,
                onChanged: controller.setSyncAll,
              ),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            borderRadius: BorderRadius.circular(5),
            onTap: controller.resetStyle,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              child: Text('重置', style: TextStyle(color: kMuted, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String number, String title, String? trailing, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(top: 11, bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(number, style: const TextStyle(color: kAccent, fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(width: 7),
              Text(title, style: const TextStyle(color: kText, fontSize: 14, fontWeight: FontWeight.w600)),
              if (trailing != null) ...<Widget>[
                const Spacer(),
                Text(trailing, style: const TextStyle(color: kFaint, fontSize: 14)),
              ],
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _divider() => const Padding(
    padding: EdgeInsets.only(top: 9),
    child: Divider(height: 1, color: kLine),
  );
}

class _CameraStrip extends StatefulWidget {
  const _CameraStrip({required this.controller});
  final GearLabController controller;

  @override
  State<_CameraStrip> createState() => _CameraStripState();
}

class _CameraStripState extends State<_CameraStrip> {
  final ScrollController _scroll = ScrollController();
  bool _canLeft = false;
  bool _canRight = true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_updateArrows);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateArrows());
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _updateArrows() {
    if (!_scroll.hasClients) return;
    final bool left = _scroll.offset > 1;
    final bool right = _scroll.offset < _scroll.position.maxScrollExtent - 1;
    if (left != _canLeft || right != _canRight) {
      setState(() {
        _canLeft = left;
        _canRight = right;
      });
    }
  }

  void _nudge(double delta) {
    if (!_scroll.hasClients) return;
    final double next = (_scroll.offset + delta).clamp(0.0, _scroll.position.maxScrollExtent);
    _scroll.animateTo(next, duration: const Duration(milliseconds: 220), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 102,
      child: Row(
        children: <Widget>[
          _StripArrow(
            icon: Icons.chevron_left,
            enabled: _canLeft,
            onTap: () => _nudge(-250),
          ),
          Expanded(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: <PointerDeviceKind>{
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.trackpad,
                  PointerDeviceKind.stylus,
                },
              ),
              child: Listener(
                onPointerSignal: (PointerSignalEvent event) {
                  if (event is PointerScrollEvent) {
                    final double delta = event.scrollDelta.dx.abs() > event.scrollDelta.dy.abs()
                        ? event.scrollDelta.dx
                        : event.scrollDelta.dy;
                    if (delta != 0 && _scroll.hasClients) {
                      _scroll.jumpTo((_scroll.offset + delta)
                          .clamp(0.0, _scroll.position.maxScrollExtent));
                    }
                  }
                },
                child: Scrollbar(
                  controller: _scroll,
                  thumbVisibility: true,
                  scrollbarOrientation: ScrollbarOrientation.bottom,
                  child: ListView.separated(
                    controller: _scroll,
                    scrollDirection: Axis.horizontal,
                    itemCount: CameraCatalog.all.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (BuildContext context, int index) {
                      final CameraTemplate camera = CameraCatalog.all[index];
                      final bool selected = widget.controller.currentStyle.cameraId == camera.id;
                      return InkWell(
                        borderRadius: BorderRadius.circular(7),
                        onTap: () => widget.controller.setCamera(camera.id),
                        child: Container(
                          width: 108,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: selected ? kAccentSoft : kCard,
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(color: selected ? kAccent : kLine),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(
                                child: CustomPaint(
                                  painter: _CameraThumbPainter(
                                    camera: CameraCatalog.images[camera.id],
                                    template: camera,
                                    photo: widget.controller.selectedPhoto?.image,
                                  ),
                                  child: const SizedBox.expand(),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                camera.brand,
                                style: const TextStyle(color: kFaint, fontSize: 14, letterSpacing: 0.5),
                              ),
                              Text(
                                camera.model,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: kText, fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          _StripArrow(
            icon: Icons.chevron_right,
            enabled: _canRight,
            onTap: () => _nudge(250),
          ),
        ],
      ),
    );
  }
}

class _StripArrow extends StatelessWidget {
  const _StripArrow({required this.icon, required this.enabled, required this.onTap});
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 24, height: 40),
        splashRadius: 16,
        onPressed: enabled ? onTap : null,
        icon: Icon(icon, size: 18, color: enabled ? kMuted : kFaint),
      ),
    );
  }
}

class _CameraThumbPainter extends CustomPainter {
  _CameraThumbPainter({required this.camera, required this.template, required this.photo});

  final ui.Image? camera;
  final CameraTemplate template;
  final ui.Image? photo;

  @override
  void paint(Canvas canvas, Size size) {
    if (camera == null) return;
    final double iw = camera!.width.toDouble();
    final double ih = camera!.height.toDouble();
    final double scale = math.min(size.width / iw, size.height / ih);
    final double aw = iw * scale;
    final double ah = ih * scale;
    final Rect art = Rect.fromLTWH((size.width - aw) / 2, (size.height - ah) / 2, aw, ah);
    canvas.drawImageRect(
      camera!,
      Rect.fromLTWH(0, 0, iw, ih),
      art,
      Paint()..filterQuality = FilterQuality.high,
    );
    final Rect screen = Rect.fromLTWH(
      art.left + template.screen.left * aw,
      art.top + template.screen.top * ah,
      template.screen.width * aw,
      template.screen.height * ah,
    );
    canvas.drawRect(screen, Paint()..color = Colors.black);
    if (photo != null) {
      canvas.save();
      canvas.clipRect(screen);
      final double ps = math.max(screen.width / photo!.width, screen.height / photo!.height);
      final double pw = photo!.width * ps;
      final double ph = photo!.height * ps;
      canvas.drawImageRect(
        photo!,
        Rect.fromLTWH(0, 0, photo!.width.toDouble(), photo!.height.toDouble()),
        Rect.fromLTWH(screen.center.dx - pw / 2, screen.center.dy - ph / 2, pw, ph),
        Paint()..filterQuality = FilterQuality.medium,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _CameraThumbPainter oldDelegate) => true;
}

class _TitleFields extends StatefulWidget {
  const _TitleFields({required this.controller});
  final GearLabController controller;

  @override
  State<_TitleFields> createState() => _TitleFieldsState();
}

class _TitleFieldsState extends State<_TitleFields> {
  late final TextEditingController _title;
  late final TextEditingController _subtitle;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.controller.currentStyle.title);
    _subtitle = TextEditingController(text: widget.controller.currentStyle.subtitle);
    widget.controller.addListener(_sync);
  }

  void _sync() {
    if (!mounted) return;
    final StyleSettings style = widget.controller.currentStyle;
    if (!_titleFocus.hasFocus && _title.text != style.title) {
      _title.text = style.title;
    }
    if (!_subtitleFocus.hasFocus && _subtitle.text != style.subtitle) {
      _subtitle.text = style.subtitle;
    }
  }

  final FocusNode _titleFocus = FocusNode();
  final FocusNode _subtitleFocus = FocusNode();

  @override
  void dispose() {
    widget.controller.removeListener(_sync);
    _title.dispose();
    _subtitle.dispose();
    _titleFocus.dispose();
    _subtitleFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final StyleSettings style = widget.controller.currentStyle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Text('标题', style: TextStyle(color: kMuted, fontSize: 14)),
            const Spacer(),
            const Text('显示', style: TextStyle(color: kFaint, fontSize: 14)),
            const SizedBox(width: 6),
            SizedBox(
              height: 22,
              child: FittedBox(
                fit: BoxFit.fill,
                child: Switch(value: style.showTitle, onChanged: widget.controller.setShowTitle),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        TextField(
          controller: _title,
          focusNode: _titleFocus,
          onChanged: widget.controller.setTitle,
          style: const TextStyle(color: kText, fontSize: 14),
          decoration: InputDecoration(
            hintText: '留空则使用 ${widget.controller.template.displayName}',
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: _subtitle,
          focusNode: _subtitleFocus,
          onChanged: widget.controller.setSubtitle,
          style: const TextStyle(color: kText, fontSize: 14),
          decoration: const InputDecoration(hintText: '地点 · 日期 · 一句话（可选）'),
        ),
      ],
    );
  }
}

class _LayoutFields extends StatelessWidget {
  const _LayoutFields({required this.controller});
  final GearLabController controller;

  @override
  Widget build(BuildContext context) {
    final StyleSettings style = controller.currentStyle;
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            const Text('照片比例', style: TextStyle(color: kMuted, fontSize: 14)),
            const Spacer(),
            const Text('跟随原图', style: TextStyle(color: kFaint, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 7),
        Row(
          children: <Widget>[
            const Text('版面分配', style: TextStyle(color: kMuted, fontSize: 14)),
            const Spacer(),
            const Text('上下 1:1', style: TextStyle(color: kFaint, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 9),
        Row(
          children: <Widget>[
            const Text('相机大小', style: TextStyle(color: kMuted, fontSize: 14)),
            const Spacer(),
            Text('${(style.cameraScale * 100).round()}%',
                style: const TextStyle(color: kMuted, fontSize: 14, fontFamily: 'monospace')),
          ],
        ),
        SizedBox(
          height: 34,
          child: Slider(
            value: style.cameraScale,
            min: 0.34,
            max: 0.72,
            onChanged: controller.setCameraScale,
          ),
        ),
        const Text(
          '照片完整不裁切，隐藏标题也保持上下 1:1。',
          style: TextStyle(color: kFaint, fontSize: 14),
        ),
      ],
    );
  }
}

class _BackgroundFields extends StatelessWidget {
  const _BackgroundFields({required this.controller});
  final GearLabController controller;

  @override
  Widget build(BuildContext context) {
    final Color current = controller.currentStyle.topColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Text('相机背景', style: TextStyle(color: kMuted, fontSize: 14)),
            const Spacer(),
            InkWell(
              borderRadius: BorderRadius.circular(5),
              onTap: () => _pickCustom(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: current,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: inkOn(current).withValues(alpha: 0.28),
                    width: 1.2,
                  ),
                ),
                child: Text(
                  '#${current.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                  style: TextStyle(
                    color: inkOn(current),
                    fontSize: 14,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: kBackdrops.map((Color color) {
            final bool selected = color.toARGB32() == current.toARGB32();
            return InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => controller.setTopColor(color),
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? kAccent : (color.computeLuminance() > .8 ? kLine : const Color(0xFF3B3E42)),
                    width: selected ? 2 : 1,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 6),
        const Text('只影响上半幅；标题会自动选择深色或浅色。', style: TextStyle(color: kFaint, fontSize: 14)),
      ],
    );
  }

  Future<void> _pickCustom(BuildContext context) async {
    final Color? picked = await showDialog<Color>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (BuildContext context) => _ColorPickerDialog(
        initial: controller.currentStyle.topColor,
      ),
    );
    if (picked != null) controller.setTopColor(picked);
  }
}

Color? _parseHex(String input) {
  String value = input.trim().replaceFirst('#', '');
  if (value.length == 3) {
    value = value.split('').map((String c) => '$c$c').join();
  }
  final int? parsed = int.tryParse(value, radix: 16);
  if (parsed == null) return null;
  if (value.length == 6) return Color(0xFF000000 | parsed);
  if (value.length == 8) return Color(parsed);
  return null;
}

String _hexOf(Color color, {bool withAlpha = false}) {
  final String rgb = color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();
  if (!withAlpha) return '#$rgb';
  final String alpha = color.toARGB32().toRadixString(16).padLeft(8, '0').substring(0, 2).toUpperCase();
  return '#$alpha$rgb';
}

class _ColorPickerDialog extends StatefulWidget {
  const _ColorPickerDialog({required this.initial});
  final Color initial;

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  static const Color ink = Color(0xFF202429);
  static const Color secondary = Color(0xFF5C636B);
  static const Color line = Color(0xFFD9DDE3);
  static const Color surface = Color(0xFFFFFFFF);

  late HSVColor _hsv;
  late double _alpha;
  late final TextEditingController _hex;

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.initial);
    _alpha = widget.initial.a;
    _hex = TextEditingController(text: _hexOf(_color));
  }

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  Color get _color => _hsv.withAlpha(_alpha).toColor();

  void _syncHex() {
    final String text = _hexOf(_color);
    if (_hex.text != text) {
      _hex.value = TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
    }
  }

  void _setHSV(HSVColor value) {
    setState(() {
      _hsv = value;
      _syncHex();
    });
  }

  void _setAlpha(double value) {
    setState(() {
      _alpha = value.clamp(0.0, 1.0);
      _syncHex();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFF6F7F9),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 390, maxHeight: 700),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: _color,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: line),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'HEX: ${_hexOf(_color)}',
                    style: const TextStyle(
                      color: ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 20, color: secondary),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _SaturationValueField(
                hsv: _hsv,
                onChanged: (double saturation, double value) {
                  _setHSV(_hsv.withSaturation(saturation).withValue(value));
                },
              ),
              const SizedBox(height: 18),
              const Text('色相', style: TextStyle(color: secondary, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              _HueSlider(
                hue: _hsv.hue,
                onChanged: (double hue) => _setHSV(_hsv.withHue(hue)),
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  const Text('不透明度', style: TextStyle(color: secondary, fontSize: 14)),
                  const Spacer(),
                  Text('${(_alpha * 100).round()}%',
                      style: const TextStyle(color: ink, fontSize: 14, fontFamily: 'monospace')),
                ],
              ),
              const SizedBox(height: 4),
              _AlphaSlider(color: _color, alpha: _alpha, onChanged: _setAlpha),
              const SizedBox(height: 14),
              const Text('HEX', style: TextStyle(color: secondary, fontSize: 14)),
              const SizedBox(height: 5),
              TextField(
                controller: _hex,
                style: const TextStyle(color: ink, fontSize: 16, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: surface,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: line),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: line),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: kAccent, width: 1.4),
                  ),
                  hintText: '#RRGGBB',
                  hintStyle: const TextStyle(color: Color(0xFF9AA1A9), fontSize: 14),
                ),
                onChanged: (String value) {
                  final Color? parsed = _parseHex(value);
                  if (parsed != null) {
                    setState(() {
                      _hsv = HSVColor.fromColor(parsed);
                      _alpha = parsed.a;
                    });
                  }
                },
              ),
              const SizedBox(height: 18),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: secondary,
                        side: const BorderSide(color: line),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消', style: TextStyle(fontSize: 14)),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: kAccent,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      onPressed: () => Navigator.pop(context, _color),
                      child: const Text('使用此颜色', style: TextStyle(fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SaturationValueField extends StatelessWidget {
  const _SaturationValueField({required this.hsv, required this.onChanged});
  final HSVColor hsv;
  final void Function(double saturation, double value) onChanged;

  void _handle(Offset local, Size size) {
    final double s = (local.dx / size.width).clamp(0.0, 1.0);
    final double v = (1 - local.dy / size.height).clamp(0.0, 1.0);
    onChanged(s, v);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size size = Size(constraints.maxWidth, 210);
        return GestureDetector(
          onPanDown: (DragDownDetails details) => _handle(details.localPosition, size),
          onPanUpdate: (DragUpdateDetails details) => _handle(details.localPosition, size),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox.fromSize(
              size: size,
              child: CustomPaint(painter: _SaturationValuePainter(hsv)),
            ),
          ),
        );
      },
    );
  }
}

class _SaturationValuePainter extends CustomPainter {
  _SaturationValuePainter(this.hsv);
  final HSVColor hsv;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor());
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: <Color>[Colors.white, Colors.transparent],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Colors.transparent, Colors.black],
        ).createShader(rect),
    );
    final Offset thumb = Offset(hsv.saturation * size.width, (1 - hsv.value) * size.height);
    canvas.drawCircle(thumb, 8, Paint()..color = Colors.white);
    canvas.drawCircle(
      thumb,
      8,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF202429),
    );
  }

  @override
  bool shouldRepaint(covariant _SaturationValuePainter oldDelegate) => oldDelegate.hsv != hsv;
}

class _HueSlider extends StatelessWidget {
  const _HueSlider({required this.hue, required this.onChanged});
  final double hue;
  final ValueChanged<double> onChanged;

  void _handle(Offset local, double width) {
    onChanged((local.dx / width).clamp(0.0, 1.0) * 360);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        return GestureDetector(
          onPanDown: (DragDownDetails details) => _handle(details.localPosition, width),
          onPanUpdate: (DragUpdateDetails details) => _handle(details.localPosition, width),
          child: SizedBox(
            height: 24,
            child: CustomPaint(painter: _HuePainter(hue)),
          ),
        );
      },
    );
  }
}

class _HuePainter extends CustomPainter {
  _HuePainter(this.hue);
  final double hue;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Rect.fromLTWH(0, 6, size.width, 12);
    final RRect rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
    final List<Color> colors = <Color>[
      for (int i = 0; i <= 6; i++) HSVColor.fromAHSV(1, (i * 60) % 360, 1, 1).toColor(),
    ];
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(colors: colors).createShader(rect),
    );
    final double x = rect.left + (hue / 360) * rect.width;
    canvas.drawCircle(Offset(x, rect.center.dy), 9, Paint()..color = Colors.white);
    canvas.drawCircle(
      Offset(x, rect.center.dy),
      9,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF202429),
    );
  }

  @override
  bool shouldRepaint(covariant _HuePainter oldDelegate) => oldDelegate.hue != hue;
}

class _AlphaSlider extends StatelessWidget {
  const _AlphaSlider({required this.color, required this.alpha, required this.onChanged});
  final Color color;
  final double alpha;
  final ValueChanged<double> onChanged;

  void _handle(Offset local, double width) {
    onChanged((local.dx / width).clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        return GestureDetector(
          onPanDown: (DragDownDetails details) => _handle(details.localPosition, width),
          onPanUpdate: (DragUpdateDetails details) => _handle(details.localPosition, width),
          child: SizedBox(
            height: 24,
            child: CustomPaint(painter: _AlphaPainter(color: color, alpha: alpha)),
          ),
        );
      },
    );
  }
}

class _AlphaPainter extends CustomPainter {
  _AlphaPainter({required this.color, required this.alpha});
  final Color color;
  final double alpha;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Rect.fromLTWH(0, 6, size.width, 12);
    final RRect rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
    canvas.save();
    canvas.clipRRect(rrect);
    const double square = 6;
    for (double x = 0; x < size.width; x += square) {
      for (double y = 6; y < 18; y += square) {
        final bool light = ((x / square).floor() + (y / square).floor()) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, square, square),
          Paint()..color = light ? Colors.white : const Color(0xFFD8DCE1),
        );
      }
    }
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: <Color>[color.withValues(alpha: 0), color.withValues(alpha: 1)],
        ).createShader(rect),
    );
    canvas.restore();
    final double x = rect.left + alpha * rect.width;
    canvas.drawCircle(Offset(x, rect.center.dy), 9, Paint()..color = Colors.white);
    canvas.drawCircle(
      Offset(x, rect.center.dy),
      9,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF202429),
    );
  }

  @override
  bool shouldRepaint(covariant _AlphaPainter oldDelegate) =>
      oldDelegate.alpha != alpha || oldDelegate.color != color;
}

class _ScreenFields extends StatelessWidget {
  const _ScreenFields({required this.controller});
  final GearLabController controller;

  @override
  Widget build(BuildContext context) {
    final StyleSettings style = controller.currentStyle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Text('照片显示', style: TextStyle(color: kMuted, fontSize: 14)),
            const Spacer(),
            _ModePill(
              label: '填充',
              selected: style.screenFit == ScreenFitMode.fill,
              onTap: () => controller.setScreenFit(ScreenFitMode.fill),
            ),
            const SizedBox(width: 5),
            _ModePill(
              label: '完整',
              selected: style.screenFit == ScreenFitMode.fit,
              onTap: () => controller.setScreenFit(ScreenFitMode.fit),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            const Text('屏幕反光', style: TextStyle(color: kMuted, fontSize: 14)),
            const Spacer(),
            SizedBox(
              height: 22,
              child: FittedBox(
                fit: BoxFit.fill,
                child: Switch(value: style.screenGlare, onChanged: controller.setScreenGlare),
              ),
            ),
          ],
        ),
        const Text('默认关闭；开启后更接近真实相机的玻璃质感。', style: TextStyle(color: kFaint, fontSize: 14)),
      ],
    );
  }
}

class _ModePill extends StatelessWidget {
  const _ModePill({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(5),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? kAccentSoft : kCardSoft,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: selected ? kAccent : kLine),
        ),
        child: Text(
          label,
          style: TextStyle(color: selected ? kAccent : kMuted, fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _ExportButtons extends StatelessWidget {
  const _ExportButtons({required this.controller, required this.onExport, this.vertical = false});
  final GearLabController controller;
  final ValueChanged<ExportScope> onExport;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    if (vertical) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: kAccent,
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
            onPressed: controller.selectedPhoto == null
                ? null
                : () => onExport(ExportScope.all),
            child: Text('导出作品  ·  全部 ${controller.photos.length} 张'),
          ),
        ],
      );
    }
    return Row(
      children: <Widget>[
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: kMuted,
              side: const BorderSide(color: kLine),
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
            onPressed: controller.selectedPhoto == null ? null : () => onExport(ExportScope.current),
            child: const Text('导出当前'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: kAccent,
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
            onPressed: controller.selectedPhoto == null
                ? null
                : () => onExport(ExportScope.all),
            child: Text('导出全部 ${controller.photos.length}'),
          ),
        ),
      ],
    );
  }
}

class ExportDialog extends StatefulWidget {
  const ExportDialog({
    super.key,
    required this.controller,
    required this.initialFolder,
    this.initialScope = ExportScope.all,
  });
  final GearLabController controller;
  final String initialFolder;
  final ExportScope initialScope;

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  late ExportScope scope;
  late int width;
  late ExportFormat format;
  late double quality;
  late String folder;

  @override
  void initState() {
    super.initState();
    scope = widget.initialScope == ExportScope.selected ? ExportScope.all : widget.initialScope;
    if (scope == ExportScope.all && widget.controller.photos.isEmpty) {
      scope = ExportScope.current;
    }
    width = 2160;
    format = ExportFormat.jpg;
    quality = 100;
    folder = widget.initialFolder;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF17191B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 570, maxHeight: 720),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Text('导出作品', style: TextStyle(color: kText, fontSize: 19, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 18, color: kMuted),
                  ),
                ],
              ),
              if (!Platform.isAndroid)
                const Text('使用每张照片自己的设置，生成本地作品。', style: TextStyle(color: kMuted, fontSize: 14)),
              const SizedBox(height: 18),
              const _DialogLabel('导出范围'),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _Choice(
                      label: '当前单张',
                      selected: scope == ExportScope.current,
                      onTap: () => setState(() => scope = ExportScope.current),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Choice(
                      label: '全部 ${widget.controller.photos.length} 张',
                      selected: scope == ExportScope.all,
                      onTap: () => setState(() => scope = ExportScope.all),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const _DialogLabel('输出尺寸'),
              Row(
                children: <Widget>[
                  _SizeChoice(label: '1080', sub: '高清', value: 1080, current: width, onTap: (int v) => setState(() => width = v)),
                  const SizedBox(width: 8),
                  _SizeChoice(label: '1440', sub: '2K', value: 1440, current: width, onTap: (int v) => setState(() => width = v)),
                  const SizedBox(width: 8),
                  _SizeChoice(label: '2160', sub: '超清', value: 2160, current: width, onTap: (int v) => setState(() => width = v)),
                ],
              ),
              const SizedBox(height: 16),
              const _DialogLabel('格式'),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _Choice(
                      label: 'JPG\n体积小',
                      selected: format == ExportFormat.jpg,
                      onTap: () => setState(() => format = ExportFormat.jpg),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Choice(
                      label: 'PNG\n无损',
                      selected: format == ExportFormat.png,
                      onTap: () => setState(() => format = ExportFormat.png),
                    ),
                  ),
                ],
              ),
              if (format == ExportFormat.jpg) ...<Widget>[
                const SizedBox(height: 15),
                Row(
                  children: <Widget>[
                    const _DialogLabel('JPG 画质'),
                    const Spacer(),
                    Text('${quality.round()}', style: const TextStyle(color: kText, fontSize: 14, fontFamily: 'monospace')),
                  ],
                ),
                Slider(
                  value: quality,
                  min: 60,
                  max: 100,
                  divisions: 40,
                  onChanged: (double v) => setState(() => quality = v),
                ),
                if (!Platform.isAndroid)
                  const Text('默认 100：最高质量、最低压缩。', style: TextStyle(color: kFaint, fontSize: 14)),
              ],
              const SizedBox(height: 16),
              _DialogLabel(Platform.isAndroid ? '保存到相册' : '保存到'),
              Container(
                padding: const EdgeInsets.fromLTRB(11, 8, 7, 8),
                decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(7), border: Border.all(color: kLine)),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.folder_outlined, size: 15, color: kFaint),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        Platform.isAndroid ? '系统相册 · GearLab' : folder,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: kMuted, fontSize: 14),
                      ),
                    ),

                  ],
                ),
              ),
              if (Platform.isAndroid)
                const Padding(
                  padding: EdgeInsets.only(top: 5),
                  child: Text(
                    '默认保存到系统相册 GearLab，可在相册中直接查看。',
                    style: TextStyle(color: kFaint, fontSize: 14),
                  ),
                ),
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kMuted,
                        side: const BorderSide(color: kLine),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: kAccent,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      onPressed: () {
                        Navigator.pop(
                          context,
                          ExportOptions(
                            scope: scope,
                            width: width,
                            format: format,
                            quality: quality.round(),
                            folder: folder,
                          ),
                        );
                      },
                      icon: const Icon(Icons.download_rounded, size: 16),
                      label: const Text('开始导出'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogLabel extends StatelessWidget {
  const _DialogLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(color: kMuted, fontSize: 14, fontWeight: FontWeight.w600),
  );
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(7),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? kAccentSoft : kCard,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: selected ? kAccent : kLine),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          softWrap: true,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: selected ? kAccent : kMuted,
            fontSize: 14,
            height: 1.25,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _SizeChoice extends StatelessWidget {
  const _SizeChoice({
    required this.label,
    required this.sub,
    required this.value,
    required this.current,
    required this.onTap,
  });

  final String label;
  final String sub;
  final int value;
  final int current;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final bool selected = value == current;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(7),
        onTap: () => onTap(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
          decoration: BoxDecoration(
            color: selected ? kAccentSoft : kCard,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: selected ? kAccent : kLine),
          ),
          child: Column(
            children: <Widget>[
              Text(
                label,
                style: TextStyle(
                  color: selected ? kAccent : kText,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: selected ? kAccent : kFaint, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExportProgressOverlay extends StatelessWidget {
  const _ExportProgressOverlay({required this.progress, required this.message});
  final ExportProgress progress;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.72),
        child: Center(
          child: Container(
            width: 360,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF191B1D),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kLine),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  '正在导出',
                  style: TextStyle(color: kText, fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 14),
                LinearProgressIndicator(
                  value: progress.total <= 0 ? null : progress.value,
                  backgroundColor: kLine,
                  color: kAccent,
                  minHeight: 5,
                ),
                const SizedBox(height: 12),
                Text(
                  message.isEmpty ? progress.message : message,
                  style: const TextStyle(color: kMuted, fontSize: 14),
                ),
                if (progress.currentFile.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    progress.currentFile,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: kFaint, fontSize: 14),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  '${progress.done} / ${progress.total}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: kFaint, fontSize: 14, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
