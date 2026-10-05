package com.tvbox.shell.player

import android.content.Context
import android.content.Intent
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.tvbox.shell.config.HistoryRepository
import com.tvbox.shell.config.UserPreference
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.robolectric.shadows.ShadowLog

/**
 * 模块七（观看历史）在播放器这一侧的护栏测试。
 *
 * 钉的是整条链：**Intent 带字段 → Activity 读进字段 → 写入历史 → 从仓库读回来**，
 * 不是"调个函数没抛异常"。历史页能不能显示片名、"续播"能不能跳到上次的位置，
 * 全看这条链有没有断。
 *
 * 为什么不直接靠"播一会儿再看进度"：Robolectric 里喂不进一段合法媒体，
 * `player.currentPosition` 永远是 0，那条路在单测里根本走不通。
 * 所以产品代码把写入抽成了 `writeHistory(position, duration, reason)`
 * （[PlayerActivity.writeHistory]，internal 可见），既能被这里直接调，又不改变真机行为
 * —— 真机上 [PlayerActivity] 内部照旧从播放器读位置再调它。
 *
 * 用 [TestablePlayerActivity]（不挂 Compose）是因为 Compose 的界面调度器是静态单例：
 * 在没有 Compose 测试规则的用例里先 `setContent`，同一个 JVM 里后面的 Compose 测试
 * 会永远等不到空闲帧。
 */
@RunWith(AndroidJUnit4::class)
@Config(sdk = [34])
class PlayerHistoryTest {

    private lateinit var context: Context

    private val servers = mutableListOf<TestHttpServer>()

    @Before
    fun setUp() {
        context = ApplicationProvider.getApplicationContext()
        UserPreference.init(context)
        HistoryRepository.init(context)
        HistoryRepository.clear()
        ShadowLog.clear()
    }

    @After
    fun tearDown() {
        servers.forEach { runCatching { it.close() } }
        servers.clear()
        HistoryRepository.clear()
    }

    // ==================================================================
    // 夹具
    // ==================================================================

    private fun serve(body: ByteArray = FAKE_BODY): TestHttpServer {
        val server = TestHttpServer(body)
        server.start()
        servers += server
        return server
    }

    /** 带全模块七字段的 Intent（等于详情页点一集时构造的那一个）。 */
    private fun historyIntent(url: String, startPositionMs: Long = 0L): Intent =
        PlayerActivity.intent(
            context = context,
            videoUrl = url,
            headers = null,
            vodId = VOD_ID,
            vodName = VOD_NAME,
            vodPic = VOD_PIC,
            episodeName = EPISODE_NAME,
            startPositionMs = startPositionMs
        )

    private fun launch(intent: Intent): org.robolectric.android.controller.ActivityController<TestablePlayerActivity> =
        Robolectric.buildActivity(TestablePlayerActivity::class.java, intent).setup()

    private fun fieldOf(activity: PlayerActivity, name: String): Any? {
        val field = PlayerActivity::class.java.getDeclaredField(name)
        field.isAccessible = true
        return field.get(activity)
    }

    // ==================================================================
    // Intent → 字段
    // ==================================================================

    @Test
    fun `Intent 里的片子信息被读进字段，并记下"上次播放的是哪部"`() {
        val url = serve().url
        val controller = launch(historyIntent(url))
        try {
            val activity = controller.get()

            assertEquals(VOD_ID, fieldOf(activity, "vodId"))
            assertEquals(VOD_NAME, fieldOf(activity, "vodName"))
            assertEquals(VOD_PIC, fieldOf(activity, "vodPic"))
            assertEquals(EPISODE_NAME, fieldOf(activity, "episodeName"))
            assertEquals("播放地址要落成 episodeUrl 的来源", url, fieldOf(activity, "videoUrl"))
            assertEquals(
                "UserPreference 那条钩子也要写上",
                VOD_ID,
                UserPreference.getLastPlayVodId()
            )
        } finally {
            controller.destroy()
        }
    }

    @Test
    fun `Intent 没带片子信息时也不崩 —— 老调用点照样能进播放页`() {
        val url = serve().url
        val controller = launch(PlayerActivity.intent(context, url))
        try {
            val activity = controller.get()
            assertEquals("", fieldOf(activity, "vodId"))
            assertEquals("", fieldOf(activity, "episodeName"))
            assertEquals(0L, fieldOf(activity, "startPositionMs"))
        } finally {
            controller.destroy()
        }
    }

    // ==================================================================
    // 续播
    // ==================================================================

