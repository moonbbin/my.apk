#!/bin/bash
# 40_recommend.sh [40rec] 推荐 Tab（卡片式大图单列 Feed）：时效加权 Top3 + 收藏加成 + 平台偏好 + 已听排除 + 每日轮换 + 深挖扩展 + 每 8 张探索位；播放页/挂件/32/21/Manager/搜索 API 零改动
set -e
cd "$(dirname "$0")/../.." 2>/dev/null || true
mkdir -p avbox/app/src/main/java/com/github/tvbox/osc/ui/music/recommend
cat > avbox/app/src/main/java/com/github/tvbox/osc/ui/music/recommend/RecommendScreen.kt << 'EOF40REC'
package com.github.tvbox.osc.ui.music.recommend

import android.content.Context
import androidx.compose.foundation.layout.Arrangement // [40card] 新增
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues // [40card] 新增
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.github.tvbox.osc.ui.activity.LxMusicSearchApi
import com.github.tvbox.osc.ui.activity.musicColors
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

typealias RSong = LxMusicSearchApi.SongInfo
data class RecommendItem(val song: RSong, val reason: String, val score: Int = 0)

private const val PREFS = "recommend_prefs"
private fun norm(s: String) = s.filterNot { it.isWhitespace() }.lowercase()
private fun songKey(title: String, artist: String) = norm(title) + "|" + norm(artist)

// 设备标识：壁纸库同款 SecureRandom hex，只存不用（纯本地 v1 无消费点）
fun recommendDeviceId(context: Context): String {
    val sp = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
    sp.getString("rec_device_id", null)?.takeIf { it.isNotBlank() }?.let { return it }
    val bytes = ByteArray(16)
    java.security.SecureRandom().nextBytes(bytes)
    val id = bytes.joinToString("") { "%02x".format(it) }
    sp.edit().putString("rec_device_id", id).apply()
    return id
}

private fun historyArray(context: Context): JSONArray = try {
    JSONArray(context.getSharedPreferences("music_history", Context.MODE_PRIVATE)
        .getString("history_list", "[]"))
} catch (_: Exception) { JSONArray() }

private fun timeWeight(ms: Long): Int {
    val days = (System.currentTimeMillis() - ms) / 86400000L
    return when { days < 7 -> 3; days < 30 -> 2; else -> 1 }
}

private fun weightedTopArtists(context: Context): List<String> {
    val arr = historyArray(context)
    val counts = LinkedHashMap<String, Int>()
    for (i in 0 until minOf(arr.length(), 40)) {
        val o = arr.optJSONObject(i) ?: continue
        val artist = o.optString("artist").trim()
        if (artist.isEmpty() || artist == "未知歌手") continue
        counts[artist] = (counts[artist] ?: 0) + timeWeight(o.optLong("time", 0L))
    }
    return counts.entries.sortedByDescending { it.value }.take(6).map { it.key }
}

private fun favoriteArtists(context: Context): Set<String> {
    val out = mutableSetOf<String>()
    for ((_, v) in context.getSharedPreferences("favorites_detail", 0).all) {
        val artist = try { JSONObject(v as String).optString("artist").trim() } catch (_: Exception) { "" }
        if (artist.isNotEmpty()) out += artist
    }
    return out
}

private fun heardKeys(context: Context): Set<String> {
    val out = mutableSetOf<String>()
    val arr = historyArray(context)
    for (i in 0 until arr.length()) {
        val o = arr.optJSONObject(i) ?: continue
        out += songKey(o.optString("title"), o.optString("artist"))
    }
    for ((_, v) in context.getSharedPreferences("favorites_detail", 0).all) {
        try {
            val j = JSONObject(v as String)
            out += songKey(j.optString("title"), j.optString("artist"))
        } catch (_: Exception) {}
    }
    return out
}

private fun topPlatform(context: Context): String {
    val counts = LinkedHashMap<String, Int>()
    val arr = historyArray(context)
    for (i in 0 until minOf(arr.length(), 20)) {
        val p = arr.optJSONObject(i)?.optString("platform").orEmpty()
        if (p.isNotEmpty()) counts[p] = (counts[p] ?: 0) + 1
    }
    return counts.maxByOrNull { it.value }?.key ?: ""
}

