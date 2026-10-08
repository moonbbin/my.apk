#!/usr/bin/env python3
"""在 MainScreen.kt 中添加 MUSIC tab 的内容分支"""
import sys

ms_file = sys.argv[1]

with open(ms_file, 'r', encoding='utf-8') as f:
    ms = f.read()

old = "AppTab.FOLLOWING -> FollowingPage(contentPadding = pageContentPadding)"
new = old + "\n                                AppTab.MUSIC -> { val ctx = LocalContext.current; Box(modifier = Modifier.fillMaxSize(), contentAlignment = androidx.compose.ui.Alignment.Center) { androidx.compose.material3.Button(onClick = { ctx.startActivity(Intent(ctx, LxSourceSettingsActivity::class.java)) }) { androidx.compose.material3.Text(\"进入音乐源管理\") } } }"

if old in ms and "AppTab.MUSIC" not in ms:
    ms = ms.replace(old, new)
    with open(ms_file, 'w', encoding='utf-8') as f:
        f.write(ms)
    print("MUSIC tab 已添加")
else:
    print("MUSIC tab 已存在或模式不匹配，跳过")
