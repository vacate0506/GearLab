# 01 · 现状审计

## 0. 审计结论

GearLab 的产品能力、渲染逻辑和本地数据链路是完整且可用的；问题集中在 **表达层**：单文件巨型 UI、单套深色主题、无设计 Token、无 i18n、无平台适配层，导致后续任何一次视觉调整都会牵动业务代码。

本次重构的判断是：

- **保留**：相机模板 catalog、海报几何与像素输出、照片导入/解码/本地库、状态恢复、导出范围/尺寸/格式/画质/文件名/相册/分享、Windows 拖拽、快捷键、无网络/无账号的本地属性。
- **重建**：主题与设计系统、应用壳与响应式布局、组件层、i18n、平台适配层、状态与偏好持久化、可访问性与性能。
- **不引入**：新的业务功能、云服务、账号体系、状态管理框架、海报渲染算法变更。

---

## 1. 基线与环境

| 项 | 实测值 |
|---|---|
| Flutter / Dart | 3.50.1 stable / 3.14.0 |
| Material 库 | `material_ui` 1.11.1（不是 `package:flutter/material.dart`） |
| 主要依赖 | `file_picker`、`path_provider`、`image`、`share_plus`、`path`、`cross_file`、`gal` |
| 后端/网络 | 无。全部本地处理，不联网、不上传 |
| 目标平台 | Windows x64；Android（当前 manifest 未锁定 minSdk，README 宣称 API 24+） |
| `flutter analyze` | `No issues found!`（退出码被 PowerShell 的 stderr 提示影响，代码无 issue） |
| `flutter test` | 3/3 通过（`catalog_test.dart`） |
| 当前工作区 | git 根目录已有 staged deletion `.github/workflows/macos.yml`，与本次无关，保持不动 |
| 已存在视觉资产 | `docs/examples/` 品牌样张与 `flutter_app/docs/*.png` 当前 UI 截图；本轮进度把真实素材用于新预览 |

---

## 2. 量化画像

### 2.1 代码规模

| 文件 | 行数 | 类数 | `fontSize:` | `Color(0x…)` | 职责 |
|---|---:|---:|---:|---:|---|
| `lib/main.dart` | 2840 | 34 | 74 | 40 | 入口、主题、全部页面、对话框、绘制器、字符串、平台分支 |
| `lib/controller.dart` | 779 | 3 | 0 | 0 | 状态、持久化、导入、解码、导出、插件、平台判断 |
| `lib/models.dart` | 179 | 6 | 0 | 1 | 可变模型、导出 DTO |
| `lib/renderer.dart` | 320 | 2 | 3 | 6 | 海报几何与像素绘制 |
| `lib/catalog.dart` | 380 | 1 | 0 | 0 | 37 个模板数据与图片缓存 |
| `test/catalog_test.dart` | 54 | — | — | — | catalog 约束测试 |
| **合计** | **4552** | **46** | **77** | **47** | — |

其他硬编码指标（`lib/**.dart` 全量统计）：

- `BorderRadius.circular(...)`：**38 次**，半径值 2/3/4/5/6/7/8/10/12/14/16/20 混用。
- 中文字符：**814 个**，没有 ARB、没有 `intl` 配置、没有 locale 解析。
- 直接 `Platform.` / `dart:io` 引用：**17 处**（`controller.dart` 8 处、`main.dart` 9 处）。
- 没有打包字体；没有主题切换；没有浅色主题；没有高对比度；没有 `ThemeExtension`。

### 2.2 运行时/交互现状

