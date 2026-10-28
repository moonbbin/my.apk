#!/bin/bash
# 41 - 推荐页逻辑一期：长期+近期口味 3:1、打分排序、同歌手不相邻（post-40 补丁）
# 新脚本，build.yml 调用行由用户手动加（40 之后执行）。
set -e

python3 << 'PYEOF41V1'
import sys, os
P = "avbox/app/src/main/java/com/github/tvbox/osc/ui/music/recommend/RecommendScreen.kt"
while not os.path.exists(P) and os.getcwd() != "/":
    os.chdir("..")
if not os.path.exists(P):
    print("❌ 未找到 RecommendScreen.kt"); sys.exit(1)
s = open(P, encoding="utf-8").read()
if "[41v1]" in s:
    print("跳过（41 v1 已应用）"); sys.exit(0)

# --- 1) tasteProfile：长期+近期混合，返回 Top3 歌手 ---
old_start = "private fun tasteProfile(context: Context): Pair<String, List<TagWeight>> {"
assert s.count(old_start) == 1, "tasteProfile 锚点"
i = s.index(old_start)
end_mark = "    return top1 to tags\n}"
assert s.count(end_mark) == 1, "tasteProfile 尾锚点"
j = s.index(end_mark, i) + len(end_mark)
new_fn = '''private fun tasteProfile(context: Context): Triple<String, List<TagWeight>, List<String>> { // [41v1] 长期+近期混合
    val arr = historyArray(context)
    val all = (0 until arr.length()).mapNotNull { arr.optJSONObject(it) }
        .sortedByDescending { it.optLong("time", 0L) }
    val recent = all.take(30)
    val byArtist = recent.groupBy { it.optString("artist").trim() }
        .filterKeys { it.isNotEmpty() && it != "未知歌手" }
    val stats = byArtist.map { (a, list) -> Triple(a, list.size, list.maxOf { it.optLong("time", 0L) }) }
    val ranked = stats.sortedWith(compareByDescending<Triple<String, Int, Long>> { it.second }
        .thenByDescending { it.third })
    val top1 = ranked.firstOrNull()?.first.orEmpty()
    val topArtists = ranked.take(3).map { it.first }
    fun tagCounts(list: List<JSONObject>): LinkedHashMap<String, Int> {
        val m = LinkedHashMap<String, Int>()
        for (o in list) {
            val text = norm(o.optString("title")) + norm(o.optString("artist"))
            for (tag in TASTE_TAGS) {
                if (text.contains(norm(tag))) m[tag] = (m[tag] ?: 0) + 1
            }
        }
        return m
    }
    val recentCounts = tagCounts(recent)
    val longCounts = tagCounts(all.take(500))
    val blended = LinkedHashMap<String, Int>()
    for ((k, v) in longCounts) blended[k] = v * 3 + (recentCounts[k] ?: 0)
    for ((k, v) in recentCounts) if (k !in blended) blended[k] = v
    val tags = blended.entries.sortedByDescending { it.value }
        .map { TagWeight(it.key, it.value) }.take(3)
    return Triple(top1, tags, topArtists)
}'''
s = s[:i] + new_fn + s[j:]
assert "Triple(top1, tags, topArtists)" in s, "tasteProfile 替换未落位"

# --- 2) 调用点解构 ---
old = "val (top1, tagWeights) = tasteProfile(context)"
assert s.count(old) == 1, "tasteProfile 调用点"
s = s.replace(old, "val (top1, tagWeights, topArtists) = tasteProfile(context) // [41v1] 长期+近期混合", 1)
assert "topArtists) = tasteProfile(context)" in s, "调用点替换未落位"

# --- 3) 池版本 _v6 -> _v7（旧池强制重建） ---
old1 = 'prefs.getString("rec_pool_date", "") != today + "_v6"'
assert s.count(old1) == 1, "建池版本锚点"
s = s.replace(old1, 'prefs.getString("rec_pool_date", "") != today + "_v7"', 1)
old2 = '.putString("rec_pool_date", today + "_v6")'
assert s.count(old2) == 1, "存池版本锚点"
s = s.replace(old2, '.putString("rec_pool_date", today + "_v7")', 1)
old3 = "加 _v6，旧池强制重建"
assert s.count(old3) == 1, "版本注释锚点"
s = s.replace(old3, "加 _v7，旧池强制重建", 1)
assert '"_v7"' in s and "_v6" not in s, "版本升级未落位"

# --- 4) 打分（Meld 公式改编）：来源分 + 歌手亲和 + 标签命中 + 新近度 ---
old = "    for (item in (gen + diff).shuffled()) {"
assert s.count(old) == 1, "打乱循环锚点"
new = '''    // [41v1] 打分：来源分（标签组 15 / 扩散组 5）+ 歌手亲和（Top1 30 / 前三 20）+ 标签命中 20 + 新近度（7 天 15 / 30 天 8）
    val histArr = historyArray(context)
    val lastPlayed = mutableMapOf<String, Long>()
    for (hi in 0 until histArr.length()) {
        val o = histArr.optJSONObject(hi) ?: continue
        val k = norm(o.optString("artist"))
        if (k.isNotEmpty() && k != norm("未知歌手")) lastPlayed[k] = maxOf(lastPlayed[k] ?: 0L, o.optLong("time", 0L))
    }
    fun scoreParts(sg: RSong, base: Int): Int {
        val a = norm(sg.artist)
        var sc = base
        if (a.isNotEmpty()) {
            if (norm(top1).isNotEmpty() && (a.contains(norm(top1)) || norm(top1).contains(a))) sc += 30
            else if (topArtists.any { norm(it).isNotEmpty() && (a.contains(norm(it)) || norm(it).contains(a)) }) sc += 20
        }
        val text = norm(sg.title) + a
        if (tagWeights.any { text.contains(norm(it.name)) }) sc += 20
        val lp = lastPlayed[a] ?: 0L
        val now = System.currentTimeMillis()
        sc += when {
            lp > 0L && now - lp <= 7 * 86400000L -> 15
            lp > 0L && now - lp <= 30 * 86400000L -> 8
            else -> 0
        }
        return sc
    }
    val scoredGen = gen.map { it.copy(score = scoreParts(it.song, 15)) }
    val scoredDiff = diff.map { it.copy(score = scoreParts(it.song, 5)) }
    for (item in (scoredGen + scoredDiff).shuffled()) {'''
s = s.replace(old, new, 1)
assert "scoredGen" in s and "scoreParts" in s, "打分替换未落位"

# --- 5) 按分排（稳定排序，同分保持打乱顺序）+ 邻接重排（同歌手不相邻） ---
old = "    val capped = listOfNotNull(anchor) + cappedRest"
assert s.count(old) == 1, "成池锚点"
new = '''    // [41v1] 先按分排，再邻接重排：同歌手中间至少隔一张（锚点计入首位）
    val sortedRest = cappedRest.sortedByDescending { it.score }
    val ordered = listOfNotNull(anchor).toMutableList()
    val rest = sortedRest.toMutableList()
    while (rest.isNotEmpty()) {
        val lastA = ordered.lastOrNull()?.song?.artist?.let { norm(it) }
        val idx = rest.indexOfFirst { norm(it.song.artist) != lastA }
        if (idx < 0) { ordered += rest; break }
        ordered += rest.removeAt(idx)
    }
    val capped = ordered'''
s = s.replace(old, new, 1)
assert "val capped = ordered" in s, "成池替换未落位"

open(P, "w", encoding="utf-8").write(s)
s2 = open(P, encoding="utf-8").read()
assert "[41v1]" in s2 and "Triple(top1, tags, topArtists)" in s2 and "val capped = ordered" in s2, "写盘复核失败"
print("OK 41 v1 推荐逻辑一期已加")
PYEOF41V1
echo "=== 41 v1 完成 ==="

# === 41 v2: 负反馈两档（不感兴趣降权 14 天 + 不要再推荐全局屏蔽可撤销）===
python3 << 'PYEOF41V2A'
import sys, os
P = "avbox/app/src/main/java/com/github/tvbox/osc/ui/music/recommend/RecommendScreen.kt"
while not os.path.exists(P) and os.getcwd() != "/":
    os.chdir("..")
if not os.path.exists(P):
    print("❌ 未找到 RecommendScreen.kt"); sys.exit(1)
s = open(P, encoding="utf-8").read()
if "[41v2]" in s:
    print("跳过（41 v2 RecommendScreen 已应用）"); sys.exit(0)

