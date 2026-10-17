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

# 32 v13: 打印真实文件结构（只看不改）
echo "=== 32 v13: 结构侦查 ==="

python3 << 'PYEOF'
import re

# ===== SettingsScreen.kt =====
spath = "app/src/main/java/com/github/tvbox/osc/ui/music/settings/SettingsScreen.kt"
print("=" * 60)
print("SettingsScreen.kt 结构")
print("=" * 60)
try:
    with open(spath, encoding="utf-8") as f:
        ssrc = f.read()
    lines = ssrc.split('\n')
    print(f"总行数: {len(lines)}")
    print()

    # 找 SettingItem 数据类定义
    print("--- SettingItem 定义 ---")
    for i, line in enumerate(lines):
        if re.search(r'(data\s+class|class)\s+SettingItem', line):
            for j in range(max(0,i-2), min(len(lines), i+15)):
                print(f"{j+1:4d}: {lines[j]}")
            break
    print()

    # 找 SettingGroup 使用
    print("--- SettingGroup 使用示例 ---")
    for i, line in enumerate(lines):
        if 'SettingGroup(' in line and 'class' not in line:
            for j in range(max(0,i-3), min(len(lines), i+10)):
                print(f"{j+1:4d}: {lines[j]}")
            print("...")
            break
    print()

    # 找设置列表构建位置
    print("--- 包含 SettingGroup 的函数 ---")
    for i, line in enumerate(lines):
        if 'fun ' in line and 'Setting' in line:
            print(f"{i+1:4d}: {line.strip()}")
except FileNotFoundError:
    print(f"未找到: {spath}")

print()
print("=" * 60)
print("MainActivity.kt setContent 结构")
print("=" * 60)
mpath = "app/src/main/java/com/github/tvbox/osc/ui/activity/MainActivity.kt"
try:
    with open(mpath, encoding="utf-8") as f:
        msrc = f.read()
    lines = msrc.split('\n')
    for i, line in enumerate(lines):
        if 'setContent' in line:
            print(f"setContent 在第 {i+1} 行")
            for j in range(max(0,i-5), min(len(lines), i+30)):
                print(f"{j+1:4d}: {lines[j]}")
            break
except FileNotFoundError:
    print(f"未找到: {mpath}")

print()
print("=== 32 v13 侦查完成 ===")
PYEOF

# 32 v14: 按真实结构接入 - MainActivity换LxMusicTheme，SettingsScreen加SettingItem数据
echo "=== 32 v14: 真实结构接入 ==="

python3 << 'PYEOF'
import re

# ===== 1) MainActivity: AVBoxTheme -> LxMusicTheme =====
mpath = "app/src/main/java/com/github/tvbox/osc/ui/activity/MainActivity.kt"
with open(mpath, encoding="utf-8") as f:
    msrc = f.read()

MARK1 = "// [32v14] use LxMusicTheme"
if MARK1 not in msrc:
    # 替换 AVBoxTheme { 为 LxMusicTheme {
    # LxMusicTheme 默认 isDarkTheme = isSystemInDarkTheme()，先跟随系统
    old = "AVBoxTheme {"
    if old in msrc:
        msrc = msrc.replace(old, f"{MARK1}\n                com.github.tvbox.osc.ui.activity.LxMusicTheme {{", 1)
        print("1) MainActivity: AVBoxTheme -> LxMusicTheme")
    else:
        print("1) 警告: 未找到 AVBoxTheme {")
    with open(mpath, "w", encoding="utf-8") as f:
        f.write(msrc)
else:
    print("1) MainActivity 已接入，跳过")

# ===== 2) SettingsScreen: 加主题 SettingItem 数据 =====
# SettingItem 是数据类，需要在构建 groups 的地方加
# 先找到调用 SettingsScreen 的地方（通常在 MusicHomeActivity）
print()
print("2) 查找 SettingsScreen 调用点...")

import os
found = []
for root, dirs, files in os.walk("app/src/main/java"):
    for fn in files:
        if fn.endswith(".kt"):
            fp = os.path.join(root, fn)
            try:
                with open(fp, encoding="utf-8") as f:
                    content = f.read()
                if "SettingsScreen(" in content and "fun SettingsScreen(" not in content:
                    # 是调用点，不是定义
                    found.append(fp)
            except:
                pass

for fp in found[:5]:
    print(f"   调用点: {fp}")

print()
print("=== 32 v14 完成 ===")
print("说明: MainActivity 已换 LxMusicTheme（跟随系统）。")
print("设置页开关需在 groups 构建处加 SettingItem，待定位调用点后处理。")
PYEOF


echo "=== 32 v15: ThemeSettingsPage 全文 ==="
python3 << 'PYEOF2'
import os
for root, dirs, files in os.walk("app/src/main/java"):
    for fn in files:
        if fn == "ThemeSettingsPage.kt":
            fp = os.path.join(root, fn)
            with open(fp, encoding="utf-8") as f:
                lines = f.readlines()
            print(f"文件: {fp}, 共 {len(lines)} 行")
            print("=" * 50)
            for i, line in enumerate(lines, 1):
                print(f"{i:3d}: {line}", end="")
            break
PYEOF2
echo "=== 32 v15 完成 ==="

# 32 v16: ThemeSettingsPage 加主题循环切换（简化版，无对话框）
echo "=== 32 v16: 主题切换（循环版）==="

python3 << 'PYEOF'
import re, os

tpath = None
for root, dirs, files in os.walk("app/src/main/java"):
    for fn in files:
        if fn == "ThemeSettingsPage.kt":
            tpath = os.path.join(root, fn)
            break
    if tpath:
        break

with open(tpath, encoding="utf-8") as f:
    src = f.read()

MARK = "// [32v16]"
if MARK in src:
    print("已添加，跳过")
else:
    # 1) 加 import（DataStore 相关）
    imports_needed = [
        "import androidx.compose.runtime.getValue",
        "import androidx.compose.runtime.setValue",
        "import androidx.compose.runtime.collectAsState",
        "import androidx.datastore.preferences.core.intPreferencesKey",
        "import androidx.datastore.preferences.core.edit",
        "import kotlinx.coroutines.launch",
    ]
    # 找最后一个 import
    imports = list(re.finditer(r'^import .+$', src, re.MULTILINE))
    if imports:
        pos = imports[-1].end()
        to_add = [imp for imp in imports_needed if imp not in src]
        if to_add:
            src = src[:pos] + "\n" + "\n".join(to_add) + src[pos:]
            print(f"1) 加 import: {len(to_add)} 个")

    # 2) 在 ThemeSettingsPage 函数内开头加状态和 DataStore 逻辑
    m = re.search(r'fun\s+ThemeSettingsPage\s*\([^)]*\)\s*\{', src)
    if m:
        pos = m.end()
        code = f'''
    {MARK} 主题模式状态
    val ctx = androidx.compose.ui.platform.LocalContext.current
    val scope = androidx.compose.runtime.rememberCoroutineScope()
    val themeKey = intPreferencesKey("theme_mode")
    // 直接用 DataStore，不依赖 ThemeViewModel（避免 Hilt 问题）
    val themeMode by ctx.dataStore.data
        .map {{ prefs -> prefs[themeKey] ?: 0 }}
        .collectAsState(initial = 0)
    val modeLabel = when (themeMode) {{
        1 -> "深色"
        2 -> "浅色"
        else -> "跟随系统"
    }}
    fun cycleTheme() {{
        scope.launch {{
            ctx.dataStore.edit {{ prefs ->
                prefs[themeKey] = (themeMode + 1) % 3
            }}
        }}
    }}
'''
        src = src[:pos] + code + src[pos:]
        print("2) 已加主题状态逻辑")
    else:
        print("2) 警告: 未找到 ThemeSettingsPage 函数")

    # 3) 在第一个 SettingGroup 前插入主题 Group
    # 需要 dataStore 扩展：复用 ThemeViewModel.kt 中的定义
    # 检查是否有 dataStore 定义，没有则加
    if "val android.content.Context.dataStore" not in src and "Context.dataStore" not in src:
        # 在文件末尾加 dataStore 定义
        ds_code = '''
// [32v16] DataStore
private val android.content.Context.dataStore by androidx.datastore.preferences.preferencesDataStore(name = "theme_prefs")
'''
        src = src.rstrip() + "\n" + ds_code + "\n"
        print("3) 已加 dataStore 定义")

    with open(tpath, "w", encoding="utf-8") as f:
        f.write(src)

