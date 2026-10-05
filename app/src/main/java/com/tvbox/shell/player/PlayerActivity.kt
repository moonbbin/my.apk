package com.tvbox.shell.player

import android.content.Context
import android.content.Intent
import android.content.pm.ActivityInfo
import android.os.Bundle
import android.util.Log
import android.view.ViewGroup
import android.view.WindowManager
import androidx.activity.ComponentActivity
import androidx.activity.compose.BackHandler
import androidx.activity.compose.setContent
import androidx.activity.viewModels
import androidx.annotation.OptIn
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.systemBars
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Fullscreen
import androidx.compose.material.icons.filled.FullscreenExit
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Slider
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import androidx.lifecycle.lifecycleScope
import com.tvbox.shell.config.HistoryRepository
import com.tvbox.shell.config.UserPreference
import com.tvbox.shell.model.PlayHistory
import com.tvbox.shell.ui.settings.SettingsActivity
import androidx.media3.common.MediaItem
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.okhttp.OkHttpDataSource
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory
import androidx.media3.exoplayer.source.MediaSource
import androidx.media3.ui.AspectRatioFrameLayout
import androidx.media3.ui.PlayerView
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import okhttp3.Interceptor
import okhttp3.OkHttpClient
import okhttp3.Response
import java.util.Locale
import java.util.concurrent.TimeUnit

/**
 * 播放页（模块 1.5）。
 *
 * 四件事：
 * 1. 双内核：ExoPlayer（Media3 [ExoPlayer] + [PlayerView]，`useController = false`，
 *    控制条是下面自绘的 Compose 那条）/ 系统播放器（VideoView），
 *    由设置页的"播放器内核"决定，UI 层只认 [PlayerUiState] 接口；
 * 2. 生命周期：`onPause()` 暂停，`onDestroy()` 必须 `release()`；从后台回来时按"进去之前是否在播"决定是否续播。
 * 3. 防盗链：把 Intent 里带过来的 Headers（Referer / User-Agent / Cookie…）通过 OkHttp 拦截器
 *    注进 [OkHttpDataSource] 的每一条请求 —— 网盘 / 采集站的直链基本都要求带 Referer，否则 403。
 * 4. 弹幕：[DanmakuOverlay] 盖在视频上，开关/颜色/字号走设置页。
 *
 * 入参（Intent）：
 * - [EXTRA_VIDEO_URL]：视频直链，必填，为空直接 finish。
 * - [EXTRA_HEADERS]：`HashMap<String, String>`，可选，形如 `{"Referer": "...", "User-Agent": "..."}`。
 */
@OptIn(UnstableApi::class)
open class PlayerActivity : ComponentActivity() {

    private val viewModel: PlayerViewModel by viewModels()

    private var player: ExoPlayer? = null

    private lateinit var playerView: PlayerView

    /**
     * 当前生效的播放器 UI 状态（需求4：切换播放器内核）。
     *
     * ExoPlayer 内核 → [ExoPlayerUiState]（包 PlayerViewModel）；
     * 系统播放器内核 → [SystemPlayerUiState]（包 VideoView）。
     * 自绘控制条只认这个接口，换内核 UI 不动。
     */
    private var uiState: PlayerUiState? = null

    /** 系统内核的持有者（Exo 内核时为 null）。 */
    private var systemUiState: SystemPlayerUiState? = null

    /** 弹幕列表（需求4）：进页面时按片名拉一次，切集时不重拉（同一部片）。 */
    private val danmakuItems = mutableStateListOf<DanmakuItem>()

    /** Intent 带过来的防盗链 Headers，创建数据源时用。 */
    private var headers: Map<String, String> = emptyMap()

    private var isFullscreen by mutableStateOf(false)

    /** onPause 时记下是否在播，onResume 时决定要不要续播。 */
    private var resumeOnReturn = false

    // ============================ 模块七：观看历史 ============================

    /** 当前播放地址。抽成字段是因为"每 5 秒记一次进度"要用它（原来是 onCreate 的局部变量）。 */
    private var videoUrl: String = ""

    /** 片子 id（Intent 带进来的；没有就退回片名、再退回地址当键）。 */
    private var vodId: String = ""

    private var vodName: String = ""