def rep(old, new, tag):
    global s
    assert s.count(old) == 1, "锚点异常: " + tag
    s = s.replace(old, new, 1)

# import 按需补（已存在则不重复）
if "material3.AlertDialog" not in s:
    rep("import androidx.compose.material3.Text",
        "import androidx.compose.material3.Text\nimport androidx.compose.material3.AlertDialog", "AlertDialog import")
if "foundation.layout.Row" not in s:
    rep("import androidx.compose.foundation.layout.Box",
        "import androidx.compose.foundation.layout.Box\nimport androidx.compose.foundation.layout.Row", "Row import")
if "text.style.TextOverflow" not in s:
    rep("import androidx.compose.material3.Text",
        "import androidx.compose.material3.Text\nimport androidx.compose.ui.text.style.TextOverflow", "TextOverflow import")

# 负反馈读写 helper（插在 savePool 之前）
helpers = '''// [41v2] 负反馈：不感兴趣（歌手降权 14 天，到期自动恢复）+ 不要再推荐（歌手全局屏蔽，弹窗里可撤销）
private fun readDownweighted(prefs: android.content.SharedPreferences): Set<String> {
    val out = mutableSetOf<String>()
    val now = System.currentTimeMillis()
    try {
        val arr = JSONArray(prefs.getString("rec_down_json", "[]"))
        for (i in 0 until arr.length()) {
            val o = arr.optJSONObject(i) ?: continue
            if (now - o.optLong("t", 0L) > 14 * 86400000L) continue
            out += o.optString("k")
        }
    } catch (_: Exception) {}
    return out
}

private fun readBlocked(prefs: android.content.SharedPreferences): List<Pair<String, String>> {
    val out = mutableListOf<Pair<String, String>>()
    try {
        val arr = JSONArray(prefs.getString("rec_blocked_json", "[]"))
        for (i in 0 until arr.length()) {
            val o = arr.optJSONObject(i) ?: continue
            val k = o.optString("k")
            if (k.isNotEmpty()) out += k to o.optString("n", k)
        }
    } catch (_: Exception) {}
    return out
}

private fun addDownweight(prefs: android.content.SharedPreferences, artist: String): Boolean {
    val k = norm(artist)
    if (k.isEmpty()) return false
    val now = System.currentTimeMillis()
    val kept = JSONArray()
    try {
        val old = JSONArray(prefs.getString("rec_down_json", "[]"))
        for (i in 0 until old.length()) {
            val o = old.optJSONObject(i) ?: continue
            if (now - o.optLong("t", 0L) <= 14 * 86400000L && o.optString("k") != k) kept.put(o)
        }
    } catch (_: Exception) {}
    kept.put(JSONObject().apply { put("k", k); put("t", now) })
    prefs.edit().putString("rec_down_json", kept.toString()).apply()
    return true
}

private fun addBlock(prefs: android.content.SharedPreferences, artist: String): Boolean {
    val k = norm(artist)
    if (k.isEmpty()) return false
    val list = readBlocked(prefs).filterNot { it.first == k }.toMutableList()
    list += k to artist
    val arr = JSONArray()
    for ((kk, nn) in list) arr.put(JSONObject().apply { put("k", kk); put("n", nn) })
    prefs.edit().putString("rec_blocked_json", arr.toString()).apply()
    return true
}

private fun removeBlock(prefs: android.content.SharedPreferences, key: String) {
    val arr = JSONArray()
    for ((kk, nn) in readBlocked(prefs)) {
        if (kk != key) arr.put(JSONObject().apply { put("k", kk); put("n", nn) })
    }
    prefs.edit().putString("rec_blocked_json", arr.toString()).apply()
}

'''
rep("private fun savePool(", helpers + "private fun savePool(", "负反馈 helper")

# 建池：读降权与屏蔽
rep("    val excluded = readExcluded(prefs)",
    "    val excluded = readExcluded(prefs)\n    val downweighted = readDownweighted(prefs) // [41v2]\n    val blocked = readBlocked(prefs).map { it.first }.toSet() // [41v2]", "降权屏蔽读取")
# ok() 加屏蔽滤
rep("    fun ok(s: RSong) = songKey(s.title, s.artist) !in heard && songKey(s.title, s.artist) !in excluded",
    "    fun ok(s: RSong) = songKey(s.title, s.artist) !in heard && songKey(s.title, s.artist) !in excluded && norm(s.artist) !in blocked // [41v2]", "ok 屏蔽滤")
# 锚点跳过降权歌手
rep("    val anchor = if (top1.isNotEmpty()) {",
    "    val anchor = if (top1.isNotEmpty() && norm(top1) !in downweighted) { // [41v2] 降权歌手不做锚点", "锚点降权")
# 打分加降权罚分
rep("        if (tagWeights.any { text.contains(norm(it.name)) }) sc += 20",
    "        if (tagWeights.any { text.contains(norm(it.name)) }) sc += 20\n        if (downweighted.contains(a)) sc -= 40 // [41v2] 不感兴趣降权", "打分降权")

# 屏蔽管理状态 + 弹窗（插在下拉刷新状态之后）
rep("    val refreshState = rememberPullToRefreshState() // [40feel]",
    """    val refreshState = rememberPullToRefreshState() // [40feel]
    var blockedList by remember { mutableStateOf(readBlocked(context.getSharedPreferences(PREFS, Context.MODE_PRIVATE))) } // [41v2]
    var showBlocked by remember { mutableStateOf(false) } // [41v2]
    if (showBlocked) { // [41v2] 已屏蔽管理弹窗
        AlertDialog(
            onDismissRequest = { showBlocked = false },
            title = { Text("已屏蔽歌手", color = musicColors().textPrimary) },
            text = {
                Column {
                    if (blockedList.isEmpty()) {
                        Text("暂无屏蔽", color = musicColors().textSecondary)
                    } else {
                        blockedList.forEach { (k, n) ->
                            Row(
                                modifier = Modifier.fillMaxWidth().padding(vertical = 8.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(n, color = musicColors().textPrimary, modifier = Modifier.weight(1f), maxLines = 1, overflow = TextOverflow.Ellipsis)
                                Text(
                                    "取消屏蔽",
                                    color = musicColors().accent,
                                    modifier = Modifier.clickable {
                                        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                                        removeBlock(prefs, k)
                                        blockedList = readBlocked(prefs)
                                    }
                                )
                            }
                        }
                    }
                }
            },
            confirmButton = {
                Text(
                    "关闭",
                    color = musicColors().accent,
                    modifier = Modifier.clickable { showBlocked = false }
                )
            },
            containerColor = musicColors().card
        )
    }""", "屏蔽弹窗")

# 卡片回调（插在 onTogglePlay 之后）
rep("                onTogglePlay = { haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove); if (playing) onTogglePlay() else onPlayOnly(songs, idx) } // [40fin] 按钮播歌不进页",
    """                onTogglePlay = { haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove); if (playing) onTogglePlay() else onPlayOnly(songs, idx) } // [40fin] 按钮播歌不进页
                onNotInterested = { // [41v2]
                    val a = item.song.artist
                    val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                    if (addDownweight(prefs, a)) {
                        val k = norm(a)
                        fullPool = fullPool.filterNot { norm(it.song.artist) == k }
                        visible = visible.filterNot { norm(it.song.artist) == k }
                    }
                },
                onBlock = { // [41v2]
                    val a = item.song.artist
                    val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                    if (addBlock(prefs, a)) {
                        val k = norm(a)
                        fullPool = fullPool.filterNot { norm(it.song.artist) == k }
                        visible = visible.filterNot { norm(it.song.artist) == k }
                        blockedList = readBlocked(prefs)
                    }
                },""", "卡片回调")

# 列表尾管理入口（插在 loadingMore 块之后，全部加载完才露）
rep("""        if (loadingMore) {
            item {
                Box(Modifier.fillMaxWidth().padding(16.dp), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator()
                }
            }
        }""",
    """        if (loadingMore) {
            item {
                Box(Modifier.fillMaxWidth().padding(16.dp), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator()
                }
            }
        }
        if (visible.size >= fullPool.size && fullPool.isNotEmpty()) { // [41v2] 已屏蔽管理入口（全部加载完才露）
            item {
                Box(
                    Modifier.fillMaxWidth().padding(16.dp).clickable { showBlocked = true },
                    contentAlignment = Alignment.Center
                ) {
                    Text("已屏蔽歌手 · ${blockedList.size} 位，点击管理", color = musicColors().textSecondary)
                }
            }
        }""", "管理入口")