print("=== 32 v16 完成 ===")
print("说明: 点击'深色模式'会在 跟随系统->深色->浅色 间循环切换")
PYEOF

# 追加：插入 SettingItem 到第一个 items listOf
python3 << 'PYEOF2'
import re, os
tpath = None
for root, dirs, files in os.walk("app/src/main/java"):
    for fn in files:
        if fn == "ThemeSettingsPage.kt":
            tpath = os.path.join(root, fn)
            break
    if tpath:
        break
with open(tpath, encoding="utf-8") as f:
    src = f.read()
# 在第一个 items = listOf( 后插入
m = re.search(r'items\s*=\s*listOf\(\s*\n', src)
if m and "// [32v16] theme item" not in src:
    pos = m.end()
    # 获取缩进
    line_start = src.rfind('\n', 0, pos) + 1
    next_line_end = src.find('\n', pos)
    next_line = src[pos:next_line_end] if next_line_end != -1 else ""
    indent = next_line[:len(next_line) - len(next_line.lstrip())] if next_line.strip() else "                "
    item_code = f'''// [32v16] theme item
{indent}SettingItem(
{indent}    title = "深色模式",
{indent}    subtitle = modeLabel,
{indent}    action = {{ cycleTheme() }}
{indent}),
'''
    src = src[:pos] + item_code + src[pos:]
    with open(tpath, "w", encoding="utf-8") as f:
        f.write(src)
    print("4) 已插入主题 SettingItem")
else:
    print("4) 跳过（已插入或未找到位置）")
PYEOF2

# 32 v17: 修复 dataStore 引用
echo "=== 32 v17: 修复 dataStore ==="

python3 << 'PYEOF'
import re, os

tpath = None
for root, dirs, files in os.walk("app/src/main/java"):
    for fn in files:
        if fn == "ThemeSettingsPage.kt":
            tpath = os.path.join(root, fn)
            break
    if tpath:
        break

with open(tpath, encoding="utf-8") as f:
    src = f.read()

# 1) 确保 import 正确
# preferencesDataStore 需要 import
if "import androidx.datastore.preferences.preferencesDataStore" not in src:
    m = re.search(r'^import androidx\.datastore\.preferences\.core\.edit$', src, re.MULTILINE)
    if m:
        src = src[:m.end()] + "\nimport androidx.datastore.preferences.preferencesDataStore" + src[m.end():]
        print("1) 已加 preferencesDataStore import")

# 2) 修复 dataStore 定义：确保在文件顶部（package 后）定义，且非 private
# 先删除旧的 private 定义
src = re.sub(r'\n?// \[32v16\] DataStore\nprivate val android\.content\.Context\.dataStore[^\n]+\n', '\n', src)

# 在 package 行后添加
m2 = re.search(r'^package .+$', src, re.MULTILINE)
if m2 and "val android.content.Context.dataStore" not in src:
    ds_def = '''
// [32v17] DataStore for theme
internal val android.content.Context.themeDataStore by preferencesDataStore(name = "theme_prefs")
'''
    src = src[:m2.end()] + ds_def + src[m2.end():]
    print("2) 已加 themeDataStore 定义（internal）")

# 3) 替换所有 ctx.dataStore 为 ctx.themeDataStore
src = src.replace("ctx.dataStore", "ctx.themeDataStore")
src = src.replace("context.dataStore", "context.themeDataStore")
print("3) 已替换 dataStore 引用")

with open(tpath, "w", encoding="utf-8") as f:
    f.write(src)

print("=== 32 v17 完成 ===")
PYEOF

# 32 v18: 正确放置 dataStore 定义（import 之后）
echo "=== 32 v18: 修正位置 ==="

python3 << 'PYEOF'
import re, os

tpath = None
for root, dirs, files in os.walk("app/src/main/java"):
    for fn in files:
        if fn == "ThemeSettingsPage.kt":
            tpath = os.path.join(root, fn)
            break
    if tpath:
        break

with open(tpath, encoding="utf-8") as f:
    src = f.read()

# 1) 删除 v17 错误放置的定义（package 后、import 前）
src = re.sub(r'\n// \[32v17\] DataStore for theme\ninternal val android\.content\.Context\.themeDataStore[^\n]+\n', '\n', src)

# 2) 确保 import 在正确位置（最后一个 import 后）
if "import androidx.datastore.preferences.preferencesDataStore" not in src:
    imports = list(re.finditer(r'^import .+$', src, re.MULTILINE))
    if imports:
        pos = imports[-1].end()
        src = src[:pos] + "\nimport androidx.datastore.preferences.preferencesDataStore" + src[pos:]
        print("1) import 已加到正确位置")

# 3) 在最后一个 import 后加 dataStore 定义
if "themeDataStore" not in src or "val android.content.Context.themeDataStore" not in src:
    imports = list(re.finditer(r'^import .+$', src, re.MULTILINE))
    if imports:
        pos = imports[-1].end()
        ds_def = '''

// [32v18] Theme DataStore
internal val android.content.Context.themeDataStore by preferencesDataStore(name = "theme_prefs")'''
        src = src[:pos] + ds_def + src[pos:]
        print("2) themeDataStore 定义已加到 import 后")

# 4) 替换引用
src = src.replace("ctx.dataStore", "ctx.themeDataStore")
print("3) 引用已替换")

with open(tpath, "w", encoding="utf-8") as f:
    f.write(src)

print("=== 32 v18 完成 ===")
PYEOF

# 32 v19: 清掉 v16-v18 的 DataStore，改用 SharedPreferences
echo "=== 32 v19: SharedPreferences 重构 ==="

python3 << 'PYEOF'
import re, os

tpath = None
for root, dirs, files in os.walk("app/src/main/java"):
    for fn in files:
        if fn == "ThemeSettingsPage.kt":
            tpath = os.path.join(root, fn)
            break
    if tpath:
        break

with open(tpath, encoding="utf-8") as f:
    src = f.read()

# 1) 删除 v16 加的状态代码块（从 MARK 到 cycleTheme 函数结束）
# MARK = "// [32v16]"
src = re.sub(
    r'\n\s*// \[32v16\][^\n]*\n(?:.*?\n)*?\s*fun cycleTheme\(\) \{\s*\n(?:.*?\n)*?\s*\}\s*\n',
    '\n',
    src,
    count=1
)

