#!/bin/bash
# 34_player_immersive.sh - 播放页沉浸式海报取色背景（定向补丁）
# 本脚本为 LxPlayerActivity.kt 沉浸式背景的唯一控制权。
# 方案B：Python 精确定向替换，不动业务逻辑（Slider/播放控制/22徽标/歌词滚动）。
# [34v2]
set -e
cd avbox

echo "=== 34 v2: 播放页沉浸式定向补丁 ==="

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
    """精确替换，带断言"""
    if old not in s:
        print(f"❌ 替换失败：未找到锚点 {name}")
        raise SystemExit(1)
    return s.replace(old, new, 1)

try:
    # === 1. 加 import ===
    imports = [
        "import androidx.palette.graphics.Palette",
        "import androidx.core.graphics.ColorUtils",
        "import androidx.compose.ui.draw.shadow",
        "import androidx.compose.foundation.border",
        "import androidx.core.view.WindowCompat",
        "import android.app.Activity",
    ]
    for imp in imports:
        if imp not in s:
            s = s.replace("import coil.compose.AsyncImage", imp + "\nimport coil.compose.AsyncImage", 1)
            print(f"✓ 已加 {imp}")
    assert "import androidx.palette.graphics.Palette" in s, "❌ import 断言失败"

    # === 2. 根背景：animatedTint + 黑色渐变遮罩 ===
    # 找到 LxPlayerScreen 中的背景逻辑，在 coverTint 定义后加入 luminance 计算
    old_lumi_anchor = "    val animatedTint by animateColorAsState("
    if old_lumi_anchor in s:
        # 在 animatedTint 定义后插入 luminance 计算
        # 找到 animatedTint 块的结束
        m = re.search(r'(    val animatedTint by animateColorAsState\(\n.*?label = "coverTint"\n    \))', s, re.DOTALL)
        if m:
            lumi_code = m.group(1) + """
    // [34v2] 智能文字反转：基于背景亮度
    val bgLuminance = remember(animatedTint) {
        ColorUtils.calculateLuminance(animatedTint.toArgb())
    }
    val isDarkBg = bgLuminance < 0.5
    val secondaryTextColor = if (isDarkBg) {
        Color.White.copy(alpha = 0.7f)
    } else {
        Color(0xFF1C1C1E)
    }"""
            s = s.replace(m.group(1), lumi_code, 1)
            print("✓ luminance 智能文字已加")
            assert "ColorUtils.calculateLuminance" in s, "❌ 替换失败：未找到锚点 luminance"
        else:
            print("❌ 替换失败：未找到锚点 animatedTint块")
            raise SystemExit(1)
    else:
        print("❌ 替换失败：未找到锚点 animatedTint")
        raise SystemExit(1)

    # === 3. 根背景 Box：改用 animatedTint + 黑遮罩 ===
    old_bg = """    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(musicColors().background)
    ) {"""
    new_bg = """    // [34v2] 沉浸式动态背景：取色 + 黑遮罩防刺眼
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(animatedTint)
    ) {
        // 黑色渐变遮罩（防亮瞎眼，保护文字）
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    Brush.verticalGradient(
                        listOf(
                            Color.Black.copy(alpha = 0.3f),
                            Color.Black.copy(alpha = 0.7f)
                        )
                    )
                )
        )"""
    s = assert_replace(old_bg, new_bg, "根背景Box")
    print("✓ 根背景已换沉浸式")

    # === 4. 海报 Box：删 rainbow，加 shadow+border+clip ===
    old_poster_bg = """                    .background(
                        Brush.linearGradient(
                            colors = listOf(
                                Color.hsv(hue, 0.5f, 0.7f),
                                Color.hsv((hue + 50) % 360, 0.6f, 0.4f)
                            )
                        )
                    )"""
    new_poster_bg = """                    .background(musicColors().cardSecondary) // [34v2] 纯色兜底，删彩虹"""
    s = assert_replace(old_poster_bg, new_poster_bg, "海报rainbow背景")
    print("✓ 海报彩虹背景已删")

    # 海报 Box 加悬浮效果（在 .size(280.dp) 后）
    old_poster_box = """            Box(
                modifier = Modifier
                    .size(280.dp)
                    .align(Alignment.CenterHorizontally)
                    .clip(RoundedCornerShape(if (_isDarkCover) 12.dp else 24.dp))"""
    new_poster_box = """            Box(
                modifier = Modifier
                    .size(280.dp)
                    .align(Alignment.CenterHorizontally)
                    .shadow(
                        elevation = 24.dp,
                        shape = RoundedCornerShape(20.dp),
                        ambientColor = Color.Black.copy(alpha = 0.4f),
                        spotColor = Color.Black
                    )
                    .border(
                        width = 1.dp,
                        color = Color.White.copy(alpha = 0.15f),
                        shape = RoundedCornerShape(20.dp)
                    )
                    .clip(RoundedCornerShape(20.dp))"""
    s = assert_replace(old_poster_box, new_poster_box, "海报Box悬浮")
    print("✓ 海报悬浮效果已加")

    # === 5. 歌手名：PlayerGray -> secondaryTextColor ===
    old_artist = """                    Text(
                        text = displayArtist,
                        style = MaterialTheme.typography.labelSmall,
                        color = PlayerGray,"""
    new_artist = """                    Text(
                        text = displayArtist,
                        style = MaterialTheme.typography.labelSmall,
                        color = secondaryTextColor, // [34v2] 智能反转"""
    s = assert_replace(old_artist, new_artist, "歌手名颜色")
    print("✓ 歌手名智能反转已加")

    # === 6. 系统栏：根据 isDarkBg 动态反转 ===
    # 在 LxPlayerScreen 的 LaunchedEffect(Unit) 后加入
    old_sysbar = """    LaunchedEffect(Unit) {
        while (true) {"""
    new_sysbar = """    // [34v2] 系统栏根据背景亮度反转
    val sysWindow = (context as? Activity)?.window
    LaunchedEffect(isDarkBg) {
        sysWindow?.let {
            WindowCompat.getInsetsController(it, it.decorView)
                .isAppearanceLightStatusBars = !isDarkBg
        }
    }
    LaunchedEffect(Unit) {
        while (true) {"""
    s = assert_replace(old_sysbar, new_sysbar, "系统栏反转")
    print("✓ 系统栏动态反转已加")

    # === 7. Palette 取色：增强 extractCoverTint ===
    old_extract = "private fun extractCoverTint(bitmap: android.graphics.Bitmap): Color {"
    new_extract = """private fun extractCoverTint(bitmap: android.graphics.Bitmap): Color {
    // [34v2] Palette 取色：优先 Vibrant，其次 DarkMuted
    return try {
        val palette = Palette.from(bitmap).generate()
        val swatch = palette.vibrantSwatch ?: palette.darkMutedSwatch ?: palette.mutedSwatch
        if (swatch != null) Color(swatch.rgb) else extractCoverTintFallback(bitmap)
    } catch (e: Exception) {
        extractCoverTintFallback(bitmap)
    }
}

private fun extractCoverTintFallback(bitmap: android.graphics.Bitmap): Color {"""
    s = assert_replace(old_extract, new_extract, "Palette取色")
    print("✓ Palette 取色已加")

    with open(path, 'w', encoding='utf-8') as f:
        f.write(s)
    print("✓ 34 v2 定向补丁全部完成")

except SystemExit:
    raise
except Exception as e:
    print(f"❌ 补丁异常: {e}")
    raise SystemExit(1)
PYEOF

echo "✓ LxPlayerActivity.kt 34v2 补丁已应用"
echo "=== 34 v2 完成 ==="
