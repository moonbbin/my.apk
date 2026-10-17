# 🛡️ Compose UI 开发与主题适配终极规范（防翻车圣经）

> **适用范围**：本规范**仅适用于 `ui/music` 音乐专区**。不可越权修改主体（AVBox）的 `styles.xml` 或全局配置，除非用户明确下达“修改主体”的指令。

---

## 📌 一、 核心铁律（10 条）
1. **颜色全走 Token**：禁止写死颜色。必须全部走 `MaterialTheme.colorScheme.xxx` 或 `musicColors().xxx`。
2. **图标着色（Tint）动态化**：禁止在 `Icon` 中写死 `Color.White`。使用 `LocalContentColor.current` 或 `onSurfaceVariant`，防止浅色模式隐身。
3. **禁止写死图片占位背景**：Coil `AsyncImage` 的占位背景必须用 `surfaceVariant`，禁用写死的深灰色。
4. **边框与描边使用主题色**：禁止写死白色边框，统一使用 `outlineVariant` 或 `outline`，避免浅色模式下边框消失。
5. **禁止写死黑色阴影**：写死的黑色阴影在浅色模式下会显得脏。必须使用环境色 `onSurface.copy(alpha = 0.1f)`，或用极浅描边代替。
6. **弹窗与浮层适配**：Dialog 或 ModalBottomSheet 必须使用 `surface` 或 `surfaceContainerHigh`。
7. **渐变遮罩与透明度**：深色模式用黑渐变，浅色模式必须用白渐变或主题背景渐变，绝对禁止全局统一黑渐变。**（例外：图片上的文字罩纱 Scrim，允许双模式均使用黑渐变，以确保文字可读性）**。
8. **输入框全套适配**：容器色用 `surface`，光标色（Cursor）用 `primary`，提示文字（Placeholder）用 `onSurfaceVariant`。
9. **禁用态（Disabled）标准色**：必须使用 `onSurface.copy(alpha = 0.38f)`，禁止写死灰色。
10. **系统栏沉浸式适配**：必须动态计算 `isAppearanceLightStatusBars =!isDarkTheme`，确保图标随时反转。

---

## 🏷️ 二、 例外条款（唯一允许硬编码的地方）
1. **主题源头文件**：`Color.kt` 和 `LxMusicTheme.kt` 是定义色值的源头，**必须且只能**在这里使用 Hex（如 `Color(0xFF34C759)`）。
2. **绝对透明色**：允许直接使用 `Color.Transparent`。
3. **系统级绝对色**：如特定必须纯黑/纯白的遮罩，需确认后使用。

---

## 🌊 三、 高级体验补充条款（深水区）
1. **动态取色（Palette）校验**：提取的主色必须计算亮度（`ColorUtils.calculateLuminance`）。如果过亮或过暗，必须对文字颜色进行自动反转（极亮配黑字，极暗配白字）。
2. **沉浸式全屏状态栏**：如果背景是图片或渐变，状态栏图标颜色必须根据局部背景色动态反转，或加渐变护盾防穿透。
3. **丝滑换肤过渡**：如需平滑过渡，仅限顶层背景和主要卡片包裹 `animateColorAsState`（过渡时长 300ms）。**严禁在长列表（LazyColumn/Grid）的 item 中全量包裹，避免掉帧**。
4. **原生 View（AndroidView）穿透**：所有包裹的第三方原生组件（如 WebView、PlayerView），主题切换时必须手动同步其背景色，防“Compose 变白了，里面还是黑块”。

---

## 🕳️ 四、 终极隐藏坑（系统级防线）
1. **空状态插图（Empty State）**：无数据/无网络时的本地插图必须是透明底，且适配深浅双色，或通过 `Modifier.alpha` 强行压暗。
2. **WebView/H5 穿透**：加载网页时，需注入 CSS 或强制开启算法暗化，防止网页在深色模式下亮瞎眼。

---

## 🧠 五、 非视觉防线（性能与第三方）
1. **无障碍对比度**：浅色模式下的主色与文字对比度必须满足 WCAG AA 级标准，防止看不清。
2. **第三方 UI 库排异**：引入的第三方 Compose 组件必须包裹在主题 `Surface` 中，手动传入主题色。
3. **懒加载性能**：`LazyColumn` / `LazyVerticalGrid` 的列表 `item` **必须带上稳定的 `key`**，避免重组抖动。

---

## 🤖 六、 给 AI 的 Prompt 标准前缀（每次必须带）

> “在编写任何代码前，请严格遵守项目根目录 `.github/UI_SPEC.md` 中的《Compose UI 开发与主题适配终极规范》。
> 提醒：适用范围仅限 `ui/music`；除主题源头文件外，严禁硬编码颜色；图片上的 scrim 允许黑渐变；非列表容器不强求动画；懒加载列表必须带 key。
> 生成代码后，请自我审查并说明你的代码是如何满足这些铁律的。”
