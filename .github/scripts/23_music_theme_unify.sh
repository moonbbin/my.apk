#!/bin/bash
# 23 - 音乐主题颜色源统一
# 背景：20 号脚本定稿了 ui.music.theme（Color.kt/Type.kt/Theme.kt），但 LxMusicTheme.kt
# 的 DarkMusicColors 仍用硬编码 Color(0xFF...)，与主题常量是两套平行系统，改色要改两处。
# 本补丁：
#   1) Color.kt 补两个缺失常量：TextOnAccent(#06210B)、SliderTrack(#3A3A3C)，色值原样不动；
#   2) LxMusicTheme.kt 的 DarkMusicColors 11 个字段全部改引主题常量（加 import）。
# 改完后全局只有一套颜色源：以后改主色只改 Color.kt，54 处 musicColors() 引用自动生效。
# 范围：只动 Color.kt 和 LxMusicTheme.kt（主题定义文件），不碰任何页面 UI 代码。
# LightMusicColors（浅色暖色盘）第一步暂不动，等第二步再处理。
# 幂等：已统一则跳过；锚点未命中则报错退出，不静默跳过。
set -e
cd avbox

echo "=== 音乐主题颜色源统一 ==="

python3 << 'PYEOF'
import sys

THEME_PKG = "com.github.tvbox.osc.ui.music.theme"
COLOR_KT = "app/src/main/java/com/github/tvbox/osc/ui/music/theme/Color.kt"
LXT = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxMusicTheme.kt"

# ---------- 1) Color.kt：补 TextOnAccent / SliderTrack ----------
with open(COLOR_KT, encoding="utf-8") as f:
    csrc = f.read()

if "val TextOnAccent" in csrc and "val SliderTrack" in csrc:
    print("跳过（Color.kt 已补常量）")
else:
    addition = (
        "/** 主色上的文字（深绿黑，23 统一补全） */\n"
        "val TextOnAccent = Color(0xFF06210B)\n"
        "/** 进度条轨道（23 统一补全） */\n"
        "val SliderTrack = Color(0xFF3A3A3C)\n"
    )
    if not csrc.endswith("\n"):
        csrc += "\n"
    csrc += addition
    with open(COLOR_KT, "w", encoding="utf-8") as f:
        f.write(csrc)
    print("Color.kt：已补 TextOnAccent / SliderTrack")

# ---------- 2) LxMusicTheme.kt：DarkMusicColors 引用主题常量 ----------
with open(LXT, encoding="utf-8") as f:
    src = f.read()

MARK = "// 深色主题：全部引用 ui.music.theme 定稿常量（23 统一）"
if MARK in src:
    print("跳过（LxMusicTheme.kt 已统一）: " + LXT)
else:
    OLD_DARK = '''val DarkMusicColors = MusicColors(
    background = Color(0xFF0F0F0F),      // #0F0F0F 主背景
    card = Color(0xFF1C1C1E),            // #1C1C1E 卡片/表面
    cardSecondary = Color(0xFF2C2C2E),   // #2C2C2E 次级卡片/按压态
    textPrimary = Color(0xFFFFFFFF),     // #FFFFFF 主文字
    textSecondary = Color(0xFF8E8E93),    // #8E8E93 辅助文字
    textHint = Color(0xFF636366),         // #636366 更弱提示
    accent = Color(0xFF34C759),           // #34C759 Apple 绿
    accentText = Color(0xFF06210B),       // 深绿黑（主色上的文字）
    divider = Color(0xFF2C2C2E),          // #2C2C2E 分割线
    sliderTrack = Color(0xFF3A3A3C),      // 进度条轨道
    iconTint = Color(0xFFFFFFFF),         // 图标白
)'''
    NEW_DARK = '''// 深色主题：全部引用 ui.music.theme 定稿常量（23 统一），改色只改 Color.kt
val DarkMusicColors = MusicColors(
    background = BgBase,
    card = BgCard,
    cardSecondary = BgCardPressed,
    textPrimary = TextPrimary,
    textSecondary = TextSecondary,
    textHint = TextTertiary,
    accent = AppleGreen,
    accentText = TextOnAccent,
    divider = DividerColor,
    sliderTrack = SliderTrack,
    iconTint = TextPrimary,
)'''
    if OLD_DARK not in src:
        print("错误: DarkMusicColors 锚点未命中")
        sys.exit(1)
    src = src.replace(OLD_DARK, NEW_DARK, 1)

    # 加 import（插到最后一个 import 之后，避免重复）
    imports = ["AppleGreen", "BgBase", "BgCard", "BgCardPressed", "DividerColor",
               "SliderTrack", "TextOnAccent", "TextPrimary", "TextSecondary", "TextTertiary"]
    lines = src.split("\n")
    last_imp = max(i for i, l in enumerate(lines) if l.startswith("import "))
    for name in imports:
        imp = f"import {THEME_PKG}.{name}"
        if imp not in src:
            lines.insert(last_imp + 1, imp)
            last_imp += 1
    src = "\n".join(lines)

    with open(LXT, "w", encoding="utf-8") as f:
        f.write(src)
    print("LxMusicTheme.kt：DarkMusicColors 已统一引用主题常量")

print("=== 音乐主题颜色源统一完成 ===")
PYEOF

echo "=== 完成 ==="
