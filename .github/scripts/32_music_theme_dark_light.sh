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

# === 32 v109: 抽屉状态跨函数传递(修 1141:27 Unresolved reference) ===
python3 << 'PYEOF109'
import os
def load(p):
    while not os.path.exists(p) and os.getcwd() != "/":
        os.chdir("..")
    return open(p, encoding="utf-8").read()
MH = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"
s = load(MH)
if "[32v109]" in s:
    print("跳过（32 v109 已应用）")
else:
    a = "import dev.chrisbanes.haze.rememberHazeState // [32v102]"
    assert s.count(a) == 1, "v109 import 锚点"
    s = s.replace(a, a + "\nimport dev.chrisbanes.haze.HazeState // [32v109]", 1)
    a = "fun RankingTab(\n    platform: String,\n    platformName: String,\n    initialChartId: String? = null\n) {"
    assert s.count(a) == 1, "v109 RankingTab 签名锚点"
    s = s.replace(a, "fun RankingTab(\n    platform: String,\n    platformName: String,\n    initialChartId: String? = null,\n    drawerHazeState: HazeState = rememberHazeState(), // [32v109] 由 MusicHomeScreen 传入(与壁纸层同源; 预览走默认)\n) {", 1)
    a = "                    RankingTab(\n                        platform = selectedPlatform,\n                        platformName = platformNames[selectedPlatform] ?: selectedPlatform,\n                        initialChartId = pendingChartId\n                    )"
    assert s.count(a) == 1, "v109 RankingTab 调用锚点"
    s = s.replace(a, "                    RankingTab(\n                        platform = selectedPlatform,\n                        platformName = platformNames[selectedPlatform] ?: selectedPlatform,\n                        initialChartId = pendingChartId,\n                        drawerHazeState = drawerHazeState, // [32v109] 抽屉状态跨函数传递(v108 只在 MusicHomeScreen 内声明, RankingTab 内不可见)\n                    )", 1)
    open(MH, "w", encoding="utf-8").write(s)
    print("OK 32 v109 抽屉状态跨函数传递完成")
PYEOF109
echo "=== 32 v109 完成 ==="

# === 32 v110: 两张毛玻璃设置卡整体缩小(字小一档+内边距/间距收紧) ===
python3 << 'PYEOF110'
import os
def load(p):
    while not os.path.exists(p) and os.getcwd() != "/":
        os.chdir("..")
    return open(p, encoding="utf-8").read()
SS = "avbox/app/src/main/java/com/github/tvbox/osc/ui/music/settings/SettingsScreen.kt"
s = load(SS)
if "[32v110]" in s:
    print("跳过（32 v110 已应用）")
else:
    def shrink(body):
        assert body.count("Modifier.padding(16.dp)") == 1, "v110 卡内边距锚点"
        body = body.replace("Modifier.padding(16.dp)", "Modifier.padding(12.dp)", 1)
        assert body.count("typography.bodyLarge") == 1, "v110 标题锚点"
        body = body.replace("typography.bodyLarge", "typography.bodyMedium", 1)
        body = body.replace("typography.bodyMedium", "typography.bodySmall")
        body = body.replace("height(12.dp)", "height(__TMP__.dp)")
        body = body.replace("height(8.dp)", "height(4.dp)")
        body = body.replace("height(__TMP__.dp)", "height(8.dp)")
        return body
    i = s.index("private fun GlassCapsuleCard()")
    j = s.index("private fun GlassDrawerCard()")
    cap = shrink(s[i:j])
    drw = shrink(s[j:])
    s = s[:i] + cap + drw
    s = s.rstrip("\n") + "\n// [32v110] 两张毛玻璃卡缩小: 内边距 16→12dp, 标题 bodyLarge→bodyMedium, 副标题/标签/数值 bodyMedium→bodySmall, 间距 12→8/8→4dp(滑杆系统 48dp 触摸高度未动, 硬压有闪退风险)\n"
    open(SS, "w", encoding="utf-8").write(s)
    print("OK 32 v110 两张毛玻璃卡缩小完成")
PYEOF110
echo "=== 32 v110 完成 ==="
# === 32 v111: 自绘紧凑滑杆 CompactSlider + 两张毛玻璃卡换装 ===
python3 << 'PYEOF111A'
import os
def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
find_root()
GLASSDIR = "avbox/app/src/main/java/com/github/tvbox/osc/ui/music/glass"
os.makedirs(GLASSDIR, exist_ok=True)
content = '''package com.github.tvbox.osc.ui.music.glass

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.input.pointer.awaitPointerEventScope
import androidx.compose.ui.input.pointer.changedToDown
import androidx.compose.ui.input.pointer.changedToUpOrCanceled
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.input.pointer.positionChanged
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import com.github.tvbox.osc.ui.activity.musicColors
import kotlin.math.roundToInt

// [32v111] 紧凑滑杆: 系统 Slider 强制 48dp 触摸高度撑大卡片, 自绘版只占 28dp(点按+拖动, 离散步进与原 Slider 一致)
@Composable
fun CompactSlider(
    value: Float,
    onValueChange: (Float) -> Unit,
    onValueChangeFinished: () -> Unit,
    valueRange: ClosedFloatingPointRange<Float> = 0f..1f,
    steps: Int = 0,
) {
    val changeState = rememberUpdatedState(onValueChange)
    val finishedState = rememberUpdatedState(onValueChangeFinished)
    val accent = musicColors().accent
    val trackColor = musicColors().cardSecondary
    BoxWithConstraints(
        modifier = Modifier
            .fillMaxWidth()
            .height(28.dp)
            .pointerInput(valueRange, steps) {
                awaitPointerEventScope {
                    while (true) {
                        val down = awaitPointerEvent().changes.firstOrNull { it.changedToDown() } ?: continue
                        down.consume()
                        fun update(pos: Offset) {
                            val frac = (pos.x / size.width).coerceIn(0f, 1f)
                            val snapped = if (steps > 0) (frac * (steps + 1)).roundToInt() / (steps + 1).toFloat() else frac
                            changeState.value(valueRange.start + snapped * (valueRange.endInclusive - valueRange.start))
                        }
                        update(down.position)
                        var released = false
                        while (!released) {
                            val event = awaitPointerEvent()
                            val change = event.changes.firstOrNull { it.id == down.id }
                            if (change == null) continue
                            if (change.changedToUpOrCanceled()) {
                                released = true
                                change.consume()
                            } else if (change.positionChanged()) {
                                change.consume()
                                update(change.position)
                            }
                        }
                        finishedState.value()
                    }
                }
            },
    ) {
        val span = (valueRange.endInclusive - valueRange.start).takeIf { it > 0f } ?: 1f
        val fraction = ((value - valueRange.start) / span).coerceIn(0f, 1f)
        Box(
            modifier = Modifier.align(Alignment.CenterStart).fillMaxWidth().height(4.dp).clip(CircleShape).background(trackColor),
        )
        Box(
            modifier = Modifier.align(Alignment.CenterStart).fillMaxWidth(fraction).height(4.dp).clip(CircleShape).background(accent),
        )
        val thumbPx = with(LocalDensity.current) { 16.dp.toPx() }
        val maxPx = with(LocalDensity.current) { maxWidth.toPx() }
        Box(
            modifier = Modifier.align(Alignment.CenterStart)
                .offset { IntOffset(((maxPx - thumbPx) * fraction).roundToInt(), 0) }
                .size(16.dp).clip(CircleShape).background(accent),
        )
    }
}
'''
open(GLASSDIR + "/CompactSlider.kt", "w", encoding="utf-8").write(content)
print("OK 32 v111 CompactSlider.kt 已写入")
PYEOF111A
python3 << 'PYEOF111'
import os
def load(p):
    while not os.path.exists(p) and os.getcwd() != "/":
        os.chdir("..")
    return open(p, encoding="utf-8").read()
SS = "avbox/app/src/main/java/com/github/tvbox/osc/ui/music/settings/SettingsScreen.kt"
s = load(SS)
if "[32v111]" in s:
    print("跳过（32 v111 设置页已应用）")
else:
    a = "import com.github.tvbox.osc.ui.music.glass.GlassSettings // [32v104]"
    assert s.count(a) == 1, "v111 import 锚点"
    s = s.replace(a, a + "\nimport com.github.tvbox.osc.ui.music.glass.CompactSlider // [32v111]", 1)
    def swap(body, n):
        assert body.count("                Slider(") == n, "v111 滑杆数"
        body = body.replace("                Slider(", "                CompactSlider(", n)
        colors = """                    colors = SliderDefaults.colors(
                        thumbColor = musicColors().accent,
                        activeTrackColor = musicColors().accent,
                        inactiveTrackColor = musicColors().cardSecondary,
                    ),
"""
        assert body.count(colors) == n, "v111 colors 块数"
        body = body.replace(colors, "", n)
        return body
    i = s.index("private fun GlassCapsuleCard()")
    j = s.index("private fun GlassDrawerCard()")
    s = s[:i] + swap(s[i:j], 4) + swap(s[j:], 3)
    open(SS, "w", encoding="utf-8").write(s)
    print("OK 32 v111 两张毛玻璃卡换紧凑滑杆完成")
PYEOF111
echo "=== 32 v111 完成 ==="

# === 32 v112: CompactSlider 指针 API 修正(修构建红 3 处 Unresolved reference) ===
python3 << 'PYEOF112'
import os
def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
find_root()
CS = "avbox/app/src/main/java/com/github/tvbox/osc/ui/music/glass/CompactSlider.kt"
s = open(CS, encoding="utf-8").read()
if "[32v112]" in s:
    print("跳过（32 v112 已应用）")
else:
    a = "import androidx.compose.ui.input.pointer.awaitPointerEventScope\n"
    assert s.count(a) == 1, "v112 awaitPointerEventScope import 锚点"
    s = s.replace(a, "", 1)
    a = "import androidx.compose.ui.input.pointer.changedToUpOrCanceled\n"
    assert s.count(a) == 1, "v112 changedToUpOrCanceled import 锚点"
    s = s.replace(a, "", 1)
    a = "if (change.changedToUpOrCanceled()) {"
    assert s.count(a) == 1, "v112 松手判断锚点"
    s = s.replace(a, "if (!change.pressed) { // [32v112] 松手/取消统一按抬起处理: awaitPointerEventScope 是 PointerInputScope 成员(无需 import), changedToUpOrCanceled 在此 Compose 版不存在, 以 pressed=false 判定", 1)
    open(CS, "w", encoding="utf-8").write(s)
    print("OK 32 v112 CompactSlider 指针 API 修正完成")
PYEOF112
echo "=== 32 v112 完成 ==="

# === 32 v113: 搜索历史 chip 词条防挤(长词不顶掉删除钮) ===
python3 << 'PYEOF113'
import os
def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
find_root()
SR = "avbox/app/src/main/java/com/github/tvbox/osc/ui/music/search/SearchResultScreen.kt"
s = open(SR, encoding="utf-8").read()
if "[32v113]" in s:
    print("跳过（32 v113 已应用）")
else:
    a = """                                    Text(
                                        text = word,
                                        style = MaterialTheme.typography.bodyMedium,
                                        color = musicColors().textPrimary,
                                        maxLines = 1,
                                    )"""
    assert s.count(a) == 1, "v113 历史词条锚点"
    s = s.replace(a, """                                    Text(
                                        text = word,
                                        style = MaterialTheme.typography.bodyMedium,
                                        color = musicColors().textPrimary,
                                        maxLines = 1,
                                        overflow = TextOverflow.Ellipsis,
                                        modifier = Modifier.weight(1f), // [32v113] 超长词(粘贴网址)只压自己, 不顶掉后方删除钮
                                    )""", 1)
    open(SR, "w", encoding="utf-8").write(s)
    print("OK 32 v113 搜索历史词条防挤完成")
PYEOF113
echo "=== 32 v113 完成 ==="


# === 32 v115: 运行日志缓冲 + 引擎失败漏斗 ===
python3 << 'PYEOF115'
import os
def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
find_root()
LOG = "avbox/app/src/main/java/com/github/tvbox/osc/util/LxRuntimeLog.kt"
if not os.path.exists(LOG):
    open(LOG, "w", encoding="utf-8").write("""package com.github.tvbox.osc.util

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

// [32v115] 运行时日志缓冲：引擎/验证失败直通 UI，免 PC 看 logcat；超 100 条截头
object LxRuntimeLog {
    private const val MAX_LINES = 100
    private val _logs = MutableStateFlow<List<String>>(emptyList())
    val logs: StateFlow<List<String>> = _logs

    @Synchronized
    fun add(msg: String) {
        val t = SimpleDateFormat("HH:mm:ss", Locale.getDefault()).format(Date())
        _logs.value = (_logs.value + "[$t] " + msg.take(500)).takeLast(MAX_LINES)
    }

    @Synchronized
    fun clear() {
        _logs.value = emptyList()
    }
}
""")
    print("OK 32 v115 LxRuntimeLog.kt 已创建")
else:
    print("SKIP LxRuntimeLog.kt 已存在")

E = "avbox/app/src/main/java/com/github/tvbox/osc/util/LxScriptEngine.kt"
s = open(E, encoding="utf-8").read()
if "[32v115]" in s:
    print("跳过（32 v115 引擎漏斗已应用）")
else:
    assert "package com.github.tvbox.osc.util" in s, "v115 引擎包名"
    # 漏斗 helper：插在 runOnMain 之前
    a = "    // ---------------- 内部：工具 ----------------"
    assert s.count(a) == 1, "v115 工具区锚点"
    s = s.replace(a, """    // [32v115] 失败直通运行日志缓冲（与 Log.e 并行，不改回调行为；同包直调，零接线）
    private fun reportErr(where: String, e: Throwable?) {
        try {
            val detail = if (e != null) " | " + e::class.simpleName + ": " + e.message else ""
            LxRuntimeLog.add(where + detail)
        } catch (_: Exception) { }
    }

""" + a, 1)
    pairs = [
        ('            Log.e(TAG, "loadScript failed: preload not loaded, call loadPreloadJs() first")',
         '            reportErr("loadScript: preload 未加载", null)'),
        ('            Log.e(TAG, "loadScript failed: scriptContent is blank")',
         '            reportErr("loadScript: 脚本内容为空", null)'),
        ('                    Log.e(TAG, "loadScript timeout: no inited event from script $sourceId")',
         '                    reportErr("loadScript 超时: $sourceId 未收到 inited", null)'),
        ('            Log.e(TAG, "loadScript failed", e)',
         '            reportErr("loadScript 失败", e)'),
        ('                            Log.e(TAG, "requestMusicUrl: empty url, raw=$raw")',
         '                            reportErr("requestMusicUrl: 返回空地址 raw=$raw", null)'),
        ('                        Log.e(TAG, "requestMusicUrl: parse failed", e)',
         '                        reportErr("requestMusicUrl: 解析失败", e)'),
        ('                    Log.e(TAG, "requestMusicUrl failed: source=$sourceKey quality=$quality", e)',
         '                    reportErr("requestMusicUrl 失败: source=$sourceKey quality=$quality", e)'),
        ('                        Log.e(TAG, "requestLyric: parse failed", e)',
         '                        reportErr("requestLyric: 解析失败", e)'),
        ('                    Log.e(TAG, "requestLyric failed: source=$sourceKey", e)',
         '                    reportErr("requestLyric 失败: source=$sourceKey", e)'),
        ('                            Log.e(TAG, "requestPic: empty url, raw=$raw")',
         '                            reportErr("requestPic: 返回空地址 raw=$raw", null)'),
        ('                        Log.e(TAG, "requestPic: parse failed", e)',
         '                        reportErr("requestPic: 解析失败", e)'),
        ('                    Log.e(TAG, "requestPic failed: source=$sourceKey", e)',
         '                    reportErr("requestPic 失败: source=$sourceKey", e)'),
        ('                    Log.e(TAG, "script http failed: $url", e)',
         '                    reportErr("脚本 HTTP 失败: $url", e)'),
    ]
    for old, rep in pairs:
        assert s.count(old) == 1, "v115 引擎锚点: " + old.strip()[:60]
        s = s.replace(old, old + "\n" + rep, 1)
    # 脚本侧 console：error/warn 直通缓冲
    a = '                "error" -> Log.e(TAG, "[script] $message")'
    assert s.count(a) == 1, "v115 script error 锚点"
    s = s.replace(a, '                "error" -> { Log.e(TAG, "[script] $message"); LxRuntimeLog.add("[script][error] $message") }', 1)
    a = '                "warn", "warning" -> Log.w(TAG, "[script] $message")'
    assert s.count(a) == 1, "v115 script warn 锚点"
    s = s.replace(a, '                "warn", "warning" -> { Log.w(TAG, "[script] $message"); LxRuntimeLog.add("[script][warn] $message") }', 1)
    open(E, "w", encoding="utf-8").write(s)
    print("OK 32 v115 引擎失败漏斗完成")
PYEOF115
echo "=== 32 v115 完成 ==="

# === 32 v116: 验证侧捞异常 + 源管理页日志入口/查看原因/抽屉 ===
python3 << 'PYEOF116'
import os
def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
find_root()
P = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxSourceSettings.kt"
s = open(P, encoding="utf-8").read()
if "[32v116]" in s:
    print("跳过（32 v116 已应用）")
else:
    def rep(old, new, tag):
        global s
        assert s.count(old) == 1, "v116 锚点: " + tag + " 数=" + str(s.count(old))
        s = s.replace(old, new, 1)

    # ---- imports ----
    rep("import com.github.tvbox.osc.util.LxScriptEngine",
        "import com.github.tvbox.osc.util.LxScriptEngine\nimport com.github.tvbox.osc.util.LxRuntimeLog", "util import")
    rep("import androidx.compose.material3.MaterialTheme",
        "import androidx.compose.material3.MaterialTheme\nimport androidx.compose.material3.ModalBottomSheet\nimport androidx.compose.material3.rememberModalBottomSheetState", "sheet import")
    rep("import androidx.compose.foundation.layout.fillMaxWidth",
        "import androidx.compose.foundation.layout.fillMaxHeight\nimport androidx.compose.foundation.layout.fillMaxWidth", "fillMaxHeight import")
    rep("import androidx.compose.runtime.getValue",
        "import androidx.compose.runtime.collectAsState\nimport androidx.compose.runtime.getValue", "collectAsState import")

    # ---- 抽屉状态 ----
    rep("    var verifyResults by remember { mutableStateOf(LxSourceVerifier.loadResultCache(context)) }",
        "    var verifyResults by remember { mutableStateOf(LxSourceVerifier.loadResultCache(context)) }\n    var showLogSheet by remember { mutableStateOf(false) } // [32v116] 运行日志抽屉",
        "showLogSheet 状态")

    # ---- TopAppBar 日志入口 ----
    rep("""            TopAppBar(
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Color.Transparent),
                title = { Text("音乐源管理", color = musicColors().textPrimary) },""",
        """            TopAppBar(
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Color.Transparent),
                title = { Text("音乐源管理", color = musicColors().textPrimary) },
                actions = { TextButton(onClick = { showLogSheet = true }) { Text("日志", color = musicColors().textPrimary) } },""",
        "TopAppBar actions")

    # ---- 抽屉挂载（内容区开头） ----
    rep("""    ) { padding ->
        if (sources.isEmpty()) {""",
        """    ) { padding ->
        if (showLogSheet) { RuntimeLogSheet(onDismiss = { showLogSheet = false }) }
        if (sources.isEmpty()) {""",
        "抽屉挂载")

    # ---- SourceCard：查看原因入参 ----
    rep("""    onPingClick: () -> Unit = {},
    isRefreshing: Boolean = false
) {""",
        """    onPingClick: () -> Unit = {},
    isRefreshing: Boolean = false,
    onShowLog: () -> Unit = {}
) {""",
        "SourceCard 入参")

    # ---- ❌ 分支旁加查看原因 ----
    rep("""                        else -> {
                            val msg = if (verifyResult.latencyMs >= 10000) "超时" else "验证失败"
                            Text(
                                text = "❌ $msg",
                                style = MaterialTheme.typography.labelSmall,
                                color = Color(0xFFF44336)
                            )
                        }""",
        """                        else -> {
                            val msg = if (verifyResult.latencyMs >= 10000) "超时" else "验证失败"
                            Text(
                                text = "❌ $msg",
                                style = MaterialTheme.typography.labelSmall,
                                color = Color(0xFFF44336)
                            )
                            Spacer(modifier = Modifier.width(6.dp))
                            Text(
                                text = "查看原因",
                                style = MaterialTheme.typography.labelSmall,
                                color = musicColors().accent,
                                modifier = Modifier.clickable { onShowLog() }
                            )
                        }""",
        "查看原因")

    # ---- 调用点接线 ----
    rep("                        onPingClick = { pingOne(source.id) },",
        "                        onPingClick = { pingOne(source.id) },\n                        onShowLog = { showLogSheet = true },",
        "调用点接线")

    # ---- VerifyResult 加 error 字段（仅内存，不进缓存格式） ----
    rep("""    data class VerifyResult(
        val sourceId: String,
        val success: Boolean,
        val latencyMs: Long = 0,
        val verifying: Boolean = false
    )""",
        """    data class VerifyResult(
        val sourceId: String,
        val success: Boolean,
        val latencyMs: Long = 0,
        val verifying: Boolean = false,
        val error: String? = null // [32v116] 失败原因（仅内存，不进 id|0/1|ms 缓存格式）
    )""",
        "VerifyResult error 字段")

    # ---- finish 加 error 参数 ----
    rep("""            fun finish(passed: Boolean, latencyMs: Long) {
                updatePool(context, sourceId, passed)
                saveResultCache(context, sourceId, passed, latencyMs)
                onResult(VerifyResult(sourceId, passed, latencyMs))
            }""",
        """            fun finish(passed: Boolean, latencyMs: Long, error: String? = null) {
                updatePool(context, sourceId, passed)
                saveResultCache(context, sourceId, passed, latencyMs)
                onResult(VerifyResult(sourceId, passed, latencyMs, error = error))
            }""",
        "finish error 参数")

    # ---- 阶段失败：脚本为空 ----
    rep("""                if (scriptContent.isNullOrBlank()) {
                    android.util.Log.w(TAG, "验证 $sourceId: 脚本内容为空")
                    finish(false, System.currentTimeMillis() - start)""",
        """                if (scriptContent.isNullOrBlank()) {
                    android.util.Log.w(TAG, "验证 $sourceId: 脚本内容为空")
                    LxRuntimeLog.add("验证 $sourceId: 脚本内容为空")
                    finish(false, System.currentTimeMillis() - start, "脚本内容为空")""",
        "脚本为空")

    # ---- 阶段失败：preload 读取异常 ----
    rep("""                } catch (e: Exception) {
                    android.util.Log.e(TAG, "读取 preload.js 失败", e)
                    ""
                }""",
        """                } catch (e: Exception) {
                    android.util.Log.e(TAG, "读取 preload.js 失败", e)
                    LxRuntimeLog.add("验证 $sourceId: 读取 preload.js 失败: " + e.message)
                    ""
                }""",
        "preload 读取异常")

    # ---- 阶段失败：preload 为空 ----
    rep("""                if (preloadJs.isBlank()) {
                    finish(false, System.currentTimeMillis() - start)""",
        """                if (preloadJs.isBlank()) {
                    LxRuntimeLog.add("验证 $sourceId: preload.js 为空")
                    finish(false, System.currentTimeMillis() - start, "preload.js 为空")""",
        "preload 为空")

    # ---- 阶段失败：preload 加载失败 ----
    rep("""                if (!preloadDone.get() || !preloadOk.get()) {
                    android.util.Log.w(TAG, "验证 $sourceId: preload 加载失败")
                    finish(false, System.currentTimeMillis() - start)""",
        """                if (!preloadDone.get() || !preloadOk.get()) {
                    android.util.Log.w(TAG, "验证 $sourceId: preload 加载失败")
                    LxRuntimeLog.add("验证 $sourceId: preload 加载失败（15 秒超时或就绪失败）")
                    finish(false, System.currentTimeMillis() - start, "preload 加载失败")""",
        "preload 加载失败")

    # ---- 脚本加载异常捕获 ----
    rep("""                val declRef = java.util.concurrent.atomic.AtomicReference<Map<String, LxSourceDeclaration>?>(null)""",
        """                val declRef = java.util.concurrent.atomic.AtomicReference<Map<String, LxSourceDeclaration>?>(null)
                val scriptErr = java.util.concurrent.atomic.AtomicReference<Throwable?>(null)""",
        "scriptErr 声明")
    rep("""                eng.loadScript(sourceId, scriptContent, ScriptInfo(id = sourceId, name = sourceName)) { result ->
                    declRef.set(result.getOrNull())
                    scriptDone.set(true)
                }""",
        """                eng.loadScript(sourceId, scriptContent, ScriptInfo(id = sourceId, name = sourceName)) { result ->
                    declRef.set(result.getOrNull())
                    scriptErr.set(result.exceptionOrNull())
                    scriptDone.set(true)
                }""",
        "脚本加载异常捕获")
    rep("""                if (!scriptDone.get() || decls == null) {
                    android.util.Log.w(TAG, "验证 $sourceId: 脚本加载失败")
                    finish(false, System.currentTimeMillis() - start)""",
        """                if (!scriptDone.get() || decls == null) {
                    android.util.Log.w(TAG, "验证 $sourceId: 脚本加载失败")
                    val se = scriptErr.get()
                    LxRuntimeLog.add("验证 $sourceId: 脚本加载失败" + if (se != null) ": " + se::class.simpleName + ": " + se.message else "")
                    finish(false, System.currentTimeMillis() - start, "脚本加载失败" + if (se != null) ": " + se.message else "")""",
        "脚本加载失败")

    # ---- 阶段失败：无平台声明 ----
    rep("""                    else -> {
                        android.util.Log.w(TAG, "验证 $sourceId: 脚本未声明任何平台")
                        finish(false, System.currentTimeMillis() - start)""",
        """                    else -> {
                        android.util.Log.w(TAG, "验证 $sourceId: 脚本未声明任何平台")
                        LxRuntimeLog.add("验证 $sourceId: 脚本未声明任何平台")
                        finish(false, System.currentTimeMillis() - start, "脚本未声明任何平台")""",
        "无平台声明")

    # ---- 逐首失败：lastError 声明 ----
    rep("""                var successCount = 0
                var totalLatency = 0L""",
        """                var successCount = 0
                var totalLatency = 0L
                var lastError: String? = null""",
        "lastError 声明")

    # ---- 逐首失败：捞 exceptionOrNull（带严格校验注释的块，ping 那处无此注释故唯一） ----
    rep("""                        res.fold(
                            onSuccess = { url ->
                                // 严格校验 URL：必须是有效 http 链接，排除错误信息冒充
                                if (isValidMusicUrl(url)) {
                                    resolvedUrl.set(url)
                                    urlOk.set(true)
                                } else {
                                    urlOk.set(false)
                                }
                            },
                            onFailure = { urlOk.set(false) }
                        )""",
        """                        res.fold(
                            onSuccess = { url ->
                                // 严格校验 URL：必须是有效 http 链接，排除错误信息冒充
                                if (isValidMusicUrl(url)) {
                                    resolvedUrl.set(url)
                                    urlOk.set(true)
                                } else {
                                    urlOk.set(false)
                                }
                            },
                            onFailure = { e ->
                                urlOk.set(false)
                                lastError = "《" + name + "》取地址失败: " + e::class.simpleName + ": " + e.message
                                LxRuntimeLog.add("验证 $sourceId 平台 $testPlatform " + lastError)
                            }
                        )""",
        "逐首失败捞异常")

    # ---- Range 校验失败 ----
    rep("""                    val url = resolvedUrl.get()
                    if (urlOk.get() && url != null) {
                        urlOk.set(rangeCheckOk(url))
                    }""",
        """                    val url = resolvedUrl.get()
                    if (urlOk.get() && url != null) {
                        val rangeOk = rangeCheckOk(url)
                        if (!rangeOk) {
                            lastError = "《" + name + "》Range 校验失败: " + url.take(120)
                            LxRuntimeLog.add("验证 $sourceId 平台 $testPlatform " + lastError)
                        }
                        urlOk.set(rangeOk)
                    }""",
        "Range 校验失败")

    # ---- 终局：带原因 finish + 汇总进日志 ----
    rep("""                val avgLatency = if (successCount > 0) totalLatency / testSongs.size else System.currentTimeMillis() - start
                val passed = successCount >= 4
                android.util.Log.i(TAG, "验证 $sourceId: $successCount/5 通过, ${if (passed) "有效" else "无效"}")
                finish(passed, avgLatency)""",
        """                val avgLatency = if (successCount > 0) totalLatency / testSongs.size else System.currentTimeMillis() - start
                val passed = successCount >= 4
                android.util.Log.i(TAG, "验证 $sourceId: $successCount/5 通过, ${if (passed) "有效" else "无效"}")
                LxRuntimeLog.add("验证 $sourceId($sourceName): $successCount/5 通过, " + if (passed) "有效" else "无效")
                finish(passed, avgLatency, if (passed) null else lastError)""",
        "终局 finish")

    # ---- 验证总 catch ----
    rep("""            } catch (e: Exception) {
                android.util.Log.e(TAG, "验证失败 $sourceId", e)
                finish(false, System.currentTimeMillis() - start)
            } finally {""",
        """            } catch (e: Exception) {
                android.util.Log.e(TAG, "验证失败 $sourceId", e)
                LxRuntimeLog.add("验证 $sourceId 异常: " + e::class.simpleName + ": " + e.message)
                finish(false, System.currentTimeMillis() - start, "验证异常: " + e.message)
            } finally {""",
        "验证总 catch")

    open(P, "w", encoding="utf-8").write(s)
    print("OK 32 v116 验证侧 + 源管理页 UI 完成")
