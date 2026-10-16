#!/bin/bash
set -e
cd avbox

echo "=== 接入音乐全局主题（QingfengMusicTheme） ==="

THEME_DIR="app/src/main/java/com/github/tvbox/osc/ui/music/theme"
mkdir -p "$THEME_DIR"

echo "cGFja2FnZSBjb20uZ2l0aHViLnR2Ym94Lm9zYy51aS5tdXNpYy50aGVtZQoKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UudWkuZ3JhcGhpY3MuQ29sb3IKCi8vID09PT09PT09PT09PSDog4zmma/lsYLnuqcgPT09PT09PT09PT09Ci8qKiDpobXpnaLlupXoibIgKi8KdmFsIEJnQmFzZSA9IENvbG9yKDB4RkYwRjBGMEYpCi8qKiDljaHniYcgLyDljLrlnZflupUgKi8KdmFsIEJnQ2FyZCA9IENvbG9yKDB4RkYxQzFDMUUpCi8qKiDljaHniYfmjInljovmgIEgKi8KdmFsIEJnQ2FyZFByZXNzZWQgPSBDb2xvcigweEZGMkMyQzJFKQoKLy8gPT09PT09PT09PT09IOS4u+iJsiA9PT09PT09PT09PT0KLyoqIOS4u+W8uuiwg+iJsiAqLwp2YWwgQXBwbGVHcmVlbiA9IENvbG9yKDB4RkYzNEM3NTkpCi8qKiDkuLvoibLlvLHljJblrrnlmajvvIjmt7HlupXkuIrnmoTnu7/lrrnlmajvvIkgKi8KdmFsIEFwcGxlR3JlZW5EaW0gPSBDb2xvcigweEZGMUU0NjIyKQoKLy8gPT09PT09PT09PT09IOaWh+Wtl+Wxgue6pyA9PT09PT09PT09PT0KdmFsIFRleHRQcmltYXJ5ID0gQ29sb3IoMHhGRkZGRkZGRikKdmFsIFRleHRTZWNvbmRhcnkgPSBDb2xvcigweEZGOEU4RTkzKQp2YWwgVGV4dFRlcnRpYXJ5ID0gQ29sb3IoMHhGRjYzNjM2NikKCi8vID09PT09PT09PT09PSDlip/og73oibIgPT09PT09PT09PT09Ci8qKiDliIblibLnur8gKi8KdmFsIERpdmlkZXJDb2xvciA9IENvbG9yKDB4RkYyQzJDMkUpCi8qKiDplJnor6/mj5DnpLogKi8KdmFsIEVycm9yUmVkID0gQ29sb3IoMHhGRkZGNjk2MSkK" | base64 -d > "$THEME_DIR/Color.kt"
echo "cGFja2FnZSBjb20uZ2l0aHViLnR2Ym94Lm9zYy51aS5tdXNpYy50aGVtZQoKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UubWF0ZXJpYWwzLlR5cG9ncmFwaHkKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UudWkudGV4dC5UZXh0U3R5bGUKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UudWkudGV4dC5mb250LkZvbnRXZWlnaHQKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UudWkudW5pdC5zcAoKLyoqIOWkp+agh+mimO+8mjI4c3AgQm9sZO+8jOWtl+i3nSAtMC41ICovCnZhbCBoZWFkbGluZUxhcmdlID0gVGV4dFN0eWxlKAogICAgZm9udFNpemUgPSAyOC5zcCwKICAgIGZvbnRXZWlnaHQgPSBGb250V2VpZ2h0LkJvbGQsCiAgICBsZXR0ZXJTcGFjaW5nID0gKC0wLjUpLnNwLAogICAgY29sb3IgPSBUZXh0UHJpbWFyeQopCgovKiog5YiG5Yy65qCH6aKY77yaMThzcCBTZW1pQm9sZO+8jOWtl+i3nSAwICovCnZhbCB0aXRsZUxhcmdlID0gVGV4dFN0eWxlKAogICAgZm9udFNpemUgPSAxOC5zcCwKICAgIGZvbnRXZWlnaHQgPSBGb250V2VpZ2h0LlNlbWlCb2xkLAogICAgbGV0dGVyU3BhY2luZyA9IDAuc3AsCiAgICBjb2xvciA9IFRleHRQcmltYXJ5CikKCi8qKiDmrYzor43ooYzvvJoxNnNwIE5vcm1hbO+8jOihjOmrmCAyOHNw77yM6buY6K6kIFRleHRTZWNvbmRhcnkgKi8KdmFsIGJvZHlMYXJnZSA9IFRleHRTdHlsZSgKICAgIGZvbnRTaXplID0gMTYuc3AsCiAgICBmb250V2VpZ2h0ID0gRm9udFdlaWdodC5Ob3JtYWwsCiAgICBsaW5lSGVpZ2h0ID0gMjguc3AsCiAgICBjb2xvciA9IFRleHRTZWNvbmRhcnkKKQoKLyoqIOatjOaJiyAvIOi+heWKqeaWh+Wtl++8mjE0c3AgTm9ybWFs77yM5a2X6LedIDAuMyAqLwp2YWwgYm9keU1lZGl1bSA9IFRleHRTdHlsZSgKICAgIGZvbnRTaXplID0gMTQuc3AsCiAgICBmb250V2VpZ2h0ID0gRm9udFdlaWdodC5Ob3JtYWwsCiAgICBsZXR0ZXJTcGFjaW5nID0gMC4zLnNwLAogICAgY29sb3IgPSBUZXh0U2Vjb25kYXJ5CikKCi8qKiDlsI/moIfnrb4gLyDml7bplb/vvJoxMXNwIE5vcm1hbO+8jOWtl+i3nSAwLjQgKi8KdmFsIGxhYmVsU21hbGwgPSBUZXh0U3R5bGUoCiAgICBmb250U2l6ZSA9IDExLnNwLAogICAgZm9udFdlaWdodCA9IEZvbnRXZWlnaHQuTm9ybWFsLAogICAgbGV0dGVyU3BhY2luZyA9IDAuNC5zcCwKICAgIGNvbG9yID0gVGV4dFRlcnRpYXJ5CikKCnZhbCBNdXNpY1R5cG9ncmFwaHkgPSBUeXBvZ3JhcGh5KAogICAgaGVhZGxpbmVMYXJnZSA9IGhlYWRsaW5lTGFyZ2UsCiAgICB0aXRsZUxhcmdlID0gdGl0bGVMYXJnZSwKICAgIGJvZHlMYXJnZSA9IGJvZHlMYXJnZSwKICAgIGJvZHlNZWRpdW0gPSBib2R5TWVkaXVtLAogICAgbGFiZWxTbWFsbCA9IGxhYmVsU21hbGwKKQo=" | base64 -d > "$THEME_DIR/Type.kt"
echo "cGFja2FnZSBjb20uZ2l0aHViLnR2Ym94Lm9zYy51aS5tdXNpYy50aGVtZQoKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UuZm91bmRhdGlvbi5zaGFwZS5Sb3VuZGVkQ29ybmVyU2hhcGUKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UubWF0ZXJpYWwzLk1hdGVyaWFsVGhlbWUKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UubWF0ZXJpYWwzLlNoYXBlcwppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5tYXRlcmlhbDMuZGFya0NvbG9yU2NoZW1lCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLnJ1bnRpbWUuQ29tcG9zYWJsZQppbXBvcnQgYW5kcm9pZHguY29tcG9zZS51aS51bml0LmRwCgp2YWwgTXVzaWNTaGFwZXMgPSBTaGFwZXMoCiAgICBleHRyYVNtYWxsID0gUm91bmRlZENvcm5lclNoYXBlKDQuZHApLAogICAgc21hbGwgPSBSb3VuZGVkQ29ybmVyU2hhcGUoOC5kcCksCiAgICBtZWRpdW0gPSBSb3VuZGVkQ29ybmVyU2hhcGUoMTIuZHApLAogICAgbGFyZ2UgPSBSb3VuZGVkQ29ybmVyU2hhcGUoMTYuZHApLAogICAgZXh0cmFMYXJnZSA9IFJvdW5kZWRDb3JuZXJTaGFwZSgyNC5kcCkKKQoKdmFsIE11c2ljQ29sb3JTY2hlbWUgPSBkYXJrQ29sb3JTY2hlbWUoCiAgICBwcmltYXJ5ID0gQXBwbGVHcmVlbiwKICAgIG9uUHJpbWFyeSA9IFRleHRQcmltYXJ5LAogICAgcHJpbWFyeUNvbnRhaW5lciA9IEFwcGxlR3JlZW5EaW0sCiAgICBvblByaW1hcnlDb250YWluZXIgPSBBcHBsZUdyZWVuLAogICAgYmFja2dyb3VuZCA9IEJnQmFzZSwKICAgIG9uQmFja2dyb3VuZCA9IFRleHRQcmltYXJ5LAogICAgc3VyZmFjZSA9IEJnQ2FyZCwKICAgIG9uU3VyZmFjZSA9IFRleHRQcmltYXJ5LAogICAgc3VyZmFjZVZhcmlhbnQgPSBCZ0NhcmRQcmVzc2VkLAogICAgb25TdXJmYWNlVmFyaWFudCA9IFRleHRTZWNvbmRhcnksCiAgICBvdXRsaW5lID0gRGl2aWRlckNvbG9yLAogICAgb3V0bGluZVZhcmlhbnQgPSBEaXZpZGVyQ29sb3IuY29weShhbHBoYSA9IDAuNWYpLAogICAgZXJyb3IgPSBFcnJvclJlZAopCgovKiog6Z+z5LmQ5LiT5Yy65qC56IqC54K55Li76aKY5YWl5Y+jICovCkBDb21wb3NhYmxlCmZ1biBRaW5nZmVuZ011c2ljVGhlbWUoCiAgICBjb250ZW50OiBAQ29tcG9zYWJsZSAoKSAtPiBVbml0CikgewogICAgTWF0ZXJpYWxUaGVtZSgKICAgICAgICBjb2xvclNjaGVtZSA9IE11c2ljQ29sb3JTY2hlbWUsCiAgICAgICAgdHlwb2dyYXBoeSA9IE11c2ljVHlwb2dyYXBoeSwKICAgICAgICBzaGFwZXMgPSBNdXNpY1NoYXBlcywKICAgICAgICBjb250ZW50ID0gY29udGVudAogICAgKQp9Cg==" | base64 -d > "$THEME_DIR/Theme.kt"
echo "主题文件已写入: $THEME_DIR/Color.kt, Type.kt, Theme.kt"