| 维度 | 现状 |
|---|---|
| 断点 | 只有 `width >= 1000` 一个分支；1000–1300 三栏明显拥挤；没有最小窗口尺寸 |
| 桌面 | 三栏固定 286 / 自适应 / 468（>=1300）或 420；没有标题栏主题控制；没有 hover/focus/context menu 规范 |
| Android | 单列长滚动，预览固定约 48% 屏高，照片条固定 158，设置区无 Tab；没有 edge-to-edge/返回/预测性返回配置 |
| 状态 | `GearLabController` 同时承担编辑状态、持久化、导入解码、导出调度、插件调用、平台判断 |
| 刷新 | 顶层 `AnimatedBuilder` 监听整个 controller；任何 notify 都会重建整页 |
| 绘制 | `PosterPainter.shouldRepaint => true`；`_CameraThumbPainter.shouldRepaint => true`；预览无 `RepaintBoundary` |
| 文案 | UI、controller、导出错误、toast 全部中文字符串常量；无法切换语言 |
| 可访问性 | 图标按钮 24–26px；动作按钮约 32px；色板 22px；无 Semantics/焦点环/键盘遍历保证；无高对比度 |
| 主题 | 单套深色 `ThemeData`；`_ColorPickerDialog` 反而是浅色，且使用独立色板 |

### 2.3 现有视觉资产

`docs/examples/00_contact_sheet_wide.png` 是 3840×2160 的 11 页品牌接触印样；`camera-lineup.jpg`、`ricoh-gr-iv.jpg` 等是真实的模板/作品样张。它们已经建立了：

- 纸感浅底、近黑墨色、安全橙色；
- 细线、宽字距、编号式标注、接触印样式排版；
- 摄影作品优先、平面化而非卡片堆叠。

现有 App 的深色 UI 与这套品牌语言是同源的，但 **App 内没有浅色主题**，而浅色恰好是品牌的主场。因此浅色主题不是“新增一套皮肤”，而是把品牌已有的纸感语言正式落地到产品里。

---

## 3. 现有业务基线（重构中不可破坏）

### 3.1 核心路径

1. 选择照片（Windows：文件选择/拖拽/文件夹；Android：文件选择）→ 复制到本地照片库（Windows `userdata/photos`，Android 应用私有目录）→ 解码（最长边 2600px）→ 加入 `photos`。
2. 选择模板（37 个）→ 调整相机大小 34%–72%、标题/副标题、背景色、屏幕 fill/fit、反光。
3. 同步全部开启时，所有照片共享 `currentStyle`；关闭后逐张保存 `PhotoItem.style`。
4. 重启恢复：`state.json`（version 1）含 `syncAll`、`selectedIndex`、`currentStyle`、照片路径/名称/managed/style。
5. 导出：当前单张 / 全部（默认）/ 选中（UI 暂不暴露 selected 入口）；1080/1440/2160；JPG 画质 60–100（默认 100）/PNG；Windows 写 `exports/`，Android 写临时目录后 `Gal.putImage(album: 'GearLab')` 入系统相册。
6. 结果对话框显示文件数、目录、错误、相册保存数、降级提示；Android 支持分享。

### 3.2 必须保持的精确行为

| 行为 | 证据/约束 |
|---|---|
| 海报几何 | `PosterPlan.forWidth`：`band = round(width / aspect)`，`height = band * 2`，上下严格 1:1；相机模板 `screen` 为归一化 Rect，`screenInset` 默认 0.06（Sony α7C II / Lumix S9 为 0） |
| 海报颜色 | `inkOn` 依据亮度阈值 0.56 选深/浅墨；`mutedInkOn` alpha 0.58；背景色 8 个预设 + 自定义 HSV/HEX |
| 导出命名 | `GearLab_{序号2位}_{安全化源文件名}_{安全化相机型号}.{jpg|png}`；重名追加 `_2`、`_3`… |
| Windows 目录 | 优先 exe 同级 `userdata/`，不可写回退 `LOCALAPPDATA`/`APPDATA`；exports 放解压目录最外层，开发态向上找 `pubspec.yaml` |
| Android 相册 | `Gal.putImage(path, album: 'GearLab')`；失败计入 errors；成功后提示相册位置 |
| 状态写入 | 350ms debounce；临时文件 `.tmp` 后 rename；退出时同步写；失败仅 debugPrint，不弹窗 |
| 快捷键 | Ctrl+O 导入、Ctrl+E 导出、Ctrl+S 保存、方向键切换照片、Delete 删除 |
| 本地性 | 无网络请求；导入、处理、导出全在设备上 |

