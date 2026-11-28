# 03 · 重构范围、架构与迁移计划

## 1. 范围与优先级

### 1.1 本期范围

| 领域 | 纳入 | 说明 |
|---|---|---|
| 设计系统 | ✅ | Token、两套主题（浅/深）、字阶、间距、圆角、阴影、图标、动效 |
| 应用壳与响应式 | ✅ | 桌面三栏 / 中型两栏 / 移动单栏；窗口最小尺寸 |
| 组件库 | ✅ | 约 24 个 `Gl*` 组件，替换 main.dart 中 34 个私有 UI 类 |
| 国际化 | ✅ | 中英双语、系统语言跟随、手动切换、持久化 |
| 平台适配 | ✅ | Windows/Android 路径、导入、拖拽、导出目的地、分享、窗口/系统栏 |
| 状态与架构 | ✅ | 控制器拆分、状态 v2、不可变 StyleSettings、照片仓储 |
| 可访问性 | ✅ | 命中区域、语义、焦点、键盘、文字缩放 |
| 性能 | ✅ | 精确 `shouldRepaint`、`RepaintBoundary`、作用域监听、缩略图缓存 |
| 海报/导出算法 | ❌ | 像素输出与文件命名必须逐字节/逐像素保持 |
| 新模板/新功能 | ❌ | 不扩大产品面 |
| 状态管理框架 | ❌ | 保持 `ChangeNotifier` + 组件作用域监听 |

### 1.2 优先级

| 优先级 | 内容 | 原因 |
|---|---|---|
| **P0** | 基线固化、Token/主题、应用壳、组件库、i18n、平台适配、回归测试 | 不完成则无法验收“跨平台一致 + 无回归” |
| **P1** | 高对比度（已在收敛阶段移除）、可访问性、中型断点、Windows 标题栏/最小尺寸、Android edge-to-edge | 平台规范与可用性硬要求 |
| **P2** | 缩略图缓存、色板键盘替代、窗口尺寸记忆（可下期） | 提升项，不阻塞验收 |

---

## 2. 目标架构

### 2.1 依赖规则

```text
presentation  ──▶ design ──▶ domain ◀── data
      │                         ▲
      └──────────▶ app ────────┘
                     │
                  platform（仅在 bootstrap 注入）
```

强制约束：

1. `presentation/`、`design/`、`domain/` **禁止** `import 'dart:io'`、`package:file_picker`、`package:gal`、`package:share_plus`、`package:path_provider`；
2. `domain/` 不依赖 Flutter Material（`dart:ui` 可以，用于 `Color`/`Image`/`Canvas`）；不包含用户可见字符串；
3. `platform/` 实现 domain 定义的端口（Ports），只被 `bootstrap.dart` 与测试工厂 import；
4. `design/` 不依赖 `presentation/` 或 `platform/`；
5. 所有用户可见文案在 `l10n/` ARB；`domain` 返回类型化结果，由 presentation 映射文案。

### 2.2 目标目录

