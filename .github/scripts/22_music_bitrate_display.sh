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

# ===== v10：bitrate 细档位 =====
python3 << 'PYEOF'
import sys

path = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt"
with open(path, encoding="utf-8") as f:
    src = f.read()

MARK = "// [v10] bitrate detail tier"
if MARK in src:
    print("跳过（已是 v10）")
    sys.exit(0)

# 找到 bitrate 分支的老格式
OLD = '''                            bitrate > 0 -> "${LxPlayerManager.qualityLabel(currentQuality)} · ${bitrate}kbps"'''

NEW = '''                            // [v10] bitrate detail tier：bitrate 分支也用细档位
                            bitrate > 0 -> {
                                val lblB = when {
                                    bitrate >= 1000 -> "无损"
                                    bitrate >= 800 -> "Hi-Res"
                                    bitrate >= 500 -> "SQ"
                                    bitrate >= 320 -> "HQ"
                                    else -> "标准"
                                }
                                val susB = (currentQuality == "flac" && bitrate < 500) || (currentQuality in listOf("flac24bit", "hires") && bitrate < 800) || (currentQuality in listOf("atmos", "atmos_plus") && bitrate < 800) || (currentQuality == "master" && bitrate < 1000)
                                if (susB) "$lblB · ${bitrate}kbps ⚠" else "$lblB · ${bitrate}kbps"
                            }'''

if OLD in src:
    src = src.replace(OLD, NEW, 1)
    with open(path, "w", encoding="utf-8") as f:
        f.write(src)
    print("v10：bitrate 分支已用细档位")
else:
    print("错误：未找到 bitrate 分支锚点")
    sys.exit(1)
PYEOF
# ===== v10 结束 =====
