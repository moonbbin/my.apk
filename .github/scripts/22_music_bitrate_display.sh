#!/bin/bash
# 22 - 播放页音质徽标：验货实测码率优先显示 + v4 自诊断
# v4：在徽标 when 分支中加入假无损自诊断，FLAC 但码率过低时显示 ⚠ 警告
# 幂等：已打过 v4 则跳过；需要先打 22 v1；锚点未命中则报错退出。
set -e
cd avbox

echo "=== 播放页音质徽标 v4：自诊断 ==="

python3 << 'PYEOF'
import sys

path = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt"
with open(path, encoding="utf-8") as f:
    src = f.read()

MARK_V4 = "// 验货实测优先显示（22）+ v4 自诊断"
if MARK_V4 in src:
    print("跳过（已是 v4）: " + path)
    raise SystemExit(0)

v4_old = "                        // 验货实测优先显示（22）：v2 测出的真实码率优先于 ExoPlayer track 估算值"
if v4_old not in src:
    print("错误: v4 锚点未命中（需要先打 22 v1 补丁）")
    sys.exit(1)

old_block = """                        // 验货实测优先显示（22）：v2 测出的真实码率优先于 ExoPlayer track 估算值
                        text = when {
                            measuredBitrate > 0 -> "${LxPlayerManager.qualityLabel(currentQuality)} · 实测约${measuredBitrate}kbps"
                            bitrate > 0 -> "${LxPlayerManager.qualityLabel(currentQuality)} · ${bitrate}kbps"
                            else -> LxPlayerManager.qualityLabel(currentQuality)
                        },"""

new_block = """                        // 验货实测优先显示（22）+ v4 自诊断：假无损警告
                        text = when {
                            measuredBitrate > 0 -> {
                                val lbl = LxPlayerManager.qualityLabel(currentQuality)
                                if (LxPlayerManager.isSuspiciousLossless(currentQuality, measuredBitrate)) "$lbl · 实测约${measuredBitrate}kbps ⚠" else "$lbl · 实测约${measuredBitrate}kbps"
                            }
                            bitrate > 0 -> {
                                val lbl = LxPlayerManager.qualityLabel(currentQuality)
                                if (LxPlayerManager.isSuspiciousLossless(currentQuality, bitrate)) "$lbl · ${bitrate}kbps ⚠" else "$lbl · ${bitrate}kbps"
                            }
                            else -> LxPlayerManager.qualityLabel(currentQuality)
                        },"""

src = src.replace(old_block, new_block, 1)

with open(path, "w", encoding="utf-8") as f:
    f.write(src)
print("v4 自诊断徽标升级完成: " + path)
PYEOF

echo "=== 完成 ==="