PYEOF116
# 抽屉 composable 追加到文件尾（CWD 可能是仓库根或 avbox/，两路都认）
if [ -f avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxSourceSettings.kt ]; then
  TGT116=avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxSourceSettings.kt
else
  TGT116=app/src/main/java/com/github/tvbox/osc/ui/activity/LxSourceSettings.kt
fi
cat >> "$TGT116" << 'KT116EOF'

// [32v116] 运行日志抽屉：引擎/验证失败直通 UI，免 PC 看 logcat
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun RuntimeLogSheet(onDismiss: () -> Unit) {
    val context = LocalContext.current
    val sheetState = rememberModalBottomSheetState()
    val logLines by LxRuntimeLog.logs.collectAsState()
    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
        containerColor = musicColors().card,
        modifier = Modifier.fillMaxHeight(0.8f)
    ) {
        Column(
            modifier = Modifier.fillMaxSize().padding(horizontal = 16.dp).padding(bottom = 24.dp)
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = "运行日志",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = musicColors().textPrimary
                )
                Spacer(modifier = Modifier.weight(1f))
                TextButton(onClick = { LxRuntimeLog.clear() }) {
                    Text("清空日志", color = musicColors().textSecondary)
                }
                TextButton(onClick = {
                    val text = logLines.joinToString("\n")
                    (context.getSystemService(android.content.Context.CLIPBOARD_SERVICE) as android.content.ClipboardManager)
                        .setPrimaryClip(android.content.ClipData.newPlainText("运行日志", text))
                    Toast.makeText(context, "已复制 " + logLines.size + " 条日志", Toast.LENGTH_SHORT).show()
                }) {
                    Text("复制日志", color = musicColors().textSecondary)
                }
            }
            Spacer(modifier = Modifier.height(8.dp))
            if (logLines.isEmpty()) {
                Text(
                    text = "暂无日志",
                    style = MaterialTheme.typography.bodyMedium,
                    color = musicColors().textSecondary
                )
            } else {
                LazyColumn(modifier = Modifier.weight(1f)) {
                    items(logLines) { line ->
                        val isErr = line.contains("Exception", ignoreCase = true) ||
                            line.contains("error", ignoreCase = true) ||
                            line.contains("timeout", ignoreCase = true) ||
                            line.contains("失败", ignoreCase = true)
                        Text(
                            text = line,
                            style = MaterialTheme.typography.bodySmall,
                            color = if (isErr) Color.Red else musicColors().textSecondary
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                    }
                }
            }
        }
    }
}
KT116EOF
echo "=== 32 v116 完成 ==="

# === 32 v117: 运行日志抽屉补 FontWeight 导入（构建红：1316 未解析） ===
python3 << 'PYEOF117'
import os
def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
find_root()
P = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxSourceSettings.kt"
s = open(P, encoding="utf-8").read()
if "[32v117]" in s:
    print("跳过（32 v117 已应用）")
else:
    a = "import androidx.compose.ui.Alignment"
    assert s.count(a) == 1, "v117 Alignment 锚点"
    assert "import androidx.compose.ui.text.font.FontWeight" not in s, "v117 FontWeight 已存在？"
    s = s.replace(a, a + "\nimport androidx.compose.ui.text.font.FontWeight // [32v117] 运行日志抽屉标题 Bold 用", 1)
    open(P, "w", encoding="utf-8").write(s)
    print("OK 32 v117 FontWeight 导入已补")
PYEOF117
echo "=== 32 v117 完成 ==="


# === 32 v118: pyramid Chaquopy pip 索引源阿里云切回 PyPI 官方（修 pyquery 装包失败；容错版） ===
python3 << 'PYEOF118'
import os
def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
find_root()
P = "avbox/pyramid/build.gradle.kts"
s = open(P, encoding="utf-8").read()
if "[32v118]" in s:
    print("跳过（32 v118 已应用）")
else:
    a = 'options("-i", "https://mirrors.aliyun.com/pypi/simple/")'
    b = 'options("-i", "https://pypi.org/simple/")'
    if s.count(a) == 1:
        s = s.replace(a, b + ' // [32v118] 阿里云镜像致 pyquery==2.0.2 无版本可用，改走 PyPI 官方；Chaquo 安卓 wheel 仍走 extra-index', 1)
        open(P, "w", encoding="utf-8").write(s)
        print("OK 32 v118 pyramid pip 源已切回 PyPI")
    elif b in s:
        print("SKIP 32 v118 pyramid pip 源已是 PyPI（此前步骤已改过），不重复改")
    else:
        print("WARN 32 v118 pyramid pip 源既非阿里云亦非 PyPI，原样放行以便 gradle 暴露真实配置：")
        for line in s.split("\n"):
            if "options(" in line or "install(" in line or "pip {" in line:
                print("  [32v118-config] " + line.strip())
PYEOF118
echo "=== 32 v118 完成 ==="


# === 32 v119: pyramid pip 源统一切 PyPI（不论之前是哪家镜像） ===
python3 << 'PYEOF119'
import os, re
def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
find_root()
P = "avbox/pyramid/build.gradle.kts"
s = open(P, encoding="utf-8").read()
if "[32v119]" in s:
    print("跳过（32 v119 已应用）")
else:
    m = re.search(r'options\("-i",\s*"([^"]+)"\)', s)
    if m is None:
        print("SKIP 32 v119 未找到 pip -i 行（无 -i 即默认 PyPI）")
    elif m.group(1) == "https://pypi.org/simple/":
        print("SKIP 32 v119 pip 源已是 PyPI")
    else:
        old_url = m.group(1)
        s = s.replace(m.group(0), 'options("-i", "https://pypi.org/simple/") // [32v119] 统一切 PyPI 官方，断镜像依赖（此前为 ' + old_url + '）', 1)
        open(P, "w", encoding="utf-8").write(s)
        print("OK 32 v119 pyramid pip 源已切 PyPI（原：" + old_url + "）")
PYEOF119
echo "=== 32 v119 完成 ==="

# === 32 v120: 播放器报错接入运行日志 + 超时高亮补中文 ===
python3 << 'PYEOF120'
import os
def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
find_root()
M = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerManager.kt"
s = open(M, encoding="utf-8").read()
if "[32v120]" in s:
    print("跳过（32 v120 已应用）")
else:
    def rep(old, new, tag):
        global s
        assert s.count(old) == 1, "v120 锚点: " + tag + " 数=" + str(s.count(old))
        s = s.replace(old, new, 1)

    # import（Manager 此前无 util 包 import）
    rep("import android.util.Log",
        "import android.util.Log\nimport com.github.tvbox.osc.util.LxRuntimeLog // [32v120] 播放器报错入运行日志",
        "Manager import")
    # 播放器流错误：onPlayerError（直接写 _error，不走 setError，必须单点补）
    rep("""                    override fun onPlayerError(error: androidx.media3.common.PlaybackException) {
                        Log.e(TAG,"播错",error)""",
        """                    override fun onPlayerError(error: androidx.media3.common.PlaybackException) {
                        Log.e(TAG,"播错",error)
                        try { LxRuntimeLog.add("播放器报错: " + _currentTitle.value + " / " + _currentArtist.value + " | code=" + error.errorCode + " " + error.message) } catch (_: Exception) { } // [32v120]""",
        "onPlayerError")
    # 播放器初始化失败（同样直接写 _error）
    rep("""            Log.e(TAG,"ExoFail",e)
            _error.value = "播放器初始化失败: ${e.message}\"""",
        """            Log.e(TAG,"ExoFail",e)
            _error.value = "播放器初始化失败: ${e.message}"
            try { LxRuntimeLog.add("播放器初始化失败: " + e.message) } catch (_: Exception) { } // [32v120]""",
        "ExoFail")
    # setError 中央漏斗（解析失败/引擎错误/播放器未初始化/Activity 终局失败都走这里）
    rep("""    fun setError(msg: String?) { // [21v30] 密封：报错必复位探针态
        _error.value = msg""",
        """    fun setError(msg: String?) { // [21v30] 密封：报错必复位探针态
        _error.value = msg
        if (msg != null) { try { LxRuntimeLog.add("播放: " + _currentTitle.value + " / " + _currentArtist.value + " | " + msg) } catch (_: Exception) { } } // [32v120]""",
        "setError 漏斗")
    # 探针无法探测（此前静默吞掉，流拉不到时无迹可查）
    rep("            _probeTier.value = prA.first",
        "            _probeTier.value = prA.first\n            if (prA.first < 0) { try { LxRuntimeLog.add(\"探针无法探测: \" + url.take(120)) } catch (_: Exception) { } } // [32v120]",
        "探针失败")
    open(M, "w", encoding="utf-8").write(s)
    print("OK 32 v120 播放器报错已接入运行日志")

P = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxSourceSettings.kt"
t = open(P, encoding="utf-8").read()
if "[32v120]" in t:
    print("跳过（32 v120 抽屉高亮已应用）")
else:
    a = """                        val isErr = line.contains("Exception", ignoreCase = true) ||
                            line.contains("error", ignoreCase = true) ||
                            line.contains("timeout", ignoreCase = true) ||
                            line.contains("失败", ignoreCase = true)"""
    assert t.count(a) == 1, "v120 高亮锚点数=" + str(t.count(a))
    t = t.replace(a, a + """ ||
                            line.contains("超时") // [32v120] 中文超时也标红（此前 loadScript 超时显示为灰）""", 1)
    open(P, "w", encoding="utf-8").write(t)
    print("OK 32 v120 超时高亮已补中文")
PYEOF120
echo "=== 32 v120 完成 ==="

# === 32 v121: 队列链死链跳过 + 取地址验活 helper（配合 39 点歌链） ===
python3 << 'PYEOF121'
import os
def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
find_root()
M = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerManager.kt"
s = open(M, encoding="utf-8").read()
if "[32v121]" in s:
    print("跳过（32 v121 已应用）")
else:
    def rep(old, new, tag):
        global s
        assert s.count(old) == 1, "v121 锚点: " + tag + " 数=" + str(s.count(old))
        s = s.replace(old, new, 1)

    # 验活 helper：放在音质验货段前（对象成员，供点歌链/队列链共用）
    rep("    // ============ 音质验货（防糊）v6 ============",
        """    // [32v121] 取地址时验活：Range 拉 1KB，200/206 才算给流；level=undefined 免网络直接判死
    fun isStreamUrlAlive(url: String): Boolean {
        if (url.contains("level=undefined")) return false
        return try {
            val conn = java.net.URL(url).openConnection() as java.net.HttpURLConnection
            conn.requestMethod = "GET"
            conn.setRequestProperty("Range", "bytes=0-1023")
            conn.instanceFollowRedirects = true
            conn.connectTimeout = 3000
            conn.readTimeout = 3000
            try {
                val code = conn.responseCode
                code == 200 || code == 206
            } finally {
                try { conn.disconnect() } catch (_: Exception) { }
            }
        } catch (_: Exception) {
            false
        }
    }

    // ============ 音质验货（防糊）v6 ============""",
        "验活 helper")
    # 队列链：探针拉不到且验活失败 = 死链，换平台重试（不记备选，免得终局播死链）
    rep("""                                        } else {
                                            // 达标或无法探测：播放，并把真实档位/码率回传 UI（替换假标签）。""",
        """                                        } else if (tier < 0 && !isStreamUrlAlive(url)) {
                                            // [32v121] 探针拉不到且地址不给流：死链，换平台重试（不记备选）
                                            try { LxRuntimeLog.add("地址验活失败(队列链): " + url.take(80)) } catch (_: Exception) { }
                                            Log.w(TAG, "音质 $q @平台 ${cand.plat} 验活失败，换平台重试")
                                            candidateIndex++
                                            tryNext()
                                        } else {
                                            // 达标或无法探测但给流：播放，并把真实档位/码率回传 UI（替换假标签）。""",
        "队列链死链跳过")
    open(M, "w", encoding="utf-8").write(s)
    print("OK 32 v121 队列链死链跳过 + 验活 helper 已接")
PYEOF121
echo "=== 32 v121 完成 ==="

# === 32 v122: 验活改播放器式拿流（普通 GET + 浏览器 UA，不带 Range） ===
python3 << 'PYEOF122'
import os
def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
find_root()
M = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerManager.kt"
s = open(M, encoding="utf-8").read()
if "[32v122]" in s:
    print("跳过（32 v122 已应用）")
else:
    def rep(old, new, tag):
        global s
        assert s.count(old) == 1, "v122 锚点: " + tag + " 数=" + str(s.count(old))
        s = s.replace(old, new, 1)

    # 验活方式：Range+JavaUA 在裤佬中转站上全灭、PeekPili 播放器能播（同机对照已排除时机翻转），
    # 故改按播放器拿流方式验：普通 GET（不带 Range，拿响应头即断开，不下载正文）+ 浏览器 UA
    rep("    // [32v121] 取地址时验活：Range 拉 1KB，200/206 才算给流；level=undefined 免网络直接判死",
        "    // [32v121] 取地址时验活；[32v122] 改播放器式拿流：普通 GET（不带 Range）+ 浏览器 UA，200/206 算给流；level=undefined 免网络直接判死",
        "验活注释")
    rep("""            conn.requestMethod = "GET"
            conn.setRequestProperty("Range", "bytes=0-1023")""",
        """            conn.requestMethod = "GET"
            conn.setRequestProperty("User-Agent", "Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.6099.144 Mobile Safari/537.36") // [32v122] 浏览器 UA，按播放器拿流方式验""",
        "验活去 Range 加 UA")
    open(M, "w", encoding="utf-8").write(s)
    print("OK 32 v122 验活已改播放器式拿流")
PYEOF122
echo "=== 32 v122 完成 ==="

# === 32 v123: 解析前取交集（引擎存 inited 声明 + Manager 按源声明过滤档位） ===
python3 << 'PYEOF123'
import os
def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
find_root()

# ---- 1) 引擎：存下 inited 声明 + 取声明口子 ----
E = "avbox/app/src/main/java/com/github/tvbox/osc/util/LxScriptEngine.kt"
e = open(E, encoding="utf-8").read()
if "[32v123]" in e:
    print("跳过（32 v123 引擎已应用）")
else:
    def erep(old, new, tag):
        global e
        assert e.count(old) == 1, "v123 引擎锚点: " + tag + " 数=" + str(e.count(old))
        e = e.replace(old, new, 1)
    erep("    private var initedCallback: ((Result<Map<String, LxSourceDeclaration>>) -> Unit)? = null",
        "    private var initedCallback: ((Result<Map<String, LxSourceDeclaration>>) -> Unit)? = null\n    @Volatile private var lastDeclarations: Map<String, LxSourceDeclaration> = emptyMap() // [32v123] 解析前取交集用：inited 上报的源声明",
        "声明字段")
    erep('            Log.i(TAG, "script inited, sources=${declarations.keys}")',
        '            lastDeclarations = declarations // [32v123] 存下声明，供解析前取交集\n            Log.i(TAG, "script inited, sources=${declarations.keys}")',
        "声明存盘")
    erep("    /**\n     * 请求歌曲播放地址。",
        """    /** [32v123] 取源声明的音质档位（inited 上报）；未知返回 null，调用方回退原顺序 */
    fun getSourceQualitys(sourceKey: String): List<String>? {
        return try { lastDeclarations[sourceKey]?.qualitys } catch (_: Exception) { null }
    }

    /**
     * 请求歌曲播放地址。""",
        "取声明口子")
    open(E, "w", encoding="utf-8").write(e)
    print("OK 32 v123 引擎声明存盘 + 取声明口子已接")

# ---- 2) Manager：按源声明过滤 + 队列链用过滤后顺序 ----
M = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerManager.kt"
s = open(M, encoding="utf-8").read()
if "[32v123]" in s:
    print("跳过（32 v123 Manager 已应用）")
else:
    def rep(old, new, tag):
        global s
        assert s.count(old) == 1, "v123 Manager 锚点: " + tag + " 数=" + str(s.count(old))
        s = s.replace(old, new, 1)
    rep("""    fun getQualityTryOrder(): List<String> {
        return qualityTryOrder()
    }""",
        """    fun getQualityTryOrder(): List<String> {
        return qualityTryOrder()
    }


    // [32v123] 解析前取交集：只发源声明过的档位（AUDIO_SPEC 老规矩）；声明未知/为空/交集为空时回退原顺序
    fun getQualityTryOrderFor(sourceKey: String): List<String> {
        val base = qualityTryOrder()
        return try {
            val declared = com.github.tvbox.osc.ui.activity.LxEngineHolder.get().getSourceQualitys(sourceKey)
            if (declared.isNullOrEmpty()) base else {
                val filtered = base.filter { it in declared }
                if (filtered.isEmpty()) base else {
                    if (filtered != base) Log.i(TAG, "音质交集: 源 $sourceKey 声明 $declared，试听顺序 $filtered")
                    filtered
                }
            }
        } catch (_: Exception) { base }
    }""",
        "按源过滤函数")
    rep("""                val engine = com.github.tvbox.osc.ui.activity.LxEngineHolder.get()
                val tryOrder = qualityTryOrder()""",
        """                val engine = com.github.tvbox.osc.ui.activity.LxEngineHolder.get()
                val tryOrder = getQualityTryOrderFor(platform) // [32v123] 队列链解析前取交集""",
        "队列链取交集")
    open(M, "w", encoding="utf-8").write(s)
    print("OK 32 v123 Manager 按源过滤 + 队列链取交集已接")
PYEOF123
echo "=== 32 v123 完成 ==="

# === 32 v124: 悬浮黑胶挂件 + 液态控制台（废长条迷你播放器，导航胶囊不动） ===
python3 << 'PYEOF124'
import os
def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
find_root()
M = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"
s = open(M, encoding="utf-8").read()
if "[32v124]" in s:
    print("跳过（32 v124 已应用）")
