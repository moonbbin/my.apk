#!/bin/bash
# 22 - 播放页音质徽标 v6：全档位中文标签 + 可疑检测
# v6：在 v5 基础上新增——徽章显示中文标签（master→母带、atmos_plus→全景声+、
#     atmos→全景声、hires→Hi-Res），不再显示英文原名；
#     可疑检测覆盖全档位（master<1000、atmos系<800、hires/flac24bit<800、flac<500）。
#     与 21 v6 的 7 档映射（6=母带 5=全景声+ 4=全景声 3=Hi-Res 2=FLAC 1=320k 0=普通）配套。
set -e
cd avbox

echo "=== 播放页音质徽标 v6 ==="

python3 << 'PYEOF'
import sys

path = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt"
with open(path, encoding="utf-8") as f:
    src = f.read()

MARK_V6 = "// 验货实测优先显示（22）+ v6 全档位中文标签"
MARK_V5 = "// 验货实测优先显示（22）+ v5 Hi-Res 自诊断"
MARK_V42 = "// 验货实测优先显示（22）+ v4.2 内联自诊断"
if MARK_V6 in src:
    print("跳过（已是 v6）: " + path)
    raise SystemExit(0)

# v6 最终形态：中文标签 + 全档位可疑检测
v6_block = """                        // 验货实测优先显示（22）+ v6 全档位中文标签：假无损警告
                        text = when {
                            measuredBitrate > 0 -> {
                                val rawLbl = LxPlayerManager.qualityLabel(currentQuality)
                                // 中文标签映射（v6）：英文原名→中文
                                val lbl = when (currentQuality) {
                                    "master" -> "母带"
                                    "atmos_plus" -> "全景声+"
                                    "atmos" -> "全景声"
                                    "hires" -> "Hi-Res"
                                    else -> rawLbl
                                }
                                val sus = (currentQuality == "flac" && measuredBitrate < 500) || (currentQuality in listOf("flac24bit", "hires") && measuredBitrate < 800) || (currentQuality in listOf("atmos", "atmos_plus") && measuredBitrate < 800) || (currentQuality == "master" && measuredBitrate < 1000)
                                if (sus) "$lbl · 实测约${measuredBitrate}kbps ⚠" else "$lbl · 实测约${measuredBitrate}kbps"
                            }
                            bitrate > 0 -> {
                                val rawLbl = LxPlayerManager.qualityLabel(currentQuality)
                                val lbl = when (currentQuality) {
                                    "master" -> "母带"
                                    "atmos_plus" -> "全景声+"
                                    "atmos" -> "全景声"
                                    "hires" -> "Hi-Res"
                                    else -> rawLbl
                                }
                                val sus = (currentQuality == "flac" && bitrate < 500) || (currentQuality in listOf("flac24bit", "hires") && bitrate < 800) || (currentQuality in listOf("atmos", "atmos_plus") && bitrate < 800) || (currentQuality == "master" && bitrate < 1000)
                                if (sus) "$lbl · ${bitrate}kbps ⚠" else "$lbl · ${bitrate}kbps"
                            }
                            else -> {
                                val rawLbl = LxPlayerManager.qualityLabel(currentQuality)
                                when (currentQuality) {
                                    "master" -> "母带"
                                    "atmos_plus" -> "全景声+"
                                    "atmos" -> "全景声"
                                    "hires" -> "Hi-Res"
                                    else -> rawLbl
                                }
                            }
                        },"""

if MARK_V5 in src:
    print("检测到 v5，增量升级 → v6（中文标签）")
    start = src.find(MARK_V5)
    idx = src.find("text = when {", start)
    depth = 0
    i = src.find("{", idx)
    while i < len(src):
        if src[i] == "{":
            depth += 1
        elif src[i] == "}":
            depth -= 1
            if depth == 0:
                end = src.find(",", i) + 1
                old_block = src[start:end]
                src = src.replace(old_block, v6_block, 1)
                break
        i += 1
    print("v5 → v6 替换完成")