// 轮询穿插：按艺人分组，轮流取每组最高分，防一艺人刷屏
private fun interleave(list: List<RecommendItem>): List<RecommendItem> {
    val byArtist = list.groupBy { norm(it.song.artist) }
    val order = byArtist.entries.sortedByDescending { it.value.first().score }.map { it.key }
    val iters = order.associateWith { byArtist[it]!!.iterator() }
    val out = mutableListOf<RecommendItem>()
    var progressed: Boolean
    do {
        progressed = false
        for (a in order) {
            val it = iters[a]!!
            if (it.hasNext()) { out += it.next(); progressed = true }
        }
    } while (progressed)
    return out
}

private fun songToJson(s: RSong, reason: String, score: Int): JSONObject = JSONObject().apply {
    put("id", s.id); put("title", s.title); put("artist", s.artist); put("album", s.album)
    put("duration", s.duration); put("platform", s.platform); put("picUrl", s.picUrl)
    put("hash", s.hash); put("albumAudioId", s.albumAudioId); put("quality", s.quality)
    put("reason", reason); put("score", score)
}

private fun songFromJson(o: JSONObject): RecommendItem {
    val s = RSong(
        id = o.optString("id"), title = o.optString("title"), artist = o.optString("artist"),
        album = o.optString("album"), duration = o.optLong("duration"),
        platform = o.optString("platform"), picUrl = o.optString("picUrl"),
        hash = o.optString("hash"), albumAudioId = o.optString("albumAudioId"),
        quality = o.optString("quality")
    )
    return RecommendItem(s, o.optString("reason"), o.optInt("score"))
}

private fun readExcluded(prefs: android.content.SharedPreferences): Set<String> {
    val out = mutableSetOf<String>()
    val now = System.currentTimeMillis()
    try {
        val arr = JSONArray(prefs.getString("rec_excluded_json", "[]"))
        for (i in 0 until arr.length()) {
            val o = arr.optJSONObject(i) ?: continue
            if (now - o.optLong("t", 0L) > 3 * 86400000L) continue
            val keys = o.optJSONArray("keys") ?: continue
            for (j in 0 until keys.length()) out += keys.optString(j)
        }
    } catch (_: Exception) {}
    return out
}

private fun savePool(prefs: android.content.SharedPreferences, today: String, pool: List<RecommendItem>) {
    val arr = JSONArray()
    for (item in pool) arr.put(songToJson(item.song, item.reason, item.score))
    prefs.edit().putString("rec_pool_date", today).putString("rec_pool_json", arr.toString()).apply()
    val now = System.currentTimeMillis()
    val old = try { JSONArray(prefs.getString("rec_excluded_json", "[]")) } catch (_: Exception) { JSONArray() }
    val kept = JSONArray()
    for (i in 0 until old.length()) {
        val o = old.optJSONObject(i) ?: continue
        if (now - o.optLong("t", 0L) <= 3 * 86400000L && o.optString("d") != today) kept.put(o)
    }
    val keys = JSONArray()
    for (item in pool) keys.put(songKey(item.song.title, item.song.artist))
    kept.put(JSONObject().apply { put("d", today); put("t", now); put("keys", keys) })
    prefs.edit().putString("rec_excluded_json", kept.toString()).apply()
}

