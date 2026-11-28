# 05 · 测试、回归与验收

## 1. 测试策略

重构不是“改完再点一遍”，而是把“不能变的东西”先变成测试：

```text
业务不变性 ──▶ Phase 0 基线（golden / fixture / 截图 / 耗时）
                │
设计系统   ──▶ Token 对比度测试 + widget 状态测试
                │
页面/组件  ──▶ widget 布局测试 + 三断点/两语言/两主题测试
                │
平台/状态  ──▶ port fake 测试 + 状态迁移测试 + 手工真机清单
```

测试分层：

| 层 | 工具 | 范围 | 是否阻断合并 |
|---|---|---|---|
| 单元测试 | `flutter test` (dart) | naming、state codec、style clamp、locale resolve、color contrast | 是 |
| Golden | `matchesGoldenFile` | 海报像素、关键组件布局（可选） | 是（海报）；组件逐步 |
| Widget | `WidgetTester` | 三断点、两主题、双语、状态、焦点、命中区 | 是 |
| 集成/手工 | Windows + Android 真机/模拟器 | 导入/导出/拖拽/相册/返回/窗口 | 是（P7） |
| 性能 | DevTools / `flutter run --profile` | 滑杆、滚动、导出、首帧 | P6 gate |

---

## 2. Phase 0 基线（先于任何重构）

### 2.1 海报像素基线

目标：证明 **renderer 重构前后输出完全一致**。

- 新增 `test/regression/poster_golden_test.dart`：
  - 使用固定模板 `ricoh-gr4`、固定照片 fixture（建议 1:1 或 3:2 的真实 JPG，≤1080px）；
  - 标题固定英文（避免测试环境 CJK 字体差异），副标题留空；
  - 背景 `#FFFFFF`，`cameraScale=0.5`，`screenFit=fill`，`screenGlare=false`；
  - `PosterPlan.forWidth(1080)` 渲染到 `ui.Image`，编码 PNG；
  - `expect(pngBytes, matchesGoldenFile('goldens/poster_1080.png'))`。
- 生成后记录 **SHA-256**，写入测试注释：
  - `goldens/poster_1080.png` 的 hash；
  - 同时记录 2160 输出的 hash（可选，耗时更长，标记 `@Tags(['slow'])`）。
- 迁移 renderer（仅改 import/颜色来源）后再次运行；若像素不同，必须解释到具体字节，否则回退。

### 2.2 状态 fixture

新增 `test/fixtures/state_v1.json`，模拟真实 v1：

```json
{
  "version": 1,
  "syncAll": false,
  "selectedIndex": 1,
  "currentStyle": { "cameraId": "fujifilm-x100vi", "cameraScale": 0.56, "showTitle": true, "title": "Test", "subtitle": "Fixture", "screenFit": "fit", "screenGlare": true, "topColor": 4293980400 },
  "photos": [
    {"path": "/fixtures/a.jpg", "name": "a.jpg", "managed": true, "style": {...}},
    {"path": "/fixtures/b.jpg", "name": "b.jpg", "managed": false, "style": {...}}
  ]
}
```

测试只覆盖 codec/迁移，不要求真实文件存在；照片文件恢复另用临时目录集成测试。

### 2.3 导出文件名基线

`test/regression/export_naming_test.dart` 至少覆盖：

| 输入 | 期望 |
|---|---|
| 单张 `DSC_2435 Gold 200.jpg` + `Fujifilm GFX100RF` | `GearLab_01_DSC_2435_Gold_200_Fujifilm_GFX100RF.jpg` |
| 序号 ≥ 10 | `GearLab_10_...` |
| 非法字符 `/:*?"<>|` | 替换为 `_` |
| 同目录重名 | 追加 `_2`、`_3` |
| PNG | 扩展名 `.png` |
| 空/超长名称 | 长度上限、保留可读性 |

### 2.4 截图与耗时基线

- Windows 1360×860：照片库有 2 张、选中第 1 张、深色主题；
- Android 390×844：同上；
- 记录：启动到首帧、导入 4 张 2600px 照片、拖动相机大小 60 次、2160 导出一张的耗时。
- 存 `docs/ui-refactor/baseline/`。

---

## 3. 自动化测试矩阵

### 3.1 设计系统

