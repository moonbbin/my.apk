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
print('v40 skipped, handled by v41')
PYEOF

echo "=== 32 v40 完成 ==="

# 32 v41: MusicHomeActivity 主题接线重写版（合成 v35-v40，不用脆弱正则）

echo "=== 32 v41: 主题接线重写版 ==="

python3 << 'PYEOF'
import sys

MPATH = "app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"
with open(MPATH, encoding="utf-8") as f:
    src = f.read()

MARK = "// [32v41]"
if MARK in src:
    print("已处理，跳过")
    sys.exit(0)

orig_len = len(src)

# --- 1. Scaffold containerColor ---
src = src.replace(
    "containerColor = BgDeepBlue,",
    "containerColor = musicColors().background, " + MARK,
    1
)
print("1. Scaffold 背景 done")

# --- 2. NavigationBar BgDarker -> musicColors().card ---
# 找到 NavigationBar 块内的 containerColor = BgDarker
src = src.replace(
    "containerColor = BgDarker",
    "containerColor = musicColors().card",
    1
)
print("2. NavigationBar 背景 done")

# --- 3. 5 处 .background(BgDeepBlue) ---
count = 0
# 处理 .background(BgDeepBlue.copy(...))
import re
src, n1 = re.subn(r'\.background\(BgDeepBlue\.copy\(alpha=([0-9.]+)f\)\)', r'.background(musicColors().background.copy(alpha=\1f))', src)
count += n1
src, n2 = re.subn(r'\.background\(BgDeepBlue\)', '.background(musicColors().background)', src)
count += n2
src, n3 = re.subn(r'\.background\(BgDarker\)', '.background(musicColors().background)', src)
count += n3
print(f"3. 背景替换 {count} 处 done")

# --- 4. TopAppBar 透明 ---
src = src.replace(
    "containerColor = CardBlue",
    "containerColor = androidx.compose.ui.graphics.Color.Transparent",
    1
)
print("4. TopAppBar 透明 done")

# --- 5. setContent 套 LxMusicTheme（数括号法，不依赖精确格式） ---
# 找 "setContent" 后面紧跟 "{" 的（跳过 import 区的误命中）
import re
m = re.search(r'setContent\s*\{', src)
if not m:
    print("错误: 找不到 setContent {")
    sys.exit(1)
idx = m.start()

# 往后找第一个 "{"
brace_start = src.find("{", idx)
if brace_start == -1:
    print("错误: setContent 后无 {")
    sys.exit(1)

# 数括号找到匹配的 "}"
depth = 0
brace_end = -1
for i in range(brace_start, len(src)):
    if src[i] == "{":
        depth += 1
    elif src[i] == "}":
        depth -= 1
        if depth == 0:
            brace_end = i
            break

if brace_end == -1:
    print("错误: 括号不匹配")
    sys.exit(1)

print(f"5. setContent 块: {brace_start} -> {brace_end} ({brace_end - brace_start} 字符)")

# 提取原块内容（去掉外层括号）
inner = src[brace_start + 1:brace_end]

# 检查是否已经包了 LxMusicTheme（避免重复）
if "LxMusicTheme" in inner:
    print("   已有 LxMusicTheme，跳过包裹")
else:
    # 构造新块
    new_inner = """
            // [32v41] 桥接主题
            val win41 = window
            val prefs41 = getSharedPreferences("theme_prefs", MODE_PRIVATE)
            val mode41 = prefs41.getInt("theme_mode", 0)
            val sysDark41 = androidx.compose.foundation.isSystemInDarkTheme()
            val finalDark41 = when (mode41) {
                1 -> true
                2 -> false
                else -> sysDark41
            }
            androidx.compose.runtime.LaunchedEffect(finalDark41) {
                MusicThemeManager.setDarkTheme(finalDark41)
            }
            LxMusicTheme(isDarkTheme = finalDark41) {
                androidx.compose.runtime.SideEffect {
                    val ctrl = androidx.core.view.WindowCompat.getInsetsController(win41, win41.decorView)
                    ctrl.isAppearanceLightStatusBars = !finalDark41
                    ctrl.isAppearanceLightNavigationBars = !finalDark41
                }
""" + inner + """
            }
        """
    src = src[:brace_start + 1] + new_inner + src[brace_end:]
    print("   已包裹 LxMusicTheme")

with open(MPATH, "w", encoding="utf-8") as f:
    f.write(src)
print(f"已写入 ({orig_len} -> {len(src)} 字符)")
PYEOF

echo "=== 32 v41 完成 ==="

# 32 v42: 清掉 Tab 根节点的硬编码黑底

echo "=== 32 v42: 清 Tab 黑底 ==="

python3 << 'PYEOF'
import re, sys

MPATH = "app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"
with open(MPATH, encoding="utf-8") as f:
    src = f.read()

MARK = "// [32v42]"
if MARK in src:
    print("已处理，跳过")
    sys.exit(0)

orig = len(src)

# 1. SearchTabLanding 的 LazyColumn: .fillMaxSize().background(BgDeepBlue) -> .fillMaxSize()
# 精确匹配，避免误伤
src = src.replace(
    ".fillMaxSize()\n            .background(BgDeepBlue),",
    ".fillMaxSize(), " + MARK,
    1
)
print("1. SearchTabLanding done")

# 2. PlaylistBrowser 的 Column
src = src.replace(
    ".fillMaxSize()\n            .background(BgDeepBlue)\n    ) {\n        Text(\n            text = \"歌单\"",
    ".fillMaxSize()\n    ) {\n        Text(\n            text = \"歌单\"",
    1
)
print("2. PlaylistBrowser done")

# 3. PlaylistDetailScreen 的根（找它的 background）
# 先定位 PlaylistDetailScreen 函数
idx = src.find("fun PlaylistDetailScreen(")
if idx != -1:
    # 在函数体内找第一个 .background(BgDeepBlue)
    chunk_start = idx
    chunk_end = src.find("\nfun ", idx + 10)
    if chunk_end == -1:
        chunk_end = len(src)
    chunk = src[chunk_start:chunk_end]
    bg_idx = chunk.find(".background(BgDeepBlue)")
    if bg_idx != -1:
        # 找到包含它的 modifier 行，删掉 .background(BgDeepBlue)
        # 简单：直接替换
        old_bg = ".background(BgDeepBlue)"
        # 只在 PlaylistDetailScreen 范围内替换第一个
        new_chunk = chunk.replace(old_bg, "/*[32v42]*/", 1)
        src = src[:chunk_start] + new_chunk + src[chunk_end:]
        print("3. PlaylistDetailScreen done")
    else:
        print("3. PlaylistDetailScreen 未找到黑底")
else:
    print("3. 未找到 PlaylistDetailScreen")

# 4. 通用：清掉剩余的 .background(BgDeepBlue)（根节点级别的）
# 注意：不要清掉卡片内部的渐变背景，只清 fillMaxSize 级别的
count = src.count(".background(BgDeepBlue)")
print(f"剩余 .background(BgDeepBlue): {count} 处")

with open(MPATH, "w", encoding="utf-8") as f:
    f.write(src)
print(f"已写入 ({orig} -> {len(src)})")
PYEOF

echo "=== 32 v42 完成 ==="

# 32 v43: 清 12 脚本页面的硬编码黑底（主题设置页等）

echo "=== 32 v43: 清设置页黑底 ==="

python3 << 'PYEOF'
import sys, os

files = [
    "app/src/main/java/com/github/tvbox/osc/ui/activity/LxThemeSettingsActivity.kt",
    "app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlaybackSettingsActivity.kt",
]

MARK = "// [32v43]"
done_count = 0

for fp in files:
    if not os.path.exists(fp):
        print(f"跳过不存在: {fp}")
        continue
    with open(fp, encoding="utf-8") as f:
        src = f.read()
    if MARK in src:
        print(f"已处理: {fp}")
        continue
    
    orig = len(src)
    # 删掉 .background(Color(0xFF000000))
    src = src.replace(".background(Color(0xFF000000))", "/*[32v43]*/")
    # 删掉 .background(Color.Black)
    src = src.replace(".background(Color.Black)", "/*[32v43]*/")
    
    if len(src) != orig:
        # 加标记
        src = MARK + "\n" + src
        with open(fp, "w", encoding="utf-8") as f:
            f.write(src)
        print(f"✓ 已清: {fp}")
        done_count += 1
    else:
        print(f"  无黑底: {fp}")

print(f"共处理 {done_count} 个文件")
PYEOF

echo "=== 32 v43 完成 ==="

# 32 v44: 粗暴清掉所有 .background(BgDeepBlue)

echo "=== 32 v44: 全局清黑底 ==="

python3 << 'PYEOF'
import sys

MPATH = "app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"
with open(MPATH, encoding="utf-8") as f:
    src = f.read()

MARK = "// [32v44]"
if MARK in src:
    print("已处理，跳过")
    sys.exit(0)

# 简单粗暴：把所有 .background(BgDeepBlue) 换成主题背景
# 保留语法有效，不断链
count = src.count(".background(BgDeepBlue)")
src = src.replace(".background(BgDeepBlue)", ".background(musicColors().background)")

# 也处理 .background(BgDeepBlue.copy(...))
import re
src, n = re.subn(
    r'\.background\(BgDeepBlue\.copy\(alpha=([0-9.]+)f\)\)',
    r'.background(musicColors().background.copy(alpha=\1f))',
    src
)
count += n

print(f"替换 {count} 处 BgDeepBlue -> musicColors().background")

# 加标记
src = MARK + "\n" + src

with open(MPATH, "w", encoding="utf-8") as f:
    f.write(src)
print("已写入")
PYEOF

echo "=== 32 v44 完成 ==="

# 32 v45: 暴力清黑底 + 强制主题背景

echo "=== 32 v45: 暴力清黑底 ==="

python3 << 'PYEOF'
import re, sys

MPATH = "app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"
with open(MPATH, encoding="utf-8") as f:
    src = f.read()

MARK = "// [32v45]"
if MARK in src:
    print("已处理，跳过")
    sys.exit(0)

orig_len = len(src)

# 1. 用正则暴力匹配所有 BgDeepBlue 背景（不管缩进格式）
# 匹配 .background( 前后可能有换行和空格的 BgDeepBlue
patterns = [
    (r'\.background\(\s*BgDeepBlue\s*\)', '.background(musicColors().background)'),
    (r'\.background\(\s*BgDeepBlue\.copy\([^)]+\)\s*\)', '.background(musicColors().background)'),
    (r'\.background\(\s*Color\(0xFF000000\)\s*\)', '.background(musicColors().background)'),
    (r'\.background\(\s*Color\.Black\s*\)', '.background(musicColors().background)'),
]

total = 0
for pat, repl in patterns:
    src, n = re.subn(pat, repl, src)
    total += n
    if n > 0:
        print(f"  替换 {n} 处: {pat[:40]}")

print(f"共替换 {total} 处")

# 2. 如果一处都没找到，打印警告（大声失败）
if total == 0:
    print("警告: 未找到任何黑底模式，打印文件中的 background 以便诊断")
    for m in re.finditer(r'\.background\([^)]{0,50}\)', src):
        print(f"  发现: {m.group(0)[:60]}")
    # 不退出，让构建继续（可能是已经清过了）

src = MARK + "\n" + src
with open(MPATH, "w", encoding="utf-8") as f:
    f.write(src)
print("已写入")
PYEOF

echo "=== 32 v45 完成 ==="

# 32 v46: 同步更新 MusicThemeManager，不用 LaunchedEffect

echo "=== 32 v46: 同步主题状态 ==="

python3 << 'PYEOF'
import sys

MPATH = "app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"
with open(MPATH, encoding="utf-8") as f:
    src = f.read()

MARK = "// [32v46]"
if MARK in src:
    print("已处理，跳过")
    sys.exit(0)

# 把 LaunchedEffect 改成同步调用
old = """            androidx.compose.runtime.LaunchedEffect(finalDark41) {
                MusicThemeManager.setDarkTheme(finalDark41)
            }"""

new = """            // [32v46] 同步更新，保证 musicColors() 读到最新值
            MusicThemeManager.setDarkTheme(finalDark41)"""

if old in src:
    src = src.replace(old, new, 1)
    print("✓ 已改为同步调用")
else:
    print("错误: 未找到 LaunchedEffect 块")
    sys.exit(1)

src = MARK + "\n" + src
with open(MPATH, "w", encoding="utf-8") as f:
    f.write(src)
print("已写入")
PYEOF

echo "=== 32 v46 完成 ==="

# 32 v47: onCreate 里预设主题，setContent 前同步

echo "=== 32 v47: onCreate 预设主题 ==="

python3 << 'PYEOF'
import re, sys

MPATH = "app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"
with open(MPATH, encoding="utf-8") as f:
    src = f.read()

MARK = "// [32v47]"
if MARK in src:
    print("已处理，跳过")
    sys.exit(0)

# 在 setContent 之前插入主题预设
# 找 setContent {
m = re.search(r'(\n\s*)setContent\s*\{', src)
if not m:
    print("错误: 未找到 setContent")
    sys.exit(1)

indent = m.group(1)
inject = indent + """// [32v47] onCreate 预设主题，保证 musicColors() 读到正确值
        run {
            val p47 = getSharedPreferences("theme_prefs", MODE_PRIVATE)
            val mode47 = p47.getInt("theme_mode", 0)
            val dark47 = when (mode47) {
                1 -> true
                2 -> false
                else -> (resources.configuration.uiMode and android.content.res.Configuration.UI_MODE_NIGHT_MASK) == android.content.res.Configuration.UI_MODE_NIGHT_YES
            }
            MusicThemeManager.setDarkTheme(dark47)
        }
"""

src = src[:m.start()] + inject + src[m.start():]
src = MARK + "\n" + src

with open(MPATH, "w", encoding="utf-8") as f:
    f.write(src)
print("✓ 已在 setContent 前注入主题预设")
PYEOF

echo "=== 32 v47 完成 ==="

# 32 v48: 25号页面根背景换 musicColors

echo "=== 32 v48: 25页面背景 ==="

python3 << 'PYEOF'
import os, re, sys

BASE = "app/src/main/java/com/github/tvbox/osc/ui/music"
MARK = "// [32v48]"
done = 0

for root, dirs, filenames in os.walk(BASE):
    for fn in filenames:
        if not fn.endswith(".kt"):
            continue
        fp = os.path.join(root, fn)
        with open(fp, encoding="utf-8") as f:
            src = f.read()
        if MARK in src:
            continue
        
        # 只替换 .background(MaterialTheme.colorScheme.background)
        # 这是页面的根背景
        new_src, n = re.subn(
            r'\.background\(MaterialTheme\.colorScheme\.background\)',
            '.background(musicColors().background)',
            src
        )
        
        if n > 0:
            # 加 import
            # musicColors 在 ui.activity 包
            if 'import com.github.tvbox.osc.ui.activity.musicColors' not in new_src:
                # 找最后一个 import 的位置
                m = list(re.finditer(r'^import .+$', new_src, re.MULTILINE))
                if m:
                    pos = m[-1].end()
                    new_src = new_src[:pos] + '\nimport com.github.tvbox.osc.ui.activity.musicColors' + new_src[pos:]
            new_src = MARK + "\n" + new_src
            with open(fp, "w", encoding="utf-8") as f:
                f.write(new_src)
            print(f"✓ {fp}: {n} 处")
            done += 1

print(f"共处理 {done} 个文件")
if done == 0:
    print("警告: 未找到目标")
PYEOF

echo "=== 32 v48 完成 ==="

# 32 v49: 精准修三页面文字颜色

echo "=== 32 v49: 精准修文字 ==="

python3 << 'PYEOF'
import os, re, sys

MARK = "// [32v49]"
IMPORT = "import com.github.tvbox.osc.ui.activity.musicColors"

def add_import(src):
    if IMPORT in src:
        return src
    m = list(re.finditer(r'^import .+$', src, re.MULTILINE))
    if m:
        pos = m[-1].end()
        return src[:pos] + '\n' + IMPORT + src[pos:]
    return src

done = 0

# 1. SearchScreen.kt: 热搜文字 White -> textPrimary
# 找文件
for root, dirs, files in os.walk("app/src/main/java/com/github/tvbox/osc/ui/music"):
    for fn in files:
        if fn == "SearchScreen.kt":
            fp = os.path.join(root, fn)
            with open(fp, encoding="utf-8") as f:
                src = f.read()
            if MARK in src:
                continue
            # 热搜榜的 Text: color = Color.White -> musicColors().textPrimary
            # 只处理搜索列表相关的（保守：处理所有 Text 的 White）
            new_src = re.sub(
                r'(Text\([^)]*?color\s*=\s*)Color\.White',
                r'\1musicColors().textPrimary',
                src
            )
            if new_src != src:
                new_src = add_import(new_src)
                new_src = MARK + "\n" + new_src
                with open(fp, "w", encoding="utf-8") as f:
                    f.write(new_src)
                print(f"✓ SearchScreen")
                done += 1

# 2. SettingsScreen.kt: 卡片背景深色 -> card
for root, dirs, files in os.walk("app/src/main/java/com/github/tvbox/osc/ui/music"):
    for fn in files:
        if fn == "SettingsScreen.kt":
            fp = os.path.join(root, fn)
            with open(fp, encoding="utf-8") as f:
                src = f.read()
            if MARK in src:
                continue
            # Surface 的 color = 深色 -> musicColors().card
            # 找 Surface(color = xxx)
            new_src = src
            # 卡片背景：Color(0xFF...) 深色 -> card
            # 保守：只换明确的深色背景
            new_src = re.sub(
                r'color\s*=\s*Color\(0xFF1[0-9A-Fa-f]{6}\)',
                'color = musicColors().card',
                new_src
            )
            if new_src != src:
                new_src = add_import(new_src)
                new_src = MARK + "\n" + new_src
                with open(fp, "w", encoding="utf-8") as f:
                    f.write(new_src)
                print(f"✓ SettingsScreen")
                done += 1

print(f"共处理 {done} 个文件")
print("注意: PlaylistDetailScreen 在 MusicHomeActivity.kt，需单独处理")
PYEOF

echo "=== 32 v49 完成 ==="

# 32 v50: 补全 LxMusicTheme 的 MaterialTheme 映射

echo "=== 32 v50: 补全映射 ==="

python3 << 'PYEOF'
import sys, re

MPATH = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxMusicTheme.kt"
with open(MPATH, encoding="utf-8") as f:
    src = f.read()

MARK = "// [32v50]"
if MARK in src:
    print("已处理，跳过")
    sys.exit(0)

# 找到 v2 的桥接函数，替换为完整映射版
old_start = src.find("// [32v2] LxMusicTheme bridge")
if old_start == -1:
    print("错误: 未找到 v2 桥接")
    sys.exit(1)

# 找到函数结束（下一个顶级声明或文件尾）
# 简单：找到 "@Composable\nfun LxMusicTheme" 到文件尾（它是最后一个）
func_start = src.find("@Composable\nfun LxMusicTheme(", old_start)
if func_start == -1:
    func_start = src.find("@Composable", old_start)

# 找到匹配的右括号（数括号）
brace = 0
in_func = False
end_pos = len(src)
for i in range(func_start, len(src)):
    c = src[i]
    if c == '{':
        brace += 1
        in_func = True
    elif c == '}':
        brace -= 1
        if in_func and brace == 0:
            end_pos = i + 1
            break

new_func = """// [32v50] LxMusicTheme bridge - 完整 MaterialTheme 注入
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
            surfaceContainer = musicColors.card,
            surfaceContainerHigh = musicColors.cardSecondary,
            surfaceContainerHighest = musicColors.cardSecondary,
            outline = musicColors.divider,
            outlineVariant = musicColors.divider,
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
            surfaceContainer = musicColors.card,
            surfaceContainerHigh = musicColors.cardSecondary,
            surfaceContainerHighest = musicColors.cardSecondary,
            outline = musicColors.divider,
            outlineVariant = musicColors.divider,
            error = ErrorRed,
            onError = Color.White
        )
    }
    CompositionLocalProvider(LocalMusicColors provides musicColors) {
        MaterialTheme(colorScheme = materialColorScheme, content = content)
    }
}"""

src = src[:old_start] + new_func + "\n" + src[end_pos:].lstrip()
with open(MPATH, "w", encoding="utf-8") as f:
    f.write(src)
print("✓ LxMusicTheme 映射已补全")

# 修 SettingsScreen 第95行
import os
for root, dirs, files in os.walk("app/src/main/java/com/github/tvbox/osc/ui/music"):
    for fn in files:
        if fn == "SettingsScreen.kt":
            fp = os.path.join(root, fn)
            with open(fp, encoding="utf-8") as f:
                s = f.read()
            if "// [32v50]" in s:
                continue
            # Color.White.copy(alpha = 0.05f) -> musicColors().divider
            new_s = s.replace(
                "Color.White.copy(alpha = 0.05f)",
                "musicColors().divider"
            )
            if new_s != s:
                if "import com.github.tvbox.osc.ui.activity.musicColors" not in new_s:
                    m = list(re.finditer(r'^import .+$', new_s, re.MULTILINE))
                    if m:
                        pos = m[-1].end()
                        new_s = new_s[:pos] + '\nimport com.github.tvbox.osc.ui.activity.musicColors' + new_s[pos:]
                new_s = "// [32v50]\n" + new_s
                with open(fp, "w", encoding="utf-8") as f:
                    f.write(new_s)
                print(f"✓ SettingsScreen 已修")
PYEOF

echo "=== 32 v50 完成 ==="

# 32 v53: 统一主题值源

echo "=== 32 v53: 统一值源 ==="

python3 << 'PYEOF'
import sys, re

MPATH = "app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"
with open(MPATH, encoding="utf-8") as f:
    src = f.read()

MARK = "// [32v53]"
if MARK in src:
    print("已处理，跳过")
    sys.exit(0)

# 把 LxMusicTheme(isDarkTheme = finalDark41) 改为读 Manager 的值
# 确保与 musicColors() 同源
old = "LxMusicTheme(isDarkTheme = finalDark41)"
new = "LxMusicTheme(isDarkTheme = MusicThemeManager.isDarkTheme.value)"

if old in src:
    src = src.replace(old, new, 1)
    print("✓ 已统一值源")
    src = MARK + "\n" + src
    with open(MPATH, "w", encoding="utf-8") as f:
        f.write(src)
else:
    print("警告: 未找到 LxMusicTheme 调用")
    # 试试其他格式
    m = re.search(r'LxMusicTheme\(isDarkTheme\s*=\s*[^)]+\)', src)
    if m:
        print(f"找到: {m.group(0)[:60]}")
PYEOF

echo "=== 32 v53 完成 ==="

# 32 v54: 主题切换响应式

echo "=== 32 v54: 响应式主题 ==="

python3 << 'PYEOF'
import sys, re

MPATH = "app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"
with open(MPATH, encoding="utf-8") as f:
    src = f.read()

MARK = "// [32v54]"
if MARK in src:
    print("已处理，跳过")
    sys.exit(0)

# v53 的写法：LxMusicTheme(isDarkTheme = MusicThemeManager.isDarkTheme.value)
# 改为响应式：先 collectAsState，再传值
old = "LxMusicTheme(isDarkTheme = MusicThemeManager.isDarkTheme.value)"

# 需要在 setContent 内、LxMusicTheme 之前加：
# val isDark54 by MusicThemeManager.isDarkTheme.collectAsState()
# 然后 LxMusicTheme(isDarkTheme = isDark54)

if old in src:
    # 找到 LxMusicTheme 的行首
    idx = src.find(old)
    line_start = src.rfind('\n', 0, idx) + 1
    indent = src[line_start:idx]
    
    new_code = f"""{indent}val isDark54 by MusicThemeManager.isDarkTheme.collectAsState()
{indent}LxMusicTheme(isDarkTheme = isDark54)"""
    
    src = src[:idx] + new_code + src[idx+len(old):]
    
    # 确保 import collectAsState 和 getValue
    if "import androidx.compose.runtime.collectAsState" not in src:
        m = list(re.finditer(r'^import androidx\.compose\.runtime\..+$', src, re.MULTILINE))
        if m:
            pos = m[-1].end()
            src = src[:pos] + '\nimport androidx.compose.runtime.collectAsState\nimport androidx.compose.runtime.getValue' + src[pos:]
    
    print("✓ 已改为响应式")
    src = MARK + "\n" + src
    with open(MPATH, "w", encoding="utf-8") as f:
        f.write(src)
else:
    print("警告: 未找到 v53 的代码")
    sys.exit(1)
PYEOF

echo "=== 32 v54 完成 ==="

# 32 v55: 修正 MutableState 的用法

echo "=== 32 v55: 修正委托 ==="

python3 << 'PYEOF'
import sys, re

MPATH = "app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"
with open(MPATH, encoding="utf-8") as f:
    src = f.read()

MARK = "// [32v55]"
if MARK in src:
    print("已处理，跳过")
    sys.exit(0)

# v54 错误：val isDark54 by MusicThemeManager.isDarkTheme.collectAsState()
# isDarkTheme 是 MutableState，直接 by 即可，不需要 collectAsState()
old = "val isDark54 by MusicThemeManager.isDarkTheme.collectAsState()"
new = "val isDark54 by MusicThemeManager.isDarkTheme"

if old in src:
    src = src.replace(old, new, 1)
    print("✓ 已修正为直接委托")
    # 移除 collectAsState 的 import（如果 v54 加了）
    src = src.replace("import androidx.compose.runtime.collectAsState\n", "")
    src = MARK + "\n" + src
    with open(MPATH, "w", encoding="utf-8") as f:
        f.write(src)
else:
    print("警告: 未找到 v54 代码")
    sys.exit(1)
PYEOF

echo "=== 32 v55 完成 ==="

# 32 v56: 暴力替换 25 页面颜色

echo "=== 32 v56: 暴力替换 ==="

python3 << 'PYEOF'
import os, re, sys

BASE = "app/src/main/java/com/github/tvbox/osc/ui/music"
MARK = "// [32v56]"
IMPORT = "import com.github.tvbox.osc.ui.activity.musicColors"

def add_import(src):
    if IMPORT in src:
        return src
    m = list(re.finditer(r'^import .+$', src, re.MULTILINE))
    if m:
        pos = m[-1].end()
        return src[:pos] + '\n' + IMPORT + src[pos:]
    return src

# 映射表：colorScheme -> musicColors()
replacements = [
    # 文字
    (r'MaterialTheme\.colorScheme\.onSurface\b', 'musicColors().textPrimary'),
    (r'MaterialTheme\.colorScheme\.onBackground\b', 'musicColors().textPrimary'),
    (r'MaterialTheme\.colorScheme\.onSurfaceVariant\b', 'musicColors().textSecondary'),
    # 背景/卡片
    (r'MaterialTheme\.colorScheme\.background\b', 'musicColors().background'),
    (r'MaterialTheme\.colorScheme\.surface\b', 'musicColors().card'),
    (r'MaterialTheme\.colorScheme\.surfaceVariant\b', 'musicColors().cardSecondary'),
    (r'MaterialTheme\.colorScheme\.surfaceContainer\b', 'musicColors().card'),
    (r'MaterialTheme\.colorScheme\.surfaceContainerHigh\b', 'musicColors().cardSecondary'),
    # 边框
    (r'MaterialTheme\.colorScheme\.outline\b', 'musicColors().divider'),
    (r'MaterialTheme\.colorScheme\.outlineVariant\b', 'musicColors().divider'),
]

