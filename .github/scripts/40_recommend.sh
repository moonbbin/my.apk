#!/bin/bash
# 40_recommend.sh [40rec] 推荐 Tab（卡片式大图单列 Feed）：时效加权 Top3 + 收藏加成 + 平台偏好 + 已听排除 + 每日轮换 + 深挖扩展 + 每 8 张探索位；播放页/挂件/32/21/Manager/搜索 API 零改动
set -e
cd "$(dirname "$0")/../.." 2>/dev/null || true
mkdir -p avbox/app/src/main/java/com/github/tvbox/osc/ui/music/recommend
cat > avbox/app/src/main/java/com/github/tvbox/osc/ui/music/recommend/RecommendScreen.kt << 'EOF40REC'
package com.github.tvbox.osc.ui.music.recommend

import android.content.Context
import androidx.compose.foundation.gestures.snapping.rememberSnapFlingBehavior // [40final]
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
import androidx.compose.ui.hapticfeedback.HapticFeedbackType // [40final]
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalHapticFeedback // [40final]
import androidx.compose.ui.unit.dp
import com.github.tvbox.osc.ui.activity.LxMusicSearchApi
import com.github.tvbox.osc.ui.activity.musicColors
import androidx.compose.animation.core.RepeatMode // [40feel]
import androidx.compose.animation.core.animateFloat // [40feel]
import androidx.compose.animation.core.infiniteRepeatable // [40feel]
import androidx.compose.animation.core.rememberInfiniteTransition // [40feel]
import androidx.compose.animation.core.tween // [40feel]
import androidx.compose.foundation.Canvas // [40feel]
import androidx.compose.foundation.background // [40feel]
import androidx.compose.foundation.border // [40glass]
import androidx.compose.foundation.clickable // [40feel]
import androidx.compose.foundation.layout.Column // [40feel]
import androidx.compose.foundation.layout.Spacer // [40feel]
import androidx.compose.foundation.layout.height // [40feel]
import androidx.compose.foundation.layout.size // [40feel]
import androidx.compose.foundation.rememberScrollState // [40feel]
import androidx.compose.foundation.shape.RoundedCornerShape // [40feel]
import androidx.compose.foundation.verticalScroll // [40feel]
import androidx.compose.material3.pulltorefresh.PullToRefreshBox // [40feel]
import androidx.compose.material3.pulltorefresh.rememberPullToRefreshState // [40feel]
import androidx.compose.runtime.rememberCoroutineScope // [40feel]
import androidx.compose.ui.draw.clip // [40feel]
import androidx.compose.ui.geometry.Offset // [40feel]
import androidx.compose.ui.graphics.Brush // [40feel]
import androidx.compose.ui.graphics.Color // [40feel]
import androidx.compose.ui.graphics.StrokeCap // [40feel]
import androidx.compose.ui.graphics.drawscope.Stroke // [40feel]
import androidx.compose.ui.graphics.graphicsLayer // [40feel]
import kotlinx.coroutines.launch // [40feel]
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