| 测试 | 断言 |
|---|---|
| `design_system_test.dart` | 两套色板（light/dark） × `ink/surface`、`ink2/surface`、`ink3/surface`、`accent/surface`、`onAccent/accent`、`accentText/surface`、`focus/surface`、`lineStrong/surface` 达到文档阈值 |
| `gl_theme_test.dart` | 两套主题可构建；组件主题（button/input/slider/switch/dialog）无空值；无 `Colors.white/black` 硬编码 |
| `gl_type_test.dart` | 字阶单调；tabular figures enabled；11/13/17/22/28 存在 |
| `gl_breakpoints_test.dart` | 390/800/1280/1600 映射到 compact/medium/expanded/large；高度 360 → compact |

### 3.2 状态

| 测试 | 断言 |
|---|---|
| `state_codec_v1_test.dart` | 读取 v1 全部字段；未知字段忽略；损坏 JSON 不抛 |
| `state_codec_v2_test.dart` | v2 写入/读取；preferences 默认值；locale `null` 表示系统 |
| `state_migration_test.dart` | v1→v2：照片/样式/选中/同步不丢；preferences 默认；再次写入为 v2 |
| `style_settings_test.dart` | clamp 34–72；标题/副标题 80/120 限制；resolvedTitle 回退相机名；copyWith 相等性 |
| `photo_item_test.dart` | copyWith 不共享可变 style；managed 标志保持 |

### 3.3 导入/导出

| 测试 | 断言 |
|---|---|
| `export_naming_test.dart` | 见 2.3 |
| `export_service_test.dart` + fake destination | current/selected/all 的文件数；JPG/PNG 编码；quality 60/100；尺寸 1080/1440/2160；取消；单张失败不阻断其余 |
| `export_destination_test.dart` | Windows 写 `exports/`；Android 调 `Gal.putImage(album: 'GearLab')`；gallery 失败计入 errors；成功数正确 |
| `import_test.dart` + fake picker/decoder | 支持格式；目录递归；最长边 2600；复制到 managed 库；重复路径处理（保持现有行为） |
| `shortcuts_test.dart` | Ctrl+O/E/S、方向键、Delete 仍触发对应动作 |

### 3.4 i18n

| 测试 | 断言 |
|---|---|
| `arb_keys_test.dart` | zh/en key 完全一致；占位符一致；无空值 |
| `locale_resolve_test.dart` | `zh`/`zh_CN`→zh；`en`/`en_US`→en；`ja`→en；手动覆盖优先；`null` 跟随系统 |
| `no_hardcoded_cjk_test.dart` | `lib/presentation`、`lib/design`、`lib/app` 无 CJK（注释/测试/允许常量白名单除外） |
| `text_layout_test.dart` | 英文最长按钮/标签在 320/390 宽不溢出；中文不裁切 |

### 3.5 Widget/交互

| 测试 | 断言 |
|---|---|
| `editor_shell_test.dart` | 390/800/1280/1600 分别渲染单列/两栏/三栏；无 overflow |
| `theme_switch_test.dart` | Light/Dark 切换后颜色来自对应 Token；状态保持 |
| `language_switch_test.dart` | 切换后文案/数字格式更新；不重建业务状态 |
| `tap_target_test.dart` | 所有可点击元素命中 ≥40（Windows）/48（Android） |
| `semantics_test.dart` | 图标按钮/照片行/相机卡/色板/滑杆有 label/value/selected；焦点顺序 |
| `text_scale_test.dart` | 1.0/1.5/2.0 下检查器/顶栏/导出对话框无裁切，可滚动 |
| `reduced_motion_test.dart` | `disableAnimations` 时动画时长 0 |
| `empty_state_test.dart` | 无照片/无选择/导出空集合有明确 CTA |

### 3.6 性能

| 测试/检查 | 目标 |
|---|---|
| 拖动相机大小滑杆 | 只重建舞台相关子树，不重建照片库/顶栏（通过 `debugPrintRebuildDirtyWidgets` 或 profile 观察） |
| 37 模板横向滚动 | 60fps，无 `shouldRepaint => true` 造成的持续重绘 |
| 2160 导出 4 张 | 相对 Phase 0 基线耗时 +10% 以内（同机同素材） |
| 首帧 | 与基线持平（±100ms） |
| 内存 | 4 张 2600px 照片 + 37 模板 ≤ 基线 +10% |

