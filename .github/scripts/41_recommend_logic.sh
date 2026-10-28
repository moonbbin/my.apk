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
