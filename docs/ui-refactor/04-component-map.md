# 04 · 组件映射与改造清单

## 1. 映射总则

- `main.dart` 现有 **34 个 UI 类 / 2840 行**，其中 30 个是私有 widget 或 painter；重构后全部收敛到 `design/components`（可复用）与 `presentation/*`（业务页面）。
- 组件只接受**数据与回调**，不直接读 `GearLabController`；页面负责把 controller 状态转成组件参数。
- 所有组件颜色/字体/间距/圆角来自 `Theme.of(context)` 或 `context.gl`；组件文件内不允许色值/字号字面量（painter 的颜色通过参数传入）。
- 每个组件同时落地 default/hover/pressed/focus/selected/disabled/error 状态中的适用项；状态矩阵见 `02-design-system.md` 第 7 节。

## 2. 现有类 → 新组件映射

| # | 现有类（`lib/main.dart`） | 行范围 | 新位置 | 改造要点 |
|---:|---|---|---|---|
| 1 | `main()` | 36–41 | `bootstrap.dart` | 装配 platform/data/controllers 后 `runApp` |
| 2 | `GearLabApp` | 43–107 | `app/gearlab_app.dart` | 两套主题、locale、delegates、`onGenerateTitle`；删除硬编码深色 ThemeData |
| 3 | `HomePage` / `_HomePageState` | 109–455 | `presentation/editor/editor_page.dart` + `editor_shell.dart` | 只保留快捷键/生命周期/拖拽接线；布局交给 `EditorShell` |
| 4 | `TopBar` | 456–539 | `design/components/gl_app_bar.dart` | 56/52 高；语言/主题/更多菜单；窗口拖拽区（Windows）可选 |
| 5 | `_TopAction` | 540–584 | `GlButton` + `GlIconButton` | 导入 secondary、导出 secondary（顶栏不再放 primary，实心导出只在底部操作栏）；命中区域 |
| 6 | `PhotoRail` | 585–772 | `presentation/editor/panes/library_pane.dart` | 桌面竖列表，移动横向胶片；空状态/计数/清除/导入 |
| 7 | `_PhotoTile` | 773–864 | `GlPhotoRow` / `GlPhotoStripCard` | 真实序号、缩略图、选中 2px 左条、hover 删除、Semantics |
| 8 | `PreviewPane` | 865–1032 | `presentation/editor/panes/stage_pane.dart` | crop marks、作品投影、尺寸/比例/格式信息；空状态 CTA |
| 9 | `SettingsPanel` | 1033–1204 | `presentation/editor/panes/inspector_pane.dart` | 桌面整列；移动 Tab；同步/重置；sticky 导出条 |
| 10 | `_CameraStrip` / `_CameraStripState` | 1205–1427 | `GlCameraStrip` | 横向滚动、箭头、滚轮/拖动、键盘；37 模板 |
| 11 | `_StripArrow` | 1428–1452 | `GlStripArrow` | 24 视觉 / 32+ 命中；disabled/hover/focus |
| 12 | `_CameraThumbPainter` | 1453–1518 | `design/components/camera_thumb_painter.dart` | 保留自绘；`shouldRepaint` 精确比较模板/选中/尺寸；加 `Semantics` 外层 |
| 13 | `_TitleFields` | 1519–1611 | `presentation/editor/sections/title_section.dart` | `GlField` ×2；字数提示；焦点/错误；标题自动回退相机名 |
| 14 | `_LayoutFields` | 1612–1668 | `layout_section.dart` | `GlInfoRow` + `GlSlider`；静态比例信息；滑杆键盘步进 |
| 15 | `_BackgroundFields` | 1669–1785 | `background_section.dart` | `GlSwatchPicker`、HEX chip、自定义按钮；8 预设 + 当前值 |
| 16 | `_ColorPickerDialog` | 1786–2015 | `GlColorPickerDialog` | 亮/暗主题；键盘焦点；SV/HEX/预设等价路径；取消/确定 |
| 17 | `_SaturationValueField` | 2016–2049 | `GlSvField` | 位置→颜色映射保持；语义 value/label |
| 18 | `_SaturationValuePainter` | 2050–2098 | `GlSvPainter` | 颜色通过参数；`shouldRepaint` 比较颜色/尺寸 |
| 19 | `_HueSlider` | 2099–2127 | `GlHueSlider` | 键盘左右键 1%/10%；语义 |
| 20 | `_HuePainter` | 2128–2164 | `GlHuePainter` | 主题无关；精确重绘 |
| 21 | `_AlphaSlider` | 2165–2200 | `GlAlphaSlider` | 棋盘底与主题解耦；键盘 |
| 22 | `_AlphaPainter` | 2201–2254 | `GlAlphaPainter` | 精确重绘 |
| 23 | `_ScreenFields` | 2255–2307 | `screen_section.dart` | `GlSegmentedControl` + `GlSwitch`；fill/fit、反光 |
| 24 | `_ModePill` | 2308–2342 | `GlSegmentedControl` | 移除独立 pill 实现 |
| 25 | `_ExportButtons` | 2343–2405 | `GlActionBar` | 桌面检查器底部/移动底栏共用；主次按钮 |
| 26 | `ExportDialog` / `_ExportDialogState` | 2406–2656 | `presentation/export/export_dialog.dart` + `export_sheet.dart` | 分段：范围/尺寸/格式/画质/目录；移动 Sheet；`GlChoiceCard` |
| 27 | `_DialogLabel` | 2657–2671 | `GlFieldLabel` | 统一 label 字阶 |
| 28 | `_Choice` | 2672–2712 | `GlChoiceCard` | selected 2px 边框 + 勾 + accentSoft |
| 29 | `_SizeChoice` | 2713–2770 | `GlChoiceCard.size` | 数值 tabular；selected 状态 |
| 30 | `_ExportProgressOverlay` | 2771–2840 | `GlProgressDialog` / `GlToast` | 遮罩、进度、当前文件、计数；完成/错误 |
| 31 | `_showExportDone` 内联 `AlertDialog` | `main.dart:323` 附近 | `GlResultDialog` | 文件数/目录/错误/相册/降级提示；l10n |
| 32 | `_toast` / `ScaffoldMessenger` 调用 | `main.dart` 内 | `AppMessages` + `GlToast` | 类型化消息映射；错误不丢细节 |
| 33 | `kBackdrops` / `kAccent` 等常量 | 14–34 | `design/tokens` + domain poster palette | UI 色与海报内容色分离 |
| 34 | 单套 `ThemeData` | 50–99 | `design/theme/gl_theme.dart` | 两套主题 + 组件主题 |