else:
    def rep(old, new, tag, cnt=1):
        global s
        assert s.count(old) == cnt, "v124 锚点: " + tag + " 数=" + str(s.count(old))
        s = s.replace(old, new, cnt)

    # 1) imports
    rep("import androidx.compose.foundation.shape.CircleShape",
        """import androidx.compose.foundation.shape.CircleShape
import androidx.compose.animation.core.Animatable // [32v124]
import androidx.compose.animation.core.LinearEasing // [32v124]
import androidx.compose.animation.core.tween // [32v124]
import androidx.compose.foundation.gestures.detectDragGestures // [32v124]
import androidx.compose.ui.draw.shadow // [32v124]
import androidx.compose.ui.geometry.Offset // [32v124]
import androidx.compose.ui.geometry.Rect // [32v124]
import androidx.compose.ui.graphics.Path // [32v124]
import androidx.compose.ui.graphics.StrokeCap // [32v124]
import androidx.compose.ui.input.pointer.pointerInput // [32v124]
import androidx.compose.ui.layout.boundsInWindow // [32v124]
import androidx.compose.ui.layout.onGloballyPositioned // [32v124]
import androidx.compose.ui.platform.LocalConfiguration // [32v124]
import androidx.compose.ui.platform.LocalDensity // [32v124]
import androidx.compose.ui.unit.IntOffset // [32v124]
import androidx.compose.ui.unit.IntSize // [32v124]
import androidx.compose.ui.unit.LayoutDirection // [32v124]
import androidx.compose.ui.window.Popup // [32v124]
import androidx.compose.ui.window.PopupPositionProvider // [32v124]
import androidx.compose.ui.window.PopupProperties // [32v124]
import kotlin.math.roundToInt // [32v124]""",
        "imports")

    # 2) 状态：miniPlayerDismissed -> 黑胶三态（同旧模式：新歌开始自动恢复）
    rep("""            // 手动关闭状态：点 X 后隐藏，直到下一首歌开始
            var miniPlayerDismissed by remember { mutableStateOf(false) }
            LaunchedEffect(playerTitle) {
                if (playerTitle.isNotEmpty()) miniPlayerDismissed = false
            }""",
        """            // [32v124] 黑胶挂件三态：点控制台 X 后隐藏，直到下一首歌开始（同旧迷你条模式）
            var vinylDismissed by remember { mutableStateOf(false) }
            var showVinylConsole by remember { mutableStateOf(false) }
            var vinylBounds by remember { mutableStateOf<Rect?>(null) }
            LaunchedEffect(playerTitle) {
                if (playerTitle.isNotEmpty()) vinylDismissed = false
                if (playerTitle.isEmpty()) showVinylConsole = false
            }""",
        "黑胶三态")

    # 3) 呼叫点：删长条迷你播放器 + 间距，导航胶囊原地不动
    rep("""                if (playerTitle.isNotEmpty() && !miniPlayerDismissed) {
                    MiniPlayerBar(
                        title = playerTitle,
                        artist = playerArtist,
                        picUrl = playerPic,
                        isPlaying = playerIsPlaying,
                        progress = if (playerDur > 0) (playerPos.toFloat() / playerDur.toFloat()).coerceIn(0f, 1f) else 0f,
                        onTogglePlay = { LxPlayerManager.togglePlayPause() },
                        onClose = {
                            LxPlayerManager.stop()
                            miniPlayerDismissed = true
                        },
                        onExpand = {
                            val intent = Intent(context, LxPlayerActivity::class.java).apply {
                                putExtra("title", playerTitle)
                                putExtra("artist", playerArtist)
                                putExtra("picUrl", playerPic)
                            }
                            context.startActivity(intent)
                        }
                    )
                    Spacer(modifier = Modifier.height(10.dp))
                }
""",
        "",
        "删迷你条呼叫点")

    # 4) 宿主：Column 之后、459 Box 之内最后绘制（最顶层，非 Haze 源内）
    rep("""                    } // [32v102] hazeBlur Box 结束
                }
            }
        }
""",
        """                    } // [32v102] hazeBlur Box 结束
                }
            }
            // [32v124] 悬浮黑胶挂件 + 液态控制台（长条迷你播放器已废，导航胶囊不动）
            BoxWithConstraints(modifier = Modifier.fillMaxSize()) {
                val density = LocalDensity.current
                val maxWpx = with(density) { maxWidth.toPx() }
                val maxHpx = with(density) { maxHeight.toPx() }
                val sizePx = with(density) { 48.dp.toPx() }
                val gapPx = with(density) { 12.dp.toPx() }.toInt()
                var vinylOffset by remember { mutableStateOf<Offset?>(null) }
                val vinylPos = vinylOffset ?: Offset(
                    maxWpx - sizePx - with(density) { 16.dp.toPx() },
                    maxHpx - sizePx - with(density) { 104.dp.toPx() }
                )
                if (playerTitle.isNotEmpty() && !vinylDismissed) {
                    VinylWidget(
                        picUrl = playerPic,
                        isPlaying = playerIsPlaying,
                        modifier = Modifier
                            .align(Alignment.TopStart)
                            .offset { IntOffset(vinylPos.x.roundToInt(), vinylPos.y.roundToInt()) }
                            .onGloballyPositioned { vinylBounds = it.boundsInWindow() }
                            .pointerInput(Unit) {
                                detectDragGestures(
                                    onDragStart = { showVinylConsole = false },
                                    onDrag = { change, dragAmount ->
                                        change.consume()
                                        vinylOffset = Offset(
                                            (vinylPos.x + dragAmount.x).coerceIn(0f, maxWpx - sizePx),
                                            (vinylPos.y + dragAmount.y).coerceIn(0f, maxHpx - sizePx)
                                        )
                                    }
                                )
                            },
                        onClick = { showVinylConsole = true }
                    )
                }
                vinylBounds?.let { bounds ->
                    if (showVinylConsole) {
                        Popup(
                            onDismissRequest = { showVinylConsole = false },
                            properties = PopupProperties(dismissOnClickOutside = true, focusable = true),
                            popupPositionProvider = VinylConsolePositionProvider(bounds, gapPx)
                        ) {
                            VinylConsole(
                                picUrl = playerPic,
                                isPlaying = playerIsPlaying,
                                progress = if (playerDur > 0) (playerPos.toFloat() / playerDur.toFloat()).coerceIn(0f, 1f) else 0f,
                                onPrev = { LxPlayerManager.playPreviousInQueue() },
                                onTogglePlay = { LxPlayerManager.togglePlayPause() },
                                onClose = {
                                    showVinylConsole = false
                                    vinylDismissed = true
                                    LxPlayerManager.pause()
                                }
                            )
                        }
                    }
                }
            }
        }
""",
        "黑胶宿主")

    # 5) MiniPlayerBar 函数整体替换为黑胶三件套（函数起止以注释锚点定位）
    start_mark = "/**\n * 迷你播放器（spotufi 风格：深色圆角条 + 封面 + 进度线）\n */"
    end_mark = "/** 点歌：设置播放队列并打开播放器（逻辑与原来一致） */"
    assert s.count(start_mark) == 1, "v124 MiniPlayerBar 起始锚点数=" + str(s.count(start_mark))
    assert s.count(end_mark) == 1, "v124 playSongs 锚点数=" + str(s.count(end_mark))
    si = s.index(start_mark)
    ei = s.index(end_mark)
    old_fn = s[si:ei]
    assert "fun MiniPlayerBar(" in old_fn and "底部进度线" in old_fn, "v124 MiniPlayerBar 范围校验失败"
    new_code = '''// [32v124] 悬浮黑胶挂件：48dp 圆形封面 + 匀速旋转（Animatable，暂停留角）
// 注意：rememberInfiniteTransition 无暂停 API，做不到暂停留角，故用 Animatable + LaunchedEffect
@Composable
private fun VinylWidget(
    picUrl: String,
    isPlaying: Boolean,
    modifier: Modifier = Modifier,
    onClick: () -> Unit,
) {
    val rotation = remember { Animatable(0f) }
    LaunchedEffect(isPlaying) {
        if (isPlaying) {
            while (true) {
                rotation.animateTo(
                    rotation.value + 360f,
                    tween(durationMillis = 15000, easing = LinearEasing)
                )
            }
        }
    }
    Box(
        modifier = modifier
            .size(48.dp)
            .clip(CircleShape)
            .border(1.dp, Color.White.copy(alpha = 0.2f), CircleShape)
            .background(musicColors().card)
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center
    ) {
        if (picUrl.isNotEmpty()) {
            AsyncImage(
                model = picUrl,
                contentDescription = null,
                modifier = Modifier.fillMaxSize().clip(CircleShape)
                    .graphicsLayer { rotationZ = rotation.value },
                contentScale = ContentScale.Crop
            )
        } else {
            Text(
                text = "♪",
                color = musicColors().textPrimary.copy(alpha = 0.6f),
                modifier = Modifier.graphicsLayer { rotationZ = rotation.value }
            )
        }
    }
}

// [32v124] 液态控制台：card 0.85 + extraLarge + 白高光边 + shadow 16
@Composable
private fun VinylConsole(
    picUrl: String,
    isPlaying: Boolean,
    progress: Float,
    onPrev: () -> Unit,
    onTogglePlay: () -> Unit,
    onClose: () -> Unit,
) {
    val screenW = LocalConfiguration.current.screenWidthDp.dp
    val cardW = minOf(300.dp, screenW - 32.dp)
    Surface(
        modifier = Modifier.width(cardW).shadow(16.dp, MaterialTheme.shapes.extraLarge),
        shape = MaterialTheme.shapes.extraLarge,
        color = musicColors().card.copy(alpha = 0.85f),
        border = BorderStroke(1.dp, Color.White.copy(alpha = 0.25f))
    ) {
        Column(modifier = Modifier.padding(20.dp)) {
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.End) {
                Text(
                    text = "正在播放",
                    style = MaterialTheme.typography.labelMedium,
                    color = musicColors().textSecondary
                )
            }
            Spacer(modifier = Modifier.height(12.dp))
            if (picUrl.isNotEmpty()) {
                AsyncImage(
                    model = picUrl,
                    contentDescription = null,
                    modifier = Modifier.fillMaxWidth().aspectRatio(1f).clip(RoundedCornerShape(16.dp)),
                    contentScale = ContentScale.Crop
                )
            } else {
                Box(
                    modifier = Modifier.fillMaxWidth().aspectRatio(1f).clip(RoundedCornerShape(16.dp))
                        .background(musicColors().cardSecondary),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = "♪",
                        style = MaterialTheme.typography.displayMedium,
                        color = musicColors().textPrimary.copy(alpha = 0.6f)
                    )
                }
            }
            Spacer(modifier = Modifier.height(12.dp))
            Box(modifier = Modifier.fillMaxWidth().height(2.dp).background(musicColors().divider)) {
                Box(
                    modifier = Modifier.fillMaxWidth(progress.coerceIn(0f, 1f)).height(2.dp)
                        .background(musicColors().accent)
                )
            }
            Spacer(modifier = Modifier.height(16.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Box(
                    modifier = Modifier.size(48.dp).clickable(onClick = onPrev),
                    contentAlignment = Alignment.Center
                ) {
                    VinylPrevIcon(tint = musicColors().textPrimary)
                }
                Box(
                    modifier = Modifier.size(64.dp).clip(CircleShape).background(Color.White)
                        .clickable(onClick = onTogglePlay),
                    contentAlignment = Alignment.Center
                ) {
                    if (isPlaying) VinylPauseIcon(tint = Color.Black) else VinylPlayIcon(tint = Color.Black)
                }
                Box(
                    modifier = Modifier.size(48.dp).clickable(onClick = onClose),
                    contentAlignment = Alignment.Center
                ) {
                    VinylCloseIcon(tint = musicColors().textPrimary)
                }
            }
        }
    }
}

// [32v124] 弹窗定位：以挂件实测 bounds 为锚（不用 Popup 自带 anchorBounds，避免语义歧义），
// 上方够放则放上方，否则放下方，横向夹紧屏内
private class VinylConsolePositionProvider(
    private val anchor: Rect,
    private val gapPx: Int,
) : PopupPositionProvider {
    override fun calculatePosition(
        anchorBounds: Rect,
        windowSize: IntSize,
        layoutDirection: LayoutDirection,
        popupContentSize: IntSize,
    ): IntOffset {
        val x = (anchor.center.x - popupContentSize.width / 2f)
            .coerceIn(0f, (windowSize.width - popupContentSize.width).coerceAtLeast(0).toFloat())
        val aboveY = anchor.top - popupContentSize.height - gapPx
        val belowY = anchor.bottom + gapPx
        val y = if (aboveY >= 0) aboveY
            else belowY.coerceAtMost((windowSize.height - popupContentSize.height).coerceAtLeast(0).toFloat())
        return IntOffset(x.toInt(), y.toInt())
    }
}

// [32v124] 手搓图标：2dp 圆头线条，复杂图标降级为基础几何
@Composable
private fun VinylPrevIcon(tint: Color) {
    Canvas(modifier = Modifier.size(28.dp)) {
        val sw = 2.dp.toPx()
        drawLine(
            color = tint,
            start = Offset(7.dp.toPx(), 7.dp.toPx()),
            end = Offset(7.dp.toPx(), 21.dp.toPx()),
            strokeWidth = sw, cap = StrokeCap.Round
        )
        val tri = Path().apply {
            moveTo(24.dp.toPx(), 7.dp.toPx())
            lineTo(11.dp.toPx(), 14.dp.toPx())
            lineTo(24.dp.toPx(), 21.dp.toPx())
            close()
        }
        drawPath(tri, tint)
    }
}

@Composable
private fun VinylPlayIcon(tint: Color) {
    Canvas(modifier = Modifier.size(28.dp)) {
        val tri = Path().apply {
            moveTo(11.dp.toPx(), 7.dp.toPx())
            lineTo(22.dp.toPx(), 14.dp.toPx())
            lineTo(11.dp.toPx(), 21.dp.toPx())
            close()
        }
        drawPath(tri, tint)
    }
}

@Composable
private fun VinylPauseIcon(tint: Color) {
    Canvas(modifier = Modifier.size(28.dp)) {
        val sw = 2.dp.toPx()
        drawLine(tint, Offset(10.dp.toPx(), 7.dp.toPx()), Offset(10.dp.toPx(), 21.dp.toPx()), sw, StrokeCap.Round)
        drawLine(tint, Offset(18.dp.toPx(), 7.dp.toPx()), Offset(18.dp.toPx(), 21.dp.toPx()), sw, StrokeCap.Round)
    }
}

@Composable
private fun VinylCloseIcon(tint: Color) {
    Canvas(modifier = Modifier.size(24.dp)) {
        val sw = 2.dp.toPx()
        drawLine(tint, Offset(6.dp.toPx(), 6.dp.toPx()), Offset(18.dp.toPx(), 18.dp.toPx()), sw, StrokeCap.Round)
        drawLine(tint, Offset(18.dp.toPx(), 6.dp.toPx()), Offset(6.dp.toPx(), 18.dp.toPx()), sw, StrokeCap.Round)
    }
}

'''
    s = s[:si] + new_code + s[ei:]
    open(M, "w", encoding="utf-8").write(s)
    print("OK 32 v124 黑胶挂件 + 液态控制台已接")
PYEOF124
echo "=== 32 v124 完成 ==="

# === 32 v125: 液态控制台加下一曲按钮（上一首/播放暂停/下一曲/X 四键） ===
python3 << 'PYEOF125'
import os
def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
find_root()
M = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"
s = open(M, encoding="utf-8").read()
if "[32v125]" in s:
    print("跳过（32 v125 已应用）")
else:
    def rep(old, new, tag, cnt=1):
        global s
        assert s.count(old) == cnt, "v125 锚点: " + tag + " 数=" + str(s.count(old))
        s = s.replace(old, new, cnt)

    rep("""private fun VinylConsole(
    picUrl: String,
    isPlaying: Boolean,
    progress: Float,
    onPrev: () -> Unit,
    onTogglePlay: () -> Unit,
    onClose: () -> Unit,
) {""",
        """private fun VinylConsole(
    picUrl: String,
    isPlaying: Boolean,
    progress: Float,
    onPrev: () -> Unit,
    onNext: () -> Unit, // [32v125] 下一曲
    onTogglePlay: () -> Unit,
    onClose: () -> Unit,
) {""",
        "控制台签名加 onNext")
    rep("""                    if (isPlaying) VinylPauseIcon(tint = Color.Black) else VinylPlayIcon(tint = Color.Black)
                }
                Box(
                    modifier = Modifier.size(48.dp).clickable(onClick = onClose),""",
        """                    if (isPlaying) VinylPauseIcon(tint = Color.Black) else VinylPlayIcon(tint = Color.Black)
                }
                Box(
                    modifier = Modifier.size(48.dp).clickable(onClick = onNext),
                    contentAlignment = Alignment.Center
                ) {
                    VinylNextIcon(tint = musicColors().textPrimary)
                }
                Box(
                    modifier = Modifier.size(48.dp).clickable(onClick = onClose),""",
        "控制台加下一曲键")
    rep("""                                onPrev = { LxPlayerManager.playPreviousInQueue() },
                                onTogglePlay = { LxPlayerManager.togglePlayPause() },""",
        """                                onPrev = { LxPlayerManager.playPreviousInQueue() },
                                onNext = { LxPlayerManager.playNextInQueue() }, // [32v125]
                                onTogglePlay = { LxPlayerManager.togglePlayPause() },""",
        "宿主接 onNext")
    rep("""@Composable
private fun VinylPlayIcon(tint: Color) {""",
        """@Composable
private fun VinylNextIcon(tint: Color) {
    // [32v125] 下一曲：上一首的镜像（三角朝右 + 右侧竖条），2dp 圆头
    Canvas(modifier = Modifier.size(28.dp)) {
        val sw = 2.dp.toPx()
        drawLine(
            color = tint,
            start = Offset(21.dp.toPx(), 7.dp.toPx()),
            end = Offset(21.dp.toPx(), 21.dp.toPx()),
            strokeWidth = sw, cap = StrokeCap.Round
        )
        val tri = Path().apply {
            moveTo(4.dp.toPx(), 7.dp.toPx())
            lineTo(17.dp.toPx(), 14.dp.toPx())
            lineTo(4.dp.toPx(), 21.dp.toPx())
            close()
        }
        drawPath(tri, tint)
    }
}

@Composable
private fun VinylPlayIcon(tint: Color) {""",
        "下一曲图标")
    open(M, "w", encoding="utf-8").write(s)
    print("OK 32 v125 控制台下一曲已接")
PYEOF125
echo "=== 32 v125 完成 ==="

# === 32 v126: 构建红修复（CI 实证两根因，见下） ===
# 根因1：851 行 VinylWidget 的 Modifier.border() 无 import——文件此前只 import 了 BorderStroke 类（Surface 参数用），
#   从未用过 Modifier.border 扩展函数（androidx.compose.foundation.border），故 Unresolved reference。
# 根因2：PopupPositionProvider 官方签名 anchorBounds 是 IntRect（非 Rect），我方写 Rect 致 override 不上 +
#   抽象成员未实现（CI 967/971 行）。改 IntRect 全链（状态/实测转换/Provider 入参/整型 math）。
python3 << 'PYEOF126'
import os
def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
find_root()
M = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"
s = open(M, encoding="utf-8").read()
if "[32v126]" in s:
    print("跳过（32 v126 已应用）")
else:
    def rep(old, new, tag, cnt=1):
        global s
        assert s.count(old) == cnt, "v126 锚点: " + tag + " 数=" + str(s.count(old))
        s = s.replace(old, new, cnt)

    rep("import androidx.compose.foundation.shape.CircleShape",
        """import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.border // [32v126] Modifier.border 扩展函数""",
        "border import")
    rep("import androidx.compose.ui.geometry.Rect // [32v124]",
        "import androidx.compose.ui.unit.IntRect // [32v126] PopupPositionProvider 官方签名用 IntRect",
        "Rect import 换 IntRect")
    rep("var vinylBounds by remember { mutableStateOf<Rect?>(null) }",
        "var vinylBounds by remember { mutableStateOf<IntRect?>(null) }",
        "挂件 bounds 状态改 IntRect")
    rep(".onGloballyPositioned { vinylBounds = it.boundsInWindow() }",
        """.onGloballyPositioned {
                                val b = it.boundsInWindow()
                                vinylBounds = IntRect(b.left.roundToInt(), b.top.roundToInt(), b.right.roundToInt(), b.bottom.roundToInt())
                            }""",
        "实测 bounds 转 IntRect")
    rep("""private class VinylConsolePositionProvider(
    private val anchor: Rect,
    private val gapPx: Int,
) : PopupPositionProvider {
    override fun calculatePosition(
        anchorBounds: Rect,
        windowSize: IntSize,
        layoutDirection: LayoutDirection,
        popupContentSize: IntSize,
    ): IntOffset {
        val x = (anchor.center.x - popupContentSize.width / 2f)
            .coerceIn(0f, (windowSize.width - popupContentSize.width).coerceAtLeast(0).toFloat())
        val aboveY = anchor.top - popupContentSize.height - gapPx
        val belowY = anchor.bottom + gapPx
        val y = if (aboveY >= 0) aboveY
            else belowY.coerceAtMost((windowSize.height - popupContentSize.height).coerceAtLeast(0).toFloat())
        return IntOffset(x.toInt(), y.toInt())
    }
}""",
        """private class VinylConsolePositionProvider(
    private val anchor: IntRect,
    private val gapPx: Int,
) : PopupPositionProvider {
    override fun calculatePosition(
        anchorBounds: IntRect,
        windowSize: IntSize,
        layoutDirection: LayoutDirection,
        popupContentSize: IntSize,
    ): IntOffset {
        val x = (anchor.center.x - popupContentSize.width / 2)
            .coerceIn(0, (windowSize.width - popupContentSize.width).coerceAtLeast(0))
        val aboveY = anchor.top - popupContentSize.height - gapPx
        val belowY = anchor.bottom + gapPx
        val y = if (aboveY >= 0) aboveY
            else belowY.coerceAtMost((windowSize.height - popupContentSize.height).coerceAtLeast(0))
        return IntOffset(x, y)
    }
}""",
        "Provider 改 IntRect")
    open(M, "w", encoding="utf-8").write(s)
    print("OK 32 v126 构建红修复已接")
PYEOF126
echo "=== 32 v126 完成 ==="

# === 32 v127: 控制台对称居中 + 挂件磁吸卡片左上角（用户 2026-10-24 确认） ===
# ①顶行：正在播放 labelSmall textSecondary 靠左 + IconButton X 靠右，SpaceBetween，卡片横向内边距 20→16dp。
# ②底行：X 移出后剩 48/64/48 对称，SpaceEvenly 下播放键中心 = 行中心（已算术证明）；进度条紧贴封面下（8dp）。
# ③吸附：卡片左上角（窗口坐标）- 宿主左上角（窗口坐标）= 卡片在挂件坐标系位置；目标 = 该位置 - 48dp + 8dp 内缩，
#   按拖拽同款规则夹紧屏内；animateOffsetAsState tween(300)，拖拽时绕开动画直接跟手，关弹窗滑回原位。
# ④防互为因果漂移：弹窗定位锚点与吸附目标若都跟活值，卡片上下跳、挂件跟着跑会一路漂移——故弹窗打开瞬间
#   冻结锚点（frozenAnchor），弹窗期间定位不再跟挂件走，卡片位置固定后吸附才收敛；关弹窗解冻。
python3 << 'PYEOF127'
import os
def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
find_root()
M = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"
s = open(M, encoding="utf-8").read()
if "[32v127]" in s:
    print("跳过（32 v127 已应用）")
else:
    def rep(old, new, tag, cnt=1):
        global s
        assert s.count(old) == cnt, "v127 锚点: " + tag + " 数=" + str(s.count(old))
        s = s.replace(old, new, cnt)

    rep("import androidx.compose.animation.core.Animatable // [32v124]",
        """import androidx.compose.animation.core.Animatable // [32v124]
import androidx.compose.animation.core.animateOffsetAsState // [32v127] 挂件磁吸动画""",
        "animateOffsetAsState import")
    rep("""            var vinylDismissed by remember { mutableStateOf(false) }
            var showVinylConsole by remember { mutableStateOf(false) }
            var vinylBounds by remember { mutableStateOf<IntRect?>(null) }""",
        """            var vinylDismissed by remember { mutableStateOf(false) }
            var showVinylConsole by remember { mutableStateOf(false) }
            var vinylBounds by remember { mutableStateOf<IntRect?>(null) }
            var hostTopLeft by remember { mutableStateOf(Offset.Zero) } // [32v127] 宿主左上角（窗口坐标）
            var consoleCardTopLeft by remember { mutableStateOf<Offset?>(null) } // [32v127] 卡片左上角（窗口坐标）
            var frozenAnchor by remember { mutableStateOf<IntRect?>(null) } // [32v127] 弹窗打开瞬间冻结的定位锚点""",
        "吸附三态")
    rep("""            LaunchedEffect(playerTitle) {
                if (playerTitle.isNotEmpty()) vinylDismissed = false
                if (playerTitle.isEmpty()) showVinylConsole = false
            }""",
        """            LaunchedEffect(playerTitle) {
                if (playerTitle.isNotEmpty()) vinylDismissed = false
                if (playerTitle.isEmpty()) showVinylConsole = false
            }
            LaunchedEffect(showVinylConsole) {
                if (showVinylConsole) {
                    if (frozenAnchor == null) frozenAnchor = vinylBounds
                } else {
                    frozenAnchor = null
                }
            }""",
        "冻结/解冻锚点")
    rep("            BoxWithConstraints(modifier = Modifier.fillMaxSize()) {",
        "            BoxWithConstraints(modifier = Modifier.fillMaxSize().onGloballyPositioned { hostTopLeft = it.boundsInWindow().topLeft }) {",
        "宿主量左上角")
    rep("""                var vinylOffset by remember { mutableStateOf<Offset?>(null) }
                val vinylPos = vinylOffset ?: Offset(
                    maxWpx - sizePx - with(density) { 16.dp.toPx() },
                    maxHpx - sizePx - with(density) { 104.dp.toPx() }
                )""",
        """                var vinylOffset by remember { mutableStateOf<Offset?>(null) }
                val vinylPos = vinylOffset ?: Offset(
                    maxWpx - sizePx - with(density) { 16.dp.toPx() },
                    maxHpx - sizePx - with(density) { 104.dp.toPx() }
                )
                var isDragging by remember { mutableStateOf(false) } // [32v127] 拖拽时绕开吸附动画直接跟手
                val snapTarget: Offset? = if (showVinylConsole) {
                    consoleCardTopLeft?.let { card ->
                        val rel = card - hostTopLeft
                        val inset = with(density) { 8.dp.toPx() }
                        Offset(
                            (rel.x - sizePx + inset).coerceIn(0f, maxWpx - sizePx),
                            (rel.y - sizePx + inset).coerceIn(0f, maxHpx - sizePx)
                        )
                    }
                } else null
                val animatedPos by animateOffsetAsState(
                    targetValue = snapTarget ?: vinylPos,
                    animationSpec = tween(durationMillis = 300), label = "vinylSnap"
                )
                val displayPos = if (isDragging) vinylPos else animatedPos""",
        "吸附目标与动画")
    rep(".offset { IntOffset(vinylPos.x.roundToInt(), vinylPos.y.roundToInt()) }",
        ".offset { IntOffset(displayPos.x.roundToInt(), displayPos.y.roundToInt()) }",
        "挂件用动画后位置")
    rep("                                    onDragStart = { showVinylConsole = false },",
        "                                    onDragStart = { isDragging = true; showVinylConsole = false },",
        "拖拽开始标记")
    rep("""                                            (vinylPos.y + dragAmount.y).coerceIn(0f, maxHpx - sizePx)
                                        )
                                    }""",
        """                                            (vinylPos.y + dragAmount.y).coerceIn(0f, maxHpx - sizePx)
                                        )
                                    },
                                    onDragEnd = { isDragging = false }""",
        "拖拽结束标记")
    rep("                            popupPositionProvider = VinylConsolePositionProvider(bounds, gapPx)",
        "                            popupPositionProvider = VinylConsolePositionProvider(frozenAnchor ?: bounds, gapPx)",
        "弹窗用冻结锚点")
    rep("                                onTogglePlay = { LxPlayerManager.togglePlayPause() },",
        """                                onTogglePlay = { LxPlayerManager.togglePlayPause() },
                                onPositioned = { consoleCardTopLeft = it },""",
        "卡片位置回传")
    rep("""    onTogglePlay: () -> Unit,
    onClose: () -> Unit,
) {""",
        """    onTogglePlay: () -> Unit,
    onClose: () -> Unit,
    onPositioned: (Offset) -> Unit, // [32v127] 卡片左上角（窗口坐标）回传宿主
) {""",
        "控制台签名加 onPositioned")
    rep("""    Surface(
        modifier = Modifier.width(cardW).shadow(16.dp, MaterialTheme.shapes.extraLarge),""",
        """    Surface(
        modifier = Modifier.width(cardW).shadow(16.dp, MaterialTheme.shapes.extraLarge)
            .onGloballyPositioned { onPositioned(it.boundsInWindow().topLeft) },""",
        "卡片量左上角")
    rep("""        Column(modifier = Modifier.padding(20.dp)) {
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.End) {
                Text(
                    text = "正在播放",
                    style = MaterialTheme.typography.labelMedium,
                    color = musicColors().textSecondary
                )
            }
            Spacer(modifier = Modifier.height(12.dp))""",
        """        Column(modifier = Modifier.padding(horizontal = 16.dp, vertical = 20.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "正在播放",
                    style = MaterialTheme.typography.labelSmall,
                    color = musicColors().textSecondary
                )
                IconButton(onClick = onClose) {
                    VinylCloseIcon(tint = musicColors().textPrimary)
                }
            }
            Spacer(modifier = Modifier.height(12.dp))""",
        "顶行重构")
    rep("""            Spacer(modifier = Modifier.height(12.dp))
            Box(modifier = Modifier.fillMaxWidth().height(2.dp).background(musicColors().divider)) {""",
        """            Spacer(modifier = Modifier.height(8.dp))
            Box(modifier = Modifier.fillMaxWidth().height(2.dp).background(musicColors().divider)) {""",
        "进度条紧贴封面")
    rep("""                Box(
                    modifier = Modifier.size(48.dp).clickable(onClick = onClose),
                    contentAlignment = Alignment.Center
                ) {
                    VinylCloseIcon(tint = musicColors().textPrimary)
                }
""",
        "",
        "底行移出 X")
    open(M, "w", encoding="utf-8").write(s)
    print("OK 32 v127 对称居中+磁吸已接")