    private var vodPic: String = ""

    private var episodeName: String = ""

    /** 要自动跳到的起始位置（上次看到哪儿）。<= 0 表示从头播。 */
    private var startPositionMs: Long = 0L

    /** 定时记进度的任务。onDestroy 里必须取消，否则 Activity 销毁后还在写盘。 */
    private var progressJob: Job? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val url = intent?.getStringExtra(EXTRA_VIDEO_URL).orEmpty().trim()
        headers = readHeaders(intent)
        if (url.isEmpty()) {
            Log.e(TAG, "缺少 $EXTRA_VIDEO_URL，直接结束")
            finish()
            return
        }
        videoUrl = url
        readHistoryExtras(intent)

        // 播放页常亮
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        // 需求4：播放器内核切换（设置页改，默认 ExoPlayer）
        val useSystemCore =
            UserPreference.getPlayerCore() == UserPreference.PLAYER_CORE_SYSTEM
        val ui: PlayerUiState
        val videoSurface: @Composable () -> Unit
        if (useSystemCore) {
            Log.i(TAG, "播放器内核：系统播放器（VideoView）")
            val holder = SystemPlayerUiState(this, lifecycleScope)
            if (startPositionMs > 0L) holder.seekToOnPrepared(startPositionMs)
            holder.setSource(videoUrl, headers, autoPlay = true)
            systemUiState = holder
            ui = holder
            videoSurface = { SystemVideoSurface(holder) }
        } else {
            Log.i(TAG, "播放器内核：ExoPlayer")
            playerView = createPlayerView()
            val exoPlayer = ExoPlayer.Builder(this).build()
            player = exoPlayer
            playerView.player = exoPlayer
            viewModel.attach(exoPlayer)

            exoPlayer.setMediaSource(createMediaSource(videoUrl, headers))
            exoPlayer.prepare()

            // 续播：Intent 带了 startPositionMs（>0）就跳到那儿再播。
            // 放在 prepare() 之后 —— prepare 之前 seek 会被播放器当成"还没准备好媒体"丢掉。
            if (startPositionMs > 0L) {
                runCatching { exoPlayer.seekTo(startPositionMs) }
                    .onSuccess { Log.i(TAG, "续播：seekTo($startPositionMs)") }
                    .onFailure { Log.w(TAG, "续播 seekTo 失败：${it.javaClass.simpleName}") }
            }

            exoPlayer.playWhenReady = true
            ui = ExoPlayerUiState(viewModel)
            videoSurface = { ExoVideoSurface() }
        }
        uiState = ui

        Log.i(
            TAG,
            "初始化播放：url=$videoUrl headers=${headers.keys.ifEmpty { setOf("(无)") }} " +
                "vodId=${vodId.ifEmpty { "(无)" }} episode=${episodeName.ifEmpty { "(无)" }} " +
                "start=$startPositionMs"
        )

        startProgressRecorder()

        // 需求4：弹幕。开了开关才拉；源 API 为空时拉回空表，Overlay 自己不画。
        if (UserPreference.isDanmakuEnabled()) {
            lifecycleScope.launch {
                val items = runCatching {
                    DanmakuProvider.load(vodName.ifBlank { videoUrl }, UserPreference.getDanmakuApi())
                }.getOrDefault(emptyList())
                danmakuItems.clear()
                danmakuItems.addAll(items)
                Log.i(TAG, "弹幕加载完成：${items.size} 条")
            }
        }

