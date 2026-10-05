package com.tvbox.shell.ui.component

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.tvbox.shell.config.HistoryRepository
import com.tvbox.shell.model.PlayHistory
import java.util.Locale

/**
 * 观看历史页（模块七，全屏）。
 *
 * 一行 = 一部片子的某一集：封面缩略图 + 片名 + 集名 + 进度条 + "看到 xx:xx / 总 xx:xx"。
 * 点一行 → 从上次那个位置**接着播**（外层拿 [PlayHistory.positionMs] 当 `startPositionMs`）；
 * 长按一行 → 弹确认框删掉这一条。
 *
 * 数据是一进页面读一次的快照（[HistoryRepository.getAll]），之后本地维护 ——
 * 不在这个页面里做实时订阅：历史只会被"播放"改，而这个页面覆盖全屏，用户正在看历史时
 * 不可能同时在播别的东西，为它引一条 Flow 属于白搭复杂度。
 * 删除 / 清空都立刻写盘 + 刷本地快照，所以返回再进来一定是新的。
 *
 * @param repository 历史仓库（默认就是全局那个单例，测试可以传自己的实现）
 * @param onBack     返回回调
 * @param onItemClick 点某条历史 → 继续播放
 */
@OptIn(ExperimentalMaterial3Api::class, ExperimentalFoundationApi::class)
@Composable
fun HistoryScreen(
    repository: HistoryRepository,
    onBack: () -> Unit,
    onItemClick: (PlayHistory) -> Unit
) {
    var items by remember { mutableStateOf(readHistory(repository)) }
    var pendingDelete by remember { mutableStateOf<PlayHistory?>(null) }

    Scaffold(
        modifier = Modifier.fillMaxSize(),
        // Tab 化之后挂在首页内容区里：背景透明，让 ShellTheme 的自定义背景透出来
        containerColor = Color.Transparent,
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "观看历史",
                        fontSize = 18.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = HistoryTitleColor
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "返回",
                            tint = HistoryTitleColor
                        )
                    }
                },
                actions = {
                    // 空历史时把"清空"禁掉，别给一个点了没反应的按钮
                    TextButton(
                        onClick = {
                            clearHistory(repository)
                            items = readHistory(repository)
                        },
                        enabled = items.isNotEmpty()
                    ) {
                        Text(
                            text = "清空",
                            fontSize = 14.sp,
                            color = if (items.isNotEmpty()) HistoryAccentColor else HistoryCaptionColor
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = HistoryScreenBackground,
                    scrolledContainerColor = HistoryScreenBackground,
                    titleContentColor = HistoryTitleColor
                )
            )
        }
    ) { innerPadding ->
        if (items.isEmpty()) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(innerPadding),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "暂无观看记录",
                    fontSize = 14.sp,
                    color = HistoryCaptionColor,
                    textAlign = TextAlign.Center
                )
            }
        } else {
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(innerPadding),
                contentPadding = androidx.compose.foundation.layout.PaddingValues(
                    start = 14.dp,
                    end = 14.dp,
                    top = 6.dp,
                    bottom = 16.dp
                ),
                verticalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                // key 用 vodId：历史仓库本身就是按 vodId 去重的，所以它天然唯一。
                // 万一脏数据里撞了（没 id 的条目已经在下层被过滤掉），items 位置兜底也不会崩。
                items(items = items, key = { row -> row.vodId.ifBlank { row.episodeUrl } }) { row ->
                    HistoryRow(
                        history = row,
                        onClick = { onItemClick(row) },
                        onLongClick = { pendingDelete = row }
                    )
                }
            }
        }
    }

    // 长按删除的确认框。刻意要确认：单条历史是"我上次看到哪"的唯一记认，误删没法恢复
    // （不像搜索历史，再搜一次就回来了）。
    pendingDelete?.let { target ->
        AlertDialog(
            onDismissRequest = { pendingDelete = null },
            title = { Text("删除这条记录？") },
            text = {
                Text(
                    text = (target.vodName.ifBlank { "这条记录" }) +
                        if (target.episodeName.isNotBlank()) "（${target.episodeName}）" else ""
                )
            },
            confirmButton = {
                TextButton(onClick = {
                    removeHistory(repository, target.vodId)
                    items = readHistory(repository)
                    pendingDelete = null
                }) {
                    Text("删除", color = HistoryDeleteColor)
                }
            },
            dismissButton = {
                TextButton(onClick = { pendingDelete = null }) { Text("取消") }
            }
        )
    }
}

/** 历史列表某一行的测试锚点。 */
internal const val HISTORY_ROW_TAG_PREFIX = "history_row:"

