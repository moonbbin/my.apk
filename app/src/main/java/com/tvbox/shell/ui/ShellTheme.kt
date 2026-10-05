package com.tvbox.shell.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import com.tvbox.shell.config.UserPreference
import com.tvbox.shell.ui.component.NetworkImage
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * 主题模式。
 *
 * - [SYSTEM] 跟随系统深色/浅色；
 * - [LIGHT] / [DARK] 强制浅色/深色。
 *
 * 存在 [UserPreference]（KEY_THEME_MODE），设置页可切换，改完即时生效
 * （读的是 StateFlow，App 重建 Activity 即刷新；当前页面切后台再回来也会刷新）。
 */
enum class ThemeMode(val prefValue: String) {
    SYSTEM("system"),
    LIGHT("light"),
    DARK("dark");

    companion object {
        fun fromPref(value: String): ThemeMode =
            entries.firstOrNull { it.prefValue == value } ?: SYSTEM
    }
}

/** 自定义背景模式。 */
enum class BgMode(val prefValue: String) {
    /** 不用自定义背景，走主题默认底色。 */
    NONE("none"),

    /** 纯色背景。 */
    COLOR("color"),

    /** 图片背景（本地路径或网络 URL）。 */
    IMAGE("image");

    companion object {
        fun fromPref(value: String): BgMode =
            entries.firstOrNull { it.prefValue == value } ?: NONE
    }
}

/**
 * App 统一主题入口（需求5）。
 *
 * 做两件事：
 * 1. 按 [ThemeMode] 选 light/dark 配色，包一层 MaterialTheme；
 * 2. 按背景设置在内容底下铺一层背景（纯色 / 图片，图片支持网络 URL）。
 *
 * 用法：每个页面的最外层包一层 `ShellTheme { … }` 即可。
 * 背景只在 [BgMode] != NONE 时绘制，图片加载失败静默退回主题底色（不挡内容）。
 */
@Composable
fun ShellTheme(
    mode: ThemeMode = themeModeNow(),
    content: @Composable () -> Unit
) {
    val dark = when (mode) {
        ThemeMode.LIGHT -> false
        ThemeMode.DARK -> true
        ThemeMode.SYSTEM -> androidx.compose.foundation.isSystemInDarkTheme()
    }
    MaterialTheme(
        colorScheme = if (dark) darkColorScheme() else lightColorScheme()
    ) {
        val bg = backgroundSpecNow()
        Box(modifier = Modifier.fillMaxSize()) {
            ThemeBackground(spec = bg, dark = dark)
            Box(modifier = Modifier.fillMaxSize()) {
                content()
            }
        }
    }
}

/** 当前主题模式（订阅偏好，设置页改完即时刷新）。 */
@Composable
fun themeModeNow(): ThemeMode {
    val pref by UserPreference.themeModeFlow.collectAsState()
    return remember(pref) { ThemeMode.fromPref(pref) }
}

/** 当前背景规格（订阅偏好）。 */
@Composable
fun backgroundSpecNow(): BackgroundSpec {
    val mode by UserPreference.bgModeFlow.collectAsState()
    val color by UserPreference.bgColorFlow.collectAsState()
    val url by UserPreference.bgImageUrlFlow.collectAsState()
    val path by UserPreference.bgImagePathFlow.collectAsState()
    return remember(mode, color, url, path) {
        BackgroundSpec(
            mode = BgMode.fromPref(mode),
            color = Color(color),
            imageUrl = url,
            imagePath = path
        )
    }
}

/** 背景规格（UI 层用的值对象）。 */
data class BackgroundSpec(
    val mode: BgMode = BgMode.NONE,
    val color: Color = Color.Transparent,
    val imageUrl: String = "",
    val imagePath: String = ""
)

/** 背景层：纯色 / 图片（网络 URL 或本地文件）。 */
@Composable
private fun ThemeBackground(spec: BackgroundSpec, dark: Boolean) {
    when (spec.mode) {
        BgMode.NONE -> Unit // 主题默认底色，不画
        BgMode.COLOR -> {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(spec.color)
            )
        }
        BgMode.IMAGE -> {
            val target = spec.imagePath.ifBlank { spec.imageUrl }.trim()
            if (target.isBlank()) return
            // 先铺一层深色/浅色底，图片没出来前不闪白
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(if (dark) Color(0xFF101014) else Color(0xFFF2F2F7))
            )
            NetworkImage(
                url = target,
                contentDescription = null,
                contentScale = ContentScale.Crop,
                modifier = Modifier.fillMaxSize()
            )
            // 压一层半透明罩，保证上面的文字可读
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(if (dark) Color(0x99000000) else Color(0x66FFFFFF))
            )
        }
    }
}

/**
 * 主题设置的响应式入口（给非 Compose 调用方 / 预览用）。
 *
 * SettingsScreen 里改完偏好后，这里推一次事件，正在前台的 Activity
 * 可以选择 recreate() 立刻换肤（默认行为：切后台再回来自动刷新）。
 */
object ThemeEvents {
    private val _version = MutableStateFlow(0)
    val version: StateFlow<Int> = _version.asStateFlow()

    /** 主题/背景设置变化后调一次。 */
    fun notifyChanged() {
        _version.value = _version.value + 1
    }
}