        setPlayerContent(videoUrl, videoSurface, ui)
    }

    /**
     * 读模块七那几个 Intent 参数。
     *
     * 全是**可选**的：老的调用点（详情页 / 网盘解析 / 测试）只传地址和 headers 也照样能进播放页，
     * 历史记录那条链只是拿到更完整的字段而已 —— 这就是为什么这批 extra 给的全是默认值，
     * 缺了不报错、不 finish。
     */
    private fun readHistoryExtras(intent: Intent?) {
        if (intent == null) return
        vodId = intent.getStringExtra(EXTRA_VOD_ID).orEmpty().trim()
        vodName = intent.getStringExtra(EXTRA_VOD_NAME).orEmpty().trim()
        vodPic = intent.getStringExtra(EXTRA_VOD_PIC).orEmpty().trim()
        episodeName = intent.getStringExtra(EXTRA_EPISODE_NAME).orEmpty().trim()
        startPositionMs = intent.getLongExtra(EXTRA_START_POSITION_MS, 0L).coerceAtLeast(0L)

        // 顺手记一下"上次播放的片子"：这就是 [UserPreference.getLastPlayVodId] 的用途
        val key = historyKey()
        if (key.isNotEmpty()) UserPreference.setLastPlayVodId(key)
    }

    /**
     * 开一个每 [PROGRESS_SAVE_INTERVAL_MS] 记一次进度的定时器。
     *
     * 为什么不用 `Player.Listener`：Media3 没有"进度变化"这种回调
     * （`onPositionDiscontinuity` 只在 seek / 换媒体时触发，正常播放不触发）。
     * 轮询是这块的标准做法，5 秒一次的写入量对 SharedPreferences 毫无压力。
     */
    private fun startProgressRecorder() {
        progressJob?.cancel()
        progressJob = lifecycleScope.launch {
            while (isActive) {
                delay(PROGRESS_SAVE_INTERVAL_MS)
                saveProgress("定时")
            }
        }
    }

    /**
     * 挂 Compose 内容。
     *
     * 抽成 `internal open` 是为了让生命周期单测能在**不启动 Compose 运行时**的前提下跑：
     * Compose 的界面调度器是个静态单例、绑死在首次初始化时的 Looper 上，
     * 在同一个 JVM 里、其它 Compose 测试之前初始化它，会让那些测试永远等不到空闲帧。
     * 产品代码行为不变，这条缝只给单测用。
     */
    internal open fun setPlayerContent(
        videoUrl: String,
        videoSurface: @Composable () -> Unit,
        ui: PlayerUiState
    ) {
        setContent {
            MaterialTheme {
                PlayerScreen(
                    videoSurface = videoSurface,
                    ui = ui,
                    title = titleOf(videoUrl),
                    isFullscreen = isFullscreen,
                    danmakuItems = danmakuItems,
                    onBack = { onBackPressedDispatcher.onBackPressed() },
                    onToggleFullscreen = { toggleFullscreen() },
                    onOpenSettings = { startActivity(SettingsActivity.intent(this)) }
                )
            }
        }
    }

    /** ExoPlayer 内核的渲染面。 */
    @Composable
    private fun ExoVideoSurface() {
        AndroidView(
            modifier = Modifier.fillMaxSize(),
            factory = { context ->
                // Compose 重建视图时先跟旧父容器解绑，否则 addView 会抛 "already has a parent"
                (playerView.parent as? ViewGroup)?.removeView(playerView)
                if (playerView.context !== context) {
                    Log.w("PlayerActivity", "PlayerView context 与 Compose 不一致，沿用原 context")
                }
                playerView
            }
        )
    }

    /** 系统播放器内核的渲染面。 */
    @Composable
    private fun SystemVideoSurface(holder: SystemPlayerUiState) {
        AndroidView(
            modifier = Modifier.fillMaxSize(),
            factory = { holder.videoView }
        )
    }

    // ============================ 生命周期 ============================

    override fun onPause() {
        super.onPause()
        // 先存再暂停：用户直接按 Home / 杀进程走人时，这是唯一一次落盘机会
        saveProgress("onPause")
        val ui = uiState
        resumeOnReturn = ui?.isPlaying?.value == true
        if (resumeOnReturn) ui?.togglePlayPause()
        Log.d(TAG, "onPause → pause()")
    }

    override fun onResume() {
        super.onResume()
        val ui = uiState
        if (resumeOnReturn && ui?.isPlaying?.value != true) {
            ui?.togglePlayPause()
            Log.d(TAG, "onResume → 续播")
        }
        resumeOnReturn = false
    }

    override fun onDestroy() {
        // 顺序：停进度记录 → 释放播放器内核 → 断视图引用
        progressJob?.cancel()
        progressJob = null
        uiState?.release()
        uiState = null
        systemUiState = null
        if (::playerView.isInitialized) {
            playerView.player = null
        }
        player?.release()
        Log.d(TAG, "onDestroy → release()")
        player = null
        super.onDestroy()
    }

    // ============================ 全屏 ============================

    /** 横竖屏 + 系统栏一起切。全屏 = 横屏 + 隐藏状态栏/导航栏。 */
    internal fun toggleFullscreen() = setFullscreen(!isFullscreen)

    internal fun setFullscreen(fullscreen: Boolean) {
        isFullscreen = fullscreen
        requestedOrientation = if (fullscreen) {
            ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE
        } else {
            ActivityInfo.SCREEN_ORIENTATION_SENSOR_PORTRAIT
        }
        WindowCompat.setDecorFitsSystemWindows(window, !fullscreen)
        val controller = WindowInsetsControllerCompat(window, window.decorView)
        if (fullscreen) {
            controller.systemBarsBehavior =
                WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            controller.hide(WindowInsetsCompat.Type.systemBars())
        } else {
            controller.show(WindowInsetsCompat.Type.systemBars())
        }
        Log.d(TAG, "setFullscreen=$fullscreen")
    }

    // ============================ 播放器 / 数据源 ============================

    private fun createPlayerView(): PlayerView = PlayerView(this).apply {
        useController = false
        setShowBuffering(PlayerView.SHOW_BUFFERING_NEVER)
        resizeMode = AspectRatioFrameLayout.RESIZE_MODE_FIT
        keepScreenOn = true
        layoutParams = ViewGroup.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
        )
    }

    /**
     * 建 MediaSource：数据源换成带防盗链 Headers 的 [OkHttpDataSource]，
     * 类型用 [DefaultMediaSourceFactory] 按地址自动识别。
     *
     * 之前的问题：这里写死的是 ProgressiveMediaSource，它只认 MP4/WebM 这类渐进式容器。
     * 采集站给的 .m3u8（HLS 播放列表）会被它当成普通视频文件去解析容器头，
     * 解析失败就抛 ERROR_CODE_PARSING_CONTAINER_UNSUPPORTED —— 正是截图里那个报错。
     * DefaultMediaSourceFactory 会按 URL 后缀 / Content-Type 自动选择
     * Progressive / HLS / DASH。注意：播 m3u8 还要求 app 的 build.gradle 里加上
     * `androidx.media3:media3-exoplayer-hls` 依赖（见压缩包根目录的 FIX_NOTES.md）。
     */
    private fun createMediaSource(videoUrl: String, headers: Map<String, String>): MediaSource =
        DefaultMediaSourceFactory(PlayerDataSourceFactory.create(headers))
            .createMediaSource(MediaItem.fromUri(videoUrl))

    /** 取 URL 最后一段当标题，纯 UI 用。 */
    private fun titleOf(url: String): String =
        url.substringAfterLast('/').substringBefore('?').ifBlank { "播放中" }

    // ============================ 模块七：进度记录 ============================

    /**
     * 这条历史的唯一键。
     *
     * 三级兜底（vodId → 片名 → 地址）：真实的调用链里三级都空是不可能的，
     * 但"只有地址"那种老调用点（网盘解析直接起播放器）确实存在 ——
     * 那种情况下用地址当键，至少用户能在历史里看到"我看过这个"。
     */
    private fun historyKey(): String =
        vodId.ifBlank { vodName }.ifBlank { videoUrl }

    /**
     * 从播放器读一次当前状态，交给 [writeHistory] 落盘。
     *
     * 进度/时长从 [PlayerUiState] 的 Flow 读（双内核统一），不直接碰播放器。
     * 内核已释放（onDestroy 之后迟到的调用）→ 直接返回，**不崩**。
     *
     * @param reason 触发来源（定时 / onPause），只用于日志
     */
    private fun saveProgress(reason: String) {
        val ui = uiState ?: return
        val position = ui.position.value.coerceAtLeast(0L)
        val rawDuration = ui.duration.value
        writeHistory(position, rawDuration, reason)
    }

    /**
     * 真正的写入：把一次 (位置, 时长) 落成一条历史。
     *
     * 从 [saveProgress] 里抽出来是为了**能被单测直接调**：
     * Robolectric 里喂不进一段合法媒体，`player.currentPosition` 永远是 0，
     * 那样"进度记录"这条链在测试里就只能靠肉眼看了。抽成参数化的 internal 之后，
     * 测试可以拿真实的 Intent → 字段 → 写入 → 读回来整条链跑一遍。
     *
     * @param positionMs 已播放毫秒
     * @param rawDurationMs 播放器报的时长（[androidx.media3.common.C.TIME_UNSET] 之类非法值由这里收敛）
     * @param reason 触发来源，只用于日志
     */
    internal fun writeHistory(positionMs: Long, rawDurationMs: Long, reason: String) {
        val key = historyKey()
        if (key.isEmpty()) return

        val position = positionMs.coerceAtLeast(0L)
        val duration = if (rawDurationMs > 0L) rawDurationMs else 0L

        // 位置和时长都是 0（还没真正播起来）→ 不写，免得列表里堆一堆"看到 00:00"的空记录
        if (position <= 0L && duration <= 0L) return

        HistoryRepository.upsert(
            PlayHistory(
                vodId = key,
                vodName = vodName,
                vodPic = vodPic,
                episodeName = episodeName,
                episodeUrl = videoUrl,
                positionMs = position,
                durationMs = duration,
                lastPlayedAt = System.currentTimeMillis()
            )
        )
        Log.d(TAG, "记录进度($reason)：key=$key, ${position}ms / ${duration}ms")
    }

    companion object {
        private const val TAG = "PlayerActivity"

        /** 视频直链。 */
        const val EXTRA_VIDEO_URL: String = "videoUrl"

        /** 防盗链 Headers，`HashMap<String, String>`。 */
        const val EXTRA_HEADERS: String = "headers"

        // ---- 模块七：观看历史用的可选参数 ----

        /** 片子 id（采集站的 `vod_id`）。 */
        const val EXTRA_VOD_ID: String = "vodId"

        /** 片名。 */
        const val EXTRA_VOD_NAME: String = "vodName"

        /** 封面地址。 */
        const val EXTRA_VOD_PIC: String = "vodPic"

        /** 集名，如 "第03集"。 */
        const val EXTRA_EPISODE_NAME: String = "episodeName"

        /** 续播起点（毫秒），>0 时播放器自动 seekTo 到这里。 */
        const val EXTRA_START_POSITION_MS: String = "startPositionMs"

        /** 进度记录间隔：5 秒（契约指定）。 */
        const val PROGRESS_SAVE_INTERVAL_MS: Long = 5_000L

        /**
         * 建 Intent。
         *
         * header 为空时不会塞多余 extra，避免调用方拿到一个空 map 还以为是"要带 header"。
         *
         * 模块七新加的后 5 个参数**全部可选**，老的三个参数调用（详情页 / 网盘解析 / 测试）
         * 一字不改照样能编过、照样能播 —— 只是历史记录里少几个字段而已。
         *
         * @param vodId           片子 id（不传则历史键退回片名 / 地址）
         * @param vodName         片名
         * @param vodPic          封面地址
         * @param episodeName     集名
         * @param startPositionMs 续播起点（毫秒），0 = 从头播
         */
        @JvmStatic
        @JvmOverloads
        fun intent(
            context: Context,
            videoUrl: String,
            headers: HashMap<String, String>? = null,
            vodId: String? = null,
            vodName: String? = null,
            vodPic: String? = null,
            episodeName: String? = null,
            startPositionMs: Long = 0L
        ): Intent = Intent(context, PlayerActivity::class.java).apply {
            putExtra(EXTRA_VIDEO_URL, videoUrl)
            if (headers.isNullOrEmpty()) {
                removeExtra(EXTRA_HEADERS)
            } else {
                putExtra(EXTRA_HEADERS, headers)
            }

            // 空值一律不塞：`putExtra(key, null)` 对 String 会写进一个 null extra，
            // 读的时候 `getStringExtra` 给 null 没问题，但 Intent 里留着一堆空 key 会让人误判
            // "这个字段传了"。统一在源头挡掉。
            putOrRemove(EXTRA_VOD_ID, vodId)
            putOrRemove(EXTRA_VOD_NAME, vodName)
            putOrRemove(EXTRA_VOD_PIC, vodPic)
            putOrRemove(EXTRA_EPISODE_NAME, episodeName)
            if (startPositionMs > 0L) {
                putExtra(EXTRA_START_POSITION_MS, startPositionMs)
            } else {
                removeExtra(EXTRA_START_POSITION_MS)
            }
        }

        /** 非空才写、空就删（见 [intent] 里的说明）。 */
        private fun Intent.putOrRemove(key: String, value: String?) {
            val safe = value?.trim().orEmpty()
            if (safe.isEmpty()) removeExtra(key) else putExtra(key, safe)
        }
    }
}