elif MARK_V42 in src:
    # v4.2 → v6：先升到 v5 形态，再套 v6 中文标签
    print("检测到 v4.2，升级 → v6")
    # v4.2 的块结构与 v5 相同，直接替换为 v6
    start = src.find(MARK_V42)
    idx = src.find("text = when {", start)
    depth = 0
    i = src.find("{", idx)
    while i < len(src):
        if src[i] == "{":
            depth += 1
        elif src[i] == "}":
            depth -= 1
            if depth == 0:
                end = src.find(",", i) + 1
                old_block = src[start:end]
                src = src.replace(old_block, v6_block, 1)
                break
        i += 1
    print("v4.2 → v6 完成")
else:
    # 全新文件：直接打 v6（兼容 v1_old / v1_new_old 两种锚点）
    v1_old = """                        text = when {
                            bitrate > 0 -> "${LxPlayerManager.qualityLabel(currentQuality)} · ${bitrate}kbps"
                            measuredBitrate > 0 -> "${LxPlayerManager.qualityLabel(currentQuality)} · 实测约${measuredBitrate}kbps"
                            else -> LxPlayerManager.qualityLabel(currentQuality)
                        },"""
    v1_new_old = """                        // 验货实测优先显示（22）：v2 测出的真实码率优先于 ExoPlayer track 估算值
                        text = when {
                            measuredBitrate > 0 -> "${LxPlayerManager.qualityLabel(currentQuality)} · 实测约${measuredBitrate}kbps"
                            bitrate > 0 -> "${LxPlayerManager.qualityLabel(currentQuality)} · ${bitrate}kbps"
                            else -> LxPlayerManager.qualityLabel(currentQuality)
                        },"""
    if v1_old in src:
        print("全新文件，直接打 v6")
        src = src.replace(v1_old, v6_block, 1)
    elif v1_new_old in src:
        print("检测到 v1，升级 → v6")
        src = src.replace(v1_new_old, v6_block, 1)
    else:
        print("错误: v6 锚点未命中")
        sys.exit(1)

with open(path, "w", encoding="utf-8") as f:
    f.write(src)
print("v6 完成: " + path)
PYEOF

echo "=== 完成 ==="

# ===== v7：切歌清歌词 =====
python3 << 'PYEOF'
import sys

path = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt"
with open(path, encoding="utf-8") as f:
    src = f.read()

MARK = "// [v7] clear lyric on title change"
if MARK in src:
    print("跳过（已是 v7）")
    sys.exit(0)

# 在 LaunchedEffect(lyricKey) 后面加一个按 title 触发的清空
OLD = '''    LaunchedEffect(lyricKey) {
        lyricLines = emptyList()'''

NEW = '''    // [v7] clear lyric on title change：title 变就清空歌词，防止残留
    LaunchedEffect(title) {
        lyricLines = emptyList()
    }
    LaunchedEffect(lyricKey) {
        lyricLines = emptyList()'''

if OLD in src:
    src = src.replace(OLD, NEW, 1)
    with open(path, "w", encoding="utf-8") as f:
        f.write(src)
    print("v7：已加 title 变化清歌词")
else:
    print("错误：未找到 LaunchedEffect(lyricKey) 锚点")
    sys.exit(1)
PYEOF
# ===== v7 结束 =====

# ===== v8：实测档位徽章 =====
python3 << 'PYEOF'
import sys

path = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt"
with open(path, encoding="utf-8") as f:
    src = f.read()

MARK = "// [v8] detail tier by measured bitrate"
if MARK in src:
    print("跳过（已是 v8）")
    sys.exit(0)

# 找到 v6 的徽章 text 逻辑，在前面插入细档位映射
# v6 的格式是：text = when { measuredBitrate > 0 -> { ... } ... }
# 我们在 measuredBitrate > 0 的分支里，把 lbl 的计算换成按码率的细档位

OLD_LBL = '''                                val lbl = when (currentQuality) {
                                    "master" -> "母带"
                                    "atmos_plus" -> "全景声+"
                                    "atmos" -> "全景声"
                                    "hires" -> "Hi-Res"
                                    else -> rawLbl
                                }'''

NEW_LBL = '''                                // [v8] detail tier by measured bitrate：按实测码率给细档位
                                val lbl = when {
                                    measuredBitrate >= 1000 -> "无损"
                                    measuredBitrate >= 800 -> "Hi-Res"
                                    measuredBitrate >= 500 -> "SQ"
                                    measuredBitrate >= 320 -> "HQ"
                                    measuredBitrate > 0 -> "标准"
                                    else -> when (currentQuality) {
                                        "master" -> "母带"
                                        "atmos_plus" -> "全景声+"
                                        "atmos" -> "全景声"
                                        "hires" -> "Hi-Res"
                                        else -> rawLbl
                                    }
                                }'''

