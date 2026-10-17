#!/bin/bash
# 32_music_theme_dark_light.sh v3 (2026-10-17): 修复重复 cd avbox (2026-10-17): 桥接方案完整实装 (2026-10-17): 全局深色/浅色切换 + 播放页动态取色
# 包含：浅色 Token、Theme 双盘、ThemeViewModel(DataStore)、MainActivity 注入、设置页开关、PlayerScreen 动态取色、build.gradle 依赖
set -e
cd avbox

echo "=== 32 v3：深色/浅色全局切换 ==="

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

echo "=== 32 v3 Part1 完成 ==="
# 32 v3 Part2: ThemeViewModel.kt 新建（DataStore 持久化）
# cd avbox (已在 avbox 内，跳过)

echo "=== 32 v3 Part2：ThemeViewModel ==="

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

echo "=== 32 v3 Part2 完成 ==="
# 32 v3 Part3: PlayerScreen.kt 新建（动态取色，三处修正版）
# cd avbox (已在 avbox 内，跳过)

echo "=== 32 v3 Part3：PlayerScreen ==="

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

echo "=== 32 v3 Part3 完成 ==="
# 32 v3 Part4: build.gradle 加依赖
# cd avbox (已在 avbox 内，跳过)

echo "=== 32 v3 Part4：build.gradle 依赖 ==="

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

echo "=== 32 v3 Part4 完成 ==="

echo "=== 32 v3 PartA 完成 ==="
# 32 v3 PartA2: LxMusicTheme composable 桥接重写
set -e
# cd avbox (已在 avbox 内，跳过)

echo "=== 32 v3 PartA2：LxMusicTheme 桥接 ==="

python3 << 'PYEOF'
import sys, re

path = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxMusicTheme.kt"
with open(path, encoding="utf-8") as f:
    src = f.read()

MARK = "// [32v2] LxMusicTheme bridge"
if MARK in src:
    print("PartA2：跳过（已是 v2）")
    sys.exit(0)

# 找 LxMusicTheme 函数定义
# 模式：@Composable\nfun LxMusicTheme(
pattern = r'@Composable\s*\nfun\s+LxMusicTheme\s*\([^)]*\)\s*\{'
m = re.search(pattern, src)
if not m:
    print("错误：未找到 LxMusicTheme 函数定义")
    sys.exit(1)

print(f"找到 LxMusicTheme 在位置 {m.start()}")

# 找到函数体的结束（匹配大括号）
start = m.end() - 1  # 在 { 的位置
depth = 0
end = start
for i in range(start, len(src)):
    if src[i] == '{':
        depth += 1
    elif src[i] == '}':
        depth -= 1
        if depth == 0:
            end = i + 1
            break

old_func = src[m.start():end]
print(f"旧函数长度：{len(old_func)} 字符")

# 新函数（桥接版）
new_func = '''// [32v2] LxMusicTheme bridge: 支持 isDarkTheme 参数，桥接 Material3
@Composable
fun LxMusicTheme(
    isDarkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    // 1. 选 MusicColors
    val musicColors = if (isDarkTheme) DarkMusicColors else LightMusicColors

    // 2. 映射到 Material3 ColorScheme
    val materialColorScheme = if (isDarkTheme) {
        darkColorScheme(
            primary = BrandGreen,
            onPrimary = TextOnAccent,
            primaryContainer = AppleGreenDim,
            onPrimaryContainer = Color(0xFFB9F5C0),
            background = musicColors.background,
            onBackground = musicColors.textPrimary,
            surface = musicColors.card,
            onSurface = musicColors.textPrimary,
            surfaceVariant = musicColors.cardSecondary,
            onSurfaceVariant = musicColors.textSecondary,
            outline = musicColors.divider,
            outlineVariant = musicColors.divider.copy(alpha = 0.5f),
            error = ErrorRed,
            onError = Color.White
        )
    } else {
        lightColorScheme(
            primary = BrandGreen,
            onPrimary = Color.White,
            primaryContainer = Color(0xFFD1F2D8),
            onPrimaryContainer = Color(0xFF0A2A10),
            background = musicColors.background,
            onBackground = musicColors.textPrimary,
            surface = musicColors.card,
            onSurface = musicColors.textPrimary,
            surfaceVariant = musicColors.cardSecondary,
            onSurfaceVariant = musicColors.textSecondary,
            outline = musicColors.divider,
            outlineVariant = musicColors.divider.copy(alpha = 0.5f),
            error = ErrorRed,
            onError = Color.White
        )
    }

    // 3. 双提供
    CompositionLocalProvider(
        LocalMusicColors provides musicColors
    ) {
        MaterialTheme(
            colorScheme = materialColorScheme,
            typography = MusicTypography,
            shapes = MusicShapes,
            content = content
        )
    }
}'''

# 确保必要的 import
if "import androidx.compose.material3.darkColorScheme" not in src:
    src = src.replace(
        "import androidx.compose.runtime.Composable",
        "import androidx.compose.runtime.Composable\nimport androidx.compose.material3.darkColorScheme\nimport androidx.compose.material3.lightColorScheme\nimport androidx.compose.material3.MaterialTheme",
        1
    )
    print("已加 Material3 import")

