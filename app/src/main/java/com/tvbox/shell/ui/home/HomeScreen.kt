package com.tvbox.shell.ui.home

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.History
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.tvbox.shell.config.HistoryRepository
import com.tvbox.shell.config.SiteRepository
import com.tvbox.shell.config.SourceRestorer
import com.tvbox.shell.model.PlayHistory
import com.tvbox.shell.model.Site
import com.tvbox.shell.model.Vod
import com.tvbox.shell.parser.HomeCategory
import com.tvbox.shell.player.PlayerActivity
import com.tvbox.shell.spider.SpiderManager
import com.tvbox.shell.ui.component.HistoryScreen
import com.tvbox.shell.ui.component.RemotePoster
import com.tvbox.shell.ui.component.SearchScreen
import com.tvbox.shell.ui.component.SitePickerSheet
import com.tvbox.shell.ui.component.SourcePickerSheet
import com.tvbox.shell.ui.ShellTheme
import com.tvbox.shell.ui.settings.SettingsActivity
import kotlinx.coroutines.launch
import android.util.Log

/**
 * 首页（影视 Tab，模块六）。
 *
 * 只做三件事：**渲染 [HomeState]、把点击转成回调、把一次性提示弹成 Snackbar**。
 * 一行取数逻辑都不碰——站点怎么挑、接口怎么调、JSON 怎么解全在 [HomeViewModel] 里，
 * 这是为了守住"UI 层不直接调网络 / 不解析"这条线（和详情页同一条线）。
 *
 * 点封面的动作不在这里跳页：通过 [onOpenDetail] 把 (站点, 片子) 抛给外层导航。
 * 原因是详情页要的是两个**对象**（Site 和 Vod），塞进路由字符串又丑又容易丢字段；
 * 由导航层持有这份数据、用一个路由名入栈，返回键天然就是退得回来的。
 *
 * @param onOpenDetail 点封面回调，参数是当前站点与该条点播数据
 * @param viewModel    注入口。不传就自己建一个（测试 / 需要复用同一个 VM 时用得上）
 * @param onPlayHistory 点历史记录时的回调。默认 null = 自己拉起播放器并 `startPositionMs` 续播；
 *                      测试 / 想接自己的播放页时传一个进来接管。
 */