private fun savePool(prefs: android.content.SharedPreferences, today: String, pool: List<RecommendItem>) { // [40feel] 快照退役
    val arr = JSONArray()
    for (item in pool) arr.put(songToJson(item.song, item.reason, item.score))
    prefs.edit().putString("rec_pool_date", today + "_v6").putString("rec_pool_json", arr.toString()).putString("rec_reason_ver", "mag1").apply() // [40feel] rec_pool_date 加 _v6，旧池强制重建
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

// [40taste] 口味标签词库
private val TASTE_TAGS = listOf("DJ", "电音", "民谣", "说唱", "钢琴", "摇滚", "古风", "粤语", "纯音乐", "爵士")

// [40feel] 口味文案池（建池时随机抽取，随池子存盘，渲染层不重抽）
private val TASTE_COPY: Map<String, List<String>> = mapOf(
    "民谣" to listOf("为你定制的民谣", "故事与吉他", "治愈系民谣"),
    "电音" to listOf("超燃电音派对", "跟着节奏抖腿", "深夜蹦迪指南"),
    "DJ" to listOf("超燃电音派对", "跟着节奏抖腿", "深夜蹦迪指南"),
    "说唱" to listOf("纯正街头说唱", "Flow 制造机"),
    "钢琴" to listOf("纯音静心", "专注时刻 BGM"),
    "纯音乐" to listOf("纯音静心", "专注时刻 BGM"),
    "摇滚" to listOf("摇滚不死", "释放灵魂的吉他"),
    "古风" to listOf("国风雅韵", "穿越千年的旋律"),
    "粤语" to listOf("港乐情怀", "粤语金曲"),
    "爵士" to listOf("慵懒爵士夜", "爵士微醺时刻")
)

// [40feel] 扩散词文案池
private val TERM_COPY: Map<String, List<String>> = mapOf(
    "热门推荐" to listOf("全网爆火", "大家都在听", "热歌风向标"),
    "抖音爆火" to listOf("短视频洗脑神曲", "刷屏级 BGM"),
    "华语流行" to listOf("华语金曲精选", "流行前线")
)

private fun pickCopy(pool: List<String>?) = pool?.randomOrNull() ?: "" // [40feel]

// [40taste] 口味标签带权重（count = 最近 30 首里命中次数）
private data class TagWeight(val name: String, val count: Int)

// [40taste] 特征提取：最近 30 首（time 倒序）→ Top1 + 带权重标签 Top3
private fun tasteProfile(context: Context): Pair<String, List<TagWeight>> {
    val arr = historyArray(context)
    val recent = (0 until arr.length()).mapNotNull { arr.optJSONObject(it) }
        .sortedByDescending { it.optLong("time", 0L) }.take(30)
    val byArtist = recent.groupBy { it.optString("artist").trim() }
        .filterKeys { it.isNotEmpty() && it != "未知歌手" }
    val stats = byArtist.map { (a, list) -> Triple(a, list.size, list.maxOf { it.optLong("time", 0L) }) }
    val top1 = stats.sortedWith(compareByDescending<Triple<String, Int, Long>> { it.second }
        .thenByDescending { it.third }).firstOrNull()?.first.orEmpty()
    val tagCount = LinkedHashMap<String, Int>()
    for (o in recent) {
        val text = norm(o.optString("title")) + norm(o.optString("artist"))
        for (tag in TASTE_TAGS) {
            if (text.contains(norm(tag))) tagCount[tag] = (tagCount[tag] ?: 0) + 1
        }
    }
    val tags = tagCount.entries.sortedByDescending { it.value }
        .map { TagWeight(it.key, it.value) }.take(3)
    return top1 to tags
}

// [40taste] 按权重配比取数：名额 = N × count / 总数，最大余数法补齐；单组不够时按权重顺位从剩余里补
private fun takeByWeight(groups: List<List<RecommendItem>>, weights: List<Int>, n: Int): List<RecommendItem> {
    val m = minOf(groups.size, weights.size)
    val g = groups.take(m)
    val w = weights.take(m)
    val total = w.sum().coerceAtLeast(1)
    val quotas = w.map { it * n / total }.toMutableList()
    val remainders = w.mapIndexed { i, c -> (c * n % total).toDouble() / total to i }
    var left = n - quotas.sum()
    val order = remainders.sortedByDescending { it.first }.map { it.second }
    var oi = 0
    while (left > 0 && oi < order.size) { quotas[order[oi]] += 1; left -= 1; oi += 1 }
    val out = mutableListOf<RecommendItem>()
    val leftovers = mutableListOf<RecommendItem>()
    for (i in g.indices) {
        out += g[i].take(quotas[i])
        if (g[i].size > quotas[i]) leftovers += g[i].drop(quotas[i])
    }
    if (out.size < n) out += leftovers.take(n - out.size)
    return out
}

// [40feel] 缓存池解析（节流回包与失败回旧池共用）
private fun readCache(prefs: android.content.SharedPreferences): List<RecommendItem> {
    return try {
        val arr = JSONArray(prefs.getString("rec_pool_json", "[]"))
        (0 until arr.length()).map { songFromJson(arr.getJSONObject(it)) }
    } catch (_: Exception) { emptyList() }
}

suspend fun buildRecommendPool(context: Context, force: Boolean = false): List<RecommendItem> { // [40feel] 节流建池
    recommendDeviceId(context)
    val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
    val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
    // [40feel] 节流 + 版本：非强制时，版本失配（新包首开/隔日首进）或距上次建池 >10 秒才重建，否则直接回缓存
    val versionMismatch = prefs.getString("rec_pool_date", "") != today + "_v6"
    if (!force && !versionMismatch) {
        val last = prefs.getLong("rec_last_build_ms", 0L)
        if (System.currentTimeMillis() - last <= 10_000L) {
            val cached = readCache(prefs)
            if (cached.isNotEmpty()) return cached
        }
    }
    val heard = heardKeys(context)
    val excluded = readExcluded(prefs)
    val (top1, tagWeights) = tasteProfile(context)
    fun ok(s: RSong) = songKey(s.title, s.artist) !in heard && songKey(s.title, s.artist) !in excluded
    fun matchArtist(list: List<RSong>, a: String) = list.filter {
        norm(it.artist).contains(norm(a)) || norm(a).contains(norm(it.artist))
    }.filter { songKey(it.title, it.artist) !in heard }
    // 锚点：Top1 的热门歌（第 1 张）；ok() 双滤（已听 + 排除项），无命中则缺席
    val anchor = if (top1.isNotEmpty()) {
        val list = try { LxMusicSearchApi.searchFull(top1) } catch (_: Exception) { emptyList() }
        matchArtist(list, top1).filter { s -> ok(s) }.firstOrNull()
            ?.let { RecommendItem(it, listOf("因为你在听 $top1", "你的近期最爱", "重温 $top1 的经典").random(), 0) }
    } else null
    // 泛化 20 首：按权重配比（零标签兜底：热门推荐取 20 首）
    val genLists: List<List<RecommendItem>>
    val genWeights: List<Int>
    if (tagWeights.isNotEmpty()) {
        genLists = tagWeights.map { tw ->
            val list = try { LxMusicSearchApi.searchFull(tw.name) } catch (_: Exception) { emptyList() }
            list.filter { s -> ok(s) }.take(20).map { RecommendItem(it, pickCopy(TASTE_COPY[tw.name]), 0) }
        }
        genWeights = tagWeights.map { it.count }
    } else {
        val list = try { LxMusicSearchApi.searchFull("热门推荐") } catch (_: Exception) { emptyList() }
        genLists = listOf(list.filter { s -> ok(s) }.take(20).map { RecommendItem(it, pickCopy(TERM_COPY["热门推荐"]), 0) })
        genWeights = listOf(1)
    }
    // 扩散 13 首：等权复用同一函数（无相似源，走热门推荐词库）
    val diffTerms = if (tagWeights.isNotEmpty()) listOf("热门推荐", "华语流行", "抖音爆火") else listOf("华语流行", "抖音爆火")
    val diffLists = diffTerms.map { term ->
        val list = try { LxMusicSearchApi.searchFull(term) } catch (_: Exception) { emptyList() }
        list.filter { s -> ok(s) }.take(20).map { RecommendItem(it, pickCopy(TERM_COPY[term]), 0) }
    }
    // 全局去重（锚点曲目也排除；跨标签同一首归最高权重标签）
    val seen = mutableSetOf<String>()
    anchor?.let { seen += songKey(it.song.title, it.song.artist) }
    fun dedup(l: List<RecommendItem>) = l.filter { seen.add(songKey(it.song.title, it.song.artist)) }
    val gen = takeByWeight(genLists.map { dedup(it) }, genWeights, 20)
    val diff = takeByWeight(diffLists.map { dedup(it) }, List(diffLists.size) { 1 }, 13)
    // 防刷屏：锚点歌手先计入 1，循环只跑打乱后的 rest，最后 prepend 锚点；同歌手最多 2 首
    val perArtist = mutableMapOf<String, Int>()
    anchor?.let { perArtist[norm(it.song.artist)] = 1 } // [40taste] 锚点歌手先计入
    val cappedRest = mutableListOf<RecommendItem>()
    for (item in (gen + diff).shuffled()) {
        val key = norm(item.song.artist)
        val c = perArtist[key] ?: 0
        if (c >= 2) continue
        perArtist[key] = c + 1
        cappedRest += item
    }
    val capped = listOfNotNull(anchor) + cappedRest
    prefs.edit().putLong("rec_last_build_ms", System.currentTimeMillis()).apply() // [40feel] 建池完成即写戳，成功失败都写
    if (capped.isEmpty()) {
        val cached = readCache(prefs)
        if (cached.isNotEmpty()) return cached // 失败不断线：旧池继续显示
        return emptyList() // 彻底失败：无缓存，入口显示断线空状态
    }
    savePool(prefs, today, capped)
    return capped
}

@Composable
private fun ShimmerCard() { // [40glass] 磨砂玻璃骨架：半透明底 + 极细白边 + 慢速微光
    val transition = rememberInfiniteTransition(label = "shimmer")
    val offset by transition.animateFloat(0f, 1f,
        infiniteRepeatable(tween(1500), RepeatMode.Restart), label = "shimmerOffset")
    Box(
        Modifier.fillMaxWidth().height(200.dp)
            .clip(RoundedCornerShape(20.dp))
            .background(musicColors().card.copy(alpha = 0.35f))
            .border(1.dp, Color.White.copy(alpha = 0.1f), RoundedCornerShape(20.dp))
    ) {
        Box(
            Modifier.fillMaxSize()
                .graphicsLayer { translationX = (offset * 2f - 1f) * size.width }
                .background(
                    Brush.horizontalGradient(
                        listOf(
                            Color.Transparent,
                            Color.White.copy(alpha = 0.15f),
                            Color.Transparent
                        )
                    )
                )
        )
    }
}

@Composable
private fun OfflineIcon() { // [40feel] 极简断线图标：圆圈 + 斜杠，2dp 线条
    val tint = musicColors().textSecondary
    Canvas(Modifier.size(64.dp)) {
        drawCircle(color = tint, radius = size.minDimension / 2f - 2.dp.toPx(), style = Stroke(width = 2.dp.toPx()))
        drawLine(
            color = tint,
            start = Offset(size.width * 0.28f, size.height * 0.28f),
            end = Offset(size.width * 0.72f, size.height * 0.72f),
            strokeWidth = 2.dp.toPx(),
            cap = StrokeCap.Round
        )
    }
}

@Composable // [40tastefix] 注解归位 RecommendScreen
fun RecommendScreen(
    playerTitle: String,
    playerArtist: String,
    playerIsPlaying: Boolean,
    onPlay: (List<RSong>, Int) -> Unit,
    onPlayOnly: (List<RSong>, Int) -> Unit, // [40fin] 按钮播歌不进页
    onTogglePlay: () -> Unit
) {
    val context = LocalContext.current
    val haptic = LocalHapticFeedback.current // [40final]
    val listState = rememberLazyListState()
    var fullPool by remember { mutableStateOf<List<RecommendItem>>(emptyList()) }
    var visible by remember { mutableStateOf<List<RecommendItem>>(emptyList()) }
    var loadingMore by remember { mutableStateOf(false) }
    var loadingFirst by remember { mutableStateOf(true) }
    var buildFailed by remember { mutableStateOf(false) } // [40feel] 建池彻底失败（无缓存）时显示断线空状态
    LaunchedEffect(Unit) { // [40feel] 节流建池：函数内裁决缓存/重建，shouldRefresh 退役
        val pool = buildRecommendPool(context, force = false)
        fullPool = pool
        visible = pool.take(20)
        loadingFirst = false
        buildFailed = pool.isEmpty()
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
    // [40final] 滚动换卡极微弱震动（跳过初始值）
    LaunchedEffect(listState) {
        var prev = -1
        snapshotFlow { listState.firstVisibleItemIndex }.collect { idx ->
            if (prev != -1 && idx != prev) haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
            prev = idx
        }
    }
    var isRefreshing by remember { mutableStateOf(false) } // [40feel] 下拉刷新状态
    val refreshScope = rememberCoroutineScope() // [40feel]
    val refreshState = rememberPullToRefreshState() // [40feel]
    PullToRefreshBox(
        isRefreshing = isRefreshing,
        onRefresh = {
            refreshScope.launch {
                isRefreshing = true
                val pool = buildRecommendPool(context, force = true) // force 绕过节流与版本门
                fullPool = pool
                visible = pool.take(20)
                loadingFirst = false
                buildFailed = pool.isEmpty()
                isRefreshing = false
            }
        },
        state = refreshState
    ) {
        if (loadingFirst) {
            Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(bottom = 160.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
                repeat(3) { ShimmerCard() }
            }
        } else if (visible.isEmpty()) {
            if (buildFailed) {
                Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState()), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.Center) {
                    OfflineIcon()
                    Spacer(Modifier.height(16.dp))
                    Text(
                        "网络开小差了，点击重试",
                        color = musicColors().textSecondary,
                        modifier = Modifier.clickable {
                            refreshScope.launch {
                                val pool = buildRecommendPool(context, force = true)
                                fullPool = pool
                                visible = pool.take(20)
                                loadingFirst = false
                                buildFailed = pool.isEmpty()
                            }
                        }
                    )
                }
            } else {
                Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Text("暂无推荐，去听几首歌再来", color = musicColors().textSecondary)
                }
            }
        } else {
    LazyColumn(
        state = listState,
        flingBehavior = rememberSnapFlingBehavior(listState), // [40final] 滑动吸附
        modifier = Modifier.fillMaxSize(),
        verticalArrangement = Arrangement.spacedBy(16.dp), // [40card] 卡间留白
        contentPadding = PaddingValues(bottom = 160.dp) // [40feed] 120 -> 160 终极避让
    ) {
        items(visible, key = { it.song.title + "|" + it.song.artist + "|" + it.song.platform }) { item ->
            val playing = playerTitle == item.song.title && playerArtist == item.song.artist
            val songs = visible.map { it.song }
            val idx = visible.indexOf(item)
            // [40mag] 视差系数：-0.5（视口顶）~ +0.5（视口底），居中为 0
            val info = listState.layoutInfo.visibleItemsInfo.find { it.index == idx }
            val vpH = listState.layoutInfo.viewportSize.height
            val parallax = if (info != null && vpH > 0)
                (info.offset + info.size / 2 - vpH / 2).toFloat() / vpH else 0f
            FeedCard(
                item = item,
                isPlaying = playing && playerIsPlaying,
                parallax = parallax, // [40mag]
                onClick = { haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove); onPlay(songs, idx) }, // [40final] 切歌极微弱震动
                onTogglePlay = { haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove); if (playing) onTogglePlay() else onPlayOnly(songs, idx) } // [40fin] 按钮播歌不进页
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
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row // [40mag]
import androidx.compose.foundation.layout.Spacer // [40mag]
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.fillMaxHeight // [40rb] 新增
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width // [40mag]
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur // [40rb] 新增
import androidx.compose.ui.draw.drawWithContent // [40poster]
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow // [40rb] 新增
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer // [40mag]
import androidx.compose.ui.graphics.BlendMode // [40poster]
import androidx.compose.ui.graphics.CompositingStrategy // [40poster]
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke // [40mag]
import androidx.compose.ui.graphics.Shadow // [40feed]
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign // [40fin] 落款右对齐
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp // [40feed]
import coil.compose.AsyncImage
import com.github.tvbox.osc.ui.activity.musicColors

// [40final] 平台码 -> 中文名，未知码 fallback 显示原码
private fun platformName(code: String): String = when (code) {
    "wy" -> "网易云"
    "tx", "qq" -> "QQ音乐"
    "kg" -> "酷狗"
    "kw" -> "酷我"
    "mg" -> "咪咕"
    else -> code
}

// [40tag] 时间前缀：深夜 > 周末 > 晨间/午后 > 无前缀；旧时间映射退役
private fun timePrefix(): String {
    val cal = java.util.Calendar.getInstance()
    val hour = cal.get(java.util.Calendar.HOUR_OF_DAY)
    val dow = cal.get(java.util.Calendar.DAY_OF_WEEK)
    val isWeekend = dow == java.util.Calendar.SATURDAY || dow == java.util.Calendar.SUNDAY
    return when {
        hour >= 22 || hour < 4 -> "深夜专属 · " // 22:00-04:00，04:00 整起退出；周六深夜仍显示深夜专属
        isWeekend -> "周末私藏 · "
        hour in 5..8 -> "晨间唤醒 · " // 05:00-09:00，09:00 整起退出
        hour in 12..13 -> "午后慵懒 · " // 12:00-14:00，14:00 整起退出
        else -> ""
    }
}

@Composable // [40dynfix] 注解归位 FeedCard
fun FeedCard(
    item: RecommendItem,
    isPlaying: Boolean,
    parallax: Float = 0f, // [40mag] 视差系数 -0.5~0.5
    onClick: () -> Unit,
    onTogglePlay: () -> Unit,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
            .height(200.dp) // [40compact] 240 -> 200
            .shadow(elevation = 24.dp, shape = RoundedCornerShape(20.dp), ambientColor = Color.Black.copy(alpha = 0.6f), spotColor = Color.Black) // [40fin] 高级弥散阴影，须在 clip 之前
            .clip(RoundedCornerShape(20.dp))
            .background(musicColors().card) // [40card2] 移到 clip 之后，底色也被裁圆
            .border(1.dp, Color.White.copy(alpha = 0.15f), RoundedCornerShape(20.dp)) // [40rb] 极细白边
            .clickable { onClick() }
    ) {
        AsyncImage( // [40rb] 底层模糊图
            model = item.song.picUrl,
            contentDescription = null,
            contentScale = ContentScale.Crop,
            modifier = Modifier.fillMaxWidth().height(240.dp) // [40mag] 图比卡高 40dp，留位移余量
                .align(Alignment.Center) // [40mag] 居中，上下各余 20dp
                .graphicsLayer { scaleX = 1.3f; scaleY = 1.3f; translationY = parallax * 20.dp.toPx(); alpha = 0.7f } // [40poster] 底层放大成氛围背景 // [40fin] 底层 0.7f，与 Fit 图融合
                .blur(25.dp)
        )
        AsyncImage( // [40poster] 顶层完整图 + 左右边缘渐隐
            model = item.song.picUrl,
            contentDescription = null,
            contentScale = ContentScale.Fit,
            modifier = Modifier.fillMaxWidth().height(240.dp)
                .align(Alignment.Center)
                .graphicsLayer {
                    translationY = parallax * 20.dp.toPx()
                    compositingStrategy = CompositingStrategy.Offscreen
                }
                .drawWithContent {
                    drawContent()
                    drawRect(
                        brush = Brush.horizontalGradient(
                            colorStops = arrayOf(
                                0f to Color.Transparent,
                                0.15f to Color.Black,
                                0.85f to Color.Black,
                                1f to Color.Transparent
                            )
                        ),
                        blendMode = BlendMode.DstIn
                    )
                }
        )
        // [40rb] 暗化层已删（全屏暗化禁用）
        Box( // [40rb] 渐变只占底部 40%
            modifier = Modifier.align(Alignment.BottomCenter)
                .fillMaxWidth()
                .fillMaxHeight(0.4f)
                .clip(RoundedCornerShape(20.dp))
                .background(
                    Brush.verticalGradient(
                        colors = listOf(Color.Transparent, Color.Black.copy(alpha = 0.8f))
                    )
                )
        )
        Row( // [40fin] 极淡黑胶囊底，压 poster 原文字
            modifier = Modifier.align(Alignment.TopStart).padding(top = 16.dp, start = 16.dp)
                .clip(RoundedCornerShape(50)).background(Color.Black.copy(alpha = 0.2f))
                .padding(horizontal = 10.dp, vertical = 5.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            if (isPlaying) { // [40final] 正在播放：标签左侧律动条
                val t = rememberInfiniteTransition(label = "recBars")
                for (i in 0 until 3) {
                    val h by t.animateFloat(4f, 12f, infiniteRepeatable(tween(500, delayMillis = i * 150), RepeatMode.Reverse), label = "bar$i")
                    Box(Modifier.padding(end = 2.dp).size(width = 3.dp, height = h.dp).clip(RoundedCornerShape(2.dp)).background(musicColors().accent))
                }
                Spacer(Modifier.width(8.dp))
            }
            Box(Modifier.size(width = 16.dp, height = 1.dp).background(Color.White.copy(alpha = 0.8f)))
            Spacer(Modifier.width(6.dp))
            Text(
                timePrefix() + platformName(item.song.platform) + "精选 · " + item.reason, // [40tag] 时间前缀 + 平台精选 + 动态理由
                color = Color.White, // [40final] 0.85f -> 纯白
                style = MaterialTheme.typography.labelSmall.copy(fontSize = 10.sp, letterSpacing = 1.sp), // [40mag]
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
        }
        Column(
            modifier = Modifier.align(Alignment.BottomStart)
                .padding(start = 12.dp, bottom = 12.dp, end = 56.dp) // [40compact] 16/16/76 -> 12/12/56
        ) {
            Text(
                item.song.title,
                color = Color.White,
                style = MaterialTheme.typography.headlineSmall.copy(shadow = Shadow(Color.Black.copy(alpha = 0.5f), blurRadius = 4f)), // [40fin] 标题放大极粗，弱阴影保留
                fontWeight = FontWeight.Black, // [40fin]
                maxLines = 1,
                overflow = TextOverflow.Ellipsis // [40final] 去 rotate，水平放置
            )
            Text(
                "— " + item.song.artist.ifEmpty { "未知歌手" }, // [40final] 落款格式
                color = Color.White.copy(alpha = 0.6f),
                style = MaterialTheme.typography.bodySmall, // [40final] bodyMedium -> bodySmall
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier.fillMaxWidth(), // [40fin] 右对齐落款
                textAlign = TextAlign.End // [40fin]
            )
        }
        Box(
            modifier = Modifier.align(Alignment.BottomEnd)
                .padding(end = 12.dp, bottom = 12.dp) // [40compact] 16/16 -> 12/12
                .size(40.dp) // [40compact] 48 -> 40
                .clip(CircleShape)
                .border(1.dp, Color.White.copy(alpha = 0.6f), CircleShape) // [40mag] 极细白圈，无底色
                .clickable { onTogglePlay() },
            contentAlignment = Alignment.Center
        ) {
            Canvas(Modifier.size(18.dp)) { // [40compact] 22 -> 18，等比缩
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
if '[40fin]' not in c:
    c = rep(c, '                        onPlay = { songs, i -> playSongs(context, songs, i) },',
        '                        onPlay = { songs, i -> playSongs(context, songs, i) },\n                        onPlayOnly = { songs, i -> playSongsOnly(songs, i) }, // [40fin] 按钮播歌不进页', '40fin 呼叫点')
    c = rep(c, '''    context.startActivity(intent)
}

/**
 * 通用歌曲行（spotufi 歌曲列表风格）''',
        '''    context.startActivity(intent)
}

/** 按钮播歌：只起播，不打开播放页（与 playSongs 区别仅在不 startActivity） */
fun playSongsOnly(
    songs: List<LxMusicSearchApi.SongInfo>,
    index: Int
) {
    if (songs.isEmpty() || index !in songs.indices) return
    val mapped = try {
        songs.map { s ->
            mapOf(
                "songId" to s.id,
                "title" to s.title,
                "artist" to s.artist,
                "platform" to s.platform,
                "hash" to s.hash,
                "albumAudioId" to s.albumAudioId,
                "picUrl" to s.picUrl,
                "quality" to s.quality
            )
        }
    } catch (e: Exception) { return }
    LxPlayerManager.setQueue(mapped, index)
    LxPlayerManager.resolveAndPlay(mapped[index])
}

/**
 * 通用歌曲行（spotufi 歌曲列表风格）''', '40fin playSongsOnly')
    save(MH, c)
    print('OK [40fin] 按钮播歌不进页')
else:
    print('SKIP [40fin] 已应用')
PYEOF40
echo "=== 40 rec 完成 ==="
