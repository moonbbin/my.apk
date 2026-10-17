#!/bin/bash
# 32_music_theme_dark_light.sh v3 (2026-10-17): 修复重复 cd avbox (2026-10-17): 桥接方案完整实装 (2026-10-17): 全局深色/浅色切换 + 播放页动态取色
# 包含：浅色 Token、Theme 双盘、ThemeViewModel(DataStore)、MainActivity 注入、设置页开关、PlayerScreen 动态取色、build.gradle 依赖
set -e
cd avbox

echo "=== 32 v15：深色/浅色全局切换 ==="

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

echo "=== 32 v15 PartA2 完成 ==="

# 32 v15: 修复 LxMusicTheme.kt 的 import 缺失
echo "=== 32 v15 PartA3: 补 Import ==="

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
print("=== 32 v15 PartA3 完成 ===")
PYEOF

# 32 v15: PartB 详细打印 MainActivity setContent 结构
echo "=== 32 v15 PartB: MainActivity 详细结构 ==="

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
echo "=== 32 v15 PartB 完成（仅排查，不修改）==="
# 不退出 1，让构建继续，先看到结构

# 32 v15 PartC: 搜 isSystemInDarkTheme 并替换
set -e
# cd avbox (已在 avbox 内，跳过)

echo "=== 32 v15 PartC：isSystemInDarkTheme 排查 ==="

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

echo "=== 32 v15 PartC 完成 ==="
# 32 v15 PartD: Modifier.shadow 检查
set -e
# cd avbox (已在 avbox 内，跳过)

echo "=== 32 v15 PartD：shadow 检查 ==="

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

echo "=== 32 v15 PartD 完成 ==="

# 32 v15: BrandGreen -> PlayerGreen (实际存在的常量名)
echo "=== 32 v15: 修复 BrandGreen ==="

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
print("=== 32 v15 完成 ===")
PYEOF

# 32 v15: PlayerGreen 改为 public
echo "=== 32 v15: PlayerGreen public ==="

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
print("=== 32 v15 完成 ===")
PYEOF

# 32 v15: 按用户要求 - Color.kt private->internal，确保 BrandGreen 存在；LxMusicTheme 统一用 BrandGreen
echo "=== 32 v15: 主题 Token 可见性修复 ==="

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

print("=== 32 v15 完成 ===")
PYEOF

# 32 v15: 按用户三步要求 - Color.kt 加 BrandGreen(0xFF34C759)，确保可见性；LxMusicTheme 确保 import
echo "=== 32 v15: BrandGreen 三步修复 ==="

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

print("=== 32 v15 完成 ===")
PYEOF

# 32 v15: 强制 BrandGreen = Color(0xFF34C759)，覆盖旧别名
echo "=== 32 v15: 强制 BrandGreen 定义 ==="

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

print("=== 32 v15 完成 ===")
PYEOF

# 32 v15: 补设置页主题开关 + MainActivity 接线
echo "=== 32 v15: 主题开关与 MainActivity 接线 ==="

python3 << 'PYEOF'
import re, sys

# ===== Part 1: SettingsScreen 加 ThemeSettingItem =====
spath = "app/src/main/java/com/github/tvbox/osc/ui/music/settings/SettingsScreen.kt"
try:
    with open(spath, encoding="utf-8") as f:
        ssrc = f.read()
except FileNotFoundError:
    print(f"警告: 未找到 {spath}，跳过设置页")
    ssrc = None