/**
 * 生成某条历史的行锚点。
 *
 * 为什么需要它：历史页是**压在首页之上的浮层**，首页封面墙上往往有同名片子 ——
 * 测试按文案找会命中两个节点（实测 `Expected exactly 1 node but found 2`）。
 * 用 vodId 当锚点，一行一个、互不干扰。
 */
internal fun historyRowTag(history: PlayHistory): String =
    HISTORY_ROW_TAG_PREFIX + history.vodId.ifBlank { history.episodeUrl }

/** 历史列表的一行。 */
@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun HistoryRow(
    history: PlayHistory,
    onClick: () -> Unit,
    onLongClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(Color.White)
            .combinedClickable(onClick = onClick, onLongClick = onLongClick)
            .testTag(historyRowTag(history))
            .padding(10.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // 封面缩略图：60x80dp（2:3，跟全站的封面比例一致）
        Box(
            modifier = Modifier
                .size(width = PosterWidth, height = PosterHeight)
                .clip(RoundedCornerShape(8.dp))
        ) {
            RemotePoster(
                url = history.vodPic,
                title = history.vodName,
                modifier = Modifier.fillMaxSize()
            )
        }

        Spacer(modifier = Modifier.width(12.dp))

        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = history.vodName.ifBlank { "未命名" },
                fontSize = 15.sp,
                fontWeight = FontWeight.Medium,
                color = HistoryTitleColor,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )

            if (history.episodeName.isNotBlank()) {
                Text(
                    text = history.episodeName,
                    fontSize = 12.sp,
                    color = HistoryBodyColor,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.padding(top = 3.dp)
                )
            }

            Spacer(modifier = Modifier.height(7.dp))

            LinearProgressIndicator(
                progress = { history.progressPercent },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(4.dp)
                    .clip(RoundedCornerShape(percent = 50)),
                color = HistoryAccentColor,
                trackColor = HistoryTrackColor
            )

            Text(
                text = formatProgressText(history),
                fontSize = 11.sp,
                color = HistoryCaptionColor,
                maxLines = 1,
                modifier = Modifier.padding(top = 5.dp)
            )
        }
    }
}

/**
 * "看到 12:34 / 总 45:00"。
 *
 * 总时长未知（采集站不给 duration 很常见）时只说"看到 xx:xx"，
 * 拼一句"总 00:00"出来会让用户以为这片子长度是 0。
 */
internal fun formatProgressText(history: PlayHistory): String {
    val seen = formatClock(history.positionMs)
    return if (history.durationMs > 0L) {
        "看到 $seen / 总 ${formatClock(history.durationMs)}"
    } else {
        "看到 $seen"
    }
}

/** 毫秒 → `mm:ss` / `h:mm:ss`。跟播放器控制条同款格式，两处保持一致。 */
internal fun formatClock(millis: Long): String {
    val totalSeconds = if (millis > 0L) millis / 1000 else 0L
    val hours = totalSeconds / 3600
    val minutes = (totalSeconds % 3600) / 60
    val seconds = totalSeconds % 60
    return if (hours > 0L) {
        String.format(Locale.US, "%d:%02d:%02d", hours, minutes, seconds)
    } else {
        String.format(Locale.US, "%02d:%02d", minutes, seconds)
    }
}

/**
 * 读历史。
 *
 * 包一层 try 是刻意的：这个页面是"进来看一眼"的地方，
 * 存储层任何一种意外（磁盘满、JSON 坏了）都不该让整页白屏 —— 大不了显示"暂无观看记录"。
 */
private fun readHistory(repository: HistoryRepository): List<PlayHistory> = try {
    repository.getAll()
} catch (t: Throwable) {
    emptyList()
}

private fun removeHistory(repository: HistoryRepository, vodId: String) {
    runCatching { repository.remove(vodId) }
}

private fun clearHistory(repository: HistoryRepository) {
    runCatching { repository.clear() }
}

/** 缩略图尺寸（契约指定 60x80dp）。 */
private val PosterWidth = 60.dp
private val PosterHeight = 80.dp

private val HistoryScreenBackground = Color(0xFFF2F2F7)
private val HistoryTitleColor = Color(0xFF1C1C1E)
private val HistoryBodyColor = Color(0xFF3A3A3C)
private val HistoryCaptionColor = Color(0xFF8E8E93)
private val HistoryAccentColor = Color(0xFF4338CA)
private val HistoryDeleteColor = Color(0xFFD32F2F)
private val HistoryTrackColor = Color(0x1F4338CA)
