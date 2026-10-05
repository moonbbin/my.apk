package com.tvbox.shell.ui.home

import android.app.Application
import android.os.Looper
import androidx.activity.ComponentActivity
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.hasSetTextAction
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.longClick
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performImeAction
import androidx.compose.ui.test.performTextInput
import androidx.compose.ui.test.performTouchInput
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.tvbox.shell.config.AppConfigManager
import com.tvbox.shell.config.HistoryRepository
import com.tvbox.shell.config.SiteRepository
import com.tvbox.shell.config.UserPreference
import com.tvbox.shell.model.AppConfig
import com.tvbox.shell.model.PlayHistory
import com.tvbox.shell.model.Site
import com.tvbox.shell.model.Vod
import com.tvbox.shell.player.PlayerActivity
import com.tvbox.shell.spider.Spider
import com.tvbox.shell.spider.SpiderManager
import com.tvbox.shell.ui.ShellTheme
import com.tvbox.shell.ui.component.SEARCH_FIELD_TAG
import com.tvbox.shell.ui.component.formatProgressText
import com.tvbox.shell.ui.component.historyRowTag
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

/**
 * 模块七（首页 6 个交互）的护栏测试 —— 真渲染 Compose、真点、真回调。
 *
 * 覆盖契约里那条验收清单：
 * 1. 首页底部导航四个 Tab（首页 / 搜索 / 历史 / 设置），顶栏保留刷新；
 * 2. **点**标题 → 站点列表（带搜索框）；**长按**标题 → 配置源列表；
 * 3. 搜索：回车出结果网格、历史以 Chip 展示、可复用；
 * 4. 历史：显示播过的片子 + 进度 + "看到 xx:xx"，点一条能从上次位置续播；
 * 5. 切站会落盘（杀 App 重开还在上次那个站）。
 *
 * 另外在 ViewModel 这一层钉了几件 UI 测不到的：换源真去拉配置并写进 AppConfigManager、
 * 搜索的四态（Idle / Loading / Success（含空结果）/ Error）、选择器开关的状态机。
 */
@RunWith(AndroidJUnit4::class)
@Config(sdk = [34], qualifiers = "w360dp-h640dp-xhdpi")
class InteractionTest {

    @get:Rule
    val rule = createAndroidComposeRule<ComponentActivity>()

    private val app: Application = ApplicationProvider.getApplicationContext()

    @Before
    fun setUp() {
        AppConfigManager.clear()
        UserPreference.init(app)
        UserPreference.clearSearchHistory()
        HistoryRepository.init(app)
        HistoryRepository.clear()
    }

    @After
    fun tearDown() {
        releaseRobolectricTextRegistry()
        AppConfigManager.clear()
        HistoryRepository.clear()
    }

    // ==================================================================
    // 夹具
    // ==================================================================

    private val homeJson = """
        {
          "class": [{"type_id":"1","type_name":"电影"}],
          "list": [
            {"vod_id":"1001","vod_name":"首页片一","vod_pic":"","vod_remarks":"更新至10集"},
            {"vod_id":"1002","vod_name":"首页片二"}
          ]
        }
    """.trimIndent()

    private val searchJson = """
        {"page":"1","list":[{"vod_id":"3001","vod_name":"搜到的片"},{"vod_id":"3002","vod_name":"搜到的片二"}]}
    """.trimIndent()

    /** 可编程替身：首页 / 搜索各返回什么、搜索调没调过，都记下来。 */
    private class RecordingSpider(
        private val home: String,
        private val search: String,
        private val searchThrows: Boolean = false
    ) : Spider {
        var searchCalls = 0
            private set
        var lastKeyword: String? = null
            private set

        override fun homeContent(filter: Boolean): String = home

        override fun categoryContent(
            tid: String,
            pg: String,
            filter: Boolean,
            extend: HashMap<String, String>
        ): String = """{"page":"1","list":[]}"""

        override fun detailContent(ids: List<String>): String = """{"list":[]}"""

        override fun searchContent(key: String, quick: Boolean): String {
            searchCalls++
            lastKeyword = key
            if (searchThrows) throw IllegalStateException("搜索接口炸了")
            return search
        }

        override fun playerContent(flag: String, id: String, vipFlags: List<String>): String =
            """{"parse":1,"url":""}"""
    }

