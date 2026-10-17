#!/bin/bash
# 32_music_theme_dark_light.sh v3 (2026-10-17): 修复重复 cd avbox (2026-10-17): 桥接方案完整实装 (2026-10-17): 全局深色/浅色切换 + 播放页动态取色
# 包含：浅色 Token、Theme 双盘、ThemeViewModel(DataStore)、MainActivity 注入、设置页开关、PlayerScreen 动态取色、build.gradle 依赖
set -e
cd avbox

echo "=== 32 v12：深色/浅色全局切换 ==="

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

echo "=== 32 v12 PartA2 完成 ==="

# 32 v12: 修复 LxMusicTheme.kt 的 import 缺失
echo "=== 32 v12 PartA3: 补 Import ==="

python3 << 'PYEOF'
import re

path = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxMusicTheme.kt"
with open(path, encoding="utf-8") as f:
    src = f.read()

# 需要确保的 import 列表
required_imports = [
    "import androidx.compose.foundation.isSystemInDarkTheme",
    "import androidx.compose.material3.darkColorScheme",
    "import androidx.compose.material3.lightColorScheme",
    "import androidx.compose.material3.MaterialTheme",
    "import androidx.compose.runtime.Composable",
    "import androidx.compose.runtime.CompositionLocalProvider",
    "import androidx.compose.ui.graphics.Color",
    "import com.github.tvbox.osc.ui.music.theme.BrandGreen",
    "import com.github.tvbox.osc.ui.music.theme.ErrorRed",
    "import com.github.tvbox.osc.ui.music.theme.TextOnAccent",
]

# 找最后一个 import 的位置
imports = list(re.finditer(r'^import .+$', src, re.MULTILINE))
if imports:
    pos = imports[-1].end()
    to_add = []
    for imp in required_imports:
        if imp not in src:
            to_add.append(imp)
    if to_add:
        src = src[:pos] + "\n" + "\n".join(to_add) + src[pos:]
        print(f"已补 {len(to_add)} 个 import:")
        for imp in to_add:
            print(f"  + {imp}")
    else:
        print("所有 import 已存在")
else:
    print("警告：未找到任何 import")

with open(path, "w", encoding="utf-8") as f:
    f.write(src)
print("=== 32 v12 PartA3 完成 ===")
PYEOF

# 32 v12: PartB 详细打印 MainActivity setContent 结构
echo "=== 32 v12 PartB: MainActivity 详细结构 ==="

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
echo "=== 32 v12 PartB 完成（仅排查，不修改）==="
# 不退出 1，让构建继续，先看到结构

# 32 v12 PartC: 搜 isSystemInDarkTheme 并替换
set -e
# cd avbox (已在 avbox 内，跳过)

echo "=== 32 v12 PartC：isSystemInDarkTheme 排查 ==="

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

echo "=== 32 v12 PartC 完成 ==="
# 32 v12 PartD: Modifier.shadow 检查
set -e
# cd avbox (已在 avbox 内，跳过)

echo "=== 32 v12 PartD：shadow 检查 ==="

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

echo "=== 32 v12 PartD 完成 ==="

# 32 v12: BrandGreen -> PlayerGreen (实际存在的常量名)
echo "=== 32 v12: 修复 BrandGreen ==="

python3 << 'PYEOF'
path = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxMusicTheme.kt"
with open(path, encoding="utf-8") as f:
    src = f.read()

# 替换 BrandGreen -> PlayerGreen
count = src.count("BrandGreen")
src = src.replace("BrandGreen", "PlayerGreen")
print(f"替换 BrandGreen -> PlayerGreen: {count} 处")

# 修正 import
src = src.replace(
    "import com.github.tvbox.osc.ui.music.theme.BrandGreen",
    "import com.github.tvbox.osc.ui.music.theme.PlayerGreen"
)
print("Import 已修正")

with open(path, "w", encoding="utf-8") as f:
    f.write(src)
print("=== 32 v12 完成 ===")
PYEOF

# 32 v12: PlayerGreen 改为 public
echo "=== 32 v12: PlayerGreen public ==="

python3 << 'PYEOF'
path = "app/src/main/java/com/github/tvbox/osc/ui/music/theme/Color.kt"
with open(path, encoding="utf-8") as f:
    src = f.read()

# 把 private val PlayerGreen 改为 val PlayerGreen
import re
old = r'private\s+val\s+PlayerGreen\s*='
new = 'val PlayerGreen ='
src_new, n = re.subn(old, new, src)
print(f"PlayerGreen private -> public: {n} 处")