## 3. 新组件清单与 API 草案

| 组件 | 关键参数 | 复用位置 | 备注 |
|---|---|---|---|
| `GlAppBar` | `title`, `leading`, `center`, `actions`, `height` | 桌面/移动顶栏 | 透明/纸面背景；可选 Windows 拖动区 |
| `GlButton` | `label`, `icon`, `variant`, `size`, `onPressed`, `loading` | 顶栏、检查器、导出、空状态 | primary/secondary/quiet/danger；loading 防重复提交 |
| `GlIconButton` | `icon`, `tooltip`, `semanticLabel`, `onPressed`, `size` | 导入、清除、删除、箭头、更多 | 40/44 命中区 |
| `GlPane` | `header`, `trailing`, `child`, `padding`, `scrollable` | 照片库/舞台/检查器 | 0 圆角；1px 分割；无卡片阴影 |
| `GlSection` | `title`, `trailing`, `children`, `dense` | 检查器五分区 | 无 01–05 编号；可选 icon |
| `GlField` | `label`, `hint`, `value`, `onChanged`, `maxLength`, `errorText` | 标题/副标题、HEX | 受控；焦点/错误状态 |
| `GlSegmentedControl<T>` | `value`, `segments`, `onChanged` | 填满/完整、尺寸、格式 | 键盘方向键；≥3 段可滚动 |
| `GlSwitchRow` | `label`, `value`, `onChanged`, `description` | 显示标题、反光、同步全部 | 整行可点 |
| `GlSlider` | `value`, `min`, `max`, `divisions`, `label`, `onChanged` | 相机大小、JPG 画质 | 键盘步进；数值 tabular |
| `GlChoiceCard` | `label`, `subLabel`, `selected`, `onTap`, `leading` | 导出范围/尺寸/格式 | 2px 选中边框 + 勾 |
| `GlCameraCard` | `template`, `selected`, `onTap`, `image` | 相机模板条 | 74×88 / 96×104；序号/品牌/型号 |
| `GlPhotoRow` | `index`, `thumbnail`, `name`, `meta`, `selected`, `onTap`, `onDelete` | 桌面照片库 | 64 高；`Semantics(selected:)` |
| `GlPhotoStripCard` | `index`, `thumbnail`, `selected`, `onTap` | 移动胶片条 | 78×58；删除在长按菜单 |
| `GlCameraStrip` | `items`, `selectedId`, `onSelected`, `onScroll` | 检查器相机区 | 箭头/滚轮/拖动；空状态 |
| `GlSwatch` | `color`, `selected`, `onTap`, `semanticLabel` | 背景预设 | 选中双环；不靠颜色单独表达 |
| `GlSwatchPicker` | `colors`, `selected`, `onSelected`, `onCustom` | 背景区 | Wrap；8 色 + 自定义 |
| `GlColorPickerDialog` | `initial`, `onConfirm` | 自定义背景色 | 亮/暗；HEX/预设/键盘；取消返回 null |
| `GlDialog` | `title`, `content`, `actions`, `maxWidth` | 导出、结果、显示设置 | 12 圆角；overlay 阴影；焦点陷阱 |
| `GlSheet` | `title`, `child`, `actions` | 移动导出/设置 | 全宽、底部安全区 |
| `GlActionBar` | `secondary`, `primary`, `note` | 检查器底部、移动底栏 | 56/64；主次按钮宽度规则 |
| `GlProgressDialog` | `title`, `progress`, `message`, `currentFile` | 导出中 | 可取消；语义进度 |
| `GlResultDialog` | `title`, `message`, `details`, `actions` | 导出完成/失败 | 错误明细可滚动 |
| `GlToast` | `message`, `kind`, `action` | 导入/保存提示 | live region；3s/可关闭 |
| `GlEmptyState` | `icon`, `title`, `body`, `action` | 空照片库/空舞台 | 简洁，不画插画 |
| `GlInfoRow` | `label`, `value`, `strong` | 版面/屏幕信息 | 两端对齐；tabular |
| `GlStripArrow` | `direction`, `onPressed`, `enabled` | 模板条/胶片条 | 命中区 ≥40 |
| `CameraThumbPainter` | `asset`, `selected`, `size` | 相机卡 | 复用现有绘制逻辑，主题无关 |
| `GlSvPainter` / `GlHuePainter` / `GlAlphaPainter` | 纯颜色/尺寸 | 取色器 | 精确 `shouldRepaint` |

