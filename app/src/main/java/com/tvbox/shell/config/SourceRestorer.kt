package com.tvbox.shell.config

import android.content.Context
import android.util.Log
import com.tvbox.shell.model.AppConfig
import com.tvbox.shell.model.Site
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.lang.ref.WeakReference

/**
 * 冷启动恢复：配置只活在内存里（[AppConfigManager]），杀进程重开就是空的。
 *
 * 两处调用：
 * - [TvBoxApp.onCreate] 里 [attach] 注入 Context（只记弱引用，不漏）；
 * - [com.tvbox.shell.ui.home.HomeScreen] 把 `::restoreIfEmpty` 传给 HomeViewModel，
 *   内存里没有站点时去把"上次选中的配置源"重新拉回来。
 *
 * 恢复不到（没选过源 / 拉失败）返回 null，调用方按原逻辑报错，不抛。
 */
object SourceRestorer {

    private const val TAG = "SourceRestorer"

    private var contextRef: WeakReference<Context>? = null

    /** 注入 Context（Application 调一次即可，幂等）。 */
    fun attach(context: Context) {
        contextRef = WeakReference(context.applicationContext ?: context)
    }

    /**
     * 内存配置为空时，把"上次选中的配置源"拉回来。
     *
     * @return 拉回来的配置；没得恢复/恢复失败返回 null
     */
    suspend fun restoreIfEmpty(): AppConfig? = withContext(Dispatchers.IO) {
        if (AppConfigManager.getCurrentConfig().sites.isNotEmpty()) {
            return@withContext AppConfigManager.getCurrentConfig()
        }
        val context = contextRef?.get()
        if (context == null) {
            Log.w(TAG, "没有 Context，无法恢复配置源")
            return@withContext null
        }
        // 上次选中的源 id（换源时记的）
        val lastSourceId = UserPreference.getLastSelectedSourceId()
        val repo = SiteRepository(context)
        val source = lastSourceId?.let { id ->
            repo.getSources().firstOrNull { it.id == id }
        } ?: repo.getSelected() ?: BuiltinSitesProvider.defaultSources().firstOrNull()

        if (source == null || source.url.isBlank()) {
            Log.w(TAG, "没有可恢复的配置源")
            return@withContext null
        }
        Log.i(TAG, "正在恢复配置源：${source.name}（${source.url}）")
        val config = ConfigLoader.loadConfig(source.url)
        if (config.sites.isEmpty()) {
            Log.w(TAG, "恢复的配置源没有站点：${source.url}")
            return@withContext null
        }
        AppConfigManager.updateConfig(config)
        config
    }

    /** 按 key 找站点（详情页"换源"这类场景用）。 */
    fun findSite(key: String): Site? = AppConfigManager.findSite(key)
}
