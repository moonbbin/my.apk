#!/usr/bin/env python3
import sys
ms_file = sys.argv[1]
with open(ms_file, 'r', encoding='utf-8') as f:
    ms = f.read()
old = "AppTab.FOLLOWING -> FollowingPage(contentPadding = pageContentPadding)"
# 按钮文字用字符串资源 R.string.tab_music（值为"音乐"），避免硬编码中文引号
new = old + "\n                                AppTab.MUSIC -> { val ctx = LocalContext.current; Box(modifier = Modifier.fillMaxSize(), contentAlignment = androidx.compose.ui.Alignment.Center) { androidx.compose.material3.Button(onClick = { ctx.startActivity(android.content.Intent(ctx, LxSourceSettingsActivity::class.java)) }) { androidx.compose.material3.Text(androidx.compose.ui.res.stringResource(id = R.string.tab_music)) } } }"
if old in ms and "AppTab.MUSIC" not in ms:
    ms = ms.replace(old, new)
    # 确保导入 stringResource
    if "import androidx.compose.ui.res.stringResource" not in ms:
        ms = ms.replace("import androidx.compose.ui.platform.LocalContext", "import androidx.compose.ui.platform.LocalContext\nimport androidx.compose.ui.res.stringResource")
    with open(ms_file, 'w', encoding='utf-8') as f:
        f.write(ms)
    print("MUSIC tab 已添加")
else:
    print("MUSIC tab 已存在或模式不匹配，跳过")
