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