open(P, "w", encoding="utf-8").write(s)
s2 = open(P, encoding="utf-8").read()
assert "[41v2]" in s2 and "readBlocked" in s2 and "onBlock" in s2, "写盘复核失败"
print("OK 41 v2 RecommendScreen 负反馈已加")
PYEOF41V2A

python3 << 'PYEOF41V2B'
import sys, os
P = "avbox/app/src/main/java/com/github/tvbox/osc/ui/music/recommend/FeedCard.kt"
while not os.path.exists(P) and os.getcwd() != "/":
    os.chdir("..")
if not os.path.exists(P):
    print("❌ 未找到 FeedCard.kt"); sys.exit(1)
s = open(P, encoding="utf-8").read()
if "[41v2]" in s:
    print("跳过（41 v2 FeedCard 已应用）"); sys.exit(0)

def rep(old, new, tag):
    global s
    assert s.count(old) == 1, "锚点异常: " + tag
    s = s.replace(old, new, 1)

if "material3.DropdownMenu" not in s:
    rep("import androidx.compose.material3.Text",
        "import androidx.compose.material3.Text\nimport androidx.compose.material3.DropdownMenu\nimport androidx.compose.material3.DropdownMenuItem", "菜单 import")
if "runtime.remember" not in s:
    rep("import androidx.compose.runtime.getValue",
        "import androidx.compose.runtime.getValue\nimport androidx.compose.runtime.mutableStateOf\nimport androidx.compose.runtime.remember\nimport androidx.compose.runtime.setValue", "状态 import")

rep("    onTogglePlay: () -> Unit,",
    "    onTogglePlay: () -> Unit,\n    onNotInterested: () -> Unit, // [41v2]\n    onBlock: () -> Unit, // [41v2]", "菜单回调参数")
rep("    modifier: Modifier = Modifier\n) {",
    "    modifier: Modifier = Modifier\n) {\n    var menuExpanded by remember { mutableStateOf(false) } // [41v2]", "菜单状态")

start_mark = '        if (isPlaying) {\n            val t = rememberInfiniteTransition(label = "recGlow")'
assert s.count(start_mark) == 1, "辉光块锚点"
i = s.index(start_mark)
tail_mark = "\n    }\n}"
j = s.index(tail_mark, i)
menu = '''
        Box( // [41v2] 负反馈菜单：右上角黑圆 + 手搓三点
            modifier = Modifier.align(Alignment.TopEnd).padding(top = 12.dp, end = 12.dp)
        ) {
            Box(
                modifier = Modifier.size(28.dp)
                    .clip(CircleShape)
                    .background(Color.Black.copy(alpha = 0.35f))
                    .clickable { menuExpanded = true },
                contentAlignment = Alignment.Center
            ) {
                Canvas(Modifier.size(18.dp)) {
                    val white = Color.White
                    val r = 1.6.dp.toPx()
                    val cx = size.width / 2
                    drawCircle(white, r, Offset(cx, size.height * 0.25f))
                    drawCircle(white, r, Offset(cx, size.height * 0.5f))
                    drawCircle(white, r, Offset(cx, size.height * 0.75f))
                }
            }
            DropdownMenu(
                expanded = menuExpanded,
                onDismissRequest = { menuExpanded = false }
            ) {
                DropdownMenuItem(
                    text = { Text("不感兴趣") },
                    onClick = { menuExpanded = false; onNotInterested() }
                )
                DropdownMenuItem(
                    text = { Text("不要再推荐") },
                    onClick = { menuExpanded = false; onBlock() }
                )
            }
        }'''
s = s[:j] + menu + s[j:]
open(P, "w", encoding="utf-8").write(s)
s2 = open(P, encoding="utf-8").read()
assert "[41v2]" in s2 and "DropdownMenu" in s2 and "onBlock" in s2, "写盘复核失败"
print("OK 41 v2 FeedCard 负反馈菜单已加")
PYEOF41V2B
echo "=== 41 v2 完成 ==="

# === 41 v3: 构建红修复（v2 漏了 onTogglePlay 参数后的逗号）===
python3 << 'PYEOF41V3'
import sys, os
P = "avbox/app/src/main/java/com/github/tvbox/osc/ui/music/recommend/RecommendScreen.kt"
while not os.path.exists(P) and os.getcwd() != "/":
    os.chdir("..")
if not os.path.exists(P):
    print("❌ 未找到 RecommendScreen.kt"); sys.exit(1)
s = open(P, encoding="utf-8").read()
if "[41v3]" in s:
    print("跳过（41 v3 已应用）"); sys.exit(0)
old = "} // [40fin] 按钮播歌不进页\n                onNotInterested = {"
assert s.count(old) == 1, "锚点异常：v2 回调接点数量 %d" % s.count(old)
new = "}, // [40fin] 按钮播歌不进页 [41v3]\n                onNotInterested = {"
s = s.replace(old, new, 1)
open(P, "w", encoding="utf-8").write(s)
s2 = open(P, encoding="utf-8").read()
assert "}, // [40fin] 按钮播歌不进页 [41v3]" in s2, "写盘复核失败"
assert old not in s2, "旧接点仍在"
print("OK 41 v3 逗号已补")
PYEOF41V3
echo "=== 41 v3 完成 ==="

# === 41 v4: 分区排布 + 换一批 ===
python3 << 'PYEOF41V4'
import sys, os
P = "avbox/app/src/main/java/com/github/tvbox/osc/ui/music/recommend/RecommendScreen.kt"
while not os.path.exists(P) and os.getcwd() != "/":
    os.chdir("..")
if not os.path.exists(P):
    print("❌ 未找到 RecommendScreen.kt"); sys.exit(1)
s = open(P, encoding="utf-8").read()
if "[41v4]" in s:
    print("跳过（41 v4 已应用）"); sys.exit(0)

def rep(old, new, tag):
    global s
    assert s.count(old) == 1, "锚点异常: " + tag
    s = s.replace(old, new, 1)

# import 按需补
if "material3.MaterialTheme" not in s:
    rep("import androidx.compose.material3.Text",
        "import androidx.compose.material3.Text\nimport androidx.compose.material3.MaterialTheme", "MaterialTheme import")
if "lazy.stickyHeader" not in s:
    rep("import androidx.compose.foundation.lazy.items",
        "import androidx.compose.foundation.lazy.items\nimport androidx.compose.foundation.lazy.stickyHeader", "stickyHeader import")
if "foundation.ExperimentalFoundationApi" not in s:
    rep("import androidx.compose.foundation.layout.Box",
        "import androidx.compose.foundation.layout.Box\nimport androidx.compose.foundation.ExperimentalFoundationApi", "实验 API import")
rep("@Composable // [40tastefix]",
    "@OptIn(ExperimentalFoundationApi::class) // [41v4]\n@Composable // [40tastefix]", "OptIn 注解")

# 数据类加 section + 分区行类型 + 邻接重排 + 派生行
rep("data class RecommendItem(val song: RSong, val reason: String, val score: Int = 0)",
    """data class RecommendItem(val song: RSong, val reason: String, val score: Int = 0, val section: String = "") // [41v4]

// [41v4] 分区渲染行：标题行 + 卡片行（旧缓存 section 为空时只出卡片行）
private sealed interface DisplayRow {
    data class Header(val title: String) : DisplayRow
    data class Card(val item: RecommendItem) : DisplayRow
}

private fun sectionTitle(section: String): String = when (section) {
    "anchor" -> "因为你在听"
    "like" -> "猜你喜欢"
    "hot" -> "大家都在听"
    else -> ""
}

// [41v4] 邻接重排：同歌手中间至少隔一张，seedArtist 计入首位（锚点/上一区尾巴）
private fun noAdjacentOrder(items: List<RecommendItem>, seedArtist: String): List<RecommendItem> {
    val ordered = mutableListOf<RecommendItem>()
    val rest = items.toMutableList()
    var lastA: String? = seedArtist.ifEmpty { null }
    while (rest.isNotEmpty()) {
        val idx = rest.indexOfFirst { norm(it.song.artist) != lastA }
        if (idx < 0) { ordered += rest; break }
        val picked = rest.removeAt(idx)
        ordered += picked
        lastA = norm(picked.song.artist)
    }
    return ordered
}

// [41v4] 由 visible 派生渲染行
private fun buildDisplayRows(visible: List<RecommendItem>): List<DisplayRow> {
    val rows = mutableListOf<DisplayRow>()
    var lastSection = ""
    for (item in visible) {
        val sec = item.section
        if (sec.isNotEmpty() && sec != lastSection) {
            rows += DisplayRow.Header(sectionTitle(sec))
            lastSection = sec
        }
        rows += DisplayRow.Card(item)
    }
    return rows
}""", "分区类型")

