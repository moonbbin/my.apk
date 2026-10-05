package com.tvbox.shell.parse

import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.os.Bundle
import android.util.Log
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import com.tvbox.shell.player.PlayerActivity
import java.util.concurrent.atomic.AtomicBoolean

/**
 * WebView 嗅探页（需求3：网盘 / 腾讯 / 爱奇艺等站内视频）。
 *
 * 原理：有些地址（网盘分享页、腾讯/爱奇艺站内播放页）**根本拿不到直链**，
 * 只能把页面在 WebView 里真正打开，让它的播放器自己去请求视频流，
 * 我们在 [WebResourceRequest] 里把 `.m3u8 / .mp4` 之类的请求抓出来，
 * 抓到就关掉本页、带着直链跳 [PlayerActivity]。
 *
 * 抓不到（30 秒超时 / 页面报错）就 Toast 提示后退出，不卡死。
 *
 * 入参（Intent）：
 * - [EXTRA_PAGE_URL]：要打开的页面地址（必填）；
 * - [EXTRA_TITLE]：片名/集名（提示用）。
 */
class WebSniffActivity : ComponentActivity() {

    private var pageUrl: String = ""
    private var title: String = ""
    private var statusText by mutableStateOf("正在打开页面嗅探播放地址…")
    private val done = AtomicBoolean(false)
    private var webView: WebView? = null

    @SuppressLint("SetJavaScriptEnabled")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        pageUrl = intent?.getStringExtra(EXTRA_PAGE_URL).orEmpty().trim()
        title = intent?.getStringExtra(EXTRA_TITLE).orEmpty().trim()
        if (pageUrl.isEmpty()) {
            Log.e(TAG, "缺少 $EXTRA_PAGE_URL")
            finish()
            return
        }

        setContent { SniffScreen() }

        val wv = WebView(this)
        webView = wv
        wv.settings.javaScriptEnabled = true
        wv.settings.domStorageEnabled = true
        wv.settings.mediaPlaybackRequiresUserGesture = false
        // 桌面 UA：很多站内页对移动端返回加密流，桌面端更容易抓到明文 m3u8
        wv.settings.userAgentString = DESKTOP_UA
        wv.webViewClient = SniffClient(
            onMediaFound = { mediaUrl -> onSniffed(mediaUrl) },
            onStatus = { statusText = it }
        )
        Log.i(TAG, "开始嗅探：$pageUrl")
        wv.loadUrl(pageUrl)

        // 30 秒抓不到就认栽
        wv.postDelayed({
            if (done.compareAndSet(false, true)) {
                Log.w(TAG, "嗅探超时：$pageUrl")
                runOnUiThread {
                    Toast.makeText(this, "没嗅探到可播放地址，换个源再试", Toast.LENGTH_LONG).show()
                }
                finish()
            }
        }, SNIFF_TIMEOUT_MS)
    }

    /** 抓到直链：关嗅探页，跳播放器。 */
    private fun onSniffed(mediaUrl: String) {
        if (!done.compareAndSet(false, true)) return
        Log.i(TAG, "嗅探命中：${mediaUrl.take(160)}")
        runOnUiThread {
            Toast.makeText(this, "已嗅探到播放地址", Toast.LENGTH_SHORT).show()
            startActivity(
                PlayerActivity.intent(
                    context = this,
                    videoUrl = mediaUrl,
                    vodName = title
                )
            )
            finish()
        }
    }

    override fun onDestroy() {
        webView?.apply {
            stopLoading()
            destroy()
        }
        webView = null
        super.onDestroy()
    }

    @Composable
    private fun SniffScreen() {
        MaterialTheme {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(Color(0xFF101014)),
                contentAlignment = Alignment.Center
            ) {
                // WebView 藏在后台跑，界面只给一个状态提示
                AndroidView(
                    factory = { webView ?: WebView(it) },
                    modifier = Modifier.fillMaxSize()
                )
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    modifier = Modifier
                        .background(Color(0xCC101014))
                        .padding(24.dp)
                ) {
                    CircularProgressIndicator(color = Color.White)
                    Spacer(modifier = Modifier.height(12.dp))
                    Text(text = statusText, color = Color.White, fontSize = 14.sp)
                    if (title.isNotBlank()) {
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(text = title, color = Color(0xFFBDBDBD), fontSize = 12.sp)
                    }
                }
            }
        }
    }

    /** 拦截所有资源请求，命中媒体后缀就收网。 */
    private inner class SniffClient(
        private val onMediaFound: (String) -> Unit,
        private val onStatus: (String) -> Unit
    ) : WebViewClient() {

        override fun onPageStarted(view: WebView?, url: String?, favicon: Bitmap?) {
            onStatus("页面加载中，监听视频流…")
        }

        override fun shouldInterceptRequest(
            view: WebView?,
            request: WebResourceRequest?
        ): WebResourceResponse? {
            val url = request?.url?.toString().orEmpty()
            if (url.isNotBlank() && ParseManager.isDirectMedia(url) && !url.contains("google", ignoreCase = true)) {
                Log.i(TAG, "拦截到媒体请求：${url.take(160)}")
                onMediaFound(url)
            }
            return super.shouldInterceptRequest(view, request)
        }

        override fun onReceivedError(
            view: WebView?,
            request: WebResourceRequest?,
            error: android.webkit.WebResourceError?
        ) {
            if (request?.isForMainFrame == true) {
                onStatus("页面加载出错，可能需要换个解析方式")
            }
        }
    }

    companion object {
        private const val TAG = "WebSniff"

        /** 要嗅探的页面地址。 */
        const val EXTRA_PAGE_URL = "pageUrl"

        /** 片名/集名（提示用）。 */
        const val EXTRA_TITLE = "title"

        /** 嗅探超时：30 秒。 */
        const val SNIFF_TIMEOUT_MS = 30_000L

        private const val DESKTOP_UA =
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 " +
                "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

        @JvmStatic
        fun intent(context: Context, pageUrl: String, title: String = ""): Intent =
            Intent(context, WebSniffActivity::class.java).apply {
                putExtra(EXTRA_PAGE_URL, pageUrl)
                putExtra(EXTRA_TITLE, title)
            }
    }
}
