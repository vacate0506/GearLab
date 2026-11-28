# 02 · 设计系统与交互规范

## 1. 设计方向

### 1.1 概念：接触印样 / 光桌

GearLab 不是“相机滤镜 App”，而是把照片装进相机的**排版台**。界面的隐喻应该是摄影师的接触印样（contact sheet）与灯箱（light table）：

- **照片和作品是内容，界面是纸和尺**：不做渐变、玻璃、发光、3D 卡片；
- **平面分栏 + 细线**：用 1px 分割线组织信息，而不是用圆角卡片一层层包起来；
- **安全橙是信号，不是装饰**：只出现在当前选中、主操作、进度、焦点；其余颜色全部为纸/墨/灰；
- **真实的编号**：照片序号、模板序号是接触印样的语言；去掉“01 相机模板 / 02 标题文字”这种伪步骤编号；
- **双语只出现在品牌词**：`GEARLAB / 器材研究所 / CAMERA STORY` 是品牌资产；不再用全大写英文眉题做装饰；
- **光桌与暗房**：浅色主题是日光下的纸与印样，深色主题是暗房里的红光与作品；两套同一结构、同一 Token。

### 1.2 与现有品牌资产的关系

`docs/examples` 已经定义了纸感浅底、近黑墨、安全橙、细线、编号和大量留白的品牌语言。本次浅色主题直接继承，不另起一套冷灰系统；深色主题是它的暗房对偶。产品内不使用品牌 deck 的衬线大标题（那是营销物料），产品界面统一使用系统 UI 无衬线字体，保证中英文与多平台可读性。

### 1.3 三条硬规则

1. **任何文字/控件颜色必须来自语义 Token**，不允许页面内写 `Color(0x...)`；
2. **任何交互状态不能只靠颜色表达**：选中必须同时有边框/图标/字重变化；焦点必须有可见环；
3. **橙色不用于正文，也不与白字组合**：主按钮使用深橙底 + 近黑字（浅色）或亮橙底 + 近黑字（深色），保证 ≥4.5:1。

---

## 2. Token 架构

实现时使用 **Dart 常量 + ThemeExtension**，页面只通过 `Theme.of(context)` 与 `context.gl` 读取；不在组件里做 `isDark ? … : …` 分支。

```text
lib/design/
├── tokens/
│   ├── gl_colors.dart        // 两套语义色板（Light / Dark）
│   ├── gl_typography.dart    // 字阶、字重、行高、字距、tabular figures
│   ├── gl_spacing.dart       // 4px 基准间距、密度、控件高度
│   ├── gl_radii.dart         // 2/4/6/8/12/pill
│   ├── gl_shadows.dart       // 仅 print/overlay 两种，无卡片阴影
│   ├── gl_motion.dart        // 120/180/240ms、标准/强调曲线
│   └── gl_sizes.dart         // 窗口、面板、断点、图标、目标尺寸
├── theme/
│   ├── gl_theme.dart         // GlTheme.build(brightness, touch)
│   ├── gl_theme_extensions.dart
│   └── gl_theme_controller.dart
└── responsive/
    ├── gl_breakpoints.dart
    └── gl_responsive_shell.dart
```

Token 命名规范：

- 语义色：`surface / canvas / raised / sunken / line / lineSoft / lineStrong / ink / ink2 / ink3 / accent / accentSoft / accentText / onAccent / focus / danger / success / warning / stage / scrim`
- 尺寸：`space.xs/sm/md/lg/xl`、`size.control`、`size.icon`、`size.touch`
- 组件只允许使用语义 Token；**禁止** `accent.withOpacity(0.12)` 这类临时透明度，需要的新语义先入 Token。

---

## 3. 颜色

### 3.1 浅色「光桌 / Light Table」

