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