if OLD_LBL in src:
    src = src.replace(OLD_LBL, NEW_LBL, 1)
    with open(path, "w", encoding="utf-8") as f:
        f.write(src)
    print("v8：徽章已按实测码率分档")
else:
    print("错误：未找到 v6 lbl 锚点")
    sys.exit(1)
PYEOF
# ===== v8 结束 =====

# ===== v9：24-bit/母带细分 =====
python3 << 'PYEOF'
import sys

path = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt"
with open(path, encoding="utf-8") as f:
    src = f.read()

MARK = "// [v9] 24-bit/master detail"
if MARK in src:
    print("跳过（已是 v9）")
    sys.exit(0)

OLD = '''                                // [v8] detail tier by measured bitrate：按实测码率给细档位
                                val lbl = when {
                                    measuredBitrate >= 1000 -> "无损"
                                    measuredBitrate >= 800 -> "Hi-Res"
                                    measuredBitrate >= 500 -> "SQ"
                                    measuredBitrate >= 320 -> "HQ"
                                    measuredBitrate > 0 -> "标准"
                                    else -> when (currentQuality) {
                                        "master" -> "母带"
                                        "atmos_plus" -> "全景声+"
                                        "atmos" -> "全景声"
                                        "hires" -> "Hi-Res"
                                        else -> rawLbl
                                    }
                                }'''

NEW = '''                                // [v9] 24-bit/master detail：v15 保证被 master 系接受的必为 24-bit
                                val lbl = when {
                                    // 24-bit 系：按请求音质+码率细分
                                    currentQuality in listOf("master", "hires", "flac24bit", "atmos", "atmos_plus") && measuredBitrate >= 1800 -> "母带"
                                    currentQuality in listOf("master", "hires", "flac24bit", "atmos", "atmos_plus") && measuredBitrate >= 1000 -> "24-bit"
                                    currentQuality in listOf("master", "hires", "flac24bit", "atmos", "atmos_plus") && measuredBitrate > 0 -> "Hi-Res"
                                    // 16-bit 系：按码率分档（v8）
                                    measuredBitrate >= 1000 -> "无损"
                                    measuredBitrate >= 800 -> "Hi-Res"
                                    measuredBitrate >= 500 -> "SQ"
                                    measuredBitrate >= 320 -> "HQ"
                                    measuredBitrate > 0 -> "标准"
                                    else -> when (currentQuality) {
                                        "master" -> "母带"
                                        "atmos_plus" -> "全景声+"
                                        "atmos" -> "全景声"
                                        "hires" -> "Hi-Res"
                                        else -> rawLbl
                                    }
                                }'''

if OLD in src:
    src = src.replace(OLD, NEW, 1)
    with open(path, "w", encoding="utf-8") as f:
        f.write(src)
    print("v9：已替换为 24-bit 细分逻辑")
else:
    print("错误：未找到 v8 lbl 块")
    sys.exit(1)
PYEOF
# ===== v9 结束 =====

# ===== v10：bitrate 细档位（修复版） =====
python3 << 'PYEOF'
import sys

path = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt"
with open(path, encoding="utf-8") as f:
    src = f.read()

MARK = "// [v10] bitrate detail tier"
if MARK in src:
    print("跳过（已是 v10）")
    sys.exit(0)

# v6 的 bitrate 块格式
OLD = '''                            bitrate > 0 -> {
                                val rawLbl = LxPlayerManager.qualityLabel(currentQuality)
                                val lbl = when (currentQuality) {
                                    "master" -> "母带"
                                    "atmos_plus" -> "全景声+"
                                    "atmos" -> "全景声"
                                    "hires" -> "Hi-Res"
                                    else -> rawLbl
                                }'''

