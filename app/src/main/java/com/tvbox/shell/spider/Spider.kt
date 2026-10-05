package com.tvbox.shell.spider

/**
 * 采集引擎接口（TVBox CatVod 系契约的 Kotlin 版）。
 *
 * 所有方法都返回 **JSON 字符串**（不是对象），调用方（ViewModel）再交给
 * [com.tvbox.shell.parser.HomeContentParser] 解析——引擎只负责"拿到原始响应"，
 * 解析口径统一在一处，这是跟详情页"UI 不碰解析"同一条线。
 *
 * 方法名/签名跟既有调用点（HomeViewModel、测试里的 RecordingSpider）一字对齐，
 * 改签名会同时炸掉测试，别动。
 */
interface Spider {

    /** 首页：`{"class":[…],"list":[…]}`。 */
    fun homeContent(filter: Boolean): String

    /** 分类：`{"page":"1","list":[…]}`。 */
    fun categoryContent(
        tid: String,
        pg: String,
        filter: Boolean,
        extend: HashMap<String, String>
    ): String

    /** 详情：`{"list":[{…vod_play_from/vod_play_url…}]}`。 */
    fun detailContent(ids: List<String>): String

    /** 搜索：`{"list":[…]}`。 */
    fun searchContent(key: String, quick: Boolean): String

    /** 取播放地址：`{"url":"…","header":{…},"parse":0/1}`。 */
    fun playerContent(flag: String, id: String, vipFlags: List<String>): String
}