    private fun site(api: String, name: String) = Site(key = api, name = name, type = 3, api = api)

    private fun configOf(vararg sites: Site) = AppConfig(sites = sites.toList())

    /**
     * 造一个能出内容的 VM。
     *
     * @param repo 注入的配置源仓库（测"长按换源"时用真仓库 + 真配置源条目）
     * @param configLoader 拉配置的实现，默认给一份空配置（测试不该真联网）
     */
    private fun viewModel(
        impl: Spider = RecordingSpider(homeJson, searchJson),
        config: AppConfig = configOf(site("csp_Alpha", "甲站")),
        repo: SiteRepository? = null,
        configLoader: (suspend (String) -> AppConfig)? = null
    ): HomeViewModel {
        val mgr = SpiderManager().apply {
            register("csp_Alpha") { impl }
            register("csp_Beta") { impl }
            register("csp_Gamma") { impl }
        }
        return HomeViewModel(
            spiderManager = mgr,
            configProvider = { AppConfigManager.getCurrentConfig().let { if (it.sites.isEmpty()) config else it } },
            siteRepository = repo,
            configLoader = configLoader ?: { AppConfig() }
        )
    }

    /** 渲染首页并等内容出来。 */
    private fun renderHome(
        vm: HomeViewModel,
        onPlayHistory: ((PlayHistory) -> Unit)? = null
    ) {
        rule.setContent {
            ShellTheme {
                HomeScreen(viewModel = vm, onPlayHistory = onPlayHistory)
            }
        }
        awaitCondition(10_000) {
            rule.onAllNodesWithText("首页片一").fetchSemanticsNodes().isNotEmpty()
        }
    }

    /**
     * Robolectric 的文本测量影子会往一张 native 对象表里登记结果、且从不释放
     * （ShadowLineBreaker.nativeObjectRegistry）。UI 测试一多，这张表能把堆吃到 OOM。
     */
    private fun releaseRobolectricTextRegistry() {
        try {
            val shadowClass = Class.forName("org.robolectric.shadows.ShadowLineBreaker")
            val field = shadowClass.getDeclaredField("nativeObjectRegistry")
            field.isAccessible = true
            val registry = field.get(null) ?: return
            registry.javaClass.getMethod("clear").invoke(registry)
        } catch (_: Throwable) {
            // ignore
        }
    }

    /**
     * 等条件成立。
     *
     * 不用 rule.waitUntil：Robolectric 主 looper 是暂停模式，waitUntil 只在测试线程自旋、
     * 不推进 looper —— 挂在 Dispatchers.Main 上的协程（ViewModel 的状态写回）永远不会执行。
     */
    private fun awaitCondition(timeoutMillis: Long, condition: () -> Boolean) {
        val deadline = System.currentTimeMillis() + timeoutMillis
        var renderWarning: Throwable? = null
        while (System.currentTimeMillis() < deadline) {
            try {
                rule.waitForIdle()
            } catch (e: Throwable) {
                renderWarning = e
            }
            shadowOf(Looper.getMainLooper()).idle()
            if (condition()) return
            Thread.sleep(20)
        }
        fail(
            "条件在 ${timeoutMillis}ms 内没满足" +
                (renderWarning?.let { "（渲染告警：${it.javaClass.simpleName}）" } ?: "")
        )
    }

