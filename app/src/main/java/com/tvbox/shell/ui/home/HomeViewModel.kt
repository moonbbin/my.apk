package com.tvbox.shell.ui.home

import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.tvbox.shell.config.AppConfigManager
import com.tvbox.shell.config.BuiltinSitesProvider
import com.tvbox.shell.config.ConfigLoader
import com.tvbox.shell.config.SiteRepository
import com.tvbox.shell.config.SiteSource
import com.tvbox.shell.config.UserPreference
import com.tvbox.shell.model.AppConfig
import com.tvbox.shell.model.Site
import com.tvbox.shell.model.Vod
import com.tvbox.shell.parser.HomeCategory
import com.tvbox.shell.parser.HomeContentParser
import com.tvbox.shell.spider.SpiderManager
import com.tvbox.shell.spider.SpiderNull
import com.tvbox.shell.spider.SpiderProbe
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/** "全部"分类的 id：空串即回到 `homeContent` 的原始列表。 */
const val ALL_CATEGORY_ID: String = ""

/**
 * 首页四态。UI 只需 `when` 一遍，不需要知道内容是从 `homeContent` 还是 `categoryContent` 来的。
 *
 * - [Idle]    还没开始加载（首帧）
 * - [Loading] 拉取中（UI 显示进度圈）
 * - [Success] 拿到内容（**空列表也走这一态**，由 UI 渲染空态文案，不算错误）
 * - [Error]   连站点都拿不到 / 引擎缺失 / 首次加载失败（UI 给提示 + 重试）
 */
sealed class HomeState {

    /** 空闲：还没点过，或者刚被创建。 */
    object Idle : HomeState()

    /** 加载中。 */
    object Loading : HomeState()

    /**
     * 拿到内容。
     *
     * 字段顺序按契约来（[categories] → [vodList]），[site] / [selectedCategoryId] 是本工程
     * 实现上额外多带的——点封面跳详情要站点对象，切分类要知道当前选中谁，
     * 都给默认值，所以 `Success(categories, vodList)` 这种两参写法照样能编过。
     *
     * @param categories          分类表（切分类失败回退时也保留着，UI 的分类行不会闪没）
     * @param vodList             当前列表（空 = 这个分类/这个源暂时没内容）
     * @param site                当前生效的站点（点封面跳详情时要把它一起带过去）
     * @param selectedCategoryId  当前选中的分类 id（[ALL_CATEGORY_ID] 表示"全部"）
     */
    data class Success(
        val categories: List<HomeCategory> = emptyList(),
        val vodList: List<Vod> = emptyList(),
        val site: Site = Site(),
        val selectedCategoryId: String = ALL_CATEGORY_ID
    ) : HomeState() {

        /**
         * [vodList] 的旧命名。
         *
         * 只读别名，不是第二个字段——历史代码（UI、测试）里写的是 `.vods`，
         * 留着它就不用为一处改名去动一堆能跑的代码。新代码统一写 `vodList`。
         */
        val vods: List<Vod> get() = vodList
    }

    /** 加载失败。[message] 是能直接丢给用户看的人话。 */
    data class Error(val message: String) : HomeState()
}

/**
 * 契约里对这套状态机的叫法。
 *
 * [HomeState] 是本工程早期的名字，两者**同一个类型**（typealias），
 * 所以 `HomeUiState.Success(...)` / `HomeState.Success(...)` 随便写哪个都对。
 */
typealias HomeUiState = HomeState

/**
 * 搜索页四态（模块七）。
 *
 * 跟 [HomeState] 分开是刻意的：搜索是首页上的**一层浮层**，它转圈时首页那张封面墙
 * 必须原样留着（用户返回时不该看到一个被搜索状态顶掉的首页）。两者共用一个状态机
 * 就必然会互相踩。
 *
 * - [Idle]    还没搜过（搜索页刚打开，只显示搜索历史）
 * - [Loading] 搜索中
 * - [Success] 出结果了（**空列表也走这一态**，由 UI 渲染"未找到相关影视"）
 * - [Error]   搜索失败（引擎缺失 / 没响应 / 接口坏了），[Error.message] 是可以直接上屏的人话
 */
sealed class SearchState {

    /** 空闲：没搜过（或关键词被清空）。 */
    object Idle : SearchState()

    /** 搜索中。 */
    object Loading : SearchState()

    /** 有结果（空列表 = 搜了但没找到，不是错误）。 */
    data class Success(val vods: List<Vod>) : SearchState()

    /** 失败。[message] 直接丢给用户看。 */
    data class Error(val message: String) : SearchState()
}

/**
 * 首页（影视 Tab）的 ViewModel（模块六）。
 *
 * 职责边界（跟详情页同一套原则）：
 * - **不实现** Spider 引擎，只按契约调用 [SpiderManager]；
 * - **不解析** JSON 树，解析全交给 [HomeContentParser]（纯工具类，可单测）；
 * - **不做** UI，也不碰播放器——点封面这件事由 UI 回调抛给外层导航。
 *
 * 加载链路（每一步都有 `Log.d(TAG, ...)`，TAG = `HomeVM`）：
 * ```
 * 开始加载首页
 *   → AppConfigManager.getCurrentConfig()
 *   → 校验 sites（一个候选都没有 → Error 直接返回，同步判定）
 *   → 打「开始遍历 N 个站点，寻找可用引擎」
 *   → 按"最可能出内容"的顺序遍历候选站（csp_ 前缀优先；插件包在本地时靠插件包的站优先，
 *     否则靠内置通用引擎的站优先）
 *       → SpiderManager.resolveSpider(site.api, site.extString)
 *         （本地已有插件包就直接加载；没有就先把配置里的插件包下下来再加载）
 *       → SpiderNull → Log.w「跳过站点 X: 引擎未加载」+ 换下一个
 *       → Log.d「尝试站点: X, api=…, ext=…」
 *       → Dispatchers.IO 里 spider.homeContent(false) 探活：抛异常 / 引擎报失败 / 返回空串
 *         都换下一个；class 和 list 都空的也换下一个（先记成备选）
 *       → 最多试 3 个可用站（[MAX_USABLE_PROBE]），有真内容立刻用
 *   → 找到可用站点 → 复用探活那次响应，不重复打接口
 *   → 打 raw json（截 500 字）
 *   → HomeContentParser.parseHomeContent(json)
 *   → Success(categories, vodList) + 打"共 N 个分类，M 部影视"
 *   → 全部站点都失败 → Error「所有站点都加载失败…采集引擎未加载…」
 * ```
 *
 * **空内容 ≠ 失败**（源暂时没片是合法的）：所有站都试空时，用第一个"引擎通、内容空"的站
 * 显示空态（[HomeState.Success]，列表为空），只有"拿不到引擎"和"引擎调起来就炸 / 连不上"
 * 才走到 [HomeState.Error]。
 *
 * 线程：[loadHomeContent] / [selectCategory] / [refresh] 随便在哪个线程调，
 * 网络与解析内部切到 IO。
 *
 * @param spiderManager 采集引擎管理器，测试可注入替身
 * @param configProvider 当前配置的提供者，默认读 [AppConfigManager] 的全局单例，测试可注入
 * @param ioDispatcher 取数（网络 + 解析）用的调度器，默认 [Dispatchers.IO]。测试注入测试调度器，
 *                     才能把"加载中"这类中间态冻住做确定性断言
 */