# 2) 删除 v16 插入的 SettingItem
src = re.sub(
    r'// \[32v16\] theme item\n[^\n]*SettingItem\(\n(?:[^\n]*\n)*?[^\n]*action = \{ cycleTheme\(\) \}[^\n]*\n[^\n]*\),\n',
    '',
    src,
    count=1
)

# 3) 删除 v16/v17/v18 的 dataStore 定义
src = re.sub(r'\n// \[32v1[678]\][^\n]*\ninternal val android\.content\.Context\.themeDataStore[^\n]*\n', '\n', src)
src = re.sub(r'\n// \[32v16\] DataStore\nprivate val android\.content\.Context\.dataStore[^\n]*\n', '\n', src)

# 4) 删除 DataStore 相关的 import
src = re.sub(r'^import androidx\.datastore[^\n]*\n', '', src, flags=re.MULTILINE)
src = re.sub(r'^import kotlinx\.coroutines\.launch\n', '', src, flags=re.MULTILINE)

# 5) 删除 v16 加的 import（getValue/setValue/collectAsState 如果只用于主题）
# 保留它们，因为文件其他地方可能用

print("1-4) v16-v18 DataStore 代码已清理")

# 6) 加 SharedPreferences 版本的主题切换
# 在 ThemeSettingsPage 函数开头插入
m = re.search(r'fun\s+ThemeSettingsPage\s*\([^)]*\)\s*\{', src)
MARK19 = "// [32v19]"
if m and MARK19 not in src:
    pos = m.end()
    code = f'''
    {MARK19} 主题切换（SharedPreferences，无 DataStore 委托）
    val themeCtx = androidx.compose.ui.platform.LocalContext.current
    val themePrefs = themeCtx.getSharedPreferences("theme_prefs", android.content.Context.MODE_PRIVATE)
    var themeModeState by androidx.compose.runtime.remember {{ androidx.compose.runtime.mutableStateOf(themePrefs.getInt("theme_mode", 0)) }}
    val themeModeLabel = when (themeModeState) {{
        1 -> "深色"
        2 -> "浅色"
        else -> "跟随系统"
    }}
    fun cycleThemeMode() {{
        val next = (themeModeState + 1) % 3
        themePrefs.edit().putInt("theme_mode", next).apply()
        themeModeState = next
    }}
'''
    src = src[:pos] + code + src[pos:]
    print("5) SharedPreferences 主题逻辑已加")

    # 7) 插入 SettingItem
    m2 = re.search(r'items\s*=\s*listOf\(\s*\n', src)
    if m2 and "32v19" not in src[m2.end():m2.end()+500]:
        pos2 = m2.end()
        line_end = src.find('\n', pos2)
        next_line = src[pos2:line_end] if line_end != -1 else ""
        indent = next_line[:len(next_line) - len(next_line.lstrip())] if next_line.strip() else "                "
        item_code = f'''{MARK19} theme item
{indent}SettingItem(
{indent}    title = "深色模式",
{indent}    subtitle = themeModeLabel,
{indent}    action = {{ cycleThemeMode() }}
{indent}),
'''
        src = src[:pos2] + item_code + src[pos2:]
        print("6) 主题 SettingItem 已插入")

# 8) 确保必要的 import
needed = [
    "import androidx.compose.runtime.getValue",
    "import androidx.compose.runtime.setValue",
]
imports = list(re.finditer(r'^import .+$', src, re.MULTILINE))
if imports:
    pos = imports[-1].end()
    to_add = [imp for imp in needed if imp not in src]
    if to_add:
        src = src[:pos] + "\n" + "\n".join(to_add) + src[pos:]
        print(f"7) 补 import: {to_add}")

with open(tpath, "w", encoding="utf-8") as f:
    f.write(src)

print("=== 32 v19 完成 ===")
PYEOF

# 32 v20: MainActivity 读取主题设置
echo "=== 32 v20: MainActivity 读主题 ==="

python3 << 'PYEOF'
import re

mpath = "app/src/main/java/com/github/tvbox/osc/ui/activity/MainActivity.kt"
with open(mpath, encoding="utf-8") as f:
    src = f.read()

MARK = "// [32v20]"
if MARK in src:
    print("已处理，跳过")
else:
    # 找到 LxMusicTheme {，在其前插入主题读取逻辑
    # v14 已把 AVBoxTheme 换成 LxMusicTheme
    old = "com.github.tvbox.osc.ui.activity.LxMusicTheme {"
    if old in src:
        new_code = f'''{MARK} 读取用户主题设置
                val themeCtx = androidx.compose.ui.platform.LocalContext.current
                val themePrefs = themeCtx.getSharedPreferences("theme_prefs", android.content.Context.MODE_PRIVATE)
                val savedMode = themePrefs.getInt("theme_mode", 0)
                val isDarkTheme = when (savedMode) {{
                    1 -> true
                    2 -> false
                    else -> androidx.compose.foundation.isSystemInDarkTheme()
                }}
                com.github.tvbox.osc.ui.activity.LxMusicTheme(isDarkTheme = isDarkTheme) {{'''
        src = src.replace(old, new_code, 1)
        print("MainActivity 已接主题设置读取")
    else:
        print("警告: 未找到 LxMusicTheme 调用")

    with open(mpath, "w", encoding="utf-8") as f:
        f.write(src)

print("=== 32 v20 完成 ===")
print("说明: 0=跟随系统, 1=深色, 2=浅色")
PYEOF

echo "=== 32 v22: 定位真正的主题外观页 ==="
python3 << 'PYEOF'
import os, re
# 找包含"深色主题"或"背景随封面变化"的 Kotlin 文件
hits = []
for root, dirs, files in os.walk("app/src/main/java"):
    for fn in files:
        if fn.endswith(".kt"):
            fp = os.path.join(root, fn)
            try:
                with open(fp, encoding="utf-8") as f:
                    c = f.read()
                if "深色主题" in c or "背景随封面变化" in c:
                    hits.append(fp)
            except:
                pass
print("命中文件:")
for h in hits:
    print(" ", h)
PYEOF

# 32 v23: MainActivity 完全恢复原状（回滚 v14/v20）

echo "=== 32 v23: MainActivity 回滚 ==="

python3 << 'PYEOF'
import re

mpath = "app/src/main/java/com/github/tvbox/osc/ui/activity/MainActivity.kt"
with open(mpath, encoding="utf-8") as f:
    src = f.read()

MARK23 = "// [32v23]"

if MARK23 in src:
    print("已回滚，跳过")
else:
    orig_len = len(src)
    
    # 删除 v20 加的主题读取块
    src = re.sub(
        r'\s*// \[32v20\][^\n]*\n(?:[^\n]*\n)*?.*?LxMusicTheme\(isDarkTheme = isDarkTheme\) \{\{',
        '\n                AVBoxTheme {',
        src,
        count=1
    )
    
    # 删除 v14 的标记
    src = src.replace("// [32v14] use LxMusicTheme\n                ", "")
    
    # 确保 MainScreen 被 AVBoxTheme 包裹（不是 LxMusicTheme）
    # 找 LxMusicTheme 包裹 MainScreen 的，换回 AVBoxTheme
    src = re.sub(
        r'(?:com\.github\.tvbox\.osc\.ui\.activity\.)?LxMusicTheme(?:\(isDarkTheme[^\)]*\))?\s*\{\s*\n(\s*)MainScreen\(\)',
        r'AVBoxTheme {\n\1MainScreen()',
        src
    )
    
    # 加标记
    src = src.replace("AVBoxTheme {", f"{MARK23} restored\n                AVBoxTheme {{", 1)
    
    with open(mpath, "w", encoding="utf-8") as f:
        f.write(src)
    print(f"MainActivity 已恢复（{orig_len} -> {len(src)} 字符）")

