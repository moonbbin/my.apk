package com.tvbox.shell.ui.detail

import android.util.Log
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.Card
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.TextButton
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import com.tvbox.shell.model.Site
import com.tvbox.shell.model.Vod
import com.tvbox.shell.parse.WebSniffActivity
import com.tvbox.shell.parser.Episode
import com.tvbox.shell.parser.EpisodeGroup
import com.tvbox.shell.player.PlayerActivity
import com.tvbox.shell.ui.ShellTheme
import com.tvbox.shell.ui.component.RemotePoster
import kotlinx.coroutines.launch

/**
 * 详情页（模块四·UI 层，卡片式排版）。
 *
 * 纵向一页流，每块一张 Card：
 * 1. 简介卡：封面 + 片名 + 评分/年份/地区/类型 + 主演/导演 + 可展开简介；
 * 2. 播放源卡：多源 FilterChip 横排切换（单个源时整张卡不显示）；
 * 3. 剧集卡：剧集网格（整页一起滚，无嵌套滚动）；
 * 4. 相关推荐卡：横向封面流，点封面走 [onVodClick]。
 *
 * 只做三件事：**展示、把点击转成 [DetailViewModel.onPlayEpisode]、消费解析结果**。
 * 一行解析逻辑都不碰——剧集表来自 [DetailViewModel.episodeGroupsFlow]，地址解析全在 ViewModel 里，
 * 这是为了守住契约"UI 层不直接调网络 / 解析"这条线。
 *
 * 状态消费（最容易做漏的地方）：
 * - [PlayState.Loading] → 全屏加载圈
 * - [PlayState.Success] → 关圈 + `startActivity` 跳 [PlayerActivity]（**地址和 headers 一起传**）
 * - [PlayState.Sniff]   → 关圈 + 跳 [WebSniffActivity] 做 WebView 嗅探
 * - [PlayState.Error]   → 关圈 + Snackbar 提示
 * 处理完都必须调 [DetailViewModel.onPlayResultHandled]，否则从播放器返回时会被再跳一次。
 *
 * 颜色全部取 [MaterialTheme.colorScheme]，最外层包 [ShellTheme]，
 * 主题切换 / 自定义背景（需求5）对详情页直接生效。
 *
 * @param site 当前站点（要它的 `api` / `ext` 去调采集引擎）
 * @param vod  详情数据
 * @param onBack 返回回调
 * @param viewModel 注入口。不传就自己建一个（测试 / 需要复用同一个 VM 时用得上）
 * @param onVodClick 相关推荐点了一部片子（默认空实现，老调用不用改）
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DetailScreen(
    site: Site,
    vod: Vod,
    onBack: () -> Unit = {},
    modifier: Modifier = Modifier,
    viewModel: DetailViewModel? = null,
    onVodClick: (Vod) -> Unit = {}
) {
    // 主题入口放最外层：配色 + 自定义背景都在这里生效，里面只用 colorScheme 取色。
    ShellTheme {
        DetailContent(
            site = site,
            vod = vod,
            onBack = onBack,
            modifier = modifier,
            viewModel = viewModel,
            onVodClick = onVodClick
        )
    }
}

/**
 * 详情页内容（被 [ShellTheme] 包着的那层）。
 *
 * 拆出来是因为 ShellTheme 的 content 块里直接写 VM 的 remember/DisposableEffect
 * 也没问题，但把"主题"和"业务"分开，测试想绕开主题时可以直接调这一层。
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun DetailContent(
    site: Site,
    vod: Vod,
    onBack: () -> Unit,
    modifier: Modifier,
    viewModel: DetailViewModel?,
    onVodClick: (Vod) -> Unit
) {
    // 没有 lifecycle-viewmodel-compose 这个依赖，所以用 remember 建 VM + 手动 release；
    // 调用方若要接进 ViewModelStore，把 viewModel 传进来即可。
    val vm = viewModel ?: remember(site, vod) { DetailViewModel(site, vod) }
    DisposableEffect(vm) {
        onDispose {
            // 只释放自己建的；外部注入的由外部负责（可能还要复用）
            if (viewModel == null) vm.release()
        }
    }

    val state by vm.playEpisodeState.collectAsState()
    val context = LocalContext.current
    val snackbarHostState = remember { SnackbarHostState() }
    // 剧集表是异步来的（进页面时向站点引擎要详情）→ 订阅，不能只读一次
    val groups by vm.episodeGroupsFlow.collectAsState()
    val loadState by vm.detailLoadState.collectAsState()
    val shownVod by vm.vodState.collectAsState()
    val recommend by vm.recommendFlow.collectAsState()

    // 进页面取一次详情（列表项通常不带剧集表，剧集只能从详情来）。
    // 幂等：已有剧集表 / 正在取的时候，再调也不发请求。
    LaunchedEffect(vm) { vm.loadDetail() }

    var selectedFlag by rememberSaveable(groups) {
        mutableStateOf(groups.firstOrNull()?.flag.orEmpty())
    }
    // 当前点过的那一集（列表里高亮用）。不参与跳转，纯 UI 状态。
    var playingUrl by rememberSaveable { mutableStateOf("") }

    // 当前点过那一集的**名字**（"第03集"）。模块七加进来的：跳播放器时要把它带过去，
    // 否则历史记录里只有地址，用户翻历史根本认不出是哪一集。
    var playingEpisodeName by rememberSaveable { mutableStateOf("") }

    // 状态消费：Success 跳播放器 / Sniff 跳嗅探页 / Error 弹提示，处理完立刻复位成 Idle。
    //
    // 用 collect 而不是 LaunchedEffect(state)：后者每次状态变化都会重启协程，
    // 而 showSnackbar 是挂起函数 —— 一条还在显示的提示会被下一次状态变化直接掐掉，
    // 连点两集时表现为"第一遍错误提示闪一下没了"。
    LaunchedEffect(vm) {
        vm.playEpisodeState.collect { current ->
            when (current) {
                is PlayState.Success -> {
                    val opened = runCatching {
                        context.startActivity(
                            PlayerActivity.intent(
                                context = context,
                                videoUrl = current.videoUrl,
                                headers = HashMap(current.headers),
                                // 模块七：把"哪部片的哪一集"一起带过去，播放页才记得住进度。
                                // 不传这几个字段，历史列表里就只剩裸地址 —— 翻历史根本认不出是哪部片。
                                vodId = shownVod.vodId,
                                vodName = shownVod.vodName,
                                vodPic = shownVod.vodPic,
                                episodeName = playingEpisodeName
                            )
                        )
                    }
                    if (opened.isFailure) {
                        val cause = opened.exceptionOrNull()
                        Log.w(TAG, "打开播放器失败：${cause?.javaClass?.simpleName}")
                        launch { snackbarHostState.showSnackbar("打不开播放器，请重试") }
                    }
                    vm.onPlayResultHandled()
                }

                is PlayState.Sniff -> {
                    // 直链和解析接口都拿不到地址 → 扔给 WebView 嗅探页兜底
                    val opened = runCatching {
                        context.startActivity(
                            WebSniffActivity.intent(context, current.pageUrl, current.title)
                        )
                    }
                    if (opened.isFailure) {
                        val cause = opened.exceptionOrNull()
                        Log.w(TAG, "打开嗅探页失败：${cause?.javaClass?.simpleName}")
                        launch { snackbarHostState.showSnackbar("打不开嗅探页，请重试") }
                    }
                    vm.onPlayResultHandled()
                }

                is PlayState.Error -> {
                    playingUrl = ""
                    vm.onPlayResultHandled()
                    // 单独起一条协程放提示，别把 collect 堵在这儿
                    // （否则提示显示的几秒里，用户再点一集不会有任何反应）
                    launch { snackbarHostState.showSnackbar(current.message) }
                }

                else -> Unit
            }
        }
    }

    val episodes = remember(groups, selectedFlag) {
        groups.firstOrNull { it.flag == selectedFlag }?.episodes.orEmpty()
    }

    // Scaffold 透明，让 ShellTheme 的自定义背景（需求5）透出来；
    // 卡片用 surface 色，层次靠 Card 自己的底色撑。
    Scaffold(
        modifier = modifier.fillMaxSize(),
        containerColor = Color.Transparent,
        snackbarHost = { SnackbarHost(snackbarHostState) },
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = shownVod.vodName.ifBlank { "详情" },
                        fontSize = 17.sp,
                        fontWeight = FontWeight.Medium,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "返回"
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.Transparent,
                    titleContentColor = MaterialTheme.colorScheme.onSurface,
                    navigationIconContentColor = MaterialTheme.colorScheme.onSurface
                )
            )
        }
    ) { innerPadding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding),
            contentPadding = PaddingValues(12.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // 1. 简介卡
            item(key = "intro") {
                IntroCard(vod = shownVod)
            }

            // 2/3. 播放源卡 + 剧集卡；没取到剧集表时给空态卡（loading / 失败原因 / 重试）
            if (groups.isNotEmpty()) {
                // 单个源时整张卡不显示，不占地方
                if (groups.size > 1) {
                    item(key = "source") {
                        SourceCard(
                            groups = groups,
                            selectedFlag = selectedFlag,
                            onSelect = { selectedFlag = it }
                        )
                    }
                }
                item(key = "episodes") {
                    EpisodeCard(
                        episodes = episodes,
                        playingUrl = playingUrl,
                        onEpisodeClick = { episode ->
                            playingUrl = episode.url
                            playingEpisodeName = episode.name
                            vm.onPlayEpisode(selectedFlag, episode.url)
                        }
                    )
                }
            } else {
                item(key = "empty") {
                    Card(modifier = Modifier.fillMaxWidth()) {
                        EmptyEpisodeHint(
                            modifier = Modifier.padding(vertical = 24.dp),
                            loading = loadState is DetailLoadState.Loading,
                            hint = (loadState as? DetailLoadState.Failed)?.message.orEmpty(),
                            // 只有"没取回来"（网络/解析这类临时问题）才给重试：
                            // 没有片子编号 → 重试一万次也一样；源压根没给剧集 → 该换源而不是重试
                            onRetry = (loadState as? DetailLoadState.Failed)
                                ?.takeIf { it.message == DetailLoadState.MSG_DETAIL_FAILED }
                                ?.let { { vm.retryDetail() } }
                        )
                    }
                }
            }

            // 4. 相关推荐卡：有数据才占地方
            if (recommend.isNotEmpty()) {
                item(key = "recommend") {
                    RecommendCard(vods = recommend, onVodClick = onVodClick)
                }
            }
        }
    }

    if (state is PlayState.Loading) {
        ResolvingDialog()
    }
}

// ======================================================================
// 卡 1：简介
// ======================================================================

@Composable
private fun IntroCard(vod: Vod) {
    val colors = MaterialTheme.colorScheme
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(12.dp)) {
            Row(modifier = Modifier.fillMaxWidth()) {
                RemotePoster(
                    url = vod.vodPic,
                    title = vod.vodName,
                    modifier = Modifier
                        .size(width = 104.dp, height = 148.dp)
                        .clip(RoundedCornerShape(10.dp))
                )

                Spacer(modifier = Modifier.width(12.dp))

                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = vod.vodName.ifBlank { "未知片名" },
                        fontSize = 17.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = colors.onSurface,
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis
                    )

                    if (vod.vodRemarks.isNotBlank()) {
                        Text(
                            text = vod.vodRemarks,
                            fontSize = 12.sp,
                            color = colors.primary,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis,
                            modifier = Modifier.padding(top = 4.dp)
                        )
                    }

                    ScoreBadge(vod.vodScore)

                    val meta = listOf(vod.vodYear, vod.vodArea, vod.typeName)
                        .filter { it.isNotBlank() }
                        .joinToString(" · ")
                    if (meta.isNotEmpty()) {
                        Text(
                            text = meta,
                            fontSize = 12.sp,
                            color = colors.onSurfaceVariant,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis,
                            modifier = Modifier.padding(top = 4.dp)
                        )
                    }

                    val actors = vod.vodActor.trim()
                    if (actors.isNotEmpty()) {
                        Text(
                            text = "主演：$actors",
                            fontSize = 12.sp,
                            color = colors.onSurfaceVariant,
                            maxLines = 2,
                            overflow = TextOverflow.Ellipsis,
                            modifier = Modifier.padding(top = 4.dp)
                        )
                    }

                    val director = vod.vodDirector.trim()
                    if (director.isNotEmpty()) {
                        Text(
                            text = "导演：$director",
                            fontSize = 12.sp,
                            color = colors.onSurfaceVariant,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis,
                            modifier = Modifier.padding(top = 2.dp)
                        )
                    }
                }
            }

            // 简介：点整块展开 / 收起
            val summary = vod.vodContent.trim()
            if (summary.isNotEmpty()) {
                var expanded by rememberSaveable { mutableStateOf(false) }
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(top = 10.dp)
                        .clickable { expanded = !expanded }
                ) {
                    Text(
                        text = summary,
                        fontSize = 13.sp,
                        color = colors.onSurfaceVariant,
                        lineHeight = 19.sp,
                        maxLines = if (expanded) Int.MAX_VALUE else 3,
                        overflow = TextOverflow.Ellipsis
                    )
                    Text(
                        text = if (expanded) "收起" else "展开",
                        fontSize = 12.sp,
                        color = colors.primary,
                        modifier = Modifier.padding(top = 2.dp)
                    )
                }
            }
        }
    }
}

/** 评分角标。没有评分就不显示——不编造分数。 */
@Composable
private fun ScoreBadge(score: String) {
    val text = score.trim()
    if (text.isEmpty()) return
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier.padding(top = 6.dp)
    ) {
        Icon(
            imageVector = Icons.Filled.Star,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.tertiary,
            modifier = Modifier.size(14.dp)
        )
        Spacer(modifier = Modifier.width(3.dp))
        Text(
            text = text,
            fontSize = 13.sp,
            color = MaterialTheme.colorScheme.tertiary,
            fontWeight = FontWeight.Medium
        )
    }
}

