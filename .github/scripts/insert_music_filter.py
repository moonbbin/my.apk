#!/usr/bin/env python3
"""在 MainScreen.kt 中添加音乐 tab 的隐藏过滤逻辑"""
import re

path = "app/src/main/java/com/github/tvbox/osc/ui/page/MainScreen.kt"
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. 在 pagerState 之前定义 navMusicHidden 和 visibleTabs
# pagerState 在 MainContent() 开头，需要先定义
old_pager = "    val pagerState = rememberPagerState(pageCount = { AppTab.entries.size })"
new_pager = """    var navMusicHidden by remember {
        mutableStateOf(KV.get(HawkConfig.NAV_MUSIC_HIDDEN, false))
    }
    val visibleTabs = remember(navMusicHidden) {
        AppTab.entries.filter { it != AppTab.MUSIC || !navMusicHidden }
    }
    val pagerState = rememberPagerState(pageCount = { visibleTabs.size })"""

if old_pager in content:
    content = content.replace(old_pager, new_pager)
    print("✅ navMusicHidden 和 visibleTabs 已在 pagerState 前定义")
else:
    print("⚠️ 未找到 pagerState")

# 2. 在 ON_RESUME 中更新 navMusicHidden
old2 = """    LifecycleEventEffect(Lifecycle.Event.ON_RESUME) {
        navAnimationEnabled = !KV.get(HawkConfig.NAV_ANIMATION_DISABLED, false)
        navLiveHidden = KV.get(HawkConfig.NAV_LIVE_HIDDEN, false)
    }"""
new2 = """    LifecycleEventEffect(Lifecycle.Event.ON_RESUME) {
        navAnimationEnabled = !KV.get(HawkConfig.NAV_ANIMATION_DISABLED, false)
        navLiveHidden = KV.get(HawkConfig.NAV_LIVE_HIDDEN, false)
        navMusicHidden = KV.get(HawkConfig.NAV_MUSIC_HIDDEN, false)
    }"""
if old2 in content:
    content = content.replace(old2, new2)
    print("✅ ON_RESUME 更新已添加")
else:
    print("⚠️ 未找到 ON_RESUME 块")

# 3. 替换其他 AppTab.entries 为 visibleTabs（注意：pagerState 已处理，跳过）
replacements = [
    ("val tabLabels = AppTab.entries.map { stringResource(it.labelRes) }",
     "val tabLabels = visibleTabs.map { stringResource(it.labelRes) }"),
    ("AppTab.entries.mapIndexed { index, tab -> GlassTabItem(tab.icon, tabLabels[index]) }",
     "visibleTabs.mapIndexed { index, tab -> GlassTabItem(tab.icon, tabLabels[index]) }"),
    ("AppTab.entries.forEachIndexed { index, tab ->",
     "visibleTabs.forEachIndexed { index, tab ->"),
    ("when (AppTab.entries[page]) {",
     "when (visibleTabs[page]) {"),
    ("NavMetrics.actionSlotFor(AppTab.entries.size)",
     "NavMetrics.actionSlotFor(visibleTabs.size)"),
]

for old, new in replacements:
    count = content.count(old)
    if count > 0:
        content = content.replace(old, new)
        print(f"✅ 替换 {count} 处: {old[:40]}...")
    else:
        print(f"⚠️ 未找到: {old[:40]}...")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("\n=== 音乐隐藏过滤逻辑添加完成 ===")
