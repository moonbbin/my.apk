package com.tvbox.shell.player

import androidx.compose.runtime.Composable

/**
 * 测试用 PlayerActivity：复写 [PlayerActivity.setPlayerContent] 使其**不挂 Compose**。
 *
 * 原因（见 PlayerHistoryTest 的类注释）：Compose 的界面调度器是静态单例，
 * 在没有 Compose 测试规则的用例里先 `setContent`，同一个 JVM 里后面的 Compose 测试
 * 会永远等不到空闲帧。
 */
class TestablePlayerActivity : PlayerActivity() {

    override fun setPlayerContent(
        videoUrl: String,
        videoSurface: @Composable () -> Unit,
        ui: PlayerUiState
    ) {
        // 故意空实现：不调 setContent。
    }
}