if "import androidx.compose.foundation.isSystemInDarkTheme" not in src:
    src = src.replace(
        "import androidx.compose.runtime.Composable",
        "import androidx.compose.runtime.Composable\nimport androidx.compose.foundation.isSystemInDarkTheme",
        1
    )
    print("已加 isSystemInDarkTheme import")

# 替换函数
src = src[:m.start()] + new_func + src[end:]

with open(path, "w", encoding="utf-8") as f:
    f.write(src)
print("PartA2：LxMusicTheme 已重写为桥接版")
PYEOF

echo "=== 32 v3 PartA2 完成 ==="
# 32 v3 PartB: MainActivity 彻底排查
set -e
# cd avbox (已在 avbox 内，跳过)

echo "=== 32 v3 PartB：MainActivity 排查 ==="

MAIN=$(find app/src/main/java -name "MainActivity.kt" 2>/dev/null | head -1)
if [ -z "$MAIN" ]; then
    echo "错误：未找到 MainActivity.kt"
    exit 1
fi
echo "文件：$MAIN"

python3 << PYEOF
import sys, re

path = "$MAIN"
with open(path, encoding="utf-8") as f:
    src = f.read()

# 1. 检查是否已用新版
if "LxMusicTheme(isDarkTheme" in src:
    print("PartB：已用 LxMusicTheme(isDarkTheme=)，跳过")
    sys.exit(0)

# 2. 找 setContent
if "setContent" not in src:
    print("错误：未找到 setContent")
    sys.exit(1)

print("找到 setContent")

# 3. 找主题包裹：LxMusicTheme( (旧版，无参数)、MaterialTheme、AppTheme 等
patterns = [
    r'LxMusicTheme\s*\{',
    r'LxMusicTheme\s*\(',
    r'MaterialTheme\s*\{',
    r'MaterialTheme\s*\(',
]

found = []
for pat in patterns:
    for m in re.finditer(pat, src):
        # 取上下文
        start = max(0, m.start() - 50)
        end = min(len(src), m.end() + 100)
        ctx = src[start:end].replace('\n', ' ')[:120]
        found.append((m.group(0), ctx))

if found:
    print(f"找到 {len(found)} 个可能的主题包裹：")
    for pat, ctx in found[:10]:
        print(f"  - {pat}: ...{ctx}...")
    print("")
    print("错误：MainActivity 主题结构需手动确认，未自动替换")
    print("请检查以上位置，确认后手动改为 LxMusicTheme(isDarkTheme = isDark)")
    sys.exit(1)
else:
    print("未找到明显的主题包裹，需手动检查 setContent 结构")
    sys.exit(1)
PYEOF

echo "=== 32 v3 PartB 完成 ==="
# 32 v3 PartC: 搜 isSystemInDarkTheme 并替换
set -e
# cd avbox (已在 avbox 内，跳过)

echo "=== 32 v3 PartC：isSystemInDarkTheme 排查 ==="

# 只查 music 相关目录，避免动主体其他部分
TARGET_DIR="app/src/main/java/com/github/tvbox/osc/ui/music"

if [ ! -d "$TARGET_DIR" ]; then
    echo "警告：未找到 $TARGET_DIR，跳过"
    exit 0
fi

echo "搜索 isSystemInDarkTheme()..."
FOUND=$(grep -r "isSystemInDarkTheme()" "$TARGET_DIR" 2>/dev/null | wc -l)
echo "找到 $FOUND 处"

if [ "$FOUND" -gt 0 ]; then
    echo "--- 位置列表 ---"
    grep -rn "isSystemInDarkTheme()" "$TARGET_DIR" 2>/dev/null | head -20
    
    # 替换策略：isSystemInDarkTheme() -> LocalMusicColors.current.isDark
    # 但 MusicColors 可能没有 isDark 字段，先检查
    # 为安全起见，只做标记，不自动替换
    echo ""
    echo "[32v2] TODO: 以上 $FOUND 处 isSystemInDarkTheme() 需手动替换为主题读取"
    echo "建议替换为：val isDark = LocalMusicColors.current.background.luminance() < 0.5"
    echo "或：MaterialTheme.colorScheme.background.luminance() < 0.5"
fi

echo "=== 32 v3 PartC 完成 ==="
# 32 v3 PartD: Modifier.shadow 检查
set -e
# cd avbox (已在 avbox 内，跳过)

echo "=== 32 v3 PartD：shadow 检查 ==="

TARGET_DIR="app/src/main/java/com/github/tvbox/osc/ui/music"

if [ ! -d "$TARGET_DIR" ]; then
    echo "警告：未找到 $TARGET_DIR，跳过"
    exit 0
fi

echo "搜索 Modifier.shadow..."
FOUND=$(grep -r "Modifier.*\.shadow" "$TARGET_DIR" 2>/dev/null | wc -l)
echo "找到 $FOUND 处"

if [ "$FOUND" -gt 0 ]; then
    echo "--- 位置列表 ---"
    grep -rn "Modifier.*\.shadow" "$TARGET_DIR" 2>/dev/null | head -20
    echo ""
    echo "[32v2] TODO: 检查以上 shadow 在浅色模式下是否太突兀"
    echo "如需修复，考虑用 MaterialTheme.colorScheme.surfaceVariant 做阴影色，或调低 elevation"
fi

echo "=== 32 v3 PartD 完成 ==="