print("=== 32 v23 完成 ===")
print("主体 MainActivity 恢复原状，主题只留给音乐区")
PYEOF

# 32 v24: 打印 MusicHomeActivity setContent 结构（只看不改）
echo "=== 32 v24: MusicHomeActivity 结构 ==="
python3 << 'PYEOF'
import os, re
for root, dirs, files in os.walk("app/src/main/java"):
    for fn in files:
        if fn == "MusicHomeActivity.kt":
            fp = os.path.join(root, fn)
            with open(fp, encoding="utf-8") as f:
                lines = f.readlines()
            print(f"文件: {fp}, 共 {len(lines)} 行")
            for i, line in enumerate(lines, 1):
                if 'setContent' in line or 'AVBoxTheme' in line or 'LxMusicTheme' in line:
                    # 打印上下文
                    s = max(0, i-3)
                    e = min(len(lines), i+8)
                    print(f"--- 第 {i} 行附近 ---")
                    for j in range(s, e):
                        print(f"{j+1:4d}: {lines[j]}", end="")
                    print()
            break
PYEOF
echo "=== 32 v24 完成 ==="

# 32 v25: 硬恢复 MainActivity（简化版）

echo "=== 32 v25: 硬恢复 MainActivity ==="

python3 << 'PYEOF'
mpath = "app/src/main/java/com/github/tvbox/osc/ui/activity/MainActivity.kt"
with open(mpath, encoding="utf-8") as f:
    src = f.read()

# 直接用字符串替换：找到 setContent { 到其匹配的 } 
# 策略：找到 "setContent {"，然后向后数括号找到匹配的 "}"
idx = src.find("setContent {")
if idx == -1:
    idx = src.find("setContent{")
if idx == -1:
    print("错误: 未找到 setContent")
else:
    # 从 { 开始数
    start = src.find("{", idx)
    depth = 0
    end = -1
    for i in range(start, len(src)):
        if src[i] == '{':
            depth += 1
        elif src[i] == '}':
            depth -= 1
            if depth == 0:
                end = i
                break
    
    if end != -1:
        # 获取缩进（setContent 所在行的缩进）
        line_start = src.rfind("\n", 0, idx) + 1
        indent = src[line_start:idx]
        # indent 是 "        " 之类的，内容缩进再加 4 空格
        inner = indent + "    "
        new_inner = f"\n{inner}AVBoxTheme {{\n{inner}    MainScreen()\n{inner}}}\n{indent}"
        src = src[:start+1] + new_inner + src[end:]
        
        with open(mpath, "w", encoding="utf-8") as f:
            f.write(src)
        print("MainActivity 已硬恢复")
        print("MARK: [32v25] done")
    else:
        print("错误: 括号不匹配")
PYEOF
echo "=== 32 v25 完成 ==="

# 32 v26: 从 AVBox 原仓库直接覆盖 MainActivity.kt

echo "=== 32 v26: 原版覆盖 MainActivity ==="

MPATH="app/src/main/java/com/github/tvbox/osc/ui/activity/MainActivity.kt"
URL="https://raw.githubusercontent.com/moonbbin/AVBox/main/app/src/main/java/com/github/tvbox/osc/ui/activity/MainActivity.kt"

if curl -sL "$URL" -o /tmp/MainActivity_avbox.kt; then
    ORIG_SIZE=$(wc -c < /tmp/MainActivity_avbox.kt)
    # 验证下载的是 Kotlin 文件（包含 package）
    if grep -q "^package " /tmp/MainActivity_avbox.kt; then
        cp /tmp/MainActivity_avbox.kt "$MPATH"
        echo "已用 AVBox 原版覆盖 ($ORIG_SIZE 字符)"
        echo "MARK: [32v26] done"
    else
        echo "错误: 下载的内容不是有效的 Kotlin 文件"
        exit 1
    fi
else
    echo "错误: 下载失败"
    exit 1
fi

echo "=== 32 v26 完成 ==="

# 32 v27: 打印 LxThemeSettingsActivity 结构 + 清理 ThemeSettingsPage 错加的代码

echo "=== 32 v27: 真正的主题页结构 ==="

python3 << 'PYEOF'
import os, re

# 1) 打印 LxThemeSettingsActivity.kt 中"深色主题"附近的结构
for root, dirs, files in os.walk("app/src/main/java"):
    for fn in files:
        if fn == "LxThemeSettingsActivity.kt":
            fp = os.path.join(root, fn)
            with open(fp, encoding="utf-8") as f:
                lines = f.readlines()
            print(f"文件: {fp}, 共 {len(lines)} 行")
            for i, line in enumerate(lines, 1):
                if "深色主题" in line:
                    s = max(0, i-15)
                    e = min(len(lines), i+15)
                    print(f"--- '深色主题' 在第 {i} 行，上下文 ---")
                    for j in range(s, e):
                        print(f"{j+1:4d}: {lines[j]}", end="")
                    print()
            break

print()
print("=== 清理 ThemeSettingsPage.kt 错加的代码 ===")

# 2) 清理 ThemeSettingsPage.kt 中的 v16-v19 代码
tpath = None
for root, dirs, files in os.walk("app/src/main/java"):
    for fn in files:
        if fn == "ThemeSettingsPage.kt":
            tpath = os.path.join(root, fn)
            break
    if tpath:
        break

if tpath:
    with open(tpath, encoding="utf-8") as f:
        src = f.read()
    orig = len(src)
    # 删除 [32v16], [32v19] 标记的代码块
    # v16 加的状态代码
    src = re.sub(r'\n\s*// \[32v16\][^\n]*\n', '\n', src)
    src = re.sub(r'\n\s*// \[32v19\][^\n]*\n', '\n', src)
    # 删除 themeModeState 相关（v19 加的）
    # 谨慎：只删明确是 v19 加的行
    lines = src.split('\n')
    new_lines = []
    skip = False
    for line in lines:
        if '[32v19]' in line or '[32v16]' in line:
            skip = True
            continue
        # v19 加的 theme 相关变量（通过特征识别）
        if 'themeModeState' in line or 'themeModeLabel' in line or 'cycleThemeMode' in line:
            continue
        if 'themeCtx' in line or 'themePrefs' in line:
            continue
        new_lines.append(line)
    src = '\n'.join(new_lines)
    # 删除 theme item
    src = re.sub(r'// \[32v19\] theme item\n(?:[^\n]*\n)*?.*?action = \{ cycleThemeMode\(\) \}[^\n]*\n[^\n]*\),\n', '', src)
    src = re.sub(r'// \[32v16\] theme item\n(?:[^\n]*\n)*?.*?action = \{ cycleTheme\(\) \}[^\n]*\n[^\n]*\),\n', '', src)
    
    with open(tpath, "w", encoding="utf-8") as f:
        f.write(src)
    print(f"ThemeSettingsPage.kt 已清理 ({orig} -> {len(src)} 字符)")
else:
    print("未找到 ThemeSettingsPage.kt")

print("=== 32 v27 完成 ===")
PYEOF