// ======================================================================
// 卡 2：播放源
// ======================================================================

/** 多源切换卡。调用方保证 groups.size > 1 才调，这里面不再重复判断。 */
@Composable
private fun SourceCard(
    groups: List<EpisodeGroup>,
    selectedFlag: String,
    onSelect: (String) -> Unit
) {
    val colors = MaterialTheme.colorScheme
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(vertical = 8.dp)) {
            Text(
                text = "播放源",
                fontSize = 14.sp,
                fontWeight = FontWeight.Medium,
                color = colors.onSurface,
                modifier = Modifier.padding(horizontal = 12.dp, vertical = 4.dp)
            )
            LazyRow(
                modifier = Modifier.fillMaxWidth(),
                contentPadding = PaddingValues(horizontal = 12.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(groups, key = { it.flag }) { group ->
                    FilterChip(
                        selected = group.flag == selectedFlag,
                        onClick = { onSelect(group.flag) },
                        label = {
                            Text(
                                text = "${group.flag} · ${group.episodes.size}",
                                fontSize = 12.sp,
                                maxLines = 1
                            )
                        },
                        colors = FilterChipDefaults.filterChipColors(
                            selectedContainerColor = colors.primary,
                            selectedLabelColor = colors.onPrimary
                        )
                    )
                }
            }
        }
    }
}