---

## 4. 手工验收矩阵

### 4.1 环境

| 平台 | 尺寸 | 主题 | 语言 |
|---|---|---|---|
| Windows 11 | 1360×860（默认）、960×640（最小）、1440×900 | 系统浅/系统深/手动浅/手动深 | 中文/英文 |
| Android 14（真机/模拟器） | 390×844（竖）、800×360（横） | 同上 | 同上 |
| Android 7/API 24（若可得） | 390×844 | 浅/深 | 中文 |

### 4.2 核心路径清单

- [ ] 首次启动：空状态、导入 CTA、无控制台错误。
- [ ] Windows 导入：文件选择、拖拽 1 张、拖拽文件夹、拖拽混合格式。
- [ ] Android 导入：文件选择、多选；权限拒绝路径提示清楚。
- [ ] 照片库：选中、删除、清空、全选（若保留）、计数、缺失文件跳过。
- [ ] 模板：37 个全部可点、箭头/滚轮/拖动/键盘；选中状态不只用颜色。
- [ ] 标题：显示/隐藏、空值回退相机名、80/120 限制、中英输入、IME 正常。
- [ ] 版面：相机大小 34%/50%/72% 边界、比例信息。
- [ ] 背景：8 预设、自定义取色器（SV/色相/alpha/HEX）、取消/确定、重启恢复。
- [ ] 屏幕：填满/完整、反光开关、模板 inset 差异（Sony α7C II / Lumix S9）。
- [ ] 同步全部开/关：逐张样式独立/恢复。
- [ ] 导出：当前/全部、1080/1440/2160、JPG 60/100、PNG、取消、空相册、错误提示。
- [ ] Windows 导出目录：`exports/` 文件数量/名称/尺寸正确；重名不覆盖。
- [ ] Android 相册：`GearLab` 相簿出现、数量正确、分享可用。
- [ ] 状态恢复：关闭重启后照片/选中/样式/主题/语言恢复；损坏 state 不影响启动。
- [ ] 快捷键：Ctrl+O/E/S、方向键、Delete、Esc。
- [ ] 窗口：最小 960×640；拉伸三断点；标题栏明暗与 App 一致。
- [ ] Android 系统：edge-to-edge、状态栏图标明暗、返回键先关浮层、预测性返回。
- [ ] 语言切换：中文↔英文即时生效；英文长文案不裁切；数字/计数格式正确。
- [ ] 主题切换：系统浅/深、手动覆盖、重启保持；无首帧白闪/黑闪。
- [ ] 大字体/屏幕阅读器：1.5/2.0 缩放；TalkBack/Narrator 可读完全部控件。
- [ ] 性能：滑杆、37 模板滚动、2160 导出、4 张批量导出。

### 4.3 视觉核对

- [ ] 1440×900 与 `preview-desktop-light/dark.png` 的结构、层级、间距一致（允许字体渲染差异）。
- [ ] 390×844 与 `preview-mobile-light/dark.png` 一致（预览高度、胶片条、五 Tab、底栏）。
- [ ] 橙色只出现在选中/主操作/进度/焦点；没有装饰性橙色。
- [ ] 面板无圆角嵌套卡片；分割线一致；舞台 crop marks/投影一致。
- [ ] 明暗主题切换时照片/海报内容不变；海报像素不被主题影响。

---

## 5. 验收标准

### 5.1 硬性验收（全部满足才通过）

| # | 标准 | 判定方式 |
|---|---|---|
| A1 | 跨平台规范一致 | Windows 最小 960×640、紧凑密度、标题栏跟随、键盘/悬停；Android 48dp、edge-to-edge、返回；手工清单 |
| A2 | UI 还原一致 | 四张预览结构/层级/间距一致；截图对比；无破版 |
| A3 | 组件复用率提升 | `Gl*` 组件 ≥24；主要交互控件 ≥60% 来自组件库；`main.dart` <100 行 |
| A4 | 核心路径无回归 | 海报 golden 逐像素；导出文件名/数量/尺寸/格式；状态恢复；catalog 测试；手工核心路径 |
| A5 | 代码质量改善 | `flutter analyze` 0 issue；全部测试通过；presentation/domain 无平台/插件引用；无 `shouldRepaint => true` |
| A6 | 主题与语言 | 默认跟随系统；Light/Dark 可手动覆盖并持久化；zh/en 完整、即时切换 |
| A7 | 可访问性 | 文字/非文字对比达标；命中区达标；语义/焦点/键盘；1.5/2.0 缩放不裁切 |
| A8 | 性能不退化 | 滑杆/滚动/导出/首帧相对基线在阈值内；无整页重建 |

