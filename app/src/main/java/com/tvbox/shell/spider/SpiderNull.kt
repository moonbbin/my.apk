package com.tvbox.shell.spider

/**
 * 兜底空引擎：站点拿不到可用引擎时用的占位实现。
 *
 * 故意只返回 `{"class":[],"list":[]}`——调用方（HomeViewModel）靠 `is SpiderNull`
 * 把它识别成"引擎缺失"而不是"源没内容"，这条 `is` 判断是整条链路的静默失败防火墙，
 * 别把它"优化"成返回 null 或抛异常。
 */
class SpiderNull : Spider {
    override fun homeContent(filter: Boolean): String = EMPTY

    override fun categoryContent(
        tid: String,
        pg: String,
        filter: Boolean,
        extend: HashMap<String, String>
    ): String = EMPTY_LIST

    override fun detailContent(ids: List<String>): String = EMPTY_LIST

    override fun searchContent(key: String, quick: Boolean): String = EMPTY_LIST

    override fun playerContent(flag: String, id: String, vipFlags: List<String>): String =
        """{"parse":1,"url":""}"""

    companion object {
        private const val EMPTY = """{"class":[],"list":[]}"""
        private const val EMPTY_LIST = """{"list":[]}"""
    }
}