@Composable
fun HomeScreen(
    onOpenDetail: (Site, Vod) -> Unit = { _, _ -> },
    modifier: Modifier = Modifier,
    viewModel: HomeViewModel? = null,
    onPlayHistory: ((PlayHistory) -> Unit)? = null
) {
    // 和详情页同款：自己建的自己释放，外部注入的交给外部（可能还要复用）
    //
    // 这里顺手把应用 Context 递给采集引擎管理器：动态加载插件包要用它算 DexClassLoader 的
    // 优化目录、插件落盘目录。**只在 UI 边缘注入这一次** —— ViewModel 本身依旧不碰 Context，
    // 对外还是只认 SpiderManager 一个口子（越界检查看的就是这条）。
    val appContext = LocalContext.current.applicationContext
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    // 配置源仓库（模块七）：长按标题换源要用它。只在这里建一次 ——
    // ViewModel 对外不认 Context，只认这个已经建好的仓库对象（越界检查看的就是这条线）。
    // 注意：必须在 remember 外面先建好再传进去 —— remember 的 lambda 里不能再调 remember。
    val siteRepository = remember(appContext) { SiteRepository(appContext) }
    val vm = viewModel ?: remember {
        HomeViewModel(
            spiderManager = SpiderManager.forApp(appContext),
            // 冷启动恢复：配置只活在内存里，杀进程重开就空了。首页这一侧接上恢复口
            // （Application 那侧也会兜一次），用户就不会再看到"我上次配的源怎么没了"。
            restoreSource = { SourceRestorer.restoreIfEmpty() },
            siteRepository = siteRepository
        )
    }
    DisposableEffect(vm) {
        onDispose {
            if (viewModel == null) vm.release()
        }
    }

    val state by vm.state.collectAsState()
    val message by vm.transientMessage.collectAsState()
    val snackbarHostState = remember { SnackbarHostState() }

    // 模块七：四个浮层开关 + 两份选择器数据 + 当前站点
    val sitePickerVisible by vm.sitePickerVisible.collectAsState()
    val sourcePickerVisible by vm.sourcePickerVisible.collectAsState()
    val searchVisible by vm.searchScreenVisible.collectAsState()
    val historyVisible by vm.historyScreenVisible.collectAsState()
    val availableSites by vm.availableSites.collectAsState()
    val availableSources by vm.availableSources.collectAsState()
    val currentSite by vm.currentSite.collectAsState()

    // 进首页就拉一次。已经有内容（例如从详情页返回）就不重拉，免得每次回来都刷一遍。
    LaunchedEffect(vm) {
        if (vm.state.value is HomeState.Idle) vm.loadHome()
    }

    // 一次性提示消费完立刻复位，否则下次进首页会重弹一遍
    LaunchedEffect(message) {
        val text = message ?: return@LaunchedEffect
        snackbarHostState.showSnackbar(text)
        vm.onMessageShown()
    }

    // 点历史 → 从上次那个位置接着播。
    // 地址为空的老记录点了没意义，给一句提示而不是静默无反应（静默失败最难查）。
    val openHistory: (PlayHistory) -> Unit = onPlayHistory ?: { row ->
        if (row.episodeUrl.isBlank()) {
            scope.launch { snackbarHostState.showSnackbar("这条记录没有可用的播放地址") }
        } else {
            val opened = runCatching {
                context.startActivity(
                    PlayerActivity.intent(
                        context = context,
                        videoUrl = row.episodeUrl,
                        headers = null,
                        vodId = row.vodId,
                        vodName = row.vodName,
                        vodPic = row.vodPic,
                        episodeName = row.episodeName,
                        startPositionMs = row.positionMs
                    )
                )
            }
            if (opened.isFailure) {
                Log.w(TAG, "从历史打开播放器失败：${opened.exceptionOrNull()?.javaClass?.simpleName}")
                scope.launch { snackbarHostState.showSnackbar("打不开播放器，请重试") }
            }
        }
    }

    // 底部导航 Tab：状态直接复用 VM 的浮层开关。
    // 搜索/历史原来是"全屏浮层"，改成 Tab 后它们变成内容区里的页面，
    // 底部导航常驻；页面里的返回按钮切回首页 Tab。
    val selectedTab = when {
        searchVisible -> HomeTab.SEARCH
        historyVisible -> HomeTab.HISTORY
        else -> HomeTab.HOME
    }

    // 主题接入（需求5）：整页包进 ShellTheme，跟随主题模式与自定义背景。
    // Scaffold 背景用透明，让 ShellTheme 的自定义背景（纯色/图片）透出来；
    // 没配自定义背景时 ShellTheme 本来就是主题底色，视觉一致。
    ShellTheme {
        Scaffold(
            modifier = modifier.fillMaxSize(),
            containerColor = Color.Transparent,
            snackbarHost = {
                // 底栏是悬浮胶囊，Snackbar 落在最底下会被它压住，往上抬一截
                SnackbarHost(
                    hostState = snackbarHostState,
                    modifier = Modifier.padding(bottom = SnackbarLift)
                )
            },
            bottomBar = {
                HomeBottomBar(
                    selected = selectedTab,
                    onSelect = { tab ->
                        when (tab) {
                            HomeTab.HOME -> {
                                vm.hideSearchScreen()
                                vm.hideHistoryScreen()
                            }
                            HomeTab.SEARCH -> vm.showSearchScreen()
                            HomeTab.HISTORY -> vm.showHistoryScreen()
                            HomeTab.SETTINGS -> {
                                context.startActivity(SettingsActivity.intent(context))
                            }
                        }
                    }
                )
            }
        ) { innerPadding ->
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(innerPadding)
            ) {
                when (selectedTab) {
                    // ---------- 搜索 Tab ----------
                    HomeTab.SEARCH -> {
                        SearchScreen(
                            viewModel = vm,
                            onBack = { vm.hideSearchScreen() },
                            onVodClick = { vod ->
                                // 结果封面点开就走详情。站点取"当前生效的那一个"，
                                // 保证详情页拿的是**同一个源**的 api/ext（换站了也不会拿错源去查详情）。
                                val site = vm.currentSite.value ?: (state as? HomeState.Success)?.site
                                if (site == null) {
                                    scope.launch { snackbarHostState.showSnackbar("还没有生效的站点，先回首页加载一次") }
                                } else {
                                    vm.hideSearchScreen()
                                    onOpenDetail(site, vod)
                                }
                            }
                        )
                    }

                    // ---------- 历史 Tab ----------
                    HomeTab.HISTORY -> {
                        HistoryScreen(
                            repository = HistoryRepository,
                            onBack = { vm.hideHistoryScreen() },
                            onItemClick = { row ->
                                vm.hideHistoryScreen()
                                openHistory(row)
                            }
                        )
                    }

                    // ---------- 首页 Tab ----------
                    else -> when (val current = state) {
                        is HomeState.Idle, is HomeState.Loading -> LoadingBox()

                        is HomeState.Error -> ErrorBox(
                            message = current.message,
                            onRetry = { vm.loadHome() }
                        )

                        is HomeState.Success -> HomeBody(
                            content = current,
                            onCategory = { vm.selectCategory(it) },
                            onRefresh = { vm.refresh() },
                            onTitleClick = { vm.showSitePicker() },
                            onTitleLongClick = { vm.showSourcePicker() },
                            onOpenDetail = onOpenDetail
                        )
                    }
                }
            }

            // ---------- 站点选择器（点标题） ----------
            if (sitePickerVisible) {
                SitePickerSheet(
                    sites = availableSites,
                    currentSite = currentSite ?: (state as? HomeState.Success)?.site,
                    onSelect = { vm.switchSite(it) },
                    onDismiss = { vm.hideSitePicker() }
                )
            }

            // ---------- 配置源选择器（长按标题） ----------
            if (sourcePickerVisible) {
                SourcePickerSheet(
                    sources = availableSources,
                    onSelect = { vm.switchSource(it) },
                    onDismiss = { vm.hideSourcePicker() }
                )
            }
        }
    } // ShellTheme
}