/**
 * 从 Intent 里安全读 Headers。
 *
 * 容错点：拿到的可能不是 Map（别的调用方塞了字符串），也可能 value 是 null —— 这两种都跳过而不是崩，
 * 播放页因为一个畸形 extra 起不来是最亏的。
 */
@Suppress("DEPRECATION")
internal fun readHeaders(intent: Intent?): Map<String, String> {
    val raw = intent?.getSerializableExtra(PlayerActivity.EXTRA_HEADERS) ?: return emptyMap()
    val map = raw as? Map<*, *> ?: run {
        Log.w("PlayerActivity", "headers extra 不是 Map，忽略：${raw.javaClass.simpleName}")
        return emptyMap()
    }
    return map.entries.mapNotNull { entry ->
        val key = entry.key as? String
        val value = entry.value as? String
        if (key.isNullOrBlank() || value.isNullOrBlank()) null else key to value
    }.toMap()
}

/**
 * 防盗链 Headers 注入拦截器（模块 1.5 的核心）。
 *
 * 为什么用拦截器而不是只靠 `setDefaultRequestProperties`：
 * 拦截器是**每一条真实请求的必经之路**，ExoPlayer 的分片请求、重定向、重试全都覆盖得到；
 * 而且这里顺手打一条日志，Logcat 里能直接看到这次请求到底带了什么 Referer（验收标准 3）。
 */
