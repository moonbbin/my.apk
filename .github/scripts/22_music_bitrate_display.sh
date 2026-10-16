#!/bin/bash
# 22 - 播放页音质徽标 v5：Hi-Res 可疑检测
# v5：在 v4.2 基础上新增 Hi-Res 档位的假无损检测——hires/master/atmos 等高音质
#     若实测码率过低也标 ⚠（hires<800kbps，master/atmos<1000kbps）。
#     与 21 v5 的档位映射（4=母带）配套。
set -e
cd avbox

echo "=== 播放页音质徽标 v5 ==="

python3 << 'PYEOF'
import sys

path = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt"
with open(path, encoding="utf-8") as f:
    src = f.read()

MARK_V5 = "// 验货实测优先显示（22）+ v5 Hi-Res 自诊断"
MARK_V42 = "// 验货实测优先显示（22）+ v4.2 内联自诊断"
if MARK_V5 in src:
    print("跳过（已是 v5）: " + path)
    raise SystemExit(0)

# v5 最终形态：内联判断，含 Hi-Res 档位
v5_block = """                        // 验货实测优先显示（22）+ v5 Hi-Res 自诊断：假无损警告
                        text = when {
                            measuredBitrate > 0 -> {
                                val lbl = LxPlayerManager.qualityLabel(currentQuality)
                                val sus = (currentQuality == "flac" && measuredBitrate < 500) || (currentQuality in listOf("flac24bit", "hires") && measuredBitrate < 800) || (currentQuality in listOf("master", "atmos", "atmos_plus") && measuredBitrate < 1000)
                                if (sus) "$lbl · 实测约${measuredBitrate}kbps ⚠" else "$lbl · 实测约${measuredBitrate}kbps"
                            }
                            bitrate > 0 -> {
                                val lbl = LxPlayerManager.qualityLabel(currentQuality)
                                val sus = (currentQuality == "flac" && bitrate < 500) || (currentQuality in listOf("flac24bit", "hires") && bitrate < 800) || (currentQuality in listOf("master", "atmos", "atmos_plus") && bitrate < 1000)
                                if (sus) "$lbl · ${bitrate}kbps ⚠" else "$lbl · ${bitrate}kbps"
                            }
                            else -> LxPlayerManager.qualityLabel(currentQuality)
                        },"""

if MARK_V42 in src:
    print("检测到 v4.2，增量升级 → v5（Hi-Res 检测）")
    # 替换 v4.2 块为 v5 块：找到 MARK_V42 到块结束
    start = src.find(MARK_V42)
    # v4.2 块以 "}," 结尾
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
                src = src.replace(old_block, v5_block, 1)
                break
        i += 1
    print("v4.2 → v5 替换完成")
else:
    print("错误: 未找到 v4.2 标记，无法升级到 v5。请先打 v4.2。")
    sys.exit(1)

with open(path, "w", encoding="utf-8") as f:
    f.write(src)
print("v5 完成: " + path)
PYEOF

echo "=== 完成 ==="
