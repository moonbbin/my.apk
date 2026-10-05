package com.tvbox.shell.config

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken

/**
 * 用户偏好持久化（模块七：交互增强）。
 *
 * 一个 `object`，全局一份，存三类东西：
 * 1. **上次选中的站点 / 配置源** —— 杀进程重开要能接着用（验收标准 5）；
 * 2. **搜索历史** —— 最多 [MAX_SEARCH_HISTORY] 条、去重、新的排最前；
 * 3. **上次播放的片子 id** —— 给"继续上次那一集"这类入口留的钩子。
 *
 * 存储走 `SharedPreferences("tvbox_prefs", MODE_PRIVATE)` + Gson 存 JSON 数组，
 * 不引 DataStore / Room —— 这点数据量不值得多一套依赖。
 *
 * ## 未 init 也安全（这条是刻意设计的，别改）
 * 本工程有一批**裸 JVM / Robolectric** 的验收与测试会在没有任何 Activity / Application
 * 的情况下创建 ViewModel。如果这里在未 init 时抛异常，那批用例会整片红。
 * 所以规则是：
 * - 读：未 init → 返回默认值（null / 空表），**不抛**；
 * - 写：未 init → 只落内存缓存 + 一条 `Log.w`，**不抛**；
 * - [init] 幂等，重复调用（Application 一次、测试一次）不会覆盖已有数据。
 *
 * 线程：SharedPreferences 本身线程安全；这里额外用内存缓存 + 单锁串行化读改写，
 * 避免"读 → 改 → 写"这条链在高频调用（搜索历史）下丢条目。
 */
object UserPreference {

    private const val TAG = "UserPreference"

    /** 契约指定的 prefs 文件名，别改。 */
    const val PREFS_NAME = "tvbox_prefs"

    private const val KEY_LAST_SELECTED_API = "last_selected_api"
    private const val KEY_LAST_SELECTED_SOURCE_ID = "last_selected_source_id"
    private const val KEY_SEARCH_HISTORY = "search_history"
    private const val KEY_LAST_PLAY_VOD_ID = "last_play_vod_id"

    /** 搜索历史上限：超过就丢最旧的。 */
    const val MAX_SEARCH_HISTORY: Int = 20

    private val gson = Gson()
    private val lock = Any()

    @Volatile
    private var prefs: SharedPreferences? = null

    /** 未 init 时的内存兜底，保证同一次进程里读写自洽（测试就是靠它）。 */
    private var memoryLastApi: String? = null
    private var memoryLastSourceId: String? = null
    private var memoryLastVodId: String? = null
    private var memorySearchHistory: List<String> = emptyList()

    /**
     * 初始化。用 `applicationContext`，不会漏 Activity。
     *
     * 幂等：同一个 Context 重复调是空操作；换了 Context（测试里换 Robolectric 实例）
     * 会重新绑定，并把内存里那份兜底数据留在原地（不丢）。
     */
    fun init(context: Context) {
        val app = context.applicationContext ?: context
        val bound = try {
            app.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        } catch (t: Throwable) {
            // 极少数桩环境下 getSharedPreferences 不可用；退回内存模式，绝不因此崩
            Log.e(TAG, "打开 SharedPreferences 失败，退回内存模式：${t.javaClass.simpleName}: ${t.message}")
            null
        }

        synchronized(lock) {
            val existing = prefs
            if (existing != null && existing === bound) return
            prefs = bound
            // 重新绑定（换 Application / 测试之间切换）时**以盘上的数据为准**重建内存缓存。
            // 不这么做的话，上一个进程留下的内存兜底值会在新 prefs 为空时被当成"真实数据"读出来，
            // 表现为"我明明没选过那个站，它却自己钉住了"。
            reloadMemoryLocked()
        }
    }

    /** 从 SharedPreferences 重建内存缓存（prefs 为 null 时把内存清空）。 */
    private fun reloadMemoryLocked() {
        val store = prefs
        if (store == null) {
            memoryLastApi = null
            memoryLastSourceId = null
            memoryLastVodId = null
            memorySearchHistory = emptyList()
            return
        }
        memoryLastApi = store.getString(KEY_LAST_SELECTED_API, null)
        memoryLastSourceId = store.getString(KEY_LAST_SELECTED_SOURCE_ID, null)
        memoryLastVodId = store.getString(KEY_LAST_PLAY_VOD_ID, null)
        memorySearchHistory = parseHistory(store.getString(KEY_SEARCH_HISTORY, null))
    }