// ======================================================================
// 卡 3：剧集
// ======================================================================

@Composable
private fun EpisodeCard(
    episodes: List<Episode>,
    playingUrl: String,
    onEpisodeClick: (Episode) -> Unit
) {
    val colors = MaterialTheme.colorScheme
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(12.dp)) {
            Text(
                text = if (episodes.isEmpty()) "选集" else "选集（${episodes.size}）",
                fontSize = 14.sp,
                fontWeight = FontWeight.Medium,
                color = colors.onSurface,
                modifier = Modifier.padding(bottom = 8.dp)
            )

            if (episodes.isEmpty()) {
                Text(
                    text = EMPTY_EPISODE_TEXT,
                    fontSize = 13.sp,
                    color = colors.onSurfaceVariant,
                    modifier = Modifier.padding(vertical = 12.dp)
                )
                return@Column
            }

            // 剧集网格：按固定列数切成行，直接画在 LazyColumn 里，
            // 整页一根滚动轴，不嵌套滚动，往下滑一路看到底。
            val rows = remember(episodes) { episodes.chunked(EPISODE_COLUMNS) }
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                rows.forEach { row ->
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        row.forEach { episode ->
                            EpisodeCell(
                                name = episode.name,
                                selected = episode.url == playingUrl,
                                onClick = { onEpisodeClick(episode) },
                                modifier = Modifier.weight(1f)
                            )
                        }
                        // 最后一行不满时用空白占位补齐，保证格子对齐
                        repeat(EPISODE_COLUMNS - row.size) {
                            Spacer(modifier = Modifier.weight(1f))
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun EpisodeCell(
    name: String,
    selected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val colors = MaterialTheme.colorScheme
    Box(
        modifier = modifier
            .height(40.dp)
            .clip(RoundedCornerShape(8.dp))
            .background(if (selected) colors.primary else colors.surfaceVariant)
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = name.ifBlank { "播放" },
            fontSize = 13.sp,
            color = if (selected) colors.onPrimary else colors.onSurfaceVariant,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            modifier = Modifier.padding(horizontal = 6.dp)
        )
    }
}

// ======================================================================
// 卡 4：相关推荐
// ======================================================================

@Composable
private fun RecommendCard(
    vods: List<Vod>,
    onVodClick: (Vod) -> Unit
) {
    val colors = MaterialTheme.colorScheme
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(vertical = 8.dp)) {
            Text(
                text = "相关推荐",
                fontSize = 14.sp,
                fontWeight = FontWeight.Medium,
                color = colors.onSurface,
                modifier = Modifier.padding(horizontal = 12.dp, vertical = 4.dp)
            )
            LazyRow(
                modifier = Modifier.fillMaxWidth(),
                contentPadding = PaddingValues(horizontal = 12.dp),
                horizontalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                items(vods, key = { it.vodId.ifBlank { it.vodName } }) { vod ->
                    RecommendItem(vod = vod, onClick = { onVodClick(vod) })
                }
            }
        }
    }
}