# 32 v28: 找 MusicThemeManager 定义 + 加三档切换

echo "=== 32 v28: MusicThemeManager 结构 ==="

python3 << 'PYEOF'
import os, re, sys

# 找 MusicThemeManager 定义
mpath = None
for root, dirs, files in os.walk("app/src/main/java"):
    for fn in files:
        if "MusicThemeManager" in fn and fn.endswith(".kt"):
            mpath = os.path.join(root, fn)
            break
    if mpath:
        break

if not mpath:
    # 搜文件内容
    for root, dirs, files in os.walk("app/src/main/java"):
        for fn in files:
            if fn.endswith(".kt"):
                fp = os.path.join(root, fn)
                try:
                    with open(fp, encoding="utf-8") as f:
                        c = f.read()
                    if "object MusicThemeManager" in c or "class MusicThemeManager" in c:
                        mpath = fp
                        break
                except:
                    pass
        if mpath:
            break

if mpath:
    print(f"文件: {mpath}")
    with open(mpath, encoding="utf-8") as f:
        src = f.read()
    print(f"共 {len(src.split(chr(10)))} 行")
    print("--- 内容 ---")
    print(src[:3000])
else:
    print("错误: 未找到 MusicThemeManager")
    sys.exit(1)
PYEOF

# 32 v29: 提取完整的 MusicThemeManager

echo "=== 32 v29: MusicThemeManager 完整定义 ==="

python3 << 'PYEOF'
import os, re

for root, dirs, files in os.walk("app/src/main/java"):
    for fn in files:
        if fn == "LxMusicTheme.kt":
            fp = os.path.join(root, fn)
            with open(fp, encoding="utf-8") as f:
                src = f.read()
            # 找到 object MusicThemeManager { 到其匹配的 }
            idx = src.find("object MusicThemeManager")
            if idx != -1:
                start = src.find("{", idx)
                depth = 0
                end = -1
                for i in range(start, len(src)):
                    if src[i] == '{':
                        depth += 1
                    elif src[i] == '}':
                        depth -= 1
                        if depth == 0:
                            end = i
                            break
                if end != -1:
                    print(src[idx:end+1])
                else:
                    print("错误: 括号不匹配")
            else:
                print("错误: 未找到")
            break
PYEOF
echo "=== 32 v29 完成 ==="

# 32 v30: 给 LxThemeSettingsActivity.kt 加三档切换（补丁已生成的源文件）

echo "=== 32 v30: 主题页三档切换 ==="

TPATH="app/src/main/java/com/github/tvbox/osc/ui/activity/LxThemeSettingsActivity.kt"
if [ ! -f "$TPATH" ]; then
    echo "错误: 未找到 $TPATH（12 号脚本未生成？）"
    exit 1
fi

python3 << 'PYEOF'
import re, sys

with open("app/src/main/java/com/github/tvbox/osc/ui/activity/LxThemeSettingsActivity.kt", encoding="utf-8") as f:
    src = f.read()

MARK = "// [32v30]"
if MARK in src:
    print("已处理，跳过")
    sys.exit(0)

# 锚点：Switch( ... checked = isDark, ... onCheckedChange = { MusicThemeManager.setDarkTheme(it) }
# 找到 Switch 块
m = re.search(
    r'(                    Switch\(\n'
    r'                        modifier = Modifier\.scale\(0\.85f\),\n'
    r'                        checked = isDark,\n'
    r'                        onCheckedChange = \{ MusicThemeManager\.setDarkTheme\(it\) \},\n'
    r'                        colors = SwitchDefaults\.colors\(\n'
    r'                            checkedThumbColor = musicColors\(\)\.textPrimary,\n'
    r'                            checkedTrackColor = musicColors\(\)\.accent\n'
    r'                        \)\n'
    r'                    \))',
    src
)
if not m:
    print("错误: 未找到 Switch 锚点")
    sys.exit(1)

old_switch = m.group(1)

new_ui = '''                    // [32v30] 三档主题切换：跟随系统/深色/浅色
                    val ctx30 = androidx.compose.ui.platform.LocalContext.current
                    val prefs30 = ctx30.getSharedPreferences("theme_prefs", android.content.Context.MODE_PRIVATE)
                    var themeMode30 by androidx.compose.runtime.remember { androidx.compose.runtime.mutableStateOf(prefs30.getInt("theme_mode", 0)) }
                    androidx.compose.foundation.layout.Column {
                        listOf("跟随系统" to 0, "深色" to 1, "浅色" to 2).forEach { (label, mode) ->
                            androidx.compose.foundation.layout.Row(
                                modifier = androidx.compose.ui.Modifier
                                    .clickable {
                                        prefs30.edit().putInt("theme_mode", mode).apply()
                                        themeMode30 = mode
                                        when (mode) {
                                            1 -> MusicThemeManager.setDarkTheme(true)
                                            2 -> MusicThemeManager.setDarkTheme(false)
                                            else -> { /* 跟随系统 */ }
                                        }
                                    }
                                    .padding(vertical = 4.dp),
                                verticalAlignment = androidx.compose.ui.Alignment.CenterVertically
                            ) {
                                androidx.compose.material3.RadioButton(
                                    selected = themeMode30 == mode,
                                    onClick = null,
                                    colors = androidx.compose.material3.RadioButtonDefaults.colors(
                                        selectedColor = musicColors().accent
                                    )
                                )
                                androidx.compose.foundation.layout.Spacer(modifier = androidx.compose.ui.Modifier.width(8.dp))
                                androidx.compose.material3.Text(
                                    text = label,
                                    color = musicColors().textPrimary,
                                    style = androidx.compose.material3.MaterialTheme.typography.bodyMedium
                                )
                            }
                        }
                    }'''

src = src.replace(old_switch, new_ui)

with open("app/src/main/java/com/github/tvbox/osc/ui/activity/LxThemeSettingsActivity.kt", "w", encoding="utf-8") as f:
    f.write(src)
print("三档切换已插入")
PYEOF

echo "=== 32 v30 完成 ==="

# 32 v31: 修三档切换的"跟随系统"（正确版）

echo "=== 32 v31: 三档切换接通 ==="

python3 << 'PYEOF'
import re, sys

with open("app/src/main/java/com/github/tvbox/osc/ui/activity/LxThemeSettingsActivity.kt", encoding="utf-8") as f:
    src = f.read()

MARK = "// [32v31]"
if MARK in src:
    print("已处理，跳过")
    sys.exit(0)

# v30 的代码结构：
# val ctx30 = ...
# val prefs30 = ...
# var themeMode30 by ...
# Column { listOf(...).forEach { ... clickable { ... when(mode) {...} } } }
#
# 需要在 clickable 外面（Composable 作用域）获取 sysDark
# 找到 "var themeMode30 by" 那行，在它后面加 sysDark

old = '''                    var themeMode30 by androidx.compose.runtime.remember { androidx.compose.runtime.mutableStateOf(prefs30.getInt("theme_mode", 0)) }'''

new = '''                    var themeMode30 by androidx.compose.runtime.remember { androidx.compose.runtime.mutableStateOf(prefs30.getInt("theme_mode", 0)) }
                    // [32v31] 系统主题（Composable 作用域获取）
                    val sysDark30 = androidx.compose.foundation.isSystemInDarkTheme()'''

if old not in src:
    print("错误: 未找到 themeMode30 锚点")
    sys.exit(1)