    /** 是否已绑定真实存储（诊断用，业务代码不需要判）。 */
    fun isReady(): Boolean = prefs != null

    // ======================================================================
    // 上次选中的站点 / 配置源
    // ======================================================================

    /** 上次选中的采集站点 api（`csp_xxx` 那种）；从没选过返回 null。 */
    fun getLastSelectedApi(): String? = synchronized(lock) {
        p()?.getString(KEY_LAST_SELECTED_API, null)?.takeIf { it.isNotBlank() }
            ?: memoryLastApi?.takeIf { it.isNotBlank() }
    }

    /** 记下本次选中的站点 api。 */
    fun setLastSelectedApi(api: String) {
        val safe = api.trim()
        if (safe.isEmpty()) {
            Log.w(TAG, "setLastSelectedApi 收到空 api，忽略")
            return
        }
        synchronized(lock) {
            memoryLastApi = safe
            writeString(KEY_LAST_SELECTED_API, safe)
        }
    }

    /** 上次选中的配置源 id（[SiteSource.id]）；从没选过返回 null。 */
    fun getLastSelectedSourceId(): String? = synchronized(lock) {
        p()?.getString(KEY_LAST_SELECTED_SOURCE_ID, null)?.takeIf { it.isNotBlank() }
            ?: memoryLastSourceId?.takeIf { it.isNotBlank() }
    }

    /** 记下本次选中的配置源 id。 */
    fun setLastSelectedSourceId(id: String) {
        val safe = id.trim()
        if (safe.isEmpty()) {
            Log.w(TAG, "setLastSelectedSourceId 收到空 id，忽略")
            return
        }
        synchronized(lock) {
            memoryLastSourceId = safe
            writeString(KEY_LAST_SELECTED_SOURCE_ID, safe)
        }
    }

    // ======================================================================
    // 上次播放的片子
    // ======================================================================

    /** 上次播放的 vodId；没播过返回 null。 */
    fun getLastPlayVodId(): String? = synchronized(lock) {
        p()?.getString(KEY_LAST_PLAY_VOD_ID, null)?.takeIf { it.isNotBlank() }
            ?: memoryLastVodId?.takeIf { it.isNotBlank() }
    }

    /** 记下这次播放的片子 id。 */
    fun setLastPlayVodId(id: String) {
        val safe = id.trim()
        if (safe.isEmpty()) return
        synchronized(lock) {
            memoryLastVodId = safe
            writeString(KEY_LAST_PLAY_VOD_ID, safe)
        }
    }

    // ======================================================================
    // 搜索历史
    // ======================================================================

    /**
     * 搜索历史，**新的排最前**，最多 [MAX_SEARCH_HISTORY] 条。
     *
     * 脏数据（JSON 坏了 / 存进去的不是字符串数组）一律收敛成空表，不抛。
     */
    fun getSearchHistory(): List<String> = synchronized(lock) {
        val raw = p()?.getString(KEY_SEARCH_HISTORY, null)
        if (raw.isNullOrBlank()) return@synchronized memorySearchHistory
        memorySearchHistory = parseHistory(raw)
        memorySearchHistory
    }

    /** 把存下来的 JSON 解析成干净的字符串列表（脏数据一律收敛成空表，不抛）。 */
    private fun parseHistory(raw: String?): List<String> {
        if (raw.isNullOrBlank()) return emptyList()
        val parsed = try {
            gson.fromJson<List<String>>(raw, object : TypeToken<List<String>>() {}.type)
        } catch (t: Throwable) {
            Log.w(TAG, "搜索历史解析失败，按空表处理：${t.javaClass.simpleName}: ${t.message}")
            return emptyList()
        }
        return parsed.orEmpty()
            .filterNotNull()
            .map { it.trim() }
            .filter { it.isNotEmpty() }
            .distinct()
            .take(MAX_SEARCH_HISTORY)
    }

    /**
     * 加一条搜索历史：**去重**（已存在就先删掉旧的），新的插到最前，超出上限丢最旧的。
     *
     * 空串 / 纯空白不记（回车没输入内容时不该污染历史）。
     */
    fun addSearchHistory(keyword: String) {
        val safe = keyword.trim()
        if (safe.isEmpty()) return

        synchronized(lock) {
            val next = buildList {
                add(safe)
                addAll(getSearchHistory().filterNot { it.equals(safe, ignoreCase = true) })
            }.take(MAX_SEARCH_HISTORY)

            memorySearchHistory = next
            writeString(KEY_SEARCH_HISTORY, gson.toJson(next))
        }
    }

