package com.tvbox.shell.parse

import android.util.Log
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import org.json.JSONObject
import java.net.URLEncoder
import java.util.concurrent.TimeUnit

/**
 * 播放地址解析链（需求3）。
 *
 * 一集的播放标识到真正能播的直链，中间可能隔着好几层，这个对象把顺序钉死：
 * ```
 * 直链（m3u8/mp4/…） → 直接播
 *   → 网盘分享链接 → 标记嗅探（WebSniffActivity 用 WebView 打开分享页抓直链）
 *   → 走用户配的解析接口（JSON / 302）逐个试
 *   → 都不行 → 嗅探（把原始页/播放页丢给 WebView 抓包）
 * ```
 *
 * 只做"拿地址"，不碰播放器。调用方是 DetailViewModel.onPlayEpisode。
 */
object ParseManager {

    private const val TAG = "ParseManager"

    /** 直链后缀（问号后面的参数不看）。 */
    private val DIRECT_SUFFIXES = listOf(
        ".m3u8", ".mp4", ".flv", ".ts", ".mpd", ".webm", ".mov", ".mkv", ".m4s", ".avi"
    )

    /** 网盘分享链接特征（阿里/夸克/115/百度）。 */
    private val PAN_HOSTS = listOf(
        "alipan.com", "aliyundrive.com",
        "pan.quark.cn", "quark.cn",
        "115.com", "pan.baidu.com"
    )

    /** 腾讯/爱奇艺/优酷/芒果/B站等站内播放页特征。 */
    private val VIP_HOSTS = listOf(
        "v.qq.com", "iqiyi.com", "youku.com", "mgtv.com",
        "bilibili.com", "sohu.com", "pptv.com", "le.com"
    )

    sealed interface Outcome {
        /** 拿到直链，直接播。 */
        data class Direct(val url: String, val headers: Map<String, String> = emptyMap()) : Outcome

        /** 需要 WebView 嗅探（网盘分享页 / 腾讯爱奇艺站内页 / 解析接口全挂）。 */
        data class NeedSniff(val pageUrl: String, val reason: String = "") : Outcome

        /** 彻底没辙。 */
        data class Failed(val message: String) : Outcome
    }

    /** 是不是一看就是直链。 */
    fun isDirectMedia(url: String): Boolean {
        val clean = url.trim()
        if (clean.isEmpty()) return false
        val path = clean.substringBefore("?").substringBefore("#").lowercase()
        if (DIRECT_SUFFIXES.any { path.endsWith(it) }) return true
        // 有些直链把后缀藏在参数里
        return clean.contains(".m3u8", ignoreCase = true)
    }

    /** 是不是网盘分享链接。 */
    fun isPanShare(url: String): Boolean =
        PAN_HOSTS.any { url.contains(it, ignoreCase = true) }

    /** 是不是腾讯/爱奇艺这类站内播放页（直链拿不到，只能嗅探）。 */
    fun isVipPage(url: String): Boolean =
        VIP_HOSTS.any { url.contains(it, ignoreCase = true) }

    /**
     * 解析一条播放标识。
     *
     * @param rawUrl 剧集的播放标识（可能是直链、网盘分享、站内页 id）
     * @param headers 站点给的防盗链头（直链时一起带上）
     * @param parseApis 用户在设置页配的解析接口，按顺序试
     */
    suspend fun resolve(
        rawUrl: String,
        headers: Map<String, String> = emptyMap(),
        parseApis: List<ParseApi> = emptyList()
    ): Outcome = withContext(Dispatchers.IO) {
        val clean = rawUrl.trim()
        if (clean.isEmpty()) return@withContext Outcome.Failed("播放地址为空")

        // 1) 直链：直接播
        if (isDirectMedia(clean)) {
            Log.d(TAG, "直链，直接播：${clean.take(120)}")
            return@withContext Outcome.Direct(clean, headers)
        }

        // 2) 网盘分享：只能嗅探（OAuth 接入太重，先走 WebView 抓分享页里的直链）
        if (isPanShare(clean)) {
            Log.i(TAG, "网盘分享链接，走嗅探：${clean.take(120)}")
            return@withContext Outcome.NeedSniff(clean, "网盘链接")
        }

        // 3) 腾讯/爱奇艺等站内页：直链拿不到，走嗅探
        if (isVipPage(clean)) {
            Log.i(TAG, "站内播放页，走嗅探：${clean.take(120)}")
            return@withContext Outcome.NeedSniff(clean, "站内视频")
        }

        // 4) 解析接口逐个试
        for (api in parseApis.filter { it.isValid }) {
            val direct = tryParseApi(api, clean)
            if (direct != null) {
                Log.i(TAG, "解析接口 ${api.name} 命中")
                return@withContext Outcome.Direct(direct.url, direct.headers + headers)
            }
        }

        // 5) 都不行：把原地址丢给 WebView 嗅探，死马当活马医
        Log.w(TAG, "解析接口无命中，走嗅探：${clean.take(120)}")
        Outcome.NeedSniff(clean, "自动嗅探")
    }