/** 首页底部导航的四个 Tab。 */
private enum class HomeTab {
    HOME,
    SEARCH,
    HISTORY,
    SETTINGS
}

/**
 * 底部导航栏：首页 / 搜索 / 历史 / 设置。
 *
 * 设置 Tab 点了直接进设置页，不切换选中态（它不是内容页）。
 */
@Composable
private fun HomeBottomBar(
    selected: HomeTab,
    onSelect: (HomeTab) -> Unit
) {
    NavigationBar {
        NavigationBarItem(
            selected = selected == HomeTab.HOME,
            onClick = { onSelect(HomeTab.HOME) },
            icon = { Icon(Icons.Filled.Home, contentDescription = "首页") },
            label = { Text("首页") }
        )
        NavigationBarItem(
            selected = selected == HomeTab.SEARCH,
            onClick = { onSelect(HomeTab.SEARCH) },
            icon = { Icon(Icons.Filled.Search, contentDescription = "搜索") },
            label = { Text("搜索") }
        )
        NavigationBarItem(
            selected = selected == HomeTab.HISTORY,
            onClick = { onSelect(HomeTab.HISTORY) },
            icon = { Icon(Icons.Filled.History, contentDescription = "历史") },
            label = { Text("历史") }
        )
        NavigationBarItem(
            selected = false,
            onClick = { onSelect(HomeTab.SETTINGS) },
            icon = { Icon(Icons.Filled.Settings, contentDescription = "设置") },
            label = { Text("设置") }
        )
    }
}

// ======================================================================
// 有内容：顶栏 + 分类行 + 封面墙
// ======================================================================

