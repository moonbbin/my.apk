#!/bin/bash
# 22 - 播放页音质徽标：验货实测码率优先显示 + v4 自诊断
# v4：在徽标 when 分支中加入假无损自诊断，FLAC 但码率过低时显示 ⚠ 警告
# 幂等：已打过 v4 则跳过；支持全新文件直接打 v4、v1→v4 增量升级；锚点未命中则报错退出。
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

# v4 最终形态（含 v1 的实测优先 + v4 自诊断）
v4_block = """                        // 验货实测优先显示（22）+ v4 自诊断：假无损警告
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

# 情况1：全新文件（22 v1 未打）→ 直接打 v4
v1_old = """                        text = when {
                            bitrate > 0 -> "${LxPlayerManager.qualityLabel(currentQuality)} · ${bitrate}kbps"
                            measuredBitrate > 0 -> "${LxPlayerManager.qualityLabel(currentQuality)} · 实测约${measuredBitrate}kbps"
                            else -> LxPlayerManager.qualityLabel(currentQuality)
                        },"""

# 情况2：已打 22 v1 → 升级到 v4
v1_new_old = """                        // 验货实测优先显示（22）：v2 测出的真实码率优先于 ExoPlayer track 估算值
                        text = when {
                            measuredBitrate > 0 -> "${LxPlayerManager.qualityLabel(currentQuality)} · 实测约${measuredBitrate}kbps"
                            bitrate > 0 -> "${LxPlayerManager.qualityLabel(currentQuality)} · ${bitrate}kbps"
                            else -> LxPlayerManager.qualityLabel(currentQuality)
                        },"""

if v1_old in src:
    print("全新文件，直接打 v4")
    src = src.replace(v1_old, v4_block, 1)
elif v1_new_old in src:
    print("检测到 v1，增量升级 → v4")
    src = src.replace(v1_new_old, v4_block, 1)
else:
    print("错误: v4 锚点未命中")
    sys.exit(1)

with open(path, "w", encoding="utf-8") as f:
    f.write(src)
print("v4 完成: " + path)
PYEOF

echo "=== 完成 ==="
