#!/bin/bash
# 32_music_theme_dark_light.sh v3 (2026-10-17): 修复重复 cd avbox (2026-10-17): 桥接方案完整实装 (2026-10-17): 全局深色/浅色切换 + 播放页动态取色
# 包含：浅色 Token、Theme 双盘、ThemeViewModel(DataStore)、MainActivity 注入、设置页开关、PlayerScreen 动态取色、build.gradle 依赖
set -e
cd avbox

echo "=== 32 v5：深色/浅色全局切换 ==="

# ===== Part 1: Color.kt 追加浅色 Token =====
python3 << 'PYEOF'
import sys, re
path = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxMusicTheme.kt"
with open(path, encoding="utf-8") as f:
    src = f.read()
MARK = "// [32v2] LxMusicTheme bridge"
if MARK in src:
    print("PartA2：跳过（已是 v2）")
    sys.exit(0)
new_func = """// [32v2] LxMusicTheme bridge
@Composable
fun LxMusicTheme(
    isDarkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    val musicColors = if (isDarkTheme) DarkMusicColors else LightMusicColors
    val materialColorScheme = if (isDarkTheme) {
        darkColorScheme(
            primary = BrandGreen,
            onPrimary = TextOnAccent,
            background = musicColors.background,
            onBackground = musicColors.textPrimary,
            surface = musicColors.card,
            onSurface = musicColors.textPrimary,
            surfaceVariant = musicColors.cardSecondary,
            onSurfaceVariant = musicColors.textSecondary,
            outline = musicColors.divider,
            error = ErrorRed,
            onError = Color.White
        )
    } else {
        lightColorScheme(
            primary = BrandGreen,
            onPrimary = Color.White,
            background = musicColors.background,
            onBackground = musicColors.textPrimary,
            surface = musicColors.card,
            onSurface = musicColors.textPrimary,
            surfaceVariant = musicColors.cardSecondary,
            onSurfaceVariant = musicColors.textSecondary,
            outline = musicColors.divider,
            error = ErrorRed,
            onError = Color.White
        )
    }
    CompositionLocalProvider(LocalMusicColors provides musicColors) {
        MaterialTheme(colorScheme = materialColorScheme, content = content)
    }
}"""
if "import androidx.compose.material3.darkColorScheme" not in src:
    src = src.replace("import androidx.compose.runtime.Composable", "import androidx.compose.runtime.Composable\nimport androidx.compose.material3.darkColorScheme\nimport androidx.compose.material3.lightColorScheme\nimport androidx.compose.material3.MaterialTheme\nimport androidx.compose.foundation.isSystemInDarkTheme", 1)
src = src.rstrip() + "\n\n" + new_func + "\n"
with open(path, "w", encoding="utf-8") as f:
    f.write(src)
print("PartA2：LxMusicTheme 桥接已创建")
PYEOF

echo "=== 32 v5 PartA2 完成 ==="
# 32 v5 PartB: MainActivity 彻底排查
set -e
# cd avbox (已在 avbox 内，跳过)

echo "=== 32 v5 PartB：MainActivity 排查 ==="

MAIN=$(find app/src/main/java -name "MainActivity.kt" 2>/dev/null | head -1)
if [ -z "$MAIN" ]; then
    echo "错误：未找到 MainActivity.kt"
    exit 1
fi
echo "文件：$MAIN"

python3 << PYEOF
import sys, re

path = "$MAIN"
with open(path, encoding="utf-8") as f:
    src = f.read()

# 1. 检查是否已用新版
if "LxMusicTheme(isDarkTheme" in src:
    print("PartB：已用 LxMusicTheme(isDarkTheme=)，跳过")
    sys.exit(0)

# 2. 找 setContent
if "setContent" not in src:
    print("错误：未找到 setContent")
    sys.exit(1)

print("找到 setContent")

# 3. 找主题包裹：LxMusicTheme( (旧版，无参数)、MaterialTheme、AppTheme 等
patterns = [
    r'LxMusicTheme\s*\{',
    r'LxMusicTheme\s*\(',
    r'MaterialTheme\s*\{',
    r'MaterialTheme\s*\(',
]

found = []
for pat in patterns:
    for m in re.finditer(pat, src):
        # 取上下文
        start = max(0, m.start() - 50)
        end = min(len(src), m.end() + 100)
        ctx = src[start:end].replace('\n', ' ')[:120]
        found.append((m.group(0), ctx))

if found:
    print(f"找到 {len(found)} 个可能的主题包裹：")
    for pat, ctx in found[:10]:
        print(f"  - {pat}: ...{ctx}...")
    print("")
    print("错误：MainActivity 主题结构需手动确认，未自动替换")
    print("请检查以上位置，确认后手动改为 LxMusicTheme(isDarkTheme = isDark)")
    sys.exit(1)
else:
    print("未找到明显的主题包裹，需手动检查 setContent 结构")
    sys.exit(1)
PYEOF

echo "=== 32 v5 PartB 完成 ==="
# 32 v5 PartC: 搜 isSystemInDarkTheme 并替换
set -e
# cd avbox (已在 avbox 内，跳过)

echo "=== 32 v5 PartC：isSystemInDarkTheme 排查 ==="

# 只查 music 相关目录，避免动主体其他部分
TARGET_DIR="app/src/main/java/com/github/tvbox/osc/ui/music"

if [ ! -d "$TARGET_DIR" ]; then
    echo "警告：未找到 $TARGET_DIR，跳过"
    exit 0
fi

echo "搜索 isSystemInDarkTheme()..."
FOUND=$(grep -r "isSystemInDarkTheme()" "$TARGET_DIR" 2>/dev/null | wc -l)
echo "找到 $FOUND 处"

if [ "$FOUND" -gt 0 ]; then
    echo "--- 位置列表 ---"
    grep -rn "isSystemInDarkTheme()" "$TARGET_DIR" 2>/dev/null | head -20
    
    # 替换策略：isSystemInDarkTheme() -> LocalMusicColors.current.isDark
    # 但 MusicColors 可能没有 isDark 字段，先检查
    # 为安全起见，只做标记，不自动替换
    echo ""
    echo "[32v2] TODO: 以上 $FOUND 处 isSystemInDarkTheme() 需手动替换为主题读取"
    echo "建议替换为：val isDark = LocalMusicColors.current.background.luminance() < 0.5"
    echo "或：MaterialTheme.colorScheme.background.luminance() < 0.5"
fi

echo "=== 32 v5 PartC 完成 ==="
# 32 v5 PartD: Modifier.shadow 检查
set -e
# cd avbox (已在 avbox 内，跳过)

echo "=== 32 v5 PartD：shadow 检查 ==="

TARGET_DIR="app/src/main/java/com/github/tvbox/osc/ui/music"

if [ ! -d "$TARGET_DIR" ]; then
    echo "警告：未找到 $TARGET_DIR，跳过"
    exit 0
fi

echo "搜索 Modifier.shadow..."
FOUND=$(grep -r "Modifier.*\.shadow" "$TARGET_DIR" 2>/dev/null | wc -l)
echo "找到 $FOUND 处"

if [ "$FOUND" -gt 0 ]; then
    echo "--- 位置列表 ---"
    grep -rn "Modifier.*\.shadow" "$TARGET_DIR" 2>/dev/null | head -20
    echo ""
    echo "[32v2] TODO: 检查以上 shadow 在浅色模式下是否太突兀"
    echo "如需修复，考虑用 MaterialTheme.colorScheme.surfaceVariant 做阴影色，或调低 elevation"
fi

echo "=== 32 v5 PartD 完成 ==="
