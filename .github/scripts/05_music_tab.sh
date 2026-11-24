#!/bin/bash
# [base-a6da734e] round1 tvbox->avbox
# [base-a6da734e] round2 bridge
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd avbox

echo "=== 添加音乐 tab ==="

# 所有 MainScreen.kt 的修改都用 Python 做，避免 bash 引号问题
python3 "$SCRIPT_DIR/modify_mainscreen.py"

# 字符串资源
MS=app/src/main/java/com/github/avbox/osc/ui/page/MainScreen.kt
KK=app/src/main/java/com/github/avbox/osc/util/KVKeys.kt
KKS=app/src/main/java/com/github/avbox/osc/util/kv/KVKeySpec.kt
USS=app/src/main/java/com/github/avbox/osc/ui/settings/UiSettingsState.kt
SP=app/src/main/java/com/github/avbox/osc/ui/page/SettingsPage.kt
SX=app/src/main/res/values/strings.xml

grep -q 'name="tab_music"' $SX || sed -i 's|<string name="tab_home">首页</string>|<string name="tab_home">首页</string>\n    <string name="tab_music">音乐</string>|' $SX
cp app/src/main/res/drawable/ic_music_page.xml app/src/main/res/drawable/ic_tab_music.xml

# [base-a6da734e] round2: HawkConfig 已删（旧主体 util/HawkConfig.kt）。
# 05 读它只为一件事：定义 NAV_MUSIC_HIDDEN key（"nav_music_hidden"），供
# SettingsPage/MainScreen 经 KV.get(HawkConfig.NAV_MUSIC_HIDDEN, false) 读写。
# 新主体等价物：KVKeys 只有 key 常量，读写走 KV（KV.get(key, default)/KV.put）。
# 故 key 定义进 KVKeys.kt（紧跟 NAV_LIVE_HIDDEN），并在 KVKeySpec 注册 Boolean
# 类型（与 NAV_LIVE_HIDDEN 同款；未注册时 KVCodec.decode 拿不到 key 类型）。
# 状态本体不再放 SettingsPage（新主体 SettingsState 只剩 cacheSizeText，
# navLiveHidden 已搬进 UiSettingsState），见下 UiSettingsState 一步。
grep -q "NAV_MUSIC_HIDDEN" $KK || python3 -c "
import sys
f = 'app/src/main/java/com/github/avbox/osc/util/KVKeys.kt'
with open(f) as fh: c = fh.read()
old = 'const val NAV_LIVE_HIDDEN = \"nav_live_hidden\"'
assert c.count(old) == 1, 'KVKeys NAV_LIVE_HIDDEN anchor count %d' % c.count(old)
c = c.replace(old, old + '\n    const val NAV_MUSIC_HIDDEN = \"nav_music_hidden\"')
with open(f, 'w') as fh: fh.write(c)
print('KVKeys.NAV_MUSIC_HIDDEN 已添加')
"
grep -q "NAV_MUSIC_HIDDEN" $KKS || python3 -c "
import sys
f = 'app/src/main/java/com/github/avbox/osc/util/kv/KVKeySpec.kt'
with open(f) as fh: c = fh.read()
old = 'register(KVKeys.NAV_LIVE_HIDDEN, false)'
assert c.count(old) == 1, 'KVKeySpec NAV_LIVE_HIDDEN anchor count %d' % c.count(old)
c = c.replace(old, old + '\n            register(KVKeys.NAV_MUSIC_HIDDEN, false)')
with open(f, 'w') as fh: fh.write(c)
print('KVKeySpec.NAV_MUSIC_HIDDEN 已注册')
"

# 设置页字符串
grep -q "settings_nav_music_hidden" $SX || sed -i 's|</resources>|    <string name="settings_nav_music_hidden">导航栏隐藏音乐</string>\n    <string name="settings_nav_music_hidden_subtitle">开启后导航栏不再显示音乐入口</string>\n</resources>|' $SX
cp app/src/main/res/drawable/ic_music_page.xml app/src/main/res/drawable/ic_pref_nav_music_hidden.xml

# UiSettingsState.kt - 添加 navMusicHidden（与 navLiveHidden 同款三件套：
# UiSettingsConfig 字段 + load() 的 KV.get + var getter/setter 的 KV.put）。
# 旧主体同款状态在 SettingsPage.SettingsState 里；新主体 SettingsState 只剩
# cacheSizeText，navLiveHidden 已搬进 UiSettingsState，故跟进此处，不动 SettingsPage。
SP=app/src/main/java/com/github/avbox/osc/ui/page/SettingsPage.kt
python3 << 'PYEOF2'
import sys
uss_file = "app/src/main/java/com/github/avbox/osc/ui/settings/UiSettingsState.kt"
with open(uss_file, 'r', encoding='utf-8') as f:
    c = f.read()
if "navMusicHidden" in c:
    print("UiSettingsState.navMusicHidden 已存在，跳过")
    sys.exit(0)
def rep1(old, new, name):
    global c
    assert c.count(old) == 1, "%s anchor count %d" % (name, c.count(old))
    c = c.replace(old, new, 1)
rep1("    val navLiveHidden: Boolean,",
     "    val navLiveHidden: Boolean,\n    val navMusicHidden: Boolean,",
     "UiSettingsConfig 字段")
rep1("        navLiveHidden = KV.get(KVKeys.NAV_LIVE_HIDDEN, false),",
     "        navLiveHidden = KV.get(KVKeys.NAV_LIVE_HIDDEN, false),\n        navMusicHidden = KV.get(KVKeys.NAV_MUSIC_HIDDEN, false),",
     "load() KV.get")
rep1("""    var navLiveHidden: Boolean
        get() = current.navLiveHidden
        set(value) {
            KV.put(KVKeys.NAV_LIVE_HIDDEN, value)
            current = current.copy(navLiveHidden = value)
        }""",
"""    var navLiveHidden: Boolean
        get() = current.navLiveHidden
        set(value) {
            KV.put(KVKeys.NAV_LIVE_HIDDEN, value)
            current = current.copy(navLiveHidden = value)
        }

    var navMusicHidden: Boolean
        get() = current.navMusicHidden
        set(value) {
            KV.put(KVKeys.NAV_MUSIC_HIDDEN, value)
            current = current.copy(navMusicHidden = value)
        }""",
     "var getter/setter")
assert c.count("{") == c.count("}"), "UiSettingsState 括号失衡"
with open(uss_file, 'w', encoding='utf-8') as f:
    f.write(c)
print("UiSettingsState.navMusicHidden 已添加")
PYEOF2
python3 "$SCRIPT_DIR/insert_music_toggle.py"
python3 "$SCRIPT_DIR/insert_music_filter.py"

echo "=== 音乐 tab 添加完成 ==="
