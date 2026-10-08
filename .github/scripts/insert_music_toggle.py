#!/usr/bin/env python3
"""在 PreferenceSettingsPage.kt 插入'导航栏隐藏音乐'开关"""
import sys

PP = "app/src/main/java/com/github/tvbox/osc/ui/page/PreferenceSettingsPage.kt"
s = open(PP).read()
if "settings_nav_music_hidden" in s:
    print("已存在，跳过")
    sys.exit(0)

# 1. 把隐藏直播的 LAST 改成 MIDDLE
old_live = """                SettingsCard(SettingsCardPosition.LAST) {
                    SettingsSwitchRow(
                        title = stringResource(R.string.settings_nav_live_hidden),"""
new_live = """                SettingsCard(SettingsCardPosition.MIDDLE) {
                    SettingsSwitchRow(
                        title = stringResource(R.string.settings_nav_live_hidden),"""
assert old_live in s, "live anchor not found"
s = s.replace(old_live, new_live, 1)

# 2. 在直播块结束后追加音乐块
live_end = """                        onCheckedChange = { vm.put(HawkConfig.NAV_LIVE_HIDDEN, it) },
                    )
                }"""
assert live_end in s, "live end not found"
music_block = live_end + """
                SettingsCard(SettingsCardPosition.LAST) {
                    SettingsSwitchRow(
                        title = stringResource(R.string.settings_nav_music_hidden),
                        leadingIconRes = R.drawable.ic_pref_nav_music_hidden,
                        subtitle = stringResource(R.string.settings_nav_music_hidden_subtitle),
                        checked = state.navMusicHidden,
                        onCheckedChange = { vm.put(HawkConfig.NAV_MUSIC_HIDDEN, it) },
                    )
                }"""
s = s.replace(live_end, music_block, 1)
open(PP, "w").write(s)
print("偏好设置 UI 已插入")