    /** 调一个解析接口，命中返回直链，否则 null。 */
    private fun tryParseApi(api: ParseApi, videoUrl: String): DirectHit? {
        return try {
            val target = api.url + URLEncoder.encode(videoUrl, "UTF-8")
            Log.d(TAG, "试解析接口 ${api.name}：${target.take(140)}")
            if (api.type == ParseApi.TYPE_URL) {
                // 302 跳转型：不跟跳转，取 Location
                val noRedirect = client.newBuilder().followRedirects(false).build()
                val req = Request.Builder().url(target).header("User-Agent", UA).build()
                noRedirect.newCall(req).execute().use { resp ->
                    val loc = resp.header("Location").orEmpty().trim()
                    if (loc.isNotBlank() && isDirectMedia(loc)) DirectHit(loc) else null
                }
            } else {
                val req = Request.Builder().url(target).header("User-Agent", UA).build()
                client.newCall(req).execute().use { resp ->
                    if (!resp.isSuccessful) return null
                    val body = resp.body?.string().orEmpty()
                    if (body.isBlank()) return null
                    extractUrlFromJson(body)?.let { DirectHit(it.url, it.headers) }
                }
            }
        } catch (t: Throwable) {
            Log.w(TAG, "解析接口 ${api.name} 异常：${t.javaClass.simpleName}")
            null
        }
    }

    /**
     * 从解析接口的 JSON 里抠直链。
     *
     * 兼容几种常见写法：`{"url":"…"} / {"data":{"url":"…"}} / {"code":200,"url":"…"}`，
     * header 兼容对象和多行字符串两种写法（跟 HomeContentParser.parsePlayer 同口径）。
     */
    private fun extractUrlFromJson(body: String): DirectHit? {
        return try {
            val t = body.trim()
            if (!t.startsWith("{")) return null
            val root = JSONObject(t)
            val dataObj = root.optJSONObject("data")
            val url = root.optString("url")
                .ifBlank { dataObj?.optString("url").orEmpty() }
                .ifBlank { root.optString("playUrl") }
                .trim()
            if (url.isEmpty()) return null
            val headers = mutableMapOf<String, String>()
            val hObj = root.optJSONObject("header") ?: dataObj?.optJSONObject("header")
            if (hObj != null) {
                val keys = hObj.keys()
                while (keys.hasNext()) {
                    val k = keys.next()
                    val v = hObj.optString(k).trim()
                    if (k.isNotBlank() && v.isNotBlank()) headers[k.trim()] = v
                }
            }
            DirectHit(url, headers)
        } catch (t: Throwable) {
            null
        }
    }

    private data class DirectHit(val url: String, val headers: Map<String, String> = emptyMap())

    private val client: OkHttpClient by lazy {
        OkHttpClient.Builder()
            .connectTimeout(10, TimeUnit.SECONDS)
            .readTimeout(15, TimeUnit.SECONDS)
            .callTimeout(25, TimeUnit.SECONDS)
            .followRedirects(true)
            .build()
    }

    private const val UA =
        "Mozilla/5.0 (Linux; Android 13; TVBoxShell/1.0) AppleWebKit/537.36 " +
            "(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36"
}
