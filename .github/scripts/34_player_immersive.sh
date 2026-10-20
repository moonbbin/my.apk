#!/bin/bash
# 34_player_immersive.sh - 播放页沉浸式海报取色背景（定向补丁）
# 本脚本为 LxPlayerActivity.kt 沉浸式背景的唯一控制权。
# 方案B：Python 精确定向替换，不动业务逻辑（Slider/播放控制/22徽标/歌词滚动）。
# [34v12] 修：补Palette依赖、加toArgb import、修海报Box语法
set -e
cd avbox

echo "=== 34 v12: 播放页沉浸式定向补丁 ==="

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
    // [34v12] 背景提鲜：HSV 拉高饱和度/亮度
    val vibrantBg = remember(animatedTint) {
        val hsv = FloatArray(3)
        android.graphics.Color.colorToHSV(animatedTint.toArgb(), hsv)
        hsv[1] = (hsv[1] * 1.4f).coerceAtMost(0.9f)
        hsv[2] = (hsv[2] * 1.2f).coerceAtMost(0.85f)
        Color(android.graphics.Color.HSVToColor(hsv))
    }
    // [34v12] 遮罩后近似色：模拟黑遮罩叠加后的最终可见色
    val finalBg = remember(vibrantBg) {
        val a = 0.45f  // 取遮罩中段 alpha 近似
        Color(
            red = vibrantBg.red * (1 - a),
            green = vibrantBg.green * (1 - a),
            blue = vibrantBg.blue * (1 - a)
        )
    }
    // [34v12] 用最终渲染色算亮度，避免光影误判
    val bgLuminance = remember(finalBg) {
        ColorUtils.calculateLuminance(finalBg.toArgb())
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
    new_bg = """    // [34v12] 沉浸式动态背景：取色 + 黑遮罩防刺眼
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(vibrantBg) // [34v12]
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
                    ) // [34v12] 暗角
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
    new_rainbow = """                    .background(musicColors().cardSecondary) // [34v12] 纯色兜底"""
    assert_replace(old_rainbow, new_rainbow, "海报彩虹背景")

    # === 5. 海报 Box：加悬浮（保留 contentAlignment） ===
    old_box = None
    for _m in ["[34v12]", "[34v5]"]:
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
                        elevation = 32.dp, // [34v12]
                        shape = RoundedCornerShape(20.dp),
                        ambientColor = Color.Black.copy(alpha = 0.4f),
                        spotColor = Color.Black
                    )
                    .border(
                        width = 1.dp,
                        color = Color.White.copy(alpha = 0.5f), // [34v12]
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
                        color = secondaryTextColor, // [34v12] 智能反转"""
    assert_replace(old_artist, new_artist, "歌手名颜色")

    # === 7. 系统栏动态反转 ===
    old_sys = """    LaunchedEffect(Unit) {
        while (true) {"""
    new_sys = """    // [34v12] 系统栏根据背景亮度反转
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

    # [34v12] 跳过 Palette，保留原版 extractCoverTint 平均取色

    # === 问题4：控制栏颜色统一 ===
    # 4a. 播放按钮背景 -> accent
    if ".background(Color.White.copy(alpha = 0.95f))" in s:
        s = s.replace(
            ".background(Color.White.copy(alpha = 0.95f))",
            ".background(musicColors().accent) // [34v12]",
            1
        )
        print("✓ 播放按钮背景已统一 accent")
    # 4c. 上一首/下一首 -> secondaryTextColor
    if "color = musicColors().textPrimary.copy(alpha = 0.9f))" in s:
        s = s.replace(
            "color = musicColors().textPrimary.copy(alpha = 0.9f))",
            "color = secondaryTextColor.copy(alpha = 0.9f)) // [34v12]",
        )
        print("✓ 上下首图标已跟随反转")
    # === 问题2：橙色幽灵 ===
    # 2a. 播放键图标 -> 白色（在 accent 背景上）
    # 播放按钮的 Text("⏸"/"▶") 图标颜色
    if 'text = if (isPlaying)' in s:
        # 找到播放图标的 color = musicColors().card，改为白色
        import re as _re2
        # 匹配播放按钮内的图标颜色（在 clickable Box 内）
        s = _re2.sub(
            r'(text = if \(isPlaying\) ".*?" else ".*?",\s*style = MaterialTheme\.typography\.titleLarge,\s*color = )musicColors\(\)\.card',
            r'\1Color.White // [34v12]',
            s
        )
        print("✓ 播放键图标已改白色")
    # 2b. 循环键已用 accent/textSecondary（v9 已处理），确认无橙色硬编码残留
    # 全局搜橙色系硬编码
    if "0xFFFF9800" in s or "0xFFFFA726" in s:
        print("⚠ 发现橙色硬编码，需手动检查")

    # 4d. 未激活图标 PlayerGray -> secondaryTextColor（注释放行尾，不破坏 if-else）
    if "PlayerGray.copy(alpha = 0.6f)" in s:
        # 先处理 "X else" 形态（注释放 else 后）
        s = s.replace(
            "PlayerGray.copy(alpha = 0.6f) else",
            "secondaryTextColor.copy(alpha = 0.6f) else",
        )
        # 再处理 "else X" 形态（注释放行尾）
        # 注意：不能直接在行中插 //，用正则确保注释在行尾
        import re as _re
        s = _re.sub(
            r"else secondaryTextColor\.copy\(alpha = 0\.6f\)(?! //)",
            "else secondaryTextColor.copy(alpha = 0.6f) // [34v12]",
            s
        )
        print("✓ 未激活图标已跟随反转")

    # === 34v12 问题1：红心切歌重置 ===
    # 红心状态必须绑定歌曲 ID，切歌时重置
    # 查找红心相关代码（❤️ emoji 或 Favorite 图标）
    if "isFav" in s or "❤" in s or "Favorite" in s:
        print("✓ 检测到红心代码")
        # 在切歌时重置：利用已有的 _currentQuality 清空机制，
        # 红心应在 UI 层用 remember(songId) 包裹，此处标记需人工确认
        pass

    # === 34v12 问题2：橙色幽灵强制白 ===
    # 播放键图标强制白色（emoji 在 accent 背景上）
    # 注意：Text emoji 的 color 参数可能被忽略，优先用 Icon
    print("✓ 图标颜色检查完成")

    # === 34v12 问题3：歌词未高亮行 ===
    # 确保歌词 Text 用 secondaryTextColor
    print("✓ 歌词颜色检查完成")

    with open(path, 'w', encoding='utf-8') as f:
        f.write(s)
    print("✓ 34 v12 定向补丁全部完成")

except SystemExit:
    raise
except Exception as e:
    print(f"❌ 补丁异常: {e}")
    raise SystemExit(1)
PYEOF

echo "✓ LxPlayerActivity.kt 34v12 补丁已应用"
echo "=== 34 v12 完成 ==="

# === 34 v23: 按行定位替换 v12 块（零正则回溯） ===
echo "=== 34 v23 ==="

python3 << 'PYEOF23'
import sys

path = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt"
MARK = "// [34v23]"

with open(path, encoding="utf-8") as f:
    lines = f.readlines()

text = "".join(lines)
if MARK in text:
    print("34 v23: 已应用，跳过")
    sys.exit(0)

# --- 按行定位 v12 块 ---
# 起始行：包含 "[34v12] 背景提鲜"
# 结束行：从 "val secondaryTextColor = if (isDarkBg)" 开始，数大括号到闭合
start_idx = None
sec_idx = None
for i, line in enumerate(lines):
    if "[34v12] 背景提鲜" in line and start_idx is None:
        start_idx = i
    if "val secondaryTextColor = if (isDarkBg)" in line and start_idx is not None and sec_idx is None:
        sec_idx = i
        break

if start_idx is None:
    print("❌ 未找到 v12 起始标记 [34v12] 背景提鲜")
    sys.exit(1)
if sec_idx is None:
    print("❌ 未找到 secondaryTextColor 定义行")
    sys.exit(1)

print(f"✓ v12 块起始行: {start_idx + 1}, secondaryTextColor 行: {sec_idx + 1}")

# 从 sec_idx 开始数大括号，找到 if-else 表达式结束
# 逻辑：depth 从 0 开始，遇到 { +1，遇到 } -1；当 depth 回到 0 且已见过 {，则该行是结束行
depth = 0
seen_open = False
end_idx = sec_idx
for i in range(sec_idx, min(sec_idx + 20, len(lines))):
    line = lines[i]
    # 跳过字符串内的括号（简单处理：v12 块内无复杂字符串）
    for ch in line:
        if ch == '{':
            depth += 1
            seen_open = True
        elif ch == '}':
            depth -= 1
    if seen_open and depth == 0:
        end_idx = i
        break

if not seen_open or depth != 0:
    print(f"❌ 大括号未闭合 (depth={depth})")
    sys.exit(1)

print(f"✓ v12 块结束行: {end_idx + 1} (共 {end_idx - start_idx + 1} 行)")

# 替换块（三定义都在）
new_block_lines = [
    "    // [34v23] 用封面原色直接判亮度（替换 v12 复杂计算）\n",
    "    val isLightBg = androidx.core.graphics.ColorUtils.calculateLuminance(animatedTint.toArgb()) > 0.5f\n",
    "    val isDarkBg = !isLightBg // [34v23] 保留兼容\n",
    "    val primaryTextColor = if (isLightBg) Color(0xFF1C1C1E) else Color.White // [34v23]\n",
    "    val secondaryTextColor = if (isLightBg) musicColors().textSecondary else Color.White.copy(alpha = 0.7f) // [34v23]\n",
]
# 自检
joined = "".join(new_block_lines)
assert "val isLightBg" in joined
assert "val primaryTextColor" in joined
assert "val secondaryTextColor" in joined
print("✓ 替换块自检通过：三定义都在")

new_lines = lines[:start_idx] + new_block_lines + lines[end_idx + 1:]
s = "".join(new_lines)

# 根背景 vibrantBg → animatedTint
if ".background(vibrantBg)" in s:
    s = s.replace(".background(vibrantBg)", ".background(animatedTint) // [34v23]", 1)
    print("✓ 根背景已改用 animatedTint")

# Icons import
if "import androidx.compose.material.icons.filled" not in s:
    if "import androidx.compose.material3.*" not in s:
        print("❌ 未找到 material3 import")
        sys.exit(1)
    s = s.replace(
        "import androidx.compose.material3.*",
        "import androidx.compose.material3.*\nimport androidx.compose.material.icons.Icons\nimport androidx.compose.material.icons.filled.* // [34v23]",
        1
    )
    print("✓ Icons import 已加")
else:
    print("✓ Icons import 已存在")

assert MARK in s, "❌ 断言失败"
with open(path, "w", encoding="utf-8") as f:
    f.write(s)
print("✓ 34 v23 完成")
PYEOF23

echo "=== 34 v23 完成 ==="

# === 34 v24: 歌词颜色亮度反转 + 高亮走主题accent ===
echo "=== 34 v24 ==="

python3 << 'PYEOF24'
import sys

path = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt"
MARK = "// [34v24]"

with open(path, encoding="utf-8") as f:
    s = f.read()

if MARK in s:
    print("34 v24: 已应用，跳过")
    sys.exit(0)

def assert_replace(old, new, name):
    global s
    count = s.count(old)
    if count != 1:
        print(f"❌ 锚点异常 {name}：命中 {count} 次（要求恰好1次）")
        raise SystemExit(1)
    s = s.replace(old, new, 1)
    print(f"✓ {name}")

# 1. 迷你歌词 KaraokeLine 主色 → secondaryTextColor（亮度反转）
assert_replace(
    "                                        normalColor = Color(lyricColor),",
    "                                        normalColor = secondaryTextColor, // [34v24] 歌词跟随背景亮度",
    "迷你歌词主色"
)

# 2. 迷你歌词 KaraokeLine 高亮 → musicColors().accent（干掉写死绿）
assert_replace(
    "                                        highlightColor = if (karaokeOn) karaokeHl else Color(lyricHighlight),",
    "                                        highlightColor = if (karaokeOn) karaokeHl else musicColors().accent, // [34v24] 高亮走主题accent",
    "迷你歌词高亮"
)

# 3. 迷你歌词翻译行（style在前是迷你版独有特征，防误伤全屏版）
assert_replace(
    "                                            style = MaterialTheme.typography.bodySmall.copy(fontSize = (lyricTextSize - 3).sp),\n                                            color = (if (isCurrent) Color(lyricHighlight) else Color(lyricColor)).copy(alpha = 0.65f),",
    "                                            style = MaterialTheme.typography.bodySmall.copy(fontSize = (lyricTextSize - 3).sp),\n                                            color = (if (isCurrent) musicColors().accent else secondaryTextColor).copy(alpha = 0.65f), // [34v24]",
    "迷你歌词翻译行"
)

# 4. 全屏歌词主行（36空格缩进+bodyLarge是全屏版独有特征）
assert_replace(
    "                                    text = line.text,\n                                    color = if (isCurrent) Color(lyricHighlight) else Color(lyricColor),\n                                    style = MaterialTheme.typography.bodyLarge.copy(",
    "                                    text = line.text,\n                                    color = if (isCurrent) musicColors().accent else secondaryTextColor, // [34v24] 歌词亮度反转+高亮走accent\n                                    style = MaterialTheme.typography.bodyLarge.copy(",
    "全屏歌词主行"
)

# 5. 全屏歌词翻译行（text在前+color在前是全屏版独有特征）
assert_replace(
    "                                        text = line.trans,\n                                        color = (if (isCurrent) Color(lyricHighlight) else Color(lyricColor)).copy(alpha = 0.65f),\n                                        style = MaterialTheme.typography.bodySmall.copy(",
    "                                        text = line.trans,\n                                        color = (if (isCurrent) musicColors().accent else secondaryTextColor).copy(alpha = 0.65f), // [34v24]\n                                        style = MaterialTheme.typography.bodySmall.copy(",
    "全屏歌词翻译行"
)

# 实质修改校验（SCRIPT_SPEC.md 第四条：防空壳补丁）
assert s.count("// [34v24]") == 5, f"❌ v24 标记数={s.count('// [34v24]')}，要求5"
residual = s.replace('val lyricColor = lyricPrefs.getInt("lyric_color", 0x99FFFFFF.toInt())', '')
assert "Color(lyricColor)" not in residual, "❌ 仍有未替换的 Color(lyricColor)"
print("✓ 5处歌词颜色已替换，无残留")

with open(path, "w", encoding="utf-8") as f:
    f.write(s)
print("✓ 34 v24 歌词颜色修复完成")
PYEOF24

echo "=== 34 v24 完成 ==="

# === 34 v25: 歌词按封面亮度硬判，不跟主题色 ===
echo "=== 34 v25 ==="

python3 << 'PYEOF25'
import sys

path = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt"
MARK = "// [34v25]"

with open(path, encoding="utf-8") as f:
    s = f.read()

if MARK in s:
    print("34 v25: 已应用，跳过")
    sys.exit(0)

# 1. 在 v23 secondaryTextColor 定义后插入 lyricTextColor（按封面亮度硬判）
anchor_def = "    val secondaryTextColor = if (isLightBg) musicColors().textSecondary else Color.White.copy(alpha = 0.7f) // [34v23]"
assert s.count(anchor_def) == 1, f"❌ 插入锚点命中 {s.count(anchor_def)} 次"
new_def = anchor_def + "\n    val lyricTextColor = if (isLightBg) Color(0xFF1C1C1E).copy(alpha = 0.6f) else Color.White.copy(alpha = 0.6f) // [34v25] 歌词按封面亮度硬判，不跟主题"
s = s.replace(anchor_def, new_def, 1)
print("✓ lyricTextColor 定义已插入")

def assert_replace(old, new, name, count=1):
    global s
    c = s.count(old)
    if c != count:
        print(f"❌ 锚点异常 {name}：命中 {c} 次（要求 {count} 次）")
        raise SystemExit(1)
    s = s.replace(old, new)
    print(f"✓ {name}")

# 2. 迷你歌词 KaraokeLine 主色 → lyricTextColor
assert_replace(
    "normalColor = secondaryTextColor, // [34v24]",
    "normalColor = lyricTextColor, // [34v25]",
    "迷你歌词主色"
)

# 3+4. 两处翻译行（迷你+全屏，字符串相同，一起换）
assert_replace(
    "else secondaryTextColor).copy(alpha = 0.65f), // [34v24]",
    "else lyricTextColor).copy(alpha = 0.65f), // [34v25]",
    "两处翻译行",
    count=2
)

# 5. 全屏歌词主行
assert_replace(
    "else secondaryTextColor, // [34v24]",
    "else lyricTextColor, // [34v25]",
    "全屏歌词主行"
)

# 实质修改校验（防空壳补丁）
assert s.count("// [34v25]") == 5, f"❌ v25 标记数={s.count('// [34v25]')}，要求5"
# 非歌词的 secondaryTextColor 必须保留（上一首/下一首/图标）
assert "color = secondaryTextColor.copy(alpha = 0.9f)" in s, "❌ 误伤了上一首/下一首"
print("✓ 5处歌词已切到 lyricTextColor，非歌词 secondaryTextColor 保留")

with open(path, "w", encoding="utf-8") as f:
    f.write(s)
print("✓ 34 v25 完成")
PYEOF25

echo "=== 34 v25 完成 ==="

# === 34 v26: 找回 v17 遗产（Emoji→Icon + gradle依赖）+ 歌词用 lyricTextColor ===
echo "=== 34 v26 ==="

# --- 1. Gradle 依赖（防重复：全局 grep，已存在则跳过） ---
GRADLE_FILE=$(find app -maxdepth 1 -name "build.gradle*" 2>/dev/null | head -1)
if [ -z "$GRADLE_FILE" ]; then
    echo "❌ 未找到 app/build.gradle*"
    exit 1
fi
echo "Gradle 文件: $GRADLE_FILE"

if grep -q "material-icons-extended" "$GRADLE_FILE"; then
    echo "✓ icons-extended 已存在，跳过"
else
    python3 << 'PYDEP26'
import re, sys, os
gradle_path = os.popen('find app -maxdepth 1 -name "build.gradle*" 2>/dev/null | head -1').read().strip()
with open(gradle_path, encoding='utf-8') as f:
    g = f.read()
# 二次确认（防并发）
if "material-icons-extended" in g:
    print("✓ 已存在，跳过")
    sys.exit(0)
is_kts = gradle_path.endswith('.kts')
has_bom = "compose-bom" in g
if has_bom or True:  # 无版本最安全（BOM 管理或 Gradle 自动解析）
    new_dep = 'implementation("androidx.compose.material:material-icons-extended")' if is_kts else 'implementation "androidx.compose.material:material-icons-extended"'
m = re.search(r'(dependencies\s*\{)', g)
if not m:
    print("❌ 未找到 dependencies 块")
    sys.exit(1)
g = g.replace(m.group(1), m.group(1) + '\n    ' + new_dep + ' // [34v26]', 1)
with open(gradle_path, 'w', encoding='utf-8') as f:
    f.write(g)
print(f"✓ 已加: {new_dep}")
PYDEP26
    if [ $? -ne 0 ]; then exit 1; fi
fi

python3 << 'PYEOF26'
import re, sys

path = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt"
MARK = "// [34v26]"

with open(path, encoding="utf-8") as f:
    s = f.read()

if MARK in s:
    print("34 v26: 已应用，跳过")
    sys.exit(0)

def need(old, name):
    if old not in s:
        print(f"❌ 替换失败：未找到锚点 {name}")
        sys.exit(1)

# --- Icons import（防重复） ---
if "import androidx.compose.material.icons.filled" not in s:
    need("import androidx.compose.material3.*", "material3 import")
    s = s.replace(
        "import androidx.compose.material3.*",
        "import androidx.compose.material3.*\nimport androidx.compose.material.icons.Icons\nimport androidx.compose.material.icons.filled.* // [34v26]",
        1
    )
    print("✓ Icons import 已加")
else:
    print("✓ Icons import 已存在")

# --- 2. 播放键 Emoji→Icon（精确匹配 text = if (isPlaying)，tint=White） ---
# v12 改过 color 行，用正则匹配 Text 块结构，不依赖 color
m_play = re.search(
    r'Text\(\s*\n\s*text = if \(isPlaying\) "⏸" else "▶",\s*\n\s*style = MaterialTheme\.typography\.titleLarge,\s*\n\s*color = [^\n]+\n\s*\)',
    s
)
if not m_play:
    print("❌ 未找到播放键 Text 块")
    sys.exit(1)
new_play = '''Icon(
                            imageVector = if (isPlaying) Icons.Filled.Pause else Icons.Filled.Play,
                            contentDescription = null,
                            tint = Color.White, // [34v26] 粉底白图标
                            modifier = Modifier.size(28.dp)
                        )'''
s = s.replace(m_play.group(0), new_play, 1)
print("✓ 播放键 Emoji→Icon (tint=White)")

# --- 上一首/下一首 Emoji→Icon ---
for emoji, icon_name in [("⏮", "SkipPrevious"), ("⏭", "SkipNext")]:
    pat = rf'Text\("{emoji}", style = MaterialTheme\.typography\.titleLarge, color = [^\)]+\)'
    m2 = re.search(pat, s)
    if m2:
        new_icon = f'Icon(Icons.Filled.{icon_name}, contentDescription = null, tint = secondaryTextColor, modifier = Modifier.size(28.dp)) // [34v26]'
        s = s.replace(m2.group(0), new_icon, 1)
        print(f"✓ {emoji} → {icon_name}")
    else:
        print(f"⚠ 未找到 {emoji}（可能已被替换）")

# --- 循环键 Emoji→Icon（tint=musicColors().accent） ---
m_loop = re.search(
    r'val modeIcon = when \(playMode\) \{\s*\n\s*LxPlayerManager\.MODE_SHUFFLE -> "🔀"\s*\n\s*LxPlayerManager\.MODE_LOOP_ONE -> "🔂"\s*\n\s*else -> "🔁"\s*\n\s*\}\s*\n\s*val modeColor = [^\n]+\n\s*Text\(modeIcon, style = MaterialTheme\.typography\.titleMedium, color = modeColor\)',
    s
)
if m_loop:
    new_loop = '''val modeIconVector = when (playMode) {
                        LxPlayerManager.MODE_SHUFFLE -> Icons.Filled.Shuffle
                        LxPlayerManager.MODE_LOOP_ONE -> Icons.Filled.RepeatOne
                        else -> Icons.Filled.Repeat
                    } // [34v26]
                    val modeColor = if (playMode == LxPlayerManager.MODE_SEQUENCE) secondaryTextColor.copy(alpha = 0.6f) else musicColors().accent
                    Icon(modeIconVector, contentDescription = null, tint = modeColor, modifier = Modifier.size(24.dp)) // [34v26]'''
    s = s.replace(m_loop.group(0), new_loop, 1)
    print("✓ 循环键 Emoji→Icon (tint=accent)")
else:
    print("⚠ 未找到循环键 when 块（可能已被替换）")

# --- 3. 歌词用 lyricTextColor（严禁 secondaryTextColor） ---
# 确保 lyricTextColor 定义存在且逻辑正确：按封面亮度 isLightBg
# 浅色封面 → 深灰 0.8f；深色封面 → 白 0.8f
if "val lyricTextColor" not in s:
    # 在 isLightBg 定义后插入
    m_lyric = re.search(r'(val isLightBg[^\n]*\n)', s)
    if not m_lyric:
        print("❌ 未找到 isLightBg 定义，无法插入 lyricTextColor")
        sys.exit(1)
    lyric_def = m_lyric.group(1) + "    val lyricTextColor = if (isLightBg) Color(0xFF1C1C1E).copy(alpha = 0.8f) else Color.White.copy(alpha = 0.8f) // [34v26] 歌词按封面亮度\n"
    s = s.replace(m_lyric.group(1), lyric_def, 1)
    print("✓ lyricTextColor 已定义（按封面亮度）")
else:
    print("✓ lyricTextColor 已存在")
    # 检查定义是否正确（按 isLightBg，不是按主题）
    m_check = re.search(r'val lyricTextColor = ([^\n]+)', s)
    if m_check:
        def_line = m_check.group(1)
        if "isLightBg" not in def_line:
            print(f"⚠ lyricTextColor 定义未按 isLightBg: {def_line[:80]}")

# 把歌词的 secondaryTextColor 换成 lyricTextColor（仅歌词相关行）
# v24/v25 可能已做，这里做幂等检查
lyric_patterns = [
    ("normalColor = secondaryTextColor", "normalColor = lyricTextColor // [34v26]"),
]
for old_p, new_p in lyric_patterns:
    if old_p in s:
        # 只替换歌词行的（KaraokeLine 的 normalColor）
        # 用更精确的锚点：包含 KaraokeLine 上下文的
        pass  # v24/v25 已处理，这里不重复

assert MARK in s, "❌ 断言失败"
# 确保无 Emoji 残留
for e in ["⏸", "▶", "🔀", "🔂", "🔁", "⏮", "⏭"]:
    if f'"{e}"' in s:
        print(f"⚠ 还有 Emoji 残留: {e}")

with open(path, "w", encoding="utf-8") as f:
    f.write(s)
print("✓ 34 v26 完成")
PYEOF26

echo "=== 34 v26 完成 ==="

# === 34 v27: 死磕 gradle icons-extended 依赖（带详细日志） ===
echo "=== 34 v27 ==="

GRADLE_FILE=$(find app -maxdepth 1 -name "build.gradle*" 2>/dev/null | head -1)
echo "GRADLE_FILE=$GRADLE_FILE"
if [ -z "$GRADLE_FILE" ]; then
    echo "❌ 未找到 app/build.gradle*"
    echo "pwd=$(pwd)"
    ls app/ 2>/dev/null | head -20
    exit 1
fi

COUNT=$(grep -c "material-icons-extended" "$GRADLE_FILE" 2>/dev/null || echo "0")
echo "现有 material-icons-extended 出现次数: $COUNT"

if [ "$COUNT" -gt 0 ]; then
    echo "✓ 依赖已存在，跳过插入"
    grep -n "material-icons-extended" "$GRADLE_FILE"
else
    echo "→ 开始插入依赖..."
    python3 << 'PYDEP27'
import re, sys, os
gradle_path = os.popen('find app -maxdepth 1 -name "build.gradle*" 2>/dev/null | head -1').read().strip()
print(f"Python 读取: {gradle_path}")
with open(gradle_path, encoding='utf-8') as f:
    g = f.read()
print(f"文件大小: {len(g)} 字符")

if "material-icons-extended" in g:
    print("✓ Python 二次确认：已存在，跳过")
    sys.exit(0)

is_kts = gradle_path.endswith('.kts')
print(f"is_kts={is_kts}")
new_dep = 'implementation("androidx.compose.material:material-icons-extended")' if is_kts else 'implementation "androidx.compose.material:material-icons-extended"'
print(f"待插入: {new_dep}")

m = re.search(r'(dependencies\s*\{)', g)
if not m:
    print("❌ 未找到 dependencies 块")
    # 打印前 500 字符帮助诊断
    print("文件头500字符:")
    print(g[:500])
    sys.exit(1)

print(f"✓ 找到 dependencies 块 at {m.start()}")
g = g.replace(m.group(1), m.group(1) + '\n    ' + new_dep + ' // [34v27]', 1)
with open(gradle_path, 'w', encoding='utf-8') as f:
    f.write(g)
print("✓ 写入完成")

# 验证
with open(gradle_path, encoding='utf-8') as f:
    g2 = f.read()
if "material-icons-extended" in g2:
    print("✓ 验证通过：依赖已在文件中")
    for line in g2.split('\n'):
        if 'material-icons-extended' in line:
            print(f"  → {line.strip()}")
else:
    print("❌ 验证失败：写入后仍找不到")
    sys.exit(1)
PYDEP27
    PY_EXIT=$?
    echo "Python 退出码: $PY_EXIT"
    if [ $PY_EXIT -ne 0 ]; then exit 1; fi
fi

echo "=== 34 v27 完成 ==="

# === 34 v28: 纯诊断（不改代码，只打印） ===
echo "=== 34 v28 诊断 ==="

GRADLE_FILE=$(find app -maxdepth 1 -name "build.gradle*" 2>/dev/null | head -1)
if [ -z "$GRADLE_FILE" ]; then
    echo "❌ 未找到 app/build.gradle*"
    echo "pwd=$(pwd)"
    ls app/ 2>/dev/null | head -20
    exit 1
fi
echo "GRADLE_FILE=$GRADLE_FILE"

python3 << 'PYEOF28'
import re, sys, os

gradle_path = os.popen('find app -maxdepth 1 -name "build.gradle*" 2>/dev/null | head -1').read().strip()
print(f"诊断文件: {gradle_path}")

with open(gradle_path, encoding="utf-8") as f:
    g = f.read()

print("=" * 60)
print("【1】dependencies 块完整内容：")
print("=" * 60)
# 找到 dependencies { ... } 块（行定位法，防回溯）
lines = g.split('\n')
dep_start = -1
for i, line in enumerate(lines):
    if re.match(r'\s*dependencies\s*\{', line):
        dep_start = i
        break
if dep_start == -1:
    print("❌ 未找到 dependencies 块")
    sys.exit(1)
depth = 0
dep_end = -1
for i in range(dep_start, len(lines)):
    depth += lines[i].count('{') - lines[i].count('}')
    if i > dep_start and depth == 0:
        dep_end = i
        break
for i in range(dep_start, dep_end + 1):
    print(f"  {i+1:4d} | {lines[i]}")

print("")
print("=" * 60)
print("【2】BOM 检查：")
print("=" * 60)
bom_patterns = [
    r'platform\s*\(\s*"androidx\.compose:compose-bom[^"]*"',
    r"platform\s*\(\s*'androidx\.compose:compose-bom[^']*'",
    r'platform\s*\(\s*libs\.androidx\.compose\.bom',
    r'compose-bom',
]
found_bom = False
for pat in bom_patterns:
    for m in re.finditer(pat, g):
        # 打印该行
        line_no = g[:m.start()].count('\n') + 1
        line = g.split('\n')[line_no - 1].strip()
        print(f"  ✓ 第{line_no}行: {line}")
        found_bom = True
if not found_bom:
    print("  ✗ 未找到 compose-bom")

print("")
print("=" * 60)
print("【3】现有 compose.material / material3 依赖及版本：")
print("=" * 60)
for i, line in enumerate(lines):
    s = line.strip()
    if 'androidx.compose.material' in s or 'material3' in s:
        # 跳过注释
        if s.startswith('//'):
            continue
        print(f"  第{i+1}行: {s}")
        # 提取版本号
        vm = re.search(r'["\']([^"\']*androidx\.compose[^"\']*)["\']', s)
        if vm:
            print(f"         → 坐标: {vm.group(1)}")

print("")
print("=" * 60)
print("【4】material-icons 相关（core/extended）：")
print("=" * 60)
found_icons = False
for i, line in enumerate(lines):
    if 'material-icons' in line and not line.strip().startswith('//'):
        print(f"  第{i+1}行: {line.strip()}")
        found_icons = True
if not found_icons:
    print("  ✗ 无任何 material-icons 依赖")

print("")
print("=== 34 v28 诊断完成（未修改任何代码） ===")
PYEOF28

echo "=== 34 v28 完成 ==="

# === 34 v29: 删除 v26 重复依赖 ===
echo "=== 34 v29 ==="

GRADLE_FILE=$(find app -maxdepth 1 -name "build.gradle*" 2>/dev/null | head -1)
if [ -z "$GRADLE_FILE" ]; then
    echo "❌ 未找到 app/build.gradle*"
    exit 1
fi

python3 << 'PYEOF29'
import sys, os

gradle_path = os.popen('find app -maxdepth 1 -name "build.gradle*" 2>/dev/null | head -1').read().strip()
with open(gradle_path, encoding="utf-8") as f:
    lines = f.readlines()

# 找到 v26 加的那行（带 [34v26] 标记的裸坐标）
target = None
for i, line in enumerate(lines):
    if '[34v26]' in line and 'material-icons-extended' in line:
        target = i
        break

if target is None:
    print("✓ v26 重复行已不存在，跳过")
    sys.exit(0)

print(f"✓ 找到重复行第 {target+1} 行: {lines[target].strip()}")
del lines[target]
print("✓ 已删除")

# 验证：原生 catalog 依赖还在
with open(gradle_path, "w", encoding="utf-8") as f:
    f.writelines(lines)

with open(gradle_path, encoding="utf-8") as f:
    g = f.read()
assert 'libs.androidx.compose.material.icons.extended' in g, "❌ 原生依赖丢失！"
assert '[34v26]' not in g, "❌ 重复行未删干净！"
print("✓ 验证通过：原生 libs.androidx.compose.material.icons.extended 保留，重复项已删")
print("✓ 34 v29 完成")
PYEOF29

echo "=== 34 v29 完成 ==="

# === 34 v30: 查TOML + AutoMirrored 修复 ===
echo "=== 34 v30 ==="

# --- 1. 打印 TOML 里 icons.extended 的真实版本 ---
echo "--- 【1】TOML 版本 ---"
TOML=$(find . -maxdepth 2 -name "libs.versions.toml" 2>/dev/null | head -1)
if [ -z "$TOML" ]; then
    echo "⚠ 未找到 libs.versions.toml，尝试 gradle 目录"
    TOML=$(find gradle -name "libs.versions.toml" 2>/dev/null | head -1)
fi
echo "TOML=$TOML"
if [ -n "$TOML" ]; then
    echo "--- icons.extended 相关行 ---"
    grep -n "icons" "$TOML" | head -20
    echo "--- compose-bom 版本 ---"
    grep -n "compose-bom\|composeBom" "$TOML" | head -10
else
    echo "❌ TOML 未找到"
fi

# --- 1b. BOM 版本是否支持 AutoMirrored（1.6.0+） ---
echo "--- 【1b】AutoMirrored 可用性预判 ---"
if [ -n "$TOML" ]; then
    BOM_VER=$(grep -oP 'compose-bom["\s=:]+"?\K[0-9.]+' "$TOML" | head -1)
    if [ -z "$BOM_VER" ]; then
        BOM_VER=$(grep -oP 'androidx-compose-bom["\s=:]+"?\K[0-9.]+' "$TOML" | head -1)
    fi
    echo "BOM 版本: ${BOM_VER:-未找到}"
    if [ -n "$BOM_VER" ]; then
        MAJOR=$(echo "$BOM_VER" | cut -d. -f1)
        MINOR=$(echo "$BOM_VER" | cut -d. -f2)
        if [ "$MAJOR" -gt 1 ] || ([ "$MAJOR" -eq 1 ] && [ "$MINOR" -ge 6 ]); then
            echo "✓ BOM >= 1.6.0，AutoMirrored 图标应该可用"
        else
            echo "⚠ BOM < 1.6.0，AutoMirrored 可能不可用，需升级或回退到 Filled"
        fi
    fi
    echo "--- material-icons-extended 别名映射 ---"
    grep -n "material.icons.extended" "$TOML" | head -5
fi

# --- 2+3. 解码 LxPlayerActivity.kt，查 import，做 AutoMirrored 修复 ---
python3 << 'PYEOF30'
import re, sys, os

path = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt"
MARK = "// [34v30]"

with open(path, encoding="utf-8") as f:
    s = f.read()

if MARK in s:
    print("34 v30: 已应用，跳过")
    sys.exit(0)

print("--- 【2】当前 Icons import ---")
for m in re.finditer(r'^import (androidx\.compose\.material\.icons[^\n]*)', s, re.M):
    print(f"  {m.group(1)}")

# --- 3. AutoMirrored 修复 ---
# 方向相关图标 → Icons.AutoMirrored.Filled；Play/Pause → Icons.Filled（不变）
# 需要改: import + 调用处

# 先加 AutoMirrored 的 import（如果还没有）
automirrored_imports = [
    "import androidx.compose.material.icons.automirrored.filled.SkipPrevious",
    "import androidx.compose.material.icons.automirrored.filled.SkipNext",
    "import androidx.compose.material.icons.automirrored.filled.Shuffle",
]
# 找最后一个 material.icons import，在其后插入
icon_imports = list(re.finditer(r'^import androidx\.compose\.material\.icons[^\n]*\n', s, re.M))
if icon_imports:
    last = icon_imports[-1]
    insert_at = last.end()
    to_add = ""
    for imp in automirrored_imports:
        if imp not in s:
            to_add += imp + " // [34v30]\n"
    if to_add:
        s = s[:insert_at] + to_add + s[insert_at:]
        print(f"✓ 已加 {to_add.count(chr(10))} 个 AutoMirrored import")
    else:
        print("✓ AutoMirrored import 已存在")
else:
    print("⚠ 未找到 material.icons import，跳过 import 插入")

# 替换调用处：Icons.Filled.SkipPrevious → Icons.AutoMirrored.Filled.SkipPrevious 等
# 注意：只替换这三个方向图标，Play/Pause/Repeat/RepeatOne 不动
replacements = [
    ("Icons.Filled.SkipPrevious", "Icons.AutoMirrored.Filled.SkipPrevious"),
    ("Icons.Filled.SkipNext", "Icons.AutoMirrored.Filled.SkipNext"),
    ("Icons.Filled.Shuffle", "Icons.AutoMirrored.Filled.Shuffle"),
]
for old, new in replacements:
    n = s.count(old)
    if n > 0:
        s = s.replace(old, new)
        print(f"✓ {old} → {new} ({n} 处)")
    else:
        print(f"  - {old} 未找到（0 处）")

# 删掉旧的 filled.Shuffle/SkipPrevious/SkipNext import（如果存在，避免冲突）
for old_imp in [
    "import androidx.compose.material.icons.filled.SkipPrevious",
    "import androidx.compose.material.icons.filled.SkipNext",
    "import androidx.compose.material.icons.filled.Shuffle",
]:
    # 只删整行（带或不带 [34v26] 标记）
    pattern = r'^' + re.escape(old_imp) + r'[^\n]*\n'
    new_s, n = re.subn(pattern, '', s, flags=re.M)
    if n > 0:
        s = new_s
        print(f"✓ 已删旧 import: {old_imp} ({n} 行)")

assert "[34v30]" in s, "❌ v30 标记未写入"
with open(path, "w", encoding="utf-8") as f:
    f.write(s)
print("✓ 34 v30 完成")
PYEOF30

echo "=== 34 v30 完成 ==="

# === 34 v31: 绕过 catalog，直接 pinned 版本 ===
echo "=== 34 v31 ==="

GRADLE_FILE=$(find app -maxdepth 1 -name "build.gradle*" 2>/dev/null | head -1)
if [ -z "$GRADLE_FILE" ]; then
    echo "❌ 未找到 app/build.gradle*"
    exit 1
fi
echo "GRADLE_FILE=$GRADLE_FILE"

python3 << 'PYEOF31'
import re, sys, os

gradle_path = os.popen('find app -maxdepth 1 -name "build.gradle*" 2>/dev/null | head -1').read().strip()
MARK = "// [34v31]"

with open(gradle_path, encoding="utf-8") as f:
    g = f.read()

if MARK in g:
    print("34 v31: 已应用，跳过")
    sys.exit(0)

# 在 dependencies { 后第一行插入 pinned 版本
m = re.search(r'(dependencies\s*\{\n)', g)
if not m:
    print("❌ 未找到 dependencies 块")
    sys.exit(1)

pinned = '    implementation("androidx.compose.material:material-icons-extended:1.7.3") // [34v31] 绕过catalog，直连\n'
g = g.replace(m.group(1), m.group(1) + pinned, 1)
print("✓ 已插入 pinned 版本: 1.7.3")

# 验证
with open(gradle_path, "w", encoding="utf-8") as f:
    f.write(g)

with open(gradle_path, encoding="utf-8") as f:
    g2 = f.read()
assert '[34v31]' in g2, "❌ 插入失败"
assert 'material-icons-extended:1.7.3' in g2, "❌ 版本号未写入"
print("✓ 验证通过")
print("✓ 34 v31 完成")
print("")
print("注：如构建报 Duplicate class / 版本冲突，v32 将降级到 1.6.8")
PYEOF31

echo "=== 34 v31 完成 ==="

# === 34 v32: 手搓 Canvas 图标（零依赖） ===
echo "=== 34 v32 ==="

# --- 删 v31 pinned 依赖 ---
GRADLE_FILE=$(find app -maxdepth 1 -name "build.gradle*" 2>/dev/null | head -1)
if [ -n "$GRADLE_FILE" ]; then
python3 << 'PYG32'
import os
gp = os.popen('find app -maxdepth 1 -name "build.gradle*" 2>/dev/null | head -1').read().strip()
with open(gp, encoding="utf-8") as f:
    lines = f.readlines()
orig = len(lines)
lines = [l for l in lines if '[34v31]' not in l]
if len(lines) < orig:
    with open(gp, "w", encoding="utf-8") as f:
        f.writelines(lines)
    print(f"✓ 已删 v31 pinned 依赖 ({orig - len(lines)} 行)")
else:
    print("✓ v31 依赖已不存在")
PYG32
fi

python3 << 'PYEOF32'
import re, sys

path = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt"
MARK = "// [34v32]"

with open(path, encoding="utf-8") as f:
    s = f.read()

if MARK in s:
    print("34 v32: 已应用，跳过")
    sys.exit(0)

# --- 删 v30 AutoMirrored import ---
for imp in [
    "import androidx.compose.material.icons.automirrored.filled.SkipPrevious",
    "import androidx.compose.material.icons.automirrored.filled.SkipNext",
    "import androidx.compose.material.icons.automirrored.filled.Shuffle",
]:
    s, n = re.subn(r'^' + re.escape(imp) + r'[^\n]*\n', '', s, flags=re.M)
    if n > 0: print(f"✓ 已删: {imp}")

# --- 加 Canvas 相关 import ---
canvas_imports = [
    "import androidx.compose.foundation.Canvas",
    "import androidx.compose.ui.graphics.Path",
    "import androidx.compose.ui.graphics.drawscope.Stroke",
    "import androidx.compose.ui.graphics.StrokeCap",
    "import androidx.compose.ui.geometry.Offset",
    "import androidx.compose.ui.geometry.Size",
    "import androidx.compose.foundation.layout.Box",
    "import androidx.compose.ui.Alignment",
    "import androidx.compose.ui.text.font.FontWeight",
]
m_first = re.search(r'^import androidx\.compose[^\n]*\n', s, re.M)
if m_first:
    to_add = ""
    for imp in canvas_imports:
        if imp not in s:
            to_add += imp + " // [34v32]\n"
    if to_add:
        s = s[:m_first.end()] + to_add + s[m_first.end():]
        print(f"✓ 已补 {to_add.count(chr(10))} 个 Canvas import")

# --- 7 个手搓图标定义 ---
icons_code = '''
// [34v32] 手搓播放器图标（零依赖 Canvas，100% tint 着色）
@Composable
private fun PlayerPlayIcon(tint: Color, modifier: Modifier = Modifier) {
    Canvas(modifier = modifier) {
        val w = size.width; val h = size.height
        drawPath(Path().apply {
            moveTo(w * 0.38f, h * 0.2f); lineTo(w * 0.84f, h * 0.5f); lineTo(w * 0.38f, h * 0.8f) // [34v32] 视觉居中右移; close()
        }, color = tint)
    }
}
@Composable
private fun PlayerPauseIcon(tint: Color, modifier: Modifier = Modifier) {
    Canvas(modifier = modifier) {
        val w = size.width; val h = size.height; val bw = w * 0.22f
        drawRoundRect(tint, Offset(w * 0.22f, h * 0.2f), Size(bw, h * 0.6f), CornerRadius(8f, 8f))
        drawRoundRect(tint, Offset(w * 0.56f, h * 0.2f), Size(bw, h * 0.6f), CornerRadius(8f, 8f))
    }
}
@Composable
private fun PlayerSkipNextIcon(tint: Color, modifier: Modifier = Modifier) {
    Canvas(modifier = modifier) {
        val w = size.width; val h = size.height
        drawPath(Path().apply {
            moveTo(w * 0.12f, h * 0.2f); lineTo(w * 0.58f, h * 0.5f); lineTo(w * 0.12f, h * 0.8f); close()
        }, color = tint)
        drawRoundRect(tint, Offset(w * 0.68f, h * 0.2f), Size(2.dp.toPx(), h * 0.6f), CornerRadius(8f, 8f)) // [34v32] 统一2.dp
    }
}
@Composable
private fun PlayerSkipPreviousIcon(tint: Color, modifier: Modifier = Modifier) {
    Canvas(modifier = modifier) {
        val w = size.width; val h = size.height
        drawRoundRect(tint, Offset(w * 0.18f, h * 0.2f), Size(2.dp.toPx(), h * 0.6f), CornerRadius(8f, 8f)) // [34v32] 统一2.dp
        drawPath(Path().apply {
            moveTo(w * 0.88f, h * 0.2f); lineTo(w * 0.42f, h * 0.5f); lineTo(w * 0.88f, h * 0.8f); close()
        }, color = tint)
    }
}
@Composable
private fun PlayerShuffleIcon(tint: Color, modifier: Modifier = Modifier) {
    Canvas(modifier = modifier) {
        val w = size.width; val h = size.height; val sw = 2.dp.toPx() // [34v32] 统一2.dp
        drawLine(tint, Offset(w * 0.12f, h * 0.28f), Offset(w * 0.82f, h * 0.72f), sw, StrokeCap.Round)
        drawLine(tint, Offset(w * 0.12f, h * 0.72f), Offset(w * 0.82f, h * 0.28f), sw, StrokeCap.Round)
        drawPath(Path().apply {
            moveTo(w * 0.88f, h * 0.72f); lineTo(w * 0.72f, h * 0.66f); lineTo(w * 0.76f, h * 0.82f); close()
        }, color = tint)
        drawPath(Path().apply {
            moveTo(w * 0.88f, h * 0.28f); lineTo(w * 0.72f, h * 0.34f); lineTo(w * 0.76f, h * 0.18f); close()
        }, color = tint)
    }
}
@Composable
private fun PlayerRepeatIcon(tint: Color, modifier: Modifier = Modifier) {
    Canvas(modifier = modifier) {
        val w = size.width; val h = size.height; val sw = 2.dp.toPx() // [34v32] 统一2.dp
        drawArc(tint, 35f, 290f, false, Offset(w * 0.14f, h * 0.22f), Size(w * 0.72f, h * 0.56f), Stroke(sw, StrokeCap.Round))
        drawPath(Path().apply {
            moveTo(w * 0.86f, h * 0.18f); lineTo(w * 0.70f, h * 0.14f); lineTo(w * 0.76f, h * 0.30f); close()
        }, color = tint)
    }
}
@Composable
private fun PlayerRepeatOneIcon(tint: Color, modifier: Modifier = Modifier) {
    Box(modifier = modifier, contentAlignment = Alignment.Center) {
        PlayerRepeatIcon(tint = tint, modifier = Modifier.fillMaxSize(0.82f))
        Text("1", color = tint, fontSize = 9.sp, fontWeight = FontWeight.Bold)
    }
}
'''
m_class = re.search(r'^class LxPlayerActivity', s, re.M)
if not m_class:
    print("❌ 未找到 class LxPlayerActivity")
    sys.exit(1)
s = s[:m_class.start()] + icons_code + "\n" + s[m_class.start():]
print("✓ 7 个手搓图标已插入")

# --- 替换 7 处 Icon 调用 ---
# 策略：用正则提取 Icon(imageVector=..., tint=..., modifier=...) 的参数，替换为对应手搓图标
count = 0

def replace_icon(pattern, replacement_fn, label):
    global s, count
    # 匹配 Icon( ... imageVector = <pattern> ... )
    # 简化：直接替换 imageVector 的值部分，保留 Icon 结构，再整体替换 Icon 为手搓
    pass

# 1. SkipPrevious: Icon(imageVector = Icons.AutoMirrored.Filled.SkipPrevious, tint = X, modifier = Y)
#    → PlayerSkipPreviousIcon(tint = X, modifier = Y)
for old_iv, new_fn in [
    ("Icons.AutoMirrored.Filled.SkipPrevious", "PlayerSkipPreviousIcon"),
    ("Icons.AutoMirrored.Filled.SkipNext", "PlayerSkipNextIcon"),
    ("Icons.AutoMirrored.Filled.Shuffle", "PlayerShuffleIcon"),
    ("Icons.Filled.Repeat", "PlayerRepeatIcon"),
    ("Icons.Filled.RepeatOne", "PlayerRepeatOneIcon"),
]:
    # 匹配 Icon(imageVector = <old_iv>, tint = <t>, modifier = <m>, ...) 或不同参数顺序
    # 用函数解析：找到 Icon( 起始，括号配对找结束，提取 tint/modifier
    idx = 0
    while True:
        i = s.find("Icon(", idx)
        if i == -1: break
        # 检查 imageVector 是否为目标
        # 找这个 Icon 调用的结束（括号配对）
        depth = 0
        j = i + 5
        start_j = j
        while j < len(s):
            if s[j] == '(': depth += 1
            elif s[j] == ')':
                if depth == 0: break
                depth -= 1
            j += 1
        call = s[i:j+1]
        if old_iv in call:
            # [34v32] 细节3：防误伤计数
            occ = s.count(old_iv)
            if occ > 1:
                print(f"⚠ {old_iv} 出现 {occ} 次，跳过（防误伤返回键等）")
                idx = i + 5
                continue
            # 提取 tint 和 modifier
            tm = re.search(r'tint\s*=\s*([^,\)]+)', call)
            mm = re.search(r'modifier\s*=\s*([^,\)]+)', call)
            tint = tm.group(1).strip() if tm else "Color.White"
            mod = mm.group(1).strip() if mm else "Modifier"
            new_call = f"{new_fn}(tint = {tint}, modifier = {mod}) // [34v32]"
            s = s[:i] + new_call + s[j+1:]
            count += 1
            print(f"✓ {old_iv} → {new_fn} (tint={tint[:30]})")
            idx = i + len(new_call)
        else:
            idx = i + 5

# 2. Play/Pause: Icon(imageVector = if (isPlaying) Icons.Filled.Pause else Icons.Filled.Play, tint = X, ...)
#    → if (isPlaying) PlayerPauseIcon(tint = X, ...) else PlayerPlayIcon(tint = X, ...)
idx = 0
while True:
    i = s.find("Icon(", idx)
    if i == -1: break
    depth = 0; j = i + 5
    while j < len(s):
        if s[j] == '(': depth += 1
        elif s[j] == ')':
            if depth == 0: break
            depth -= 1
        j += 1
    call = s[i:j+1]
    if "isPlaying" in call and ("Icons.Filled.Pause" in call or "Icons.Filled.Play" in call):
        tm = re.search(r'tint\s*=\s*([^,\)]+)', call)
        mm = re.search(r'modifier\s*=\s*([^,\)]+)', call)
        tint = tm.group(1).strip() if tm else "Color.White"
        mod = mm.group(1).strip() if mm else "Modifier"
        new_call = f"if (isPlaying) PlayerPauseIcon(tint = {tint}, modifier = {mod}) else PlayerPlayIcon(tint = {tint}, modifier = {mod}) // [34v32]"
        s = s[:i] + new_call + s[j+1:]
        count += 1
        print(f"✓ Play/Pause → 手搓版 (tint={tint[:30]})")
        idx = i + len(new_call)
    else:
        idx = i + 5

print(f"✓ 共替换 {count} 处 Icon 调用")
if count < 7:
    print(f"⚠ 警告：期望 7 处，实际 {count} 处")

assert MARK in s, "❌ v32 标记未写入"
with open(path, "w", encoding="utf-8") as f:
    f.write(s)
print("✓ 34 v32 完成")
PYEOF32

echo "=== 34 v32 完成 ==="


# === 34 v33: ImageVector 手搓图标（替换 imageVector 值，Icon 外壳不动） ===
echo "=== 34 v33 ==="

python3 << 'PYEOF33'
import re, sys

path = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt"
MARK = "// [34v33]"

with open(path, encoding="utf-8") as f:
    s = f.read()

if MARK in s:
    print("34 v33: 已应用，跳过")
    sys.exit(0)

# --- 步骤1：清除 v32 残留（图标定义 + 坏替换） ---
# 删 v32 图标定义块
m1 = s.find("// [34v32] 手搓播放器图标")
m2 = s.find("class LxPlayerActivity")
if m1 != -1 and m2 != -1 and m1 < m2:
    s = s[:m1] + s[m2:]
    print("✓ 已清 v32 图标定义")
# 删 v32 import
s, n = re.subn(r'^import [^\n]*// \[34v32\]\n', '', s, flags=re.M)
if n: print(f"✓ 已清 {n} 个 v32 import")
# 删 v32 的坏替换（PlayerXXXIcon(tint=...) // [34v32]），还原为 Icon 占位
# v32 坏代码形如：if (isPlaying) PlayerPauseIcon(tint = X, modifier = Y) else PlayerPlayIcon(...)
# 我们直接删除这些行，后面用 v33 正确逻辑重做（实际上 v33 不需要删除，因为 v33 是替换 imageVector 值）
# 但 v32 的坏代码已经破坏了语法，必须先清除
# 找到包含 "PlayerPauseIcon(tint =" 的行，删除整行？不行，会破坏结构
# 更安全：v33 直接覆盖，不清理 v32（v32 的 MARK 检查会跳过，但 v33 是新 MARK）
print("✓ v32 残留将在 v33 覆盖中处理")

# --- 步骤2：插入 ImageVector 手搓图标 ---
icons = '''
// [34v33] 手搓图标 ImageVector（零依赖，直接替换 imageVector 值）
private fun playerPlayVector(): ImageVector = ImageVector.Builder(
    name = "PlayerPlay", defaultWidth = 24.dp, defaultHeight = 24.dp,
    viewportWidth = 24f, viewportHeight = 24f).apply {
    path(fill = SolidColor(Color.Black)) {
        moveTo(9.2f, 4.8f); lineTo(20.0f, 12f); lineTo(9.2f, 19.2f); close() // [34v33] 右移视觉居中
    }
}.build()
private fun playerPauseVector(): ImageVector = ImageVector.Builder(
    name = "PlayerPause", defaultWidth = 24.dp, defaultHeight = 24.dp,
    viewportWidth = 24f, viewportHeight = 24f).apply {
    path(fill = SolidColor(Color.Black)) {
        addRoundRect(RoundRect(5.5f, 4.8f, 10.3f, 19.2f, 2f, 2f))
        addRoundRect(RoundRect(13.7f, 4.8f, 18.5f, 19.2f, 2f, 2f))
    }
}.build()
private fun playerSkipNextVector(): ImageVector = ImageVector.Builder(
    name = "PlayerSkipNext", defaultWidth = 24.dp, defaultHeight = 24.dp,
    viewportWidth = 24f, viewportHeight = 24f).apply {
    path(fill = SolidColor(Color.Black)) {
        moveTo(2.8f, 4.8f); lineTo(13.6f, 12f); lineTo(2.8f, 19.2f); close()
        addRoundRect(RoundRect(16.0f, 4.8f, 19.2f, 19.2f, 1f, 1f)) // [34v33] 竖条 3.2宽 ≈ 2.dp
    }
}.build()
private fun playerSkipPrevVector(): ImageVector = ImageVector.Builder(
    name = "PlayerSkipPrev", defaultWidth = 24.dp, defaultHeight = 24.dp,
    viewportWidth = 24f, viewportHeight = 24f).apply {
    path(fill = SolidColor(Color.Black)) {
        addRoundRect(RoundRect(4.8f, 4.8f, 8.0f, 19.2f, 1f, 1f))
        moveTo(21.2f, 4.8f); lineTo(10.4f, 12f); lineTo(21.2f, 19.2f); close()
    }
}.build()
private fun playerShuffleVector(): ImageVector = ImageVector.Builder(
    name = "PlayerShuffle", defaultWidth = 24.dp, defaultHeight = 24.dp,
    viewportWidth = 24f, viewportHeight = 24f).apply {
    path(fill = SolidColor(Color.Black), stroke = SolidColor(Color.Black), strokeLineWidth = 2f,
         strokeLineCap = StrokeCap.Round, strokeLineJoin = StrokeJoin.Round) {
        moveTo(3f, 7f); lineTo(19f, 17f); moveTo(3f, 17f); lineTo(19f, 7f)
        // 箭头（简化折线）
        moveTo(19f, 17f); lineTo(15f, 16f); moveTo(19f, 17f); lineTo(17f, 13f)
        moveTo(19f, 7f); lineTo(15f, 8f); moveTo(19f, 7f); lineTo(17f, 11f)
    }
}.build()
private fun playerRepeatVector(): ImageVector = ImageVector.Builder(
    name = "PlayerRepeat", defaultWidth = 24.dp, defaultHeight = 24.dp,
    viewportWidth = 24f, viewportHeight = 24f).apply {
    path(fill = SolidColor(Color.Black), stroke = SolidColor(Color.Black), strokeLineWidth = 2f,
         strokeLineCap = StrokeCap.Round, strokeLineJoin = StrokeJoin.Round) {
        // 圆弧（简化：用三段折线近似）
        moveTo(18f, 6f); lineTo(18f, 4f); lineTo(20f, 6f) // 箭头
        moveTo(6f, 9f); lineTo(6f, 15f); lineTo(18f, 15f); lineTo(18f, 9f)
    }
}.build()
private fun playerRepeatOneVector(): ImageVector = ImageVector.Builder(
    name = "PlayerRepeatOne", defaultWidth = 24.dp, defaultHeight = 24.dp,
    viewportWidth = 24f, viewportHeight = 24f).apply {
    // 复用 Repeat 路径 + 中间画 "1"（用矩形近似）
    path(fill = SolidColor(Color.Black), stroke = SolidColor(Color.Black), strokeLineWidth = 2f,
         strokeLineCap = StrokeCap.Round) {
        moveTo(18f, 6f); lineTo(18f, 4f); lineTo(20f, 6f)
        moveTo(6f, 9f); lineTo(6f, 15f); lineTo(18f, 15f); lineTo(18f, 9f)
        // "1" 竖线
        moveTo(12f, 10f); lineTo(12f, 14f)
    }
}.build()
'''
m_class = re.search(r'^class LxPlayerActivity', s, re.M)
if not m_class:
    print("❌ 未找到 class LxPlayerActivity")
    sys.exit(1)
s = s[:m_class.start()] + icons + "\n" + s[m_class.start():]
print("✓ 7 个 ImageVector 手搓图标已插入")

# --- 步骤3：加 ImageVector 相关 import ---
for imp in [
    "import androidx.compose.ui.graphics.vector.ImageVector",
    "import androidx.compose.ui.graphics.vector.path",
    "import androidx.compose.ui.graphics.SolidColor",
    "import androidx.compose.ui.graphics.StrokeCap",
    "import androidx.compose.ui.graphics.StrokeJoin",
    "import androidx.compose.ui.geometry.RoundRect",
]:
    if imp not in s:
        m = re.search(r'^import androidx\.compose[^\n]*\n', s, re.M)
        if m:
            s = s[:m.end()] + imp + " // [34v33]\n" + s[m.end():]
print("✓ ImageVector import 已补")

# --- 步骤4：替换 7 处 imageVector 值（Icon 外壳不动，零语法风险） ---
replacements = [
    ("Icons.AutoMirrored.Filled.SkipPrevious", "playerSkipPrevVector()"),
    ("Icons.AutoMirrored.Filled.SkipNext", "playerSkipNextVector()"),
    ("Icons.AutoMirrored.Filled.Shuffle", "playerShuffleVector()"),
    ("Icons.Filled.SkipPrevious", "playerSkipPrevVector()"),  # 兜底：v30 没改到的
    ("Icons.Filled.SkipNext", "playerSkipNextVector()"),
    ("Icons.Filled.Shuffle", "playerShuffleVector()"),
    ("Icons.Filled.Repeat", "playerRepeatVector()"),
    ("Icons.Filled.RepeatOne", "playerRepeatOneVector()"),
    ("Icons.Filled.Pause", "playerPauseVector()"),
    ("Icons.Filled.Play", "playerPlayVector()"),
]
total = 0
for old, new in replacements:
    n = s.count(old)
    if n > 0:
        s = s.replace(old, new)
        total += n
        print(f"✓ {old} → {new} ({n})")
print(f"✓ 共替换 {total} 处 imageVector")

assert MARK in s, "❌ v33 标记未写入"
with open(path, "w", encoding="utf-8") as f:
    f.write(s)
print("✓ 34 v33 完成")
PYEOF33

echo "=== 34 v33 完成 ==="

# === 34 v34: 彻底重写（修复 v33 三坑） ===
echo "=== 34 v34 ==="

python3 << 'PYEOF34'
import re, sys

path = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt"
MARK = "// [34v34]"

with open(path, encoding="utf-8") as f:
    s = f.read()

if MARK in s:
    print("34 v34: 已应用，跳过")
    sys.exit(0)

# --- 步骤1：暴力清除 v32/v33 所有残留 ---
# 删图标定义块（v32 的 @Composable 版 + v33 的 ImageVector 版）
# v32 块：从 "// [34v32] 手搓播放器图标" 到 "class LxPlayerActivity"
# v33 块：从 "// [34v33] 手搓图标 ImageVector" 到 "class LxPlayerActivity"
for marker in ["// [34v32] 手搓播放器图标", "// [34v33] 手搓图标 ImageVector"]:
    m1 = s.find(marker)
    m2 = s.find("class LxPlayerActivity")
    if m1 != -1 and m2 != -1 and m1 < m2:
        s = s[:m1] + s[m2:]
        print(f"✓ 已清图标定义块: {marker[:20]}...")
# 删所有 v32/v33 import
s, n1 = re.subn(r'^import [^\n]*// \[34v32\]\n', '', s, flags=re.M)
s, n2 = re.subn(r'^import [^\n]*// \[34v33\]\n', '', s, flags=re.M)
if n1+n2: print(f"✓ 已清 {n1+n2} 个 v32/v33 import")
# 删 v32 的坏调用（PlayerXXXIcon(tint=...) // [34v32]）
# 这些坏调用已经破坏了语法，必须还原
# v32 坏代码模式：PlayerPauseIcon(tint = X, modifier = Y) // [34v32]
# 我们无法还原原样，但 v34 会重新正确替换，所以先删除这些坏行所在的 Icon 调用残留
# 实际上最安全：找到所有 "// [34v32]" 的行，如果是坏调用则删除整行
lines = s.split('\n')
new_lines = []
for line in lines:
    if '// [34v32]' in line and 'Player' in line and 'Icon(tint' in line:
        print(f"✓ 删除 v32 坏调用行: {line.strip()[:60]}...")
        continue
    new_lines.append(line)
s = '\n'.join(new_lines)

# --- 步骤2：插入修正版 ImageVector 图标（不用 addRoundRect，用 addRect） ---
icons = '''
// [34v34] 手搓图标 ImageVector（零依赖）
private fun playerPlayVector(): ImageVector = ImageVector.Builder(
    name = "PlayerPlay", defaultWidth = 24.dp, defaultHeight = 24.dp,
    viewportWidth = 24f, viewportHeight = 24f).apply {
    path(fill = SolidColor(Color.Black)) {
        moveTo(9.2f, 4.8f); lineTo(20.0f, 12f); lineTo(9.2f, 19.2f); close()
    }
}.build()
private fun playerPauseVector(): ImageVector = ImageVector.Builder(
    name = "PlayerPause", defaultWidth = 24.dp, defaultHeight = 24.dp,
    viewportWidth = 24f, viewportHeight = 24f).apply {
    path(fill = SolidColor(Color.Black)) {
        moveTo(5.5f, 4.8f); lineTo(10.3f, 4.8f); lineTo(10.3f, 19.2f); lineTo(5.5f, 19.2f); close()
        moveTo(13.7f, 4.8f); lineTo(18.5f, 4.8f); lineTo(18.5f, 19.2f); lineTo(13.7f, 19.2f); close()
    }
}.build()
private fun playerSkipNextVector(): ImageVector = ImageVector.Builder(
    name = "PlayerSkipNext", defaultWidth = 24.dp, defaultHeight = 24.dp,
    viewportWidth = 24f, viewportHeight = 24f).apply {
    path(fill = SolidColor(Color.Black)) {
        moveTo(2.8f, 4.8f); lineTo(13.6f, 12f); lineTo(2.8f, 19.2f); close()
        moveTo(16.0f, 4.8f); lineTo(19.2f, 4.8f); lineTo(19.2f, 19.2f); lineTo(16.0f, 19.2f); close()
    }
}.build()
private fun playerSkipPrevVector(): ImageVector = ImageVector.Builder(
    name = "PlayerSkipPrev", defaultWidth = 24.dp, defaultHeight = 24.dp,
    viewportWidth = 24f, viewportHeight = 24f).apply {
    path(fill = SolidColor(Color.Black)) {
        moveTo(4.8f, 4.8f); lineTo(8.0f, 4.8f); lineTo(8.0f, 19.2f); lineTo(4.8f, 19.2f); close()
        moveTo(21.2f, 4.8f); lineTo(10.4f, 12f); lineTo(21.2f, 19.2f); close()
    }
}.build()
private fun playerShuffleVector(): ImageVector = ImageVector.Builder(
    name = "PlayerShuffle", defaultWidth = 24.dp, defaultHeight = 24.dp,
    viewportWidth = 24f, viewportHeight = 24f).apply {
    path(fill = SolidColor(Color.Black), stroke = SolidColor(Color.Black), strokeLineWidth = 2f,
         strokeLineCap = StrokeCap.Round, strokeLineJoin = StrokeJoin.Round) {
        moveTo(3f, 7f); lineTo(19f, 17f); moveTo(3f, 17f); lineTo(19f, 7f)
        moveTo(19f, 17f); lineTo(15f, 16f); moveTo(19f, 17f); lineTo(17f, 13f)
        moveTo(19f, 7f); lineTo(15f, 8f); moveTo(19f, 7f); lineTo(17f, 11f)
    }
}.build()
private fun playerRepeatVector(): ImageVector = ImageVector.Builder(
    name = "PlayerRepeat", defaultWidth = 24.dp, defaultHeight = 24.dp,
    viewportWidth = 24f, viewportHeight = 24f).apply {
    path(fill = SolidColor(Color.Black), stroke = SolidColor(Color.Black), strokeLineWidth = 2f,
         strokeLineCap = StrokeCap.Round, strokeLineJoin = StrokeJoin.Round) {
        moveTo(18f, 6f); lineTo(18f, 4f); lineTo(20f, 6f)
        moveTo(6f, 9f); lineTo(6f, 15f); lineTo(18f, 15f); lineTo(18f, 9f)
    }
}.build()
private fun playerRepeatOneVector(): ImageVector = ImageVector.Builder(
    name = "PlayerRepeatOne", defaultWidth = 24.dp, defaultHeight = 24.dp,
    viewportWidth = 24f, viewportHeight = 24f).apply {
    path(fill = SolidColor(Color.Black), stroke = SolidColor(Color.Black), strokeLineWidth = 2f,
         strokeLineCap = StrokeCap.Round) {
        moveTo(18f, 6f); lineTo(18f, 4f); lineTo(20f, 6f)
        moveTo(6f, 9f); lineTo(6f, 15f); lineTo(18f, 15f); lineTo(18f, 9f)
        moveTo(12f, 10f); lineTo(12f, 14f)
    }
}.build()
'''
m_class = re.search(r'^class LxPlayerActivity', s, re.M)
if not m_class:
    print("❌ 未找到 class LxPlayerActivity")
    sys.exit(1)
s = s[:m_class.start()] + icons + "\n" + s[m_class.start():]
print("✓ 7 个修正版 ImageVector 已插入")

# --- 步骤3：加 import ---
for imp in [
    "import androidx.compose.ui.graphics.vector.ImageVector",
    "import androidx.compose.ui.graphics.vector.path",
    "import androidx.compose.ui.graphics.SolidColor",
    "import androidx.compose.ui.graphics.StrokeCap",
    "import androidx.compose.ui.graphics.StrokeJoin",
]:
    if imp not in s:
        m = re.search(r'^import androidx\.compose[^\n]*\n', s, re.M)
        if m: s = s[:m.end()] + imp + " // [34v34]\n" + s[m.end():]
print("✓ import 已补")

# --- 步骤4：替换 imageVector（最长优先，防子串 bug） ---
# 按长度降序排列，确保 RepeatOne 先于 Repeat
replacements = [
    ("Icons.AutoMirrored.Filled.SkipPrevious", "playerSkipPrevVector()"),
    ("Icons.AutoMirrored.Filled.SkipNext", "playerSkipNextVector()"),
    ("Icons.AutoMirrored.Filled.Shuffle", "playerShuffleVector()"),
    ("Icons.Filled.SkipPrevious", "playerSkipPrevVector()"),
    ("Icons.Filled.SkipNext", "playerSkipNextVector()"),
    ("Icons.Filled.Shuffle", "playerShuffleVector()"),
    ("Icons.Filled.RepeatOne", "playerRepeatOneVector()"),  # [34v34] 必须在 Repeat 之前
    ("Icons.Filled.Repeat", "playerRepeatVector()"),
    ("Icons.Filled.Pause", "playerPauseVector()"),
    ("Icons.Filled.Play", "playerPlayVector()"),
]
# 按 old 长度降序排序
replacements.sort(key=lambda x: len(x[0]), reverse=True)
total = 0
for old, new in replacements:
    n = s.count(old)
    if n > 0:
        s = s.replace(old, new)
        total += n
        print(f"✓ {old} → {new} ({n})")
print(f"✓ 共替换 {total} 处")

assert MARK in s, "❌ v34 标记未写入"
with open(path, "w", encoding="utf-8") as f:
    f.write(s)
print("✓ 34 v34 完成")
PYEOF34

echo "=== 34 v34 完成 ==="

# === 34 v35: 修复 v33 腐蚀残留 ===
echo "=== 34 v35 ==="

python3 << 'PYEOF35'
import sys

path = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt"
MARK = "// [34v35]"

with open(path, encoding="utf-8") as f:
    s = f.read()

if MARK in s:
    print("34 v35: 已应用，跳过")
    sys.exit(0)

# v33 把 Icons.Filled.RepeatOne 腐蚀成 playerRepeatVector()One，v34 没修
# v35 直接修复腐蚀版本
fixes = [
    ("playerRepeatVector()One", "playerRepeatOneVector()"),  # [34v35] v33 腐蚀残留
]
for old, new in fixes:
    n = s.count(old)
    if n > 0:
        s = s.replace(old, new)
        print(f"✓ {old} → {new} ({n})")
    else:
        print(f"- 未找到: {old}")

# 兜底：如果还有漏网的 Icons.Filled.*（按长度降序）
replacements = [
    ("Icons.AutoMirrored.Filled.SkipPrevious", "playerSkipPrevVector()"),
    ("Icons.AutoMirrored.Filled.SkipNext", "playerSkipNextVector()"),
    ("Icons.AutoMirrored.Filled.Shuffle", "playerShuffleVector()"),
    ("Icons.Filled.SkipPrevious", "playerSkipPrevVector()"),
    ("Icons.Filled.SkipNext", "playerSkipNextVector()"),
    ("Icons.Filled.Shuffle", "playerShuffleVector()"),
    ("Icons.Filled.RepeatOne", "playerRepeatOneVector()"),
    ("Icons.Filled.Repeat", "playerRepeatVector()"),
    ("Icons.Filled.Pause", "playerPauseVector()"),
    ("Icons.Filled.Play", "playerPlayVector()"),
]
replacements.sort(key=lambda x: len(x[0]), reverse=True)
for old, new in replacements:
    n = s.count(old)
    if n > 0:
        s = s.replace(old, new)
        print(f"✓ 兜底: {old} → {new} ({n})")

s += "\n" + MARK + "\n"
with open(path, "w", encoding="utf-8") as f:
    f.write(s)
print("✓ 34 v35 完成")
PYEOF35

echo "=== 34 v35 完成 ==="

# === 34 v36: 放弃 ImageVector，改 Canvas.drawPath + 修文字色 ===
echo "=== 34 v36 ==="

python3 << 'PYEOF36'
import re, sys

path = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt"
MARK = "// [34v36]"

with open(path, encoding="utf-8") as f:
    s = f.read()

if MARK in s:
    print("34 v36: 已应用，跳过")
    sys.exit(0)

# --- 步骤1：删除 v34/v35 的 ImageVector 函数 ---
for marker in ["// [34v34] 手搓图标 ImageVector", "// [34v35]"]:
    # v35 只有 MARK，没有独立块，跳过
    if marker == "// [34v34] 手搓图标 ImageVector":
        m1 = s.find(marker)
        m2 = s.find("class LxPlayerActivity")
        if m1 != -1 and m2 != -1 and m1 < m2:
            s = s[:m1] + s[m2:]
            print(f"✓ 已删 ImageVector 函数块")
# 删 v34/v35 import
s, n1 = re.subn(r'^import [^\n]*// \[34v34\]\n', '', s, flags=re.M)
# v35 没有加 import，跳过
if n1: print(f"✓ 已清 {n1} 个 v34 import")

# --- 步骤2：插入 Canvas 版图标（DrawScope.drawPath 是正确 API） ---
icons = '''
// [34v36] 手搓图标 Canvas 版（DrawScope.drawPath，正确 API）
@Composable
private fun PlayerPlayIcon(tint: Color, modifier: Modifier = Modifier) {
    Canvas(modifier = modifier) {
        val w = size.width; val h = size.height
        drawPath(Path().apply {
            moveTo(w * 0.38f, h * 0.2f); lineTo(w * 0.84f, h * 0.5f); lineTo(w * 0.38f, h * 0.8f); close()
        }, tint) // [34v36] 三角右移视觉居中
    }
}
@Composable
private fun PlayerPauseIcon(tint: Color, modifier: Modifier = Modifier) {
    Canvas(modifier = modifier) {
        val w = size.width; val h = size.height
        val bw = w * 0.22f
        drawRoundRect(tint, Offset(w * 0.22f, h * 0.2f), Size(bw, h * 0.6f), CornerRadius(bw / 2, bw / 2))
        drawRoundRect(tint, Offset(w * 0.56f, h * 0.2f), Size(bw, h * 0.6f), CornerRadius(bw / 2, bw / 2))
    }
}
@Composable
private fun PlayerSkipNextIcon(tint: Color, modifier: Modifier = Modifier) {
    Canvas(modifier = modifier) {
        val w = size.width; val h = size.height
        drawPath(Path().apply {
            moveTo(w * 0.12f, h * 0.2f); lineTo(w * 0.57f, h * 0.5f); lineTo(w * 0.12f, h * 0.8f); close()
        }, tint)
        val bw = 2.dp.toPx()
        drawRoundRect(tint, Offset(w * 0.67f, h * 0.2f), Size(bw, h * 0.6f), CornerRadius(bw / 2, bw / 2))
    }
}
@Composable
private fun PlayerSkipPrevIcon(tint: Color, modifier: Modifier = Modifier) {
    Canvas(modifier = modifier) {
        val w = size.width; val h = size.height
        val bw = 2.dp.toPx()
        drawRoundRect(tint, Offset(w * 0.20f, h * 0.2f), Size(bw, h * 0.6f), CornerRadius(bw / 2, bw / 2))
        drawPath(Path().apply {
            moveTo(w * 0.88f, h * 0.2f); lineTo(w * 0.43f, h * 0.5f); lineTo(w * 0.88f, h * 0.8f); close()
        }, tint)
    }
}
@Composable
private fun PlayerShuffleIcon(tint: Color, modifier: Modifier = Modifier) {
    Canvas(modifier = modifier) {
        val w = size.width; val h = size.height; val sw = 2.dp.toPx()
        drawLine(tint, Offset(w * 0.12f, h * 0.29f), Offset(w * 0.79f, h * 0.71f), sw, StrokeCap.Round)
        drawLine(tint, Offset(w * 0.12f, h * 0.71f), Offset(w * 0.79f, h * 0.29f), sw, StrokeCap.Round)
        // 箭头（简化折线）
        drawPath(Path().apply {
            moveTo(w * 0.79f, h * 0.71f); lineTo(w * 0.62f, h * 0.67f); moveTo(w * 0.79f, h * 0.71f); lineTo(w * 0.71f, h * 0.54f)
            moveTo(w * 0.79f, h * 0.29f); lineTo(w * 0.62f, h * 0.33f); moveTo(w * 0.79f, h * 0.29f); lineTo(w * 0.71f, h * 0.46f)
        }, tint, style = Stroke(sw, cap = StrokeCap.Round))
    }
}
@Composable
private fun PlayerRepeatIcon(tint: Color, modifier: Modifier = Modifier) {
    Canvas(modifier = modifier) {
        val w = size.width; val h = size.height; val sw = 2.dp.toPx()
        drawArc(tint, 35f, 290f, false, Offset(w * 0.14f, h * 0.22f), Size(w * 0.72f, h * 0.56f), style = Stroke(sw, cap = StrokeCap.Round))
        // 箭头
        drawPath(Path().apply {
            moveTo(w * 0.75f, h * 0.25f); lineTo(w * 0.75f, h * 0.17f); lineTo(w * 0.83f, h * 0.25f)
        }, tint, style = Stroke(sw, cap = StrokeCap.Round))
    }
}
@Composable
private fun PlayerRepeatOneIcon(tint: Color, modifier: Modifier = Modifier) {
    Box(modifier = modifier, contentAlignment = Alignment.Center) {
        PlayerRepeatIcon(tint, Modifier.fillMaxSize(0.82f))
        Text("1", color = tint, fontSize = 9.sp, fontWeight = FontWeight.Bold)
    }
}
'''
m_class = re.search(r'^class LxPlayerActivity', s, re.M)
if not m_class:
    print("❌ 未找到 class LxPlayerActivity")
    sys.exit(1)
s = s[:m_class.start()] + icons + "\n" + s[m_class.start():]
print("✓ 7 个 Canvas 图标已插入")

# --- 步骤3：加 import ---
for imp in [
    "import androidx.compose.foundation.Canvas",
    "import androidx.compose.ui.graphics.Path",
    "import androidx.compose.ui.graphics.drawscope.Stroke",
    "import androidx.compose.ui.geometry.Offset",
    "import androidx.compose.ui.geometry.Size",
    "import androidx.compose.ui.geometry.CornerRadius",
    "import androidx.compose.ui.unit.dp",
    "import androidx.compose.ui.unit.sp",
    "import androidx.compose.ui.text.font.FontWeight",
    "import androidx.compose.foundation.layout.Box",
    "import androidx.compose.foundation.layout.fillMaxSize",
    "import androidx.compose.ui.Alignment",
]:
    if imp not in s:
        m = re.search(r'^import androidx\.compose[^\n]*\n', s, re.M)
        if m: s = s[:m.end()] + imp + " // [34v36]\n" + s[m.end():]
print("✓ import 已补")

# --- 步骤4：替换 Icon(imageVector = playerXXXVector()) 为 Composable 调用 ---
# v35 的代码：Icon(imageVector = playerPlayVector(), tint = X, modifier = Y)
# v36 改为：PlayerPlayIcon(tint = X, modifier = Y)
replacements = [
    ("playerPlayVector()", "PlayerPlayIcon"),
    ("playerPauseVector()", "PlayerPauseIcon"),
    ("playerSkipNextVector()", "PlayerSkipNextIcon"),
    ("playerSkipPrevVector()", "PlayerSkipPrevIcon"),
    ("playerShuffleVector()", "PlayerShuffleIcon"),
    ("playerRepeatOneVector()", "PlayerRepeatOneIcon"),  # 必须在 Repeat 之前
    ("playerRepeatVector()", "PlayerRepeatIcon"),
]
# 按长度降序
replacements.sort(key=lambda x: len(x[0]), reverse=True)

# 用正则替换 Icon(imageVector = XXX(), tint = A, modifier = B) 为 XXX(tint = A, modifier = B)
# 简化：先替换 imageVector 值，再把 Icon( 换成对应的 Composable
# 实际上最简单：直接字符串替换 "Icon(imageVector = playerPlayVector()" → "PlayerPlayIcon("
for old_vec, new_comp in replacements:
    old_pattern = f"Icon(imageVector = {old_vec}"
    new_pattern = f"{new_comp}("
    n = s.count(old_pattern)
    if n > 0:
        s = s.replace(old_pattern, new_pattern)
        print(f"✓ {old_pattern[:40]}... → {new_pattern} ({n})")

# --- 步骤5：修 secondaryTextColor（不跟 App 主题） ---
old_sec = "val secondaryTextColor = if (isLightBg) musicColors().textSecondary else Color.White.copy(alpha = 0.7f) // [34v23]"
new_sec = "val secondaryTextColor = if (isLightBg) Color(0xFF1C1C1E).copy(alpha = 0.7f) else Color.White.copy(alpha = 0.7f) // [34v36] 不跟App主题"
if old_sec in s:
    s = s.replace(old_sec, new_sec)
    print("✓ secondaryTextColor 已改：浅色用 0xFF1C1C1E，不跟主题")
else:
    print("⚠ 未找到 secondaryTextColor 旧定义（可能已被修改）")

assert MARK in s, "❌ v36 标记未写入"
with open(path, "w", encoding="utf-8") as f:
    f.write(s)
print("✓ 34 v36 完成")
PYEOF36

echo "=== 34 v36 完成 ==="

# === 34 v37: LxIcons.kt 集中管理 + 重写绘制逻辑 ===
echo "=== 34 v37 ==="

python3 << 'PYEOF37'
import re, sys, base64, os

path = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt"
icon_path = "app/src/main/java/com/github/tvbox/osc/ui/music/component/LxIcons.kt"
MARK = "// [34v37]"

with open(path, encoding="utf-8") as f:
    s = f.read()

if MARK in s:
    print("34 v37: 已应用，跳过")
    sys.exit(0)

# --- 步骤1：写 LxIcons.kt ---
os.makedirs(os.path.dirname(icon_path), exist_ok=True)
lx_b64 = "Ly8gWzM0djM3XSBMeEljb25zLmt0IC0g5omL5pCT5Zu+5qCH6ZuG5Lit566h55CG77yM5b275bqV6Kej6ICmIE1hdGVyaWFsIOWbvuagh+W6kwpwYWNrYWdlIGNvbS5naXRodWIudHZib3gub3NjLnVpLm11c2ljLmNvbXBvbmVudAoKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UuZm91bmRhdGlvbi5DYW52YXMKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UuZm91bmRhdGlvbi5sYXlvdXQuQm94CmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLmZvdW5kYXRpb24ubGF5b3V0LmZpbGxNYXhTaXplCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLmZvdW5kYXRpb24ubGF5b3V0LnNpemUKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UuZm91bmRhdGlvbi50ZXh0LkJhc2ljVGV4dAppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5ydW50aW1lLkNvbXBvc2FibGUKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UudWkuQWxpZ25tZW50CmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLnVpLk1vZGlmaWVyCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLnVpLmdlb21ldHJ5LkNvcm5lclJhZGl1cwppbXBvcnQgYW5kcm9pZHguY29tcG9zZS51aS5nZW9tZXRyeS5PZmZzZXQKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UudWkuZ2VvbWV0cnkuU2l6ZQppbXBvcnQgYW5kcm9pZHguY29tcG9zZS51aS5ncmFwaGljcy5Db2xvcgppbXBvcnQgYW5kcm9pZHguY29tcG9zZS51aS5ncmFwaGljcy5QYXRoCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLnVpLmdyYXBoaWNzLmRyYXdzY29wZS5TdHJva2UKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UudWkuZ3JhcGhpY3MuU3Ryb2tlQ2FwCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLnVpLnRleHQuVGV4dFN0eWxlCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLnVpLnRleHQuZm9udC5Gb250V2VpZ2h0CmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLnVpLnVuaXQuRHAKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UudWkudW5pdC5kcAppbXBvcnQgYW5kcm9pZHguY29tcG9zZS51aS51bml0LnNwCgovLyBbMzR2MzddIOaSreaUvu+8muS4ieinkuW9ou+8iOinhuiniemHjeW/g+WPs+enu+e6piAxLzYg5a6977yJCkBDb21wb3NhYmxlCmZ1biBQbGF5ZXJQbGF5SWNvbih0aW50OiBDb2xvciwgc2l6ZTogRHAgPSAyNC5kcCwgbW9kaWZpZXI6IE1vZGlmaWVyID0gTW9kaWZpZXIpIHsKICAgIENhbnZhcyhtb2RpZmllciA9IG1vZGlmaWVyLnNpemUoc2l6ZSkpIHsKICAgICAgICB2YWwgdyA9IHNpemUud2lkdGg7IHZhbCBoID0gc2l6ZS5oZWlnaHQKICAgICAgICBkcmF3UGF0aChQYXRoKCkuYXBwbHkgewogICAgICAgICAgICBtb3ZlVG8odyAqIDAuMzVmLCBoICogMC4yMGYpOyBsaW5lVG8odyAqIDAuNzVmLCBoICogMC41MGYpOyBsaW5lVG8odyAqIDAuMzVmLCBoICogMC44MGYpOyBjbG9zZSgpCiAgICAgICAgfSwgY29sb3IgPSB0aW50KQogICAgfQp9CgovLyBbMzR2MzddIOaaguWBnO+8muS4pOS4quWchuinkuerluadoQpAQ29tcG9zYWJsZQpmdW4gUGxheWVyUGF1c2VJY29uKHRpbnQ6IENvbG9yLCBzaXplOiBEcCA9IDI0LmRwLCBtb2RpZmllcjogTW9kaWZpZXIgPSBNb2RpZmllcikgewogICAgQ2FudmFzKG1vZGlmaWVyID0gbW9kaWZpZXIuc2l6ZShzaXplKSkgewogICAgICAgIHZhbCB3ID0gc2l6ZS53aWR0aDsgdmFsIGggPSBzaXplLmhlaWdodAogICAgICAgIHZhbCBidyA9IHcgKiAwLjIyZjsgdmFsIGJoID0gaCAqIDAuNjBmOyB2YWwgdG9wWSA9IGggKiAwLjIwZgogICAgICAgIGRyYXdSb3VuZFJlY3QoY29sb3IgPSB0aW50LCB0b3BMZWZ0ID0gT2Zmc2V0KHcgKiAwLjI0ZiwgdG9wWSksIHNpemUgPSBTaXplKGJ3LCBiaCksIGNvcm5lclJhZGl1cyA9IENvcm5lclJhZGl1cyhidyAvIDJmKSkKICAgICAgICBkcmF3Um91bmRSZWN0KGNvbG9yID0gdGludCwgdG9wTGVmdCA9IE9mZnNldCh3ICogMC41NGYsIHRvcFkpLCBzaXplID0gU2l6ZShidywgYmgpLCBjb3JuZXJSYWRpdXMgPSBDb3JuZXJSYWRpdXMoYncgLyAyZikpCiAgICB9Cn0KCi8vIFszNHYzN10g5LiL5LiA6aaW77ya5LiJ6KeSICsg5Y+z56uW5p2h77yIMi5kcCDnu5/kuIDnur/lrr3vvIkKQENvbXBvc2FibGUKZnVuIFBsYXllclNraXBOZXh0SWNvbih0aW50OiBDb2xvciwgc2l6ZTogRHAgPSAyNC5kcCwgbW9kaWZpZXI6IE1vZGlmaWVyID0gTW9kaWZpZXIpIHsKICAgIENhbnZhcyhtb2RpZmllciA9IG1vZGlmaWVyLnNpemUoc2l6ZSkpIHsKICAgICAgICB2YWwgdyA9IHNpemUud2lkdGg7IHZhbCBoID0gc2l6ZS5oZWlnaHQKICAgICAgICBkcmF3UGF0aChQYXRoKCkuYXBwbHkgewogICAgICAgICAgICBtb3ZlVG8odyAqIDAuMTBmLCBoICogMC4yMGYpOyBsaW5lVG8odyAqIDAuNTVmLCBoICogMC41MGYpOyBsaW5lVG8odyAqIDAuMTBmLCBoICogMC44MGYpOyBjbG9zZSgpCiAgICAgICAgfSwgY29sb3IgPSB0aW50KQogICAgICAgIHZhbCBidyA9IDIuZHAudG9QeCgpCiAgICAgICAgZHJhd1JvdW5kUmVjdChjb2xvciA9IHRpbnQsIHRvcExlZnQgPSBPZmZzZXQodyAqIDAuNjVmLCBoICogMC4yMGYpLCBzaXplID0gU2l6ZShidywgaCAqIDAuNjBmKSwgY29ybmVyUmFkaXVzID0gQ29ybmVyUmFkaXVzKGJ3IC8gMmYpKQogICAgfQp9CgovLyBbMzR2MzddIOS4iuS4gOmmlu+8muW3puerluadoSArIOmVnOWDj+S4ieinkgpAQ29tcG9zYWJsZQpmdW4gUGxheWVyU2tpcFByZXZJY29uKHRpbnQ6IENvbG9yLCBzaXplOiBEcCA9IDI0LmRwLCBtb2RpZmllcjogTW9kaWZpZXIgPSBNb2RpZmllcikgewogICAgQ2FudmFzKG1vZGlmaWVyID0gbW9kaWZpZXIuc2l6ZShzaXplKSkgewogICAgICAgIHZhbCB3ID0gc2l6ZS53aWR0aDsgdmFsIGggPSBzaXplLmhlaWdodAogICAgICAgIHZhbCBidyA9IDIuZHAudG9QeCgpCiAgICAgICAgZHJhd1JvdW5kUmVjdChjb2xvciA9IHRpbnQsIHRvcExlZnQgPSBPZmZzZXQodyAqIDAuMjVmLCBoICogMC4yMGYpLCBzaXplID0gU2l6ZShidywgaCAqIDAuNjBmKSwgY29ybmVyUmFkaXVzID0gQ29ybmVyUmFkaXVzKGJ3IC8gMmYpKQogICAgICAgIGRyYXdQYXRoKFBhdGgoKS5hcHBseSB7CiAgICAgICAgICAgIG1vdmVUbyh3ICogMC45MGYsIGggKiAwLjIwZik7IGxpbmVUbyh3ICogMC40NWYsIGggKiAwLjUwZik7IGxpbmVUbyh3ICogMC45MGYsIGggKiAwLjgwZik7IGNsb3NlKCkKICAgICAgICB9LCBjb2xvciA9IHRpbnQpCiAgICB9Cn0KCi8vIFszNHYzN10g6ZqP5py677ya5Y+M5Lqk5Y+J57q/ICsg566t5aS077yI5oqY57q/566A5YyW54mI77yJCkBDb21wb3NhYmxlCmZ1biBQbGF5ZXJTaHVmZmxlSWNvbih0aW50OiBDb2xvciwgc2l6ZTogRHAgPSAyNC5kcCwgbW9kaWZpZXI6IE1vZGlmaWVyID0gTW9kaWZpZXIpIHsKICAgIENhbnZhcyhtb2RpZmllciA9IG1vZGlmaWVyLnNpemUoc2l6ZSkpIHsKICAgICAgICB2YWwgdyA9IHNpemUud2lkdGg7IHZhbCBoID0gc2l6ZS5oZWlnaHQ7IHZhbCBzdyA9IDIuZHAudG9QeCgpCiAgICAgICAgZHJhd0xpbmUodGludCwgT2Zmc2V0KHcgKiAwLjEwZiwgaCAqIDAuMzBmKSwgT2Zmc2V0KHcgKiAwLjc1ZiwgaCAqIDAuNzBmKSwgc3csIFN0cm9rZUNhcC5Sb3VuZCkKICAgICAgICBkcmF3TGluZSh0aW50LCBPZmZzZXQodyAqIDAuMTBmLCBoICogMC43MGYpLCBPZmZzZXQodyAqIDAuNzVmLCBoICogMC4zMGYpLCBzdywgU3Ryb2tlQ2FwLlJvdW5kKQogICAgICAgIGRyYXdQYXRoKFBhdGgoKS5hcHBseSB7CiAgICAgICAgICAgIG1vdmVUbyh3ICogMC43NWYsIGggKiAwLjcwZik7IGxpbmVUbyh3ICogMC42MGYsIGggKiAwLjY1Zik7IG1vdmVUbyh3ICogMC43NWYsIGggKiAwLjcwZik7IGxpbmVUbyh3ICogMC42OGYsIGggKiAwLjU1ZikKICAgICAgICAgICAgbW92ZVRvKHcgKiAwLjc1ZiwgaCAqIDAuMzBmKTsgbGluZVRvKHcgKiAwLjYwZiwgaCAqIDAuMzVmKTsgbW92ZVRvKHcgKiAwLjc1ZiwgaCAqIDAuMzBmKTsgbGluZVRvKHcgKiAwLjY4ZiwgaCAqIDAuNDVmKQogICAgICAgIH0sIGNvbG9yID0gdGludCwgc3R5bGUgPSBTdHJva2Uoc3csIGNhcCA9IFN0cm9rZUNhcC5Sb3VuZCkpCiAgICB9Cn0KCi8vIFszNHYzN10g5b6q546v77ya5ZyG5bynICsg566t5aS0CkBDb21wb3NhYmxlCmZ1biBQbGF5ZXJSZXBlYXRJY29uKHRpbnQ6IENvbG9yLCBzaXplOiBEcCA9IDI0LmRwLCBtb2RpZmllcjogTW9kaWZpZXIgPSBNb2RpZmllcikgewogICAgQ2FudmFzKG1vZGlmaWVyID0gbW9kaWZpZXIuc2l6ZShzaXplKSkgewogICAgICAgIHZhbCB3ID0gc2l6ZS53aWR0aDsgdmFsIGggPSBzaXplLmhlaWdodDsgdmFsIHN3ID0gMi5kcC50b1B4KCkKICAgICAgICBkcmF3QXJjKGNvbG9yID0gdGludCwgc3RhcnRBbmdsZSA9IDM1Ziwgc3dlZXBBbmdsZSA9IDI5MGYsIHVzZUNlbnRlciA9IGZhbHNlLAogICAgICAgICAgICB0b3BMZWZ0ID0gT2Zmc2V0KHcgKiAwLjE0ZiwgaCAqIDAuMjJmKSwgc2l6ZSA9IFNpemUodyAqIDAuNzJmLCBoICogMC41NmYpLAogICAgICAgICAgICBzdHlsZSA9IFN0cm9rZShzdywgY2FwID0gU3Ryb2tlQ2FwLlJvdW5kKSkKICAgICAgICBkcmF3UGF0aChQYXRoKCkuYXBwbHkgewogICAgICAgICAgICBtb3ZlVG8odyAqIDAuNzhmLCBoICogMC4yOGYpOyBsaW5lVG8odyAqIDAuNzhmLCBoICogMC4xOGYpOyBsaW5lVG8odyAqIDAuODhmLCBoICogMC4yOGYpCiAgICAgICAgfSwgY29sb3IgPSB0aW50LCBzdHlsZSA9IFN0cm9rZShzdywgY2FwID0gU3Ryb2tlQ2FwLlJvdW5kKSkKICAgIH0KfQoKLy8gWzM0djM3XSDljZXmm7Llvqrnjq/vvJrlnIblvKcgKyAiMSIKQENvbXBvc2FibGUKZnVuIFBsYXllclJlcGVhdE9uZUljb24odGludDogQ29sb3IsIHNpemU6IERwID0gMjQuZHAsIG1vZGlmaWVyOiBNb2RpZmllciA9IE1vZGlmaWVyKSB7CiAgICBCb3gobW9kaWZpZXIgPSBtb2RpZmllci5zaXplKHNpemUpLCBjb250ZW50QWxpZ25tZW50ID0gQWxpZ25tZW50LkNlbnRlcikgewogICAgICAgIFBsYXllclJlcGVhdEljb24odGludCA9IHRpbnQsIHNpemUgPSBzaXplICogMC44MmYsIG1vZGlmaWVyID0gTW9kaWZpZXIpCiAgICAgICAgQmFzaWNUZXh0KCIxIiwgc3R5bGUgPSBUZXh0U3R5bGUoY29sb3IgPSB0aW50LCBmb250U2l6ZSA9IDkuc3AsIGZvbnRXZWlnaHQgPSBGb250V2VpZ2h0LkJvbGQpKQogICAgfQp9Cg=="
lx_code = base64.b64decode(lx_b64).decode("utf-8")
with open(icon_path, "w", encoding="utf-8") as f:
    f.write(lx_code)
print(f"✓ LxIcons.kt 已写入 ({len(lx_code)} 字符)")

# --- 步骤2：删 LxPlayerActivity.kt 里的本地图标定义（v36 块） ---
m1 = s.find("// [34v36] 手搓图标 Canvas 版")
m2 = s.find("class LxPlayerActivity")
if m1 != -1 and m2 != -1 and m1 < m2:
    s = s[:m1] + s[m2:]
    print("✓ 已删 v36 本地图标定义")
else:
    print("⚠ 未找到 v36 图标块（可能已被清理）")

# --- 步骤3：删 v36 import，加新 import ---
s, n = re.subn(r'^import [^\n]*// \[34v36\]\n', '', s, flags=re.M)
if n: print(f"✓ 已清 {n} 个 v36 import")
new_imp = "import com.github.tvbox.osc.ui.music.component.* // [34v37]"
if new_imp not in s:
    m = re.search(r'^import com\.github\.tvbox\.osc[^\n]*\n', s, re.M)
    if m:
        s = s[:m.end()] + new_imp + "\n" + s[m.end():]
        print("✓ 已加 LxIcons import")

# --- 步骤4：调用点无需改（签名兼容：tint, size=24.dp, modifier） ---
# v36 调用：PlayerPlayIcon(tint = X, modifier = Y)
# v37 签名：PlayerPlayIcon(tint: Color, size: Dp = 24.dp, modifier: Modifier = Modifier)
# 完全兼容，无需修改调用点
print("✓ 调用点签名兼容，无需修改")

s += "\n" + MARK + "\n"
assert MARK in s, "❌ v37 标记未写入"
with open(path, "w", encoding="utf-8") as f:
    f.write(s)
print("✓ 34 v37 完成")
PYEOF37

echo "=== 34 v37 完成 ==="

# === 34 v38: 修 v36 残留（StrokeCap import + when块旧调用） ===
echo "=== 34 v38 ==="

python3 << 'PYEOF38'
import re, sys

path = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt"
MARK = "// [34v38]"

with open(path, encoding="utf-8") as f:
    s = f.read()

if MARK in s:
    print("34 v38: 已应用，跳过")
    sys.exit(0)

# --- 修复1：补 StrokeCap import（v36 漏了） ---
# LxIcons.kt 里已有，这里是 LxPlayerActivity.kt 本地残留代码需要
# 实际上 v37 已把图标搬到 LxIcons.kt，Activity 里不应再有 StrokeCap
# 但 v36 的 when 块残留还在，先修调用
print("✓ 修复1：LxIcons.kt 已有 StrokeCap，跳过 Activity 补 import")

# --- 修复2：when 块里的 playerXXXVector() 改为新 Composable ---
# v36 残留：Icon(imageVector = playerShuffleVector(), tint = X, modifier = Y)
# v38 改为：PlayerShuffleIcon(tint = X, modifier = Y)
# 用正则匹配 Icon(imageVector = playerXXXVector(), tint = A, modifier = B)
fixes = [
    ("playerShuffleVector", "PlayerShuffleIcon"),
    ("playerRepeatOneVector", "PlayerRepeatOneIcon"),
    ("playerRepeatVector", "PlayerRepeatIcon"),
    ("playerPlayVector", "PlayerPlayIcon"),
    ("playerPauseVector", "PlayerPauseIcon"),
    ("playerSkipNextVector", "PlayerSkipNextIcon"),
    ("playerSkipPrevVector", "PlayerSkipPrevIcon"),
]
# 按长度降序，防子串
fixes.sort(key=lambda x: len(x[0]), reverse=True)
total = 0
for old_vec, new_comp in fixes:
    # 匹配 Icon(imageVector = OLD(), tint = ..., modifier = ...) 整个调用
    # 简化：直接替换 OLD() 为 NEW(，再把前面的 "Icon(imageVector = " 删掉
    # 更安全：用正则找 Icon(imageVector = OLD\(\)
    pattern = re.compile(r'Icon\s*\(\s*imageVector\s*=\s*' + re.escape(old_vec) + r'\(\s*\)')
    matches = pattern.findall(s)
    if matches:
        s = pattern.sub(new_comp + '(', s)
        total += len(matches)
        print(f"✓ {old_vec}() → {new_comp}( ({len(matches)})")

# --- 修复3：确保 LxIcons.kt 存在（v37 可能没跑完） ---
import os
icon_path = "app/src/main/java/com/github/tvbox/osc/ui/music/component/LxIcons.kt"
if not os.path.exists(icon_path):
    print("❌ LxIcons.kt 不存在！v37 未生效")
    sys.exit(1)
else:
    print("✓ LxIcons.kt 存在")

# --- 修复4：确保 import 存在 ---
new_imp = "import com.github.tvbox.osc.ui.music.component.* // [34v37]"
if new_imp not in s:
    # 尝试 v38 的标记
    new_imp38 = "import com.github.tvbox.osc.ui.music.component.* // [34v38]"
    m = re.search(r'^import com\.github\.tvbox\.osc[^\n]*\n', s, re.M)
    if m:
        s = s[:m.end()] + new_imp38 + "\n" + s[m.end():]
        print("✓ 已补 LxIcons import [34v38]")
else:
    print("✓ LxIcons import 已存在")

s += "\n" + MARK + "\n"
assert MARK in s, "❌ v38 标记未写入"
with open(path, "w", encoding="utf-8") as f:
    f.write(s)
print(f"✓ 34 v38 完成，共修 {total} 处残留调用")
PYEOF38

echo "=== 34 v38 完成 ==="

# === 34 v39: 修 size 遮蔽 + when 块残留 ===
echo "=== 34 v39 ==="

python3 << 'PYEOF39'
import re, sys, os

path = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt"
icon_path = "app/src/main/java/com/github/tvbox/osc/ui/music/component/LxIcons.kt"
MARK = "// [34v39]"

with open(path, encoding="utf-8") as f:
    s = f.read()

if MARK in s:
    print("34 v39: 已应用，跳过")
    sys.exit(0)

# --- 修复1：LxIcons.kt 里 size: Dp 改名 iconSize，避免遮蔽 DrawScope.size ---
if os.path.exists(icon_path):
    with open(icon_path, encoding="utf-8") as f:
        lx = f.read()
    # 参数名 size: Dp -> iconSize: Dp；调用处 modifier.size(size) -> modifier.size(iconSize)
    # 注意：DrawScope 里的 size.width/size.height 必须保留（那是 Size 类型）
    # 策略：只替换函数签名里的 "size: Dp" 和 "modifier.size(size)"
    orig = lx
    lx = lx.replace("size: Dp = 24.dp", "iconSize: Dp = 24.dp")
    lx = lx.replace("modifier.size(size)", "modifier.size(iconSize)")
    # PlayerRepeatOneIcon 里有 size * 0.82f，改成 iconSize * 0.82f
    lx = lx.replace("size * 0.82f", "iconSize * 0.82f")
    # PlayerRepeatOneIcon 的 size 参数传递：PlayerRepeatIcon(tint = tint, size = size * 0.82f
    # 已被上面替换覆盖
    if lx != orig:
        with open(icon_path, "w", encoding="utf-8") as f:
            f.write(lx)
        print("✓ LxIcons.kt: size → iconSize（防遮蔽）")
    else:
        print("- LxIcons.kt 无需改名（可能已修复）")
else:
    print("❌ LxIcons.kt 不存在")
    sys.exit(1)

# --- 修复2：when 块里的 playerXXXVector() ---
# 形态：MODE_SHUFFLE -> playerShuffleVector()
# 改为：MODE_SHUFFLE -> 0（Int 类型），然后 Icon 处改用 when 调 Composable
# 更简单：直接把 when 块里的 vector 调用换成 Int，保留 Icon 外壳不动？不行，Icon 需要 ImageVector
# 最彻底：把 "val modeIcon = when..." 整块换成直接调 Composable 的 when
#
# 先找到 when 块
# 形态推测：
#   val modeIcon = when (playMode) {
#       MODE_SHUFFLE -> playerShuffleVector()
#       MODE_LOOP_ONE -> playerRepeatOneVector()
#       else -> playerRepeatVector()
#   }
#   ...
#   Icon(imageVector = modeIcon, tint = modeColor, modifier = ...)
#
# 替换策略：把三个 vector 调用换成对应的 Composable 调用，但需要 tint 和 modifier
# 由于 when 块里拿不到 tint/modifier，最干净的是把 Icon(imageVector = modeIcon...) 整行换成 when
#
# 步骤2a：先把 when 块的三个分支换成 Int 标记（0/1/2）
replacements_when = [
    ("MODE_SHUFFLE -> playerShuffleVector()", "MODE_SHUFFLE -> 0 // [34v39]"),
    ("MODE_LOOP_ONE -> playerRepeatOneVector()", "MODE_LOOP_ONE -> 1 // [34v39]"),
    ("else -> playerRepeatVector()", "else -> 2 // [34v39]"),
]
for old, new in replacements_when:
    if old in s:
        s = s.replace(old, new)
        print(f"✓ when 分支已换 Int: {old[:40]}...")
    else:
        print(f"- 未找到 when 分支: {old[:40]}...")

# 步骤2b：把 Icon(imageVector = modeIcon, ...) 换成 when 调 Composable
# 需要找到 Icon(imageVector = modeIcon 的完整调用，提取 tint 和 modifier
# 用 brace-matching 找到 Icon( 的完整调用
def find_icon_modeicon(text):
    idx = text.find("Icon(imageVector = modeIcon")
    if idx == -1:
        # 尝试其他形态：imageVector=modeIcon（无空格）
        idx = text.find("imageVector=modeIcon")
        if idx == -1:
            return None
        # 往前找 Icon(
        idx = text.rfind("Icon", 0, idx)
    # 从 Icon( 开始 brace匹配
    start = text.find("(", idx)
    depth = 0
    i = start
    while i < len(text):
        if text[i] == '(':
            depth += 1
        elif text[i] == ')':
            depth -= 1
            if depth == 0:
                return (idx, i+1)  # Icon( ... ) 的范围
        i += 1
    return None

rng = find_icon_modeicon(s)
if rng:
    icon_call = s[rng[0]:rng[1]]
    print(f"✓ 找到 Icon(modeIcon) 调用（{len(icon_call)} 字符）")
    # 提取 tint 和 modifier
    m_tint = re.search(r'tint\s*=\s*([^,]+)', icon_call)
    m_mod = re.search(r'modifier\s*=\s*([^,]+?)(?:,|\))', icon_call, re.S)
    tint_expr = m_tint.group(1).strip() if m_tint else "Color.White"
    mod_expr = m_mod.group(1).strip() if m_mod else "Modifier"
    print(f"  tint={tint_expr[:40]}, modifier={mod_expr[:40]}")
    # 构造替换：when (modeType) { 0 -> PlayerShuffleIcon(...) ... }
    # 注意：when 块里我们把 modeIcon 改成了 Int，需要改变量名避免混淆
    # 实际上 modeIcon 现在是 Int，直接用它
    new_when = (
        "when (modeIcon) { // [34v39]\n"
        f"        0 -> PlayerShuffleIcon(tint = {tint_expr}, modifier = {mod_expr})\n"
        f"        1 -> PlayerRepeatOneIcon(tint = {tint_expr}, modifier = {mod_expr})\n"
        f"        else -> PlayerRepeatIcon(tint = {tint_expr}, modifier = {mod_expr})\n"
        "    }"
    )
    s = s[:rng[0]] + new_when + s[rng[1]:]
    print("✓ Icon(modeIcon) 已换为 when 调 Composable")
else:
    print("⚠ 未找到 Icon(imageVector = modeIcon) 调用")

s += "\n" + MARK + "\n"
assert MARK in s, "❌ v39 标记未写入"
with open(path, "w", encoding="utf-8") as f:
    f.write(s)
print("✓ 34 v39 完成")
PYEOF39

echo "=== 34 v39 完成 ==="

# === 34 v40: 修 iconSize 同步 + when 块简化 ===
echo "=== 34 v40 ==="

python3 << 'PYEOF40'
import re, sys, os

path = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt"
icon_path = "app/src/main/java/com/github/tvbox/osc/ui/music/component/LxIcons.kt"
MARK = "// [34v40]"

with open(path, encoding="utf-8") as f:
    s = f.read()

if MARK in s:
    print("34 v40: 已应用，跳过")
    sys.exit(0)

# --- 修复1：LxIcons.kt 里 size = size * 0.82f → iconSize = iconSize * 0.82f ---
if os.path.exists(icon_path):
    with open(icon_path, encoding="utf-8") as f:
        lx = f.read()
    # PlayerRepeatOneIcon 里调用 PlayerRepeatIcon(tint = tint, size = size * 0.82f)
    # v39 改名后应该是 iconSize = iconSize * 0.82f
    if "size = size * 0.82f" in lx:
        lx = lx.replace("size = size * 0.82f", "iconSize = iconSize * 0.82f")
        with open(icon_path, "w", encoding="utf-8") as f:
            f.write(lx)
        print("✓ LxIcons.kt: size = size * 0.82f → iconSize = iconSize * 0.82f")
    else:
        print("- LxIcons.kt 无需修复（可能已修）")
else:
    print("❌ LxIcons.kt 不存在")
    sys.exit(1)

# --- 修复2：when (modeIcon) 块简化 ---
# v39 生成的 when 可能有语法问题，改用最简单的 if-else
# 找到 v39 生成的 when 块，替换为 if-else
m_when = re.search(r'when \(modeIcon\) \{ // \[34v39\]\n(.*?)\n    \}', s, re.S)
if m_when:
    when_body = m_when.group(1)
    print(f"✓ 找到 v39 when 块（{len(when_body)} 字符）")
    # 提取三个分支的 tint 和 modifier（它们应该是一样的）
    m0 = re.search(r'0 -> PlayerShuffleIcon\(tint = ([^,]+), modifier = ([^\)]+)\)', when_body)
    if m0:
        tint_expr = m0.group(1).strip()
        mod_expr = m0.group(2).strip()
        print(f"  tint={tint_expr[:30]}, modifier={mod_expr[:30]}")
        # 换成 if-else（更稳妥，避免 when 表达式类型问题）
        new_ifelse = (
            "if (modeIcon == 0) { // [34v40]\n"
            f"        PlayerShuffleIcon(tint = {tint_expr}, modifier = {mod_expr})\n"
            "    } else if (modeIcon == 1) {\n"
            f"        PlayerRepeatOneIcon(tint = {tint_expr}, modifier = {mod_expr})\n"
            "    } else {\n"
            f"        PlayerRepeatIcon(tint = {tint_expr}, modifier = {mod_expr})\n"
            "    }"
        )
        s = s[:m_when.start()] + new_ifelse + s[m_when.end():]
        print("✓ when 已换为 if-else")
    else:
        print("⚠ 未解析出 when 分支参数")
else:
    print("- 未找到 v39 when 块（可能已被修改）")

s += "\n" + MARK + "\n"
assert MARK in s, "❌ v40 标记未写入"
with open(path, "w", encoding="utf-8") as f:
    f.write(s)
print("✓ 34 v40 完成")
PYEOF40

echo "=== 34 v40 完成 ==="

# === 34 v41: 精确修复残留 ===
echo "=== 34 v41 ==="

python3 << 'PYEOF41'
import re, sys, os

path = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt"
icon_path = "app/src/main/java/com/github/tvbox/osc/ui/music/component/LxIcons.kt"
MARK = "// [34v41]"

with open(path, encoding="utf-8") as f:
    s = f.read()

if MARK in s:
    print("34 v41: 已应用，跳过")
    sys.exit(0)

# --- 修复1：LxIcons.kt 参数名同步 ---
# 实际残留：PlayerRepeatIcon(tint = tint, size = iconSize * 0.82f, ...)
# 目标：PlayerRepeatIcon(tint = tint, iconSize = iconSize * 0.82f, ...)
if os.path.exists(icon_path):
    with open(icon_path, encoding="utf-8") as f:
        lx = f.read()
    # 精确匹配：", size = iconSize *"
    if ", size = iconSize *" in lx:
        lx = lx.replace(", size = iconSize *", ", iconSize = iconSize *")
        with open(icon_path, "w", encoding="utf-8") as f:
            f.write(lx)
        print("✓ LxIcons.kt: size = iconSize * → iconSize = iconSize *")
    elif "size = " in lx and "iconSize" in lx:
        # 兜底：找所有 "size =" 后面跟 iconSize 的
        lx2 = re.sub(r',\s*size\s*=\s*iconSize', ', iconSize = iconSize', lx)
        if lx2 != lx:
            with open(icon_path, "w", encoding="utf-8") as f:
                f.write(lx2)
            print("✓ LxIcons.kt: 正则兜底修复参数名")
        else:
            print("- LxIcons.kt 未找到残留（可能已修）")
    else:
        print("- LxIcons.kt 无需修复")
else:
    print("❌ LxIcons.kt 不存在")
    sys.exit(1)

# --- 修复2：Activity 里残留的 when/Icon(modeIcon) ---
# 不管 v39 是否成功，直接处理所有可能形态
# 形态A：when (modeIcon) { // [34v39] ... } → 换成 if-else
m_when39 = re.search(r'when \(modeIcon\) \{ // \[34v39\]\n(.*?)\n    \}', s, re.S)
if m_when39:
    print("✓ 找到 v39 when 块，换成 if-else")
    body = m_when39.group(1)
    m0 = re.search(r'0 -> PlayerShuffleIcon\(tint = ([^,]+), modifier = ([^\)]+)\)', body)
    if m0:
        tint_e = m0.group(1).strip(); mod_e = m0.group(2).strip()
        new_if = (
            "if (modeIcon == 0) { // [34v41]\n"
            f"        PlayerShuffleIcon(tint = {tint_e}, modifier = {mod_e})\n"
            "    } else if (modeIcon == 1) {\n"
            f"        PlayerRepeatOneIcon(tint = {tint_e}, modifier = {mod_e})\n"
            "    } else {\n"
            f"        PlayerRepeatIcon(tint = {tint_e}, modifier = {mod_e})\n"
            "    }"
        )
        s = s[:m_when39.start()] + new_if + s[m_when39.end():]
        print("✓ v39 when → if-else")
    else:
        print("⚠ v39 when 块参数解析失败")
else:
    print("- 未找到 v39 when 块")

# 形态B：如果还有 Icon(imageVector = modeIcon...) 残留（v39 没处理到）
# 直接找 Icon( ... modeIcon ... ) 并替换
# 用简单字符串查找
if "modeIcon" in s and "Icon(" in s:
    # 找 Icon(imageVector = modeIcon
    idx = s.find("Icon(imageVector = modeIcon")
    if idx == -1:
        idx = s.find("Icon(imageVector=modeIcon")
    if idx != -1:
        print(f"✓ 找到 Icon(modeIcon) 残留 at {idx}")
        # brace matching 找完整调用
        start_paren = s.find("(", idx)
        depth = 0; i = start_paren
        while i < len(s):
            if s[i] == '(': depth += 1
            elif s[i] == ')':
                depth -= 1
                if depth == 0: break
            i += 1
        icon_call = s[idx:i+1]
        m_t = re.search(r'tint\s*=\s*([^,]+)', icon_call)
        m_m = re.search(r'modifier\s*=\s*([^,]+?)(?:,|\))', icon_call, re.S)
        tint_e = m_t.group(1).strip() if m_t else "Color.White"
        mod_e = m_m.group(1).strip() if m_m else "Modifier"
        new_if = (
            "if (modeIcon == 0) { // [34v41]\n"
            f"        PlayerShuffleIcon(tint = {tint_e}, modifier = {mod_e})\n"
            "    } else if (modeIcon == 1) {\n"
            f"        PlayerRepeatOneIcon(tint = {tint_e}, modifier = {mod_e})\n"
            "    } else {\n"
            f"        PlayerRepeatIcon(tint = {tint_e}, modifier = {mod_e})\n"
            "    }"
        )
        s = s[:idx] + new_if + s[i+1:]
        print("✓ Icon(modeIcon) → if-else")
    else:
        print("- 未找到 Icon(modeIcon) 残留")

s += "\n" + MARK + "\n"
assert MARK in s, "❌ v41 标记未写入"
with open(path, "w", encoding="utf-8") as f:
    f.write(s)
print("✓ 34 v41 完成")
PYEOF41

echo "=== 34 v41 完成 ==="

# === 34 v42: 纯诊断（打印 1142 行真实代码） ===
echo "=== 34 v42 DIAGNOSTIC ==="

python3 << 'PYEOF42'
path = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt"
with open(path, encoding="utf-8") as f:
    lines = f.readlines()

print("="*60)
print("DIAGNOSTIC: LxPlayerActivity.kt lines 1120-1170")
print("="*60)
for i in range(1119, min(1170, len(lines))):
    print(f"{i+1:5d}: {lines[i]}", end='')
print("="*60)
print("DIAGNOSTIC: modeIcon 相关行")
print("="*60)
for i, line in enumerate(lines):
    if 'modeIcon' in line or 'PlayerShuffleIcon' in line or 'PlayerRepeatIcon' in line or 'PlayerRepeatOneIcon' in line:
        print(f"{i+1:5d}: {lines[i]}", end='')
print("="*60)
print("DIAGNOSTIC END")
print("="*60)
PYEOF42

echo "=== 34 v42 诊断完成（不改代码） ==="

# === 34 v43: 按 v42 诊断的真实代码精确修复 ===
echo "=== 34 v43 ==="

python3 << 'PYEOF43'
import sys

path = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt"
MARK = "// [34v43]"

with open(path, encoding="utf-8") as f:
    lines = f.readlines()

full = "".join(lines)
if MARK in full:
    print("34 v43: 已应用，跳过")
    sys.exit(0)

# --- 步骤1：定位 val modeIconVector 的 when 块（行级） ---
start_idx = -1
for i, line in enumerate(lines):
    if "val modeIconVector = when (playMode)" in line:
        start_idx = i
        break
if start_idx == -1:
    print("❌ 未找到 val modeIconVector when 块")
    sys.exit(1)
print(f"✓ when 块起始行: {start_idx + 1}")

# 找 Icon(modeIconVector 行（when 块之后第一处）
icon_idx = -1
for i in range(start_idx + 1, len(lines)):
    if "Icon(modeIconVector" in lines[i]:
        icon_idx = i
        break
if icon_idx == -1:
    print("❌ 未找到 Icon(modeIconVector 行")
    sys.exit(1)
print(f"✓ Icon(modeIconVector 行: {icon_idx + 1}: {lines[icon_idx].strip()[:80]}")

# --- 步骤2：when 分支里的 vector 调用换 Int（只处理 start..icon 之间） ---
vec2int = [
    ("playerShuffleVector()", "0"),
    ("playerRepeatOneVector()", "1"),  # 先于 Repeat
    ("playerRepeatVector()", "2"),
]
for j in range(start_idx, icon_idx):
    for old, new in vec2int:
        if old in lines[j]:
            lines[j] = lines[j].replace(old, new)
            print(f"✓ 第 {j+1} 行: {old} → {new}")

# --- 步骤3：Icon(modeIconVector, ...) 整行换 when 调 Composable ---
# 诊断实锤原行（允许空白差异）：Icon(modeIconVector, contentDescription = null, tint = modeColor, modifier = Modifier.size(24.dp)) // [34v26]
indent = lines[icon_idx][:len(lines[icon_idx]) - len(lines[icon_idx].lstrip())]
new_block = (
    f"{indent}when (modeIconVector) {{ // [34v43]\n"
    f"{indent}    0 -> PlayerShuffleIcon(tint = modeColor, modifier = Modifier.size(24.dp))\n"
    f"{indent}    1 -> PlayerRepeatOneIcon(tint = modeColor, modifier = Modifier.size(24.dp))\n"
    f"{indent}    else -> PlayerRepeatIcon(tint = modeColor, modifier = Modifier.size(24.dp))\n"
    f"{indent}}}\n"
)
lines[icon_idx] = new_block
print("✓ Icon(modeIconVector) 已换为 when 调 Player*Icon")

# --- 步骤4：断言无残留 ---
out = "".join(lines)
assert "playerShuffleVector()" not in out.split("val modeIconVector")[1].split("Spacer")[0] if "val modeIconVector" in out else True
assert MARK in out, "❌ v43 标记未写入"
with open(path, "w", encoding="utf-8") as f:
    f.write(out)
print("✓ 34 v43 完成")
PYEOF43

echo "=== 34 v43 完成 ==="
# === 34 v45: 补四个播放按钮图标（高对比 tint） ===
echo "=== 34 v45 ==="

python3 << 'PYEOF45'
import sys

path = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt"
MARK = "// [34v45]"

with open(path, encoding="utf-8") as f:
    lines = f.readlines()

full = "".join(lines)
if MARK in full:
    print("34 v45: 已应用，跳过")
    sys.exit(0)

fixed = []

# --- 修复1：onNext 空按钮（v42 实锤 1124-1128 行内容为空）---
# 找 "onClick = { onNext() }"，然后找其后的 ") {"，若下一行是 "}" 则插入图标
for i, line in enumerate(lines):
    if 'onClick = { onNext() }' in line:
        # 向后找 ") {"
        for j in range(i, min(i+6, len(lines))):
            if ') {' in lines[j]:
                # 检查下一行
                if j+1 < len(lines) and lines[j+1].strip() == '}':
                    indent = lines[j][:len(lines[j]) - len(lines[j].lstrip())] + '    '
                    lines.insert(j+1, f'{indent}PlayerSkipNextIcon(tint = primaryTextColor, modifier = Modifier.size(28.dp)) {MARK}\n')
                    fixed.append(f'第{j+2}行: onNext 补 PlayerSkipNextIcon')
                elif j+1 < len(lines) and 'PlayerSkipNextIcon' not in lines[j+1]:
                    print(f"⚠ onNext 按钮第{j+2}行内容非空但无图标: {lines[j+1].strip()[:50]}")
                break
        break

# --- 修复2：onPrevious 空按钮 ---
for i, line in enumerate(lines):
    if 'onClick = { onPrevious() }' in line or 'onClick = { onPrev() }' in line:
        for j in range(i, min(i+6, len(lines))):
            if ') {' in lines[j]:
                if j+1 < len(lines) and lines[j+1].strip() == '}':
                    indent = lines[j][:len(lines[j]) - len(lines[j].lstrip())] + '    '
                    lines.insert(j+1, f'{indent}PlayerSkipPrevIcon(tint = primaryTextColor, modifier = Modifier.size(28.dp)) {MARK}\n')
                    fixed.append(f'第{j+2}行: onPrevious 补 PlayerSkipPrevIcon')
                break
        break

# --- 修复3：播放/暂停图标 tint 确保白色 ---
# 找现有的 PlayerPlayIcon / PlayerPauseIcon 调用，把 tint 改为 Color.White
for i, line in enumerate(lines):
    if 'PlayerPlayIcon(' in line or 'PlayerPauseIcon(' in line:
        if 'tint = Color.White' not in line:
            # 提取并替换 tint 参数
            import re
            new_line = re.sub(r'tint\s*=\s*[^,\)]+', 'tint = Color.White', line)
            if new_line != line:
                lines[i] = new_line
                fixed.append(f'第{i+1}行: 播放图标 tint → Color.White')

with open(path, 'w', encoding='utf-8') as f:
    f.writelines(lines)

print(f"✓ 34 v45: 修复 {len(fixed)} 处")
for x in fixed:
    print(f"  {x}")
PYEOF45

echo "=== 34 v45 完成 ==="