@Composable
private fun RecommendItem(
    vod: Vod,
    onClick: () -> Unit
) {
    Column(
        modifier = Modifier
            .width(96.dp)
            .clickable(onClick = onClick),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        RemotePoster(
            url = vod.vodPic,
            title = vod.vodName,
            modifier = Modifier
                .size(width = 96.dp, height = 136.dp)
                .clip(RoundedCornerShape(8.dp))
        )
        Spacer(modifier = Modifier.height(6.dp))
        Text(
            text = vod.vodName.ifBlank { "未知片名" },
            fontSize = 12.sp,
            color = MaterialTheme.colorScheme.onSurface,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis
        )
    }
}

// ======================================================================
// 空态 / 加载圈（语义跟原来保持一致）
// ======================================================================

/**
 * 没有任何可播剧集时的占位视图。
 *
 * 分三种情况（都在同一个视图里，不跳屏）：
 * - [loading] 为 true：转圈 + "正在读取剧集…"（进页面正在向站点引擎要详情）
 * - [hint] 非空：把具体原因写出来（网络没取到 / 源没给剧集 / 缺片子编号）
 * - [onRetry] 非空：给一个"重试"按钮。**网络类失败才给**——
 *   "源就是没给剧集"和"没片子编号"这两种重试一万次也一样，给按钮是骗用户。
 *
 * 主文案 [EMPTY_EPISODE_TEXT] 始终在：它是这个区域的固定含义（"这儿没有剧集"），
 * 加载中/失败原因都是它的补充说明。
 */