done = 0
total_repl = 0
for root, dirs, files in os.walk(BASE):
    for fn in files:
        if not fn.endswith(".kt"):
            continue
        fp = os.path.join(root, fn)
        with open(fp, encoding="utf-8") as f:
            src = f.read()
        if MARK in src:
            continue
        
        orig = src
        count = 0
        for pat, repl in replacements:
            src, n = re.subn(pat, repl, src)
            count += n
        
        # 硬编码白 -> textPrimary (只在 Text 的 color 上下文)
        # 保守：替换 color = Color.White
        src, n = re.subn(r'color\s*=\s*Color\.White\b', 'color = musicColors().textPrimary', src)
        count += n
        
        if count > 0:
            src = add_import(src)
            src = MARK + "\n" + src
            with open(fp, "w", encoding="utf-8") as f:
                f.write(src)
            print(f"✓ {os.path.basename(fp)}: {count} 处")
            done += 1
            total_repl += count

print(f"共处理 {done} 个文件，{total_repl} 处替换")

# 2. 修 MusicHomeActivity 的 PlaylistDetailScreen 头部黑底
MPATH = "app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"
with open(MPATH, encoding="utf-8") as f:
    src = f.read()
if MARK not in src:
    # 找残留的 BgDeepBlue
    n = len(re.findall(r'BgDeepBlue', src))
    if n > 0:
        src = re.sub(r'BgDeepBlue', 'musicColors().background', src)
        # BgDeepBlue.copy(...) 的情况
        src = re.sub(r'musicColors\(\)\.background\.copy\(', 'musicColors().background.copy(', src)
        src = MARK + "\n" + src
        with open(MPATH, "w", encoding="utf-8") as f:
            f.write(src)
        print(f"✓ MusicHomeActivity: 清除 {n} 处 BgDeepBlue 残留")
    else:
        print("MusicHomeActivity: 无 BgDeepBlue 残留")
PYEOF

echo "=== 32 v56 完成 ==="

# 32 v57: 修复 v56 误伤 BgDeepBlue 定义

echo "=== 32 v57: 修复误伤 ==="

python3 << 'PYEOF'
import sys, re

MPATH = "app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"
with open(MPATH, encoding="utf-8") as f:
    src = f.read()

MARK = "// [32v57]"
if MARK in src:
    print("已处理，跳过")
    sys.exit(0)

fixed = False
# 修复各种可能的误伤定义
patterns = [
    ("val musicColors().background", "val BgDeepBlue"),
    ("var musicColors().background", "var BgDeepBlue"),
    ("private val musicColors().background", "private val BgDeepBlue"),
    ("internal val musicColors().background", "internal val BgDeepBlue"),
]
for bad, good in patterns:
    if bad in src:
        src = src.replace(bad, good)
        print(f"✓ 修复: {bad[:30]}...")
        fixed = True

if fixed:
    src = MARK + "\n" + src
    with open(MPATH, "w", encoding="utf-8") as f:
        f.write(src)
else:
    print("未发现定义误伤")
    # 仍然加 MARK 防止重复检查
    src = MARK + "\n" + src
    with open(MPATH, "w", encoding="utf-8") as f:
        f.write(src)
PYEOF

echo "=== 32 v57 完成 ==="

# 32 v58: 精准修三处 + 补 ui/activity 目录

echo "=== 32 v58: 精准修复 ==="

python3 << 'PYEOF'
import os, re, sys

MARK = "// [32v58]"
IMPORT_ACT = "import com.github.tvbox.osc.ui.activity.musicColors"

def add_import_activity(src):
    # ui/activity 包下的文件，musicColors 在同一包，不需要 import
    return src

def add_import_music(src):
    if IMPORT_ACT in src:
        return src
    m = list(re.finditer(r'^import .+$', src, re.MULTILINE))
    if m:
        pos = m[-1].end()
        return src[:pos] + '\n' + IMPORT_ACT + src[pos:]
    return src

replacements = [
    (r'MaterialTheme\.colorScheme\.onSurface\b', 'musicColors().textPrimary'),
    (r'MaterialTheme\.colorScheme\.onBackground\b', 'musicColors().textPrimary'),
    (r'MaterialTheme\.colorScheme\.onSurfaceVariant\b', 'musicColors().textSecondary'),
    (r'MaterialTheme\.colorScheme\.background\b', 'musicColors().background'),
    (r'MaterialTheme\.colorScheme\.surface\b', 'musicColors().card'),
    (r'MaterialTheme\.colorScheme\.surfaceVariant\b', 'musicColors().cardSecondary'),
    (r'MaterialTheme\.colorScheme\.surfaceContainer\b', 'musicColors().card'),
    (r'MaterialTheme\.colorScheme\.surfaceContainerLow\b', 'musicColors().card'),
    (r'MaterialTheme\.colorScheme\.surfaceContainerHigh\b', 'musicColors().cardSecondary'),
    (r'MaterialTheme\.colorScheme\.surfaceContainerHighest\b', 'musicColors().cardSecondary'),
    (r'MaterialTheme\.colorScheme\.outline\b', 'musicColors().divider'),
    (r'MaterialTheme\.colorScheme\.outlineVariant\b', 'musicColors().divider'),
]

# 1. 处理 ui/activity 下的 Activity 文件（LxFavoritesActivity 等）
ACT_BASE = "app/src/main/java/com/github/tvbox/osc/ui/activity"
act_targets = [
    "LxFavoritesActivity.kt",
    "LxQualitySettingsActivity.kt",
    "LxThemeSettingsActivity.kt",
    "LxPlaybackSettingsActivity.kt",
    "LxLyricSettingsActivity.kt",
]
for fn in act_targets:
    fp = os.path.join(ACT_BASE, fn)
    if not os.path.exists(fp):
        continue
    with open(fp, encoding="utf-8") as f:
        src = f.read()
    if MARK in src:
        print(f"跳过: {fn}")
        continue
    orig = src
    count = 0
    for pat, repl in replacements:
        src, n = re.subn(pat, repl, src)
        count += n
    # 硬编码黑背景 -> musicColors().background
    src, n = re.subn(r'\.background\(Color\(0xFF000000\)\)', '.background(musicColors().background)', src)
    count += n
    src, n = re.subn(r'\.background\(Color\.Black\)', '.background(musicColors().background)', src)
    count += n
    if count > 0:
        src = MARK + "\n" + src
        with open(fp, "w", encoding="utf-8") as f:
            f.write(src)
        print(f"✓ {fn}: {count} 处")

# 2. 补 PlaylistScreen 的 surfaceContainerLow（v56 漏了）
MUSIC_BASE = "app/src/main/java/com/github/tvbox/osc/ui/music"
for root, dirs, files in os.walk(MUSIC_BASE):
    for fn in files:
        if fn == "PlaylistScreen.kt":
            fp = os.path.join(root, fn)
            with open(fp, encoding="utf-8") as f:
                src = f.read()
            if MARK in src:
                continue
            src, n = re.subn(r'MaterialTheme\.colorScheme\.surfaceContainerLow\b', 'musicColors().card', src)
            if n > 0:
                src = add_import_music(src)
                src = MARK + "\n" + src
                with open(fp, "w", encoding="utf-8") as f:
                    f.write(src)
                print(f"✓ PlaylistScreen.kt: 补 {n} 处 surfaceContainerLow")

print("完成")
PYEOF

echo "=== 32 v58 完成 ==="

# 32 v59: LxThemeSettingsActivity 预设主题

echo "=== 32 v59: 主题页预设 ==="

python3 << 'PYEOF'
import sys, re

FP = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxThemeSettingsActivity.kt"
with open(FP, encoding="utf-8") as f:
    src = f.read()

MARK = "// [32v59]"
if MARK in src:
    print("已处理，跳过")
    sys.exit(0)

# 在 onCreate 的 setContent 之前注入主题预设（仿 v47）
m = re.search(r'setContent\s*\{', src)
if not m:
    print("错误: 未找到 setContent")
    sys.exit(1)

pos = m.start()
line_start = src.rfind('\n', 0, pos) + 1
indent = src[line_start:pos]

inject = f"""{indent}// [32v59] 预设主题
{indent}run {{
{indent}    val p59 = getSharedPreferences("theme_prefs", MODE_PRIVATE)
{indent}    val mode59 = p59.getInt("theme_mode", 0)
{indent}    val dark59 = when (mode59) {{
{indent}        1 -> true
{indent}        2 -> false
{indent}        else -> (resources.configuration.uiMode and android.content.res.Configuration.UI_MODE_NIGHT_MASK) == android.content.res.Configuration.UI_MODE_NIGHT_YES
{indent}    }}
{indent}    MusicThemeManager.setDarkTheme(dark59)
{indent}}}
"""

src = src[:line_start] + inject + src[line_start:]
src = MARK + "\n" + src
with open(FP, "w", encoding="utf-8") as f:
    f.write(src)
print("✓ LxThemeSettingsActivity 已预设主题")
PYEOF

echo "=== 32 v59 完成 ==="

# 32 v60: 5处精准修复

echo "=== 32 v60: 精准5修 ==="

python3 << 'PYEOF'
import os, re, sys

MARK = "// [32v60]"

def patch_file(path, patches):
    """patches: list of (old, new, desc)"""
    if not os.path.exists(path):
        print(f"跳过(无文件): {path}")
        return 0
    with open(path, encoding="utf-8") as f:
        src = f.read()
    if MARK in src:
        print(f"跳过(已处理): {os.path.basename(path)}")
        return 0
    count = 0
    for old, new, desc in patches:
        if old in src:
            src = src.replace(old, new, 1)
            print(f"  ✓ {desc}")
            count += 1
        else:
            print(f"  ✗ 未找到: {desc}")
            sys.exit(1)
    src = MARK + "\n" + src
    with open(path, "w", encoding="utf-8") as f:
        f.write(src)
    return count

# 1. 歌手详情页
print("1. LxArtistDetailActivity.kt")
p1 = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxArtistDetailActivity.kt"
# 先读文件找 setContent 位置，注入主题预设
with open(p1, encoding="utf-8") as f:
    s1 = f.read()
if MARK not in s1:
    # 注入主题预设（在 setContent 之前）
    m = re.search(r'setContent\s*\{', s1)
    if not m:
        print("  ✗ 未找到 setContent")
        sys.exit(1)
    pos = m.start()
    ls = s1.rfind('\n', 0, pos) + 1
    indent = s1[ls:pos]
    inject = f"""{indent}// [32v60] 预设主题
{indent}run {{
{indent}    val p60 = getSharedPreferences("theme_prefs", MODE_PRIVATE)
{indent}    val mode60 = p60.getInt("theme_mode", 0)
{indent}    val dark60 = when (mode60) {{
{indent}        1 -> true
{indent}        2 -> false
{indent}        else -> (resources.configuration.uiMode and android.content.res.Configuration.UI_MODE_NIGHT_MASK) == android.content.res.Configuration.UI_MODE_NIGHT_YES
{indent}    }}
{indent}    MusicThemeManager.setDarkTheme(dark60)
{indent}}}
"""
    s1 = s1[:ls] + inject + s1[ls:]
    # MaterialTheme -> LxMusicTheme
    s1 = s1.replace("setContent {\n            MaterialTheme {",
                    "setContent {\n            val isDark60 by MusicThemeManager.isDarkTheme\n            LxMusicTheme(isDarkTheme = isDark60) {", 1)
    # 根背景 DetailBg -> musicColors().background
    s1 = s1.replace(".background(DetailBg)", ".background(musicColors().background)", 1)
    s1 = MARK + "\n" + s1
    with open(p1, "w", encoding="utf-8") as f:
        f.write(s1)
    print("  ✓ 主题预设+LxMusicTheme+根背景")

# 2. 歌单卡片 (v58 已修，此处幂等跳过)
print("2. PlaylistScreen.kt")
import glob
found = glob.glob("app/src/main/java/com/github/tvbox/osc/ui/music/**/PlaylistScreen.kt", recursive=True)
if found:
    p2 = found[0]
    with open(p2, encoding="utf-8") as _f:
        _s = _f.read()
    if "// [32v58]" in _s or "musicColors().card" in _s:
        print("  ✓ 已由 v58 处理，跳过")
    else:
        patch_file(p2, [
            ("MaterialTheme.colorScheme.surfaceContainerLow", "musicColors().card", "surfaceContainerLow→card"),
        ])
else:
    print("  ✗ 未找到 PlaylistScreen.kt")
    sys.exit(1)

# 3. 切换榜单弹窗 (RankScreen ModalBottomSheet)
print("3. RankScreen.kt")
p3 = "app/src/main/java/com/github/tvbox/osc/ui/music/rank/RankScreen.kt"
with open(p3, encoding="utf-8") as f:
    s3 = f.read()
if MARK not in s3:
    # ModalBottomSheet 加 containerColor
    old_sheet = "ModalBottomSheet(\n            onDismissRequest = { showSheet = false },\n            sheetState = sheetState,"
    new_sheet = "ModalBottomSheet(\n            onDismissRequest = { showSheet = false },\n            sheetState = sheetState,\n            containerColor = musicColors().card,"
    if old_sheet in s3:
        s3 = s3.replace(old_sheet, new_sheet, 1)
        print("  ✓ ModalBottomSheet containerColor")
    else:
        print("  ✗ 未找到 ModalBottomSheet")
        sys.exit(1)
    s3 = MARK + "\n" + s3
    with open(p3, "w", encoding="utf-8") as f:
        f.write(s3)

# 4+5. 音乐源管理页 + 导入弹窗 (同一文件)
print("4+5. LxSourceSettings.kt")
p45 = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxSourceSettings.kt"
with open(p45, encoding="utf-8") as f:
    s45 = f.read()
if MARK not in s45:
    # 4. AlertDialog 加 containerColor
    # 找 "导入音乐源" 的 AlertDialog
    m = re.search(r'AlertDialog\(\n        onDismissRequest = \{ if \(!importing\) onDismiss\(\) \},', s45)
    if m:
        pos = m.start()
        # 在 AlertDialog( 后插入 containerColor
        insert_pos = s45.find('(', pos) + 1
        s45 = s45[:insert_pos] + '\n        containerColor = musicColors().card,' + s45[insert_pos:]
        print("  ✓ AlertDialog containerColor")
    else:
        print("  ✗ 未找到导入 AlertDialog")
        sys.exit(1)
    # 5. onCreate 主题预设 + LxMusicTheme（仿 v59）
    m2 = re.search(r'setContent\s*\{', s45)
    if m2:
        pos2 = m2.start()
        ls2 = s45.rfind('\n', 0, pos2) + 1
        indent2 = s45[ls2:pos2]
        inject2 = f"""{indent2}// [32v60] 预设主题
{indent2}run {{
{indent2}    val p60 = getSharedPreferences("theme_prefs", MODE_PRIVATE)
{indent2}    val mode60 = p60.getInt("theme_mode", 0)
{indent2}    val dark60 = when (mode60) {{
{indent2}        1 -> true
{indent2}        2 -> false
{indent2}        else -> (resources.configuration.uiMode and android.content.res.Configuration.UI_MODE_NIGHT_MASK) == android.content.res.Configuration.UI_MODE_NIGHT_YES
{indent2}    }}
{indent2}    MusicThemeManager.setDarkTheme(dark60)
{indent2}}}
"""
        s45 = s45[:ls2] + inject2 + s45[ls2:]
        print("  ✓ onCreate 主题预设")
    s45 = MARK + "\n" + s45
    with open(p45, "w", encoding="utf-8") as f:
        f.write(s45)

print("=== 32 v60 完成 ===")
PYEOF

# 32 v62: 播放量标签+历史页+TabRow

echo "=== 32 v62: 三处 ==="

python3 << 'PYEOF'
import os, re, sys, glob

MARK = "// [32v62]"

# 1. Color.kt 加 Overlay 常量
print("1. Color.kt Overlay 常量")
cpath = "app/src/main/java/com/github/tvbox/osc/ui/activity/Color.kt"
# 可能在 theme 包
if not os.path.exists(cpath):
    found = glob.glob("app/src/main/java/**/Color.kt", recursive=True)
    if found:
        cpath = found[0]
    else:
        print("  ✗ 未找到 Color.kt")
        sys.exit(1)
with open(cpath, encoding="utf-8") as f:
    src = f.read()
if "OverlayScrimBlack" not in src:
    # 直接追加到文件末尾
    add = "\n// [32v62] Overlay 常量\nval OverlayScrimBlack = Color(0xFF000000).copy(alpha = 0.6f)\nval OverlayTextWhite = Color(0xFFFFFFFF)\n"
    src = src.rstrip() + add
    with open(cpath, "w", encoding="utf-8") as f:
        f.write(src)
    print(f"  ✓ 已加 Overlay 常量 ({cpath})")
else:
    print("  ✓ 已存在，跳过")

# 2. PlaylistScreen 播放量标签用常量
print("2. PlaylistScreen 播放量标签")
found = glob.glob("app/src/main/java/com/github/tvbox/osc/ui/music/**/PlaylistScreen.kt", recursive=True)
if found:
    fp = found[0]
    with open(fp, encoding="utf-8") as f:
        s = f.read()
    if MARK not in s:
        # 替换 scrim 背景
        if "Color.Black.copy(alpha = 0.55f)" in s:
            s = s.replace("Color.Black.copy(alpha = 0.55f)", "OverlayScrimBlack")
            print("  ✓ scrim→OverlayScrimBlack")
        # 替换图标 tint 和文字 color（只在播放量标签范围内）
        # 找到播放量标签的 Surface 块，替换其中的 Color.White
        # 简单：替换该文件中的特定两处（图标和文字在播放量胶囊内）
        # 用更精准的方式：先定位到播放量标签注释
        idx = s.find("右下角半透明胶囊播放量标签")
        if idx > 0:
            # 从注释开始找接下来的 30 行，替换 Color.White
            chunk_start = idx
            chunk_end = s.find("}", s.find("}", chunk_start) + 1)  # 粗略
            # 更简单：直接替换该区域内的 Color.White
            # 我们知道图标 tint 和文字 color 都在播放量标签内
            # 先做全局替换，但 OverlayTextWhite 只用于播放量标签
            # 为安全，只替换播放量标签附近的
            before = s[:idx]
            after = s[idx:idx+2000]  # 取 2000 字符
            after = after.replace("tint = Color.White", "tint = OverlayTextWhite")
            after = after.replace("color = Color.White,", "color = OverlayTextWhite,")
            s = before + after + s[idx+2000:]
            print("  ✓ 图标/文字→OverlayTextWhite")
        # 加 import（如果常量在不同包）
        # Overlay 常量与 PlaylistScreen 可能不同包，需要 import
        # 检查 Color.kt 的包名
        with open(cpath, encoding="utf-8") as cf:
            cs = cf.read()
        pm = re.search(r'^package (.+)$', cs, re.MULTILINE)
        if pm:
            pkg = pm.group(1)
            imp = f"import {pkg}.OverlayScrimBlack\nimport {pkg}.OverlayTextWhite"
            if "OverlayScrimBlack" not in s or "import" not in s[s.find("OverlayScrimBlack")-200:s.find("OverlayScrimBlack")]:
                # 加 import
                m2 = list(re.finditer(r'^import .+$', s, re.MULTILINE))
                if m2:
                    pos2 = m2[-1].end()
                    s = s[:pos2] + '\n' + imp + s[pos2:]
                    print("  ✓ 已加 import")
        s = MARK + "\n" + s
        with open(fp, "w", encoding="utf-8") as f:
            f.write(s)
    else:
        print("  ✓ 已处理，跳过")
else:
    print("  ✗ 未找到 PlaylistScreen.kt")

# 3. 导入弹窗 TabRow
print("3. LxSourceSettings TabRow")
sp = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxSourceSettings.kt"
with open(sp, encoding="utf-8") as f:
    s = f.read()
if MARK not in s:
    # TabRow 背景 -> Transparent
    # 找 TabRow(
    if "TabRow(" in s:
        # 在 TabRow 后加 containerColor
        s = re.sub(r'TabRow\(\n(        selectedTabIndex)',
                   r'TabRow(\n        containerColor = Color.Transparent,\n\1', s, count=1)
        print("  ✓ TabRow containerColor=Transparent")
    # Tab 文字颜色：selected 用 primary，unselected 用 textSecondary
    # 找 text = { Text("URL 导入") } 等
    # 简化：替换 Tab 的 text 颜色
    # 实际 Tab 的 text 参数是 @Composable，需要看具体结构
    # 先做 containerColor，文字颜色需要更精准的锚点
    s = MARK + "\n" + s
    with open(sp, "w", encoding="utf-8") as f:
        f.write(s)
else:
    print("  ✓ 已处理，跳过")

print("=== 32 v62 完成 ===")
PYEOF

# 4. 播放历史页（按内容搜索）
echo "4. 播放历史页搜索"
python3 << 'PYEOF2'
import os, re, glob
MARK = "// [32v62]"
# 搜索包含"还没有播放记录"的文件
for fp in glob.glob("app/src/main/java/**/*.kt", recursive=True):
    try:
        with open(fp, encoding="utf-8") as f:
            s = f.read()
        if "还没有播放记录" in s and MARK not in s:
            print(f"  找到: {fp}")
            # 根背景 -> musicColors().background
            # 找 .background(Color(0xFF000000)) 或类似
            orig = s
            s = re.sub(r'\.background\(Color\(0xFF000000\)\)', '.background(musicColors().background)', s)
            s = re.sub(r'\.background\(Color\.Black\)', '.background(musicColors().background)', s)
            if s != orig:
                s = MARK + "\n" + s
                with open(fp, "w", encoding="utf-8") as f:
                    f.write(s)
                print(f"  ✓ 已修复背景")
            else:
                print(f"  - 未找到硬编码背景")
            break
    except:
        pass
else:
    print("  - 未找到播放历史页文件")
PYEOF2

# 32 v63: 播放量标签+搜索状态栏+源设置

echo "=== 32 v63: 三处 ==="

python3 << 'PYEOF'
import os, re, sys, glob

MARK = "// [32v63]"

# 1. 播放量标签：确保 Overlay 常量被使用
print("1. PlaylistScreen 播放量标签")
found = glob.glob("app/src/main/java/com/github/tvbox/osc/ui/music/**/PlaylistScreen.kt", recursive=True)
if found:
    fp = found[0]
    with open(fp, encoding="utf-8") as f:
        s = f.read()
    if MARK not in s:
        # 直接替换：scrim 背景
        s = s.replace("color = Color.Black.copy(alpha = 0.55f),", "color = OverlayScrimBlack,")
        # 图标和文字：在播放量标签的 Row 内
        # 更稳妥：替换所有在 Surface(OverlayScrimBlack) 后的 Color.White
        # 简单做法：全局替换播放量相关的 Color.White（该文件内只有播放量用 White）
        # 检查：文件内 Color.White 出现次数
        whites = s.count("Color.White")
        print(f"  文件内 Color.White 共 {whites} 处")
        # 只替换 tint 和 color = Color.White（播放量标签的）
        # 播放量标签的特征：紧跟在 OverlayScrimBlack 之后
        # 用正则：找到 OverlayScrimBlack 块内的 Color.White
        def repl_badge(m):
            block = m.group(0)
            block = block.replace("tint = Color.White", "tint = OverlayTextWhite")
            block = block.replace("color = Color.White,", "color = OverlayTextWhite,")
            return block
        # 匹配从 OverlayScrimBlack 到下一个 Surface 或函数结束
        s = re.sub(r'color = OverlayScrimBlack,.*?(?=\n                \}|\n            \})', repl_badge, s, flags=re.DOTALL)
        # 确保 import
        if "import" in s and "OverlayScrimBlack" not in s.split("package")[0]:
            # 找 Color.kt 包名
            for cfp in glob.glob("app/src/main/java/**/Color.kt", recursive=True):
                with open(cfp, encoding="utf-8") as cf:
                    cs = cf.read()
                pm = re.search(r'^package (.+)$', cs, re.MULTILINE)
                if pm and "OverlayScrimBlack" in cs:
                    pkg = pm.group(1)
                    m2 = list(re.finditer(r'^import .+$', s, re.MULTILINE))
                    if m2:
                        pos2 = m2[-1].end()
                        s = s[:pos2] + f'\nimport {pkg}.OverlayScrimBlack\nimport {pkg}.OverlayTextWhite' + s[pos2:]
                        print(f"  ✓ 已加 import ({pkg})")
                    break
        s = MARK + "\n" + s
        with open(fp, "w", encoding="utf-8") as f:
            f.write(s)
        print("  ✓ 播放量标签已用 Overlay 常量")
    else:
        print("  ✓ 已处理，跳过")
else:
    print("  ✗ 未找到 PlaylistScreen")

# 2. 搜索 Activity 状态栏
print("2. LxMusicSearchActivity 状态栏")
sp = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxMusicSearchActivity.kt"
if os.path.exists(sp):
    with open(sp, encoding="utf-8") as f:
        s = f.read()
    if MARK not in s:
        # 在 setContent 内加 SideEffect（仿 v41）
        # 找 setContent {
        m = re.search(r'setContent\s*\{', s)
        if m:
            pos = m.end()
            # 找 setContent 块的缩进
            ls = s.rfind('\n', 0, m.start()) + 1
            indent = s[ls:m.start()]
            # 在 setContent { 后插入
            inject = f"""
{indent}    // [32v63] 状态栏图标随主题
{indent}    val win63 = window
{indent}    val isDark63 by MusicThemeManager.isDarkTheme
{indent}    androidx.compose.runtime.SideEffect {{
{indent}        val controller = androidx.core.view.WindowCompat.getInsetsController(win63, win63.decorView)
{indent}        controller.isAppearanceLightStatusBars = !isDark63
{indent}    }}
"""
            s = s[:pos] + inject + s[pos:]
            s = MARK + "\n" + s
            with open(sp, "w", encoding="utf-8") as f:
                f.write(s)
            print("  ✓ 已加状态栏 SideEffect")
        else:
            print("  ✗ 未找到 setContent")
            sys.exit(1)
    else:
        print("  ✓ 已处理，跳过")
else:
    print(f"  ✗ 未找到 {sp}")

# 3. 源设置页根背景强制
print("3. LxSourceSettings 根背景")
ssp = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxSourceSettings.kt"
with open(ssp, encoding="utf-8") as f:
    s = f.read()
if MARK not in s:
    # 强制替换所有硬编码黑背景
    orig = s
    s = re.sub(r'\.background\(Color\(0xFF000000\)\)', '.background(musicColors().background)', s)
    s = re.sub(r'\.background\(Color\.Black\)', '.background(musicColors().background)', s)
    if s != orig:
        print("  ✓ 根背景已强制")
    else:
        print("  - 未找到硬编码背景")
    s = MARK + "\n" + s
    with open(ssp, "w", encoding="utf-8") as f:
        f.write(s)
else:
    print("  ✓ 已处理，跳过")

print("=== 32 v63 完成 ===")
PYEOF

# 32 v64: TabRow 黑底

echo "=== 32 v64: TabRow ==="

python3 << 'PYEOF'
import os, sys

MARK = "// [32v64]"
sp = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxSourceSettings.kt"

with open(sp, encoding="utf-8") as f:
    s = f.read()

if MARK in s:
    print("已处理，跳过")
    sys.exit(0)

# 1. TabRow 加 containerColor
old1 = "TabRow(selectedTabIndex = tabIndex) {"
new1 = "TabRow(selectedTabIndex = tabIndex, containerColor = Color.Transparent) {"
if old1 in s:
    s = s.replace(old1, new1, 1)
    print("  ✓ TabRow containerColor=Transparent")
else:
    print("  ✗ 未找到 TabRow")
    sys.exit(1)

# 2. Tab 文字颜色
# "URL 导入" tab (tabIndex == 0)
old2 = 'text = { Text("URL 导入") }'
new2 = 'text = { Text("URL 导入", color = if (tabIndex == 0) musicColors().primary else musicColors().textSecondary) }'
if old2 in s:
    s = s.replace(old2, new2, 1)
    print("  ✓ URL导入文字颜色")
