package com.tvbox.shell.spider

import android.util.Log
import android.util.Xml
import okhttp3.OkHttpClient
import okhttp3.Request
import org.json.JSONArray
import org.json.JSONObject
import org.xmlpull.v1.XmlPullParser
import java.net.URLEncoder
import java.util.concurrent.TimeUnit

/**
 * CMS 直连引擎（需求2：适配网上五花八门的影视源接口）。
 *
 * 站点配置里 `api` 直接写 `http…` 地址时走这个引擎，**不需要插件包**：
 * 它把苹果 CMS / 海洋 CMS 系的 HTTP 接口（`/api.php/provide/vod/` 这类）
 * 转成跟插件引擎一模一样的 JSON，剩下的链路（解析、展示）完全不用改。
 *
 * 兼容两套返回格式：
 * - **JSON**：`{"class":[…],"list":[{vod_id…}]}`，字段别名由 HomeContentParser 兼容；
 * - **XML**：老 CMS 的 rss 风格（`<rss><list><video>…`），这里转成同样的 JSON 再返回。
 *
 * 接口约定（苹果 CMS 系）：
 * - 首页/分类：`?ac=videolist` / `?ac=videolist&t={tid}&pg={pg}`
 * - 搜索：`?ac=videolist&wd={关键词}`
 * - 详情：`?ac=detail&ids={vod_id}`
 *
 * 有些站点的 api 地址本身已经带了 `?ac=…`，这时直接拼 `&` 参数；
 * 啥都没带的裸域名，默认按 `/api.php/provide/vod/` 补全（ext 可覆盖路径，见 [CmsApiProbe]）。
 */