# 持久化：section 入 JSON
rep("private fun songToJson(s: RSong, reason: String, score: Int): JSONObject = JSONObject().apply {",
    "private fun songToJson(s: RSong, reason: String, score: Int, section: String): JSONObject = JSONObject().apply {", "songToJson 签名")
rep('    put("reason", reason); put("score", score)',
    '    put("reason", reason); put("score", score); put("section", section)', "songToJson 字段")
rep('    return RecommendItem(s, o.optString("reason"), o.optInt("score"))',
    '    return RecommendItem(s, o.optString("reason"), o.optInt("score"), o.optString("section"))', "songFromJson 字段")
rep("arr.put(songToJson(item.song, item.reason, item.score))",
    "arr.put(songToJson(item.song, item.reason, item.score, item.section))", "savePool 调用")

# 池版本 _v7 -> _v8（两处 + 注释）
assert s.count('today + "_v7"') == 2, "版本锚点"
s = s.replace('today + "_v7"', 'today + "_v8"')
rep("rec_pool_date 加 _v7，旧池强制重建", "rec_pool_date 加 _v8，旧池强制重建", "版本注释")

# 锚点与打分区标记
rep('?.let { RecommendItem(it, listOf("因为你在听 $top1", "你的近期最爱", "重温 $top1 的经典").random(), 0) }',
    '?.let { RecommendItem(it, listOf("因为你在听 $top1", "你的近期最爱", "重温 $top1 的经典").random(), 0, "anchor") } // [41v4]', "锚点分区")
rep("    val scoredGen = gen.map { it.copy(score = scoreParts(it.song, 15)) }",
    '    val scoredGen = gen.map { it.copy(score = scoreParts(it.song, 15), section = "like") } // [41v4]', "标签组分区")
rep("    val scoredDiff = diff.map { it.copy(score = scoreParts(it.song, 5)) }",
    '    val scoredDiff = diff.map { it.copy(score = scoreParts(it.song, 5), section = "hot") } // [41v4]', "扩散组分区")

# 分区排序：替换 v1 全局排序块
start_mark = "    // [41v1] 先按分排，再邻接重排"
assert s.count(start_mark) == 1, "排序块锚点"
i = s.index(start_mark)
end_mark = "    val capped = ordered\n"
j = s.index(end_mark, i) + len(end_mark)
new_sort = """    // [41v4] 分区排序：每区内按分排 + 邻接重排（锚点计入猜你喜欢首位，猜你喜欢尾巴计入大家都在听首位）
    val cappedGen = cappedRest.filter { it.section == "like" }
    val cappedDiff = cappedRest.filter { it.section == "hot" }
    val anchorArtist = anchor?.song?.artist?.let { norm(it) } ?: ""
    val orderedGen = noAdjacentOrder(cappedGen.sortedByDescending { it.score }, anchorArtist)
    val genTailArtist = orderedGen.lastOrNull()?.song?.artist?.let { norm(it) } ?: ""
    val orderedDiff = noAdjacentOrder(cappedDiff.sortedByDescending { it.score }, genTailArtist)
    val capped = listOfNotNull(anchor) + orderedGen + orderedDiff
"""
s = s[:i] + new_sort + s[j:]

# 渲染行派生（visible 声明之后，切歌滚动之前）
rep("    var visible by remember { mutableStateOf<List<RecommendItem>>(emptyList()) }",
    """    var visible by remember { mutableStateOf<List<RecommendItem>>(emptyList()) }
    // [41v4] 分区渲染行：visible 顺序不变，按 section 变化插标题行
    val displayRows = remember(visible) { buildDisplayRows(visible) }""", "渲染行派生")

# 切歌滚动改按渲染行下标
rep("""    // [40scroll] 切歌时平滑滚到列表内原位置（索引按 visible 算）
    LaunchedEffect(playerTitle, playerArtist, visible.isEmpty()) {
        val index = visible.indexOfFirst { it.song.title == playerTitle && it.song.artist == playerArtist }
        if (index >= 0) listState.animateScrollToItem(index)
    }""",
    """    // [41v4] 切歌时平滑滚到列表内原位置（索引按渲染行算，含标题行）
    LaunchedEffect(playerTitle, playerArtist, visible.isEmpty()) {
        val index = displayRows.indexOfFirst { it is DisplayRow.Card && it.item.song.title == playerTitle && it.item.song.artist == playerArtist }
        if (index >= 0) listState.animateScrollToItem(index)
    }""", "切歌滚动")

# 视差改按渲染行下标（items 改写前先改，改写时整体缩进会带走）
rep("            val info = listState.layoutInfo.visibleItemsInfo.find { it.index == idx } // [40scroll] 视差下标合回 idx，displayed 退役",
    "            val info = listState.layoutInfo.visibleItemsInfo.find { it.index == displayRows.indexOf(row) } // [41v4] 视差按渲染行下标（含标题行）", "视差下标")

# 换一批置顶（LazyColumn 内第一块）
rep("""        contentPadding = PaddingValues(bottom = 160.dp) // [40scroll] 顶部让位删除，底 160 不动
    ) {""",
    """        contentPadding = PaddingValues(bottom = 160.dp) // [40scroll] 顶部让位删除，底 160 不动
    ) {
        stickyHeader { // [41v4] 换一批：纯打乱当前池（锚点首位不动），零网络，下拉刷新恢复按分排
            Box(
                Modifier.fillMaxWidth().background(musicColors().background).padding(end = 16.dp, top = 8.dp, bottom = 8.dp),
                contentAlignment = Alignment.CenterEnd
            ) {
                Text(
                    "换一批",
                    color = musicColors().accent,
                    modifier = Modifier.clickable {
                        val anchorItem = fullPool.firstOrNull { it.section == "anchor" }
                        val seed = anchorItem?.song?.artist?.let { norm(it) } ?: ""
                        val rest = fullPool.filterNot { it.section == "anchor" }.shuffled()
                        fullPool = listOfNotNull(anchorItem) + noAdjacentOrder(rest, seed)
                        visible = fullPool.take(20)
                        refreshScope.launch { listState.scrollToItem(0) }
                    }
                )
            }
        }""", "换一批")

# items 块整体改写：displayRows + 标题行 + 卡片分支（体部原样整体缩进 4 格）
start_mark = "        items(visible, key = "
assert s.count(start_mark) == 1, "items 锚点"
i = s.index(start_mark)
end_mark = "        if (loadingMore) {"
j = s.index(end_mark, i)
old_block = s[i:j].rstrip("\n")
lines = old_block.split("\n")
assert lines[0].startswith("        items(visible,"), "items 首行"
assert lines[-1] == "        }", "items 尾行"
body = lines[1:-1]
body_indented = ["    " + ln if ln.strip() else ln for ln in body]
new_block = '        items(displayRows, key = { row -> if (row is DisplayRow.Card) row.item.song.title + "|" + row.item.song.artist + "|" + row.item.song.platform else "header:" + (row as DisplayRow.Header).title }) { row ->\n'
new_block += "            if (row is DisplayRow.Header) {\n"
new_block += "                Text(row.title, color = musicColors().textPrimary, style = MaterialTheme.typography.titleMedium, modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp))\n"
new_block += "            }\n"
new_block += "            if (row is DisplayRow.Card) {\n"
new_block += "                val item = row.item\n"
new_block += "\n".join(body_indented) + "\n"
new_block += "            }\n"
new_block += "        }"
s = s[:i] + new_block + "\n" + s[j:]

open(P, "w", encoding="utf-8").write(s)
s2 = open(P, encoding="utf-8").read()
assert "[41v4]" in s2 and "displayRows" in s2 and "stickyHeader" in s2, "写盘复核失败"
assert '"_v7"' not in s2, "旧池版本仍在"
print("OK 41 v4 分区 + 换一批已加")
PYEOF41V4
echo "=== 41 v4 完成 ==="

# === 41 v5: 构建红修复（stickyHeader 在本工程 foundation 里不存在，改固定顶行）===
python3 << 'PYEOF41V5'
import sys, os
P = "avbox/app/src/main/java/com/github/tvbox/osc/ui/music/recommend/RecommendScreen.kt"
while not os.path.exists(P) and os.getcwd() != "/":
    os.chdir("..")
if not os.path.exists(P):
    print("❌ 未找到 RecommendScreen.kt"); sys.exit(1)