    /** 只推主 looper（不渲染 UI 的纯 ViewModel 用例用这个）。 */
    private fun awaitMain(timeoutMillis: Long = 10_000, condition: () -> Boolean) {
        val deadline = System.currentTimeMillis() + timeoutMillis
        while (System.currentTimeMillis() < deadline) {
            shadowOf(Looper.getMainLooper()).idle()
            if (condition()) return
            Thread.sleep(10)
        }
        fail("（不渲染）条件在 ${timeoutMillis}ms 内没满足")
    }


    /**
     * 精确定位"历史列表里的那一行"（按 vodId 生成的锚点）。
     *
     * 历史页是压在首页之上的浮层，首页封面墙上往往有同名片子
     * —— 只按文案找会命中两个节点（实测：`Expected exactly 1 node but found 2`）。
     */
    private fun historyRow(vodId: String) =
        rule.onNodeWithTag(historyRowTag(PlayHistory(vodId = vodId)))

    // ==================================================================
    // 验收 1：右上角三个图标
    // ==================================================================

    @Test
    fun `验收1 - 底部导航有首页 搜索 历史 设置四个入口，顶栏保留刷新`() {
        renderHome(viewModel())

        rule.onNodeWithText("首页").assertIsDisplayed()
        rule.onNodeWithText("搜索").assertIsDisplayed()
        rule.onNodeWithText("历史").assertIsDisplayed()
        rule.onNodeWithText("设置").assertIsDisplayed()
        rule.onNodeWithContentDescription("刷新").assertIsDisplayed()
    }

    // ==================================================================
    // 验收 2：点标题换站 / 长按标题换源
    // ==================================================================

    @Test
    fun `验收2 - 点标题弹出站点列表（带搜索框）`() {
        val vm = viewModel()
        renderHome(vm)

        assertTrue("初始不该有选择器", !vm.sitePickerVisible.value)

        rule.onNodeWithTag(HOME_TITLE_TAG).performClick()

        awaitCondition(5_000) { vm.sitePickerVisible.value }
        rule.onNodeWithText("切换站点").assertIsDisplayed()
        rule.onNodeWithText("csp_Alpha").assertIsDisplayed()
        rule.onNodeWithText("搜索站点名或 api").assertIsDisplayed()
    }

    @Test
    fun `验收2 - 站点列表搜索过滤出空结果时给提示`() {
        renderHome(viewModel())

        rule.onNodeWithTag(HOME_TITLE_TAG).performClick()
        awaitCondition(5_000) {
            rule.onAllNodesWithText("切换站点").fetchSemanticsNodes().isNotEmpty()
        }

        rule.onNode(hasSetTextAction()).performTextInput("不存在的站")

        awaitCondition(5_000) {
            rule.onAllNodesWithText("未找到匹配的站点").fetchSemanticsNodes().isNotEmpty()
        }
        rule.onNodeWithText("未找到匹配的站点").assertIsDisplayed()
    }

    @Test
    fun `验收2 - 长按标题弹出配置源列表`() {
        val repo = SiteRepository(app).apply { addSource("我的源", "https://example.com/config.json") }
        val vm = viewModel(repo = repo)

        // 先让首页加载出来（这样 availableSources 已经刷过）
        renderHome(vm)
        awaitCondition(5_000) { vm.availableSources.value.isNotEmpty() }

        rule.onNodeWithTag(HOME_TITLE_TAG).performTouchInput { longClick() }

        awaitCondition(5_000) { vm.sourcePickerVisible.value }
        rule.onNodeWithText("切换配置源").assertIsDisplayed()
        rule.onNodeWithText("我的源").assertIsDisplayed()
        rule.onNodeWithText("https://example.com/config.json").assertIsDisplayed()
    }

    // ==================================================================
    // 验收 3：搜索
    // ==================================================================