    /** 清空搜索历史。 */
    fun clearSearchHistory() {
        synchronized(lock) {
            memorySearchHistory = emptyList()
            writeString(KEY_SEARCH_HISTORY, gson.toJson(emptyList<String>()))
        }
    }

    /**
     * 删掉**一条**搜索历史（搜索页长按某个 Chip）。
     *
     * 契约里列的是 `clearSearchHistory()`，这个是它旁边必须有的一个：
     * 契约同时要求历史 Chip "可点击复用 / 长按删除"，没有单条删除那个手势就没落点。
     * 匹配是**大小写不敏感**的（跟 [addSearchHistory] 的去重口径保持一致）。
     */
    fun removeSearchHistory(keyword: String) {
        val safe = keyword.trim()
        if (safe.isEmpty()) return
        synchronized(lock) {
            val current = getSearchHistory()
            val next = current.filterNot { it.equals(safe, ignoreCase = true) }
            if (next.size == current.size) return
            memorySearchHistory = next
            writeString(KEY_SEARCH_HISTORY, gson.toJson(next))
        }
    }

    // ======================================================================
    // 播放器设置（需求4）
    // ======================================================================

    private const val KEY_DANMAKU_ENABLED = "danmaku_enabled"
    private const val KEY_DANMAKU_COLOR = "danmaku_color"
    private const val KEY_DANMAKU_TEXT_SCALE = "danmaku_text_scale"
    private const val KEY_DANMAKU_API = "danmaku_api"
    private const val KEY_PLAYER_CORE = "player_core"

    /** 播放器内核：`exo`（Media3/ExoPlayer，默认）/`system`（系统 VideoView）。 */
    const val PLAYER_CORE_EXO: String = "exo"
    const val PLAYER_CORE_SYSTEM: String = "system"

    private var memoryDanmakuEnabled: Boolean = false
    private var memoryDanmakuColor: Int = 0xFFFFFFFF.toInt()
    private var memoryDanmakuTextScale: Float = 1.0f
    private var memoryDanmakuApi: String = ""
    private var memoryPlayerCore: String = PLAYER_CORE_EXO

    /** 弹幕开关。 */
    fun isDanmakuEnabled(): Boolean = synchronized(lock) {
        if (p()?.contains(KEY_DANMAKU_ENABLED) == true) p()!!.getBoolean(KEY_DANMAKU_ENABLED, false)
        else memoryDanmakuEnabled
    }

    fun setDanmakuEnabled(enabled: Boolean) {
        synchronized(lock) {
            memoryDanmakuEnabled = enabled
            writeBoolean(KEY_DANMAKU_ENABLED, enabled)
        }
    }

    /** 弹幕颜色（ARGB Int，默认白色）。 */
    fun getDanmakuColor(): Int = synchronized(lock) {
        if (p()?.contains(KEY_DANMAKU_COLOR) == true) p()!!.getInt(KEY_DANMAKU_COLOR, 0xFFFFFFFF.toInt())
        else memoryDanmakuColor
    }

    fun setDanmakuColor(color: Int) {
        synchronized(lock) {
            memoryDanmakuColor = color
            writeInt(KEY_DANMAKU_COLOR, color)
        }
    }

    /** 弹幕字号倍率（默认 1.0）。 */
    fun getDanmakuTextScale(): Float = synchronized(lock) {
        if (p()?.contains(KEY_DANMAKU_TEXT_SCALE) == true) p()!!.getFloat(KEY_DANMAKU_TEXT_SCALE, 1.0f)
        else memoryDanmakuTextScale
    }

    fun setDanmakuTextScale(scale: Float) {
        val safe = scale.coerceIn(0.5f, 2.5f)
        synchronized(lock) {
            memoryDanmakuTextScale = safe
            writeFloat(KEY_DANMAKU_TEXT_SCALE, safe)
        }
    }

    /**
     * 弹幕源 API（模板，`{keyword}` 会被替换成片名）。
     * 为空 = 不拉弹幕，只显示开关/样式设置。
     */
    fun getDanmakuApi(): String = synchronized(lock) {
        p()?.getString(KEY_DANMAKU_API, null)?.takeIf { it.isNotBlank() } ?: memoryDanmakuApi
    }

