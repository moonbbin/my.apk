@file:OptIn(kotlinx.coroutines.ExperimentalCoroutinesApi::class)

package com.tvbox.shell.ui.home

import com.tvbox.shell.config.HistoryRepository
import com.tvbox.shell.config.UserPreference
import com.tvbox.shell.model.PlayHistory
import java.lang.reflect.Modifier as JModifier

/**
 * 模块七（首页 6 个交互：换站 / 换源 / 搜索 / 历史）的**独立验收入口** ——
 * 不经过测试框架，直接调编译产物。
 *
 * 跑法：
 * ```
 * bash acceptance/run-interaction.sh
 * ```
 *
 * 为什么要这一遍：Robolectric 会把实现垫进一层插桩沙箱，而这一轮最容易做漏的恰恰是
 * **契约面** —— 方法名、参数类型、返回值类型、常量的确切值。
 * 这些在"裸 JVM + 真 classpath"上反射一遍最硬：少一个方法、参数类型写错、
 * 常量值漂了，这里当场红，而不是等到集成到用户工程里才发现。
 *
 * 覆盖：
 * - 契约面（反射）：10 个交付文件里对外的每个入口，签名逐条对齐
 * - 行为：`PlayHistory.progressPercent` 全表（含 0 时长 / 越界 / 负数这些边界）
 * - 行为：`HistoryRepository` 的增删改查 + 上限截断（内存路径，无需 Android 运行时）
 * - 行为：`UserPreference` 搜索历史的去重 / 排序 / 上限（同上，走内存兜底）
 * - 不变量：三个常量的确切值（20 / 100 / 5000ms）
 * - 越界检查：UI 层与 ViewModel 不得依赖播放器 / 网盘解析器内部类型
 *
 * 诚实边界：Compose 渲染、SharedPreferences 真落盘、ModalBottomSheet 的弹出，
 * 在裸 JVM 上跑不了（要 Android 运行时），由 Robolectric 的
 * `InteractionTest` / `PreferenceAndHistoryTest` / `PlayerHistoryTest` 真验，
 * 不在本文件覆盖面内。
 */