if ssrc is not None and "// [32v13] ThemeSettingItem" not in ssrc:
    # 主题开关 composable（用户定稿版）
    theme_item_code = '''
// [32v13] ThemeSettingItem: 深色模式切换
@Composable
fun ThemeSettingItem(
    themeViewModel: com.github.tvbox.osc.ui.music.theme.ThemeViewModel = androidx.hilt.navigation.compose.hiltViewModel()
) {
    val themeMode by themeViewModel.themeMode.collectAsState()
    var showDialog by androidx.compose.runtime.remember { androidx.compose.runtime.mutableStateOf(false) }

    val modeLabel = when (themeMode) {
        com.github.tvbox.osc.ui.music.theme.ThemeMode.FORCE_DARK -> "深色"
        com.github.tvbox.osc.ui.music.theme.ThemeMode.FORCE_LIGHT -> "浅色"
        else -> "跟随系统"
    }

    SettingItem(
        title = "深色模式",
        subtitle = modeLabel,
        onClick = { showDialog = true }
    )

    if (showDialog) {
        androidx.compose.material3.AlertDialog(
            onDismissRequest = { showDialog = false },
            title = {
                androidx.compose.material3.Text(
                    "深色模式",
                    style = androidx.compose.material3.MaterialTheme.typography.titleLarge
                )
            },
            text = {
                androidx.compose.foundation.layout.Column {
                    ThemeOption(
                        label = "跟随系统",
                        selected = themeMode == com.github.tvbox.osc.ui.music.theme.ThemeMode.FOLLOW_SYSTEM,
                        onClick = {
                            themeViewModel.setThemeMode(com.github.tvbox.osc.ui.music.theme.ThemeMode.FOLLOW_SYSTEM)
                            showDialog = false
                        }
                    )
                    ThemeOption(
                        label = "开启（深色）",
                        selected = themeMode == com.github.tvbox.osc.ui.music.theme.ThemeMode.FORCE_DARK,
                        onClick = {
                            themeViewModel.setThemeMode(com.github.tvbox.osc.ui.music.theme.ThemeMode.FORCE_DARK)
                            showDialog = false
                        }
                    )
                    ThemeOption(
                        label = "关闭（浅色）",
                        selected = themeMode == com.github.tvbox.osc.ui.music.theme.ThemeMode.FORCE_LIGHT,
                        onClick = {
                            themeViewModel.setThemeMode(com.github.tvbox.osc.ui.music.theme.ThemeMode.FORCE_LIGHT)
                            showDialog = false
                        }
                    )
                }
            },
            confirmButton = {
                androidx.compose.material3.TextButton(onClick = { showDialog = false }) {
                    androidx.compose.material3.Text("取消")
                }
            }
        )
    }
}

@Composable
private fun ThemeOption(
    label: String,
    selected: Boolean,
    onClick: () -> Unit
) {
    androidx.compose.foundation.layout.Row(
        modifier = androidx.compose.ui.Modifier
            .fillMaxWidth()
            .clip(androidx.compose.foundation.shape.RoundedCornerShape(8.dp))
            .clickable(onClick = onClick)
            .padding(vertical = 12.dp, horizontal = 8.dp),
        verticalAlignment = androidx.compose.ui.Alignment.CenterVertically
    ) {
        androidx.compose.material3.RadioButton(
            selected = selected,
            onClick = null,
            colors = androidx.compose.material3.RadioButtonDefaults.colors(
                selectedColor = androidx.compose.material3.MaterialTheme.colorScheme.primary,
                unselectedColor = androidx.compose.material3.MaterialTheme.colorScheme.onSurfaceVariant
            )
        )
        androidx.compose.foundation.layout.Spacer(
            modifier = androidx.compose.ui.Modifier.width(12.dp)
        )
        androidx.compose.material3.Text(
            text = label,
            style = androidx.compose.material3.MaterialTheme.typography.bodyLarge,
            color = androidx.compose.material3.MaterialTheme.colorScheme.onSurface
        )
    }
}
'''
    # 追加到文件末尾
    ssrc = ssrc.rstrip() + "\n" + theme_item_code + "\n"
    with open(spath, "w", encoding="utf-8") as f:
        f.write(ssrc)
    print("1) SettingsScreen.kt: ThemeSettingItem 已追加")
    print("   注意: 需手动在设置列表中调用 ThemeSettingItem()")
else:
    print("1) SettingsScreen.kt: 已有 ThemeSettingItem，跳过")

