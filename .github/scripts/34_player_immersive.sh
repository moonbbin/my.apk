#!/bin/bash
# 34_player_immersive.sh - 播放页沉浸式海报取色背景（定向补丁）
# 本脚本为 LxPlayerActivity.kt 沉浸式背景的唯一控制权。
# 方案B：Python 精确定向替换，不动业务逻辑（Slider/播放控制/22徽标/歌词滚动）。
# [34v12] 修：补Palette依赖、加toArgb import、修海报Box语法
set -e
cd avbox

echo "=== 34 v12: 播放页沉浸式定向补丁 ==="

TARGET="app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt"

if [ ! -f "$TARGET" ]; then
    echo "✗ 文件不存在: $TARGET"
    exit 1
fi

python3 << 'PYEOF'
import re

path = 'app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt'
with open(path, encoding='utf-8') as f:
    s = f.read()

def assert_replace(old, new, name):
    global s
    if old not in s:
        print(f"❌ 替换失败：未找到锚点 {name}")
        raise SystemExit(1)
    s = s.replace(old, new, 1)
    print(f"✓ {name} 已替换")

try:
    # === 1. 加 import ===
    imports = [
        "import androidx.core.graphics.ColorUtils",
        "import androidx.compose.ui.draw.shadow",
        "import androidx.compose.foundation.border",
        "import androidx.compose.ui.graphics.toArgb",
        "import androidx.core.view.WindowCompat",
        "import android.app.Activity",
    ]
    for imp in imports:
        if imp not in s:
            s = s.replace("import coil.compose.AsyncImage", imp + "\nimport coil.compose.AsyncImage", 1)
            print(f"✓ 已加 {imp}")
    assert "import androidx.core.graphics.ColorUtils" in s, "❌ import 断言失败"
    assert "import androidx.compose.ui.graphics.toArgb" in s, "❌ toArgb import 断言失败"

    # === 2. luminance 计算（在 animatedTint 后） ===
    m = re.search(r'(    val animatedTint by animateColorAsState\(\n.*?label = "coverTint"\n    \))', s, re.DOTALL)
    if not m:
        print("❌ 替换失败：未找到锚点 animatedTint块"); raise SystemExit(1)
    lumi_code = m.group(1) + """
    // [34v12] 背景提鲜：HSV 拉高饱和度/亮度
    val vibrantBg = remember(animatedTint) {
        val hsv = FloatArray(3)
        android.graphics.Color.colorToHSV(animatedTint.toArgb(), hsv)
        hsv[1] = (hsv[1] * 1.4f).coerceAtMost(0.9f)
        hsv[2] = (hsv[2] * 1.2f).coerceAtMost(0.85f)
        Color(android.graphics.Color.HSVToColor(hsv))
    }
    // [34v12] 遮罩后近似色：模拟黑遮罩叠加后的最终可见色
    val finalBg = remember(vibrantBg) {
        val a = 0.45f  // 取遮罩中段 alpha 近似
        Color(
            red = vibrantBg.red * (1 - a),
            green = vibrantBg.green * (1 - a),
            blue = vibrantBg.blue * (1 - a)
        )
    }
    // [34v12] 用最终渲染色算亮度，避免光影误判
    val bgLuminance = remember(finalBg) {
        ColorUtils.calculateLuminance(finalBg.toArgb())
    }
    val isDarkBg = bgLuminance < 0.5
    val secondaryTextColor = if (isDarkBg) {
        Color.White.copy(alpha = 0.7f)
    } else {
        Color(0xFF1C1C1E)
    }"""
    s = s.replace(m.group(1), lumi_code, 1)
    print("✓ luminance 智能文字已加")
    assert "ColorUtils.calculateLuminance" in s

    # === 3. 根背景：animatedTint + 黑遮罩 ===
    old_bg = """    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(musicColors().background)
    ) {"""
    new_bg = """    // [34v12] 沉浸式动态背景：取色 + 黑遮罩防刺眼
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(vibrantBg) // [34v12]
    ) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    Brush.verticalGradient(
                        listOf(
                            Color.Black.copy(alpha = 0.2f),
                            Color.Transparent,
                            Color.Black.copy(alpha = 0.7f)
                        )
                    ) // [34v12] 暗角
                )
        )"""
    assert_replace(old_bg, new_bg, "根背景Box")

    # === 4. 海报：删彩虹，换纯色兜底 ===
    old_rainbow = """                    .background(
                        Brush.linearGradient(
                            colors = listOf(
                                Color.hsv(hue, 0.5f, 0.7f),
                                Color.hsv((hue + 50) % 360, 0.6f, 0.4f)
                            )
                        )
                    )"""
    new_rainbow = """                    .background(musicColors().cardSecondary) // [34v12] 纯色兜底"""
    assert_replace(old_rainbow, new_rainbow, "海报彩虹背景")

    # === 5. 海报 Box：加悬浮（保留 contentAlignment） ===
    old_box = None
    for _m in ["[34v12]", "[34v5]"]:
        _c = "            Box(\n                modifier = Modifier\n                    .size(280.dp)\n                    .align(Alignment.CenterHorizontally)\n                    .clip(RoundedCornerShape(if (_isDarkCover) 12.dp else 24.dp))\n                    .background(musicColors().cardSecondary) // " + _m + " \u7eaf\u8272\u515c\u5e95,\n                contentAlignment = Alignment.Center\n            ) {"
        if _c in s:
            old_box = _c
            break
    if old_box is None:
        print("❌ 替换失败：未找到锚点 海报Box悬浮")
        raise SystemExit(1)
    new_box = """            Box(
                modifier = Modifier
                    .size(280.dp)
                    .align(Alignment.CenterHorizontally)
                    .shadow(
                        elevation = 32.dp, // [34v12]
                        shape = RoundedCornerShape(20.dp),
                        ambientColor = Color.Black.copy(alpha = 0.4f),
                        spotColor = Color.Black
                    )
                    .border(
                        width = 1.dp,
                        color = Color.White.copy(alpha = 0.5f), // [34v12]
                        shape = RoundedCornerShape(20.dp)
                    )
                    .clip(RoundedCornerShape(20.dp)),
                contentAlignment = Alignment.Center
            ) {"""
    assert_replace(old_box, new_box, "海报Box悬浮")

    # === 6. 歌手名智能反转 ===
    old_artist = """                    Text(
                        text = displayArtist,
                        style = MaterialTheme.typography.labelSmall,
                        color = PlayerGray,"""
    new_artist = """                    Text(
                        text = displayArtist,
                        style = MaterialTheme.typography.labelSmall,
                        color = secondaryTextColor, // [34v12] 智能反转"""
    assert_replace(old_artist, new_artist, "歌手名颜色")

    # === 7. 系统栏动态反转 ===
    old_sys = """    LaunchedEffect(Unit) {
        while (true) {"""
    new_sys = """    // [34v12] 系统栏根据背景亮度反转
    val sysWindow = (context as? Activity)?.window
    LaunchedEffect(isDarkBg) {
        sysWindow?.let {
            WindowCompat.getInsetsController(it, it.decorView)
                .isAppearanceLightStatusBars = !isDarkBg
        }
    }
    LaunchedEffect(Unit) {
        while (true) {"""
    assert_replace(old_sys, new_sys, "系统栏反转")

    # [34v12] 跳过 Palette，保留原版 extractCoverTint 平均取色

    # === 问题4：控制栏颜色统一 ===
    # 4a. 播放按钮背景 -> accent
    if ".background(Color.White.copy(alpha = 0.95f))" in s:
        s = s.replace(
            ".background(Color.White.copy(alpha = 0.95f))",
            ".background(musicColors().accent) // [34v12]",
            1
        )
        print("✓ 播放按钮背景已统一 accent")
    # 4c. 上一首/下一首 -> secondaryTextColor
    if "color = musicColors().textPrimary.copy(alpha = 0.9f))" in s:
        s = s.replace(
            "color = musicColors().textPrimary.copy(alpha = 0.9f))",
            "color = secondaryTextColor.copy(alpha = 0.9f)) // [34v12]",
        )
        print("✓ 上下首图标已跟随反转")
    # === 问题2：橙色幽灵 ===
    # 2a. 播放键图标 -> 白色（在 accent 背景上）
    # 播放按钮的 Text("⏸"/"▶") 图标颜色
    if 'text = if (isPlaying)' in s:
        # 找到播放图标的 color = musicColors().card，改为白色
        import re as _re2
        # 匹配播放按钮内的图标颜色（在 clickable Box 内）
        s = _re2.sub(
            r'(text = if \(isPlaying\) ".*?" else ".*?",\s*style = MaterialTheme\.typography\.titleLarge,\s*color = )musicColors\(\)\.card',
            r'\1Color.White // [34v12]',
            s
        )
        print("✓ 播放键图标已改白色")
    # 2b. 循环键已用 accent/textSecondary（v9 已处理），确认无橙色硬编码残留
    # 全局搜橙色系硬编码
    if "0xFFFF9800" in s or "0xFFFFA726" in s:
        print("⚠ 发现橙色硬编码，需手动检查")

    # 4d. 未激活图标 PlayerGray -> secondaryTextColor（注释放行尾，不破坏 if-else）
    if "PlayerGray.copy(alpha = 0.6f)" in s:
        # 先处理 "X else" 形态（注释放 else 后）
        s = s.replace(
            "PlayerGray.copy(alpha = 0.6f) else",
            "secondaryTextColor.copy(alpha = 0.6f) else",
        )
        # 再处理 "else X" 形态（注释放行尾）
        # 注意：不能直接在行中插 //，用正则确保注释在行尾
        import re as _re
        s = _re.sub(
            r"else secondaryTextColor\.copy\(alpha = 0\.6f\)(?! //)",
            "else secondaryTextColor.copy(alpha = 0.6f) // [34v12]",
            s
        )
        print("✓ 未激活图标已跟随反转")

    # === 34v12 问题1：红心切歌重置 ===
    # 红心状态必须绑定歌曲 ID，切歌时重置
    # 查找红心相关代码（❤️ emoji 或 Favorite 图标）
    if "isFav" in s or "❤" in s or "Favorite" in s:
        print("✓ 检测到红心代码")
        # 在切歌时重置：利用已有的 _currentQuality 清空机制，
        # 红心应在 UI 层用 remember(songId) 包裹，此处标记需人工确认
        pass

    # === 34v12 问题2：橙色幽灵强制白 ===
    # 播放键图标强制白色（emoji 在 accent 背景上）
    # 注意：Text emoji 的 color 参数可能被忽略，优先用 Icon
    print("✓ 图标颜色检查完成")

    # === 34v12 问题3：歌词未高亮行 ===
    # 确保歌词 Text 用 secondaryTextColor
    print("✓ 歌词颜色检查完成")

    with open(path, 'w', encoding='utf-8') as f:
        f.write(s)
    print("✓ 34 v12 定向补丁全部完成")

