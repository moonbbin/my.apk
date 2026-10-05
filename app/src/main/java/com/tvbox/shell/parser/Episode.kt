package com.tvbox.shell.parser

import android.util.Log
import com.tvbox.shell.model.Vod
import org.json.JSONArray
import org.json.JSONObject

/**
 * 一集：展示名 + 播放标识。
 *
 * [url] 不一定是直链——采集站给的经常是"第 3 集对应的站内 id"，
 * 真正的播放地址要拿它再调一次 `playerContent`（见 DetailViewModel）。
 */
data class Episode(
    val name: String = "",
    val url: String = ""
)

/**
 * 一组剧集 = 一个播放源。
 *
 * [flag] 是源名（如 `在线` / `线路二`），[episodes] 是该源的剧集表。
 * 跟 CMS 的 `vod_play_from` / `vod_play_url` 按 `$$$` 分段一一对应。
 */
data class EpisodeGroup(
    val flag: String = "",
    val episodes: List<Episode> = emptyList()
)

/** 首页分类（一行 type_id + type_name）。 */
data class HomeCategory(
    val typeId: String = "",
    val typeName: String = ""
)

/** 首页解析结果：分类 + 列表 + 出错时的原因（成功时为 null）。 */
data class HomeResult(
    val categories: List<HomeCategory> = emptyList(),
    val vodList: List<Vod> = emptyList(),
    val error: String? = null
)

/** 详情解析结果：补全后的 Vod + 按播放源分组的剧集表。 */
data class DetailResult(
    val vod: Vod,
    val groups: List<EpisodeGroup> = emptyList()
)

/** playerContent 解析结果。 */
data class PlayUrlInfo(
    /** 最终播放地址（可能为空——空表示要走解析/嗅探）。 */
    val url: String = "",
    /** 防盗链头。 */
    val headers: Map<String, String> = emptyMap(),
    /** 站点说"这个地址还要过一次解析"（CMS 的 parse 标记）。 */
    val needParse: Boolean = false
)

/**
 * CMS 接口 JSON 解析器（纯工具类，不碰网络，可单测）。
 *
 * 兼容的字段名写在 [FIELD_ALIASES] 里：网上五花八门的 CMS（苹果/海洋/XY 系列）
 * 字段名大同小异但总有几处不一样，这里按"先标准名、后别名"的顺序取，
 * 取不到就给空串——**不编造数据**，缺字段的条目照样返回，只是对应字段为空。
 *
 * 线程：无状态，哪里调都行。解析永不抛异常：坏 JSON 收敛成带 error 的 [HomeResult]。
 */
object HomeContentParser {

    private const val TAG = "HomeParser"

    /**
     * 字段别名表：key 是标准字段，value 是按优先级排的候选键。
     * 解析时按顺序取第一个非空的值。
     */
    private val FIELD_ALIASES: Map<String, List<String>> = mapOf(
        "vod_id" to listOf("vod_id", "id"),
        "vod_name" to listOf("vod_name", "name", "title"),
        "vod_pic" to listOf("vod_pic", "pic", "cover", "img"),
        "vod_remarks" to listOf("vod_remarks", "remarks", "note"),
        "vod_score" to listOf("vod_score", "score", "rating"),
        "vod_year" to listOf("vod_year", "year"),
        "vod_area" to listOf("vod_area", "area"),
        "vod_actor" to listOf("vod_actor", "actor"),
        "vod_director" to listOf("vod_director", "director"),
        "vod_content" to listOf("vod_content", "content", "desc", "blurb"),
        "type_id" to listOf("type_id", "tid"),
        "type_name" to listOf("type_name", "tname")
    )

    /** 首页：`{"class":[…],"list":[…]}`。 */
    fun parseHomeContent(json: String): HomeResult {
        if (json.isBlank()) return HomeResult(error = "空响应")
        return try {
            val root = JSONObject(json)
            val categories = parseClassArray(root.optJSONArray("class"))
            val vods = parseVodArray(root.optJSONArray("list"))
            HomeResult(categories = categories, vodList = vods)
        } catch (t: Throwable) {
            Log.w(TAG, "parseHomeContent 失败：${t.javaClass.simpleName}")
            HomeResult(error = "JSON 解析失败：${t.message}")
        }
    }

    /** 分类/搜索：只要 `list` 数组。 */
    fun parseVods(json: String): List<Vod> {
        if (json.isBlank()) return emptyList()
        return try {
            parseVodArray(JSONObject(json).optJSONArray("list"))
        } catch (t: Throwable) {
            Log.w(TAG, "parseVods 失败：${t.javaClass.simpleName}")
            emptyList()
        }
    }

    /** 详情：`{"list":[{…vod_play_from/vod_play_url…}]}` 取第一条。 */
    fun parseDetail(json: String, fallback: Vod): DetailResult {
        if (json.isBlank()) return DetailResult(vod = fallback)
        return try {
            val first = JSONObject(json).optJSONArray("list")?.optJSONObject(0)
                ?: return DetailResult(vod = fallback)
            val vod = parseVod(first).copy(
                vodId = pick(first, "vod_id").ifBlank { fallback.vodId },
                vodName = pick(first, "vod_name").ifBlank { fallback.vodName },
                vodPic = pick(first, "vod_pic").ifBlank { fallback.vodPic }
            )
            DetailResult(vod = vod, groups = splitEpisodeGroups(vod))
        } catch (t: Throwable) {
            Log.w(TAG, "parseDetail 失败：${t.javaClass.simpleName}")
            DetailResult(vod = fallback)
        }
    }

