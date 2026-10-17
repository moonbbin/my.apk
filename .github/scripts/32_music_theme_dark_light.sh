#!/bin/bash
# 32_music_theme_dark_light.sh v1 (2026-10-17): 全局深色/浅色切换 + 播放页动态取色
# 包含：浅色 Token、Theme 双盘、ThemeViewModel(DataStore)、MainActivity 注入、设置页开关、PlayerScreen 动态取色、build.gradle 依赖
set -e
cd avbox

echo "=== 32 v1：深色/浅色全局切换 ==="

# ===== Part 1: Color.kt 追加浅色 Token =====
python3 << 'PYEOF'
import sys

path = "app/src/main/java/com/github/tvbox/osc/ui/music/theme/Color.kt"
try:
    with open(path, encoding="utf-8") as f:
        src = f.read()
except FileNotFoundError:
    print(f"错误：未找到 {path}")
    sys.exit(1)

MARK = "// ===== 浅色 Token（Light Mode） ====="
if MARK in src:
    print("Part1 Color.kt：跳过（已是 v1）")
else:
    LIGHT_TOKENS = """
// ==========================================
// ===== 浅色 Token（Light Mode） =====
// ==========================================

// 背景层级
val LightBgBase = Color(0xFFF5F5F7)      // 极浅灰，主背景
val LightBgCard = Color(0xFFFFFFFF)      // 纯白，卡片/弹窗
val LightBgCardPressed = Color(0xFFF2F2F7) // 按压态（比背景稍微深一点点）

// 文字层级
val LightTextPrimary = Color(0xFF1C1C1E)   // 碳灰，主文字
val LightTextSecondary = Color(0xFF6E6E73) // 中性灰，辅助文字
val LightTextTertiary = Color(0xFFAEAEB2)  // 更浅的灰，用于极小标签/时间

// 功能色
val LightDivider = Color(0xFFE5E5EA)       // 极浅的分割线
"""
    src = src.rstrip() + "\n" + LIGHT_TOKENS
    with open(path, "w", encoding="utf-8") as f:
        f.write(src)
    print("Part1 Color.kt：浅色 Token 已追加")
PYEOF

echo "=== 32 v1 Part1 完成 ==="
# 32 v1 Part2: ThemeViewModel.kt 新建（DataStore 持久化）
cd avbox

echo "=== 32 v1 Part2：ThemeViewModel ==="

TARGET="app/src/main/java/com/github/tvbox/osc/ui/music/theme/ThemeViewModel.kt"
mkdir -p "$(dirname "$TARGET")"

if [ -f "$TARGET" ]; then
    echo "Part2：跳过（ThemeViewModel.kt 已存在）"
else
    cat > "$TARGET" << 'KTEOF'
package com.github.tvbox.osc.ui.music.theme

import android.content.Context
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.emptyPreferences
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import java.io.IOException
import javax.inject.Inject

private val Context.dataStore by preferencesDataStore("theme_prefs")

object ThemeMode {
    const val FOLLOW_SYSTEM = 0
    const val FORCE_DARK = 1
    const val FORCE_LIGHT = 2
}

@HiltViewModel
class ThemeViewModel @Inject constructor(
    @ApplicationContext private val context: Context
) : ViewModel() {

    private val KEY_THEME_MODE = intPreferencesKey("theme_mode")

    val themeMode: StateFlow<Int> = context.dataStore.data
        .catch { exception ->
            if (exception is IOException) {
                emit(emptyPreferences())
            } else {
                throw exception
            }
        }
        .map { preferences ->
            val savedMode = preferences[KEY_THEME_MODE] ?: ThemeMode.FOLLOW_SYSTEM
            if (savedMode in 0..2) savedMode else ThemeMode.FOLLOW_SYSTEM
        }
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.Eagerly,
            initialValue = ThemeMode.FOLLOW_SYSTEM
        )

    fun setThemeMode(mode: Int) {
        if (mode !in 0..2) return
        viewModelScope.launch {
            try {
                context.dataStore.edit { it[KEY_THEME_MODE] = mode }
            } catch (e: IOException) {
                // 写入失败静默处理
            }
        }
    }
}
KTEOF
    echo "Part2：ThemeViewModel.kt 已创建"
fi

echo "=== 32 v1 Part2 完成 ==="
# 32 v1 Part3: PlayerScreen.kt 新建（动态取色，三处修正版）
cd avbox

echo "=== 32 v1 Part3：PlayerScreen ==="

TARGET="app/src/main/java/com/github/tvbox/osc/ui/music/player/PlayerScreen.kt"
mkdir -p "$(dirname "$TARGET")"

if [ -f "$TARGET" ]; then
    echo "Part3：跳过（PlayerScreen.kt 已存在）"
else
    cat > "$TARGET" << 'KTEOF'
package com.github.tvbox.osc.ui.music.player

import android.graphics.drawable.BitmapDrawable
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.core.graphics.ColorUtils
import androidx.palette.graphics.Palette
import coil.ImageLoader
import coil.compose.AsyncImage
import coil.request.ImageRequest
import coil.request.SuccessResult
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