```text
flutter_app/lib/
├── main.dart                         # 仅 runApp(bootstrap())
├── bootstrap.dart                    # 装配 platform / data / controllers / app
├── app/
│   ├── gearlab_app.dart              # MaterialApp、主题、locale、delegates
│   ├── app_scope.dart                # InheritedNotifier/InheritedWidget 作用域
│   ├── app_theme_controller.dart     # ThemeMode + 系统亮度
│   └── app_locale_controller.dart    # Locale? + 系统语言 + 手动覆盖
├── design/
│   ├── tokens/
│   │   ├── gl_colors.dart
│   │   ├── gl_typography.dart
│   │   ├── gl_spacing.dart
│   │   ├── gl_radii.dart
│   │   ├── gl_shadows.dart
│   │   ├── gl_motion.dart
│   │   └── gl_sizes.dart
│   ├── theme/
│   │   ├── gl_theme.dart
│   │   ├── gl_theme_extensions.dart
│   │   └── gl_theme_data.dart
│   ├── responsive/
│   │   ├── gl_breakpoints.dart
│   │   └── gl_size_class.dart
│   └── components/                   # 设计系统组件（无业务依赖）
│       ├── gl_app_bar.dart
│       ├── gl_button.dart
│       ├── gl_icon_button.dart
│       ├── gl_pane.dart
│       ├── gl_section.dart
│       ├── gl_field.dart
│       ├── gl_segmented.dart
│       ├── gl_switch.dart
│       ├── gl_slider.dart
│       ├── gl_choice_card.dart
│       ├── gl_camera_card.dart
│       ├── gl_photo_row.dart
│       ├── gl_photo_strip.dart
│       ├── gl_swatch.dart
│       ├── gl_color_picker.dart
│       ├── gl_dialog.dart
│       ├── gl_sheet.dart
│       ├── gl_toast.dart
│       ├── gl_progress.dart
│       ├── gl_empty_state.dart
│       └── gl_action_bar.dart
├── domain/
│   ├── models/
│   │   ├── camera_template.dart
│   │   ├── style_settings.dart        # immutable + copyWith + clamp
│   │   ├── photo_item.dart            # immutable 元数据 + ui.Image
│   │   ├── export_options.dart
│   │   ├── export_progress.dart
│   │   └── export_result.dart         # 类型化错误/结果，不含文案
│   ├── catalog/
│   │   └── camera_catalog.dart        # 37 模板 + 图片缓存 + find/load
│   ├── poster/
│   │   ├── poster_plan.dart
│   │   ├── poster_painter.dart        # 纯 dart:ui
│   │   └── poster_renderer.dart
│   ├── export/
│   │   ├── export_naming.dart         # 纯函数，可单测
│   │   ├── export_service.dart        # 编码/调度，不含 gallery/share 细节
│   │   └── export_phase.dart
│   └── ports/
│       ├── app_paths.dart
│       ├── image_picker_port.dart
│       ├── drop_target_port.dart
│       ├── photo_store_port.dart
│       ├── export_destination_port.dart
│       ├── share_port.dart
│       ├── window_port.dart
│       ├── system_chrome_port.dart
│       └── preferences_store_port.dart
├── data/
│   ├── state/
│   │   ├── state_codec_v1.dart
│   │   ├── state_codec_v2.dart
│   │   └── state_store.dart
│   ├── photos/
│   │   └── photo_library_store.dart
│   ├── preferences/
│   │   └── preferences_store.dart
│   └── catalog/
│       └── asset_catalog_repository.dart
├── platform/
│   ├── platform_factory.dart          # 唯一 Platform.isWindows/isAndroid 分支
│   ├── windows/
│   │   ├── windows_platform.dart
│   │   ├── windows_paths.dart
│   │   ├── windows_import.dart
│   │   ├── windows_drop_target.dart
│   │   ├── windows_export_destination.dart
│   │   └── windows_window.dart
│   ├── android/
│   │   ├── android_platform.dart
│   │   ├── android_paths.dart
│   │   ├── android_import.dart
│   │   ├── android_export_destination.dart
│   │   ├── android_share.dart
│   │   └── android_system_chrome.dart
│   └── stubs/
│       └── test_platform.dart
├── l10n/
│   ├── app_zh.arb
│   ├── app_en.arb
│   └── generated/                    # gen-l10n 输出（提交或生成，二选一）
└── presentation/
    ├── editor/
    │   ├── editor_controller.dart
    │   ├── editor_page.dart          # shortcuts / lifecycle / 拖拽接线
    │   ├── editor_shell.dart         # 三断点布局
    │   ├── panes/
    │   │   ├── library_pane.dart
    │   │   ├── stage_pane.dart
    │   │   └── inspector_pane.dart
    │   └── sections/
    │       ├── camera_section.dart
    │       ├── title_section.dart
    │       ├── layout_section.dart
    │       ├── background_section.dart
    │       └── screen_section.dart
    ├── export/
    │   ├── export_controller.dart
    │   ├── export_dialog.dart
    │   ├── export_sheet.dart
    │   └── export_progress_dialog.dart
    ├── preferences/
    │   └── display_settings_sheet.dart
    └── common/
        ├── app_messages.dart        # typed result → l10n
        └── keyboard_shortcuts.dart
```

