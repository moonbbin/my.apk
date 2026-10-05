package com.tvbox.shell.ui.detail

import android.util.Log
import com.tvbox.shell.config.UserPreference
import com.tvbox.shell.model.Site
import com.tvbox.shell.model.Vod
import com.tvbox.shell.parse.ParseManager
import com.tvbox.shell.parser.EpisodeGroup
import com.tvbox.shell.parser.HomeContentParser
import com.tvbox.shell.spider.SpiderManager
import com.tvbox.shell.spider.SpiderNull
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/**
 * 点一集后的播放状态机（UI 消费约定跟 DetailScreen 的注释对齐）。
 *
 * - [Idle]：没点过（或上一次消费完了）；
 * - [Loading]：正在拿播放地址（全屏"正在解析播放地址…"）；
 * - [Success]：拿到直链 → UI 跳 [com.tvbox.shell.player.PlayerActivity]；
 * - [Sniff]：直链拿不到 → UI 跳 [com.tvbox.shell.parse.WebSniffActivity] 嗅探；
 * - [Error]：失败 → UI 弹 Snackbar。
 *
 * 每次消费完 UI 必须调 [onPlayResultHandled] 复位成 [Idle]，
 * 否则从播放器返回会被再跳一次。
 */
sealed class PlayState {
    object Idle : PlayState()
    object Loading : PlayState()
    data class Success(val videoUrl: String, val headers: Map<String, String> = emptyMap()) : PlayState()

    /** 需要 WebView 嗅探：UI 跳嗅探页。 */
    data class Sniff(val pageUrl: String, val title: String = "") : PlayState()
    data class Error(val message: String) : PlayState()
}

/** 详情/剧集表加载状态。 */
sealed class DetailLoadState {
    object Idle : DetailLoadState()
    object Loading : DetailLoadState()
    data class Failed(val message: String) : DetailLoadState()

    companion object {
        /** 网络/解析这类"临时问题"的失败文案——只有它才给"重试"按钮。 */
        const val MSG_DETAIL_FAILED = "详情没取回来，检查网络后重试"
    }
}

/**
 * 详情页 ViewModel（普通类，不是 AndroidX ViewModel）。
 *
 * 没接 lifecycle-viewmodel-compose 依赖，所以用 `remember { DetailViewModel(…) }`
 * 建、用 [release] 拆（DetailScreen 里已经这么写了，这里对齐）。
 *
 * 职责：
 * - [loadDetail]：调引擎 `detailContent` 拿剧集表 + 补全 Vod（幂等）；
 * - [onPlayEpisode]：点一集 → 直链直跳 / 走解析链 / 扔给嗅探；
 * - [recommendFlow]：**需求1** 底部"相关推荐"，按分类/片名搜一批同类片。
 */
