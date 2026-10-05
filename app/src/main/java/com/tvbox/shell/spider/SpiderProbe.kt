package com.tvbox.shell.spider

import android.util.Log

/**
 * 探针装饰器：包一层真正的引擎，把"这次调用到底拿没拿到响应"记下来。
 *
 * 为什么需要：引擎返回 `{"class":[],"list":[]}` 有两种完全不同的含义——
 * "接口通了但源里没片"（合法空态）和"连不上/非 2xx/返回的不是 JSON"（故障）。
 * 只有引擎自己分得清。探针看两件事：抛没抛异常、返回的是不是"像 JSON 的东西"，
 * 记在 [lastCallFailed] 里，调用方（HomeViewModel 探活）按它决定换站还是显示空态。
 *
 * 注意：[lastCallFailed] 只反映**最近一次**调用，每次调用前复位。
 */
class SpiderProbe(
    private val delegate: Spider
) : Spider {

    /** 最近一次调用是否"没拿到可用响应"。读完即复位（下一次调用会重写）。 */
    var lastCallFailed: Boolean = false
        private set

    private fun <T> probe(what: String, block: () -> T): T {
        lastCallFailed = false
        return try {
            val result = block()
            if (result is String && !looksLikeJson(result)) {
                lastCallFailed = true
                Log.w(TAG, "$what 返回的不是 JSON（${result.take(80)}），记为失败")
            }
            result
        } catch (t: Throwable) {
            lastCallFailed = true
            Log.w(TAG, "$what 抛异常：${t.javaClass.simpleName}，记为失败")
            throw t
        }
    }

    private fun looksLikeJson(s: String): Boolean {
        val t = s.trimStart()
        return t.startsWith("{") || t.startsWith("[")
    }

    override fun homeContent(filter: Boolean): String =
        probe("homeContent") { delegate.homeContent(filter) }

    override fun categoryContent(
        tid: String,
        pg: String,
        filter: Boolean,
        extend: HashMap<String, String>
    ): String = probe("categoryContent") { delegate.categoryContent(tid, pg, filter, extend) }

    override fun detailContent(ids: List<String>): String =
        probe("detailContent") { delegate.detailContent(ids) }

    override fun searchContent(key: String, quick: Boolean): String =
        probe("searchContent") { delegate.searchContent(key, quick) }

    override fun playerContent(flag: String, id: String, vipFlags: List<String>): String =
        probe("playerContent") { delegate.playerContent(flag, id, vipFlags) }

    private companion object {
        const val TAG = "SpiderProbe"
    }
}