suspend fun buildRecommendPool(context: Context): List<RecommendItem> {
    recommendDeviceId(context)
    val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
    val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
    if (prefs.getString("rec_pool_date", "") == today) {
        val cached = try {
            val arr = JSONArray(prefs.getString("rec_pool_json", "[]"))
            (0 until arr.length()).map { songFromJson(arr.getJSONObject(it)) }
        } catch (_: Exception) { emptyList() }
        if (cached.isNotEmpty()) return cached
    }
    val heard = heardKeys(context)
    val favArtists = favoriteArtists(context)
    val favNorm = favArtists.map { norm(it) }.toSet()
    val topPlat = topPlatform(context)
    val artists = weightedTopArtists(context).ifEmpty { favArtists.take(6) }
    fun scoreOf(s: RSong, base: Int): Int {
        var sc = base
        if (norm(s.artist) in favNorm) sc += 50
        if (topPlat.isNotEmpty() && s.platform == topPlat) sc += 20
        return sc
    }
    fun matchArtist(list: List<RSong>, a: String) = list.filter {
        norm(it.artist).contains(norm(a)) || norm(a).contains(norm(it.artist))
    }.filter { songKey(it.title, it.artist) !in heard }

    if (artists.isEmpty()) {
        val pool = mutableListOf<RecommendItem>()
        for (kw in listOf("华语流行", "抖音爆火", "怀旧经典")) {
            val list = try { LxMusicSearchApi.searchFull(kw) } catch (_: Exception) { emptyList() }
            list.filter { songKey(it.title, it.artist) !in heard }
                .take(15).forEach { pool += RecommendItem(it, "热门推荐 · $kw") }
        }
        val final = pool.distinctBy { songKey(it.song.title, it.song.artist) }.shuffled()
        savePool(prefs, today, final)
        return final
    }

    val mainArtists = artists.take(3)
    val expArtists = artists.drop(3)
    val rankWeight = listOf(100, 70, 40)
    val scored = mutableListOf<RecommendItem>()
    val tail = mutableListOf<RecommendItem>()
    for ((idx, a) in mainArtists.withIndex()) {
        val list = try { LxMusicSearchApi.searchFull(a) } catch (_: Exception) { emptyList() }
        val matched = matchArtist(list, a)
        matched.take(10).forEach { s -> scored += RecommendItem(s, "因为你常听 $a", scoreOf(s, rankWeight[idx])) }
        matched.drop(10).take(20).forEach { s -> tail += RecommendItem(s, "深挖 · $a", scoreOf(s, 25)) }
    }
    for (a in expArtists) {
        val list = try { LxMusicSearchApi.searchFull(a) } catch (_: Exception) { emptyList() }
        matchArtist(list, a).take(10).forEach { s -> tail += RecommendItem(s, "因为你常听 $a", scoreOf(s, 25)) }
    }
    val explore = mutableListOf<RecommendItem>()
    for (kw in listOf("华语流行", "抖音爆火", "怀旧经典")) {
        val list = try { LxMusicSearchApi.searchFull(kw) } catch (_: Exception) { emptyList() }
        list.filter { songKey(it.title, it.artist) !in heard }
            .take(5).forEach { explore += RecommendItem(it, "探索 · $kw") }
    }
    val seen = mutableSetOf<String>()
    val main = interleave(scored.sortedByDescending { it.score }
        .filter { seen.add(songKey(it.song.title, it.song.artist)) })
    val tailOrdered = interleave(tail.sortedByDescending { it.score }
        .filter { seen.add(songKey(it.song.title, it.song.artist)) })
    val exploreDedup = explore.filter { seen.add(songKey(it.song.title, it.song.artist)) }
    val pool = mutableListOf<RecommendItem>()
    var ei = 0
    for ((i, item) in main.withIndex()) {
        pool += item
        if ((i + 1) % 8 == 0 && ei < exploreDedup.size) pool += exploreDedup[ei++]
    }
    pool += tailOrdered
    val excluded = readExcluded(prefs)
    val filtered = pool.filter { songKey(it.song.title, it.song.artist) !in excluded }
    val final = if (filtered.size >= 10) filtered else pool
    savePool(prefs, today, final)
    return final
}

@Composable
fun RecommendScreen(
    playerTitle: String,
    playerArtist: String,
    playerIsPlaying: Boolean,
    onPlay: (List<RSong>, Int) -> Unit,
    onTogglePlay: () -> Unit
) {
    val context = LocalContext.current
    val listState = rememberLazyListState()
    var fullPool by remember { mutableStateOf<List<RecommendItem>>(emptyList()) }
    var visible by remember { mutableStateOf<List<RecommendItem>>(emptyList()) }
    var loadingMore by remember { mutableStateOf(false) }
    var loadingFirst by remember { mutableStateOf(true) }
    LaunchedEffect(Unit) {
        val pool = buildRecommendPool(context)
        fullPool = pool
        visible = pool.take(20)
        loadingFirst = false
    }
    LaunchedEffect(listState) {
        snapshotFlow { listState.layoutInfo.visibleItemsInfo.lastOrNull()?.index ?: 0 }.collect { last ->
            if (loadingFirst || loadingMore) return@collect
            if (visible.isEmpty() || last < visible.size - 3) return@collect
            val next = fullPool.drop(visible.size).take(20)
            if (next.isEmpty()) return@collect
            loadingMore = true
            visible = visible + next
            loadingMore = false
        }
    }
    if (loadingFirst) {
        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) { CircularProgressIndicator() }
        return
    }
    if (visible.isEmpty()) {
        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            Text("暂无推荐，去听几首歌再来", color = musicColors().textSecondary)
        }
        return
    }
    LazyColumn(
        state = listState,
        modifier = Modifier.fillMaxSize(),
        verticalArrangement = Arrangement.spacedBy(16.dp), // [40card] 卡间留白
        contentPadding = PaddingValues(bottom = 160.dp) // [40feed] 120 -> 160 终极避让
    ) {
        items(visible, key = { it.song.title + "|" + it.song.artist + "|" + it.song.platform }) { item ->
            val playing = playerTitle == item.song.title && playerArtist == item.song.artist
            val songs = visible.map { it.song }
            val idx = visible.indexOf(item)
            FeedCard(
                item = item,
                isPlaying = playing && playerIsPlaying,
                onClick = { onPlay(songs, idx) },
                onTogglePlay = { if (playing) onTogglePlay() else onPlay(songs, idx) }
            )
        }
        if (loadingMore) {
            item {
                Box(Modifier.fillMaxWidth().padding(16.dp), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator()
                }
            }
        }
    }
}
EOF40REC
cat > avbox/app/src/main/java/com/github/tvbox/osc/ui/music/recommend/FeedCard.kt << 'EOF40FEED'
package com.github.tvbox.osc.ui.music.recommend