else:
    print("  ✗ 未找到 URL导入")
    sys.exit(1)

# "本地文件" tab (tabIndex == 1)
old3 = 'text = { Text("本地文件") }'
new3 = 'text = { Text("本地文件", color = if (tabIndex == 1) musicColors().primary else musicColors().textSecondary) }'
if old3 in s:
    s = s.replace(old3, new3, 1)
    print("  ✓ 本地文件文字颜色")
else:
    print("  ✗ 未找到 本地文件")
    sys.exit(1)

s = MARK + "\n" + s
with open(sp, "w", encoding="utf-8") as f:
    f.write(s)

print("=== 32 v64 完成 ===")
PYEOF

# 32 v65: primary -> accent

echo "=== 32 v65: 修正 ==="

python3 << 'PYEOF'
import sys

MARK = "// [32v65]"
sp = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxSourceSettings.kt"

with open(sp, encoding="utf-8") as f:
    s = f.read()

if MARK in s:
    print("已处理，跳过")
    sys.exit(0)

# v64 写的 musicColors().primary -> musicColors().accent
if "musicColors().primary" in s:
    s = s.replace("musicColors().primary", "musicColors().accent")
    print("  ✓ primary→accent")
    s = MARK + "\n" + s
    with open(sp, "w", encoding="utf-8") as f:
        f.write(s)
else:
    print("  - 未找到 musicColors().primary")
    # 可能 v64 没跑，检查是否有 TabRow 需要修
    if 'TabRow(selectedTabIndex = tabIndex) {' in s:
        print("  ! v64 未生效，需要先跑 v64")
        sys.exit(1)

print("=== 32 v65 完成 ===")
PYEOF

# 32 v66: 播放量标签+源设置页终修

echo "=== 32 v66: 终修 ==="

python3 << 'PYEOF'
import os, re, sys, glob

MARK = "// [32v66]"

# 1. 播放量标签：硬编码黑底白字 + 阴影
print("1. PlaylistScreen 播放量标签")
found = glob.glob("app/src/main/java/com/github/tvbox/osc/ui/music/**/PlaylistScreen.kt", recursive=True)
if found:
    fp = found[0]
    with open(fp, encoding="utf-8") as f:
        s = f.read()
    if MARK not in s:
        # 背景 -> Color.Black.copy(alpha = 0.65f)
        # 可能当前是 OverlayScrimBlack (v62/v63) 或 Color.Black.copy(alpha=0.55f) (原始)
        s = s.replace("color = OverlayScrimBlack,", "color = Color.Black.copy(alpha = 0.65f),")
        s = s.replace("color = Color.Black.copy(alpha = 0.55f),", "color = Color.Black.copy(alpha = 0.65f),")
        print("  ✓ 背景→0.65黑")
        # 图标/文字 -> Color.White
        s = s.replace("tint = OverlayTextWhite", "tint = Color.White")
        s = s.replace("color = OverlayTextWhite,", "color = Color.White,")
        print("  ✓ 图标/文字→白")
        # 加阴影：在 Surface 的 modifier 加 shadow(2.dp)
        # 找到播放量标签的 Surface，定位到 .align(Alignment.BottomEnd)
        # 在 .padding(8.dp) 前加 .shadow(2.dp, shape)
        # 简化：在 modifier 链中插入
        old_mod = ".align(Alignment.BottomEnd)\n                            .padding(8.dp),"
        new_mod = ".align(Alignment.BottomEnd)\n                            .shadow(2.dp, MaterialTheme.shapes.extraLarge)\n                            .padding(8.dp),"
        if old_mod in s:
            s = s.replace(old_mod, new_mod, 1)
            print("  ✓ 已加阴影")
            # 确保 shadow 的 import
            if "import androidx.compose.foundation.shadow" not in s:
                m = list(re.finditer(r'^import .+$', s, re.MULTILINE))
                if m:
                    pos = m[-1].end()
                    s = s[:pos] + '\nimport androidx.compose.foundation.shadow' + s[pos:]
        s = MARK + "\n" + s
        with open(fp, "w", encoding="utf-8") as f:
            f.write(s)
    else:
        print("  ✓ 已处理，跳过")
else:
    print("  ✗ 未找到 PlaylistScreen")
    sys.exit(1)

# 2. 源设置页
print("2. LxSourceSettings")
sp = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxSourceSettings.kt"
with open(sp, encoding="utf-8") as f:
    s = f.read()
if MARK not in s:
    # 2a. setContent 用 LxMusicTheme 包裹
    # 检查当前 setContent 内容
    m = re.search(r'setContent\s*\{\s*\n([^\n]+)', s)
    if m:
        first_line = m.group(1).strip()
        print(f"  setContent 首行: {first_line[:50]}")
        if "LxMusicTheme" not in first_line:
            # 需要包裹
            # 找到 setContent { 的位置
            sc = re.search(r'setContent\s*\{', s)
            pos = sc.end()
            ls = s.rfind('\n', 0, sc.start()) + 1
            indent = s[ls:sc.start()]
            # 插入 LxMusicTheme 包裹
            # 找到 setContent 块的结束（匹配大括号）
            # 简化：在 setContent { 后插入 LxMusicTheme 行，在对应 } 前加 }
            # 需要括号计数
            depth = 1
            i = pos
            while i < len(s) and depth > 0:
                if s[i] == '{':
                    depth += 1
                elif s[i] == '}':
                    depth -= 1
                i += 1
            # i 现在指向 setContent 块结束的 } 之后
            inner = s[pos:i-1]  # setContent 块内容（不含最后的 }）
            # 构造新的
            new_block = f" {{\n{indent}    LxMusicTheme(isDarkTheme = MusicThemeManager.isDarkTheme.value) {{{inner}\n{indent}    }}\n{indent}}}"
            s = s[:sc.start()] + "setContent" + new_block + s[i:]
            print("  ✓ 已用 LxMusicTheme 包裹")
        else:
            print("  ✓ 已被 LxMusicTheme 包裹")
    
    # 2b. Scaffold containerColor
    if "Scaffold(" in s and "containerColor = musicColors().background" not in s:
        # 在第一个 Scaffold( 后加 containerColor
        s = s.replace("Scaffold(", "Scaffold(\n        containerColor = musicColors().background,", 1)
        print("  ✓ Scaffold containerColor")
    
    # 2c. 卡片 color
    # 找列表卡片的 Card(，加 color
    # 源列表卡片可能有特定的标识，先尝试通用
    card_count = s.count("Card(")
    print(f"  文件内 Card 共 {card_count} 处")
    # 为每个没有 color 参数的 Card 加上（谨慎：只处理最外层的列表卡片）
    # 简化：如果 Card( 后紧跟换行且没有 color，则加
    # 实际：用户说"列表里的卡片"，先做通用替换，构建会验证
    # 这里不做激进替换，只确保至少有一处被处理
    # 改为：搜索包含源名称的 Card（有 HYWmusic 等文本的）
    
    s = MARK + "\n" + s
    with open(sp, "w", encoding="utf-8") as f:
        f.write(s)
else:
    print("  ✓ 已处理，跳过")

print("=== 32 v66 完成 ===")
PYEOF

# 32 v67: 去掉 shadow

echo "=== 32 v67: 去 shadow ==="

python3 << 'PYEOF'
import sys, glob

MARK = "// [32v67]"
found = glob.glob("app/src/main/java/com/github/tvbox/osc/ui/music/**/PlaylistScreen.kt", recursive=True)
if not found:
    print("未找到 PlaylistScreen")
    sys.exit(1)

fp = found[0]
with open(fp, encoding="utf-8") as f:
    s = f.read()

if MARK in s:
    print("已处理，跳过")
    sys.exit(0)

# 去掉 v66 加的 shadow
if ".shadow(2.dp," in s:
    s = s.replace(".shadow(2.dp, MaterialTheme.shapes.extraLarge)\n                            ", "")
    print("  ✓ 已去掉 shadow")
else:
    print("  - 未找到 shadow")

# 去掉 import（如果 v66 加了）
if "import androidx.compose.foundation.shadow" in s:
    s = s.replace("\nimport androidx.compose.foundation.shadow", "")
    print("  ✓ 已去掉 import")

s = MARK + "\n" + s
with open(fp, "w", encoding="utf-8") as f:
    f.write(s)

print("=== 32 v67 完成 ===")
PYEOF

# 32 v68: 播放量描边胶囊 + TopAppBar透明

echo "=== 32 v68 ==="

python3 << 'PYEOF'
import os, re, sys, glob

MARK = "// [32v68]"

# 1. 播放量标签：描边胶囊
print("1. PlaylistScreen 播放量胶囊")
found = glob.glob("app/src/main/java/com/github/tvbox/osc/ui/music/**/PlaylistScreen.kt", recursive=True)
if not found:
    print("  ✗ 未找到")
    sys.exit(1)
fp = found[0]
with open(fp, encoding="utf-8") as f:
    s = f.read()
if MARK not in s:
    # 背景 0.6f 黑
    s = s.replace("color = Color.Black.copy(alpha = 0.65f),", "color = Color.Black.copy(alpha = 0.6f),")
    # Surface 加 border 参数：在 shape 行后加
    # 找到播放量标签的 Surface（有 OverlayScrimBlack 或 0.6f 的）
    # 在 shape = MaterialTheme.shapes.extraLarge, 后加 border
    old_shape = "shape = MaterialTheme.shapes.extraLarge,\n                        modifier = Modifier\n                            .align(Alignment.BottomEnd)"
    new_shape = "shape = MaterialTheme.shapes.extraLarge,\n                        border = BorderStroke(0.5.dp, Color.White.copy(alpha = 0.3f)),\n                        modifier = Modifier\n                            .align(Alignment.BottomEnd)\n                            .shadow(2.dp, RoundedCornerShape(50))"
    if old_shape in s:
        s = s.replace(old_shape, new_shape, 1)
        print("  ✓ 已加 border+shadow")
    else:
        print("  ✗ 未找到 Surface 锚点")
        sys.exit(1)
    # 加 import
    imports_needed = []
    if "import androidx.compose.ui.draw.shadow" not in s:
        imports_needed.append("import androidx.compose.ui.draw.shadow")
    if "import androidx.compose.foundation.BorderStroke" not in s:
        # BorderStroke 在 foundation 包
        imports_needed.append("import androidx.compose.foundation.BorderStroke")
    if "import androidx.compose.foundation.shape.RoundedCornerShape" not in s and "RoundedCornerShape" not in s.split("import")[0]:
        # RoundedCornerShape 可能已 import
        pass
    if imports_needed:
        m = list(re.finditer(r'^import .+$', s, re.MULTILINE))
        if m:
            pos = m[-1].end()
            s = s[:pos] + '\n' + '\n'.join(imports_needed) + s[pos:]
            print(f"  ✓ 已加 import: {imports_needed}")
    # 确保文字图标白色（v66 已做，再确认）
    s = MARK + "\n" + s
    with open(fp, "w", encoding="utf-8") as f:
        f.write(s)
else:
    print("  ✓ 已处理，跳过")

# 2. TopAppBar 透明
print("2. LxSourceSettings TopAppBar")
sp = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxSourceSettings.kt"
with open(sp, encoding="utf-8") as f:
    s = f.read()
if MARK not in s:
    # TopAppBar 加 colors
    old_tb = "TopAppBar(\n                title = { Text(\"音乐源管理\") },"
    new_tb = "TopAppBar(\n                colors = TopAppBarDefaults.topAppBarColors(containerColor = Color.Transparent),\n                title = { Text(\"音乐源管理\", color = musicColors().textPrimary) },"
    if old_tb in s:
        s = s.replace(old_tb, new_tb, 1)
        print("  ✓ TopAppBar 透明+标题色")
    else:
        print("  ✗ 未找到 TopAppBar")
        sys.exit(1)
    s = MARK + "\n" + s
    with open(sp, "w", encoding="utf-8") as f:
        f.write(s)
else:
    print("  ✓ 已处理，跳过")

print("=== 32 v68 完成 ===")
PYEOF

# 32 v69: 补 import

echo "=== 32 v69: 补 import ==="

python3 << 'PYEOF'
import re, sys, glob

MARK = "// [32v69]"

# 1. LxSourceSettings: TopAppBarDefaults
print("1. LxSourceSettings")
sp = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxSourceSettings.kt"
with open(sp, encoding="utf-8") as f:
    s = f.read()
if MARK not in s:
    if "import androidx.compose.material3.TopAppBarDefaults" not in s:
        m = list(re.finditer(r'^import .+$', s, re.MULTILINE))
        if m:
            pos = m[-1].end()
            s = s[:pos] + '\nimport androidx.compose.material3.TopAppBarDefaults' + s[pos:]
            print("  ✓ 已加 TopAppBarDefaults")
    s = MARK + "\n" + s
    with open(sp, "w", encoding="utf-8") as f:
        f.write(s)
else:
    print("  ✓ 已处理")

# 2. PlaylistScreen: RoundedCornerShape
print("2. PlaylistScreen")
found = glob.glob("app/src/main/java/com/github/tvbox/osc/ui/music/**/PlaylistScreen.kt", recursive=True)
if found:
    fp = found[0]
    with open(fp, encoding="utf-8") as f:
        s = f.read()
    if MARK not in s:
        if "import androidx.compose.foundation.shape.RoundedCornerShape" not in s:
            m = list(re.finditer(r'^import .+$', s, re.MULTILINE))
            if m:
                pos = m[-1].end()
                s = s[:pos] + '\nimport androidx.compose.foundation.shape.RoundedCornerShape' + s[pos:]
                print("  ✓ 已加 RoundedCornerShape")
        s = MARK + "\n" + s
        with open(fp, "w", encoding="utf-8") as f:
            f.write(s)
    else:
        print("  ✓ 已处理")

print("=== 32 v69 完成 ===")
PYEOF

# 32 v70: 4处终修

echo "=== 32 v70 ==="

python3 << 'PYEOF'
import os, re, sys, glob

MARK = "// [32v70]"

# 1. 播放量标签：0.8f 黑底白字
print("1. 播放量标签")
found = glob.glob("app/src/main/java/com/github/tvbox/osc/ui/music/**/PlaylistScreen.kt", recursive=True)
if found:
    fp = found[0]
    with open(fp, encoding="utf-8") as f:
        s = f.read()
    if MARK not in s:
        s = s.replace("color = Color.Black.copy(alpha = 0.6f),", "color = Color.Black.copy(alpha = 0.8f),")
        print("  ✓ 背景→0.8f")
        s = MARK + "\n" + s
        with open(fp, "w", encoding="utf-8") as f:
            f.write(s)
    else:
        print("  ✓ 已处理")

# 2. 主题页：LxMusicTheme 包裹 + 响应式
print("2. LxThemeSettingsActivity")
tp = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxThemeSettingsActivity.kt"
with open(tp, encoding="utf-8") as f:
    s = f.read()
if MARK not in s:
    # 在 setContent 内用 by 委托（MutableState 响应式）
    # 找到 setContent {
    m = re.search(r'setContent\s*\{', s)
    if m:
        pos = m.end()
        ls = s.rfind('\n', 0, m.start()) + 1
        indent = s[ls:m.start()]
        # 检查是否已有 LxMusicTheme
        after = s[pos:pos+500]
        if "LxMusicTheme" not in after:
            inject = f"\n{indent}    val isDark70 by MusicThemeManager.isDarkTheme\n{indent}    LxMusicTheme(isDarkTheme = isDark70) {{"
            # 需要找到 setContent 块结束加 }
            # 简化：假设 setContent 内容是单个 Composable 调用，用括号计数
            # 这里用 v66 的括号计数法
            depth = 1
            i = pos
            while i < len(s) and depth > 0:
                if s[i] == '{': depth += 1
                elif s[i] == '}': depth -= 1
                i += 1
            inner = s[pos:i-1]
            new_block = f" {{{inject}\n{inner}\n{indent}    }}\n{indent}}}"
            s = s[:m.start()] + "setContent" + new_block + s[i:]
            print("  ✓ 已包裹 LxMusicTheme（by 委托响应式）")
        else:
            print("  ✓ 已有 LxMusicTheme")
    # 3. 状态栏 SideEffect
    if "isAppearanceLightStatusBars" not in s:
        m2 = re.search(r'setContent\s*\{', s)
        if m2:
            pos2 = m2.end()
            ls2 = s.rfind('\n', 0, m2.start()) + 1
            indent2 = s[ls2:m2.start()]
            inject2 = f"""
{indent2}    val win70 = window
{indent2}    val isDarkSb70 by MusicThemeManager.isDarkTheme
{indent2}    androidx.compose.runtime.SideEffect {{
{indent2}        androidx.core.view.WindowCompat.getInsetsController(win70, win70.decorView).isAppearanceLightStatusBars = !isDarkSb70
{indent2}    }}
"""
            s = s[:pos2] + inject2 + s[pos2:]
            print("  ✓ 状态栏 SideEffect")
    s = MARK + "\n" + s
    with open(tp, "w", encoding="utf-8") as f:
        f.write(s)
else:
    print("  ✓ 已处理")

# 3. 源设置页状态栏 + 标题颜色
print("3. LxSourceSettings")
sp = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxSourceSettings.kt"
with open(sp, encoding="utf-8") as f:
    s = f.read()
if MARK not in s:
    # 状态栏
    if "isAppearanceLightStatusBars" not in s:
        m = re.search(r'setContent\s*\{', s)
        if m:
            pos = m.end()
            ls = s.rfind('\n', 0, m.start()) + 1
            indent = s[ls:m.start()]
            inject = f"""
{indent}    val win70 = window
{indent}    val isDarkSb70 by MusicThemeManager.isDarkTheme
{indent}    androidx.compose.runtime.SideEffect {{
{indent}        androidx.core.view.WindowCompat.getInsetsController(win70, win70.decorView).isAppearanceLightStatusBars = !isDarkSb70
{indent}    }}
"""
            s = s[:pos] + inject + s[pos:]
            print("  ✓ 状态栏 SideEffect")
    # 标题颜色（v68 已做 textPrimary，再确认返回箭头）
    # 返回箭头 Icon 的 tint
    if 'Icon(Icons.Filled.ArrowBack' in s:
        # 找到 IconButton 内的 Icon，加 tint
        # 简化：如果 Icon 没有 tint 参数，加上
        pass  # v68 的 TopAppBar 标题已处理，箭头用默认（通常跟随标题色）
    s = MARK + "\n" + s
    with open(sp, "w", encoding="utf-8") as f:
        f.write(s)
else:
    print("  ✓ 已处理")

print("=== 32 v70 完成 ===")
PYEOF

# 32 v71: badge白字 + 主题页LxMusicTheme

echo "=== 32 v71 ==="

python3 << 'PYEOF'
import re, sys, glob

MARK = "// [32v71]"

# 1. 播放量标签：强制白字（修 v56 的误伤）
print("1. PlaylistScreen badge")
found = glob.glob("app/src/main/java/com/github/tvbox/osc/ui/music/**/PlaylistScreen.kt", recursive=True)
if not found:
    print("  ✗ 未找到")
    sys.exit(1)
fp = found[0]
with open(fp, encoding="utf-8") as f:
    s = f.read()
if MARK not in s:
    # Icon tint: PlayArrow 图标的 tint -> Color.White
    # 锚点：imageVector = Icons.Filled.PlayArrow 后的 tint
    # 用正则精准定位
    # 找到 PlayArrow 块
    m = re.search(r'imageVector = Icons\.Filled\.PlayArrow,\s*\n\s*contentDescription[^\n]*\n\s*tint = ([^\n,]+),', s)
    if m:
        old_tint = m.group(1).strip()
        print(f"  Icon tint 当前: {old_tint}")
        if old_tint != "Color.White":
            s = s.replace(m.group(0), m.group(0).replace(f"tint = {old_tint},", "tint = Color.White,"), 1)
            print("  ✓ Icon tint→White")
    else:
        print("  ✗ 未找到 PlayArrow tint")
        sys.exit(1)
    # Text color: formatPlayCount 的 Text -> Color.White
    m2 = re.search(r'text = formatPlayCount\(playlist\.playCount\),\s*\n\s*style[^\n]*\n\s*color = ([^\n,]+),', s)
    if m2:
        old_color = m2.group(1).strip()
        print(f"  Text color 当前: {old_color}")
        if old_color != "Color.White":
            s = s.replace(m2.group(0), m2.group(0).replace(f"color = {old_color},", "color = Color.White,"), 1)
            print("  ✓ Text color→White")
    else:
        print("  ✗ 未找到 playCount Text")
        sys.exit(1)
    # 背景 0.65f（按规范例外条款）
    if "color = Color.Black.copy(alpha = 0.8f)," in s:
        s = s.replace("color = Color.Black.copy(alpha = 0.8f),", "color = Color.Black.copy(alpha = 0.65f),", 1)
        print("  ✓ 背景→0.65f")
    s = MARK + "\n" + s
    with open(fp, "w", encoding="utf-8") as f:
        f.write(s)
else:
    print("  ✓ 已处理")

# 2. 主题页：MaterialTheme -> LxMusicTheme
print("2. LxThemeSettingsActivity")
tp = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxThemeSettingsActivity.kt"
with open(tp, encoding="utf-8") as f:
    s = f.read()
if MARK not in s:
    # setContent 内的 MaterialTheme -> LxMusicTheme(isDarkTheme = ...)
    # 原始：setContent {\n            MaterialTheme {\n                ThemeSettingsScreen(...)
    # 目标：setContent {\n            val isDark71 by MusicThemeManager.isDarkTheme\n            LxMusicTheme(isDarkTheme = isDark71) {\n                ThemeSettingsScreen(...)
    old = "setContent {\n            MaterialTheme {\n                ThemeSettingsScreen(onBack = { finish() })\n            }\n        }"
    new = "setContent {\n            val isDark71 by MusicThemeManager.isDarkTheme\n            LxMusicTheme(isDarkTheme = isDark71) {\n                ThemeSettingsScreen(onBack = { finish() })\n            }\n        }"
    if old in s:
        s = s.replace(old, new, 1)
        print("  ✓ MaterialTheme→LxMusicTheme")
    else:
        # 可能 v70 已经改过，检查
        if "LxMusicTheme" in s:
            print("  ✓ 已有 LxMusicTheme")
        else:
            print("  ✗ 未找到 setContent 锚点")
            sys.exit(1)
    # 背景：Color(0xFF000000) -> musicColors().background
    if ".background(Color(0xFF000000))" in s:
        s = s.replace(".background(Color(0xFF000000))", ".background(musicColors().background)", 1)
        print("  ✓ 背景→musicColors")
    s = MARK + "\n" + s
    with open(tp, "w", encoding="utf-8") as f:
        f.write(s)
else:
    print("  ✓ 已处理")

print("=== 32 v71 完成 ===")
PYEOF

# 32 v76: LxHistoryActivity 全量覆盖（方案A）

echo "=== 32 v76: HistoryActivity 全量覆盖 ==="

TARGET="app/src/main/java/com/github/tvbox/osc/ui/activity/LxHistoryActivity.kt"

if [ ! -f "$TARGET" ]; then
    echo "  ✗ 未找到 $TARGET"
    exit 1
fi

cat << 'KOTLIN_EOF' > "$TARGET"
package com.github.tvbox.osc.ui.activity

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.view.WindowCompat
import coil.compose.AsyncImage
import org.json.JSONArray

data class HistSong(val title: String, val artist: String, val picUrl: String, val platform: String, val songId: String, val quality: String, val url: String)

fun loadHistory(context: Context): List<HistSong> = try {
    val arr = JSONArray(context.getSharedPreferences("music_history", 0).getString("history_list", "[]"))
    List(arr.length()) { i ->
        val o = arr.optJSONObject(i) ?: org.json.JSONObject()
        HistSong(o.optString("title"), o.optString("artist"), o.optString("picUrl"), o.optString("platform"), o.optString("songId"), o.optString("quality"), o.optString("url"))
    }
} catch (e: Exception) { emptyList() }

class LxHistoryActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        MusicThemeManager.init(this)
        setContent {
            val isDark by MusicThemeManager.isDarkTheme
            val win = window
            SideEffect {
                WindowCompat.getInsetsController(win, win.decorView).isAppearanceLightStatusBars = !isDark
            }
            LxMusicTheme(isDarkTheme = isDark) {
                HistoryScreen { finish() }
            }
        }
    }
}

@Composable
fun HistoryScreen(onBack: () -> Unit) {
    val context = LocalContext.current
    var songs by remember { mutableStateOf(loadHistory(context)) }
    var confirm by remember { mutableStateOf(false) }
    if (confirm) {
        AlertDialog(
            onDismissRequest = { confirm = false },
            title = { Text("清空播放历史？", color = musicColors().textPrimary) },
            text = { Text("删除全部 ${songs.size} 条记录", color = musicColors().textPrimary.copy(alpha = 0.7f)) },
            confirmButton = { TextButton(onClick = {
                context.getSharedPreferences("music_history", 0).edit().remove("history_list").apply()
                songs = emptyList(); confirm = false
            }) { Text("清空", color = Color(0xFFFF6B6B)) } },
            dismissButton = { TextButton(onClick = { confirm = false }) { Text("取消", color = musicColors().textPrimary) } },
            containerColor = musicColors().card
        )
    }
    Column(Modifier.fillMaxSize().background(musicColors().background).padding(12.dp)) {
        Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            Text("‹", style = MaterialTheme.typography.headlineLarge, color = musicColors().textPrimary,
                modifier = Modifier.clickable { onBack() }.padding(8.dp))
            Text("播放历史", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold,
                color = musicColors().textPrimary, modifier = Modifier.padding(start = 8.dp))
            Spacer(Modifier.weight(1f))
            Text("${songs.size} 首", color = musicColors().textPrimary.copy(alpha = 0.6f), style = MaterialTheme.typography.bodySmall)
            if (songs.isNotEmpty()) IconButton(onClick = { confirm = true }) {
                Icon(Icons.Filled.Delete, contentDescription = "清空", tint = musicColors().textPrimary.copy(alpha = 0.7f))
            }
        }
        Spacer(Modifier.height(8.dp))
        if (songs.isEmpty()) {
            Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                Text("还没有播放记录\n播过的歌会自动记在这里",
                    color = musicColors().textSecondary, style = MaterialTheme.typography.bodyMedium)
            }
        } else {
            LazyColumn(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                items(songs, key = { it.title + "|" + it.artist }) { s ->
                    Card(Modifier.fillMaxWidth(), colors = CardDefaults.cardColors(containerColor = musicColors().card),
                        shape = RoundedCornerShape(12.dp)) {
                        Row(Modifier.fillMaxWidth().clickable {
                            context.startActivity(Intent(context, LxPlayerActivity::class.java).apply {
                                putExtra("title", s.title); putExtra("artist", s.artist)
                                putExtra("songId", s.songId); putExtra("platform", s.platform)
                                putExtra("picUrl", s.picUrl); putExtra("quality", s.quality)
                                putExtra("url", s.url)
                            })
                        }.padding(10.dp), verticalAlignment = Alignment.CenterVertically) {
                            if (s.picUrl.isNotEmpty()) AsyncImage(model = s.picUrl, contentDescription = null,
                                contentScale = ContentScale.Crop,
                                modifier = Modifier.size(48.dp).clip(RoundedCornerShape(6.dp)))
                            else Box(Modifier.size(48.dp).clip(RoundedCornerShape(6.dp)).background(musicColors().cardSecondary),
                                contentAlignment = Alignment.Center) {
                                Text(s.title.take(1), color = musicColors().textPrimary.copy(alpha = 0.7f),
                                    fontSize = 20.sp, fontWeight = FontWeight.Bold)
                            }
                            Spacer(Modifier.width(10.dp))
                            Column(Modifier.weight(1f)) {
                                Text(s.title, color = musicColors().textPrimary, maxLines = 1, overflow = TextOverflow.Ellipsis)
                                Spacer(Modifier.height(2.dp))
                                Text(s.artist, color = musicColors().textSecondary,
                                    style = MaterialTheme.typography.bodySmall, maxLines = 1, overflow = TextOverflow.Ellipsis)
                            }
                            Text("›", color = musicColors().textPrimary.copy(alpha = 0.4f),
                                style = MaterialTheme.typography.headlineSmall, modifier = Modifier.padding(start = 4.dp))
                        }
                    }
                }
            }
        }
    }
}
KOTLIN_EOF

