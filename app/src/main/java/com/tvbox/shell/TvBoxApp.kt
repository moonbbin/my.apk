package com.tvbox.shell

import android.app.Application
import android.content.Context
import android.util.Log
import com.tvbox.shell.config.HistoryRepository
import com.tvbox.shell.config.SourceRestorer
import com.tvbox.shell.config.UserPreference
import com.tvbox.shell.loader.BuiltinSpiderInstaller
import com.tvbox.shell.loader.DexLoader
import com.tvbox.shell.spider.SpiderManager
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/**
 * 应用入口：把**动态加载这条链路上的三个单例**建起来，并在后台把内置插件包释放到私有目录。
 *
 * ## 为什么值得单独搞一个 Application
 * 这条链路上的三样东西天然是"进程级单例"：
 * - [DexLoader] 内部缓存着 DexClassLoader 与已加载的插件实例 —— 建两份就变成两套缓存、
 *   两份类加载器，同一个插件类在两个 loader 里是不同的 `Class`（`is` 判断会莫名其妙失败）；
 * - [BuiltinSpiderInstaller] 管着"assets → filesDir"的复制；
 * - [SpiderManager] 缓存着 api → Spider 的实例。
 *
 * 放在这里建一次、全局复用，比"每个界面各 new 一个"要正确得多。
 * （既有的 `SpiderManager.forApp(context)` 仍然可用、也仍然会自己接上内置安装器 ——
 *  两条路都通向同一套行为，不会因为有的界面用单例、有的界面用 forApp 而出现两种结果。）
 *
 * ## 启动时做什么、不做什么
 * - **做**：建三个单例；后台（[Dispatchers.IO]）把 `assets/spiders` 下的 .jar 复制到
 *   `filesDir/spiders/`；随后跑一次 [SpiderManager.selfTest]，把"内置插件链路通不通"
 *   明确打进 Logcat（过滤 `TvBoxApp` 能看到 `启动自检: demoJarInstalled=…`）。
 *   复制是几个小文件的顺序 IO，自检是加载一个本地包 + 调一次它的方法，**绝不在主线程做**。
 * - **不做**：不 `runBlocking` 等复制完，不下载任何东西（自检也不联网：示范包返回写死数据）
 *   —— 首页首帧不该被它拖住。
 *
 * 自检失败**不是启动失败**：它只打一条 Log.e 指路（是包没进 APK、还是映射没对上），
 * 内置链路不通时 App 照样起、照样能走外部插件包与 URL 兜底那两条路。
 *
 * 复制用的是 [SupervisorJob] + IO 调度器，抛了也只记日志：内置包装不上最坏结果就是
 * "回到没有内置包时的老路子"（外部插件包 / URL 兜底），不该让 App 起不来。
 * [SpiderManager.resolveSpider] 那边还会再兜一次安装（幂等），所以时序上不会漏。
 */
class TvBoxApp : Application() {

    /** 动态加载器：进程内唯一，缓存 DexClassLoader 与插件实例 */
    lateinit var dexLoader: DexLoader
        private set

    /** 内置插件包安装器：assets → filesDir/spiders */
    lateinit var builtinInstaller: BuiltinSpiderInstaller
        private set

    /** 采集引擎管理器：进程内唯一，缓存 api → Spider */
    lateinit var spiderManager: SpiderManager
        private set

    /** 进程级协程作用域。只有一个 SupervisorJob，一个子任务失败不影响其他子任务 */
    private val appScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    override fun onCreate() {
        super.onCreate()

        dexLoader = DexLoader(this)
        builtinInstaller = BuiltinSpiderInstaller(this)
        spiderManager = SpiderManager(
            dexLoader = dexLoader,
            context = this,
            builtinInstaller = builtinInstaller
        )

        // 冷启动恢复的来源：配置只活在内存里，杀进程重开就是空的。
        // 这里注入 Context 让 SourceRestorer 能去磁盘上读"上次选中的源"。
        SourceRestorer.attach(this)

        // 模块七（交互增强）：这两个是纯本地存储，init 就是绑一下 SharedPreferences，
        // 没有 IO、没有网络，放主线程完全没负担。
        //
        // 必须在这里 init 一次的原因：
        // - UserPreference 不 init → "上次选中的站点"存不下去，杀进程重开就回到默认站（验收 5 会挂）；
        // - HistoryRepository 不 init → 历史只在内存里，重启全丢。
        // 两者在未 init 时都是安全的（读给默认值、写只落内存），所以这里就算失败也不会连累启动。
        UserPreference.init(this)
        HistoryRepository.init(this)

        appScope.launch {
            try {
                val count = builtinInstaller.installBuiltinSpiders()
                Log.d(TAG, "内置 jar 安装完成，共 $count 个")

                // 等文件系统把刚释放的包刷稳，再走自检。
                // 复制本身是"写临时文件 + 原子改名"，已经不会有半截文件被读到；
                // 这 500ms 只是让自检的结论**稳定**（包刚改名完、目录项还在刷的那种时序），
                // 正确性不依赖它 —— 真正的取用路径（resolveSpider）自己会兜一次安装。
                delay(SELF_TEST_DELAY_MS)

                val result = spiderManager.selfTest()
                Log.d(TAG, "启动自检: ${result.message}")
                if (!result.demoSpiderLoaded) {
                    Log.e(
                        TAG,
                        "内置 jar 链路未打通，请检查 assets/spiders/demo.jar 与 BuiltinSpiderInstaller 映射"
                    )
                }
            } catch (t: Throwable) {
                // 装不上 / 自检炸了都不算致命：取引擎时 SpiderManager 还会再试一次，
                // 最坏也只是没有内置包（回到外部插件包 / URL 兜底那条老路）
                Log.e(TAG, "内置 jar 安装或启动自检失败（不影响启动，取引擎时会再试一次）", t)
            }

            // 冷启动恢复"上次选中的源"：配置只活在内存里，杀进程重开就是空的。
            // 这里提前拉一次（后台 IO + 联网，失败只记日志），用户点进首页时就不必现等。
            try {
                val restored = SourceRestorer.restoreIfEmpty()
                if (restored != null) {
                    Log.i(TAG, "启动时已恢复上次选中的配置源，站点数: ${restored.sites.size}")
                }
            } catch (t: Throwable) {
                Log.w(TAG, "启动时恢复配置源失败（不影响启动，首页还会再试一次）", t)
            }
        }

        Log.i(TAG, "初始化完成：DexLoader / BuiltinSpiderInstaller / SpiderManager 已就绪")
    }

    companion object {
        /** 日志 tag：和契约一致，过滤 TvBoxApp 能看全"启动 + 内置包释放 + 自检"这一步 */
        const val TAG = "TvBoxApp"

        /**
         * 启动自检前的等待时长。
         *
         * 存在的理由：刚复制完的包立刻被另一个线程 `open` 时，极少数文件系统上会有一瞬
         * 目录项还没刷稳。这不是正确性问题（复制已经是原子改名、真正的取用路径还会兜安装），
         * 只是**别让启动日志打出一次误导性的"未安装"**。
         */
        const val SELF_TEST_DELAY_MS: Long = 500L

        /**
         * 取本进程的 [TvBoxApp]（拿不到就返回 null）。
         *
         * 为什么返回可空而不是抛异常：单元测试（Robolectric）里的 Application 未必是这个类，
         * 硬转会在测试里炸掉，而调用方本来就有 `?:` 兜底的路子可走。
         */
        fun of(context: Context): TvBoxApp? = context.applicationContext as? TvBoxApp
    }
}
