#!/bin/bash
# 33_search_page_polish.sh - 搜索页视觉微调（方案A全量覆盖）
# 本脚本为 SearchScreen.kt 的唯一最终控制权，后续所有搜索页修改均在此进行。
# 注意：25_music_pages_wire.sh 也会写 SearchScreen.kt，但本脚本编号更大（33 > 25），
# 构建时后运行，覆盖生效。25 的写入仅作为兜底。
# [33v4] 榜单序号三重组合（颜色+字重+透明度），火苗图标accent
set -e
cd avbox

echo "=== 33 v4: 搜索页视觉微调 ==="

TARGET="app/src/main/java/com/github/tvbox/osc/ui/music/search/SearchScreen.kt"

if [ ! -f "$TARGET" ]; then
    echo "✗ 文件不存在: $TARGET（25 未生成？）"
    exit 1
fi

cat << 'KOTLIN_EOF' > "$TARGET"
package com.github.tvbox.osc.ui.music.search

// 本脚本为 SearchScreen.kt 的唯一最终控制权，后续所有搜索页修改均在此进行。
// [33v1]

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.Clear
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Whatshot
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.ui.graphics.Color
import com.github.tvbox.osc.ui.activity.musicColors
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.sp
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp

// ---------- 搜索页 ----------
// 数据结构沿用现有定义，未改动：
// keyword: String（现有搜索关键词状态）
// hotWords: List<String>（现有热搜词，对应 HotSearchCard 的 hotWords 参数）
@Composable
fun SearchScreen(
    keyword: String,
    onKeywordChange: (String) -> Unit,
    hotWords: List<String>,
    onHotWordClick: (String) -> Unit,
    onSearch: (String) -> Unit,
    isSearching: Boolean = false,
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(musicColors().background)
            .padding(horizontal = 16.dp), // 细节1：左右 16dp
    ) {
        Spacer(modifier = Modifier.height(16.dp))

        // 细节2：搜索框——深灰底（surface），无刺眼白块
        OutlinedTextField(
            value = keyword,
            onValueChange = onKeywordChange,
            modifier = Modifier.fillMaxWidth(),
            placeholder = {
                Text(
                    text = "搜索歌曲、歌手",
                    color = musicColors().textHint,
                )
            },
            leadingIcon = {
                Icon(
                    imageVector = Icons.Filled.Search,
                    contentDescription = null,
                    tint = musicColors().textSecondary,
                )
            },
            trailingIcon = {
                when {
                    isSearching -> CircularProgressIndicator(
                        modifier = Modifier.size(20.dp),
                        strokeWidth = 2.dp,
                        color = MaterialTheme.colorScheme.primary,
                    )
                    keyword.isNotEmpty() -> IconButton(onClick = { onKeywordChange("") }) {
                        Icon(
                            imageVector = Icons.Filled.Clear,
                            contentDescription = "清空",
                            tint = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    }
                }
            },
            shape = MaterialTheme.shapes.large,
            singleLine = true,
            keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
            keyboardActions = KeyboardActions(onSearch = { onSearch(keyword) }),
            colors = OutlinedTextFieldDefaults.colors(
                focusedContainerColor = musicColors().cardSecondary,
                unfocusedContainerColor = musicColors().cardSecondary,
                disabledContainerColor = musicColors().cardSecondary,
                focusedTextColor = musicColors().textPrimary,
                unfocusedTextColor = musicColors().textPrimary,
                cursorColor = musicColors().accent,
                focusedBorderColor = Color.Transparent,
                unfocusedBorderColor = Color.Transparent,
                focusedLeadingIconColor = musicColors().textSecondary,
                unfocusedLeadingIconColor = musicColors().textSecondary,
                focusedPlaceholderColor = musicColors().textHint,
                unfocusedPlaceholderColor = MaterialTheme.colorScheme.onSurfaceVariant,
            ),
        )

        Spacer(modifier = Modifier.height(20.dp))

        // 细节3：热搜榜标题——火苗图标 + titleMedium 加粗
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            Icon(
                imageVector = Icons.Filled.Whatshot,
                contentDescription = null,
                tint = musicColors().accent,
                modifier = Modifier.size(20.dp),
            )
            Text(
                text = "热搜榜",
                style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                color = musicColors().textPrimary, // 细节3：标题 onSurface
            )
        }

        Spacer(modifier = Modifier.height(8.dp))

        // 细节4：热搜列表
        LazyColumn(modifier = Modifier.fillMaxSize()) {
            itemsIndexed(hotWords) { index, word ->
                HotSearchItem(
                    rank = index + 1,
                    word = word,
                    onClick = { onHotWordClick(word) },
                )
            }
        }
    }
}

// ---------- 细节4：热搜列表项 ----------
@Composable
private fun HotSearchItem(
    rank: Int,
    word: String,
    onClick: () -> Unit,
) {
    Column(modifier = Modifier.fillMaxWidth()) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .height(56.dp) // 细节4：行高 56dp
            .clickable(onClick = onClick), // 细节4：整行点击
        verticalAlignment = Alignment.CenterVertically,
    ) {
        // 左侧序号：三重组合（颜色+字重+透明度），1/2/3名与后面拉开视觉断层
        Text(
            text = rank.toString(),
            style = when (rank) {
                1 -> MaterialTheme.typography.bodyLarge.copy(fontSize = 22.sp, fontWeight = FontWeight.Black)
                2, 3 -> MaterialTheme.typography.bodyLarge.copy(fontSize = 20.sp, fontWeight = FontWeight.Bold)
                else -> MaterialTheme.typography.bodyLarge.copy(fontSize = 16.sp, fontWeight = FontWeight.Normal)
            },
            color = when (rank) {
                1 -> musicColors().accent
                2, 3 -> musicColors().textPrimary
                else -> musicColors().textHint.copy(alpha = 0.6f)
            },
            textAlign = TextAlign.Center,
            modifier = Modifier.width(32.dp),
        )
        // 中间歌名：单行省略
        Text(
            text = word,
            style = MaterialTheme.typography.bodyLarge,
            color = musicColors().textPrimary,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            modifier = Modifier.weight(1f),
        )
        // 右侧箭头：20dp，onSurfaceVariant
        Icon(
            imageVector = Icons.Filled.ChevronRight,
            contentDescription = null,
            tint = musicColors().textHint,
            modifier = Modifier.size(16.dp),
        )
    }
        HorizontalDivider(
            color = musicColors().divider.copy(alpha = 0.5f),
            thickness = 0.5.dp,
            modifier = Modifier.padding(horizontal = 16.dp)
        )
    }
}

// ---------- 预览 ----------
@Preview(showBackground = true)
@Composable
fun SearchScreenPreview() {
    val demoHot = listOf("夜曲", "海阔天空", "Blinding Lights", "晴天", "七里香", "稻香", "青花瓷")
    MaterialTheme {
        SearchScreen(
            keyword = "",
            onKeywordChange = {},
            hotWords = demoHot,
            onHotWordClick = {},
            onSearch = {},
        )
    }
}
KOTLIN_EOF

echo "✓ SearchScreen.kt 已全量覆盖（33v4）"
echo "=== 33 v4 完成 ==="