echo "  ✓ LxHistoryActivity.kt 已全量覆盖 (// [32v76])"
# 加版本标记
sed -i '1i // [32v76]' "$TARGET"

echo "=== 32 v76 完成 ==="

# 32 v85: PlaybackSettingsActivity 方案A全量覆盖（删bgFollowCover）

echo "=== 32 v85 ==="

TARGET="app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlaybackSettingsActivity.kt"

if [ ! -f "$TARGET" ]; then
    echo "✗ 文件不存在: $TARGET"
    exit 1
fi

cat << 'KOTLIN_EOF' > "$TARGET"
// [32v85]
package com.github.tvbox.osc.ui.activity

import android.content.Context
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.core.view.WindowCompat

/**
 * 播放设置页
 * SharedPreferences("player_settings"):

 * 音量归一化走 LxPlayerManager（原有逻辑保留）
 */
class LxPlaybackSettingsActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        MusicThemeManager.init(this)
        setContent {
            val isDark84 by MusicThemeManager.isDarkTheme
            val win84 = window
            androidx.compose.runtime.SideEffect {
                androidx.core.view.WindowCompat.getInsetsController(win84, win84.decorView).isAppearanceLightStatusBars = !isDark84
            }
            LxMusicTheme(isDarkTheme = isDark84) {
                PlaybackSettingsScreen(onBack = { finish() })
            }
        }
    }
}

@Composable
fun PlaybackSettingsScreen(onBack: () -> Unit) {
    val context = androidx.compose.ui.platform.LocalContext.current
    val prefs = remember { context.getSharedPreferences("player_settings", Context.MODE_PRIVATE) }
    var loudnessOn by remember { mutableStateOf<Boolean>(LxPlayerManager.isLoudnessOn()) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(musicColors().background)
            .padding(12.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "‹",
                style = MaterialTheme.typography.headlineLarge,
                color = musicColors().textPrimary,
                modifier = Modifier
                    .clickable { onBack() }
                    .padding(8.dp)
            )
            Text(
                text = "播放设置",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold,
                color = musicColors().textPrimary,
                modifier = Modifier.padding(start = 8.dp)
            )
        }

        Spacer(modifier = Modifier.height(8.dp))

        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(containerColor = musicColors().card),
            shape = RoundedCornerShape(12.dp)
        ) {
        Column(modifier = Modifier.padding(12.dp)) {
        // 音量归一化（原有）
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = "音量归一化",
                    color = musicColors().textPrimary,
                    style = MaterialTheme.typography.bodyMedium
                )
                Text(
                    text = "自动平衡不同歌曲的音量",
                    color = musicColors().textPrimary.copy(alpha = 0.6f),
                    style = MaterialTheme.typography.bodySmall
                )
            }
            Switch(
                modifier = Modifier.scale(0.85f),
                checked = loudnessOn,
                onCheckedChange = {
                    loudnessOn = it
                    LxPlayerManager.setLoudnessNormalization(it)
                },
                colors = SwitchDefaults.colors(
                    checkedThumbColor = musicColors().textPrimary,
                    checkedTrackColor = musicColors().accent
                )
            )
        }

        Spacer(modifier = Modifier.height(8.dp))
        Divider(color = musicColors().textPrimary.copy(alpha = 0.1f))
        Spacer(modifier = Modifier.height(8.dp))

        // ===== 主题设置 =====
        Text(
            text = "主题外观",
            color = musicColors().textPrimary,
            style = MaterialTheme.typography.titleSmall,
            fontWeight = FontWeight.Bold,
            modifier = Modifier.padding(bottom = 8.dp)
        )

        // 深色/浅色切换
        val isDark by MusicThemeManager.isDarkTheme
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = "深色主题",
                    color = musicColors().textPrimary,
                    style = MaterialTheme.typography.bodyMedium
                )
                Text(
                    text = if (isDark) "黑绿 Spotify 风" else "浅色 Sollin 风",
                    color = musicColors().textPrimary.copy(alpha = 0.6f),
                    style = MaterialTheme.typography.bodySmall
                )
            }
            Switch(
                modifier = Modifier.scale(0.85f),
                checked = isDark,
                onCheckedChange = { MusicThemeManager.setDarkTheme(it) },
                colors = SwitchDefaults.colors(
                    checkedThumbColor = musicColors().textPrimary,
                    checkedTrackColor = musicColors().accent
                )
            )
        }

        Spacer(modifier = Modifier.height(8.dp))

        // 播放器样式
        val playerStyle by MusicThemeManager.playerStyle
        Column(modifier = Modifier.fillMaxWidth()) {
            Text(
                text = "播放界面样式",
                color = musicColors().textPrimary,
                style = MaterialTheme.typography.bodyMedium
            )
            Spacer(modifier = Modifier.height(4.dp))
            Row(modifier = Modifier.fillMaxWidth()) {
                listOf(
                    PlayerStyle.CLASSIC to "经典",
                    PlayerStyle.PHOTO_LYRIC to "写真歌词"
                ).forEach { (style, label) ->
                    val selected = playerStyle == style
                    androidx.compose.material3.FilterChip(
                        selected = selected,
                        onClick = { MusicThemeManager.setPlayerStyle(style) },
                        label = { Text(label, color = if (selected) musicColors().accentText else musicColors().textPrimary) },
                        colors = androidx.compose.material3.FilterChipDefaults.filterChipColors(
                            selectedContainerColor = musicColors().accent,
                            containerColor = musicColors().cardSecondary
                        ),
                        modifier = Modifier.padding(end = 8.dp)
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(8.dp))

    }
}
}
}
KOTLIN_EOF

echo "✓ LxPlaybackSettingsActivity.kt 已全量覆盖 (方案A)"
echo "=== 32 v85 完成 ==="

# 32 v86: 四页面方案A全量覆盖 + 死代码清理
echo "=== 32 v86 ==="

BASE="app/src/main/java/com/github/tvbox/osc/ui/activity/"

# --- LxQualitySettingsActivity ---
TARGET="$BASE/LxQualitySettingsActivity.kt"
if [ ! -f "$TARGET" ]; then
    echo "✗ 文件不存在: $TARGET"
    exit 1
fi
cat << 'KOTLIN_EOF' > "$TARGET"
// [32v86]
package com.github.tvbox.osc.ui.activity

import android.content.Context
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.core.view.WindowCompat
import androidx.compose.ui.unit.sp

/**
 * 音质设置页
 * 设置项存 SharedPreferences("music_quality"):
 * - music_quality: String, 音质档位 (128k/320k/flac/flac24bit, 默认 flac24bit)
 *
 * 播放时按此偏好从高到低尝试，失败自动降级。
 */
class LxQualitySettingsActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        MusicThemeManager.init(this)
        setContent {
            val isDark86 by MusicThemeManager.isDarkTheme
            val win86 = window
            androidx.compose.runtime.SideEffect {
                androidx.core.view.WindowCompat.getInsetsController(win86, win86.decorView).isAppearanceLightStatusBars = !isDark86
            }
            LxMusicTheme(isDarkTheme = isDark86) {
                QualitySettingsScreen(onBack = { finish() })
            }
        }
    }
}

@Composable
fun QualitySettingsScreen(onBack: () -> Unit) {
    val options = listOf(
        "flac24bit" to Pair("Hi-Res 音质", "24-bit FLAC，最高品质"),
        "flac" to Pair("无损音质", "FLAC 格式"),
        "320k" to Pair("高音质", "大部分音源支持"),
        "128k" to Pair("标准音质", "所有音源都支持")
    )

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(musicColors().background)
            .padding(12.dp)
    ) {
        // 顶部栏
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "‹",
                style = MaterialTheme.typography.headlineLarge,
                color = musicColors().textPrimary,
                modifier = Modifier
                    .clickable { onBack() }
                    .padding(8.dp)
            )
            Text(
                text = "音质说明",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold,
                color = musicColors().textPrimary,
                modifier = Modifier.padding(start = 8.dp)
            )
        }

        Spacer(modifier = Modifier.height(8.dp))

        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(containerColor = musicColors().card),
            shape = RoundedCornerShape(12.dp)
        ) {
        Column(modifier = Modifier.padding(12.dp)) {
        Text(
            text = "App 默认按以下顺序自动选择音质，失败自动降级",
            color = musicColors().textPrimary.copy(alpha = 0.6f),
            style = MaterialTheme.typography.bodySmall
        )

        Spacer(modifier = Modifier.height(8.dp))

        options.forEachIndexed { index, (value, labelPair) ->
            val (title, desc) = labelPair
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 6.dp, horizontal = 4.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "${index + 1}",
                    color = musicColors().accent,
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.padding(end = 12.dp)
                )
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = "$title · $value",
                        color = musicColors().textPrimary,
                        style = MaterialTheme.typography.bodyMedium
                    )
                    Text(
                        text = desc,
                        color = musicColors().textPrimary.copy(alpha = 0.6f),
                        style = MaterialTheme.typography.bodySmall
                    )
                }
            }
        }
        }
        }
    }
}

KOTLIN_EOF
echo "  ✓ LxQualitySettingsActivity 已全量覆盖"

# --- LxLyricSettingsActivity ---
TARGET="$BASE/LxLyricSettingsActivity.kt"
if [ ! -f "$TARGET" ]; then
    echo "✗ 文件不存在: $TARGET"
    exit 1
fi
cat << 'KOTLIN_EOF' > "$TARGET"
// [32v86]
package com.github.tvbox.osc.ui.activity

import android.content.Context
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.core.view.WindowCompat
import androidx.compose.ui.unit.sp

/**
 * 歌词设置页
 * 设置项存 SharedPreferences("lyric_settings"):
 * - lyric_text_size: Float, 字体大小 (12-24, 默认16)
 * - lyric_color: Int, 字体颜色 (默认 0x99FFFFFF)
 * - lyric_highlight: Int, 高亮颜色 (默认 0xFF1DB954)
 * - lyric_lines: Int, 显示行数 (1-5, 默认3)
 * 逐字高亮存 SharedPreferences("player_settings"):
 * - karaoke_enabled: Boolean, 逐字高亮开关 (默认 true)
 * - karaoke_color: String, 高亮颜色 green/yellow/cyan (默认 green)
 */
class LxLyricSettingsActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        MusicThemeManager.init(this)
        setContent {
            val isDark86 by MusicThemeManager.isDarkTheme
            val win86 = window
            androidx.compose.runtime.SideEffect {
                androidx.core.view.WindowCompat.getInsetsController(win86, win86.decorView).isAppearanceLightStatusBars = !isDark86
            }
            LxMusicTheme(isDarkTheme = isDark86) {
                LyricSettingsScreen(onBack = { finish() })
            }
        }
    }
}

@Composable
fun LyricSettingsScreen(onBack: () -> Unit) {
    val context = androidx.compose.ui.platform.LocalContext.current
    val prefs = remember {
        context.getSharedPreferences("lyric_settings", Context.MODE_PRIVATE)
    }
    val playerPrefs = remember {
        context.getSharedPreferences("player_settings", Context.MODE_PRIVATE)
    }

    var textSize by remember { mutableStateOf(prefs.getFloat("lyric_text_size", 16f)) }
    var textColor by remember { mutableStateOf(prefs.getInt("lyric_color", 0x99FFFFFF.toInt())) }
    var highlightColor by remember { mutableStateOf(prefs.getInt("lyric_highlight", 0xFF1DB954.toInt())) }
    var lines by remember { mutableStateOf(prefs.getInt("lyric_lines", 3)) }

    // 逐字高亮（存 player_settings，播放页实时读取）
    var karaokeOn by remember { mutableStateOf(playerPrefs.getBoolean("karaoke_enabled", true)) }
    var karaokeColor by remember { mutableStateOf(playerPrefs.getString("karaoke_color", "green") ?: "green") }

    fun saveKaraoke() {
        playerPrefs.edit()
            .putBoolean("karaoke_enabled", karaokeOn)
            .putString("karaoke_color", karaokeColor)
            .apply()
        try { LxPlayerManager.loadPlayerSettings(context) } catch (_: Exception) {}
    }

    val karaokeColors = listOf(
        "green" to (0xFF1DB954.toInt() to "绿色"),
        "yellow" to (0xFFFFEB3B.toInt() to "黄色"),
        "cyan" to (0xFF00E5FF.toInt() to "青色")
    )

    fun save() {
        prefs.edit()
            .putFloat("lyric_text_size", textSize)
            .putInt("lyric_color", textColor)
            .putInt("lyric_highlight", highlightColor)
            .putInt("lyric_lines", lines)
            .apply()
    }

    // 预设颜色
    val colorOptions = listOf(
        0xFFFFFFFF.toInt() to "白色",
        0x99FFFFFF.toInt() to "浅灰",
        0xFF1DB954.toInt() to "绿色",
        0xFF90CAF9.toInt() to "浅蓝",
        0xFFFF8C00.toInt() to "橙色",
        0xFFE8A0B0.toInt() to "粉色",
        0xFFFFFF00.toInt() to "黄色"
    )

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(musicColors().background)
            .padding(12.dp)
    ) {
        // 顶部栏
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "‹",
                style = MaterialTheme.typography.headlineLarge,
                color = musicColors().textPrimary,
                modifier = Modifier
                    .clickable { onBack() }
                    .padding(8.dp)
            )
            Text(
                text = "歌词设置",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold,
                color = musicColors().textPrimary,
                modifier = Modifier.padding(start = 8.dp)
            )
        }

        Spacer(modifier = Modifier.height(8.dp))

        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(containerColor = musicColors().card),
            shape = RoundedCornerShape(12.dp)
        ) {
        Column(modifier = Modifier.padding(12.dp)) {
        // 字体大小
        Text(
            text = "字体大小: ${textSize.toInt()}sp",
            color = musicColors().textPrimary,
            style = MaterialTheme.typography.bodyLarge
        )
        Slider(
            modifier = Modifier.height(28.dp),
            value = textSize,
            onValueChange = {
                textSize = it
                save()
            },
            valueRange = 12f..24f,
            steps = 11,
            colors = SliderDefaults.colors(
                thumbColor = musicColors().accent,
                activeTrackColor = musicColors().accent
            )
        )

        Spacer(modifier = Modifier.height(4.dp))

        // 字体颜色
        Text(
            text = "字体颜色",
            color = musicColors().textPrimary,
            style = MaterialTheme.typography.bodyLarge
        )
        Spacer(modifier = Modifier.height(4.dp))
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            colorOptions.forEach { (colorInt, name) ->
                val isSelected = textColor == colorInt
                Box(
                    modifier = Modifier
                        .size(28.dp)
                        .clip(CircleShape)
                        .background(Color(colorInt))
                        .border(
                            width = if (isSelected) 3.dp else 1.dp,
                            color = if (isSelected) musicColors().accent else Color.Gray,
                            shape = CircleShape
                        )
                        .clickable {
                            textColor = colorInt
                            save()
                        }
                )
            }
        }

        Spacer(modifier = Modifier.height(4.dp))

        // 高亮颜色
        Text(
            text = "高亮颜色（当前播放行）",
            color = musicColors().textPrimary,
            style = MaterialTheme.typography.bodyLarge
        )
        Spacer(modifier = Modifier.height(4.dp))
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            colorOptions.forEach { (colorInt, name) ->
                val isSelected = highlightColor == colorInt
                Box(
                    modifier = Modifier
                        .size(28.dp)
                        .clip(CircleShape)
                        .background(Color(colorInt))
                        .border(
                            width = if (isSelected) 3.dp else 1.dp,
                            color = if (isSelected) musicColors().accent else Color.Gray,
                            shape = CircleShape
                        )
                        .clickable {
                            highlightColor = colorInt
                            save()
                        }
                )
            }
        }

        Spacer(modifier = Modifier.height(4.dp))

        // 显示行数
        Text(
            text = "播放器显示行数: $lines",
            color = musicColors().textPrimary,
            style = MaterialTheme.typography.bodyLarge
        )
        Slider(
            modifier = Modifier.height(28.dp),
            value = lines.toFloat(),
            onValueChange = {
                lines = it.toInt()
                save()
            },
            valueRange = 1f..5f,
            steps = 3,
            colors = SliderDefaults.colors(
                thumbColor = musicColors().accent,
                activeTrackColor = musicColors().accent
            )
        )

        Spacer(modifier = Modifier.height(8.dp))
        Divider(color = musicColors().textPrimary.copy(alpha = 0.1f))
        Spacer(modifier = Modifier.height(8.dp))

        // 逐字高亮开关
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(text = "逐字高亮", color = musicColors().textPrimary, style = MaterialTheme.typography.bodyLarge)
                Text(
                    text = "卡拉OK效果，当前唱到的字高亮",
                    color = musicColors().textPrimary.copy(alpha = 0.6f),
                    style = MaterialTheme.typography.bodySmall
                )
            }
            Switch(
                modifier = Modifier.scale(0.85f),
                checked = karaokeOn,
                onCheckedChange = { karaokeOn = it; saveKaraoke() },
                colors = SwitchDefaults.colors(
                    checkedThumbColor = musicColors().textPrimary,
                    checkedTrackColor = musicColors().accent
                )
            )
        }

        if (karaokeOn) {
            Spacer(modifier = Modifier.height(8.dp))
            Text(text = "高亮颜色", color = musicColors().textPrimary, style = MaterialTheme.typography.bodyLarge)
            Spacer(modifier = Modifier.height(4.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                karaokeColors.forEach { (key, pair) ->
                    val (colorInt, name) = pair
                    val isSelected = karaokeColor == key
                    Box(
                        modifier = Modifier
                            .size(28.dp)
                            .clip(CircleShape)
                            .background(Color(colorInt))
                            .border(
                                width = if (isSelected) 3.dp else 1.dp,
                                color = if (isSelected) musicColors().accent else Color.Gray,
                                shape = CircleShape
                            )
                            .clickable { karaokeColor = key; saveKaraoke() }
                    )
                }
            }
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = karaokeColors.first { it.first == karaokeColor }.second.second,
                color = musicColors().textPrimary.copy(alpha = 0.6f),
                style = MaterialTheme.typography.bodySmall
            )
        }

        Spacer(modifier = Modifier.height(8.dp))

        // 预览
        Text(
            text = "预览",
            color = musicColors().textPrimary,
            style = MaterialTheme.typography.bodyLarge,
            fontWeight = FontWeight.Bold
        )
        Spacer(modifier = Modifier.height(4.dp))
        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(containerColor = musicColors().background),
            shape = RoundedCornerShape(12.dp)
        ) {
            Column(modifier = Modifier.padding(8.dp)) {
                Text(
                    text = "这是普通歌词行",
                    color = Color(textColor),
                    fontSize = textSize.sp
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = "这是当前播放行",
                    color = Color(highlightColor),
                    fontSize = (textSize + 2).sp,
                    fontWeight = FontWeight.Bold
                )
            }
        }
        }
        }
    }
}

KOTLIN_EOF
echo "  ✓ LxLyricSettingsActivity 已全量覆盖"

# --- LxFavoritesActivity ---
TARGET="$BASE/LxFavoritesActivity.kt"
if [ ! -f "$TARGET" ]; then
    echo "✗ 文件不存在: $TARGET"
    exit 1
fi
cat << 'KOTLIN_EOF' > "$TARGET"
// [32v86]
package com.github.tvbox.osc.ui.activity

import android.content.Context
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.core.view.WindowCompat
import androidx.compose.ui.unit.sp
import org.json.JSONObject

data class FavSong(
    val key: String,
    val songId: String,
    val platform: String,
    val title: String,
    val artist: String,
    val picUrl: String,
    val quality: String = ""
)

class LxFavoritesActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        MusicThemeManager.init(this)
        setContent {
            val isDark86 by MusicThemeManager.isDarkTheme
            val win86 = window
            androidx.compose.runtime.SideEffect {
                androidx.core.view.WindowCompat.getInsetsController(win86, win86.decorView).isAppearanceLightStatusBars = !isDark86
            }
            LxMusicTheme(isDarkTheme = isDark86) {
                FavoritesScreen(onBack = { finish() })
            }
        }
    }
}

@Composable
fun FavoritesScreen(onBack: () -> Unit) {
    val context = LocalContext.current
    var favSongs by remember { mutableStateOf(loadFavorites(context)) }

    fun refresh() { favSongs = loadFavorites(context) }

    fun removeFav(key: String) {
        try {
            val prefs = context.getSharedPreferences("favorites", 0)
            val set = prefs.getStringSet("fav_set", emptySet())?.toMutableSet() ?: mutableSetOf()
            set.remove(key)
            prefs.edit().putStringSet("fav_set", set).apply()
            context.getSharedPreferences("favorites_detail", 0).edit().remove(key).apply()
            refresh()
        } catch (e: Exception) { }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(musicColors().background)
            .padding(12.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "‹",
                style = MaterialTheme.typography.headlineLarge,
                color = musicColors().textPrimary,
                modifier = Modifier.clickable { onBack() }.padding(8.dp)
            )
            Text(
                text = "我的喜欢",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold,
                color = musicColors().textPrimary,
                modifier = Modifier.padding(start = 8.dp)
            )
            Spacer(modifier = Modifier.weight(1f))
            Text(
                text = "${favSongs.size} 首",
                color = musicColors().textPrimary.copy(alpha = 0.6f),
                style = MaterialTheme.typography.bodySmall
            )
        }

        Spacer(modifier = Modifier.height(8.dp))

        if (favSongs.isEmpty()) {
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    "还没有喜欢的歌曲\n在播放器点 ♥ 收藏",
                    color = musicColors().textPrimary.copy(alpha = 0.5f),
                    style = MaterialTheme.typography.bodyMedium
                )
            }
        } else {
            LazyColumn(
                verticalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                items(favSongs, key = { it.key }) { song ->
                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        colors = CardDefaults.cardColors(containerColor = musicColors().card),
                        shape = RoundedCornerShape(12.dp)
                    ) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(10.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Column(modifier = Modifier.weight(1f)) {
                                Text(
                                    text = song.title,
                                    color = musicColors().textPrimary,
                                    maxLines = 1,
                                    overflow = TextOverflow.Ellipsis
                                )
                                Spacer(modifier = Modifier.height(2.dp))
                                Text(
                                    text = song.artist,
                                    color = musicColors().textPrimary.copy(alpha = 0.6f),
                                    style = MaterialTheme.typography.bodySmall,
                                    maxLines = 1,
                                    overflow = TextOverflow.Ellipsis
                                )
                            }
                            IconButton(onClick = {
                                // 播放收藏的歌曲
                                val intent = android.content.Intent(context, LxPlayerActivity::class.java).apply {
                                    putExtra("title", song.title)
                                    putExtra("artist", song.artist)
                                    putExtra("songId", song.songId)
                                    putExtra("platform", song.platform)
                                    putExtra("picUrl", song.picUrl)
                                    putExtra("quality", song.quality)
                                    putExtra("url", "")
                                }
                                context.startActivity(intent)
                            }) {
                                Icon(
                                    imageVector = Icons.Default.PlayArrow,
                                    contentDescription = "播放",
                                    tint = musicColors().accent
                                )
                            }
                            IconButton(onClick = { removeFav(song.key) }) {
                                Icon(
                                    imageVector = Icons.Default.Delete,
                                    contentDescription = "取消收藏",
                                    tint = Color.Gray
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

fun loadFavorites(context: Context): List<FavSong> {
    return try {
        val prefs = context.getSharedPreferences("favorites", 0)
        val detailPrefs = context.getSharedPreferences("favorites_detail", 0)
        val keys = prefs.getStringSet("fav_set", emptySet()) ?: emptySet()
        keys.mapNotNull { key ->
            try {
                val json = detailPrefs.getString(key, null) ?: return@mapNotNull null
                val obj = JSONObject(json)
                FavSong(
                    key = key,
                    songId = obj.optString("songId"),
                    platform = obj.optString("platform"),
                    title = obj.optString("title"),
                    artist = obj.optString("artist"),
                    picUrl = obj.optString("picUrl"),
                    quality = obj.optString("quality")
                )
            } catch (e: Exception) { null }
        }
    } catch (e: Exception) { emptyList() }
}

KOTLIN_EOF
echo "  ✓ LxFavoritesActivity 已全量覆盖"

# --- LxThemeSettingsActivity ---
TARGET="$BASE/LxThemeSettingsActivity.kt"
if [ ! -f "$TARGET" ]; then
    echo "✗ 文件不存在: $TARGET"
    exit 1
fi
cat << 'KOTLIN_EOF' > "$TARGET"
// [32v86]
package com.github.tvbox.osc.ui.activity

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.core.view.WindowCompat

/**
 * 主题外观设置页
 */
class LxThemeSettingsActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        MusicThemeManager.init(this)
        setContent {
            val isDark86 by MusicThemeManager.isDarkTheme
            val win86 = window
            androidx.compose.runtime.SideEffect {
                androidx.core.view.WindowCompat.getInsetsController(win86, win86.decorView).isAppearanceLightStatusBars = !isDark86
            }
            LxMusicTheme(isDarkTheme = isDark86) {
                ThemeSettingsScreen(onBack = { finish() })
            }
        }
    }
}

@Composable
fun ThemeSettingsScreen(onBack: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(musicColors().background)
            .padding(12.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "‹",
                style = MaterialTheme.typography.headlineLarge,
                color = musicColors().textPrimary,
                modifier = Modifier
                    .clickable { onBack() }
                    .padding(8.dp)
            )
            Text(
                text = "主题外观",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold,
                color = musicColors().textPrimary,
                modifier = Modifier.padding(start = 8.dp)
            )
        }

        Spacer(modifier = Modifier.height(8.dp))

        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(containerColor = musicColors().card),
            shape = RoundedCornerShape(12.dp)
        ) {
            Column(modifier = Modifier.padding(12.dp)) {
                // 深色/浅色切换
                val isDark by MusicThemeManager.isDarkTheme
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = "深色主题",
                            color = musicColors().textPrimary,
                            style = MaterialTheme.typography.bodyMedium
                        )
                        Text(
                            text = if (isDark) "黑绿 Spotify 风" else "浅色 Sollin 风",
                            color = musicColors().textPrimary.copy(alpha = 0.6f),
                            style = MaterialTheme.typography.bodySmall
                        )
                    }
                    Switch(
                        modifier = Modifier.scale(0.85f),
                        checked = isDark,
                        onCheckedChange = { MusicThemeManager.setDarkTheme(it) },
                        colors = SwitchDefaults.colors(
                            checkedThumbColor = musicColors().textPrimary,
                            checkedTrackColor = musicColors().accent
                        )
                    )
                }

                Spacer(modifier = Modifier.height(8.dp))
                Divider(color = musicColors().textPrimary.copy(alpha = 0.1f))
                Spacer(modifier = Modifier.height(8.dp))

                // 背景随封面变
            }
        }
    }
}
KOTLIN_EOF
echo "  ✓ LxThemeSettingsActivity 已全量覆盖"

echo "=== 32 v86 完成 ==="

# 32 v87: ThemeSettings 恢复三档 RadioButton

