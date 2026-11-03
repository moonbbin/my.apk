#!/bin/bash
# 43 v1: 车载蓝牙歌词接线（播放页侧，35 后补丁，build.yml 行用户加）
# 作用：行切换时把当前歌词行推给管理器（写进 MediaSession ARTIST，歌手位置），歌名不动；
# 更多弹窗加“车载蓝牙歌词”开关（默认开，写 lyric_settings 的 car_lyric）。
set -e
cd "$(dirname "$0")/../.."
PA="avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt"
[ -f "$PA" ] || { echo "X 43 v1 目标文件不存在: $PA"; exit 1; }
python3 << 'PYEOF43V1'
import sys
path = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt"
s = open(path, encoding="utf-8").read()
if "[43v1]" in s:
    print("跳过（43 v1 车载蓝牙歌词接线已应用）"); sys.exit(0)
def rep1(old, new, name):
    global s
    assert s.count(old) == 1, name
    s = s.replace(old, new, 1)

# import：Switch 与 DisposableEffect 各占独立行
rep1("import androidx.compose.material3.TextButton",
     "import androidx.compose.material3.TextButton\nimport androidx.compose.material3.Switch // [43v1]", "Switch import")
rep1("import androidx.compose.runtime.LaunchedEffect",
     "import androidx.compose.runtime.LaunchedEffect\nimport androidx.compose.runtime.DisposableEffect // [43v1]", "DisposableEffect import")
# 开关状态：跟 lyricPrefs 放一处，默认开
rep1('    val lyricLineCount = lyricPrefs.getInt("lyric_lines", 3)',
     '    val lyricLineCount = lyricPrefs.getInt("lyric_lines", 3)\n    var carLyricOn by remember { mutableStateOf(lyricPrefs.getBoolean("car_lyric", true)) } // [43v1] 车载蓝牙歌词开关（默认开）', "开关状态")
# 行切换推送 + 页面销毁清行：插在“跟随播放进度自动滚动到当前行”注释之前
rep1("    // 跟随播放进度自动滚动到当前行",
     """    // [43v1] 车载蓝牙歌词：行切换时把当前歌词行推给管理器，管理器写进 MediaSession ARTIST（歌手位置），歌名不动；无行时推 null 回落歌手
    LaunchedEffect(currentLyricIndex) {
        try { LxPlayerManager.updateCarLyricLine(lyricLines.getOrNull(currentLyricIndex)?.text) } catch (_: Exception) { }
    }
    // [43v1] 页面销毁时清掉车载歌词行，车机回落到歌手名
    DisposableEffect(Unit) {
        onDispose {
            try { LxPlayerManager.updateCarLyricLine(null) } catch (_: Exception) { }
        }
    }
    // 跟随播放进度自动滚动到当前行""", "行切换推送")
# 更多弹窗：播放速度标签之前加开关行 + 说明
rep1('                        Text("播放速度", color = PlayerGray, style = MaterialTheme.typography.labelMedium)',
     """                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text("车载蓝牙歌词", color = musicColors().textPrimary, style = MaterialTheme.typography.bodyMedium, modifier = Modifier.weight(1f)) // [43v1]
                            Switch(
                                checked = carLyricOn,
                                onCheckedChange = {
                                    carLyricOn = it
                                    try { lyricPrefs.edit().putBoolean("car_lyric", it).apply() } catch (_: Exception) { }
                                    try {
                                        if (it) LxPlayerManager.updateCarLyricLine(lyricLines.getOrNull(currentLyricIndex)?.text)
                                        else LxPlayerManager.updateCarLyricLine(null)
                                    } catch (_: Exception) { }
                                }
                            )
                        }
                        Text("开：车机歌手行显示当前歌词；关：显示歌手", color = PlayerGray, style = MaterialTheme.typography.bodySmall)
                        Spacer(modifier = Modifier.height(12.dp))
                        Text("播放速度", color = PlayerGray, style = MaterialTheme.typography.labelMedium)""", "更多弹窗开关")

assert s.count("43v1") == 6, "43v1 标记数异常"
assert s.count("LxPlayerManager.updateCarLyricLine") == 4, "updateCarLyricLine 调用数异常"
open(path, "w", encoding="utf-8").write(s)
print("OK 43 v1 车载蓝牙歌词接线已写")
PYEOF43V1
echo "=== 43 v1 完成 ==="
grep -q '43v1' "$PA" || { echo "X 43 v1 写入失败"; exit 1; }
echo "OK 43 v1 车载蓝牙歌词接线已写入"
