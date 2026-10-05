package com.tvbox.shell.parse

/**
 * 解析接口（一行配置）。
 *
 * 网上五花八门的解析接口分两种：
 * - [TYPE_JSON]：`GET {url}{视频页地址}` 返回 JSON，从 `url` / `data.url` 取直链，
 *   `header` 字段取防盗链头；
 * - [TYPE_URL]：`GET {url}{视频页地址}` 直接 302 跳到直链（取最终 Location）。
 *
 * 存在 [com.tvbox.shell.config.UserPreference]（JSON 数组），设置页可增删改。
 */
data class ParseApi(
    val name: String = "",
    val url: String = "",
    val type: Int = TYPE_JSON
) {
    companion object {
        const val TYPE_JSON: Int = 0
        const val TYPE_URL: Int = 1
    }

    /** 是否有效（名和地址都有）。 */
    val isValid: Boolean get() = name.isNotBlank() && url.startsWith("http", ignoreCase = true)
}