s = open(P, encoding="utf-8").read()
if "[41v5]" in s:
    print("跳过（41 v5 已应用）"); sys.exit(0)

def rep(old, new, tag):
    global s
    assert s.count(old) == 1, "锚点异常: " + tag
    s = s.replace(old, new, 1)

# 1) 删 stickyHeader 整块
i = s.index("        stickyHeader { // [41v4]")
j = s.index("        items(displayRows", i)
removed = s[i:j]
assert "换一批" in removed and removed.strip().endswith("}"), "置顶块边界"
s = s[:i] + s[j:]
# 2) 删 stickyHeader import、实验 API import 与 OptIn 注解
rep("import androidx.compose.foundation.lazy.stickyHeader\n", "", "删置顶 import")
rep("import androidx.compose.foundation.ExperimentalFoundationApi\n", "", "删实验 API import")
rep("@OptIn(ExperimentalFoundationApi::class) // [41v4]\n", "", "删 OptIn 注解")
# 3) 顶部固定换一批行 + Column 包裹（列表改 weight 占剩余空间）
rep("""        } else {
    LazyColumn(""",
    """        } else {
    Column(Modifier.fillMaxSize()) { // [41v5] 顶部换一批行固定在上，列表占剩余空间
        Box(
            Modifier.fillMaxWidth().background(musicColors().background).padding(end = 16.dp, top = 8.dp, bottom = 8.dp),
            contentAlignment = Alignment.CenterEnd
        ) {
            Text(
                "换一批",
                color = musicColors().accent,
                modifier = Modifier.clickable {
                    val anchorItem = fullPool.firstOrNull { it.section == "anchor" }
                    val seed = anchorItem?.song?.artist?.let { norm(it) } ?: ""
                    val rest = fullPool.filterNot { it.section == "anchor" }.shuffled()
                    fullPool = listOfNotNull(anchorItem) + noAdjacentOrder(rest, seed)
                    visible = fullPool.take(20)
                    refreshScope.launch { listState.scrollToItem(0) }
                }
            )
        }
        LazyColumn(""", "顶行包裹")
rep("        modifier = Modifier.fillMaxSize(),",
    "        modifier = Modifier.weight(1f), // [41v5] 列占剩余空间", "列表 weight")
# 4) 补 Column 闭合（LazyColumn 闭合之后）
rep("    }\n\n        }\n    }\n}",
    "    }\n    }\n\n        }\n    }\n}", "Column 闭合")

open(P, "w", encoding="utf-8").write(s)
s2 = open(P, encoding="utf-8").read()
assert "[41v5]" in s2 and "换一批" in s2, "写盘复核失败"
assert "stickyHeader" not in s2 and "ExperimentalFoundationApi" not in s2, "置顶残留"
print("OK 41 v5 置顶改固定顶行已加")
PYEOF41V5
echo "=== 41 v5 完成 ==="

# === 41 v6: 换一批黑条修复（去实底色，改小胶囊，壁纸透出）===
python3 << 'PYEOF41V6'
import sys, os
P = "avbox/app/src/main/java/com/github/tvbox/osc/ui/music/recommend/RecommendScreen.kt"
while not os.path.exists(P) and os.getcwd() != "/":
    os.chdir("..")
if not os.path.exists(P):
    print("❌ 未找到 RecommendScreen.kt"); sys.exit(1)
s = open(P, encoding="utf-8").read()
if "[41v6]" in s:
    print("跳过（41 v6 已应用）"); sys.exit(0)

def rep(old, new, tag):
    global s
    assert s.count(old) == 1, "锚点异常: " + tag
    s = s.replace(old, new, 1)

# 顶行去实底色（本页根是壁纸透出，实底色会刷出黑条）
rep("            Modifier.fillMaxWidth().background(musicColors().background).padding(end = 16.dp, top = 8.dp, bottom = 8.dp),",
    "            Modifier.fillMaxWidth().padding(end = 16.dp, top = 8.dp, bottom = 8.dp), // [41v6] 去实底色，壁纸透出", "顶行去底色")

# 换一批改小胶囊（黑 0.35f，与卡片 ⋮ 钮同款压图语言；点击区移到胶囊上）
start_mark = '            Text(\n                "换一批",'
assert s.count(start_mark) == 1, "换一批锚点"
i = s.index(start_mark)
end_mark = "                    refreshScope.launch { listState.scrollToItem(0) }\n                }\n            )\n        }"
j = s.index(end_mark, i) + len(end_mark)
new_span = """            Box(
                modifier = Modifier.clip(RoundedCornerShape(50))
                    .background(Color.Black.copy(alpha = 0.35f))
                    .padding(horizontal = 12.dp, vertical = 6.dp)
                    .clickable {
                        val anchorItem = fullPool.firstOrNull { it.section == "anchor" }
                        val seed = anchorItem?.song?.artist?.let { norm(it) } ?: ""
                        val rest = fullPool.filterNot { it.section == "anchor" }.shuffled()
                        fullPool = listOfNotNull(anchorItem) + noAdjacentOrder(rest, seed)
                        visible = fullPool.take(20)
                        refreshScope.launch { listState.scrollToItem(0) }
                    },
                contentAlignment = Alignment.Center
            ) {
                Text(
                    "换一批",
                    color = musicColors().accent
                )
            }
        }"""
s = s[:i] + new_span + s[j:]

open(P, "w", encoding="utf-8").write(s)
s2 = open(P, encoding="utf-8").read()
assert "[41v6]" in s2 and "Black.copy(alpha = 0.35f)" in s2, "写盘复核失败"
assert "background(musicColors().background)" not in s2, "实底色仍在"
print("OK 41 v6 换一批小胶囊已加")
PYEOF41V6
echo "=== 41 v6 完成 ==="

# === 41 v7: 三段式布局（锚点主角卡 + 大卡流 + 大家都在听横滑货架）===
python3 << 'PYEOF41V7A'
import sys, os
P = "avbox/app/src/main/java/com/github/tvbox/osc/ui/music/recommend/RecommendScreen.kt"
while not os.path.exists(P) and os.getcwd() != "/":
    os.chdir("..")
if not os.path.exists(P):
    print("❌ 未找到 RecommendScreen.kt"); sys.exit(1)
s = open(P, encoding="utf-8").read()
if "[41v7]" in s:
    print("跳过（41 v7 RecommendScreen 已应用）"); sys.exit(0)

def rep(old, new, tag):
    global s
    assert s.count(old) == 1, "锚点异常: " + tag
    s = s.replace(old, new, 1)

rep("import androidx.compose.foundation.lazy.LazyColumn\n",
    "import androidx.compose.foundation.lazy.LazyColumn\nimport androidx.compose.foundation.lazy.LazyRow // [41v7] 横滑货架\n", "货架 import")
rep("    data class Card(val item: RecommendItem) : DisplayRow\n}",
    "    data class Card(val item: RecommendItem) : DisplayRow\n    data class Shelf(val items: List<RecommendItem>) : DisplayRow // [41v7] 横滑货架行\n}", "货架行类型")

start_mark = "private fun buildDisplayRows(visible: List<RecommendItem>): List<DisplayRow> {"
i = s.index(start_mark)
end_mark = "    return rows\n}"
j = s.index(end_mark, i) + len(end_mark)
new_fn = """private fun buildDisplayRows(visible: List<RecommendItem>): List<DisplayRow> { // [41v7] hot 段收进一行货架
    val rows = mutableListOf<DisplayRow>()
    var lastSection = ""
    val shelfBuffer = mutableListOf<RecommendItem>()
    fun flushShelf() {
        if (shelfBuffer.isNotEmpty()) {
            rows += DisplayRow.Shelf(shelfBuffer.toList())
            shelfBuffer.clear()
        }
    }
    for (item in visible) {
        val sec = item.section
        if (sec == "hot") {
            if (lastSection != "hot") {
                rows += DisplayRow.Header(sectionTitle(sec))
                lastSection = "hot"
            }
            shelfBuffer += item
        } else {
            flushShelf()
            if (sec.isNotEmpty() && sec != lastSection) {
                rows += DisplayRow.Header(sectionTitle(sec))
                lastSection = sec
            }
            rows += DisplayRow.Card(item)
        }
    }
    flushShelf()
    return rows
}"""
s = s[:i] + new_fn + s[j:]

