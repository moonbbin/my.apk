package com.tvbox.shell.config

import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.tvbox.shell.model.PlayHistory
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.annotation.Config

/**
 * 模块七（交互增强）持久化层的护栏测试。
 *
 * 这里钉的都是**验收标准直接依赖**的行为，不是"跑一遍不报错"：
 * - 搜索历史：去重、新的排最前、上限 20（验收标准 3 的"历史 Chip"就靠它）；
 * - 上次选中的站点：存得下、读得回（验收标准 5 的"杀 App 重开还在上次那个站"靠它）；
 * - 观看历史：降序、上限 100、upsert 不产生重复条目（验收标准 4 靠它）。
 */
@RunWith(AndroidJUnit4::class)
@Config(sdk = [34])
class PreferenceAndHistoryTest {

    private val app = ApplicationProvider.getApplicationContext<android.app.Application>()

    @Before
    fun setUp() {
        UserPreference.init(app)
        UserPreference.clearSearchHistory()
        HistoryRepository.init(app)
        HistoryRepository.clear()
    }

    // ==================================================================
    // UserPreference
    // ==================================================================

    @Test
    fun `搜索历史 - 新的排最前且去重`() {
        UserPreference.addSearchHistory("庆余年")
        UserPreference.addSearchHistory("狂飙")
        UserPreference.addSearchHistory("庆余年")

        val history = UserPreference.getSearchHistory()
        assertEquals("重复的那条要挪到最前，不该出现两条", listOf("庆余年", "狂飙"), history)
    }

    @Test
    fun `搜索历史 - 超过 20 条丢最旧的`() {
        (1..25).forEach { UserPreference.addSearchHistory("关键词$it") }

        val history = UserPreference.getSearchHistory()
        assertEquals("上限是 ${UserPreference.MAX_SEARCH_HISTORY}", 20, history.size)
        assertEquals("最新那条必须在最前", "关键词25", history.first())
        assertTrue("最旧那条应该被挤掉了", history.none { it == "关键词1" })
    }

    @Test
    fun `搜索历史 - 空白关键词不记，单条删除按大小写不敏感匹配`() {
        UserPreference.addSearchHistory("   ")
        assertTrue("纯空白不该产生记录", UserPreference.getSearchHistory().isEmpty())

        UserPreference.addSearchHistory("Friends")
        UserPreference.removeSearchHistory("friends")
        assertTrue("大小写不同也该删掉同一条", UserPreference.getSearchHistory().isEmpty())
    }

    @Test
    fun `搜索历史 - 清空`() {
        UserPreference.addSearchHistory("a")
        UserPreference.clearSearchHistory()
        assertTrue(UserPreference.getSearchHistory().isEmpty())
    }

    @Test
    fun `上次选中的站点与配置源 - 存得下读得回`() {
        UserPreference.setLastSelectedApi("csp_Alpha")
        UserPreference.setLastSelectedSourceId("src-1")

        assertEquals("csp_Alpha", UserPreference.getLastSelectedApi())
        assertEquals("src-1", UserPreference.getLastSelectedSourceId())
    }

    @Test
    fun `上次选中的站点 - 空串不覆盖已有值`() {
        UserPreference.setLastSelectedApi("csp_Beta")
        UserPreference.setLastSelectedApi("   ")
        assertEquals("空 api 是脏数据，不该把有效值冲掉", "csp_Beta", UserPreference.getLastSelectedApi())
    }

    // ==================================================================
    // PlayHistory
    // ==================================================================

    @Test
    fun `进度百分比 - 正常算出比例，越界夹到 0到1`() {
        assertEquals(0.5f, PlayHistory(positionMs = 90_000, durationMs = 180_000).progressPercent, 0.0001f)
        assertEquals(
            "超出总时长要夹到 1，不能给 1.2",
            1f,
            PlayHistory(positionMs = 200_000, durationMs = 180_000).progressPercent,
            0.0001f
        )
    }

    @Test
    fun `进度百分比 - 时长未知给 0 而不是 NaN`() {
        val value = PlayHistory(positionMs = 30_000, durationMs = 0L).progressPercent
        assertEquals(0f, value, 0.0001f)
        assertTrue("NaN 会让进度条直接崩", !value.isNaN())
    }

    // ==================================================================
    // HistoryRepository
    // ==================================================================

    private fun history(
        vodId: String,
        name: String = "片$vodId",
        at: Long = System.currentTimeMillis() + vodId.hashCode().toLong()
    ) = PlayHistory(
        vodId = vodId,
        vodName = name,
        vodPic = "https://example.com/$vodId.jpg",
        episodeName = "第01集",
        episodeUrl = "https://example.com/$vodId.m3u8",
        positionMs = 60_000,
        durationMs = 120_000,
        lastPlayedAt = at
    )

    @Test
    fun `观看历史 - upsert 新增并按时间降序`() {
        HistoryRepository.upsert(history("old", at = 1_000))
        HistoryRepository.upsert(history("new", at = 9_000))
        HistoryRepository.upsert(history("mid", at = 5_000))

        val all = HistoryRepository.getAll()
        assertEquals("最近看的必须在最前", listOf("new", "mid", "old"), all.map { it.vodId })
    }

    @Test
    fun `观看历史 - 同一个 vodId 再 upsert 是更新不是新增`() {
        HistoryRepository.upsert(history("v1", at = 1_000))
        HistoryRepository.upsert(history("v1", at = 2_000).copy(positionMs = 99_000))

        val all = HistoryRepository.getAll()
        assertEquals("同一条片子只该留一条记录", 1, all.size)
        assertEquals("进度要被新的覆盖", 99_000L, all[0].positionMs)
    }

    @Test
    fun `观看历史 - 取单条、删单条、清空`() {
        HistoryRepository.upsert(history("v1", at = 1_000))
        HistoryRepository.upsert(history("v2", at = 2_000))

        assertEquals("片v1", HistoryRepository.getByVodId("v1")?.vodName)

        HistoryRepository.remove("v1")
        assertNull("删掉的就不该再查得到", HistoryRepository.getByVodId("v1"))
        assertEquals(1, HistoryRepository.getAll().size)

        HistoryRepository.clear()
        assertTrue(HistoryRepository.getAll().isEmpty())
    }

    @Test
    fun `观看历史 - 上限 100 条，丢最旧的`() {
        (1..105).forEach { HistoryRepository.upsert(history("v$it", at = it.toLong())) }

        val all = HistoryRepository.getAll()
        assertEquals("上限是 ${HistoryRepository.MAX_ENTRIES}", HistoryRepository.MAX_ENTRIES, all.size)
        assertEquals("最新的那条要在最前", "v105", all.first().vodId)
        assertTrue("最旧那几条应该被丢掉", all.none { it.vodId == "v1" })
    }

    @Test
    fun `观看历史 - 落盘之后能重新读回来（跨 init，等价于杀进程重开）`() {
        HistoryRepository.upsert(history("persist-1", name = "持久化片子", at = 7_000))

        // 重新 init = 重新从 SharedPreferences 读一遍（模拟进程重启后的读路径）
        HistoryRepository.init(app)

        val row = HistoryRepository.getByVodId("persist-1")
        assertEquals("重启后历史必须在", "持久化片子", row?.vodName)
        assertEquals(60_000L, row?.positionMs)
    }

    @Test
    fun `观看历史 - 没有任何有效字段的条目被丢弃`() {
        HistoryRepository.upsert(PlayHistory())
        assertTrue("id 和地址都空的记录点不开，不该进列表", HistoryRepository.getAll().isEmpty())
    }
}