@Composable
private fun HomeBody(
    content: HomeState.Success,
    onCategory: (String) -> Unit,
    onRefresh: () -> Unit,
    onTitleClick: () -> Unit,
    onTitleLongClick: () -> Unit,
    onOpenDetail: (Site, Vod) -> Unit
) {
    Column(modifier = Modifier.fillMaxSize()) {
        HomeTopBar(
            title = content.site.name,
            count = content.vodList.size,
            onTitleClick = onTitleClick,
            onTitleLongClick = onTitleLongClick,
            onRefresh = onRefresh
        )

        // 分类表为空时不占地方（有的源确实不返回 class）
        if (content.categories.isNotEmpty()) {
            CategoryRow(
                categories = content.categories,
                selectedId = content.selectedCategoryId,
                onSelect = onCategory
            )
        }

        if (content.vodList.isEmpty()) {
            EmptyBox()
        } else {
            PosterGrid(
                vods = content.vodList,
                site = content.site,
                onOpenDetail = onOpenDetail
            )
        }
    }
}

/**
 * 顶栏：源名（**点标题换站 / 长按标题换源**）+ 刷新入口。
 *
 * 搜索 / 历史 / 设置都搬到底部导航了，这里只留刷新。
 *
 * 为什么标题做成手势而不是一个下拉箭头：标题本身就是"当前是哪个站"这个信息，
 * 点它去改它是用户的第一直觉（手机上的通行交互）。箭头会平白多占一块横向空间。
 *
 * 手势用 `pointerInput + detectTapGestures` 而不是 `combinedClickable`：
 * 这里**不该有点击波纹**（标题是文字，涟漪会显得整行都在跳），
 * 而且 `detectTapGestures` 能精确控制"长按 400ms 内抬手算点击"这个互斥关系。
 */
@Composable
private fun HomeTopBar(
    title: String,
    count: Int,
    onTitleClick: () -> Unit,
    onTitleLongClick: () -> Unit,
    onRefresh: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(start = 16.dp, end = 6.dp, top = 14.dp, bottom = 4.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(
            modifier = Modifier
                .weight(1f)
                .clip(RoundedCornerShape(10.dp))
                .pointerInput(Unit) {
                    detectTapGestures(
                        onTap = { onTitleClick() },
                        onLongPress = { onTitleLongClick() }
                    )
                }
                // 竖直方向留一点内边距：手势热区别贴着文字边界，不然点边角很别扭
                .padding(vertical = 4.dp)
                .testTag(HOME_TITLE_TAG)
        ) {
            Text(
                text = title.ifBlank { "影视" },
                fontSize = 19.sp,
                fontWeight = FontWeight.SemiBold,
                color = TitleColor,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
            Spacer(modifier = Modifier.height(2.dp))
            Text(
                text = "共 $count 部",
                fontSize = 12.sp,
                color = CaptionColor
            )
        }

        // 搜索 / 历史 / 设置都搬到底部导航了，顶栏只留刷新
        IconButton(onClick = onRefresh) {
            Icon(
                imageVector = Icons.Filled.Refresh,
                contentDescription = "刷新",
                tint = AccentColor
            )
        }
    }
}

/** 分类行：第一个是"全部"（回去调 homeContent），其余来自接口的 class 数组。 */
@Composable
private fun CategoryRow(
    categories: List<HomeCategory>,
    selectedId: String,
    onSelect: (String) -> Unit
) {
    LazyRow(
        modifier = Modifier.fillMaxWidth(),
        contentPadding = PaddingValues(horizontal = 14.dp, vertical = 4.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        item {
            CategoryChip(
                label = "全部",
                selected = selectedId == ALL_CATEGORY_ID,
                onClick = { onSelect(ALL_CATEGORY_ID) }
            )
        }
        items(categories) { category ->
            CategoryChip(
                label = category.typeName,
                selected = selectedId == category.typeId,
                onClick = { onSelect(category.typeId) }
            )
        }
    }
}

@Composable
private fun CategoryChip(label: String, selected: Boolean, onClick: () -> Unit) {
    Box(
        modifier = Modifier
            .clip(RoundedCornerShape(percent = 50))
            .background(if (selected) AccentColor else ChipBackground)
            .clickable(onClick = onClick)
            .padding(horizontal = 14.dp, vertical = 7.dp)
    ) {
        Text(
            text = label,
            fontSize = 13.sp,
            color = if (selected) Color.White else BodyColor,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis
        )
    }
}

/** 封面墙。3 列固定 —— 手机竖屏一屏 9~12 张，够看又不至于小到认不出片名。 */
@Composable
private fun PosterGrid(
    vods: List<Vod>,
    site: Site,
    onOpenDetail: (Site, Vod) -> Unit
) {
    LazyVerticalGrid(
        columns = GridCells.Fixed(GridColumns),
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(start = 14.dp, end = 14.dp, top = 6.dp, bottom = 16.dp),
        horizontalArrangement = Arrangement.spacedBy(10.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        // 刻意不设 key：采集站同一页里重名的片子不少（不同 id 同名），
        // 硬设 key 会撞车并直接抛异常，按位置复用是这里最稳的选择。
        items(vods) { vod ->
            PosterCell(vod = vod, onClick = { onOpenDetail(site, vod) })
        }
    }
}

@Composable
private fun PosterCell(vod: Vod, onClick: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(10.dp))
            .clickable(onClick = onClick)
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .aspectRatio(PosterRatio)
                .clip(RoundedCornerShape(10.dp))
                .background(CellBackground)
        ) {
            RemotePoster(
                url = vod.vodPic,
                title = vod.vodName,
                modifier = Modifier.fillMaxSize()
            )
            if (vod.vodRemarks.isNotBlank()) {
                Text(
                    text = vod.vodRemarks,
                    fontSize = 10.sp,
                    color = Color.White,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier
                        .align(Alignment.BottomEnd)
                        .padding(6.dp)
                        .clip(RoundedCornerShape(6.dp))
                        .background(RemarkBackground)
                        .padding(horizontal = 5.dp, vertical = 2.dp)
                )
            }
        }

        Spacer(modifier = Modifier.height(6.dp))

        Text(
            text = vod.vodName.ifBlank { "未命名" },
            fontSize = 12.sp,
            lineHeight = 15.sp,
            color = TitleColor,
            maxLines = 2,
            overflow = TextOverflow.Ellipsis,
            modifier = Modifier.padding(horizontal = 2.dp)
        )
    }
}

