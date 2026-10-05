package com.tvbox.shell.ui.component

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.LruCache
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.produceState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import java.io.File
import java.util.concurrent.TimeUnit

/**
 * 全局图片加载（OkHttp 拉字节流 → 解码 → 内存 LRU）。
 *
 * 项目不引入 Coil 等图片库（契约限制），所以这里用已有的 OkHttp 手写一个最小实现：
 * - 支持 `http(s)` 网络地址和本地文件路径（`/…` 或 `file://…`）；
 * - 内存缓存最多 48 张，按 URL/路径做 key；
 * - 任何一步失败返回 null，调用方自己画占位（绝不抛）。
 */
object AppImageLoader {

    private val cache = object : LruCache<String, Bitmap>(48) {}

    private val client: OkHttpClient by lazy {
        OkHttpClient.Builder()
            .connectTimeout(8, TimeUnit.SECONDS)
            .readTimeout(8, TimeUnit.SECONDS)
            .callTimeout(12, TimeUnit.SECONDS)
            .followRedirects(true)
            .build()
    }

    /**
     * 取一张图的图片。
     *
     * @param target 网络 URL 或本地文件路径。空串直接返回 null。
     * @return 解码后的 [ImageBitmap]，失败 null
     */
    suspend fun load(target: String): ImageBitmap? = withContext(Dispatchers.IO) {
        val key = target.trim()
        if (key.isEmpty()) return@withContext null
        cache.get(key)?.let { return@withContext it.asImageBitmap() }
        try {
            val bitmap: Bitmap? = if (isLocalPath(key)) {
                val file = File(key.removePrefix("file://"))
                if (!file.exists()) null
                else BitmapFactory.decodeFile(file.absolutePath)
            } else {
                val request = Request.Builder().url(key)
                    .header("User-Agent", UA).build()
                client.newCall(request).execute().use { resp ->
                    if (!resp.isSuccessful) return@withContext null
                    val bytes = resp.body?.bytes() ?: return@withContext null
                    if (bytes.isEmpty()) null
                    else BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
                }
            } ?: return@withContext null
            cache.put(key, bitmap)
            bitmap.asImageBitmap()
        } catch (e: CancellationException) {
            throw e
        } catch (t: Throwable) {
            null
        }
    }

    private fun isLocalPath(target: String): Boolean =
        target.startsWith("/") || target.startsWith("file://")

    private const val UA =
        "Mozilla/5.0 (Linux; Android 13; TVBoxShell/1.0) AppleWebKit/537.36 " +
            "(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36"
}

/**
 * 通用网络/本地图片。
 *
 * 加载中/失败时只显示 [fallback]（默认透明），不闪、不占位条——调用方想画占位自己包一层。
 */
@Composable
fun NetworkImage(
    url: String,
    contentDescription: String?,
    modifier: Modifier = Modifier,
    contentScale: ContentScale = ContentScale.Crop,
    fallback: @Composable () -> Unit = {}
) {
    val image by produceState<ImageBitmap?>(initialValue = null, url) {
        value = AppImageLoader.load(url)
    }
    val bitmap = image
    if (bitmap != null) {
        Image(
            bitmap = bitmap,
            contentDescription = contentDescription,
            contentScale = contentScale,
            modifier = modifier.fillMaxSize()
        )
    } else {
        Box(modifier = modifier, contentAlignment = Alignment.Center) {
            fallback()
        }
    }
}

/**
 * 影视封面（首页/详情/推荐共用）。
 *
 * 签名跟 HomeScreen 的调用点对齐：`RemotePoster(url, title, modifier)`。
 * 封面拉不到时退回"按片名散列的渐变 + 首字"，不留白。
 */
@Composable
fun RemotePoster(
    url: String,
    title: String,
    modifier: Modifier = Modifier
) {
    val image by produceState<ImageBitmap?>(initialValue = null, url) {
        value = AppImageLoader.load(url)
    }
    Box(
        modifier = modifier.background(fallbackBrush(title)),
        contentAlignment = Alignment.Center
    ) {
        val bitmap = image
        if (bitmap != null) {
            Image(
                bitmap = bitmap,
                contentDescription = title,
                contentScale = ContentScale.Crop,
                modifier = Modifier.fillMaxSize()
            )
        } else {
            Text(
                text = title.take(1).ifBlank { "海" },
                fontSize = 30.sp,
                fontWeight = FontWeight.Bold,
                color = Color(0xCCFFFFFF),
                textAlign = TextAlign.Center
            )
        }
    }
}

/** 占位底色：按标题散列挑一组固定渐变，同一标题每次颜色一致。 */
private fun fallbackBrush(title: String): Brush {
    val index = title.hashCode().mod(PosterGradients.size).let { if (it < 0) it + PosterGradients.size else it }
    val pair = PosterGradients[index]
    return Brush.linearGradient(listOf(pair.first, pair.second))
}

private val PosterGradients: List<Pair<Color, Color>> = listOf(
    Color(0xFF4338CA) to Color(0xFF9333EA),
    Color(0xFF0F766E) to Color(0xFF14B8A6),
    Color(0xFF9D174D) to Color(0xFFF472B6),
    Color(0xFF1E3A8A) to Color(0xFF3B82F6),
    Color(0xFF7C2D12) to Color(0xFFF59E0B)
)