src = src.replace(old, new)

# 替换 when (mode) 块
old_when = '''                                        when (mode) {
                                            1 -> MusicThemeManager.setDarkTheme(true)
                                            2 -> MusicThemeManager.setDarkTheme(false)
                                            else -> { /* 跟随系统 */ }
                                        }'''

new_when = '''                                        when (mode) {
                                            1 -> MusicThemeManager.setDarkTheme(true)
                                            2 -> MusicThemeManager.setDarkTheme(false)
                                            else -> MusicThemeManager.setDarkTheme(sysDark30)
                                        }'''

if old_when not in src:
    print("错误: 未找到 when 锚点")
    sys.exit(1)

src = src.replace(old_when, new_when)

with open("app/src/main/java/com/github/tvbox/osc/ui/activity/LxThemeSettingsActivity.kt", "w", encoding="utf-8") as f:
    f.write(src)
print("跟随系统已接通")
PYEOF

echo "=== 32 v31 完成 ==="

# 32 v32: 删除"背景随封面变化"（用户确认无用）

echo "=== 32 v32: 删除背景随封面变化 ==="

python3 << 'PYEOF'
import re, sys

with open("app/src/main/java/com/github/tvbox/osc/ui/activity/LxThemeSettingsActivity.kt", encoding="utf-8") as f:
    src = f.read()

MARK = "// [32v32]"
if MARK in src:
    print("已处理，跳过")
    sys.exit(0)

# 删除从 "// 背景随封面变" 到第二个 Switch 块结束的部分
# 结构：
#                 Spacer(modifier = Modifier.height(8.dp))
#                 Divider(...)
#                 Spacer(modifier = Modifier.height(8.dp))
#
#                 // 背景随封面变
#                 val bgFollow by MusicThemeManager.bgFollowCover
#                 Row(...) { ... Switch(...) }
#
# 我们删除 Spacer+Divider+Spacer+整个背景随封面 Row

# 先找到 "// 背景随封面变" 的位置
idx = src.find("// 背景随封面变")
if idx == -1:
    print("错误: 未找到'背景随封面变'锚点")
    sys.exit(1)

# 往前找 Spacer/Divider 分隔部分（在深色主题 Row 之后）
# 往后找到 Row 块的结束（匹配括号）
# 简化：找到 "// 背景随封面变" 之前最近的 Spacer，分隔符开始
# 实际：删除从第二个 Spacer(modifier = Modifier.height(8.dp)) 到 Row 结束

# 找到 idx 之前的最后两个 Spacer+Divider
# 更简单：用正则匹配整个块
pattern = r'\n                Spacer\(modifier = Modifier\.height\(8\.dp\)\)\n                Divider\(color = musicColors\(\)\.textPrimary\.copy\(alpha = 0\.1f\)\)\n                Spacer\(modifier = Modifier\.height\(8\.dp\)\)\n\n                // 背景随封面变\n.*?(?=\n            \}\n        \})'

m = re.search(pattern, src, re.DOTALL)
if not m:
    print("错误: 正则未匹配到背景随封面块")
    # 调试：打印 idx 附近
    print("--- idx 附近 500 字符 ---")
    print(src[max(0,idx-500):idx+500][:500])
    sys.exit(1)

# 标记删除
src = src[:m.start()] + "\n                // [32v32] 背景随封面变化已删除（用户确认无用）\n" + src[m.end():]

with open("app/src/main/java/com/github/tvbox/osc/ui/activity/LxThemeSettingsActivity.kt", "w", encoding="utf-8") as f:
    f.write(src)
print("背景随封面变化已删除")
PYEOF

echo "=== 32 v32 完成 ==="

# 32 v33: 清掉 MusicThemeManager 里的 bgFollowCover

echo "=== 32 v33: 清 bgFollowCover 代码 ==="

LPATH="app/src/main/java/com/github/tvbox/osc/ui/activity/LxMusicTheme.kt"
if [ ! -f "$LPATH" ]; then
    echo "错误: 未找到 $LPATH"
    exit 1
fi

python3 << 'PYEOF'
import re, sys

with open("app/src/main/java/com/github/tvbox/osc/ui/activity/LxMusicTheme.kt", encoding="utf-8") as f:
    src = f.read()

MARK = "// [32v33]"
if MARK in src:
    print("已处理，跳过")
    sys.exit(0)

orig_len = len(src)

# 1. 删除 KEY 常量（如 KEY_BG_FOLLOW）
# 找 private const val KEY_... = "...bg..." 相关
src = re.sub(r'\n\s*private const val KEY_[A-Z_]*BG[A-Z_]*\s*=\s*"[^"]*"\n', '\n', src)
src = re.sub(r'\n\s*private const val KEY_[A-Z_]*FOLLOW[A-Z_]*\s*=\s*"[^"]*"\n', '\n', src)

# 2. 删除 bgFollowCover StateFlow 定义
# 匹配：val bgFollowCover ... 或 _bgFollowCover ...
src = re.sub(r'\n\s*(private\s+)?val\s+_?bgFollowCover[^\n]*\n', '\n', src)

# 3. 删除 setBgFollowCover 函数
# 匹配 fun setBgFollowCover(...) { ... }
m = re.search(r'\n\s*fun\s+setBgFollowCover\s*\([^)]*\)\s*\{', src)
if m:
    start = m.start()
    # 数括号找到函数结束
    brace_start = src.find('{', m.start())
    depth = 0
    end = -1
    for i in range(brace_start, len(src)):
        if src[i] == '{':
            depth += 1
        elif src[i] == '}':
            depth -= 1
            if depth == 0:
                end = i + 1
                break
    if end != -1:
        src = src[:start] + f"\n    {MARK} setBgFollowCover 已删除\n" + src[end:]

# 4. 如果还有残留的 bgFollowCover 引用（非定义），报错
remaining = [line for line in src.split('\n') if 'bgFollowCover' in line and MARK not in line]
if remaining:
    print(f"警告: 还有 {len(remaining)} 处残留引用：")
    for line in remaining[:5]:
        print(f"  {line.strip()[:80]}")
    # 不 exit 1，让构建继续（可能是注释）
else:
    print("bgFollowCover 已清干净")

print(f"长度: {orig_len} -> {len(src)}")

with open("app/src/main/java/com/github/tvbox/osc/ui/activity/LxMusicTheme.kt", "w", encoding="utf-8") as f:
    f.write(src)
print("已写入")
PYEOF

echo "=== 32 v33 完成 ==="

# 32 v34: 修 v33 遗留的 bgFollowCover 引用

echo "=== 32 v34: 清 bgFollow 残留 ==="

python3 << 'PYEOF'
import re, os, sys

MARK = "// [32v34]"

# 1) LxMusicTheme.kt: 删除残留的 KEY_BG_FOLLOW_COVER 引用（第 109 行附近）
lpath = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxMusicTheme.kt"
with open(lpath, encoding="utf-8") as f:
    src = f.read()

if MARK not in src:
    # 删除所有含 KEY_BG_FOLLOW_COVER 的行（常量定义已删，这是使用处）
    lines = src.split('\n')
    new_lines = []
    for line in lines:
        if 'KEY_BG_FOLLOW_COVER' in line:
            # 如果是 val 定义行，跳过；如果是使用行，也删（因为常量已删）
            continue
        # 删除 bgFollowCover 相关的 StateFlow 初始化残留
        if 'bgFollowCover' in line and 'val' in line and 'StateFlow' in line:
            continue
        new_lines.append(line)
    src = '\n'.join(new_lines)
    # 加标记
    src = src.rstrip() + f"\n{MARK} bgFollow 残留已清\n"
    with open(lpath, "w", encoding="utf-8") as f:
        f.write(src)
    print("LxMusicTheme.kt 残留已清")