## 4. 改造清单（按 Phase）

### P0 · 基线

- [ ] `poster_golden_test.dart` + `test/goldens/poster_1080.png`
- [ ] `state_v1.json` fixture
- [ ] `export_naming_test.dart`
- [ ] 当前 Windows/Android 截图与尺寸记录
- [ ] 记录 golden SHA-256，加入 README

### P1 · 设计系统

- [ ] `gl_colors.dart`（两套语义色）
- [ ] `gl_typography.dart`（显示/标题/标题/正文/标签/元数据/数字）
- [ ] `gl_spacing.dart` / `gl_radii.dart` / `gl_shadows.dart` / `gl_motion.dart` / `gl_sizes.dart`
- [ ] `gl_theme_extensions.dart` + `gl_theme.dart`
- [ ] 对比度测试（Light/Dark × 关键配对）
- [ ] 字体 tabular figures 工具
- [ ] 平台密度（Windows compact / Android comfortable）

### P2 · 壳层

- [ ] `bootstrap.dart` + `app/gearlab_app.dart`
- [ ] `EditorPage`（快捷键/生命周期/拖拽）
- [ ] `EditorShell`（compact/medium/expanded/large）
- [ ] `GlAppBar`、`GlPane`、`GlActionBar`、`GlEmptyState`
- [ ] 移动五 Tab 的壳
- [ ] 顶栏语言/主题菜单占位
- [ ] Windows 最小窗口 960×640（原生）

