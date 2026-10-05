package com.tvbox.shell.config

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import com.tvbox.shell.model.PlayHistory

/**
 * 观看历史存储（模块七：交互增强）。
 *
 * `object` 单例，`SharedPreferences` + Gson 存一个 `List<PlayHistory>` 的 JSON 数组。
 * 不引 Room：本地历史最多 [MAX_ENTRIES] 条（几十 KB），SQLite 那一套属于杀鸡用牛刀。
 *
 * ## 为什么是 object 而不是 class
 * 写入方在 [com.tvbox.shell.player.PlayerActivity]（每 5 秒一次 + onPause），
 * 读取方在历史页。做成全局单例，两边共用一份内存缓存，
 * 播放完返回首页立刻能在历史里看到，不用等磁盘回读。
 *
 * ## 未 init 也安全（别改）
 * 有一批裸 JVM / Robolectric 的验收会在没有 Application 的情况下构造播放器。
 * 规则和 [UserPreference] 一致：读给空表、写只落内存 + `Log.w`，绝不抛。
 *
 * 线程：所有公开方法在同一把锁里串行。
 */
object HistoryRepository {

    private const val TAG = "HistoryRepository"

    /** 存储文件名。 */
    const val PREFS_NAME = "tvbox_history"

    private const val KEY_HISTORY = "history_json"

    /**
     * 上限：超出丢**最旧**的（按 [PlayHistory.lastPlayedAt] 算，不是按插入顺序）。
     *
     * 为什么不按插入顺序丢：upsert 会原地更新老条目，插入顺序早就不是时间顺序了，
     * 按它丢会把"刚看完的老片子"错删掉。
     */
    const val MAX_ENTRIES: Int = 100

    private val gson = Gson()
    private val lock = Any()

    @Volatile
    private var prefs: SharedPreferences? = null

    /** 内存缓存。init 时从盘上读一次，之后读写都走它。 */
    private var cache: List<PlayHistory> = emptyList()

    private var loaded = false

    /**
     * 初始化。幂等，重复调用不会丢数据。
     *
     * 应用启动时（[com.tvbox.shell.TvBoxApp]）调一次；测试里也可以自己调。
     */
    fun init(context: Context) {
        synchronized(lock) {
            val app = context.applicationContext ?: context
            val store = try {
                app.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            } catch (t: Throwable) {
                Log.e(TAG, "打开 SharedPreferences 失败，退回内存模式：${t.javaClass.simpleName}: ${t.message}")
                null
            }
            prefs = store
            loaded = false
            if (store != null) {
                ensureLoadedLocked()
            }
        }
    }

    /** 是否已绑定真实存储（诊断用）。 */
    fun isReady(): Boolean = prefs != null

    /**
     * 全部历史，**按 [PlayHistory.lastPlayedAt] 降序**（最近看的在最前）。
     *
     * 脏数据（JSON 坏了 / 元素缺字段）只丢坏的那条，不连累整份。
     */
    fun getAll(): List<PlayHistory> = synchronized(lock) {
        ensureLoadedLocked()
        cache
    }

    /** 按 vodId 精确取一条；没有返回 null。 */
    fun getByVodId(vodId: String): PlayHistory? = synchronized(lock) {
        ensureLoadedLocked()
        val key = vodId.trim()
        if (key.isEmpty()) return@synchronized null
        cache.firstOrNull { it.vodId == key }
    }

    /**
     * 存在则更新、不存在则添加（就是 upsert）。
     *
     * 三条规则：
     * - 键是 [PlayHistory.vodId]；id 空但地址非空的条目用地址当键兜底（最坏也不丢记录）；
     * - 更新时**原地替换**，位置由 [PlayHistory.lastPlayedAt] 决定，不额外挪动；
     * - 写完立刻收敛到 [MAX_ENTRIES] 条上限。
     *
     * 完全无效的条目（id 和地址都空）直接丢弃 —— 那多半是调用方传漏了参数，
     * 记下来只会变成一条点不开的死记录。
     */
    fun upsert(history: PlayHistory) {
        if (!history.isValid()) {
            Log.w(TAG, "丢弃无效历史条目（vodId 和 episodeUrl 都为空）：vodName=${history.vodName}")
            return
        }

        synchronized(lock) {
            ensureLoadedLocked()

            val key = keyOf(history)
            val next = ArrayList<PlayHistory>(cache.size + 1)
            var replaced = false

            cache.forEach { existing ->
                if (keyOf(existing) == key) {
                    next += history
                    replaced = true
                } else {
                    next += existing
                }
            }
            if (!replaced) next += history

            cache = next
                .sortedByDescending { it.lastPlayedAt }
                .take(MAX_ENTRIES)
            persistLocked()
        }
    }

    /** 删一条（按 vodId）。删不存在的 id 是空操作。 */
    fun remove(vodId: String) {
        synchronized(lock) {
            ensureLoadedLocked()
            val key = vodId.trim()
            if (key.isEmpty()) return@synchronized
            val next = cache.filterNot { keyOf(it) == key }
            if (next.size == cache.size) return@synchronized
            cache = next
            persistLocked()
        }
    }

    /** 清空全部历史。 */
    fun clear() {
        synchronized(lock) {
            ensureLoadedLocked()
            cache = emptyList()
            persistLocked()
        }
    }

    // ======================================================================
    // 内部
    // ======================================================================

    /** 一条历史的唯一键：优先 vid，没有就用地址。 */
    private fun keyOf(history: PlayHistory): String =
        history.vodId.trim().ifEmpty { history.episodeUrl.trim() }

    private fun ensureLoadedLocked() {
        if (loaded) return
        loaded = true

        val raw = prefs?.getString(KEY_HISTORY, null)
        if (raw.isNullOrBlank()) {
            cache = emptyList()
            return
        }

        val parsed: List<PlayHistory>? = try {
            gson.fromJson<List<PlayHistory>>(raw, object : TypeToken<List<PlayHistory>>() {}.type)
        } catch (t: Throwable) {
            Log.w(TAG, "历史 JSON 解析失败，按空表处理：${t.javaClass.simpleName}: ${t.message}")
            null
        }

        cache = parsed.orEmpty()
            .filterNotNull()
            .filter { it.isValid() }
            // Gson 不走构造函数，基本类型缺字段会留成 0，已经是我们要的默认值；
            // 这里只兜住引用类型可能为 null 的坑
            .map {
                it.copy(
                    vodId = it.vodId.orEmpty(),
                    vodName = it.vodName.orEmpty(),
                    vodPic = it.vodPic.orEmpty(),
                    episodeName = it.episodeName.orEmpty(),
                    episodeUrl = it.episodeUrl.orEmpty()
                )
            }
            .sortedByDescending { it.lastPlayedAt }
            .take(MAX_ENTRIES)
    }

    private fun persistLocked() {
        val store = prefs
        if (store == null) {
            Log.w(TAG, "未初始化，历史只留在内存（重启会丢），当前 ${cache.size} 条")
            return
        }
        try {
            store.edit().putString(KEY_HISTORY, gson.toJson(cache)).apply()
        } catch (t: Throwable) {
            Log.e(TAG, "历史落盘失败：${t.javaClass.simpleName}: ${t.message}")
        }
    }
}