python3 << 'PYEOF2'
import re

THEME_PKG = "com.github.tvbox.osc.ui.music.theme"
ACT = "app/src/main/java/com/github/tvbox/osc/ui/activity"

# 文件 -> ([(旧, 新)], [需导入的主题符号])
PATCHES = {
    f"{ACT}/LxPlayerActivity.kt": (
        [
            ("// Spotify 主题色", "// 音乐主题色（引用 ui.music.theme 定稿常量）"),
            ("private val PlayerGray = Color(0xFFB3B3B3)", "private val PlayerGray = TextSecondary"),
            ("private val PlayerGreen = Color(0xFF1DB954)", "private val PlayerGreen = AppleGreen"),
            ("private val CoverTintFallback = Color(0xFF1A1A1A)", "private val CoverTintFallback = BgCard"),
        ],
        ["AppleGreen", "BgCard", "TextSecondary", "QingfengMusicTheme"],
    ),
    f"{ACT}/LxMusicSearchActivity.kt": (
        [
            ("private val SearchBg = Color(0xFF000000)", "private val SearchBg = BgBase"),
            ("private val SearchCard = Color(0xFF1A1A1A)", "private val SearchCard = BgCard"),
            ("private val SearchAccent = Color(0xFF1DB954)", "private val SearchAccent = AppleGreen"),
            ("private val SearchGray = Color(0xFFB3B3B3)", "private val SearchGray = TextSecondary"),
            # 头像占位灰 #333333 并入主题
            (".background(Color(0xFF333333))", ".background(BgCardPressed)"),
        ],
        ["BgBase", "BgCard", "BgCardPressed", "AppleGreen", "TextSecondary", "QingfengMusicTheme"],
    ),
    f"{ACT}/LxArtistDetailActivity.kt": (
        [
            ("private val DetailBg = Color(0xFF121212)", "private val DetailBg = BgBase"),
            ("private val DetailGreen = Color(0xFF1DB954)", "private val DetailGreen = AppleGreen"),
            ("private val DetailGray = Color(0xFFB3B3B3)", "private val DetailGray = TextSecondary"),
            # 内联旧色改为引用已重映射的 val
            (".background(Color(0xFF121212))", ".background(DetailBg)"),
            ("return Color(0xFF1DB954)", "return DetailGreen"),
            # 头像占位灰 #333333 并入主题
            (".background(Color(0xFF333333))", ".background(BgCardPressed)"),
        ],
        ["BgBase", "BgCardPressed", "AppleGreen", "TextSecondary", "QingfengMusicTheme"],
    ),
    f"{ACT}/MusicHomeActivity.kt": (
        [
            ("private val BgDeepBlue = Color(0xFF000000)", "private val BgDeepBlue = BgBase"),
            ("private val BgDarker = Color(0xFF000000)", "private val BgDarker = BgBase"),
            ("private val CardBlue = Color(0xFF1A1A1A)", "private val CardBlue = BgCard"),
            ("private val AccentBlue = Color(0xFF1DB954)", "private val AccentBlue = AppleGreen"),
            ("private val TextGray = Color(0xFFB3B3B3)", "private val TextGray = TextSecondary"),
        ],
        ["BgBase", "BgCard", "AppleGreen", "TextSecondary", "QingfengMusicTheme"],
    ),
    f"{ACT}/LxHistoryActivity.kt": (
        [
            (".background(Color(0xFF000000))", ".background(BgBase)"),
            (
                "setContent { MaterialTheme { HistoryScreen { finish() } } }",
                "setContent { QingfengMusicTheme { HistoryScreen { finish() } } }",
            ),
        ],
        ["BgBase", "QingfengMusicTheme"],
    ),
}

changed = 0
for path, (repl, imports) in PATCHES.items():
    with open(path, encoding="utf-8") as f:
        src = f.read()
    if THEME_PKG in src:
        print(f"跳过（已接入）: {path}")
        continue
    for old, new in repl:
        if old not in src:
            print(f"警告: 锚点未命中 [{path}] {old[:70]}")
        src = src.replace(old, new)
    # setContent 根节点: MaterialTheme -> QingfengMusicTheme（多行形式）
    src, n = re.subn(
        r"setContent \{\n(\s*)MaterialTheme \{\n",
        r"setContent {\n\1QingfengMusicTheme {\n",
        src,
    )
    # 导入主题符号（插到最后一个 import 之后）
    lines = src.split("\n")
    last_imp = max(i for i, l in enumerate(lines) if l.startswith("import "))
    for name in imports:
        lines.insert(last_imp + 1, f"import {THEME_PKG}.{name}")
        last_imp += 1
    src = "\n".join(lines)
    with open(path, "w", encoding="utf-8") as f:
        f.write(src)
    changed += 1
    print(f"已接入主题: {path}")

print(f"共处理 {changed} 个文件")
PYEOF2

echo "=== 音乐全局主题接入完成 ==="