### P3 · 页面与组件

- [ ] `LibraryPane` + `GlPhotoRow` + `GlPhotoStripCard`
- [ ] `StagePane` + crop marks + 作品投影
- [ ] `InspectorPane` + 五个 section
- [ ] `GlCameraStrip` + `GlCameraCard` + `GlStripArrow`
- [ ] `TitleSection` + `GlField`
- [ ] `LayoutSection` + `GlSlider` + `GlInfoRow`
- [ ] `BackgroundSection` + `GlSwatchPicker` + `GlHexChip`
- [ ] `GlColorPickerDialog` + 三个 painter
- [ ] `ScreenSection` + `GlSegmentedControl` + `GlSwitchRow`
- [ ] `GlActionBar`
- [ ] `ExportDialog` / `ExportSheet` / `GlChoiceCard`
- [ ] `GlProgressDialog` / `GlResultDialog` / `GlToast`
- [ ] 删除 main.dart 对应私有类，`main.dart` 仅 bootstrap

### P4 · i18n

- [ ] `flutter_localizations` + `intl` 直接依赖
- [ ] `l10n.yaml` + `app_zh.arb` + `app_en.arb`
- [ ] 所有 UI/错误/toast 文案迁移
- [ ] 语言跟随系统 + 手动覆盖 + 持久化
- [ ] 英文布局/字数检查
- [ ] ARB key 对齐测试；CJK 残留检查

### P5 · 平台

- [ ] `AppPaths` / `ImagePickerPort` / `DropTargetPort` / `ExportDestinationPort` / `SharePort` / `WindowPort` / `SystemChromePort`
- [ ] `WindowsPlatform` + `AndroidPlatform` + `TestPlatform`
- [ ] 迁移 controller 的路径/导入/导出目的地/分享/Platform 判断
- [ ] Windows 标题栏主题 + 最小尺寸原生实现
- [ ] Android edge-to-edge/系统栏/返回/预测性返回
- [ ] `platform_factory.dart` 唯一平台分支

### P6 · 状态/性能/无障碍

- [ ] `StateCodecV1/V2` + `StateStore`
- [ ] `StyleSettings` immutable；`PhotoItem.copyWith`
- [ ] `EditorController` / `ExportController` / `PreferencesController`
- [ ] 删除 `GearLabController` facade
- [ ] 作用域 `ListenableBuilder`
- [ ] 舞台/行 `RepaintBoundary`
- [ ] `shouldRepaint` 精确化（海报、相机缩略图、SV/色相/alpha）
- [ ] 缩略图缓存（520）
- [ ] Semantics/焦点顺序/键盘遍历/命中区
- [ ] 文字缩放 1.5/2.0、减少动效
- [ ] 回归：golden、导出、状态迁移

### P7 · 验收

- [ ] 全矩阵截图（Windows/Android × Light/Dark × zh/en）
- [ ] 手工清单全部通过
- [ ] `flutter analyze` 0 issue；`flutter test` 全绿
- [ ] Windows release / APK release 构建
- [ ] README/文档更新

## 5. 复用率与代码质量指标

### 5.1 当前 → 目标