    @Test
    fun `验收3 - 点搜索图标打开搜索页，回车出结果网格并记进历史`() {
        val impl = RecordingSpider(homeJson, searchJson)
        val vm = viewModel(impl = impl)
        renderHome(vm)

        rule.onNodeWithContentDescription("搜索").performClick()
        awaitCondition(5_000) { vm.searchScreenVisible.value }

        rule.onNodeWithTag(SEARCH_FIELD_TAG).performTextInput("片")
        rule.onNodeWithTag(SEARCH_FIELD_TAG).performImeAction()

        awaitCondition(10_000) { impl.searchCalls == 1 }
        assertEquals("关键词要原样传下去", "片", impl.lastKeyword)

        awaitCondition(10_000) {
            rule.onAllNodesWithText("搜到的片").fetchSemanticsNodes().isNotEmpty()
        }
        rule.onNodeWithText("搜到的片").assertIsDisplayed()
        rule.onNodeWithText("搜到的片二").assertIsDisplayed()

        assertTrue(
            "搜索关键词要进搜索历史（验收 3 的 Chip 就靠它）",
            UserPreference.getSearchHistory().contains("片")
        )
    }

    @Test
    fun `验收3 - 搜索历史以 Chip 展示，点一下能复用`() {
        UserPreference.addSearchHistory("狂飙")
        val impl = RecordingSpider(homeJson, searchJson)
        val vm = viewModel(impl = impl)
        renderHome(vm)

        rule.onNodeWithContentDescription("搜索").performClick()
        awaitCondition(5_000) { vm.searchScreenVisible.value }

        rule.onNodeWithText("搜索历史").assertIsDisplayed()
        rule.onNodeWithText("狂飙").performClick()

        awaitCondition(10_000) { impl.searchCalls == 1 }
        assertEquals("点历史应该用那条关键词重搜", "狂飙", impl.lastKeyword)
    }

    /** ViewModel 层的搜索四态：UI 只画状态，状态的正确性在这里钉死。 */
    @Test
    fun `搜索四态 - 空关键词回 Idle、成功给结果、没命中给空表、引擎炸了给 Error`() {
        val impl = RecordingSpider(homeJson, """{"list":[]}""")
        val vm = viewModel(impl = impl)
        vm.loadHomeContent()
        awaitMain { vm.state.value is HomeState.Success }

        vm.searchContent("   ")
        assertTrue("空关键词不该发请求", vm.searchResultState.value is SearchState.Idle)
        assertEquals(0, impl.searchCalls)

        vm.searchContent("什么都没有")
        awaitMain { vm.searchResultState.value is SearchState.Success }
        assertTrue(
            "合法 JSON 但没结果 = 搜到了但没命中，不是错误",
            (vm.searchResultState.value as SearchState.Success).vods.isEmpty()
        )
        assertTrue("引擎确实被调了", impl.searchCalls == 1)

        val broken = viewModel(impl = RecordingSpider(homeJson, searchJson, searchThrows = true))
        broken.loadHomeContent()
        awaitMain { broken.state.value is HomeState.Success }
        broken.searchContent("片")
        awaitMain { broken.searchResultState.value is SearchState.Error }
        assertTrue(
            "引擎抛异常要走 Error，不能装作『没找到』",
            (broken.searchResultState.value as SearchState.Error).message.isNotBlank()
        )
    }

    // ==================================================================
    // 验收 4：观看历史
    // ==================================================================

    @Test
    fun `验收4 - 历史页显示片名 集名 进度和看到时间`() {
        HistoryRepository.upsert(
            PlayHistory(
                vodId = "1001",
                vodName = "首页片一",
                vodPic = "",
                episodeName = "第03集",
                episodeUrl = "https://example.com/e3.m3u8",
                positionMs = 90_000,
                durationMs = 180_000,
                lastPlayedAt = System.currentTimeMillis()
            )
        )

        val vm = viewModel()
        renderHome(vm)

        rule.onNodeWithContentDescription("历史").performClick()
        awaitCondition(5_000) { vm.historyScreenVisible.value }

        rule.onNodeWithText("观看历史").assertIsDisplayed()
        historyRow("1001").assertIsDisplayed()
        rule.onNodeWithText("第03集").assertIsDisplayed()
        rule.onNodeWithText("看到 01:30 / 总 03:00").assertIsDisplayed()
        rule.onNodeWithText("清空").assertIsDisplayed()
    }

