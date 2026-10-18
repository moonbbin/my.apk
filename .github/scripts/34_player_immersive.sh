#!/bin/bash
# 34_player_immersive.sh - 播放页沉浸式海报取色背景（定向补丁）
# 本脚本为 LxPlayerActivity.kt 沉浸式背景的唯一控制权。
# 方案B：Python 精确定向替换，不动业务逻辑（Slider/播放控制/22徽标/歌词滚动）。
# [34v3] 修：补Palette依赖、加toArgb import、修海报Box语法
set -e
cd avbox

echo "=== 34 v3: 播放页沉浸式定向补丁 ==="

TARGET="app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt"

if [ ! -f "$TARGET" ]; then
    echo "✗ 文件不存在: $TARGET"
    exit 1
fi

# === 0. 加 Palette 依赖（自动找 build.gradle） ===
GRADLE_FILE=$(find . -maxdepth 2 -name "build.gradle" -path "*/app/*" 2>/dev/null | head -1)
if [ -z "$GRADLE_FILE" ]; then
    GRADLE_FILE=$(find . -maxdepth 2 -name "build.gradle" 2>/dev/null | head -1)
fi
if [ -z "$GRADLE_FILE" ]; then
    echo "❌ 找不到 build.gradle"; exit 1
fi
echo "→ 找到 $GRADLE_FILE"
if grep -q "androidx.palette:palette" "$GRADLE_FILE"; then
    echo "→ Palette 依赖已存在，跳过"
else
    echo "→ 添加 Palette 依赖"
    python3 << PYEOF2
import re
with open("$GRADLE_FILE", encoding='utf-8') as f:
    s = f.read()
m = re.search(r'dependencies\s*\{', s)
if not m:
    print('❌ 未找到 dependencies 块'); exit(1)
s = s[:m.end()] + '\n    implementation "androidx.palette:palette:1.0.0"' + s[m.end():]
open("$GRADLE_FILE",'w').write(s)
print('✓ Palette 依赖已加')
assert 'androidx.palette:palette' in s
PYEOF2
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
        "import androidx.palette.graphics.Palette",
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
    assert "import androidx.palette.graphics.Palette" in s, "❌ import 断言失败"
    assert "import androidx.compose.ui.graphics.toArgb" in s, "❌ toArgb import 断言失败"

    # === 2. luminance 计算（在 animatedTint 后） ===
    m = re.search(r'(    val animatedTint by animateColorAsState\(\n.*?label = "coverTint"\n    \))', s, re.DOTALL)
    if not m:
        print("❌ 替换失败：未找到锚点 animatedTint块"); raise SystemExit(1)
    lumi_code = m.group(1) + """
    // [34v3] 智能文字反转：基于背景亮度
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
    assert "ColorUtils.calculateLuminance" in s

    # === 3. 根背景：animatedTint + 黑遮罩 ===
    old_bg = """    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(musicColors().background)
    ) {"""
    new_bg = """    // [34v3] 沉浸式动态背景：取色 + 黑遮罩防刺眼
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(animatedTint)
    ) {
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
    new_rainbow = """                    .background(musicColors().cardSecondary) // [34v3] 纯色兜底"""
    assert_replace(old_rainbow, new_rainbow, "海报彩虹背景")

    # === 5. 海报 Box：加悬浮（保留 contentAlignment） ===
    old_box = """            Box(
                modifier = Modifier
                    .size(280.dp)
                    .align(Alignment.CenterHorizontally)
                    .clip(RoundedCornerShape(if (_isDarkCover) 12.dp else 24.dp)),
                contentAlignment = Alignment.Center
            ) {"""
    new_box = """            Box(
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
                        color = secondaryTextColor, // [34v3] 智能反转"""
    assert_replace(old_artist, new_artist, "歌手名颜色")

    # === 7. 系统栏动态反转 ===
    old_sys = """    LaunchedEffect(Unit) {
        while (true) {"""
    new_sys = """    // [34v3] 系统栏根据背景亮度反转
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

    # === 8. Palette 取色 ===
    old_ext = "private fun extractCoverTint(bitmap: android.graphics.Bitmap): Color {"
    new_ext = """private fun extractCoverTint(bitmap: android.graphics.Bitmap): Color {
    // [34v3] Palette 取色：优先 Vibrant，其次 DarkMuted
    return try {
        val palette = Palette.from(bitmap).generate()
        val swatch = palette.vibrantSwatch ?: palette.darkMutedSwatch ?: palette.mutedSwatch
        if (swatch != null) Color(swatch.rgb) else extractCoverTintFallback(bitmap)
    } catch (e: Exception) {
        extractCoverTintFallback(bitmap)
    }
}

private fun extractCoverTintFallback(bitmap: android.graphics.Bitmap): Color {"""
    assert_replace(old_ext, new_ext, "Palette取色")

    with open(path, 'w', encoding='utf-8') as f:
        f.write(s)
    print("✓ 34 v3 定向补丁全部完成")

except SystemExit:
    raise
except Exception as e:
    print(f"❌ 补丁异常: {e}")
    raise SystemExit(1)
PYEOF

echo "✓ LxPlayerActivity.kt 34v3 补丁已应用"
echo "=== 34 v3 完成 ==="
