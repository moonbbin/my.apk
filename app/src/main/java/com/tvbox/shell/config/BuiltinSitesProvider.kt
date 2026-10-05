package com.tvbox.shell.config

import com.tvbox.shell.model.Site

/**
 * 内置站点/配置源：一分配置都没有时，App 靠它起步。
 *
 * - [DEMO_API]：示范引擎的 api 标识（`csp_Demo`），[com.tvbox.shell.spider.SpiderManager.selfTest]
 *   和 HomeViewModel 的兜底都认它；
 * - [demoSite]：示范站点（点播类型，打开即有写死数据，专供无网络/无配置时演示流程）；
 * - [defaultSources]：内置的配置源列表（用户没配过源时，恢复链路从这里拿第一个）。
 *
 * 想让 App 开箱即用，把你常用的 CMS 接口地址填进 [defaultSources] 即可，
 * 它们走 CMS 直连引擎，不需要插件包。
 */
object BuiltinSitesProvider {

    /** 示范引擎 api。 */
    const val DEMO_API: String = "csp_Demo"

    /** 示范站点。 */
    val demoSite: Site = Site(
        key = DEMO_API,
        name = "示范站点",
        type = 3,
        api = DEMO_API
    )

    /**
     * 内置配置源。
     *
     * 默认给一个"本机演示"源（空地址，触发示范数据）；下面注释掉的是一行 CMS 示例，
     * 把注释解开并换成你自己的接口地址，App 就有真实片源了：
     * ```
     * SiteSource(id = "builtin_cms", name = "示例CMS", url = "https://你的接口/api.php/provide/vod/")
     * ```
     * 注意：url 直接写 CMS 接口根地址即可（[com.tvbox.shell.spider.CmsSpider] 会拼参数）。
     */
    fun defaultSources(): List<SiteSource> = listOf(
        SiteSource(id = "builtin_demo", name = "本机演示", url = "")
    )
}
