#!/bin/bash
# 22 - 播放页音质徽标 v4.2：修复 v4.1 跳过逻辑
# v4.1 的 MARK 与旧 v4 相同，导致已打旧 v4 的文件被误判为"已是 v4"而跳过，
# 静态调用残留导致 #217 编译失败（Unresolved reference 'isSuspiciousLossless'）。
# v4.2：新 MARK；检测到旧 v4 静态调用时替换为内联版。
set -e
cd avbox

echo "=== 播放页音质徽标 v4.2 ==="

python3 << 'PYEOF'
import sys

path = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt"
with open(path, encoding="utf-8") as f:
    src = f.read()

MARK_V42 = "// 验货实测优先显示（22）+ v4.2 内联自诊断"
if MARK_V42 in src:
    print("跳过（已是 v4.2）: " + path)
    raise SystemExit(0)

# v4.2 最终形态：内联判断，不静态调用
v42_block = """                        // 验货实测优先显示（22）+ v4.2 内联自诊断：假无损警告
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

# 情况1：旧 v4（含静态调用）→ 替换为 v4.2 内联版
old_v4_static = "LxPlayerManager.isSuspiciousLossless"
if old_v4_static in src:
    print("检测到旧 v4 静态调用，替换为 v4.2 内联版")
    # 找到旧 v4 块并替换（用 MARK 定位）
    import re
    # 旧 v4 块：从 MARK_V4 注释到对应的 }, 结束
    old_mark = "// 验货实测优先显示（22）+ v4 自诊断"
    if old_mark in src:
        # 简单替换：把整个旧 when 块换掉
        # 找旧块的起止
        start = src.find(old_mark)
        # 往后找配对的 "},"（块结束）
        # 用括号计数找 when 块结束
        idx = src.find("text = when {", start)
        depth = 0
        i = src.find("{", idx)
        start_brace = i
        while i < len(src):
            if src[i] == "{":
                depth += 1
            elif src[i] == "}":
                depth -= 1
                if depth == 0:
                    # 找到 when 结束，再找后面的逗号
                    end = src.find(",", i) + 1
                    old_block = src[start:end]
                    src = src.replace(old_block, v42_block, 1)
                    break
            i += 1
        print("旧 v4 → v4.2 替换完成")
    else:
        print("错误: 找不到旧 v4 标记")
        sys.exit(1)
else:
    # 情况2：全新文件 → 直接打 v4.2
    v1_old = """                        text = when {
                            bitrate > 0 -> "${LxPlayerManager.qualityLabel(currentQuality)} · ${bitrate}kbps"
                            measuredBitrate > 0 -> "${LxPlayerManager.qualityLabel(currentQuality)} · 实测约${measuredBitrate}kbps"
                            else -> LxPlayerManager.qualityLabel(currentQuality)
                        },"""
    # 情况3：已打 22 v1 → 升级
    v1_new_old = """                        // 验货实测优先显示（22）：v2 测出的真实码率优先于 ExoPlayer track 估算值
                        text = when {
                            measuredBitrate > 0 -> "${LxPlayerManager.qualityLabel(currentQuality)} · 实测约${measuredBitrate}kbps"
                            bitrate > 0 -> "${LxPlayerManager.qualityLabel(currentQuality)} · ${bitrate}kbps"
                            else -> LxPlayerManager.qualityLabel(currentQuality)
                        },"""
    if v1_old in src:
        print("全新文件，直接打 v4.2")
        src = src.replace(v1_old, v42_block, 1)
    elif v1_new_old in src:
        print("检测到 v1，升级 → v4.2")
        src = src.replace(v1_new_old, v42_block, 1)
    else:
        print("错误: v4.2 锚点未命中")
        sys.exit(1)

with open(path, "w", encoding="utf-8") as f:
    f.write(src)
print("v4.2 完成: " + path)
PYEOF

echo "=== 完成 ==="
