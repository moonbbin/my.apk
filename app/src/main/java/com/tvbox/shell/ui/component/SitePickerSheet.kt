package com.tvbox.shell.ui.component

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Clear
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.tvbox.shell.model.Site

/**
 * 站点选择器（模块七：首页顶部**点标题**弹出）。
 *
 * 数据是现成的（配置里 `type == 3` 的采集站），所以这里不发任何网络、不解析任何 JSON
 * —— 纯展示 + 搜索过滤 + 回调。
 *
 * 为什么要带搜索框：真实配置源里几十上百个站是常态，一路滑到底找"那个能出片的站"
 * 不现实。搜索同时匹配 [Site.name] 与 [Site.api]（用户可能记得的是 api 前缀）。
 *
 * @param sites       候选站点（已由 ViewModel 过滤好）
 * @param currentSite 当前生效的站点（左侧打 ✓）
 * @param onSelect    选中回调（ViewModel 那边负责落盘 + 换站重载）
 * @param onDismiss   关闭回调（点遮罩 / 下拉 / 返回键都会走这里）
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SitePickerSheet(
    sites: List<Site>,
    currentSite: Site?,
    onSelect: (Site) -> Unit,
    onDismiss: () -> Unit
) {
    var keyword by rememberSaveable { mutableStateOf("") }

    val filtered = remember(sites, keyword) { filterSites(sites, keyword) }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        containerColor = PickerSheetBackground
    ) {
        Column(modifier = Modifier.fillMaxWidth()) {
            Text(
                text = "切换站点",
                fontSize = 17.sp,
                fontWeight = FontWeight.SemiBold,
                color = PickerTitleColor,
                modifier = Modifier.padding(start = 20.dp, end = 20.dp, bottom = 10.dp)
            )

            PickerSearchField(
                keyword = keyword,
                onKeywordChange = { keyword = it },
                placeholder = "搜索站点名或 api"
            )

            Spacer(modifier = Modifier.height(8.dp))

            if (filtered.isEmpty()) {
                PickerEmptyHint("未找到匹配的站点")
            } else {
                LazyColumn(
                    modifier = Modifier
                        .fillMaxWidth()
                        .heightIn(max = 420.dp),
                    contentPadding = PaddingValues(horizontal = 10.dp, vertical = 4.dp),
                    verticalArrangement = Arrangement.spacedBy(2.dp)
                ) {
                    // 用下标当 key：同一份配置里重名站、甚至重 api 的站都见过，
                    // 硬拿 api 当 key 会撞车并直接抛异常。
                    itemsIndexed(filtered) { _, site ->
                        PickerRow(
                            name = site.name.ifBlank { "未命名站点" },
                            subtitle = site.api,
                            selected = isSiteSelected(site, currentSite),
                            onClick = { onSelect(site) }
                        )
                    }
                }
            }

            // 底部留白：压过系统导航栏，最后一行不被手势条盖住
            Spacer(modifier = Modifier.height(28.dp))
        }
    }
}

/**
 * 过滤：站点名或 api 命中关键词（大小写不敏感）就留下。
 *
 * 空关键词返回原表，**顺序保持配置原样** —— 不做二次排序。
 * 用户已经习惯按配置里的相对位置找站，这里重排只会让人找不到。
 */
private fun filterSites(sites: List<Site>, keyword: String): List<Site> {
    val kw = keyword.trim()
    if (kw.isEmpty()) return sites
    return sites.filter {
        it.name.contains(kw, ignoreCase = true) || it.api.contains(kw, ignoreCase = true)
    }
}

/** 站点是否就是当前生效的那个：优先比 api（唯一），api 为空再退回比名字。 */
internal fun isSiteSelected(site: Site, current: Site?): Boolean {
    if (current == null) return false
    val currentApi = current.api.trim()
    return if (currentApi.isNotEmpty()) {
        site.api.trim() == currentApi
    } else {
        site.name.trim() == current.name.trim()
    }
}

/**
 * 选择器顶部搜索框。站点 / 配置源两个 Sheet 共用。
 *
 * @param placeholder 提示文案（如"搜索站点名或 api"）
 */
@Composable
internal fun PickerSearchField(
    keyword: String,
    onKeywordChange: (String) -> Unit,
    placeholder: String
) {
    OutlinedTextField(
        value = keyword,
        onValueChange = onKeywordChange,
        singleLine = true,
        placeholder = { Text(placeholder, fontSize = 14.sp, color = PickerCaptionColor) },
        leadingIcon = {
            Icon(imageVector = Icons.Filled.Search, contentDescription = null, tint = PickerCaptionColor)
        },
        trailingIcon = {
            if (keyword.isNotEmpty()) {
                IconButton(onClick = { onKeywordChange("") }) {
                    Icon(
                        imageVector = Icons.Filled.Clear,
                        contentDescription = "清空搜索",
                        tint = PickerCaptionColor
                    )
                }
            }
        },
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
    )
}

/** 选择器的空结果提示。 */
@Composable
internal fun PickerEmptyHint(text: String) {
    Text(
        text = text,
        fontSize = 14.sp,
        color = PickerCaptionColor,
        textAlign = TextAlign.Center,
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 32.dp)
    )
}

/**
 * 选择器里的一行：大字名字 + 小字副标题 + 选中打勾。
 *
 * 站点和配置源两个 Sheet 共用，所以抽出来。注意 [subtitle] 是**原样回显**的：
 * 不要在调用方加"api："这类前缀 —— 配置源那边回显的是 URL，加了前缀反而怪。
 *
 * ✓ 那个位置用固定宽度的槽（[CheckSlotWidth]），没选中时留空白。
 * 这样行文案不会因为"选中/未选中"而左右跳，列表滚动时视觉更稳。
 */
@Composable
internal fun PickerRow(
    name: String,
    subtitle: String,
    selected: Boolean,
    onClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(if (selected) PickerSelectedBackground else Color.Transparent)
            .clickable(onClick = onClick)
            .padding(horizontal = 12.dp, vertical = 11.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier.width(CheckSlotWidth),
            contentAlignment = Alignment.Center
        ) {
            if (selected) {
                Icon(
                    imageVector = Icons.Filled.Check,
                    contentDescription = "当前选中",
                    tint = PickerAccentColor
                )
            }
        }

        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = name,
                fontSize = 15.sp,
                fontWeight = if (selected) FontWeight.SemiBold else FontWeight.Normal,
                color = if (selected) PickerAccentColor else PickerTitleColor,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
            if (subtitle.isNotBlank()) {
                Text(
                    text = subtitle,
                    fontSize = 11.sp,
                    color = PickerCaptionColor,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.padding(top = 2.dp)
                )
            }
        }
    }
}

/** ✓ 槽宽：够放一个 24dp 图标，又不至于把名字挤到第二行。 */
private val CheckSlotWidth = 28.dp

internal val PickerSheetBackground = Color.White
internal val PickerTitleColor = Color(0xFF1C1C1E)
internal val PickerCaptionColor = Color(0xFF8E8E93)
internal val PickerAccentColor = Color(0xFF4338CA)
private val PickerSelectedBackground = Color(0x144338CA)