    @Test
    fun `验收4 - 空历史显示暂无观看记录`() {
        val vm = viewModel()
        renderHome(vm)

        rule.onNodeWithContentDescription("历史").performClick()
        awaitCondition(5_000) { vm.historyScreenVisible.value }

        rule.onNodeWithText("暂无观看记录").assertIsDisplayed()
    }

    @Test
    fun `验收4 - 点历史一条会把上次进度带出去（续播靠它）`() {
        HistoryRepository.upsert(
            PlayHistory(
                vodId = "1001",
                vodName = "首页片一",
                episodeName = "第03集",
                episodeUrl = "https://example.com/e3.m3u8",
                positionMs = 90_000,
                durationMs = 180_000,
                lastPlayedAt = System.currentTimeMillis()
            )
        )

        var picked: PlayHistory? = null
        val vm = viewModel()
        renderHome(vm, onPlayHistory = { picked = it })

        rule.onNodeWithContentDescription("历史").performClick()
        awaitCondition(5_000) { vm.historyScreenVisible.value }

        historyRow("1001").performClick()

        awaitCondition(5_000) { picked != null }
        assertEquals("续播起点必须是上次看到的位置", 90_000L, picked!!.positionMs)
        assertEquals("https://example.com/e3.m3u8", picked!!.episodeUrl)
        assertTrue("点完历史页要关掉，别挡住播放", !vm.historyScreenVisible.value)
    }

    @Test
    fun `验收4 - 历史页能删单条和清空`() {
        HistoryRepository.upsert(
            PlayHistory(vodId = "1001", vodName = "首页片一", lastPlayedAt = 1_000)
        )
        HistoryRepository.upsert(
            PlayHistory(vodId = "1002", vodName = "首页片二", lastPlayedAt = 2_000)
        )

        val vm = viewModel()
        renderHome(vm)

        rule.onNodeWithContentDescription("历史").performClick()
        awaitCondition(5_000) { vm.historyScreenVisible.value }

        // 长按 → 确认框 → 删除
        historyRow("1002").performTouchInput { longClick() }
        awaitCondition(5_000) {
            rule.onAllNodesWithText("删除这条记录？").fetchSemanticsNodes().isNotEmpty()
        }
        rule.onNodeWithText("删除").performClick()
        awaitCondition(5_000) { HistoryRepository.getByVodId("1002") == null }
        assertEquals("只该删掉那一条", 1, HistoryRepository.getAll().size)

        // 清空
        rule.onNodeWithText("清空").performClick()
        awaitCondition(5_000) { HistoryRepository.getAll().isEmpty() }
        rule.onNodeWithText("暂无观看记录").assertIsDisplayed()
    }

    // ==================================================================
    // 验收 5：切站落盘（杀 App 重开还在上次那个站）
    // ==================================================================

    @Test
    fun `验收5 - 切站会更新当前站点、落盘、并真的重新加载`() {
        val impl = RecordingSpider(homeJson, searchJson)
        val vm = viewModel(
            impl = impl,
            config = configOf(site("csp_Alpha", "甲站"), site("csp_Beta", "乙站"))
        )
        vm.loadHomeContent()
        awaitMain { vm.state.value is HomeState.Success }

        val target = vm.availableSites.value.first { it.api == "csp_Beta" }
        vm.switchSite(target)

        assertEquals("当前站点要立刻换掉", "csp_Beta", vm.currentSite.value?.api)
        assertEquals("必须落盘（验收 5 靠它）", "csp_Beta", UserPreference.getLastSelectedApi())
        assertTrue("选择器要关掉", !vm.sitePickerVisible.value)

        awaitMain { vm.state.value is HomeState.Success }
        assertEquals(
            "新站要真的生效",
            "csp_Beta",
            (vm.state.value as HomeState.Success).site.api
        )
    }

