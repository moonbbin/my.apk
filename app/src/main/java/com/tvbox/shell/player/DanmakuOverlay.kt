package com.tvbox.shell.player

import android.util.Log
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.offset
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shadow
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import org.json.JSONArray
import org.json.JSONObject
import java.net.URLEncoder
import java.util.concurrent.TimeUnit
import kotlin.math.roundToInt

/**
 * 一条弹幕。
 *
 * @param text   弹幕文本
 * @param timeMs 相对视频开始的时间（毫秒），到点就从右侧滚入
 */
data class DanmakuItem(val text: String, val timeMs: Long)

/** 一条弹幕从右滚到左的总时长（毫秒）。 */
private const val DANMAKU_DURATION_MS: Long = 8000L

/** 固定行数：按弹幕在列表里的序号轮转，避免同一行重叠。 */
private const val DANMAKU_ROWS: Int = 5

/** 行高（dp）。 */
private const val DANMAKU_ROW_HEIGHT_DP: Int = 28

private const val TAG = "Danmaku"

/**
 * 弹幕滚动层（需求4）。
 *
 * 盖在播放器画面上、控制条之下。按时间轴工作：
 * 每条弹幕在 [DanmakuItem.timeMs] 到达时从屏幕右侧滚入，[DANMAKU_DURATION_MS]
 * 后滚出左侧消失；固定 [DANMAKU_ROWS] 行，按序号轮转分行。
 *
 * 实现刻意保持简单：偏移量直接由外部传入的 [positionMs] 算出来，
 * 不自己开动画时钟 —— 播放器侧定时刷新 positionMs（200~500ms 一次）即可流畅滚动，
 * 暂停 / seek 时弹幕天然跟着停 / 跳，不用额外同步逻辑。
 *
 * @param items      全部弹幕（按 timeMs 升序为佳，不强制）
 * @param positionMs 当前播放位置（毫秒），由播放器侧传入
 * @param enabled    总开关，false 时什么都不画
 * @param textColor  弹幕颜色（来自设置页）
 * @param textScale  字号倍率（来自设置页）
 */
@Composable
fun DanmakuOverlay(
    items: List<DanmakuItem>,
    positionMs: Long,
    enabled: Boolean,
    textColor: Color,
    textScale: Float,
    modifier: Modifier = Modifier
) {
    // 开关关了 / 没有弹幕：直接不画
    if (!enabled || items.isEmpty()) return

    BoxWithConstraints(modifier = modifier.fillMaxSize()) {
        val density = LocalDensity.current
        val widthPx = with(density) { maxWidth.toPx() }
        val rowHeightPx = with(density) { DANMAKU_ROW_HEIGHT_DP.dp.toPx() }

        // 只取"正在屏幕上"的几条：时间已到、还没滚完
        val visible = remember(items, positionMs) {
            items.mapIndexedNotNull { index, item ->
                val elapsed = positionMs - item.timeMs
                if (elapsed < 0 || elapsed > DANMAKU_DURATION_MS) return@mapIndexedNotNull null
                val fraction = elapsed.toFloat() / DANMAKU_DURATION_MS
                Triple(item, index % DANMAKU_ROWS, fraction)
            }
        }

        // 黑色描边保证在亮画面上也看得清
        val textStyle = TextStyle(
            color = textColor,
            fontSize = 16.sp * textScale,
            shadow = Shadow(
                color = Color.Black,
                offset = Offset(2f, 2f),
                blurRadius = 3f
            )
        )

        visible.forEach { (item, row, fraction) ->
            // fraction 0→1：x 从屏幕右边缘滚到左边缘
            val xPx = widthPx * (1f - fraction)
            val yPx = row * rowHeightPx
            Text(
                text = item.text,
                style = textStyle,
                maxLines = 1,
                modifier = Modifier.offset { IntOffset(xPx.roundToInt(), yPx.roundToInt()) }
            )
        }
    }
}

/**
 * 弹幕拉取（需求4）。
 *
 * 按用户在设置页配的 API 模板拉弹幕：
 * - 模板为空 → 不拉，返回空表；
 * - 否则把模板里的 `{keyword}` 替换成 URL 编码后的片名后 GET。
 *
 * JSON 兼容两种形状：
 * - 数组：`[{"text":"…","time":12.5}, …]`
 * - 对象：`{"danmaku":[{"text":"…","time":12.5}, …]}`
 *
 * `time` 可能是秒也可能是毫秒：小于 10000 按秒处理（×1000），
 * 否则按毫秒。任何失败（网络 / 解析）都返回空表，**不抛异常**。
 */
object DanmakuProvider {

    /** 单例 OkHttpClient：复用连接池，别每次拉都新建。 */
    private val client: OkHttpClient by lazy {
        OkHttpClient.Builder()
            .connectTimeout(10, TimeUnit.SECONDS)
            .readTimeout(10, TimeUnit.SECONDS)
            .build()
    }

    suspend fun load(keyword: String, apiTemplate: String): List<DanmakuItem> =
        withContext(Dispatchers.IO) {
            if (apiTemplate.isBlank()) return@withContext emptyList()
            try {
                val url = apiTemplate.replace(
                    "{keyword}",
                    URLEncoder.encode(keyword, "UTF-8")
                )
                val request = Request.Builder()
                    .url(url)
                    .get()
                    .header(
                        "User-Agent",
                        "Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 " +
                            "(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36"
                    )
                    .build()
                client.newCall(request).execute().use { response ->
                    if (!response.isSuccessful) {
                        Log.w(TAG, "弹幕接口 HTTP ${response.code}")
                        return@withContext emptyList()
                    }
                    val body = response.body?.string().orEmpty()
                    if (body.isBlank()) return@withContext emptyList()
                    parse(body)
                }
            } catch (t: Throwable) {
                // 网络抖动 / 地址配错 / JSON 畸形：记一条日志，返回空表，不影响播放
                Log.w(TAG, "拉取弹幕失败：${t.javaClass.simpleName}: ${t.message}")
                emptyList()
            }
        }

    /** 解析弹幕 JSON（数组或 {"danmaku":[…]}），脏数据逐条跳过。 */
    internal fun parse(body: String): List<DanmakuItem> {
        return try {
            val trimmed = body.trim()
            val array: JSONArray = when {
                trimmed.startsWith("[") -> JSONArray(trimmed)
                trimmed.startsWith("{") -> JSONObject(trimmed).optJSONArray("danmaku")
                    ?: return emptyList()
                else -> return emptyList()
            }
            buildList {
                for (i in 0 until array.length()) {
                    val obj = array.optJSONObject(i) ?: continue
                    val text = obj.optString("text")
                        .ifBlank { obj.optString("content") }
                        .trim()
                    if (text.isEmpty()) continue
                    val rawTime = obj.optDouble("time", Double.NaN)
                        .takeIf { !it.isNaN() }
                        ?: obj.optDouble("t", Double.NaN).takeIf { !it.isNaN() }
                        ?: continue
                    // 小于 10000 按秒算，否则按毫秒
                    val timeMs = if (rawTime < 10000) (rawTime * 1000).toLong() else rawTime.toLong()
                    if (timeMs < 0) continue
                    add(DanmakuItem(text = text, timeMs = timeMs))
                }
            }.sortedBy { it.timeMs }
        } catch (t: Throwable) {
            Log.w(TAG, "弹幕 JSON 解析失败：${t.javaClass.simpleName}")
            emptyList()
        }
    }
}