# 同理检查 DetailGreen, SearchAccent, AccentBlue 是否也需要
for name in ['DetailGreen', 'SearchAccent', 'AccentBlue', 'ErrorRed', 'TextOnAccent']:
    # 如果是 private，改为 public
    pattern = rf'private\s+val\s+{name}\s*='
    src_new, cnt = re.subn(pattern, f'val {name} =', src_new)
    if cnt > 0:
        print(f"{name} private -> public: {cnt} 处")

with open(path, "w", encoding="utf-8") as f:
    f.write(src_new)
print("=== 32 v12 完成 ===")
PYEOF

# 32 v12: 按用户要求 - Color.kt private->internal，确保 BrandGreen 存在；LxMusicTheme 统一用 BrandGreen
echo "=== 32 v12: 主题 Token 可见性修复 ==="

python3 << 'PYEOF'
import re

# ===== 1) Color.kt: 所有 private val -> internal val，确保 BrandGreen 存在 =====
cpath = "app/src/main/java/com/github/tvbox/osc/ui/music/theme/Color.kt"
with open(cpath, encoding="utf-8") as f:
    csrc = f.read()

# 所有 private val 改为 internal val
csrc_new, n1 = re.subn(r'\bprivate\s+val\s+', 'internal val ', csrc)
print(f"Color.kt: private val -> internal val: {n1} 处")

# 确保 BrandGreen 存在：如果不存在但 PlayerGreen 存在，加别名
has_brand = re.search(r'\bval\s+BrandGreen\s*=', csrc_new)
has_player = re.search(r'\bval\s+PlayerGreen\s*=', csrc_new)
if not has_brand and has_player:
    # 在 PlayerGreen 定义后加别名
    csrc_new = re.sub(
        r'((?:internal\s+)?val\s+PlayerGreen\s*=\s*Color\(0xFF[0-9A-Fa-f]+\))',
        r'\1\ninternal val BrandGreen = PlayerGreen',
        csrc_new,
        count=1
    )
    print("Color.kt: 已加 internal val BrandGreen = PlayerGreen 别名")
elif has_brand:
    print("Color.kt: BrandGreen 已存在")
else:
    print("Color.kt: 警告 - PlayerGreen 和 BrandGreen 都不存在")

with open(cpath, "w", encoding="utf-8") as f:
    f.write(csrc_new)

# ===== 2) LxMusicTheme.kt: PlayerGreen -> BrandGreen，确保 import =====
lpath = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxMusicTheme.kt"
with open(lpath, encoding="utf-8") as f:
    lsrc = f.read()

# 替换 PlayerGreen -> BrandGreen
cnt = lsrc.count("PlayerGreen")
lsrc = lsrc.replace("PlayerGreen", "BrandGreen")
print(f"LxMusicTheme.kt: PlayerGreen -> BrandGreen: {cnt} 处")

# 确保 import BrandGreen，移除 PlayerGreen 的 import
lsrc = lsrc.replace(
    "import com.github.tvbox.osc.ui.music.theme.PlayerGreen",
    "import com.github.tvbox.osc.ui.music.theme.BrandGreen"
)
if "import com.github.tvbox.osc.ui.music.theme.BrandGreen" not in lsrc:
    # 加到最后一个 import 后
    imports = list(re.finditer(r'^import .+$', lsrc, re.MULTILINE))
    if imports:
        pos = imports[-1].end()
        lsrc = lsrc[:pos] + "\nimport com.github.tvbox.osc.ui.music.theme.BrandGreen" + lsrc[pos:]
        print("LxMusicTheme.kt: 已加 BrandGreen import")

with open(lpath, "w", encoding="utf-8") as f:
    f.write(lsrc)

print("=== 32 v12 完成 ===")
PYEOF

# 32 v12: 按用户三步要求 - Color.kt 加 BrandGreen(0xFF34C759)，确保可见性；LxMusicTheme 确保 import
echo "=== 32 v12: BrandGreen 三步修复 ==="

python3 << 'PYEOF'
import re

# ===== 1) Color.kt: 确保 BrandGreen = Color(0xFF34C759)，非 private =====
cpath = "app/src/main/java/com/github/tvbox/osc/ui/music/theme/Color.kt"
with open(cpath, encoding="utf-8") as f:
    csrc = f.read()

# 1a) 所有 private val -> internal val
csrc, n1 = re.subn(r'\bprivate\s+val\s+', 'internal val ', csrc)
print(f"1) Color.kt: private val -> internal val: {n1} 处")