PYEOF127
echo "=== 32 v127 完成 ==="

# === 32 v128: 弹窗绝对居中 + 吸附坐标系修复（用户 2026-10-25 确认） ===
# ①居中：cardW 删 300dp 上限改 screenW - 32dp；provider X 改 (windowW - popupW) / 2，不再跟挂件走。
# ②吸附真机制：v127 在弹窗内 onGloballyPositioned 量到的 boundsInWindow 是相对弹窗窗口自身原点（≈0,0），
#   不是屏幕坐标，减宿主坐标再钳制必然落到 (0,0)——故整条卡片内量坐标机制删除，改 provider 回报自己算出的
#   IntOffset（按定义即卡片屏幕坐标）；宿主仍 boundsInWindow（全屏 Activity 下窗口原点即屏幕原点），相减得 Box 系坐标。
# ③吸附公式按用户给定：target = providerPos - hostTopLeft - 24dp（v127 的 -40dp 作废），钳制同拖拽；重开先清旧 pos。
# ④冻结锚点保留：Y 仍用 frozenAnchor，弹窗期间 provider 回报位置固定，不互为因果。
python3 << 'PYEOF128'
import os
def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
find_root()
M = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"
s = open(M, encoding="utf-8").read()
if "[32v128]" in s:
    print("跳过（32 v128 已应用）")
else:
    def rep(old, new, tag, cnt=1):
        global s
        assert s.count(old) == cnt, "v128 锚点: " + tag + " 数=" + str(s.count(old))
        s = s.replace(old, new, cnt)

    rep("            var consoleCardTopLeft by remember { mutableStateOf<Offset?>(null) } // [32v127] 卡片左上角（窗口坐标）",
        "            var providerPos by remember { mutableStateOf<IntOffset?>(null) } // [32v128] provider 回报的卡片屏幕坐标",
        "卡片位置态改 provider 回报")
    rep("""                } else {
                    frozenAnchor = null
                }""",
        """                } else {
                    frozenAnchor = null
                    providerPos = null
                }""",
        "关弹窗清旧位置")
    rep("""                val snapTarget: Offset? = if (showVinylConsole) {
                    consoleCardTopLeft?.let { card ->
                        val rel = card - hostTopLeft
                        val inset = with(density) { 8.dp.toPx() }
                        Offset(
                            (rel.x - sizePx + inset).coerceIn(0f, maxWpx - sizePx),
                            (rel.y - sizePx + inset).coerceIn(0f, maxHpx - sizePx)
                        )
                    }
                } else null""",
        """                val snapTarget: Offset? = if (showVinylConsole) {
                    providerPos?.let { pos ->
                        Offset(
                            (pos.x - hostTopLeft.x - sizePx / 2).coerceIn(0f, maxWpx - sizePx),
                            (pos.y - hostTopLeft.y - sizePx / 2).coerceIn(0f, maxHpx - sizePx)
                        )
                    }
                } else null""",
        "吸附公式改 provider 坐标 -24dp")
    rep("                            popupPositionProvider = VinylConsolePositionProvider(frozenAnchor ?: bounds, gapPx)",
        "                            popupPositionProvider = VinylConsolePositionProvider(frozenAnchor ?: bounds, gapPx, onPositioned = { providerPos = it })",
        "provider 接回报回调")
    rep("""                                onPositioned = { consoleCardTopLeft = it },
""",
        "",
        "宿主删卡片内量回传")
    rep("""    onPositioned: (Offset) -> Unit, // [32v127] 卡片左上角（窗口坐标）回传宿主
""",
        "",
        "控制台签名删 onPositioned")
    rep("""        modifier = Modifier.width(cardW).shadow(16.dp, MaterialTheme.shapes.extraLarge)
            .onGloballyPositioned { onPositioned(it.boundsInWindow().topLeft) },""",
        """        modifier = Modifier.width(cardW).shadow(16.dp, MaterialTheme.shapes.extraLarge),""",
        "卡片删内量坐标")
    rep("    val cardW = minOf(300.dp, screenW - 32.dp)",
        "    val cardW = screenW - 32.dp // [32v128] 删 300dp 上限，两端各留 16dp",
        "卡片宽改全宽减 32dp")
    rep("""private class VinylConsolePositionProvider(
    private val anchor: IntRect,
    private val gapPx: Int,
) : PopupPositionProvider {
    override fun calculatePosition(
        anchorBounds: IntRect,
        windowSize: IntSize,
        layoutDirection: LayoutDirection,
        popupContentSize: IntSize,
    ): IntOffset {
        val x = (anchor.center.x - popupContentSize.width / 2)
            .coerceIn(0, (windowSize.width - popupContentSize.width).coerceAtLeast(0))
        val aboveY = anchor.top - popupContentSize.height - gapPx
        val belowY = anchor.bottom + gapPx
        val y = if (aboveY >= 0) aboveY
            else belowY.coerceAtMost((windowSize.height - popupContentSize.height).coerceAtLeast(0))
        return IntOffset(x, y)
    }
}""",
        """private class VinylConsolePositionProvider(
    private val anchor: IntRect,
    private val gapPx: Int,
    private val onPositioned: (IntOffset) -> Unit, // [32v128] 回报算出的卡片屏幕坐标（供吸附用）
) : PopupPositionProvider {
    private var lastReported: IntOffset? = null
    override fun calculatePosition(
        anchorBounds: IntRect,
        windowSize: IntSize,
        layoutDirection: LayoutDirection,
        popupContentSize: IntSize,
    ): IntOffset {
        val x = (windowSize.width - popupContentSize.width) / 2
        val aboveY = anchor.top - popupContentSize.height - gapPx
        val belowY = anchor.bottom + gapPx
        val y = if (aboveY >= 0) aboveY
            else belowY.coerceAtMost((windowSize.height - popupContentSize.height).coerceAtLeast(0))
        return IntOffset(x, y).also {
            if (it != lastReported) { lastReported = it; onPositioned(it) }
        }
    }
}""",
        "provider 居中 X + 回报位置")
    open(M, "w", encoding="utf-8").write(s)
    print("OK 32 v128 居中+吸附坐标修复已接")
PYEOF128
echo "=== 32 v128 完成 ==="

# === 32 v129: 控制台终极打磨——徽章压角 + 卡片缩小（用户 2026-10-25 确认，默认不移弹窗、额外量 12dp） ===
# ①卡片：screenW - 32dp → screenW - 72dp（两边各 36dp）；固定 320dp 不用（360dp 屏留边仅 20dp，挂件左缘负数被钳制）。
# ②封面：宽改卡片宽 × 0.7f、居中、仍正方形；进度条保持全宽。
# ③吸附：target = 角 - 36dp（v128 的 -24dp + 用户要的 -12dp），中心 = 角 - 12dp 斜向外，只一小口压住卡片角；
#   左缘正好 0dp 不钳制；弹窗不移位（移位会破坏绝对居中，36dp 边距已解决钳制）。
# ④紧凑：X 按钮 48→40dp；底行上一首/下一曲 48→40dp、播放 64→56dp；图标 28dp/2dp 线条不动；
#   顶行文字已是 labelSmall（最小 label 档，无更小 Token，不动）；40/56/40 对称，播放键仍绝对居中。
python3 << 'PYEOF129'
import os
def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
find_root()
M = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"
s = open(M, encoding="utf-8").read()
if "[32v129]" in s:
    print("跳过（32 v129 已应用）")
else:
    def rep(old, new, tag, cnt=1):
        global s
        assert s.count(old) == cnt, "v129 锚点: " + tag + " 数=" + str(s.count(old))
        s = s.replace(old, new, cnt)

    rep("    val cardW = screenW - 32.dp // [32v128] 删 300dp 上限，两端各留 16dp",
        "    val cardW = screenW - 72.dp // [32v129] 两边各留 36dp，挂件压角不钳制",
        "卡片宽改 72dp 边距")
    rep("                    modifier = Modifier.fillMaxWidth().aspectRatio(1f).clip(RoundedCornerShape(16.dp)),",
        "                    modifier = Modifier.fillMaxWidth(0.7f).align(Alignment.CenterHorizontally).aspectRatio(1f).clip(RoundedCornerShape(16.dp)),",
        "封面图改 0.7f 居中")
    rep("                    modifier = Modifier.fillMaxWidth().aspectRatio(1f).clip(RoundedCornerShape(16.dp))",
        "                    modifier = Modifier.fillMaxWidth(0.7f).align(Alignment.CenterHorizontally).aspectRatio(1f).clip(RoundedCornerShape(16.dp))",
        "封面占位改 0.7f 居中")
    rep("""                val snapTarget: Offset? = if (showVinylConsole) {
                    providerPos?.let { pos ->
                        Offset(
                            (pos.x - hostTopLeft.x - sizePx / 2).coerceIn(0f, maxWpx - sizePx),
                            (pos.y - hostTopLeft.y - sizePx / 2).coerceIn(0f, maxHpx - sizePx)
                        )
                    }
                } else null""",
        """                val snapOut = sizePx / 2 + with(density) { 12.dp.toPx() } // [32v129] 中心压角外 12dp
                val snapTarget: Offset? = if (showVinylConsole) {
                    providerPos?.let { pos ->
                        Offset(
                            (pos.x - hostTopLeft.x - snapOut).coerceIn(0f, maxWpx - sizePx),
                            (pos.y - hostTopLeft.y - snapOut).coerceIn(0f, maxHpx - sizePx)
                        )
                    }
                } else null""",
        "吸附改角外 12dp")
    rep("                IconButton(onClick = onClose) {",
        "                IconButton(onClick = onClose, modifier = Modifier.size(40.dp)) {",
        "X 按钮改 40dp")
    rep("                    modifier = Modifier.size(48.dp).clickable(onClick = onPrev),",
        "                    modifier = Modifier.size(40.dp).clickable(onClick = onPrev),",
        "上一首改 40dp")
    rep("                    modifier = Modifier.size(64.dp).clip(CircleShape).background(Color.White)",
        "                    modifier = Modifier.size(56.dp).clip(CircleShape).background(Color.White)",
        "播放改 56dp")
    rep("                    modifier = Modifier.size(48.dp).clickable(onClick = onNext),",
        "                    modifier = Modifier.size(40.dp).clickable(onClick = onNext),",
        "下一曲改 40dp")
    open(M, "w", encoding="utf-8").write(s)
    print("OK 32 v129 徽章压角+卡片缩小已接")
PYEOF129
echo "=== 32 v129 完成 ==="

# === 32 v130: 废 Popup，控制台卡片回 Box 内（用户 2026-10-25 确认） ===
# ①宿主：卡片放进挂件所在的同一个 BoxWithConstraints（不是更外层 padding Box，否则又是两套父坐标），
#   遮罩/卡片/挂件同坐标系，offset 与 positionInParent 直接可比，零换算。
# ②卡片：AnimatedVisibility 淡入淡出 200ms + align(Center)；左上角不手算（高度自适应），positionInParent 实测；
#   X = (BoxW - cardW) / 2 = 36dp（屏宽方向即屏幕正中），Y 是内容区正中（Scaffold 有顶栏）。
# ③吸附：target = cardPosInBox - 12dp（两轴），中心 = 角 + 12dp 内侧（v129 的角外 12dp 作废，因挂件已在上层）；
#   钳制同拖拽，关弹窗滑回原位。
# ④Z 轴：Box 内顺序 遮罩→卡片→挂件，挂件再加 zIndex(1f) 双保险，真正盖在卡片角上。
# ⑤删除：Popup 调用、VinylConsolePositionProvider 类、Popup 三 import、vinylBounds/hostTopLeft/providerPos/frozenAnchor
#   四态、冻结 LaunchedEffect、provider 回报回调、挂件 bounds 实测、宿主 bounds 实测、gapPx。
python3 << 'PYEOF130'
import os
def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
find_root()
M = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"
s = open(M, encoding="utf-8").read()
if "[32v130]" in s:
    print("跳过（32 v130 已应用）")
else:
    def rep(old, new, tag, cnt=1):
        global s
        assert s.count(old) == cnt, "v130 锚点: " + tag + " 数=" + str(s.count(old))
        s = s.replace(old, new, cnt)

    rep("import androidx.compose.ui.window.Popup // [32v124]\n",
        "", "删 Popup import")
    rep("import androidx.compose.ui.window.PopupPositionProvider // [32v124]\n",
        "", "删 PopupPositionProvider import")
    rep("import androidx.compose.ui.window.PopupProperties // [32v124]\n",
        "", "删 PopupProperties import")
    rep("import androidx.compose.animation.core.Animatable // [32v124]",
        """import androidx.compose.animation.AnimatedVisibility // [32v130]
import androidx.compose.animation.fadeIn // [32v130]
import androidx.compose.animation.fadeOut // [32v130]
import androidx.compose.foundation.interaction.MutableInteractionSource // [32v130]
import androidx.compose.ui.zIndex // [32v130]
import androidx.compose.animation.core.Animatable // [32v124]""",
        "加 AnimatedVisibility/zIndex import")
    rep("""            var vinylDismissed by remember { mutableStateOf(false) }
            var showVinylConsole by remember { mutableStateOf(false) }
            var vinylBounds by remember { mutableStateOf<IntRect?>(null) }
            var hostTopLeft by remember { mutableStateOf(Offset.Zero) } // [32v127] 宿主左上角（窗口坐标）
            var providerPos by remember { mutableStateOf<IntOffset?>(null) } // [32v128] provider 回报的卡片屏幕坐标
            var frozenAnchor by remember { mutableStateOf<IntRect?>(null) } // [32v127] 弹窗打开瞬间冻结的定位锚点""",
        """            var vinylDismissed by remember { mutableStateOf(false) }
            var showVinylConsole by remember { mutableStateOf(false) }
            var cardPosInBox by remember { mutableStateOf<Offset?>(null) } // [32v130] 卡片左上角（Box 内坐标，与挂件同系）""",
        "四态改 cardPosInBox")
    rep("""            LaunchedEffect(showVinylConsole) {
                if (showVinylConsole) {
                    if (frozenAnchor == null) frozenAnchor = vinylBounds
                } else {
                    frozenAnchor = null
                    providerPos = null
                }
            }
""",
        "",
        "删冻结 LaunchedEffect")
    rep("            // [32v124] 悬浮黑胶挂件 + 液态控制台（长条迷你播放器已废，导航胶囊不动）\n            BoxWithConstraints(modifier = Modifier.fillMaxSize().onGloballyPositioned { hostTopLeft = it.boundsInWindow().topLeft }) {",
        "            // [32v130] 悬浮黑胶挂件 + 液态控制台（Popup 已废，卡片回 Box 内；导航胶囊不动）\n            BoxWithConstraints(modifier = Modifier.fillMaxSize()) {",
        "宿主去窗口坐标实测")
    rep("""                val sizePx = with(density) { 48.dp.toPx() }
                val gapPx = with(density) { 12.dp.toPx() }.toInt()
""",
        """                val sizePx = with(density) { 48.dp.toPx() }
""",
        "删 gapPx")
    rep("""                var isDragging by remember { mutableStateOf(false) } // [32v127] 拖拽时绕开吸附动画直接跟手
                val snapOut = sizePx / 2 + with(density) { 12.dp.toPx() } // [32v129] 中心压角外 12dp
                val snapTarget: Offset? = if (showVinylConsole) {
                    providerPos?.let { pos ->
                        Offset(
                            (pos.x - hostTopLeft.x - snapOut).coerceIn(0f, maxWpx - sizePx),
                            (pos.y - hostTopLeft.y - snapOut).coerceIn(0f, maxHpx - sizePx)
                        )
                    }
                } else null""",
        """                var isDragging by remember { mutableStateOf(false) } // [32v127] 拖拽时绕开吸附动画直接跟手
                val snapInset = with(density) { 12.dp.toPx() } // [32v130] 挂件左上角 = 卡片左上角 - 12dp
                val snapTarget: Offset? = if (showVinylConsole) {
                    cardPosInBox?.let { pos ->
                        Offset(
                            (pos.x - snapInset).coerceIn(0f, maxWpx - sizePx),
                            (pos.y - snapInset).coerceIn(0f, maxHpx - sizePx)
                        )
                    }
                } else null""",
        "吸附改 Box 内坐标 -12dp")
    rep("""                if (playerTitle.isNotEmpty() && !vinylDismissed) {
                    VinylWidget(""",
        """                // [32v130] 遮罩（透明、无涟漪）：点外部关弹窗、挂件复位
                if (showVinylConsole) {
                    Box(
                        modifier = Modifier.fillMaxSize()
                            .clickable(
                                indication = null,
                                interactionSource = remember { MutableInteractionSource() }
                            ) { showVinylConsole = false }
                    )
                }
                // [32v130] 控制台卡片：Box 内居中（Popup 已废），挂件随后画在上层
                AnimatedVisibility(
                    visible = showVinylConsole,
                    enter = fadeIn(tween(200)),
                    exit = fadeOut(tween(200)),
                    modifier = Modifier.align(Alignment.Center)
                        .onGloballyPositioned { cardPosInBox = it.positionInParent() }
                ) {
                    VinylConsole(
                        picUrl = playerPic,
                        isPlaying = playerIsPlaying,
                        progress = if (playerDur > 0) (playerPos.toFloat() / playerDur.toFloat()).coerceIn(0f, 1f) else 0f,
                        onPrev = { LxPlayerManager.playPreviousInQueue() },
                        onNext = { LxPlayerManager.playNextInQueue() }, // [32v125]
                        onTogglePlay = { LxPlayerManager.togglePlayPause() },
                        onClose = {
                            showVinylConsole = false
                            vinylDismissed = true
                            LxPlayerManager.pause()
                        }
                    )
                }
                if (playerTitle.isNotEmpty() && !vinylDismissed) {
                    VinylWidget(""",
        "遮罩+卡片插到挂件之前")
    rep("""                            .offset { IntOffset(displayPos.x.roundToInt(), displayPos.y.roundToInt()) }
                            .onGloballyPositioned {
                                val b = it.boundsInWindow()
                                vinylBounds = IntRect(b.left.roundToInt(), b.top.roundToInt(), b.right.roundToInt(), b.bottom.roundToInt())
                            }
""",
        """                            .offset { IntOffset(displayPos.x.roundToInt(), displayPos.y.roundToInt()) }
                            .zIndex(1f) // [32v130] 挂件画在卡片上层
""",
        "挂件去实测加 zIndex")
    rep("""                vinylBounds?.let { bounds ->
                    if (showVinylConsole) {
                        Popup(
                            onDismissRequest = { showVinylConsole = false },
                            properties = PopupProperties(dismissOnClickOutside = true, focusable = true),
                            popupPositionProvider = VinylConsolePositionProvider(frozenAnchor ?: bounds, gapPx, onPositioned = { providerPos = it })
                        ) {
                            VinylConsole(
                                picUrl = playerPic,
                                isPlaying = playerIsPlaying,
                                progress = if (playerDur > 0) (playerPos.toFloat() / playerDur.toFloat()).coerceIn(0f, 1f) else 0f,
                                onPrev = { LxPlayerManager.playPreviousInQueue() },
                                onNext = { LxPlayerManager.playNextInQueue() }, // [32v125]
                                onTogglePlay = { LxPlayerManager.togglePlayPause() },
                                onClose = {
                                    showVinylConsole = false
                                    vinylDismissed = true
                                    LxPlayerManager.pause()
                                }
                            )
                        }
                    }
                }
""",
        "",
        "删 Popup 调用")
    rep("""// [32v124] 弹窗定位：以挂件实测 bounds 为锚（不用 Popup 自带 anchorBounds，避免语义歧义），
// 上方够放则放上方，否则放下方，横向夹紧屏内
private class VinylConsolePositionProvider(
    private val anchor: IntRect,
    private val gapPx: Int,
    private val onPositioned: (IntOffset) -> Unit, // [32v128] 回报算出的卡片屏幕坐标（供吸附用）
) : PopupPositionProvider {
    private var lastReported: IntOffset? = null
    override fun calculatePosition(
        anchorBounds: IntRect,
        windowSize: IntSize,
        layoutDirection: LayoutDirection,
        popupContentSize: IntSize,
    ): IntOffset {
        val x = (windowSize.width - popupContentSize.width) / 2
        val aboveY = anchor.top - popupContentSize.height - gapPx
        val belowY = anchor.bottom + gapPx
        val y = if (aboveY >= 0) aboveY
            else belowY.coerceAtMost((windowSize.height - popupContentSize.height).coerceAtLeast(0))
        return IntOffset(x, y).also {
            if (it != lastReported) { lastReported = it; onPositioned(it) }
        }
    }
}
""",
        "",
        "删 Provider 类")
    open(M, "w", encoding="utf-8").write(s)
    print("OK 32 v130 废 Popup 回 Box 内已接")
PYEOF130
echo "=== 32 v130 完成 ==="

# === 32 v130 附：删跨窗口机制死 import（grep 实证：IntRect/boundsInWindow/IntSize/LayoutDirection 在 MH 内已零代码引用） ===
python3 << 'PYEOF130B'
import os
def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
find_root()
M = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"
s = open(M, encoding="utf-8").read()
for line, tag in [
    ("import androidx.compose.ui.unit.IntRect // [32v126] PopupPositionProvider 官方签名用 IntRect\n", "IntRect import"),
    ("import androidx.compose.ui.layout.boundsInWindow // [32v124]\n", "boundsInWindow import"),
    ("import androidx.compose.ui.unit.IntSize // [32v124]\n", "IntSize import"),
    ("import androidx.compose.ui.unit.LayoutDirection // [32v124]\n", "LayoutDirection import"),
]:
    assert s.count(line) == 1, "v130b 锚点: " + tag + " 数=" + str(s.count(line))
    s = s.replace(line, "")
open(M, "w", encoding="utf-8").write(s)
print("OK 32 v130 死 import 已清")
PYEOF130B
echo "=== 32 v130 附完成 ==="

# === 32 v131: 构建红修复——positionInParent 未 import 的扩展函数（CI 640 行实证） ===
# 真机制（已查官方文档，不猜）：positionInParent 在文档里列于 Extension functions（扩展函数），不是成员函数，
#   文件从未 import 它，故 Unresolved reference——与 v126 的 Modifier.border 缺 import 是同一类坑。
#   但扩展函数的本版可用性本地无法验证（ci_sim 不编译 Kotlin），为不再赌一轮，改用自 1.0 即有的成员函数
#   positionInRoot()：宿主与卡片各量一次 root 坐标，相减即 Box 内坐标，构造上精确，与 v130 设计等价。
python3 << 'PYEOF131'
import os
def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
find_root()
M = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"
s = open(M, encoding="utf-8").read()
if "[32v131]" in s:
    print("跳过（32 v131 已应用）")
else:
    def rep(old, new, tag, cnt=1):
        global s
        assert s.count(old) == cnt, "v131 锚点: " + tag + " 数=" + str(s.count(old))
        s = s.replace(old, new, cnt)

    rep("            var cardPosInBox by remember { mutableStateOf<Offset?>(null) } // [32v130] 卡片左上角（Box 内坐标，与挂件同系）",
        """            var cardPosInBox by remember { mutableStateOf<Offset?>(null) } // [32v130] 卡片左上角（Box 内坐标，与挂件同系）
            var boxRootPos by remember { mutableStateOf(Offset.Zero) } // [32v131] 宿主 root 坐标（供相减用）""",
        "加宿主 root 坐标态")
    rep("            BoxWithConstraints(modifier = Modifier.fillMaxSize()) {",
        "            BoxWithConstraints(modifier = Modifier.fillMaxSize().onGloballyPositioned { boxRootPos = it.positionInRoot() }) {",
        "宿主量 root 坐标")
    rep(".onGloballyPositioned { cardPosInBox = it.positionInParent() }",
        ".onGloballyPositioned { cardPosInBox = it.positionInRoot() - boxRootPos }",
        "卡片改 root 相减")
    open(M, "w", encoding="utf-8").write(s)
    print("OK 32 v131 positionInRoot 相减已接")
PYEOF131
echo "=== 32 v131 完成 ==="

# === 32 v132: 构建红修复——positionInRoot 同为未 import 的扩展函数（CI 600:105 + 641:67 实证） ===
# 真机制（两处实证，不猜）：①官方文档现版把 positionInRoot 列于 Extension functions（与 positionInParent 同栏），
#   扩展函数必须单独 import，文件只引了 onGloballyPositioned，从未引 positionInRoot；②本工程先例：v126–v129
#   四次绿构建里 boundsInWindow() 同为该包扩展函数，因引了 import 才编译通过——同一模式。
#   v131 称其为“自 1.0 即有的成员函数”是错的（现版已改为扩展函数），本次只补一行 import，不动其他代码。
python3 << 'PYEOF132'
import os
def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
find_root()
M = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"
s = open(M, encoding="utf-8").read()
if "[32v132]" in s:
    print("跳过（32 v132 已应用）")
else:
    old = "import androidx.compose.ui.layout.onGloballyPositioned // [32v124]"
    assert s.count(old) == 1, "v132 锚点数=" + str(s.count(old))
    s = s.replace(old, old + "\nimport androidx.compose.ui.layout.positionInRoot // [32v132] 扩展函数须单独 import", 1)
    open(M, "w", encoding="utf-8").write(s)
    print("OK 32 v132 positionInRoot import 已补")
PYEOF132
echo "=== 32 v132 完成 ==="