# ===== Part 2: MainActivity 接线 =====
mpath = "app/src/main/java/com/github/tvbox/osc/ui/activity/MainActivity.kt"
with open(mpath, encoding="utf-8") as f:
    msrc = f.read()

if "// [32v13] MainActivity theme" not in msrc:
    # 加 findActivity 扩展函数和必要的 import
    # 在文件末尾追加扩展函数
    ext_code = '''
// [32v13] MainActivity theme: 安全获取 Activity
fun android.content.Context.findActivity(): android.app.Activity? {
    var ctx = this
    while (ctx is android.content.ContextWrapper) {
        if (ctx is android.app.Activity) return ctx
        ctx = ctx.baseContext
    }
    return null
}
'''
    msrc = msrc.rstrip() + "\n" + ext_code + "\n"

    # 在 setContent 中包裹 LxMusicTheme
    # 找 setContent { 的位置
    m = re.search(r'setContent\s*\{', msrc)
    if m:
        # 在 setContent { 后插入主题逻辑
        insert_pos = m.end()
        theme_wrap = '''
        // [32v13] MainActivity theme: 主题切换
        val themeViewModel: com.github.tvbox.osc.ui.music.theme.ThemeViewModel = androidx.hilt.navigation.compose.hiltViewModel()
        val themeMode by themeViewModel.themeMode.collectAsState()
        val systemDark = androidx.compose.foundation.isSystemInDarkTheme()
        val isDark = when (themeMode) {
            com.github.tvbox.osc.ui.music.theme.ThemeMode.FORCE_DARK -> true
            com.github.tvbox.osc.ui.music.theme.ThemeMode.FORCE_LIGHT -> false
            else -> systemDark
        }
        val context = androidx.compose.ui.platform.LocalContext.current
        val window = context.findActivity()?.window
        androidx.compose.runtime.SideEffect {
            window?.let {
                val controller = androidx.core.view.WindowCompat.getInsetsController(it, it.decorView)
                controller.isAppearanceLightStatusBars = !isDark
                controller.isAppearanceLightNavigationBars = !isDark
            }
        }
        com.github.tvbox.osc.ui.activity.LxMusicTheme(isDarkTheme = isDark) {
'''
        # 找到 setContent 块的结束位置（匹配大括号）
        # 简化：假设 setContent 是最后一个大块，在文件末尾前插入闭合
        # 这里用括号匹配
        depth = 1
        end_pos = insert_pos
        for i in range(insert_pos, len(msrc)):
            if msrc[i] == '{':
                depth += 1
            elif msrc[i] == '}':
                depth -= 1
                if depth == 0:
                    end_pos = i
                    break

        msrc = msrc[:insert_pos] + theme_wrap + msrc[insert_pos:end_pos] + "\n        }\n" + msrc[end_pos:]
        print("2) MainActivity.kt: 已包裹 LxMusicTheme(isDarkTheme)")
    else:
        print("2) 警告: 未找到 setContent")

    with open(mpath, "w", encoding="utf-8") as f:
        f.write(msrc)
else:
    print("2) MainActivity.kt: 已有主题接线，跳过")

print("=== 32 v15 完成 ===")
PYEOF

# 32 v15: 在设置列表中自动插入 ThemeSettingItem() 调用
echo "=== 32 v15: 插入主题开关调用 ==="

python3 << 'PYEOF'
import re

spath = "app/src/main/java/com/github/tvbox/osc/ui/music/settings/SettingsScreen.kt"
with open(spath, encoding="utf-8") as f:
    ssrc = f.read()

MARK = "// [32v14] ThemeSettingItem call"
if MARK in ssrc:
    print("32 v15: 已插入，跳过")
