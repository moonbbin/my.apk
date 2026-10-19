# 💻 Compose 代码编写与工程底线铁律（防闪退/防卡顿/防状态残留）

> **💡 规范定位**：本手册是 `.github/UI_DESIGN_SPEC.md` 的代码级实现标准。
> **核心宗旨**：严禁使用会导致 UI 失去响应、编译报错、内存泄漏或出现隐身的 API 写法。所有状态必须响应式，所有组件必须类型安全。

---

## 📌 第一章：状态管理与数据流（防"切歌不刷新"惨案）
1. **`remember` 必须绑定唯一标识（Key）**：如果 UI 状态（如红心是否点亮、当前音质）依赖特定实体（如 `songId`），不能只用普通的 `remember`。
   * ❌ 错误：`var isFav by remember { mutableStateOf(false) }`（切歌永远不变）
   * ✅ 正确：`LaunchedEffect(songId) { isFav = ... }` 或 `val isFav by remember(songId) { ... }`
2. **强制响应式流**：底层数据（音质、进度、当前歌曲）必须通过 `StateFlow` 暴露，并在 UI 层使用 `collectAsStateWithLifecycle()` 或 `collectAsState()` 收集。严禁在 UI 层用普通变量接一次数据就不管。
3. **切歌/状态重置**：播放器切歌时（`onMediaItemTransition`），必须无条件清空上一首的 `currentQuality`、`measuredBitrate`，再触发新的数据拉取，防止 UI 串台。

## 📌 第二章：Compose 组件避坑指南（防编译报错）
1. **彩色 Emoji 绝对禁用**：严禁在 `Text` 中使用彩色 Emoji（如 `"⏸"`, `"🔁"`, `"❤️"`）充当图标。
   * ❌ 错误：`Text("⏸", color = Color.White)`（在某些系统上它永远是原生橙色，无视 color 参数）
   * ✅ 正确：`Icon(imageVector = Icons.Filled.Pause, tint = Color.White)`
2. **Material3 的 `Card` 没有 `color` 参数**：
   * ❌ 错误：`Card(color = musicColors().card)`
   * ✅ 正确：`Card(colors = CardDefaults.cardColors(containerColor = musicColors().card))` 或直接用 `Surface(color = ...)`
3. **`by` 委托的正确位置**：`by` 只能用于变量声明，严禁直接写在函数调用的参数里。
   * ❌ 错误：`Theme(isDark = by Manager.isDark)`
   * ✅ 正确：`val isDark by Manager.isDark` 然后 `Theme(isDark = isDark)`
4. **颜色转码防丢**：使用 `calculateLuminance` 时，必须转成 `Int`。
   * ✅ 正确：`calculateLuminance(animatedTint.toArgb())`

## 📌 第三章：Modifier 顺序死规（防 UI 变形）
在 Compose 中，`Modifier` 的书写顺序会直接改变渲染结果。全项目统一使用以下标准顺序：
1. **阴影与裁剪**：`Modifier.shadow(8.dp).clip(RoundedCornerShape(16.dp))`（阴影在外面，写反会被裁切消失）。
2. **背景与点击**：`Modifier.background(...).clickable { ... }`（背景不会被水波纹盖住）。
3. **边距与背景**：统一使用 `Modifier.background(...)` 在 `padding` 之前。即：红底铺满，内边距留白。

## 📌 第四章：性能与重组（防卡顿/OOM）
1. **禁止在 Lazy 列表 Item 中加动画**：`LazyColumn` / `LazyRow` 的 `item` 内部严禁使用 `animateColorAsState`、`AnimatedVisibility`，否则滑动时必定严重掉帧。动画只能放在页面根节点、顶栏或底部控制栏。
2. **Lazy 列表的 Key 必须唯一且稳定**：**严禁使用 `index` 作为 key**，必须使用数据自身的唯一 ID。
   * ✅ 正确：`items(list, key = { it.id })`
   * （注：用 `index` 会导致删除或插入数据时，UI 状态错位、红心串台）。
3. **Coil 图片尺寸限制**：加载封面图必须限制尺寸（如 `Modifier.size(64.dp)` 或通过 `ImageRequest.size()`）。严禁直接把原图拉进内存，否则遇到高清大图必定 OOM 闪退。
4. **协程作用域隔离**：网络请求、音频验真必须在 `viewModelScope` 或 `Dispatchers.IO` 中进行。**严禁使用 `GlobalScope.launch`**。

## 📌 第五章：生命周期与交互安全（防闪退/防连点）
1. **ExoPlayer 生命周期**：播放器实例必须在 `onCleared()`（ViewModel）或 `onDestroy()`（Activity）中调用 `release()`，防止底层解码器内存泄漏。严禁在每次切歌时 `new` 一个新的 ExoPlayer。
2. **防连点与防页面堆叠**：在触发 `navController.navigate(...)` 的地方，必须配合防抖或状态锁（`if (isNavigating) return`），或使用 `launchSingleTop = true`。网络请求按钮点击后必须立刻进入 `Loading/Disabled` 状态。
3. **Kotlin 强解包（`!!`）禁令**：严禁对可能为 `null` 的对象使用 `!!`。必须使用安全调用 `?.` 或提供默认值 `?: ""`。

## 📌 第六章：日志、异常与国际化（防无头苍蝇）
1. **异常处理边界**：
   * **业务逻辑**（网络、播放、验真）：严禁空 `catch`，必须 `Log.e` 打印堆栈。
   * **非关键 UI 兜底**（如状态栏沉浸式设置）：允许使用 `catch (_: Exception) {}`，但必须加注释说明原因（防特定机型闪退）。
2. **统一日志 TAG**：所有日志的 TAG 必须统一前缀（如 `"LxPlayer"`, `"LxNetwork"`），方便通过 `adb logcat -s LxPlayer` 一键过滤。
3. **敏感数据脱敏**：打印日志时，严禁把 URL 里的 `auth_key`、`token`、用户 `card_key`（卡密）打印出来。
4. **字符串国际化**：
   * **新写代码**：优先将文字放入 `res/values/strings.xml` 并通过 `stringResource()` 调用。
   * **存量代码**：允许硬编码中文，逐步迁移，不阻塞正常发布构建。

## 📌 第七章：图标与主题（防"橙色幽灵"）
1. **图标必须绑定动态 Tint**：所有 `Icon` 必须有明确的 `tint`，优先使用 `musicColors().accent`、`musicColors().textPrimary` 或 `LocalContentColor.current`。
2. **禁止硬编码任何 Hex**：杜绝 `Color(0xFFFF8C00)`，除非是图片 scrim 遮罩等明确被豁免的特例。

---

## 🤖 给 AI 的 Prompt 准入前缀（代码审查专项）

> "在生成任何 Compose 代码前，请严格遵守 `.github/CODE_SPEC.md`：
> 1. 状态必须绑定 `songId` 或使用 `LaunchedEffect` 重置。
> 2. 禁用彩色 Emoji 当图标，必须用 `Icon` + `tint`。
> 3. 禁用 `Card(color=)`，必须用 `colors = CardDefaults...`。
> 4. 颜色计算别忘 `.toArgb()`。
> 5. 复杂文件（>50行）禁用 sed，必须 Python 带断言替换或 `cat` 全量覆盖。"
