package com.tvbox.shell.ui.component

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
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
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import com.tvbox.shell.config.UserPreference
import com.tvbox.shell.model.Vod
import com.tvbox.shell.ui.home.HomeViewModel
import com.tvbox.shell.ui.home.SearchState

/** 搜索页里那个输入框的测试锚点（Compose 测试用它精确点到输入框）。 */
const val SEARCH_FIELD_TAG = "search_field"

/**
 * 搜索页（模块七，全屏）。
 *
 * 三块，从上到下：
 * 1. 顶栏：返回箭头 + **自动聚焦**的输入框（进来就能打字，少一次点击）；
 * 2. 搜索历史：Chip 流式布局。**点一下复用**（直接重搜这条），**长按删除**（单条）；
 * 3. 结果区：四态（[SearchState]）—— 没搜过给提示、搜中给圈、搜不到给文案、搜到给封面网格。
 *
 * 边界（刻意划清的）：
 * - 这里**不碰采集引擎**：搜什么、怎么解析全在 [HomeViewModel.searchContent] 里，
 *   UI 只负责把关键词递下去、把结果画出来 —— 跟首页/详情页同一条线；
 * - 历史读写走 [UserPreference]（本地首选项），跟"搜索结果"是两件事：清了历史不影响当前结果，
 *   反过来也一样。
 *
 * @param viewModel 首页那个 VM（搜索复用它的当前站点，所以结果跟首页是同一个源，不会串站）
 * @param onBack    返回回调
 * @param onVodClick 点结果封面 → 交给外层开详情页
 */
@OptIn(ExperimentalMaterial3Api::class, ExperimentalLayoutApi::class, ExperimentalFoundationApi::class)
@Composable
fun SearchScreen(
    viewModel: HomeViewModel,
    onBack: () -> Unit,
    onVodClick: (Vod) -> Unit
) {
    val resultState by viewModel.searchResultState.collectAsState()
    val currentSite by viewModel.currentSite.collectAsState()

    var keyword by rememberSaveable { mutableStateOf("") }
    // 历史是本地数据，进来读一次即可；写的时候（提交 / 删除）原地刷一遍
    var history by remember { mutableStateOf(UserPreference.getSearchHistory()) }

    val focusRequester = remember { FocusRequester() }

    /** 提交一次搜索：**先记历史再搜**，顺序不能反（搜失败也要留下这条记录，用户还能再点一次）。 */
    fun submit(text: String) {
        val kw = text.trim()
        if (kw.isEmpty()) return
        UserPreference.addSearchHistory(kw)
        history = UserPreference.getSearchHistory()
        keyword = kw
        viewModel.searchContent(kw)
    }

    // 自动聚焦：进页面直接能打字。用 LaunchedEffect 而不是 Modifier 上的 autoFocus，
    // 是因为后者在某些 ROM 上会和页面的进场动画抢焦点，偶发不生效。
    LaunchedEffect(Unit) {
        runCatching { focusRequester.requestFocus() }
    }

    Scaffold(
        modifier = Modifier.fillMaxSize(),
        // Tab 化之后挂在首页内容区里：背景透明，让 ShellTheme 的自定义背景透出来
        containerColor = Color.Transparent,
        topBar = {
            TopAppBar(
                title = {
                    OutlinedTextField(
                        value = keyword,
                        onValueChange = { text ->
                            keyword = text
                            // 清空输入框 = 退回"没搜过"（只显示历史），别把上一次的结果糊在下面
                            if (text.isBlank()) viewModel.clearSearchResult()
                        },
                        singleLine = true,
                        placeholder = {
                            Text(
                                text = currentSite?.name?.let { "在「$it」里搜" } ?: "输入关键词",
                                fontSize = 14.sp,
                                color = SearchCaptionColor
                            )
                        },
                        leadingIcon = {
                            Icon(
                                imageVector = Icons.Filled.Search,
                                contentDescription = null,
                                tint = SearchCaptionColor
                            )
                        },
                        keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
                        keyboardActions = KeyboardActions(onSearch = { submit(keyword) }),
                        modifier = Modifier
                            .fillMaxWidth()
                            .focusRequester(focusRequester)
                            .testTag(SEARCH_FIELD_TAG)
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "返回",
                            tint = SearchTitleColor
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = SearchScreenBackground,
                    scrolledContainerColor = SearchScreenBackground,
                    titleContentColor = SearchTitleColor
                )
            )
        }
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
        ) {
            if (history.isNotEmpty()) {
                SearchHistorySection(
                    history = history,
                    onPick = { submit(it) },
                    onDelete = { entry ->
                        UserPreference.removeSearchHistory(entry)
                        history = UserPreference.getSearchHistory()
                    }
                )
            }

            when (val current = resultState) {
                is SearchState.Idle -> SearchHintBox(
                    text = if (history.isEmpty()) "输入关键词，回车开始搜索" else "点上面的历史可以再搜一次"
                )

                is SearchState.Loading -> Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator(color = SearchAccentColor)
                }

                is SearchState.Error -> SearchErrorBox(
                    message = current.message,
                    onRetry = { submit(keyword) }
                )

                is SearchState.Success -> if (current.vods.isEmpty()) {
                    SearchHintBox("未找到相关影视")
                } else {
                    SearchResultGrid(vods = current.vods, onVodClick = onVodClick)
                }
            }
        }
    }
}