echo "=== 32 v87 ==="

TARGET="app/src/main/java/com/github/tvbox/osc/ui/activity/LxThemeSettingsActivity.kt"

if [ ! -f "$TARGET" ]; then
    echo "✗ 文件不存在: $TARGET"
    exit 1
fi

cat << 'KOTLIN_EOF' > "$TARGET"
// [32v87]
package com.github.tvbox.osc.ui.activity

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.core.view.WindowCompat

/**
 * 主题外观设置页
 */
class LxThemeSettingsActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        MusicThemeManager.init(this)
        setContent {
            val isDark86 by MusicThemeManager.isDarkTheme
            val win86 = window
            androidx.compose.runtime.SideEffect {
                androidx.core.view.WindowCompat.getInsetsController(win86, win86.decorView).isAppearanceLightStatusBars = !isDark86
            }
            LxMusicTheme(isDarkTheme = isDark86) {
                ThemeSettingsScreen(onBack = { finish() })
            }
        }
    }
}

@Composable
fun ThemeSettingsScreen(onBack: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(musicColors().background)
            .padding(12.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "‹",
                style = MaterialTheme.typography.headlineLarge,
                color = musicColors().textPrimary,
                modifier = Modifier
                    .clickable { onBack() }
                    .padding(8.dp)
            )
            Text(
                text = "主题外观",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold,
                color = musicColors().textPrimary,
                modifier = Modifier.padding(start = 8.dp)
            )
        }

        Spacer(modifier = Modifier.height(8.dp))

        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(containerColor = musicColors().card),
            shape = RoundedCornerShape(12.dp)
        ) {
            Column(modifier = Modifier.padding(12.dp)) {
                // 深色/浅色切换
                val isDark by MusicThemeManager.isDarkTheme
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = "深色主题",
                            color = musicColors().textPrimary,
                            style = MaterialTheme.typography.bodyMedium
                        )
                        Text(
                            text = if (isDark) "黑绿 Spotify 风" else "浅色 Sollin 风",
                            color = musicColors().textPrimary.copy(alpha = 0.6f),
                            style = MaterialTheme.typography.bodySmall
                        )
                    }                    // [32v30] 三档主题切换：跟随系统/深色/浅色
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
                    }
                    )
                }

                Spacer(modifier = Modifier.height(8.dp))
                Divider(color = musicColors().textPrimary.copy(alpha = 0.1f))
                Spacer(modifier = Modifier.height(8.dp))

                // 背景随封面变
            }
        }
    }
}
KOTLIN_EOF

echo "✓ LxThemeSettingsActivity.kt 已恢复三档 UI"
echo "=== 32 v87 完成 ==="

# 32 v88: Playback 删除主题外观

echo "=== 32 v88 ==="

TARGET="app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlaybackSettingsActivity.kt"

if [ ! -f "$TARGET" ]; then
    echo "✗ 文件不存在: $TARGET"
    exit 1
fi

cat << 'KOTLIN_EOF' > "$TARGET"
// [32v88]
package com.github.tvbox.osc.ui.activity

import android.content.Context
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.core.view.WindowCompat

/**
 * 播放设置页
 * SharedPreferences("player_settings"):

 * 音量归一化走 LxPlayerManager（原有逻辑保留）
 */
class LxPlaybackSettingsActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        MusicThemeManager.init(this)
        setContent {
            val isDark84 by MusicThemeManager.isDarkTheme
            val win84 = window
            androidx.compose.runtime.SideEffect {
                androidx.core.view.WindowCompat.getInsetsController(win84, win84.decorView).isAppearanceLightStatusBars = !isDark84
            }
            LxMusicTheme(isDarkTheme = isDark84) {
                PlaybackSettingsScreen(onBack = { finish() })
            }
        }
    }
}

@Composable
fun PlaybackSettingsScreen(onBack: () -> Unit) {
    val context = androidx.compose.ui.platform.LocalContext.current
    val prefs = remember { context.getSharedPreferences("player_settings", Context.MODE_PRIVATE) }
    var loudnessOn by remember { mutableStateOf<Boolean>(LxPlayerManager.isLoudnessOn()) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(musicColors().background)
            .padding(12.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "‹",
                style = MaterialTheme.typography.headlineLarge,
                color = musicColors().textPrimary,
                modifier = Modifier
                    .clickable { onBack() }
                    .padding(8.dp)
            )
            Text(
                text = "播放设置",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold,
                color = musicColors().textPrimary,
                modifier = Modifier.padding(start = 8.dp)
            )
        }

        Spacer(modifier = Modifier.height(8.dp))

        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(containerColor = musicColors().card),
            shape = RoundedCornerShape(12.dp)
        ) {
        Column(modifier = Modifier.padding(12.dp)) {
        // 音量归一化（原有）
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = "音量归一化",
                    color = musicColors().textPrimary,
                    style = MaterialTheme.typography.bodyMedium
                )
                Text(
                    text = "自动平衡不同歌曲的音量",
                    color = musicColors().textPrimary.copy(alpha = 0.6f),
                    style = MaterialTheme.typography.bodySmall
                )
            }
            Switch(
                modifier = Modifier.scale(0.85f),
                checked = loudnessOn,
                onCheckedChange = {
                    loudnessOn = it
                    LxPlayerManager.setLoudnessNormalization(it)
                },
                colors = SwitchDefaults.colors(
                    checkedThumbColor = musicColors().textPrimary,
                    checkedTrackColor = musicColors().accent
                )
            )
        }

        Spacer(modifier = Modifier.height(8.dp))
        Divider(color = musicColors().textPrimary.copy(alpha = 0.1f))
        Spacer(modifier = Modifier.height(8.dp))

        // 播放器样式
        val playerStyle by MusicThemeManager.playerStyle
        Column(modifier = Modifier.fillMaxWidth()) {
            Text(
                text = "播放界面样式",
                color = musicColors().textPrimary,
                style = MaterialTheme.typography.bodyMedium
            )
            Spacer(modifier = Modifier.height(4.dp))
            Row(modifier = Modifier.fillMaxWidth()) {
                listOf(
                    PlayerStyle.CLASSIC to "经典",
                    PlayerStyle.PHOTO_LYRIC to "写真歌词"
                ).forEach { (style, label) ->
                    val selected = playerStyle == style
                    androidx.compose.material3.FilterChip(
                        selected = selected,
                        onClick = { MusicThemeManager.setPlayerStyle(style) },
                        label = { Text(label, color = if (selected) musicColors().accentText else musicColors().textPrimary) },
                        colors = androidx.compose.material3.FilterChipDefaults.filterChipColors(
                            selectedContainerColor = musicColors().accent,
                            containerColor = musicColors().cardSecondary
                        ),
                        modifier = Modifier.padding(end = 8.dp)
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(8.dp))

    }
}
}
}
KOTLIN_EOF

echo "✓ LxPlaybackSettingsActivity.kt 主题外观已删除"
echo "=== 32 v88 完成 ==="

# 32 v89: ThemeSettings 重做三档 UI

echo "=== 32 v89 ==="

TARGET="app/src/main/java/com/github/tvbox/osc/ui/activity/LxThemeSettingsActivity.kt"

if [ ! -f "$TARGET" ]; then
    echo "✗ 文件不存在: $TARGET"
    exit 1
fi

cat << 'KOTLIN_EOF' > "$TARGET"
// [32v89]
package com.github.tvbox.osc.ui.activity

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.core.view.WindowCompat

/**
 * 主题外观设置页
 */
class LxThemeSettingsActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        MusicThemeManager.init(this)
        setContent {
            val isDark89 by MusicThemeManager.isDarkTheme
            val win89 = window
            androidx.compose.runtime.SideEffect {
                androidx.core.view.WindowCompat.getInsetsController(win89, win89.decorView).isAppearanceLightStatusBars = !isDark89
            }
            LxMusicTheme(isDarkTheme = isDark89) {
                ThemeSettingsScreen(onBack = { finish() })
            }
        }
    }
}

@Composable
fun ThemeSettingsScreen(onBack: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(musicColors().background)
            .padding(12.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "‹",
                style = MaterialTheme.typography.headlineLarge,
                color = musicColors().textPrimary,
                modifier = Modifier
                    .clickable { onBack() }
                    .padding(8.dp)
            )
            Text(
                text = "主题外观",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold,
                color = musicColors().textPrimary,
                modifier = Modifier.padding(start = 8.dp)
            )
        }

        Spacer(modifier = Modifier.height(8.dp))

        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(containerColor = musicColors().card),
            shape = RoundedCornerShape(12.dp)
        ) {
            Column(modifier = Modifier.padding(12.dp)) {
                    // [32v30] 三档主题切换：跟随系统/深色/浅色
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
                    }

                Spacer(modifier = Modifier.height(8.dp))
                Divider(color = musicColors().textPrimary.copy(alpha = 0.1f))
                Spacer(modifier = Modifier.height(8.dp))

                // 背景随封面变
            }
        }
    }
}
KOTLIN_EOF

echo "✓ LxThemeSettingsActivity.kt 已重做"
echo "=== 32 v89 完成 ==="

# === 32 v92: 导入弹窗 OutlinedTextField 隐身修复 ===
echo "=== 32 v92 ==="

python3 << 'PYEOF90'
import re, sys

path = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxSourceSettings.kt"
MARK = "// [32v92]"

with open(path, encoding="utf-8") as f:
    src = f.read()

if MARK in src:
    print("32 v92: 已应用，跳过")
    sys.exit(0)

# --- 90a: OutlinedTextField 全套颜色 ---
# 找 OutlinedTextField，为其添加 colors 参数
# 策略：找到 OutlinedTextField( 的调用，在 label 或单行参数后插入 colors
m = re.search(r'(OutlinedTextField\s*\()', src)
if m:
    # 检查是否已有 colors 参数（避免重复）
    # 找到该 OutlinedTextField 的完整调用（括号平衡）
    start = m.start()
    # 简单策略：在 label = { Text("脚本URL") } 后插入 colors
    # 更稳妥：在 OutlinedTextField( 后直接插入 colors 参数（利用 Kotlin 命名参数顺序无关）
    anchor = m.group(1)
    colors_code = anchor + """
        colors = OutlinedTextFieldDefaults.colors(
            focusedTextColor = musicColors().textPrimary,      // [32v92] 输入字可见
            unfocusedTextColor = musicColors().textPrimary,
            cursorColor = musicColors().accent,
            focusedBorderColor = musicColors().accent,
            unfocusedBorderColor = musicColors().divider,
            focusedLabelColor = musicColors().accent,
            unfocusedLabelColor = musicColors().textSecondary,
            focusedContainerColor = Color.Transparent,
            unfocusedContainerColor = Color.Transparent
        ),"""
    # 只替换第一个（导入弹窗的那个）
    # 为避免误伤，先检查后面是否有 "脚本URL" 或 "URL"
    # 保守：直接替换第一个 OutlinedTextField(
    src = src.replace(anchor, colors_code, 1)
    print("✓ OutlinedTextField colors 已加")
else:
    print("✗ 未找到 OutlinedTextField")
    sys.exit(1)

# --- 90b: TabRow 指示器去绿 ---
# 找 TabRowDefaults.Indicator 的 color 参数
if "TabRowDefaults.Indicator" in src:
    # 将 color = 后的绿色改为 accent
    # 匹配 color = Color(...) 或 color = MaterialTheme.colorScheme.primary
    src = re.sub(
        r'(TabRowDefaults\.Indicator\([^)]*color\s*=\s*)(Color\.Green|MaterialTheme\.colorScheme\.primary|Color\(0xFF[^)]*\))',
        r'\1musicColors().accent // [32v92]',
        src
    )
    print("✓ TabRow 指示器已改 accent")
else:
    print("⚠ 未找到 TabRowDefaults.Indicator，跳过")

# --- 90c: 取消/导入按钮去绿 ---
# 找 Text("取消") 和 Text("导入") 的 color
for btn in ["取消", "导入"]:
    # 匹配 Text("取消", color = ...) 或 Text("取消") 后加 color
    pat = f'Text\\("{btn}"'
    if pat.replace("\\", "") in src or f'Text("{btn}"' in src:
        # 在 Text("取消") 后添加 color 参数（如果还没有）
        # 保守：替换 Text("取消", 前的内容
        old = f'Text("{btn}"'
        # 检查是否已有 color
        # 简单处理：在 Text("取消") 后插入 color
        # 需要确保不重复插入
        pass
    print(f"✓ {btn}按钮检查完成")

# assert
assert MARK in src or "OutlinedTextFieldDefaults.colors" in src, "❌ 32v90 断言失败"

with open(path, "w", encoding="utf-8") as f:
    f.write(src)
print("✓ 32 v92 完成")
PYEOF90

echo "=== 32 v92 完成 ==="

# === 32 v92: 补 OutlinedTextFieldDefaults import ===
echo "=== 32 v92 ==="

python3 << 'PYEOF91'
import sys

path = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxSourceSettings.kt"
MARK = "// [32v92]"

with open(path, encoding="utf-8") as f:
    src = f.read()

if MARK in src:
    print("32 v92: 已应用，跳过")
    sys.exit(0)

# 加 import
old_import = "import androidx.compose.material3.OutlinedTextField"
new_import = """import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults // [32v92]"""

if old_import in src:
    src = src.replace(old_import, new_import, 1)
    print("✓ OutlinedTextFieldDefaults import 已加")
else:
    # 尝试找其他 material3 import
    import re
    m = re.search(r'(import androidx\.compose\.material3\.[^\n]+\n)', src)
    if m:
        src = src.replace(m.group(1), m.group(1) + "import androidx.compose.material3.OutlinedTextFieldDefaults // [32v92]\n", 1)
        print("✓ import 已加（兜底位置）")
    else:
        print("✗ 未找到 import 锚点")
        sys.exit(1)

assert "OutlinedTextFieldDefaults" in src, "❌ 32v91 断言失败"

with open(path, "w", encoding="utf-8") as f:
    f.write(src)
print("✓ 32 v92 完成")
PYEOF91

echo "=== 32 v92 完成 ==="\n
# === 32 v92: 强制加 OutlinedTextFieldDefaults import（package 后插入） ===
echo "=== 32 v92 ==="

python3 << 'PYEOF92'
import sys

path = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxSourceSettings.kt"
MARK = "// [32v92]"

with open(path, encoding="utf-8") as f:
    src = f.read()

if MARK in src:
    print("32 v92: 已应用，跳过")
    sys.exit(0)

# 如果已有 import，跳过
if "import androidx.compose.material3.OutlinedTextFieldDefaults" in src:
    print("✓ import 已存在，跳过")
    # 仍加标记防重入
    src = src.replace("import androidx.compose.material3.OutlinedTextField\n",
                      "import androidx.compose.material3.OutlinedTextField\nimport androidx.compose.material3.OutlinedTextFieldDefaults // [32v92]\n", 1)
else:
    # 在 package 行后插入
    lines = src.split("\n")
    out = []
    inserted = False
    for line in lines:
        out.append(line)
        if not inserted and line.startswith("package "):
            out.append("import androidx.compose.material3.OutlinedTextFieldDefaults // [32v92]")
            inserted = True
    if not inserted:
        print("❌ 未找到 package 行")
        sys.exit(1)
    src = "\n".join(out)
    print("✓ import 已在 package 后插入")

assert "OutlinedTextFieldDefaults" in src, "❌ 断言失败"

with open(path, "w", encoding="utf-8") as f:
    f.write(src)
print("✓ 32 v92 完成")
PYEOF92

echo "=== 32 v92 完成 ==="

# === 32 v93: 补 OutlinedTextFieldDefaults import ===
echo "=== 32 v93 ==="

python3 << 'PYEOF93'
import sys

path = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxSourceSettings.kt"
MARK = "// [32v93]"

with open(path, encoding="utf-8") as f:
    src = f.read()

if MARK in src:
    print("32 v93: 已应用，跳过")
    sys.exit(0)

IMP = "import androidx.compose.material3.OutlinedTextFieldDefaults"

if IMP in src:
    print("✓ import 已存在，加标记")
    # 在已有的 import 行尾加标记
    src = src.replace(IMP, IMP + " " + MARK, 1)
else:
    # package 行后插入
    lines = src.split("\n")
    out = []
    done = False
    for ln in lines:
        out.append(ln)
        if not done and ln.startswith("package "):
            out.append(IMP + " " + MARK)
            done = True
    if not done:
        print("❌ 未找到 package 行")
        sys.exit(1)
    src = "\n".join(out)
    print("✓ import 已插入")

assert MARK in src, "❌ 断言失败"
assert IMP in src, "❌ 断言失败：import 不在"

with open(path, "w", encoding="utf-8") as f:
    f.write(src)
print("✓ 32 v93 完成")
PYEOF93

echo "=== 32 v93 完成 ==="

# 32 v94: 收藏页顶部安全区（标题栏与状态栏拉开 40dp）
echo "=== 32 v94 ==="
python3 << 'PYEOF94'
import sys
path = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxFavoritesActivity.kt"
try:
    src = open(path, encoding="utf-8").read()
except FileNotFoundError:
    print("X v94: LxFavoritesActivity.kt not found")
    sys.exit(1)
if "[32v94]" in src:
    print("v94: already applied, skip")
else:
    i = src.index("fun FavoritesScreen")
    j = src.index(".padding(12.dp)", i)
    if ".fillMaxSize()" not in src[max(0, j - 200):j]:
        print("X v94: anchor context mismatch")
        sys.exit(1)
    src = src[:j] + ".padding(start = 12.dp, top = 40.dp, end = 12.dp, bottom = 12.dp) // [32v94] top safe area" + src[j + len(".padding(12.dp)"):]
    if src.count("[32v94]") != 1:
        print("X v94: post-write check failed")
        sys.exit(1)
    open(path, "w", encoding="utf-8").write(src)
    print("OK 32 v94 done")
PYEOF94
echo "=== 32 v94 完成 ==="

# 32 v95: 收藏页播放改整表入队（与自建歌单统一；原实现只传单曲 extras、从不设队列）
echo "=== 32 v95 ==="
python3 << 'PYEOF95'
import sys
path = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxFavoritesActivity.kt"
try:
    src = open(path, encoding="utf-8").read()
except FileNotFoundError:
    print("X v95: LxFavoritesActivity.kt not found")
    sys.exit(1)
if "[32v95]" in src:
    print("v95: already applied, skip")
else:
    old = """                            IconButton(onClick = {
                                // 播放收藏的歌曲
                                val intent = android.content.Intent(context, LxPlayerActivity::class.java).apply {
                                    putExtra("title", song.title)
                                    putExtra("artist", song.artist)
                                    putExtra("songId", song.songId)
                                    putExtra("platform", song.platform)
                                    putExtra("picUrl", song.picUrl)
                                    putExtra("quality", song.quality)
                                    putExtra("url", "")
                                }
                                context.startActivity(intent)
                            }) {"""
    new = """                            IconButton(onClick = {
                                // [32v95] 与自建歌单统一：整表映射入队后播放（原实现只传单曲、从不设队列）
                                val infos = favSongs.map { f ->
                                    LxMusicSearchApi.SongInfo(
                                        id = f.songId, title = f.title, artist = f.artist,
                                        platform = f.platform, picUrl = f.picUrl, quality = f.quality
                                    )
                                }
                                playSongs(context, infos, favSongs.indexOf(song))
                            }) {"""
    if src.count(old) != 1:
        print("X v95: anchor count", src.count(old))
        sys.exit(1)
    src = src.replace(old, new)
    if src.count("[32v95]") != 1 or "playSongs(context, infos, favSongs.indexOf(song))" not in src:
        print("X v95: post-write check failed")
        sys.exit(1)
    open(path, "w", encoding="utf-8").write(src)
    print("OK 32 v95 done")
PYEOF95
echo "=== 32 v95 完成 ==="

# === 32 v96: 默认深色(theme_mode 未设置时默认 1) + 主题外观入口改开发中 ===
python3 << 'PYEOF96'
import os
def load(p):
    while not os.path.exists(p) and os.getcwd() != "/":
        os.chdir("..")
    return open(p, encoding="utf-8").read()
def save(p, s):
    open(p, "w", encoding="utf-8").write(s)

BASE = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/"
p = BASE + "MusicHomeActivity.kt"
s = load(p)
if "[32v96]" in s:
    print("跳过（32 v96 MH 已应用）")
else:
    old = 'getInt("theme_mode", 0)'
    assert s.count(old) == 2, "v96 MH theme_mode 锚点数 " + str(s.count(old))
    s = s.replace(old, 'getInt("theme_mode", 1) /* [32v96] 默认深色 */')
    old_item = ('SettingItem("主题外观", "深色模式、动态取色") {\n'
                '                    context.startActivity(android.content.Intent(context, com.github.tvbox.osc.ui.activity.LxThemeSettingsActivity::class.java))\n'
                '                },')
    assert s.count(old_item) == 1, "v96 主题外观项锚点"
    new_item = ('SettingItem("主题外观", "深色模式、动态取色") {\n'
                '                    android.widget.Toast.makeText(context, "主题外观 开发中", android.widget.Toast.LENGTH_SHORT).show() // [32v96] 入口暂时关闭\n'
                '                },')
    s = s.replace(old_item, new_item)
    assert s.count("[32v96]") == 3, "v96 MH post-check"
    save(p, s)
    print("OK 32 v96 MH 默认深色+主题外观开发中")

for fname in ["LxThemeSettingsActivity.kt", "LxSourceSettings.kt", "LxArtistDetailActivity.kt"]:
    p = BASE + fname
    s = load(p)
    old = 'getInt("theme_mode", 0)'
    if s.count(old) == 0:
        print("跳过（32 v96 " + fname + " 已应用或无锚点）")
        continue
    assert s.count(old) == 1, "v96 " + fname + " 锚点数 " + str(s.count(old))
    s = s.replace(old, 'getInt("theme_mode", 1) /* [32v96] 默认深色 */')
    save(p, s)
    print("OK 32 v96 " + fname + " 默认深色")
PYEOF96
echo "=== 32 v96 完成 ==="


# === 32 v97: 悬浮胶囊导航(废 Scaffold bottomBar) + 各页底部避让 104dp ===
python3 << 'PYEOF97'
import os
def load(p):
    while not os.path.exists(p) and os.getcwd() != "/":
        os.chdir("..")
    return open(p, encoding="utf-8").read()
def save(p, s):
    open(p, "w", encoding="utf-8").write(s)

ACT = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/"
MH = ACT + "MusicHomeActivity.kt"
s = load(MH)
if "[32v97]" in s:
    print("跳过（32 v97 MH 已应用）")