    @Test
    fun `换站时分类表被清空 - 免得点到新站根本没有的分类`() {
        val impl = RecordingSpider(homeJson, searchJson)
        val vm = viewModel(
            impl = impl,
            config = configOf(site("csp_Alpha", "甲站"), site("csp_Beta", "乙站"))
        )
        vm.loadHomeContent()
        awaitMain { vm.state.value is HomeState.Success }
        assertTrue(
            "初始应该带出分类",
            (vm.state.value as HomeState.Success).categories.isNotEmpty()
        )

        vm.switchSite(vm.availableSites.value.first { it.api == "csp_Beta" })

        // 加载完成那一刻，分类必须是新站这次给出的那一份（旧站那份不能残留）
        awaitMain {
            val s = vm.state.value
            s is HomeState.Success && s.site.api == "csp_Beta" && s.categories.isNotEmpty()
        }
    }

    @Test
    fun `冷启动 - 上次选中的站点优先（不再从第一个站瞎试）`() {
        val impl = RecordingSpider(homeJson, searchJson)
        UserPreference.setLastSelectedApi("csp_Gamma")
        val vm = viewModel(
            impl = impl,
            config = configOf(site("csp_Alpha", "甲站"), site("csp_Beta", "乙站"), site("csp_Gamma", "丙站"))
        )

        vm.loadHomeContent()
        awaitMain { vm.state.value is HomeState.Success }

        assertEquals(
            "钉住的站点必须排在最前，被优先选中",
            "csp_Gamma",
            (vm.state.value as HomeState.Success).site.api
        )
    }

    // ==================================================================
    // 换配置源
    // ==================================================================

    @Test
    fun `换配置源 - 选中项落盘、拉新配置、写进 AppConfigManager 并重载`() {
        val repo = SiteRepository(app).apply { addSource("源A", "https://example.com/a.json") }
        val source = repo.getSources().first()

        val impl = RecordingSpider(homeJson, searchJson)
        val newConfig = configOf(site("csp_Beta", "乙站"))
        val vm = viewModel(
            impl = impl,
            config = configOf(site("csp_Alpha", "甲站")),
            repo = repo,
            configLoader = { newConfig }
        )

        vm.switchSource(source)

        awaitMain { AppConfigManager.getCurrentConfig().sites.any { it.api == "csp_Beta" } }
        assertEquals("选中项要落盘", source.id, UserPreference.getLastSelectedSourceId())
        assertEquals("仓库里也要选中", source.id, repo.getSelectedSource()?.id)
        assertTrue("选择器要关掉", !vm.sourcePickerVisible.value)

        awaitMain { vm.state.value is HomeState.Success }
        assertEquals("新配置要生效", "csp_Beta", (vm.state.value as HomeState.Success).site.api)
    }

    @Test
    fun `换配置源 - 拉回来是空配置时保住原页面，只给提示`() {
        val repo = SiteRepository(app).apply { addSource("空源", "https://example.com/empty.json") }
        val source = repo.getSources().first()

        val vm = viewModel(
            impl = RecordingSpider(homeJson, searchJson),
            config = configOf(site("csp_Alpha", "甲站")),
            repo = repo,
            configLoader = { AppConfig() }
        )
        vm.loadHomeContent()
        awaitMain { vm.state.value is HomeState.Success }

        vm.switchSource(source)

        awaitMain { vm.transientMessage.value != null }
        assertTrue(
            "换源失败不该把已经能看的列表打掉",
            vm.state.value is HomeState.Success
        )
    }

