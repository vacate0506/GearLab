# GearLab UI 重构 · 实施与验证

> 状态：**已实施并通过本机验证**
> 实施时间：2026-11-28
> 基线：`85fb629 feat: 新增一些相机模板`（未触碰工作区原有的 `.github/workflows/macos.yml` 删除）
> 技术基线：Flutter 3.50.1 / Dart 3.14.0 / material_ui 1.11.1

## 1. 实施结果

按 `03-refactor-plan.md` 完成 P0–P6，P7 验收记录见本文第 4 节。

### 1.1 架构落地

```text
lib/
├── main.dart                     2 行，仅调用 bootstrap
├── bootstrap.dart               组合根：创建平台、控制器、初始化、runApp
├── app/
│   ├── app_preferences.dart     主题/语言偏好与持久化
│   └── gearlab_app.dart         系统跟随、两套主题、locale、系统栏/标题栏
├── design/
│   ├── tokens.dart              GlPalette（2 套）、GlType、GlSpace、GlRadius、GlSize
│   ├── theme.dart               GlTheme、GlDensity、BuildContext 扩展
│   └── components.dart          22 个 Gl* 组件
├── domain/
│   ├── models.dart              不可变 StyleSettings / PhotoItem / 导出模型
│   ├── catalog.dart             37 个相机模板
│   ├── poster_renderer.dart     海报渲染，纯 dart:ui + flutter/rendering
│   └── export_naming.dart       导出命名/去重/非法字符，纯函数
├── platform/
│   ├── app_platform.dart        AppPaths/导入/拖放/导出/分享/窗口/系统栏契约
│   ├── windows_app_platform.dart
│   ├── android_app_platform.dart
│   ├── fake_app_platform.dart  测试替身
│   └── platform_factory.dart    唯一允许 Platform.is* 的入口
├── l10n/                        ARB + 生成类
└── presentation/editor/
    ├── editor_controller.dart   状态、导入、导出编排、状态 v2
    ├── editor_page.dart         响应式壳、三栏/两栏/单栏、Tab
    ├── export_dialog.dart       范围/尺寸/格式/画质/进度/结果
    ├── color_picker_dialog.dart HSV + alpha + HEX
    └── preferences_dialog.dart  主题/语言
```

Dart 源码 21 个文件、6706 行（不含生成 l10n），`main.dart` 从 2840 行降到 2 行。

### 1.2 设计系统

- 两套语义色板：浅色光桌、深色暗房；`GlPalette` 作为 `ThemeExtension` 注入。
- 字阶 13 级：display/title/heading/section/body/bodyStrong/label/caption/micro/button/numeric/numericLarge/wordmark。
- 间距 4/8/12/16/24/32/48；圆角 2/4/6/8/12/pill；密度 Token 按 Windows 紧凑 / Android 触控切换。
- 组件状态矩阵覆盖默认/hover/pressed/focus/disabled/selected；图标按钮有 44/36 两档命中区，Android 为 48dp。
- 橙色只用于选中、主操作、进度、焦点；主要按钮橙底近黑字，浅色 4.79:1 / 深色 6.78:1。

### 1.3 i18n

- `lib/l10n/app_zh.arb` / `app_en.arb`，约 100+ key，key 完全对齐（测试保障）。
- 默认跟随系统：`zh*` → 中文，其余 → 英文；手动切换持久化到状态 v2。
- `presentation/domain/platform/design/app` 内 **0 行硬编码中文**（测试扫描）；导出进度/错误/文件命名不再拼接中文句子。
- 英文单复数：`1 work` / `n works`、`All 1 photo` 等通过 `*One` key 分支处理。

### 1.4 平台差异隔离

- 业务层不再出现 `dart:io`、`file_picker`、`gal`、`share_plus`、`path_provider`；全仓 `Platform.is*` 只剩 `platform_factory.dart` 两处。
- Windows：可移植 `userdata`/`exports`、拖放、标题栏 DWM 明暗覆盖、最小窗口 960×640。
- Android：edge-to-edge、状态栏安全区、系统相册 `Pictures/GearLab`、分享、预测性返回开关。

### 1.5 状态与回归

- 状态 schema v2，新增 `preferences`；兼容读取 v1（缺省 preferences + 默认值），旧版可忽略 unknown 字段。
- 海报渲染逻辑未改，仅移除 Material 依赖；像素 golden 未变。
- 导出命名/尺寸/质量/文件夹/相册行为保持；单张与批量均实测。

## 2. 关键指标变化