internal class ProtectionHeaderInterceptor(
    private val headers: Map<String, String>
) : Interceptor {

    override fun intercept(chain: Interceptor.Chain): Response {
        val builder = chain.request().newBuilder()
        headers.forEach { (key, value) ->
            if (key.isNotBlank() && value.isNotBlank()) {
                builder.header(key, value)
            }
        }
        val request = builder.build()
        Log.d(
            TAG,
            "→ ${request.method} ${request.url} | Referer=${request.header("Referer")} " +
                "| User-Agent=${request.header("User-Agent")}"
        )
        return chain.proceed(request)
    }

    private companion object {
        const val TAG = "PlayerHttp"
    }
}

/**
 * 数据源工厂：把 Headers 变成 ExoPlayer 真正会用的 [OkHttpDataSource.Factory]。
 *
 * 拆成 object 是为了单测能直接拿它建数据源跑真请求，不必起 Activity。
 */
@OptIn(UnstableApi::class)
internal object PlayerDataSourceFactory {

    /** 没传 User-Agent 时的兜底 UA（很多源站拿 UA 判客户端，空 UA 会被 403）。 */
    const val DEFAULT_USER_AGENT: String =
        "Mozilla/5.0 (Linux; Android 13; TVBoxShell/1.0) AppleWebKit/537.36 " +
            "(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36"

