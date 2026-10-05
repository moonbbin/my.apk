package com.tvbox.shell.player

import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch

/**
 * 播放页的 ViewModel：把 ExoPlayer 的状态翻译成 UI 能直接订阅的 Flow。
 *
 * 职责：
 * - [attach] 时挂 Player.Listener + 开进度轮询（500ms 一次）；
 * - [detach] 时全拆掉（Activity.onDestroy 调它，顺序在 player.release 之前）；
 * - 播放错误翻译成**人话**（[playbackError]），UI 直接上屏。
 *
 * 进度轮询而不是 Listener：Media3 没有"position 变化"回调，
 * 500ms 轮询是这块的标准做法。
 */
class PlayerViewModel : ViewModel() {

    private val _isPlaying = MutableStateFlow(false)
    val isPlaying: StateFlow<Boolean> = _isPlaying.asStateFlow()

    private val _duration = MutableStateFlow(0L)
    val duration: StateFlow<Long> = _duration.asStateFlow()

    private val _currentPosition = MutableStateFlow(0L)
    val currentPosition: StateFlow<Long> = _currentPosition.asStateFlow()

    private val _isBuffering = MutableStateFlow(false)
    val isBuffering: StateFlow<Boolean> = _isBuffering.asStateFlow()

    private val _playbackError = MutableStateFlow<String?>(null)

    /** 人话错误，UI 直接上屏；null = 没错。 */
    val playbackError: StateFlow<String?> = _playbackError.asStateFlow()

    private var player: Player? = null
    private var pollJob: Job? = null

    private val listener = object : Player.Listener {
        override fun onIsPlayingChanged(isPlaying: Boolean) {
            _isPlaying.value = isPlaying
        }

        override fun onPlaybackStateChanged(playbackState: Int) {
            _isBuffering.value = playbackState == Player.STATE_BUFFERING
            if (playbackState == Player.STATE_READY) {
                _duration.value = player?.duration?.takeIf { it > 0 } ?: 0L
            }
        }

        override fun onPlayerError(error: PlaybackException) {
            val message = humanMessage(error)
            Log.e(TAG, "播放错误：$message（${error.errorCodeName}）")
            _playbackError.value = message
        }
    }

    /** 接管一个播放器（Activity.onCreate 调一次）。 */
    fun attach(p: Player) {
        detach()
        player = p
        p.addListener(listener)
        _isPlaying.value = p.isPlaying
        pollJob = viewModelScope.launch {
            while (isActive) {
                delay(POLL_MS)
                val pl = player ?: break
                _currentPosition.value = runCatching { pl.currentPosition }.getOrDefault(0L)
                val d = runCatching { pl.duration }.getOrDefault(0L)
                if (d > 0) _duration.value = d
            }
        }
    }

    /** 与播放器解绑（Activity.onDestroy 调，release 之前）。 */
    fun detach() {
        pollJob?.cancel()
        pollJob = null
        player?.removeListener(listener)
        player = null
    }

    /** 播放/暂停切换。 */
    fun togglePlayPause() {
        val p = player ?: return
        if (p.isPlaying) p.pause() else p.play()
    }

    /** 拖动中：只改 UI 数字，不真 seek（手指抬起才 seek，避免拖动时疯狂寻址）。 */
    fun scrubTo(positionMs: Long) {
        _currentPosition.value = positionMs.coerceAtLeast(0L)
    }

    /** 拖动结束：真 seek。 */
    fun endScrub(positionMs: Long) {
        runCatching { player?.seekTo(positionMs.coerceAtLeast(0L)) }
    }

    /** 播放错误 → 人话。 */
    private fun humanMessage(error: PlaybackException): String {
        return when (error.errorCode) {
            PlaybackException.ERROR_CODE_PARSING_CONTAINER_UNSUPPORTED,
            PlaybackException.ERROR_CODE_PARSING_MANIFEST_UNSUPPORTED ->
                "视频格式不支持或地址无效，换个源或检查播放地址后再试"
            PlaybackException.ERROR_CODE_IO_NETWORK_CONNECTION_FAILED,
            PlaybackException.ERROR_CODE_IO_NETWORK_CONNECTION_TIMEOUT ->
                "网络连接失败，检查网络后重试"
            PlaybackException.ERROR_CODE_IO_FILE_NOT_FOUND,
            PlaybackException.ERROR_CODE_IO_BAD_HTTP_STATUS ->
                "播放地址已失效，换个源再试"
            PlaybackException.ERROR_CODE_DRM_CONTENT_ERROR,
            PlaybackException.ERROR_CODE_DRM_LICENSE_ACQUISITION_FAILED ->
                "该视频有版权保护，无法播放"
            else -> "播放出错（${error.errorCodeName}），换个源再试"
        }
    }

    private companion object {
        const val TAG = "PlayerVM"
        const val POLL_MS = 500L
    }
}