rep("val index = displayRows.indexOfFirst { it is DisplayRow.Card && it.item.song.title == playerTitle && it.item.song.artist == playerArtist }",
    "val index = displayRows.indexOfFirst { (it is DisplayRow.Card && it.item.song.title == playerTitle && it.item.song.artist == playerArtist) || (it is DisplayRow.Shelf && it.items.any { s -> s.song.title == playerTitle && s.song.artist == playerArtist }) } // [41v7] 货架行内找歌", "滚到货架歌")
rep("    LaunchedEffect(listState) {\n        snapshotFlow { listState.layoutInfo.visibleItemsInfo.lastOrNull()?.index ?: 0 }.collect { last ->",
    "    LaunchedEffect(listState, displayRows.size) { // [41v7] 行数变化重订（货架行使行数小于歌数）\n        snapshotFlow { listState.layoutInfo.visibleItemsInfo.lastOrNull()?.index ?: 0 }.collect { last ->", "分页重订")
rep("            if (visible.isEmpty() || last < visible.size - 3) return@collect",
    "            if (visible.isEmpty() || last < displayRows.size - 3) return@collect // [41v7] 按行数算（货架行）", "分页按行数")
rep('key = { row -> if (row is DisplayRow.Card) row.item.song.title + "|" + row.item.song.artist + "|" + row.item.song.platform else "header:" + (row as DisplayRow.Header).title }',
    'key = { row -> when (row) { is DisplayRow.Card -> row.item.song.title + "|" + row.item.song.artist + "|" + row.item.song.platform is DisplayRow.Header -> "header:" + row.title is DisplayRow.Shelf -> "shelf:hot" } }', "行定键")
rep("                FeedCard(\n                    item = item,\n",
    "                FeedCard(\n                    item = item,\n                    isHero = item.section == \"anchor\", // [41v7] 锚点主角卡\n", "主角卡参数")

old_tail = "                )\n            }\n        }\n        if (loadingMore) {"
assert s.count(old_tail) == 1, "锚点异常: 货架分支"
shelf_branch = """                )
            }
            if (row is DisplayRow.Shelf) { // [41v7] 横滑货架行
                val songs = visible.map { it.song }
                LazyRow(
                    modifier = Modifier.fillMaxWidth().height(120.dp),
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    contentPadding = PaddingValues(horizontal = 16.dp)
                ) {
                    items(row.items, key = { it.song.title + "|" + it.song.artist + "|" + it.song.platform }) { shelfItem ->
                        val sPlaying = playerTitle == shelfItem.song.title && playerArtist == shelfItem.song.artist
                        val sIdx = visible.indexOf(shelfItem)
                        ShelfCard(
                            item = shelfItem,
                            isPlaying = sPlaying && playerIsPlaying,
                            onClick = { haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove); onPlay(songs, sIdx) },
                            onTogglePlay = { haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove); if (sPlaying) onTogglePlay() else onPlayOnly(songs, sIdx) },
                            onNotInterested = {
                                val a = shelfItem.song.artist
                                val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                                if (addDownweight(prefs, a)) {
                                    val k = norm(a)
                                    fullPool = fullPool.filterNot { norm(it.song.artist) == k }
                                    visible = visible.filterNot { norm(it.song.artist) == k }
                                }
                            },
                            onBlock = {
                                val a = shelfItem.song.artist
                                val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                                if (addBlock(prefs, a)) {
                                    val k = norm(a)
                                    fullPool = fullPool.filterNot { norm(it.song.artist) == k }
                                    visible = visible.filterNot { norm(it.song.artist) == k }
                                    blockedList = readBlocked(prefs)
                                }
                            },
                        )
                    }
                }
            }
        }
        if (loadingMore) {"""
s = s.replace(old_tail, shelf_branch, 1)

open(P, "w", encoding="utf-8").write(s)
s2 = open(P, encoding="utf-8").read()
assert "[41v7]" in s2 and "shelf:hot" in s2 and "LazyRow" in s2 and "DisplayRow.Shelf" in s2 and "isHero" in s2, "写盘复核失败"
print("OK 41 v7 RecommendScreen 三段式已加")
PYEOF41V7A

python3 << 'PYEOF41V7B'
import sys, os
P = "avbox/app/src/main/java/com/github/tvbox/osc/ui/music/recommend/FeedCard.kt"
while not os.path.exists(P) and os.getcwd() != "/":
    os.chdir("..")
if not os.path.exists(P):
    print("❌ 未找到 FeedCard.kt"); sys.exit(1)
s = open(P, encoding="utf-8").read()
if "[41v7]" in s:
    print("跳过（41 v7 FeedCard 已应用）"); sys.exit(0)

def rep(old, new, tag):
    global s
    assert s.count(old) == 1, "锚点异常: " + tag
    s = s.replace(old, new, 1)

rep("    parallax: Float = 0f, // [40mag] 视差系数 -0.5~0.5\n",
    "    parallax: Float = 0f, // [40mag] 视差系数 -0.5~0.5\n    isHero: Boolean = false, // [41v7] 主角卡\n", "主角参数")
rep("            .height(200.dp) // [40compact] 240 -> 200",
    "            .height(if (isHero) 200.dp else 160.dp) // [41v7] 主角卡加高", "主角卡高")
rep("            modifier = Modifier.fillMaxWidth().height(240.dp)",
    "            modifier = Modifier.fillMaxWidth().height(if (isHero) 240.dp else 200.dp) // [41v7] 视差预留", "主角图高")
rep("                style = MaterialTheme.typography.headlineSmall.copy(shadow = Shadow(Color.Black.copy(alpha = 0.5f), blurRadius = 4f)), // [40fin] 标题放大极粗，弱阴影保留",
    "                style = (if (isHero) MaterialTheme.typography.headlineMedium else MaterialTheme.typography.headlineSmall).copy(shadow = Shadow(Color.Black.copy(alpha = 0.5f), blurRadius = 4f)), // [41v7] 主角标题大一号", "主角标题")

shelf_card = """
@Composable // [41v7] 横滑货架小卡：图 + 底渐变 + 标题/歌手 + 播放钮 + ⋮ 菜单，无理由胶囊
fun ShelfCard(
    item: RecommendItem,
    isPlaying: Boolean,
    onClick: () -> Unit,
    onTogglePlay: () -> Unit,
    onNotInterested: () -> Unit,
    onBlock: () -> Unit,
    modifier: Modifier = Modifier
) {
    var menuExpanded by remember { mutableStateOf(false) }
    Box(
        modifier = modifier
            .width(210.dp)
            .height(120.dp)
            .clip(RoundedCornerShape(20.dp))
            .background(musicColors().card)
            .border(1.dp, Color.White.copy(alpha = 0.15f), RoundedCornerShape(20.dp))
            .clickable { onClick() }
    ) {
        AsyncImage(
            model = item.song.picUrl,
            contentDescription = null,
            contentScale = ContentScale.Crop,
            modifier = Modifier.fillMaxSize()
        )
        Box(
            modifier = Modifier.align(Alignment.BottomCenter)
                .fillMaxWidth()
                .fillMaxHeight(0.4f)
                .background(
                    Brush.verticalGradient(
                        colors = listOf(Color.Transparent, Color.Black.copy(alpha = 0.8f))
                    )
                )
        )
        Column(
            modifier = Modifier.align(Alignment.BottomStart)
                .padding(start = 12.dp, bottom = 12.dp, end = 52.dp)
        ) {
            Text(
                item.song.title,
                color = Color.White,
                style = MaterialTheme.typography.titleMedium.copy(shadow = Shadow(Color.Black.copy(alpha = 0.5f), blurRadius = 4f)),
                fontWeight = FontWeight.Bold,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
            Text(
                "— " + item.song.artist.ifEmpty { "未知歌手" },
                color = Color.White.copy(alpha = 0.7f),
                style = MaterialTheme.typography.bodySmall,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
        }
        Box(
            modifier = Modifier.align(Alignment.BottomEnd)
                .padding(end = 12.dp, bottom = 12.dp)
                .size(36.dp)
                .clip(CircleShape)
                .border(1.dp, Color.White.copy(alpha = 0.6f), CircleShape)
                .clickable { onTogglePlay() },
            contentAlignment = Alignment.Center
        ) {
            Canvas(Modifier.size(18.dp)) {
                val sw = 1.5.dp.toPx()
                val cap = StrokeCap.Round
                val white = Color.White
                if (isPlaying) {
                    drawLine(white, Offset(6.dp.toPx(), 3.dp.toPx()), Offset(6.dp.toPx(), 15.dp.toPx()), sw, cap)
                    drawLine(white, Offset(12.dp.toPx(), 3.dp.toPx()), Offset(12.dp.toPx(), 15.dp.toPx()), sw, cap)
                } else {
                    drawPath(
                        Path().apply {
                            moveTo(6.dp.toPx(), 3.dp.toPx())
                            lineTo(14.dp.toPx(), 9.dp.toPx())
                            lineTo(6.dp.toPx(), 15.dp.toPx())
                            close()
                        },
                        white, style = Stroke(width = sw)
                    )
                }
            }
        }
        if (isPlaying) {
            val t = rememberInfiniteTransition(label = "recGlowShelf")
            val alpha by t.animateFloat(
                initialValue = 0.9f,
                targetValue = 0.25f,
                animationSpec = infiniteRepeatable(tween(1000), RepeatMode.Reverse),
                label = "recGlowShelfA"
            )
            Box(
                Modifier.matchParentSize()
                    .border(2.dp, musicColors().accent.copy(alpha = alpha), RoundedCornerShape(20.dp))
            )
        }
        Box(
            modifier = Modifier.align(Alignment.TopEnd).padding(top = 12.dp, end = 12.dp)
        ) {
            Box(
                modifier = Modifier.size(28.dp)
                    .clip(CircleShape)
                    .background(Color.Black.copy(alpha = 0.35f))
                    .clickable { menuExpanded = true },
                contentAlignment = Alignment.Center
            ) {
                Canvas(Modifier.size(18.dp)) {
                    val white = Color.White
                    val r = 1.6.dp.toPx()
                    val cx = size.width / 2
                    drawCircle(white, r, Offset(cx, size.height * 0.25f))
                    drawCircle(white, r, Offset(cx, size.height * 0.5f))
                    drawCircle(white, r, Offset(cx, size.height * 0.75f))
                }
            }
            DropdownMenu(
                expanded = menuExpanded,
                onDismissRequest = { menuExpanded = false }
            ) {
                DropdownMenuItem(
                    text = { Text("不感兴趣") },
                    onClick = { menuExpanded = false; onNotInterested() }
                )
                DropdownMenuItem(
                    text = { Text("不要再推荐") },
                    onClick = { menuExpanded = false; onBlock() }
                )
            }
        }
    }
}
"""
s = s.rstrip("\n") + "\n" + shelf_card
open(P, "w", encoding="utf-8").write(s)
s2 = open(P, encoding="utf-8").read()
assert "[41v7]" in s2 and "ShelfCard" in s2 and "isHero" in s2, "写盘复核失败"
print("OK 41 v7 FeedCard 主角卡 + 货架小卡已加")
PYEOF41V7B
echo "=== 41 v7 完成 ==="