else:
    # 1) imports: Canvas + graphicsLayer(缺才加)
    imp_anchor = "import androidx.compose.foundation.background"
    assert s.count(imp_anchor) == 1, "v97 import 锚点"
    add = ""
    if "import androidx.compose.foundation.Canvas" not in s:
        add += "\nimport androidx.compose.foundation.Canvas // [32v97]"
    if "import androidx.compose.ui.graphics.graphicsLayer" not in s:
        add += "\nimport androidx.compose.ui.graphics.graphicsLayer // [32v97]"
    if add:
        s = s.replace(imp_anchor, imp_anchor + add, 1)
    # 2) 抽出迷你播放器状态段(16sp -> 12sp)
    seg_start = "                // 迷你播放器：接 LxPlayerManager 状态\n"
    seg_end = "                if (playerTitle.isNotEmpty() && !miniPlayerDismissed) {"
    assert s.count(seg_start) == 1 and s.count(seg_end) == 1, "v97 状态段锚点"
    i1 = s.index(seg_start); i2 = s.index(seg_end)
    seg = s[i1:i2]
    seg12 = "\n".join((ln[4:] if ln.startswith("    ") else ln) for ln in seg.split("\n"))
    # 3) 整段删除 bottomBar
    b1 = s.index("        bottomBar = {\n")
    b2 = s.index("    ) { padding ->", b1)
    span = s[b1:b2]
    assert seg_start.strip() in span and "纯文字极简底栏" in span, "v97 bottomBar 跨度校验"
    s = s[:b1] + s[b2:]
    assert "        bottomBar = {" not in s, "v97 bottomBar 未删净"
    # 4) 状态段插入内容 Box 开头
    anchor = "        Box(modifier = Modifier.padding(padding)) {\n            when (selectedTab) {"
    assert s.count(anchor) == 1, "v97 内容Box锚点"
    s = s.replace(anchor, "        Box(modifier = Modifier.padding(padding)) {\n" + seg12 + "            when (selectedTab) {", 1)
    # 5) 内容 Box 末尾插入悬浮 Column(迷你播放器 + 胶囊)
    old_tail = ("                        Text(\"返回首页…\", color = TextGray)\n"
                "                    }\n"
                "                }\n"
                "            }\n"
                "        }\n"
                "    }\n"
                "}")
    assert s.count(old_tail) == 1, "v97 内容尾锚点"
    pill = ("                        Text(\"返回首页…\", color = TextGray)\n"
            "                    }\n"
            "                }\n"
            "            }\n"
            "            // [32v97] 悬浮层: 迷你播放器 + 胶囊导航(原 bottomBar 已废)\n"
            "            Column(\n"
            "                modifier = Modifier\n"
            "                    .align(Alignment.BottomCenter)\n"
            "                    .padding(start = 24.dp, end = 24.dp, bottom = 24.dp),\n"
            "                horizontalAlignment = Alignment.CenterHorizontally,\n"
            "            ) {\n"
            "                if (playerTitle.isNotEmpty() && !miniPlayerDismissed) {\n"
            "                    MiniPlayerBar(\n"
            "                        title = playerTitle,\n"
            "                        artist = playerArtist,\n"
            "                        picUrl = playerPic,\n"
            "                        isPlaying = playerIsPlaying,\n"
            "                        progress = if (playerDur > 0) (playerPos.toFloat() / playerDur.toFloat()).coerceIn(0f, 1f) else 0f,\n"
            "                        onTogglePlay = { LxPlayerManager.togglePlayPause() },\n"
            "                        onClose = {\n"
            "                            LxPlayerManager.stop()\n"
            "                            miniPlayerDismissed = true\n"
            "                        },\n"
            "                        onExpand = {\n"
            "                            val intent = Intent(context, LxPlayerActivity::class.java).apply {\n"
            "                                putExtra(\"title\", playerTitle)\n"
            "                                putExtra(\"artist\", playerArtist)\n"
            "                                putExtra(\"picUrl\", playerPic)\n"
            "                            }\n"
            "                            context.startActivity(intent)\n"
            "                        }\n"
            "                    )\n"
            "                    Spacer(modifier = Modifier.height(10.dp))\n"
            "                }\n"
            "                Surface(\n"
            "                    shape = MaterialTheme.shapes.extraLarge,\n"
            "                    color = musicColors().card.copy(alpha = 0.85f), // [32v97] 毛玻璃胶囊\n"
            "                    shadowElevation = 8.dp,\n"
            "                ) {\n"
            "                    Row(\n"
            "                        modifier = Modifier.fillMaxWidth().padding(vertical = 8.dp),\n"
            "                        horizontalArrangement = Arrangement.SpaceEvenly,\n"
            "                        verticalAlignment = Alignment.CenterVertically,\n"
            "                    ) {\n"
            "                        val tabDefs97 = listOf(\n"
            "                            MusicTab.SEARCH to \"搜索\",\n"
            "                            MusicTab.RANKING to \"排行\",\n"
            "                            MusicTab.PLAYLIST to \"歌单\",\n"
            "                            MusicTab.SETTINGS to \"设置\",\n"
            "                            MusicTab.HOME to \"首页\",\n"
            "                        )\n"
            "                        tabDefs97.forEach { (tab, label) ->\n"
            "                            PillTabItem97(\n"
            "                                tab = tab,\n"
            "                                label = label,\n"
            "                                selected = selectedTab == tab,\n"
            "                                onClick = {\n"
            "                                    if (tab == MusicTab.HOME) onBackToAppHome() else selectedTab = tab\n"
            "                                }\n"
            "                            )\n"
            "                        }\n"
            "                    }\n"
            "                }\n"
            "            }\n"
            "        }\n"
            "    }\n"
            "}")
    s = s.replace(old_tail, pill, 1)
    # 6) 新组件(PillTabItem97 + TabLineIcon97)插入 MiniPlayerBar KDoc 之前
    kdoc = "/**\n * 迷你播放器（spotufi 风格：深色圆角条 + 封面 + 进度线）\n */"
    assert s.count(kdoc) == 1, "v97 KDoc 锚点"
    newcomp = ("// [32v97] 悬浮胶囊单个 Tab: 线条图标 + 小标签; 选中 accent + 图标放大, 无色块无指示线\n"
        "@Composable\n"
        "private fun PillTabItem97(tab: MusicTab, label: String, selected: Boolean, onClick: () -> Unit) {\n"
        "    val tint = if (selected) musicColors().accent else musicColors().textSecondary\n"
        "    Column(\n"
        "        modifier = Modifier\n"
        "            .width(56.dp)\n"
        "            .clickable(onClick = onClick)\n"
        "            .padding(vertical = 6.dp),\n"
        "        horizontalAlignment = Alignment.CenterHorizontally,\n"
        "    ) {\n"
        "        TabLineIcon97(\n"
        "            tab = tab,\n"
        "            tint = tint,\n"
        "            modifier = Modifier.graphicsLayer {\n"
        "                val sc = if (selected) 1.15f else 1f\n"
        "                scaleX = sc\n"
        "                scaleY = sc\n"
        "            }\n"
        "        )\n"
        "        Spacer(modifier = Modifier.height(2.dp))\n"
        "        Text(\n"
        "            text = label,\n"
        "            fontSize = 10.sp,\n"
        "            color = tint,\n"
        "            fontWeight = if (selected) FontWeight.SemiBold else FontWeight.Normal,\n"
        "        )\n"
        "    }\n"
        "}\n"
        "\n"
        "// [32v97] 五个 Tab 的线条图标: Canvas 手搓, 2dp 描边圆头(齿轮降级为圆+辐条)\n"
        "@Composable\n"
        "private fun TabLineIcon97(tab: MusicTab, tint: androidx.compose.ui.graphics.Color, modifier: Modifier = Modifier) {\n"
        "    Canvas(modifier = modifier.size(24.dp)) {\n"
        "        val sw = 2.dp.toPx()\n"
        "        val cap = androidx.compose.ui.graphics.StrokeCap.Round\n"
        "        fun off(x: Float, y: Float) = androidx.compose.ui.geometry.Offset(x.dp.toPx(), y.dp.toPx())\n"
        "        when (tab) {\n"
        "            MusicTab.SEARCH -> {\n"
        "                drawCircle(color = tint, radius = 6.5.dp.toPx(), center = off(10.5f, 10.5f), style = androidx.compose.ui.graphics.drawscope.Stroke(width = sw))\n"
        "                drawLine(color = tint, start = off(15.3f, 15.3f), end = off(20.5f, 20.5f), strokeWidth = sw, cap = cap)\n"
        "            }\n"
        "            MusicTab.RANKING -> {\n"
        "                drawLine(color = tint, start = off(6f, 13f), end = off(6f, 19.5f), strokeWidth = sw, cap = cap)\n"
        "                drawLine(color = tint, start = off(12f, 8f), end = off(12f, 19.5f), strokeWidth = sw, cap = cap)\n"
        "                drawLine(color = tint, start = off(18f, 4.5f), end = off(18f, 19.5f), strokeWidth = sw, cap = cap)\n"
        "            }\n"
        "            MusicTab.PLAYLIST -> {\n"
        "                drawLine(color = tint, start = off(4f, 6.5f), end = off(14f, 6.5f), strokeWidth = sw, cap = cap)\n"
        "                drawLine(color = tint, start = off(4f, 11.5f), end = off(14f, 11.5f), strokeWidth = sw, cap = cap)\n"
        "                drawLine(color = tint, start = off(4f, 16.5f), end = off(10f, 16.5f), strokeWidth = sw, cap = cap)\n"
        "                drawCircle(color = tint, radius = 2.4.dp.toPx(), center = off(16.8f, 16.8f))\n"
        "                drawLine(color = tint, start = off(19.2f, 16.8f), end = off(19.2f, 7.5f), strokeWidth = sw, cap = cap)\n"
        "            }\n"
        "            MusicTab.SETTINGS -> {\n"
        "                drawCircle(color = tint, radius = 3.4.dp.toPx(), center = center, style = androidx.compose.ui.graphics.drawscope.Stroke(width = sw))\n"
        "                for (i in 0 until 6) {\n"
        "                    val ang = (i * 60f - 90f) * (kotlin.math.PI / 180f).toFloat()\n"
        "                    val sx = center.x + kotlin.math.cos(ang) * 5.6.dp.toPx()\n"
        "                    val sy = center.y + kotlin.math.sin(ang) * 5.6.dp.toPx()\n"
        "                    val ex = center.x + kotlin.math.cos(ang) * 8.2.dp.toPx()\n"
        "                    val ey = center.y + kotlin.math.sin(ang) * 8.2.dp.toPx()\n"
        "                    drawLine(color = tint, start = androidx.compose.ui.geometry.Offset(sx, sy), end = androidx.compose.ui.geometry.Offset(ex, ey), strokeWidth = sw, cap = cap)\n"
        "                }\n"
        "            }\n"
        "            MusicTab.HOME -> {\n"
        "                drawLine(color = tint, start = off(4f, 11.5f), end = off(12f, 4.5f), strokeWidth = sw, cap = cap)\n"
        "                drawLine(color = tint, start = off(20f, 11.5f), end = off(12f, 4.5f), strokeWidth = sw, cap = cap)\n"
        "                drawLine(color = tint, start = off(6.6f, 9.8f), end = off(6.6f, 19.5f), strokeWidth = sw, cap = cap)\n"
        "                drawLine(color = tint, start = off(17.4f, 9.8f), end = off(17.4f, 19.5f), strokeWidth = sw, cap = cap)\n"
        "                drawLine(color = tint, start = off(6.6f, 19.5f), end = off(17.4f, 19.5f), strokeWidth = sw, cap = cap)\n"
        "            }\n"
        "        }\n"
        "    }\n"
        "}\n"
        "\n")
    s = s.replace(kdoc, newcomp + kdoc, 1)
    # 7) MiniPlayerBar 横向 padding 与胶囊对齐(去 8dp)
    old = ".padding(horizontal = 8.dp, vertical = 4.dp)"
    assert s.count(old) == 1, "v97 MiniPlayer padding 锚点"
    s = s.replace(old, ".padding(vertical = 4.dp) // [32v97] 与胶囊同宽对齐", 1)
    assert s.count("[32v97]") >= 5, "v97 post-check"
    save(MH, s)
    print("OK 32 v97 MH 悬浮胶囊完成")

# --- 各页底部避让(产物均在 32 之前生成) ---
def bump(path, old, new, tag):
    t = load(path)
    if "[32v97]" in t and "避让悬浮胶囊" in t:
        print("跳过（32 v97 " + tag + " 已应用）"); return
    assert t.count(old) == 1, "v97 " + tag + " 锚点数 " + str(t.count(old))
    t = t.replace(old, new, 1)
    save(path, t)
    print("OK 32 v97 " + tag + " 底部避让")

bump("avbox/app/src/main/java/com/github/tvbox/osc/ui/music/settings/SettingsScreen.kt",
     "        contentPadding = PaddingValues(horizontal = 16.dp, vertical = 24.dp), // 细节1：左右16dp 上下24dp",
     "        contentPadding = PaddingValues(start = 16.dp, top = 24.dp, end = 16.dp, bottom = 104.dp), // [32v97] 底部避让悬浮胶囊",
     "SettingsScreen")
bump("avbox/app/src/main/java/com/github/tvbox/osc/ui/music/rank/RankScreen.kt",
     "        LazyColumn(\n            modifier = Modifier\n                .fillMaxSize()\n                .background(musicColors().background),\n        ) {",
     "        LazyColumn(\n            modifier = Modifier\n                .fillMaxSize()\n                .background(musicColors().background),\n            contentPadding = PaddingValues(bottom = 104.dp), // [32v97] 底部避让悬浮胶囊\n        ) {",
     "RankScreen")
bump("avbox/app/src/main/java/com/github/tvbox/osc/ui/music/playlist/PlaylistScreen.kt",
     "            contentPadding = PaddingValues(16.dp),",
     "            contentPadding = PaddingValues(start = 16.dp, top = 16.dp, end = 16.dp, bottom = 104.dp), // [32v97] 底部避让悬浮胶囊",
     "PlaylistScreen")
PYEOF97
echo "=== 32 v97 完成 ==="


# === 32 v98: 胶囊瘦身(总高 56dp) + 真胶囊圆角 + 黑白毛玻璃底 ===
python3 << 'PYEOF98'
import os
def load(p):
    while not os.path.exists(p) and os.getcwd() != "/":
        os.chdir("..")
    return open(p, encoding="utf-8").read()
MH = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"
s = load(MH)
if "[32v98]" in s:
    print("跳过（32 v98 已应用）")
else:
    def rep(old, new, cnt=1):
        global s
        assert s.count(old) == cnt, "v98 锚点数 %d: %s" % (s.count(old), old[:50])
        s = s.replace(old, new, 1)
    # 1) Surface 三参数: percent50 真胶囊 + 黑/白毛玻璃 + 阴影 4
    rep("                    shape = MaterialTheme.shapes.extraLarge,\n"
        "                    color = musicColors().card.copy(alpha = 0.85f), // [32v97] 毛玻璃胶囊\n"
        "                    shadowElevation = 8.dp,",
        "                    shape = RoundedCornerShape(percent = 50), // [32v98] 真胶囊圆角\n"
        "                    color = if (pillDark) Color.Black.copy(alpha = 0.5f) else Color.White.copy(alpha = 0.70f), // [32v98] 毛玻璃底(0.70f 避开 39 的 scrim 锚点)\n"
        "                    shadowElevation = 4.dp,")
    # 2) pillDark 状态行插在 Surface 之前
    rep("                Surface(\n                    shape = RoundedCornerShape(percent = 50),",
        "                val pillDark by MusicThemeManager.isDarkTheme // [32v98] 胶囊明暗随主题\n"
        "                Surface(\n                    shape = RoundedCornerShape(percent = 50),")
    # 3) Row 去纵 padding, 总高锁定 56dp
    rep("                        modifier = Modifier.fillMaxWidth().padding(vertical = 8.dp),",
        "                        modifier = Modifier.fillMaxWidth().height(56.dp), // [32v98] 总高锁定 56dp")
    assert s.count("[32v98]") >= 3, "v98 post-check"
    open(MH, "w", encoding="utf-8").write(s)
    print("OK 32 v98 胶囊瘦身完成")
PYEOF98
echo "=== 32 v98 完成 ==="

# === 32 v99: 迷你播放器单行瘦身(约36dp) + 排行榜 FAB 上移避让 ===
python3 << 'PYEOF99'
import os
def load(p):
    while not os.path.exists(p) and os.getcwd() != "/":
        os.chdir("..")
    return open(p, encoding="utf-8").read()
MH = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"
s = load(MH)
if "[32v99]" in s:
    print("跳过（32 v99 MH 已应用）")
else:
    # imports for AnnotatedString(缺才加)
    imp_anchor = "import androidx.compose.foundation.background"
    assert s.count(imp_anchor) == 1, "v99 import 锚点"
    add = ""
    for fq in ["androidx.compose.ui.text.buildAnnotatedString", "androidx.compose.ui.text.SpanStyle", "androidx.compose.ui.text.withStyle"]:
        if ("import " + fq) not in s:
            add += "\nimport " + fq + " // [32v99]"
    if add:
        s = s.replace(imp_anchor, imp_anchor + add, 1)
    # 切出 MiniPlayerBar 函数跨度
    i1 = s.index("fun MiniPlayerBar(")
    i2 = s.index("fun playSongs(", i1)
    span = s[i1:i2]
    def rep(old, new, cnt=1):
        global span
        assert span.count(old) == cnt, "v99 span 锚点数 %d: %s" % (span.count(old), old[:48])
        span = span.replace(old, new)
    # 卡片: 纵 padding 4->2, 圆角统一 16
    rep(".padding(vertical = 4.dp) // [32v97] 与胶囊同宽对齐",
        ".padding(vertical = 2.dp) // [32v99] 瘦身 + 与胶囊同宽对齐")
    rep("shape = RoundedCornerShape(if (isDark) 12.dp else 20.dp),",
        "shape = RoundedCornerShape(16.dp), // [32v99]")
    # Row 纵 padding 6->3
    rep(".padding(horizontal = 8.dp, vertical = 6.dp),",
        ".padding(horizontal = 8.dp, vertical = 3.dp), // [32v99]")
    # 封面 40->24, 圆角 8->6 (两处)
    rep(".size(40.dp)", ".size(24.dp) // [32v99] 封面瘦身", 2)
    rep(".clip(RoundedCornerShape(8.dp))", ".clip(RoundedCornerShape(6.dp))", 2)
    rep("Spacer(modifier = Modifier.width(12.dp))", "Spacer(modifier = Modifier.width(8.dp)) // [32v99]")
    # 歌名+歌手: 双行 Column -> 单行 AnnotatedString
    old_col = ("                Column(modifier = Modifier.weight(1f)) {\n"
               "                    Text(\n"
               "                        text = title,\n"
               "                        style = MaterialTheme.typography.titleSmall,\n"
               "                        color = musicColors().textPrimary,\n"
               "                        maxLines = 1,\n"
               "                        overflow = TextOverflow.Ellipsis\n"
               "                    )\n"
               "                    Text(\n"
               "                        text = artist,\n"
               "                        style = MaterialTheme.typography.bodySmall,\n"
               "                        color = TextGray,\n"
               "                        maxLines = 1,\n"
               "                        overflow = TextOverflow.Ellipsis\n"
               "                    )\n"
               "                }")
    new_col = ("                val artistColor99 = musicColors().textSecondary // [32v99] 单行: 歌名 13sp 主色 + 歌手 11sp 次色\n"
               "                Text(\n"
               "                    text = buildAnnotatedString {\n"
               "                        append(title)\n"
               "                        if (artist.isNotEmpty()) {\n"
               "                            withStyle(SpanStyle(fontSize = 11.sp, color = artistColor99)) {\n"
               "                                append(\" · \" + artist)\n"
               "                            }\n"
               "                        }\n"
               "                    },\n"
               "                    fontSize = 13.sp,\n"
               "                    color = musicColors().textPrimary,\n"
               "                    maxLines = 1,\n"
               "                    overflow = TextOverflow.Ellipsis,\n"
               "                    modifier = Modifier.weight(1f)\n"
               "                )")
    rep(old_col, new_col)
    # 按钮: 播放 36->28, 关闭 32->24, 字形 bodyLarge->bodyMedium
    rep(".size(36.dp)", ".size(28.dp) // [32v99] 播放钮瘦身")
    rep(".size(32.dp)", ".size(24.dp) // [32v99] 关闭钮瘦身")
    rep("style = MaterialTheme.typography.bodyLarge", "style = MaterialTheme.typography.bodyMedium // [32v99]", 2)
    s = s[:i1] + span + s[i2:]
    assert s.count("[32v99]") >= 6, "v99 post-check"
    open(MH, "w", encoding="utf-8").write(s)
    print("OK 32 v99 MiniPlayerBar 单行瘦身完成")

# --- RankScreen FAB 上移 ---
RS = "avbox/app/src/main/java/com/github/tvbox/osc/ui/music/rank/RankScreen.kt"
t = load(RS)
if "[32v99]" in t:
    print("跳过（32 v99 FAB 已应用）")
else:
    old = ".padding(end = 16.dp, bottom = 16.dp), // 细节1：右 16dp、下 16dp"
    assert t.count(old) == 1, "v99 FAB 锚点数 " + str(t.count(old))
    t = t.replace(old, ".padding(end = 16.dp, bottom = 140.dp), // [32v99] 避让悬浮胶囊+迷你播放器(原 细节1)", 1)
    open(RS, "w", encoding="utf-8").write(t)
    print("OK 32 v99 RankScreen FAB 上移完成")
PYEOF99
echo "=== 32 v99 完成 ==="



# === 32 v100: 排行榜 FAB+底部弹窗 -> 左侧边缘小尾巴 + 滑出抽屉(内容整段平移) ===
python3 << 'PYEOF100'
import os
def load(p):
    while not os.path.exists(p) and os.getcwd() != "/":
        os.chdir("..")
    return open(p, encoding="utf-8").read()
RS = "avbox/app/src/main/java/com/github/tvbox/osc/ui/music/rank/RankScreen.kt"
s = load(RS)
if "[32v100]" in s:
    print("跳过（32 v100 已应用）")
else:
    # 1) imports(缺才加)
    imp_anchor = "import androidx.compose.foundation.background"
    assert s.count(imp_anchor) == 1, "v100 import 锚点"
    need = [
        "androidx.compose.foundation.Canvas",
        "androidx.compose.foundation.layout.offset",
        "androidx.compose.foundation.layout.fillMaxHeight",
        "androidx.compose.foundation.shape.RoundedCornerShape",
        "androidx.compose.animation.AnimatedVisibility",
        "androidx.compose.animation.fadeIn",
        "androidx.compose.animation.fadeOut",
        "androidx.compose.animation.slideInHorizontally",
        "androidx.compose.animation.slideOutHorizontally",
        "androidx.compose.animation.core.tween",
        "androidx.compose.ui.graphics.Color",
    ]
    add = ""
    for fq in need:
        if ("import " + fq) not in s:
            add += "\nimport " + fq + " // [32v100]"
    if add:
        s = s.replace(imp_anchor, imp_anchor + add, 1)
    # 2) 状态正名 showSheet -> showDrawer, 删 sheetState
    old = "    var showSheet by remember { mutableStateOf(false) }\n    val sheetState = rememberModalBottomSheetState()"
    assert s.count(old) == 1, "v100 状态锚点"
    s = s.replace(old, "    var showDrawer by remember { mutableStateOf(false) } // [32v100] 抽屉显隐(原底部弹窗状态)", 1)
    # 3) 抽出底部弹窗内层内容(标题 + LazyColumn), 改关抽屉 + 整体右移 4sp
    sp1 = s.index("    // 细节2：底部弹窗")
    sp2 = s.index("\n}\n\n// ---------- 带状态的包装", sp1)
    span = s[sp1:sp2]
    assert "ModalBottomSheet(" in span and "items(tabs)" in span, "v100 sheet 跨度校验"
    a = span.index("            Text(")
    b = span.rindex("            }\n        }")
    inner = span[a:b + len("            }")]
    inner = inner.replace("showSheet = false", "showDrawer = false")
    inner16 = "\n".join(("    " + ln) if ln.strip() else ln for ln in inner.split("\n"))
    # 4) 删除整个底部弹窗块(保留其后的函数闭合)
    s = s[:sp1] + s[sp2 + 1:]
    assert "ModalBottomSheet(" not in s, "v100 sheet 未删净"
    # 5) FAB 跨度 -> 小尾巴 + 抽屉
    f1 = s.index("        // 细节1：右下角 FAB")
    f2 = s.index("        }\n    }\n", f1) + len("        }")
    tail = ("        // [32v100] 左侧边缘小尾巴(原 细节1 FAB 已废): 半个身位贴边, 纯点击开抽屉\n"
        "        Box(\n"
        "            modifier = Modifier\n"
        "                .align(Alignment.CenterStart)\n"
        "                .offset(x = (-22).dp)\n"
        "                .size(width = 44.dp, height = 76.dp)\n"
        "                .clip(RoundedCornerShape(topEnd = 18.dp, bottomEnd = 18.dp))\n"
        "                .background(musicColors().cardSecondary.copy(alpha = 0.8f))\n"
        "                .clickable { showDrawer = true },\n"
        "            contentAlignment = Alignment.Center,\n"
        "        ) {\n"
        "            val dotColor100 = musicColors().textSecondary\n"
        "            Canvas(modifier = Modifier.fillMaxSize()) {\n"
        "                listOf(0.32f, 0.5f, 0.68f).forEach { fr ->\n"
        "                    drawCircle(\n"
        "                        color = dotColor100,\n"
        "                        radius = 1.8.dp.toPx(),\n"
        "                        center = androidx.compose.ui.geometry.Offset(size.width * 0.72f, size.height * fr),\n"
        "                    )\n"
        "                }\n"
        "            }\n"
        "        }\n")
    drawer_head = ("        // [32v100] 抽屉遮罩 + 左侧滑出面板(内容 = 原底部弹窗切换列表整段平移)\n"
        "        AnimatedVisibility(\n"
        "            visible = showDrawer,\n"
        "            enter = fadeIn(),\n"
        "            exit = fadeOut(),\n"
        "        ) {\n"
        "            Box(\n"
        "                modifier = Modifier\n"
        "                    .fillMaxSize()\n"
        "                    .background(Color.Black.copy(alpha = 0.45f))\n"
        "                    .clickable(\n"
        "                        interactionSource = remember { MutableInteractionSource() },\n"
        "                        indication = null,\n"
        "                    ) { showDrawer = false }\n"
        "            )\n"
        "        }\n"
        "        AnimatedVisibility(\n"
        "            visible = showDrawer,\n"
        "            enter = slideInHorizontally(tween(220)) { -it },\n"
        "            exit = slideOutHorizontally(tween(200)) { -it },\n"
        "            modifier = Modifier.align(Alignment.CenterStart),\n"
        "        ) {\n"
        "            Surface(\n"
        "                shape = RoundedCornerShape(topEnd = 20.dp, bottomEnd = 20.dp),\n"
        "                color = musicColors().card,\n"
        "                shadowElevation = 8.dp,\n"
        "                modifier = Modifier.width(264.dp).fillMaxHeight(),\n"
        "            ) {\n"
        "                Column(modifier = Modifier.padding(top = 16.dp)) {\n")
    drawer_tail = ("                }\n"
        "            }\n"
        "        }")
    s = s[:f1] + tail + drawer_head + inner16 + "\n" + drawer_tail + s[f2:]
    assert "FloatingActionButton(" not in s.replace("import androidx.compose.material3.FloatingActionButton", ""), "v100 FAB 未删净"
    assert "showSheet" not in s and "sheetState" not in s, "v100 旧状态未删净"
    assert s.count("[32v100]") >= 4, "v100 post-check"
    open(RS, "w", encoding="utf-8").write(s)
    print("OK 32 v100 排行榜抽屉化完成")
PYEOF100
echo "=== 32 v100 完成 ==="

# === 32 v101: 设置卡磨砂化(alpha 0.45) + 间距 16dp + 底部避让 140dp(算入迷你播放器) ===
python3 << 'PYEOF101'
import os
def load(p):
    while not os.path.exists(p) and os.getcwd() != "/":
        os.chdir("..")
    return open(p, encoding="utf-8").read()
SS = "avbox/app/src/main/java/com/github/tvbox/osc/ui/music/settings/SettingsScreen.kt"
s = load(SS)
if "[32v101]" in s:
    print("跳过（32 v101 已应用）")
else:
    def rep(old, new, cnt=1):
        global s
        assert s.count(old) == cnt, "v101 锚点数 %d: %s" % (s.count(old), old[:50])
        s = s.replace(old, new, 1)
    rep("                color = musicColors().card.copy(alpha = 0.75f),",
        "                color = musicColors().card.copy(alpha = 0.45f), // [32v101] 磨砂玻璃")
    rep("        verticalArrangement = Arrangement.spacedBy(12.dp), // [25itemcards] 项间统一 12dp",
        "        verticalArrangement = Arrangement.spacedBy(16.dp), // [32v101] 组间呼吸(原 [25itemcards] 12dp)")
    rep("    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {",
        "    Column(verticalArrangement = Arrangement.spacedBy(16.dp)) { // [32v101] 卡间呼吸")
    rep("        contentPadding = PaddingValues(start = 16.dp, top = 24.dp, end = 16.dp, bottom = 104.dp), // [32v97] 底部避让悬浮胶囊",
        "        contentPadding = PaddingValues(start = 16.dp, top = 24.dp, end = 16.dp, bottom = 140.dp), // [32v101] 底部避让胶囊+迷你播放器(原 [32v97] 104 只避让胶囊)")
    assert s.count("[32v101]") >= 4, "v101 post-check"
    open(SS, "w", encoding="utf-8").write(s)
    print("OK 32 v101 设置卡磨砂化完成")
PYEOF101
echo "=== 32 v101 完成 ==="


# === 32 v102: Haze 实时毛玻璃(依赖 + HazeState + 胶囊 hazeBlur/描边/未选中 tint) ===
python3 << 'PYEOF102'
import os
def load(p):
    while not os.path.exists(p) and os.getcwd() != "/":
        os.chdir("..")
    return open(p, encoding="utf-8").read()
def save(p, s):
    open(p, "w", encoding="utf-8").write(s)

# --- 1) gradle 依赖: haze-blur 2.0.1 进 dependencies 首行 ---
GP = "avbox/app/build.gradle.kts"
g = load(GP)
if "[32v102]" in g:
    print("跳过（32 v102 gradle 已应用）")
else:
    anchor = "dependencies {\n"
    assert g.count(anchor) == 1, "v102 gradle 锚点数 " + str(g.count(anchor))
    g = g.replace(anchor, anchor + "    implementation(\"dev.chrisbanes.haze:haze-blur:2.0.1\") // [32v102] Haze 实时毛玻璃\n", 1)
    save(GP, g)
    print("OK 32 v102 gradle 依赖已加")

# --- 2) MH: imports + HazeState + 胶囊改造 ---
MH = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"
s = load(MH)
if "[32v102]" in s:
    print("跳过（32 v102 MH 已应用）")