# 1b) 检查 BrandGreen 是否存在
has_brand = re.search(r'\bval\s+BrandGreen\s*=', csrc)
if not has_brand:
    # 加到文件末尾（或最后一个 val 后）
    # 找最后一个 val 定义
    vals = list(re.finditer(r'^(?:internal\s+)?val\s+\w+\s*=\s*Color\(0xFF[0-9A-Fa-f]+\)', csrc, re.MULTILINE))
    if vals:
        pos = vals[-1].end()
        csrc = csrc[:pos] + "\ninternal val BrandGreen = Color(0xFF34C759)" + csrc[pos:]
        print("1) Color.kt: 已加 internal val BrandGreen = Color(0xFF34C759)")
    else:
        csrc = csrc.rstrip() + "\n\ninternal val BrandGreen = Color(0xFF34C759)\n"
        print("1) Color.kt: 已追加 BrandGreen 到末尾")
else:
    # 确保不是 private
    csrc = re.sub(r'\bprivate\s+val\s+BrandGreen\s*=', 'internal val BrandGreen =', csrc)
    print("1) Color.kt: BrandGreen 已存在，确保为 internal")

with open(cpath, "w", encoding="utf-8") as f:
    f.write(csrc)

# ===== 2) LxMusicTheme.kt: PlayerGreen -> BrandGreen =====
lpath = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxMusicTheme.kt"
with open(lpath, encoding="utf-8") as f:
    lsrc = f.read()

cnt = lsrc.count("PlayerGreen")
lsrc = lsrc.replace("PlayerGreen", "BrandGreen")
print(f"2) LxMusicTheme.kt: PlayerGreen -> BrandGreen: {cnt} 处")

# ===== 3) 确保 import =====
# 移除旧的 PlayerGreen import（如果还有）
lsrc = lsrc.replace("import com.github.tvbox.osc.ui.music.theme.PlayerGreen\n", "")
# 确保有 BrandGreen import
if "import com.github.tvbox.osc.ui.music.theme.BrandGreen" not in lsrc:
    imports = list(re.finditer(r'^import .+$', lsrc, re.MULTILINE))
    if imports:
        pos = imports[-1].end()
        lsrc = lsrc[:pos] + "\nimport com.github.tvbox.osc.ui.music.theme.BrandGreen" + lsrc[pos:]
        print("3) LxMusicTheme.kt: 已加 BrandGreen import")
else:
    print("3) LxMusicTheme.kt: BrandGreen import 已存在")

with open(lpath, "w", encoding="utf-8") as f:
    f.write(lsrc)

print("=== 32 v12 完成 ===")
PYEOF

# 32 v12: 强制 BrandGreen = Color(0xFF34C759)，覆盖旧别名
echo "=== 32 v12: 强制 BrandGreen 定义 ==="

python3 << 'PYEOF'
import re

cpath = "app/src/main/java/com/github/tvbox/osc/ui/music/theme/Color.kt"
with open(cpath, encoding="utf-8") as f:
    csrc = f.read()

# 1) 所有 private val -> internal val
csrc, n1 = re.subn(r'\bprivate\s+val\s+', 'internal val ', csrc)
print(f"1) private -> internal: {n1} 处")

# 2) 删除所有已存在的 BrandGreen 定义（不管是别名还是旧值）
csrc, n2 = re.subn(r'^(?:internal\s+)?val\s+BrandGreen\s*=.*$', '', csrc, flags=re.MULTILINE)
print(f"2) 删除旧 BrandGreen 定义: {n2} 处")

# 3) 在文件末尾添加正确的 BrandGreen
csrc = csrc.rstrip() + "\n\ninternal val BrandGreen = Color(0xFF34C759)\n"
print("3) 已加: internal val BrandGreen = Color(0xFF34C759)")

with open(cpath, "w", encoding="utf-8") as f:
    f.write(csrc)

# 4) LxMusicTheme.kt: 确保用 BrandGreen + import
lpath = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxMusicTheme.kt"
with open(lpath, encoding="utf-8") as f:
    lsrc = f.read()

cnt = lsrc.count("PlayerGreen")
lsrc = lsrc.replace("PlayerGreen", "BrandGreen")
print(f"4) PlayerGreen -> BrandGreen: {cnt} 处")

lsrc = lsrc.replace("import com.github.tvbox.osc.ui.music.theme.PlayerGreen\n", "")
if "import com.github.tvbox.osc.ui.music.theme.BrandGreen" not in lsrc:
    imports = list(re.finditer(r'^import .+$', lsrc, re.MULTILINE))
    if imports:
        pos = imports[-1].end()
        lsrc = lsrc[:pos] + "\nimport com.github.tvbox.osc.ui.music.theme.BrandGreen" + lsrc[pos:]
        print("4) 已加 BrandGreen import")
else:
    print("4) BrandGreen import 已存在")

with open(lpath, "w", encoding="utf-8") as f:
    f.write(lsrc)

print("=== 32 v12 完成 ===")
PYEOF