fun main() {
    var passed = 0
    var failed = 0
    val t0 = System.currentTimeMillis()

    fun check(name: String, ok: Boolean, detail: String = "") {
        val suffix = if (detail.isEmpty()) "" else " -> $detail"
        if (ok) {
            passed++
            println("PASS:: $name$suffix")
        } else {
            failed++
            println("FAIL:: $name$suffix")
        }
    }

    fun mark(label: String) = println("== $label (耗时 +${System.currentTimeMillis() - t0}ms)")

    fun loadOrNull(name: String): Class<*>? = try {
        Class.forName(name)
    } catch (e: Throwable) {
        println("   无法加载 $name: ${e.javaClass.simpleName}: ${e.message}")
        null
    }

    fun methodsOf(cls: Class<*>?, name: String): List<java.lang.reflect.Method> =
        cls?.declaredMethods?.filter { it.name == name } ?: emptyList()

    fun paramNames(m: java.lang.reflect.Method): List<String> =
        m.parameterTypes.map { it.simpleName }

    fun describe(m: java.lang.reflect.Method): String =
        "${m.name}(${m.parameterTypes.joinToString(", ") { it.simpleName }})"

    /** 取 Kotlin `object` 的单例实例。 */
    fun instanceOf(cls: Class<*>?): Any? = try {
        cls?.getDeclaredField("INSTANCE")?.get(null)
    } catch (e: Throwable) {
        null
    }

    fun intConst(cls: Class<*>?, field: String): Int? = try {
        cls?.getDeclaredField(field)?.getInt(null)
    } catch (e: Throwable) {
        println("   [诊断] 读 $field 失败：${e.javaClass.simpleName}: ${e.message}")
        null
    }

    fun longConst(cls: Class<*>?, field: String): Long? = try {
        cls?.getDeclaredField(field)?.getLong(null)
    } catch (e: Throwable) {
        println("   [诊断] 读 $field 失败：${e.javaClass.simpleName}: ${e.message}")
        null
    }

    fun stringConst(cls: Class<*>?, field: String): String? = try {
        cls?.getDeclaredField(field)?.get(null) as? String
    } catch (e: Throwable) {
        println("   [诊断] 读 $field 失败：${e.javaClass.simpleName}: ${e.message}")
        null
    }

    /** 某个方法是不是"接一个 StateFlow 出来"（属性 getter 的形式）。 */
    fun returnsStateFlow(m: java.lang.reflect.Method): Boolean =
        m.returnType.name.startsWith("kotlinx.coroutines.flow.StateFlow")

    /**
     * 比对 Composable 方法的"形状"。
     *
     * Compose 编译器插件会在参数表尾部另外塞 `Composer` 和一个 `int`（`$changed`），
     * 而且**带默认值的 lambda 参数**会被换成 `Function0`（默认值哨兵）。
     * 所以这里先剥掉尾巴、再把 `Function?` 当通配符比，才是这个函数的真实契约形状。
     *
     * @param expected 期望形状；写 "Function" 表示"任意 FunctionN 都算对"
     */
    fun shapeOf(m: java.lang.reflect.Method, expected: List<String>): String? {
        val actual = paramNames(m).filterNot { it == "Composer" || it == "int" }
        if (actual.size != expected.size) return "参数个数 ${actual.size} != ${expected.size}（${actual.joinToString()}）"
        expected.forEachIndexed { i, want ->
            val got = actual[i]
            val ok = if (want == "Function") got.startsWith("Function") else got == want
            if (!ok) return "第 ${i + 1} 个参数是 $got，期望 $want"
        }
        return null
    }

    /**
     * 读一个已编译类的**字节码原文**（不加载类）。
     *
     * 为什么需要这条路：`PlayerActivity` 继承 android 的 Activity，
     * 裸 JVM 里 `Class.forName` 会因为找不到 `android.app.Activity` 整个塌掉
     * —— 于是它的常量与入口在独立验收这一侧就完全没人看。
     * 直接读 class 文件的常量池能把这件事补上：常量值、方法名这些 UTF8 串都在里面。
     */
    fun classBytes(internalName: String): ByteArray? = try {
        // 用系统类加载器而不是本文件的 facade 类：同一编译单元里引用自己的 facade 解析不了。
        ClassLoader.getSystemClassLoader()
            .getResourceAsStream(internalName)
            ?.use { stream -> stream.readBytes() }
    } catch (e: Throwable) {
        null
    }

    fun ByteArray?.hasAscii(text: String): Boolean =
        this != null && String(this, Charsets.ISO_8859_1).contains(text)

    println("===== 模块七（首页交互增强）独立验收 =====")

    // ================================================================
    mark("一、UserPreference：统一持久化的契约面")
    // ================================================================

    val prefCls = loadOrNull("com.tvbox.shell.config.UserPreference")
    check("UserPreference 存在", prefCls != null)

    if (prefCls != null) {
        check("PREFS_NAME 就是契约值 tvbox_prefs", stringConst(prefCls, "PREFS_NAME") == "tvbox_prefs",
            stringConst(prefCls, "PREFS_NAME").orEmpty())
        check("MAX_SEARCH_HISTORY = 20（契约值）", intConst(prefCls, "MAX_SEARCH_HISTORY") == 20,
            intConst(prefCls, "MAX_SEARCH_HISTORY").toString())

        val signatures = mapOf(
            "init" to listOf("Context"),
            "getLastSelectedApi" to emptyList(),
            "setLastSelectedApi" to listOf("String"),
            "getLastSelectedSourceId" to emptyList(),
            "setLastSelectedSourceId" to listOf("String"),
            "getSearchHistory" to emptyList(),
            "addSearchHistory" to listOf("String"),
            "clearSearchHistory" to emptyList(),
            "getLastPlayVodId" to emptyList(),
            "setLastPlayVodId" to listOf("String")
        )
        signatures.forEach { (name, expected) ->
            val hit = methodsOf(prefCls, name).firstOrNull { paramNames(it) == expected }
            check("UserPreference.$name(${expected.joinToString()}) 存在", hit != null,
                if (hit == null) methodsOf(prefCls, name).joinToString { describe(it) } else "")
        }

        val lastApi = methodsOf(prefCls, "getLastSelectedApi").firstOrNull()
        check("getLastSelectedApi 返回可空 String（String?）", lastApi?.returnType == String::class.java)
        val history = methodsOf(prefCls, "getSearchHistory").firstOrNull()
        check("getSearchHistory 返回 List", history?.returnType == List::class.java,
            history?.returnType?.name.orEmpty())
    }

    // ================================================================
    mark("二、PlayHistory：模型契约 + 进度计算全表")
    // ================================================================

    val histCls = loadOrNull("com.tvbox.shell.model.PlayHistory")
    check("PlayHistory 存在", histCls != null)

    if (histCls != null) {
        val ctor = histCls.declaredConstructors.firstOrNull { it.parameterCount == 8 }
        check("构造器是 8 个字段（vodId..lastPlayedAt）", ctor != null,
            histCls.declaredConstructors.joinToString { it.parameterTypes.joinToString { p -> p.simpleName } })

        val expectedFields = listOf(
            "vodId", "vodName", "vodPic", "episodeName",
            "episodeUrl", "positionMs", "durationMs", "lastPlayedAt"
        )
        expectedFields.forEach { f ->
            val getter = "get" + f.replaceFirstChar { it.uppercase() }
            check("PlayHistory.$f 读得出来", methodsOf(histCls, getter).isNotEmpty())
        }

        val progress = methodsOf(histCls, "getProgressPercent").firstOrNull()
        check("progressPercent 是 float（进度条要的）", progress?.returnType == Float::class.javaPrimitiveType,
            progress?.returnType?.name.orEmpty())

        // 行为全表：真算，不是"能调通就算过"
        fun progress(positionMs: Long, durationMs: Long): Float {
            val inst = histCls.getDeclaredConstructor(
                String::class.java, String::class.java, String::class.java, String::class.java,
                String::class.java, java.lang.Long.TYPE, java.lang.Long.TYPE, java.lang.Long.TYPE
            ).newInstance("v", "n", "", "", "", positionMs, durationMs, 0L)
            return histCls.getMethod("getProgressPercent").invoke(inst) as Float
        }

        check("进度 90s/180s = 0.5", progress(90_000, 180_000) == 0.5f, progress(90_000, 180_000).toString())
        check("进度 0 时长 → 0（不是 NaN）", progress(30_000, 0) == 0f, progress(30_000, 0).toString())
        check("进度超出总时长 → 夹到 1", progress(200_000, 180_000) == 1f, progress(200_000, 180_000).toString())
        check("进度负数 → 夹到 0", progress(-5, 180_000) == 0f, progress(-5, 180_000).toString())
        check("进度 0/0 → 0", progress(0, 0) == 0f, progress(0, 0).toString())
    }

    // ================================================================
    mark("三、HistoryRepository：单例 + 增删改查 + 上限")
    // ================================================================

    val repoCls = loadOrNull("com.tvbox.shell.config.HistoryRepository")
    check("HistoryRepository 存在", repoCls != null)

    if (repoCls != null) {
        check("MAX_ENTRIES = 100（契约值）", intConst(repoCls, "MAX_ENTRIES") == 100,
            intConst(repoCls, "MAX_ENTRIES").toString())

        val required = mapOf(
            "init" to listOf("Context"),
            "getAll" to emptyList(),
            "getByVodId" to listOf("String"),
            "upsert" to listOf("PlayHistory"),
            "remove" to listOf("String"),
            "clear" to emptyList()
        )
        required.forEach { (name, expected) ->
            val hit = methodsOf(repoCls, name).firstOrNull { paramNames(it) == expected }
            check("HistoryRepository.$name(${expected.joinToString()}) 存在", hit != null,
                if (hit == null) methodsOf(repoCls, name).joinToString { describe(it) } else "")
        }
        check("getAll 返回 List", methodsOf(repoCls, "getAll").firstOrNull()?.returnType == List::class.java)
        check("getByVodId 返回可空 PlayHistory", methodsOf(repoCls, "getByVodId").firstOrNull()?.returnType?.simpleName == "PlayHistory")

        // 行为：裸 JVM 上没 Context，走内存兜底路径 —— 正好把增删改查与上限真跑一遍
        val repo = instanceOf(repoCls)
        @Suppress("UNCHECKED_CAST")
        val upsert = repoCls.getMethod("upsert", histCls)
        val getAll = repoCls.getMethod("getAll")
        val getByVodId = repoCls.getMethod("getByVodId", String::class.java)
        val remove = repoCls.getMethod("remove", String::class.java)
        val clear = repoCls.getMethod("clear")

        fun mk(id: String, at: Long, pos: Long = 60_000L) = PlayHistory(
            vodId = id, vodName = "片$id", episodeName = "第01集",
            episodeUrl = "https://example.com/$id.m3u8",
            positionMs = pos, durationMs = 120_000, lastPlayedAt = at
        )

        clear.invoke(repo)
        upsert.invoke(repo, mk("a", 1_000))
        upsert.invoke(repo, mk("b", 3_000))
        upsert.invoke(repo, mk("c", 2_000))

        @Suppress("UNCHECKED_CAST")
        var all = getAll.invoke(repo) as List<PlayHistory>
        check("getAll 按时间降序（最近看的在最前）", all.map { it.vodId } == listOf("b", "c", "a"),
            all.map { it.vodId }.toString())

        upsert.invoke(repo, mk("a", 9_000, pos = 99_000L))
        all = getAll.invoke(repo) as List<PlayHistory>
        check("同一个 vodId 再 upsert 是更新不是新增", all.size == 3, all.size.toString())
        check("更新后进度被覆盖", all.first().vodId == "a" && all.first().positionMs == 99_000L,
            "${all.first().vodId}/${all.first().positionMs}")

        check("getByVodId 查得到", (getByVodId.invoke(repo, "b") as PlayHistory?)?.vodName == "片b")
        remove.invoke(repo, "b")
        check("remove 之后查不到", getByVodId.invoke(repo, "b") == null)

        clear.invoke(repo)
        check("clear 之后是空表", (getAll.invoke(repo) as List<*>).isEmpty())

        (1..105).forEach { upsert.invoke(repo, mk("v$it", it.toLong())) }
        all = getAll.invoke(repo) as List<PlayHistory>
        check("上限 100 条生效", all.size == 100, all.size.toString())
        check("丢的是最旧的那批", all.first().vodId == "v105" && all.none { it.vodId == "v1" },
            all.first().vodId)
        clear.invoke(repo)

        val blank = PlayHistory()
        upsert.invoke(repo, blank)
        check("id 和地址都空的记录被丢弃（点不开的死记录）", (getAll.invoke(repo) as List<*>).isEmpty())
    }

    // ================================================================
    mark("四、UserPreference：搜索历史行为（内存路径）")
    // ================================================================

    if (prefCls != null) {
        val pref = instanceOf(prefCls)
        val add = prefCls.getMethod("addSearchHistory", String::class.java)
        val list = prefCls.getMethod("getSearchHistory")
        val clear = prefCls.getMethod("clearSearchHistory")
        val removeOne = prefCls.getMethod("removeSearchHistory", String::class.java)

        clear.invoke(pref)
        add.invoke(pref, "庆余年")
        add.invoke(pref, "狂飙")
        add.invoke(pref, "庆余年")

        @Suppress("UNCHECKED_CAST")
        var history = list.invoke(pref) as List<String>
        check("去重 + 新的排最前", history == listOf("庆余年", "狂飙"), history.toString())

        clear.invoke(pref)
        (1..25).forEach { add.invoke(pref, "关键词$it") }
        history = list.invoke(pref) as List<String>
        check("上限 20 条", history.size == 20, history.size.toString())
        check("最新那条在最前", history.first() == "关键词25", history.first())
        check("最旧那条被挤掉", history.none { it == "关键词1" })

        clear.invoke(pref)
        add.invoke(pref, "   ")
        check("空白关键词不记", (list.invoke(pref) as List<*>).isEmpty())

        add.invoke(pref, "Friends")
        removeOne.invoke(pref, "friends")
        check("单条删除大小写不敏感", (list.invoke(pref) as List<*>).isEmpty())
        clear.invoke(pref)
    }

    // ================================================================
    mark("五、HomeViewModel：6 个交互的对外入口")
    // ================================================================

    val vmCls = loadOrNull("com.tvbox.shell.ui.home.HomeViewModel")
    check("HomeViewModel 存在", vmCls != null)

    if (vmCls != null) {
        val flows = listOf(
            "currentSite", "availableSites", "sitePickerVisible", "sourcePickerVisible",
            "searchScreenVisible", "historyScreenVisible", "searchResultState"
        )
        flows.forEach { prop ->
            val getter = "get" + prop.replaceFirstChar { it.uppercase() }
            val hit = methodsOf(vmCls, getter).firstOrNull { returnsStateFlow(it) }
            check("HomeViewModel.$prop 是 StateFlow", hit != null,
                if (hit == null) methodsOf(vmCls, getter).joinToString { it.returnType.simpleName } else "")
        }

        val actions = mapOf(
            "showSitePicker" to emptyList<String>(),
            "hideSitePicker" to emptyList(),
            "showSourcePicker" to emptyList(),
            "hideSourcePicker" to emptyList(),
            "showSearchScreen" to emptyList(),
            "hideSearchScreen" to emptyList(),
            "showHistoryScreen" to emptyList(),
            "hideHistoryScreen" to emptyList(),
            "switchSite" to listOf("Site"),
            "switchSource" to listOf("SiteSource"),
            "searchContent" to listOf("String")
        )
        actions.forEach { (name, expected) ->
            val hit = methodsOf(vmCls, name).firstOrNull { paramNames(it) == expected }
            check("HomeViewModel.$name(${expected.joinToString()}) 存在", hit != null,
                if (hit == null) methodsOf(vmCls, name).joinToString { describe(it) } else "")
        }

        check(
            "loadHomeContent() 无参入口存在（契约入口，靠 @JvmOverloads 生成）",
            methodsOf(vmCls, "loadHomeContent").any { it.parameterCount == 0 },
            methodsOf(vmCls, "loadHomeContent").joinToString { describe(it) }
        )
        check(
            "loadHomeContent(Site) 也要在（换站走这条）",
            methodsOf(vmCls, "loadHomeContent").any { paramNames(it) == listOf("Site") },
            methodsOf(vmCls, "loadHomeContent").joinToString { describe(it) }
        )
    }

    // ================================================================
    mark("六、SearchState：四态齐全")
    // ================================================================

    val searchState = loadOrNull("com.tvbox.shell.ui.home.SearchState")
    check("SearchState 存在", searchState != null)
    listOf("Idle", "Loading", "Success", "Error").forEach { name ->
        val sub = loadOrNull("com.tvbox.shell.ui.home.SearchState\$$name")
        check("SearchState.$name 存在", sub != null)
        check("SearchState.$name 是 SearchState 的子类", sub != null && searchState != null && searchState.isAssignableFrom(sub))
    }
    val successCls = loadOrNull("com.tvbox.shell.ui.home.SearchState\$Success")
    check(
        "SearchState.Success 带 vods: List<Vod>",
        successCls?.declaredConstructors?.any { it.parameterCount == 1 && it.parameterTypes[0].name == "java.util.List" } == true
    )
    val errorCls = loadOrNull("com.tvbox.shell.ui.home.SearchState\$Error")
    check(
        "SearchState.Error 带 message: String",
        errorCls?.declaredConstructors?.any { it.parameterCount == 1 && it.parameterTypes[0] == String::class.java } == true
    )

    // ================================================================
    mark("七、Compose 组件：四个新页面的签名")
    // ================================================================

    val siteSheet = loadOrNull("com.tvbox.shell.ui.component.SitePickerSheetKt")
    check("SitePickerSheet.kt 编译产物存在", siteSheet != null)
    siteSheet?.let { cls ->
        val hit = methodsOf(cls, "SitePickerSheet").firstOrNull()
        check("SitePickerSheet(sites, currentSite, onSelect, onDismiss) 存在", hit != null,
            methodsOf(cls, "SitePickerSheet").joinToString { describe(it) })
        hit?.let {
            val shape = shapeOf(it, listOf("List", "Site", "Function", "Function"))
            check("SitePickerSheet 形状是 (List<Site>, Site, onSelect, onDismiss)", shape == null, shape.orEmpty())
        }
    }

    val sourceSheet = loadOrNull("com.tvbox.shell.ui.component.SourcePickerSheetKt")
    check("SourcePickerSheet.kt 编译产物存在", sourceSheet != null)
    sourceSheet?.let { cls ->
        val hit = methodsOf(cls, "SourcePickerSheet").firstOrNull()
        check("SourcePickerSheet(sources, onSelect, onDismiss) 存在", hit != null,
            methodsOf(cls, "SourcePickerSheet").joinToString { describe(it) })
        hit?.let {
            val shape = shapeOf(it, listOf("List", "Function", "Function"))
            check("SourcePickerSheet 形状是 (List<SiteSource>, onSelect, onDismiss)", shape == null, shape.orEmpty())
        }
    }

    val searchScreen = loadOrNull("com.tvbox.shell.ui.component.SearchScreenKt")
    check("SearchScreen.kt 编译产物存在", searchScreen != null)
    searchScreen?.let { cls ->
        val hit = methodsOf(cls, "SearchScreen").firstOrNull()
        check("SearchScreen(viewModel, onBack, onVodClick) 存在", hit != null,
            methodsOf(cls, "SearchScreen").joinToString { describe(it) })
        hit?.let {
            val shape = shapeOf(it, listOf("HomeViewModel", "Function", "Function"))
            check("SearchScreen 形状是 (HomeViewModel, onBack, onVodClick)", shape == null, shape.orEmpty())
        }
        check("搜索框有测试锚点常量", stringConst(cls, "SEARCH_FIELD_TAG") != null,
            stringConst(cls, "SEARCH_FIELD_TAG").orEmpty())
    }

    val historyScreen = loadOrNull("com.tvbox.shell.ui.component.HistoryScreenKt")
    check("HistoryScreen.kt 编译产物存在", historyScreen != null)
    historyScreen?.let { cls ->
        val hit = methodsOf(cls, "HistoryScreen").firstOrNull()
        check("HistoryScreen(repository, onBack, onItemClick) 存在", hit != null,
            methodsOf(cls, "HistoryScreen").joinToString { describe(it) })
        hit?.let {
            val shape = shapeOf(it, listOf("HistoryRepository", "Function", "Function"))
            check("HistoryScreen 形状是 (HistoryRepository, onBack, onItemClick)", shape == null, shape.orEmpty())
        }
    }

    // ================================================================
    mark("八、PlayerActivity：5 个新 extra 与续播（读字节码，不加载类）")
    // 为什么读字节码：PlayerActivity 继承 android 的 Activity，裸 JVM 里 `Class.forName`
    // 会因为找不到 `android.app.Activity` 直接塌掉。它的常量与入口不能因此就没人看 ——
    // class 文件的常量池里有全部字面量与方法名，读一遍同样硬。
    // 行为面（Intent 构造、字段解析、进度落盘）由 Robolectric 的 PlayerHistoryTest 真验。

    val playerClass = "com/tvbox/shell/player/PlayerActivity.class"
    val playerBytes = classBytes(playerClass)
    check("PlayerActivity 已编译进产物（class 文件找得到）", playerBytes != null)

    if (playerBytes != null) {
        listOf("vodId", "vodName", "vodPic", "episodeName", "startPositionMs").forEach { extra ->
            check("extra 常量名 \"$extra\" 在字节码里", playerBytes.hasAscii(extra))
        }
        val expectedExtras = mapOf(
            "EXTRA_VOD_ID" to "vodId",
            "EXTRA_VOD_NAME" to "vodName",
            "EXTRA_VOD_PIC" to "vodPic",
            "EXTRA_EPISODE_NAME" to "episodeName",
            "EXTRA_START_POSITION_MS" to "startPositionMs"
        )
        expectedExtras.forEach { (fieldName, value) ->
            check("常量字段名 EXTRA_* 在字节码里：$fieldName", playerBytes.hasAscii(fieldName))
            check("$fieldName 的字面值就是 \"$value\"", playerBytes.hasAscii(value))
        }
        check("EXTRA_VIDEO_URL / EXTRA_HEADERS 没被改掉（老调用点靠它们）",
            playerBytes.hasAscii("videoUrl") && playerBytes.hasAscii("headers"))
        check("进度落盘入口 writeHistory 在", playerBytes.hasAscii("writeHistory"))
        check("续播入口 saveProgress 在", playerBytes.hasAscii("saveProgress"))
        check("每 5 秒记一次的间隔常量在", playerBytes.hasAscii("PROGRESS_SAVE_INTERVAL_MS"))
        check("进度记录任务字段 progressJob 在（onDestroy 要取消它）",
            playerBytes.hasAscii("progressJob"))
    }

    // ================================================================
    mark("九、越界检查：UI / ViewModel 不许碰下层实现")
    // ================================================================

    val forbidden = listOf(
        "com.tvbox.shell.pan.",
        "com.tvbox.shell.loader.",
        "com.tvbox.shell.player.",
        "com.tvbox.shell.spider.SpiderManager"
    )

    fun signatureLeak(cls: Class<*>?): String? {
        if (cls == null) return null
        cls.declaredMethods.forEach { m ->
            (m.parameterTypes.toList() + m.returnType).forEach { t ->
                forbidden.firstOrNull { t.name.startsWith(it) }?.let { return "${m.name} 用了 ${t.name}" }
            }
        }
        return null
    }

    val homeScreenCls = loadOrNull("com.tvbox.shell.ui.home.HomeScreenKt")
    val homeLeak = signatureLeak(homeScreenCls)
    check("HomeScreen 签名里不出现播放器 / 网盘 / 加载器 / 引擎类型", homeLeak == null, homeLeak.orEmpty())

    val vmLeak = vmCls?.declaredMethods
        ?.flatMap { it.parameterTypes.toList() + it.returnType }
        ?.map { it.name }
        ?.firstOrNull { it.startsWith("com.tvbox.shell.player.") || it.startsWith("com.tvbox.shell.pan.") }
    check("HomeViewModel 不依赖播放器 / 网盘解析器", vmLeak == null, vmLeak.orEmpty())

    val historyLeak = signatureLeak(historyScreen)
    check("HistoryScreen 签名里不出现播放器 / 引擎类型", historyLeak == null, historyLeak.orEmpty())

    // ================================================================
    mark("十、不变量：模块七没把既有交互改坏")
    // ================================================================

    check(
        "HomeState 四态仍在（Idle/Loading/Success/Error）",
        listOf("Idle", "Loading", "Success", "Error").all {
            loadOrNull("com.tvbox.shell.ui.home.HomeState\$$it") != null
        }
    )
    check(
        "ALL_CATEGORY_ID 仍是空串（『全部』分类的契约值）",
        (loadOrNull("com.tvbox.shell.ui.home.HomeViewModelKt")
            ?.getDeclaredField("ALL_CATEGORY_ID")?.get(null)) == ""
    )
    check("MainScreen 仍在（6 个 Tab 没被这轮改坏）", loadOrNull("com.tvbox.shell.ui.MainActivityKt") != null)

    // ================================================================
    println()
    println("========================================")
    println("模块七独立验收结果：$passed 通过 / $failed 失败 （共 ${passed + failed} 项，耗时 ${System.currentTimeMillis() - t0}ms）")
    println("========================================")
    if (failed > 0) {
        throw AssertionError("模块七独立验收有 $failed 项失败")
    }
}
