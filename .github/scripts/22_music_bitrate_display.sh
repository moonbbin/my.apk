#!/bin/bash
# 22 - 播放页音质徽标：验货实测码率优先显示
# 背景：21 v2 已把实测档位/码率回传（_currentQuality/_measuredBitrate），但播放页徽标的
# when 分支是 `bitrate > 0`（ExoPlayer track 估算值）优先，导致"实测约Xkbps"被盖住，
# 用户看到的码率是 ExoPlayer 的估算值而非验货实测值。
# 本补丁调换分支顺序：measuredBitrate > 0 时优先显示"实测约"，只有拿不到实测值时
# 才回退到 ExoPlayer 估算值；两者都拿不到则只显示档位标签。
# 幂等：已打过补丁则跳过；锚点未命中则报错退出，不静默跳过。
set -e
cd avbox

echo "=== 播放页音质徽标：实测码率优先显示 ==="

python3 << 'PYEOF'
import sys

path = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt"
with open(path, encoding="utf-8") as f:
    src = f.read()

MARK = "// 验货实测优先显示（22）"
if MARK in src:
    print("跳过（已打补丁）: " + path)
    raise SystemExit(0)

old = '''                        text = when {
                            bitrate > 0 -> "${LxPlayerManager.qualityLabel(currentQuality)} · ${bitrate}kbps"
                            measuredBitrate > 0 -> "${LxPlayerManager.qualityLabel(currentQuality)} · 实测约${measuredBitrate}kbps"
                            else -> LxPlayerManager.qualityLabel(currentQuality)
                        },'''
new = '''                        // 验货实测优先显示（22）：v2 测出的真实码率优先于 ExoPlayer track 估算值
                        text = when {
                            measuredBitrate > 0 -> "${LxPlayerManager.qualityLabel(currentQuality)} · 实测约${measuredBitrate}kbps"
                            bitrate > 0 -> "${LxPlayerManager.qualityLabel(currentQuality)} · ${bitrate}kbps"
                            else -> LxPlayerManager.qualityLabel(currentQuality)
                        },'''

if old not in src:
    print("错误: 锚点未命中（播放页徽标 when 分支）")
    sys.exit(1)
src = src.replace(old, new, 1)

with open(path, "w", encoding="utf-8") as f:
    f.write(src)
print("已打补丁: " + path)
PYEOF

echo "=== 完成 ==="