### 3.3 可接受的内部变化

以下变化不改变用户可见行为，允许在重构中发生：

- `GearLabController` 拆分为 editor/export/preferences 协作对象；
- `StyleSettings` 由可变改为不可变 + `copyWith`；
- 状态文件增加 `version: 2` 与 `preferences` 节点，但必须兼容读取 v1；
- 平台判断移入适配器，presentation/domain 不再直接 `Platform.`；
- 渲染器只移除对 Material 的 import 依赖，像素输出必须逐字节/逐像素不变；
- 组件类名、文件位置、widget 树可以调整，但 Semantics/快捷键/导出行为保持。

---

## 4. 问题清单

### P0 · 阻碍验收（必须本期解决）

| ID | 问题 | 证据 | 影响 |
|---|---|---|---|
| A1 | 单文件巨型 UI | `main.dart` 2840 行 / 34 类 | 任何改动回归面大；无法并行、无法测试 |
| A2 | Controller 上帝对象 | `controller.dart:19-779` 同时管状态/IO/导出/插件 | 业务不可单测；平台逻辑无法替换 |
| A3 | 平台判断散落 | 17 处 `Platform.`/`dart:io`，如 `controller.dart:159,490,578,672,685,707,715`、`main.dart:214,909,2472,2571,2578,2592,2601` | Android/Windows 行为与 UI 耦合；无法在测试中替换 |
| A4 | 无设计 Token | 47 个色值字面量、77 个字号、38 处半径 | 视觉不一致；浅色/高对比度无法系统化 |
| B1 | 仅深色主题，且深色本身对比不足 | 白字在 `#FF6A3D` 上约 2.85:1 | 不满足 WCAG AA；无法跟随系统 |
| B2 | 字号层级失效 | 几乎所有正文 14px；标题与元数据同号 | 信息层级弱、扫描效率低 |
| C1 | 无 i18n | 814 个中文字符；无 ARB/locale | 无法满足中英文切换要求 |
| D1 | 响应式不足 | 只有 `width >= 1000`；无 min size | 1000–1300 拥挤；平板/横屏不可用 |
| F1 | 可访问性不达标 | 24–26px 图标按钮、22px 色板；无 Semantics/焦点环 | 键盘、屏幕阅读器、大字体用户无法完整使用 |
| G1 | 整页重建/绘制 | `main.dart:318` 顶层 `AnimatedBuilder`；`main.dart:1516` 等 `shouldRepaint => true` | 拖动滑杆/切照片时整页重绘；大图下掉帧 |
| R1 | 无像素/状态回归基线 | 只有 catalog 测试 | 重构无法证明“没有破坏渲染/导出” |

### P1 · 本期完成，允许分阶段

| ID | 问题 | 证据/说明 | 目标 |
|---|---|---|---|
| B3 | 颜色/圆角/阴影不成体系 | 半径 2–20、对话框独立深色、浅色取色器破坏主题 | 全部走 Token；只有语义化阴影 |
| E1 | Windows 交互习惯缺失 | 原生标题栏只跟随系统；无最小窗口；无 hover/focus 规范；无菜单 | 最小 960×640；标题栏明暗跟随 App；指针/键盘状态完整 |
| E2 | Android 规范缺失 | 无 edge-to-edge、状态栏/导航栏样式、返回/预测性返回处理 | 透明系统栏 + SafeArea；返回关闭浮层；API 24–36 验证 |
| D2 | 信息架构在移动端断裂 | 手机把设置区全部堆在长滚动尾部 | “预览 + 胶片条 + 五 Tab + 底部导出” |
| H1 | 装饰性编号/双语眉题 | 01–05 并非步骤；`STYLE`/`LIVE COMPOSITION` 无信息价值 | 去除装饰性大写眉题，保留真实编号（照片/模板序号） |
| H2 | 卡片嵌套 | 面板内再套卡片、卡片内再套控件 | 平面分栏 + 细线；只在弹层/浮层用阴影 |
| F2 | 高对比度/减弱动效缺失 | 无 HC 色板，动画硬编码 | 系统/手动 HC；尊重 `disableAnimations` |
| G2 | 图片缩略图/纹理内存 | 每张照片保留最长边 2600 的 `ui.Image`；列表重复绘制 | 缩略图缓存 + RepaintBoundary；导出仍用原图 |