    /**
     * playerContent：`{"url":"…","header":{…},"parse":0/1}`。
     *
     * 网上源的写法不统一：`url` 也可能是 `playUrl`；header 可能是对象也可能是
     * `"Referer: xxx\nUser-Agent: yyy"` 这种多行字符串，都兼容。
     */
    fun parsePlayer(json: String): PlayUrlInfo {
        if (json.isBlank()) return PlayUrlInfo()
        return try {
            val root = JSONObject(json)
            val url = root.optString("url").ifBlank { root.optString("playUrl") }.trim()
            val headers = parseHeaderBlock(root)
            val needParse = root.optInt("parse", 0) == 1 || root.optBoolean("needParse", false)
            PlayUrlInfo(url = url, headers = headers, needParse = needParse || url.isBlank())
        } catch (t: Throwable) {
            Log.w(TAG, "parsePlayer 失败：${t.javaClass.simpleName}")
            PlayUrlInfo()
        }
    }

    /** 粗判"是不是合法 JSON 对象"（给调用方区分"接口坏了"和"内容为空"）。 */
    fun isWellFormed(json: String): Boolean {
        val t = json.trim()
        if (!t.startsWith("{") && !t.startsWith("[")) return false
        return try {
            JSONObject(json); true
        } catch (e1: Throwable) {
            try {
                JSONArray(json); true
            } catch (e2: Throwable) {
                false
            }
        }
    }

    // ============================ 内部 ============================

    private fun parseClassArray(arr: JSONArray?): List<HomeCategory> {
        if (arr == null) return emptyList()
        return buildList {
            for (i in 0 until arr.length()) {
                val o = arr.optJSONObject(i) ?: continue
                add(
                    HomeCategory(
                        typeId = pick(o, "type_id"),
                        typeName = pick(o, "type_name")
                    )
                )
            }
        }.filter { it.typeId.isNotBlank() || it.typeName.isNotBlank() }
    }

    private fun parseVodArray(arr: JSONArray?): List<Vod> {
        if (arr == null) return emptyList()
        return buildList {
            for (i in 0 until arr.length()) {
                arr.optJSONObject(i)?.let { add(parseVod(it)) }
            }
        }
    }

    private fun parseVod(o: JSONObject): Vod = Vod(
        vodId = pick(o, "vod_id"),
        vodName = pick(o, "vod_name"),
        vodPic = pick(o, "vod_pic"),
        vodRemarks = pick(o, "vod_remarks"),
        vodScore = pick(o, "vod_score"),
        vodYear = pick(o, "vod_year"),
        vodArea = pick(o, "vod_area"),
        vodActor = pick(o, "vod_actor"),
        vodDirector = pick(o, "vod_director"),
        vodContent = pick(o, "vod_content").replace("<[^>]+>".toRegex(), ""),
        typeId = pick(o, "type_id"),
        typeName = pick(o, "type_name"),
        vodPlayFrom = o.optString("vod_play_from").orEmpty(),
        vodPlayUrl = o.optString("vod_play_url").orEmpty()
    )

    /** 按别名表取第一个非空值。 */
    private fun pick(o: JSONObject, standard: String): String {
        val keys = FIELD_ALIASES[standard] ?: return o.optString(standard).orEmpty().trim()
        for (k in keys) {
            val v = o.optString(k).orEmpty().trim()
            if (v.isNotEmpty()) return v
        }
        return ""
    }

    private fun parseHeaderBlock(root: JSONObject): Map<String, String> {
        val out = LinkedHashMap<String, String>()
        val obj = root.optJSONObject("header")
        if (obj != null) {
            val keys = obj.keys()
            while (keys.hasNext()) {
                val k = keys.next()
                val v = obj.optString(k).orEmpty().trim()
                if (k.isNotBlank() && v.isNotBlank()) out[k.trim()] = v
            }
            return out
        }
        // 多行字符串写法："Referer: https://x/\nUser-Agent: yyy"
        val raw = root.optString("header").orEmpty()
        if (raw.isNotBlank() && !raw.trimStart().startsWith("{")) {
            raw.lines().forEach { line ->
                val idx = line.indexOf(':')
                if (idx > 0) {
                    val k = line.substring(0, idx).trim()
                    val v = line.substring(idx + 1).trim()
                    if (k.isNotEmpty() && v.isNotEmpty()) out[k] = v
                }
            }
        }
        return out
    }

    /**
     * `vod_play_from` / `vod_play_url` 拆成 [EpisodeGroup]。
     *
     * CMS 约定：`$$$` 分播放源，源内 `#` 分集，每集 `名字$地址`。
     * 有些源只有 url 没有 from（单源），有些集没有 `$`（整串就是地址，名字用"播放"兜底）。
     */
    fun splitEpisodeGroups(vod: Vod): List<EpisodeGroup> {
        val urlBlock = vod.vodPlayUrl.trim()
        if (urlBlock.isEmpty()) return emptyList()
        val fromParts = vod.vodPlayFrom.split("$$$").map { it.trim() }
        val urlParts = urlBlock.split("$$$")
        return urlParts.mapIndexed { index, part ->
            val flag = fromParts.getOrNull(index).orEmpty().ifBlank { "默认源" }
            val episodes = part.split("#").mapNotNull { seg ->
                val s = seg.trim()
                if (s.isEmpty()) return@mapNotNull null
                val dollar = s.lastIndexOf('$')
                if (dollar > 0) {
                    Episode(name = s.substring(0, dollar).trim(), url = s.substring(dollar + 1).trim())
                } else {
                    Episode(name = "播放", url = s)
                }
            }.filter { it.url.isNotEmpty() }
            EpisodeGroup(flag = flag, episodes = episodes)
        }.filter { it.episodes.isNotEmpty() }
    }
}