class DetailViewModel(
    private val site: Site,
    vod: Vod,
    private val spiderManager: SpiderManager = SpiderManager(),
    private val ioDispatcher: CoroutineDispatcher = Dispatchers.IO
) {

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

    private val _vodState = MutableStateFlow(vod)
    val vodState: StateFlow<Vod> = _vodState.asStateFlow()

    private val _episodeGroupsFlow =
        MutableStateFlow(HomeContentParser.splitEpisodeGroups(vod))
    val episodeGroupsFlow: StateFlow<List<EpisodeGroup>> = _episodeGroupsFlow.asStateFlow()

    private val _detailLoadState = MutableStateFlow<DetailLoadState>(DetailLoadState.Idle)
    val detailLoadState: StateFlow<DetailLoadState> = _detailLoadState.asStateFlow()

    private val _playEpisodeState = MutableStateFlow<PlayState>(PlayState.Idle)
    val playEpisodeState: StateFlow<PlayState> = _playEpisodeState.asStateFlow()

    private val _recommendFlow = MutableStateFlow<List<Vod>>(emptyList())

    /** 底部"相关推荐"（需求1）。失败就空表，不影响详情主体。 */
    val recommendFlow: StateFlow<List<Vod>> = _recommendFlow.asStateFlow()

    private var detailJob: Job? = null
    private var playJob: Job? = null
    private var recommendJob: Job? = null
    private var detailLoaded = false

    /**
     * 取详情（幂等：已取过 / 正在取时再调不发请求）。
     *
     * 列表页点进来时 vod 通常只有 id/name/pic，剧集表和简介要靠这次请求补。
     * vodId 为空（调用方直接给了完整 Vod 的场景）就跳过网络，直接拆本地的播放串。
     */
    fun loadDetail() {
        if (detailLoaded || detailJob?.isActive == true) return
        val current = _vodState.value
        if (current.vodId.isBlank()) {
            // 没 id 可查：本地有播放串就拆，没有就给"源没给剧集"的失败态
            val groups = HomeContentParser.splitEpisodeGroups(current)
            _episodeGroupsFlow.value = groups
            if (groups.isEmpty()) {
                _detailLoadState.value = DetailLoadState.Failed("这个源没有可播放的剧集")
            }
            detailLoaded = true
            loadRecommend()
            return
        }
        _detailLoadState.value = DetailLoadState.Loading
        detailJob = scope.launch {
            try {
                val spider = withContext(ioDispatcher) {
                    spiderManager.resolveSpider(site.api, site.extString)
                }
                if (spider is SpiderNull) {
                    _detailLoadState.value =
                        DetailLoadState.Failed("站点 ${site.name} 的采集引擎未加载")
                    return@launch
                }
                val json = withContext(ioDispatcher) {
                    spider.detailContent(listOf(current.vodId))
                }
                if (json.isBlank()) {
                    _detailLoadState.value =
                        DetailLoadState.Failed(DetailLoadState.MSG_DETAIL_FAILED)
                    return@launch
                }
                val result = HomeContentParser.parseDetail(json, current)
                _vodState.value = result.vod
                _episodeGroupsFlow.value = result.groups
                _detailLoadState.value = if (result.groups.isEmpty()) {
                    DetailLoadState.Failed("这个源没有可播放的剧集")
                } else {
                    DetailLoadState.Idle
                }
                detailLoaded = true
                loadRecommend()
            } catch (e: CancellationException) {
                throw e
            } catch (t: Throwable) {
                Log.e(TAG, "详情加载失败：${t.javaClass.simpleName}: ${t.message}")
                _detailLoadState.value =
                    DetailLoadState.Failed(DetailLoadState.MSG_DETAIL_FAILED)
            }
        }
    }

    /** 只有"临时失败"才给重试（跟 UI 的 EmptyEpisodeHint 对齐）。 */
    fun retryDetail() {
        detailLoaded = false
        detailJob?.cancel()
        loadDetail()
    }

    /**
     * 点了一集：拿播放地址。
     *
     * 顺序：直链 → 引擎 playerContent → 解析接口 → 嗅探。
     * 过程中状态机按 Loading → Success / Sniff / Error 走，UI 按约定消费。
     */
    fun onPlayEpisode(flag: String, episodeUrl: String) {
        playJob?.cancel()
        val clean = episodeUrl.trim()
        if (clean.isEmpty()) {
            _playEpisodeState.value = PlayState.Error("这个剧集没有播放地址")
            return
        }
        _playEpisodeState.value = PlayState.Loading
        playJob = scope.launch {
            try {
                // 1) 直链：直接播
                if (ParseManager.isDirectMedia(clean)) {
                    _playEpisodeState.value = PlayState.Success(clean)
                    return@launch
                }
                // 2) 引擎二次解析
                val spider = withContext(ioDispatcher) {
                    spiderManager.resolveSpider(site.api, site.extString)
                }
                var candidate = clean
                var headers: Map<String, String> = emptyMap()
                var needParse = true
                if (spider !is SpiderNull) {
                    val json = withContext(ioDispatcher) {
                        spider.playerContent(flag, clean, emptyList())
                    }
                    val info = HomeContentParser.parsePlayer(json)
                    if (info.url.isNotBlank()) {
                        candidate = info.url
                        headers = info.headers
                        needParse = info.needParse
                    }
                }
                if (!needParse && ParseManager.isDirectMedia(candidate)) {
                    _playEpisodeState.value = PlayState.Success(candidate, headers)
                    return@launch
                }
                // 3) 解析链：解析接口 → 嗅探
                when (val out = withContext(ioDispatcher) {
                    ParseManager.resolve(candidate, headers, UserPreference.getParseApis())
                }) {
                    is ParseManager.Outcome.Direct ->
                        _playEpisodeState.value = PlayState.Success(out.url, out.headers)
                    is ParseManager.Outcome.NeedSniff ->
                        _playEpisodeState.value = PlayState.Sniff(
                            pageUrl = out.pageUrl,
                            title = _vodState.value.vodName
                        )
                    is ParseManager.Outcome.Failed ->
                        _playEpisodeState.value = PlayState.Error(out.message)
                }
            } catch (e: CancellationException) {
                throw e
            } catch (t: Throwable) {
                Log.e(TAG, "取播放地址失败：${t.javaClass.simpleName}: ${t.message}")
                _playEpisodeState.value = PlayState.Error("解析失败，换个源或剧集再试")
            }
        }
    }

    /** UI 消费完播放状态后复位（约定，不调会重复跳转）。 */
    fun onPlayResultHandled() {
        _playEpisodeState.value = PlayState.Idle
    }

    /**
     * 相关推荐（需求1 底部那一排）。
     *
     * 策略：有分类名就用分类名搜，没有就用片名前两个字搜，过滤掉自己，取前 12 个。
     * 纯增强功能：失败/搜不到就空表，绝不影响详情主体。
     */
    private fun loadRecommend() {
        recommendJob?.cancel()
        recommendJob = scope.launch {
            try {
                val vod = _vodState.value
                val query = vod.typeName.trim().ifBlank { vod.vodName.trim().take(2) }
                if (query.isEmpty()) return@launch
                val spider = withContext(ioDispatcher) {
                    spiderManager.resolveSpider(site.api, site.extString)
                }
                if (spider is SpiderNull) return@launch
                val json = withContext(ioDispatcher) { spider.searchContent(query, true) }
                val list = HomeContentParser.parseVods(json)
                    .filter { it.vodId != vod.vodId && it.vodName != vod.vodName }
                    .take(MAX_RECOMMEND)
                _recommendFlow.value = list
                Log.d(TAG, "相关推荐 ${list.size} 部（query=$query）")
            } catch (e: CancellationException) {
                throw e
            } catch (t: Throwable) {
                Log.w(TAG, "推荐加载失败（不影响详情）：${t.javaClass.simpleName}")
            }
        }
    }

    /** 释放协程（DetailScreen 的 DisposableEffect 调）。 */
    fun release() {
        scope.cancel()
    }

    private companion object {
        const val TAG = "DetailVM"
        const val MAX_RECOMMEND = 12
    }
}
