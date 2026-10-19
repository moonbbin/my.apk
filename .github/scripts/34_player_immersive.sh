#!/bin/bash
# 34_player_immersive.sh - 播放页沉浸式海报取色背景（定向补丁）
# 本脚本为 LxPlayerActivity.kt 沉浸式背景的唯一控制权。
# 方案B：Python 精确定向替换，不动业务逻辑（Slider/播放控制/22徽标/歌词滚动）。
# [34v8] 修：补Palette依赖、加toArgb import、修海报Box语法
set -e
cd avbox

echo "=== 34 v8: 播放页沉浸式定向补丁 ==="

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
    // [34v8] 背景提鲜：HSV 拉高饱和度/亮度
    val vibrantBg = remember(animatedTint) {
        val hsv = FloatArray(3)
        android.graphics.Color.colorToHSV(animatedTint.toArgb(), hsv)
        hsv[1] = (hsv[1] * 1.4f).coerceAtMost(0.9f)
        hsv[2] = (hsv[2] * 1.2f).coerceAtMost(0.85f)
        Color(android.graphics.Color.HSVToColor(hsv))
    }
    // [34v8] 智能文字反转：用最终背景色算亮度
    val bgLuminance = remember(vibrantBg) {
        ColorUtils.calculateLuminance(vibrantBg.toArgb())
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
    new_bg = """    // [34v8] 沉浸式动态背景：取色 + 黑遮罩防刺眼
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(vibrantBg) // [34v8]
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
                    ) // [34v8] 暗角
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
    new_rainbow = """                    .background(musicColors().cardSecondary) // [34v8] 纯色兜底"""
    assert_replace(old_rainbow, new_rainbow, "海报彩虹背景")

    # === 5. 海报 Box：加悬浮（保留 contentAlignment） ===
    old_box = None
    for _m in ["[34v8]", "[34v5]"]:
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
                        elevation = 32.dp, // [34v8]
                        shape = RoundedCornerShape(20.dp),
                        ambientColor = Color.Black.copy(alpha = 0.4f),
                        spotColor = Color.Black
                    )
                    .border(
                        width = 1.dp,
                        color = Color.White.copy(alpha = 0.4f), // [34v8]
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
                        color = secondaryTextColor, // [34v8] 智能反转"""
    assert_replace(old_artist, new_artist, "歌手名颜色")

    # === 7. 系统栏动态反转 ===
    old_sys = """    LaunchedEffect(Unit) {
        while (true) {"""
    new_sys = """    // [34v8] 系统栏根据背景亮度反转
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

    # [34v8] 跳过 Palette，保留原版 extractCoverTint 平均取色

    # === 问题4：控制栏颜色统一 ===
    # 4a. 播放按钮背景 -> accent
    if ".background(Color.White.copy(alpha = 0.95f))" in s:
        s = s.replace(
            ".background(Color.White.copy(alpha = 0.95f))",
            ".background(musicColors().accent) // [34v8]",
            1
        )
        print("✓ 播放按钮背景已统一 accent")
    # 4c. 上一首/下一首 -> secondaryTextColor
    if "color = musicColors().textPrimary.copy(alpha = 0.9f))" in s:
        s = s.replace(
            "color = musicColors().textPrimary.copy(alpha = 0.9f))",
            "color = secondaryTextColor.copy(alpha = 0.9f)) // [34v8]",
        )
        print("✓ 上下首图标已跟随反转")
    # 4d. 未激活图标 PlayerGray -> secondaryTextColor
    if "PlayerGray.copy(alpha = 0.6f)" in s:
        s = s.replace(
            "PlayerGray.copy(alpha = 0.6f)",
            "secondaryTextColor.copy(alpha = 0.6f) // [34v8]",
        )
        print("✓ 未激活图标已跟随反转")

    with open(path, 'w', encoding='utf-8') as f:
        f.write(s)
    print("✓ 34 v8 定向补丁全部完成")

except SystemExit:
    raise
except Exception as e:
    print(f"❌ 补丁异常: {e}")
    raise SystemExit(1)
PYEOF

echo "✓ LxPlayerActivity.kt 34v8 补丁已应用"
echo "=== 34 v8 完成 ==="
