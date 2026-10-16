#!/bin/bash
# 22 - 播放页音质徽标：验货实测码率优先显示 + v4 自诊断
# v4.1 修复 #216 编译失败：不静态调用 LxPlayerManager.isSuspiciousLossless（该函数在 21 v4 中是实例方法，
#       静态调用导致 Unresolved reference）。改为徽标内直接内联判断 FLAC<500 / 24bit<800。
# 幂等：已打过 v4/v4.1 则跳过；支持全新文件直接打、v1→v4.1 增量；锚点未命中则报错退出。
set -e
cd avbox

echo "=== 播放页音质徽标 v4.1：自诊断（内联） ==="

python3 << 'PYEOF'
import sys

path = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt"
with open(path, encoding="utf-8") as f:
    src = f.read()

MARK_V4 = "// 验货实测优先显示（22）+ v4 自诊断"
if MARK_V4 in src:
    # 已有 v4（旧版静态调用版）→ 替换为内联版
    if "isSuspiciousLossless" in src:
        print("检测到旧 v4（静态调用版），升级为 v4.1 内联版")
    else:
        print("跳过（已是 v4.1）: " + path)
        raise SystemExit(0)

# v4.1 目标：内联假无损判断，不依赖 LxPlayerManager 静态方法
v41_block = """                        // 验货实测优先显示（22）+ v4 自诊断：假无损警告（内联判断）
                        text = when {
                            measuredBitrate > 0 -> {
                                val lbl = LxPlayerManager.qualityLabel(currentQuality)
                                val sus = (currentQuality == "flac" && measuredBitrate < 500) || (currentQuality == "flac24bit" && measuredBitrate < 800)
                                if (sus) "$lbl · 实测约${measuredBitrate}kbps ⚠" else "$lbl · 实测约${measuredBitrate}kbps"
                            }
                            bitrate > 0 -> {
                                val lbl = LxPlayerManager.qualityLabel(currentQuality)
                                val sus = (currentQuality == "flac" && bitrate < 500) || (currentQuality == "flac24bit" && bitrate < 800)
                                if (sus) "$lbl · ${bitrate}kbps ⚠" else "$lbl · ${bitrate}kbps"
                            }
                            else -> LxPlayerManager.qualityLabel(currentQuality)
                        },"""

# 旧 v4（静态调用版）→ 替换为 v4.1
old_v4_static = "if (LxPlayerManager.isSuspiciousLossless(currentQuality, measuredBitrate))"
if old_v4_static in src:
    import re
    # 替换整个旧 v4 when 块为 v4.1
    pattern = r"                        // 验货实测优先显示（22）\+ v4 自诊断：假无损警告\n                        text = when \{.*?                            else -> LxPlayerManager\.qualityLabel\(currentQuality\)\n                        \},"
    src_new, n = re.subn(pattern, v41_block, src, count=1, flags=re.S)
    if n == 0:
        print("错误: 旧 v4 块匹配失败")
        sys.exit(1)
    src = src_new
    print("旧 v4 → v4.1 内联版升级完成")
else:
    # 全新文件或 v1 → 直接打 v4.1
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
        print("全新文件，直接打 v4.1")
        src = src.replace(v1_old, v41_block, 1)
    elif v1_new_old in src:
        print("检测到 v1，增量升级 → v4.1")
        src = src.replace(v1_new_old, v41_block, 1)
    else:
        print("错误: v4.1 锚点未命中")
        sys.exit(1)

with open(path, "w", encoding="utf-8") as f:
    f.write(src)
print("v4.1 完成: " + path)
PYEOF

echo "=== 完成 ==="