NEW = '''                            // [v10] bitrate detail tier
                            bitrate > 0 -> {
                                val rawLbl = LxPlayerManager.qualityLabel(currentQuality)
                                val lbl = when {
                                    bitrate >= 1000 -> "无损"
                                    bitrate >= 800 -> "Hi-Res"
                                    bitrate >= 500 -> "SQ"
                                    bitrate >= 320 -> "HQ"
                                    bitrate > 0 -> "标准"
                                    else -> when (currentQuality) {
                                        "master" -> "母带"
                                        "atmos_plus" -> "全景声+"
                                        "atmos" -> "全景声"
                                        "hires" -> "Hi-Res"
                                        else -> rawLbl
                                    }
                                }'''

if OLD in src:
    src = src.replace(OLD, NEW, 1)
    with open(path, "w", encoding="utf-8") as f:
        f.write(src)
    print("v10 修复版：已应用")
else:
    print("错误：未找到 v6 bitrate 块")
    sys.exit(1)
PYEOF
# ===== v10 结束 =====

# ===== v11：徽章可见性修复（修正版） =====
python3 << 'PYEOF'
import sys

path = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt"
with open(path, encoding="utf-8") as f:
    src = f.read()

MARK = "// [v11] badge visible by title"
if MARK in src:
    print("跳过（已是 v11）")
    sys.exit(0)

OLD = "            if (currentQuality.isNotEmpty()) {"
NEW = """            // [v11] badge visible by title：用 title 判断，避免重建时 quality 短暂为空导致徽章消失
            if (currentQuality.isNotEmpty() || title.isNotEmpty()) {"""

if OLD in src:
    src = src.replace(OLD, NEW, 1)
    with open(path, "w", encoding="utf-8") as f:
        f.write(src)
    print("v11 修正版：已应用（复用 title 变量）")
else:
    print("错误：未找到徽章可见锚点")
    sys.exit(1)
PYEOF
# ===== v11 结束 =====

# ===== v12：有数据才显示 =====
python3 << 'PYEOF'
import sys

path = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt"
with open(path, encoding="utf-8") as f:
    src = f.read()

MARK = "// [v12]"
if MARK in src:
    print("跳过（已是 v12）")
    sys.exit(0)

# 找到 v11 的 if，替换为有数据判断
# v11 修正版是：if (currentQuality.isNotEmpty() || title.isNotEmpty()) {
OLD = "            if (currentQuality.isNotEmpty() || title.isNotEmpty()) {"
NEW = """            // [v12] 有数据才显示：避免空框
            val hasBadgeData = currentQuality.isNotEmpty() || measuredBitrate > 0 || bitrate > 0
            if (hasBadgeData) {"""

if OLD in src:
    src = src.replace(OLD, NEW, 1)
    with open(path, "w", encoding="utf-8") as f:
        f.write(src)
    print("v12：已改为有数据才显示")
else:
    print("错误：未找到锚点")
    sys.exit(1)
PYEOF
# ===== v12 结束 =====

# ===== v13：虚标拦截（探针侧判定）+ F 串临时上屏 =====
# 探针（21 v31）判定自报参数物理不可能时置 probeSuspect：徽章显示「格式名 · 虚标⚠」，不显示假数。
# [临时诊断] probeDbg 的 F 串后缀挂在实测文案后、Text 放开 maxLines=2，定性后随收敛版撤除。
python3 << 'PYEOF22V13'
import sys

path = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt"
MARK = "// [22v13]"

with open(path, encoding="utf-8") as f:
    c = f.read()

if MARK in c:
    print("跳过（已是 v13）")
    sys.exit(0)

# 1) 收集 probeSuspect / probeDbg（锚：原版 measuredBitrate 收集行）
anchor = "    val measuredBitrate by LxPlayerManager.measuredBitrate.collectAsState()"
if c.count(anchor) != 1:
    print(f"X v13 收集锚点计数异常: {c.count(anchor)}")
    sys.exit(1)
c = c.replace(anchor, anchor + "\n    val probeSuspect by LxPlayerManager.probeSuspect.collectAsState() // [22v13]\n    val probeDbg by LxPlayerManager.probeDbg.collectAsState() // [22v13][临时诊断]", 1)
print("  OK probeSuspect/probeDbg 收集")

# 2) 徽章区行级手术（hasBadgeData 起 120 行窗口内定位）
lines = c.split("\n")
base = -1
for i, l in enumerate(lines):
    if "val hasBadgeData" in l:
        base = i
        break