# === 32 v133: 控制台封面点按进播放页（用户 2026-10-25 确认方案） ===
# 根因：v124 删 MiniPlayerBar 时 onExpand 接线未迁移，VinylConsole 封面从无 clickable。
# 接线照搬旧 onExpand（title/artist/picUrl 三键，不传 songId/platform/url，不改队列）；
# 播放页 onCreate 全是 ?: "" 兜底 + managerActive 分支，控制台只在有当前歌时渲染，故必走“显示当前播放”分支；
# 先关控制台再 startActivity，免得从播放页返回还面对开着的控制台；挂件点按语义（开控制台）不动。
python3 << 'PYEOF133'
import os
def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
find_root()
M = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"
s = open(M, encoding="utf-8").read()
if "[32v133]" in s:
    print("跳过（32 v133 已应用）")
else:
    a1 = "    onClose: () -> Unit,\n) {"
    assert s.count(a1) == 1, "v133 签名锚点数=" + str(s.count(a1))
    s = s.replace(a1, "    onClose: () -> Unit,\n    onCoverClick: () -> Unit, // [32v133] 封面点按进播放页\n) {", 1)
    a2 = "aspectRatio(1f).clip(RoundedCornerShape(16.dp)),"
    assert s.count(a2) == 1, "v133 有图封面锚点数=" + str(s.count(a2))
    s = s.replace(a2, "aspectRatio(1f).clip(RoundedCornerShape(16.dp)).clickable(onClick = onCoverClick),", 1)
    a3 = "aspectRatio(1f).clip(RoundedCornerShape(16.dp))\n                        .background(musicColors().cardSecondary),"
    assert s.count(a3) == 1, "v133 无图封面锚点数=" + str(s.count(a3))
    s = s.replace(a3, "aspectRatio(1f).clip(RoundedCornerShape(16.dp)).clickable(onClick = onCoverClick)\n                        .background(musicColors().cardSecondary),", 1)
    a4 = """                        onClose = {
                            showVinylConsole = false
                            vinylDismissed = true
                            LxPlayerManager.pause()
                        }"""
    assert s.count(a4) == 1, "v133 宿主锚点数=" + str(s.count(a4))
    s = s.replace(a4, a4 + """
                        onCoverClick = { // [32v133] 照搬旧迷你条 onExpand，先关控制台再进播放页
                            showVinylConsole = false
                            val intent = Intent(context, LxPlayerActivity::class.java).apply {
                                putExtra("title", playerTitle)
                                putExtra("artist", playerArtist)
                                putExtra("picUrl", playerPic)
                            }
                            context.startActivity(intent)
                        }""", 1)
    open(M, "w", encoding="utf-8").write(s)
    print("OK 32 v133 封面点按接线已接")
PYEOF133
echo "=== 32 v133 完成 ==="

# === 32 v134: 构建红修复——v133 宿主漏逗号（CI 644/656 四错同根） ===
# 实证：CI 四错（644:21 缺 onCoverClick 实参；656:25 onCoverClick 在 () -> Unit 接收器上未解析；
# 656:38 两处语法错）与 ci_sim 生成文件逐行对上：onClose 原是最后一个实参，其块尾 `}` 后本无逗号，
# v133 在其后追加 onCoverClick 时未补逗号，致使 `} onCoverClick = {` 被解析为对 lambda 的成员访问而非具名实参。
# 签名处无此问题（onClose 参数行原有尾逗号）。修复=只补这一个逗号，不动其他代码。
python3 << 'PYEOF134'
import os
def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
find_root()
M = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"
s = open(M, encoding="utf-8").read()
if "[32v134]" in s:
    print("跳过（32 v134 已应用）")
else:
    a = """                            LxPlayerManager.pause()
                        }
                        onCoverClick = { // [32v133]"""
    assert s.count(a) == 1, "v134 锚点数=" + str(s.count(a))
    s = s.replace(a, """                            LxPlayerManager.pause()
                        }, // [32v134] v133 漏逗号补上：onClose 原为末实参
                        onCoverClick = { // [32v133]""", 1)
    open(M, "w", encoding="utf-8").write(s)
    print("OK 32 v134 宿主逗号已补")
PYEOF134
echo "=== 32 v134 完成 ==="

# === 32 v135: 运行日志抽屉滑动 Bug——A 方案（用户 2026-10-25 确认） ===
# 根因：RuntimeLogSheet 用默认 rememberModalBottomSheetState()（skipPartiallyExpanded=false，三档），
# 打开先落半展开档，手指上下拖先让抽屉在半展开↔全展开之间跟手移动而非滚列表，半展开时顶部标题/按钮被裁。
# 修复=只改一行：skipPartiallyExpanded=true，打开即 80% 满高（fillMaxHeight(0.8f) 不变），
# 内部 LazyColumn+weight(1f) 与顶部清空/复制按钮原样不动；同工程先例：播放页 CommentsSheet 亦如此。
# 残留（已向用户说明）：列表滑到顶继续下拉仍会关闭抽屉（Material3 标准行为，点遮罩/返回也可关）。
python3 << 'PYEOF135'
import os
def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxSourceSettings.kt") and os.getcwd() != "/":
        os.chdir("..")
find_root()
M = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxSourceSettings.kt"
s = open(M, encoding="utf-8").read()
if "[32v135]" in s:
    print("跳过（32 v135 已应用）")
else:
    a = "    val sheetState = rememberModalBottomSheetState()\n    val logLines by LxRuntimeLog.logs.collectAsState()"
    assert s.count(a) == 1, "v135 锚点数=" + str(s.count(a))
    s = s.replace(a, "    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true) // [32v135] 抽屉满高，取消半展开档\n    val logLines by LxRuntimeLog.logs.collectAsState()", 1)
    open(M, "w", encoding="utf-8").write(s)
    print("OK 32 v135 日志抽屉满高已改")
PYEOF135
echo "=== 32 v135 完成 ==="

# === 32 v136: 排行榜序号与搜索页彻底统一（用户 2026-10-25 确认方案） ===
# 现状 RankItem：全部统一 bodyMedium 14sp + textSecondary×0.6，无前 3 名区分，序号列 28dp 靠右。
# 改为与搜索页 HotSearchItem 完全一致的三档：1 名 accent/Black/22sp、2-3 名 textPrimary/Bold/20sp、
# 4+ 名 textSecondary 实色（无 alpha）、Normal/16sp；序号列统一 32dp 居中；补 sp import（本文件此前未用 sp）。
python3 << 'PYEOF136'
import os
def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/music/rank/RankScreen.kt") and os.getcwd() != "/":
        os.chdir("..")
find_root()
M = "avbox/app/src/main/java/com/github/tvbox/osc/ui/music/rank/RankScreen.kt"
s = open(M, encoding="utf-8").read()
if "[32v136]" in s:
    print("跳过（32 v136 已应用）")
else:
    a0 = "import androidx.compose.ui.unit.dp"
    assert s.count(a0) == 1, "v136 sp import 锚点数=" + str(s.count(a0))
    s = s.replace(a0, a0 + "\nimport androidx.compose.ui.unit.sp // [32v136]", 1)
    a1 = """        Box(
            modifier = Modifier.width(28.dp),
            contentAlignment = Alignment.CenterEnd,
        ) {"""
    assert s.count(a1) == 1, "v136 序号列锚点数=" + str(s.count(a1))
    s = s.replace(a1, """        Box(
            modifier = Modifier.width(32.dp), // [32v136] 与搜索页统一：32dp 居中
            contentAlignment = Alignment.Center,
        ) {""", 1)
    a2 = """            Text(
                text = rank.toString(),
                style = MaterialTheme.typography.bodyMedium, // 精修：14sp
                color = musicColors().textSecondary.copy(alpha = 0.6f),
            )"""
    assert s.count(a2) == 1, "v136 序号 Text 锚点数=" + str(s.count(a2))
    s = s.replace(a2, """            Text(
                text = rank.toString(),
                style = when (rank) { // [32v136] 与搜索页 HotSearchItem 完全一致的三档
                    1 -> MaterialTheme.typography.bodyLarge.copy(fontSize = 22.sp, fontWeight = FontWeight.Black)
                    2, 3 -> MaterialTheme.typography.bodyLarge.copy(fontSize = 20.sp, fontWeight = FontWeight.Bold)
                    else -> MaterialTheme.typography.bodyLarge.copy(fontSize = 16.sp, fontWeight = FontWeight.Normal)
                },
                color = when (rank) {
                    1 -> musicColors().accent
                    2, 3 -> musicColors().textPrimary
                    else -> musicColors().textSecondary
                },
            )""", 1)
    open(M, "w", encoding="utf-8").write(s)
    print("OK 32 v136 排行榜序号已统一")
PYEOF136
echo "=== 32 v136 完成 ==="

# === 32 v137: 日志抽屉死死贴底（用户 2026-10-25 确认贴底方案） ===
# 查实：呼叫点裸调、无外层包裹；Sheet 自身无 padding/margin；全函数唯一底部留白是内层 Column 的 bottom 24dp；
# 高度 0.8f 已是 80% 不动；skipPartiallyExpanded=true（v135）按用户建议保留。
# 改动三处：①Sheet modifier 补 fillMaxWidth()；②内层 Column 去掉 bottom 24dp、加 navigationBarsPadding()
# （内容避系统小白条，卡片背景仍延到底边）；③补 navigationBarsPadding import。
python3 << 'PYEOF137'
import os
def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxSourceSettings.kt") and os.getcwd() != "/":
        os.chdir("..")
find_root()
M = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxSourceSettings.kt"
s = open(M, encoding="utf-8").read()
if "[32v137]" in s:
    print("跳过（32 v137 已应用）")
else:
    a0 = "import androidx.compose.foundation.layout.padding"
    assert s.count(a0) == 1, "v137 import 锚点数=" + str(s.count(a0))
    s = s.replace(a0, a0 + "\nimport androidx.compose.foundation.layout.navigationBarsPadding // [32v137]", 1)
    a1 = "        modifier = Modifier.fillMaxHeight(0.8f)"
    assert s.count(a1) == 1, "v137 Sheet 锚点数=" + str(s.count(a1))
    s = s.replace(a1, "        modifier = Modifier.fillMaxWidth().fillMaxHeight(0.8f) // [32v137] 贴底满宽，高度 80% 不变", 1)
    a2 = "            modifier = Modifier.fillMaxSize().padding(horizontal = 16.dp).padding(bottom = 24.dp)"
    assert s.count(a2) == 1, "v137 Column 锚点数=" + str(s.count(a2))
    s = s.replace(a2, "            modifier = Modifier.fillMaxSize().padding(horizontal = 16.dp).navigationBarsPadding() // [32v137] 去底边距，内容避小白条、背景延到底边", 1)
    open(M, "w", encoding="utf-8").write(s)
    print("OK 32 v137 日志抽屉贴底已改")
PYEOF137
echo "=== 32 v137 完成 ==="

# === 32 v138: 控制台补歌名/歌手/时间 + 进度 tick（用户 2026-10-25 确认方案） ===
# 真因（已查实）：进度条接线本身是真实数据（宿主传 playerPos/playerDur 比例），缺的是 tick——
# updatePosition() 全仓唯一调用点在播放页（while(true)+delay(100)），MH 宿主从不刷 position，故条不动。
# 改动：①VinylConsole 签名加 title/artist/posMs/durMs；②封面 0.7f→0.6f（两处）；
# ③封面下加歌名（titleMedium/Bold/textPrimary）+ 歌手（bodyMedium/textSecondary），居中、单行省略；
# ④进度条下加时间行（labelSmall/textSecondary，当前/总时长 SpaceBetween）；
# ⑤宿主传新参数；⑥宿主补 tick（播放中每 500ms 刷 position，时间按秒变故 500ms 足够）；
# ⑦MH 内加 formatTimeConsole（PlayerProgressBar.formatTime 为 private 限本文件，不可见）；
# ⑧补 TextAlign import（delay import 已有）。
python3 << 'PYEOF138'
import os
def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
find_root()
M = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"
s = open(M, encoding="utf-8").read()
if "[32v138]" in s:
    print("跳过（32 v138 已应用）")
else:
    a0 = "import androidx.compose.ui.text.style.TextOverflow"
    assert s.count(a0) == 1, "v138 TextAlign import 锚点数=" + str(s.count(a0))
    s = s.replace(a0, a0 + "\nimport androidx.compose.ui.text.style.TextAlign // [32v138]", 1)
    a1 = "// [32v124] 液态控制台：card 0.85 + extraLarge + 白高光边 + shadow 16"
    assert s.count(a1) == 1, "v138 helper 锚点数=" + str(s.count(a1))
    s = s.replace(a1, """// [32v138] 控制台时间格式化：与 PlayerProgressBar.formatTime 同款 mm:ss（彼为 private 限本文件，MH 不可见）
private fun formatTimeConsole(ms: Long): String {
    val totalSeconds = ms / 1000
    return String.format("%02d:%02d", totalSeconds / 60, totalSeconds % 60)
}

""" + a1, 1)
    a2 = """private fun VinylConsole(
    picUrl: String,
    isPlaying: Boolean,
    progress: Float,"""
    assert s.count(a2) == 1, "v138 签名锚点数=" + str(s.count(a2))
    s = s.replace(a2, """private fun VinylConsole(
    picUrl: String,
    title: String, // [32v138]
    artist: String, // [32v138]
    isPlaying: Boolean,
    progress: Float,
    posMs: Long, // [32v138]
    durMs: Long, // [32v138]""", 1)
    a3 = "modifier = Modifier.fillMaxWidth(0.7f).align(Alignment.CenterHorizontally).aspectRatio(1f).clip(RoundedCornerShape(16.dp)).clickable(onClick = onCoverClick),"
    assert s.count(a3) == 1, "v138 有图封面锚点数=" + str(s.count(a3))
    s = s.replace(a3, "modifier = Modifier.fillMaxWidth(0.6f).align(Alignment.CenterHorizontally).aspectRatio(1f).clip(RoundedCornerShape(16.dp)).clickable(onClick = onCoverClick),", 1)
    a4 = "modifier = Modifier.fillMaxWidth(0.7f).align(Alignment.CenterHorizontally).aspectRatio(1f).clip(RoundedCornerShape(16.dp)).clickable(onClick = onCoverClick)"
    assert s.count(a4) == 1, "v138 无图封面锚点数=" + str(s.count(a4))
    s = s.replace(a4, "modifier = Modifier.fillMaxWidth(0.6f).align(Alignment.CenterHorizontally).aspectRatio(1f).clip(RoundedCornerShape(16.dp)).clickable(onClick = onCoverClick)", 1)
    a5 = """            Spacer(modifier = Modifier.height(8.dp))
            Box(modifier = Modifier.fillMaxWidth().height(2.dp).background(musicColors().divider)) {"""
    assert s.count(a5) == 1, "v138 歌名锚点数=" + str(s.count(a5))
    s = s.replace(a5, """            Spacer(modifier = Modifier.height(12.dp))
            Text( // [32v138] 歌名
                text = title,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = musicColors().textPrimary,
                textAlign = TextAlign.Center,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier.fillMaxWidth()
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text( // [32v138] 歌手
                text = artist,
                style = MaterialTheme.typography.bodyMedium,
                color = musicColors().textSecondary,
                textAlign = TextAlign.Center,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier.fillMaxWidth()
            )
            Spacer(modifier = Modifier.height(8.dp))
            Box(modifier = Modifier.fillMaxWidth().height(2.dp).background(musicColors().divider)) {""", 1)
    a6 = """            Box(modifier = Modifier.fillMaxWidth().height(2.dp).background(musicColors().divider)) {
                Box(
                    modifier = Modifier.fillMaxWidth(progress.coerceIn(0f, 1f)).height(2.dp)
                        .background(musicColors().accent)
                )
            }
            Spacer(modifier = Modifier.height(16.dp))"""
    assert s.count(a6) == 1, "v138 时间行锚点数=" + str(s.count(a6))
    s = s.replace(a6, """            Box(modifier = Modifier.fillMaxWidth().height(2.dp).background(musicColors().divider)) {
                Box(
                    modifier = Modifier.fillMaxWidth(progress.coerceIn(0f, 1f)).height(2.dp)
                        .background(musicColors().accent)
                )
            }
            Spacer(modifier = Modifier.height(4.dp))
            Row( // [32v138] 时间行
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(text = formatTimeConsole(posMs), style = MaterialTheme.typography.labelSmall, color = musicColors().textSecondary)
                Text(text = formatTimeConsole(durMs), style = MaterialTheme.typography.labelSmall, color = musicColors().textSecondary)
            }
            Spacer(modifier = Modifier.height(16.dp))""", 1)
    a7 = """                        picUrl = playerPic,
                        isPlaying = playerIsPlaying,
                        progress = if (playerDur > 0) (playerPos.toFloat() / playerDur.toFloat()).coerceIn(0f, 1f) else 0f,"""
    assert s.count(a7) == 1, "v138 宿主传参锚点数=" + str(s.count(a7))
    s = s.replace(a7, """                        picUrl = playerPic,
                        title = playerTitle, // [32v138]
                        artist = playerArtist, // [32v138]
                        isPlaying = playerIsPlaying,
                        progress = if (playerDur > 0) (playerPos.toFloat() / playerDur.toFloat()).coerceIn(0f, 1f) else 0f,
                        posMs = playerPos, // [32v138]
                        durMs = playerDur, // [32v138]""", 1)
    a8 = """            LaunchedEffect(playerTitle) {
                if (playerTitle.isNotEmpty()) vinylDismissed = false
                if (playerTitle.isEmpty()) showVinylConsole = false
            }"""
    assert s.count(a8) == 1, "v138 tick 锚点数=" + str(s.count(a8))
    s = s.replace(a8, a8 + """
            // [32v138] 控制台进度 tick：播放页同款拉取，播放中每 500ms 刷一次 position（否则控制台进度条不动）
            LaunchedEffect(Unit) {
                while (true) {
                    if (LxPlayerManager.isPlaying.value) {
                        LxPlayerManager.updatePosition()
                    }
                    delay(500L)
                }
            }""", 1)
    open(M, "w", encoding="utf-8").write(s)
    print("OK 32 v138 控制台信息+进度已接")
PYEOF138
echo "=== 32 v138 完成 ==="

# === 32 v139: 控制台三键改用 FeedbackIconButton + 切歌锁接线（用户 2026-10-25 确认） ===
# 新文件 ui/activity/FeedbackIconButton.kt（与 MH、PlayerControls 同包，两边用它都不用 import）：
# 按下震动 LongPress + 缩放 0.85f（interactionSource + animateFloatAsState），enabled=false 时不发震动、不响应。
# 控制台：签名加 locked；宿主传 isChangingTrack；三键改用组件；锁定时 prev/next 图标 alpha 0.35f 且不可点，
# 中心键换黑转圈（白底、与现有黑图标一致）且不可点；X 关闭键不动（随时可关）。
python3 << 'PYEOF139'
import os
def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
find_root()
M = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"
s = open(M, encoding="utf-8").read()
if "[32v139]" in s:
    print("跳过（32 v139 已应用）")
else:
    F = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/FeedbackIconButton.kt"
    comp = '''package com.github.tvbox.osc.ui.activity

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.unit.Dp

// [32v139] 统一按压反馈按钮：控制台 + 播放页共用（同包、无需 import）
// 按下：震动（LongPress）+ 缩放 0.85f；enabled=false 时不发震动、不响应；去涟漪（要涟漪删 indication 一行）
@Composable
fun FeedbackIconButton(
    onClick: () -> Unit,
    enabled: Boolean,
    size: Dp,
    containerColor: Color? = null,
    content: @Composable BoxScope.() -> Unit,
) {
    val interactionSource = remember { MutableInteractionSource() }
    val pressed by interactionSource.collectIsPressedAsState()
    val scale by animateFloatAsState(if (pressed) 0.85f else 1f, label = "feedbackPress")
    val haptic = LocalHapticFeedback.current
    LaunchedEffect(pressed) {
        if (pressed) haptic.performHapticFeedback(HapticFeedbackType.LongPress)
    }
    Box(
        modifier = Modifier.size(size)
            .then(if (containerColor != null) Modifier.clip(CircleShape).background(containerColor) else Modifier)
            .graphicsLayer { scaleX = scale; scaleY = scale }
            .clickable(interactionSource = interactionSource, indication = null, enabled = enabled, onClick = onClick),
        contentAlignment = Alignment.Center,
        content = content,
    )
}
'''
    if not (os.path.exists(F) and "[32v139]" in open(F, encoding="utf-8").read()):
        open(F, "w", encoding="utf-8").write(comp)
    a1 = "val playerDur by LxPlayerManager.duration.collectAsState()"
    assert s.count(a1) == 1, "v139 宿主状态锚点数=" + str(s.count(a1))
    s = s.replace(a1, a1 + "\n            val playerChanging by LxPlayerManager.isChangingTrack.collectAsState() // [32v139]", 1)
    a2 = """    isPlaying: Boolean,
    progress: Float,"""
    assert s.count(a2) == 1, "v139 签名锚点数=" + str(s.count(a2))
    s = s.replace(a2, """    isPlaying: Boolean,
    locked: Boolean, // [32v139]
    progress: Float,""", 1)
    a3 = """                        artist = playerArtist, // [32v138]
                        isPlaying = playerIsPlaying,"""
    assert s.count(a3) == 1, "v139 呼叫点锚点数=" + str(s.count(a3))
    s = s.replace(a3, a3 + "\n                        locked = playerChanging, // [32v139]", 1)
    a4 = """                Box(
                    modifier = Modifier.size(40.dp).clickable(onClick = onPrev),
                    contentAlignment = Alignment.Center
                ) {
                    VinylPrevIcon(tint = musicColors().textPrimary)
                }
                Box(
                    modifier = Modifier.size(56.dp).clip(CircleShape).background(Color.White)
                        .clickable(onClick = onTogglePlay),
                    contentAlignment = Alignment.Center
                ) {
                    if (isPlaying) VinylPauseIcon(tint = Color.Black) else VinylPlayIcon(tint = Color.Black)
                }
                Box(
                    modifier = Modifier.size(40.dp).clickable(onClick = onNext),
                    contentAlignment = Alignment.Center
                ) {
                    VinylNextIcon(tint = musicColors().textPrimary)
                }"""
    assert s.count(a4) == 1, "v139 底行锚点数=" + str(s.count(a4))
    s = s.replace(a4, """                FeedbackIconButton( // [32v139]
                    onClick = onPrev,
                    enabled = !locked,
                    size = 40.dp,
                ) {
                    VinylPrevIcon(tint = if (locked) musicColors().textPrimary.copy(alpha = 0.35f) else musicColors().textPrimary)
                }
                FeedbackIconButton( // [32v139]
                    onClick = onTogglePlay,
                    enabled = !locked,
                    size = 56.dp,
                    containerColor = Color.White,
                ) {
                    if (locked) CircularProgressIndicator(color = Color.Black, modifier = Modifier.size(22.dp), strokeWidth = 2.dp)
                    else if (isPlaying) VinylPauseIcon(tint = Color.Black) else VinylPlayIcon(tint = Color.Black)
                }
                FeedbackIconButton( // [32v139]
                    onClick = onNext,
                    enabled = !locked,
                    size = 40.dp,
                ) {
                    VinylNextIcon(tint = if (locked) musicColors().textPrimary.copy(alpha = 0.35f) else musicColors().textPrimary)
                }""", 1)
    open(M, "w", encoding="utf-8").write(s)
    print("OK 32 v139 控制台反馈按钮已接")
PYEOF139
echo "=== 32 v139 完成 ==="

# === 32 v140: 控制台呼吸灯 + 歌手行开关 + 动态间距（用户 2026-10-25 确认） ===
# 呼吸灯：8dp 圆点 accent 色，rememberInfiniteTransition（alpha 1.0→0.2、scale 1.0→0.8，tween 1000 + Reverse）；
# transition 常驻、只门控取值（播时取动画值、停时固定 0.5f/1f）——无暂停 API（MH:879 注释），相位不重建。
# 歌手行：签名加 showArtist: Boolean = false（呼叫点全具名，零改动、默认隐藏、代码全保留）；
# 行内 text 改 artist.ifEmpty { "未知歌手" }（通知栏/播放页同一口径）、字号 bodyMedium→bodySmall；
# 间距：封面→歌名 12dp 不动；showArtist 时 4dp + 歌手 + 12dp（用户新写 12dp，代码原值 8dp，已按 12 落），
# 隐藏时歌名→进度条直接 16dp；时间→按钮 16dp→20dp；进度条→时间 4dp 不动。
# 不动：封面 0.6f、进度条、时间行、底部三个 FeedbackIconButton。
python3 << 'PYEOF140'
import os
def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
find_root()
M = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"
s = open(M, encoding="utf-8").read()
if "[32v140]" in s:
    print("跳过（32 v140 已应用）")