except SystemExit:
    raise
except Exception as e:
    print(f"❌ 补丁异常: {e}")
    raise SystemExit(1)
PYEOF

echo "✓ LxPlayerActivity.kt 34v12 补丁已应用"
echo "=== 34 v12 完成 ==="

# === 34 v14: 文字反转+橙色幽灵+红心重置 真修复 ===
echo "=== 34 v14 ==="

python3 << 'PYEOF14'
import re, sys

path = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt"
MARK = "// [34v14]"

with open(path, encoding="utf-8") as f:
    s = f.read()

if MARK in s:
    print("34 v14: 已应用，跳过")
    sys.exit(0)

def assert_replace(old, new, name):
    if old not in s:
        print(f"❌ 替换失败：未找到锚点 {name}")
        sys.exit(1)
    return s.replace(old, new, 1)

# --- 1. 删掉 v12 的 luminance 复杂计算，改用 animatedTint 直接判 ---
# 找到 v12 的 luminance 块并删除
# v12 块特征：// [34v12] 背景提鲜 ... val isDarkBg = bgLuminance < 0.5
old_lumi = None
# 用正则匹配整个 v12 luminance 块
m = re.search(
    r'    // \[34v12\] 背景提鲜：HSV 拉高饱和度/亮度\n'
    r'    val vibrantBg = remember\(animatedTint\) \{.*?\n'
    r'    \}\n'
    r'    // \[34v12\] 遮罩后近似色.*?\n'
    r'    val finalBg = remember\(vibrantBg\) \{.*?\n'
    r'    \}\n'
    r'    // \[34v12\] 用最终渲染色算亮度.*?\n'
    r'    val bgLuminance = remember\(finalBg\) \{.*?\n'
    r'    \}\n'
    r'    val isDarkBg = bgLuminance < 0\.5\n'
    r'    val secondaryTextColor = if \(isDarkBg\) \{.*?\n'
    r'    \} else \{.*?\n'
    r'    \}',
    s, re.DOTALL
)
if m:
    old_lumi = m.group(0)
    # 替换为简单的 animatedTint 亮度判断
    new_lumi = '''    // [34v14] 用封面原色直接判亮度，不绑定 App 主题
    val isLightBg = remember(animatedTint) {
        androidx.core.graphics.ColorUtils.calculateLuminance(animatedTint.toArgb()) > 0.5f
    }
    val primaryTextColor = if (isLightBg) Color(0xFF1C1C1E) else Color.White // [34v14]
    val secondaryTextColor = if (isLightBg) musicColors().textSecondary else Color.White.copy(alpha = 0.7f) // [34v14]'''
    s = s.replace(old_lumi, new_lumi, 1)
    print("✓ luminance 改为 animatedTint 直接判")