### 2.3 关键设计决策

| 决策 | 方案 | 理由 |
|---|---|---|
| 状态管理 | 保留 `ChangeNotifier`，用 `ListenableBuilder`/`InheritedNotifier` 做作用域订阅 | 不引入新依赖；改动最小；可测试 |
| 主题 | `ThemeExtension<GlPalette>` + `GlTheme.build(brightness, touch)` | 语义 Token 可随主题切换；组件无 `isDark` 分支 |
| 响应式 | `LayoutBuilder` + `GlSizeClass`，只依据 constraints | 平板/横屏/Windows 缩小统一处理；不在 UI 判断平台 |
| 平台差异 | Ports + 三个实现（Windows/Android/Test） | 业务层零平台依赖；测试注入 fake |
| 状态 | v2 增加 `preferences`，v1 兼容读取；写入仍原子 | 语言/主题需要持久化；旧状态不能丢 |
| 渲染 | `PosterPainter` 只 import `dart:ui`；颜色来自 `PosterPalette` 常量 | 去掉 Material 耦合；像素不变 |
| 文案 | ARB + `AppLocalizations`；domain 返回 enum/typed error | 可翻译、可测试、无字符串散落 |
| 图片 | `PhotoItem` 保存 `ui.Image` 原图 + 可选缩略图缓存 | 导出需要原图；列表用缩略图降低绘制成本 |
| 动画 | Token 化 120/180/240ms；`MediaQuery.disableAnimations` 时 0 | 平台规范与无障碍 |

---

## 3. 平台适配层契约

### 3.1 Ports（domain 定义，platform 实现）

```dart
abstract interface class AppPaths {
  Future<String> appDataDirectory();      // 绝对路径；由 platform 实现转换
  Future<String> exportsDirectory();
  Future<String> temporaryDirectory();
  Future<String> defaultExportFolderLabel(); // 仅用于展示，文案在 presentation 组合
}

abstract interface class ImagePickerPort {
  Future<List<String>> pickImageFiles();     // 返回本地路径
  Future<List<String>> pickFolder();         // Windows 支持；Android 返回空
}

abstract interface class DropTargetPort {
  Stream<List<String>> get drops;            // Windows 原生拖拽；Android 空流
}

abstract interface class ExportDestinationPort {
  Future<DestinationResult> commit(List<EncodedFile> files);
}

abstract interface class SharePort {
  Future<void> shareFiles(List<String> paths);
}

abstract interface class WindowPort {
  Future<void> setTitleBarTheme({required bool dark});
  Future<void> setMinimumSize(Size size);
}

abstract interface class SystemChromePort {
  Future<void> apply(Brightness brightness);
}
```

> 说明：Ports 只使用 `String` 与基础类型，不暴露 `dart:io` 的 `Directory`/`File`，这样 domain 可以纯 Dart 单测，平台实现负责路径与 IO 转换。

### 3.2 Windows 实现

- `WindowsPaths`：迁移 `controller.dart:158-175` 的 portable `userdata` 逻辑与 exports 目录查找；保持 `_canWriteFolder` 回退链。
- `WindowsImagePicker`：`file_picker` 文件/文件夹选择。
- `WindowsDropTarget`：包装现有 `MethodChannel('gearlab/drag_drop')`；原生侧不动或仅补充消息。
- `WindowsExportDestination`：把编码文件写入 `exports/`，返回 folder + 文件列表；保持命名/重名规则在 domain。
- `WindowsWindow`：`MethodChannel('gearlab/window')`：
  - `setTitleBarTheme(bool dark)`：原生 `DwmSetWindowAttribute(DWMWA_USE_IMMERSIVE_DARK_MODE)`；
  - `setMinimumSize(width,height)`：原生处理 `WM_GETMINMAXINFO`；
  - 原生侧当前 `win32_window.cpp` 的 `UpdateTheme` 仅按系统注册表；增加 App 请求覆盖，App 主题变化时调用。