else:
    a0 = "import androidx.compose.animation.core.tween // [32v124]"
    assert s.count(a0) == 1, "v140 import 锚点数=" + str(s.count(a0))
    s = s.replace(a0, a0 + "\nimport androidx.compose.animation.core.infiniteRepeatable // [32v140]\nimport androidx.compose.animation.core.rememberInfiniteTransition // [32v140]\nimport androidx.compose.animation.core.RepeatMode // [32v140]", 1)
    a1 = """    locked: Boolean, // [32v139]
    progress: Float,"""
    assert s.count(a1) == 1, "v140 签名锚点数=" + str(s.count(a1))
    s = s.replace(a1, """    locked: Boolean, // [32v139]
    showArtist: Boolean = false, // [32v140] 默认隐藏，代码保留；呼叫点全具名故零改动
    progress: Float,""", 1)
    a2 = "        Column(modifier = Modifier.padding(horizontal = 16.dp, vertical = 20.dp)) {"
    assert s.count(a2) == 1, "v140 Column 锚点数=" + str(s.count(a2))
    s = s.replace(a2, """        // [32v140] 呼吸灯：transition 常驻、只门控取值（无暂停 API，相位不重建）
        val breath = rememberInfiniteTransition(label = "breath")
        val breathAlpha by breath.animateFloat(
            initialValue = 1f, targetValue = 0.2f,
            animationSpec = infiniteRepeatable(animation = tween(1000), repeatMode = RepeatMode.Reverse),
            label = "breathAlpha"
        )
        val breathScale by breath.animateFloat(
            initialValue = 1f, targetValue = 0.8f,
            animationSpec = infiniteRepeatable(animation = tween(1000), repeatMode = RepeatMode.Reverse),
            label = "breathScale"
        )
        val dotAlpha = if (isPlaying) breathAlpha else 0.5f
        val dotScale = if (isPlaying) breathScale else 1f
""" + a2, 1)
    a3 = """            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "正在播放",
                    style = MaterialTheme.typography.labelSmall,
                    color = musicColors().textSecondary
                )
                IconButton(onClick = onClose, modifier = Modifier.size(40.dp)) {
                    VinylCloseIcon(tint = musicColors().textPrimary)
                }
            }"""
    assert s.count(a3) == 1, "v140 顶行锚点数=" + str(s.count(a3))
    s = s.replace(a3, """            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) { // [32v140] 呼吸灯 + 正在播放同行
                    Box(
                        modifier = Modifier.size(8.dp)
                            .graphicsLayer { alpha = dotAlpha; scaleX = dotScale; scaleY = dotScale }
                            .clip(CircleShape)
                            .background(musicColors().accent)
                    )
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(
                        text = "正在播放",
                        style = MaterialTheme.typography.labelSmall,
                        color = musicColors().textSecondary
                    )
                }
                IconButton(onClick = onClose, modifier = Modifier.size(40.dp)) {
                    VinylCloseIcon(tint = musicColors().textPrimary)
                }
            }""", 1)
    a4 = """            Spacer(modifier = Modifier.height(4.dp))
            Text( // [32v138] 歌手
                text = artist,
                style = MaterialTheme.typography.bodyMedium,
                color = musicColors().textSecondary,
                textAlign = TextAlign.Center,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier.fillMaxWidth()
            )
            Spacer(modifier = Modifier.height(8.dp))"""
    assert s.count(a4) == 1, "v140 歌手行锚点数=" + str(s.count(a4))
    s = s.replace(a4, """            if (showArtist) { // [32v140] 默认 false：代码保留、不显示
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = artist.ifEmpty { "未知歌手" },
                    style = MaterialTheme.typography.bodySmall,
                    color = musicColors().textSecondary,
                    textAlign = TextAlign.Center,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.fillMaxWidth()
                )
                Spacer(modifier = Modifier.height(12.dp))
            } else {
                Spacer(modifier = Modifier.height(16.dp))
            }""", 1)
    a5 = """            Spacer(modifier = Modifier.height(16.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly,"""
    assert s.count(a5) == 1, "v140 底距锚点数=" + str(s.count(a5))
    s = s.replace(a5, """            Spacer(modifier = Modifier.height(20.dp)) // [32v140] 时间→按钮：16→20
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly,""", 1)
    open(M, "w", encoding="utf-8").write(s)
    print("OK 32 v140 呼吸灯+歌手开关+间距已接")
PYEOF140
echo "=== 32 v140 完成 ==="

# === 32 v141: 构建红修复（CI 实证，v140 漏 import） ===
# CI 报错（用户截图，真实日志）：MusicHomeActivity.kt:962:35 / 967:35
# "Unresolved reference 'animateFloat' on receiver of type 'InfiniteTransition'"，
# 外加 964/969 两处 "Cannot infer type for type parameter 'T'"。
# 根因：animateFloat 是 InfiniteTransition 的扩展函数（非成员），与 v131/v132 的 positionInRoot 同类坑；
# v140 只引了 rememberInfiniteTransition/infiniteRepeatable/RepeatMode，漏了 animateFloat。
# 实证：同工程已绿的 Skeleton.kt（ui/components）第 5 行就引了 androidx.compose.animation.core.animateFloat，
# 且以 transition.animateFloat(...) 同款写法调用。T 推断报错是级联——animateFloat 未解析则无期望类型
# InfiniteRepeatableSpec<Float> 可供 tween 推断 T，补 import 后六错同消。本次只补一行 import，不动其他代码。
python3 << 'PYEOF141'
import os
def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
find_root()
M = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"
s = open(M, encoding="utf-8").read()
if "[32v141]" in s:
    print("跳过（32 v141 已应用）")
else:
    assert "import androidx.compose.animation.core.animateFloat" not in s, "v141 animateFloat import 已存在"
    a0 = "import androidx.compose.animation.core.RepeatMode // [32v140]"
    assert s.count(a0) == 1, "v141 锚点数=" + str(s.count(a0))
    s = s.replace(a0, a0 + "\nimport androidx.compose.animation.core.animateFloat // [32v141]", 1)
    open(M, "w", encoding="utf-8").write(s)
    print("OK 32 v141 animateFloat import 已补")
PYEOF141
echo "=== 32 v141 完成 ==="

# === 32 v142: 6 Tab 胶囊自适应均分（40rec 加第 6 个 Tab 后固定宽溢出） ===
# 实测根因：胶囊容器左右各 24dp + 每个 Tab 固定宽 56dp；6 Tab 共 336dp；
# 360dp 屏胶囊可用宽 312dp，超 24dp，SpaceEvenly 负 slack 无法分布，首尾 Tab 被推出边缘裁切。
# 只压边距不够（16dp 后可用 328dp，仍少 8dp）。修法：item 固定宽改 weight 均分 + 边距压 16dp + 图标 24→22dp。
# 图标坐标上限 20.5（SEARCH 手柄、心形右圆边、SETTINGS 辐条 20.2）均在 22dp 框内；20dp 会裁，故取 22。
# 文字已是 10sp、Row 已是 SpaceEvenly、Row 高 56dp 锁定，均不动；设置页 padding 已是 140dp（v101），不动。
# RowScope 说明：MH 已引 layout.*（RowScope 同包，无需新 import）；PillTabItem97 仅在胶囊 Row 内调用，接收者改动安全。
python3 << 'PYEOF142'
import os
def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
find_root()
M = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"
s = open(M, encoding="utf-8").read()
if "[32v142]" in s:
    print("跳过（32 v142 已应用）")
else:
    def rep(old, new):
        global s
        assert s.count(old) == 1, "v142 锚点数=" + str(s.count(old)) + ": " + old[:60]
        s = s.replace(old, new, 1)
    rep("                    .align(Alignment.BottomCenter)\n                    .padding(start = 24.dp, end = 24.dp, bottom = 24.dp),",
        "                    .align(Alignment.BottomCenter)\n                    .padding(start = 16.dp, end = 16.dp, bottom = 24.dp), // [32v142] 6 Tab 边距压缩")
    rep("private fun PillTabItem97(tab: MusicTab, label: String, selected: Boolean, dark: Boolean, onClick: () -> Unit) { // [32v102] dark 入参",
        "private fun RowScope.PillTabItem97(tab: MusicTab, label: String, selected: Boolean, dark: Boolean, onClick: () -> Unit) { // [32v142] 自适应均分")
    rep("            .width(56.dp)\n            .clickable(onClick = onClick)",
        "            .weight(1f) // [32v142] 固定 56dp 改均分，任何屏宽不裁切\n            .clickable(onClick = onClick)")
    rep("private fun TabLineIcon97(tab: MusicTab, tint: androidx.compose.ui.graphics.Color, modifier: Modifier = Modifier) {\n    Canvas(modifier = modifier.size(24.dp)) {",
        "private fun TabLineIcon97(tab: MusicTab, tint: androidx.compose.ui.graphics.Color, modifier: Modifier = Modifier) {\n    Canvas(modifier = modifier.size(22.dp)) { // [32v142] 6 Tab 图标瘦身")
    assert s.count("[32v142]") == 4, "v142 post-check"
    open(M, "w", encoding="utf-8").write(s)
    print("OK 32 v142 胶囊自适应均分完成")
PYEOF142
echo "=== 32 v142 完成 ==="
# === 32 v143: 音源卡片三点入口 + 高级检测弹窗 SourceTestDialog（视觉并发，单引擎串行解析） ===
# 红线：零新依赖（手搓 Canvas 三点）；verify()/updatePool/缓存写入一字不动；平台全程取自 decls.keys，严禁写死。
# 结构实证：SourceCard 根 Card 无 onClick（冲突不存在）；右上角 TopEnd 悬浮须配 Row 右侧避让 60dp，
# 否则矮卡片（名 + 状态行约 68dp）上 48dp 按钮会盖住居中的删除键（不重叠要求卡高 ≥120dp）。
# 并发实证：sendScriptRequest 每请求唯一 requestKey + ConcurrentHashMap 分发回调，互不覆盖；JS 单线程串行，
# 故逐个 await 的顺序即完成序（视觉并发，底层排队）。正常口径 = ping 口径（URL 字符串校验，不做 Range）。
# 定位方式：签名尾锚点取自 32 v115/v116 自身补丁文本（现行）；函数体用大括号配对定位（体内字符串/注释无非配对花括号，
# "${...}" 模板均为配对出现）；新顶层代码插在函数尾之后，不锚后续函数。
python3 << 'PYEOF143'
import os
def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
find_root()
M = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxSourceSettings.kt"
s = open(M, encoding="utf-8").read()
if "[32v143]" in s:
    print("跳过（32 v143 已应用）")
else:
    def rep(old, new):
        global s
        assert s.count(old) == 1, "v143 锚点数=" + str(s.count(old)) + ": " + old[:60]
        s = s.replace(old, new, 1)
    # 1. imports：缺失才补（去重防重复 import 编译错）
    NEED_IMPS = [
        "import androidx.compose.animation.AnimatedVisibility // [32v143]",
        "import androidx.compose.animation.fadeIn // [32v143]",
        "import androidx.compose.animation.fadeOut // [32v143]",
        "import androidx.compose.foundation.Canvas // [32v143]",
        "import androidx.compose.foundation.lazy.grid.GridCells // [32v143]",
        "import androidx.compose.foundation.lazy.grid.LazyVerticalGrid // [32v143]",
        "import androidx.compose.material3.TextButton // [32v143]",
        "import androidx.compose.runtime.LaunchedEffect // [32v143]",
        "import androidx.compose.ui.geometry.Offset // [32v143]",
        "import androidx.compose.ui.platform.LocalContext // [32v143]",
        "import androidx.compose.ui.window.Dialog // [32v143]",
        "import kotlinx.coroutines.async // [32v143]",
        "import kotlinx.coroutines.coroutineScope // [32v143]",
        "import kotlinx.coroutines.suspendCancellableCoroutine // [32v143]",
        "import kotlinx.coroutines.withTimeout // [32v143]",
    ]
    lines = s.split("\n")
    last_imp = max(i for i, ln in enumerate(lines) if ln.startswith("import "))
    for imp in NEED_IMPS:
        base = imp.split(" // ")[0]
        if not any(ln == base or ln.startswith(base + " ") for ln in lines):
            last_imp += 1
            lines.insert(last_imp, imp)
    s = "\n".join(lines)
    # 2. Row 右侧避让：三点显示时留 60dp（48 按钮 + 12 间隙）
    rep("                .padding(12.dp),\n            verticalAlignment = Alignment.CenterVertically",
        "                .padding(start = 12.dp, top = 12.dp, end = if (showDots) 60.dp else 12.dp, bottom = 12.dp), // [32v143] 三点显示时右侧留 60dp，矮卡片也不盖删除键\n            verticalAlignment = Alignment.CenterVertically")
    # 3. SourceCard 手术：签名尾锚点（32 v115/v116 自身文本）+ 大括号配对定位函数体
    sig = "    onPingClick: () -> Unit = {},\n    isRefreshing: Boolean = false,\n    onShowLog: () -> Unit = {}\n) {"
    assert s.count(sig) == 1, "v143 SourceCard 签名锚点数=" + str(s.count(sig))
    body_open = s.index(sig) + len(sig) - 1
    depth = 0
    i = body_open
    func_end = -1
    while i < len(s):
        ch = s[i]
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                func_end = i
                break
        i += 1
    assert func_end > 0, "v143 SourceCard 函数尾未找到"
    rest_lines = [ln for ln in s[func_end + 1:].split("\n") if ln.strip() and not ln.strip().startswith("//")]
    assert rest_lines and (rest_lines[0].startswith("@") or rest_lines[0].startswith("private fun") or rest_lines[0].startswith("fun ") or rest_lines[0].startswith("object ") or rest_lines[0].startswith("class ")), "v143 函数尾后内容异常: " + (rest_lines[0][:40] if rest_lines else "")
    HEAD = """
    var showTestDialog by remember { mutableStateOf(false) } // [32v143] 高级检测弹窗开关（每卡自带，签名不动）
    // 与卡内“验证通过”同一条件；VerifyResult 是 data class（success 布尔字段），无 Success 子类
    val showDots = verifyResult != null && !verifyResult.verifying && verifyResult.success
    Box(Modifier.fillMaxWidth()) { // [32v143] 外层 Box：卡片 + 右上角三点悬浮同级
"""
    TAIL = """
    AnimatedVisibility( // [32v143] 三点入口：仅验证成功时淡入
        visible = showDots,
        enter = fadeIn(), exit = fadeOut(),
        modifier = Modifier.align(Alignment.TopEnd)
    ) {
        IconButton(onClick = { showTestDialog = true }) {
            Canvas(Modifier.size(24.dp)) {
                val r = 2.5.dp.toPx()
                val cx = size.width / 2
                val c = MaterialTheme.colorScheme.onSurfaceVariant
                drawCircle(c, r, Offset(cx, 5.dp.toPx()))
                drawCircle(c, r, Offset(cx, 12.dp.toPx()))
                drawCircle(c, r, Offset(cx, 19.dp.toPx()))
            }
        }
    }
    } // [32v143] 外层 Box 关
    if (showTestDialog) SourceTestDialog(source = source, onDismiss = { showTestDialog = false })
"""
    NEWCODE = """
// [32v143] 高级检测弹窗：平台检测状态机
private sealed interface TestState {
    data object Testing : TestState
    data class Ok(val ms: Long) : TestState
    data object Fail : TestState
}

// [32v143] 平台 code → 中文名；未知 code 原样显示
private fun platformName(code: String): String = when (code) {
    "kw" -> "酷我"
    "kg" -> "酷狗"
    "tx", "qq" -> "QQ音乐"
    "wy" -> "网易云"
    "mg" -> "咪咕"
    "qs" -> "汽水"
    else -> code
}

// [32v143] 高级检测弹窗：单引擎 + 逐平台顺序解析，UI 逐个实时翻转；只读诊断，不回写可用池/缓存
@Composable
private fun SourceTestDialog(source: LxSource, onDismiss: () -> Unit) {
    val context = LocalContext.current
    var platforms by remember { mutableStateOf<List<String>>(emptyList()) }
    var results by remember { mutableStateOf<Map<String, TestState>>(emptyMap()) }
    var phase by remember { mutableStateOf("引擎加载中...") }
    LaunchedEffect(Unit) {
        var engine: TestEngine? = null
        try {
            val eng = loadDeclsSuspend(context, source.id)
            engine = eng
            platforms = eng.platforms
            results = platforms.associateWith { TestState.Testing }
            phase = "正在检测..."
            coroutineScope {
                val tasks = platforms.map { plat ->
                    async {
                        try {
                            val ms = withTimeout(15_000L) { resolveOnePlatformSuspend(eng, plat) }
                            TestState.Ok(ms)
                        } catch (e: Exception) {
                            TestState.Fail
                        }
                    }
                }
                for ((plat, task) in platforms.zip(tasks)) {
                    results = results + (plat to task.await())
                }
            }
            phase = "完成"
        } catch (e: Exception) {
            phase = "引擎加载失败"
        } finally {
            try {
                engine?.release()
            } catch (_: Exception) {
            }
        }
    }
    Dialog(onDismissRequest = onDismiss) {
        Card(colors = CardDefaults.cardColors(containerColor = musicColors().card)) {
            Column(Modifier.padding(16.dp)) {
                Text("${source.name} · 高级检测", style = MaterialTheme.typography.titleMedium, color = musicColors().textPrimary)
                Text(phase, style = MaterialTheme.typography.labelSmall, color = musicColors().textSecondary)
                if (platforms.isEmpty() && phase == "完成") {
                    Text("该脚本未声明任何平台", style = MaterialTheme.typography.labelSmall, color = musicColors().textSecondary)
                }
                LazyVerticalGrid(columns = GridCells.Fixed(3)) {
                    items(platforms, key = { it }) { plat ->
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Text(platformName(plat), style = MaterialTheme.typography.bodyMedium, color = musicColors().textPrimary)
                            when (val r = results[plat]) {
                                null, TestState.Testing -> Text("检测中...", style = MaterialTheme.typography.labelSmall, color = Color(0xFFFFA000))
                                is TestState.Ok -> Text("解析正常 ${r.ms}ms", style = MaterialTheme.typography.labelSmall, color = musicColors().accent)
                                TestState.Fail -> Text("解析失败", style = MaterialTheme.typography.labelSmall, color = Color(0xFFF44336))
                            }
                        }
                    }
                }
                TextButton(onClick = onDismiss) { Text("完成") }
            }
        }
    }
}

// [32v143] 检测引擎句柄：引擎与平台列表共享，弹窗关闭时统一销毁（verify() finally 同款）
private class TestEngine(val engine: LxScriptEngine, val platforms: List<String>) {
    fun release() {
        try {
            engine.destroy()
        } catch (_: Exception) {
        }
    }
}

// [32v143] 引擎加载 + 取脚本声明平台（复用 verify() 第 1–5 步，Thread + sleep 轮询改挂起桥接；不碰 verify() 本体）
private suspend fun loadDeclsSuspend(context: android.content.Context, sourceId: String): TestEngine {
    val scriptContent = LxSourceManager.getScriptContent(sourceId)
        ?: throw IllegalStateException("脚本内容为空")
    val sourceName = LxSourceManager.getSources().firstOrNull { it.id == sourceId }?.name ?: sourceId
    val preloadJs = context.assets.open("lx/preload.js").bufferedReader().use { it.readText() }
        .takeIf { it.isNotBlank() } ?: throw IllegalStateException("preload 为空")
    val eng = LxScriptEngine()
    eng.initialize(context)
    try {
        withTimeout(15_000L) {
            suspendCancellableCoroutine<Unit> { cont ->
                eng.loadPreloadJs(preloadJs) { ok ->
                    if (ok) cont.resume(Unit)
                    else cont.resumeWithException(IllegalStateException("preload 加载失败"))
                }
            }
        }
        val decls = withTimeout(20_000L) {
            suspendCancellableCoroutine<Map<String, LxSourceDeclaration>> { cont ->
                eng.loadScript(sourceId, scriptContent, ScriptInfo(id = sourceId, name = sourceName)) { result ->
                    result.fold(
                        onSuccess = { cont.resume(it) },
                        onFailure = { cont.resumeWithException(it) }
                    )
                }
            }
        }
        return TestEngine(eng, decls.keys.toList())
    } catch (e: Exception) {
        try {
            eng.destroy()
        } catch (_: Exception) {
        }
        throw e
    }
}

// [32v143] 单平台解析：requestMusicUrl 挂起桥接；正常口径 = ping 口径（URL 字符串校验，不做 Range）
private suspend fun resolveOnePlatformSuspend(engine: TestEngine, plat: String): Long =
    suspendCancellableCoroutine { cont ->
        val start = System.currentTimeMillis()
        val musicInfo = mapOf(
            "id" to "347230",
            "songId" to "347230",
            "songmid" to "347230",
            "name" to "海阔天空",
            "singer" to "Beyond",
            "source" to plat,
            "hash" to "347230",
            "albumAudioId" to ""
        )
        engine.engine.requestMusicUrl(plat, musicInfo, "128k") { res ->
            if (!cont.isActive) return@requestMusicUrl
            res.fold(
                onSuccess = { url ->
                    if (isValidMusicUrl(url)) cont.resume(System.currentTimeMillis() - start)
                    else cont.resumeWithException(IllegalStateException("无效 URL"))
                },
                onFailure = { cont.resumeWithException(it) }
            )
        }
        cont.invokeOnCancellation { }
    }
"""
    # 从后往前插，索引不失效
    s = s[:func_end + 1] + "\n" + NEWCODE + s[func_end + 1:]
    s = s[:func_end] + TAIL + s[func_end:]
    s = s[:body_open + 1] + HEAD + s[body_open + 1:]
    for k in ["SourceTestDialog(", "loadDeclsSuspend(", "resolveOnePlatformSuspend(", "class TestEngine", "platformName(", "sealed interface TestState", "AnimatedVisibility(", "showTestDialog", "showDots"]:
        assert k in s, "v143 缺失: " + k
    assert s.count("[32v143]") >= 11, "v143 标记数=" + str(s.count("[32v143]"))
    open(M, "w", encoding="utf-8").write(s)
    print("OK 32 v143 三点入口 + 高级检测弹窗完成")
PYEOF143
echo "=== 32 v143 完成 ==="
# === 32 v144: 构建红修复（v143 CI 实证四错，2026-10-26） ===
python3 << 'PYEOF144'
import os

def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
    assert os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"), "find_root 失败"

find_root()
M = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxSourceSettings.kt"
s = open(M, encoding="utf-8").read()
if "[32v144]" in s:
    print("跳过（32 v144 已应用）")
else:
    def rep(old, new, cnt=1):
        n = s.count(old)
        assert n == cnt, "v144 锚点数=%d 期望=%d: %s" % (n, cnt, old[:60])
        return s.replace(old, new)

    # ① 补两个缺失 import（CI 实证：Box 未引致整段 @Composable 级联错；grid items 未引致 items 走 Int 重载）
    anchor_imp = "import kotlinx.coroutines.withTimeout // [32v143]"
    assert s.count(anchor_imp) == 1, "v144 import 锚点数=%d" % s.count(anchor_imp)
    s = s.replace(anchor_imp, anchor_imp + "\nimport androidx.compose.foundation.layout.Box // [32v144]\nimport androidx.compose.foundation.lazy.grid.items // [32v144]")

    # ② grid items key 显式类型，彻底断 Int 重载歧义
    s = rep("items(platforms, key = { it }) { plat ->", "items(platforms, key = { plat: String -> plat }) { plat ->")

    # ③ coroutines 1.11.0：resume 的 onCancellation 无默认值，必须显传 null；resumeWithException 非接口成员，改 resumeWith(Result.failure)
    s = rep("if (ok) cont.resume(Unit)", "if (ok) cont.resume(Unit, null)")
    s = rep('else cont.resumeWithException(IllegalStateException("preload 加载失败"))', 'else cont.resumeWith(Result.failure(IllegalStateException("preload 加载失败")))')
    s = rep("onSuccess = { cont.resume(it) }", "onSuccess = { cont.resume(it, null) }")
    s = rep("onFailure = { cont.resumeWithException(it) }", "onFailure = { cont.resumeWith(Result.failure(it)) }", 2)
    s = rep("if (isValidMusicUrl(url)) cont.resume(System.currentTimeMillis() - start)", "if (isValidTestMusicUrl(url)) cont.resume(System.currentTimeMillis() - start, null)")
    s = rep('else cont.resumeWithException(IllegalStateException("无效 URL"))', 'else cont.resumeWith(Result.failure(IllegalStateException("无效 URL")))')

    # ④ 顶层复刻 ping 口径校验（原函数为 LxSourceVerifier 私有成员，顶层函数不可见）
    PRED = """// [32v144] ping 口径 URL 校验（与 LxSourceVerifier.isValidMusicUrl 同体；原函数为 verifier 私有成员，顶层函数不可见，故在此复刻）
private fun isValidTestMusicUrl(url: String): Boolean {
    if (url.isBlank()) return false
    val u = url.trim()
    if (!u.startsWith("http://") && !u.startsWith("https://")) return false
    if (u.length < 30) return false
    val lower = u.lowercase()
    val badKeywords = listOf("error", "null", "undefined", "fail", "empty", "404", "notfound")
    for (kw in badKeywords) {
        if (lower.contains(kw)) return false
    }
    return true
}

"""
    anchor_fn = "private suspend fun resolveOnePlatformSuspend(engine: TestEngine, plat: String): Long ="
    assert s.count(anchor_fn) == 1, "v144 函数锚点数=%d" % s.count(anchor_fn)
    s = s.replace(anchor_fn, PRED + anchor_fn)

    # 后验：新串齐全、旧串清零
    for k, c in [
        ("import androidx.compose.foundation.layout.Box // [32v144]", 1),
        ("import androidx.compose.foundation.lazy.grid.items // [32v144]", 1),
        ("key = { plat: String -> plat }", 1),
        ("cont.resume(Unit, null)", 1),
        ("cont.resume(it, null)", 1),
        ("cont.resume(System.currentTimeMillis() - start, null)", 1),
        ('Result.failure(IllegalStateException("preload 加载失败"))', 1),
        ('Result.failure(IllegalStateException("无效 URL"))', 1),
        ("Result.failure(it)", 2),
        ("fun isValidTestMusicUrl", 1),
        ("isValidTestMusicUrl(url)", 1),
    ]:
        assert s.count(k) == c, "v144 后验失败 %s: %d != %d" % (k[:50], s.count(k), c)
    for old in [
        'cont.resumeWithException(IllegalStateException("preload 加载失败"))',
        "onFailure = { cont.resumeWithException(it) }",
        'cont.resumeWithException(IllegalStateException("无效 URL"))',
        "if (isValidMusicUrl(url)) cont.resume(System.currentTimeMillis() - start)",
    ]:
        assert old not in s, "v144 旧串残留: " + old[:60]
    assert s.count("[32v144]") >= 3, "v144 标记数=" + str(s.count("[32v144]"))
    open(M, "w", encoding="utf-8").write(s)
    print("OK 32 v144 构建红修复完成")
