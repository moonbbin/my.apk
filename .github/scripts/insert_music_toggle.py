#!/usr/bin/env python3
# [base-a6da734e] round1 tvbox->avbox
# [base-a6da734e] round2 bridge
"""在 PreferenceSettingsPage.kt 插入'导航栏隐藏音乐'开关"""
import sys

PP = "app/src/main/java/com/github/avbox/osc/ui/page/PreferenceSettingsPage.kt"
s = open(PP).read()
if "settings_nav_music_hidden" in s:
    print("已存在，跳过")
    sys.exit(0)

# 新主体结构（旧主体是 SettingsPage + vm.put(HawkConfig.*) + state.*）：
# PreferenceSettingsPage 用 UiSettingsState.config（uiConfig）读、
# UiSettingsState.navLiveHidden = it 写；直播行是最后一个 SettingsCard(LAST)。
# 音乐行照同款：checked = uiConfig.navMusicHidden，
# onCheckedChange = { UiSettingsState.navMusicHidden = it }（KV 读写在 UiSettingsState 内）。

# 1. 把隐藏直播的 LAST 改成 MIDDLE
old_live = """                SettingsCard(SettingsCardPosition.LAST) {
                    SettingsSwitchRow(
                        title = stringResource(R.string.settings_nav_live_hidden),"""
new_live = """                SettingsCard(SettingsCardPosition.MIDDLE) {
                    SettingsSwitchRow(
                        title = stringResource(R.string.settings_nav_live_hidden),"""
assert s.count(old_live) == 1, "live anchor count %d" % s.count(old_live)
s = s.replace(old_live, new_live, 1)

# 2. 在直播块结束后追加音乐块
live_end = """                        onCheckedChange = { UiSettingsState.navLiveHidden = it },
                    )
                }"""
assert s.count(live_end) == 1, "live end count %d" % s.count(live_end)
music_block = live_end + """
                SettingsCard(SettingsCardPosition.LAST) {
                    SettingsSwitchRow(
                        title = stringResource(R.string.settings_nav_music_hidden),
                        leadingIconRes = R.drawable.ic_pref_nav_music_hidden,
                        subtitle = stringResource(R.string.settings_nav_music_hidden_subtitle),
                        checked = uiConfig.navMusicHidden,
                        onCheckedChange = { UiSettingsState.navMusicHidden = it },
                    )
                }"""
s = s.replace(live_end, music_block, 1)
assert s.count("{") == s.count("}"), "括号失衡"
open(PP, "w").write(s)
print("偏好设置 UI 已插入")