- `SharePort`：Windows 目前不分享，返回 no-op 或保留现有行为（需在 Phase 5 验证）。

### 3.3 Android 实现

- `AndroidPaths`：`getApplicationSupportDirectory()`/临时目录；保持私有目录。
- `AndroidImagePicker`：`file_picker`，仅图片。
- `AndroidExportDestination`：写临时文件 → `Gal.putImage(path, album: 'GearLab')`；逐张记录成功/失败；返回 `gallerySaved`、`errors`；分享仍由 `SharePort` 调用 `share_plus`。
- `AndroidSystemChrome`：edge-to-edge + 状态栏/导航栏图标明暗；`AnnotatedRegion<SystemUiOverlayStyle>` 由 App 统一设置。
- 返回/预测性返回：`PopScope(canPop: ...)` 在编辑页处理“关闭浮层 → 退出”；manifest 增 `android:enableOnBackInvokedCallback="true"`（API 33+）；`MainActivity` 保持 FlutterActivity，必要时在 `onCreate` 调 `WindowCompat.setDecorFitsSystemWindows(window, false)`。
- 不改变相册目录、文件名、导出尺寸/格式/画质。

### 3.4 测试实现

`TestPlatform` 用临时目录、fixture 列表、可控 drop stream、记录调用的 fake（`FakeExportDestination`、`FakeShare`、`FakeWindow`），使 domain/controller 可在纯 Dart 测试中运行。

---

## 4. 状态 Schema v2 与迁移

### 4.1 v1（现状，必须兼容读取）

```json
{
  "version": 1,
  "syncAll": true,
  "selectedIndex": 0,
  "currentStyle": {
    "cameraId": "ricoh-gr4",
    "cameraScale": 0.5,
    "showTitle": true,
    "title": "",
    "subtitle": "",
    "screenFit": "fill",
    "screenGlare": false,
    "topColor": 4294967295
  },
  "photos": [
    {"path": "...", "name": "...", "managed": true, "style": {...}}
  ]
}
```

### 4.2 v2

```json
{
  "version": 2,
  "preferences": {
    "themeMode": "system",      // system | light | dark
    "locale": null               // null = system；"zh" | "en"
  },
  "syncAll": true,
  "selectedIndex": 0,
  "currentStyle": {...},
  "photos": [...]
}
```

规则：

- `themeMode` 默认 `system`；`locale` 默认 `null`。
- 读取 v1：所有原字段照旧；preferences 使用默认值；不重写文件，直到用户修改设置或下一次正常保存（随后写 v2）。
- 读取未知/损坏：保持现状的“忽略并从空状态启动”，但记录 `debugPrint`；不弹错误。
- 写入：仍使用 `.tmp` + rename；仍 350ms debounce；退出同步写。
- 旧版 App 读取 v2：当前 `_restoreState` 不校验 `version`，会忽略 `preferences` 并正常读取照片/样式；因此回退到旧版不会破坏编辑数据（会丢失主题/语言偏好，可接受）。
- 状态文件位置不变：`<appData>/state.json`；照片库不变：`<appData>/photos/`。

### 4.3 模型不可变化

```dart
@immutable
class StyleSettings {
  const StyleSettings({
    this.cameraId = 'ricoh-gr4',
    this.cameraScale = 0.50,
    this.showTitle = true,
    this.title = '',
    this.subtitle = '',
    this.screenFit = ScreenFitMode.fill,
    this.screenGlare = false,
    this.topColor = const Color(0xFFFFFFFF),
  });
  StyleSettings copyWith({...});
  StyleSettings clamped();
  String get resolvedTitle => title.trim().isEmpty
      ? CameraCatalog.find(cameraId).displayName
      : title;
}
```

`PhotoItem` 的元数据 final；`ui.Image` 仍由 controller 管理生命周期；替换 photo 时用 `copyWith`，避免就地修改导致 `shouldRepaint` 失效。

