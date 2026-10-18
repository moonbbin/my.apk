# 📘 音乐专区 主题架构与接入规范（纯净版）

> **💡 规范定位**：本手册专门针对音乐专区的"颜色、主题、卡片、状态栏"底层架构。
> **适用场景**：新增页面、重构旧代码、排查"切主题失效"、全局换肤。
> *（注：关于动效、无障碍、折叠屏等通用 UX 规范，请见 `UI_UX_GUIDE.md`）*

---

## 📌 第一章：底层架构与数据流
主题系统采用**"单一数据源 + 自定义桥接"**架构：
1. **数据源**：`MusicThemeManager.isDarkTheme` (存于 **SharedPreferences: music_theme_prefs**，并非 DataStore)。
2. **桥接层**：`LxMusicTheme.kt` 映射 `Dark/LightMusicColors` 至 `MaterialTheme`，并向下传递 `musicColors()`。
3. **UI 层**：强制统一使用 `musicColors().xxx` 读取颜色。

## 📌 第二章：新增页面标准接入流程
每新增独立 Activity，**必须且只能**执行这 4 步：
1. **状态注入**：使用 `val isDark by MusicThemeManager.isDarkTheme`（禁用 `collectAsState`）。
2. **主题包裹**：最外层用 `LxMusicTheme(isDarkTheme = isDark) {...}` 包裹。
3. **状态栏适配**：根布局加 `SideEffect`，执行 `isAppearanceLightStatusBars =!isDark`。
4. **根背景**：根节点强制指定 `musicColors().background`。

## 📌 第三章：全局换肤指南
1. 修改 `Color.kt` 中的主色变量（如 `BrandGreen`）。
2. 根据主色冷暖，微调 `LightBgBase` 等背景底色。
3. ****：严禁让 AI 全局使用 `sed` 批量替换 Hex 色值（极易导致编译失败）。必须由开发者或 AI 针对具体页面进行代码级排查修改。
4. 全 App 即刻生效，无需修改任何组件代码。

## 📌 第四章：常见"隐疾"与对症下药
* 🚨 **切主题没反应** ➡️ 替换为 `LxMusicTheme`，确保状态是 `by` 委托。
* 🚨 **浅色下文字/图标隐身** ➡️ 替换为 `musicColors().textPrimary`，图标用 `LocalContentColor.current`。
* 🚨 **弹窗背景是黑的** ➡️ 强制指定 `containerColor = musicColors().card`。
* 🚨 **图片上的标签看不清** ➡️ 写死黑底 `Color.Black.copy(alpha=0.65f)` + 白字 + 白描边（允许硬编码，无视主题变化）。
* 🚨 **状态栏电池/时间消失** ➡️ 补上 `SideEffect` 中的 `isAppearanceLightStatusBars` 反转。

## 📌 第五章：免死金牌组件封装（源头防呆）
从源头封装标准组件，让 AI 只能调用，杜绝写死：
1. **`LxCard`**：使用 `Surface(color = musicColors().card)` 或 `Card(colors = CardDefaults.cardColors(containerColor = musicColors().card))`。**警告：Material3 的 `Card` 没有 `color` 参数，严禁写成 `Card(color=...)`！**
2. **`LxTopBar`**：内部强制处理状态栏反转和透明背景。
3. **`LxScrimTag`**：图片上的播放量标签，内部写死黑底白字和极细白描边。

## 📌 第六章：Compose 预览双检法
**指令标准**：强制要求 AI 为每个 UI 组件提供两套 `@Preview`：
* **浅色**：`@Preview(showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_NO)`
* **深色**：`@Preview(showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)`

## 📌 第七章：CI 静态扫描防线（文本扫描，非代码修改）
在 Shell 构建脚本中加入 `grep` 拦截（*注：此处的 grep 属于 CI 文本扫描，与修改代码时禁用的 sed 语法正则不同*）：
```bash
# 检查是否有人写了死颜色（排除 Scrim 例外和 OverlayTextWhite）
if grep -rn "Color.White" app/src/main/java/com/github/tvbox/osc/ui/music/ | grep -v "OverlayTextWhite" | grep -v "Scrim" | grep -v "LxScrimTag" | grep -v "LxMusicTheme.kt"; then
echo "❌ 发现硬编码 Color.White，违反规范！"; exit 1
fi
if grep -rn "Card(.*color\s*=" app/src/main/java/com/github/tvbox/osc/ui/music/; then
echo "❌ 发现违规使用 Card(color=...)，请用 colors = CardDefaults.cardColors(...)"; exit 1
fi
# 检查是否有人写死了黑背景（深色模式也走 token，写死黑必死）
if grep -rn "background(Color.Black)" app/src/main/java/com/github/tvbox/osc/ui/music/ | grep -v "Scrim" | grep -v "Overlay"; then
echo "❌ 发现写死黑背景，违反规范！"; exit 1
fi
```

---

## 📌 附录：给 AI 的 Prompt 准入前缀

"严格遵守.github/THEME_SKILL_BOOK.md：

1. 独立 Activity 包 LxMusicTheme + SideEffect 状态栏反转。
2. 颜色走 musicColors()，禁写死黑白（Scrim 标签除外）。
3. 弹窗传 containerColor，图片标签用 LxScrimTag。
4. 修改庞大 Kotlin 文件严禁用 sed 盲改，必须基于真实源码全量覆盖。
5. Card 背景色必须用 colors = CardDefaults.cardColors(...)。"