    private const val CONNECT_TIMEOUT_SECONDS = 15L
    private const val READ_TIMEOUT_SECONDS = 30L

    /**
     * 建一个带 Headers 的数据源工厂。
     *
     * @param headers 防盗链头，空 / null 时退化成普通数据源（但仍会带默认 UA）。
     */
    fun create(headers: Map<String, String> = emptyMap()): OkHttpDataSource.Factory {
        val builder = OkHttpClient.Builder()
            .connectTimeout(CONNECT_TIMEOUT_SECONDS, TimeUnit.SECONDS)
            .readTimeout(READ_TIMEOUT_SECONDS, TimeUnit.SECONDS)
            .followRedirects(true)
            .followSslRedirects(true)
        if (headers.isNotEmpty()) {
            builder.addInterceptor(ProtectionHeaderInterceptor(headers))
        }
        return createFrom(builder.build(), headers)
    }

    /**
     * 用现成的 OkHttpClient 建数据源工厂（方便外部替换 client：加代理、加 cookie jar 等）。
     *
     * 这里再做一道 `setDefaultRequestProperties`：拦截器管"请求发出前改写"，
     * 这层管"数据源自己就知道该带什么"，两层叠起来，任一层被绕过都还有一层。
     */
    fun createFrom(
        client: OkHttpClient,
        headers: Map<String, String> = emptyMap()
    ): OkHttpDataSource.Factory {
        val userAgent = headers.entries
            .firstOrNull { it.key.equals("User-Agent", ignoreCase = true) }
            ?.value
            ?.takeIf { it.isNotBlank() }
            ?: DEFAULT_USER_AGENT

        val factory = OkHttpDataSource.Factory(client).setUserAgent(userAgent)
        if (headers.isNotEmpty()) {
            factory.setDefaultRequestProperties(headers)
        }
        return factory
    }
}

