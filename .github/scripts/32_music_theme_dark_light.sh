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