@Composable
private fun EmptyEpisodeHint(
    modifier: Modifier = Modifier,
    loading: Boolean = false,
    hint: String = "",
    onRetry: (() -> Unit)? = null
) {
    val colors = MaterialTheme.colorScheme
    Box(
        modifier = modifier.fillMaxWidth(),
        contentAlignment = Alignment.Center
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            if (loading) {
                CircularProgressIndicator(
                    color = colors.primary,
                    strokeWidth = 2.dp,
                    modifier = Modifier.size(22.dp)
                )
                Spacer(modifier = Modifier.height(10.dp))
            }

            Text(
                text = EMPTY_EPISODE_TEXT,
                fontSize = 13.sp,
                color = colors.onSurfaceVariant
            )

            if (loading) {
                Spacer(modifier = Modifier.height(6.dp))
                Text(text = "正在读取剧集…", fontSize = 12.sp, color = colors.onSurfaceVariant)
            } else if (hint.isNotEmpty()) {
                Spacer(modifier = Modifier.height(6.dp))
                Text(
                    text = hint,
                    fontSize = 12.sp,
                    color = colors.onSurfaceVariant,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.padding(horizontal = 32.dp)
                )
            }

            if (!loading && onRetry != null) {
                TextButton(onClick = onRetry) {
                    Text(text = "重试", fontSize = 13.sp)
                }
            }
        }
    }
}

/**
 * 全屏解析中。
 *
 * 用 `usePlatformDefaultWidth = false` 才铺得满——默认 Dialog 有平台宽度限制，
 * 会变成一个居中小方块，挡不住下面的点击，很容易被连点。
 */
@Composable
private fun ResolvingDialog() {
    Dialog(
        onDismissRequest = { /* 解析中不允许点外面关掉 */ },
        properties = DialogProperties(
            dismissOnBackPress = false,
            dismissOnClickOutside = false,
            usePlatformDefaultWidth = false
        )
    ) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(Color(0x66000000)),
            contentAlignment = Alignment.Center
        ) {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier
                    .clip(RoundedCornerShape(14.dp))
                    .background(Color(0xE6202124))
                    .padding(horizontal = 28.dp, vertical = 22.dp)
            ) {
                CircularProgressIndicator(color = Color.White, strokeWidth = 3.dp)
                Spacer(modifier = Modifier.height(12.dp))
                Text(text = "正在解析播放地址…", fontSize = 13.sp, color = Color.White)
            }
        }
    }
}

// ======================================================================
// 常量
// ======================================================================

private const val TAG = "DetailScreen"

/** 空态主文案。UI 测试按这句断言，别随手改字。 */
private const val EMPTY_EPISODE_TEXT = "这个源没有可播放的剧集"

/** 剧集网格每行列数（跟原来 Adaptive(88.dp) 在手机上的效果一致）。 */
private const val EPISODE_COLUMNS = 4