// ============================ 播放页 UI ============================

/**
 * 播放页界面：底层视频渲染面 + 上层自绘控制条。
 *
 * [videoSurface] 是内核的渲染面（ExoPlayer 的 PlayerView / 系统内核的 VideoView），
 * [ui] 是内核的状态抽象 —— 控制条只认接口，换内核不动 UI。
 *
 * 控制条：返回、标题、播放/暂停、当前时间 / 总时长、进度条（可拖）、全屏切换。
 * 点画面切换控制条显示；播放中 4 秒无操作自动收起。
 */
@Composable
private fun PlayerScreen(
    videoSurface: @Composable () -> Unit,
    ui: PlayerUiState,
    title: String,
    isFullscreen: Boolean,
    danmakuItems: List<DanmakuItem>,
    onBack: () -> Unit,
    onToggleFullscreen: () -> Unit,
    onOpenSettings: () -> Unit
) {
    val isPlaying by ui.isPlaying.collectAsState()
    val duration by ui.duration.collectAsState()
    val position by ui.position.collectAsState()
    val buffering by ui.buffering.collectAsState()
    val errorMessage by ui.errorMessage.collectAsState()
    // 弹幕开关：Activity 进页面时已经按开关拉过数据，这里只读开关决定画不画
    val danmakuEnabled = remember { UserPreference.isDanmakuEnabled() }

    var controlsVisible by remember { mutableStateOf(true) }
    var scrubValue by remember { mutableStateOf<Float?>(null) }

    // 播放中且没在拖动 → 4 秒后自动收起控制条
    LaunchedEffect(controlsVisible, isPlaying, scrubValue) {
        if (controlsVisible && isPlaying && scrubValue == null) {
            delay(CONTROLS_AUTO_HIDE_MS)
            controlsVisible = false
        }
    }

    // 全屏时返回键先退出全屏，而不是直接关页面
    BackHandler(enabled = isFullscreen) { onToggleFullscreen() }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black)
    ) {
        // 内核渲染面（ExoPlayer 的 PlayerView / 系统内核的 VideoView）
        videoSurface()

        // 弹幕层：盖在视频上、控制条之下（需求4）
        if (danmakuEnabled) {
            DanmakuOverlay(
                items = danmakuItems,
                positionMs = position,
                enabled = true,
                textColor = Color(UserPreference.getDanmakuColor()),
                textScale = UserPreference.getDanmakuTextScale(),
                modifier = Modifier.fillMaxSize()
            )
        }

        // 点画面 → 控制条显隐
        Box(
            modifier = Modifier
                .fillMaxSize()
                .clickable(
                    interactionSource = remember { MutableInteractionSource() },
                    indication = null
                ) { controlsVisible = !controlsVisible }
        )

        if (buffering) {
            CircularProgressIndicator(
                modifier = Modifier.align(Alignment.Center),
                color = Color.White
            )
        }

        errorMessage?.let { message ->
            Column(
                modifier = Modifier
                    .align(Alignment.Center)
                    .padding(24.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(text = message, color = Color(0xFFFF6B6B), fontSize = 16.sp)
                Text(
                    text = "换个源或检查播放地址后再试",
                    color = Color(0xFFBDBDBD),
                    fontSize = 13.sp,
                    modifier = Modifier.padding(top = 6.dp)
                )
            }
        }

        if (controlsVisible) {
            ControlBar(
                title = title,
                isPlaying = isPlaying,
                isFullscreen = isFullscreen,
                duration = duration,
                position = position,
                scrubValue = scrubValue,
                onScrub = { value ->
                    scrubValue = value
                    ui.scrubTo(value.toLong())
                },
                onScrubFinished = {
                    val target = scrubValue
                    scrubValue = null
                    if (target != null) ui.endScrub(target.toLong())
                },
                onTogglePlay = { ui.togglePlayPause() },
                onToggleFullscreen = onToggleFullscreen,
                onOpenSettings = onOpenSettings,
                onBack = onBack
            )
        }
    }
}