| Token | 值 | 用途 | 对比度（关键组合） |
|---|---|---|---|
| `surface` | `#F2EEE4` | 面板、主内容底 | ink 15.84:1，ink2 7.58:1，ink3 4.70:1 |
| `canvas` | `#EAE5D8` | 窗口底、面板间隙 | — |
| `raised` | `#FBF8F0` | 输入框、选中行、浮层表面 | ink 17.29:1 |
| `sunken` | `#E5DED0` | 分段控件槽、内嵌区域 | accent 3.01:1（≥3:1 非文本） |
| `line` | `#D6CFC0` | 分割线、默认描边 | 1.34:1（仅装饰） |
| `lineSoft` | `#E2DBCC` | 照片行分隔、次级分割 | 装饰 |
| `lineStrong` | `#8B8476` | 输入框/次级按钮边界 | 3.20:1（≥3:1） |
| `ink` | `#171411` | 主文字、标题 | 15.84:1 |
| `ink2` | `#4F4A42` | 次级文字、标签 | 7.58:1 |
| `ink3` | `#6F695E` | 元数据、辅助说明 | 4.70:1（AA 正文临界，仅用于 11–13px 辅助信息） |
| `accent` | `#E24A10` | 主按钮、选中边框、进度 | 3.47:1 on surface；3.01:1 on sunken |
| `accentHover` | `#D0420C` | 主按钮 hover | — |
| `accentPressed` | `#B93B0A` | 主按钮 pressed | — |
| `accentSoft` | `#F9E1D4` | 选中行底、选中卡片底 | — |
| `accentText` | `#B9400F` | 浅底上的橙色文字/链接 | 4.77:1 |
| `onAccent` | `#190B04` | 橙底上的文字/图标 | 4.79:1 on accent |
| `focus` | `#B9400F` | 2px 焦点环 | 4.77:1 |
| `stage` | `#E4DED0` | 作品舞台底、crop marks 区域 | — |
| `danger` | `#B3261E` | 错误文字/危险操作 | 5.64:1 |
| `success` | `#1F7A5A` | 成功提示 | 5.03:1 |
| `warning` | `#9A6210` | 警告提示 | 4.86:1 |
| `brand` | `#FF5A1F` | 仅 Logo/App Icon/品牌图形 | 2.69:1，**禁止用于文字/控件边界** |

### 3.2 深色「暗房 / Darkroom」

| Token | 值 | 用途 | 对比度 |
|---|---|---|---|
| `surface` | `#101214` | 面板、主内容底 | ink 16.64:1，ink2 11.60:1，ink3 7.24:1 |
| `canvas` | `#0B0C0D` | 窗口底 | — |
| `raised` | `#191C1F` | 输入框、浮层、选中行 | ink 15.17:1 |
| `sunken` | `#070808` | 分段槽、内嵌区域 | accent 7.05:1 |
| `line` | `#282C30` | 分割线 | 1.33:1（装饰） |
| `lineSoft` | `#1E2226` | 次级分割 | 装饰 |
| `lineStrong` | `#737A83` | 输入框/按钮边界 | 4.33:1 |
| `ink` | `#F4F1EA` | 主文字 | 16.64:1 |
| `ink2` | `#CFCBC2` | 次级文字 | 11.60:1 |
| `ink3` | `#9EA29B` | 元数据 | 7.24:1 |
| `accent` | `#FF6A3D` | 主操作/选中 | 6.60:1 on surface |
| `accentHover` | `#FF815A` | 主按钮 hover | — |
| `accentPressed` | `#E8551F` | 主按钮 pressed | — |
| `accentSoft` | `#3A211A` | 选中行底 | — |
| `accentText` | `#FF9A78` | 深底橙色文字 | 9.07:1 |
| `onAccent` | `#1A0A04` | 橙底上的文字 | 6.78:1 |
| `focus` | `#FFB59C` | 焦点环 | 11.03:1 |
| `stage` | `#060707` | 舞台底 | — |
| `danger` | `#E9A29A` | 错误文字 | 9.03:1 |
| `success` | `#7BC8A4` | 成功提示 | 9.27:1 |
| `warning` | `#E7BE78` | 警告提示 | 10.48:1 |
| `brand` | `#FF6A3D` | Logo/图形 | 6.60:1 |