class CmsSpider(
    private val apiBase: String,
    private val ext: String = ""
) : Spider {

    private val client: OkHttpClient by lazy {
        OkHttpClient.Builder()
            .connectTimeout(10, TimeUnit.SECONDS)
            .readTimeout(15, TimeUnit.SECONDS)
            .callTimeout(20, TimeUnit.SECONDS)
            .followRedirects(true)
            .build()
    }

    override fun homeContent(filter: Boolean): String =
        get("ac=videolist").let(::normalize)

    override fun categoryContent(
        tid: String,
        pg: String,
        filter: Boolean,
        extend: HashMap<String, String>
    ): String = get("ac=videolist&t=${enc(tid)}&pg=${enc(pg)}").let(::normalize)

    override fun detailContent(ids: List<String>): String =
        get("ac=detail&ids=${enc(ids.joinToString(","))}").let(::normalize)

    override fun searchContent(key: String, quick: Boolean): String =
        get("ac=videolist&wd=${enc(key)}").let(::normalize)

    /**
     * CMS 直连没有"二次取流"接口：详情里 `vod_play_url` 拆出来的本来就是直链。
     *
     * - [id] 是 http 直链 → 原样返回，播放器直接播；
     * - 否则 → `parse:1`，交给 [com.tvbox.shell.parse.ParseManager] 走解析/嗅探链。
     */
    override fun playerContent(flag: String, id: String, vipFlags: List<String>): String {
        val clean = id.trim()
        return if (clean.startsWith("http", ignoreCase = true)) {
            JSONObject().put("url", clean).put("parse", 0).toString()
        } else {
            JSONObject().put("url", clean).put("parse", 1).toString()
        }
    }

    // ============================ 内部 ============================

    private fun get(query: String): String {
        val url = buildUrl(query)
        Log.d(TAG, "CMS 请求：$url")
        val request = Request.Builder()
            .url(url)
            .header("User-Agent", UA)
            .build()
        client.newCall(request).execute().use { resp ->
            if (!resp.isSuccessful) {
                Log.w(TAG, "CMS 非 2xx：${resp.code} $url")
                return ""
            }
            return resp.body?.string().orEmpty()
        }
    }

    private fun buildUrl(query: String): String {
        var base = apiBase.trim()
        if (!base.contains("?")) {
            // 裸域名/裸路径：补默认接口路径（ext 可指定别的，如 "/api.php/provide/vod_at/"）
            val path = ext.trim().ifBlank { DEFAULT_API_PATH }
            base = base.trimEnd('/') + (if (path.startsWith("/")) path else "/$path")
            return "$base?$query"
        }
        val sep = if (base.endsWith("?") || base.endsWith("&")) "" else "&"
        return "$base$sep$query"
    }

    /** XML 转 JSON；JSON 原样返回；都不是就返回空串（探针会记失败）。 */
    private fun normalize(raw: String): String {
        val t = raw.trim()
        if (t.isEmpty()) return ""
        if (t.startsWith("<")) return xmlToJson(t)
        return t
    }

    /**
     * 老 CMS 的 XML（`<rss><class><ty id="1">电影</ty></class><list><video>…`）
     * 转成 `{"class":[…],"list":[…]}`，字段名跟 JSON 版对齐。
     */
    private fun xmlToJson(xml: String): String {
        return try {
            val parser: XmlPullParser = Xml.newPullParser()
            parser.setInput(xml.reader())
            val classes = JSONArray()
            val list = JSONArray()
            var event = parser.eventType
            var inVideo = false
            var cur: JSONObject? = null
            var textOf: String? = null
            var ddFlag = ""
            while (event != XmlPullParser.END_DOCUMENT) {
                when (event) {
                    XmlPullParser.START_TAG -> {
                        when (parser.name) {
                            "ty" -> {
                                val id = parser.getAttributeValue(null, "id").orEmpty()
                                textOf = "ty:$id"
                            }
                            "video" -> {
                                inVideo = true
                                cur = JSONObject()
                            }
                            "dl" -> {
                                // 播放源分组：<dl><dt>在线</dt><dd>第1集$http://…#…</dd></dl>
                                ddFlag = parser.getAttributeValue(null, "flag").orEmpty()
                                textOf = null
                            }
                            "dt", "dd" -> textOf = parser.name
                            else -> textOf = if (inVideo) parser.name else null
                        }
                    }
                    XmlPullParser.TEXT -> {
                        val text = parser.text.orEmpty()
                        when {
                            textOf?.startsWith("ty:") == true -> {
                                val id = textOf!!.substringAfter("ty:")
                                if (text.isNotBlank()) {
                                    classes.put(JSONObject().put("type_id", id).put("type_name", text.trim()))
                                }
                            }
                            textOf == "dt" -> ddFlag = ddFlag.ifBlank { text.trim() }
                            textOf == "dd" -> {
                                // dd 内容追加到播放串
                                cur?.let { mergePlay(it, ddFlag.ifBlank { "默认源" }, text.trim()) }
                            }
                            inVideo && textOf != null -> {
                                val v = text.trim()
                                if (v.isNotEmpty()) {
                                    cur?.put(XML_FIELD_MAP[textOf] ?: textOf!!, v)
                                }
                            }
                        }
                        if (textOf?.startsWith("ty:") == true) textOf = null
                    }
                    XmlPullParser.END_TAG -> {
                        if (parser.name == "video") {
                            cur?.let { list.put(it) }
                            inVideo = false
                            cur = null
                        }
                        textOf = null
                    }
                }
                event = parser.next()
            }
            JSONObject().put("class", classes).put("list", list).toString()
        } catch (t: Throwable) {
            Log.w(TAG, "XML 转 JSON 失败：${t.javaClass.simpleName}")
            ""
        }
    }

    /** 把 <dd> 的剧集串按 CMS 的 $$$ / # 约定并进 vod_play_from / vod_play_url。 */
    private fun mergePlay(video: JSONObject, flag: String, dd: String) {
        if (dd.isBlank()) return
        val from = video.optString("vod_play_from")
        val urls = video.optString("vod_play_url")
        video.put("vod_play_from", if (from.isBlank()) flag else "$from$$$flag")
        video.put("vod_play_url", if (urls.isBlank()) dd else "$urls$$$dd")
    }

    private fun enc(s: String): String = URLEncoder.encode(s, "UTF-8")

    companion object {
        private const val TAG = "CmsSpider"
        private const val DEFAULT_API_PATH = "/api.php/provide/vod/"
        private const val UA =
            "Mozilla/5.0 (Linux; Android 13; TVBoxShell/1.0) AppleWebKit/537.36 " +
                "(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36"

        /** XML 标签 → 标准字段。 */
        private val XML_FIELD_MAP = mapOf(
            "id" to "vod_id",
            "name" to "vod_name",
            "pic" to "vod_pic",
            "note" to "vod_remarks",
            "year" to "vod_year",
            "area" to "vod_area",
            "actor" to "vod_actor",
            "director" to "vod_director",
            "des" to "vod_content"
        )
    }
}