### 5.2 量化阈值

| 指标 | 阈值 |
|---|---|
| `flutter analyze` | 0 issue |
| 测试 | 100% 通过；新增单测覆盖 domain/state/naming/i18n |
| 海报 golden | PNG 字节完全一致 |
| 导出文件 | 文件名/数量/尺寸/格式/画质与基线一致 |
| 主要交互控件复用 | ≥60% |
| `main.dart` | <100 行 |
| `lib/presentation` + `lib/domain` 平台引用 | 0 |
| 硬编码 CJK（除 ARB/白名单） | 0 |
| `shouldRepaint => true` | 0 |
| 对比度 | 正常主题正文 ≥4.5:1；非文本 ≥3:1 |
| 2160 导出耗时 | 基线 +10% 以内 |
| 4 张批量导出内存 | 基线 +10% 以内 |

### 5.3 视觉验收截图（P7 产出）

| 文件 | 内容 |
|---|---|
| `screens/windows-light-zh.png` | 1360×860 浅色中文 |
| `screens/windows-dark-zh.png` | 1360×860 深色中文 |
| `screens/windows-light-en.png` | 1360×860 浅色英文 |
| `screens/android-light-zh.png` | 390×844 浅色中文 |
| `screens/android-dark-en.png` | 390×844 深色英文 |
| `screens/export-dialog.png` / `screens/mobile-export-sheet.png` | 导出浮层 |
| `screens/empty-state.png` | 空状态 |

---

## 6. 风险与缓解

| 风险 | 概率 | 影响 | 缓解 |
|---|---|---|---|
| 视觉“换皮不换骨” | 中 | 验收不过 | Token 先行；组件状态矩阵；预览先评审；删除旧常量 |
| 海报像素回归 | 中 | 致命 | Phase 0 golden；renderer 只改依赖不改绘制；每阶段跑 |
| 导出行为回归 | 中 | 致命 | naming 测试；destination fake；Windows/Android 真机相册验证 |
| 状态迁移丢数据 | 低 | 致命 | v1 fixture；迁移测试；迁移前备份；旧代码仍可读 v2 |
| 英文/大字体破版 | 中 | 高 | 英文最长文案表；minHeight/Wrap/Scroll；1.5/2.0 测试 |
| Windows 标题栏/最小尺寸原生改动 | 中 | 中 | 原生改动最小化；失败则保留原生标题栏只做 min size；单独回退 |
| Android edge-to-edge 兼容 API 24 | 中 | 中 | 按 SDK 分支；`SystemChrome` 回退；API 24 真机/模拟器验证 |
| 组件过度抽象 | 中 | 中 | 只抽实际复用；组件只暴露使用中的属性；避免“万能组件” |
| 重构周期拉长 | 中 | 中 | 阶段可演示；P0–P3 优先；P6 可拆到下一迭代但不影响验收核心 |
| 主题切换首帧闪烁 | 中 | 低 | 启动时先读偏好再 runApp；原生 chrome 先设；避免异步首帧 |
| 中文/English 字体回退不一致 | 低 | 低 | 不打包字体；`fontFamilyFallback`；截图对比；不做像素级跨平台断言 |

---

## 7. 完成定义（Definition of Done）

一个阶段完成，必须同时满足：

1. 代码已提交，提交信息带 Phase；
2. `flutter analyze` 0 issue；
3. 相关测试通过，且未跳过既有测试；
4. 手工冒烟：导入 → 编辑 → 导出 → 重启恢复；
5. 截图/产物归档到 `docs/ui-refactor/screens/<phase>/`；
6. 已知问题记录在阶段总结中，不隐藏；
7. 若涉及 renderer/导出/状态，必须附 golden/迁移测试结果。

全部阶段完成后，以第 5 节验收标准做最终签收；签收前不合并到 `main`（或按仓库约定打 tag/release）。