# === 41 v8: 构建红修复（定键 when 三分支挤在一行被编译器粘成一个分支，改每分支独立行）===
python3 << 'PYEOF41V8'
import sys, os
P = "avbox/app/src/main/java/com/github/tvbox/osc/ui/music/recommend/RecommendScreen.kt"
while not os.path.exists(P) and os.getcwd() != "/":
    os.chdir("..")
if not os.path.exists(P):
    print("❌ 未找到 RecommendScreen.kt"); sys.exit(1)
s = open(P, encoding="utf-8").read()
if "[41v8]" in s:
    print("跳过（41 v8 已应用）"); sys.exit(0)

old = 'key = { row -> when (row) { is DisplayRow.Card -> row.item.song.title + "|" + row.item.song.artist + "|" + row.item.song.platform is DisplayRow.Header -> "header:" + row.title is DisplayRow.Shelf -> "shelf:hot" } }'
assert s.count(old) == 1, "锚点异常: 定键单行 when"
new = 'key = { row ->\n            when (row) { // [41v8] 分支各独立行（单行挤写会被粘成一个分支）\n                is DisplayRow.Card -> row.item.song.title + "|" + row.item.song.artist + "|" + row.item.song.platform\n                is DisplayRow.Header -> "header:" + row.title\n                is DisplayRow.Shelf -> "shelf:hot"\n            }\n        }'
s = s.replace(old, new, 1)

open(P, "w", encoding="utf-8").write(s)
s2 = open(P, encoding="utf-8").read()
assert "[41v8]" in s2, "写盘复核失败"
assert "platform is DisplayRow.Header" not in s2, "粘连仍在"
assert 'is DisplayRow.Shelf -> "shelf:hot"\n' in s2, "货架分支未独立成行"
print("OK 41 v8 定键 when 分支独立行已加")
PYEOF41V8
echo "=== 41 v8 完成 ==="

# === 41 v9: 排版二期（字阶/段标题/主角出血/主角两行/实心钮/胶囊缩短/顶部渐变）===
python3 << 'PYEOF41V9A'
import sys, os
P = "avbox/app/src/main/java/com/github/tvbox/osc/ui/music/recommend/RecommendScreen.kt"
while not os.path.exists(P) and os.getcwd() != "/":
    os.chdir("..")
if not os.path.exists(P):
    print("❌ 未找到 RecommendScreen.kt"); sys.exit(1)
s = open(P, encoding="utf-8").read()
if "[41v9]" in s:
    print("跳过（41 v9 RecommendScreen 已应用）"); sys.exit(0)

def rep(old, new, tag):
    global s
    assert s.count(old) == 1, "锚点异常: " + tag
    s = s.replace(old, new, 1)

rep("import androidx.compose.foundation.lazy.LazyRow // [41v7] 横滑货架\n",
    "import androidx.compose.foundation.lazy.LazyRow // [41v7] 横滑货架\nimport androidx.compose.foundation.layout.width // [41v9] 段标题横线间隔\nimport androidx.compose.ui.graphics.Shadow // [41v9] 段标题弱阴影\n", "段标题 import")
rep("                Text(row.title, color = musicColors().textPrimary, style = MaterialTheme.typography.titleMedium, modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp))",
    """                Row( // [41v9] 段标题绿横线 + 弱阴影
                    modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Box(Modifier.size(width = 20.dp, height = 3.dp).background(musicColors().accent))
                    Spacer(Modifier.width(8.dp))
                    Text(row.title, color = musicColors().textPrimary, style = MaterialTheme.typography.titleMedium.copy(shadow = Shadow(Color.Black.copy(alpha = 0.5f), blurRadius = 6f)))
                }""", "段标题行")

open(P, "w", encoding="utf-8").write(s)
s2 = open(P, encoding="utf-8").read()
assert "[41v9]" in s2 and "size(width = 20.dp, height = 3.dp)" in s2, "写盘复核失败"
print("OK 41 v9 RecommendScreen 段标题已加")
PYEOF41V9A

python3 << 'PYEOF41V9B'
import sys, os
P = "avbox/app/src/main/java/com/github/tvbox/osc/ui/music/recommend/FeedCard.kt"
while not os.path.exists(P) and os.getcwd() != "/":
    os.chdir("..")
if not os.path.exists(P):
    print("❌ 未找到 FeedCard.kt"); sys.exit(1)
s = open(P, encoding="utf-8").read()
if "[41v9]" in s:
    print("跳过（41 v9 FeedCard 已应用）"); sys.exit(0)

def rep(old, new, tag):
    global s
    assert s.count(old) == 1, "锚点异常: " + tag
    s = s.replace(old, new, 1)

rep("            .padding(horizontal = 16.dp)\n            .height(if (isHero) 200.dp else 160.dp)",
    "            .padding(horizontal = if (isHero) 0.dp else 16.dp) // [41v9] 主角卡左右顶边\n            .height(if (isHero) 200.dp else 160.dp)", "主角出血")
rep("                .graphicsLayer { translationY = parallax * 20.dp.toPx() }\n        )\n        // [40rb] 暗化层已删（全屏暗化禁用）",
    """                .graphicsLayer { translationY = parallax * 20.dp.toPx() }
        )
        Box( // [41v9] 顶部淡渐变，与底部对称
            modifier = Modifier.align(Alignment.TopCenter)
                .fillMaxWidth()
                .fillMaxHeight(0.25f)
                .background(
                    Brush.verticalGradient(
                        colors = listOf(Color.Black.copy(alpha = 0.35f), Color.Transparent)
                    )
                )
        )
        // [40rb] 暗化层已删（全屏暗化禁用）""", "顶部渐变")
rep('                timePrefix() + platformName(item.song.platform) + "精选 · " + item.reason, // [40tag] 时间前缀 + 平台精选 + 动态理由',
    '                timePrefix() + platformName(item.song.platform) + " · " + item.reason, // [41v9] 胶囊缩短', "胶囊缩短")