| 指标 | 当前 | 目标 | 测量方式 |
|---|---:|---:|---|
| UI 私有类（main.dart） | 34 | 0（全部迁出） | `rg "class _" lib/main.dart` |
| 可复用组件 | 0 | ≥ 24 个 `Gl*` | `lib/design/components` |
| `fontSize:` 字面量 | 77 | 0（组件/Token 内可用常量） | `rg "fontSize:" lib/presentation lib/design` |
| `Color(0x…)` | 47 | 仅 tokens/内容配色 | `rg "Color\(0x" lib`（白名单） |
| `BorderRadius.circular` | 38 | 仅通过 `GlRadii` | `rg "BorderRadius.circular" lib` |
| 平台/插件引用 | 17 | 仅 `lib/platform` + `bootstrap` | `rg "Platform\\.|dart:io|file_picker|gal|share_plus|path_provider"` |
| 硬编码中文 | 814 字符 | 仅 ARB 与允许的内容常量 | `rg "[\u4e00-\u9fff]" lib --glob '!l10n/**'` |
| 主题 | 1 | 2（Light/Dark） | 主题测试 |
| 语言 | 1 | 2（zh/en）+ 系统跟随 | ARB key 对齐 |
| `shouldRepaint => true` | 2+ | 0 | code review |
| 主要交互控件复用 | 0% | ≥ 60% 来自 `Gl*` | 组件使用计数 |

### 5.2 复用示例

| 组件 | 使用位置数 | 位置 |
|---|---:|---|
| `GlButton` | ≥ 8 | 顶栏导入/导出、检查器导出当前/全部、导出对话框取消/开始、空状态导入、结果对话框 |
| `GlIconButton` | ≥ 6 | 导入、清除、删除、相机箭头、语言/主题、更多 |
| `GlPane` | 3 | 照片库、舞台、检查器 |
| `GlSection` | 5 | 相机/标题/版面/背景/屏幕 |
| `GlChoiceCard` | ≥ 6 | 范围 2 + 尺寸 3 + 格式 2 |
| `GlSwitchRow` | 3 | 显示标题、反光、同步全部 |
| `GlField` | 2 | 标题、副标题 |
| `GlSlider` | 2 | 相机大小、JPG 画质 |
| `GlDialog` | 3 | 导出、结果、显示设置 |
| `GlToast` | 所有页面 | 导入/保存/错误 |

### 5.3 预计代码变化

| 文件/目录 | 变化 |
|---|---|
| `lib/main.dart` | 2840 → < 100 行（仅 bootstrap） |
| `lib/controller.dart` | 779 → 拆为 3 个 controller + 2 个 service（每文件 < 300 行） |
| 新增 `design/` | ~1800 行（含 Token/主题/组件/测试） |
| 新增 `presentation/` | ~2200 行 |
| 新增 `platform/` | ~600 行 |
| 新增 `domain/data` | ~1000 行（含迁移/命名/服务） |
| 净变化 | 代码总量增加（因为组件/测试/适配器），但 **重复度、耦合度、单文件复杂度显著下降**；不以“减少行数”作为唯一指标 |

## 6. 改造风险与应对（组件层）

| 风险 | 触发点 | 应对 |
|---|---|---|
| 视觉回归 | 主题替换、间距/字号调整 | 每阶段截图对比；先 Token 后布局；保留旧截图 |
| 交互回归 | 拖拽/快捷键/数字输入 | `EditorPage` 接回旧逻辑；手工清单 |
| 海报像素回归 | renderer 去 Material 化 | golden；只改 import/颜色来源，不改绘制顺序 |
| 导出回归 | destination 适配器 | 文件名/尺寸/格式测试；Android 真机相册验证 |
| 状态丢失 | v2 迁移 | v1 fixture + 迁移测试；迁移前备份 |
| 文字溢出 | 英文/大字体 | 英文布局用例；minHeight + Wrap；1.5/2.0 缩放 |
| 过度抽象 | 组件 API 过多 | 组件只暴露实际使用属性；避免“万能组件” |
| 主题切换闪烁 | 标题栏/系统栏 | 先设原生 chrome 再切 UI；避免首帧白闪 |