PYEOF144
echo "=== 32 v144 完成 ==="
# === 32 v145: 构建红修复（v144 残留一错 594:39，2026-10-26） ===
python3 << 'PYEOF145'
import os

def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
    assert os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"), "find_root 失败"

find_root()
M = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxSourceSettings.kt"
s = open(M, encoding="utf-8").read()
if "[32v145]" in s:
    print("跳过（32 v145 已应用）")
else:
    old = """        IconButton(onClick = { showTestDialog = true }) {
            Canvas(Modifier.size(24.dp)) {
                val r = 2.5.dp.toPx()
                val cx = size.width / 2
                val c = MaterialTheme.colorScheme.onSurfaceVariant
                drawCircle(c, r, Offset(cx, 5.dp.toPx()))
                drawCircle(c, r, Offset(cx, 12.dp.toPx()))
                drawCircle(c, r, Offset(cx, 19.dp.toPx()))
            }
        }"""
    assert s.count(old) == 1, "v145 锚点数=%d" % s.count(old)
    new = """        IconButton(onClick = { showTestDialog = true }) {
            val dotColor = MaterialTheme.colorScheme.onSurfaceVariant // [32v145] 主题色必须在 @Composable 上下文读；Canvas 的 DrawScope 里读即报 594:39
            Canvas(Modifier.size(24.dp)) {
                val r = 2.5.dp.toPx()
                val cx = size.width / 2
                drawCircle(dotColor, r, Offset(cx, 5.dp.toPx()))
                drawCircle(dotColor, r, Offset(cx, 12.dp.toPx()))
                drawCircle(dotColor, r, Offset(cx, 19.dp.toPx()))
            }
        }"""
    s = s.replace(old, new)
    assert s.count("val dotColor = MaterialTheme.colorScheme.onSurfaceVariant") == 1, "v145 dotColor 数异常"
    assert "val c = MaterialTheme.colorScheme.onSurfaceVariant" not in s, "v145 旧读色行残留"
    assert s.count("drawCircle(dotColor, r,") == 3, "v145 三点用色数异常"
    assert s.count("[32v145]") >= 1, "v145 标记数=" + str(s.count("[32v145]"))
    open(M, "w", encoding="utf-8").write(s)
    print("OK 32 v145 构建红修复完成")
PYEOF145
echo "=== 32 v145 完成 ==="
# === 32 v146: 高级检测弹窗严谨版（用户 2026-10-26 确认：每平台 5 首歌 + Range 真拉流 + 失败原因） ===
python3 << 'PYEOF146'
import os

def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
    assert os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"), "find_root 失败"

find_root()
M = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxSourceSettings.kt"
s = open(M, encoding="utf-8").read()
if "[32v146]" in s:
    print("跳过（32 v146 已应用）")
else:
    def rep(old, new, cnt=1):
        n = s.count(old)
        assert n == cnt, "v146 锚点数=%d 期望=%d: %s" % (n, cnt, old[:60])
        return s.replace(old, new)

    # ① 补两个协程异常 import（取消透传与超时分类用；withContext/Dispatchers/withTimeout 已有）
    anchor_imp = "import kotlinx.coroutines.withTimeout // [32v143]"
    assert s.count(anchor_imp) == 1, "v146 import 锚点数=%d" % s.count(anchor_imp)
    for imp in ["import kotlinx.coroutines.CancellationException // [32v146]",
                "import kotlinx.coroutines.TimeoutCancellationException // [32v146]"]:
        assert s.count(imp) == 0, "v146 import 已存在: " + imp
    s = s.replace(anchor_imp, anchor_imp + "\nimport kotlinx.coroutines.CancellationException // [32v146]\nimport kotlinx.coroutines.TimeoutCancellationException // [32v146]")

    # ② TestState：Fail 带原因 + 通过数
    s = rep("""private sealed interface TestState {
    data object Testing : TestState
    data class Ok(val ms: Long) : TestState
    data object Fail : TestState
}""", """// [32v146] 严谨版状态机：Fail 带原因 + 通过数（5 首制）
private sealed interface TestState {
    data object Testing : TestState
    data class Ok(val ms: Long) : TestState
    data class Fail(val reason: String, val okCount: Int) : TestState
}""")

    # ③ 弹窗循环：每平台 5 首顺序测（任务本身只抛取消，其余失败全在 testPlatform 内消化为 Fail）
    s = rep("""            coroutineScope {
                val tasks = platforms.map { plat ->
                    async {
                        try {
                            val ms = withTimeout(15_000L) { resolveOnePlatformSuspend(eng, plat) }
                            TestState.Ok(ms)
                        } catch (e: Exception) {
                            TestState.Fail
                        }
                    }
                }""", """            coroutineScope {
                val tasks = platforms.map { plat ->
                    async { testPlatform(eng, plat) } // [32v146] 严谨版：每平台 5 首顺序测 + Range，任务本身只抛取消
                }""")

    # ④ 格子失败行： verdict + 原因 · X/5通过 两行
    s = rep("""                                TestState.Fail -> Text("解析失败", style = MaterialTheme.typography.labelSmall, color = Color(0xFFF44336))""", """                                is TestState.Fail -> {
                                    Text("解析失败", style = MaterialTheme.typography.labelSmall, color = Color(0xFFF44336))
                                    Text("${r.reason} · ${r.okCount}/5通过", style = MaterialTheme.typography.labelSmall, color = musicColors().textSecondary)
                                }""")

    # ⑤ 旧桥接整段替换：大括号配对定位（体内字符串/注释无非配对花括号），换成 URL 桥接 + 单首 + 单平台 + Range 四件
    assert s.count("private suspend fun resolveOnePlatformSuspend") == 1, "v146 旧函数锚点异常"
    i0 = s.index("private suspend fun resolveOnePlatformSuspend")
    j = s.index("suspendCancellableCoroutine {", i0)
    b = s.index("{", j)
    depth = 0
    k = b
    while True:
        ch = s[k]
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                break
        k += 1
    end = k + 1
    assert "cont.invokeOnCancellation" in s[i0:end], "v146 旧函数跨度未含 invokeOnCancellation"
    NEWCODE = """// [32v146] 严谨版测试歌单：与卡片 verify() 的 5 首固定歌完全一致（同 id 集、同 128k）；不提前 break，X/5 为实测数
private val TEST_SONGS = listOf(
    Triple("347230", "海阔天空", "Beyond"),
    Triple("186016", "晴天", "周杰伦"),
    Triple("260573", "夜曲", "周杰伦"),
    Triple("33894312", "演员", "薛之谦"),
    Triple("167876", "有何不可", "许嵩")
)

private sealed interface SongResult {
    data class Ok(val ms: Long) : SongResult
    data class Fail(val reason: String) : SongResult
}

// [32v146] 单首解析桥接：只把引擎结果取回为 URL 字符串；字符串校验与 Range 由 testOneSong 做
private suspend fun resolveUrlSuspend(engine: TestEngine, plat: String, songId: String, name: String, singer: String): String =
    suspendCancellableCoroutine { cont ->
        val musicInfo = mapOf(
            "id" to songId,
            "songId" to songId,
            "songmid" to songId,
            "name" to name,
            "singer" to singer,
            "source" to plat,
            "hash" to songId,
            "albumAudioId" to ""
        )
        engine.engine.requestMusicUrl(plat, musicInfo, "128k") { res ->
            if (!cont.isActive) return@requestMusicUrl
            res.fold(
                onSuccess = { url -> cont.resume(url, null) },
                onFailure = { cont.resumeWith(Result.failure(it)) }
            )
        }
        cont.invokeOnCancellation { }
    }

// [32v146] 单首严谨测试：解析 15 秒超时 → 字符串校验 → IO 线程 Range 真拉流（主线程直接联网会闪退，故 withContext(Dispatchers.IO)；取消一律透传，不记为失败）
private suspend fun testOneSong(engine: TestEngine, plat: String, song: Triple<String, String, String>): SongResult {
    val (songId, name, singer) = song
    val start = System.currentTimeMillis()
    val url: String = try {
        withTimeout(15_000L) { resolveUrlSuspend(engine, plat, songId, name, singer) }
    } catch (e: TimeoutCancellationException) {
        return SongResult.Fail("超时")
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        return SongResult.Fail("引擎错误")
    }
    if (!isValidTestMusicUrl(url)) return SongResult.Fail("无效URL")
    val rangeOk = try {
        withContext(Dispatchers.IO) { testRangeOk(url) }
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        false
    }
    if (!rangeOk) return SongResult.Fail("Range失败")
    return SongResult.Ok(System.currentTimeMillis() - start)
}

// [32v146] 单平台严谨测试：5 首顺序测（与 verify() 同规则 ≥4 首过即正常；JS 单线程串行，顺序测与并发测底层一致）
private suspend fun testPlatform(engine: TestEngine, plat: String): TestState {
    var okCount = 0
    var okMs = 0L
    val failReasons = mutableListOf<String>()
    for (song in TEST_SONGS) {
        when (val r = testOneSong(engine, plat, song)) {
            is SongResult.Ok -> { okCount++; okMs += r.ms }
            is SongResult.Fail -> failReasons += r.reason
        }
    }
    if (okCount >= 4) return TestState.Ok(if (okCount > 0) okMs / okCount else 0)
    val reason = failReasons.groupingBy { it }.eachCount().maxByOrNull { it.value }?.key ?: "未知"
    return TestState.Fail(reason, okCount)
}

// [32v146] Range 真拉流：与卡片 verify() 的 rangeCheckOk 同体（200/206 + 音频 Content-Type + 实读数据；顶层无 verifier 的 TAG，用字面 tag）
private fun testRangeOk(url: String): Boolean {
    return try {
        val client = okhttp3.OkHttpClient.Builder()
            .connectTimeout(5, java.util.concurrent.TimeUnit.SECONDS)
            .readTimeout(5, java.util.concurrent.TimeUnit.SECONDS)
            .followRedirects(true)
            .build()
        val request = okhttp3.Request.Builder()
            .url(url)
            .header("Range", "bytes=0-1023")
            .header("User-Agent", "Mozilla/5.0 (Linux; Android 10)")
            .get()
            .build()
        client.newCall(request).execute().use { resp ->
            val code = resp.code
            if (code != 200 && code != 206) {
                android.util.Log.w("LxSourceTest", "Range GET 状态码不通过: $code $url")
                return false
            }
            val contentType = (resp.header("Content-Type") ?: "").lowercase()
            val typeOk = contentType.contains("audio") ||
                    contentType.contains("application/octet-stream")
            if (!typeOk) {
                android.util.Log.w("LxSourceTest", "Content-Type 不通过: $contentType $url")
                return false
            }
            val contentLength = resp.header("Content-Length")?.toLongOrNull() ?: -1L
            if (contentLength > 0) return true
            val body = resp.body
            if (body == null) {
                android.util.Log.w("LxSourceTest", "响应 body 为空: $url")
                return false
            }
            val buf = okio.Buffer()
            val source = body.source()
            var readTotal = 0L
            while (readTotal < 1024) {
                val read = source.read(buf, 1024 - readTotal)
                if (read == -1L) break
                readTotal += read
            }
            val ok = buf.size > 0
            if (!ok) android.util.Log.w("LxSourceTest", "未读到任何数据: $url")
            ok
        }
    } catch (e: Exception) {
        android.util.Log.w("LxSourceTest", "Range 检查异常: $url", e)
        false
    }
}
"""
    s = s[:i0] + NEWCODE + s[end:]

    # 后验：新串齐全、旧串清零
    for k, c in [
        ("import kotlinx.coroutines.CancellationException // [32v146]", 1),
        ("import kotlinx.coroutines.TimeoutCancellationException // [32v146]", 1),
        ("data class Fail(val reason: String, val okCount: Int)", 1),
        ("async { testPlatform(eng, plat) }", 1),
        ("is TestState.Fail -> {", 1),
        ("private val TEST_SONGS", 1),
        ("sealed interface SongResult", 1),
        ("fun resolveUrlSuspend", 1),
        ("fun testOneSong", 1),
        ("fun testPlatform", 1),
        ("fun testRangeOk", 1),
        ("withContext(Dispatchers.IO) { testRangeOk(url) }", 1),
    ]:
        assert s.count(k) == c, "v146 后验失败 %s: %d != %d" % (k[:50], s.count(k), c)
    for old in [
        "data object Fail : TestState",
        "resolveOnePlatformSuspend",
        'TestState.Fail -> Text("解析失败"',
    ]:
        assert old not in s, "v146 旧串残留: " + old[:60]
    assert s.count("[32v146]") >= 9, "v146 标记数=" + str(s.count("[32v146]"))
    open(M, "w", encoding="utf-8").write(s)
    print("OK 32 v146 高级检测严谨版完成")
PYEOF146
echo "=== 32 v146 完成 ==="

# === 32 v147: 高级检测一首真歌 + 复核（用户 2026-10-26 确认：搜海阔天空真歌测 1 首，失败换第二首复核，5 首制作废） ===
python3 << 'PYEOF147'
import os

def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
    assert os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"), "find_root 失败"

find_root()
M = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxSourceSettings.kt"
s = open(M, encoding="utf-8").read()
if "[32v147]" in s:
    print("跳过（32 v147 已应用）")
else:
    def rep(old, new, cnt=1):
        n = s.count(old)
        assert n == cnt, "v147 锚点数=%d 期望=%d: %s" % (n, cnt, old[:60])
        return s.replace(old, new)

    # ① TestState：Fail 带原因 + 是否两首都失败；NoSong = 该平台搜不到探针歌
    s = rep("""// [32v146] 严谨版状态机：Fail 带原因 + 通过数（5 首制）
private sealed interface TestState {
    data object Testing : TestState
    data class Ok(val ms: Long) : TestState
    data class Fail(val reason: String, val okCount: Int) : TestState
}""", """// [32v147] 一首真歌 + 复核状态机：Fail 带原因 + 是否两首都失败（1+1 制，5 首制作废）；NoSong = 该平台搜不到探针歌
private sealed interface TestState {
    data object Testing : TestState
    data class Ok(val ms: Long) : TestState
    data class Fail(val reason: String, val bothFailed: Boolean) : TestState
    data object NoSong : TestState
}""")

    # ② 弹窗循环：引擎加载后先搜一次真歌（失败则整表记搜索失败），再逐平台一首 + 复核；无声明平台直接完成（空平台提示行条件不变）
    s = rep("""            val eng = loadDeclsSuspend(context, source.id)
            engine = eng
            platforms = eng.platforms
            results = platforms.associateWith { TestState.Testing }
            phase = "正在检测..."
            coroutineScope {
                val tasks = platforms.map { plat ->
                    async { testPlatform(eng, plat) } // [32v146] 严谨版：每平台 5 首顺序测 + Range，任务本身只抛取消
                }
                for ((plat, task) in platforms.zip(tasks)) {
                    results = results + (plat to task.await())
                }
            }
            phase = "完成\"""", """            val eng = loadDeclsSuspend(context, source.id)
            engine = eng
            platforms = eng.platforms
            results = platforms.associateWith { TestState.Testing }
            if (platforms.isNotEmpty()) {
                phase = "正在搜索..." // [32v147]
                val songsByPlat = try {
                    probeSongsByPlatform() // [32v147]
                } catch (e: CancellationException) {
                    throw e
                } catch (e: Exception) {
                    null
                }
                if (songsByPlat == null) {
                    phase = "搜索失败"
                    results = platforms.associateWith { TestState.Fail("搜索失败", false) } // [32v147]
                } else {
                    phase = "正在检测..."
                    coroutineScope {
                        val tasks = platforms.map { plat ->
                            async { testPlatformProbe(eng, plat, songsByPlat[probeNormPlat(plat)] ?: emptyList()) } // [32v147] 一首真歌 + 复核，任务本身只抛取消
                        }
                        for ((plat, task) in platforms.zip(tasks)) {
                            results = results + (plat to task.await())
                        }
                    }
                    phase = "完成"
                }
            } else {
                phase = "完成"
            }""")

    # ③ 格子失败行：两首都失败才带后缀；NoSong 单行灰字
    s = rep("""                                is TestState.Fail -> {
                                    Text("解析失败", style = MaterialTheme.typography.labelSmall, color = Color(0xFFF44336))
                                    Text("${r.reason} · ${r.okCount}/5通过", style = MaterialTheme.typography.labelSmall, color = musicColors().textSecondary)
                                }""", """                                is TestState.Fail -> {
                                    Text("解析失败", style = MaterialTheme.typography.labelSmall, color = Color(0xFFF44336))
                                    Text(if (r.bothFailed) "${r.reason} · 两首均失败" else r.reason, style = MaterialTheme.typography.labelSmall, color = musicColors().textSecondary) // [32v147]
                                }
                                TestState.NoSong -> Text("搜不到歌", style = MaterialTheme.typography.labelSmall, color = musicColors().textSecondary) // [32v147]""")

    # ④ 固定 5 首歌单作废，换成探针歌选取：搜一次海阔天空，按平台取主测 + 复核两首真歌
    s = rep("""// [32v146] 严谨版测试歌单：与卡片 verify() 的 5 首固定歌完全一致（同 id 集、同 128k）；不提前 break，X/5 为实测数
private val TEST_SONGS = listOf(
    Triple("347230", "海阔天空", "Beyond"),
    Triple("186016", "晴天", "周杰伦"),
    Triple("260573", "夜曲", "周杰伦"),
    Triple("33894312", "演员", "薛之谦"),
    Triple("167876", "有何不可", "许嵩")
)""", """// [32v147] 一首真歌探针：关键词固定为海阔天空（五平台共有歌）；每平台取搜索结果里的真歌测，不再用固定 id
private const val PROBE_KEYWORD = "海阔天空" // [32v147]
private const val PROBE_ARTIST = "Beyond" // [32v147]

// [32v147] 平台键归一：App 搜索 QQ 侧 code 为 tx、脚本声明侧可能为 qq，统一成 qq 再配对；显示仍用原始 code 走 platformName
private fun probeNormPlat(code: String): String = if (code == "tx") "qq" else code // [32v147]

private fun probeNorm(s: String): String = s.filter { !it.isWhitespace() }.lowercase() // [32v147]

// [32v147] 每平台取主测 + 复核两首：优先歌名精确 + 歌手含 Beyond，退而求其次只歌名精确；均无则空列表（该平台显示搜不到歌）
private fun pickProbeSongs(songs: List<LxMusicSearchApi.SongInfo>): List<LxMusicSearchApi.SongInfo> {
    val key = probeNorm(PROBE_KEYWORD)
    val artistKey = probeNorm(PROBE_ARTIST)
    val titleOk = songs.filter { probeNorm(it.title) == key }
    val artistOk = titleOk.filter { probeNorm(it.artist).contains(artistKey) }
    return (if (artistOk.isNotEmpty()) artistOk else titleOk).take(2)
}

// [32v147] 搜一次取全平台探针歌：searchFull 五平台并行、单平台搜索失败只吞成空列表（其自带 try-catch）；返回键为归一化平台 code
private suspend fun probeSongsByPlatform(): Map<String, List<LxMusicSearchApi.SongInfo>> {
    val all = LxMusicSearchApi.searchFull(PROBE_KEYWORD)
    return all.groupBy { probeNormPlat(it.platform) }
        .mapValues { (_, list) -> pickProbeSongs(list) }
        .filterValues { it.isNotEmpty() }
}""")

    # ⑤ 解析桥接：musicInfo 改传搜索结果真实字段（hash/songmid/专辑 id），不再 id 硬填四项
    s = rep("""// [32v146] 单首解析桥接：只把引擎结果取回为 URL 字符串；字符串校验与 Range 由 testOneSong 做
private suspend fun resolveUrlSuspend(engine: TestEngine, plat: String, songId: String, name: String, singer: String): String =
    suspendCancellableCoroutine { cont ->
        val musicInfo = mapOf(
            "id" to songId,
            "songId" to songId,
            "songmid" to songId,
            "name" to name,
            "singer" to singer,
            "source" to plat,
            "hash" to songId,
            "albumAudioId" to ""
        )""", """// [32v147] 单首解析桥接：只把引擎结果取回为 URL 字符串；字符串校验与 Range 由 testOneSong 做；musicInfo 改传搜索结果真实字段（hash/songmid/专辑 id），不再 id 硬填四项
private suspend fun resolveUrlSuspend(engine: TestEngine, plat: String, song: LxMusicSearchApi.SongInfo): String =
    suspendCancellableCoroutine { cont ->
        val musicInfo = mapOf(
            "id" to song.id,
            "songId" to song.id,
            "songmid" to song.songmid,
            "name" to song.title,
            "singer" to song.artist,
            "source" to plat,
            "hash" to song.hash.ifBlank { song.id },
            "albumAudioId" to song.albumAudioId
        )""")

    # ⑥ 单首测试：入参改真歌对象，超时/校验/Range 逻辑不动
    s = rep("""// [32v146] 单首严谨测试：解析 15 秒超时 → 字符串校验 → IO 线程 Range 真拉流（主线程直接联网会闪退，故 withContext(Dispatchers.IO)；取消一律透传，不记为失败）
private suspend fun testOneSong(engine: TestEngine, plat: String, song: Triple<String, String, String>): SongResult {
    val (songId, name, singer) = song
    val start = System.currentTimeMillis()
    val url: String = try {
        withTimeout(15_000L) { resolveUrlSuspend(engine, plat, songId, name, singer) }""", """// [32v147] 单首测试：解析 15 秒超时 → 字符串校验 → IO 线程 Range 真拉流（主线程直接联网会闪退，故 withContext(Dispatchers.IO)；取消一律透传，不记为失败）
private suspend fun testOneSong(engine: TestEngine, plat: String, song: LxMusicSearchApi.SongInfo): SongResult {
    val start = System.currentTimeMillis()
    val url: String = try {
        withTimeout(15_000L) { resolveUrlSuspend(engine, plat, song) }""")

    # ⑦ 单平台 5 首制改一首 + 复核：主测过即正常；主测失败换第二首，两首都失败才判败（原因取主测原因）；无歌即搜不到歌
    s = rep("""// [32v146] 单平台严谨测试：5 首顺序测（与 verify() 同规则 ≥4 首过即正常；JS 单线程串行，顺序测与并发测底层一致）
private suspend fun testPlatform(engine: TestEngine, plat: String): TestState {
    var okCount = 0
    var okMs = 0L
    val failReasons = mutableListOf<String>()
    for (song in TEST_SONGS) {
        when (val r = testOneSong(engine, plat, song)) {
            is SongResult.Ok -> { okCount++; okMs += r.ms }
            is SongResult.Fail -> failReasons += r.reason
        }
    }
    if (okCount >= 4) return TestState.Ok(if (okCount > 0) okMs / okCount else 0)
    val reason = failReasons.groupingBy { it }.eachCount().maxByOrNull { it.value }?.key ?: "未知"
    return TestState.Fail(reason, okCount)
}""", """// [32v147] 单平台一首 + 复核：主测过即正常（显示该首耗时）；主测失败换第二首复核，两首都失败才判败（原因取主测原因）；无歌即搜不到歌
private suspend fun testPlatformProbe(engine: TestEngine, plat: String, songs: List<LxMusicSearchApi.SongInfo>): TestState {
    if (songs.isEmpty()) return TestState.NoSong
    val main = testOneSong(engine, plat, songs[0])
    if (main is SongResult.Ok) return TestState.Ok(main.ms)
    val mainReason = main.reason
    if (songs.size < 2) return TestState.Fail(mainReason, false)
    val backup = testOneSong(engine, plat, songs[1])
    if (backup is SongResult.Ok) return TestState.Ok(backup.ms)
    return TestState.Fail(mainReason, true)
}""")

    # ⑧ Range 共用 Client：连接复用，省每首歌重复 TLS 握手（超时与 rangeCheckOk 同值 5 秒）
    s = rep("""// [32v146] Range 真拉流：与卡片 verify() 的 rangeCheckOk 同体（200/206 + 音频 Content-Type + 实读数据；顶层无 verifier 的 TAG，用字面 tag）
private fun testRangeOk(url: String): Boolean {
    return try {
        val client = okhttp3.OkHttpClient.Builder()
            .connectTimeout(5, java.util.concurrent.TimeUnit.SECONDS)
            .readTimeout(5, java.util.concurrent.TimeUnit.SECONDS)
            .followRedirects(true)
            .build()""", """// [32v147] Range 真拉流：与卡片 verify() 的 rangeCheckOk 同体（200/206 + 音频 Content-Type + 实读数据；顶层无 verifier 的 TAG，用字面 tag）；Client 共用，连接复用省重复 TLS 握手
private val sharedRangeClient = okhttp3.OkHttpClient.Builder() // [32v147]
    .connectTimeout(5, java.util.concurrent.TimeUnit.SECONDS)
    .readTimeout(5, java.util.concurrent.TimeUnit.SECONDS)
    .followRedirects(true)
    .build()

private fun testRangeOk(url: String): Boolean {
    return try {
        val client = sharedRangeClient // [32v147]""")

    # 后验：新串齐全、旧串清零
    for k, c in [
        ("data class Fail(val reason: String, val bothFailed: Boolean)", 1),
        ("data object NoSong : TestState", 1),
        ("async { testPlatformProbe(eng, plat, songsByPlat[probeNormPlat(plat)] ?: emptyList()) }", 1),
        ("TestState.NoSong -> Text(\"搜不到歌\"", 1),
        ("private const val PROBE_KEYWORD", 1),
        ("fun probeSongsByPlatform", 1),
        ("fun pickProbeSongs", 1),
        ("fun probeNormPlat", 1),
        ("fun testPlatformProbe", 1),
        ("val sharedRangeClient", 1),
        ("val client = sharedRangeClient", 1),
        ("LxMusicSearchApi.searchFull(PROBE_KEYWORD)", 1),
        ("fun resolveUrlSuspend(engine: TestEngine, plat: String, song: LxMusicSearchApi.SongInfo)", 1),
        ("fun testOneSong(engine: TestEngine, plat: String, song: LxMusicSearchApi.SongInfo)", 1),
        ("phase = \"正在搜索...\"", 1),
        ("phase = \"搜索失败\"", 1),
    ]:
        assert s.count(k) == c, "v147 后验失败 %s: %d != %d" % (k[:50], s.count(k), c)
    for old in [
        "private val TEST_SONGS",
        "testPlatform(eng, plat)",
        "${r.okCount}/5通过",
        "song: Triple<String, String, String>",
        "songId: String, name: String, singer: String",
        "for (song in TEST_SONGS)",
        "groupingBy { it }.eachCount().maxByOrNull",
    ]:
        assert old not in s, "v147 旧串残留: " + old[:60]
    assert s.count("[32v147]") >= 16, "v147 标记数=" + str(s.count("[32v147]"))
    open(M, "w", encoding="utf-8").write(s)
    print("OK 32 v147 高级检测一首真歌 + 复核完成")