    @Test
    fun `续播 - Intent 带了起点会 seekTo 并留下日志`() {
        val url = serve().url
        val controller = launch(historyIntent(url, startPositionMs = 90_000L))
        try {
            assertEquals(
                "起点要读进字段",
                90_000L,
                fieldOf(controller.get(), "startPositionMs")
            )
            val logs = ShadowLog.getLogsForTag("PlayerActivity").map { it.msg.orEmpty() }
            assertTrue(
                "没看到续播的日志，说明 seekTo 那一步没跑：$logs",
                logs.any { it.contains("续播") }
            )
        } finally {
            controller.destroy()
        }
    }

    // ==================================================================
    // 写历史
    // ==================================================================

    @Test
    fun `写历史 - 位置与时长落进仓库，键用 vodId`() {
        val url = serve().url
        val controller = launch(historyIntent(url))
        try {
            controller.get().writeHistory(90_000L, 180_000L, "测试")

            val row = HistoryRepository.getByVodId(VOD_ID)
            assertNotNull("历史里必须能查到这条", row)
            assertEquals(VOD_NAME, row!!.vodName)
            assertEquals(VOD_PIC, row.vodPic)
            assertEquals(EPISODE_NAME, row.episodeName)
            assertEquals("续播要用的就是它", url, row.episodeUrl)
            assertEquals(90_000L, row.positionMs)
            assertEquals(180_000L, row.durationMs)
            assertEquals(0.5f, row.progressPercent, 0.0001f)
            assertTrue("必须带时间戳，历史列表按它排序", row.lastPlayedAt > 0L)
        } finally {
            controller.destroy()
        }
    }

    @Test
    fun `写历史 - 每 5 秒写一次是更新同一条，不会堆出一堆重复记录`() {
        val url = serve().url
        val controller = launch(historyIntent(url))
        try {
            val activity = controller.get()
            activity.writeHistory(5_000L, 180_000L, "定时")
            activity.writeHistory(10_000L, 180_000L, "定时")
            activity.writeHistory(15_000L, 180_000L, "定时")

            val all = HistoryRepository.getAll()
            assertEquals("同一个 vodId 只该有一条", 1, all.size)
            assertEquals("进度要是最新那次", 15_000L, all[0].positionMs)
        } finally {
            controller.destroy()
        }
    }

    @Test
    fun `写历史 - 还没播起来（0-0）时不落记录`() {
        val url = serve().url
        val controller = launch(historyIntent(url))
        try {
            controller.get().writeHistory(0L, 0L, "onPause")
            assertTrue(
                "位置和时长都是 0 说明根本没播起来，不该在历史里堆一条『看到 00:00』",
                HistoryRepository.getAll().isEmpty()
            )
        } finally {
            controller.destroy()
        }
    }

    @Test
    fun `写历史 - 时长非法（TIME_UNSET 那种负值）收敛成 0，位置照记`() {
        val url = serve().url
        val controller = launch(historyIntent(url))
        try {
            controller.get().writeHistory(30_000L, Long.MIN_VALUE + 1, "定时")

            val row = HistoryRepository.getByVodId(VOD_ID)
            assertNotNull(row)
            assertEquals("非法时长要收敛成 0，不能让进度条拿到负数", 0L, row!!.durationMs)
            assertEquals(30_000L, row.positionMs)
        } finally {
            controller.destroy()
        }
    }

    @Test
    fun `onPause 会触发一次保存（没播起来时是空操作，不崩）`() {
        val url = serve().url
        val controller = launch(historyIntent(url))
        try {
            // 不抛异常就是本条的核心断言：onPause 里那次 saveProgress 拿不到有效位置时必须安静返回
            controller.pause()
            assertTrue(
                "Robolectric 里媒体没真播起来 → 位置是 0 → 不该落记录",
                HistoryRepository.getAll().isEmpty()
            )
        } finally {
            controller.destroy()
        }
    }

    @Test
    fun `写历史 - 只有地址的老调用点也能记（键退回地址）`() {
        val url = serve().url
        val controller = launch(PlayerActivity.intent(context, url))
        try {
            controller.get().writeHistory(12_000L, 60_000L, "定时")

            val row = HistoryRepository.getByVodId(url)
            assertNotNull("没有 vodId 时要用地址当键，至少别丢记录", row)
            assertEquals(12_000L, row!!.positionMs)
        } finally {
            controller.destroy()
        }
    }

    companion object {
        const val VOD_ID = "v-1001"
        const val VOD_NAME = "首页片一"
        const val VOD_PIC = "https://example.com/poster.jpg"
        const val EPISODE_NAME = "第03集"

        /** 假 body：Robolectric 解不了码，这里只用来把"Activity 真起来了"这件事钉死。 */
        val FAKE_BODY: ByteArray = ByteArray(4096) { (it % 251).toByte() }
    }
}