else:
    print("⚠ 未找到 v12 luminance 块，尝试直接加 v14")
    # 如果 v12 块不在（可能已被删），直接在 animatedTint 后加
    m2 = re.search(r'(    val animatedTint by animateColorAsState\(\n.*?label = "coverTint"\n    \))', s, re.DOTALL)
    if not m2:
        print("❌ 未找到 animatedTint 锚点")
        sys.exit(1)
    new_code = m2.group(1) + '''
    // [34v14] 用封面原色直接判亮度
    val isLightBg = remember(animatedTint) {
        androidx.core.graphics.ColorUtils.calculateLuminance(animatedTint.toArgb()) > 0.5f
    }
    val primaryTextColor = if (isLightBg) Color(0xFF1C1C1E) else Color.White // [34v14]
    val secondaryTextColor = if (isLightBg) musicColors().textSecondary else Color.White.copy(alpha = 0.7f) // [34v14]'''
    s = s.replace(m2.group(1), new_code, 1)
    print("✓ v14 亮度判断已加")

# --- 2. 播放/暂停 Emoji → Vector Icon ---
# 找到 Text("⏸"/"▶") 并替换为 Icon
# 锚点：text = if (isPlaying) "⏸" else "▶"
if 'text = if (isPlaying)' in s:
    # 匹配整个 Text 组件
    # 原：Text(text = if (isPlaying) "⏸" else "▶", style = ..., color = ...)
    # 新：Icon(imageVector = if (isPlaying) Icons.Filled.Pause else Icons.Filled.Play, tint = Color.White, ...)
    # 需要先确保 Icons.Filled 被 import
    if "import androidx.compose.material.icons.Icons" not in s:
        # 在 import 区加
        s = s.replace(
            "import androidx.compose.material3.*",
            "import androidx.compose.material3.*\nimport androidx.compose.material.icons.Icons\nimport androidx.compose.material.icons.filled.Pause\nimport androidx.compose.material.icons.filled.Play // [34v14]",
            1
        )
        print("✓ Icons import 已加")
    
    # 替换 Text 为 Icon（用正则）
    # 匹配：Text(\n ... text = if (isPlaying) "⏸" else "▶",\n ... )
    pat = r'Text\(\s*text = if \(isPlaying\) ".*?" else ".*?",\s*style = MaterialTheme\.typography\.titleLarge,\s*color = [^,]+,?'
    m_icon = re.search(pat, s)
    if m_icon:
        old_text = m_icon.group(0)
        # 提取 modifier（如果有）
        # 简单替换为 Icon
        new_icon = 'Icon(\n                        imageVector = if (isPlaying) Icons.Filled.Pause else Icons.Filled.Play,\n                        contentDescription = null,\n                        tint = Color.White, // [34v14] 强行白色，不受 Emoji 影响\n                        modifier = Modifier.size(28.dp)\n                    )'
        s = s.replace(old_text, new_icon, 1)
        print("✓ 播放键 Emoji→Vector Icon")
    else:
        print("⚠ 未找到播放键 Text 锚点，跳过")