    fun setDanmakuApi(api: String) {
        val safe = api.trim()
        synchronized(lock) {
            memoryDanmakuApi = safe
            writeString(KEY_DANMAKU_API, safe)
        }
    }

    /** 播放器内核（`exo` / `system`），非法值收敛成 exo。 */
    fun getPlayerCore(): String = synchronized(lock) {
        val v = p()?.getString(KEY_PLAYER_CORE, null)?.takeIf { it.isNotBlank() } ?: memoryPlayerCore
        if (v == PLAYER_CORE_SYSTEM) PLAYER_CORE_SYSTEM else PLAYER_CORE_EXO
    }

    fun setPlayerCore(core: String) {
        val safe = if (core == PLAYER_CORE_SYSTEM) PLAYER_CORE_SYSTEM else PLAYER_CORE_EXO
        synchronized(lock) {
            memoryPlayerCore = safe
            writeString(KEY_PLAYER_CORE, safe)
        }
    }

    // ======================================================================
    // 主题设置（需求5）
    // ======================================================================

    private const val KEY_THEME_MODE = "theme_mode"
    private const val KEY_BG_MODE = "bg_mode"
    private const val KEY_BG_COLOR = "bg_color"
    private const val KEY_BG_IMAGE_URL = "bg_image_url"
    private const val KEY_BG_IMAGE_PATH = "bg_image_path"

    private var memoryThemeMode: String = "system"
    private var memoryBgMode: String = "none"
    private var memoryBgColor: Int = 0xFF1C1C1E.toInt()
    private var memoryBgImageUrl: String = ""
    private var memoryBgImagePath: String = ""

    /** 主题模式 Flow（ShellTheme 订阅，设置页改完即时刷新）。 */
    val themeModeFlow = kotlinx.coroutines.flow.MutableStateFlow(getThemeMode())
    val bgModeFlow = kotlinx.coroutines.flow.MutableStateFlow(getBgMode())
    val bgColorFlow = kotlinx.coroutines.flow.MutableStateFlow(getBgColor())
    val bgImageUrlFlow = kotlinx.coroutines.flow.MutableStateFlow(getBgImageUrl())
    val bgImagePathFlow = kotlinx.coroutines.flow.MutableStateFlow(getBgImagePath())

    /** 主题模式：`system` / `light` / `dark`。 */
    fun getThemeMode(): String = synchronized(lock) {
        p()?.getString(KEY_THEME_MODE, null)?.takeIf { it.isNotBlank() } ?: memoryThemeMode
    }

    fun setThemeMode(mode: String) {
        val safe = when (mode) {
            "light", "dark" -> mode
            else -> "system"
        }
        synchronized(lock) {
            memoryThemeMode = safe
            writeString(KEY_THEME_MODE, safe)
            themeModeFlow.value = safe
        }
        com.tvbox.shell.ui.ThemeEvents.notifyChanged()
    }

    /** 背景模式：`none` / `color` / `image`。 */
    fun getBgMode(): String = synchronized(lock) {
        p()?.getString(KEY_BG_MODE, null)?.takeIf { it.isNotBlank() } ?: memoryBgMode
    }

    fun setBgMode(mode: String) {
        val safe = when (mode) {
            "color", "image" -> mode
            else -> "none"
        }
        synchronized(lock) {
            memoryBgMode = safe
            writeString(KEY_BG_MODE, safe)
            bgModeFlow.value = safe
        }
        com.tvbox.shell.ui.ThemeEvents.notifyChanged()
    }

    /** 自定义背景颜色（ARGB Int）。 */
    fun getBgColor(): Int = synchronized(lock) {
        if (p()?.contains(KEY_BG_COLOR) == true) p()!!.getInt(KEY_BG_COLOR, 0xFF1C1C1E.toInt())
        else memoryBgColor
    }

    fun setBgColor(color: Int) {
        synchronized(lock) {
            memoryBgColor = color
            writeInt(KEY_BG_COLOR, color)
            bgColorFlow.value = color
        }
        com.tvbox.shell.ui.ThemeEvents.notifyChanged()
    }

    /** 自定义背景网络 URL（支持 http(s)）。 */
    fun getBgImageUrl(): String = synchronized(lock) {
        p()?.getString(KEY_BG_IMAGE_URL, null)?.takeIf { it.isNotBlank() } ?: memoryBgImageUrl
    }