### 3.3 高对比度（已移除）

原设计中的高对比度模式（含 `GlPalette.highContrastLight` / `GlPalette.highContrastDark` 两套色板、系统 HC 监听与手动开关）已在收敛阶段移除（2026-11-28）。现在仅保留浅色、深色两套语义色板；文字与控件的对比度要求由这两套色板自身满足（见第 9 节）。

### 3.4 颜色使用约束

- **海报内容色**（白、纸、8 个背景、自动深/浅墨）只属于 `renderer` 的内容 Token，不进入 UI 主题；UI 变色不影响作品像素。
- 选中照片行：`accentSoft` 底 + 2px `accent` 左边条 + `ink` 文件名 + `accentText` 序号；不能只靠底色。
- 选中相机/模板：2px `accent` 边框 + `raised` 底 + 右上/左下勾选标记。
- 选中色板：2px `surface` 内环 + 2px `accent` 外环 + `accentText` HEX 文案；不能只靠色块。
- 错误：`danger` 文字 + 错误图标 + 字段边框；不能只用红色文本。
- 禁用：容器 `sunken`，文字 `ink3`；不降低到不可读（禁用文本不计入 AA，但不得 <3:1）。

---

## 4. 字体与字阶

### 4.1 字体策略

| 项 | 决策 |
|---|---|
| UI 字体 | 平台系统 UI 字体：Windows 使用 Segoe UI + 系统中文字体回退；Android 使用 Roboto/Noto Sans CJK 回退 |
| 打包字体 | **不打包**。CJK 字体会显著增加 APK/安装包体积，且 Windows/Android 已有高质量系统字体；用 Token 锁定字号/字重/行高/字距来统一节奏 |
| 数字 | 全部启用 `FontFeature.tabularFigures()`，尺寸、百分比、序号、计数不跳动 |
| 英文 | 系统 UI 字体；品牌词 `GEARLAB` 使用 `+0.16em` 字距、700 字重 |
| 营销衬线 | `docs/examples` 的衬线只用于品牌物料，不进入产品 UI |
| 回退 | `fontFamilyFallback` 保留系统中文字体链；不硬编码 `Microsoft YaHei` |

### 4.2 字阶表

| Token | 字号/行高 (dp) | 字重 | 字距 | 用途 |
|---|---|---|---|---|
| `display` | 28 / 34 | 700 | -0.02em | 空状态、导出完成等极少数大标题 |
| `title` | 22 / 28 | 700 | -0.01em | Dialog / Sheet 标题 |
| `heading` | 17 / 24 | 600 | -0.01em | Dialog 标题、大区块标题 |
| `paneTitle` | 15 / 20 | 700 | -0.01em | 三栏界面唯一高于 `section` 的层级：照片库 / 预览 / 版面设置 |
| `section` | 13 / 18 | 600 | +0.02em | Inspector 分区标题、Tab 选中 |
| `body` | 13 / 20 | 400 | 0 | 字段、说明、正文 |
| `bodyStrong` | 13 / 20 | 600 | 0 | 照片名、选中项、主要值 |
| `label` | 12 / 16 | 500 | +0.02em | 字段标签、工具条文字 |
| `caption` | 12 / 17 | 400 | +0.02em | 元数据、辅助说明、尺寸、开关标签 |
| `micro` | 10 / 14 | 500 | +0.08em | 相机品牌小字、极少量 overline |
| `button` | 13 / 18 | 600 | +0.01em | 按钮、Tab、主要操作 |
| `numeric` | 12 / 16 | 600 | +0.02em | 尺寸/百分比/计数（tabular） |
| `wordmark` | 15 / 20 | 700 | +0.16em | GEARLAB 品牌词 |