// ======================================================================
// 加载 / 空 / 错误
// ======================================================================

@Composable
private fun LoadingBox() {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        CircularProgressIndicator(color = AccentColor)
    }
}

@Composable
private fun EmptyBox() {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = "这个源暂时没返回内容，换个分类或点右上角刷新试试",
            fontSize = 14.sp,
            color = CaptionColor,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(horizontal = 40.dp)
        )
    }
}

@Composable
private fun ErrorBox(message: String, onRetry: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 40.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = message,
            fontSize = 14.sp,
            lineHeight = 20.sp,
            color = BodyColor,
            textAlign = TextAlign.Center
        )
        Spacer(modifier = Modifier.height(16.dp))
        Button(onClick = onRetry) {
            Text(text = "重试", fontSize = 14.sp)
        }
    }
}

// ======================================================================
// 常量
// ======================================================================

private val CellBackground = Color.White
private val ChipBackground = Color.White
private val AccentColor = Color(0xFF4338CA)
private val TitleColor = Color(0xFF1C1C1E)
private val BodyColor = Color(0xFF3A3A3C)
private val CaptionColor = Color(0xFF8E8E93)
private val RemarkBackground = Color(0xCC000000)

/** 封面墙列数。 */
private const val GridColumns = 3

/** 封面宽高比（海报 2:3，跟详情页一致）。 */
private const val PosterRatio = 2f / 3f

/** Snackbar 抬升量：压过悬浮底栏的高度。 */
private val SnackbarLift = 96.dp

/**
 * 顶栏标题区的测试锚点。
 *
 * 点它 = 换站，长按 = 换源 —— 这两个手势绑在文字上，Compose 里没有天然的办法
 * 按文案精确定位"那一块可点区域"，所以留一个 tag 给测试用。
 */
const val HOME_TITLE_TAG = "home_top_title"

/** 日志 tag（Logcat 里搜它能看到"从历史打开播放器失败"这类接线问题）。 */
private const val TAG = "HomeScreen"