---

## 5. i18n 与主题接线

### 5.1 MaterialApp

```dart
MaterialApp(
  onGenerateTitle: (context) => context.l10n.appTitle,
  locale: localeController.locale,          // null = follow system
  supportedLocales: const [Locale('zh'), Locale('en')],
  localizationsDelegates: const [
    AppLocalizations.delegate,
    ...GlobalMaterialLocalizations.delegates, // from material_ui
  ],
  localeResolutionCallback: resolveLocale,  // zh*→zh, en*→en, other→en
  theme: GlTheme.light,
  darkTheme: GlTheme.dark,
  themeMode: themeController.themeMode,
  builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: systemOverlayStyle(context),
    child: child!,
  ),
)
```

主题：

- 仅两套色板：`brightness == dark ? GlTheme.dark : GlTheme.light`，`themeMode` 覆盖系统亮度；
- 原计划的高对比度能力（`contrastMode` 持久化、系统高对比度监听、`hcLight`/`hcDark` 色板）已在收敛阶段移除，不再出现在主题构建与状态 schema 中；
- 主题切换后调用 `WindowPort.setTitleBarTheme`（Windows）与 `SystemChromePort.apply`（Android）。

### 5.2 ARB 规则

- 模板 `app_zh.arb`，英文 `app_en.arb`；key 使用语义名（`libraryTitle`、`exportAllCount`）；
- 占位符/复数：`{count, plural, ...}`；不拼接句子；
- domain 错误枚举 → presentation 映射；
- 导出文件名、相机型号、ARB 中品牌名不翻译；
- 语言切换即时生效（`MaterialApp.locale` 变化即可）。

示例：

```json
{
  "@@locale": "zh",
  "libraryTitle": "照片库",
  "libraryCount": "{count, plural, other{{count} 张}}",
  "exportAllCount": "导出全部 {count} 张",
  "exportSavedToGallery": "已保存 {count} 张到系统相册 GearLab",
  "errorUnsupportedImage": "不支持的图片格式：{name}"
}
```

---

## 6. 分阶段迁移

> 估算按 1 名熟悉 Flutter 的工程师计算；每个阶段结束都必须可运行、可回退。实际执行时可合并提交，但不得跳过 Gate。

### Phase 0 · 基线固化（0.5 天）

产出：

- `test/regression/poster_golden_test.dart`：用现有 renderer + fixture 相机/照片，1080 宽渲染，保存 `test/goldens/poster_1080.png`；记录 SHA-256。
- `test/fixtures/state_v1.json`：真实 v1 状态（sanitize 路径），作为迁移 fixture。
- `test/regression/export_naming_test.dart`：覆盖文件名、去重、格式/尺寸。
- `docs/ui-refactor/baseline/`：当前 Windows 1360×860、Android 390×844 截图与关键尺寸记录。
- `flutter test` 全绿，golden 生成。

Gate：golden 在改动 renderer 前通过；记录文件 hash 到测试注释。

### Phase 1 · 设计系统骨架（1.5 天）

产出：

- `design/tokens/*`、`design/theme/*`、`design/responsive/*`；
- `GlPalette` ThemeExtension + `GlTheme.build` 两套（浅/深）；
- 字阶 helper（`GlType`/`context.gl.type`）；
- 对比度自检脚本（Dart 测试遍历浅/深两套色板的关键配对）；
- `preview.html` 与最终预览作为视觉参考，不参与运行时。

Gate：`flutter analyze`、`flutter test`；两套主题可构建；色板对比度测试通过；现有 UI 仍运行（此阶段不切换页面）。

### Phase 2 · 应用壳与三断点布局（2 天）

产出：

