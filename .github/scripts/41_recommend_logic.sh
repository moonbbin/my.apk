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
