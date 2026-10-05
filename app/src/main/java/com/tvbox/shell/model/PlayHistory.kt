package com.tvbox.shell.model

/**
 * 观看历史条目（模块七：交互增强）。
 *
 * 一条 = "某部片子的某一集，看到哪儿了"。粒度刻意做到**集**而不是**片**：
 * 电视剧按片记进度没有意义（用户要的是"从第 3 集的一半接着看"）。
 *
 * 字段全部给默认值：Gson 反序列化历史 JSON 时缺字段不会留 null，
 * 下游拿去做字符串拼接 / 算百分比也不会因为 null 崩。
 *
 * @param vodId      片子 id（采集站的 `vod_id`），同一条历史的唯一键
 * @param vodName    片名，历史列表主文案
 * @param vodPic     封面地址，历史列表左侧缩略图
 * @param episodeName 集名，如 "第03集"
 * @param episodeUrl  这一集的播放地址（续播时直接拿它喂播放器）
 * @param positionMs  已播放毫秒
 * @param durationMs  总时长毫秒；未知 / 直播为 0
 * @param lastPlayedAt 最后一次播放的时间戳（毫秒），列表按它降序
 */
data class PlayHistory(
    val vodId: String = "",
    val vodName: String = "",
    val vodPic: String = "",
    val episodeName: String = "",
    val episodeUrl: String = "",
    val positionMs: Long = 0L,
    val durationMs: Long = 0L,
    val lastPlayedAt: Long = 0L
) {

    /**
     * 观看进度 0f~1f。
     *
     * 时长未知时返回 [NO_PROGRESS]（0f）而不是 NaN —— 进度条拿到 NaN 会直接崩，
     * 而"这个源没给时长"在实际采集站里很常见。
     */
    val progressPercent: Float
        get() = if (durationMs > 0L) {
            (positionMs.toFloat() / durationMs.toFloat()).coerceIn(0f, 1f)
        } else {
            NO_PROGRESS
        }

    /** 这条历史还值不值得留在列表里（有 id 或地址就算有效记录）。 */
    fun isValid(): Boolean = vodId.isNotBlank() || episodeUrl.isNotBlank()

    companion object {
        /** 时长未知时的进度值。 */
        const val NO_PROGRESS: Float = 0f
    }
}