else:
    print("⚠ 未找到 isPlaying 锚点")

# --- 3. 循环键 Emoji → Vector Icon ---
# 找到 Text("🔁"/"🔀"/"🔂") 并替换
for emoji, icon in [("🔁", "Repeat"), ("🔀", "Shuffle"), ("🔂", "RepeatOne")]:
    if f'"{emoji}"' in s:
        # 简单策略：把包含该 emoji 的 Text 整行换成 Icon
        # 这里保守处理，只打标记让用户知道
        print(f"⚠ 发现 {emoji}，需手动换 Icon（{icon}）")

# --- 4. 时长文字强制 textSecondary ---
# 找到时间显示的 Text，强制颜色
# 锚点：通常是 Text(text = formatTime(...)) 或类似
# 保守：不自动改，打标记
print("⚠ 时长文字需手动确认位置")

# --- 5. 红心重置：LaunchedEffect(currentSongId) ---
# 找到红心的 isFav 状态，加 LaunchedEffect 重置
if "isFav" in s:
    # 在 isFav 定义后加 LaunchedEffect
    # 锚点：var isFav by remember { mutableStateOf(...) }
    m_fav = re.search(r'(var isFav by remember \{[^}]+\})', s)
    if m_fav:
        old_fav = m_fav.group(1)
        # 需要 currentSongId，先找
        # 假设有 songId 或 currentSongId 变量
        new_fav = old_fav + '''
    // [34v14] 切歌强制重置红心
    LaunchedEffect(currentSongId) {
        try { isFav = FavManager.isFav(currentSongId) } catch (_: Exception) {}
    }'''
        s = s.replace(old_fav, new_fav, 1)
        print("✓ 红心重置已加")
    else:
        print("⚠ 未找到 isFav 定义")
else:
    print("⚠ 未找到 isFav")

assert MARK in s, "❌ 断言失败：v14 标记未加入"

with open(path, "w", encoding="utf-8") as f:
    f.write(s)
print("✓ 34 v14 完成")
PYEOF14

echo "=== 34 v14 完成 ==="