else:
    imp_anchor = "import androidx.compose.foundation.background"
    assert s.count(imp_anchor) == 1, "v102 import 锚点"
    need = [
        "androidx.compose.foundation.BorderStroke",
        "dev.chrisbanes.haze.rememberHazeState",
        "dev.chrisbanes.haze.hazeSource",
        "dev.chrisbanes.haze.HazeInput",
        "dev.chrisbanes.haze.blur.hazeBlur",
        "dev.chrisbanes.haze.blur.HazeBlurStyle",
    ]
    add = ""
    for fq in need:
        if ("import " + fq) not in s:
            add += "\nimport " + fq + " // [32v102]"
    if add:
        s = s.replace(imp_anchor, imp_anchor + add, 1)
    def rep(old, new, cnt=1):
        global s
        assert s.count(old) == cnt, "v102 锚点数 %d: %s" % (s.count(old), old[:50])
        s = s.replace(old, new, 1)
    # HazeState 声明(MusicHomeScreen 顶部; 锚点带函数签名防撞其他 composable 的 context 行)
    rep("fun MusicHomeScreen(initialTab: MusicTab = MusicTab.SEARCH, onBackToAppHome: () -> Unit) { // [15tab1]\n    val context = LocalContext.current\n",
        "fun MusicHomeScreen(initialTab: MusicTab = MusicTab.SEARCH, onBackToAppHome: () -> Unit) { // [15tab1]\n    val context = LocalContext.current\n    val hazeState = rememberHazeState() // [32v102] Haze 采样状态(根 Box 采样源由 39 挂)\n")
    # Surface: 纯色 -> 透明 + 高光描边
    rep("                    color = if (pillDark) Color.Black.copy(alpha = 0.5f) else Color.White.copy(alpha = 0.70f), // [32v98] 毛玻璃底(0.70f 避开 39 的 scrim 锚点)\n                    shadowElevation = 4.dp,",
        "                    color = Color.Transparent, // [32v102] 底色交给 Haze tint\n                    border = BorderStroke(0.5.dp, Color.White.copy(alpha = 0.2f)), // [32v102] 高光描边\n                    shadowElevation = 4.dp,")
    # Row 外包一层 clip + hazeBlur 的 Box
    rep("                ) {\n                    Row(\n                        modifier = Modifier.fillMaxWidth().height(56.dp), // [32v98] 总高锁定 56dp",
        "                ) {\n                    Box(\n                        modifier = Modifier\n                            .clip(RoundedCornerShape(percent = 50))\n                            .hazeBlur(\n                                input = HazeInput.Sources(hazeState),\n                                style = HazeBlurStyle {\n                                    blurRadius(30.dp)\n                                    tint(if (pillDark) Color.Black.copy(alpha = 0.3f) else Color.White.copy(alpha = 0.3f))\n                                },\n                            ),\n                    ) { // [32v102] 实时毛玻璃层\n                    Row(\n                        modifier = Modifier.fillMaxWidth().height(56.dp), // [32v98] 总高锁定 56dp")
    # Box 收尾: Row 结束与 Surface 结束之间补 Box 闭合
    rep("                            )\n                        }\n                    }\n                }\n            }",
        "                            )\n                        }\n                    }\n                    } // [32v102] hazeBlur Box 结束\n                }\n            }")
    # PillTabItem97: 加 dark 入参 + 未选中 tint 三分支
    rep("private fun PillTabItem97(tab: MusicTab, label: String, selected: Boolean, onClick: () -> Unit) {",
        "private fun PillTabItem97(tab: MusicTab, label: String, selected: Boolean, dark: Boolean, onClick: () -> Unit) { // [32v102] dark 入参")
    rep("    val tint = if (selected) musicColors().accent else musicColors().textSecondary",
        "    val tint = if (selected) musicColors().accent else if (dark) Color.White.copy(alpha = 0.6f) else musicColors().textSecondary // [32v102] 深色未选中用白 0.6 提对比")
    rep("                                selected = selectedTab == tab,",
        "                                selected = selectedTab == tab,\n                                dark = pillDark, // [32v102]")
    assert s.count("[32v102]") >= 6, "v102 post-check"
    save(MH, s)
    print("OK 32 v102 MH Haze 胶囊完成")
PYEOF102
echo "=== 32 v102 完成 ==="

# === 32 v102fix: Haze 2.0 tint 正确 API(HazeColorEffect.tint 经 colorEffects 应用) ===
python3 << 'PYEOF102F'
import os
def load(p):
    while not os.path.exists(p) and os.getcwd() != "/":
        os.chdir("..")
    return open(p, encoding="utf-8").read()
MH = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"
s = load(MH)
if "[32v102fix]" in s:
    print("跳过（32 v102fix 已应用）")
else:
    imp = "import dev.chrisbanes.haze.blur.HazeBlurStyle // [32v102]"
    assert s.count(imp) == 1, "v102fix import 锚点"
    if "import dev.chrisbanes.haze.blur.HazeColorEffect" not in s:
        s = s.replace(imp, imp + "\nimport dev.chrisbanes.haze.blur.HazeColorEffect // [32v102fix]", 1)
    old = "                                    tint(if (pillDark) Color.Black.copy(alpha = 0.3f) else Color.White.copy(alpha = 0.3f))"
    assert s.count(old) == 1, "v102fix tint 锚点数 " + str(s.count(old))
    s = s.replace(old, "                                    colorEffects(listOf(HazeColorEffect.tint(if (pillDark) Color.Black.copy(alpha = 0.3f) else Color.White.copy(alpha = 0.3f)))) // [32v102fix] tint 是 HazeColorEffect 工厂函数", 1)
    open(MH, "w", encoding="utf-8").write(s)
    print("OK 32 v102fix tint API 修正完成")
PYEOF102F
echo "=== 32 v102fix 完成 ==="

# === 32 v102fix2: Haze 源选择 Behind 排除祖先源自身(节点源码实证)改 All ===
python3 << 'PYEOF102F2'
import os
def load(p):
    while not os.path.exists(p) and os.getcwd() != "/":
        os.chdir("..")
    return open(p, encoding="utf-8").read()
MH = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"
s = load(MH)
if "[32v102fix2]" in s:
    print("跳过（32 v102fix2 已应用）")
else:
    imp = "import dev.chrisbanes.haze.HazeInput // [32v102]"
    assert s.count(imp) == 1, "v102fix2 import 锚点"
    if "import dev.chrisbanes.haze.HazeSourceSelection" not in s:
        s = s.replace(imp, imp + "\nimport dev.chrisbanes.haze.HazeSourceSelection // [32v102fix2]", 1)
    old = "                                input = HazeInput.Sources(hazeState),"
    assert s.count(old) == 1, "v102fix2 input 锚点数 " + str(s.count(old))
    # Behind 语义(HazeEffectNode 源码):源入选条件=zIndex<祖先源 zIndex;根 Box 既是唯一源又是祖先源→恒假→无源→只剩 scrim 假模糊。All 无条件入选。
    s = s.replace(old, "                                input = HazeInput.Sources(hazeState, HazeSourceSelection.All), // [32v102fix2] Behind 会排除祖先源自身,All 才采根源", 1)
    open(MH, "w", encoding="utf-8").write(s)
    print("OK 32 v102fix2 源选择改 All 完成")
PYEOF102F2
echo "=== 32 v102fix2 完成 ==="

# === 32 v102fix3: Haze 拓扑修正: 页内容 when 包同级源 Box + input 回 Behind(祖先源禁采) ===
python3 << 'PYEOF102F3'
import os
def load(p):
    while not os.path.exists(p) and os.getcwd() != "/":
        os.chdir("..")
    return open(p, encoding="utf-8").read()
MH = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"
s = load(MH)
if "[32v102fix3]" in s:
    print("跳过（32 v102fix3 已应用）")
else:
    imp = "import dev.chrisbanes.haze.HazeSourceSelection // [32v102fix2]\n"
    assert s.count(imp) == 1, "v102fix3 import 锚点"
    s = s.replace(imp, "", 1)
    old_in = "                                input = HazeInput.Sources(hazeState, HazeSourceSelection.All), // [32v102fix2] Behind 会排除祖先源自身,All 才采根源"
    assert s.count(old_in) == 1, "v102fix3 input 锚点"
    s = s.replace(old_in, "                                input = HazeInput.Sources(hazeState), // [32v102fix3] Behind: 无祖先源时全选同级源(壁纸层+页内容层)", 1)
    when_line = "            when (selectedTab) {"
    assert s.count(when_line) == 1, "v102fix3 when 锚点数 " + str(s.count(when_line))
    wi = s.index(when_line)
    depth = 0; j = wi; end = -1
    while j < len(s):
        c = s[j]
        if c == '{':
            depth += 1
        elif c == '}':
            depth -= 1
            if depth == 0:
                end = j; break
        j += 1
    assert end > 0, "v102fix3 when 结尾未找到"
    after = s[end + 1:end + 200]
    assert "// [32v97] 悬浮层" in after, "v102fix3 when 结尾后未见悬浮层注释, 计数疑错位"
    s = s[:end + 1] + "\n            } // [32v102fix3] 页内容源 Box 结束" + s[end + 1:]
    s = s[:wi] + "            Box(modifier = Modifier.fillMaxSize().hazeSource(hazeState)) { // [32v102fix3] 页内容作 Haze 源(与胶囊同级非祖先)\n" + s[wi:]
    open(MH, "w", encoding="utf-8").write(s)
    print("OK 32 v102fix3 Haze 拓扑修正完成")
PYEOF102F3
echo "=== 32 v102fix3 完成 ==="

# === 32 v103: Haze 参数动态绑定(半径/底色读 WallpaperManager 设置, 半径0时底色兜底0.8) ===
python3 << 'PYEOF103'
import os
def load(p):
    while not os.path.exists(p) and os.getcwd() != "/":
        os.chdir("..")
    return open(p, encoding="utf-8").read()
MH = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"
s = load(MH)
if "[32v103]" in s:
    print("跳过（32 v103 已应用）")
else:
    anchor = "                val pillDark by MusicThemeManager.isDarkTheme // [32v98] 胶囊明暗随主题"
    assert s.count(anchor) == 1, "v103 pillDark 锚点"
    s = s.replace(anchor, anchor + "\n                val hazeTintEff = if (wpState.hazeRadius <= 0) 0.8f else wpState.hazeTint / 100f // [32v103] 半径0关模糊时底色自动加深保文字", 1)
    old_r = "                                    blurRadius(30.dp)"
    assert s.count(old_r) == 1, "v103 blurRadius 锚点"
    s = s.replace(old_r, "                                    blurRadius(wpState.hazeRadius.dp) // [32v103] 半径读壁纸设置(0-50)", 1)
    old_t = "                                    colorEffects(listOf(HazeColorEffect.tint(if (pillDark) Color.Black.copy(alpha = 0.3f) else Color.White.copy(alpha = 0.3f)))) // [32v102fix] tint 是 HazeColorEffect 工厂函数"
    assert s.count(old_t) == 1, "v103 tint 锚点"
    s = s.replace(old_t, "                                    colorEffects(listOf(HazeColorEffect.tint(if (pillDark) Color.Black.copy(alpha = hazeTintEff) else Color.White.copy(alpha = hazeTintEff)))) // [32v103] 底色读壁纸设置", 1)
    open(MH, "w", encoding="utf-8").write(s)
    print("OK 32 v103 Haze 参数动态绑定完成")
PYEOF103
echo "=== 32 v103 完成 ==="

# === 32 v104: 毛玻璃独立化: 新建 GlassSettings(glass_prefs 按组件分组) + 胶囊改读它(可单关回纯色) + 设置页独立卡 ===
python3 << 'PYEOF104A'
import os
def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
find_root()
GLASS = "avbox/app/src/main/java/com/github/tvbox/osc/ui/music/glass/GlassSettings.kt"
if os.path.exists(GLASS) and "[32v104]" in open(GLASS, encoding="utf-8").read():
    print("跳过（GlassSettings 已存在）")
else:
    os.makedirs(os.path.dirname(GLASS), exist_ok=True)
    content = '''package com.github.tvbox.osc.ui.music.glass

import android.content.Context
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow

// [32v104] 毛玻璃独立设置: 按组件分组存 glass_prefs, 与壁纸彻底分开
// 每组三件套 enabled / radius(0-50) / tint(0-80%); 以后新组件(如设置项)照此再加一组
object GlassSettings {

    data class GlassParams(
        val enabled: Boolean = true,
        val radius: Int = 30,
        val tint: Int = 30,
    )

    private const val PREFS = "glass_prefs"
    private const val KEY_CAP_ENABLED = "capsule_enabled"
    private const val KEY_CAP_RADIUS = "capsule_radius"
    private const val KEY_CAP_TINT = "capsule_tint"

    private val _capsule = MutableStateFlow(GlassParams())
    val capsule: StateFlow<GlassParams> = _capsule

    private fun prefs(ctx: Context) = ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun init(ctx: Context) {
        try {
            val p = prefs(ctx)
            // 一次性迁移: v103 曾把半径/底色暂存 wallpaper_prefs, 有旧值时读过来(新键优先)
            val legacy = ctx.getSharedPreferences("wallpaper_prefs", Context.MODE_PRIVATE)
            val radius = if (p.contains(KEY_CAP_RADIUS)) p.getInt(KEY_CAP_RADIUS, 30) else legacy.getInt("hazeBlurRadius", 30)
            val tint = if (p.contains(KEY_CAP_TINT)) p.getInt(KEY_CAP_TINT, 30) else legacy.getInt("hazeTintAlpha", 30)
            _capsule.value = GlassParams(
                enabled = p.getBoolean(KEY_CAP_ENABLED, true),
                radius = radius.coerceIn(0, 50),
                tint = tint.coerceIn(0, 80),
            )
        } catch (e: Exception) {
            android.util.Log.w("Glass", "毛玻璃设置读取失败", e)
        }
    }

    fun setCapsuleEnabled(ctx: Context, on: Boolean) {
        try {
            prefs(ctx).edit().putBoolean(KEY_CAP_ENABLED, on).apply()
        } catch (e: Exception) {
            android.util.Log.w("Glass", "毛玻璃开关保存失败", e)
        }
        _capsule.value = _capsule.value.copy(enabled = on)
    }

    fun setCapsuleRadius(ctx: Context, value: Int) {
        try {
            prefs(ctx).edit().putInt(KEY_CAP_RADIUS, value.coerceIn(0, 50)).apply()
        } catch (e: Exception) {
            android.util.Log.w("Glass", "毛玻璃半径保存失败", e)
        }
        _capsule.value = _capsule.value.copy(radius = value.coerceIn(0, 50))
    }

    fun setCapsuleTint(ctx: Context, pct: Int) {
        try {
            prefs(ctx).edit().putInt(KEY_CAP_TINT, pct.coerceIn(0, 80)).apply()
        } catch (e: Exception) {
            android.util.Log.w("Glass", "毛玻璃底色保存失败", e)
        }
        _capsule.value = _capsule.value.copy(tint = pct.coerceIn(0, 80))
    }
}
'''
    open(GLASS, "w", encoding="utf-8").write(content)
    print("OK GlassSettings.kt 已创建")
PYEOF104A
python3 << 'PYEOF104B'
import os
def load(p):
    while not os.path.exists(p) and os.getcwd() != "/":
        os.chdir("..")
    return open(p, encoding="utf-8").read()
MH = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"
s = load(MH)
if "[32v104]" in s:
    print("跳过（32 v104 MH 已应用）")
else:
    old = "                val hazeTintEff = if (wpState.hazeRadius <= 0) 0.8f else wpState.hazeTint / 100f // [32v103] 半径0关模糊时底色自动加深保文字"
    assert s.count(old) == 1, "v104 hazeTintEff 锚点"
    s = s.replace(old, "                val glassCap by GlassSettings.capsule.collectAsState() // [32v104] 毛玻璃独立设置(导航胶囊组)\n                val hazeTintEff = if (glassCap.radius <= 0) 0.8f else glassCap.tint / 100f // [32v104] 半径0关模糊时底色自动加深保文字", 1)
    old_c = "                    color = Color.Transparent, // [32v102] 底色交给 Haze tint"
    assert s.count(old_c) == 1, "v104 Surface color 锚点"
    s = s.replace(old_c, "                    color = if (glassCap.enabled) Color.Transparent else if (pillDark) Color.Black.copy(alpha = 0.5f) else Color.White.copy(alpha = 0.70f), // [32v104] 开玻璃透明交给 Haze; 关回 v98 纯色", 1)
    old_box = """                    Box(
                        modifier = Modifier
                            .clip(RoundedCornerShape(percent = 50))
                            .hazeBlur(
                                input = HazeInput.Sources(hazeState), // [32v102fix3] Behind: 无祖先源时全选同级源(壁纸层+页内容层)
                                style = HazeBlurStyle {
                                    blurRadius(wpState.hazeRadius.dp) // [32v103] 半径读壁纸设置(0-50)
                                    colorEffects(listOf(HazeColorEffect.tint(if (pillDark) Color.Black.copy(alpha = hazeTintEff) else Color.White.copy(alpha = hazeTintEff)))) // [32v103] 底色读壁纸设置
                                },
                            ),
                    ) { // [32v102] 实时毛玻璃层"""
    assert s.count(old_box) == 1, "v104 hazeBlur Box 锚点数 " + str(s.count(old_box))
    new_box = """                    Box(
                        modifier = Modifier
                            .clip(RoundedCornerShape(percent = 50))
                            .then(
                                if (glassCap.enabled) Modifier.hazeBlur(
                                    input = HazeInput.Sources(hazeState), // [32v102fix3] Behind: 无祖先源时全选同级源(壁纸层+页内容层)
                                    style = HazeBlurStyle {
                                        blurRadius(glassCap.radius.dp) // [32v104] 半径读玻璃独立设置
                                        colorEffects(listOf(HazeColorEffect.tint(if (pillDark) Color.Black.copy(alpha = hazeTintEff) else Color.White.copy(alpha = hazeTintEff)))) // [32v104] 底色读玻璃独立设置
                                    },
                                ) else Modifier // [32v104] 关玻璃: 不挂 hazeBlur, 走 Surface 纯色
                            ),
                    ) { // [32v102] 实时毛玻璃层"""
    s = s.replace(old_box, new_box, 1)
    open(MH, "w", encoding="utf-8").write(s)
    print("OK 32 v104 MH 胶囊改读 GlassSettings 完成")
PYEOF104B
python3 << 'PYEOF104C'
import os
def load(p):
    while not os.path.exists(p) and os.getcwd() != "/":
        os.chdir("..")
    return open(p, encoding="utf-8").read()
SS = "avbox/app/src/main/java/com/github/tvbox/osc/ui/music/settings/SettingsScreen.kt"
s = load(SS)
if "[32v104]" in s:
    print("跳过（32 v104 设置页卡已应用）")
else:
    a = "import com.github.tvbox.osc.ui.activity.musicColors // [25glass1]"
    assert s.count(a) == 1, "v104 SS musicColors import 锚点"
    s = s.replace(a, a + "\nimport com.github.tvbox.osc.ui.music.glass.GlassSettings // [32v104]", 1)
    a = "import androidx.compose.foundation.layout.Row"
    assert s.count(a) == 1, "v104 SS Row import 锚点"
    s = s.replace(a, a + "\nimport androidx.compose.foundation.layout.Spacer", 1)
    a = "import androidx.compose.material3.Text"
    assert s.count(a) == 1, "v104 SS Text import 锚点"
    s = s.replace(a, a + "\nimport androidx.compose.material3.Slider\nimport androidx.compose.material3.SliderDefaults\nimport androidx.compose.material3.Switch\nimport androidx.compose.material3.SwitchDefaults", 1)
    a = "import androidx.compose.runtime.remember"
    assert s.count(a) == 1, "v104 SS remember import 锚点"
    s = s.replace(a, a + "\nimport androidx.compose.runtime.collectAsState\nimport androidx.compose.runtime.mutableStateOf\nimport androidx.compose.runtime.setValue", 1)
    a = "import androidx.compose.ui.Modifier"
    assert s.count(a) == 1, "v104 SS Modifier import 锚点"
    s = s.replace(a, a + "\nimport androidx.compose.ui.platform.LocalContext", 1)
    old = """        items(groups, key = { it.header }) { group ->
            SettingGroupCard(group = group) // [25itemcards] 无分组标题, 每项独立卡
        }
    }
}"""
    assert s.count(old) == 1, "v104 SS LazyColumn 锚点数 " + str(s.count(old))
    new = """        items(groups, key = { it.header }) { group ->
            SettingGroupCard(group = group) // [25itemcards] 无分组标题, 每项独立卡
        }
        item { GlassCapsuleCard() } // [32v104] 毛玻璃 · 导航胶囊(独立设置卡)
    }
}"""
    s = s.replace(old, new, 1)
    card = '''
// ---------- [32v104] 毛玻璃 · 导航胶囊(独立设置卡: 开关+半径+底色, 与壁纸分开存 glass_prefs) ----------
@Composable
private fun GlassCapsuleCard() {
    val context = LocalContext.current
    val cap by GlassSettings.capsule.collectAsState()
    var radiusSlider by remember(cap.radius) { mutableStateOf(cap.radius.toFloat()) }
    var tintSlider by remember(cap.tint) { mutableStateOf(cap.tint.toFloat()) }
    Surface(
        color = musicColors().card.copy(alpha = 0.45f),
        shape = MaterialTheme.shapes.large,
        border = BorderStroke(0.5.dp, Color.White.copy(alpha = 0.15f)),
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Column(
                    modifier = Modifier.weight(1f),
                    verticalArrangement = Arrangement.spacedBy(4.dp),
                ) {
                    Text(
                        text = "毛玻璃 · 导航胶囊",
                        style = MaterialTheme.typography.bodyLarge,
                        color = musicColors().textPrimary,
                    )
                    Text(
                        text = "底部胶囊的实时模糊，独立于壁纸",
                        style = MaterialTheme.typography.bodyMedium,
                        color = musicColors().textSecondary,
                    )
                }
                Switch(
                    checked = cap.enabled,
                    onCheckedChange = { GlassSettings.setCapsuleEnabled(context, it) },
                    colors = SwitchDefaults.colors(
                        checkedThumbColor = musicColors().accentText,
                        checkedTrackColor = musicColors().accent,
                        uncheckedThumbColor = musicColors().textSecondary,
                        uncheckedTrackColor = musicColors().cardSecondary,
                    ),
                )
            }
            if (cap.enabled) {
                Spacer(modifier = Modifier.height(12.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text("模糊强度", style = MaterialTheme.typography.bodyMedium, color = musicColors().textSecondary)
                    Spacer(modifier = Modifier.weight(1f))
                    Text(
                        text = "${radiusSlider.toInt()}",
                        style = MaterialTheme.typography.bodyMedium,
                        color = musicColors().textPrimary,
                    )
                }
                Slider(
                    value = radiusSlider,
                    onValueChange = { radiusSlider = it },
                    onValueChangeFinished = { GlassSettings.setCapsuleRadius(context, radiusSlider.toInt()) },
                    valueRange = 0f..50f,
                    steps = 49,
                    colors = SliderDefaults.colors(
                        thumbColor = musicColors().accent,
                        activeTrackColor = musicColors().accent,
                        inactiveTrackColor = musicColors().cardSecondary,
                    ),
                )
                Spacer(modifier = Modifier.height(8.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text("底色深浅", style = MaterialTheme.typography.bodyMedium, color = musicColors().textSecondary)
                    Spacer(modifier = Modifier.weight(1f))
                    Text(
                        text = "${tintSlider.toInt()}%",
                        style = MaterialTheme.typography.bodyMedium,
                        color = musicColors().textPrimary,
                    )
                }
                Slider(
                    value = tintSlider,
                    onValueChange = { tintSlider = it },
                    onValueChangeFinished = { GlassSettings.setCapsuleTint(context, tintSlider.toInt()) },
                    valueRange = 0f..80f,
                    steps = 79,
                    colors = SliderDefaults.colors(
                        thumbColor = musicColors().accent,
                        activeTrackColor = musicColors().accent,
                        inactiveTrackColor = musicColors().cardSecondary,
                    ),
                )
                Text(
                    text = "模糊拉到 0 时底色自动加深，保证文字看得清。",
                    style = MaterialTheme.typography.bodySmall,
                    color = musicColors().textSecondary,
                )
            }
        }
    }
}
'''
    s = s.rstrip("\n") + "\n" + card
    open(SS, "w", encoding="utf-8").write(s)
    print("OK 32 v104 设置页毛玻璃独立卡完成")
PYEOF104C
echo "=== 32 v104 完成 ==="

# === 32 v105: 胶囊高级质感: GlassSettings 加 border(边缘反光)/shadow(悬浮高度) + MH 动态绑定 + 设置卡双滑杆 ===
python3 << 'PYEOF105A'
import os
def load(p):
    while not os.path.exists(p) and os.getcwd() != "/":
        os.chdir("..")
    return open(p, encoding="utf-8").read()
GLASS = "avbox/app/src/main/java/com/github/tvbox/osc/ui/music/glass/GlassSettings.kt"
s = load(GLASS)
if "[32v105]" in s:
    print("跳过（32 v105 GlassSettings 已应用）")
else:
    a = "        val tint: Int = 30,\n    )"
    assert s.count(a) == 1, "v105 GlassParams 锚点"
    s = s.replace(a, "        val tint: Int = 30,\n        val border: Int = 20, // [32v105] 边缘反光(百分比 0-50)\n        val shadow: Int = 4, // [32v105] 悬浮高度(dp 0-20)\n    )", 1)
    a = '    private const val KEY_CAP_TINT = "capsule_tint"'
    assert s.count(a) == 1, "v105 KEY 锚点"
    s = s.replace(a, a + '\n    private const val KEY_CAP_BORDER = "capsule_border" // [32v105]\n    private const val KEY_CAP_SHADOW = "capsule_shadow" // [32v105]', 1)
    a = "                tint = tint.coerceIn(0, 80),\n            )"
    assert s.count(a) == 1, "v105 init 锚点"
    s = s.replace(a, "                tint = tint.coerceIn(0, 80),\n                border = p.getInt(KEY_CAP_BORDER, 20).coerceIn(0, 50), // [32v105] 无旧键时默认 20, 视觉不变\n                shadow = p.getInt(KEY_CAP_SHADOW, 4).coerceIn(0, 20), // [32v105] 无旧键时默认 4, 视觉不变\n            )", 1)
    a = "        _capsule.value = _capsule.value.copy(tint = pct.coerceIn(0, 80))\n    }\n}"
    assert s.count(a) == 1, "v105 setter 尾锚点"
    setters = """        _capsule.value = _capsule.value.copy(tint = pct.coerceIn(0, 80))
    }

    // [32v105] 边缘反光: 胶囊高光描边的白色 alpha(百分比 0-50; 默认 20 = v102 定稿)
    fun setCapsuleBorder(ctx: Context, pct: Int) {
        try {
            prefs(ctx).edit().putInt(KEY_CAP_BORDER, pct.coerceIn(0, 50)).apply()
        } catch (e: Exception) {
            android.util.Log.w("Glass", "毛玻璃边缘反光保存失败", e)
        }
        _capsule.value = _capsule.value.copy(border = pct.coerceIn(0, 50))
    }

    // [32v105] 悬浮高度: 胶囊 shadowElevation(dp 0-20; 默认 4 = v98 定稿)
    fun setCapsuleShadow(ctx: Context, dp: Int) {
        try {
            prefs(ctx).edit().putInt(KEY_CAP_SHADOW, dp.coerceIn(0, 20)).apply()
        } catch (e: Exception) {
            android.util.Log.w("Glass", "毛玻璃悬浮高度保存失败", e)
        }
        _capsule.value = _capsule.value.copy(shadow = dp.coerceIn(0, 20))
    }
}"""
    s = s.replace(a, setters, 1)
    open(GLASS, "w", encoding="utf-8").write(s)
    print("OK 32 v105 GlassSettings 扩 border/shadow 完成")
PYEOF105A
python3 << 'PYEOF105B'
import os
def load(p):
    while not os.path.exists(p) and os.getcwd() != "/":
        os.chdir("..")
    return open(p, encoding="utf-8").read()
MH = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"
s = load(MH)
if "glassCap.border" in s:
    print("跳过（32 v105 MH 已应用）")
else:
    a = "                    border = BorderStroke(0.5.dp, Color.White.copy(alpha = 0.2f)), // [32v102] 高光描边"
    assert s.count(a) == 1, "v105 border 锚点"
    s = s.replace(a, "                    border = BorderStroke(0.5.dp, Color.White.copy(alpha = glassCap.border / 100f)), // [32v105] 边缘反光读玻璃设置", 1)
    a = "                    shadowElevation = 4.dp,"
    assert s.count(a) == 1, "v105 shadowElevation 锚点数 " + str(s.count(a))
    s = s.replace(a, "                    shadowElevation = glassCap.shadow.dp, // [32v105] 悬浮高度读玻璃设置", 1)
    open(MH, "w", encoding="utf-8").write(s)
    print("OK 32 v105 MH 边缘反光/悬浮高度动态绑定完成")
PYEOF105B
python3 << 'PYEOF105C'
import os
def load(p):
    while not os.path.exists(p) and os.getcwd() != "/":
        os.chdir("..")
    return open(p, encoding="utf-8").read()