- `app/`、`bootstrap.dart`、`EditorPage`/`EditorShell`；
- `GlAppBar`、`GlPane`、`GlActionBar`、`GlEmptyState`；
- 桌面三栏/中型两栏/移动单栏骨架；移动五 Tab；
- **先机械搬移** `TopBar`/`PhotoRail`/`PreviewPane`/`SettingsPanel` 到 `presentation/editor/*`，只改 import 与回调接线，不改内部视觉；让新壳层可以立即承载旧内容；
- 接入现有 `GearLabController`（只读/回调），业务逻辑不动；
- 顶栏语言/主题按钮先用占位回调；主题仍用旧深色值，避免半套视觉混用。

Gate：三个断点结构可用；导入/选择/删除/导出路径仍可用；快捷键/拖拽仍可用；`flutter test`；允许暂时沿用旧配色，但布局与信息层级需按新壳层稳定。

### Phase 3 · 组件库与全部页面区域（2 天）

产出：

- `design/components/*` 全部组件 + widget/golden 测试；
- `library_pane`、`stage_pane`、`inspector_pane` 及五个 section；
- 照片行/胶片卡、相机卡、色板、分段、滑杆、开关、字段、按钮；
- `GlColorPickerDialog`（含键盘焦点/HEX/预设等价路径）；
- `ExportDialog`/`ExportSheet`/`ExportProgressDialog`；
- 删除 main.dart 中对应私有类。

Gate：`main.dart` 行数降至 <100（仅 bootstrap）；无 `Color(0x...)` 在 presentation；所有组件状态截图；导出对话框/进度/结果行为不变。

### Phase 4 · 国际化（1 天）

产出：

- 直接依赖 `flutter_localizations` + `intl`；`l10n.yaml`、`app_zh.arb`、`app_en.arb`；
- `AppLocalizations` 接入 `MaterialApp`；
- 清除 lib 内 814 个硬编码中文字符（renderer 内容色/相机名/允许的内容常量除外）；
- 语言菜单/设置；系统语言跟随 + 手动覆盖持久化；
- 英文布局检查（按钮不裁切、字段可换行）。

Gate：中英文完整走通导入→编辑→导出；ARB key 对齐测试；`rg '[\u4e00-\u9fff]' lib --glob '!l10n/**'` 只剩允许的注释/内容常量；语言切换不重启。

### Phase 5 · 平台适配与窗口/系统栏（1 天）

产出：

- `platform/` ports + Windows/Android 实现 + `TestPlatform`；
- 拆分 `GearLabController` 中路径/导入/拖拽/导出/分享/平台判断；
- Windows 原生：最小 960×640、标题栏明暗跟随、拖拽通道包装；
- Android：edge-to-edge、状态栏/导航栏图标、返回/预测性返回、SafeArea；
- 平台差异只在 `platform_factory.dart`。

Gate：`rg "Platform\.|dart:io|file_picker|gal|share_plus|path_provider" lib/presentation lib/domain lib/design` 为 0；Windows/Android 手工验证；fake platform 单测通过。

### Phase 6 · 控制器拆分、状态 v2、性能与可访问性（1.5 天）

产出：

- `EditorController` / `ExportController` / `PreferencesController`；
- `StateCodecV1/V2`、`StateStore`、迁移测试；
- `StyleSettings` immutable、`PhotoItem` copyWith；
- 作用域 `ListenableBuilder`、`RepaintBoundary`（舞台/照片行）、精确 `shouldRepaint`；
- 缩略图缓存（最长边 520，导出仍用原图）；
- 全量 Semantics/焦点顺序/键盘遍历/命中区域；文字缩放 1.5/2.0 测试；
- 删除 `GearLabController` facade。

Gate：poster golden 逐像素不变；导出文件名/结果一致；状态 v1→v2 迁移测试；性能 profile（拖动滑杆不重建整页）；无障碍手工清单。

### Phase 7 · 验收、文档与发布（0.5 天）

产出：

- 全量截图（Windows 1360×860、1440×900；Android 390×844，明/暗/中/英）；
- `05-test-acceptance.md` 手工清单打勾；
- 更新根 README/项目 README 的 UI 部分；
- `flutter analyze` 0 issue；`flutter test` 全绿；release 构建通过。

Gate：验收标准全部满足；风险清单复核；用户确认。

### 阶段依赖图