规则：

- 中文正文行高不低于 1.5；标题 1.3–1.4。
- 不使用全大写英文作为装饰眉题；`micro` 仅用于相机品牌等真实品牌信息。
- 中文说明文字不得使用 `micro`（10px 中文笔画糊成一团），最低 `caption` 12px；主操作、字段值、正文不小于 13px。
- 支持系统文字缩放：Windows 1.0–1.4，Android 1.0–2.0；所有容器可增高/换行/滚动，不裁切。

---

## 5. 间距、密度、圆角、阴影

### 5.1 间距

基准 4px；常用：`2, 4, 8, 12, 16, 24, 32, 40, 48`。

| Token | 值 | 用途 |
|---|---:|---|
| `space.xxs` | 2 | 图标与文字的紧贴间隔 |
| `space.xs` | 4 | 行内微调 |
| `space.sm` | 8 | 控件内水平 padding、图标间距 |
| `space.md` | 12 | 字段间距、分区内部 |
| `space.lg` | 16 | 面板 padding、分区 padding |
| `space.xl` | 24 | 大块间距、空状态 |
| `space.xxl` | 32 | 舞台留白 |
| `space.xxxl` | 40/48 | 页面级留白 |

布局常量：

- 桌面顶栏 56；面板头 44；检查器分区 padding 16，分区之间 1px `lineSoft`；
- 桌面动作条 56；移动底栏 64 + 安全区；
- 桌面控件高 32；Android 控件高 40；图标按钮桌面 32 视觉 / 40 命中，Android 44 视觉 / 48 命中；
- 照片行桌面 64；移动胶片卡 78×58；相机卡 74×88（桌面）/ 96×104（移动）。

### 5.2 圆角

| Token | 值 | 用途 |
|---|---:|---|
| `radius.xs` | 2 | crop 角、微标记 |
| `radius.sm` | 4 | 缩略图、色块、小标签 |
| `radius.md` | 6 | 按钮、输入框、卡片 |
| `radius.lg` | 8 | 相机卡、分段控件 |
| `radius.xl` | 12 | Dialog / Sheet |
| `radius.pill` | 999 | 开关、pill、圆形色板 |

**禁止** 16/20 的“大圆角卡片”；面板本身 0 圆角，用 1px 线分隔。

### 5.3 边框与阴影

- 默认边框 1px `line`；控件边界 `lineStrong`；选中/焦点 2px `accent`/`focus`。
- 阴影只有两种：
  - `shadow.print`：舞台作品纸的投影 `0 18 48 rgba(0,0,0,.16)`（深色 `.36`）；
  - `shadow.overlay`：Dialog/浮层 `0 12 32 rgba(0,0,0,.20)`（深色 `.42`）。
- 面板、卡片、按钮一律无阴影；悬浮/按下只改背景与边框。

---

## 6. 图标

- 统一 Material Symbols Outlined 风格；只使用 outlined，不混 filled/rounded。
- 尺寸：14（行内元数据）、16（紧凑）、18（按钮/输入）、20（顶栏）、24（空状态/大按钮）。
- 图标与文字间距 8；图标按钮最小命中区域见 5.1。
- 所有纯图标按钮必须有 `tooltip` 与 `Semantics(label:)`。
- 自定义绘制器（色板、相机缩略图、SV 面板）必须有语义替代或外层语义标签。

---

## 7. 组件状态