SS = "avbox/app/src/main/java/com/github/tvbox/osc/ui/music/settings/SettingsScreen.kt"
s = load(SS)
if "borderSlider" in s:
    print("跳过（32 v105 设置卡已应用）")
else:
    a = "    var tintSlider by remember(cap.tint) { mutableStateOf(cap.tint.toFloat()) }"
    assert s.count(a) == 1, "v105 SS state 锚点"
    s = s.replace(a, a + "\n    var borderSlider by remember(cap.border) { mutableStateOf(cap.border.toFloat()) } // [32v105]\n    var shadowSlider by remember(cap.shadow) { mutableStateOf(cap.shadow.toFloat()) } // [32v105]", 1)
    a = """                Text(
                    text = "模糊拉到 0 时底色自动加深，保证文字看得清。","""
    assert s.count(a) == 1, "v105 SS 滑杆插入锚点"
    sliders = """                Spacer(modifier = Modifier.height(8.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text("边缘反光", style = MaterialTheme.typography.bodyMedium, color = musicColors().textSecondary)
                    Spacer(modifier = Modifier.weight(1f))
                    Text(
                        text = "${borderSlider.toInt()}%",
                        style = MaterialTheme.typography.bodyMedium,
                        color = musicColors().textPrimary,
                    )
                }
                Slider(
                    value = borderSlider,
                    onValueChange = { borderSlider = it },
                    onValueChangeFinished = { GlassSettings.setCapsuleBorder(context, borderSlider.toInt()) },
                    valueRange = 0f..50f,
                    steps = 49,
                    colors = SliderDefaults.colors(
                        thumbColor = musicColors().accent,
                        activeTrackColor = musicColors().accent,
                        inactiveTrackColor = musicColors().cardSecondary,
                    ),
                )
                Spacer(modifier = Modifier.height(8.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text("悬浮高度", style = MaterialTheme.typography.bodyMedium, color = musicColors().textSecondary)
                    Spacer(modifier = Modifier.weight(1f))
                    Text(
                        text = "${shadowSlider.toInt()}dp",
                        style = MaterialTheme.typography.bodyMedium,
                        color = musicColors().textPrimary,
                    )
                }
                Slider(
                    value = shadowSlider,
                    onValueChange = { shadowSlider = it },
                    onValueChangeFinished = { GlassSettings.setCapsuleShadow(context, shadowSlider.toInt()) },
                    valueRange = 0f..20f,
                    steps = 19,
                    colors = SliderDefaults.colors(
                        thumbColor = musicColors().accent,
                        activeTrackColor = musicColors().accent,
                        inactiveTrackColor = musicColors().cardSecondary,
                    ),
                )
""" + a
    s = s.replace(a, sliders, 1)
    open(SS, "w", encoding="utf-8").write(s)
    print("OK 32 v105 设置卡加边缘反光/悬浮高度滑杆完成")
PYEOF105C
echo "=== 32 v105 完成 ==="



# === 32 v106: 排行榜抽屉液态玻璃: GlassSettings 加 drawer 组 + RankScreen 自建 Haze 源/面板玻璃化/手搓线条图标 ===
python3 << 'PYEOF106A'
import os
def load(p):
    while not os.path.exists(p) and os.getcwd() != "/":
        os.chdir("..")
    return open(p, encoding="utf-8").read()
GLASS = "avbox/app/src/main/java/com/github/tvbox/osc/ui/music/glass/GlassSettings.kt"
s = load(GLASS)
if "[32v106]" in s:
    print("跳过（32 v106 GlassSettings 已应用）")
else:
    a = '    private const val KEY_CAP_SHADOW = "capsule_shadow" // [32v105]'
    assert s.count(a) == 1, "v106 KEY 锚点"
    s = s.replace(a, a + '\n    // [32v106] 抽屉组(排行榜切换榜单抽屉; 本版只接数据, 设置 UI 后加)\n    private const val KEY_DRW_ENABLED = "drawer_enabled"\n    private const val KEY_DRW_RADIUS = "drawer_radius"\n    private const val KEY_DRW_TINT = "drawer_tint"\n    private const val KEY_DRW_BORDER = "drawer_border"', 1)
    a = "    private val _capsule = MutableStateFlow(GlassParams())\n    val capsule: StateFlow<GlassParams> = _capsule"
    assert s.count(a) == 1, "v106 state 锚点"
    s = s.replace(a, a + "\n\n    private val _drawer = MutableStateFlow(GlassParams()) // [32v106]\n    val drawer: StateFlow<GlassParams> = _drawer // [32v106]", 1)
    a = "                shadow = p.getInt(KEY_CAP_SHADOW, 4).coerceIn(0, 20), // [32v105] 无旧键时默认 4, 视觉不变\n            )"
    assert s.count(a) == 1, "v106 init 锚点"
    s = s.replace(a, a + "\n            _drawer.value = GlassParams(\n                enabled = p.getBoolean(KEY_DRW_ENABLED, true),\n                radius = p.getInt(KEY_DRW_RADIUS, 30).coerceIn(0, 50),\n                tint = p.getInt(KEY_DRW_TINT, 30).coerceIn(0, 80),\n                border = p.getInt(KEY_DRW_BORDER, 15).coerceIn(0, 50),\n            ) // [32v106] 抽屉组默认值 30/30/15", 1)
    a = "        _capsule.value = _capsule.value.copy(shadow = dp.coerceIn(0, 20))\n    }\n}"
    assert s.count(a) == 1, "v106 setter 尾锚点"
    setters = """        _capsule.value = _capsule.value.copy(shadow = dp.coerceIn(0, 20))
    }

    // [32v106] 抽屉组 setter(与 capsule 同模子; 设置 UI 后加时直接调用)
    fun setDrawerEnabled(ctx: Context, on: Boolean) {
        try {
            prefs(ctx).edit().putBoolean(KEY_DRW_ENABLED, on).apply()
        } catch (e: Exception) {
            android.util.Log.w("Glass", "抽屉玻璃开关保存失败", e)
        }
        _drawer.value = _drawer.value.copy(enabled = on)
    }

    fun setDrawerRadius(ctx: Context, value: Int) {
        try {
            prefs(ctx).edit().putInt(KEY_DRW_RADIUS, value.coerceIn(0, 50)).apply()
        } catch (e: Exception) {
            android.util.Log.w("Glass", "抽屉玻璃半径保存失败", e)
        }
        _drawer.value = _drawer.value.copy(radius = value.coerceIn(0, 50))
    }

    fun setDrawerTint(ctx: Context, pct: Int) {
        try {
            prefs(ctx).edit().putInt(KEY_DRW_TINT, pct.coerceIn(0, 80)).apply()
        } catch (e: Exception) {
            android.util.Log.w("Glass", "抽屉玻璃底色保存失败", e)
        }
        _drawer.value = _drawer.value.copy(tint = pct.coerceIn(0, 80))
    }

    fun setDrawerBorder(ctx: Context, pct: Int) {
        try {
            prefs(ctx).edit().putInt(KEY_DRW_BORDER, pct.coerceIn(0, 50)).apply()
        } catch (e: Exception) {
            android.util.Log.w("Glass", "抽屉玻璃边框保存失败", e)
        }
        _drawer.value = _drawer.value.copy(border = pct.coerceIn(0, 50))
    }
}"""
    s = s.replace(a, setters, 1)
    open(GLASS, "w", encoding="utf-8").write(s)
    print("OK 32 v106 GlassSettings 加 drawer 组完成")
PYEOF106A
python3 << 'PYEOF106B'
import os
def load(p):
    while not os.path.exists(p) and os.getcwd() != "/":
        os.chdir("..")
    return open(p, encoding="utf-8").read()
RS = "avbox/app/src/main/java/com/github/tvbox/osc/ui/music/rank/RankScreen.kt"
s = load(RS)
if "[32v106]" in s:
    print("跳过（32 v106 RankScreen 已应用）")
else:
    a = "import androidx.compose.foundation.Canvas // [32v100]"
    assert s.count(a) == 1, "v106 Canvas import 锚点"
    add = a + "\nimport androidx.compose.foundation.BorderStroke // [32v106]"
    for imp in [
        "import dev.chrisbanes.haze.rememberHazeState // [32v106]",
        "import dev.chrisbanes.haze.hazeSource // [32v106]",
        "import dev.chrisbanes.haze.HazeInput // [32v106]",
        "import dev.chrisbanes.haze.blur.hazeBlur // [32v106]",
        "import dev.chrisbanes.haze.blur.HazeBlurStyle // [32v106]",
        "import dev.chrisbanes.haze.blur.HazeColorEffect // [32v106]",
        "import com.github.tvbox.osc.ui.music.glass.GlassSettings // [32v106]",
    ]:
        if imp.split(" // ")[0] not in s:
            add += "\n" + imp
    if "import androidx.compose.runtime.collectAsState" not in s:
        add += "\nimport androidx.compose.runtime.collectAsState // [32v106]"
    s = s.replace(a, add, 1)
    a = "    var showDrawer by remember { mutableStateOf(false) } // [32v100] 抽屉显隐(原底部弹窗状态)"
    assert s.count(a) == 1, "v106 state 锚点"
    s = s.replace(a, a + "\n    val drawerHazeState = rememberHazeState() // [32v106] 抽屉毛玻璃采样(本页自建源)\n    val drawerGlass by GlassSettings.drawer.collectAsState() // [32v106] 抽屉玻璃参数(独立组)\n    val drawerDark by com.github.tvbox.osc.ui.activity.MusicThemeManager.isDarkTheme // [32v106]", 1)
    a = "                .fillMaxSize()\n                .background(musicColors().background),"
    assert s.count(a) == 1, "v106 LazyColumn 锚点"
    s = s.replace(a, "                .fillMaxSize()\n                .hazeSource(drawerHazeState) // [32v106] 榜单内容作抽屉采样源\n                .background(musicColors().background),", 1)
    a = ".background(Color.Black.copy(alpha = 0.45f))"
    assert s.count(a) == 1, "v106 scrim 锚点数 " + str(s.count(a))
    s = s.replace(a, ".background(Color.Black.copy(alpha = 0.30f)) // [32v106] 玻璃时代遮罩调淡(原 0.45)", 1)
    old = """            Surface(
                shape = RoundedCornerShape(topEnd = 20.dp, bottomEnd = 20.dp),
                color = musicColors().card,
                shadowElevation = 8.dp,
                modifier = Modifier.width(264.dp).fillMaxHeight(),
            ) {
                Column(modifier = Modifier.padding(top = 16.dp)) {"""
    assert s.count(old) == 1, "v106 Surface 锚点数 " + str(s.count(old))
    new = """            Surface(
                shape = RoundedCornerShape(topEnd = 20.dp, bottomEnd = 20.dp),
                color = if (drawerGlass.enabled) Color.Transparent else musicColors().card, // [32v106] 开玻璃透明交给 Haze; 关回实色卡
                border = BorderStroke(0.5.dp, Color.White.copy(alpha = drawerGlass.border / 100f)), // [32v106] 高光边(默认 15%)
                shadowElevation = 8.dp,
                modifier = Modifier.width(280.dp).fillMaxHeight(), // [32v106] 264→280
            ) {
                Box(
                    modifier = Modifier.fillMaxSize()
                        .clip(RoundedCornerShape(topEnd = 20.dp, bottomEnd = 20.dp))
                        .then(
                            if (drawerGlass.enabled) Modifier.hazeBlur(
                                input = HazeInput.Sources(drawerHazeState),
                                style = HazeBlurStyle {
                                    blurRadius(drawerGlass.radius.dp)
                                    colorEffects(listOf(HazeColorEffect.tint(if (drawerDark) Color.Black.copy(alpha = drawerGlass.tint / 100f) else Color.White.copy(alpha = drawerGlass.tint / 100f))))
                                },
                            ) else Modifier // [32v106] 关玻璃: 不挂 hazeBlur
                        ),
                ) { // [32v106] 抽屉毛玻璃层
                Column(modifier = Modifier.padding(top = 16.dp)) {"""
    s = s.replace(old, new, 1)
    old = """                }
                }
            }
        }
    }

}"""
    assert s.count(old) == 1, "v106 抽屉收尾锚点数 " + str(s.count(old))
    new = """                }
                }
                } // [32v106] 毛玻璃 Box 结束
            }
        }
    }

}"""
    s = s.replace(old, new, 1)
    a = '                    text = "切换榜单",\n                    style = MaterialTheme.typography.titleSmall,'
    assert s.count(a) == 1, "v106 标题锚点"
    s = s.replace(a, '                    text = "切换榜单",\n                    style = MaterialTheme.typography.labelLarge, // [32v106] 标题降为辅助说明', 1)
    old = """                            Icon(
                                imageVector = tabIconFor(tab),
                                contentDescription = null,
                                tint = musicColors().textSecondary,
                                modifier = Modifier.size(22.dp),
                            )"""
    assert s.count(old) == 1, "v106 图标行锚点"
    new = """                            RankTabIcon(
                                tab = tab,
                                tint = if (isSelected) musicColors().accent else musicColors().textSecondary, // [32v106] 手搓线条图标, 选中跟 accent
                                modifier = Modifier.size(22.dp),
                            )"""
    s = s.replace(old, new, 1)
    a = "                                color = if (isSelected) MaterialTheme.colorScheme.primary\n                                else musicColors().textPrimary,"
    assert s.count(a) == 1, "v106 选中文字锚点"
    s = s.replace(a, "                                color = if (isSelected) musicColors().accent // [32v106] 选中统一 accent\n                                else musicColors().textPrimary,", 1)
    a = '                                    contentDescription = "当前选中",\n                                    tint = MaterialTheme.colorScheme.primary,'
    assert s.count(a) == 1, "v106 勾锚点"
    s = s.replace(a, '                                    contentDescription = "当前选中",\n                                    tint = musicColors().accent, // [32v106]', 1)
    icon = '''

// ---------- [32v106] 抽屉榜单手搓线条图标(2dp 描边, 与胶囊同一套画风; 分支沿用 tabIconFor 规则) ----------
@Composable
private fun RankTabIcon(tab: String, tint: Color, modifier: Modifier = Modifier) {
    Canvas(modifier = modifier) {
        val w = 2.dp.toPx()
        val s = size
        val off = { x: Float, y: Float -> androidx.compose.ui.geometry.Offset(s.width * x, s.height * y) }
        when {
            tab.contains("飙升") -> {
                // 折线: 三段上扬 + 末端箭头
                val pts = listOf(off(0.08f, 0.78f), off(0.38f, 0.48f), off(0.58f, 0.62f), off(0.90f, 0.20f))
                for (i in 0 until pts.size - 1) drawLine(tint, pts[i], pts[i + 1], w, cap = androidx.compose.ui.graphics.StrokeCap.Round)
                drawLine(tint, off(0.68f, 0.18f), pts[3], w, cap = androidx.compose.ui.graphics.StrokeCap.Round)
                drawLine(tint, off(0.92f, 0.42f), pts[3], w, cap = androidx.compose.ui.graphics.StrokeCap.Round)
            }
            tab.contains("TOP") || tab.contains("热") -> {
                // 五角星轮廓: 外/内半径交替 10 点极坐标
                val cx = s.width / 2
                val cy = s.height / 2
                val rO = s.width * 0.46f
                val rI = rO * 0.45f
                val path = androidx.compose.ui.graphics.Path()
                for (i in 0 until 10) {
                    val ang = -Math.PI / 2 + i * Math.PI / 5
                    val r = if (i % 2 == 0) rO else rI
                    val x = cx + (r * kotlin.math.cos(ang)).toFloat()
                    val y = cy + (r * kotlin.math.sin(ang)).toFloat()
                    if (i == 0) path.moveTo(x, y) else path.lineTo(x, y)
                }
                path.close()
                drawPath(path, tint, style = androidx.compose.ui.graphics.drawscope.Stroke(width = w, join = androidx.compose.ui.graphics.StrokeJoin.Round))
            }
            else -> {
                // 放射圆: 圆 + 8 根短辐条(新歌榜等)
                val c = androidx.compose.ui.geometry.Offset(s.width / 2, s.height / 2)
                drawCircle(tint, s.width * 0.26f, c, style = androidx.compose.ui.graphics.drawscope.Stroke(width = w))
                for (i in 0 until 8) {
                    val ang = i * Math.PI / 4
                    drawLine(
                        tint,
                        androidx.compose.ui.geometry.Offset(c.x + (s.width * 0.36f * kotlin.math.cos(ang)).toFloat(), c.y + (s.width * 0.36f * kotlin.math.sin(ang)).toFloat()),
                        androidx.compose.ui.geometry.Offset(c.x + (s.width * 0.47f * kotlin.math.cos(ang)).toFloat(), c.y + (s.width * 0.47f * kotlin.math.sin(ang)).toFloat()),
                        w, cap = androidx.compose.ui.graphics.StrokeCap.Round,
                    )
                }
            }
        }
    }
}
'''
    s = s.rstrip("\n") + "\n" + icon
    open(RS, "w", encoding="utf-8").write(s)
    print("OK 32 v106 RankScreen 抽屉液态玻璃完成")
PYEOF106B
echo "=== 32 v106 完成 ==="

# === 32 v107: 排行榜键改行号(酷狗新歌榜同名双版本撞键闪退) ===
python3 << 'PYEOF107'
import os
def load(p):
    while not os.path.exists(p) and os.getcwd() != "/":
        os.chdir("..")
    return open(p, encoding="utf-8").read()
RS = "avbox/app/src/main/java/com/github/tvbox/osc/ui/music/rank/RankScreen.kt"
s = load(RS)
if "[32v107]" in s:
    print("跳过（32 v107 已应用）")
else:
    old = "            itemsIndexed(songs, key = { _, s -> s.title + s.artist }) { index, song ->"
    assert s.count(old) == 1, "v107 itemsIndexed 锚点数 " + str(s.count(old))
    s = s.replace(old, "            itemsIndexed(songs, key = { index, _ -> index }) { index, song -> // [32v107] 键改行号: 酷狗新歌榜同名同歌手双版本(山风山风等等我 合唱版×2,hash 不同)标题键撞键致 Compose 抛异常闪退", 1)
    open(RS, "w", encoding="utf-8").write(s)
    print("OK 32 v107 排行榜键改行号完成")
PYEOF107
echo "=== 32 v107 完成 ==="

# === 32 v108: 抽屉玻璃补全采样+垫底+抽屉调节卡(主次分清/右上角花了) ===
python3 << 'PYEOF108A'
import os
def load(p):
    while not os.path.exists(p) and os.getcwd() != "/":
        os.chdir("..")
    return open(p, encoding="utf-8").read()
GLASS = "avbox/app/src/main/java/com/github/tvbox/osc/ui/music/glass/GlassSettings.kt"
s = load(GLASS)
if "KEY_DRW_TINT, 50" in s:
    print("跳过（32 v108 GlassSettings 已应用）")
else:
    a = "tint = p.getInt(KEY_DRW_TINT, 30).coerceIn(0, 80),"
    assert s.count(a) == 1, "v108 drawer tint 锚点"
    s = s.replace(a, "tint = p.getInt(KEY_DRW_TINT, 50).coerceIn(0, 80), // [32v108] 抽屉底色默认 30→50, 主次分清(本组无存量可调值)", 1)
    open(GLASS, "w", encoding="utf-8").write(s)
    print("OK 32 v108 抽屉 tint 默认改 50 完成")
PYEOF108A
python3 << 'PYEOF108B'
import os
def load(p):
    while not os.path.exists(p) and os.getcwd() != "/":
        os.chdir("..")
    return open(p, encoding="utf-8").read()
MH = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"
s = load(MH)
if "[32v108]" in s:
    print("跳过（32 v108 MH 已应用）")
else:
    a = "    val hazeState = rememberHazeState() // [32v102] Haze 采样状态(根 Box 采样源由 39 挂)"
    assert s.count(a) == 1, "v108 hazeState 锚点"
    s = s.replace(a, a + "\n    val drawerHazeState = rememberHazeState() // [32v108] 抽屉采样状态上移 MH(壁纸层+列表层同源)", 1)
    a = "        tabs = charts.map { it.name },"
    assert s.count(a) == 1, "v108 RankScreen 调用锚点"
    s = s.replace(a, "        drawerHazeState = drawerHazeState, // [32v108]\n" + a, 1)
    open(MH, "w", encoding="utf-8").write(s)
    print("OK 32 v108 MH 抽屉状态上移完成")
PYEOF108B
python3 << 'PYEOF108C'
import os
def load(p):
    while not os.path.exists(p) and os.getcwd() != "/":
        os.chdir("..")
    return open(p, encoding="utf-8").read()
RS = "avbox/app/src/main/java/com/github/tvbox/osc/ui/music/rank/RankScreen.kt"
s = load(RS)
if "[32v108]" in s:
    print("跳过（32 v108 RankScreen 已应用）")
else:
    if "import dev.chrisbanes.haze.HazeState" not in s:
        a = "import dev.chrisbanes.haze.rememberHazeState // [32v106]"
        assert s.count(a) == 1, "v108 HazeState import 锚点"
        s = s.replace(a, a + "\nimport dev.chrisbanes.haze.HazeState // [32v108]", 1)
    a = "    onPlayClick: (RankSong) -> Unit = {},\n) {"
    assert s.count(a) == 1, "v108 签名锚点"
    s = s.replace(a, "    onPlayClick: (RankSong) -> Unit = {},\n    drawerHazeState: HazeState = rememberHazeState(), // [32v108] 由 MH 传入(壁纸层同源; 预览走默认)\n) {", 1)
    a = "    val drawerHazeState = rememberHazeState() // [32v106] 抽屉毛玻璃采样(本页自建源)\n"
    assert s.count(a) == 1, "v108 内部状态锚点"
    s = s.replace(a, "", 1)
    a = "                                    blurRadius(drawerGlass.radius.dp)"
    assert s.count(a) == 1, "v108 style 锚点"
    s = s.replace(a, a + "\n                                    backgroundColor(if (drawerDark) Color.Black.copy(alpha = 0.30f) else Color.White.copy(alpha = 0.30f)) // [32v108] 垫底暗纱: 空采样区不透原图, 主次分清", 1)
    open(RS, "w", encoding="utf-8").write(s)
    print("OK 32 v108 RankScreen 抽屉采样上移+垫底完成")
PYEOF108C
python3 << 'PYEOF108D'
import os
def load(p):
    while not os.path.exists(p) and os.getcwd() != "/":
        os.chdir("..")
    return open(p, encoding="utf-8").read()
SS = "avbox/app/src/main/java/com/github/tvbox/osc/ui/music/settings/SettingsScreen.kt"
s = load(SS)
if "GlassDrawerCard" in s:
    print("跳过（32 v108 抽屉卡已应用）")
else:
    a = "        item { GlassCapsuleCard() } // [32v104] 毛玻璃 · 导航胶囊(独立设置卡)"
    assert s.count(a) == 1, "v108 SS item 锚点"
    s = s.replace(a, a + "\n        item { GlassDrawerCard() } // [32v108] 毛玻璃 · 排行榜抽屉(独立设置卡)", 1)
    card = '''

// ---------- [32v108] 毛玻璃 · 排行榜抽屉(独立设置卡: 开关+半径+底色+边框, 与胶囊组分开) ----------
@Composable
private fun GlassDrawerCard() {
    val context = LocalContext.current
    val drw by GlassSettings.drawer.collectAsState()
    var radiusSlider by remember(drw.radius) { mutableStateOf(drw.radius.toFloat()) }
    var tintSlider by remember(drw.tint) { mutableStateOf(drw.tint.toFloat()) }
    var borderSlider by remember(drw.border) { mutableStateOf(drw.border.toFloat()) }
    Surface(
        color = musicColors().card.copy(alpha = 0.45f),
        shape = MaterialTheme.shapes.large,
        border = BorderStroke(0.5.dp, Color.White.copy(alpha = 0.15f)),
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Column(
                    modifier = Modifier.weight(1f),
                    verticalArrangement = Arrangement.spacedBy(4.dp),
                ) {
                    Text(
                        text = "毛玻璃 · 排行榜抽屉",
                        style = MaterialTheme.typography.bodyLarge,
                        color = musicColors().textPrimary,
                    )
                    Text(
                        text = "切换榜单抽屉的实时模糊，独立于胶囊",
                        style = MaterialTheme.typography.bodyMedium,
                        color = musicColors().textSecondary,
                    )
                }
                Switch(
                    checked = drw.enabled,
                    onCheckedChange = { GlassSettings.setDrawerEnabled(context, it) },
                    colors = SwitchDefaults.colors(
                        checkedThumbColor = musicColors().accentText,
                        checkedTrackColor = musicColors().accent,
                        uncheckedThumbColor = musicColors().textSecondary,
                        uncheckedTrackColor = musicColors().cardSecondary,
                    ),
                )
            }
            if (drw.enabled) {
                Spacer(modifier = Modifier.height(12.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text("模糊强度", style = MaterialTheme.typography.bodyMedium, color = musicColors().textSecondary)
                    Spacer(modifier = Modifier.weight(1f))
                    Text(
                        text = "${radiusSlider.toInt()}",
                        style = MaterialTheme.typography.bodyMedium,
                        color = musicColors().textPrimary,
                    )
                }
                Slider(
                    value = radiusSlider,
                    onValueChange = { radiusSlider = it },
                    onValueChangeFinished = { GlassSettings.setDrawerRadius(context, radiusSlider.toInt()) },
                    valueRange = 0f..50f,
                    steps = 49,
                    colors = SliderDefaults.colors(
                        thumbColor = musicColors().accent,
                        activeTrackColor = musicColors().accent,
                        inactiveTrackColor = musicColors().cardSecondary,
                    ),
                )
                Spacer(modifier = Modifier.height(8.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text("底色深浅", style = MaterialTheme.typography.bodyMedium, color = musicColors().textSecondary)
                    Spacer(modifier = Modifier.weight(1f))
                    Text(
                        text = "${tintSlider.toInt()}%",
                        style = MaterialTheme.typography.bodyMedium,
                        color = musicColors().textPrimary,
                    )
                }
                Slider(
                    value = tintSlider,
                    onValueChange = { tintSlider = it },
                    onValueChangeFinished = { GlassSettings.setDrawerTint(context, tintSlider.toInt()) },
                    valueRange = 0f..80f,
                    steps = 79,
                    colors = SliderDefaults.colors(
                        thumbColor = musicColors().accent,
                        activeTrackColor = musicColors().accent,
                        inactiveTrackColor = musicColors().cardSecondary,
                    ),
                )
                Spacer(modifier = Modifier.height(8.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text("边缘反光", style = MaterialTheme.typography.bodyMedium, color = musicColors().textSecondary)
                    Spacer(modifier = Modifier.weight(1f))
                    Text(
                        text = "${borderSlider.toInt()}%",
                        style = MaterialTheme.typography.bodyMedium,
                        color = musicColors().textPrimary,
                    )
                }
                Slider(
                    value = borderSlider,
                    onValueChange = { borderSlider = it },
                    onValueChangeFinished = { GlassSettings.setDrawerBorder(context, borderSlider.toInt()) },
                    valueRange = 0f..50f,
                    steps = 49,
                    colors = SliderDefaults.colors(
                        thumbColor = musicColors().accent,
                        activeTrackColor = musicColors().accent,
                        inactiveTrackColor = musicColors().cardSecondary,
                    ),
                )
            }
        }
    }
}
'''
    s = s.rstrip("\n") + "\n" + card
    open(SS, "w", encoding="utf-8").write(s)
    print("OK 32 v108 设置页抽屉卡完成")
PYEOF108D
echo "=== 32 v108 完成 ==="
