package com.tvbox.shell.player

import kotlinx.coroutines.flow.StateFlow

/**
 * 播放器 UI 状态抽象（需求4：切换播放器内核）。
 *
 * 自绘控制条（ControlBar）只认这个接口，不认具体内核：
 * - ExoPlayer 内核 → [ExoPlayerUiState]（包一层 [PlayerViewModel]）；
 * - 系统播放器内核 → [SystemPlayerUiState]（包一层 VideoView）。
 *
 * 换内核 = 换实现类，UI 一行不动。
 */
interface PlayerUiState {

    val isPlaying: StateFlow<Boolean>

    /** 总时长（毫秒，未知时 0）。 */
    val duration: StateFlow<Long>

    /** 当前位置（毫秒）。 */
    val position: StateFlow<Long>

    /** 是否正在缓冲。 */
    val buffering: StateFlow<Boolean>

    /** 人话错误，null = 没错。 */
    val errorMessage: StateFlow<String?>

    /** 播放/暂停切换。 */
    fun togglePlayPause()

    /** 拖动中：只改 UI 数字。 */
    fun scrubTo(positionMs: Long)

    /** 拖动结束：真 seek。 */
    fun endScrub(positionMs: Long)

    /** 释放底层资源（Activity.onDestroy 调）。 */
    fun release()
}

/** ExoPlayer 内核：直接委托给既有的 [PlayerViewModel]。 */
class ExoPlayerUiState(
    private val vm: PlayerViewModel
) : PlayerUiState {
    override val isPlaying: StateFlow<Boolean> = vm.isPlaying
    override val duration: StateFlow<Long> = vm.duration
    override val position: StateFlow<Long> = vm.currentPosition
    override val buffering: StateFlow<Boolean> = vm.isBuffering
    override val errorMessage: StateFlow<String?> = vm.playbackError

    override fun togglePlayPause() = vm.togglePlayPause()
    override fun scrubTo(positionMs: Long) = vm.scrubTo(positionMs)
    override fun endScrub(positionMs: Long) = vm.endScrub(positionMs)
    override fun release() = vm.detach()
}
