package com.tvbox.shell.config

/**
 * 配置源：整份站点配置的来源（一行）。
 *
 * @param id 唯一 id（选中状态按它记）
 * @param name 显示名（如"肥猫的源"）
 * @param url 配置 JSON 地址
 */
data class SiteSource(
    val id: String = "",
    val name: String = "",
    val url: String = ""
)