    fun setBgImageUrl(url: String) {
        val safe = url.trim()
        synchronized(lock) {
            memoryBgImageUrl = safe
            writeString(KEY_BG_IMAGE_URL, safe)
            bgImageUrlFlow.value = safe
        }
        com.tvbox.shell.ui.ThemeEvents.notifyChanged()
    }

    /** 自定义背景本地路径（优先级高于网络 URL）。 */
    fun getBgImagePath(): String = synchronized(lock) {
        p()?.getString(KEY_BG_IMAGE_PATH, null)?.takeIf { it.isNotBlank() } ?: memoryBgImagePath
    }

    fun setBgImagePath(path: String) {
        val safe = path.trim()
        synchronized(lock) {
            memoryBgImagePath = safe
            writeString(KEY_BG_IMAGE_PATH, safe)
            bgImagePathFlow.value = safe
        }
        com.tvbox.shell.ui.ThemeEvents.notifyChanged()
    }

    // ======================================================================
    // 解析接口（需求3）
    // ======================================================================

    private const val KEY_PARSE_APIS = "parse_apis"

    private var memoryParseApis: List<com.tvbox.shell.parse.ParseApi> = emptyList()

    /** 用户配的解析接口（按顺序试）。 */
    fun getParseApis(): List<com.tvbox.shell.parse.ParseApi> = synchronized(lock) {
        val raw = p()?.getString(KEY_PARSE_APIS, null)
        if (raw.isNullOrBlank()) return@synchronized memoryParseApis
        memoryParseApis = parseApiList(raw)
        memoryParseApis
    }

    fun setParseApis(apis: List<com.tvbox.shell.parse.ParseApi>) {
        val safe = apis.filter { it.isValid }
        synchronized(lock) {
            memoryParseApis = safe
            writeString(KEY_PARSE_APIS, gson.toJson(safe))
        }
    }

    private fun parseApiList(raw: String): List<com.tvbox.shell.parse.ParseApi> {
        return try {
            gson.fromJson<List<com.tvbox.shell.parse.ParseApi>>(
                raw,
                object : TypeToken<List<com.tvbox.shell.parse.ParseApi>>() {}.type
            ).orEmpty().filter { it.isValid }
        } catch (t: Throwable) {
            Log.w(TAG, "解析接口配置解析失败，按空表处理")
            emptyList()
        }
    }

    // ======================================================================
    // 内部
    // ======================================================================

    private fun p(): SharedPreferences? = prefs

    /**
     * 落盘。未 init 时只记一条 warn —— 内存那份已经更新过了，
     * 本次进程内读写是自洽的，只是重启后丢（测试场景完全够用）。
     */
    private fun writeString(key: String, value: String) {
        val store = p()
        if (store == null) {
            Log.w(TAG, "未初始化，$key 只留在内存（重启会丢）")
            return
        }
        try {
            store.edit().putString(key, value).apply()
        } catch (t: Throwable) {
            Log.e(TAG, "写入 $key 失败：${t.javaClass.simpleName}: ${t.message}")
        }
    }

    private fun writeBoolean(key: String, value: Boolean) {
        val store = p()
        if (store == null) {
            Log.w(TAG, "未初始化，$key 只留在内存（重启会丢）")
            return
        }
        try {
            store.edit().putBoolean(key, value).apply()
        } catch (t: Throwable) {
            Log.e(TAG, "写入 $key 失败：${t.javaClass.simpleName}: ${t.message}")
        }
    }

    private fun writeInt(key: String, value: Int) {
        val store = p()
        if (store == null) {
            Log.w(TAG, "未初始化，$key 只留在内存（重启会丢）")
            return
        }
        try {
            store.edit().putInt(key, value).apply()
        } catch (t: Throwable) {
            Log.e(TAG, "写入 $key 失败：${t.javaClass.simpleName}: ${t.message}")
        }
    }

    private fun writeFloat(key: String, value: Float) {
        val store = p()
        if (store == null) {
            Log.w(TAG, "未初始化，$key 只留在内存（重启会丢）")
            return
        }
        try {
            store.edit().putFloat(key, value).apply()
        } catch (t: Throwable) {
            Log.e(TAG, "写入 $key 失败：${t.javaClass.simpleName}: ${t.message}")
        }
    }
}