| 指标 | 重构前 | 重构后 |
|---|---:|---:|
| `lib/main.dart` 行数 | 2840 | 2 |
| 单文件 UI 私有类 | 34 | 0（页面 + 22 个 Gl* 组件） |
| 直接 `Platform.is*` | 17 处散落 | 2 处，仅在 `platform_factory.dart` |
| 硬编码中文字符行 | 814 行 | 0（运行时层，生成 l10n 除外） |
| `fontSize:` 字面量 | 77 | 17（16 在 `design/tokens.dart`，1 处为响应式标题动态字号） |
| 十六进制颜色字面量 | 47 | 集中在 `tokens.dart` / 海报内容色板 |
| 主题套数 | 1（固定深色） | 2（浅/深）+ 系统跟随 |
| 语言 | 仅硬编码中文 | 中文 / English，系统跟随 + 手动 |
| 测试数量 | 3 | 16 |
| 海报 golden | 无 | FNV-1A `0x480345d7b80091b5` |

## 3. 验证记录

| 验证 | 命令/方式 | 结果 |
|---|---|---|
| 静态分析 | `flutter analyze` | **No issues found!** |
| 单元/回归测试 | `flutter test` | **16/16 pass** |
| 海报像素 | `test/poster_regression_test.dart` | FNV-1A 与基线一致 `0x480345d7b80091b5` |
| ARB 对齐 | `test/l10n_test.dart` | zh/en key 完全一致；运行时层 0 中文硬编码 |
| 色板对比度 | `test/design_system_test.dart` | 两套（light/dark）色板正文/控件/焦点均达 AA 阈值 |
| 导出命名 | `test/export_naming_test.dart` | `GearLab_XX_<base>_<model>`、非法字符、重复后缀通过 |
| Windows Debug | `flutter build windows --debug` | 成功；实际窗口 1360×860 截图验收 |
| Windows Release | `flutter build windows --release` | 成功（`build\windows\x64\runner\Release\gearlab.exe`） |
| Windows 导出 | 应用内 5 张 2160 JPG | 5 个文件，命名/大小正确 |
| Android Release | `flutter build apk --release` | 成功（61.6 MB） |
| Android 模拟器流程 | 模拟器 `Medium_Phone_API_37.0` | 安装/启动/导入/紧凑布局/导出对话框/相册导出通过 |
| Android 相册 | `/sdcard/Pictures/GearLab/` | 新文件写入成功，结果弹窗显示 `Gallery · GearLab` |

### 截图

- [桌面浅色中文](app-desktop-light-zh.png) · [桌面深色英文](app-desktop-dark-en.png)
- [Android 紧凑布局](app-android-light-en.png) · [Android 导出结果](app-android-export-result.png)
- [偏好设置](app-preferences.png) · [导出对话框](app-export-dialog.png) · [主题菜单](app-theme-menu.png) · [颜色选择器](app-color-picker.png)

## 4. 验收结论

- **跨平台规范**：Windows 紧凑密度、原生标题栏明暗、最小窗口；Android 48dp 命中区、edge-to-edge、状态栏安全区、系统相册。
- **UI 还原一致**：浅色/深色均按设计 Token 渲染，组件状态一致；桌面三栏、移动单栏均已实测。
- **复用率**：22 个 `Gl*` 组件覆盖全部按钮、面板、字段、分段控件、滑块、色板、相机卡、照片行、对话框、空状态、工具栏。
- **核心路径无回归**：导入、选择、同步、模板、标题、版面、背景、屏幕、状态恢复、导出、分享、快捷键、拖放均保留。
- **代码质量**：analyze 0 issue；16 项测试；分层依赖规则由 import 边界保证；`main.dart` 仅 2 行。

## 5. 已知风险与后续

1. Android Release 仍使用 debug 签名（仓库既有问题，正式分发前需替换 keystore）。
2. Windows 原生标题栏明暗依赖 DWM 属性；Windows 10 早期版本可能回退为系统默认色，不影响 App 内主题。
3. Android 返回手势只验证了 manifest 配置与 `PopScope` 代码路径，未做系统级预测性返回动画的完整回归。
4. 响应式布局目前靠 Desktop/Android 截图与用例验证，尚无 Flutter widget test 覆盖所有断点。
5. 英文复数只覆盖本次 UI 文案（`*One` key），未引入 ICU plural；新增文案需沿用同一约定。
6. `editor_page.dart` 仍有 1798 行，后续可继续把五个 Section 拆成独立文件以降低单文件体量。