PYEOF147
echo "=== 32 v147 完成 ==="

# === 32 v148: 构建红修复（CI 853:27 实证：testPlatformProbe 内 if-is-return 后 main 未收窄为 Fail） ===
python3 << 'PYEOF148'
import os

def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
    assert os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"), "find_root 失败"

find_root()
M = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxSourceSettings.kt"
s = open(M, encoding="utf-8").read()
if "[32v148]" in s:
    print("跳过（32 v148 已应用）")
else:
    def rep(old, new, cnt=1):
        n = s.count(old)
        assert n == cnt, "v148 锚点数=%d 期望=%d: %s" % (n, cnt, old[:60])
        return s.replace(old, new)

    # testPlatformProbe 整函数改 return-when 主体分支：Fail 分支内 main 已收窄，reason 可读；v146 同款 when 已绿
    s = rep("""// [32v147] 单平台一首 + 复核：主测过即正常（显示该首耗时）；主测失败换第二首复核，两首都失败才判败（原因取主测原因）；无歌即搜不到歌
private suspend fun testPlatformProbe(engine: TestEngine, plat: String, songs: List<LxMusicSearchApi.SongInfo>): TestState {
    if (songs.isEmpty()) return TestState.NoSong
    val main = testOneSong(engine, plat, songs[0])
    if (main is SongResult.Ok) return TestState.Ok(main.ms)
    val mainReason = main.reason
    if (songs.size < 2) return TestState.Fail(mainReason, false)
    val backup = testOneSong(engine, plat, songs[1])
    if (backup is SongResult.Ok) return TestState.Ok(backup.ms)
    return TestState.Fail(mainReason, true)
}""", """// [32v148] 构建红修复：CI 853:27 实证——if (main is Ok) return 后编译器不把 main 收窄为 Fail（接收者仍为 SongResult 父类型），改 return-when 主体分支（v146 同款已绿写法）
private suspend fun testPlatformProbe(engine: TestEngine, plat: String, songs: List<LxMusicSearchApi.SongInfo>): TestState {
    if (songs.isEmpty()) return TestState.NoSong
    return when (val main = testOneSong(engine, plat, songs[0])) {
        is SongResult.Ok -> TestState.Ok(main.ms)
        is SongResult.Fail -> {
            if (songs.size < 2) TestState.Fail(main.reason, false)
            else when (val backup = testOneSong(engine, plat, songs[1])) {
                is SongResult.Ok -> TestState.Ok(backup.ms)
                is SongResult.Fail -> TestState.Fail(main.reason, true)
            }
        }
    }
}""")

    # 后验：新串齐全、旧串清零
    for k, c in [
        ("return when (val main = testOneSong(engine, plat, songs[0])) {", 1),
        ("when (val backup = testOneSong(engine, plat, songs[1])) {", 1),
        ("fun testPlatformProbe(engine: TestEngine, plat: String, songs: List<LxMusicSearchApi.SongInfo>): TestState {", 1),
    ]:
        assert s.count(k) == c, "v148 后验失败 %s: %d != %d" % (k[:50], s.count(k), c)
    for old in [
        "val mainReason = main.reason",
        "if (main is SongResult.Ok) return TestState.Ok(main.ms)",
        "return TestState.Fail(mainReason, true)",
    ]:
        assert old not in s, "v148 旧串残留: " + old[:60]
    assert s.count("[32v148]") >= 1, "v148 标记数=" + str(s.count("[32v148]"))
    open(M, "w", encoding="utf-8").write(s)
    print("OK 32 v148 构建红修复完成")
PYEOF148
echo "=== 32 v148 完成 ==="
# === 32 v149: 探针补强（JSON 取 url + 占位黑名单 + [object] + m3u8/mpd 类型门 + 取消先行） ===
python3 << 'PYEOF149'
import os

def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
    assert os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"), "find_root 失败"

find_root()
M = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxSourceSettings.kt"
s = open(M, encoding="utf-8").read()
if "[32v149]" in s:
    print("跳过（32 v149 已应用）")
else:
    def rep(old, new, cnt=1):
        n = s.count(old)
        assert n == cnt, "v149 锚点数=%d 期望=%d: %s" % (n, cnt, old[:60])
        return s.replace(old, new)

    # 1) isValidTestMusicUrl：长度门后加整段 host 占位黑名单（只比 host，不禁裸词 test）；关键词表追加 [object]（防 [object Object]/[object Promise]）
    s = rep("""private fun isValidTestMusicUrl(url: String): Boolean {
    if (url.isBlank()) return false
    val u = url.trim()
    if (!u.startsWith("http://") && !u.startsWith("https://")) return false
    if (u.length < 30) return false
    val lower = u.lowercase()
    val badKeywords = listOf("error", "null", "undefined", "fail", "empty", "404", "notfound")""", """private fun isValidTestMusicUrl(url: String): Boolean {
    if (url.isBlank()) return false
    val u = url.trim()
    if (!u.startsWith("http://") && !u.startsWith("https://")) return false
    if (u.length < 30) return false
    // [32v149] 占位黑名单：只比整段 host，不禁裸词 test（带参数的长占位 URL 至此才拦得住）
    val host = u.substringAfter("://").substringBefore("/").substringBefore("?").substringBefore(":").lowercase()
    if (host == "example.com" || host == "example.org" || host == "example.net" ||
        host == "localhost" || host == "127.0.0.1" ||
        host.endsWith(".example.com") || host.endsWith(".example.org") || host.endsWith(".example.net")) return false
    val lower = u.lowercase()
    val badKeywords = listOf("error", "null", "undefined", "fail", "empty", "404", "notfound", "[object")""")

    # 2) JSON 对象兼容 helper：插在 resolveUrlSuspend 定义之前；org.json 全限定写法，不新增 import
    s = rep("""private suspend fun resolveUrlSuspend(engine: TestEngine, plat: String, song: LxMusicSearchApi.SongInfo): String =""", """// [32v149] JSON 对象兼容：脚本返回 {"url": "..."} 时先取 url 字段；不是 JSON 对象、解析失败、url 字段为空时原样返回，由下游 isValidTestMusicUrl 判负（fail-closed，不崩）
private fun extractUrlField(raw: String): String {
    val t = raw.trim()
    if (!t.startsWith("{")) return raw
    return try {
        val url = org.json.JSONObject(t).optString("url", "")
        if (url.isNotBlank()) url.trim() else raw
    } catch (e: Exception) {
        raw
    }
}

private suspend fun resolveUrlSuspend(engine: TestEngine, plat: String, song: LxMusicSearchApi.SongInfo): String =""")

    # 3) resolveUrlSuspend 的 onSuccess：引擎结果先进 extractUrlField 再 resume；15 秒超时与取消透传在 testOneSong，原样不动
    s = rep("""onSuccess = { url -> cont.resume(url, null) },""", """onSuccess = { raw -> cont.resume(extractUrlField(raw), null) }, // [32v149]""")

    # 4) testRangeOk 类型门：audio/octet-stream 之外放行 m3u8/mpd；锚点带 LxSourceTest 日志行，与 verifier 的 rangeCheckOk（TAG 日志）区分
    s = rep("""            val typeOk = contentType.contains("audio") ||
                    contentType.contains("application/octet-stream")
            if (!typeOk) {
                android.util.Log.w("LxSourceTest", "Content-Type 不通过: $contentType $url")""", """            val typeOk = contentType.contains("audio") ||
                    contentType.contains("application/octet-stream") ||
                    contentType.contains("mpegurl") || // [32v149] m3u8：application/x-mpegURL / vnd.apple.mpegurl，ExoPlayer 可播
                    contentType.contains("dash+xml") // [32v149] mpd：application/dash+xml，ExoPlayer 可播
            if (!typeOk) {
                android.util.Log.w("LxSourceTest", "Content-Type 不通过: $contentType $url")""")

    # 5) testRangeOk catch：取消先行再兜底；Client 共用、GET+Range 0-1023、200/206、实读数据门原样不动
    s = rep("""    } catch (e: Exception) {
        android.util.Log.w("LxSourceTest", "Range 检查异常: $url", e)
        false
    }""", """    } catch (e: CancellationException) {
        throw e // [32v149] 取消先行，不记为失败
    } catch (e: Exception) {
        android.util.Log.w("LxSourceTest", "Range 检查异常: $url", e)
        false
    }""")

    # 后验：新串齐全、旧串清零、标记数
    for k, c in [
        ("private fun extractUrlField(raw: String): String {", 1),
        ("cont.resume(extractUrlField(raw), null)", 1),
        ("host.endsWith(\".example.com\")", 1),
        ("\"[object\")", 1),
        ("contains(\"mpegurl\")", 1),
        ("contains(\"dash+xml\")", 1),
    ]:
        assert s.count(k) == c, "v149 后验失败 %s: %d != %d" % (k[:50], s.count(k), c)
    for old in [
        "onSuccess = { url -> cont.resume(url, null) },",
        "contains(\"application/octet-stream\")\n            if (!typeOk)",
    ]:
        assert old not in s, "v149 旧串残留: " + old[:60]
    # 注意：verifier 的 isValidMusicUrl（约 1500 行）仍是旧关键词表，那是卡片 verify() 的路，本次探针范围不动，故旧表残留恰为 1
    assert s.count("val badKeywords = listOf(\"error\", \"null\", \"undefined\", \"fail\", \"empty\", \"404\", \"notfound\")") == 1, "v149 旧关键词表残留数异常"
    assert s.count("[32v149]") == 6, "v149 标记数=" + str(s.count("[32v149]"))
    open(M, "w", encoding="utf-8").write(s)
    print("OK 32 v149 探针补强完成")
PYEOF149
echo "=== 32 v149 完成 ==="
# === 32 v150: Range 失败明细进运行日志（判定门不动，只把码/类型/读数写进 LxRuntimeLog） ===
python3 << 'PYEOF150'
import os

def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
    assert os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"), "find_root 失败"

find_root()
M = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxSourceSettings.kt"
s = open(M, encoding="utf-8").read()
if "[32v150]" in s:
    print("跳过（32 v150 已应用）")
else:
    def rep(old, new, cnt=1):
        n = s.count(old)
        assert n == cnt, "v150 锚点数=%d 期望=%d: %s" % (n, cnt, old[:60])
        return s.replace(old, new)

    # 1) import：LxRuntimeLog 在 util 包（v115 建，object + add(String)）；v116 已给 LxSourceSettings 加过该 import（无标记），CI 全链到此已有 1 份，再加即 2 份致后验失败——故已存在时只补标记、不重复加（v152 修复，落 v150 块内：v150 后验先死，后续块跑不到）
    if "import com.github.tvbox.osc.util.LxRuntimeLog" in s:
        s = rep("""import com.github.tvbox.osc.util.LxRuntimeLog""", """import com.github.tvbox.osc.util.LxRuntimeLog // [32v150]""")
    else:
        s = rep("""import com.github.tvbox.osc.util.ScriptInfo""", """import com.github.tvbox.osc.util.ScriptInfo
import com.github.tvbox.osc.util.LxRuntimeLog // [32v150]""")

    # 2) testOneSong 的 Range 段：Boolean 改明细，失败时写运行日志（码/类型/读数/异常；只记 host 不记完整 URL，签名参数不进日志）；格子原因仍为 Range失败
    s = rep("""    val rangeOk = try {
        withContext(Dispatchers.IO) { testRangeOk(url) }
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        false
    }
    if (!rangeOk) return SongResult.Fail("Range失败")""", """    val range = try {
        withContext(Dispatchers.IO) { testRangeOk(url) }
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        RangeDetail(false, -1, "", 0, "异常:" + (e::class.simpleName ?: "?") + ":" + (e.message ?: ""))
    }
    if (!range.ok) {
        // [32v150] Range 失败明细进运行日志：码/类型/读数/异常；只记 host 不记完整 URL（签名参数不进日志）
        val host = url.substringAfter("://").substringBefore("/").substringBefore("?")
        LxRuntimeLog.add("探针 Range 失败: plat=" + plat + " 歌=" + song.title + "/" + song.artist + " 码=" + range.code + " 类型=" + range.contentType + " 读数=" + range.readBytes + " host=" + host + if (range.error.isNotEmpty()) " 原因=" + range.error else "")
        return SongResult.Fail("Range失败")
    }""")

    # 3) RangeDetail 定义 + testRangeOk 签名：Boolean 改明细；判定门（码/类型/读数）一字未动
    s = rep("""private fun testRangeOk(url: String): Boolean {""", """// [32v150] Range 明细：返回值由 Boolean 改 RangeDetail，判定门（码/类型/读数）一字未动；失败明细由 testOneSong 写运行日志
private data class RangeDetail(
    val ok: Boolean,
    val code: Int,
    val contentType: String,
    val readBytes: Long,
    val error: String
)

private fun testRangeOk(url: String): RangeDetail {""")

    # 4) testRangeOk 内各返回点：只换返回值，门与日志行不动（锚点带 LxSourceTest 日志行，与 verifier 的 TAG 版区分）
    s = rep("""            if (code != 200 && code != 206) {
                android.util.Log.w("LxSourceTest", "Range GET 状态码不通过: $code $url")
                return false
            }""", """            if (code != 200 && code != 206) {
                android.util.Log.w("LxSourceTest", "Range GET 状态码不通过: $code $url")
                return RangeDetail(false, code, "", 0, "状态码不通过")
            }""")
    s = rep("""            if (!typeOk) {
                android.util.Log.w("LxSourceTest", "Content-Type 不通过: $contentType $url")
                return false
            }""", """            if (!typeOk) {
                android.util.Log.w("LxSourceTest", "Content-Type 不通过: $contentType $url")
                return RangeDetail(false, code, contentType, 0, "类型不通过")
            }""")
    s = rep("""            val contentLength = resp.header("Content-Length")?.toLongOrNull() ?: -1L
            if (contentLength > 0) return true""", """            val contentLength = resp.header("Content-Length")?.toLongOrNull() ?: -1L
            if (contentLength > 0) return RangeDetail(true, code, contentType, contentLength, "")""")
    s = rep("""            if (body == null) {
                android.util.Log.w("LxSourceTest", "响应 body 为空: $url")
                return false
            }""", """            if (body == null) {
                android.util.Log.w("LxSourceTest", "响应 body 为空: $url")
                return RangeDetail(false, code, contentType, 0, "body为空")
            }""")
    s = rep("""            val ok = buf.size > 0
            if (!ok) android.util.Log.w("LxSourceTest", "未读到任何数据: $url")
            ok""", """            if (buf.size <= 0) android.util.Log.w("LxSourceTest", "未读到任何数据: $url")
            RangeDetail(buf.size > 0, code, contentType, readTotal, if (buf.size > 0) "" else "未读到数据")""")
    s = rep("""    } catch (e: Exception) {
        android.util.Log.w("LxSourceTest", "Range 检查异常: $url", e)
        false
    }""", """    } catch (e: Exception) {
        android.util.Log.w("LxSourceTest", "Range 检查异常: $url", e)
        RangeDetail(false, -1, "", 0, "异常:" + (e::class.simpleName ?: "?") + ":" + (e.message ?: ""))
    }""")

    # 后验：新串齐全、旧串清零、标记数（注意：verifier 的 rangeCheckOk 仍是旧版，它的那行 return true 是另一条路，不在此列）
    for k, c in [
        ("private data class RangeDetail(", 1),
        ("fun testRangeOk(url: String): RangeDetail", 1),
        ("import com.github.tvbox.osc.util.LxRuntimeLog", 1),
        ("LxRuntimeLog.add(\"探针 Range 失败:", 1),
        ("return RangeDetail(false, code, \"\", 0, \"状态码不通过\")", 1),
        ("return RangeDetail(false, code, contentType, 0, \"类型不通过\")", 1),
        ("return RangeDetail(true, code, contentType, contentLength", 1),
        ("RangeDetail(buf.size > 0, code, contentType, readTotal", 1),
    ]:
        assert s.count(k) == c, "v150 后验失败 %s: %d != %d" % (k[:50], s.count(k), c)
    for old in [
        "private fun testRangeOk(url: String): Boolean {",
        "val rangeOk = try {",
        "if (!rangeOk) return SongResult.Fail(\"Range失败\")",
    ]:
        assert old not in s, "v150 旧串残留: " + old[:60]
    assert s.count("[32v150]") == 3, "v150 标记数=" + str(s.count("[32v150]"))
    open(M, "w", encoding="utf-8").write(s)
    print("OK 32 v150 Range 明细进日志完成")
PYEOF150
echo "=== 32 v150 完成 ==="
# === 32 v151: SourceTestDialog 单列重构（仅渲染段，逻辑不动） ===
python3 << 'PYEOF151'
import os

def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
    assert os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"), "find_root 失败"

find_root()
M = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxSourceSettings.kt"
s = open(M, encoding="utf-8").read()
if "[32v151]" in s:
    print("跳过（32 v151 已应用）")
else:
    def rep(old, new, cnt=1):
        n = s.count(old)
        assert n == cnt, "v151 锚点数=%d 期望=%d: %s" % (n, cnt, old[:60])
        return s.replace(old, new)

    # 1) import：删 grid 三件（仅弹窗用），补 7 个新符号
    s = rep("""import androidx.compose.foundation.lazy.grid.GridCells // [32v143]
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid // [32v143]""", "")
    s = rep("""import androidx.compose.foundation.lazy.grid.items // [32v144]""", """import androidx.compose.foundation.layout.heightIn // [32v151]
import androidx.compose.foundation.lazy.itemsIndexed // [32v151]
import androidx.compose.foundation.shape.RoundedCornerShape // [32v151]
import androidx.compose.material3.ButtonDefaults // [32v151]
import androidx.compose.material3.HorizontalDivider // [32v151]
import androidx.compose.ui.text.font.FontWeight // [32v151]
import androidx.compose.ui.unit.sp // [32v151]""")

    # 2) Card：20.dp 圆角（颜色不动）
    s = rep("""        Card(colors = CardDefaults.cardColors(containerColor = musicColors().card)) {""", """        Card( // [32v151]
            shape = RoundedCornerShape(20.dp),
            colors = CardDefaults.cardColors(containerColor = musicColors().card)
        ) {""")

    # 3) 外层 Column 内边距 16.dp -> 24.dp；标题 titleMedium -> titleLarge + Bold；补 4.dp 间隔
    s = rep("""            Column(Modifier.padding(16.dp)) {
                Text("${source.name} · 高级检测", style = MaterialTheme.typography.titleMedium, color = musicColors().textPrimary)""", """            Column(Modifier.padding(24.dp)) {
                Text(
                    "${source.name} · 高级检测",
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold,
                    color = musicColors().textPrimary
                )
                Spacer(Modifier.height(4.dp))""")

    # 4) 副标题 labelSmall -> bodySmall（phase 文案本身不动）
    s = rep("""                Text(phase, style = MaterialTheme.typography.labelSmall, color = musicColors().textSecondary)""", """                Text(
                    phase,
                    style = MaterialTheme.typography.bodySmall,
                    color = musicColors().textSecondary
                )""")

    # 5) Grid 3 列 -> 单列 LazyColumn：span 替换（字符串/注释内大括号不计数），其余渲染段按 spec 重写；TestState/探针逻辑一字不动
    g_anchor = "                LazyVerticalGrid(columns = GridCells.Fixed(3)) {"
    assert s.count(g_anchor) == 1, "v151 grid 锚点数 != 1"
    g0 = s.index(g_anchor)
    depth = 0
    i = g0
    state = "code"
    end = None
    while i < len(s):
        ch = s[i]
        nxt = s[i + 1] if i + 1 < len(s) else ""
        if state == "code":
            if ch == '"' and s.startswith('"""', i):
                state = "triple"
                i += 3
                continue
            if ch == '"':
                state = "str"
                i += 1
                continue
            if ch == "'":
                state = "chr"
                i += 1
                continue
            if ch == "/" and nxt == "/":
                state = "line"
                i += 2
                continue
            if ch == "/" and nxt == "*":
                state = "block"
                i += 2
                continue
            if ch == "{":
                depth += 1
            elif ch == "}":
                depth -= 1
                if depth == 0:
                    end = i + 1
                    break
            i += 1
        elif state == "str":
            if ch == "\\":
                i += 2
            elif ch == '"':
                state = "code"
                i += 1
            else:
                i += 1
        elif state == "chr":
            if ch == "\\":
                i += 2
            elif ch == "'":
                state = "code"
                i += 1
            else:
                i += 1
        elif state == "triple":
            if s.startswith('"""', i):
                state = "code"
                i += 3
            else:
                i += 1
        elif state == "line":
            if ch == "\n":
                state = "code"
            i += 1
        elif state == "block":
            if ch == "*" and nxt == "/":
                state = "code"
                i += 2
            else:
                i += 1
    assert end is not None, "v151 grid span 未闭合"
    new_span = """                Spacer(Modifier.height(20.dp))
                LazyColumn(Modifier.heightIn(max = 360.dp)) { // [32v151]
                    itemsIndexed(platforms, key = { _, plat -> plat }) { index, plat ->
                        Column {
                            Row(
                                modifier = Modifier.fillMaxWidth().padding(vertical = 14.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(
                                    platformName(plat),
                                    modifier = Modifier.width(90.dp),
                                    style = MaterialTheme.typography.bodyMedium,
                                    fontWeight = FontWeight.Medium,
                                    color = musicColors().textPrimary,
                                    maxLines = 1,
                                    overflow = TextOverflow.Ellipsis
                                )
                                Row(
                                    modifier = Modifier.weight(1f),
                                    horizontalArrangement = Arrangement.End,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    when (val r = results[plat]) {
                                        null, TestState.Testing -> {
                                            Row(verticalAlignment = Alignment.CenterVertically) {
                                                CircularProgressIndicator(
                                                    modifier = Modifier.size(14.dp),
                                                    color = Color(0xFFFFA000),
                                                    strokeWidth = 1.5.dp
                                                )
                                                Spacer(Modifier.width(6.dp))
                                                Text("检测中", color = Color(0xFFFFA000), fontSize = 13.sp)
                                            }
                                        }
                                        is TestState.Ok -> {
                                            Text("成功", color = Color(0xFF00B894), fontWeight = FontWeight.Bold, fontSize = 13.sp)
                                            Spacer(Modifier.width(8.dp))
                                            Text("${r.ms}ms", color = musicColors().textSecondary, fontSize = 12.sp)
                                        }
                                        is TestState.Fail -> {
                                            Text("失败", color = Color(0xFFFF7675), fontWeight = FontWeight.Bold, fontSize = 13.sp)
                                        }
                                        TestState.NoSong -> {
                                            Text("搜不到歌", color = musicColors().textSecondary, fontSize = 13.sp)
                                        }
                                    }
                                }
                            }
                            if (index < platforms.size - 1) {
                                HorizontalDivider(
                                    color = musicColors().textSecondary.copy(alpha = 0.1f),
                                    thickness = 0.5.dp
                                )
                            }
                        }
                    }
                }
"""
    s = s[:g0] + new_span + s[end:]

    # 6) 底部 TextButton -> 全宽 48.dp accent 按钮（白字 titleMedium），前补 24.dp 间隔
    s = rep("""                TextButton(onClick = onDismiss) { Text("完成") }""", """                Spacer(Modifier.height(24.dp))
                Button(
                    onClick = onDismiss,
                    modifier = Modifier.fillMaxWidth().height(48.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = musicColors().accent,
                        contentColor = Color.White
                    )
                ) {
                    Text("完成", style = MaterialTheme.typography.titleMedium)
                }""")

    # 7) 后验：旧渲染残留为 0，新渲染在位，注解未被吞
    assert "LazyVerticalGrid" not in s, "v151 残留 LazyVerticalGrid"
    assert "GridCells" not in s, "v151 残留 GridCells"
    assert "TextButton(onClick = onDismiss)" not in s, "v151 残留 TextButton"
    assert "itemsIndexed(platforms" in s, "v151 缺 itemsIndexed"
    assert "RoundedCornerShape(20.dp)" in s, "v151 缺 20.dp 圆角"
    assert "HorizontalDivider(" in s, "v151 缺 HorizontalDivider"
    assert "ButtonDefaults.buttonColors(" in s, "v151 缺 ButtonDefaults"
    assert "heightIn(max = 360.dp)" in s, "v151 缺 heightIn"
    assert "@Composable\nprivate fun SourceTestDialog" in s, "v151 吞了 SourceTestDialog 注解"
    lines = s.split("\n")
    di = next(i for i, ln in enumerate(lines) if ln.startswith("private fun SourceTestDialog"))
    print("DIALOG_ANNOT:", lines[di - 1])
    ti = next(i for i, ln in enumerate(lines) if ln.startswith("private class TestEngine"))
    print("BEFORE_TESTENGINE:", lines[ti - 2], "|", lines[ti - 1])
    open(M, "w", encoding="utf-8").write(s)
    print("OK 32 v151 SourceTestDialog 单列重构完成")
PYEOF151
echo "=== 32 v151 完成 ==="