@Composable
private fun ControlBar(
    title: String,
    isPlaying: Boolean,
    isFullscreen: Boolean,
    duration: Long,
    position: Long,
    scrubValue: Float?,
    onScrub: (Float) -> Unit,
    onScrubFinished: () -> Unit,
    onTogglePlay: () -> Unit,
    onToggleFullscreen: () -> Unit,
    onOpenSettings: () -> Unit,
    onBack: () -> Unit
) {
    val sliderMax = if (duration > 0L) duration.toFloat() else 1f
    val sliderValue = (scrubValue ?: position.toFloat()).coerceIn(0f, sliderMax)
    val shownPosition = scrubValue?.toLong() ?: position

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0x99000000))
            .windowInsetsPadding(WindowInsets.systemBars)
    ) {
        // 顶栏：返回 + 标题
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 4.dp, vertical = 4.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(onClick = onBack) {
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                    contentDescription = "返回",
                    tint = Color.White
                )
            }
            Text(
                text = title,
                color = Color.White,
                fontSize = 15.sp,
                fontWeight = FontWeight.Medium,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier.padding(start = 4.dp)
            )
        }

        Box(modifier = Modifier.weight(1f))

        // 底栏：播放/暂停 + 进度 + 时间 + 全屏
        Column(modifier = Modifier.fillMaxWidth().padding(horizontal = 8.dp, vertical = 8.dp)) {
            Slider(
                value = sliderValue,
                onValueChange = onScrub,
                onValueChangeFinished = onScrubFinished,
                valueRange = 0f..sliderMax,
                enabled = duration > 0L,
                modifier = Modifier.fillMaxWidth()
            )
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                IconButton(onClick = onTogglePlay) {
                    Icon(
                        imageVector = if (isPlaying) Icons.Filled.Pause else Icons.Filled.PlayArrow,
                        contentDescription = if (isPlaying) "暂停" else "播放",
                        tint = Color.White
                    )
                }
                Text(
                    text = "${formatTime(shownPosition)} / ${formatTime(duration)}",
                    color = Color.White,
                    fontSize = 13.sp,
                    modifier = Modifier.padding(horizontal = 4.dp)
                )
                Box(modifier = Modifier.weight(1f))
                IconButton(onClick = onOpenSettings) {
                    Icon(
                        imageVector = Icons.Filled.Settings,
                        contentDescription = "设置",
                        tint = Color.White
                    )
                }
                IconButton(onClick = onToggleFullscreen) {
                    Icon(
                        imageVector = if (isFullscreen) {
                            Icons.Filled.FullscreenExit
                        } else {
                            Icons.Filled.Fullscreen
                        },
                        contentDescription = if (isFullscreen) "退出全屏" else "全屏",
                        tint = Color.White
                    )
                }
            }
        }
    }
}

/** 毫秒 → `mm:ss` / `h:mm:ss`。用 Locale.US 格式化，避免地区语言把数字换成别的字符。 */
internal fun formatTime(millis: Long): String {
    val totalSeconds = if (millis > 0L) millis / 1000 else 0L
    val hours = totalSeconds / 3600
    val minutes = (totalSeconds % 3600) / 60
    val seconds = totalSeconds % 60
    return if (hours > 0L) {
        String.format(Locale.US, "%d:%02d:%02d", hours, minutes, seconds)
    } else {
        String.format(Locale.US, "%02d:%02d", minutes, seconds)
    }
}

/** 控制条自动收起延时。 */
private const val CONTROLS_AUTO_HIDE_MS = 4_000L