### P2 · 本期收尾或下一迭代

| ID | 问题 | 说明 |
|---|---|---|
| G3 | 相机模板 37 张缩略图的自绘 | 可保留自绘但必须 `shouldRepaint` 精确；必要时做缓存 |
| F3 | 取色器 SV 面板无键盘/读屏替代 | 提供 HEX 输入 + 预设色板作为等价路径；滑块可键盘操作 |
| H3 | 导出成功弹窗/进度浮层风格不一致 | 统一到 `GlDialog`/`GlProgressDialog` |
| D3 | 无窗口尺寸记忆 | 可选，需额外持久化；本期不做，避免扩大状态面 |

---

## 5. 现有代码结构图

```text
flutter_app/lib/
├── main.dart          2840 行：入口 + ThemeData + HomePage + TopBar + PhotoRail
│                      + PreviewPane + SettingsPanel + CameraStrip + 颜色选择器
│                      + Screen/Layout/Title/Background 字段 + ExportDialog + 进度浮层
├── controller.dart     779 行：GearLabController（状态/持久化/导入/解码/导出/分享/平台）
├── models.dart         179 行：StyleSettings（可变）、PhotoItem、ExportOptions/Progress/Result
├── renderer.dart       320 行：PosterPlan、paintPoster、PosterPainter、renderPoster
└── catalog.dart        380 行：37 个 CameraTemplate、图片缓存、find/load
```

关键耦合点：

- `main.dart:1` 直接 `import 'dart:io'`，UI 层做平台分支；
- `controller.dart` 直接依赖 `file_picker` / `gal` / `share_plus` / `path_provider` / `image`；
- `renderer.dart:4` 依赖 `material_ui` 的 `Colors`，使“内容绘制”与 UI 库耦合；
- `main.dart:14-34` 的 `kBg/kPanel/kAccent/kBackdrops` 既是 UI 色也是海报内容色，语义混用；
- `StyleSettings` 可变，`PosterPainter` 无法可靠判断“真正变了什么”。

---

## 6. 重构边界

### 做

- 设计 Token、四套主题、组件库、应用壳、响应式、i18n、平台适配层、状态 v2、可访问性、性能优化。
- 现有视觉资产的延续与再组织：纸感、细线、安全橙、真实照片优先。
- 可测试性：domain 单测、widget 测试、golden、适配器 fake、手工跨平台清单。

### 不做（本期）

- 不改海报算法、不新增模板、不改导出格式/画质选项/命名规则。
- 不改本地优先、无账号、无网络的定位。
- 不引入 Riverpod/Bloc/GetX 等状态管理框架（保持 ChangeNotifier + 作用域监听）。
- 不做自定义窗口标题栏（保留原生标题栏，只做明暗同步与最小尺寸）。
- 不新增网络/云同步/崩溃上报。
- 不替换 `material_ui`，不引入第二套 UI 框架。

---

## 7. 审计结论

**现有功能边界的完整性 > 现有 UI 的可维护性。** 因此重构顺序必须是：

1. 先固化“业务不可变”的证据（poster golden、v1 state fixture、导出文件基线）；
2. 再建立设计系统与组件层（纯增量，可独立回退）；
3. 再替换页面与交互（按区域逐块迁移）；
4. 最后拆控制器/状态/平台（此时 UI 已有测试网）。

这个顺序能保证任一阶段失败时，产品仍可运行、导出仍正确、状态仍可恢复。