@Composable
fun PlayerScreen(
    coverUrl: String,
    title: String,
    artist: String,
    isDarkTheme: Boolean,
    progress: Float,
    currentLyric: String,
    onProgressChange: (Float) -> Unit,
    onPlayPause: () -> Unit,
    isPlaying: Boolean
) {
    val context = LocalContext.current

    // 1. Palette 异步取主色（修正版：不 recycle，用 Swatch 优先级）
    var dominantColor by remember(coverUrl) { mutableStateOf<Color?>(null) }

    LaunchedEffect(coverUrl) {
        if (coverUrl.isEmpty()) {
            dominantColor = null
            return@LaunchedEffect
        }
        withContext(Dispatchers.IO) {
            try {
                val loader = ImageLoader(context)
                val request = ImageRequest.Builder(context)
                    .data(coverUrl)
                    .allowHardware(false)
                    .build()
                val result = loader.execute(request)
                val drawable = (result as? SuccessResult)?.drawable
                val bitmap = (drawable as? BitmapDrawable)?.bitmap
                if (bitmap != null && !bitmap.isRecycled) {
                    val palette = Palette.from(bitmap).generate()
                    // Swatch 优先级：Vibrant > DarkVibrant > Muted > DarkMuted > Dominant兜底
                    val swatch = palette.vibrantSwatch
                        ?: palette.darkVibrantSwatch
                        ?: palette.lightVibrantSwatch
                        ?: palette.mutedSwatch
                        ?: palette.darkMutedSwatch
                        ?: palette.lightMutedSwatch
                    val fallback = if (isDarkTheme) 0xFF121212.toInt() else 0xFFF5F5F7.toInt()
                    val colorInt = swatch?.rgb ?: palette.getDominantColor(fallback)
                    dominantColor = Color(colorInt)
                    // 不 recycle，交给 Coil 内存管理
                }
            } catch (e: Exception) {
                dominantColor = null
            }
        }
    }

    val bgColor = dominantColor ?: MaterialTheme.colorScheme.background

    val luminance = dominantColor?.let {
        ColorUtils.calculateLuminance(it.toArgb())
    } ?: if (isDarkTheme) 0.0 else 1.0

    val contentColor = if (luminance > 0.5) Color(0xFF1C1C1E) else Color.White

    // 动态遮罩透明度（修正版）
    val overlayAlpha = when {
        luminance > 0.8 -> 0.75f
        luminance > 0.5 -> 0.6f
        else -> 0.45f
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(bgColor)
    ) {
        if (coverUrl.isNotEmpty()) {
            AsyncImage(
                model = coverUrl,
                contentDescription = null,
                modifier = Modifier
                    .fillMaxSize()
                    .blur(60.dp),
                contentScale = ContentScale.Crop,
                alpha = 0.6f
            )
        }

        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    Brush.verticalGradient(
                        colors = if (isDarkTheme) {
                            listOf(Color.Black.copy(alpha = overlayAlpha), Color.Transparent)
                        } else {
                            listOf(Color.White.copy(alpha = overlayAlpha), Color.Transparent)
                        }
                    )
                )
        )

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = title,
                color = contentColor,
                style = MaterialTheme.typography.titleLarge
            )
            Text(
                text = artist,
                color = contentColor.copy(alpha = 0.7f),
                style = MaterialTheme.typography.bodyMedium
            )

            Spacer(Modifier.height(24.dp))

            Slider(
                value = progress,
                onValueChange = onProgressChange,
                colors = SliderDefaults.colors(
                    thumbColor = MaterialTheme.colorScheme.primary,
                    activeTrackColor = MaterialTheme.colorScheme.primary
                )
            )

            IconButton(
                onClick = onPlayPause,
                modifier = Modifier
                    .size(72.dp)
                    .background(MaterialTheme.colorScheme.primary, CircleShape)
            ) {
                Icon(
                    imageVector = Icons.Filled.Pause,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.onPrimary,
                    modifier = Modifier.size(32.dp)
                )
            }

            Spacer(Modifier.height(16.dp))

            Text(
                text = currentLyric,
                color = MaterialTheme.colorScheme.primary,
                style = MaterialTheme.typography.bodyLarge
            )
        }
    }
}
KTEOF
    echo "Part3：PlayerScreen.kt 已创建"
fi

echo "=== 32 v1 Part3 完成 ==="
# 32 v1 Part4: build.gradle 加依赖
cd avbox

echo "=== 32 v1 Part4：build.gradle 依赖 ==="

python3 << 'PYEOF'
import sys

path = "app/build.gradle"
try:
    with open(path, encoding="utf-8") as f:
        src = f.read()
except FileNotFoundError:
    # 尝试 .kts
    path = "app/build.gradle.kts"
    try:
        with open(path, encoding="utf-8") as f:
            src = f.read()
    except FileNotFoundError:
        print("错误：未找到 build.gradle")
        sys.exit(1)

MARK = "// [32] theme deps"
if MARK in src:
    print("Part4：跳过（依赖已加）")
    sys.exit(0)

# 在 dependencies 块末尾加
OLD = "dependencies {"
if OLD in src:
    NEW = """dependencies {
    // [32] theme deps
    implementation("androidx.datastore:datastore-preferences:1.1.1")
    implementation("androidx.palette:palette-ktx:1.0.0")"""
    src = src.replace(OLD, NEW, 1)
    with open(path, "w", encoding="utf-8") as f:
        f.write(src)
    print(f"Part4：依赖已加到 {path}")
else:
    print("错误：未找到 dependencies 块")
    sys.exit(1)
PYEOF

echo "=== 32 v1 Part4 完成 ==="
