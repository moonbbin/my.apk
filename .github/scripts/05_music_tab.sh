#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd avbox
MS=app/src/main/java/com/github/tvbox/osc/ui/page/MainScreen.kt
HC=app/src/main/java/com/github/tvbox/osc/util/HawkConfig.kt
SP=app/src/main/java/com/github/tvbox/osc/ui/page/SettingsPage.kt
PP=app/src/main/java/com/github/tvbox/osc/ui/page/PreferenceSettingsPage.kt
SX=app/src/main/res/values/strings.xml
echo "=== 添加音乐 tab ==="
# Python 脚本已提取为同目录的 insert_music_toggle.py
perl -0pi -e 's/FOLLOWING\(R\.string\.tab_following, R\.drawable\.ic_tab_following\),\n    SETTINGS/FOLLOWING(R.string.tab_following, R.drawable.ic_tab_following),\n    MUSIC(R.string.tab_music, R.drawable.ic_tab_music),\n    SETTINGS/' $MS
perl -0pi -e 's/AppTab\.FOLLOWING -> FollowingPage\(contentPadding = pageContentPadding\)/AppTab.FOLLOWING -> FollowingPage(contentPadding = pageContentPadding)\n                                AppTab.MUSIC -> { val ctx = LocalContext.current; LaunchedEffect(Unit) { ctx.startActivity(Intent(ctx, MusicPlayerActivity::class.java)) }; Box(modifier = Modifier.fillMaxSize()) }/' $MS
grep -q "import android.content.Intent" $MS || sed -i '1i import android.content.Intent' $MS
grep -q "import androidx.compose.ui.platform.LocalContext" $MS || sed -i '/import android.content.Intent/a import androidx.compose.ui.platform.LocalContext' $MS
grep -q "com.github.tvbox.osc.ui.activity.MusicPlayerActivity" $MS || sed -i '/import androidx.compose.ui.platform.LocalContext/a import com.github.tvbox.osc.ui.activity.MusicPlayerActivity' $MS
grep -q "import androidx.compose.foundation.layout.Box" $MS || sed -i '/import com.github.tvbox.osc.ui.activity.MusicPlayerActivity/a import androidx.compose.foundation.layout.Box' $MS
grep -q 'name="tab_music"' $SX || sed -i 's|<string name="tab_home">首页</string>|<string name="tab_home">首页</string>\n    <string name="tab_music">音乐</string>|' $SX
cp app/src/main/res/drawable/ic_music_page.xml app/src/main/res/drawable/ic_tab_music.xml
grep -q "NAV_MUSIC_HIDDEN" $HC || perl -0pi -e 's/const val NAV_LIVE_HIDDEN = "nav_live_hidden"/const val NAV_LIVE_HIDDEN = "nav_live_hidden"\n    const val NAV_MUSIC_HIDDEN = "nav_music_hidden"/' $HC
grep -q "settings_nav_music_hidden" $SX || sed -i 's|</resources>|    <string name="settings_nav_music_hidden">导航栏隐藏音乐</string>\n    <string name="settings_nav_music_hidden_subtitle">开启后导航栏不再显示音乐入口</string>\n</resources>|' $SX
cp app/src/main/res/drawable/ic_music_page.xml app/src/main/res/drawable/ic_pref_nav_music_hidden.xml
grep -q "val navMusicHidden" $SP || perl -0pi -e 's/val navLiveHidden: Boolean,/val navLiveHidden: Boolean,\n    val navMusicHidden: Boolean,/' $SP
grep -q "NAV_MUSIC_HIDDEN, false" $SP || perl -0pi -e 's/navLiveHidden = KV\.get\(HawkConfig\.NAV_LIVE_HIDDEN, false\),/navLiveHidden = KV.get(HawkConfig.NAV_LIVE_HIDDEN, false),\n        navMusicHidden = KV.get(HawkConfig.NAV_MUSIC_HIDDEN, false),/' $SP
python3 "$SCRIPT_DIR/insert_music_toggle.py"
echo "=== 音乐 tab 添加完成 ==="