| 组件 | 默认 | Hover | Pressed | Focus | Selected | Disabled | Error |
|---|---|---|---|---|---|---|---|
| Primary Button | accent 底 / onAccent 字 | accentHover（亮 4%） | accentPressed（暗 6%） | 2px focus 外环 + 2px 间隙 | — | sunken 底 / ink3 字 | — |
| Secondary Button | 透明底 / ink / lineStrong 边框 | raised 底 | sunken 底 | focus 环 | — | ink3 40% | — |
| Quiet/Icon Button | 透明 | 8% ink 覆盖 | 12% ink | focus 环 | accentText | ink3 | — |
| Text Field | raised 底 / line 边框 | lineStrong 边框 | — | 2px focus 边框 | — | sunken 底 / ink3 | danger 边框 + 错误文案 |
| Choice Card | surface 底 / line | raised 底 | sunken 底 | focus 环 | 2px accent + accentSoft + 勾 | ink3 40% | — |
| Camera Card | surface 底 / lineSoft | raised 底 | sunken 底 | focus 环 | 2px accent + 勾 | 30% | — |
| Swatch | 圆形色块 / lineStrong 边 | 放大 1.06 | — | 2px focus 环 | 2px surface + 2px accent 环 | 40% | — |
| Segmented | sunken 槽 | raised | sunken | focus 环 | raised 底 + 2px accent 底边 | 40% | — |
| Switch | line 轨道 / ink 圆点 | 轨道 lineStrong | — | 2px focus 环 | accent 轨道 + raised 圆点（纸白） | 40% | — |
| Slider | line 轨道 / accent 已选 | accent 高亮 | 圆点放大 | focus 环 | — | 40% | — |
| Tab | ink3 文字 | ink2 | sunken 底 | focus 环 | ink + 2px accent 下划线 | 40% | — |
| Photo Row | surface | raised | sunken | focus 环 | accentSoft 底 + 2px 左条 + accentText 序号 | 40% | — |
| Toast | raised / line / 6px | — | — | — | — | — | danger 图标 |
| Dialog | raised / 12px / overlay 阴影 | — | — | 焦点陷阱 | — | — | — |

动效：`fast 120ms`（hover/pressed）、`base 180ms`（选中、展开、Tab）、`slow 240ms`（Dialog/Sheet）；曲线 `easeOutCubic` / `easeInOutCubic`。尊重 `MediaQuery.disableAnimations`，开启时全部降为 0ms。

---

## 8. 响应式规范

### 8.1 断点

以窗口逻辑宽度为主，同时考虑高度：

| 名称 | 条件 | 布局 |
|---|---|---|
| Compact | `width < 720` 或 `height < 520` | 单列：顶栏 → 预览 → 胶片条 → 版面工具条 → 五个 Tab → 滚动内容 → 底部导出 |
| Medium | `720 ≤ width < 1100` | 两栏：顶栏 → 横向胶片条 → `Row(舞台 / 检查器 320)` → 底部导出；检查器不分 Tab，整列滚动 |
| Expanded | `1100 ≤ width < 1440` | 三栏：照片库 272 / 舞台 flex / 检查器 352 |
| Large | `width ≥ 1440` | 三栏：照片库 288 / 舞台 max 920 / 检查器 368 |

- Windows 最小窗口 **960×640**；默认 1360×860 保持现有启动尺寸；`Compact` 不会出现在 Windows（除非用户强制缩小到 <720，此时窗口管理器阻止）。
- Android 竖屏通常是 Compact；横屏 `800×360` 因高度 <520 仍走 Compact，不强行挤两栏。
- 面板宽度使用 `clamp`，内容切换时允许 1px 线吸附；不允许横向滚动页面。
- 不使用 `Platform.isAndroid` 决定布局，只用 constraints；平台只决定密度（Windows 紧凑 / Android 舒适）与系统栏行为。

### 8.2 布局细节