```text
Phase 0 ──▶ Phase 1 ──▶ Phase 2 ──▶ Phase 3 ──▶ Phase 4
                                      │
                                      ├──▶ Phase 5
                                      └──▶ Phase 6 ──▶ Phase 7
```

Phase 4 与 Phase 5 可以并行（i18n 与平台适配互不依赖），Phase 6 依赖 Phase 3/5。

---

## 7. 提交、回滚与验收门

### 7.1 提交策略

- 每个 Phase 至少一个独立 commit，message 带阶段前缀：`ui-refactor(p2): app shell and breakpoints`；
- 不在同一 commit 中混合“重构”和“行为变更”；
- 每阶段结束运行：`flutter analyze`、`flutter test`、`flutter build windows --release`（至少 P2/P5/P7）、`flutter build apk --release`（至少 P5/P7）；
- 截图存 `docs/ui-refactor/screens/<phase>/`，便于对比。

### 7.2 回滚

| 阶段 | 回滚方式 | 数据风险 |
|---|---|---|
| P0–P5 | `git revert` 该阶段提交；业务逻辑未迁移，状态仍 v1 | 无 |
| P6 | 回退后 v1 代码仍能读取 v2 状态（当前 restore 不校验 version，忽略 preferences） | 仅丢失主题/语言偏好 |
| 任意阶段 | 保留旧 `GearLabController` 直到 P6 结束 | 低 |

### 7.3 每阶段“不可越过”的红线

1. 海报 golden 像素变化 → 停；
2. 导出文件数量/命名/尺寸/格式/画质变化 → 停；
3. Windows `userdata` 或 Android 相册行为变化 → 停；
4. 状态恢复丢失照片或样式 → 停；
5. `flutter analyze` 出现 issue 或既有测试失败 → 停。

---

## 8. 需要新增/修改的工程配置

| 文件 | 变更 |
|---|---|
| `pubspec.yaml` | 新增 `flutter_localizations`（sdk）、`intl`；`flutter: generate: true`；不新增状态管理/UI 库 |
| `l10n.yaml` | 新增；ARB 目录/模板/输出类 |
| `windows/runner/win32_window.cpp` | 支持 `WM_GETMINMAXINFO` 最小尺寸；导出方法或消息 |
| `windows/runner/flutter_window.cpp` | 注册 `gearlab/window` MethodChannel；处理标题栏主题/最小尺寸 |
| `windows/CMakeLists.txt` | 若需要，确认 dwmapi 链接（已链接） |
| `android/app/src/main/AndroidManifest.xml` | `android:enableOnBackInvokedCallback="true"`；其余图标/label 保持 |
| `android/app/src/main/kotlin/.../MainActivity.kt` | 如需 edge-to-edge 兼容，增加 `WindowCompat` 调用；否则 Dart 端 `SystemChrome` 即可 |
| `README.md` / `flutter_app/README.md` | 更新 UI/主题/语言说明与构建命令 |

> 版本控制注意：开始实现前先确认当前 `.github/workflows/macos.yml` 的删除是否要一并提交或还原；本次重构不触碰该文件。

---

## 9. 工作量与交付节奏

| 阶段 | 估时 | 可演示结果 |
|---|---:|---|
| P0 | 0.5d | 基线 golden/截图，证明后续未破坏 |
| P1 | 1.5d | 两套主题、Token、对比度测试 |
| P2 | 2d | 新应用壳 + 三断点，业务可用 |
| P3 | 2d | 组件库 + 全部面板/对话框，视觉完成 |
| P4 | 1d | 中英文切换完整 |
| P5 | 1d | Windows/Android 平台行为收口 |
| P6 | 1.5d | 控制器/状态/性能/无障碍 |
| P7 | 0.5d | 验收截图、文档、构建 |
| **合计** | **~10 天** | 可分 4 次演示：P0/P1、P2、P3/P4、P5/P6/P7 |

实际编码时按 Phase 顺序推进；若某阶段出现 golden 或导出回归，优先修复而不是继续叠加新改动。