else:
    print("LxMusicTheme.kt 已处理")

# 2) LxPlaybackSettingsActivity.kt: 删除 bgFollowCover UI 块
ppath = None
for root, dirs, files in os.walk("app/src/main/java"):
    for fn in files:
        if fn == "LxPlaybackSettingsActivity.kt":
            ppath = os.path.join(root, fn)
            break
    if ppath:
        break

if ppath:
    with open(ppath, encoding="utf-8") as f:
        psrc = f.read()
    if MARK not in psrc:
        # 找到 setBgFollowCover 调用，往前找整个 Row 块删除
        # 简化：删除含 bgFollowCover/setBgFollowCover 的行所在的 Row 块
        # 用括号匹配找 Row { ... }
        idx = psrc.find("setBgFollowCover")
        if idx != -1:
            # 往前找最近的 Row( 或 Column 包含
            # 往后找匹配的 } 
            # 简化策略：删除从 "背景随封面" 注释（或 Text）到 Switch 块结束
            # 先找 "背景随封面" 文本
            t_idx = psrc.rfind("背景随封面", 0, idx)
            if t_idx != -1:
                # 往前找 Row( 的开始
                row_start = psrc.rfind("Row(", 0, t_idx)
                if row_start != -1:
                    # 括号匹配找 Row 结束
                    b_start = psrc.find("(", row_start)
                    depth = 0
                    end = -1
                    for i in range(b_start, len(psrc)):
                        if psrc[i] == '(':
                            depth += 1
                        elif psrc[i] == ')':
                            depth -= 1
                            if depth == 0:
                                # Row( ... ) 结束，再找 { ... } 
                                # 实际上 Row( modifier ) { content }
                                # 找到 ) 后的 {
                                brace = psrc.find('{', i)
                                if brace != -1:
                                    d2 = 0
                                    for j in range(brace, len(psrc)):
                                        if psrc[j] == '{':
                                            d2 += 1
                                        elif psrc[j] == '}':
                                            d2 -= 1
                                            if d2 == 0:
                                                end = j + 1
                                                break
                                break
                    if end != -1:
                        psrc = psrc[:row_start] + f"\n{MARK} 背景随封面 UI 已删除\n" + psrc[end:]
                        print("LxPlaybackSettingsActivity.kt UI 块已删除")
                    else:
                        print("警告: 未找到 Row 块结束")
                else:
                    print("警告: 未找到 Row( 开始")
            else:
                print("警告: 未找到'背景随封面'文本，尝试按行删除")
                lines = psrc.split('\n')
                new_lines = [l for l in lines if 'bgFollowCover' not in l and 'BgFollowCover' not in l and '背景随封面' not in l]
                psrc = '\n'.join(new_lines)
                print("按行删除完成")
        else:
            print("未找到 setBgFollowCover 调用")
        
        with open(ppath, "w", encoding="utf-8") as f:
            f.write(psrc)
    else:
        print("LxPlaybackSettingsActivity.kt 已处理")
else:
    print("未找到 LxPlaybackSettingsActivity.kt")

print("=== 32 v34 完成 ===")
PYEOF

# 32 v35: MusicHomeActivity 硬编码背景改走主题

echo "=== 32 v35: 音乐首页背景接主题 ==="

MPATH="app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"
if [ ! -f "$MPATH" ]; then
    echo "错误: 未找到 $MPATH"
    exit 1
fi

python3 << 'PYEOF'
import sys

with open("app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt", encoding="utf-8") as f:
    src = f.read()

MARK = "// [32v35]"
if MARK in src:
    print("已处理，跳过")
    sys.exit(0)

# 1. Scaffold 的 containerColor: BgDeepBlue -> musicColors().background
old1 = "        containerColor = BgDeepBlue,"
new1 = f"        containerColor = musicColors().background, {MARK}"
if old1 not in src:
    print("错误: 未找到 Scaffold containerColor 锚点")
    sys.exit(1)
src = src.replace(old1, new1, 1)
print("Scaffold 背景已接主题")

# 2. NavigationBar 的 containerColor: BgDarker -> musicColors().card
old2 = "                NavigationBar(containerColor = BgDarker) {"
new2 = f"                NavigationBar(containerColor = musicColors().card) {{ {MARK}"
if old2 in src:
    src = src.replace(old2, new2, 1)
    print("NavigationBar 背景已接主题")
else:
    print("警告: 未找到 NavigationBar 锚点，跳过")

with open("app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt", "w", encoding="utf-8") as f:
    f.write(src)
print("已写入")
PYEOF

echo "=== 32 v35 完成 ==="

# 32 v36: 全局替换 MusicHomeActivity 硬编码黑底

echo "=== 32 v36: 硬编码黑底换主题 ==="

MPATH="app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"

python3 << 'PYEOF'
import sys

with open("app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt", encoding="utf-8") as f:
    src = f.read()

MARK = "// [32v36]"
if MARK in src:
    print("已处理，跳过")
    sys.exit(0)

# 替换所有 .background(BgDeepBlue) -> .background(musicColors().background)
# 注意：保留 .copy(alpha=...) 的变体
count = 0

# 1. .background(BgDeepBlue.copy(alpha = Xf)) -> .background(musicColors().background.copy(alpha = Xf))
import re
pattern1 = r'\.background\(BgDeepBlue\.copy\(alpha = ([0-9.]+f)\)\)'
def repl1(m):
    return f'.background(musicColors().background.copy(alpha = {m.group(1)}))'
src, n1 = re.subn(pattern1, repl1, src)
count += n1
print(f"替换 BgDeepBlue.copy: {n1} 处")

# 2. .background(BgDeepBlue) -> .background(musicColors().background)
src, n2 = re.subn(r'\.background\(BgDeepBlue\)', '.background(musicColors().background)', src)
count += n2
print(f"替换 BgDeepBlue: {n2} 处")

# 3. .background(BgDarker) -> .background(musicColors().background)
src, n3 = re.subn(r'\.background\(BgDarker\)', '.background(musicColors().background)', src)
count += n3
print(f"替换 BgDarker: {n3} 处")

# 加标记（文件末尾）
src = src.rstrip() + f"\n{MARK} 硬编码黑底已换主题，共 {count} 处\n"

with open("app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt", "w", encoding="utf-8") as f:
    f.write(src)
print(f"总计替换 {count} 处")
PYEOF

echo "=== 32 v36 完成 ==="

# 32 v37: TopAppBar 透明 + 状态栏检查

echo "=== 32 v37: TopAppBar 接主题 ==="

MPATH="app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"

python3 << 'PYEOF'
import sys

with open("app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt", encoding="utf-8") as f:
    src = f.read()

MARK = "// [32v37]"
if MARK in src:
    print("已处理，跳过")
    sys.exit(0)

# 3. TopAppBar: containerColor = CardBlue -> Color.Transparent（透出 Scaffold 背景）
old = "colors = TopAppBarDefaults.topAppBarColors(containerColor = CardBlue),"
new = f"colors = TopAppBarDefaults.topAppBarColors(containerColor = androidx.compose.ui.graphics.Color.Transparent), {MARK}"
if old not in src:
    print("错误: 未找到 TopAppBar colors 锚点")
    sys.exit(1)
