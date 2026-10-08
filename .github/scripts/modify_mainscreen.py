#!/usr/bin/env python3
"""修改 MainScreen.kt：添加 MUSIC tab 枚举、内容分支和必要的 import"""
import sys

MS = "app/src/main/java/com/github/tvbox/osc/ui/page/MainScreen.kt"

with open(MS, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. 添加 MUSIC 到 AppTab 枚举
old_enum = "FOLLOWING(R.string.tab_following, R.drawable.ic_tab_following),\n    SETTINGS"
new_enum = "FOLLOWING(R.string.tab_following, R.drawable.ic_tab_following),\n    MUSIC(R.string.tab_music, R.drawable.ic_tab_music),\n    SETTINGS"
if "MUSIC(R.string.tab_music" not in content:
    content = content.replace(old_enum, new_enum)
    print("✅ 枚举已添加")

# 2. 添加 MUSIC tab 内容分支（自动跳转到音乐专区）
old_branch = "AppTab.FOLLOWING -> FollowingPage(contentPadding = pageContentPadding)"
new_branch = old_branch + "\n                                AppTab.MUSIC -> { val ctx = LocalContext.current; Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) { Button(onClick = { ctx.startActivity(Intent(ctx, MusicHomeActivity::class.java)) }) { Text(\"进入音乐专区\") } } }"
if "AppTab.MUSIC ->" not in content:
    content = content.replace(old_branch, new_branch)
    print("✅ 内容分支已添加")

# 3. 添加必要的 import
imports = [
    ("import android.content.Intent", "import android.content.Intent\n"),
    ("import androidx.compose.ui.platform.LocalContext", "import androidx.compose.ui.platform.LocalContext\nimport androidx.compose.ui.res.stringResource\n"),
    ("import com.github.tvbox.osc.ui.activity.LxSourceSettingsActivity", None),  # 特殊处理
    ("import androidx.compose.foundation.layout.Box", None),
    ("import androidx.compose.foundation.layout.Column", None),
    ("import androidx.compose.foundation.layout.Spacer", None),
    ("import androidx.compose.foundation.layout.Arrangement", None),
    ("import androidx.compose.foundation.layout.height", None),
    ("import androidx.compose.ui.unit.dp", None),
    ("import androidx.compose.ui.Alignment", None),
    ("import androidx.compose.material3.Button", None),
    ("import androidx.compose.material3.Text", None),
    ("import androidx.compose.runtime.LaunchedEffect", None),
]

# 先确保基础 import 存在
if "import android.content.Intent" not in content:
    # 加到文件开头
    content = "import android.content.Intent\n" + content
    print("✅ Intent import 已添加")

if "import androidx.compose.ui.platform.LocalContext" not in content:
    content = content.replace("import android.content.Intent\n", "import android.content.Intent\nimport androidx.compose.ui.platform.LocalContext\nimport androidx.compose.ui.res.stringResource\n")
    print("✅ LocalContext/stringResource import 已添加")

if "LxSourceSettingsActivity" not in content or "import com.github.tvbox.osc.ui.activity.LxSourceSettingsActivity" not in content:
    content = content.replace("import androidx.compose.ui.res.stringResource\n", "import androidx.compose.ui.res.stringResource\nimport com.github.tvbox.osc.ui.activity.LxSourceSettingsActivity\n")
    print("✅ LxSourceSettingsActivity import 已添加")

# Box, Alignment, Button, Text - 使用完全限定名，已在代码中写全路径，无需 import
# 但为了简洁，代码中使用了 Box, Alignment, Button, Text 的短名，需要 import
for imp, _ in imports[3:]:
    if imp not in content:
        # 加到 LxSourceSettingsActivity 之后
        content = content.replace("import com.github.tvbox.osc.ui.activity.LxSourceSettingsActivity\n", f"import com.github.tvbox.osc.ui.activity.LxSourceSettingsActivity\n{imp}\n")
        print(f"✅ {imp} 已添加")

with open(MS, 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ MainScreen.kt 修改完成")
