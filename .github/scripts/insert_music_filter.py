#!/usr/bin/env python3
# [base-a6da734e] round1 tvbox->avbox
# [base-a6da734e] round2 bridge
"""在 MainScreen.kt 中添加音乐 tab 的隐藏过滤逻辑"""
import sys

path = "app/src/main/java/com/github/avbox/osc/ui/page/MainScreen.kt"
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

if "visibleTabs" in content:
    print("已存在，跳过")
    sys.exit(0)

# 新主体结构（旧主体是 pagerState 前 var navMusicHidden by remember +
# mutableStateOf(KV.get(HawkConfig.NAV_MUSIC_HIDDEN, false)) + ON_RESUME 重读）：
# 新 MainScreen 没有 ON_RESUME 块，导航状态统一走 UiSettingsState.config
#（mutableStateOf，改后自动重组；见 navConfig/navLiveHidden 一行，L169 附近）。
# 故 navMusicHidden 直接读 UiSettingsState.config.navMusicHidden，
# 在 pagerState 之前定义 visibleTabs；KV 读写只在 UiSettingsState 内。
old_pager = "    val pagerState = rememberPagerState(pageCount = { AppTab.entries.size })"
assert content.count(old_pager) == 1, "pagerState anchor count %d" % content.count(old_pager)
new_pager = """    val navMusicHidden = UiSettingsState.config.navMusicHidden
    val visibleTabs = remember(navMusicHidden) {
        AppTab.entries.filter { it != AppTab.MUSIC || !navMusicHidden }
    }
    val pagerState = rememberPagerState(pageCount = { visibleTabs.size })"""
content = content.replace(old_pager, new_pager)
print("✅ navMusicHidden 和 visibleTabs 已在 pagerState 前定义")

# ON_RESUME 一步已删除：新 MainScreen 无 ON_RESUME/LifecycleEventEffect 重读块，
# UiSettingsState.current 是 mutableStateOf，开关改值后 MainContent 自动重组，
# navMusicHidden 即取新值，无需手动重读。

# 其余 AppTab.entries 用 visibleTabs（pagerState 已处理，跳过）
replacements = [
    ("val tabLabels = AppTab.entries.map { stringResource(it.labelRes) }",
     "val tabLabels = visibleTabs.map { stringResource(it.labelRes) }", 1),
    ("AppTab.entries.mapIndexed { index, tab -> GlassTabItem(tab.icon, tabLabels[index]) }",
     "visibleTabs.mapIndexed { index, tab -> GlassTabItem(tab.icon, tabLabels[index]) }", 1),
    ("AppTab.entries.forEachIndexed { index, tab ->",
     "visibleTabs.forEachIndexed { index, tab ->", 2),
    ("when (AppTab.entries[page]) {",
     "when (visibleTabs[page]) {", 1),
    ("NavMetrics.actionSlotFor(AppTab.entries.size)",
     "NavMetrics.actionSlotFor(visibleTabs.size)", 2),
]

for old, new, expected in replacements:
    count = content.count(old)
    assert count == expected, "anchor count %d != %d: %r" % (count, expected, old[:60])
    content = content.replace(old, new)
    print(f"✅ 替换 {count} 处: {old[:40]}...")

# 后验：AppTab.entries 只剩 visibleTabs 定义里的一处；括号平衡
assert content.count("AppTab.entries") == 1, "AppTab.entries 残留 %d 处" % content.count("AppTab.entries")
assert content.count("{") == content.count("}"), "括号失衡"
assert content.count("(") == content.count(")"), "圆括号失衡"

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("\n=== 音乐隐藏过滤逻辑添加完成 ===")
