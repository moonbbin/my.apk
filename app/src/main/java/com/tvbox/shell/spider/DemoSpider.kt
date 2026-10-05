package com.tvbox.shell.spider

import org.json.JSONArray
import org.json.JSONObject

/**
 * 示范引擎：无网络 / 无配置时的兜底，返回写死数据。
 *
 * 用途：
 * - [SpiderManager.selfTest] 的自检对象；
 * - [com.tvbox.shell.ui.home.HomeViewModel] 的最后一道兜底（全部站点都失败时显示它）。
 *
 * 数据是**写死的演示数据**（不是从网上拉的），详情页点开能看到剧集表，
 * 点播放会播一段公开的测试流（mux 的 x36xhzz），用来验证"详情→解析→播放"整条链路。
 */
class DemoSpider : Spider {

    override fun homeContent(filter: Boolean): String = JSONObject()
        .put("class", JSONArray().apply {
            put(JSONObject().put("type_id", "1").put("type_name", "电影"))
            put(JSONObject().put("type_id", "2").put("type_name", "电视剧"))
        })
        .put("list", demoList())
        .toString()

    override fun categoryContent(
        tid: String,
        pg: String,
        filter: Boolean,
        extend: HashMap<String, String>
    ): String = JSONObject()
        .put("page", pg)
        .put("list", demoList())
        .toString()

    override fun detailContent(ids: List<String>): String {
        val id = ids.firstOrNull().orEmpty()
        val vod = JSONObject()
            .put("vod_id", id.ifBlank { "demo1" })
            .put("vod_name", "示范影片")
            .put("vod_pic", "")
            .put("vod_remarks", "演示数据")
            .put("vod_year", "2026")
            .put("vod_area", "内地")
            .put("vod_actor", "演示演员")
            .put("vod_content", "这是一部示范影片，用来在没有配置源时演示详情页、剧集表和播放链路。")
            .put("type_name", "电影")
            .put("vod_play_from", "演示源")
            .put(
                "vod_play_url",
                "第1集\$$DEMO_STREAM#第2集\$$DEMO_STREAM"
            )
        return JSONObject().put("list", JSONArray().put(vod)).toString()
    }

    override fun searchContent(key: String, quick: Boolean): String {
        val all = demoList()
        val hit = JSONArray()
        for (i in 0 until all.length()) {
            val o = all.getJSONObject(i)
            if (o.optString("vod_name").contains(key)) hit.put(o)
        }
        return JSONObject().put("list", hit).toString()
    }

    override fun playerContent(flag: String, id: String, vipFlags: List<String>): String =
        JSONObject().put("url", id.ifBlank { DEMO_STREAM }).put("parse", 0).toString()

    private fun demoList(): JSONArray = JSONArray().apply {
        put(
            JSONObject()
                .put("vod_id", "demo1")
                .put("vod_name", "示范影片")
                .put("vod_pic", "")
                .put("vod_remarks", "演示数据")
        )
        put(
            JSONObject()
                .put("vod_id", "demo2")
                .put("vod_name", "示范剧集")
                .put("vod_pic", "")
                .put("vod_remarks", "共2集")
        )
    }

    companion object {
        /** 公开测试流（mux），仅示范播放链路用。 */
        const val DEMO_STREAM: String = "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8"
    }
}