/**
 * 搜索历史：Chip 流式布局。
 *
 * 点击 = 用这条关键词再搜一次（[onPick]），长按 = 删掉这一条（[onDelete]）。
 * 单条删除是这里唯一的破坏性操作，但它可逆成本极低（再搜一次就回来了），
 * 所以不弹确认框 —— 长按本身就是"我确实要动它"的明确手势。
 */
@OptIn(ExperimentalLayoutApi::class, ExperimentalFoundationApi::class)
@Composable
private fun SearchHistorySection(
    history: List<String>,
    onPick: (String) -> Unit,
    onDelete: (String) -> Unit
) {
    Column(modifier = Modifier.fillMaxWidth().padding(top = 10.dp, bottom = 4.dp)) {
        Text(
            text = "搜索历史",
            fontSize = 12.sp,
            color = SearchCaptionColor,
            modifier = Modifier.padding(start = 16.dp, bottom = 8.dp)
        )
        FlowRow(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 14.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            history.forEach { entry ->
                Box(
                    modifier = Modifier
                        .clip(RoundedCornerShape(percent = 50))
                        .background(Color.White)
                        .combinedClickable(
                            onClick = { onPick(entry) },
                            onLongClick = { onDelete(entry) }
                        )
                        .padding(horizontal = 13.dp, vertical = 7.dp)
                ) {
                    Text(
                        text = entry,
                        fontSize = 13.sp,
                        color = SearchBodyColor,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }
            }
        }
    }
}

/** 结果封面墙：跟首页一致的 3 列 2:3 海报，不换样子。 */
@Composable
private fun SearchResultGrid(vods: List<Vod>, onVodClick: (Vod) -> Unit) {
    LazyVerticalGrid(
        columns = GridCells.Fixed(SearchGridColumns),
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(start = 14.dp, end = 14.dp, top = 6.dp, bottom = 16.dp),
        horizontalArrangement = Arrangement.spacedBy(10.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        // 不设 key：搜索结果里重名片子很常见（不同 id 同名），硬设 key 会撞车抛异常
        items(vods) { vod ->
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(10.dp))
                    .clickable(onClick = { onVodClick(vod) })
            ) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .aspectRatio(SearchPosterRatio)
                        .clip(RoundedCornerShape(8.dp))
                ) {
                    RemotePoster(url = vod.vodPic, title = vod.vodName, modifier = Modifier.fillMaxSize())
                }
                Text(
                    text = vod.vodName.ifBlank { "未命名" },
                    fontSize = 12.sp,
                    color = SearchTitleColor,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.padding(top = 5.dp)
                )
            }
        }
    }
}

/** 中性提示（没搜过 / 搜不到）。 */
@Composable
private fun SearchHintBox(text: String) {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = text,
            fontSize = 14.sp,
            color = SearchCaptionColor,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(horizontal = 32.dp)
        )
    }
}

/**
 * 搜索失败：给原因 + 给重试。
 *
 * 为什么不直接显示"未找到相关影视"：那两句是完全不同的两件事 ——
 * "引擎没加载 / 接口连不上"重试有用，"源里真没这片"重试一万次也没用。
 * 把故障说成"没找到"，用户只会以为 App 搜不出来。
 */
@Composable
private fun SearchErrorBox(message: String, onRetry: () -> Unit) {
    Column(
        modifier = Modifier.fillMaxSize().padding(horizontal = 32.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = message,
            fontSize = 14.sp,
            color = SearchBodyColor,
            textAlign = TextAlign.Center
        )
        Spacer(modifier = Modifier.height(14.dp))
        Button(onClick = onRetry) { Text("重试") }
    }
}

private const val SearchGridColumns = 3
private const val SearchPosterRatio = 2f / 3f

private val SearchScreenBackground = Color(0xFFF2F2F7)
private val SearchTitleColor = Color(0xFF1C1C1E)
private val SearchBodyColor = Color(0xFF3A3A3C)
private val SearchCaptionColor = Color(0xFF8E8E93)
private val SearchAccentColor = Color(0xFF4338CA)
