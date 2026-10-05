package com.tvbox.shell.player

import android.content.Context
import android.net.Uri
import android.util.Log
import android.widget.VideoView
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch

/**
 * 系统播放器内核（需求4"切换播放器"的第二个选项）。
 *
 * 用框架自带的 [VideoView] 实现 [PlayerUiState]，不引入新依赖。
 * 能力边界（实话实说）：
 * - 能播：m3u8（HLS）/ mp4 等系统支持的格式，headers 透过 setVideoURI 传；
 * - 不如 ExoPlayer 的地方：无精细缓冲状态、seek 精度差一截、疑难格式兼容性弱。
 * 默认还是 ExoPlayer，这个内核是给"Exo 播不了的怪格式换条路试试"准备的。
 */
class SystemPlayerUiState(
    context: Context,
    private val scope: CoroutineScope
) : PlayerUiState {

    /** 渲染视图，Activity 用 AndroidView 把它嵌进 Compose。 */
    val videoView: VideoView = VideoView(context)

    private val _isPlaying = MutableStateFlow(false)
    override val isPlaying: StateFlow<Boolean> = _isPlaying.asStateFlow()

    private val _duration = MutableStateFlow(0L)
    override val duration: StateFlow<Long> = _duration.asStateFlow()

    private val _position = MutableStateFlow(0L)
    override val position: StateFlow<Long> = _position.asStateFlow()

    private val _buffering = MutableStateFlow(false)
    override val buffering: StateFlow<Boolean> = _buffering.asStateFlow()

    private val _errorMessage = MutableStateFlow<String?>(null)
    override val errorMessage: StateFlow<String?> = _errorMessage.asStateFlow()

    private var pollJob: Job? = null

    /** prepare 之前记下的续播起点，prepared 后一次性 seek。 */
    private var pendingSeekMs: Long = 0L

    /** 起播。只调一次。 */
    fun setSource(url: String, headers: Map<String, String>, autoPlay: Boolean) {
        _buffering.value = true
        _errorMessage.value = null
        videoView.setOnPreparedListener { mp ->
            _duration.value = runCatching { mp.duration }.getOrDefault(0).toLong()
                .takeIf { it > 0 } ?: 0L
            _buffering.value = false
            if (pendingSeekMs > 0) {
                runCatching { videoView.seekTo(pendingSeekMs.toInt()) }
                Log.d(TAG, "系统播放器续播：seekTo($pendingSeekMs)")
                pendingSeekMs = 0L
            }
            Log.d(TAG, "系统播放器 prepared，时长=${_duration.value}")
            if (autoPlay) {
                videoView.start()
                _isPlaying.value = true
            }
            startPolling()
        }
        videoView.setOnCompletionListener {
            _isPlaying.value = false
        }
        videoView.setOnErrorListener { _, what, extra ->
            Log.e(TAG, "系统播放器出错：what=$what extra=$extra")
            _buffering.value = false
            _errorMessage.value = "系统播放器播不了这个地址（what=$what），可切回 ExoPlayer 再试"
            true
        }
        videoView.setVideoURI(
            Uri.parse(url),
            if (headers.isEmpty()) null else HashMap(headers)
        )
    }

    /** 续播起点（setSource 之前调，prepared 后自动 seek）。 */
    fun seekToOnPrepared(positionMs: Long) {
        pendingSeekMs = positionMs.coerceAtLeast(0L)
    }

    override fun togglePlayPause() {
        if (videoView.isPlaying) {
            videoView.pause()
            _isPlaying.value = false
        } else {
            videoView.start()
            _isPlaying.value = true
        }
    }

    override fun scrubTo(positionMs: Long) {
        _position.value = positionMs.coerceAtLeast(0L)
    }

    override fun endScrub(positionMs: Long) {
        runCatching { videoView.seekTo(positionMs.coerceAtLeast(0L).toInt()) }
    }

    override fun release() {
        pollJob?.cancel()
        pollJob = null
        runCatching { videoView.stopPlayback() }
    }

    private fun startPolling() {
        pollJob?.cancel()
        pollJob = scope.launch {
            while (isActive) {
                delay(POLL_MS)
                _position.value = runCatching { videoView.currentPosition }.getOrDefault(0).toLong()
                val d = runCatching { videoView.duration }.getOrDefault(0).toLong()
                if (d > 0) _duration.value = d
                _isPlaying.value = videoView.isPlaying
            }
        }
    }

    private companion object {
        const val TAG = "SystemPlayer"
        const val POLL_MS = 500L
    }
}