if base == -1:
    print("X v13 未找到 hasBadgeData")
    sys.exit(1)
win_end = min(len(lines), base + 120)
comment_i = sus_i = color_i = -1
for i in range(base, win_end):
    if "验货实测优先显示" in lines[i]:
        comment_i = i
    if 'if (sus) "$lbl · 实测约' in lines[i]:
        if sus_i != -1:
            print("X v13 sus 行不唯一")
            sys.exit(1)
        sus_i = i
    if sus_i != -1 and color_i == -1 and "color = musicColors().accent.copy(alpha = 0.8f)," in lines[i]:
        color_i = i
if comment_i == -1 or sus_i == -1 or color_i == -1:
    print(f"X v13 徽章区定位失败: comment={comment_i} sus={sus_i} color={color_i}")
    sys.exit(1)
text_i = comment_i - 1
if "Text(" not in lines[text_i]:
    print("X v13 comment 上一行不是 Text(")
    sys.exit(1)

def indent_of(line):
    return line[:len(line) - len(line.lstrip())]

# 2c) maxLines=2（先插最下方，保持上方行号不变）
lines.insert(color_i + 1, indent_of(lines[color_i]) + "maxLines = 2, // [22v13][临时诊断]")
print("  OK maxLines=2")
# 2b) sus 文案行替换（虚标拦截优先，实测文案挂 F 串后缀）
ind = indent_of(lines[sus_i])
lines[sus_i] = ind + 'if (probeSuspect) "$rawLbl · 虚标⚠$dbgSuffix" else if (sus) "$lbl · 实测约${measuredBitrate}kbps ⚠$dbgSuffix" else "$lbl · 实测约${measuredBitrate}kbps$dbgSuffix" // [22v13]'
print("  OK 虚标拦截文案")
# 2a) dbgSuffix 定义（插在 Text( 之前）
lines.insert(text_i, indent_of(lines[text_i]) + 'val dbgSuffix = if (probeDbg.isNotEmpty()) " [$probeDbg]" else "" // [22v13][临时诊断]')
print("  OK dbgSuffix 定义")

c = "\n".join(lines)
assert MARK in c and "probeSuspect" in c and "dbgSuffix" in c
with open(path, "w", encoding="utf-8") as f:
    f.write(c)
print("v13：虚标拦截已应用")
PYEOF22V13

# ===== v13 结束 =====

# ===== v14：解锁无损以上档位（位深钥匙、顶格 24-bit）+ 撤临时诊断 =====
# 背景（979bf796 装机实证）：源站全员升频模板（96/24 壳 ~3600kbps、192/24 壳 5392），文件参数自洽、
# 内容出身验不了；徽章旧阶梯的 24-bit 系分支钥匙是 currentQuality 的档位名，而探针接线时把它改写成
# 格式名 "flac"，导致真 24-bit 文件（probeTier=3）也永远卡在「无损」。
# 本版：① 实测分支的 24-bit 系条件并入 probeTier>=3（文件自报位深为准）；② 顶格词「母带」全徽章
# 退役、统一改「24-bit」（只描述文件本身，不替源站认母带出身，用户 2026-10-20 定）；
# ③ 撤除 v13 的 [临时诊断]：probeDbg 收集、dbgSuffix 定义与三处 $dbgSuffix 引用、maxLines=2 全删。
python3 << 'PYEOF22V14'
import sys

path = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt"
MARK = "// [22v14]"

with open(path, encoding="utf-8") as f:
    c = f.read()

if MARK in c:
    print("跳过（已是 v14）")
    sys.exit(0)

# 前置断言：v13 产物必须齐全（虚标行 + 三处临时诊断）
need_once = [
    "val probeSuspect by LxPlayerManager.probeSuspect.collectAsState() // [22v13]",
    "val probeDbg by LxPlayerManager.probeDbg.collectAsState() // [22v13][临时诊断]",
    'val dbgSuffix = if (probeDbg.isNotEmpty()) " [$probeDbg]" else "" // [22v13][临时诊断]',
    "maxLines = 2, // [22v13][临时诊断]",
    'if (probeSuspect) "$rawLbl · 虚标⚠$dbgSuffix" else if (sus) "$lbl · 实测约${measuredBitrate}kbps ⚠$dbgSuffix" else "$lbl · 实测约${measuredBitrate}kbps$dbgSuffix" // [22v13]',
]
for need in need_once:
    if c.count(need) != 1:
        print(f"X v14 前置(v13 产物)计数异常: {c.count(need)} <- {need[:50]}")
        sys.exit(1)
