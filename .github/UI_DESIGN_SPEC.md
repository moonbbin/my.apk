# 🎨 音乐专区 UI 开发与视觉设计规范（大厂级防翻车圣经）

> **🚨 适用范围（强约束）**：
> 本规范适用于所有 `ui/music` 音乐专区的 Compose 页面。
> **工程策略**：本规范为**新代码的准入标准**。存量老页面按本规范逐步重写，不允许为了改规范而强行推翻现有业务逻辑。

---

## 📌 一、 核心铁律（10 条防翻车底线）
1. **颜色全走 Token**：禁止出现 `Color.Black`、`Color.White` 或 `Color(0xFF...)`（除非在例外条款中）。必须走 `musicColors().xxx`。
2. **图标着色（Tint）动态化**：禁止写死 `Color.White`。使用 `LocalContentColor.current` 或 `musicColors().textPrimary`，防浅色模式隐身。
3. **禁止写死图片占位背景**：Coil `AsyncImage` 占位图必须用 `musicColors().cardSecondary`，禁用深灰色。
4. **边框与描边**：禁止随便写死白色边框，统一使用 `musicColors().divider`。（例外条款除外）。
5. **禁止写死黑色阴影**：浅色模式下死黑阴影会显脏。使用 `shadow(2.dp)`，或依赖边框区分层级。
6. **弹窗与浮层适配**：`AlertDialog` 和 `ModalBottomSheet` **必须**显式指定 `containerColor = musicColors().card`。
7. **系统栏沉浸式适配**：必须在 Activity 中动态设置 `isAppearanceLightStatusBars = !isDarkTheme`。
8. **输入框全套适配**：容器色 `musicColors().card`，光标色 `musicColors().accent`，提示文字 `textSecondary`。
9. **禁用态（Disabled）标准色**：使用 `textPrimary.copy(alpha = 0.38f)`。
10. **无死角包裹**：所有独立 Activity 必须用 `LxMusicTheme` 包裹，并强制走 `musicColors()` 防主题断层。

## 🏷️ 二、 例外条款（允许硬编码的地方）
1. **主题源头**：`Color.kt` 和 `LxMusicTheme.kt`。
2. **绝对透明**：`Color.Transparent`。
3. **图片文字罩纱（Scrim）**：压在封面图上的播放量/时长标签，**必须写死** `Color.Black.copy(alpha = 0.65f)` 背景和 `Color.White` 文字。同时**允许写死** `BorderStroke(0.5.dp, Color.White.copy(alpha = 0.3f))` 描边，以保证在复杂底图上依然清晰。

---

## 📌 三、 设计系统与排版（Design System）
**前提确认**：字体排版请优先使用 `MaterialTheme.typography`（前提是已在 `LxMusicTheme` 中打通桥接）。若未接通，请直接使用 `TextStyle` 定义。

*   **页面大标题**：28sp, Bold，颜色 `textPrimary`。
*   **卡片标题/歌名**：18sp, Medium/SemiBold，颜色 `textPrimary`，最多 2 行 `Ellipsis`。
*   **副标题/歌手**：14sp, Normal，颜色 `textSecondary`，最多 1 行。
*   **极小标签**：11sp/12sp，颜色跟随容器。
*   **圆角规范**：大卡片/弹窗 `16.dp`；小卡片/封面 `12.dp`；胶囊按钮 `24.dp`；极小标签 `4.dp`。
*   **间距系统**：必须为 4 的倍数（推荐 8 的倍数）。屏幕边距 `16.dp`，列表间距 `8.dp/12.dp`。

## 📌 四、 状态兜底规范
*   **分类标签**：选中态 `musicColors().accent` 底 + `musicColors().accentText` 字；未选中 `cardSecondary` 底 + `textSecondary` 字。
*   **空数据/断网**：标题 `textPrimary`，描述 `textSecondary`。禁止黑底黑字，必须提供重试按钮。

---

## 🤖 五、 给 AI 的 Prompt 准入前缀（务必极简，防忽略）

> “严格遵守 `.github/UI_DESIGN_SPEC.md`：
> 1. 禁写死颜色/字号/圆角，全走 Token。
> 2. 图标必须动态 Tint。
> 3. 卡片/弹窗背景走 `musicColors().card`。
> 4. 图片遮罩标签写死黑底白字+白描边。
> 5. 独立 Activity 必须包 `LxMusicTheme` 并配状态栏。”
