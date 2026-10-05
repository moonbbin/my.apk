package com.tvbox.shell.ui.component

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.tvbox.shell.config.SiteSource

/**
 * 配置源选择器（模块七：首页顶部**长按标题**弹出）。
 *
 * 跟 [SitePickerSheet] 是同一套壳子 —— 同样的搜索框、同样的行样式、同样的空提示，
 * 差别只有两处：数据源是 [SiteSource]，以及**选中回调是异步的**
 * （换源要真联网拉一份新配置，不是本地切一下就完事）。
 *
 * 关于"异步选中"：这里**不做 loading 态**。点完之后 Sheet 立刻关掉、首页转圈，
 * 那条转圈本身就是反馈 —— 在 Sheet 里再压一层菊花，用户要等两个圈，体验更差。
 * 拉不动配置时由首页弹提示（`MSG_SOURCE_EMPTY`）。
 *
 * @param sources   候选配置源（来自 SiteRepository）
 * @param onSelect  选中回调（ViewModel 会落盘 + 拉新配置 + 重载）
 * @param onDismiss 关闭回调
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SourcePickerSheet(
    sources: List<SiteSource>,
    onSelect: (SiteSource) -> Unit,
    onDismiss: () -> Unit
) {
    var keyword by rememberSaveable { mutableStateOf("") }

    val filtered = remember(sources, keyword) { filterSources(sources, keyword) }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        containerColor = PickerSheetBackground
    ) {
        Column(modifier = Modifier.fillMaxWidth()) {
            Text(
                text = "切换配置源",
                fontSize = 17.sp,
                fontWeight = FontWeight.SemiBold,
                color = PickerTitleColor,
                modifier = Modifier.padding(start = 20.dp, end = 20.dp, bottom = 10.dp)
            )

            PickerSearchField(
                keyword = keyword,
                onKeywordChange = { keyword = it },
                placeholder = "搜索配置源名或地址"
            )

            Spacer(modifier = Modifier.height(8.dp))

            when {
                sources.isEmpty() -> PickerEmptyHint("还没有配置源，去「设置 → 站点管理」加一个")
                filtered.isEmpty() -> PickerEmptyHint("未找到匹配的配置源")
                else -> LazyColumn(
                    modifier = Modifier
                        .fillMaxWidth()
                        .heightIn(max = 420.dp),
                    contentPadding = PaddingValues(horizontal = 10.dp, vertical = 4.dp),
                    verticalArrangement = Arrangement.spacedBy(2.dp)
                ) {
                    // 下标当 key：SiteSource 的 id 理论上唯一，但历史脏数据里出现过重复 id
                    // （早期版本用 Gson 直接灌列表，id 补过一轮），拿它当 key 会直接抛异常。
                    itemsIndexed(filtered) { _, source ->
                        PickerRow(
                            name = source.name.ifBlank { "未命名配置源" },
                            subtitle = source.url,
                            selected = source.isSelected,
                            onClick = { onSelect(source) }
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(28.dp))
        }
    }
}

/**
 * 过滤：名字或地址命中关键词就留下，空关键词返回原表（顺序不动）。
 */
private fun filterSources(sources: List<SiteSource>, keyword: String): List<SiteSource> {
    val kw = keyword.trim()
    if (kw.isEmpty()) return sources
    return sources.filter {
        it.name.contains(kw, ignoreCase = true) || it.url.contains(kw, ignoreCase = true)
    }
}
