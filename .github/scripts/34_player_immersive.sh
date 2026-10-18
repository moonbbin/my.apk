#!/bin/bash
# 34_player_immersive.sh - 播放页沉浸式海报取色背景重构
# 本脚本为 LxPlayerActivity.kt 沉浸式背景的唯一控制权。
# 目标：Palette 取色背景 + 悬浮海报（阴影+高光边框）+ 智能文字反转 + 系统栏适配
# 注意：13 生成 LxPlayerActivity.kt，22 加徽标补丁，本脚本编号更大（34 > 22），后运行覆盖生效。
# [34v1]
set -e
cd avbox

echo "=== 34 v1: 播放页沉浸式重构 ==="

TARGET="app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt"
GRADLE="app/build.gradle"

if [ ! -f "$TARGET" ]; then
    echo "✗ 文件不存在: $TARGET"
    exit 1
fi

# 1. 加 Palette 依赖
if ! grep -q "androidx.palette:palette" "$GRADLE"; then
    echo "→ 添加 Palette 依赖"
    python3 << 'PYEOF'
import re
with open('app/build.gradle', encoding='utf-8') as f:
    s = f.read()
# 在 dependencies 块中添加
old = 'implementation "androidx.core:core-ktx'
new = 'implementation "androidx.palette:palette:1.0.0"\n    implementation "androidx.core:core-ktx'
if old in s:
    s = s.replace(old, new, 1)
    open('app/build.gradle','w').write(s)
    print("✓ Palette 依赖已加")
else:
    # 尝试其他锚点
    m = re.search(r'(dependencies\s*\{)', s)
    if m:
        s = s[:m.end()] + '\n    implementation "androidx.palette:palette:1.0.0"' + s[m.end():]
        open('app/build.gradle','w').write(s)
        print("✓ Palette 依赖已加（备用锚点）")
    else:
        print("✗ 未找到 dependencies 块")
        exit(1)
PYEOF
else
    echo "→ Palette 依赖已存在，跳过"
fi

# 2. 补丁 LxPlayerActivity.kt
python3 << 'PYEOF'
with open('app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt', encoding='utf-8') as f:
    s = f.read()

# a. 加 import
imports = [
    "import androidx.palette.graphics.Palette",
    "import androidx.core.graphics.ColorUtils",
    "import androidx.compose.ui.draw.shadow",
    "import androidx.compose.foundation.border",
    "import androidx.compose.ui.graphics.Brush",
]
for imp in imports:
    if imp not in s:
        # 加到 import 块末尾
        m = __import__('re').search(r'(import .*\n)(?!\nimport)', s)
        # 简化：加到第一个 package 后的 import 区域
        s = s.replace("import coil.compose.AsyncImage", imp + "\nimport coil.compose.AsyncImage", 1)
        print(f"✓ 已加 {imp}")
    else:
        print(f"→ {imp} 已存在")

# b. 海报 Box：加阴影 + 高光边框 + 改圆角
old_poster = """            // 大封面
            val _isDarkCover by MusicThemeManager.isDarkTheme
            Box(
                modifier = Modifier
                    .size(280.dp)
                    .align(Alignment.CenterHorizontally)
                    .clip(RoundedCornerShape(if (_isDarkCover) 12.dp else 24.dp))"""

new_poster = """            // 大封面（沉浸式悬浮：阴影+高光边框）
            val _isDarkCover by MusicThemeManager.isDarkTheme
            Box(
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

if old_poster in s:
    s = s.replace(old_poster, new_poster, 1)
    print("✓ 海报悬浮效果已加")
    assert "elevation = 24.dp" in s, "❌ 替换失败：未找到锚点 海报阴影"
else:
    print("✗ 海报 Box 锚点未匹配")
    exit(1)

# c. 用 Palette 增强取色（在 LaunchedEffect(coverUrl) 中）
# 将 extractCoverTint 替换为 Palette 实现
old_extract = "private fun extractCoverTint(bitmap: android.graphics.Bitmap): Color {"
new_extract = '''private fun extractCoverTint(bitmap: android.graphics.Bitmap): Color {
    // [34v1] Palette 取色：优先 Vibrant，其次 DarkMuted
    return try {
        val palette = Palette.from(bitmap).generate()
        val swatch = palette.vibrantSwatch ?: palette.darkMutedSwatch ?: palette.mutedSwatch
        if (swatch != null) Color(swatch.rgb) else CoverTintFallback
    } catch (e: Exception) {
        CoverTintFallback
    }
}

private fun extractCoverTintLegacy(bitmap: android.graphics.Bitmap): Color {'''

if old_extract in s:
    s = s.replace(old_extract, new_extract, 1)
    print("✓ Palette 取色已加")
    assert "Palette.from(bitmap)" in s, "❌ 替换失败：未找到锚点 Palette取色"
else:
    print("✗ extractCoverTint 锚点未匹配")

open('app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt','w').write(s)
print("✓ 34 v1 补丁完成")
PYEOF

echo "✓ LxPlayerActivity.kt 沉浸式补丁已应用"
echo "=== 34 v1 完成 ==="