import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.BorderStroke // [40card]
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.Shadow // [40feed]
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp // [40feed]
import coil.compose.AsyncImage
import com.github.tvbox.osc.ui.activity.musicColors

@Composable
fun FeedCard(
    item: RecommendItem,
    isPlaying: Boolean,
    onClick: () -> Unit,
    onTogglePlay: () -> Unit,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
            .height(200.dp) // [40compact] 240 -> 200
            .clip(RoundedCornerShape(20.dp))
            .background(musicColors().card) // [40card2] 移到 clip 之后，底色也被裁圆
            .clickable { onClick() }
    ) {
        AsyncImage(
            model = item.song.picUrl,
            contentDescription = null,
            contentScale = ContentScale.Crop,
            modifier = Modifier.fillMaxSize().clip(RoundedCornerShape(20.dp)) // [40card2] 内层裁剪
        )
        Box(
            modifier = Modifier.fillMaxSize().clip(RoundedCornerShape(20.dp)).background( // [40card2] 内层裁剪，clip 须在 background 之前
                Brush.verticalGradient(
                    colors = listOf(Color.Transparent, Color.Black.copy(alpha = 0.75f)),
                    startY = 0f,
                    endY = Float.POSITIVE_INFINITY
                )
            )
        )
        Surface(
            color = Color.Black.copy(alpha = 0.4f), // [40feed] 白 0.2f -> 黑 0.4f
            border = BorderStroke(0.5.dp, Color.White.copy(alpha = 0.3f)), // [40card] 极细白边
            shape = RoundedCornerShape(percent = 50),
            modifier = Modifier.align(Alignment.TopStart).padding(12.dp) // [40compact] 16 -> 12
        ) {
            Text(
                item.reason,
                color = Color.White,
                style = MaterialTheme.typography.labelSmall.copy(fontSize = 10.sp), // [40feed]
                modifier = Modifier.padding(horizontal = 8.dp, vertical = 3.dp) // [40compact] 10/5 -> 8/3
            )
        }
        Column(
            modifier = Modifier.align(Alignment.BottomStart)
                .padding(start = 12.dp, bottom = 12.dp, end = 56.dp) // [40compact] 16/16/76 -> 12/12/56
        ) {
            Text(
                item.song.title,
                color = Color.White,
                style = MaterialTheme.typography.titleMedium.copy(shadow = Shadow(Color.Black.copy(alpha = 0.5f), blurRadius = 4f)), // [40feed] 加阴影
                fontWeight = FontWeight.Bold,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
            Text(
                "· " + item.song.artist.ifEmpty { "未知歌手" }, // [40feed]
                color = Color.White.copy(alpha = 0.6f), // [40feed]
                style = MaterialTheme.typography.labelMedium, // [40feed] bodySmall -> labelMedium
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
        }
        Box(
            modifier = Modifier.align(Alignment.BottomEnd)
                .padding(end = 12.dp, bottom = 12.dp) // [40compact] 16/16 -> 12/12
                .size(40.dp) // [40compact] 48 -> 40
                .clip(CircleShape)
                .background(if (isPlaying) musicColors().accent else Color.White) // [40feed] 播放中切 accent
                .border(0.5.dp, Color.Black.copy(alpha = 0.15f), CircleShape) // [40card] 极细黑边
                .clickable { onTogglePlay() },
            contentAlignment = Alignment.Center
        ) {
            Canvas(Modifier.size(18.dp)) { // [40compact] 22 -> 18，等比缩
                val sw = 2.dp.toPx()
                val cap = StrokeCap.Round
                val black = Color.Black
                if (isPlaying) {
                    drawLine(black, Offset(6.dp.toPx(), 3.dp.toPx()), Offset(6.dp.toPx(), 15.dp.toPx()), sw, cap)
                    drawLine(black, Offset(12.dp.toPx(), 3.dp.toPx()), Offset(12.dp.toPx(), 15.dp.toPx()), sw, cap)
                } else {
                    drawPath(
                        Path().apply {
                            moveTo(6.dp.toPx(), 3.dp.toPx())
                            lineTo(14.dp.toPx(), 9.dp.toPx())
                            lineTo(6.dp.toPx(), 15.dp.toPx())
                            close()
                        },
                        black
                    )
                }
            }
        }
        if (isPlaying) {
            val t = rememberInfiniteTransition(label = "recGlow")
            val alpha by t.animateFloat(
                initialValue = 0.9f,
                targetValue = 0.25f,
                animationSpec = infiniteRepeatable(tween(1000), RepeatMode.Reverse),
                label = "recGlowA"
            )
            Box(
                Modifier.matchParentSize()
                    .border(2.dp, musicColors().accent.copy(alpha = alpha), RoundedCornerShape(20.dp)) // [40card] 16 -> 20，跟卡角对齐
            )
        }
    }
}
EOF40FEED
python3 << 'PYEOF40'
import io

BASE = 'avbox/app/src/main/java/com/github/tvbox/osc/'
MH = BASE + 'ui/activity/MusicHomeActivity.kt'

def load(p):
    with io.open(p, encoding='utf-8') as f:
        return f.read()

def save(p, s):
    with io.open(p, 'w', encoding='utf-8', newline='\n') as f:
        f.write(s)

def rep(s, old, new, tag, cnt=1):
    n = s.count(old)
    assert n == cnt, '❌ [40] %s 锚点数量异常: %d' % (tag, n)
    return s.replace(old, new, cnt)

c = load(MH)
if '[40rec]' not in c:
    c = rep(c, 'import androidx.compose.material3.*',
        'import androidx.compose.material3.*\nimport com.github.tvbox.osc.ui.music.recommend.RecommendScreen // [40rec]', '40rec import')
    c = rep(c, '    SEARCH, RANKING, PLAYLIST, SETTINGS, HOME',
        '    SEARCH, RANKING, RECOMMEND, PLAYLIST, SETTINGS, HOME // [40rec]', '40rec 枚举')
    c = rep(c, '                MusicTab.PLAYLIST -> {',
        '''                MusicTab.RECOMMEND -> { // [40rec]
                    RecommendScreen(
                        playerTitle = playerTitle,
                        playerArtist = playerArtist,
                        playerIsPlaying = playerIsPlaying,
                        onPlay = { songs, i -> playSongs(context, songs, i) },
                        onTogglePlay = { LxPlayerManager.togglePlayPause() }
                    )
                }
                MusicTab.PLAYLIST -> {''', '40rec 内容分支')
    c = rep(c, '                            MusicTab.RANKING to "排行",',
        '                            MusicTab.RANKING to "排行",\n                            MusicTab.RECOMMEND to "推荐", // [40rec]', '40rec 胶囊')
    c = rep(c, '''            MusicTab.HOME -> {
                drawLine(color = tint, start = off(4f, 11.5f), end = off(12f, 4.5f), strokeWidth = sw, cap = cap)
                drawLine(color = tint, start = off(20f, 11.5f), end = off(12f, 4.5f), strokeWidth = sw, cap = cap)''',
        '''            MusicTab.RECOMMEND -> { // [40rec] 推荐：心形（两圆 + V 线，2dp 圆头）
                drawCircle(color = tint, radius = 5.dp.toPx(), center = off(8.5f, 8f), style = androidx.compose.ui.graphics.drawscope.Stroke(width = sw))
                drawCircle(color = tint, radius = 5.dp.toPx(), center = off(15.5f, 8f), style = androidx.compose.ui.graphics.drawscope.Stroke(width = sw))
                drawLine(color = tint, start = off(4.5f, 11f), end = off(12f, 20f), strokeWidth = sw, cap = cap)
                drawLine(color = tint, start = off(19.5f, 11f), end = off(12f, 20f), strokeWidth = sw, cap = cap)
            }
            MusicTab.HOME -> {
                drawLine(color = tint, start = off(4f, 11.5f), end = off(12f, 4.5f), strokeWidth = sw, cap = cap)
                drawLine(color = tint, start = off(20f, 11.5f), end = off(12f, 4.5f), strokeWidth = sw, cap = cap)''', '40rec 图标')
    save(MH, c)
    print('OK [40rec] 推荐 Tab 接线完成')
else:
    print('SKIP [40rec] 已应用')
PYEOF40
echo "=== 40 rec 完成 ==="