rep("                style = (if (isHero) MaterialTheme.typography.headlineMedium else MaterialTheme.typography.headlineSmall).copy(shadow = Shadow(Color.Black.copy(alpha = 0.5f), blurRadius = 4f)), // [41v7] 主角标题大一号",
    "                style = (if (isHero) MaterialTheme.typography.headlineMedium else MaterialTheme.typography.headlineSmall).copy(shadow = Shadow(Color.Black.copy(alpha = if (isHero) 0.5f else 0.35f), blurRadius = if (isHero) 4f else 6f)), // [41v9] 标准卡标题阴影收弱", "标题阴影")
rep("                fontWeight = FontWeight.Black, // [40fin]\n                maxLines = 1,",
    "                fontWeight = if (isHero) FontWeight.Black else FontWeight.ExtraBold, // [41v9] 标准卡标题降重\n                maxLines = if (isHero) 2 else 1, // [41v9] 主角标题两行", "标题字重行数")
rep("""                "— " + item.song.artist.ifEmpty { "未知歌手" }, // [40final] 落款格式
                color = Color.White.copy(alpha = 0.6f),
                style = MaterialTheme.typography.bodySmall, // [40final] bodyMedium -> bodySmall
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier.fillMaxWidth(), // [40fin] 右对齐落款
                textAlign = TextAlign.End // [40fin]
            )""",
    """                item.song.artist.ifEmpty { "未知歌手" }, // [41v9] 落款横线随右对齐去掉
                color = Color.White.copy(alpha = 0.85f),
                style = MaterialTheme.typography.bodySmall,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )""", "歌手行左对齐")
rep("""                .size(40.dp) // [40compact] 48 -> 40
                .clip(CircleShape)
                .border(1.dp, Color.White.copy(alpha = 0.6f), CircleShape) // [40mag] 极细白圈，无底色
                .clickable { onTogglePlay() },""",
    """                .size(40.dp) // [40compact] 48 -> 40
                .clip(CircleShape)
                .background(if (isPlaying) musicColors().accent else Color.White) // [41v9] 播放钮实心化
                .clickable { onTogglePlay() },""", "标准卡实心钮")
rep("""                .size(36.dp)
                .clip(CircleShape)
                .border(1.dp, Color.White.copy(alpha = 0.6f), CircleShape)
                .clickable { onTogglePlay() },""",
    """                .size(36.dp)
                .clip(CircleShape)
                .background(if (isPlaying) musicColors().accent else Color.White) // [41v9] 播放钮实心化
                .clickable { onTogglePlay() },""", "货架卡实心钮")

new_canvas = """            Canvas(Modifier.size(18.dp)) { // [41v9] 实心钮：白底/绿底 + 深色图标
                val cap = StrokeCap.Round
                val dark = Color.Black
                if (isPlaying) {
                    val bw = 3.dp.toPx()
                    drawLine(dark, Offset(6.dp.toPx(), 3.dp.toPx()), Offset(6.dp.toPx(), 15.dp.toPx()), bw, cap)
                    drawLine(dark, Offset(12.dp.toPx(), 3.dp.toPx()), Offset(12.dp.toPx(), 15.dp.toPx()), bw, cap)
                } else {
                    drawPath(
                        Path().apply {
                            moveTo(6.dp.toPx(), 3.dp.toPx())
                            lineTo(14.dp.toPx(), 9.dp.toPx())
                            lineTo(6.dp.toPx(), 15.dp.toPx())
                            close()
                        },
                        dark
                    )
                }
            }"""
old_canvas_feed = """            Canvas(Modifier.size(18.dp)) { // [40compact] 22 -> 18，等比缩
                val sw = 1.5.dp.toPx() // [40mag] 2 -> 1.5 细线
                val cap = StrokeCap.Round
                val white = Color.White
                if (isPlaying) {
                    drawLine(white, Offset(6.dp.toPx(), 3.dp.toPx()), Offset(6.dp.toPx(), 15.dp.toPx()), sw, cap)
                    drawLine(white, Offset(12.dp.toPx(), 3.dp.toPx()), Offset(12.dp.toPx(), 15.dp.toPx()), sw, cap)
                } else {
                    drawPath(
                        Path().apply {
                            moveTo(6.dp.toPx(), 3.dp.toPx())
                            lineTo(14.dp.toPx(), 9.dp.toPx())
                            lineTo(6.dp.toPx(), 15.dp.toPx())
                            close()
                        },
                        white, style = Stroke(width = sw) // [40mag] 单线三角，描边不填充
                    )
                }
            }"""
rep(old_canvas_feed, new_canvas, "标准卡图标")
old_canvas_shelf = old_canvas_feed.replace(" // [40compact] 22 -> 18，等比缩", "").replace(" // [40mag] 2 -> 1.5 细线", "").replace(" // [40mag] 单线三角，描边不填充", "")
rep(old_canvas_shelf, new_canvas, "货架卡图标")

rep("""            modifier = Modifier.fillMaxSize()
        )
        Box(
            modifier = Modifier.align(Alignment.BottomCenter)""",
    """            modifier = Modifier.fillMaxSize()
        )
        Box( // [41v9] 顶部淡渐变
            modifier = Modifier.align(Alignment.TopCenter)
                .fillMaxWidth()
                .fillMaxHeight(0.25f)
                .background(
                    Brush.verticalGradient(
                        colors = listOf(Color.Black.copy(alpha = 0.35f), Color.Transparent)
                    )
                )
        )
        Box(
            modifier = Modifier.align(Alignment.BottomCenter)""", "货架顶部渐变")
rep("""            Text(
                "— " + item.song.artist.ifEmpty { "未知歌手" },
                color = Color.White.copy(alpha = 0.7f),
                style = MaterialTheme.typography.bodySmall,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )""",
    """            Text(
                item.song.artist.ifEmpty { "未知歌手" }, // [41v9] 与标准卡同款副标题
                color = Color.White.copy(alpha = 0.85f),
                style = MaterialTheme.typography.bodySmall,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )""", "货架歌手行")
rep("import androidx.compose.ui.graphics.drawscope.Stroke // [40mag]\n", "", "删 Stroke import")
rep("import androidx.compose.ui.text.style.TextAlign // [40fin] 落款右对齐\n", "", "删 TextAlign import")

open(P, "w", encoding="utf-8").write(s)
s2 = open(P, encoding="utf-8").read()
assert "[41v9]" in s2 and "FontWeight.ExtraBold" in s2, "写盘复核失败"
assert s2.count("background(if (isPlaying) musicColors().accent else Color.White)") == 2, "实心钮未成对"
assert "精选" not in s2 and "Stroke(width" not in s2 and "TextAlign" not in s2, "旧物残留"
print("OK 41 v9 FeedCard 排版二期已加")
PYEOF41V9B
echo "=== 41 v9 完成 ==="

# === 41 v10: 段标题绿线换白点 ===
python3 << 'PYEOF41V10'
import sys, os
P = "avbox/app/src/main/java/com/github/tvbox/osc/ui/music/recommend/RecommendScreen.kt"
while not os.path.exists(P) and os.getcwd() != "/":
    os.chdir("..")
if not os.path.exists(P):
    print("❌ 未找到 RecommendScreen.kt"); sys.exit(1)
s = open(P, encoding="utf-8").read()
if "[41v10]" in s:
    print("跳过（41 v10 已应用）"); sys.exit(0)

def rep(old, new, tag):
    global s
    assert s.count(old) == 1, "锚点异常: " + tag
    s = s.replace(old, new, 1)

rep("import androidx.compose.foundation.shape.CircleShape // [40float]\n",
    "import androidx.compose.foundation.shape.CircleShape // [40float]\nimport androidx.compose.ui.draw.shadow // [41v10] 白点淡阴影\n", "白点阴影 import")
rep("                    Box(Modifier.size(width = 20.dp, height = 3.dp).background(musicColors().accent))",
    "                    Box(Modifier.size(8.dp).shadow(2.dp, CircleShape).background(Color.White, CircleShape)) // [41v10] 段标题白点", "绿线换白点")

open(P, "w", encoding="utf-8").write(s)
s2 = open(P, encoding="utf-8").read()
assert "[41v10]" in s2 and "size(8.dp).shadow(2.dp, CircleShape)" in s2, "写盘复核失败"
assert "size(width = 20.dp, height = 3.dp)" not in s2, "旧绿线残留"
print("OK 41 v10 段标题白点已加")
PYEOF41V10
echo "=== 41 v10 完成 ==="
