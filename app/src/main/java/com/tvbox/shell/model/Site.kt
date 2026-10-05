package com.tvbox.shell.model

/**
 * 采集站点（一行配置）。
 *
 * 字段口径（跟既有调用点对齐）：
 * - [key] 站点唯一键，默认取 [api]；
 * - [type] TVBox 约定：3 = 点播采集站；
 * - [api] 引擎标识：`csp_xxx` 走插件引擎，`http…` 开头走内置 CMS 直连引擎（见 CmsSpider）；
 * - [extString] 引擎扩展参数：插件引擎用它找 jar/类名，CMS 引擎用它当备用 host。
 *
 * 全字段默认值：[HomeViewModel] 里有 `Site()` 这种空构造用法。
 */
data class Site(
    val key: String = "",
    val name: String = "",
    val type: Int = 0,
    val api: String = "",
    val extString: String = ""
) {
    /** 有效键：key 为空时退回 api。 */
    val effectiveKey: String get() = key.ifBlank { api }

    /** 是否 CMS 直连站（api 本身就是 http 地址）。 */
    val isCmsDirect: Boolean get() = api.startsWith("http", ignoreCase = true)

    /** 是否插件引擎站（csp_ 前缀）。 */
    val isPlugin: Boolean get() = api.startsWith("csp_", ignoreCase = true)
}

/**
 * 当前生效的整份配置（内存里那份）。
 *
 * 配置源拉回来的是 JSON（见 [com.tvbox.shell.config.ConfigLoader]），
 * 站点数组的字段名兼容 `sites` / `videoSites` / `list` 三种写法。
 */
data class AppConfig(
    val sites: List<Site> = emptyList()
)

/**
 * 影视条目（列表 / 详情共用）。
 *
 * 字段是苹果 CMS 系接口的常用全集：`vod_id / vod_name / vod_pic / vod_remarks …`，
 * 详情接口多给的 `vod_play_from / vod_play_url`（`$$$` 分播放源、`#` 分剧集）也收在这里，
 * 免得详情和列表各搞一套类。
 */
data class Vod(
    val vodId: String = "",
    val vodName: String = "",
    val vodPic: String = "",
    val vodRemarks: String = "",
    val vodScore: String = "",
    val vodYear: String = "",
    val vodArea: String = "",
    val vodActor: String = "",
    val vodDirector: String = "",
    val vodContent: String = "",
    val typeId: String = "",
    val typeName: String = "",
    /** 播放源标识串，`$$$` 分隔（如 `在线$$$线路二`），与 [vodPlayUrl] 按段一一对应。 */
    val vodPlayFrom: String = "",
    /** 各源剧集串，`$$$` 分源，源内 `#` 分集，每集形如 `第1集$https://…`。 */
    val vodPlayUrl: String = ""
)