class HomeViewModel @JvmOverloads constructor(
    private val spiderManager: SpiderManager = SpiderManager(),
    private val configProvider: () -> AppConfig = { AppConfigManager.getCurrentConfig() },
    private val ioDispatcher: CoroutineDispatcher = Dispatchers.IO,
    /**
     * 冷启动恢复:配置为空时,让调用方去把"上次选中的那个源"重新拉回来。
     *
     * 为什么需要:配置只存在内存里([AppConfigManager]),而写入它的只有设置页换源那一次。
     * 杀进程重开 → 内存空 → 首页直接"当前配置里没有可用的采集站点",用户看到的表象就是
     * "真实源打不开 / 源没了"。这里给一个可注入的恢复口,默认 null = 不去恢复,
     * 既有用例(注入空配置直接期望错误态)行为完全不变。
     *
     * @return 拉回来的配置;没得恢复 / 恢复失败返回 null
     */
    private val restoreSource: (suspend () -> AppConfig?)? = null,
    /**
     * 配置源仓库（模块七）。首页顶部**长按标题**弹出配置源列表、选中后换源，都靠它。
     *
     * 为什么要可空：这个类是模块 0.6 的东西，构造它需要 Context，而本工程有一批
     * 裸 JVM / Robolectric 的验收会直接 `HomeViewModel(spiderManager = …, configProvider = …)`。
     * 给 null 时"换源"这条交互退化成一条提示（[MSG_NO_SOURCE_REPO]），
     * 但**站点切换、搜索、历史、上一次站点恢复这些一律照常**——既有用例行为一字不变。
     */
    private val siteRepository: SiteRepository? = null,
    /**
     * 拉配置的实现（模块 0.7 的 `ConfigLoader.loadConfig`）。
     *
     * 声明成**挂起函数类型**而不是直接持有 `ConfigLoader`：
     * [com.tvbox.shell.config.ConfigLoader] 是个 `object`，持有它等于把"真联网"焊死在这里，
     * 验收就没法在本地起一个 HTTP 服务喂真格式响应来测换源这条链。
     * 默认实现就是调它，行为一致；测试注入自己的实现即可。
     */
    private val configLoader: suspend (String) -> AppConfig = { url -> ConfigLoader.loadConfig(url) }
) : ViewModel() {

    private val _state = MutableStateFlow<HomeState>(HomeState.Idle)

    /** UI 订阅这个。任何时刻只会是 [HomeState] 四态之一。 */
    val state: StateFlow<HomeState> = _state.asStateFlow()

    /**
     * 一次性提示（切分类失败这类"不该打掉页面但要告诉用户"的情况）。
     *
     * UI 消费完必须调 [onMessageShown] 复位，否则下次进首页会重弹一遍
     * ——和详情页 `onPlayResultHandled` 是同一个约定。
     */
    private val _transientMessage = MutableStateFlow<String?>(null)

    /** UI 订阅这个弹 Snackbar。 */
    val transientMessage: StateFlow<String?> = _transientMessage.asStateFlow()

    /** 同一时刻只允许一个加载在飞：切分类连点时，旧请求直接取消，避免旧结果盖掉新结果。 */
    private var loadJob: Job? = null

    /**
     * 当前站点 / 当前分类。
     *
     * 为什么要单独存，而不是每次都从 [HomeState.Success] 里取：
     * 加载中状态是 [HomeState.Loading]，里面没有站点信息。用户手快连点两个分类时，
     * 第二次点击会撞上 Loading 态——如果只看 state，这一下就被丢掉了，界面停在第一个分类上
     * （表现就是"点了没反应"）。所以站点和分类在这里独立记着，跟状态机解耦。
     */
    // ======================================================================
    // 模块七（交互增强）：对外状态
    //
    // 这些 Flow 全部跟 [state] 解耦，是刻意的：选择器开没开、搜索页在不在最前面，
    // 都是"浮层状态"，不该被首页那句 `_state.value = Loading` 冲掉。
    // ======================================================================

    private val _currentSiteFlow = MutableStateFlow<Site?>(null)

    /** 当前生效的站点（顶部标题显示 [Site.name]，点它换站）。 */
    val currentSite: StateFlow<Site?> = _currentSiteFlow.asStateFlow()

    private val _availableSites = MutableStateFlow<List<Site>>(emptyList())

    /** 站点选择器要的那份列表：当前配置里 `type == 3` 的采集站。 */
    val availableSites: StateFlow<List<Site>> = _availableSites.asStateFlow()

    private val _availableSources = MutableStateFlow<List<SiteSource>>(emptyList())

    /**
     * 配置源选择器要的那份列表（来自 [SiteRepository]）。
     *
     * 构造时没注入仓库就是空表 —— UI 那边会渲染成"还没有配置源"，
     * 而不是崩掉或显示一个永远点不动的列表。
     */
    val availableSources: StateFlow<List<SiteSource>> = _availableSources.asStateFlow()

    private val _sitePickerVisible = MutableStateFlow(false)

    /** 站点选择器是否可见（**点**顶部标题 → true）。 */
    val sitePickerVisible: StateFlow<Boolean> = _sitePickerVisible.asStateFlow()

    private val _sourcePickerVisible = MutableStateFlow(false)

    /** 配置源选择器是否可见（**长按**顶部标题 → true）。 */
    val sourcePickerVisible: StateFlow<Boolean> = _sourcePickerVisible.asStateFlow()

    private val _searchScreenVisible = MutableStateFlow(false)

    /** 搜索页是否可见。 */
    val searchScreenVisible: StateFlow<Boolean> = _searchScreenVisible.asStateFlow()

    private val _historyScreenVisible = MutableStateFlow(false)

    /** 观看历史页是否可见。 */
    val historyScreenVisible: StateFlow<Boolean> = _historyScreenVisible.asStateFlow()

    private val _searchResultState = MutableStateFlow<SearchState>(SearchState.Idle)

    /** 搜索结果四态。搜索页在 onBack 时留在原地，下次进来还是上次那批结果。 */
    val searchResultState: StateFlow<SearchState> = _searchResultState.asStateFlow()

    /**
     * 用户显式钉住的站点（[switchSite] / [loadHomeContent] 的 `forceSite`）。
     *
     * 有它就**优先于一切排序**：用户刚从站点列表里点了一个站，
     * 下次加载却按"哪个站最可能出内容"又给换回去，那这个交互就是坏的。
     */
    private var pinnedSite: Site? = null

    /**
     * 当前站点 / 当前分类。
     *
     * 为什么要单独存，而不是每次都从 [HomeState.Success] 里取：
     * 加载中状态是 [HomeState.Loading]，里面没有站点信息。用户手快连点两个分类时，
     * 第二次点击会撞上 Loading 态——如果只看 state，这一下就被丢掉了，界面停在第一个分类上
     * （表现就是"点了没反应"）。所以站点和分类在这里独立记着，跟状态机解耦。
     *
     * 名字带 active 是为了跟对外的 [currentSite]（StateFlow）区分：
     * 这个字段是"内部当前值"，那个是"给 UI 订阅的快照"，写入统一走 [setActiveSite]。
     */
    private var activeSite: Site? = null

    /** 搜索任务槽：连搜两次时旧的直接取消，不让先返回的旧结果盖掉新结果。 */
    private var searchJob: Job? = null
    private var currentCategoryId: String = ALL_CATEGORY_ID

    /** 最近一次成功的内容。加载失败时用它回退，别把用户已经翻到的列表打掉。 */
    private var lastContent: HomeState.Success? = null

    /**
     * 分类表缓存。
     *
     * 切分类时接口不返回 `class`，但分类行还得显示着——所以这里留一份，
     * 让分类行在切换过程中不闪没。
     */
    private var categories: List<HomeCategory> = emptyList()

    /**
     * 首次加载（契约入口）。已经在加载 / 已经有内容时不重复拉（旋转重建后重复进 [Idle] 才会再拉一次）。
     *
     * 这就是契约里的 `loadHomeContent()`：11 步全走完，每一步都打日志，
     * 任何异常都进 [HomeState.Error]，绝不静默吞。
     *
     * ## 站点优先级（模块七加进来的两层）
     * 1. [forceSite] 非空 → 用户刚在站点列表里点的那一个，**最高优先级**；
     * 2. 否则读 [UserPreference.getLastSelectedApi]（杀进程重开就是靠这条回到上次那个站，
     *    验收标准 5）；
     * 3. 都没有 → 维持原来的"哪个站最可能出内容就先试哪个"。
     *
     * @param forceSite 指定用哪个站加载；null = 走"上次选中的 api / 默认排序"
     */
    // @JvmOverloads 是必须的：Kotlin 的默认参数**不会**在字节码里生成无参重载，
    // 而契约（以及验收脚本的反射检查）要求 `loadHomeContent()` 这个无参入口真实存在。
    // 少了它，Java 侧 / 反射侧就只能看到 loadHomeContent(Site)，验收当场红。
    @JvmOverloads
    fun loadHomeContent(forceSite: Site? = null) {
        Log.d(TAG, "开始加载首页" + if (forceSite != null) "（指定站点：${forceSite.name}）" else "")

        // 2) 拿配置
        val config = configProvider()
        Log.d(TAG, "配置站点数: ${config.sites.size}")

        // 2.5) 选择器要用的两份列表先刷给 UI。
        //      放在这里而不是构造时刷一次：配置是可以在运行期换掉的（换配置源），
        //      每次加载都对齐一次，站点列表就不会停留在上一份配置上。
        publishAvailableSites(config)
        publishAvailableSources()

        // 2.6) 定"钉住的站点"
        if (forceSite != null) {
            pinnedSite = forceSite
            UserPreference.setLastSelectedApi(forceSite.api)
        } else if (pinnedSite == null) {
            pinnedSite = siteOfLastSelectedApi(config)
        }

        // 3) 校验站点
        //    这一步是**同步**的：一份配置里一个能用的站都没有时，界面要立刻是错误态，
        //    不能先闪一下进度圈再报错（那条路径由 candidates() 判定，不发网络）。
        if (candidates(config).isEmpty()) {
            // 冷启动恢复：配置只活在内存里（只有设置页换源那次会写），杀进程重开就是空的 ——
            // 用户看到的表象叫"源没了 / 真实源打不开"。注入过恢复口就先把上次那个源拉回来再判，
            // 没注入（既有用例）走原来的同步错误态，行为一字不变。
            if (restoreSource != null) {
                restoreSourceThenLoad()
                return
            }
            enterNoSiteError()
            return
        }

        startLoad(config)
    }

    /** 内存里没有站点时：让调用方把"上次选中的源"恢复回来，成功就接着正常加载，失败才报错。 */
    private fun restoreSourceThenLoad() {
        Log.w(TAG, "内存里没有可用站点（杀进程重开就是这样），尝试恢复上次选中的配置源")
        loadJob?.cancel()
        setActiveSite(null)
        _state.value = HomeState.Loading
        loadJob = viewModelScope.launch {
            val restored = try {
                restoreSource?.invoke()
            } catch (e: CancellationException) {
                throw e
            } catch (t: Throwable) {
                Log.e(TAG, "恢复上次选中的配置源失败：${t.javaClass.simpleName}: ${t.message}")
                null
            }
            if (restored == null || candidates(restored).isEmpty()) {
                Log.e(TAG, "没有可恢复的配置源，也没有能用的站点，给错误态")
                loadJob = null
                setActiveSite(null)
                _state.value = HomeState.Error(MSG_NO_SITE)
                return@launch
            }
            Log.i(TAG, "已恢复上次选中的配置源，站点数：${restored.sites.size}")
            loadJob = null
            startLoad(restored)
        }
    }

    /** 配置里一个能用的站都没有：立刻错误态（同步判，不闪进度圈）。 */
    private fun enterNoSiteError() {
        Log.e(TAG, "配置里没有能用的站点（一个站点都没有 / api 全为空），直接给错误态")
        loadJob?.cancel()
        loadJob = null
        setActiveSite(null)
        _state.value = HomeState.Error(MSG_NO_SITE)
    }

    /**
     * 第 4 步起：遍历候选站点，找一个真能出内容的引擎。
     * 抽成独立函数是因为冷启动恢复成功后要接着走这一段（[restoreSourceThenLoad]）。
     */
    private fun startLoad(config: AppConfig) {
        val candidates = candidates(config)

        // 4) 遍历候选站点，找一个真能出内容的引擎
        //    同步这一帧必须是 Loading：UI 要立刻显示进度圈（用户点了不能像没反应）
        loadJob?.cancel()
        // **刻意不清当前站点**：加载期间顶栏要继续显示"正在用哪个站"——
        // 换站那条链刚把新站名摆上去，这里清掉就会让标题闪回「影视」，
        // 用户看到的表象就是"我点了新站，标题却变空了"。
        // 真的一批站全挂时，下面那条失败路径会把站点置空（见 picked == null 分支）。
        _state.value = HomeState.Loading

        Log.d(TAG, "开始遍历 ${candidates.size} 个站点，寻找可用引擎")
        loadJob = viewModelScope.launch {
            val probe = pickUsableSite(candidates)
            val picked = probe.picked
            if (picked == null) {
                Log.e(TAG, "所有站点都遍历完了，没找到一个能出内容的引擎")

                // 【兜底】用户配置源整批不可用时，最后拿内置示范站点试一把。
                // 为什么要这一步：真源里几十上百个 csp_ 站全要插件包，用户手上只有配置文件时
                // 一个都跑不起来，界面只剩一句"加载失败"——用户根本分不清是配置问题、
                // 网络问题还是 App 的插件链路坏了。示范站点不联网、结果确定，
                // 它能把"链路通不通"这件事直接告诉用户。
                val fallback = tryDemoFallback()
                val demoContent = fallback.content
                if (demoContent != null) {
                    Log.w(TAG, "用户配置源无可用站点，已自动切到内置示范站点")
                    setActiveSite(BuiltinSitesProvider.demoSite)
                    currentCategoryId = ALL_CATEGORY_ID
                    lastContent = demoContent
                    // 顶栏会显示"示范站点"，再补一条一次性提示告诉用户去哪儿加真源
                    _transientMessage.value = MSG_DEMO_FALLBACK
                    _state.value = demoContent
                    return@launch
                }

                Log.e(TAG, "内置示范站点也没兜住，按原样报加载失败（自检结果见上一条日志）")
                setActiveSite(null)
                _state.value = HomeState.Error(
                    allFailedMessage(
                        first = candidates.first(),
                        total = candidates.size,
                        selfTest = fallback.selfTest,
                        reasons = probe.failures,
                        jarFailure = runCatching { spiderManager.pluginJarFailureReason() }.getOrNull()
                    )
                )
                return@launch
            }

            Log.d(
                TAG,
                "选中站点: ${picked.site.name}, api: ${picked.site.api}, ext: ${picked.site.extString}"
            )
            // 交给统一的取数路径。先把 job 槽摘掉 —— 否则 load() 会把正在跑自己的这个 job 取消掉
            loadJob = null
            load(picked.site, ALL_CATEGORY_ID, picked.json)
        }
    }

    /**
     * [loadHomeContent] 的旧命名，保留给早期调用点。
     * 新代码请写 [loadHomeContent]（跟契约同名，别再多一个名字）。
     */
    fun loadHome() {
        loadHomeContent()
    }

    /**
     * 下拉/点刷新：重拉当前分类。
     * 还没加载过（或已经出错）就直接走首次加载那条路。
     */
    fun refresh() {
        // 手动刷新 = 用户明确要"再试一次"：把插件包负缓存清掉，给下载一次重试机会。
        // 自动路径不清（否则"同一个包几十个站各下一次"那个坑就又回来了）。
        runCatching { spiderManager.clearPluginJarBackoff() }
        val site = activeSite
        if (site == null) {
            loadHomeContent()
            return
        }
        Log.d(TAG, "刷新当前分类: ${if (currentCategoryId.isEmpty()) "全部" else currentCategoryId}")
        load(site, currentCategoryId)
    }

    /**
     * 切分类。
     *
     * **加载中也允许切**（手快连点两个分类时，第二下必须算数）——所以这里看的是
     * [activeSite] 而不是 [HomeState.Success]，见那个字段的注释。
     *
     * @param typeId 分类 id；[ALL_CATEGORY_ID]（空串）表示"全部"，会重新调 `homeContent`
     */
    fun selectCategory(typeId: String) {
        val site = activeSite ?: return
        val target = typeId.trim()
        if (target == currentCategoryId) return
        load(site, target)
    }

    // ======================================================================
    // 模块七（交互增强）：站点 / 配置源 / 搜索 / 历史的入口
    // ======================================================================

    /** 点顶部标题 → 打开站点选择器。 */
    fun showSitePicker() {
        // 列表在打开这一刻对齐一次：用户可能在设置页刚加过源
        publishAvailableSites(configProvider())
        _sourcePickerVisible.value = false
        _sitePickerVisible.value = true
        Log.d(TAG, "打开站点选择器，候选 ${_availableSites.value.size} 个")
    }

    /** 关掉站点选择器。 */
    fun hideSitePicker() {
        _sitePickerVisible.value = false
    }

    /** 长按顶部标题 → 打开配置源选择器。 */
    fun showSourcePicker() {
        publishAvailableSources()
        _sitePickerVisible.value = false
        _sourcePickerVisible.value = true
        Log.d(TAG, "打开配置源选择器，候选 ${_availableSources.value.size} 个")
    }

    /** 关掉配置源选择器。 */
    fun hideSourcePicker() {
        _sourcePickerVisible.value = false
    }

    /** 打开搜索页。 */
    fun showSearchScreen() {
        _searchScreenVisible.value = true
        Log.d(TAG, "打开搜索页")
    }

    /** 关掉搜索页（**不清结果**：返回后重进还看得到上次那批，这是刻意的）。 */
    fun hideSearchScreen() {
        _searchScreenVisible.value = false
    }

    /** 打开观看历史页。 */
    fun showHistoryScreen() {
        _historyScreenVisible.value = true
        Log.d(TAG, "打开观看历史页")
    }

    /** 关掉观看历史页。 */
    fun hideHistoryScreen() {
        _historyScreenVisible.value = false
    }

    /**
     * 切换站点（站点选择器里点了一条）。
     *
     * 四步，顺序不能乱：
     * 1. 立刻把 [currentSite] 换成新的 —— 顶栏要马上显示新站名，不能等网络；
     * 2. 落盘 [[UserPreference.setLastSelectedApi]]（验收标准 5 就靠它）；
     * 3. 清空影视列表**和分类表** —— 分类是上一个站的，留着会让用户点到一个在新站根本不存在的分类；
     * 4. 强制用这个站重新加载。
     *
     * 加载失败不回退到旧站：用户明确点了这个站，退回去只会让人以为"点了没反应"。
     * 失败态由 [HomeState.Error] 兜着，用户可以再换一个或者点重试。
     *
     * @param site 目标站点
     */
    fun switchSite(site: Site) {
        Log.i(TAG, "切换站点 → ${site.name}（api=${site.api}）")

        pinnedSite = site
        setActiveSite(site)
        UserPreference.setLastSelectedApi(site.api)

        // 清列表 + 清分类 + 清回退缓存：换站之后旧的分类 id 在新站上是无效的
        categories = emptyList()
        lastContent = null
        currentCategoryId = ALL_CATEGORY_ID
        _transientMessage.value = null

        _sitePickerVisible.value = false

        loadHomeContent(forceSite = site)
    }

    /**
     * 切换配置源（配置源选择器里点了一条）。
     *
     * 链路（契约指定）：
     * 1. [SiteRepository.selectSource] 记下选中项；
     * 2. [UserPreference.setLastSelectedSourceId] 落盘；
     * 3. [ConfigLoader.loadConfig] 把新地址拉回来 → 写进 [AppConfigManager]；
     * 4. 重新加载首页。
     *
     * 第 3 步是**真联网**，所以整段异步；拉回来的配置里一个站都没有（地址填错 / 拿到的是空壳）
     * 就弹提示 + 保住原来的页面，绝不用一份空配置把用户已经能看的源打掉。
     */
    fun switchSource(siteSource: SiteSource) {
        val repo = siteRepository
        Log.i(TAG, "切换配置源 → ${siteSource.name}（${siteSource.url}）")

        if (repo == null) {
            // 没有仓库（裸 JVM / 未注入）：如实说清而不是假装换好了
            Log.e(TAG, "没有可用的配置源仓库（SiteRepository 未注入），换源做不了")
            _sourcePickerVisible.value = false
            _transientMessage.value = MSG_NO_SOURCE_REPO
            return
        }

        repo.selectSource(siteSource.id)
        UserPreference.setLastSelectedSourceId(siteSource.id)

        _sourcePickerVisible.value = false
        loadJob?.cancel()
        loadJob = null
        _state.value = HomeState.Loading

        loadJob = viewModelScope.launch {
            val loaded = try {
                configLoader(siteSource.url)
            } catch (e: CancellationException) {
                throw e
            } catch (t: Throwable) {
                Log.e(TAG, "换配置源失败：${t.javaClass.simpleName}: ${t.message}")
                AppConfig()
            }

            if (loaded.sites.isEmpty()) {
                // 空配置：保留原来的页面，只提示。用户已经能看的源不该因为一次换源失败而消失。
                Log.e(TAG, "换源后配置里没有站点，保留原页面")
                loadJob = null
                val previous = lastContent
                _transientMessage.value = MSG_SOURCE_EMPTY
                _state.value = previous ?: HomeState.Error(MSG_SOURCE_EMPTY)
                return@launch
            }

            AppConfigManager.updateConfig(loaded)
            Log.i(TAG, "配置源已切换，站点数 ${loaded.sites.size}")

            // 换源 = 换了一整套站点：钉住的站、分类、回退缓存全部作废
            pinnedSite = null
            setActiveSite(null)
            categories = emptyList()
            lastContent = null
            currentCategoryId = ALL_CATEGORY_ID

            loadJob = null
            loadHomeContent()
        }
    }

    /**
     * 搜索（契约入口）。
     *
     * 调当前站点的 `searchContent(keyword, false)` → [HomeContentParser.parseVods] → [SearchState]。
     *
     * 三件事刻意这么处理：
     * - **没有当前站点就直接报错**，不偷偷拿配置里第一个站顶上：那会让用户在 A 站搜出 B 站的结果；
     * - 引擎是 [SpiderNull] / 引擎报"没拿到响应" / 返回空串 —— 这三种都是**故障**，
     *   走 [SearchState.Error]；只有"解析出来是空表但 JSON 合法"才算"没搜到"（[SearchState.Success] 空表）；
     * - 连搜两次时旧任务直接取消，别让先发的慢请求盖掉后发的快请求。
     *
     * @param keyword 关键词；空串 / 纯空白 = 复位成 [SearchState.Idle]（UI 会退回只显示历史）
     */
    fun searchContent(keyword: String) {
        val kw = keyword.trim()
        if (kw.isEmpty()) {
            searchJob?.cancel()
            searchJob = null
            _searchResultState.value = SearchState.Idle
            return
        }

        val site = activeSite ?: _currentSiteFlow.value
        if (site == null || site.api.isBlank()) {
            Log.w(TAG, "还没有生效的站点，搜索无法发起")
            searchJob?.cancel()
            _searchResultState.value = SearchState.Error(MSG_SEARCH_NO_SITE)
            return
        }

        Log.d(TAG, "搜索「$kw」@ ${site.name}")
        searchJob?.cancel()
        _searchResultState.value = SearchState.Loading

        searchJob = viewModelScope.launch {
            val next: SearchState = try {
                val vods = withContext(ioDispatcher) {
                    val spider = spiderManager.resolveSpider(site.api, site.extString)
                    if (spider is SpiderNull) {
                        // 兜底空实现只会返回 {"list":[]}。不打这条日志的话，
                        // 用户看到的是"没找到相关影视"——把"引擎没加载"说成了"没这片"。
                        Log.e(
                            TAG,
                            "★ 搜索失败：站点没有可用的采集引擎 " +
                                "name=${site.name}, api=${site.api}, ext=${site.extString}"
                        )
                        throw IllegalStateException("当前站点没有可用的采集引擎")
                    }

                    val json = spider.searchContent(kw, false)
                    Log.d(TAG, "搜索结果 raw json: " + json.take(500))

                    if (json.isBlank()) {
                        throw IllegalStateException("搜索引擎没有返回内容")
                    }
                    if ((spider as? SpiderProbe)?.lastCallFailed == true) {
                        throw IllegalStateException("搜索引擎没拿到可用响应")
                    }

                    val vods = HomeContentParser.parseVods(json)
                    if (vods.isEmpty() && !HomeContentParser.isWellFormed(json)) {
                        Log.e(TAG, "★ 搜索返回的不是合法 JSON（不是「没搜到」，是接口坏了）：" + json.take(200))
                        throw IllegalStateException("搜索引擎返回的内容看不懂")
                    }
                    vods
                }
                SearchState.Success(vods)
            } catch (e: CancellationException) {
                throw e
            } catch (t: Throwable) {
                Log.e(TAG, "搜索失败：${t.javaClass.simpleName}: ${t.message}")
                SearchState.Error(MSG_SEARCH_FAIL)
            }

            _searchResultState.value = next
            if (next is SearchState.Success) {
                Log.d(TAG, "搜索「$kw」命中 ${next.vods.size} 部")
            }
        }
    }

    /**
     * 清搜索结果（搜索页清空输入框时调）。
     *
     * 跟 [searchContent] 传空串等价，单独开一个是因为 UI 那边"清空输入框"是个独立事件，
     * 用名字说清意图比传空串好读。
     */
    fun clearSearchResult() {
        searchJob?.cancel()
        searchJob = null
        _searchResultState.value = SearchState.Idle
    }

    /** UI 弹完提示后调一次，复位一次性消息。 */
    fun onMessageShown() {
        _transientMessage.value = null
    }

    /** 外部自建 VM 时的释放口。 */
    fun release() {
        loadJob?.cancel()
        loadJob = null
        searchJob?.cancel()
        searchJob = null
    }

    // ======================================================================
    // 内部实现
    // ======================================================================

    /**
     * 候选站点：`type == 3` 的点播采集站优先；`api` 为空的直接丢（点了也不知道往哪拉）。
     *
     * 一份配置里一个 `type == 3` 都没有是常事（直播 / CMS 混着写），所以退一层到
     * "任意 api 非空的站"——那时候直接报"没有站点"就把整个首页打死了，有站能出内容就先用着。
     */
    private fun candidates(config: AppConfig): List<Site> {
        val usable = config.sites.filter { it.api.trim().isNotEmpty() }
        return usable.filter { it.type == TYPE_CSP }.ifEmpty { usable }
    }

    /**
     * 把候选站点排成"最可能出内容"的顺序（稳定的，同档保持配置原顺序）。
     *
     * 排序意图 —— 首页只有几秒耐心，顺序错了用户就是盯着转圈：
     * - `csp_` 前缀的采集站排前面（TVBox 约定，也是既有选站策略）；
     * - 然后按**引擎来源**分档：插件包已经在本地时，"靠插件包的站"先试（本地加载毫秒级、
     *   确定能成）；插件包还没落盘时，"靠内置通用引擎的站"先试（不依赖下载，直接联网就出片）；
     * - 两批之外的（ext 是相对路径 / 内联 JSON 又没插件包可用）排最后。
     */
    private fun orderCandidates(sites: List<Site>): List<Site> {
        val pluginReady = runCatching { spiderManager.isGlobalPluginReady() }.getOrDefault(false)

        /**
         * "这个站跑起来要花多大代价"的分档,越小越先试:
         * - 0 = `ext` 直接给得出站点地址 → 内置通用引擎当场吃得下，**不发任何下载**
         * - 1 = 插件包已经在本地 → 加载是毫秒级
         * - 2 = 既没地址、插件包又没到位 → 最慢,而且大概率白等
         *
         * 为什么这条必须排在"csp_ 前缀"前面：真源里 csp_ 站占比压倒性多数，
         * 原来先按前缀排，前 5 个名额全被"要插件包"的站吃掉，
         * 后面那几个 ext 直接给 http 地址、当场就能出片的站一次都没轮到 ——
         * 用户看到的表象就是"真实源一个站都打不开"。
         */
        fun engineRank(site: Site): Int {
            val url = siteSiteUrl(site)
            return when {
                url != null -> 0
                pluginReady -> 1
                else -> 2
            }
        }

        return sites.sortedWith(
            compareBy(
                // 第一档：用户**显式**选过的那个站（点过站点列表 / 上次选中）必须排第一。
                // 放在所有分档之前 —— 用户刚点了一个站，结果加载时又被"哪个站最可能出片"的
                // 启发式换回另一个，那这个交互就是坏的。
                { if (isPinned(it)) 0 else 1 },
                { engineRank(it) },
                { if (it.api.trim().startsWith(SPIDER_API_PREFIX, ignoreCase = true)) 0 else 1 }
            )
        )
    }

    /** 这个站是不是用户钉住的那个（按 api 比，api 为空一律不算）。 */
    private fun isPinned(site: Site): Boolean {
        val pinnedApi = pinnedSite?.api?.trim().orEmpty()
        return pinnedApi.isNotEmpty() && site.api.trim() == pinnedApi
    }

    /**
     * 从配置里找出"上次选中的那个站"（模块七：冷启动恢复）。
     *
     * 只认 [UserPreference.getLastSelectedApi] 里那个 api，**配置里没有就返回 null**，
     * 绝不去猜一个相近的站顶上 —— 猜错了用户看到的是"我明明选的是 A 站，打开的却是 B 站"。
     */
    private fun siteOfLastSelectedApi(config: AppConfig): Site? {
        val saved = UserPreference.getLastSelectedApi()?.trim().orEmpty()
        if (saved.isEmpty()) return null
        val hit = candidates(config).firstOrNull { it.api.trim() == saved }
        if (hit == null) {
            Log.d(TAG, "上次选中的站点（api=$saved）不在这份配置里，忽略")
        } else {
            Log.d(TAG, "命中上次选中的站点：${hit.name}")
        }
        return hit
    }

    /** 写"当前生效站点"：内部字段与对外 StateFlow 一起改，别只改一个。 */
    private fun setActiveSite(site: Site?) {
        activeSite = site
        _currentSiteFlow.value = site
    }

    /** 把配置里 `type == 3` 的采集站刷给站点选择器。 */
    private fun publishAvailableSites(config: AppConfig) {
        val sites = config.sites.filter { it.type == TYPE_CSP && it.api.trim().isNotEmpty() }
        _availableSites.value = sites
    }

    /**
     * 刷配置源列表给配置源选择器。
     *
     * 没有仓库时给空表（UI 显示"还没有配置源"），**不抛** ——
     * 裸 JVM 的验收入口就是这么跑起来的。
     */
    private fun publishAvailableSources() {
        val sources = try {
            siteRepository?.getSources().orEmpty()
        } catch (t: Throwable) {
            Log.e(TAG, "读配置源列表失败：${t.javaClass.simpleName}: ${t.message}")
            emptyList()
        }
        _availableSources.value = sources
    }

    /** `ext` 给得出"站点根地址"就返回它（内置通用引擎吃得下的那类），否则 null。 */
    private fun siteSiteUrl(site: Site): String? {
        val ext = site.extString?.trim().orEmpty()
        if (!ext.startsWith("http", ignoreCase = true)) return null
        // 指向 .js 的是 drpy 那类脚本站，需要 JS 引擎执行，不是 CMS 接口
        if (ext.substringBefore('?').lowercase().endsWith(".js")) return null
        return ext
    }

    /**
     * 依次尝试候选站点，返回第一个"引擎拿得到、也调得起来、还真有内容"的站 + 它第一次的响应。
     *
     * 判定口径：
     * - 拿到 [SpiderNull] → 换下一个（这个站真没有引擎）；
     * - 引擎抛异常 → 换下一个（这个站这会儿用不了）；
     * - 引擎报"没拿到响应"（[SpiderProbe]）→ 换下一个（连不上 / 不是 JSON，跟"源里没片"是两回事）；
     * - **返回的 `class` 和 `list` 都是空的** → 也算"这个站这会儿没片"，记下来当备选、继续试下一个
     *   （契约要求：首页要看到封面，别停在一个空站上）；
     * - 只要有一个站给出真内容 → 立刻用它，后面的站一个都不碰。
     *
     * 试到第 [MAX_USABLE_PROBE] 个可用站就停（配置里几十上百个站，不可能让用户挨个等）；
     * 也都试空了、但有"引擎通、内容空"的备选 → 用备选显示**空态**而不是报加载失败
     * （源暂时没片 ≠ 这个站坏了）；一个备选都没有才算真失败。
     *
     * 另有总时间预算（[PROBE_BUDGET_MS]）：不能为了"找全"让用户盯着转圈好几分钟，
     * 试到预算用完就先报错，用户下拉刷新可以接着试。
     */
    private suspend fun pickUsableSite(sites: List<Site>): ProbeOutcome =
        withContext(ioDispatcher) {
            val ordered = orderCandidates(sites)
            val deadline = System.currentTimeMillis() + PROBE_BUDGET_MS

            /** 真把引擎调起来的站数（拿不到引擎的不算）——契约要求它不超过 [MAX_USABLE_PROBE] */
            var usable = 0

            /** 引擎通、但 class 和 list 都是空的站：全都试空时用它显示空态，别报失败 */
            var emptyContentFallback: PickedSite? = null

            /**
             * 每个站"为什么没被选中"：全部失败时一次性 Log.e 出来。
             * 契约要求点清楚三件事 —— 是哪个 api、什么 ext、以及**是拿不到引擎还是内容空**。
             * 真机上用户看不到这些日志，但排查"为什么这个源出不来片"全指望它。
             */
            val failures = ArrayList<String>()

            for ((index, site) in ordered.withIndex()) {
                if (usable >= MAX_USABLE_PROBE) {
                    Log.d(TAG, "已经试过 $usable 个可用站点，按上限先停（配置里还有 ${ordered.size - index} 个没试）")
                    break
                }
                // 绝对次数闸：拿不到引擎的站现在是毫秒级短路（插件包负缓存），但仍要给个硬上限，
                // 免得遇到几百个站的配置在"整批都拿不到引擎"时空转。
                if (index >= MAX_CANDIDATE_VISITS) {
                    Log.w(TAG, "已看过 $index 个站点，按扫描上限先停（共 ${ordered.size} 个）")
                    break
                }
                if (usable > 0 && System.currentTimeMillis() > deadline) {
                    Log.w(TAG, "站点探活超出预算（${PROBE_BUDGET_MS}ms），先停在试过的 $usable 个")
                    break
                }

                val spider = spiderManager.resolveSpider(site.api, site.extString)
                if (spider is SpiderNull) {
                    Log.w(TAG, "跳过站点 ${site.name}: 引擎未加载")
                    // 兜底空实现只会返回 {"class":[],"list":[]}。要是不打这条，
                    // 上层就会当成"源暂时没内容"渲染成空态——那正是最坑人的静默失败。
                    Log.e(
                        TAG,
                        "★ 站点没有可用的采集引擎：" +
                            "name=${site.name}, api=${site.api}, ext=${site.extString}（拿到的是兜底空实现）"
                    )
                    failures += "${site.name} → 拿到兜底空实现（引擎未加载）, api=${site.api}, ext=${site.extString}"
                    continue
                }

                Log.d(TAG, "Spider 实现: ${spider.javaClass.name}（站点 ${site.name}）")
                Log.d(TAG, "尝试站点: ${site.name}, api=${site.api}, ext=${site.extString}")
                usable++

                val json = try {
                    spider.homeContent(false)
                } catch (e: CancellationException) {
                    throw e
                } catch (t: Throwable) {
                    Log.e(
                        TAG,
                        "站点 ${site.name} 取首页失败，换下一个：${t.javaClass.simpleName}: ${t.message}"
                    )
                    failures += "${site.name} → 引擎抛异常 ${t.javaClass.simpleName}: ${t.message}, api=${site.api}, ext=${site.extString}"
                    continue
                }

                if (json.isBlank()) {
                    Log.e(TAG, "站点 ${site.name} 首页返回空字符串，换下一个")
                    failures += "${site.name} → 首页返回空字符串, api=${site.api}, ext=${site.extString}"
                    continue
                }

                // 引擎自己报"压根没拿到响应"（连不上 / 非 2xx / 返回的不是 JSON）→ 换下一个站。
                // 判定走的是探针而不是"列表空不空"，因为这两件事都可能长成 {"class":[],"list":[]}，
                // 只有引擎自己分得清"接口通了但没内容"和"连不上"。
                if ((spider as? SpiderProbe)?.lastCallFailed == true) {
                    Log.w(TAG, "站点 ${site.name} 这次没拿到响应（引擎报失败），换下一个")
                    failures += "${site.name} → 引擎报没拿到响应（连不上/非 2xx/不是 JSON）, api=${site.api}, ext=${site.extString}"
                    continue
                }

                // 契约要求：class 和 list 都空 = 这个站这会儿给不出首页内容 → 换下一个站试。
                // 但**不当失败**记着：全试完都空时用它显示空态（源里暂时没片 ≠ 加载失败）。
                if (isEmptyHome(json)) {
                    Log.w(TAG, "站点 ${site.name} 首页 class 和 list 都为空，先记下、继续试下一个站点")
                    failures += "${site.name} → 引擎通、但 class 和 list 都是空（源这会儿没片）, api=${site.api}, ext=${site.extString}"
                    if (emptyContentFallback == null) emptyContentFallback = PickedSite(site, json)
                    continue
                }

                Log.d(TAG, "站点 ${site.name} 首页可用，raw json: " + json.take(200))
                return@withContext ProbeOutcome(PickedSite(site, json), failures, index + 1)
            }

            emptyContentFallback?.let {
                Log.w(
                    TAG,
                    "试过的站点首页都是空内容，用回第一个可用但空的站点：${it.site.name}" +
                        "（显示空态，不算加载失败）"
                )
                return@withContext ProbeOutcome(it, failures, usable)
            }

            // 一个都没选中：逐个站把原因摊开（契约要求 api / ext / 拿不到引擎还是内容空 都点出来）
            if (failures.isNotEmpty()) {
                Log.e(TAG, "★ 没有站点能出首页内容，逐站原因（共 ${failures.size} 条）：")
                failures.forEachIndexed { i, reason -> Log.e(TAG, "  ${i + 1}. $reason") }
            }
            ProbeOutcome(null, failures, usable)
        }

    /** 首页响应里 `class` 与 `list` 是不是都空（脏 JSON 解析不出东西，也算空）。 */
    private fun isEmptyHome(json: String): Boolean {
        val parsed = HomeContentParser.parseHomeContent(json)
        return parsed.categories.isEmpty() && parsed.vodList.isEmpty()
    }

    /** 挑中的站点 + 探活那一次已经拿到的首页 JSON（复用它，首屏不必再发一次请求）。 */
    private data class PickedSite(val site: Site, val json: String)

    /**
     * 探活结果：挑中的站（可能为 null）+ 逐站失败原因 + 真调起来的站数。
     *
     * 为什么要把 failures 带出来：日志只有开发看得到，真机上用户只看到一句
     * "所有站点都加载失败"。把这批原因塞进错误文案，用户当场就能分清是
     * "插件包没下下来"（换源 / 联网重试）还是"接口连不上"（源本身挂了）——
     * 不用再靠猜。
     */
    private data class ProbeOutcome(
        val picked: PickedSite?,
        val failures: List<String>,
        val usable: Int
    )

    /**
     * 全部站点都失败时的文案。
     *
     * 三件事一次说清：**试了几个**（让用户知道不是没试）、**是引擎问题不是网络问题**、
     * **下一步该干嘛**（换源 / 检查配置源里的插件包）。
     *
     * 措辞里同时保留了两套说法（「未找到可用站点引擎（已尝试 N 个）」/「所有站点都加载失败」），
     * 因为真机上这两种描述用户都会遇到，而既有的日志与用例是按前一套钉的。
     */
    private fun allFailedMessage(
        first: Site,
        total: Int,
        selfTest: SpiderManager.SelfTestResult? = null,
        reasons: List<String> = emptyList(),
        jarFailure: String? = null
    ): String {
        val base = "未找到可用站点引擎（已尝试 $total 个）：所有站点都加载失败，" +
            "站点 ${first.name.ifBlank { "当前" }} 的采集引擎未加载。" +
            "该站点可能需要插件包（.jar），请检查配置源或更换配置源。"

        // 逐站原因（前几条）直接上屏：这是用户唯一能自己分清"插件包没下来"和"接口连不上"的东西。
        // 只给前 3 条 —— 几十条糊在屏幕上没人看，完整清单在 Logcat 里。
        val reasonBlock = buildString {
            if (jarFailure != null) {
                append("\n插件包：").append(jarFailure).append('。')
            }
            if (reasons.isNotEmpty()) {
                append("\n逐站原因（前 ").append(minOf(3, reasons.size)).append(" 条）：")
                reasons.take(3).forEach { append("\n· ").append(it) }
                if (reasons.size > 3) {
                    append("\n…另有 ").append(reasons.size - 3).append(" 个站同类原因（见 Logcat）")
                }
            }
        }

        // 内置链路自检的明细**追加**在后面，不替换上面那句：
        // 那句话是用户唯一能看懂"该去改什么"的指引（前面几套验收也按它钉的），
        // 而自检明细回答的是另一个问题——「App 自己的内置引擎到底通没通」。
        // 两件事都要说清，用户才不会拿着"引擎未加载"去瞎猜。
        if (selfTest == null) return base + reasonBlock
        // 自检明细里如果已经拿到了更硬的证据（包是可写的 / 加载失败在哪个阶段），
        // 就再补一句指路 —— 只盯"有没有打包进 APK"会把排查带偏（包和 dex 早就验过是好的）。
        val detail = selfTest.message
        val hint = when {
            detail.contains("只读=no") ->
                "磁盘上那份包是**可写的**，而 targetSdk 34+ 的动态加载只接受只读包" +
                    "（本次启动已尝试自动加固，若仍失败请看 JarHardening 日志）。"
            detail.contains("加载失败于") ->
                "包已就位、dex 也合法，病根在加载环节（见上面那句「加载失败于 …」）。"
            else -> ""
        }
        return base + "\n内置示范引擎未生效：$detail。" +
            "请检查 assets/spiders/demo.jar 是否打包进 APK。" + hint + reasonBlock
    }

    /**
     * 全部候选站都失败后的**最后一道兜底**：[SpiderManager.selfTest] 走一遍，
     * 通了就用内置示范站点把首页撑起来。
     *
     * 为什么放在这里而不是让上层去调：兜底的内容也要走 `HomeContentParser`、
     * 也要落进同一套状态机（[HomeState.Success]），放在 ViewModel 里才有那套解析与状态收口。
     *
     * 线程：整段在 [ioDispatcher] 上跑 —— 自检会真加载插件、真调 `homeContent`，
     * 压在调用线程（真机上是主线程）上会直接卡 UI。
     *
     * @return 兜到的内容（成功）与自检结果（失败时拿去拼错误文案）；两者都可能是 null
     */
    private suspend fun tryDemoFallback(): DemoFallback = withContext(ioDispatcher) {
        val selfTest = try {
            spiderManager.selfTest()
        } catch (t: Throwable) {
            Log.e(TAG, "内置链路自检失败：${t.javaClass.simpleName}: ${t.message}", t)
            null
        }

        if (selfTest?.demoSpiderLoaded != true) {
            Log.w(TAG, "内置示范引擎没生效，无法兜底：${selfTest?.message ?: "自检没跑起来"}")
            return@withContext DemoFallback(null, selfTest)
        }

        val content = try {
            val spider = spiderManager.getSpider(BuiltinSitesProvider.DEMO_API, null)
            if (spider is SpiderNull) {
                // 自检刚说能加载、这里却拿不到：只有并发下缓存被清过才会这样
                Log.e(TAG, "示范站点兜底失败：拿不到示范 Spider（自检说能加载，这里却拿到兜底空实现）")
                null
            } else {
                val json = spider.homeContent(false)
                when {
                    json.isBlank() -> {
                        Log.e(TAG, "示范站点兜底失败：homeContent 返回空字符串")
                        null
                    }
                    isEmptyHome(json) -> {
                        Log.e(TAG, "示范站点兜底失败：class 和 list 都是空")
                        null
                    }
                    else -> {
                        val parsed = HomeContentParser.parseHomeContent(json)
                        Log.d(
                            TAG,
                            "示范站点兜底成功：共 ${parsed.categories.size} 个分类，${parsed.vodList.size} 部影视"
                        )
                        // 分类表要跟着更新：示范站点的分类行也得能点（切分类走 categoryContent）
                        categories = parsed.categories
                        HomeState.Success(
                            categories = parsed.categories,
                            vodList = parsed.vodList,
                            site = BuiltinSitesProvider.demoSite,
                            selectedCategoryId = ALL_CATEGORY_ID
                        )
                    }
                }
            }
        } catch (e: CancellationException) {
            throw e
        } catch (t: Throwable) {
            Log.e(TAG, "示范站点兜底失败：${t.javaClass.simpleName}: ${t.message}", t)
            null
        }

        DemoFallback(content, selfTest)
    }

    /**
     * 兜底结果。
     *
     * @param content  兜到的首页内容（成功时非 null）
     * @param selfTest 内置链路自检结果（拿来说清"到底哪一步没通"）
     */
    private data class DemoFallback(
        val content: HomeState.Success?,
        val selfTest: SpiderManager.SelfTestResult?
    )

    /**
     * 拉一次内容并落到状态里。
     *
     * @param categoryId [ALL_CATEGORY_ID] 走 `homeContent`，否则走 `categoryContent`
     * @param prefetched 探活阶段已经拿到的首页 JSON。首屏那条路径把它带进来复用，
     *                   省掉一次重复请求（顺带让"homeContent 被调了几次"这件事符合预期）；
     *                   切分类 / 刷新时为 null，照常真发请求
     */
    private fun load(site: Site, categoryId: String, prefetched: String? = null) {
        loadJob?.cancel()

        val previous = lastContent
        // 站点与分类立刻记下：加载期间再点分类/刷新都按这一份走，不会被 Loading 态吞掉
        setActiveSite(site)
        currentCategoryId = categoryId
        _state.value = HomeState.Loading

        loadJob = viewModelScope.launch {
            val next: HomeState = try {
                val outcome = withContext(ioDispatcher) { fetch(site, categoryId, prefetched) }
                if (outcome.engineMissing) {
                    // 引擎都没有，空列表不是"源没内容"，别让 UI 显示空态骗人
                    val message = engineMissingMessage(outcome.siteName.ifBlank { site.name })
                    if (previous != null) {
                        setActiveSite(previous.site)
                        currentCategoryId = previous.selectedCategoryId
                        _transientMessage.value = message
                        previous
                    } else {
                        HomeState.Error(message)
                    }
                } else {
                    HomeState.Success(
                        categories = categories,
                        vodList = outcome.vods,
                        site = site,
                        selectedCategoryId = categoryId
                    )
                }
            } catch (e: CancellationException) {
                // 被新任务取消：让位，别把状态改回去（新任务会写）
                throw e
            } catch (e: Throwable) {
                // 契约要求：不许静默吃掉异常，堆栈要能进 Logcat
                Log.e(TAG, "首页加载失败: ${e.javaClass.simpleName}: ${e.message}")
                e.printStackTrace()
                if (previous != null) {
                    // 切分类失败：列表退回原样 + 一条提示。用户翻到的内容不该因为一次失败就消失，
                    // 记下的站点/分类也一起退回去，免得后续刷新按一个没加载成功的分类去拉。
                    setActiveSite(previous.site)
                    currentCategoryId = previous.selectedCategoryId
                    _transientMessage.value = MSG_CATEGORY_FAIL
                    previous
                } else {
                    HomeState.Error(MSG_LOAD_FAIL)
                }
            }

            if (next is HomeState.Success) {
                lastContent = next
            }
            _state.value = next
        }
    }

    /**
     * 真正的取数：拿 Spider → 调接口 → 解析。只允许在 IO 线程执行。
     *
     * 契约第 5~10 步全在这个函数里，日志一条不落。
     * 返回 [FetchOutcome.engineMissing] = true 的情况**不是错误也不是空内容**，
     * 是"这个站根本没有可用引擎"——上层要给它一个能指路的错误态，而不是一张空列表。
     */
    private suspend fun fetch(site: Site, categoryId: String, prefetched: String? = null): FetchOutcome =
        withContext(Dispatchers.IO) {
            // 5) 拿 Spider 实现：本地没有插件包时，这一步会把配置里的包下下来再加载
            val spider = spiderManager.resolveSpider(site.api, site.extString)

            // 6) 打类名——这条日志能一眼看出"是不是兜底空实现"
            Log.d(TAG, "Spider 实现: ${spider.javaClass.name}")

            if (spider is SpiderNull) {
                // 兜底空实现只会返回 {"class":[],"list":[]}。要是这里不打日志，
                // 上层就会把它当成"源暂时没内容"渲染成空态——那正是最坑人的静默失败。
                Log.e(
                    TAG,
                    "★ 站点没有可用的采集引擎：" +
                        "name=${site.name}, api=${site.api}, ext=${site.extString}（拿到的是兜底空实现）"
                )
                return@withContext FetchOutcome(engineMissing = true, siteName = site.name)
            }

            if (categoryId == ALL_CATEGORY_ID) {
                // 7) 真发请求（首屏那次已经在探活时拿过了，直接复用，不重复打一遍接口）
                val json = prefetched ?: spider.homeContent(false)

                // 8) 原始响应（截断，避免刷屏；前 500 字足够看出结构）
                Log.d(TAG, "raw json: " + json.take(500))
                if (json.isBlank()) {
                    Log.w(TAG, "★ homeContent 返回空字符串：不是解析问题，是引擎/网络没给东西")
                }

                // 9) 解析（永不抛，失败从 error 出去）
                val result = HomeContentParser.parseHomeContent(json)
                result.error?.let { Log.e(TAG, "★ JSON 解析出错: $it") }

                // 10) 结果
                Log.d(TAG, "共 ${result.categories.size} 个分类，${result.vodList.size} 部影视")
                if (result.vodList.isEmpty() && result.error == null) {
                    Log.w(
                        TAG,
                        "解析成功但列表为空（class=${result.categories.size}）：" +
                            "要么这个源首页就是空的，要么字段名不在兼容列表里"
                    )
                }

                // 顺手把分类表更新掉：新配置换了源，分类也要跟着换
                categories = result.categories
                FetchOutcome(vods = result.vodList)
            } else {
                val json = spider.categoryContent(categoryId, PAGE_FIRST, false, HashMap())
                Log.d(TAG, "分类 $categoryId raw json: " + json.take(500))
                if (json.isBlank()) {
                    Log.w(TAG, "★ categoryContent 返回空字符串（tid=$categoryId）")
                }
                // 引擎报"没拿到响应"：这不是"这个分类没内容"，不能静默显示空态
                // （空结构是合法空态；连不上/返回垃圾是故障，得走失败路径给用户提示）
                if ((spider as? SpiderProbe)?.lastCallFailed == true) {
                    throw IllegalStateException("分类 $categoryId 没拿到可用响应（引擎报失败）")
                }
                val vods = HomeContentParser.parseVods(json)
                if (json.isNotBlank() && vods.isEmpty() && !HomeContentParser.isWellFormed(json)) {
                    // 静默失败最坑人：接口返回了一坨不是 JSON 的东西，不揪出来就只会显示"这个分类没内容"
                    Log.e(
                        TAG,
                        "★ 分类 $categoryId 返回的不是合法 JSON（解析出来是空表，但这不是空内容，是接口坏了）：" +
                            json.take(200)
                    )
                }
                Log.d(TAG, "分类 $categoryId 共 ${vods.size} 部影视")
                FetchOutcome(vods = vods)
            }
        }

    /**
     * 一次取数的结果。
     *
     * @param vods          解析出来的列表（[engineMissing] 为 true 时无意义）
     * @param engineMissing 这个站根本没有可用采集引擎（拿到了 [SpiderNull]）
     * @param siteName      出问题的站点名，用来把错误文案说准（"站点 xxx 的采集引擎未加载"）
     */
    private data class FetchOutcome(
        val vods: List<Vod> = emptyList(),
        val engineMissing: Boolean = false,
        val siteName: String = ""
    )

    /** 引擎缺失文案：把站点名带进去，用户一眼知道该换哪个源。 */
    private fun engineMissingMessage(siteName: String): String =
        "站点 ${siteName.ifBlank { "当前" }} 的采集引擎未加载。" +
            "该站点可能需要插件包（.jar），请检查配置源或切换其他站点。"

    private companion object {
        /**
         * Logcat 过滤用的 TAG。
         * 契约要求就是 `HomeVM`（过滤这个短串，首页每一步都看得到），别改回类名。
         */
        const val TAG = "HomeVM"

        /** TVBox 约定：type == 3 是"点播采集站" */
        const val TYPE_CSP = 3

        /** TVBox 约定：api 以 csp_ 开头的是内置/插件采集引擎 */
        const val SPIDER_API_PREFIX = "csp_"

        /**
         * 多站点探活的总时间预算。
         *
         * 为什么要有：配置里几十个站，真机上每个站卡一次超时就是好几分钟，
         * 用户只会以为 App 死了。预算内没找到就先报错，下拉刷新可以接着试。
         * 正常情况下第一个候选（内置通用引擎 / 本地插件包）就是毫秒级命中，走不到这个上限。
         */
        const val PROBE_BUDGET_MS = 7_000L

        /**
         * 首页最多试几个"可用站"（引擎拿得到、能调起来的站）。
         *
         * 为什么 5 够用（不用抬）：原来的病根是**排序**——`csp_` 前缀优先让前 5 个名额全被
         * "要下插件包"的站吃掉，`ext` 直接给 http 地址、当场就能出片的 CMS 站一次都没轮到，
         * 表象就是"真实源一个都打不开"。现在 [orderCandidates] 已经把"当场能跑的站"提到最前，
         * 而且插件包那边有负缓存 + 单飞（同一个包本次会话只尝试一次，失败毫秒级短路），
         * 所以前 5 个名额都是花在"真有可能出片"的站上。既有契约（UI 用例 + 验收 Runner
         * 都断言"试满 5 个就停"）保持不动，不让用户挨个等。
         */
        const val MAX_USABLE_PROBE = 5

        /**
         * 一次探活最多"看过"几个站（含拿不到引擎、直接跳过的）。
         *
         * 拿不到引擎的站现在是毫秒级短路（插件包负缓存），这条只是防"几百个站的配置
         * 整批都没引擎"时空转到天荒地老。
         */
        const val MAX_CANDIDATE_VISITS = 60

        /** 分类接口第一页（TVBox 约定从 "1" 开始，不是 "0"） */
        const val PAGE_FIRST = "1"

        const val MSG_NO_SITE = "当前配置里没有可用的采集站点，先去「设置 → 站点管理」导入一份配置"

        const val MSG_LOAD_FAIL = "首页加载失败，检查一下网络，或换一个源再试"

        const val MSG_CATEGORY_FAIL = "这个分类没拉到内容，先看看刚才那批"

        /**
         * 兜到内置示范站点时的一次性提示。
         *
         * 顶栏此时显示的站点名就是「示范站点」，这条提示补上"接下来该干什么"——
         * 不然用户会以为这个站能一直用下去。
         */
        const val MSG_DEMO_FALLBACK = "当前为示范站点，请在站点管理中添加可用配置源"

        /** 构造 VM 时没注入配置源仓库 —— 裸 JVM / 单测路径会走到这里。 */
        const val MSG_NO_SOURCE_REPO = "这会儿读不到配置源列表，稍后再试"

        /** 换源后拉回来的配置里一个站点都没有（地址填错 / 空壳配置）。 */
        const val MSG_SOURCE_EMPTY = "这个配置源没给出站点，换一个试试"

        /** 还没有生效的站点时点搜索。 */
        const val MSG_SEARCH_NO_SITE = "先回首页让站点加载出来，再搜索"

        /** 搜索失败的人话（引擎缺失 / 没响应 / 返回看不懂）。明细在 Logcat 的 HomeVM 里。 */
        const val MSG_SEARCH_FAIL = "搜索没成功，换个关键词或者点右上角刷新后再试"
    }
}
