package com.tvbox.shell.spider

import android.content.Context
import android.util.Log
import com.tvbox.shell.loader.BuiltinSpiderInstaller
import com.tvbox.shell.loader.DexLoader
import java.util.concurrent.ConcurrentHashMap

/**
 * 采集引擎管理器：`api` → [Spider] 的唯一入口。
 *
 * 路由规则（跟 HomeViewModel 的站点排序对齐）：
 * 1. `api` 以 `http` 开头 → [CmsSpider]（CMS 直连，**不需要插件包**）；
 * 2. `api` 以 `csp_` 开头 → 插件引擎：先找本地 jar（[DexLoader]），没有就按 [ext] 里的
 *    地址把插件包下下来再加载（[BuiltinSpiderInstaller] 兜一次安装）；
 * 3. 都拿不到 → [SpiderNull]（调用方靠 `is SpiderNull` 识别"引擎缺失"，别改这条约定）。
 *
 * 拿到引擎后统一包一层 [SpiderProbe]，让调用方分得清"接口通但没内容"和"连不上"。
 *
 * 线程：[resolveSpider] 可能下载/加载 jar，**只允许在 IO 线程调**。
 * 实例缓存：同一个 api 在进程里只加载一次（[ConcurrentHashMap]）。
 */
class SpiderManager(
    private val dexLoader: DexLoader? = null,
    private val context: Context? = null,
    private val builtinInstaller: BuiltinSpiderInstaller? = null
) {

    private val cache = ConcurrentHashMap<String, Spider>()

    /** 插件包加载失败的负缓存：同一个包本次会话只尝试一次，失败毫秒级短路。 */
    private val jarFailureCache = ConcurrentHashMap<String, String>()

    /** 自检结果。 */
    data class SelfTestResult(
        /** 示范引擎能不能正常加载+调用。 */
        val demoSpiderLoaded: Boolean,
        /** 人话结论，打进 Logcat。 */
        val message: String
    )

    /**
     * 取本进程的全局单例（TvBoxApp 建好的那份）。
     *
     * 拿不到（测试里 Application 不是 TvBoxApp）就现场建一个无插件能力的实例——
     * 这种实例只能走 CMS 直连，插件站会拿到 SpiderNull，行为是"降级"不是"崩"。
     */
    companion object {
        @Volatile
        private var appInstance: SpiderManager? = null

        fun forApp(context: Context): SpiderManager {
            appInstance?.let { return it }
            val app = context.applicationContext
            val mgr = try {
                val tvBoxApp = app as? com.tvbox.shell.TvBoxApp
                tvBoxApp?.spiderManager ?: createStandalone(app)
            } catch (t: Throwable) {
                Log.w(TAG, "forApp 降级为独立实例：${t.javaClass.simpleName}")
                createStandalone(app)
            }
            appInstance = mgr
            return mgr
        }

        private fun createStandalone(context: Context): SpiderManager {
            val loader = runCatching { DexLoader(context) }.getOrNull()
            val installer = runCatching { BuiltinSpiderInstaller(context) }.getOrNull()
            return SpiderManager(dexLoader = loader, context = context, builtinInstaller = installer)
        }

        private const val TAG = "SpiderManager"
    }

    /** 无参构造：给测试/裸 JVM 用的（只有 CMS 直连能力）。写法注：主构造器全参数都有默认值，
     *  所以 `SpiderManager()` 本来就能调，这里不额外声明次构造器。 */

    /**
     * 按 api 拿引擎（拿不到给 [SpiderNull]，不抛）。
     *
     * @param api 站点配置的 api（`csp_xxx` / `http…`）
     * @param ext 站点配置的 ext（插件包地址 / CMS 备用路径）
     */
    fun resolveSpider(api: String, ext: String?): Spider {
        val key = "${api.trim()}|${ext.orEmpty().trim()}"
        cache[key]?.let { return it }

        val spider: Spider = when {
            api == com.tvbox.shell.config.BuiltinSitesProvider.DEMO_API -> {
                Log.d(TAG, "示范引擎：$api")
                DemoSpider()
            }
            api.startsWith("http", ignoreCase = true) -> {
                Log.d(TAG, "CMS 直连引擎：$api")
                CmsSpider(api.trim(), ext.orEmpty())
            }
            api.startsWith("csp_", ignoreCase = true) -> {
                resolvePluginSpider(api.trim(), ext.orEmpty()) ?: SpiderNull()
            }
            else -> {
                Log.w(TAG, "未知的 api 类型，按空引擎处理：$api")
                SpiderNull()
            }
        }
        // 探针包一层（SpiderNull 不用包：它的"失败"是调用方要的明确信号）
        val probed = if (spider is SpiderNull) spider else SpiderProbe(spider)
        cache[key] = probed
        return probed
    }

    /** 取已缓存的引擎（没有不加载），插件热替换这类场景用。 */
    fun getSpider(api: String, ext: String?): Spider? =
        cache["${api.trim()}|${ext.orEmpty().trim()}"]

    /** 插件包全局就绪状态（给排序用：就绪时插件站优先）。 */
    fun isGlobalPluginReady(): Boolean = dexLoader?.hasAnyPlugin() == true

    /** 最近一次插件包失败的原因（无失败返回 null）。 */
    fun pluginJarFailureReason(): String? = jarFailureCache.values.firstOrNull()

    /** 清掉插件包负缓存（用户点了"重试" / 换了包地址后调）。 */
    fun clearPluginJarBackoff() {
        jarFailureCache.clear()
        Log.d(TAG, "插件包负缓存已清")
    }

    /**
     * 启动自检：示范引擎能不能走完"加载→调一次方法"。
     *
     * 只打日志、不抛异常——自检失败不是启动失败。
     */
    fun selfTest(): SelfTestResult {
        return try {
            val spider = resolveSpider(
                com.tvbox.shell.config.BuiltinSitesProvider.DEMO_API, null
            )
            val ok = spider !is SpiderNull
            val json = if (ok) runCatching { spider.homeContent(false) }.getOrDefault("") else ""
            SelfTestResult(
                demoSpiderLoaded = ok && json.isNotBlank(),
                message = "demoSpiderLoaded=${ok && json.isNotBlank()}"
            )
        } catch (t: Throwable) {
            SelfTestResult(false, "自检异常：${t.javaClass.simpleName}: ${t.message}")
        }
    }

    // ============================ 插件引擎 ============================

    /**
     * 插件引擎解析：`csp_Xxx` → 本地 jar。
     *
     * 约定（跟插件打包规范对齐）：
     * - jar 文件名：`{api}.jar`（如 `csp_Kunyu.jar`），在 filesDir/spiders/ 下找；
     * - 找不到且 ext 是 http 地址 → 把它当插件包地址下载后重试一次；
     * - 类名：jar 内的 `assets/plugin.properties` 写 `mainClass`，没写就按
     *   `com.github.catvod.spider.{Api去掉csp_前缀}` 猜。
     */
    private fun resolvePluginSpider(api: String, ext: String): Spider? {
        jarFailureCache[api]?.let {
            Log.d(TAG, "插件 $api 本次会话已失败过，短路")
            return null
        }
        val loader = dexLoader ?: run {
            Log.w(TAG, "没有 DexLoader，插件引擎不可用：$api")
            return null
        }
        // 先兜一次内置安装（幂等）：assets 里带了这个包就直接释放出来
        runCatching { builtinInstaller?.installBuiltinSpiders() }

        val simpleName = api.removePrefix("csp_")
        var spider = loader.loadSpider("$api.jar", simpleName)
        if (spider == null && ext.startsWith("http", ignoreCase = true)) {
            // ext 是插件包地址：下载 → 再试一次
            Log.i(TAG, "本地没有 $api.jar，尝试从 ext 下载：$ext")
            val ok = runCatching { loader.downloadPlugin(ext, "$api.jar") }.getOrDefault(false)
            if (ok) {
                clearPluginJarBackoff()
                spider = loader.loadSpider("$api.jar", simpleName)
            }
        }
        if (spider == null) {
            val reason = "插件包 $api.jar 不存在（ext=$ext），站点不可用"
            jarFailureCache[api] = reason
            Log.w(TAG, reason)
        }
        return spider
    }
}