    @Test
    fun `换配置源 - 没注入仓库时如实提示而不是假装换好了`() {
        val vm = viewModel()

        vm.switchSource(
            com.tvbox.shell.config.SiteSource(id = "x", name = "我的源", url = "https://example.com/c.json")
        )

        assertEquals(
            "要有明确的提示，不能假装换好了",
            true,
            vm.transientMessage.value?.isNotBlank() == true
        )
    }

    // ==================================================================
    // 选择器开关的状态机
    // ==================================================================

    @Test
    fun `选择器开关 - 两个选择器互斥，搜索页与历史页各自独立`() {
        val vm = viewModel()

        vm.showSitePicker()
        assertTrue(vm.sitePickerVisible.value)

        vm.showSourcePicker()
        assertTrue("打开配置源选择器要把站点选择器关掉", !vm.sitePickerVisible.value)
        assertTrue(vm.sourcePickerVisible.value)

        vm.hideSourcePicker()
        assertTrue(!vm.sourcePickerVisible.value)

        vm.showSearchScreen()
        assertTrue(vm.searchScreenVisible.value)
        vm.hideSearchScreen()
        assertTrue(!vm.searchScreenVisible.value)

        vm.showHistoryScreen()
        assertTrue(vm.historyScreenVisible.value)
        vm.hideHistoryScreen()
        assertTrue(!vm.historyScreenVisible.value)
    }

    // ==================================================================
    // PlayerActivity 的 Intent 契约（模块七新增的 5 个 extra）
    // ==================================================================

    @Test
    fun `播放器 Intent - 新增的片子信息与续播起点都能带上`() {
        val intent = PlayerActivity.intent(
            context = app,
            videoUrl = "https://example.com/e3.m3u8",
            headers = HashMap<String, String>().apply { put("Referer", "https://example.com") },
            vodId = "1001",
            vodName = "首页片一",
            vodPic = "https://example.com/p.jpg",
            episodeName = "第03集",
            startPositionMs = 90_000L
        )

        assertEquals("1001", intent.getStringExtra(PlayerActivity.EXTRA_VOD_ID))
        assertEquals("首页片一", intent.getStringExtra(PlayerActivity.EXTRA_VOD_NAME))
        assertEquals("https://example.com/p.jpg", intent.getStringExtra(PlayerActivity.EXTRA_VOD_PIC))
        assertEquals("第03集", intent.getStringExtra(PlayerActivity.EXTRA_EPISODE_NAME))
        assertEquals(90_000L, intent.getLongExtra(PlayerActivity.EXTRA_START_POSITION_MS, 0L))
        assertEquals("https://example.com/e3.m3u8", intent.getStringExtra(PlayerActivity.EXTRA_VIDEO_URL))
        assertNotNull(intent.getSerializableExtra(PlayerActivity.EXTRA_HEADERS))
    }

    @Test
    fun `播放器 Intent - 老的三参调用照样能用且不塞多余的 extra`() {
        val intent = PlayerActivity.intent(app, "https://example.com/a.mp4")

        assertEquals("https://example.com/a.mp4", intent.getStringExtra(PlayerActivity.EXTRA_VIDEO_URL))
        assertEquals("空值不该塞进去，否则调用方会误判『传了』", null, intent.getStringExtra(PlayerActivity.EXTRA_VOD_ID))
        assertEquals(0L, intent.getLongExtra(PlayerActivity.EXTRA_START_POSITION_MS, 0L))
    }

    // ==================================================================
    // HistoryScreen 的时长格式化（不渲染，直接验文本）
    // ==================================================================

    @Test
    fun `历史文案 - 时长未知时只说看到，不编一个总 00-00`() {
        val noDuration = PlayHistory(vodName = "片", positionMs = 65_000, durationMs = 0L)
        assertEquals("看到 01:05", formatProgressText(noDuration))

        val withDuration = PlayHistory(vodName = "片", positionMs = 65_000, durationMs = 3_725_000)
        assertEquals("看到 01:05 / 总 1:02:05", formatProgressText(withDuration))
    }
}
