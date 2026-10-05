package com.tvbox.shell.ui.settings

import android.content.Context
import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Slider
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.tvbox.shell.config.UserPreference
import com.tvbox.shell.parse.ParseApi
import com.tvbox.shell.ui.ShellTheme

/**
 * 设置页（需求4 UI + 需求5 UI）。
 *
 * 三组设置，全部直接读写 [UserPreference]：
 * 1. **播放器设置** —— 弹幕开关 / 颜色 / 字号 / 弹幕源 API / 播放器内核；
 * 2. **主题设置** —— 主题模式 / 背景（无 / 纯色 / 图片）；
 * 3. **解析接口** —— 增删用户配置的解析接口。
 *
 * 主题那组改完通过 [UserPreference] 内部的 Flow + ThemeEvents 即时生效，
 * 所以本页自己也包一层 ShellTheme，进来就能预览效果。
 */
class SettingsActivity : ComponentActivity() {

    @OptIn(ExperimentalMaterial3Api::class)
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            ShellTheme {
                SettingsScreen(onBack = { finish() })
            }
        }
    }

    companion object {
        @JvmStatic
        fun intent(context: Context): Intent =
            Intent(context, SettingsActivity::class.java)
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun SettingsScreen(onBack: () -> Unit) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(text = "设置") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "返回"
                        )
                    }
                }
            )
        }
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            item { PlayerSettingsCard() }
            item { ThemeSettingsCard() }
            item { ParseApiCard() }
            item { VersionRow() }
        }
    }
}