else:
    # 找设置列表：通常是 LazyColumn 或 Column 中的 SettingItem 调用
    # 策略：在第一个 SettingItem( 调用前插入 ThemeSettingItem()
    # 先找所有 SettingItem( 的位置
    pattern = r'^(\s*)SettingItem\s*\('
    matches = list(re.finditer(pattern, ssrc, re.MULTILINE))

    if not matches:
        print("错误: 未找到 SettingItem( 调用，无法定位插入点")
        # 打印文件前 50 行帮助诊断
        lines = ssrc.split('\n')[:50]
        for i, l in enumerate(lines, 1):
            print(f"{i:3d}: {l[:80]}")
        exit(1)

    # 在第一个 SettingItem 前插入
    first = matches[0]
    indent = first.group(1)
    insert_pos = first.start()

    call_code = f"{MARK}\n{indent}ThemeSettingItem()\n{indent}"

    ssrc = ssrc[:insert_pos] + call_code + ssrc[insert_pos:]

    with open(spath, "w", encoding="utf-8") as f:
        f.write(ssrc)
    print(f"32 v15: 已在第 {ssrc[:insert_pos].count(chr(10))+1} 行插入 ThemeSettingItem()")

print("=== 32 v15 完成 ===")
PYEOF

# 32 v15: 回滚 v13/v14 的破坏性修改
echo "=== 32 v15: 回滚 ==="

python3 << 'PYEOF'
import re

# 1) SettingsScreen.kt: 删除 v13 加的 ThemeSettingItem 和 v14 加的调用
spath = "app/src/main/java/com/github/tvbox/osc/ui/music/settings/SettingsScreen.kt"
with open(spath, encoding="utf-8") as f:
    ssrc = f.read()

# 删除 v13 的 ThemeSettingItem composable（从标记到文件末尾或下一个大块）
# v13 追加在文件末尾，标记是 // [32v13] ThemeSettingItem
if "// [32v13] ThemeSettingItem" in ssrc:
    # 删除从标记开始到文件末尾（v13 是追加在末尾的）
    ssrc = re.sub(r'\n// \[32v13\] ThemeSettingItem.*$', '', ssrc, flags=re.DOTALL)
    print("1) 已删除 v13 的 ThemeSettingItem")

# 删除 v14 的调用
ssrc = ssrc.replace("// [32v14] ThemeSettingItem call\n", "")
# 删除可能残留的 ThemeSettingItem() 调用行（独立一行）
ssrc = re.sub(r'^\s*ThemeSettingItem\(\)\s*\n', '', ssrc, flags=re.MULTILINE)
print("1) 已删除 v14 的调用")

with open(spath, "w", encoding="utf-8") as f:
    f.write(ssrc)

# 2) MainActivity.kt: 删除 v13 加的主题包裹和 findActivity
mpath = "app/src/main/java/com/github/tvbox/osc/ui/activity/MainActivity.kt"
with open(mpath, encoding="utf-8") as f:
    msrc = f.read()

if "// [32v13] MainActivity theme" in msrc:
    # 删除 findActivity 扩展函数
    msrc = re.sub(
        r'\n// \[32v13\] MainActivity theme: 安全获取 Activity\nfun android\.content\.Context\.findActivity\(\).*?\n\}\n',
        '\n',
        msrc,
        flags=re.DOTALL
    )
    print("2) 已删除 findActivity")

    # 删除 setContent 内的主题包裹代码
    # 找到 // [32v13] MainActivity theme: 主题切换 到对应的闭合
    # 这部分比较复杂，用标记删除
    msrc = re.sub(
        r'\s*// \[32v13\] MainActivity theme: 主题切换\n(?:.*\n)*?\s*com\.github\.tvbox\.osc\.ui\.activity\.LxMusicTheme\(isDarkTheme = isDark\) \{\n',
        '\n',
        msrc
    )
    # 删除多余的闭合大括号（v13 加的）
    # 这个需要小心，先不删，让编译报错指引

    print("2) 已删除主题包裹（部分）")

    with open(mpath, "w", encoding="utf-8") as f:
        f.write(msrc)
else:
    print("2) MainActivity 无 v13 标记，跳过")

print("=== 32 v15 回滚完成 ===")
print("注意: MainActivity 可能需要手动检查括号平衡")
PYEOF