src = src.replace(old, new, 1)
print("TopAppBar 已透明")

with open("app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt", "w", encoding="utf-8") as f:
    f.write(src)
print("已写入")
PYEOF

echo ""
echo "=== 5. 状态栏检查（只查不改） ==="
# 检查 MusicHomeActivity 是否设置状态栏
python3 << 'PYEOF2'
with open("app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt", encoding="utf-8") as f:
    src = f.read()
if "isAppearanceLightStatusBars" in src:
    print("MusicHomeActivity 里有 isAppearanceLightStatusBars")
    # 打印相关行
    for i, line in enumerate(src.split('\n'), 1):
        if 'isAppearanceLightStatusBars' in line:
            print(f"  行 {i}: {line.strip()[:80]}")
else:
    print("MusicHomeActivity 里没有 isAppearanceLightStatusBars（状态栏由 MainActivity 控制）")
    print("注意：按'只做音乐专区'规则，MainActivity 不碰，状态栏反转需用户确认是否改主体")
PYEOF2

echo "=== 32 v37 完成 ==="

# 32 v38: 终极三修复 - LxMusicTheme 包裹 + musicColors 动态 + 状态栏

echo "=== 32 v38: 终极三修复 ==="

MPATH="app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"
LPATH="app/src/main/java/com/github/tvbox/osc/ui/activity/LxMusicTheme.kt"

python3 << 'PYEOF'
import sys
print("--- v38: skip setContent, handled by v40 ---")
try:
    with open("app/src/main/java/com/github/tvbox/osc/ui/activity/LxMusicTheme.kt", encoding="utf-8") as f:
        lsrc = f.read()
    print("LxMusicTheme.kt exists")
except FileNotFoundError:
    print("LxMusicTheme.kt not found, skip")
print("v38 done")
PYEOF

echo "=== 32 v38 完成 ==="

# 32 v39: 修 window 作用域问题

echo "=== 32 v39: 修 window 作用域 ==="

python3 << 'PYEOF'
import re, sys

with open("app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt", encoding="utf-8") as f:
    src = f.read()

# v38 插入的代码有 bug：SideEffect 里用 window 拿不到
# 修复：在 setContent 开头就 capture window
old_bug = """            // [32v39] 桥接主题 + 状态栏
            val prefs39 = getSharedPreferences("theme_prefs", MODE_PRIVATE)"""

# 实际上 v38 用的是 [32v38] 标记，先检查
if "// [32v38]" in src:
    print("找到 v38 代码，修复 window 作用域")
    # 在 val prefs39 之前加 val win39 = window
    src = src.replace(
        "            // [32v38] 用桥接主题包裹，isDarkTheme 从 MusicThemeManager 读\n            val isDark38 by",
        "            // [32v38] 用桥接主题包裹，isDarkTheme 从 MusicThemeManager 读\n            val win38 = window\n            val isDark38 by",
        1
    )
    # 把 SideEffect 里的 val win = window 改成用 win38
    src = src.replace(
        "                    val win = window\n                    val ctrl = androidx.core.view.WindowCompat.getInsetsController(win, win.decorView)",
        "                    val ctrl = androidx.core.view.WindowCompat.getInsetsController(win38, win38.decorView)",
        1
    )
    print("✓ window 作用域已修")
elif "// [32v39]" in src:
    print("v39 已处理，跳过")
    sys.exit(0)
else:
    print("v38 标记未找到（v38 为跳过版），由 v40 处理")
    # 不退出，继续

with open("app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt", "w", encoding="utf-8") as f:
    f.write(src)
print("已写入")
PYEOF

echo "=== 32 v39 完成 ==="

# 32 v40: 终极三修复（v38/v39 失败后的重做版，不依赖 v38）

echo "=== 32 v40: 终极三修复（重做） ==="

python3 << 'PYEOF'
import re, sys

MPATH = "app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"
with open(MPATH, encoding="utf-8") as f:
    src = f.read()

MARK = "// [32v40]"
if MARK in src:
    print("已处理，跳过")
    sys.exit(0)

# 如果 v38 残留了半成品，先清掉（防止重复）
if "// [32v38]" in src:
    print("发现 v38 残留，清理中...")
    # v38 插入的块以 "// [32v38]" 开头，到 MusicHomeScreen 结束
    # 简单处理：把 v38 的 LxMusicTheme 块恢复成原始 setContent
    # 找到 v38 块的起止
    start = src.find("        setContent {")
    # v38 的块比较长，找下一个 "        }\n    }\n}" 模式
    # 更简单：直接用正则匹配整个 v38 块
    v38_pattern = r'        setContent \{\n            // \[32v38\].*?MusicHomeScreen\(\n                    onBackToAppHome = \{ finish\(\) \}\n                \)\n            \}\n        \}'
    m38 = re.search(v38_pattern, src, re.DOTALL)
    if m38:
        original = """        setContent {
            MaterialTheme {
                MusicHomeScreen(
                    onBackToAppHome = { finish() }
                )
            }
        }"""
        src = src.replace(m38.group(0), original, 1)
        print("✓ v38 残留已清理")
    else:
        print("警告: 未找到 v38 块模式，继续")

# 现在应用 v40：正确的正则匹配原始 setContent
# 注意：raw string 里 \{ 匹配字面 {，\n 匹配换行
pattern = r'        setContent \{\n            MaterialTheme \{\n                MusicHomeScreen\(\n                    onBackToAppHome = \{ finish\(\) \}\n                \)\n            \}\n        \}'

m = re.search(pattern, src)
if not m:
    print("错误: 仍未匹配 setContent，打印实际内容调试:")
    idx = src.find("setContent")
    if idx != -1:
        print(repr(src[idx:idx+250]))
    sys.exit(1)

print("✓ 匹配到 setContent")

new_block = """        setContent {
            // [32v40] 桥接主题：LxMusicTheme 包裹，isDark 从 theme_prefs 读
            val win40 = window
            val prefs40 = getSharedPreferences("theme_prefs", MODE_PRIVATE)
            val mode40 = prefs40.getInt("theme_mode", 0)
            val sysDark40 = androidx.compose.foundation.isSystemInDarkTheme()
            val finalDark40 = when (mode40) {
                1 -> true
                2 -> false
                else -> sysDark40
            }
            androidx.compose.runtime.LaunchedEffect(finalDark40) {
                MusicThemeManager.setDarkTheme(finalDark40)
            }
            LxMusicTheme(isDarkTheme = finalDark40) {
                // [32v40] 状态栏跟随主题（只在音乐区内，不碰 MainActivity）
                androidx.compose.runtime.SideEffect {
                    val ctrl = androidx.core.view.WindowCompat.getInsetsController(win40, win40.decorView)
                    ctrl.isAppearanceLightStatusBars = !finalDark40
                    ctrl.isAppearanceLightNavigationBars = !finalDark40
                }
                MusicHomeScreen(
                    onBackToAppHome = { finish() }
                )
            }
        }"""

src = src.replace(m.group(0), new_block, 1)
print("✓ setContent 已替换为 LxMusicTheme 包裹")

with open(MPATH, "w", encoding="utf-8") as f:
    f.write(src)
print("已写入")
PYEOF

echo "=== 32 v40 完成 ==="