/** 版本信息行：设置页最底部，展示当前版本号。 */
@Composable
private fun VersionRow() {
    Box(
        modifier = Modifier.fillMaxWidth(),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = "版本 ${com.tvbox.shell.BuildInfo.VERSION_NAME}",
            fontSize = 12.sp,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

// ======================================================================
// 播放器设置
// ======================================================================

/** 播放器设置卡片：弹幕开关 / 颜色 / 字号 / 弹幕源 / 内核。 */
@Composable
private fun PlayerSettingsCard() {
    // 每个控件都用 remember 读一次偏好做初始值，改动时立刻写回偏好
    var danmakuEnabled by remember { mutableStateOf(UserPreference.isDanmakuEnabled()) }
    var danmakuColor by remember { mutableStateOf(UserPreference.getDanmakuColor()) }
    var textScale by remember { mutableStateOf(UserPreference.getDanmakuTextScale()) }
    var danmakuApi by remember { mutableStateOf(UserPreference.getDanmakuApi()) }
    var playerCore by remember { mutableStateOf(UserPreference.getPlayerCore()) }

    SettingsCard(title = "播放器设置") {
        // —— 弹幕总开关 ——
        SwitchRow(
            label = "弹幕",
            checked = danmakuEnabled,
            onCheckedChange = {
                danmakuEnabled = it
                UserPreference.setDanmakuEnabled(it)
            }
        )

        // —— 弹幕颜色：一排圆点，选中描边 ——
        SettingLabel(text = "弹幕颜色")
        ColorDotRow(
            colors = listOf(
                "白" to Color.White,
                "黄" to Color.Yellow,
                "绿" to Color.Green,
                "青" to Color.Cyan,
                "粉" to Color(0xFFFF69B4),
                "红" to Color.Red
            ),
            selectedColor = Color(danmakuColor),
            onSelect = {
                danmakuColor = it.toArgb()
                UserPreference.setDanmakuColor(it.toArgb())
            }
        )

        // —— 弹幕字号：0.5 ~ 2.5 倍 ——
        SettingLabel(text = "弹幕字号（${"%.1f".format(textScale)}×）")
        Slider(
            value = textScale,
            onValueChange = {
                textScale = it
                UserPreference.setDanmakuTextScale(it)
            },
            valueRange = 0.5f..2.5f,
            modifier = Modifier.fillMaxWidth()
        )

        // —— 弹幕源 API：模板，{keyword} 会被替换成片名 ——
        OutlinedTextField(
            value = danmakuApi,
            onValueChange = {
                danmakuApi = it
                UserPreference.setDanmakuApi(it)
            },
            label = { Text(text = "弹幕源 API") },
            placeholder = { Text(text = "模板，{keyword} 会被替换成片名，为空则不拉取") },
            singleLine = true,
            modifier = Modifier.fillMaxWidth()
        )

        // —— 播放器内核：ExoPlayer / 系统播放器 ——
        SettingLabel(text = "播放器内核")
        RadioRow(
            label = "ExoPlayer",
            selected = playerCore == UserPreference.PLAYER_CORE_EXO,
            onClick = {
                playerCore = UserPreference.PLAYER_CORE_EXO
                UserPreference.setPlayerCore(UserPreference.PLAYER_CORE_EXO)
            }
        )
        RadioRow(
            label = "系统播放器",
            selected = playerCore == UserPreference.PLAYER_CORE_SYSTEM,
            onClick = {
                playerCore = UserPreference.PLAYER_CORE_SYSTEM
                UserPreference.setPlayerCore(UserPreference.PLAYER_CORE_SYSTEM)
            }
        )
    }
}

// ======================================================================
// 主题设置
// ======================================================================

/** 主题设置卡片：主题模式 / 背景。改完即时生效（偏好内部推 Flow + 事件）。 */
@Composable
private fun ThemeSettingsCard() {
    var themeMode by remember { mutableStateOf(UserPreference.getThemeMode()) }
    var bgMode by remember { mutableStateOf(UserPreference.getBgMode()) }
    var bgColor by remember { mutableStateOf(UserPreference.getBgColor()) }
    var bgUrl by remember { mutableStateOf(UserPreference.getBgImageUrl()) }
    // 本地背景路径只展示：设置页不提供选择器（由其它入口写入）
    val bgPath = remember { UserPreference.getBgImagePath() }

    SettingsCard(title = "主题设置") {
        // —— 主题模式 ——
        SettingLabel(text = "主题模式")
        RadioRow(
            label = "跟随系统",
            selected = themeMode == "system",
            onClick = {
                themeMode = "system"
                UserPreference.setThemeMode("system")
            }
        )
        RadioRow(
            label = "浅色",
            selected = themeMode == "light",
            onClick = {
                themeMode = "light"
                UserPreference.setThemeMode("light")
            }
        )
        RadioRow(
            label = "深色",
            selected = themeMode == "dark",
            onClick = {
                themeMode = "dark"
                UserPreference.setThemeMode("dark")
            }
        )

        // —— 背景 ——
        SettingLabel(text = "背景")
        RadioRow(
            label = "无",
            selected = bgMode == "none",
            onClick = {
                bgMode = "none"
                UserPreference.setBgMode("none")
            }
        )
        RadioRow(
            label = "纯色",
            selected = bgMode == "color",
            onClick = {
                bgMode = "color"
                UserPreference.setBgMode("color")
            }
        )
        RadioRow(
            label = "图片",
            selected = bgMode == "image",
            onClick = {
                bgMode = "image"
                UserPreference.setBgMode("image")
            }
        )

        // 纯色模式：选颜色
        if (bgMode == "color") {
            ColorDotRow(
                colors = listOf(
                    "黑" to Color.Black,
                    "深灰" to Color(0xFF1C1C1E),
                    "藏青" to Color(0xFF1A2332),
                    "墨绿" to Color(0xFF1E3A2B),
                    "酒红" to Color(0xFF3E1F1F),
                    "白" to Color.White
                ),
                selectedColor = Color(bgColor),
                onSelect = {
                    bgColor = it.toArgb()
                    UserPreference.setBgColor(it.toArgb())
                }
            )
        }

        // 图片模式：网络 URL 输入 + 本地路径展示 + 清除按钮
        if (bgMode == "image") {
            OutlinedTextField(
                value = bgUrl,
                onValueChange = {
                    bgUrl = it
                    UserPreference.setBgImageUrl(it)
                },
                label = { Text(text = "网络背景 URL") },
                placeholder = { Text(text = "https://…") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth()
            )
            if (bgPath.isNotBlank()) {
                Text(
                    text = "本地背景：$bgPath",
                    fontSize = 12.sp,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            }
            Button(
                onClick = {
                    // 清除自定义背景：模式回"无"，URL 和本地路径一起清空
                    UserPreference.setBgMode("none")
                    UserPreference.setBgImageUrl("")
                    UserPreference.setBgImagePath("")
                    bgMode = "none"
                    bgUrl = ""
                },
                modifier = Modifier.fillMaxWidth()
            ) {
                Text(text = "清除自定义背景")
            }
        }
    }
}

// ======================================================================
// 解析接口
// ======================================================================

/** 解析接口卡片：列表展示 + 删除 + 新增（名称 / 地址 / 类型）。 */
@Composable
private fun ParseApiCard() {
    var apis by remember { mutableStateOf(UserPreference.getParseApis()) }
    // 新增表单是否展开
    var adding by remember { mutableStateOf(false) }
    var newName by remember { mutableStateOf("") }
    var newUrl by remember { mutableStateOf("") }
    var newType by remember { mutableStateOf(ParseApi.TYPE_JSON) }
    var error by remember { mutableStateOf("") }

    SettingsCard(title = "解析接口") {
        // —— 已有接口：名称 + 地址 + 删除 ——
        apis.forEach { api ->
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = api.name,
                        fontSize = 15.sp,
                        fontWeight = FontWeight.Medium,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                    Text(
                        text = (if (api.type == ParseApi.TYPE_URL) "[302跳转] " else "[JSON] ") + api.url,
                        fontSize = 12.sp,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }
                IconButton(
                    onClick = {
                        apis = apis - api
                        UserPreference.setParseApis(apis)
                    }
                ) {
                    Icon(
                        imageVector = Icons.Filled.Delete,
                        contentDescription = "删除${api.name}"
                    )
                }
            }
        }

        if (apis.isEmpty() && !adding) {
            Text(
                text = "还没有配置解析接口",
                fontSize = 13.sp,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }

        // —— 新增 ——
        if (adding) {
            OutlinedTextField(
                value = newName,
                onValueChange = { newName = it },
                label = { Text(text = "名称") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth()
            )
            OutlinedTextField(
                value = newUrl,
                onValueChange = { newUrl = it },
                label = { Text(text = "地址") },
                placeholder = { Text(text = "https://…") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth()
            )
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                RadioRow(
                    label = "JSON",
                    selected = newType == ParseApi.TYPE_JSON,
                    onClick = { newType = ParseApi.TYPE_JSON },
                    modifier = Modifier.weight(1f)
                )
                Spacer(modifier = Modifier.width(16.dp))
                RadioRow(
                    label = "302跳转",
                    selected = newType == ParseApi.TYPE_URL,
                    onClick = { newType = ParseApi.TYPE_URL },
                    modifier = Modifier.weight(1f)
                )
            }
            if (error.isNotBlank()) {
                Text(
                    text = error,
                    fontSize = 13.sp,
                    color = MaterialTheme.colorScheme.error
                )
            }
            Button(
                onClick = {
                    val api = ParseApi(
                        name = newName.trim(),
                        url = newUrl.trim(),
                        type = newType
                    )
                    if (!api.isValid) {
                        error = "名称和地址都要填，地址以 http 开头"
                        return@Button
                    }
                    apis = apis + api
                    UserPreference.setParseApis(apis)
                    // 保存成功：收起表单并清空
                    newName = ""
                    newUrl = ""
                    newType = ParseApi.TYPE_JSON
                    error = ""
                    adding = false
                },
                modifier = Modifier.fillMaxWidth()
            ) {
                Text(text = "保存")
            }
        } else {
            OutlinedButton(onClick = { adding = true }) {
                Icon(
                    imageVector = Icons.Filled.Add,
                    contentDescription = null
                )
                Spacer(modifier = Modifier.width(4.dp))
                Text(text = "新增")
            }
        }
    }
}

// ======================================================================
// 通用小组件
// ======================================================================

/** 设置分组卡片：标题 + 内容。 */
@Composable
private fun SettingsCard(
    title: String,
    content: @Composable ColumnScope.() -> Unit
) {
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Text(
                text = title,
                fontSize = 16.sp,
                fontWeight = FontWeight.Bold
            )
            content()
        }
    }
}

/** 分组内的小标题。 */
@Composable
private fun SettingLabel(text: String) {
    Text(
        text = text,
        fontSize = 13.sp,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
        modifier = Modifier.padding(top = 4.dp)
    )
}

/** 开关行：左文字右 Switch。 */
@Composable
private fun SwitchRow(
    label: String,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = label,
            fontSize = 15.sp,
            modifier = Modifier.weight(1f)
        )
        Switch(
            checked = checked,
            onCheckedChange = onCheckedChange
        )
    }
}

/** 单选行：整行可点，前面是 RadioButton。 */
@Composable
private fun RadioRow(
    label: String,
    selected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier.fillMaxWidth()
) {
    Row(
        modifier = modifier
            .clip(RoundedCornerShape(8.dp))
            .clickable(onClick = onClick)
            .padding(vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        RadioButton(
            selected = selected,
            onClick = onClick
        )
        Spacer(modifier = Modifier.width(8.dp))
        Text(
            text = label,
            fontSize = 15.sp
        )
    }
}

/**
 * 圆形颜色选项：一排圆点，选中的描边加粗 + 打勾。
 *
 * @param colors 选项（名称, 颜色）
 * @param selectedColor 当前选中的颜色
 */
@Composable
private fun ColorDotRow(
    colors: List<Pair<String, Color>>,
    selectedColor: Color,
    onSelect: (Color) -> Unit
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        colors.forEach { (name, color) ->
            val selected = color == selectedColor
            Box(
                modifier = Modifier
                    .size(40.dp)
                    .clip(CircleShape)
                    .background(color)
                    .border(
                        width = if (selected) 3.dp else 1.dp,
                        color = if (selected) MaterialTheme.colorScheme.primary else Color.Gray,
                        shape = CircleShape
                    )
                    .clickable { onSelect(color) },
                contentAlignment = Alignment.Center
            ) {
                if (selected) {
                    // 白色圆点上用黑勾，其它用白勾，保证看得见
                    Icon(
                        imageVector = Icons.Filled.Check,
                        contentDescription = "$name已选中",
                        tint = if (color == Color.White) Color.Black else Color.White,
                        modifier = Modifier.size(20.dp)
                    )
                }
            }
        }
    }
}
