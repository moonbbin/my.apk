#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd avbox

echo "=== 添加音乐 tab ==="

# 所有 MainScreen.kt 的修改都用 Python 做，避免 bash 引号问题
python3 "$SCRIPT_DIR/modify_mainscreen.py"

# 字符串资源
MS=app/src/main/java/com/github/tvbox/osc/ui/page/MainScreen.kt
HC=app/src/main/java/com/github/tvbox/osc/util/HawkConfig.kt
SP=app/src/main/java/com/github/tvbox/osc/ui/page/SettingsPage.kt
SX=app/src/main/res/values/strings.xml

grep -q 'name="tab_music"' $SX || sed -i 's|<string name="tab_home">首页</string>|<string name="tab_home">首页</string>\n    <string name="tab_music">音乐</string>|' $SX
cp app/src/main/res/drawable/ic_music_page.xml app/src/main/res/drawable/ic_tab_music.xml

# HawkConfig
grep -q "NAV_MUSIC_HIDDEN" $HC || python3 -c "
import sys
f = 'app/src/main/java/com/github/tvbox/osc/util/HawkConfig.kt'
with open(f) as fh: c = fh.read()
c = c.replace('const val NAV_LIVE_HIDDEN = \"nav_live_hidden\"', 'const val NAV_LIVE_HIDDEN = \"nav_live_hidden\"\n    const val NAV_MUSIC_HIDDEN = \"nav_music_hidden\"')
with open(f, 'w') as fh: fh.write(c)
"

# 设置页字符串
grep -q "settings_nav_music_hidden" $SX || sed -i 's|</resources>|    <string name="settings_nav_music_hidden">导航栏隐藏音乐</string>\n    <string name="settings_nav_music_hidden_subtitle">开启后导航栏不再显示音乐入口</string>\n</resources>|' $SX
cp app/src/main/res/drawable/ic_music_page.xml app/src/main/res/drawable/ic_pref_nav_music_hidden.xml

# SettingsPage.kt - 添加 navMusicHidden 属性
SP=app/src/main/java/com/github/tvbox/osc/ui/page/SettingsPage.kt
python3 << 'PYEOF2'
sp_file = "app/src/main/java/com/github/tvbox/osc/ui/page/SettingsPage.kt"
with open(sp_file, 'r', encoding='utf-8') as f:
    c = f.read()
if "val navMusicHidden" not in c:
    c = c.replace("val navLiveHidden: Boolean,", "val navLiveHidden: Boolean,\n    val navMusicHidden: Boolean,")
    print("SettingsState.navMusicHidden 已添加")
if "NAV_MUSIC_HIDDEN, false" not in c:
    c = c.replace("navLiveHidden = KV.get(HawkConfig.NAV_LIVE_HIDDEN, false),", "navLiveHidden = KV.get(HawkConfig.NAV_LIVE_HIDDEN, false),\n        navMusicHidden = KV.get(HawkConfig.NAV_MUSIC_HIDDEN, false),")
    print("KV.get 已添加")
with open(sp_file, 'w', encoding='utf-8') as f:
    f.write(c)
PYEOF2
python3 "$SCRIPT_DIR/insert_music_toggle.py"
python3 "$SCRIPT_DIR/insert_music_filter.py"

echo "=== 音乐 tab 添加完成 ==="
