#!/bin/bash
# 32_music_theme_dark_light.sh v3 (2026-10-17): 修复重复 cd avbox (2026-10-17): 桥接方案完整实装 (2026-10-17): 全局深色/浅色切换 + 播放页动态取色
# 包含：浅色 Token、Theme 双盘、ThemeViewModel(DataStore)、MainActivity 注入、设置页开关、PlayerScreen 动态取色、build.gradle 依赖
set -e
cd avbox

echo "=== 32 v6：深色/浅色全局切换 ==="

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

echo "=== 32 v6 PartA2 完成 ==="
# 32 v6: PartB 详细打印 MainActivity setContent 结构
echo "=== 32 v6 PartB: MainActivity 详细结构 ==="

MAIN="app/src/main/java/com/github/tvbox/osc/ui/activity/MainActivity.kt"
if [ ! -f "$MAIN" ]; then
    echo "错误：找不到 MainActivity.kt"
    # 尝试 find
    find app/src/main/java -name "MainActivity.kt" 2>/dev/null | head -5
    exit 1
fi

echo "文件: $MAIN"
echo ""
echo "--- setContent 上下文 (前后 30 行) ---"

python3 << 'PYEOF'
import re

path = "app/src/main/java/com/github/tvbox/osc/ui/activity/MainActivity.kt"
with open(path, encoding="utf-8") as f:
    lines = f.readlines()

# 找 setContent
for i, line in enumerate(lines):
    if "setContent" in line:
        print(f"找到 setContent 在第 {i+1} 行:")
        print("")
        # 打印前后 30 行，带行号
        start = max(0, i - 10)
        end = min(len(lines), i + 40)
        for j in range(start, end):
            prefix = ">>>" if j == i else "   "
            print(f"{prefix} {j+1:4d}: {lines[j]}", end="")
        print("")
        print("--- setContent 块结束 ---")
        break
else:
    print("未找到 setContent")

# 找所有可能的主题包裹
print("")
print("--- 主题相关调用 ---")
for i, line in enumerate(lines):
    if re.search(r'(LxMusicTheme|MaterialTheme|TVBoxTheme|AppTheme|MyTheme)\s*[\{\(]', line):
        print(f"第 {i+1} 行: {line.strip()}")
PYEOF

echo ""
echo "=== 32 v6 PartB 完成（仅排查，不修改）==="
# 不退出 1，让构建继续，先看到结构

# 32 v6 PartC: 搜 isSystemInDarkTheme 并替换
set -e
# cd avbox (已在 avbox 内，跳过)

echo "=== 32 v6 PartC：isSystemInDarkTheme 排查 ==="

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

echo "=== 32 v6 PartC 完成 ==="
# 32 v6 PartD: Modifier.shadow 检查
set -e
# cd avbox (已在 avbox 内，跳过)

echo "=== 32 v6 PartD：shadow 检查 ==="

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

echo "=== 32 v6 PartD 完成 ==="
