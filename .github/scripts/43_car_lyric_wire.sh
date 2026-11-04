#!/bin/bash
# 43 v1: 车载蓝牙歌词接线（播放页侧，35 后补丁，build.yml 行用户加）
# 作用：行切换时把当前歌词行推给管理器（写进 MediaSession ARTIST，歌手位置），歌名不动；
# 更多弹窗加“车载蓝牙歌词”开关（默认开，写 lyric_settings 的 car_lyric）。
# 43 v2: 更多弹窗里的开关组整个删掉；页进场时 LaunchedEffect(Unit) 把 car_lyric 写回 true，开关去掉后行为恒为开；不改 21 的 isCarLyricOn，不动 Manager。
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

python3 << 'PYEOF43V2'
import sys
path = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt"
s = open(path, encoding="utf-8").read()
if "[43v2]" in s:
    print("跳过（43 v2 开关移除已应用）"); sys.exit(0)
assert "[43v1]" in s, "43 v1 未应用，v2 无从删起"
def rep1(old, new, name):
    global s
    assert s.count(old) == 1, name
    s = s.replace(old, new, 1)

# 1. 删更多弹窗开关组（Row + 说明行 + 分隔 Spacer），播放速度行原地不动
old_switch = """                        Row(
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
"""
rep1(old_switch, "", "更多弹窗开关组删除")

# 2. 页进场默认开：插在 v1 的 DisposableEffect 块之后、跟随注释之前；沿用 v1 的 lyricPrefs 写法（lyric_settings），.apply()
rep1("""    // [43v1] 页面销毁时清掉车载歌词行，车机回落到歌手名
    DisposableEffect(Unit) {
        onDispose {
            try { LxPlayerManager.updateCarLyricLine(null) } catch (_: Exception) { }
        }
    }
    // 跟随播放进度自动滚动到当前行""",
"""    // [43v1] 页面销毁时清掉车载歌词行，车机回落到歌手名
    DisposableEffect(Unit) {
        onDispose {
            try { LxPlayerManager.updateCarLyricLine(null) } catch (_: Exception) { }
        }
    }
    // [43v2] 开关已移除，默认恒开：页进场时把 car_lyric 写回 true，开关去掉后行为仍为开
    LaunchedEffect(Unit) {
        try { lyricPrefs.edit().putBoolean("car_lyric", true).apply() } catch (_: Exception) { }
    }
    // 跟随播放进度自动滚动到当前行""", "页进场默认开")

# 后验：开关标签与说明行已删（状态行注释里还留有“车载蓝牙歌词”字样，故不做全串断言）；播放速度行不动；默认开写入在位；括号平衡
assert s.count('Text("车载蓝牙歌词"') == 0, "开关标签未删净"
assert s.count("开：车机歌手行显示当前歌词；关：显示歌手") == 0, "开关说明行未删净"
assert s.count('Text("播放速度"') == 1, "播放速度行受损"
assert s.count('putBoolean("car_lyric", true)') == 1, "默认开写入缺失"
assert s.count("43v2") == 1, "43v2 标记数异常"
for _ln in s.split("\n"):
    if "[43v2]" in _ln and "//" in _ln:
        _tail = _ln.split("//", 1)[1]
        assert not any(_c in _tail for _c in "{}()"), "marker ate code: " + _ln
assert s.count("{") == s.count("}"), "括号失衡"
open(path, "w", encoding="utf-8").write(s)
print("OK 43 v2 开关移除已写")
PYEOF43V2
echo "=== 43 v2 完成 ==="
grep -q '43v2' "$PA" || { echo "X 43 v2 写入失败"; exit 1; }
echo "OK 43 v2 开关移除已写入"
