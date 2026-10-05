package com.tvbox.shell.config

import android.content.Context
import android.util.Log
import com.tvbox.shell.model.AppConfig
import com.tvbox.shell.model.Site

/**
 * 当前配置的内存持有者（进程级单例）。
 *
 * 配置只活在内存里：杀进程重开就是空的，靠 [SourceRestorer] 在启动/首页恢复。
 * 换配置源（[com.tvbox.shell.ui.home.HomeViewModel.switchSource]）走 [updateConfig]。
 *
 * 线程安全：读写都走同一把锁。
 */
object AppConfigManager {

    private const val TAG = "AppConfigManager"

    private val lock = Any()
    private var current: AppConfig = AppConfig()

    /** 当前配置（没加载过就是空配置，sites 为空）。 */
    fun getCurrentConfig(): AppConfig = synchronized(lock) { current }

    /** 换一份新配置（换源 / 首次加载成功时调）。 */
    fun updateConfig(config: AppConfig) {
        synchronized(lock) { current = config }
        Log.i(TAG, "配置已更新，站点数：${config.sites.size}")
    }

    /** 按 key 找站点。 */
    fun findSite(key: String): Site? = synchronized(lock) {
        current.sites.firstOrNull { it.effectiveKey == key || it.api == key }
    }
}

/**
 * 配置源仓库：用户配过的"配置源"列表 + 当前选中项。
 *
 * 持久化走 [UserPreference]（选中 id）+ 内置默认源；
 * 用户在设置页添加的源存在 SharedPreferences 的 JSON 数组里。
 */
class SiteRepository(context: Context) {

    private val appContext = context.applicationContext ?: context
    private val prefs by lazy {
        appContext.getSharedPreferences(PREFS_SOURCES, Context.MODE_PRIVATE)
    }

    /** 全部配置源（内置默认 + 用户添加的）。 */
    fun getSources(): List<SiteSource> {
        val defaults = BuiltinSitesProvider.defaultSources()
        val custom = readCustom()
        return defaults + custom
    }

    /** 当前选中的配置源（没选过返回 null）。 */
    fun getSelected(): SiteSource? {
        val id = prefs.getString(KEY_SELECTED_ID, null)
        return getSources().firstOrNull { it.id == id }
    }

    /** 选中一个配置源（只记 id，真正的加载由调用方做）。 */
    fun selectSource(id: String) {
        prefs.edit().putString(KEY_SELECTED_ID, id.trim()).apply()
    }

    /** 添加用户自己的配置源（url 必须 http 开头，重复 url 不重复加）。 */
    fun addSource(name: String, url: String): SiteSource? {
        val cleanUrl = url.trim()
        if (!cleanUrl.startsWith("http", ignoreCase = true)) return null
        val custom = readCustom().toMutableList()
        if (custom.any { it.url.equals(cleanUrl, ignoreCase = true) }) {
            return custom.first { it.url.equals(cleanUrl, ignoreCase = true) }
        }
        val source = SiteSource(
            id = "custom_${System.currentTimeMillis()}",
            name = name.trim().ifBlank { cleanUrl },
            url = cleanUrl
        )
        custom.add(source)
        writeCustom(custom)
        return source
    }

    /** 删除用户添加的配置源（内置的不让删）。 */
    fun removeSource(id: String): Boolean {
        val custom = readCustom().toMutableList()
        val removed = custom.removeIf { it.id == id }
        if (removed) writeCustom(custom)
        return removed
    }

    private fun readCustom(): List<SiteSource> {
        val raw = prefs.getString(KEY_CUSTOM, null).orEmpty()
        if (raw.isBlank()) return emptyList()
        return try {
            val arr = org.json.JSONArray(raw)
            buildList {
                for (i in 0 until arr.length()) {
                    val o = arr.optJSONObject(i) ?: continue
                    add(
                        SiteSource(
                            id = o.optString("id"),
                            name = o.optString("name"),
                            url = o.optString("url")
                        )
                    )
                }
            }.filter { it.id.isNotBlank() && it.url.isNotBlank() }
        } catch (t: Throwable) {
            emptyList()
        }
    }

    private fun writeCustom(list: List<SiteSource>) {
        val arr = org.json.JSONArray()
        list.forEach {
            arr.put(
                org.json.JSONObject()
                    .put("id", it.id)
                    .put("name", it.name)
                    .put("url", it.url)
            )
        }
        prefs.edit().putString(KEY_CUSTOM, arr.toString()).apply()
    }

    companion object {
        private const val PREFS_SOURCES = "tvbox_sources"
        private const val KEY_SELECTED_ID = "selected_source_id"
        private const val KEY_CUSTOM = "custom_sources"
    }
}