| 区域 | 桌面 | 移动 |
|---|---|---|
| 顶栏 | 56：Logo 26 + GEARLAB + 器材研究所 + 居中本地说明 + 语言/主题 + 导入/导出 | 52：Logo 24 + GEARLAB + 导入图标 + 更多菜单 |
| 照片库 | 竖列表 64/行，序号、缩略图 52×39、文件名、元数据、hover 删除 | 横向胶片 78×58，序号角标，选中 2px 橙边 |
| 舞台 | `stage` 底、crop marks 四角、作品投影、顶部尺寸/底部文件名+比例+格式 | 高度 clamp(36% 屏高, 220, 320)，crop marks 简化 |
| 检查器 | 352/368；分区：相机模板/标题与文字/版面/相机背景/相机屏幕；底部 sticky 导出条 | 版面工具条（同步/重置）+ 五 Tab；内容滚动；底部 sticky 导出条 |
| 导出 | Dialog 570×最大 720，或独立 Sheet | 全屏 Sheet（底部安全区），大按钮 48 高 |

### 8.3 信息架构调整

- 桌面保留三栏，但删除设置区的 01–05 编号与英文眉题；改用 `GlSection` 标题 + 真实值。
- 移动端把设置拆成 5 个 Tab：相机 / 文字 / 版面 / 背景 / 屏幕；同步开关与重置放在 Tab 上方的工具条。
- 导出入口：桌面顶栏 + 检查器底部双入口（保持现有“导出当前/导出全部”）；移动端底栏双按钮 + 顶栏更多菜单。
- 语言/主题放在顶栏的“更多/显示设置”菜单中，移动端不占底栏空间。

---

## 9. 可访问性规范

| 项 | 要求 |
|---|---|
| 文字对比 | 正文 ≥4.5:1；大字号 ≥3:1 |
| 非文本对比 | 控件边界/焦点/选中 ≥3:1 |
| 命中区域 | Windows ≥40×40，Android ≥48×48，视觉图标可小于命中区 |
| 键盘 | Tab 顺序：顶栏 → 照片库 → 舞台 → 检查器 → 底部操作；所有按钮 Enter/Space；方向键在照片/模板条内移动；Delete 删除需确认；Ctrl+O/E/S 保留 |
| 焦点 | 2px `focus` 环 + 2px 间隙；不得被裁剪；Dialog 焦点陷阱与 Esc 关闭 |
| 语义 | 所有图标按钮、照片行、模板卡、色板、滑杆、自定义绘制器有 label/value/selected/actions |
| 屏幕阅读器 | 导入/导出开始/完成播报；错误通过 live region；作品预览给出尺寸与比例 |
| 大字体 | 1.0–2.0 文字缩放不裁切；固定高度改为 minHeight + Wrap/Scroll |
| 动效 | 尊重系统减少动效；无自动播放/闪烁 |
| 颜色 | 状态不只用颜色 |

---

## 10. 国际化的设计约束

- 默认语言：跟随系统；`zh*` → 中文，`en*` → 英文，其他 → 英文。
- 手动选择持久化；提供“跟随系统”选项。
- 英文文案比中文长 20–40%：按钮/标签使用 `Flexible`/`Wrap`，禁止固定宽度裁切；需要缩写的词（如 `Library`）在 ARB 中单独给短版 key。
- 所有数字、尺寸、百分比用 `intl` 格式化；单位 `PX`、`×`、`%` 保持；不拼接字符串，使用带占位符的 ARB。
- 海报内标题/副标题是用户内容，不翻译；相机品牌/型号是产品名，不翻译；导出文件名保持现有英文格式。
- 语言切换即时生效，不重启；日期/数字格式跟随 locale。

---

## 11. 视觉预览

预览使用真实素材（`docs/examples` 品牌语言 + 实际相机模板/照片/导出作品），不是示意图：

- 桌面浅色：`preview-desktop-light.png`（1440×900）
- 桌面深色：`preview-desktop-dark.png`
- 移动浅色：`preview-mobile-light.png`（390×844）
- 移动深色：`preview-mobile-dark.png`

预览的关键特征：无卡片套件的平面分栏、照片行/胶片条的真实序号、舞台的 crop marks 与纸面投影、检查器的细线分区、橙只出现在当前项与主操作、品牌词宽字距。它已经能读成“摄影师的排版台”，而不是通用 SaaS 后台。