print("  OK 前置 v13 产物齐全")

# 1) 收集 probeTier（位深钥匙），锚：v13 的 probeSuspect 收集行
anchor = "    val probeSuspect by LxPlayerManager.probeSuspect.collectAsState() // [22v13]"
c = c.replace(anchor, anchor + "\n    val probeTier by LxPlayerManager.probeTier.collectAsState() // [22v14]", 1)
print("  OK probeTier 收集")

# 2) 虚标/实测文案行：剥掉三处 $dbgSuffix（标记换 v14）
old_sus = 'if (probeSuspect) "$rawLbl · 虚标⚠$dbgSuffix" else if (sus) "$lbl · 实测约${measuredBitrate}kbps ⚠$dbgSuffix" else "$lbl · 实测约${measuredBitrate}kbps$dbgSuffix" // [22v13]'
new_sus = 'if (probeSuspect) "$rawLbl · 虚标⚠" else if (sus) "$lbl · 实测约${measuredBitrate}kbps ⚠" else "$lbl · 实测约${measuredBitrate}kbps" // [22v14]'
c = c.replace(old_sus, new_sus, 1)
print("  OK 文案行去诊断后缀")

# 3) 整行删除三处临时诊断（probeDbg 收集 / dbgSuffix 定义 / maxLines）
drop_strips = [
    "val probeDbg by LxPlayerManager.probeDbg.collectAsState() // [22v13][临时诊断]",
    'val dbgSuffix = if (probeDbg.isNotEmpty()) " [$probeDbg]" else "" // [22v13][临时诊断]',
    "maxLines = 2, // [22v13][临时诊断]",
]
lines = c.split("\n")
for ds in drop_strips:
    before = len(lines)
    lines = [l for l in lines if l.strip() != ds]
    if before - len(lines) != 1:
        print(f"X v14 诊断行删除数异常: {before - len(lines)} <- {ds[:50]}")
        sys.exit(1)
    print(f"  OK 删除诊断行: {ds[:44]}")
c = "\n".join(lines)

# 4) 解锁：实测分支 24-bit 系三条条件并入 probeTier>=3（钥匙从档位名换成文件自报位深）
old_cond = 'currentQuality in listOf("master", "hires", "flac24bit", "atmos", "atmos_plus") && measuredBitrate'
if c.count(old_cond) != 3:
    print(f"X v14 24-bit 系条件计数异常: {c.count(old_cond)}（应为 3）")
    sys.exit(1)
c = c.replace(old_cond, '(currentQuality in listOf("master", "hires", "flac24bit", "atmos", "atmos_plus") || probeTier >= 3) && measuredBitrate')
print("  OK 24-bit 系条件并入 probeTier>=3 ×3")

# 5) 顶格词退役：「母带」→「24-bit」（全徽章 4 处：实测≥1800 / 实测兜底 / 估算兜底 / 无数据兜底）
if c.count('"母带"') != 4:
    print(f"X v14 「母带」计数异常: {c.count(chr(34) + '母带' + chr(34))}（应为 4）")
    sys.exit(1)
c = c.replace('"母带"', '"24-bit"')
print("  OK 「母带」→「24-bit」 ×4")

# 终检
assert MARK in c
assert "probeDbg" not in c, "probeDbg 残留"
assert "$dbgSuffix" not in c, "$dbgSuffix 残留"
assert "[临时诊断]" not in c, "[临时诊断] 残留"
assert '"母带"' not in c, "「母带」残留"
assert c.count("val probeTier by LxPlayerManager.probeTier.collectAsState() // [22v14]") == 1
assert c.count("|| probeTier >= 3) && measuredBitrate") == 3
assert c.count("val probeSuspect by LxPlayerManager.probeSuspect.collectAsState() // [22v13]") == 1
with open(path, "w", encoding="utf-8") as f:
    f.write(c)
print("v14：解锁无损以上（顶格 24-bit）+ 撤临时诊断 已应用")
PYEOF22V14

# ===== v14 结束 =====
