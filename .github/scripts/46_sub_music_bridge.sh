#!/bin/bash
set -e
cd "$(dirname "$0")/../.." 2>/dev/null || true

# === 46 v8: 源内音乐 Peek 式（选源 Sheet + 歌单/榜单 Tab 浏览为先、搜索为辅；桥接加 homeContent/categoryContent 链，榜单类优先含 榜/排行/热；tab 也按 Peek 变） ===

echo "=== 46 v8 ==="

cat > avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicBridge.kt << 'KOTEOF'
package com.github.tvbox.osc.ui.activity

// [46v2] 订阅源内音乐桥接：只读主体 ApiConfig 订阅列表，不改主体代码。
// 筛源规则：源名按 ┆ 切段含“音乐”段 + searchable=1；播链：searchContent -> detailContent -> playerContent。

import com.github.tvbox.osc.api.ApiConfig
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.withContext
import org.json.JSONObject

object SubMusicBridge {

    const val PREFS = "sub_music_settings"
    const val KEY_ENABLED = "sub_music_enabled"

    fun isEnabled(context: android.content.Context): Boolean {
        return context.getSharedPreferences(PREFS, android.content.Context.MODE_PRIVATE)
            .getBoolean(KEY_ENABLED, false)
    }

    fun setEnabled(context: android.content.Context, on: Boolean) {
        context.getSharedPreferences(PREFS, android.content.Context.MODE_PRIVATE)
            .edit().putBoolean(KEY_ENABLED, on).apply()
    }

    data class SubSource(val key: String, val displayName: String)

    data class SubTrack(
        val sourceKey: String,
        val sourceName: String,
        val id: String,
        val title: String,
        val pic: String,
        val remark: String
    )

    fun isMusicSource(name: String): Boolean {
        return name.split("┆").any { it.contains("音乐") }
    }

    fun displayName(raw: String): String {
        val segs = raw.split("┆").map { it.trim() }.filter { it.isNotEmpty() }
        val idx = segs.indexOfFirst { it.contains("音乐") }
        return when {
            idx > 0 -> segs[idx - 1]
            idx == 0 && segs.size > 1 -> segs[1]
            else -> raw
        }
    }

    private fun musicBeans(): List<com.github.tvbox.osc.bean.SourceBean> {
        return try {
            ApiConfig.get().getSwitchSourceBeanList()
                .filter { it.isSearchable() && isMusicSource(it.name ?: "") }
        } catch (e: Exception) {
            emptyList()
        }
    }

    fun loadMusicSources(): List<SubSource> {
        return musicBeans().map { SubSource(it.key ?: "", displayName(it.name ?: "")) }
    }

    suspend fun search(keyword: String): List<SubTrack> = withContext(Dispatchers.IO) {
        val beans = musicBeans()
        if (beans.isEmpty()) return@withContext emptyList()
        beans.map { bean ->
            async {
                try {
                    val sp = ApiConfig.get().getCSP(bean)
                    val json = sp.searchContent(keyword, false) ?: return@async emptyList<SubTrack>()
                    val arr = JSONObject(json).optJSONArray("list") ?: return@async emptyList<SubTrack>()
                    val out = mutableListOf<SubTrack>()
                    for (i in 0 until arr.length()) {
                        val o = arr.optJSONObject(i) ?: continue
                        val id = o.optString("vod_id")
                        val title = o.optString("vod_name")
                        if (id.isBlank() || title.isBlank()) continue
                        out.add(
                            SubTrack(
                                bean.key ?: "",
                                displayName(bean.name ?: ""),
                                id,
                                title,
                                o.optString("vod_pic"),
                                o.optString("vod_remarks")
                            )
                        )
                    }
                    out
                } catch (e: Exception) {
                    emptyList()
                }
            }
        }.awaitAll().flatten()
    }

    sealed interface PlayResult {
        data class Ok(val url: String) : PlayResult
        data class Fail(val msg: String) : PlayResult
    }

    suspend fun resolvePlay(track: SubTrack): PlayResult = withContext(Dispatchers.IO) {
        try {
            val bean = ApiConfig.get().getSource(track.sourceKey)
                ?: return@withContext PlayResult.Fail("源已不存在")
            val sp = ApiConfig.get().getCSP(bean)
            val detail = sp.detailContent(listOf(track.id))
                ?: return@withContext PlayResult.Fail("详情为空")
            val d = JSONObject(detail)
            val item = d.optJSONArray("list")?.optJSONObject(0) ?: d
            val from = item.optString("vod_play_from")
            val urls = item.optString("vod_play_url")
            if (from.isBlank() || urls.isBlank()) return@withContext PlayResult.Fail("该条目无播放地址")
            val flag = from.split("$$$")[0]
            val firstGroup = urls.split("$$$")[0]
            val firstEp = firstGroup.split("#")[0]
            val playId = firstEp.substringAfter("$", firstEp)
            val pr = sp.playerContent(flag, playId, ApiConfig.get().getVipParseFlags())
                ?: return@withContext PlayResult.Fail("取播放地址失败")
            val pj = JSONObject(pr)
            val parse = pj.optInt("parse", 0)
            val url = pj.optString("url")
            if (url.isBlank()) return@withContext PlayResult.Fail("播放地址为空")
            if (parse == 1) return@withContext PlayResult.Fail("该源需要解析，源内音乐 v1 暂不支持解析播放")
            PlayResult.Ok(url)
        } catch (e: Exception) {
            PlayResult.Fail("播放失败：${e.message}")
        }
    }
}
KOTEOF

cat > avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicScreen.kt << 'KOTEOF'
package com.github.tvbox.osc.ui.activity

// [46v2] 源内音乐独立页：与落雪搜索/歌单/播放页完全分开；播走 LxPlayerManager.play 裸地址，不进落雪队列。

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
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
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage
import kotlinx.coroutines.launch

@Composable
fun SubMusicScreen(onOpenSettings: () -> Unit) {
    val context = LocalContext.current
    var enabled by remember { mutableStateOf(SubMusicBridge.isEnabled(context)) }
    if (!enabled) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .background(musicColors().background)
                .padding(16.dp),
            verticalArrangement = Arrangement.Center
        ) {
            Text(
                text = "源内音乐已关闭",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = musicColors().textPrimary
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "在设置里打开“源内音乐”开关后，这里会列出订阅源里 ┆音乐┆ 分类的源。",
                style = MaterialTheme.typography.bodyMedium,
                color = musicColors().textSecondary
            )
            Spacer(modifier = Modifier.height(16.dp))
            Button(onClick = {
                enabled = SubMusicBridge.isEnabled(context)
                if (!enabled) onOpenSettings()
            }) {
                Text(text = "去设置开启")
            }
        }
        return
    }

    var keyword by remember { mutableStateOf("") }
    var searching by remember { mutableStateOf(false) }
    var searched by remember { mutableStateOf(false) }
    var results by remember { mutableStateOf<List<SubMusicBridge.SubTrack>>(emptyList()) }
    var notice by remember { mutableStateOf("") }
    var sources by remember { mutableStateOf<List<SubMusicBridge.SubSource>>(emptyList()) }
    val scope = rememberCoroutineScope()
    val nowTitle by LxPlayerManager.currentTitle.collectAsState()
    val playing by LxPlayerManager.isPlaying.collectAsState()

    LaunchedEffect(Unit) {
        sources = SubMusicBridge.loadMusicSources()
    }

    fun doSearch() {
        val kw = keyword.trim()
        if (kw.isEmpty() || searching) return
        searching = true
        searched = false
        notice = ""
        scope.launch {
            try {
                results = SubMusicBridge.search(kw)
                searched = true
            } catch (e: Exception) {
                notice = "搜索失败：${e.message}"
            } finally {
                searching = false
            }
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(musicColors().background)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            TextField(
                value = keyword,
                onValueChange = { keyword = it },
                label = { Text(text = "搜源内音乐") },
                singleLine = true,
                keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
                keyboardActions = KeyboardActions(onSearch = { doSearch() }),
                modifier = Modifier.weight(1f)
            )
            Spacer(modifier = Modifier.width(8.dp))
            Button(onClick = { doSearch() }, enabled = !searching) {
                Text(text = if (searching) "搜…" else "搜索")
            }
        }
        Text(
            text = if (sources.isEmpty()) {
                "暂无音乐源：请先在主体订阅里添加带 ┆音乐┆ 分类的源"
            } else {
                "音乐源：" + sources.joinToString("、") { it.displayName }
            },
            style = MaterialTheme.typography.bodySmall,
            color = musicColors().textSecondary,
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 4.dp)
        )
        if (nowTitle.isNotBlank()) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "正在播：" + nowTitle,
                    style = MaterialTheme.typography.bodyMedium,
                    color = musicColors().textPrimary,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.weight(1f)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Button(onClick = { LxPlayerManager.togglePlayPause() }) {
                    Text(text = if (playing) "暂停" else "继续")
                }
            }
        }
        if (notice.isNotBlank()) {
            Text(
                text = notice,
                style = MaterialTheme.typography.bodySmall,
                color = musicColors().textSecondary,
                modifier = Modifier.padding(horizontal = 16.dp, vertical = 4.dp)
            )
        }
        LazyColumn(modifier = Modifier.fillMaxSize()) {
            items(results, key = { it.sourceKey + ":" + it.id }) { track ->
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable {
                            notice = "正在取播放地址…"
                            scope.launch {
                                when (val r = SubMusicBridge.resolvePlay(track)) {
                                    is SubMusicBridge.PlayResult.Ok -> {
                                        LxPlayerManager.play(r.url, track.title, track.sourceName, track.pic)
                                        notice = ""
                                    }
                                    is SubMusicBridge.PlayResult.Fail -> {
                                        notice = r.msg
                                    }
                                }
                            }
                        }
                        .padding(horizontal = 16.dp, vertical = 10.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    if (track.pic.isNotBlank()) {
                        AsyncImage(
                            model = track.pic,
                            contentDescription = null,
                            contentScale = ContentScale.Crop,
                            modifier = Modifier
                                .size(48.dp)
                                .clip(androidx.compose.foundation.shape.RoundedCornerShape(8.dp))
                        )
                    } else {
                        Box(
                            modifier = Modifier
                                .size(48.dp)
                                .clip(androidx.compose.foundation.shape.RoundedCornerShape(8.dp))
                                .background(musicColors().card),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = track.title.take(1),
                                color = musicColors().textSecondary
                            )
                        }
                    }
                    Spacer(modifier = Modifier.width(12.dp))
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = track.title,
                            style = MaterialTheme.typography.bodyLarge,
                            color = musicColors().textPrimary,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                        Spacer(modifier = Modifier.height(2.dp))
                        Text(
                            text = track.sourceName + if (track.remark.isNotBlank()) " · " + track.remark else "",
                            style = MaterialTheme.typography.bodySmall,
                            color = musicColors().textSecondary,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                    }
                }
            }
            if (searched && results.isEmpty()) {
                item {
                    Text(
                        text = "没有搜到结果",
                        style = MaterialTheme.typography.bodyMedium,
                        color = musicColors().textSecondary,
                        modifier = Modifier.padding(16.dp)
                    )
                }
            }
        }
    }
}
KOTEOF

python3 << 'PYEOF_S'
spath = "avbox/app/src/main/java/com/github/tvbox/osc/ui/music/settings/SettingsScreen.kt"
with open(spath, encoding="utf-8") as f:
    s = f.read()
if "// [46v6]" not in s:
    a = "import androidx.compose.material3.Surface"
    assert s.count(a) == 1, f"settings Surface import count {s.count(a)}"
    if "import androidx.compose.material3.Switch" not in s:
        s = s.replace(a, a + "\nimport androidx.compose.material3.Switch", 1)
    b = """data class SettingItem(
    val title: String,
    val subtitle: String,
    val action: () -> Unit,
)"""
    assert s.count(b) == 1, f"new SettingItem count {s.count(b)}"
    s = s.replace(b, """data class SettingItem(
    val title: String,
    val subtitle: String,
    val action: () -> Unit,
    val isSwitch: Boolean = false, // [46v6]
    val switchChecked: () -> Boolean = { false }, // [46v6]
    val onSwitchChange: ((Boolean) -> Unit)? = null, // [46v6]
)""", 1)
    c = "onClick = item.action, // 细节4：整行点击，直接调现有 action"
    assert s.count(c) == 1, f"row onClick count {s.count(c)}"
    s = s.replace(c, "onClick = { if (item.isSwitch && item.onSwitchChange != null) item.onSwitchChange(!item.switchChecked()) else item.action() }, // [46v6] 开关行点整行也切换", 1)
    d = """        // 右侧：小箭头 20dp，onSurfaceVariant（稍缩小更精致）
        Icon(
            imageVector = Icons.Filled.ChevronRight,
            contentDescription = null,
            tint = musicColors().textSecondary,
            modifier = Modifier.size(20.dp),
        )"""
    assert s.count(d) == 1, f"row trailing count {s.count(d)}"
    s = s.replace(d, """        // 右侧：开关行画 Switch，其余行画小箭头 // [46v6]
        if (item.isSwitch && item.onSwitchChange != null) {
            Switch(
                checked = item.switchChecked(),
                onCheckedChange = item.onSwitchChange,
            )
        } else {
            Icon(
                imageVector = Icons.Filled.ChevronRight,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.size(20.dp),
            )
        }""", 1)
    assert s.count("{") == s.count("}"), "settings brace imbalance"

    # 后验（注释吞码全家桶）：同 MH 块
    for _ln in s.split("\n"):
        if "[46v6]" in _ln and "//" in _ln:
            _tail = _ln.split("//", 1)[1]
            assert not any(_c in _tail for _c in "{}()"), "marker ate code: " + _ln
    with open(spath, "w", encoding="utf-8") as f:
        f.write(s)
    print("OK SettingsScreen 46v6")
else:
    print("skip: SettingsScreen 已有 [46v6]")
PYEOF_S

python3 << 'PYEOF'
import re
import sys

path = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"
with open(path, encoding="utf-8") as f:
    src = f.read()

MARK = "// [46v6]"
if MARK in src:
    print("skip: 46v6 already present")
    sys.exit(0)

# 1. 枚举：容忍 40/41 已加过的表项；末行可能带行尾注释（如 40 的 // [40rec]），SUBMUSIC 必须插在注释之前，绝不追到注释后面
m = re.search(r"enum class MusicTab \{([^}]*)\}", src)
assert m, "MusicTab enum block not found"
body = m.group(1)
assert "SUBMUSIC" not in body, "SUBMUSIC already in enum"
blines = body.split("\n")
for _i, _ln in enumerate(blines):
    if "HOME" in _ln:
        if "//" in _ln:
            _code, _cmt = _ln.split("//", 1)
            blines[_i] = _code.rstrip() + ", SUBMUSIC //" + _cmt
        else:
            blines[_i] = _ln.rstrip() + ", SUBMUSIC"
        break
else:
    assert False, "enum entries line not found"
new_body = "\n".join(blines)
src = src[:m.start(1)] + new_body + src[m.end(1):]
# 后验：SUBMUSIC 必须在代码区，不在注释里
for _ln in new_body.split("\n"):
    if "SUBMUSIC" in _ln:
        assert "//" not in _ln or _ln.index("SUBMUSIC") < _ln.index("//"), "SUBMUSIC fell into comment: " + _ln

# 2. 底栏（32v97 胶囊 tabDefs97，to-pair 形）：在 PLAYLIST 对子后插源内对子；若已变，退到 SETTINGS 对子后
lines = src.split("\n")
done = False
for i, ln in enumerate(lines):
    if 'MusicTab.PLAYLIST to "歌单",' in ln:
        lines.insert(i + 1, '                            MusicTab.SUBMUSIC to "源内",')
        done = True
        break
if not done:
    for i, ln in enumerate(lines):
        if 'MusicTab.SETTINGS to "设置",' in ln:
            lines.insert(i + 1, '                            MusicTab.SUBMUSIC to "源内",')
            done = True
            break
assert done, "no PLAYLIST/SETTINGS pair anchor for tabDefs97"
src = "\n".join(lines)

# 3. when 分支：内容区 SETTINGS 分支（下一行是 MusicSettingsList 调用）闭合后插 SUBMUSIC 分支；
# 32v97 的线条图标 when 里也有 SETTINGS 分支，必须跳过（它下一行是 drawCircle，不是 MusicSettingsList）
lines = src.split("\n")
done = False
for i, ln in enumerate(lines):
    if "MusicTab.SETTINGS -> {" in ln and i + 1 < len(lines) and "MusicSettingsList" in lines[i + 1]:
        j = i + 1
        while j < len(lines) and lines[j].strip() != "}":
            j += 1
        assert j < len(lines), "SETTINGS branch close not found"
        lines.insert(j + 1, "                MusicTab.SUBMUSIC -> {")
        lines.insert(j + 2, "                    SubMusicScreen(onOpenSettings = { selectedTab = MusicTab.SETTINGS }) // [46v6]")
        lines.insert(j + 3, "                }")
        done = True
        break
assert done, "SETTINGS content branch anchor not found"
src = "\n".join(lines)

# 4. [46v6] 开关状态提升到 MusicHomeScreen（底栏门控 + 设置开关共用同一状态）
anchor_state = "    var selectedTab by remember { mutableStateOf(initialTab) }"
assert src.count(anchor_state) == 1, f"selectedTab anchor count {src.count(anchor_state)}"
src = src.replace(anchor_state, anchor_state + "\n    var subMusicOn by remember { mutableStateOf(SubMusicBridge.isEnabled(context)) } // [46v6]", 1)

# 5. [46v6] 底栏门控：开关关时 tabDefs97 里滤掉 SUBMUSIC
anchor_gate = "tabDefs97.forEach { (tab, label) ->"
assert src.count(anchor_gate) == 1, f"tabDefs97 forEach count {src.count(anchor_gate)}"
src = src.replace(anchor_gate, "(if (subMusicOn) tabDefs97 else tabDefs97.filter { it.first != MusicTab.SUBMUSIC }).forEach { (tab, label) ->", 1)

# 6. [46v6] SETTINGS 分支调用点：把开关状态与回写传进设置页
anchor_call = "MusicSettingsList(onComingSoon = ::comingSoon)"
assert src.count(anchor_call) == 1, f"settings call count {src.count(anchor_call)}"
src = src.replace(anchor_call, "MusicSettingsList(onComingSoon = ::comingSoon, subMusicOn = subMusicOn, onSubMusicChange = { v -> subMusicOn = v; SubMusicBridge.setEnabled(context, v); if (!v && selectedTab == MusicTab.SUBMUSIC) selectedTab = MusicTab.SEARCH }) // [46v6]", 1)

# 7. [46v6] MusicSettingsList 签名：接开关状态与回写（默认保持老调用可编译）
anchor_sig = "fun MusicSettingsList(onComingSoon: (String) -> Unit) {"
assert src.count(anchor_sig) == 1, f"settings sig count {src.count(anchor_sig)}"
src = src.replace(anchor_sig, "fun MusicSettingsList(onComingSoon: (String) -> Unit, subMusicOn: Boolean = false, onSubMusicChange: ((Boolean) -> Unit)? = null) { // [46v6]", 1)

# 8. [46v6] 旧 SettingItem 数据类：加开关三字段（默认保持老行不变）
anchor_item = """    data class SettingItem(
        val title: String,
        val subtitle: String,
        val action: () -> Unit
    )"""
assert src.count(anchor_item) == 1, f"old SettingItem count {src.count(anchor_item)}"
src = src.replace(anchor_item, """    data class SettingItem(
        val title: String,
        val subtitle: String,
        val action: () -> Unit,
        val isSwitch: Boolean = false, // [46v6]
        val switchChecked: () -> Boolean = { false }, // [46v6]
        val onSwitchChange: ((Boolean) -> Unit)? = null // [46v6]
    )""", 1)

# 9. [46v6] 映射转发：旧项 -> 新项时把开关字段带过去
anchor_map = "NewSettingItem(title = i.title, subtitle = i.subtitle, action = i.action)"
assert src.count(anchor_map) == 1, f"settings map count {src.count(anchor_map)}"
src = src.replace(anchor_map, "NewSettingItem(title = i.title, subtitle = i.subtitle, action = i.action, isSwitch = i.isSwitch, switchChecked = i.switchChecked, onSwitchChange = i.onSwitchChange) // [46v6]", 1)

# 10. [46v6] 新分组：groups 列表末尾加“源内音乐”开关组
anchor_groups = "    )\n    // NAV_WIRE_V1: 设置新版 UI"
assert src.count(anchor_groups) == 1, f"groups tail count {src.count(anchor_groups)}"
src = src.replace(anchor_groups, """        SettingGroup(
            "源内音乐",
            listOf(
                SettingItem("源内音乐", "识别订阅源里 ┆音乐┆ 分类的源，与落雪分开", {}, isSwitch = true, switchChecked = { subMusicOn }, onSwitchChange = onSubMusicChange) // [46v6]
            )
        ),
    )
    // NAV_WIRE_V1: 设置新版 UI""", 1)


assert src.count("{") == src.count("}"), "brace imbalance after 46v1"
assert src.count("SUBMUSIC") == 5, f"SUBMUSIC count {src.count('SUBMUSIC')}  # enum+pair+branch+gate filter+call-site reset"

# 后验（注释吞码全家桶）：任何带 [46v6] 的行，第一个 // 之后不得再有代码界符 { } ( )，否则标记吃掉了同行代码
for _ln in src.split("\n"):
    if "[46v6]" in _ln and "//" in _ln:
        _tail = _ln.split("//", 1)[1]
        assert not any(_c in _tail for _c in "{}()"), "marker ate code: " + _ln
with open(path, "w", encoding="utf-8") as f:
    f.write(src)
print("OK 46v6")

PYEOF


python3 << 'PYEOF7'
import sys

path = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"
with open(path, encoding="utf-8") as f:
    src = f.read()

if "// [46v7]" in src:
    print("skip: 46v7 already present")
    sys.exit(0)

# 1. 图标 when（TabLineIcon97，Canvas 内 8 格缩进）：补 SUBMUSIC 空分支（只出文字标签、无配套线条图标，属已知待润色项）；否则枚举多一项即非穷尽
a = """                drawLine(color = tint, start = off(6.6f, 19.5f), end = off(17.4f, 19.5f), strokeWidth = sw, cap = cap)
            }
        }"""
assert src.count(a) == 1, f"icon HOME close count {src.count(a)}"
src = src.replace(a, """                drawLine(color = tint, start = off(6.6f, 19.5f), end = off(17.4f, 19.5f), strokeWidth = sw, cap = cap)
            }
            MusicTab.SUBMUSIC -> { } // [46v7]
        }""", 1)

# 2. 旧 SettingItem 数据类：尾随 lambda 劫持——新函数参跟在 action 后面会抢走全部尾随 lambda 调用点的 action，致“缺 action”；改把三字段挪到 action 之前，尾随 lambda 仍归 action
b = """    data class SettingItem(
        val title: String,
        val subtitle: String,
        val action: () -> Unit,
        val isSwitch: Boolean = false, // [46v6]
        val switchChecked: () -> Boolean = { false }, // [46v6]
        val onSwitchChange: ((Boolean) -> Unit)? = null // [46v6]
    )"""
assert src.count(b) == 1, f"v6 dataclass count {src.count(b)}"
src = src.replace(b, """    data class SettingItem(
        val title: String,
        val subtitle: String,
        val isSwitch: Boolean = false, // [46v7]
        val switchChecked: () -> Boolean = { false }, // [46v7]
        val onSwitchChange: ((Boolean) -> Unit)? = null, // [46v7]
        val action: () -> Unit
    )""", 1)

# 3. 源内音乐项：重排后位置参变了，action 改具名，免得 {} 落到 isSwitch 上
c = 'SettingItem("源内音乐", "识别订阅源里 ┆音乐┆ 分类的源，与落雪分开", {}, isSwitch = true, switchChecked = { subMusicOn }, onSwitchChange = onSubMusicChange) // [46v6]'
assert src.count(c) == 1, f"submusic item count {src.count(c)}"
src = src.replace(c, 'SettingItem("源内音乐", "识别订阅源里 ┆音乐┆ 分类的源，与落雪分开", action = {}, isSwitch = true, switchChecked = { subMusicOn }, onSwitchChange = onSubMusicChange) // [46v7]', 1)

# 后验：[46v7] 行 // 之后不得有代码界符
for _ln in src.split("\n"):
    if "[46v7]" in _ln and "//" in _ln:
        _tail = _ln.split("//", 1)[1]
        assert not any(_c in _tail for _c in "{}()"), "marker ate code: " + _ln
assert src.count("{") == src.count("}"), "MH brace imbalance"

with open(path, "w", encoding="utf-8") as f:
    f.write(src)
print("OK 46v7")
PYEOF7

cat > avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicBridge.kt << 'KOTEOF8'
package com.github.tvbox.osc.ui.activity

// [46v8] 订阅源内音乐桥接：只读主体 ApiConfig 订阅列表，不改主体代码。
// 筛源规则：源名按 ┆ 切段含“音乐”段 + searchable=1；播链：searchContent -> detailContent -> playerContent。
// 浏览链（Peek 式）：homeContent -> class/list；categoryContent(tid, "1") -> list；榜单类优先含 榜/排行/热 的分类。

import com.github.tvbox.osc.api.ApiConfig
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject

object SubMusicBridge {

    const val PREFS = "sub_music_settings"
    const val KEY_ENABLED = "sub_music_enabled"

    fun isEnabled(context: android.content.Context): Boolean {
        return context.getSharedPreferences(PREFS, android.content.Context.MODE_PRIVATE)
            .getBoolean(KEY_ENABLED, false)
    }

    fun setEnabled(context: android.content.Context, on: Boolean) {
        context.getSharedPreferences(PREFS, android.content.Context.MODE_PRIVATE)
            .edit().putBoolean(KEY_ENABLED, on).apply()
    }

    data class SubSource(val key: String, val displayName: String)

    data class SubTrack(
        val sourceKey: String,
        val sourceName: String,
        val id: String,
        val title: String,
        val pic: String,
        val remark: String
    )

    data class SubClass(val id: String, val name: String)

    data class SubHome(val classes: List<SubClass>, val items: List<SubTrack>)

    fun isMusicSource(name: String): Boolean {
        return name.split("┆").any { it.contains("音乐") }
    }

    fun displayName(raw: String): String {
        val segs = raw.split("┆").map { it.trim() }.filter { it.isNotEmpty() }
        val idx = segs.indexOfFirst { it.contains("音乐") }
        return when {
            idx > 0 -> segs[idx - 1]
            idx == 0 && segs.size > 1 -> segs[1]
            else -> raw
        }
    }

    private fun musicBeans(): List<com.github.tvbox.osc.bean.SourceBean> {
        return try {
            ApiConfig.get().getSwitchSourceBeanList()
                .filter { it.isSearchable() && isMusicSource(it.name ?: "") }
        } catch (e: Exception) {
            emptyList()
        }
    }

    fun loadMusicSources(): List<SubSource> {
        return musicBeans().map { SubSource(it.key ?: "", displayName(it.name ?: "")) }
    }

    private fun parseTrackList(arr: JSONArray?, sourceKey: String, sourceName: String): List<SubTrack> {
        if (arr == null) return emptyList()
        val out = mutableListOf<SubTrack>()
        for (i in 0 until arr.length()) {
            val o = arr.optJSONObject(i) ?: continue
            val id = o.optString("vod_id")
            val title = o.optString("vod_name")
            if (id.isBlank() || title.isBlank()) continue
            out.add(
                SubTrack(
                    sourceKey,
                    sourceName,
                    id,
                    title,
                    o.optString("vod_pic"),
                    o.optString("vod_remarks")
                )
            )
        }
        return out
    }

    suspend fun search(keyword: String): List<SubTrack> = withContext(Dispatchers.IO) {
        val beans = musicBeans()
        if (beans.isEmpty()) return@withContext emptyList()
        beans.map { bean ->
            async {
                try {
                    val sp = ApiConfig.get().getCSP(bean)
                    val json = sp.searchContent(keyword, false) ?: return@async emptyList<SubTrack>()
                    val arr = JSONObject(json).optJSONArray("list") ?: return@async emptyList<SubTrack>()
                    parseTrackList(arr, bean.key ?: "", displayName(bean.name ?: ""))
                } catch (e: Exception) {
                    emptyList()
                }
            }
        }.awaitAll().flatten()
    }

    suspend fun home(sourceKey: String): SubHome = withContext(Dispatchers.IO) {
        try {
            val bean = ApiConfig.get().getSource(sourceKey) ?: return@withContext SubHome(emptyList(), emptyList())
            val sp = ApiConfig.get().getCSP(bean)
            val json = sp.homeContent(false) ?: return@withContext SubHome(emptyList(), emptyList())
            val jo = JSONObject(json)
            val classes = mutableListOf<SubClass>()
            val carr = jo.optJSONArray("class")
            if (carr != null) {
                for (i in 0 until carr.length()) {
                    val o = carr.optJSONObject(i) ?: continue
                    val id = o.optString("type_id").ifBlank { o.optString("id") }
                    val name = o.optString("type_name").ifBlank { o.optString("name") }
                    if (id.isNotBlank() && name.isNotBlank()) classes.add(SubClass(id, name))
                }
            }
            val items = parseTrackList(jo.optJSONArray("list"), sourceKey, displayName(bean.name ?: ""))
            SubHome(classes, items)
        } catch (e: Exception) {
            SubHome(emptyList(), emptyList())
        }
    }

    fun chartClass(classes: List<SubClass>): SubClass? {
        return classes.firstOrNull {
            it.name.contains("榜") || it.name.contains("排行") || it.name.contains("热")
        } ?: classes.firstOrNull()
    }

    suspend fun category(sourceKey: String, tid: String): List<SubTrack> = withContext(Dispatchers.IO) {
        try {
            val bean = ApiConfig.get().getSource(sourceKey) ?: return@withContext emptyList()
            val sp = ApiConfig.get().getCSP(bean)
            val json = sp.categoryContent(tid, "1", false, HashMap()) ?: return@withContext emptyList()
            val jo = JSONObject(json)
            parseTrackList(jo.optJSONArray("list"), sourceKey, displayName(bean.name ?: ""))
        } catch (e: Exception) {
            emptyList()
        }
    }

    sealed interface PlayResult {
        data class Ok(val url: String) : PlayResult
        data class Fail(val msg: String) : PlayResult
    }

    suspend fun resolvePlay(track: SubTrack): PlayResult = withContext(Dispatchers.IO) {
        try {
            val bean = ApiConfig.get().getSource(track.sourceKey)
                ?: return@withContext PlayResult.Fail("源已不存在")
            val sp = ApiConfig.get().getCSP(bean)
            val detail = sp.detailContent(listOf(track.id))
                ?: return@withContext PlayResult.Fail("详情为空")
            val d = JSONObject(detail)
            val item = d.optJSONArray("list")?.optJSONObject(0) ?: d
            val from = item.optString("vod_play_from")
            val urls = item.optString("vod_play_url")
            if (from.isBlank() || urls.isBlank()) return@withContext PlayResult.Fail("该条目无播放地址")
            val flag = from.split("$$$")[0]
            val firstGroup = urls.split("$$$")[0]
            val firstEp = firstGroup.split("#")[0]
            val playId = firstEp.substringAfter("$", firstEp)
            val pr = sp.playerContent(flag, playId, ApiConfig.get().getVipParseFlags())
                ?: return@withContext PlayResult.Fail("取播放地址失败")
            val pj = JSONObject(pr)
            val parse = pj.optInt("parse", 0)
            val url = pj.optString("url")
            if (url.isBlank()) return@withContext PlayResult.Fail("播放地址为空")
            if (parse == 1) return@withContext PlayResult.Fail("该源需要解析，源内音乐 v1 暂不支持解析播放")
            PlayResult.Ok(url)
        } catch (e: Exception) {
            PlayResult.Fail("播放失败：${e.message}")
        }
    }
}
KOTEOF8

cat > avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicScreen.kt << 'KOTEOF8'
package com.github.tvbox.osc.ui.activity

// [46v8] 源内音乐 Peek 式页：选源 Sheet + 歌单/榜单 Tab 浏览为先，搜索退为辅助；与落雪搜索/歌单/播放页完全分开；播走 LxPlayerManager.play 裸地址，不进落雪队列。

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import coil.compose.AsyncImage
import kotlinx.coroutines.launch

@Composable
fun SubMusicScreen(onOpenSettings: () -> Unit) {
    val context = LocalContext.current
    var enabled by remember { mutableStateOf(SubMusicBridge.isEnabled(context)) }
    if (!enabled) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .background(musicColors().background)
                .padding(16.dp),
            verticalArrangement = Arrangement.Center
        ) {
            Text(
                text = "源内音乐已关闭",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = musicColors().textPrimary
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "在设置里打开“源内音乐”开关后，这里会列出订阅源里 ┆音乐┆ 分类的源。",
                style = MaterialTheme.typography.bodyMedium,
                color = musicColors().textSecondary
            )
            Spacer(modifier = Modifier.height(16.dp))
            Button(onClick = {
                enabled = SubMusicBridge.isEnabled(context)
                if (!enabled) onOpenSettings()
            }) {
                Text(text = "去设置开启")
            }
        }
        return
    }

    var sources by remember { mutableStateOf<List<SubMusicBridge.SubSource>>(emptyList()) }
    var selected by remember { mutableStateOf<SubMusicBridge.SubSource?>(null) }
    var showSourceSheet by remember { mutableStateOf(false) }
    var tab by remember { mutableStateOf(0) }
    var home by remember { mutableStateOf<SubMusicBridge.SubHome?>(null) }
    var browseItems by remember { mutableStateOf<List<SubMusicBridge.SubTrack>>(emptyList()) }
    var browseLoading by remember { mutableStateOf(false) }
    var browseNote by remember { mutableStateOf("") }
    var keyword by remember { mutableStateOf("") }
    var searching by remember { mutableStateOf(false) }
    var searched by remember { mutableStateOf(false) }
    var results by remember { mutableStateOf<List<SubMusicBridge.SubTrack>>(emptyList()) }
    var notice by remember { mutableStateOf("") }
    val scope = rememberCoroutineScope()
    val nowTitle by LxPlayerManager.currentTitle.collectAsState()
    val playing by LxPlayerManager.isPlaying.collectAsState()

    fun applyTab(src: SubMusicBridge.SubSource, t: Int, h: SubMusicBridge.SubHome?) {
        if (t == 0) {
            browseItems = h?.items ?: emptyList()
            browseNote = if (h == null || h.items.isEmpty()) "该源暂无浏览内容，可用上方搜索" else ""
            return
        }
        val cls = h?.let { SubMusicBridge.chartClass(it.classes) }
        if (cls == null) {
            browseItems = emptyList()
            browseNote = "该源暂无分类，可用上方搜索"
            return
        }
        browseLoading = true
        scope.launch {
            try {
                browseItems = SubMusicBridge.category(src.key, cls.id)
                browseNote = if (browseItems.isEmpty()) "该分类暂无内容" else ""
            } catch (e: Exception) {
                browseItems = emptyList()
                browseNote = "加载失败：${e.message}"
            } finally {
                browseLoading = false
            }
        }
    }

    fun loadBrowse(src: SubMusicBridge.SubSource) {
        browseLoading = true
        browseNote = ""
        scope.launch {
            try {
                val h = SubMusicBridge.home(src.key)
                home = h
                browseLoading = false
                applyTab(src, tab, h)
            } catch (e: Exception) {
                browseLoading = false
                home = null
                browseItems = emptyList()
                browseNote = "加载失败：${e.message}"
            }
        }
    }

    LaunchedEffect(Unit) {
        val list = SubMusicBridge.loadMusicSources()
        sources = list
        val first = list.firstOrNull()
        if (first != null) {
            selected = first
            loadBrowse(first)
        }
    }

    fun doSearch() {
        val kw = keyword.trim()
        if (kw.isEmpty() || searching) return
        searching = true
        searched = false
        notice = ""
        scope.launch {
            try {
                results = SubMusicBridge.search(kw)
                searched = true
            } catch (e: Exception) {
                notice = "搜索失败：${e.message}"
            } finally {
                searching = false
            }
        }
    }

    fun playTrack(track: SubMusicBridge.SubTrack) {
        notice = "正在取播放地址…"
        scope.launch {
            when (val r = SubMusicBridge.resolvePlay(track)) {
                is SubMusicBridge.PlayResult.Ok -> {
                    LxPlayerManager.play(r.url, track.title, track.sourceName, track.pic)
                    notice = ""
                }
                is SubMusicBridge.PlayResult.Fail -> {
                    notice = r.msg
                }
            }
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(musicColors().background)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "当前源：" + (selected?.displayName ?: "无音乐源"),
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.SemiBold,
                color = musicColors().textPrimary,
                modifier = Modifier
                    .weight(1f)
                    .clickable(enabled = sources.isNotEmpty()) { showSourceSheet = true },
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
            Spacer(modifier = Modifier.width(8.dp))
            Text(
                text = "换源",
                style = MaterialTheme.typography.bodyMedium,
                color = musicColors().accent,
                modifier = Modifier.clickable(enabled = sources.isNotEmpty()) { showSourceSheet = true }
            )
        }
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 4.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            TextField(
                value = keyword,
                onValueChange = { keyword = it },
                label = { Text(text = "搜源内音乐") },
                singleLine = true,
                keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
                keyboardActions = KeyboardActions(onSearch = { doSearch() }),
                modifier = Modifier.weight(1f)
            )
            Spacer(modifier = Modifier.width(8.dp))
            Button(onClick = { doSearch() }, enabled = !searching) {
                Text(text = if (searching) "搜…" else "搜索")
            }
        }
        if (sources.isEmpty()) {
            Text(
                text = "暂无音乐源：请先在主体订阅里添加带 ┆音乐┆ 分类的源",
                style = MaterialTheme.typography.bodySmall,
                color = musicColors().textSecondary,
                modifier = Modifier.padding(horizontal = 16.dp, vertical = 4.dp)
            )
        }
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            listOf("歌单", "榜单").forEachIndexed { i, label ->
                Column(
                    modifier = Modifier
                        .clickable {
                            if (tab != i) {
                                tab = i
                                val src = selected
                                if (src != null) applyTab(src, i, home)
                            }
                        }
                        .padding(horizontal = 12.dp, vertical = 4.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text(
                        text = label,
                        style = MaterialTheme.typography.bodyLarge,
                        fontWeight = if (tab == i) FontWeight.Bold else FontWeight.Normal,
                        color = if (tab == i) musicColors().accent else musicColors().textSecondary
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Box(
                        modifier = Modifier
                            .width(20.dp)
                            .height(2.dp)
                            .background(if (tab == i) musicColors().accent else musicColors().background)
                    )
                }
            }
            Spacer(modifier = Modifier.weight(1f))
            if (searched) {
                Text(
                    text = "回浏览",
                    style = MaterialTheme.typography.bodyMedium,
                    color = musicColors().accent,
                    modifier = Modifier.clickable {
                        searched = false
                        keyword = ""
                    }
                )
            }
        }
        if (nowTitle.isNotBlank()) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "正在播：" + nowTitle,
                    style = MaterialTheme.typography.bodyMedium,
                    color = musicColors().textPrimary,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.weight(1f)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Button(onClick = { LxPlayerManager.togglePlayPause() }) {
                    Text(text = if (playing) "暂停" else "继续")
                }
            }
        }
        if (notice.isNotBlank()) {
            Text(
                text = notice,
                style = MaterialTheme.typography.bodySmall,
                color = musicColors().textSecondary,
                modifier = Modifier.padding(horizontal = 16.dp, vertical = 4.dp)
            )
        }
        if (searched) {
            LazyColumn(modifier = Modifier.fillMaxSize()) {
                items(results, key = { it.sourceKey + ":" + it.id }) { track ->
                    SubTrackRow(track = track, onPlay = { playTrack(track) })
                }
                if (results.isEmpty()) {
                    item {
                        Text(
                            text = "没有搜到结果",
                            style = MaterialTheme.typography.bodyMedium,
                            color = musicColors().textSecondary,
                            modifier = Modifier.padding(16.dp)
                        )
                    }
                }
            }
        } else if (browseLoading) {
            Text(
                text = "正在加载浏览内容…",
                style = MaterialTheme.typography.bodyMedium,
                color = musicColors().textSecondary,
                modifier = Modifier.padding(16.dp)
            )
        } else if (browseNote.isNotBlank()) {
            Text(
                text = browseNote,
                style = MaterialTheme.typography.bodyMedium,
                color = musicColors().textSecondary,
                modifier = Modifier.padding(16.dp)
            )
        } else {
            LazyColumn(modifier = Modifier.fillMaxSize()) {
                items(browseItems, key = { it.sourceKey + ":" + it.id }) { track ->
                    SubTrackRow(track = track, onPlay = { playTrack(track) })
                }
            }
        }
    }

    if (showSourceSheet) {
        Dialog(onDismissRequest = { showSourceSheet = false }) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(androidx.compose.foundation.shape.RoundedCornerShape(16.dp))
                    .background(musicColors().card)
                    .padding(16.dp)
            ) {
                Text(
                    text = "选择音乐源",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = musicColors().textPrimary
                )
                Spacer(modifier = Modifier.height(12.dp))
                LazyColumn(modifier = Modifier.heightIn(max = 320.dp)) {
                    items(sources, key = { it.key }) { src ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable {
                                    selected = src
                                    showSourceSheet = false
                                    loadBrowse(src)
                                }
                                .padding(vertical = 10.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = src.displayName,
                                style = MaterialTheme.typography.bodyLarge,
                                color = if (src.key == selected?.key) musicColors().accent else musicColors().textPrimary,
                                modifier = Modifier.weight(1f)
                            )
                            if (src.key == selected?.key) {
                                Text(
                                    text = "已选",
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = musicColors().accent
                                )
                            }
                        }
                    }
                }
                Spacer(modifier = Modifier.height(12.dp))
                Button(onClick = { showSourceSheet = false }) {
                    Text(text = "取消")
                }
            }
        }
    }
}

@Composable
private fun SubTrackRow(track: SubMusicBridge.SubTrack, onPlay: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onPlay() }
            .padding(horizontal = 16.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        if (track.pic.isNotBlank()) {
            AsyncImage(
                model = track.pic,
                contentDescription = null,
                contentScale = ContentScale.Crop,
                modifier = Modifier
                    .size(48.dp)
                    .clip(androidx.compose.foundation.shape.RoundedCornerShape(8.dp))
            )
        } else {
            Box(
                modifier = Modifier
                    .size(48.dp)
                    .clip(androidx.compose.foundation.shape.RoundedCornerShape(8.dp))
                    .background(musicColors().card),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = track.title.take(1),
                    color = musicColors().textSecondary
                )
            }
        }
        Spacer(modifier = Modifier.width(12.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = track.title,
                style = MaterialTheme.typography.bodyLarge,
                color = musicColors().textPrimary,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
            Spacer(modifier = Modifier.height(2.dp))
            Text(
                text = track.sourceName + if (track.remark.isNotBlank()) " · " + track.remark else "",
                style = MaterialTheme.typography.bodySmall,
                color = musicColors().textSecondary,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
        }
    }
}
KOTEOF8
echo "OK 46v8"
echo "=== 46 v8 done ==="

# === 46 v9: 整区源内化（底栏曲库/搜索/我的/设置/首页；顶栏源内源 Sheet；曲库卡片网格；搜索/我的新页；源内 Tab 与开关删除；空源四数诊断） ===

echo "=== 46 v9 ==="

cat > avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicBridge.kt << 'KOTEOF9'
package com.github.tvbox.osc.ui.activity

// [46v8] 订阅源内音乐桥接：只读主体 ApiConfig 订阅列表，不改主体代码。
// 筛源规则：源名按 ┆ 切段含“音乐”段 + searchable=1；播链：searchContent -> detailContent -> playerContent。
// 浏览链（Peek 式）：homeContent -> class/list；categoryContent(tid, "1") -> list；榜单类优先含 榜/排行/热 的分类。

import com.github.tvbox.osc.api.ApiConfig
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject

object SubMusicBridge {

    const val PREFS = "sub_music_settings"
    const val KEY_ENABLED = "sub_music_enabled"

    fun isEnabled(context: android.content.Context): Boolean {
        return context.getSharedPreferences(PREFS, android.content.Context.MODE_PRIVATE)
            .getBoolean(KEY_ENABLED, false)
    }

    fun setEnabled(context: android.content.Context, on: Boolean) {
        context.getSharedPreferences(PREFS, android.content.Context.MODE_PRIVATE)
            .edit().putBoolean(KEY_ENABLED, on).apply()
    }

    data class SubSource(val key: String, val displayName: String)

    data class SubTrack(
        val sourceKey: String,
        val sourceName: String,
        val id: String,
        val title: String,
        val pic: String,
        val remark: String
    )

    data class SubClass(val id: String, val name: String)

    data class SubHome(val classes: List<SubClass>, val items: List<SubTrack>)

    fun isMusicSource(name: String): Boolean {
        return name.split("┆").any { it.contains("音乐") }
    }

    fun displayName(raw: String): String {
        val segs = raw.split("┆").map { it.trim() }.filter { it.isNotEmpty() }
        val idx = segs.indexOfFirst { it.contains("音乐") }
        return when {
            idx > 0 -> segs[idx - 1]
            idx == 0 && segs.size > 1 -> segs[1]
            else -> raw
        }
    }

    private fun musicBeans(): List<com.github.tvbox.osc.bean.SourceBean> {
        return try {
            ApiConfig.get().getSwitchSourceBeanList()
                .filter { it.isSearchable() && isMusicSource(it.name ?: "") }
        } catch (e: Exception) {
            emptyList()
        }
    }

    fun loadMusicSources(): List<SubSource> {
        return musicBeans().map { SubSource(it.key ?: "", displayName(it.name ?: "")) }
    }

    data class SourceDiag(val total: Int, val visible: Int, val nameMatched: Int, val finalCount: Int)

    fun diagnoseSources(): SourceDiag? { // [46v9] 空源诊断：四数定位筛源哪一步掉光
        return try {
            val all = ApiConfig.get().getSourceBeanList()
            val vis = ApiConfig.get().getSwitchSourceBeanList()
            val named = vis.filter { isMusicSource(it.name ?: "") }
            val fin = named.filter { it.isSearchable() }
            SourceDiag(all.size, vis.size, named.size, fin.size)
        } catch (e: Exception) {
            null
        }
    }

    private fun parseTrackList(arr: JSONArray?, sourceKey: String, sourceName: String): List<SubTrack> {
        if (arr == null) return emptyList()
        val out = mutableListOf<SubTrack>()
        for (i in 0 until arr.length()) {
            val o = arr.optJSONObject(i) ?: continue
            val id = o.optString("vod_id")
            val title = o.optString("vod_name")
            if (id.isBlank() || title.isBlank()) continue
            out.add(
                SubTrack(
                    sourceKey,
                    sourceName,
                    id,
                    title,
                    o.optString("vod_pic"),
                    o.optString("vod_remarks")
                )
            )
        }
        return out
    }

    suspend fun search(keyword: String): List<SubTrack> = withContext(Dispatchers.IO) {
        val beans = musicBeans()
        if (beans.isEmpty()) return@withContext emptyList()
        beans.map { bean ->
            async {
                try {
                    val sp = ApiConfig.get().getCSP(bean)
                    val json = sp.searchContent(keyword, false) ?: return@async emptyList<SubTrack>()
                    val arr = JSONObject(json).optJSONArray("list") ?: return@async emptyList<SubTrack>()
                    parseTrackList(arr, bean.key ?: "", displayName(bean.name ?: ""))
                } catch (e: Exception) {
                    emptyList()
                }
            }
        }.awaitAll().flatten()
    }

    suspend fun searchInSource(sourceKey: String, keyword: String): List<SubTrack> = withContext(Dispatchers.IO) { // [46v9]
        try {
            val bean = ApiConfig.get().getSource(sourceKey) ?: return@withContext emptyList()
            val sp = ApiConfig.get().getCSP(bean)
            val json = sp.searchContent(keyword, false) ?: return@withContext emptyList()
            val arr = JSONObject(json).optJSONArray("list") ?: return@withContext emptyList()
            parseTrackList(arr, sourceKey, displayName(bean.name ?: ""))
        } catch (e: Exception) {
            emptyList()
        }
    }

    suspend fun home(sourceKey: String): SubHome = withContext(Dispatchers.IO) {
        try {
            val bean = ApiConfig.get().getSource(sourceKey) ?: return@withContext SubHome(emptyList(), emptyList())
            val sp = ApiConfig.get().getCSP(bean)
            val json = sp.homeContent(false) ?: return@withContext SubHome(emptyList(), emptyList())
            val jo = JSONObject(json)
            val classes = mutableListOf<SubClass>()
            val carr = jo.optJSONArray("class")
            if (carr != null) {
                for (i in 0 until carr.length()) {
                    val o = carr.optJSONObject(i) ?: continue
                    val id = o.optString("type_id").ifBlank { o.optString("id") }
                    val name = o.optString("type_name").ifBlank { o.optString("name") }
                    if (id.isNotBlank() && name.isNotBlank()) classes.add(SubClass(id, name))
                }
            }
            val items = parseTrackList(jo.optJSONArray("list"), sourceKey, displayName(bean.name ?: ""))
            SubHome(classes, items)
        } catch (e: Exception) {
            SubHome(emptyList(), emptyList())
        }
    }

    fun chartClass(classes: List<SubClass>): SubClass? {
        return classes.firstOrNull {
            it.name.contains("榜") || it.name.contains("排行") || it.name.contains("热")
        } ?: classes.firstOrNull()
    }

    suspend fun category(sourceKey: String, tid: String): List<SubTrack> = withContext(Dispatchers.IO) {
        try {
            val bean = ApiConfig.get().getSource(sourceKey) ?: return@withContext emptyList()
            val sp = ApiConfig.get().getCSP(bean)
            val json = sp.categoryContent(tid, "1", false, HashMap()) ?: return@withContext emptyList()
            val jo = JSONObject(json)
            parseTrackList(jo.optJSONArray("list"), sourceKey, displayName(bean.name ?: ""))
        } catch (e: Exception) {
            emptyList()
        }
    }

    sealed interface PlayResult {
        data class Ok(val url: String) : PlayResult
        data class Fail(val msg: String) : PlayResult
    }

    suspend fun resolvePlay(track: SubTrack): PlayResult = withContext(Dispatchers.IO) {
        try {
            val bean = ApiConfig.get().getSource(track.sourceKey)
                ?: return@withContext PlayResult.Fail("源已不存在")
            val sp = ApiConfig.get().getCSP(bean)
            val detail = sp.detailContent(listOf(track.id))
                ?: return@withContext PlayResult.Fail("详情为空")
            val d = JSONObject(detail)
            val item = d.optJSONArray("list")?.optJSONObject(0) ?: d
            val from = item.optString("vod_play_from")
            val urls = item.optString("vod_play_url")
            if (from.isBlank() || urls.isBlank()) return@withContext PlayResult.Fail("该条目无播放地址")
            val flag = from.split("$$$")[0]
            val firstGroup = urls.split("$$$")[0]
            val firstEp = firstGroup.split("#")[0]
            val playId = firstEp.substringAfter("$", firstEp)
            val pr = sp.playerContent(flag, playId, ApiConfig.get().getVipParseFlags())
                ?: return@withContext PlayResult.Fail("取播放地址失败")
            val pj = JSONObject(pr)
            val parse = pj.optInt("parse", 0)
            val url = pj.optString("url")
            if (url.isBlank()) return@withContext PlayResult.Fail("播放地址为空")
            if (parse == 1) return@withContext PlayResult.Fail("该源需要解析，源内音乐 v1 暂不支持解析播放")
            PlayResult.Ok(url)
        } catch (e: Exception) {
            PlayResult.Fail("播放失败：${e.message}")
        }
    }
}
KOTEOF9

cat > avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicScreen.kt << 'KOTEOF9'
package com.github.tvbox.osc.ui.activity

// [46v9] 曲库页：Peek 式（顶栏源驱动 + 搜索框入口 + 歌单/榜单 Tab + 卡片网格）；播走 LxPlayerManager.play 裸地址，不进落雪队列；源选择由顶栏 Sheet 驱动，本页只读。

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage
import kotlinx.coroutines.launch

@Composable
fun SubMusicScreen(
    sources: List<SubMusicBridge.SubSource>,
    selectedKey: String?,
    diag: SubMusicBridge.SourceDiag?,
    onSearchClick: () -> Unit
) {
    val selected = sources.firstOrNull { it.key == selectedKey } ?: sources.firstOrNull()
    var tab by remember { mutableStateOf(0) }
    var home by remember { mutableStateOf<SubMusicBridge.SubHome?>(null) }
    var gridItems by remember { mutableStateOf<List<SubMusicBridge.SubTrack>>(emptyList()) }
    var gridLoading by remember { mutableStateOf(false) }
    var gridNote by remember { mutableStateOf("") }
    var notice by remember { mutableStateOf("") }
    val scope = rememberCoroutineScope()

    fun applyTab(src: SubMusicBridge.SubSource, t: Int, h: SubMusicBridge.SubHome?) {
        if (t == 0) {
            gridItems = h?.items ?: emptyList()
            gridNote = if (h == null || h.items.isEmpty()) "该源暂无浏览内容" else ""
            return
        }
        val cls = h?.let { SubMusicBridge.chartClass(it.classes) }
        if (cls == null) {
            gridItems = emptyList()
            gridNote = "该源暂无分类"
            return
        }
        gridLoading = true
        scope.launch {
            try {
                gridItems = SubMusicBridge.category(src.key, cls.id)
                gridNote = if (gridItems.isEmpty()) "该分类暂无内容" else ""
            } catch (e: Exception) {
                gridItems = emptyList()
                gridNote = "加载失败：${e.message}"
            } finally {
                gridLoading = false
            }
        }
    }

    fun loadBrowse(src: SubMusicBridge.SubSource) {
        gridLoading = true
        gridNote = ""
        scope.launch {
            try {
                val h = SubMusicBridge.home(src.key)
                home = h
                gridLoading = false
                applyTab(src, tab, h)
            } catch (e: Exception) {
                gridLoading = false
                home = null
                gridItems = emptyList()
                gridNote = "加载失败：${e.message}"
            }
        }
    }

    LaunchedEffect(selected?.key) {
        val src = selected
        if (src != null) loadBrowse(src)
    }

    fun playTrack(track: SubMusicBridge.SubTrack) {
        notice = "正在取播放地址…"
        scope.launch {
            when (val r = SubMusicBridge.resolvePlay(track)) {
                is SubMusicBridge.PlayResult.Ok -> {
                    LxPlayerManager.play(r.url, track.title, track.sourceName, track.pic)
                    notice = ""
                }
                is SubMusicBridge.PlayResult.Fail -> {
                    notice = r.msg
                }
            }
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(musicColors().background)
    ) {
        if (selected == null) {
            Text(
                text = "暂无音乐源：请先在主体订阅里添加带┆音乐┆分类的源",
                style = MaterialTheme.typography.bodyMedium,
                color = musicColors().textSecondary,
                modifier = Modifier.padding(16.dp)
            )
            if (diag != null) {
                Text(
                    text = "诊断：订阅源共 " + diag.total + " 个，其中未隐藏 " + diag.visible + " 个，名字带┆音乐┆的 " + diag.nameMatched + " 个，可搜索 " + diag.finalCount + " 个",
                    style = MaterialTheme.typography.bodySmall,
                    color = musicColors().textSecondary,
                    modifier = Modifier.padding(horizontal = 16.dp)
                )
            }
        } else {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { onSearchClick() }
                    .padding(horizontal = 16.dp, vertical = 12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                val searchTint = musicColors().textSecondary
                Canvas(modifier = Modifier.size(20.dp)) {
                    val sw = 2.dp.toPx()
                    drawCircle(
                        color = searchTint,
                        radius = 6.dp.toPx(),
                        center = androidx.compose.ui.geometry.Offset(8.dp.toPx(), 8.dp.toPx()),
                        style = androidx.compose.ui.graphics.drawscope.Stroke(width = sw)
                    )
                    drawLine(
                        color = searchTint,
                        start = androidx.compose.ui.geometry.Offset(12.5.dp.toPx(), 12.5.dp.toPx()),
                        end = androidx.compose.ui.geometry.Offset(17.dp.toPx(), 17.dp.toPx()),
                        strokeWidth = sw,
                        cap = androidx.compose.ui.graphics.StrokeCap.Round
                    )
                }
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = "搜索歌曲、歌手…",
                    style = MaterialTheme.typography.bodyLarge,
                    color = musicColors().textSecondary
                )
            }
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                listOf("歌单", "榜单").forEachIndexed { i, label ->
                    Column(
                        modifier = Modifier
                            .clickable {
                                if (tab != i) {
                                    tab = i
                                    val src = selected
                                    if (src != null) applyTab(src, i, home)
                                }
                            }
                            .padding(horizontal = 12.dp, vertical = 4.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text(
                            text = label,
                            style = MaterialTheme.typography.bodyLarge,
                            fontWeight = if (tab == i) FontWeight.Bold else FontWeight.Normal,
                            color = if (tab == i) musicColors().accent else musicColors().textSecondary
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        Box(
                            modifier = Modifier
                                .width(20.dp)
                                .height(2.dp)
                                .background(if (tab == i) musicColors().accent else musicColors().background)
                        )
                    }
                }
            }
            if (notice.isNotBlank()) {
                Text(
                    text = notice,
                    style = MaterialTheme.typography.bodySmall,
                    color = musicColors().textSecondary,
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 4.dp)
                )
            }
            if (gridLoading) {
                Text(
                    text = "正在加载浏览内容…",
                    style = MaterialTheme.typography.bodyMedium,
                    color = musicColors().textSecondary,
                    modifier = Modifier.padding(16.dp)
                )
            } else if (gridNote.isNotBlank()) {
                Text(
                    text = gridNote,
                    style = MaterialTheme.typography.bodyMedium,
                    color = musicColors().textSecondary,
                    modifier = Modifier.padding(16.dp)
                )
            } else {
                LazyVerticalGrid(
                    columns = GridCells.Fixed(3),
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(16.dp),
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    items(gridItems, key = { it.sourceKey + ":" + it.id }) { track ->
                        SubGridCard(track = track, onPlay = { playTrack(track) })
                    }
                }
            }
        }
    }
}

@Composable
private fun SubGridCard(track: SubMusicBridge.SubTrack, onPlay: () -> Unit) {
    val accent = musicColors().accent
    val accentText = musicColors().accentText
    val cardBg = musicColors().card
    Column(modifier = Modifier.clickable { onPlay() }) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .aspectRatio(1f)
                .clip(MaterialTheme.shapes.medium)
                .background(cardBg)
        ) {
            if (track.pic.isNotBlank()) {
                AsyncImage(
                    model = track.pic,
                    contentDescription = null,
                    contentScale = ContentScale.Crop,
                    modifier = Modifier.fillMaxSize()
                )
            } else {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = track.title.take(1),
                        color = musicColors().textSecondary
                    )
                }
            }
            if (track.remark.isNotBlank()) {
                Text(
                    text = track.remark,
                    style = MaterialTheme.typography.bodySmall,
                    color = musicColors().textPrimary,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier
                        .align(Alignment.TopStart)
                        .padding(6.dp)
                        .clip(MaterialTheme.shapes.small)
                        .background(cardBg.copy(alpha = 0.8f))
                        .padding(horizontal = 6.dp, vertical = 2.dp)
                )
            }
            Box(
                modifier = Modifier
                    .align(Alignment.BottomEnd)
                    .padding(8.dp)
                    .size(32.dp)
                    .clip(androidx.compose.foundation.shape.CircleShape)
                    .background(accent)
                    .clickable { onPlay() },
                contentAlignment = Alignment.Center
            ) {
                Canvas(modifier = Modifier.size(14.dp)) {
                    val p = androidx.compose.ui.graphics.Path().apply {
                        moveTo(4.dp.toPx(), 2.dp.toPx())
                        lineTo(4.dp.toPx(), 12.dp.toPx())
                        lineTo(12.dp.toPx(), 7.dp.toPx())
                        close()
                    }
                    drawPath(path = p, color = accentText)
                }
            }
        }
        Spacer(modifier = Modifier.height(6.dp))
        Text(
            text = track.title,
            style = MaterialTheme.typography.bodyMedium,
            color = musicColors().textPrimary,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis
        )
    }
}
KOTEOF9

cat > avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubSearchScreen.kt << 'KOTEOF9'
package com.github.tvbox.osc.ui.activity

// [46v9] 搜索页：搜当前源内源（顶栏 Sheet 选源）；播走 LxPlayerManager.play 裸地址，不进落雪队列。

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
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
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage
import kotlinx.coroutines.launch

@Composable
fun SubSearchScreen(
    sources: List<SubMusicBridge.SubSource>,
    selectedKey: String?,
    diag: SubMusicBridge.SourceDiag?
) {
    val selected = sources.firstOrNull { it.key == selectedKey } ?: sources.firstOrNull()
    var keyword by remember { mutableStateOf("") }
    var searching by remember { mutableStateOf(false) }
    var searched by remember { mutableStateOf(false) }
    var results by remember { mutableStateOf<List<SubMusicBridge.SubTrack>>(emptyList()) }
    var notice by remember { mutableStateOf("") }
    val scope = rememberCoroutineScope()

    fun doSearch() {
        val kw = keyword.trim()
        val src = selected
        if (kw.isEmpty() || searching || src == null) return
        searching = true
        searched = false
        notice = ""
        scope.launch {
            try {
                results = SubMusicBridge.searchInSource(src.key, kw)
                searched = true
            } catch (e: Exception) {
                notice = "搜索失败：${e.message}"
            } finally {
                searching = false
            }
        }
    }

    fun playTrack(track: SubMusicBridge.SubTrack) {
        notice = "正在取播放地址…"
        scope.launch {
            when (val r = SubMusicBridge.resolvePlay(track)) {
                is SubMusicBridge.PlayResult.Ok -> {
                    LxPlayerManager.play(r.url, track.title, track.sourceName, track.pic)
                    notice = ""
                }
                is SubMusicBridge.PlayResult.Fail -> {
                    notice = r.msg
                }
            }
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(musicColors().background)
    ) {
        if (selected == null) {
            Text(
                text = "暂无音乐源：请先在主体订阅里添加带┆音乐┆分类的源",
                style = MaterialTheme.typography.bodyMedium,
                color = musicColors().textSecondary,
                modifier = Modifier.padding(16.dp)
            )
            if (diag != null) {
                Text(
                    text = "诊断：订阅源共 " + diag.total + " 个，其中未隐藏 " + diag.visible + " 个，名字带┆音乐┆的 " + diag.nameMatched + " 个，可搜索 " + diag.finalCount + " 个",
                    style = MaterialTheme.typography.bodySmall,
                    color = musicColors().textSecondary,
                    modifier = Modifier.padding(horizontal = 16.dp)
                )
            }
        } else {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                TextField(
                    value = keyword,
                    onValueChange = { keyword = it },
                    label = { Text(text = "搜当前源：" + selected.displayName) },
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
                    keyboardActions = KeyboardActions(onSearch = { doSearch() }),
                    modifier = Modifier.weight(1f)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Button(onClick = { doSearch() }, enabled = !searching) {
                    Text(text = if (searching) "搜…" else "搜索")
                }
            }
            if (notice.isNotBlank()) {
                Text(
                    text = notice,
                    style = MaterialTheme.typography.bodySmall,
                    color = musicColors().textSecondary,
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 4.dp)
                )
            }
            if (searching) {
                Text(
                    text = "正在搜索…",
                    style = MaterialTheme.typography.bodyMedium,
                    color = musicColors().textSecondary,
                    modifier = Modifier.padding(16.dp)
                )
            } else if (searched) {
                LazyColumn(modifier = Modifier.fillMaxSize()) {
                    items(results, key = { it.sourceKey + ":" + it.id }) { track ->
                        SubTrackRow(track = track, onPlay = { playTrack(track) })
                    }
                    if (results.isEmpty()) {
                        item {
                            Text(
                                text = "没有搜到结果",
                                style = MaterialTheme.typography.bodyMedium,
                                color = musicColors().textSecondary,
                                modifier = Modifier.padding(16.dp)
                            )
                        }
                    }
                }
            } else {
                Text(
                    text = "在上方输入关键词，搜当前源：" + selected.displayName,
                    style = MaterialTheme.typography.bodyMedium,
                    color = musicColors().textSecondary,
                    modifier = Modifier.padding(16.dp)
                )
            }
        }
    }
}

@Composable
private fun SubTrackRow(track: SubMusicBridge.SubTrack, onPlay: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onPlay() }
            .padding(horizontal = 16.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        if (track.pic.isNotBlank()) {
            AsyncImage(
                model = track.pic,
                contentDescription = null,
                contentScale = ContentScale.Crop,
                modifier = Modifier
                    .size(48.dp)
                    .clip(androidx.compose.foundation.shape.RoundedCornerShape(8.dp))
            )
        } else {
            Box(
                modifier = Modifier
                    .size(48.dp)
                    .clip(androidx.compose.foundation.shape.RoundedCornerShape(8.dp))
                    .background(musicColors().card),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = track.title.take(1),
                    color = musicColors().textSecondary
                )
            }
        }
        Spacer(modifier = Modifier.width(12.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = track.title,
                style = MaterialTheme.typography.bodyLarge,
                color = musicColors().textPrimary,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
            Spacer(modifier = Modifier.height(2.dp))
            Text(
                text = track.sourceName + if (track.remark.isNotBlank()) " · " + track.remark else "",
                style = MaterialTheme.typography.bodySmall,
                color = musicColors().textSecondary,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
        }
    }
}
KOTEOF9

cat > avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMineScreen.kt << 'KOTEOF9'
package com.github.tvbox.osc.ui.activity

// [46v9] 我的页：先放我的喜欢 + 播放历史两块现成的（与设置页同一入口）。

import android.content.Intent
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

@Composable
fun SubMineScreen() {
    val context = LocalContext.current
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(musicColors().background)
            .padding(16.dp)
    ) {
        Text(
            text = "我的",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold,
            color = musicColors().textPrimary
        )
        Spacer(modifier = Modifier.height(16.dp))
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .clickable {
                    context.startActivity(Intent(context, com.github.tvbox.osc.ui.activity.LxFavoritesActivity::class.java))
                }
                .padding(vertical = 14.dp)
        ) {
            Text(
                text = "我的喜欢",
                style = MaterialTheme.typography.bodyLarge,
                color = musicColors().textPrimary
            )
            Spacer(modifier = Modifier.height(2.dp))
            Text(
                text = "收藏的歌曲",
                style = MaterialTheme.typography.bodySmall,
                color = musicColors().textSecondary
            )
        }
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .clickable {
                    context.startActivity(Intent(context, com.github.tvbox.osc.ui.activity.LxHistoryActivity::class.java))
                }
                .padding(vertical = 14.dp)
        ) {
            Text(
                text = "播放历史",
                style = MaterialTheme.typography.bodyLarge,
                color = musicColors().textPrimary
            )
            Spacer(modifier = Modifier.height(2.dp))
            Text(
                text = "最近播放的歌曲",
                style = MaterialTheme.typography.bodySmall,
                color = musicColors().textSecondary
            )
        }
    }
}
KOTEOF9

python3 - << 'PYEOF46V9'
import sys

path = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"
src = open(path, encoding="utf-8").read()
if "// [46v9]" in src:
    print("MH already 46v9, skip")
    sys.exit(0)


def rep(old, new, n=1):
    global src
    assert src.count(old) == n, "anchor count %d != %d: %r" % (src.count(old), n, old[:100])
    src = src.replace(old, new, n)


# ---- 1. 枚举：QUKU / MINE 加在注释前（注释吞码教训：插在 // 之前）----
lines = src.split("\n")
enum_idx = [i for i, ln in enumerate(lines) if ln.strip() == "SEARCH, RANKING, RECOMMEND, PLAYLIST, SETTINGS, HOME, SUBMUSIC // [40rec]"]
assert len(enum_idx) == 1, "enum line not found"
lines[enum_idx[0]] = "    SEARCH, RANKING, RECOMMEND, PLAYLIST, SETTINGS, HOME, SUBMUSIC, QUKU, MINE // [40rec] // [46v9]"
src = "\n".join(lines)

# ---- 2. 状态块：删落雪平台状态 + 源内开关状态，换成源内源状态 ----
old_state = """    var selectedTab by remember { mutableStateOf(initialTab) }
    var subMusicOn by remember { mutableStateOf(SubMusicBridge.isEnabled(context)) } // [46v6]
    // 源选择记忆：读上次的源，没有用 kg
    var selectedPlatform by remember {
        mutableStateOf(
            context.getSharedPreferences("lx_music", Context.MODE_PRIVATE)
                .getString("lx_last_source_id", "kg") ?: "kg"
        )
    }
    var showPlatformMenu by remember { mutableStateOf(false) }
    // 搜索 tab 分类卡点击后，要在排行 tab 预选的榜单
    var pendingChartId by remember { mutableStateOf<String?>(null) }"""
new_state = """    var selectedTab by remember { mutableStateOf(initialTab) }
    // [46v9] 整区源内化：源内源状态由顶栏 Sheet 与曲库/搜索共用
    var subSources by remember { mutableStateOf<List<SubMusicBridge.SubSource>>(emptyList()) }
    var selectedSubKey by remember { mutableStateOf<String?>(null) }
    var showSourceSheet by remember { mutableStateOf(false) }
    var sourceDiag by remember { mutableStateOf<SubMusicBridge.SourceDiag?>(null) } // [46v9] 空源诊断四数
    LaunchedEffect(Unit) {
        try {
            val list = SubMusicBridge.loadMusicSources()
            subSources = list
            if (selectedSubKey == null) selectedSubKey = list.firstOrNull()?.key
            sourceDiag = SubMusicBridge.diagnoseSources()
        } catch (_: Exception) { }
    }"""
rep(old_state, new_state)

# ---- 3. 平台列表块删除 ----
old_plat = """    // 平台列表：固定 5 大平台（用户要求）
    val platforms = remember { listOf("wy", "tx", "kg", "kw", "mg") }
    val platformNames = mapOf("wy" to "小芸", "tx" to "小秋", "kg" to "小枸", "kw" to "小蜗", "mg" to "小蜜")
    if (selectedPlatform !in platforms) {
        selectedPlatform = platforms.firstOrNull() ?: "kg"
    }"""
rep(old_plat, "")

# ---- 4. 底栏 tabDefs97：5 Tab ----
old_tabs = """                        val tabDefs97 = listOf(
                            MusicTab.SEARCH to "搜索",
                            MusicTab.RANKING to "排行",
                            MusicTab.RECOMMEND to "推荐", // [40rec]
                            MusicTab.PLAYLIST to "歌单",
                            MusicTab.SUBMUSIC to "源内",
                            MusicTab.SETTINGS to "设置",
                            MusicTab.HOME to "首页",
                        )"""
new_tabs = """                        val tabDefs97 = listOf(
                            MusicTab.QUKU to "曲库",
                            MusicTab.SEARCH to "搜索",
                            MusicTab.MINE to "我的",
                            MusicTab.SETTINGS to "设置",
                            MusicTab.HOME to "首页",
                        )"""
rep(old_tabs, new_tabs)

# ---- 5. 门控删除 ----
rep(
    "                        (if (subMusicOn) tabDefs97 else tabDefs97.filter { it.first != MusicTab.SUBMUSIC }).forEach { (tab, label) ->",
    "                        tabDefs97.forEach { (tab, label) ->",
)

# ---- 6. 设置页调用：去开关参数 ----
rep(
    "                    MusicSettingsList(onComingSoon = ::comingSoon, subMusicOn = subMusicOn, onSubMusicChange = { v -> subMusicOn = v; SubMusicBridge.setEnabled(context, v); if (!v && selectedTab == MusicTab.SUBMUSIC) selectedTab = MusicTab.SEARCH }) // [46v6] // 新版 SettingsScreen",
    "                    MusicSettingsList(onComingSoon = ::comingSoon) // [46v9]",
)

# ---- 7. 设置页签名：去开关参数 ----
rep(
    "fun MusicSettingsList(onComingSoon: (String) -> Unit, subMusicOn: Boolean = false, onSubMusicChange: ((Boolean) -> Unit)? = null) { // [46v6]",
    "fun MusicSettingsList(onComingSoon: (String) -> Unit) { // [46v9]",
)

# ---- 8. 源内音乐分组删除 ----
lines = src.split("\n")
item_idx = [i for i, ln in enumerate(lines) if 'SettingItem("源内音乐"' in ln]
assert len(item_idx) == 1, "源内音乐 row not found"
i = item_idx[0]
j = i
while lines[j].strip() != "SettingGroup(":
    j -= 1
k = i
while lines[k].strip() != "),":
    k += 1
del lines[j:k + 1]
src = "\n".join(lines)
assert "源内音乐" not in src, "源内音乐 still present"

# ---- 9. 内容 when：分支手术（自下而上，索引不漂移）----
lines = src.split("\n")


def find_line(prefix):
    idx = [i for i, ln in enumerate(lines) if ln == prefix]
    assert len(idx) == 1, "branch line not unique: %r -> %d" % (prefix, len(idx))
    return idx[0]


i_search = find_line("                MusicTab.SEARCH -> {")
i_rank = find_line("                MusicTab.RANKING -> {")
i_rec = find_line("                MusicTab.RECOMMEND -> { // [40rec]")
i_play = find_line("                MusicTab.PLAYLIST -> {")
i_set = find_line("                MusicTab.SETTINGS -> {")
i_sub = find_line("                MusicTab.SUBMUSIC -> {")
new_search = [
    "                MusicTab.SEARCH -> {",
    "                    SubSearchScreen(",
    "                        sources = subSources,",
    "                        selectedKey = subSources.firstOrNull { it.key == selectedSubKey }?.key,",
    "                        diag = sourceDiag",
    "                    ) // [46v9]",
    "                }",
]
new_quku_mine = [
    "                MusicTab.QUKU -> {",
    "                    SubMusicScreen(",
    "                        sources = subSources,",
    "                        selectedKey = subSources.firstOrNull { it.key == selectedSubKey }?.key,",
    "                        diag = sourceDiag,",
    "                        onSearchClick = { selectedTab = MusicTab.SEARCH }",
    "                    ) // [46v9]",
    "                }",
    "                MusicTab.MINE -> {",
    "                    SubMineScreen() // [46v9]",
    "                }",
]
# 自下而上：SUBMUSIC(替换) -> PLAYLIST(删) -> RECOMMEND(删) -> RANKING(删) -> SEARCH(替换)
assert lines[i_sub + 1].strip().startswith("SubMusicScreen(onOpenSettings")
assert lines[i_sub + 2] == "                }"
lines[i_sub:i_sub + 3] = new_quku_mine
lines[i_play:i_set] = []
lines[i_rec:i_play] = []
lines[i_rank:i_rec] = []
lines[i_search:i_rank] = new_search
src = "\n".join(lines)

# ---- 10. effectiveTab：旧 Tab 兜底到曲库 ----
rep(
    "            when (selectedTab) {",
    "            val effectiveTab = if (selectedTab == MusicTab.QUKU || selectedTab == MusicTab.SEARCH || selectedTab == MusicTab.MINE || selectedTab == MusicTab.SETTINGS || selectedTab == MusicTab.HOME) selectedTab else MusicTab.QUKU // [46v9]\n            when (effectiveTab) {",
)

# ---- 11. 顶栏 actions：平台下拉换成源内源按钮 ----
lines = src.split("\n")
act = [i for i, ln in enumerate(lines) if ln == "                actions = {"]
assert len(act) == 1, "actions block not unique"
ia = act[0]
ic = ia + 1
while lines[ic] != "                }":
    ic += 1
assert lines[ic + 1] == "            )", "topbar close mismatch: %r" % lines[ic + 1]
new_actions = [
    "                actions = {",
    "                    // [46v9] 顶栏源内源：点开按订阅顺序排的 Sheet，选中驱动曲库/搜索",
    "                    TextButton(onClick = { showSourceSheet = true }) {",
    "                        Text(",
    "                            subSources.firstOrNull { it.key == selectedSubKey }?.displayName ?: \"选择源\",",
    "                            color = musicColors().textPrimary,",
    "                            fontWeight = FontWeight.Bold",
    "                        )",
    "                    }",
    "                }",
]
lines[ia:ic + 1] = new_actions
src = "\n".join(lines)

# ---- 12. 图标 when：QUKU / MINE 分支（插在 SUBMUSIC 空分支前）----
lines = src.split("\n")
icon_sub = [i for i, ln in enumerate(lines) if ln == "            MusicTab.SUBMUSIC -> { } // [46v7]"]
assert len(icon_sub) == 1, "icon SUBMUSIC branch not found"
new_icons = [
    "            MusicTab.QUKU -> { // [46v9] 曲库：音符（圆 + 竖线 + 旗）",
    "                drawCircle(color = tint, radius = 3.2.dp.toPx(), center = off(8f, 16f), style = androidx.compose.ui.graphics.drawscope.Stroke(width = sw))",
    "                drawLine(color = tint, start = off(11.2f, 16f), end = off(11.2f, 5f), strokeWidth = sw, cap = cap)",
    "                drawLine(color = tint, start = off(11.2f, 5f), end = off(17f, 7f), strokeWidth = sw, cap = cap)",
    "            }",
    "            MusicTab.MINE -> { // [46v9] 我的：人形（头圆 + 肩弧）",
    "                drawCircle(color = tint, radius = 3.4.dp.toPx(), center = off(12f, 8f), style = androidx.compose.ui.graphics.drawscope.Stroke(width = sw))",
    "                drawArc(color = tint, startAngle = 180f, sweepAngle = 180f, useCenter = false, topLeft = off(4f, 11f), size = androidx.compose.ui.geometry.Size(16.dp.toPx(), 12.dp.toPx()), style = androidx.compose.ui.graphics.drawscope.Stroke(width = sw))",
    "            }",
]
lines[icon_sub[0]:icon_sub[0]] = new_icons
src = "\n".join(lines)

# ---- 13. 选源 Sheet：放在 Scaffold 之后、Provider 结束之前 ----
lines = src.split("\n")
prov = [i for i, ln in enumerate(lines) if ln == "        } // [39wp5] Provider 结束"]
assert len(prov) == 1, "provider close not found"
sheet = [
    "        // [46v9] 选源 Sheet：订阅源按顺序排，选中驱动曲库/搜索",
    "        if (showSourceSheet) {",
    "            androidx.compose.ui.window.Dialog(onDismissRequest = { showSourceSheet = false }) {",
    "                Column(",
    "                    modifier = Modifier",
    "                        .fillMaxWidth()",
    "                        .clip(androidx.compose.foundation.shape.RoundedCornerShape(16.dp))",
    "                        .background(musicColors().card)",
    "                        .padding(16.dp)",
    "                ) {",
    "                    Text(",
    "                        text = \"选择音乐源\",",
    "                        style = MaterialTheme.typography.titleMedium,",
    "                        fontWeight = FontWeight.Bold,",
    "                        color = musicColors().textPrimary",
    "                    )",
    "                    Spacer(modifier = Modifier.height(12.dp))",
    "                    if (subSources.isEmpty()) {",
    "                        Text(",
    "                            text = \"暂无音乐源：请先在主体订阅里添加带┆音乐┆分类的源\",",
    "                            style = MaterialTheme.typography.bodyMedium,",
    "                            color = musicColors().textSecondary",
    "                        )",
    "                        if (sourceDiag != null) {",
    "                            Spacer(modifier = Modifier.height(8.dp))",
    "                            Text(",
    "                                text = \"诊断：订阅源共 \" + sourceDiag!!.total + \" 个，其中未隐藏 \" + sourceDiag!!.visible + \" 个，名字带┆音乐┆的 \" + sourceDiag!!.nameMatched + \" 个，可搜索 \" + sourceDiag!!.finalCount + \" 个\",",
    "                                style = MaterialTheme.typography.bodySmall,",
    "                                color = musicColors().textSecondary",
    "                            )",
    "                        }",
    "                    } else {",
    "                        subSources.forEach { s ->",
    "                            Row(",
    "                                modifier = Modifier",
    "                                    .fillMaxWidth()",
    "                                    .clickable { selectedSubKey = s.key; showSourceSheet = false }",
    "                                    .padding(vertical = 10.dp),",
    "                                verticalAlignment = Alignment.CenterVertically",
    "                            ) {",
    "                                Text(",
    "                                    text = s.displayName,",
    "                                    style = MaterialTheme.typography.bodyLarge,",
    "                                    color = musicColors().textPrimary,",
    "                                    modifier = Modifier.weight(1f)",
    "                                )",
    "                                if (s.key == selectedSubKey) {",
    "                                    Text(",
    "                                        text = \"已选\",",
    "                                        style = MaterialTheme.typography.bodyMedium,",
    "                                        color = musicColors().accent",
    "                                    )",
    "                                }",
    "                            }",
    "                        }",
    "                    }",
    "                    Spacer(modifier = Modifier.height(12.dp))",
    "                    Button(onClick = { showSourceSheet = false }) {",
    "                        Text(text = \"取消\")",
    "                    }",
    "                }",
    "            }",
    "        }",
]
lines[prov[0]:prov[0]] = sheet
src = "\n".join(lines)

# ---- 终验 ----
for dead in ["selectedPlatform", "platformNames", "showPlatformMenu", "pendingChartId", "subMusicOn"]:
    assert dead not in src, "leftover: " + dead
for live in ["MusicTab.QUKU", "MusicTab.MINE", "SubSearchScreen(", "SubMineScreen(", "selectedSubKey", "showSourceSheet", "sourceDiag", "diagnoseSources"]:
    assert live in src, "missing: " + live
assert src.count("MusicTab.SUBMUSIC ->") == 1, "SUBMUSIC branches: %d" % src.count("MusicTab.SUBMUSIC ->")
assert src.count("tabDefs97") >= 2
open(path, "w", encoding="utf-8").write(src)
print("OK 46v9 MH")
PYEOF46V9
echo "OK 46v9"
echo "=== 46 v9 done ==="

# === 46 v10: 修 v9 构建红（内容 when 作表达式须穷尽，补 else 空分支） ===

echo "=== 46 v10 ==="

python3 - << 'PYEOF46V10'
import sys

path = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"
src = open(path, encoding="utf-8").read()
if "// [46v10]" in src:
    print("MH already 46v10, skip")
    sys.exit(0)

# v9 构建红根因（CI 实证，run 41955445270，MusicHomeActivity.kt:495:13）：
# 内容 when 坐在页内容 Box 尾 lambda 里，作表达式用，必须穷尽；
# v9 删了 RANKING/RECOMMEND/PLAYLIST/SUBMUSIC 四分支后不再穷尽。
# effectiveTab 已预映射到 5 Tab，故 else 分支不可达，仅满足穷尽。
old_home = """                MusicTab.HOME -> {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        Text("返回首页…", color = TextGray)
                    }
                }"""
assert src.count(old_home) == 1, "HOME branch anchor count %d" % src.count(old_home)
new_home = old_home + "\n                else -> { } // [46v10] effectiveTab 已预映射到 5 Tab，此分支不可达，仅满足 when 穷尽"
src = src.replace(old_home, new_home, 1)
assert src.count("                else -> { } // [46v10]") == 1
assert "when (effectiveTab)" in src
assert "MusicTab.QUKU -> {" in src
open(path, "w", encoding="utf-8").write(src)
print("OK 46v10 MH")
PYEOF46V10
echo "OK 46v10"
echo "=== 46 v10 done ==="

# === 46 v11: 内容源开关（订阅源/脚本源双模式） ===

echo "=== 46 v11 ==="

python3 - << 'PYEOF46V11'
import sys

path = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"
src = open(path, encoding="utf-8").read()
if "// [46v11]" in src:
    print("MH already 46v11, skip")
    sys.exit(0)

# --- 1. 模式状态 + 脚本源平台状态（v9 前原文恢复） ---
old_state = """    LaunchedEffect(Unit) {
        try {
            val list = SubMusicBridge.loadMusicSources()
            subSources = list
            if (selectedSubKey == null) selectedSubKey = list.firstOrNull()?.key
            sourceDiag = SubMusicBridge.diagnoseSources()
        } catch (_: Exception) { }
    }

    fun comingSoon(name: String) {"""
assert src.count(old_state) == 1, "state anchor count %d" % src.count(old_state)
new_state = """    LaunchedEffect(Unit) {
        try {
            val list = SubMusicBridge.loadMusicSources()
            subSources = list
            if (selectedSubKey == null) selectedSubKey = list.firstOrNull()?.key
            sourceDiag = SubMusicBridge.diagnoseSources()
        } catch (_: Exception) { }
    }

    // [46v11] 内容源模式：script=落雪脚本源（默认，现订阅为 0 先保可播），sub=订阅源；切模式时不在新模式里的 Tab 自动回落
    var contentMode by remember { mutableStateOf(context.getSharedPreferences("music_settings", Context.MODE_PRIVATE).getString("content_mode", "script") ?: "script") }
    fun setContentMode(mode: String) {
        contentMode = mode
        context.getSharedPreferences("music_settings", Context.MODE_PRIVATE).edit().putString("content_mode", mode).apply()
        if (mode == "sub") {
            if (selectedTab != MusicTab.QUKU && selectedTab != MusicTab.SEARCH && selectedTab != MusicTab.MINE && selectedTab != MusicTab.SETTINGS && selectedTab != MusicTab.HOME) selectedTab = MusicTab.QUKU
        } else {
            if (selectedTab != MusicTab.SEARCH && selectedTab != MusicTab.RANKING && selectedTab != MusicTab.RECOMMEND && selectedTab != MusicTab.PLAYLIST && selectedTab != MusicTab.MINE && selectedTab != MusicTab.SETTINGS && selectedTab != MusicTab.HOME) selectedTab = MusicTab.SEARCH
        }
    }
    // [46v11] 脚本源模式的平台状态（v9 前原文恢复）：读上次的源，没有用 kg
    var selectedPlatform by remember {
        mutableStateOf(
            context.getSharedPreferences("lx_music", Context.MODE_PRIVATE)
                .getString("lx_last_source_id", "kg") ?: "kg"
        )
    }
    var showPlatformMenu by remember { mutableStateOf(false) }
    // 搜索 tab 分类卡点击后，要在排行 tab 预选的榜单
    var pendingChartId by remember { mutableStateOf<String?>(null) }
    // 平台列表：固定 5 大平台（用户要求）
    val platforms = remember { listOf("wy", "tx", "kg", "kw", "mg") }
    val platformNames = mapOf("wy" to "小芸", "tx" to "小秋", "kg" to "小枸", "kw" to "小蜗", "mg" to "小蜜")
    if (selectedPlatform !in platforms) {
        selectedPlatform = platforms.firstOrNull() ?: "kg"
    }

    fun comingSoon(name: String) {"""
src = src.replace(old_state, new_state, 1)

# --- 2. 顶栏：模式二选一（订阅源 Sheet / 脚本源平台下拉） ---
old_top = """                actions = {
                    // [46v9] 顶栏源内源：点开按订阅顺序排的 Sheet，选中驱动曲库/搜索
                    TextButton(onClick = { showSourceSheet = true }) {
                        Text(
                            subSources.firstOrNull { it.key == selectedSubKey }?.displayName ?: "选择源",
                            color = musicColors().textPrimary,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }"""
assert src.count(old_top) == 1, "topbar anchor count %d" % src.count(old_top)
new_top = """                actions = {
                    if (contentMode == "sub") {
                        // [46v9] 顶栏源内源：点开按订阅顺序排的 Sheet，选中驱动曲库/搜索
                        TextButton(onClick = { showSourceSheet = true }) {
                            Text(
                                subSources.firstOrNull { it.key == selectedSubKey }?.displayName ?: "选择源",
                                color = musicColors().textPrimary,
                                fontWeight = FontWeight.Bold
                            )
                        }
                    } else {
                        // [46v11] 脚本源模式：平台切换器（v9 前原文恢复）
                        Box {
                            TextButton(onClick = { showPlatformMenu = true }) {
                                Text(
                                    platformNames[selectedPlatform] ?: selectedPlatform,
                                    color = musicColors().textPrimary,
                                    fontWeight = FontWeight.Bold
                                )
                            }
                            DropdownMenu(
                                expanded = showPlatformMenu,
                                onDismissRequest = { showPlatformMenu = false }
                            ) {
                                platforms.forEach { p ->
                                    DropdownMenuItem(
                                        text = { Text("${platformNames[p] ?: p} ($p)") },
                                        onClick = {
                                            selectedPlatform = p
                                            // 源选择记忆：保存
                                            context.getSharedPreferences("lx_music", Context.MODE_PRIVATE)
                                                .edit().putString("lx_last_source_id", p).apply()
                                            showPlatformMenu = false
                                        }
                                    )
                                }
                            }
                        }
                    }
                }"""
src = src.replace(old_top, new_top, 1)

# --- 3. 内容 when：双模式（订阅 5 分支 + 脚本 4 分支恢复 + 共享 我的/设置/首页） ---
old_when = """            val effectiveTab = if (selectedTab == MusicTab.QUKU || selectedTab == MusicTab.SEARCH || selectedTab == MusicTab.MINE || selectedTab == MusicTab.SETTINGS || selectedTab == MusicTab.HOME) selectedTab else MusicTab.QUKU // [46v9]
            when (effectiveTab) {
                MusicTab.SEARCH -> {
                    SubSearchScreen(
                        sources = subSources,
                        selectedKey = subSources.firstOrNull { it.key == selectedSubKey }?.key,
                        diag = sourceDiag
                    ) // [46v9]
                }
                MusicTab.SETTINGS -> {
                    MusicSettingsList(onComingSoon = ::comingSoon) // [46v9]
                }
                MusicTab.QUKU -> {
                    SubMusicScreen(
                        sources = subSources,
                        selectedKey = subSources.firstOrNull { it.key == selectedSubKey }?.key,
                        diag = sourceDiag,
                        onSearchClick = { selectedTab = MusicTab.SEARCH }
                    ) // [46v9]
                }
                MusicTab.MINE -> {
                    SubMineScreen() // [46v9]
                }
                MusicTab.HOME -> {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        Text("返回首页…", color = TextGray)
                    }
                }
                else -> { } // [46v10] effectiveTab 已预映射到 5 Tab，此分支不可达，仅满足 when 穷尽
            }"""
assert src.count(old_when) == 1, "content-when anchor count %d" % src.count(old_when)
new_when = """            val effectiveTab = if (contentMode == "sub") {
                if (selectedTab == MusicTab.QUKU || selectedTab == MusicTab.SEARCH || selectedTab == MusicTab.MINE || selectedTab == MusicTab.SETTINGS || selectedTab == MusicTab.HOME) selectedTab else MusicTab.QUKU
            } else {
                if (selectedTab == MusicTab.SEARCH || selectedTab == MusicTab.RANKING || selectedTab == MusicTab.RECOMMEND || selectedTab == MusicTab.PLAYLIST || selectedTab == MusicTab.MINE || selectedTab == MusicTab.SETTINGS || selectedTab == MusicTab.HOME) selectedTab else MusicTab.SEARCH
            } // [46v11]
            when (effectiveTab) {
                MusicTab.QUKU -> {
                    SubMusicScreen(
                        sources = subSources,
                        selectedKey = subSources.firstOrNull { it.key == selectedSubKey }?.key,
                        diag = sourceDiag,
                        onSearchClick = { selectedTab = MusicTab.SEARCH }
                    ) // [46v9]
                }
                MusicTab.SEARCH -> {
                    if (contentMode == "sub") {
                        SubSearchScreen(
                            sources = subSources,
                            selectedKey = subSources.firstOrNull { it.key == selectedSubKey }?.key,
                            diag = sourceDiag
                        ) // [46v9]
                    } else {
                        // 搜索：新版 SearchScreen（数据：SearchTabLanding 的热词/关键词逻辑）
                        SearchTabLanding(
                            platform = selectedPlatform,
                            onSearch = { kw ->
                                context.startActivity(
                                    Intent(context, LxMusicSearchActivity::class.java).apply {
                                        putExtra("platform", selectedPlatform)
                                        putExtra("keyword", kw)
                                    }
                                )
                            },
                            onBrowseChart = { chartId ->
                                pendingChartId = chartId
                                selectedTab = MusicTab.RANKING
                            }
                        )
                    }
                }
                MusicTab.RANKING -> {
                    // 排行：新版 RankScreen（数据：RankingTab 的榜单/歌曲逻辑）
                    RankingTab(
                        platform = selectedPlatform,
                        platformName = platformNames[selectedPlatform] ?: selectedPlatform,
                        initialChartId = pendingChartId,
                        drawerHazeState = drawerHazeState, // [32v109] 抽屉状态跨函数传递(v108 只在 MusicHomeScreen 内声明, RankingTab 内不可见)
                    )
                }
                MusicTab.RECOMMEND -> { // [40rec]
                    RecommendScreen(
                        playerTitle = playerTitle,
                        playerArtist = playerArtist,
                        playerIsPlaying = playerIsPlaying,
                        onPlay = { songs, i -> playSongs(context, songs, i) },
                        onPlayOnly = { songs, i -> playSongsOnly(songs, i) }, // [40fin] 按钮播歌不进页
                        onTogglePlay = { LxPlayerManager.togglePlayPause() }
                    )
                }
                MusicTab.PLAYLIST -> {
                    // 歌单：新版 PlaylistScreen（数据：PlaylistTab/PlaylistBrowser 的歌单逻辑）
                    PlaylistTab(platform = selectedPlatform)
                }
                MusicTab.MINE -> {
                    SubMineScreen() // [46v9]
                }
                MusicTab.SETTINGS -> {
                    MusicSettingsList(onComingSoon = ::comingSoon, contentMode = contentMode, onContentModeChange = ::setContentMode) // [46v11]
                }
                MusicTab.HOME -> {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        Text("返回首页…", color = TextGray)
                    }
                }
                else -> { } // [46v10] effectiveTab 已预映射到两模式各自 Tab 集，此分支不可达，仅满足 when 穷尽
            }"""
src = src.replace(old_when, new_when, 1)

# --- 4. 底栏 tabDefs：模式二选一 ---
old_tabs = """                        val tabDefs97 = listOf(
                            MusicTab.QUKU to "曲库",
                            MusicTab.SEARCH to "搜索",
                            MusicTab.MINE to "我的",
                            MusicTab.SETTINGS to "设置",
                            MusicTab.HOME to "首页",
                        )"""
assert src.count(old_tabs) == 1, "tabDefs anchor count %d" % src.count(old_tabs)
new_tabs = """                        val tabDefs97 = if (contentMode == "sub") listOf( // [46v11]
                            MusicTab.QUKU to "曲库",
                            MusicTab.SEARCH to "搜索",
                            MusicTab.MINE to "我的",
                            MusicTab.SETTINGS to "设置",
                            MusicTab.HOME to "首页",
                        ) else listOf(
                            MusicTab.SEARCH to "搜索",
                            MusicTab.RANKING to "排行",
                            MusicTab.RECOMMEND to "推荐", // [40rec]
                            MusicTab.PLAYLIST to "歌单",
                            MusicTab.MINE to "我的",
                            MusicTab.SETTINGS to "设置",
                            MusicTab.HOME to "首页",
                        )"""
src = src.replace(old_tabs, new_tabs, 1)

# --- 5. 设置：签名加模式参数 + 顶部“内容源”开关组 ---
old_sig = "fun MusicSettingsList(onComingSoon: (String) -> Unit) { // [46v9]"
assert src.count(old_sig) == 1, "settings sig anchor count %d" % src.count(old_sig)
src = src.replace(old_sig, "fun MusicSettingsList(onComingSoon: (String) -> Unit, contentMode: String, onContentModeChange: (String) -> Unit) { // [46v11]", 1)
old_groups = """    val groups = listOf(
        SettingGroup(
            "音乐源","""
assert src.count(old_groups) == 1, "groups anchor count %d" % src.count(old_groups)
new_groups = """    val groups = listOf(
        SettingGroup(
            "内容源",
            listOf(
                SettingItem(title = "订阅源", subtitle = "关闭则使用脚本源（落雪）", isSwitch = true, switchChecked = { contentMode == "sub" }, onSwitchChange = { on -> onContentModeChange(if (on) "sub" else "script") }, action = {}) // [46v11]
            )
        ),
        SettingGroup(
            "音乐源","""
src = src.replace(old_groups, new_groups, 1)

# --- 断言 ---
assert src.count("var selectedPlatform by remember") == 1
assert src.count("var showPlatformMenu by remember") == 1
assert src.count("var pendingChartId by remember") == 1
assert src.count('val platforms = remember { listOf("wy", "tx", "kg", "kw", "mg") }') == 1
assert src.count("var contentMode by remember") == 1
assert "SearchTabLanding(" in src and "RankingTab(" in src and "RecommendScreen(" in src and "PlaylistTab(platform = selectedPlatform)" in src
assert "onContentModeChange = ::setContentMode" in src
assert 'SettingItem(title = "订阅源"' in src
open(path, "w", encoding="utf-8").write(src)
print("OK 46v11 MH")
PYEOF46V11
echo "OK 46v11"
echo "=== 46 v11 done ==="

# === 46 v12: 订阅队列化＋歌手 tab＋榜单名次 ===

echo "=== 46 v12 ==="

python3 - << 'PYEOF46V12A'
import sys

path = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicBridge.kt"
src = open(path, encoding="utf-8").read()
if "// [46v12]" in src:
    print("bridge already 46v12, skip")
    sys.exit(0)

# 1. SubTrack 加 actor 字段（仅 parseTrackList 一处构造，默认值保兼容）
old_track = """    data class SubTrack(
        val sourceKey: String,
        val sourceName: String,
        val id: String,
        val title: String,
        val pic: String,
        val remark: String
    )"""
assert src.count(old_track) == 1, "SubTrack anchor count %d" % src.count(old_track)
src = src.replace(old_track, """    data class SubTrack(
        val sourceKey: String,
        val sourceName: String,
        val id: String,
        val title: String,
        val pic: String,
        val remark: String,
        val actor: String = ""
    )""", 1)

old_ctor = """                SubTrack(
                    sourceKey,
                    sourceName,
                    id,
                    title,
                    o.optString("vod_pic"),
                    o.optString("vod_remarks")
                )"""
assert src.count(old_ctor) == 1, "ctor anchor count %d" % src.count(old_ctor)
src = src.replace(old_ctor, """                SubTrack(
                    sourceKey,
                    sourceName,
                    id,
                    title,
                    o.optString("vod_pic"),
                    o.optString("vod_remarks"),
                    o.optString("vod_actor")
                )""", 1)

# 2. 歌手推导 + 队列映射 + 队列反查（挂在 resolvePlay 尾巴前）
old_tail = """        } catch (e: Exception) {
            PlayResult.Fail("播放失败：${e.message}")
        }
    }
}"""
assert src.count(old_tail) == 1, "tail anchor count %d" % src.count(old_tail)
new_tail = """        } catch (e: Exception) {
            PlayResult.Fail("播放失败：${e.message}")
        }
    }

    fun artistOf(track: SubTrack): String? { // [46v12] 歌手推导：合集备注→标题即歌手；否则 vod_actor；否则不含 > 的备注
        if (track.remark.contains("合集") || track.remark.contains("专辑")) return track.title.ifBlank { null }
        if (track.actor.isNotBlank()) return track.actor
        if (track.remark.isNotBlank() && !track.remark.contains(">")) return track.remark
        return null
    }

    fun toQueueMaps(tracks: List<SubTrack>): List<Map<String, String>> { // [46v12] 订阅队列：播放器页列表读的就是这份 playQueue
        return tracks.map { t ->
            mapOf(
                "sub" to "1",
                "subSourceKey" to t.sourceKey,
                "subId" to t.id,
                "songId" to (t.sourceKey + ":" + t.id),
                "platform" to "sub",
                "title" to t.title,
                "artist" to t.sourceName,
                "picUrl" to t.pic
            )
        }
    }

    fun trackFromMap(map: Map<String, String>): SubTrack? { // [46v12] 队列切歌反查订阅条目
        val sk = map["subSourceKey"] ?: return null
        val id = map["subId"] ?: return null
        return SubTrack(sk, map["artist"] ?: "", id, map["title"] ?: "", map["picUrl"] ?: "", "")
    }
}"""
src = src.replace(old_tail, new_tail, 1)

assert src.count("fun artistOf") == 1
assert src.count("fun toQueueMaps") == 1
assert src.count("fun trackFromMap") == 1
assert src.count('val actor: String = ""') == 1
open(path, "w", encoding="utf-8").write(src)
print("OK 46v12 bridge")
PYEOF46V12A

python3 - << 'PYEOF46V12B'
import sys

path = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicScreen.kt"
src = open(path, encoding="utf-8").read()
if "// [46v12]" in src:
    print("screen already 46v12, skip")
    sys.exit(0)

# 0. 头注释：队列已通，旧“不进队列”说法作废
old_head = "// [46v9] 曲库页：Peek 式（顶栏源驱动 + 搜索框入口 + 歌单/榜单 Tab + 卡片网格）；播走 LxPlayerManager.play 裸地址，不进落雪队列；源选择由顶栏 Sheet 驱动，本页只读。"
assert src.count(old_head) == 1, "head anchor count %d" % src.count(old_head)
src = src.replace(old_head, "// [46v12] 曲库页：Peek 式（顶栏源驱动 + 搜索框入口 + 歌手/榜单 Tab + 卡片网格）；点卡片把当前页建成播放队列（从点中那首起），切歌/列表点播走订阅解析；源选择由顶栏 Sheet 驱动，本页只读。", 1)

# 0b. itemsIndexed 导入（榜单名次用）
old_imp = "import androidx.compose.foundation.lazy.grid.items\n"
assert src.count(old_imp) == 1, "import anchor count %d" % src.count(old_imp)
src = src.replace(old_imp, old_imp + "import androidx.compose.foundation.lazy.grid.itemsIndexed\n", 1)

# 1. 状态：歌手视图开关 + 榜单 items（供歌手推导）
old_state = """    var notice by remember { mutableStateOf("") }
    val scope = rememberCoroutineScope()"""
assert src.count(old_state) == 1, "state anchor count %d" % src.count(old_state)
src = src.replace(old_state, """    var notice by remember { mutableStateOf("") }
    var showingArtistTracks by remember { mutableStateOf(false) } // [46v12] 歌手 tab 内：true=某歌手的歌曲网格
    var chartItems by remember { mutableStateOf<List<SubMusicBridge.SubTrack>>(emptyList()) } // [46v12] 榜单 items，供歌手推导
    val scope = rememberCoroutineScope()

    val artists = remember(home, chartItems) { // [46v12] 歌手推导：首页＋榜单条目去重
        val seen = LinkedHashMap<String, String>()
        for (t in (home?.items ?: emptyList()) + chartItems) {
            val name = SubMusicBridge.artistOf(t) ?: continue
            if (!seen.containsKey(name)) seen[name] = t.pic
        }
        seen.map { (name, pic) -> name to pic }
    }""", 1)

# 2. applyTab：t==0 改歌手视图（不再直接铺首页）；榜单分支同步 chartItems
old_apply0 = """    fun applyTab(src: SubMusicBridge.SubSource, t: Int, h: SubMusicBridge.SubHome?) {
        if (t == 0) {
            gridItems = h?.items ?: emptyList()
            gridNote = if (h == null || h.items.isEmpty()) "该源暂无浏览内容" else ""
            return
        }"""
assert src.count(old_apply0) == 1, "apply0 anchor count %d" % src.count(old_apply0)
src = src.replace(old_apply0, """    fun applyTab(src: SubMusicBridge.SubSource, t: Int, h: SubMusicBridge.SubHome?) {
        showingArtistTracks = false // [46v12] 切 Tab 回歌手列表
        if (t == 0) {
            gridItems = emptyList()
            gridNote = ""
            return
        }""", 1)

old_cat = """        gridLoading = true
        scope.launch {
            try {
                gridItems = SubMusicBridge.category(src.key, cls.id)
                gridNote = if (gridItems.isEmpty()) "该分类暂无内容" else ""
            } catch (e: Exception) {
                gridItems = emptyList()
                gridNote = "加载失败：${e.message}"
            } finally {
                gridLoading = false
            }
        }"""
assert src.count(old_cat) == 1, "cat anchor count %d" % src.count(old_cat)
src = src.replace(old_cat, """        gridLoading = true
        scope.launch {
            try {
                gridItems = SubMusicBridge.category(src.key, cls.id)
                chartItems = gridItems // [46v12]
                gridNote = if (gridItems.isEmpty()) "该分类暂无内容" else ""
            } catch (e: Exception) {
                gridItems = emptyList()
                chartItems = emptyList() // [46v12]
                gridNote = "加载失败：${e.message}"
            } finally {
                gridLoading = false
            }
        }""", 1)

# 3. 歌手点开：搜该歌手，进歌曲网格
old_play = """    fun playTrack(track: SubMusicBridge.SubTrack) {
        notice = "正在取播放地址…"
        scope.launch {
            when (val r = SubMusicBridge.resolvePlay(track)) {
                is SubMusicBridge.PlayResult.Ok -> {
                    LxPlayerManager.play(r.url, track.title, track.sourceName, track.pic)
                    notice = ""
                }
                is SubMusicBridge.PlayResult.Fail -> {
                    notice = r.msg
                }
            }
        }
    }"""
assert src.count(old_play) == 1, "play anchor count %d" % src.count(old_play)
new_play = """    fun openArtist(name: String) { // [46v12] 歌手点开：搜该歌手，进歌曲网格
        val src = selected ?: return
        gridLoading = true
        gridNote = ""
        scope.launch {
            try {
                val res = SubMusicBridge.searchInSource(src.key, name)
                gridItems = res
                showingArtistTracks = res.isNotEmpty()
                if (res.isEmpty()) gridNote = "该歌手暂无内容"
            } catch (e: Exception) {
                gridItems = emptyList()
                gridNote = "加载失败：${e.message}"
            } finally {
                gridLoading = false
            }
        }
    }

    fun playTrack(track: SubMusicBridge.SubTrack, list: List<SubMusicBridge.SubTrack>) { // [46v12] 点卡片建队列：当前页从点中那首起
        notice = "正在取播放地址…"
        val maps = SubMusicBridge.toQueueMaps(list)
        val idx = list.indexOfFirst { it.sourceKey == track.sourceKey && it.id == track.id }.takeIf { it >= 0 } ?: 0
        LxPlayerManager.playQueue = maps
        LxPlayerManager.queueIndex = idx
        scope.launch {
            when (val r = SubMusicBridge.resolvePlay(track)) {
                is SubMusicBridge.PlayResult.Ok -> {
                    LxPlayerManager.play(r.url, track.title, track.sourceName, track.pic)
                    notice = ""
                }
                is SubMusicBridge.PlayResult.Fail -> {
                    notice = r.msg
                }
            }
        }
    }"""
src = src.replace(old_play, new_play, 1)

# 4. Tab 标签：歌单 → 歌手
old_tabs = 'listOf("歌单", "榜单").forEachIndexed { i, label ->'
assert src.count(old_tabs) == 1, "tabs anchor count %d" % src.count(old_tabs)
src = src.replace(old_tabs, 'listOf("歌手", "榜单").forEachIndexed { i, label -> // [46v12] 歌单改歌手', 1)

# 5. 网格分支：歌手网格 / 返回行 / 榜单名次
old_grid = """            } else {
                LazyVerticalGrid(
                    columns = GridCells.Fixed(3),
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(16.dp),
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    items(gridItems, key = { it.sourceKey + ":" + it.id }) { track ->
                        SubGridCard(track = track, onPlay = { playTrack(track) })
                    }
                }
            }"""
assert src.count(old_grid) == 1, "grid anchor count %d" % src.count(old_grid)
new_grid = """            } else if (tab == 0 && !showingArtistTracks) { // [46v12] 歌手 tab：推导出的歌手网格
                if (artists.isEmpty()) {
                    Text(
                        text = "该源未提供歌手信息",
                        style = MaterialTheme.typography.bodyMedium,
                        color = musicColors().textSecondary,
                        modifier = Modifier.padding(16.dp)
                    )
                } else {
                    LazyVerticalGrid(
                        columns = GridCells.Fixed(3),
                        modifier = Modifier.fillMaxSize(),
                        contentPadding = PaddingValues(16.dp),
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                        verticalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        items(artists, key = { it.first }) { a ->
                            SubArtistCard(name = a.first, pic = a.second, onClick = { openArtist(a.first) })
                        }
                    }
                }
            } else {
                if (tab == 0 && showingArtistTracks) {
                    Text(
                        text = "← 返回歌手",
                        style = MaterialTheme.typography.bodyMedium,
                        color = musicColors().accent,
                        modifier = Modifier
                            .clickable { showingArtistTracks = false }
                            .padding(horizontal = 16.dp, vertical = 8.dp)
                    )
                }
                LazyVerticalGrid(
                    columns = GridCells.Fixed(3),
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(16.dp),
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    itemsIndexed(gridItems, key = { _, it -> it.sourceKey + ":" + it.id }) { idx, track ->
                        SubGridCard(track = track, rank = if (tab == 1) idx + 1 else null, onPlay = { playTrack(track, gridItems) })
                    }
                }
            }"""
src = src.replace(old_grid, new_grid, 1)

# 6. 卡片：名次角标（左下，榜单 tab 才传 rank）
old_card = "private fun SubGridCard(track: SubMusicBridge.SubTrack, onPlay: () -> Unit) {"
assert src.count(old_card) == 1, "card anchor count %d" % src.count(old_card)
src = src.replace(old_card, "private fun SubGridCard(track: SubMusicBridge.SubTrack, rank: Int? = null, onPlay: () -> Unit) { // [46v12] rank 非空=榜单名次", 1)

old_playbtn = """            Box(
                modifier = Modifier
                    .align(Alignment.BottomEnd)"""
assert src.count(old_playbtn) == 1, "playbtn anchor count %d" % src.count(old_playbtn)
src = src.replace(old_playbtn, """            if (rank != null) {
                Text(
                    text = rank.toString(),
                    style = MaterialTheme.typography.bodySmall,
                    color = musicColors().textPrimary,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier
                        .align(Alignment.BottomStart)
                        .padding(6.dp)
                        .clip(MaterialTheme.shapes.small)
                        .background(cardBg.copy(alpha = 0.8f))
                        .padding(horizontal = 6.dp, vertical = 2.dp)
                )
            }
            Box(
                modifier = Modifier
                    .align(Alignment.BottomEnd)""", 1)

# 7. 文件尾追加歌手卡片
old_tail = """        Text(
            text = track.title,
            style = MaterialTheme.typography.bodyMedium,
            color = musicColors().textPrimary,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis
        )
    }
}"""
assert src.count(old_tail) == 1, "tail anchor count %d" % src.count(old_tail)
src = src.replace(old_tail, """        Text(
            text = track.title,
            style = MaterialTheme.typography.bodyMedium,
            color = musicColors().textPrimary,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis
        )
    }
}

@Composable
private fun SubArtistCard(name: String, pic: String, onClick: () -> Unit) { // [46v12] 歌手卡：封面＋名，点开搜该歌手
    val cardBg = musicColors().card
    Column(modifier = Modifier.clickable { onClick() }) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .aspectRatio(1f)
                .clip(MaterialTheme.shapes.medium)
                .background(cardBg),
            contentAlignment = Alignment.Center
        ) {
            if (pic.isNotBlank()) {
                AsyncImage(
                    model = pic,
                    contentDescription = null,
                    contentScale = ContentScale.Crop,
                    modifier = Modifier.fillMaxSize()
                )
            } else {
                Text(
                    text = name.take(1),
                    color = musicColors().textSecondary
                )
            }
        }
        Spacer(modifier = Modifier.height(6.dp))
        Text(
            text = name,
            style = MaterialTheme.typography.bodyMedium,
            color = musicColors().textPrimary,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis
        )
    }
}""", 1)

assert src.count("fun openArtist") == 1
assert src.count("fun playTrack(track: SubMusicBridge.SubTrack, list:") == 1
assert src.count('listOf("歌手", "榜单")') == 1
assert src.count("fun SubArtistCard") == 1
assert src.count("itemsIndexed(gridItems") == 1
open(path, "w", encoding="utf-8").write(src)
print("OK 46v12 screen")
PYEOF46V12B

python3 - << 'PYEOF46V12C'
import sys

# 搜索屏：点行建队列（与曲库网格同一机制）
path = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubSearchScreen.kt"
src = open(path, encoding="utf-8").read()
if "// [46v12]" in src:
    print("search already 46v12, skip")
    sys.exit(0)

old_head = "// [46v9] 搜索页：搜当前源内源（顶栏 Sheet 选源）；播走 LxPlayerManager.play 裸地址，不进落雪队列。"
assert src.count(old_head) == 1, "head anchor count %d" % src.count(old_head)
src = src.replace(old_head, "// [46v12] 搜索页：搜当前源内源（顶栏 Sheet 选源）；点行把结果建成播放队列（从点中那首起），切歌/列表点播走订阅解析。", 1)

old_play = """    fun playTrack(track: SubMusicBridge.SubTrack) {
        notice = "正在取播放地址…"
        scope.launch {
            when (val r = SubMusicBridge.resolvePlay(track)) {
                is SubMusicBridge.PlayResult.Ok -> {
                    LxPlayerManager.play(r.url, track.title, track.sourceName, track.pic)
                    notice = ""
                }
                is SubMusicBridge.PlayResult.Fail -> {
                    notice = r.msg
                }
            }
        }
    }"""
assert src.count(old_play) == 1, "play anchor count %d" % src.count(old_play)
src = src.replace(old_play, """    fun playTrack(track: SubMusicBridge.SubTrack) { // [46v12] 点行建队列：结果列表从点中那首起
        notice = "正在取播放地址…"
        val maps = SubMusicBridge.toQueueMaps(results)
        val idx = results.indexOfFirst { it.sourceKey == track.sourceKey && it.id == track.id }.takeIf { it >= 0 } ?: 0
        LxPlayerManager.playQueue = maps
        LxPlayerManager.queueIndex = idx
        scope.launch {
            when (val r = SubMusicBridge.resolvePlay(track)) {
                is SubMusicBridge.PlayResult.Ok -> {
                    LxPlayerManager.play(r.url, track.title, track.sourceName, track.pic)
                    notice = ""
                }
                is SubMusicBridge.PlayResult.Fail -> {
                    notice = r.msg
                }
            }
        }
    }""", 1)
open(path, "w", encoding="utf-8").write(src)
print("OK 46v12 search")

# 播放器页：队列点播/切歌时，订阅条目走桥接解析（35 后定向补丁）
path = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt"
src = open(path, encoding="utf-8").read()
if "// [46v12]" in src:
    print("player page already 46v12, skip")
    sys.exit(0)

old_fn = """    private fun playSongFromQueue(song: Map<String, String>) {
        val sid = song["songId"] ?: return"""
assert src.count(old_fn) == 1, "playSongFromQueue anchor count %d" % src.count(old_fn)
src = src.replace(old_fn, """    private fun playSongFromQueue(song: Map<String, String>) {
        if (song["sub"] == "1") { // [46v12] 订阅条目走桥接解析，不走落雪链
            val t = SubMusicBridge.trackFromMap(song) ?: return
            LxPlayerManager.setLoading(true)
            Thread {
                try {
                    val r = kotlinx.coroutines.runBlocking { SubMusicBridge.resolvePlay(t) }
                    if (r is SubMusicBridge.PlayResult.Ok) {
                        runOnUiThread { LxPlayerManager.play(r.url, t.title, t.sourceName, t.pic); LxPlayerManager.setLoading(false) }
                    } else if (r is SubMusicBridge.PlayResult.Fail) {
                        runOnUiThread { LxPlayerManager.setError(r.msg); LxPlayerManager.setLoading(false) }
                    }
                } catch (e: Exception) {
                    runOnUiThread { LxPlayerManager.setError("播放失败：${e.message}"); LxPlayerManager.setLoading(false) }
                }
            }.start()
            return
        }
        val sid = song["songId"] ?: return""", 1)
open(path, "w", encoding="utf-8").write(src)
print("OK 46v12 player page")
PYEOF46V12C

grep -q "46v12" avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicBridge.kt || { echo "X 46v12 bridge"; exit 1; }
grep -q "46v12" avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicScreen.kt || { echo "X 46v12 screen"; exit 1; }
grep -q "46v12" avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubSearchScreen.kt || { echo "X 46v12 search"; exit 1; }
grep -q "46v12" avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt || { echo "X 46v12 player"; exit 1; }
echo "OK 46v12"
echo "=== 46 v12 done ==="

# === 46 v13: 榜单分段视图 ===

echo "=== 46 v13 ==="

python3 - << 'PYEOF46V13'
import sys

# 46 v13：榜单 tab 改分段视图（参考图：按源分类分段，段标题＋“全部”＋横滑竖版卡片＋右上角名次）
path = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicScreen.kt"
src = open(path, encoding="utf-8").read()
if "// [46v13]" in src:
    print("screen already 46v13, skip")
    sys.exit(0)

# 0. 头注释
old_head = "// [46v12] 曲库页：Peek 式（顶栏源驱动 + 搜索框入口 + 歌手/榜单 Tab + 卡片网格）；点卡片把当前页建成播放队列（从点中那首起），切歌/列表点播走订阅解析；源选择由顶栏 Sheet 驱动，本页只读。"
assert src.count(old_head) == 1, "head anchor count %d" % src.count(old_head)
src = src.replace(old_head, "// [46v13] 曲库页：Peek 式（顶栏源驱动 + 搜索框入口 + 歌手/榜单 Tab）；榜单为分段视图（按源分类分段，段内横滑竖版卡片＋右上角名次，点“全部”进该分类整页网格）；点卡片把当前页建成播放队列（从点中那首起），切歌/列表点播走订阅解析；源选择由顶栏 Sheet 驱动，本页只读。", 1)

# 0b. 导入 LazyColumn/LazyRow（与 grid 的 items/itemsIndexed 同名但接收器不同，分别解析）
old_imp = "import androidx.compose.foundation.lazy.grid.itemsIndexed\n"
assert src.count(old_imp) == 1, "import anchor count %d" % src.count(old_imp)
src = src.replace(old_imp, old_imp + "import androidx.compose.foundation.lazy.LazyColumn\nimport androidx.compose.foundation.lazy.LazyRow\nimport androidx.compose.foundation.lazy.items\nimport androidx.compose.foundation.lazy.itemsIndexed\n", 1)

# 1. 状态：分段列表＋钻入段＋分段加载中
old_state = '    var chartItems by remember { mutableStateOf<List<SubMusicBridge.SubTrack>>(emptyList()) } // [46v12] 榜单 items，供歌手推导'
assert src.count(old_state) == 1, "state anchor count %d" % src.count(old_state)
src = src.replace(old_state, old_state + '\n    var chartSections by remember { mutableStateOf<List<Triple<String, String, List<SubMusicBridge.SubTrack>>>>(emptyList()) } // [46v13] 榜单分段：(分类 id, 分类名, 第 1 页条目)\n    var chartDetail by remember { mutableStateOf<Triple<String, String, List<SubMusicBridge.SubTrack>>?>(null) } // [46v13] 榜单“全部”钻入的段，null=分段视图\n    var sectionsLoading by remember { mutableStateOf(false) } // [46v13] 分段加载中', 1)

# 2. applyTab：t==1 改全部分类逐段拉（有数据的段先出，单段失败不拦后段）
old_apply = """    fun applyTab(src: SubMusicBridge.SubSource, t: Int, h: SubMusicBridge.SubHome?) {
        showingArtistTracks = false // [46v12] 切 Tab 回歌手列表
        if (t == 0) {
            gridItems = emptyList()
            gridNote = ""
            return
        }
        val cls = h?.let { SubMusicBridge.chartClass(it.classes) }
        if (cls == null) {
            gridItems = emptyList()
            gridNote = "该源暂无分类"
            return
        }
        gridLoading = true
        scope.launch {
            try {
                gridItems = SubMusicBridge.category(src.key, cls.id)
                chartItems = gridItems // [46v12]
                gridNote = if (gridItems.isEmpty()) "该分类暂无内容" else ""
            } catch (e: Exception) {
                gridItems = emptyList()
                chartItems = emptyList() // [46v12]
                gridNote = "加载失败：${e.message}"
            } finally {
                gridLoading = false
            }
        }
    }"""
assert src.count(old_apply) == 1, "apply anchor count %d" % src.count(old_apply)
new_apply = """    fun applyTab(src: SubMusicBridge.SubSource, t: Int, h: SubMusicBridge.SubHome?) {
        showingArtistTracks = false // [46v12] 切 Tab 回歌手列表
        chartDetail = null // [46v13] 回榜单分段视图
        if (t == 0) {
            gridItems = emptyList()
            gridNote = ""
            return
        }
        if (h == null || h.classes.isEmpty()) {
            chartSections = emptyList()
            chartItems = emptyList()
            gridNote = "该源暂无分类"
            return
        }
        gridNote = ""
        chartSections = emptyList()
        sectionsLoading = true
        scope.launch {
            try {
                for (cls in h.classes) { // [46v13] 全量分类逐段拉第 1 页，有数据的段先出
                    try {
                        val items = SubMusicBridge.category(src.key, cls.id)
                        if (items.isNotEmpty()) {
                            val ns = chartSections + Triple(cls.id, cls.name, items)
                            chartSections = ns
                            chartItems = ns.flatMap { it.third } // [46v13] 歌手推导覆盖全部分段
                        }
                    } catch (e: Exception) {
                        // 单段失败跳过，不拦后段
                    }
                }
            } finally {
                sectionsLoading = false
            }
        }
    }"""
src = src.replace(old_apply, new_apply, 1)

# 3. 渲染链：榜单分段分支插在 gridLoading 之前（分段视图不走 gridLoading/gridNote 门）
old_chain = """            if (gridLoading) {
                Text(
                    text = "正在加载浏览内容…","""
assert src.count(old_chain) == 1, "chain anchor count %d" % src.count(old_chain)
new_chain = """            if (tab == 1 && chartDetail == null) { // [46v13] 榜单分段视图
                if (gridNote.isNotBlank()) {
                    Text(
                        text = gridNote,
                        style = MaterialTheme.typography.bodyMedium,
                        color = musicColors().textSecondary,
                        modifier = Modifier.padding(16.dp)
                    )
                } else if (chartSections.isEmpty()) {
                    Text(
                        text = if (sectionsLoading) "正在加载榜单…" else "该源暂无分类内容",
                        style = MaterialTheme.typography.bodyMedium,
                        color = musicColors().textSecondary,
                        modifier = Modifier.padding(16.dp)
                    )
                } else {
                    LazyColumn(
                        modifier = Modifier.fillMaxSize(),
                        contentPadding = PaddingValues(vertical = 8.dp)
                    ) {
                        items(chartSections, key = { it.first }) { sec ->
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(horizontal = 16.dp, vertical = 8.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(
                                    text = sec.second,
                                    style = MaterialTheme.typography.titleMedium,
                                    fontWeight = FontWeight.Bold,
                                    color = musicColors().textPrimary
                                )
                                Spacer(modifier = Modifier.weight(1f))
                                Text(
                                    text = "全部 >",
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = musicColors().accent,
                                    modifier = Modifier.clickable {
                                        chartDetail = sec
                                        gridItems = sec.third
                                    }
                                )
                            }
                            LazyRow(
                                contentPadding = PaddingValues(horizontal = 16.dp),
                                horizontalArrangement = Arrangement.spacedBy(12.dp)
                            ) {
                                itemsIndexed(sec.third, key = { _, it -> it.sourceKey + ":" + it.id }) { idx, track ->
                                    SubSectionCard(track = track, rank = idx + 1, onPlay = { playTrack(track, sec.third) })
                                }
                            }
                            Spacer(modifier = Modifier.height(16.dp))
                        }
                        if (sectionsLoading) {
                            item {
                                Text(
                                    text = "正在加载更多分类…",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = musicColors().textSecondary,
                                    modifier = Modifier.padding(16.dp)
                                )
                            }
                        }
                    }
                }
            } else if (gridLoading) {
                Text(
                    text = "正在加载浏览内容…","""
src = src.replace(old_chain, new_chain, 1)

# 4. 钻入整页网格的返回行（与“返回歌手”并列）
old_back = """                if (tab == 0 && showingArtistTracks) {
                    Text(
                        text = "← 返回歌手",
                        style = MaterialTheme.typography.bodyMedium,
                        color = musicColors().accent,
                        modifier = Modifier
                            .clickable { showingArtistTracks = false }
                            .padding(horizontal = 16.dp, vertical = 8.dp)
                    )
                }"""
assert src.count(old_back) == 1, "back anchor count %d" % src.count(old_back)
src = src.replace(old_back, old_back + """
                if (tab == 1 && chartDetail != null) { // [46v13] 从分类整页回分段视图
                    Text(
                        text = "← 返回榜单",
                        style = MaterialTheme.typography.bodyMedium,
                        color = musicColors().accent,
                        modifier = Modifier
                            .clickable { chartDetail = null }
                            .padding(horizontal = 16.dp, vertical = 8.dp)
                    )
                }""", 1)

# 5. 整页网格名次统一到右上角（与段内卡片一致；备注 chip 仍在左上角，不冲突）
old_rank = """                    text = rank.toString(),
                    style = MaterialTheme.typography.bodySmall,
                    color = musicColors().textPrimary,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier
                        .align(Alignment.BottomStart)"""
assert src.count(old_rank) == 1, "rank anchor count %d" % src.count(old_rank)
src = src.replace(old_rank, """                    text = rank.toString(),
                    style = MaterialTheme.typography.bodySmall,
                    color = musicColors().textPrimary,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier
                        .align(Alignment.TopEnd) // [46v13] 名次统一右上角""", 1)

# 6. 文件尾追加段内横滑卡片（竖版）
old_tail = """        Text(
            text = name,
            style = MaterialTheme.typography.bodyMedium,
            color = musicColors().textPrimary,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis
        )
    }
}"""
assert src.count(old_tail) == 1, "tail anchor count %d" % src.count(old_tail)
src = src.replace(old_tail, """        Text(
            text = name,
            style = MaterialTheme.typography.bodyMedium,
            color = musicColors().textPrimary,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis
        )
    }
}

@Composable
private fun SubSectionCard(track: SubMusicBridge.SubTrack, rank: Int, onPlay: () -> Unit) { // [46v13] 榜单段内横滑卡：竖版＋右上角名次，点卡播本段队列
    val cardBg = musicColors().card
    Column(modifier = Modifier.width(120.dp).clickable { onPlay() }) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .aspectRatio(3f / 4f)
                .clip(MaterialTheme.shapes.medium)
                .background(cardBg),
            contentAlignment = Alignment.Center
        ) {
            if (track.pic.isNotBlank()) {
                AsyncImage(
                    model = track.pic,
                    contentDescription = null,
                    contentScale = ContentScale.Crop,
                    modifier = Modifier.fillMaxSize()
                )
            } else {
                Text(
                    text = track.title.take(1),
                    color = musicColors().textSecondary
                )
            }
            Text(
                text = rank.toString(),
                style = MaterialTheme.typography.bodySmall,
                color = musicColors().textPrimary,
                fontWeight = FontWeight.Bold,
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .padding(6.dp)
                    .clip(MaterialTheme.shapes.small)
                    .background(cardBg.copy(alpha = 0.8f))
                    .padding(horizontal = 6.dp, vertical = 2.dp)
            )
        }
        Spacer(modifier = Modifier.height(6.dp))
        Text(
            text = track.title,
            style = MaterialTheme.typography.bodyMedium,
            color = musicColors().textPrimary,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis
        )
    }
}""", 1)

assert src.count("fun SubSectionCard") == 1
assert src.count("chartSections") >= 5
assert src.count("Alignment.BottomStart") == 0
open(path, "w", encoding="utf-8").write(src)
print("OK 46v13 screen")
PYEOF46V13
grep -q "46v13" avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicScreen.kt || { echo "X 46v13 screen"; exit 1; }
echo "OK 46v13"
echo "=== 46 v13 done ==="

# === 46 v14: 三页壁纸透明（同设置页） ===

echo "=== 46 v14 ==="

python3 - << 'PYEOF46V14'
import sys

# 46 v14：三页（曲库/搜索/我的）像设置页一样透明——有壁纸时页底透明、卡片磨砂（card 0.45 + 白 0.15 描边）
# 参照：SettingsScreen.kt:77（页底 WallpaperManager.isActive() ? Transparent : background）、:96/:206/:342（磨砂卡片）

ROOT_OLD = "            .background(musicColors().background)"
ROOT_NEW = "            .background(if (WallpaperManager.isActive()) androidx.compose.ui.graphics.Color.Transparent else musicColors().background) // [46v14] 有壁纸时透明（同设置页）"

# ---- 曲库页 SubMusicScreen.kt ----
path = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicScreen.kt"
src = open(path, encoding="utf-8").read()
if "// [46v14]" not in src:
    old_head = "源选择由顶栏 Sheet 驱动，本页只读。"
    assert src.count(old_head) == 1, "screen head count %d" % src.count(old_head)
    src = src.replace(old_head, "源选择由顶栏 Sheet 驱动，本页只读；[46v14] 有壁纸时页底透明、卡片磨砂（同设置页）。", 1)

    old_imp = "import androidx.compose.foundation.background\n"
    assert src.count(old_imp) == 1, "screen import bg count %d" % src.count(old_imp)
    src = src.replace(old_imp, old_imp + "import androidx.compose.foundation.border\n", 1)
    old_imp2 = "import androidx.compose.ui.draw.clip\n"
    assert src.count(old_imp2) == 1, "screen import clip count %d" % src.count(old_imp2)
    src = src.replace(old_imp2, old_imp2 + "import androidx.compose.ui.graphics.Color\n", 1)

    assert src.count(ROOT_OLD) == 1, "screen root count %d" % src.count(ROOT_OLD)
    src = src.replace(ROOT_OLD, ROOT_NEW, 1)

    old_under = ".background(if (tab == i) musicColors().accent else musicColors().background)"
    assert src.count(old_under) == 1, "underline count %d" % src.count(old_under)
    src = src.replace(old_under, ".background(if (tab == i) musicColors().accent else Color.Transparent) // [46v14] 未选中下划线透明（壁纸上不留黑条）", 1)

    old_grid = "                .background(cardBg)\n        ) {"
    assert src.count(old_grid) == 1, "grid card count %d" % src.count(old_grid)
    src = src.replace(old_grid, "                .background(cardBg.copy(alpha = 0.45f)) // [46v14] 磨砂卡片（同设置页）\n                .border(0.5.dp, Color.White.copy(alpha = 0.15f), MaterialTheme.shapes.medium)\n        ) {", 1)

    old_card = "                .background(cardBg),\n            contentAlignment = Alignment.Center"
    assert src.count(old_card) == 2, "artist/section card count %d" % src.count(old_card)
    src = src.replace(old_card, "                .background(cardBg.copy(alpha = 0.45f)) // [46v14] 磨砂卡片（同设置页）\n                .border(0.5.dp, Color.White.copy(alpha = 0.15f), MaterialTheme.shapes.medium),\n            contentAlignment = Alignment.Center")
    open(path, "w", encoding="utf-8").write(src)
    print("OK 46v14 screen")
else:
    print("screen already 46v14, skip")

# ---- 搜索页 SubSearchScreen.kt ----
path = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubSearchScreen.kt"
src = open(path, encoding="utf-8").read()
if "// [46v14]" not in src:
    old_head = "切歌/列表点播走订阅解析。"
    assert src.count(old_head) == 1, "search head count %d" % src.count(old_head)
    src = src.replace(old_head, "切歌/列表点播走订阅解析；[46v14] 有壁纸时页底透明、占位缩略图磨砂（同设置页）。", 1)

    old_imp = "import androidx.compose.foundation.background\n"
    assert src.count(old_imp) == 1, "search import bg count %d" % src.count(old_imp)
    src = src.replace(old_imp, old_imp + "import androidx.compose.foundation.border\n", 1)
    old_imp2 = "import androidx.compose.ui.draw.clip\n"
    assert src.count(old_imp2) == 1, "search import clip count %d" % src.count(old_imp2)
    src = src.replace(old_imp2, old_imp2 + "import androidx.compose.ui.graphics.Color\n", 1)

    assert src.count(ROOT_OLD) == 1, "search root count %d" % src.count(ROOT_OLD)
    src = src.replace(ROOT_OLD, ROOT_NEW, 1)

    old_thumb = """                    .background(musicColors().card),
                contentAlignment = Alignment.Center"""
    assert src.count(old_thumb) == 1, "thumb count %d" % src.count(old_thumb)
    src = src.replace(old_thumb, """                    .background(musicColors().card.copy(alpha = 0.45f)) // [46v14] 磨砂（同设置页）
                    .border(0.5.dp, Color.White.copy(alpha = 0.15f), androidx.compose.foundation.shape.RoundedCornerShape(8.dp)),
                contentAlignment = Alignment.Center""", 1)
    open(path, "w", encoding="utf-8").write(src)
    print("OK 46v14 search")
else:
    print("search already 46v14, skip")

# ---- 我的页 SubMineScreen.kt ----
path = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMineScreen.kt"
src = open(path, encoding="utf-8").read()
if "// [46v14]" not in src:
    old_head = "// [46v9] 我的页：先放我的喜欢 + 播放历史两块现成的（与设置页同一入口）。"
    assert src.count(old_head) == 1, "mine head count %d" % src.count(old_head)
    src = src.replace(old_head, "// [46v14] 我的页：先放我的喜欢 + 播放历史两块现成的（与设置页同一入口）；有壁纸时页底透明（同设置页）。", 1)
    assert src.count(ROOT_OLD) == 1, "mine root count %d" % src.count(ROOT_OLD)
    src = src.replace(ROOT_OLD, ROOT_NEW, 1)
    open(path, "w", encoding="utf-8").write(src)
    print("OK 46v14 mine")
else:
    print("mine already 46v14, skip")
PYEOF46V14
grep -q "46v14" avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicScreen.kt || { echo "X 46v14 screen"; exit 1; }
grep -q "46v14" avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubSearchScreen.kt || { echo "X 46v14 search"; exit 1; }
grep -q "46v14" avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMineScreen.kt || { echo "X 46v14 mine"; exit 1; }
echo "OK 46v14"
echo "=== 46 v14 done ==="

# === 46 v15: 歌手过滤＋榜单只拉有用分类 ===

echo "=== 46 v15 ==="

python3 - << 'PYEOF46V15A'
import sys

# 46 v15 桥接：杂项名过滤＋合作歌手拆分（歌手页去乱 + 榜单只拉有用分类共用）
path = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicBridge.kt"
src = open(path, encoding="utf-8").read()
if "// [46v15]" in src:
    print("bridge already 46v15, skip")
    sys.exit(0)

old_fn = """    fun artistOf(track: SubTrack): String? { // [46v12] 歌手推导：合集备注→标题即歌手；否则 vod_actor；否则不含 > 的备注
        if (track.remark.contains("合集") || track.remark.contains("专辑")) return track.title.ifBlank { null }
        if (track.actor.isNotBlank()) return track.actor
        if (track.remark.isNotBlank() && !track.remark.contains(">")) return track.remark
        return null
    }"""
assert src.count(old_fn) == 1, "artistOf anchor count %d" % src.count(old_fn)
new_fn = """    private val JUNK_HINTS = listOf("点击", "上移", "下移", "调整", "恢复", "默认", "分类", "设置") // [46v15] 杂项信号词：源自带的导航/操作项标题里有这些词

    fun isJunkName(name: String): Boolean { // [46v15] 杂项名：空白、纯数字（榜单名次备注）、含杂项信号词
        val n = name.trim()
        return n.isEmpty() || n.all { it.isDigit() } || JUNK_HINTS.any { n.contains(it) }
    }

    fun artistsOf(track: SubTrack): List<String> { // [46v15] 歌手推导（多名）：合集备注→标题、否则 vod_actor、否则不含 > 的备注；合作歌手按 &/、/，拆；杂项名过滤
        val raw: String? = when {
            track.remark.contains("合集") || track.remark.contains("专辑") -> track.title.ifBlank { null }
            track.actor.isNotBlank() -> track.actor
            track.remark.isNotBlank() && !track.remark.contains(">") -> track.remark
            else -> null
        } ?: return emptyList()
        return raw.split("&", "＆", "、", "，", ",").map { it.trim() }.filter { it.isNotEmpty() && !isJunkName(it) }
    }

    fun artistOf(track: SubTrack): String? = artistsOf(track).firstOrNull() // [46v15] 兼容旧调用"""
src = src.replace(old_fn, new_fn, 1)

assert src.count("fun artistsOf") == 1
assert src.count("fun isJunkName") == 1
open(path, "w", encoding="utf-8").write(src)
print("OK 46v15 bridge")
PYEOF46V15A

python3 - << 'PYEOF46V15B'
import sys

# 46 v15 曲库页：歌手过滤（拆合作歌手、去杂项、合集图优先）＋榜单只拉有用分类（杂项分类不拉、段内杂项条目过滤）
path = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicScreen.kt"
src = open(path, encoding="utf-8").read()
if "// [46v15]" in src:
    print("screen already 46v15, skip")
    sys.exit(0)

old_head = "有壁纸时页底透明、卡片磨砂（同设置页）。"
assert src.count(old_head) == 1, "head anchor count %d" % src.count(old_head)
src = src.replace(old_head, "有壁纸时页底透明、卡片磨砂（同设置页）；[46v15] 歌手过滤＋榜单只拉有用分类。", 1)

old_artists = """    val artists = remember(home, chartItems) { // [46v12] 歌手推导：首页＋榜单条目去重
        val seen = LinkedHashMap<String, String>()
        for (t in (home?.items ?: emptyList()) + chartItems) {
            val name = SubMusicBridge.artistOf(t) ?: continue
            if (!seen.containsKey(name)) seen[name] = t.pic
        }
        seen.map { (name, pic) -> name to pic }
    }"""
assert src.count(old_artists) == 1, "artists anchor count %d" % src.count(old_artists)
new_artists = """    val artists = remember(home, chartItems) { // [46v15] 歌手推导：拆合作歌手、去杂项、合集图优先
        val classNames = home?.classes?.map { it.name } ?: emptyList()
        val sectionWords = listOf("歌手", "热门", "歌单", "榜单", "全部", "更多")
        fun okName(n: String) = !SubMusicBridge.isJunkName(n) && sectionWords.none { n.contains(it) } && !classNames.contains(n)
        val seen = LinkedHashMap<String, String>()
        val all = (home?.items ?: emptyList()) + chartItems
        val ordered = all.filter { it.remark.contains("合集") || it.remark.contains("专辑") } + all.filter { !(it.remark.contains("合集") || it.remark.contains("专辑")) }
        for (t in ordered) {
            for (name in SubMusicBridge.artistsOf(t)) {
                if (!okName(name)) continue
                if (!seen.containsKey(name)) seen[name] = t.pic
            }
        }
        seen.map { (name, pic) -> name to pic }
    }"""
src = src.replace(old_artists, new_artists, 1)

old_loop = """                for (cls in h.classes) { // [46v13] 全量分类逐段拉第 1 页，有数据的段先出
                    try {
                        val items = SubMusicBridge.category(src.key, cls.id)"""
assert src.count(old_loop) == 1, "loop anchor count %d" % src.count(old_loop)
new_loop = """                for (cls in h.classes) { // [46v15] 只拉有用的分类：杂项分类、歌手类分类跳过不拉
                    if (SubMusicBridge.isJunkName(cls.name) || cls.name.contains("歌手")) continue
                    try {
                        val items = SubMusicBridge.category(src.key, cls.id).filter { !SubMusicBridge.isJunkName(it.title) } // [46v15] 段内杂项条目过滤"""
src = src.replace(old_loop, new_loop, 1)

assert src.count("fun artistsOf") == 0  # screen must not define it, only call it
assert src.count("SubMusicBridge.artistsOf(t)") == 1
assert src.count("isJunkName(cls.name)") == 1
open(path, "w", encoding="utf-8").write(src)
print("OK 46v15 screen")
PYEOF46V15B

grep -q "46v15" avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicBridge.kt || { echo "X 46v15 bridge"; exit 1; }
grep -q "46v15" avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicScreen.kt || { echo "X 46v15 screen"; exit 1; }
echo "OK 46v15"
echo "=== 46 v15 done ==="

# === 46 v16: 分桶整理（歌手/歌单/榜单三分） ===

echo "=== 46 v16 ==="

python3 - << 'PYEOF46V16A'
import sys

# 46 v16 桥接：分桶信号（人名、歌单型）
path = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicBridge.kt"
src = open(path, encoding="utf-8").read()
if "// [46v16]" in src:
    print("bridge already 46v16, skip")
    sys.exit(0)

old_fn = '    fun artistOf(track: SubTrack): String? = artistsOf(track).firstOrNull() // [46v15] 兼容旧调用'
assert src.count(old_fn) == 1, "artistOf anchor count %d" % src.count(old_fn)
new_fn = old_fn + """

    fun isPersonName(title: String): Boolean { // [46v16] 人名信号：短（≤4 字）、无分隔符/括号/书名号、无歌单类词（“伤感歌单”4 字不是人名）
        val n = title.trim()
        if (n.isEmpty() || n.length > 4) return false
        if (listOf("歌单", "合集", "专辑", "精选", "榜单", "排行", "热门", "推荐").any { n.contains(it) }) return false
        return !n.contains("&") && !n.contains("＆") && !n.contains("、") && !n.contains("，") && !n.contains(",") && !n.contains(" ") && !n.contains("-") && !n.contains("《") && !n.contains("》") && !n.contains("(") && !n.contains("（")
    }

    fun isCollection(track: SubTrack): Boolean { // [46v16] 歌单型：备注合集/专辑/歌单，且标题不像人名（人名合集归歌手 tab）
        val remark = track.remark
        return (remark.contains("合集") || remark.contains("专辑") || remark.contains("歌单")) && !isPersonName(track.title)
    }"""
src = src.replace(old_fn, new_fn, 1)

# 补：artistsOf 规则一加“歌单”（备注“歌单”且标题是人名时，标题即歌手；标题是歌单名时由 okName 滤掉）
old_rule1 = '            track.remark.contains("合集") || track.remark.contains("专辑") -> track.title.ifBlank { null }'
assert src.count(old_rule1) == 1, "rule1 anchor count %d" % src.count(old_rule1)
src = src.replace(old_rule1, '            track.remark.contains("合集") || track.remark.contains("专辑") || track.remark.contains("歌单") -> track.title.ifBlank { null } // [46v16] 规则一加歌单', 1)

assert src.count("fun isPersonName") == 1
assert src.count("fun isCollection") == 1
open(path, "w", encoding="utf-8").write(src)
print("OK 46v16 bridge")
PYEOF46V16A

python3 - << 'PYEOF46V16B'
import sys

# 46 v16 曲库页：分桶整理——歌手/歌单/榜单三分（歌手=推导歌手，歌单=合集型条目，榜单=按分类分段）
path = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicScreen.kt"
src = open(path, encoding="utf-8").read()
if "// [46v16]" in src:
    print("screen already 46v16, skip")
    sys.exit(0)

old_head = "；[46v15] 歌手过滤＋榜单只拉有用分类。"
assert src.count(old_head) == 1, "head anchor count %d" % src.count(old_head)
src = src.replace(old_head, "；[46v15] 歌手过滤＋榜单只拉有用分类；[46v16] 分桶整理（歌手/歌单/榜单三分）。", 1)

# 1. 分桶原料 pool（放 artists 之前，artists 改用 pool）
old_artists_head = "    val artists = remember(home, chartItems) { // [46v15] 歌手推导：拆合作歌手、去杂项、合集图优先"
assert src.count(old_artists_head) == 1, "artists head count %d" % src.count(old_artists_head)
src = src.replace(old_artists_head, """    val pool = remember(home, chartItems) { // [46v16] 分桶原料：首页＋全部分段，去杂项、去重
        val names = home?.classes?.map { it.name } ?: emptyList()
        ((home?.items ?: emptyList()) + chartItems)
            .filter { !SubMusicBridge.isJunkName(it.title) && !names.contains(it.title.trim()) && it.title.trim() != "热门歌曲" }
            .distinctBy { it.sourceKey + ":" + it.id }
    }

""" + old_artists_head, 1)

old_all = "        val all = (home?.items ?: emptyList()) + chartItems"
assert src.count(old_all) == 1, "all anchor count %d" % src.count(old_all)
src = src.replace(old_all, "        val all = pool", 1)

old_artists_tail = """        seen.map { (name, pic) -> name to pic }
    }"""
assert src.count(old_artists_tail) == 1, "artists tail count %d" % src.count(old_artists_tail)
src = src.replace(old_artists_tail, old_artists_tail + """

    val playlists = remember(pool) { // [46v16] 歌单桶：合集型条目（人名合集除外，归歌手）
        pool.filter { SubMusicBridge.isCollection(it) }
    }""", 1)

# 2. Tab 标签三分
old_tabs = 'listOf("歌手", "榜单").forEachIndexed { i, label -> // [46v12] 歌单改歌手'
assert src.count(old_tabs) == 1, "tabs anchor count %d" % src.count(old_tabs)
src = src.replace(old_tabs, 'listOf("歌手", "歌单", "榜单").forEachIndexed { i, label -> // [46v16] 分桶三分', 1)

# 3. applyTab：t==1 歌单为派生视图，不拉数据
old_t0 = """        if (t == 0) {
            gridItems = emptyList()
            gridNote = ""
            return
        }"""
assert src.count(old_t0) == 1, "t0 anchor count %d" % src.count(old_t0)
src = src.replace(old_t0, old_t0 + """
        if (t == 1) { // [46v16] 歌单 tab：派生视图，不拉数据
            gridItems = emptyList()
            gridNote = ""
            return
        }""", 1)

# 4. 分段视图改 tab==2
old_sec = "            if (tab == 1 && chartDetail == null) { // [46v13] 榜单分段视图"
assert src.count(old_sec) == 1, "sec anchor count %d" % src.count(old_sec)
src = src.replace(old_sec, "            if (tab == 2 && chartDetail == null) { // [46v13] 榜单分段视图", 1)

# 5. 歌单分支插在歌手分支之后、兜底网格之前
old_grid_branch = """                        items(artists, key = { it.first }) { a ->
                            SubArtistCard(name = a.first, pic = a.second, onClick = { openArtist(a.first) })
                        }
                    }
                }
            } else {"""
assert src.count(old_grid_branch) == 1, "grid branch anchor count %d" % src.count(old_grid_branch)
new_grid_branch = """                        items(artists, key = { it.first }) { a ->
                            SubArtistCard(name = a.first, pic = a.second, onClick = { openArtist(a.first) })
                        }
                    }
                }
            } else if (tab == 1) { // [46v16] 歌单 tab：合集型条目网格
                if (playlists.isEmpty()) {
                    Text(
                        text = "该源暂无歌单",
                        style = MaterialTheme.typography.bodyMedium,
                        color = musicColors().textSecondary,
                        modifier = Modifier.padding(16.dp)
                    )
                } else {
                    LazyVerticalGrid(
                        columns = GridCells.Fixed(3),
                        modifier = Modifier.fillMaxSize(),
                        contentPadding = PaddingValues(16.dp),
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                        verticalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        items(playlists, key = { it.sourceKey + ":" + it.id }) { track ->
                            SubGridCard(track = track, onPlay = { playTrack(track, playlists) })
                        }
                    }
                }
            } else {"""
src = src.replace(old_grid_branch, new_grid_branch, 1)

# 6. 返回榜单与名次改 tab==2
old_back = "                if (tab == 1 && chartDetail != null) { // [46v13] 从分类整页回分段视图"
assert src.count(old_back) == 1, "back anchor count %d" % src.count(old_back)
src = src.replace(old_back, "                if (tab == 2 && chartDetail != null) { // [46v13] 从分类整页回分段视图", 1)

old_rank = "rank = if (tab == 1) idx + 1 else null"
assert src.count(old_rank) == 1, "rank anchor count %d" % src.count(old_rank)
src = src.replace(old_rank, "rank = if (tab == 2) idx + 1 else null", 1)

assert src.count('listOf("歌手", "歌单", "榜单")') == 1
assert src.count("fun isCollection") == 0  # screen must not define it, only call it
open(path, "w", encoding="utf-8").write(src)
print("OK 46v16 screen")
PYEOF46V16B

grep -q "46v16" avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicBridge.kt || { echo "X 46v16 bridge"; exit 1; }
grep -q "46v16" avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicScreen.kt || { echo "X 46v16 screen"; exit 1; }
echo "OK 46v16"
echo "=== 46 v16 done ==="

# === 46 v17: 修 228:19 构建红 ===

echo "=== 46 v17 ==="

python3 - << 'PYEOF46V17'
import sys

# 46 v17：修 v15/v16 构建红——SubMusicBridge.kt:228:19，raw.split 的 raw 仍是 String?
# 根因：val raw: String? = when {...} ?: return emptyList() ——初始化器里的 ?: return 没让编译器把 raw 收窄为非空；
# 另 track.title.ifBlank { null } 的类型靠推断（泛型 ifBlank 的 C 随上下文变），一并换成 takeIf
path = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicBridge.kt"
src = open(path, encoding="utf-8").read()
if "// [46v17]" in src:
    print("bridge already 46v17, skip")
    sys.exit(0)

old_fn = """    fun artistsOf(track: SubTrack): List<String> { // [46v15] 歌手推导（多名）：合集备注→标题、否则 vod_actor、否则不含 > 的备注；合作歌手按 &/、/，拆；杂项名过滤
        val raw: String? = when {
            track.remark.contains("合集") || track.remark.contains("专辑") || track.remark.contains("歌单") -> track.title.ifBlank { null } // [46v16] 规则一加歌单
            track.actor.isNotBlank() -> track.actor
            track.remark.isNotBlank() && !track.remark.contains(">") -> track.remark
            else -> null
        } ?: return emptyList()
        return raw.split("&", "＆", "、", "，", ",").map { it.trim() }.filter { it.isNotEmpty() && !isJunkName(it) }
    }"""
assert src.count(old_fn) == 1, "artistsOf anchor count %d" % src.count(old_fn)
new_fn = """    fun artistsOf(track: SubTrack): List<String> { // [46v17] 修 228:19 构建红：判空改显式检查，ifBlank{null} 改 takeIf
        val raw: String? = when {
            track.remark.contains("合集") || track.remark.contains("专辑") || track.remark.contains("歌单") -> track.title.takeIf { it.isNotBlank() }
            track.actor.isNotBlank() -> track.actor
            track.remark.isNotBlank() && !track.remark.contains(">") -> track.remark
            else -> null
        }
        if (raw.isNullOrBlank()) return emptyList()
        return raw.split("&", "＆", "、", "，", ",").map { it.trim() }.filter { it.isNotEmpty() && !isJunkName(it) }
    }"""
src = src.replace(old_fn, new_fn, 1)

assert src.count("ifBlank { null }") == 0
assert src.count("isNullOrBlank()) return emptyList()") == 1
open(path, "w", encoding="utf-8").write(src)
print("OK 46v17 bridge")
PYEOF46V17
grep -q "46v17" avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicBridge.kt || { echo "X 46v17 bridge"; exit 1; }
echo "OK 46v17"
echo "=== 46 v17 done ==="

# === 46 v18: 歌手推导收紧（对照 Peek/主体：只用真歌手信号） ===

echo "=== 46 v18 ==="

python3 - << 'PYEOF46V18B'
import sys

# 46 v18：歌手推导收紧——只用真歌手信号（对照 Peek/主体：它们按源自己的分类摆歌单/榜单，从不从备注猜歌手）
# 故障（2026-11-05 14:31 用户截图，v17 包，酷我源歌手 tab）：
#   规则三把榜单条目的备注（说明文字）当歌手：“按搜索播放数”“播放时”“根据公开市场…”“酷我会员用户…”“按歌曲热度”
#   规则一把榜单名当歌手：“飙升榜”“新歌榜”“会员畅听”“会员飙升榜”“视频歌曲”（备注带歌单字样或备注本身就是榜单名）
#   导航/提示项当歌手：“当前平台：酷…”“在酷我音乐 搜…”“酷我每日搜索…”（标题无 v15 杂项词）
# 挡不住的原因：okName 只拦含“榜单”（两字）的名，“飙升榜”只含“榜”；isPersonName 的排除表只有“榜单”没有单字“榜”；
#   isJunkName 只认点击/上移/调整…，不认平台/搜索/当前/榜/排行/畅听/会员
# 修法：artistsOf 三规则全部加门——规则一要求标题本身是人名且非榜单/导航类；规则二 vod_actor 不动（唯一真歌手字段）；
#   规则三（备注当歌手）只认“像人名的备注”且条目本身得是单曲样的、备注不能是说明文字；isPersonName 排除表扩到单字榜及榜单/导航/说明类词；
#   isCollection 加榜单/导航类标题排除；新增 isChartLike/isNavTitle 供屏幕层过滤
path = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicBridge.kt"
src = open(path, encoding="utf-8").read()
if "// [46v18]" in src:
    print("bridge already 46v18, skip")
    sys.exit(0)

old_junk = """    fun isJunkName(name: String): Boolean { // [46v15] 杂项名：空白、纯数字（榜单名次备注）、含杂项信号词
        val n = name.trim()
        return n.isEmpty() || n.all { it.isDigit() } || JUNK_HINTS.any { n.contains(it) }
    }"""
assert src.count(old_junk) == 1, "junk anchor %d" % src.count(old_junk)
new_junk = old_junk + """

    private val CHART_WORDS = listOf("榜", "排行", "飙升", "新歌", "畅听", "会员", "热歌", "金曲", "视频") // [46v18] 榜单类信号词：榜单名、榜单说明不进歌手、歌单桶
    private val NAV_WORDS = listOf("平台", "搜索", "当前", "每日", "：") // [46v18] 导航/提示项信号词：“当前平台：酷我音乐”这类首页导航项
    private val DESC_WORDS = listOf("播放", "搜索", "市场", "热度", "用户", "酷我", "按", "根据") // [46v18] 说明文字信号词：备注当歌手时排除

    fun isChartLike(text: String): Boolean = CHART_WORDS.any { text.contains(it) } // [46v18] 榜单类标题/名

    fun isNavTitle(text: String): Boolean = NAV_WORDS.any { text.contains(it) } // [46v18] 导航/提示类标题"""
src = src.replace(old_junk, new_junk, 1)

old_artists = """    fun artistsOf(track: SubTrack): List<String> { // [46v17] 修 228:19 构建红：判空改显式检查，ifBlank{null} 改 takeIf
        val raw: String? = when {
            track.remark.contains("合集") || track.remark.contains("专辑") || track.remark.contains("歌单") -> track.title.takeIf { it.isNotBlank() }
            track.actor.isNotBlank() -> track.actor
            track.remark.isNotBlank() && !track.remark.contains(">") -> track.remark
            else -> null
        }
        if (raw.isNullOrBlank()) return emptyList()
        return raw.split("&", "＆", "、", "，", ",").map { it.trim() }.filter { it.isNotEmpty() && !isJunkName(it) }
    }"""
assert src.count(old_artists) == 1, "artistsOf anchor %d" % src.count(old_artists)
new_artists = """    fun artistsOf(track: SubTrack): List<String> { // [46v18] 歌手推导收紧：只用真歌手信号——vod_actor、合集类人名标题、像人名的备注（榜单说明/导航项不再当歌手）
        val out = LinkedHashSet<String>()
        fun addNames(raw: String?) {
            if (raw.isNullOrBlank()) return
            raw.split("&", "＆", "、", "，", ",").map { it.trim() }.filter { it.isNotEmpty() && !isJunkName(it) }.forEach { out.add(it) }
        }
        if ((track.remark.contains("合集") || track.remark.contains("专辑") || track.remark.contains("歌单")) && isPersonName(track.title) && !isChartLike(track.title) && !isNavTitle(track.title)) addNames(track.title)
        if (track.actor.isNotBlank()) addNames(track.actor)
        if (!isChartLike(track.title) && !isNavTitle(track.title) && track.remark.isNotBlank() && !track.remark.contains(">") && isPersonName(track.remark) && DESC_WORDS.none { track.remark.contains(it) }) addNames(track.remark)
        return out.toList()
    }"""
src = src.replace(old_artists, new_artists, 1)

old_person = """    fun isPersonName(title: String): Boolean { // [46v16] 人名信号：短（≤4 字）、无分隔符/括号/书名号、无歌单类词（“伤感歌单”4 字不是人名）
        val n = title.trim()
        if (n.isEmpty() || n.length > 4) return false
        if (listOf("歌单", "合集", "专辑", "精选", "榜单", "排行", "热门", "推荐").any { n.contains(it) }) return false"""
assert src.count(old_person) == 1, "isPersonName anchor %d" % src.count(old_person)
new_person = """    fun isPersonName(title: String): Boolean { // [46v18] 人名信号收紧：榜单/导航/说明/曲风类词（榜、畅听、会员、搜索、平台、播放、粤语、经典…）一律不是人名
        val n = title.trim()
        if (n.isEmpty() || n.length > 4) return false
        if (listOf("歌单", "合集", "专辑", "精选", "榜", "排行", "热门", "推荐", "畅听", "会员", "飙升", "新歌", "热歌", "金曲", "视频", "搜索", "平台", "播放", "当前", "每日", "粤语", "国语", "经典", "流行", "怀旧", "伤感", "治愈", "古风", "民谣", "摇滚", "纯音乐", "轻音乐", "钢琴", "电音", "舞曲", "老歌").any { n.contains(it) }) return false"""
src = src.replace(old_person, new_person, 1)

old_coll = """    fun isCollection(track: SubTrack): Boolean { // [46v16] 歌单型：备注合集/专辑/歌单，且标题不像人名（人名合集归歌手 tab）
        val remark = track.remark
        return (remark.contains("合集") || remark.contains("专辑") || remark.contains("歌单")) && !isPersonName(track.title)
    }"""
assert src.count(old_coll) == 1, "isCollection anchor %d" % src.count(old_coll)
new_coll = """    fun isCollection(track: SubTrack): Boolean { // [46v18] 歌单型：备注合集/专辑/歌单，标题是人名归歌手、榜单/导航类标题排除
        val remark = track.remark
        return (remark.contains("合集") || remark.contains("专辑") || remark.contains("歌单")) && !isPersonName(track.title) && !isChartLike(track.title) && !isNavTitle(track.title)
    }"""
src = src.replace(old_coll, new_coll, 1)

open(path, "w", encoding="utf-8").write(src)
print("OK 46v18 bridge")
PYEOF46V18B
python3 - << 'PYEOF46V18S'
import sys

# 46 v18（屏幕侧）：歌手原料先排掉榜单/导航类条目；okName 拦词扩到单字榜及榜单/导航/说明类词；榜单分段跳过导航类分类
path = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicScreen.kt"
src = open(path, encoding="utf-8").read()
if "// [46v18]" in src:
    print("screen already 46v18, skip")
    sys.exit(0)

old_all = "        val all = pool"
assert src.count(old_all) == 1, "all anchor %d" % src.count(old_all)
new_all = "        val all = pool.filter { !SubMusicBridge.isChartLike(it.title) && !SubMusicBridge.isNavTitle(it.title) } // [46v18] 歌手原料先排掉榜单/导航类条目"
src = src.replace(old_all, new_all, 1)

old_words = '        val sectionWords = listOf("歌手", "热门", "歌单", "榜单", "全部", "更多")'
assert src.count(old_words) == 1, "sectionWords anchor %d" % src.count(old_words)
new_words = '        val sectionWords = listOf("歌手", "热门", "歌单", "榜单", "全部", "更多", "榜", "排行", "畅听", "会员", "飙升", "新歌", "搜索", "平台", "播放", "当前", "每日", "热歌", "金曲", "视频", "粤语", "国语", "经典", "流行", "怀旧", "伤感", "治愈", "古风", "民谣", "摇滚", "纯音乐", "轻音乐", "钢琴", "电音", "舞曲", "老歌") // [46v18] 拦词扩到单字榜及榜单/导航/说明类词'
src = src.replace(old_words, new_words, 1)

old_cls = '                    if (SubMusicBridge.isJunkName(cls.name) || cls.name.contains("歌手")) continue'
assert src.count(old_cls) == 1, "cls anchor %d" % src.count(old_cls)
new_cls = '                    if (SubMusicBridge.isJunkName(cls.name) || cls.name.contains("歌手") || SubMusicBridge.isNavTitle(cls.name)) continue // [46v18] 导航类分类跳过不拉'
src = src.replace(old_cls, new_cls, 1)

open(path, "w", encoding="utf-8").write(src)
print("OK 46v18 screen")
PYEOF46V18S
grep -q "46v18" avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicBridge.kt || { echo "X 46v18 bridge"; exit 1; }
grep -q "46v18" avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicScreen.kt || { echo "X 46v18 screen"; exit 1; }
echo "OK 46v18"
echo "=== 46 v18 done ==="

# === 46 v19: 曲库按 Peek 改紧致简洁（两 pill tab＋平铺榜单＋Peek 卡＋MH 顶栏） ===

echo "=== 46 v19 ==="

python3 - << 'PYEOF46V19B'
import sys

# 46 v19（桥接侧）：歌手 tab 按 Peek 拿掉——歌手推导整段删除（artistsOf/artistOf/isPersonName/DESC_WORDS）；
# 歌单判定改 Peek 口径：有首数就是歌单（Peek 歌单卡都有首数，含热歌榜这类榜单名），或备注合集/专辑/歌单且标题非榜单类；
# 人名合集不再单列（无歌手 tab 可归，合集就是歌单）；导航项排除；新增 countOf（备注里取“355首”，没有不显示）
path = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicBridge.kt"
src = open(path, encoding="utf-8").read()
if "// [46v19]" in src:
    print("bridge already 46v19, skip")
    sys.exit(0)

old_desc = '    private val DESC_WORDS = listOf("播放", "搜索", "市场", "热度", "用户", "酷我", "按", "根据") // [46v18] 说明文字信号词：备注当歌手时排除\n'
assert src.count(old_desc) == 1, "desc anchor %d" % src.count(old_desc)
src = src.replace(old_desc, "", 1)

old_artists = """    fun artistsOf(track: SubTrack): List<String> { // [46v18] 歌手推导收紧：只用真歌手信号——vod_actor、合集类人名标题、像人名的备注（榜单说明/导航项不再当歌手）
        val out = LinkedHashSet<String>()
        fun addNames(raw: String?) {
            if (raw.isNullOrBlank()) return
            raw.split("&", "＆", "、", "，", ",").map { it.trim() }.filter { it.isNotEmpty() && !isJunkName(it) }.forEach { out.add(it) }
        }
        if ((track.remark.contains("合集") || track.remark.contains("专辑") || track.remark.contains("歌单")) && isPersonName(track.title) && !isChartLike(track.title) && !isNavTitle(track.title)) addNames(track.title)
        if (track.actor.isNotBlank()) addNames(track.actor)
        if (!isChartLike(track.title) && !isNavTitle(track.title) && track.remark.isNotBlank() && !track.remark.contains(">") && isPersonName(track.remark) && DESC_WORDS.none { track.remark.contains(it) }) addNames(track.remark)
        return out.toList()
    }

    fun artistOf(track: SubTrack): String? = artistsOf(track).firstOrNull() // [46v15] 兼容旧调用

    fun isPersonName(title: String): Boolean { // [46v18] 人名信号收紧：榜单/导航/说明/曲风类词（榜、畅听、会员、搜索、平台、播放、粤语、经典…）一律不是人名
        val n = title.trim()
        if (n.isEmpty() || n.length > 4) return false
        if (listOf("歌单", "合集", "专辑", "精选", "榜", "排行", "热门", "推荐", "畅听", "会员", "飙升", "新歌", "热歌", "金曲", "视频", "搜索", "平台", "播放", "当前", "每日", "粤语", "国语", "经典", "流行", "怀旧", "伤感", "治愈", "古风", "民谣", "摇滚", "纯音乐", "轻音乐", "钢琴", "电音", "舞曲", "老歌").any { n.contains(it) }) return false
        return !n.contains("&") && !n.contains("＆") && !n.contains("、") && !n.contains("，") && !n.contains(",") && !n.contains(" ") && !n.contains("-") && !n.contains("《") && !n.contains("》") && !n.contains("(") && !n.contains("（")
    }

"""
assert src.count(old_artists) == 1, "artists anchor %d" % src.count(old_artists)
src = src.replace(old_artists, "", 1)

old_coll = """    fun isCollection(track: SubTrack): Boolean { // [46v18] 歌单型：备注合集/专辑/歌单，标题是人名归歌手、榜单/导航类标题排除
        val remark = track.remark
        return (remark.contains("合集") || remark.contains("专辑") || remark.contains("歌单")) && !isPersonName(track.title) && !isChartLike(track.title) && !isNavTitle(track.title)
    }"""
assert src.count(old_coll) == 1, "isCollection anchor %d" % src.count(old_coll)
new_coll = """    fun countOf(remark: String): String? { // [46v19] 歌单首数徽标：备注里“355首”取出来，没有就不显示
        val idx = remark.indexOf("首")
        if (idx <= 0) return null
        var s = idx
        while (s > 0 && remark[s - 1].isDigit()) s--
        if (s == idx) return null
        return remark.substring(s, idx + 1)
    }

    fun isCollection(track: SubTrack): Boolean { // [46v19] 歌单型：有首数就是歌单（Peek 的歌单卡都有首数，含热歌榜这类榜单名）；或备注合集/专辑/歌单且标题非榜单类；导航项排除
        val remark = track.remark
        if (isNavTitle(track.title)) return false
        if (countOf(remark) != null) return true
        return (remark.contains("合集") || remark.contains("专辑") || remark.contains("歌单")) && !isChartLike(track.title)
    }"""
src = src.replace(old_coll, new_coll, 1)

assert "artistsOf" not in src and "isPersonName" not in src and "DESC_WORDS" not in src
open(path, "w", encoding="utf-8").write(src)
print("OK 46v19 bridge")
PYEOF46V19B
python3 - << 'PYEOF46V19S'
import sys

# 46 v19（屏幕侧）：曲库按 Peek 改成紧致简洁——两 pill tab（歌单/榜单，选中绿底＋手绘对勾）、圆角搜索框、
# 榜单改平铺榜单卡网格（一段一卡，点卡钻入、点播播本榜）、歌单与钻入网格共用 Peek 卡（方形封面＋左上徽标＋右下圆播＋单行标题，间距 8/12dp）、
# 歌手 tab 拿掉（Peek 没有；歌手推导代码随桥接侧一并删）
path = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicScreen.kt"
src = open(path, encoding="utf-8").read()
if "// [46v19]" in src:
    print("screen already 46v19, skip")
    sys.exit(0)

def rep(old, new, tag):
    global src
    assert src.count(old) == 1, "%s anchor %d" % (tag, src.count(old))
    src = src.replace(old, new, 1)

# 1) 删歌手状态 + 改 chartItems 注释
rep("    var showingArtistTracks by remember { mutableStateOf(false) } // [46v12] 歌手 tab 内：true=某歌手的歌曲网格\n", "", "artist-state")
rep(" // [46v12] 榜单 items，供歌手推导", " // [46v12] 榜单 items（进歌单池）", "chartitems-comment")

# 2) 删歌手推导块
old_artists = """    val artists = remember(home, chartItems) { // [46v15] 歌手推导：拆合作歌手、去杂项、合集图优先
        val classNames = home?.classes?.map { it.name } ?: emptyList()
        val sectionWords = listOf("歌手", "热门", "歌单", "榜单", "全部", "更多", "榜", "排行", "畅听", "会员", "飙升", "新歌", "搜索", "平台", "播放", "当前", "每日", "热歌", "金曲", "视频", "粤语", "国语", "经典", "流行", "怀旧", "伤感", "治愈", "古风", "民谣", "摇滚", "纯音乐", "轻音乐", "钢琴", "电音", "舞曲", "老歌") // [46v18] 拦词扩到单字榜及榜单/导航/说明类词
        fun okName(n: String) = !SubMusicBridge.isJunkName(n) && sectionWords.none { n.contains(it) } && !classNames.contains(n)
        val seen = LinkedHashMap<String, String>()
        val all = pool.filter { !SubMusicBridge.isChartLike(it.title) && !SubMusicBridge.isNavTitle(it.title) } // [46v18] 歌手原料先排掉榜单/导航类条目
        val ordered = all.filter { it.remark.contains("合集") || it.remark.contains("专辑") } + all.filter { !(it.remark.contains("合集") || it.remark.contains("专辑")) }
        for (t in ordered) {
            for (name in SubMusicBridge.artistsOf(t)) {
                if (!okName(name)) continue
                if (!seen.containsKey(name)) seen[name] = t.pic
            }
        }
        seen.map { (name, pic) -> name to pic }
    }

"""
rep(old_artists, "", "artists-block")

# 3) applyTab 改两 tab
old_apply = """    fun applyTab(src: SubMusicBridge.SubSource, t: Int, h: SubMusicBridge.SubHome?) {
        showingArtistTracks = false // [46v12] 切 Tab 回歌手列表
        chartDetail = null // [46v13] 回榜单分段视图
        if (t == 0) {
            gridItems = emptyList()
            gridNote = ""
            return
        }
        if (t == 1) { // [46v16] 歌单 tab：派生视图，不拉数据
            gridItems = emptyList()
            gridNote = ""
            return
        }
"""
new_apply = """    fun applyTab(src: SubMusicBridge.SubSource, t: Int, h: SubMusicBridge.SubHome?) { // [46v19] Peek 式两 tab：0=歌单，1=榜单（歌手 tab 拿掉）
        chartDetail = null // [46v13] 回榜单视图
        if (t == 0) { // [46v16] 歌单 tab：派生视图，不拉数据
            gridItems = emptyList()
            gridNote = ""
            return
        }
"""
rep(old_apply, new_apply, "applyTab")

# 4) 删 openArtist
old_open = """    fun openArtist(name: String) { // [46v12] 歌手点开：搜该歌手，进歌曲网格
        val src = selected ?: return
        gridLoading = true
        gridNote = ""
        scope.launch {
            try {
                val res = SubMusicBridge.searchInSource(src.key, name)
                gridItems = res
                showingArtistTracks = res.isNotEmpty()
                if (res.isEmpty()) gridNote = "该歌手暂无内容"
            } catch (e: Exception) {
                gridItems = emptyList()
                gridNote = "加载失败：${e.message}"
            } finally {
                gridLoading = false
            }
        }
    }

"""
rep(old_open, "", "openArtist")

# 5) 搜索框改圆角
old_search = """            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { onSearchClick() }
                    .padding(horizontal = 16.dp, vertical = 12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {"""
new_search = """            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 8.dp)
                    .clip(androidx.compose.foundation.shape.RoundedCornerShape(50))
                    .background(musicColors().card)
                    .clickable { onSearchClick() }
                    .padding(horizontal = 16.dp, vertical = 12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) { // [46v19] Peek 式圆角搜索框"""
rep(old_search, new_search, "search-row")

# 6) 文字 tab 改 pill tab
old_tabs = """            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                listOf("歌手", "歌单", "榜单").forEachIndexed { i, label -> // [46v16] 分桶三分
                    Column(
                        modifier = Modifier
                            .clickable {
                                if (tab != i) {
                                    tab = i
                                    val src = selected
                                    if (src != null) applyTab(src, i, home)
                                }
                            }
                            .padding(horizontal = 12.dp, vertical = 4.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text(
                            text = label,
                            style = MaterialTheme.typography.bodyLarge,
                            fontWeight = if (tab == i) FontWeight.Bold else FontWeight.Normal,
                            color = if (tab == i) musicColors().accent else musicColors().textSecondary
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        Box(
                            modifier = Modifier
                                .width(20.dp)
                                .height(2.dp)
                                .background(if (tab == i) musicColors().accent else Color.Transparent) // [46v14] 未选中下划线透明（壁纸上不留黑条）
                        )
                    }
                }
            }"""
new_tabs = """            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) { // [46v19] Peek 式 pill tab：选中绿底＋对勾，未选中卡片底
                listOf("歌单", "榜单").forEachIndexed { i, label ->
                    val sel = tab == i
                    Row(
                        modifier = Modifier
                            .padding(end = 12.dp)
                            .clip(androidx.compose.foundation.shape.RoundedCornerShape(50))
                            .background(if (sel) musicColors().accent else musicColors().card)
                            .clickable {
                                if (!sel) {
                                    tab = i
                                    val src = selected
                                    if (src != null) applyTab(src, i, home)
                                }
                            }
                            .padding(horizontal = 16.dp, vertical = 8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        val checkTint = musicColors().accentText
                        if (sel) {
                            Canvas(modifier = Modifier.size(14.dp)) {
                                val sw = 2.dp.toPx()
                                drawLine(color = checkTint, start = androidx.compose.ui.geometry.Offset(2.dp.toPx(), 7.dp.toPx()), end = androidx.compose.ui.geometry.Offset(6.dp.toPx(), 11.dp.toPx()), strokeWidth = sw, cap = androidx.compose.ui.graphics.StrokeCap.Round)
                                drawLine(color = checkTint, start = androidx.compose.ui.geometry.Offset(6.dp.toPx(), 11.dp.toPx()), end = androidx.compose.ui.geometry.Offset(12.dp.toPx(), 3.dp.toPx()), strokeWidth = sw, cap = androidx.compose.ui.graphics.StrokeCap.Round)
                            }
                            Spacer(modifier = Modifier.width(6.dp))
                        }
                        Text(
                            text = label,
                            style = MaterialTheme.typography.bodyLarge,
                            fontWeight = if (sel) FontWeight.Bold else FontWeight.Normal,
                            color = if (sel) musicColors().accentText else musicColors().textSecondary
                        )
                    }
                }
            }"""
rep(old_tabs, new_tabs, "tabs")

# 7) 榜单分段视图改平铺榜单卡网格
old_sections = """            if (tab == 2 && chartDetail == null) { // [46v13] 榜单分段视图
                if (gridNote.isNotBlank()) {
                    Text(
                        text = gridNote,
                        style = MaterialTheme.typography.bodyMedium,
                        color = musicColors().textSecondary,
                        modifier = Modifier.padding(16.dp)
                    )
                } else if (chartSections.isEmpty()) {
                    Text(
                        text = if (sectionsLoading) "正在加载榜单…" else "该源暂无分类内容",
                        style = MaterialTheme.typography.bodyMedium,
                        color = musicColors().textSecondary,
                        modifier = Modifier.padding(16.dp)
                    )
                } else {
                    LazyColumn(
                        modifier = Modifier.fillMaxSize(),
                        contentPadding = PaddingValues(vertical = 8.dp)
                    ) {
                        items(chartSections, key = { it.first }) { sec ->
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(horizontal = 16.dp, vertical = 8.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(
                                    text = sec.second,
                                    style = MaterialTheme.typography.titleMedium,
                                    fontWeight = FontWeight.Bold,
                                    color = musicColors().textPrimary
                                )
                                Spacer(modifier = Modifier.weight(1f))
                                Text(
                                    text = "全部 >",
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = musicColors().accent,
                                    modifier = Modifier.clickable {
                                        chartDetail = sec
                                        gridItems = sec.third
                                    }
                                )
                            }
                            LazyRow(
                                contentPadding = PaddingValues(horizontal = 16.dp),
                                horizontalArrangement = Arrangement.spacedBy(12.dp)
                            ) {
                                itemsIndexed(sec.third, key = { _, it -> it.sourceKey + ":" + it.id }) { idx, track ->
                                    SubSectionCard(track = track, rank = idx + 1, onPlay = { playTrack(track, sec.third) })
                                }
                            }
                            Spacer(modifier = Modifier.height(16.dp))
                        }
                        if (sectionsLoading) {
                            item {
                                Text(
                                    text = "正在加载更多分类…",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = musicColors().textSecondary,
                                    modifier = Modifier.padding(16.dp)
                                )
                            }
                        }
                    }
                }
            } else if (gridLoading) {"""
new_sections = """            if (tab == 1 && chartDetail == null) { // [46v19] Peek 式榜单：平铺榜单卡网格（一段一卡，点卡钻入、点播播本榜）
                if (gridNote.isNotBlank()) {
                    Text(
                        text = gridNote,
                        style = MaterialTheme.typography.bodyMedium,
                        color = musicColors().textSecondary,
                        modifier = Modifier.padding(16.dp)
                    )
                } else if (chartSections.isEmpty()) {
                    Text(
                        text = if (sectionsLoading) "正在加载榜单…" else "该源暂无分类内容",
                        style = MaterialTheme.typography.bodyMedium,
                        color = musicColors().textSecondary,
                        modifier = Modifier.padding(16.dp)
                    )
                } else {
                    if (sectionsLoading) {
                        Text(
                            text = "正在加载更多分类…",
                            style = MaterialTheme.typography.bodySmall,
                            color = musicColors().textSecondary,
                            modifier = Modifier.padding(horizontal = 16.dp, vertical = 4.dp)
                        )
                    }
                    LazyVerticalGrid(
                        columns = GridCells.Fixed(3),
                        modifier = Modifier.fillMaxSize(),
                        contentPadding = PaddingValues(16.dp),
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        items(chartSections, key = { it.first }) { sec ->
                            val first = sec.third.firstOrNull()
                            SubPeekCard(
                                pic = first?.pic ?: "",
                                title = sec.second,
                                badge = "榜单",
                                onOpen = { chartDetail = sec; gridItems = sec.third },
                                onPlay = { if (sec.third.isNotEmpty()) playTrack(sec.third.first(), sec.third) }
                            )
                        }
                    }
                }
            } else if (gridLoading) {"""
rep(old_sections, new_sections, "chart-sections")

# 8) 删歌手网格分支，歌单分支改 tab 0
old_singer = """            } else if (tab == 0 && !showingArtistTracks) { // [46v12] 歌手 tab：推导出的歌手网格
                if (artists.isEmpty()) {
                    Text(
                        text = "该源未提供歌手信息",
                        style = MaterialTheme.typography.bodyMedium,
                        color = musicColors().textSecondary,
                        modifier = Modifier.padding(16.dp)
                    )
                } else {
                    LazyVerticalGrid(
                        columns = GridCells.Fixed(3),
                        modifier = Modifier.fillMaxSize(),
                        contentPadding = PaddingValues(16.dp),
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                        verticalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        items(artists, key = { it.first }) { a ->
                            SubArtistCard(name = a.first, pic = a.second, onClick = { openArtist(a.first) })
                        }
                    }
                }
            } else if (tab == 1) { // [46v16] 歌单 tab：合集型条目网格"""
new_singer = """            } else if (tab == 0) { // [46v19] 歌单 tab：Peek 式紧致网格"""
rep(old_singer, new_singer, "singer-grid")

# 9) 歌单网格改 Peek 卡 + 紧致间距
old_playlist_grid = """                    LazyVerticalGrid(
                        columns = GridCells.Fixed(3),
                        modifier = Modifier.fillMaxSize(),
                        contentPadding = PaddingValues(16.dp),
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                        verticalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        items(playlists, key = { it.sourceKey + ":" + it.id }) { track ->
                            SubGridCard(track = track, onPlay = { playTrack(track, playlists) })
                        }
                    }"""
new_playlist_grid = """                    LazyVerticalGrid(
                        columns = GridCells.Fixed(3),
                        modifier = Modifier.fillMaxSize(),
                        contentPadding = PaddingValues(16.dp),
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        items(playlists, key = { it.sourceKey + ":" + it.id }) { track ->
                            SubPeekCard(pic = track.pic, title = track.title, badge = SubMusicBridge.countOf(track.remark), onOpen = { playTrack(track, playlists) }, onPlay = { playTrack(track, playlists) })
                        }
                    }"""
rep(old_playlist_grid, new_playlist_grid, "playlist-grid")

# 10) 钻入分支：删返回歌手行，榜单 tab 号 2→1，网格改 Peek 卡
old_drill = """            } else {
                if (tab == 0 && showingArtistTracks) {
                    Text(
                        text = "← 返回歌手",
                        style = MaterialTheme.typography.bodyMedium,
                        color = musicColors().accent,
                        modifier = Modifier
                            .clickable { showingArtistTracks = false }
                            .padding(horizontal = 16.dp, vertical = 8.dp)
                    )
                }
                if (tab == 2 && chartDetail != null) { // [46v13] 从分类整页回分段视图
                    Text(
                        text = "← 返回榜单",
                        style = MaterialTheme.typography.bodyMedium,
                        color = musicColors().accent,
                        modifier = Modifier
                            .clickable { chartDetail = null }
                            .padding(horizontal = 16.dp, vertical = 8.dp)
                    )
                }
                LazyVerticalGrid(
                    columns = GridCells.Fixed(3),
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(16.dp),
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    itemsIndexed(gridItems, key = { _, it -> it.sourceKey + ":" + it.id }) { idx, track ->
                        SubGridCard(track = track, rank = if (tab == 2) idx + 1 else null, onPlay = { playTrack(track, gridItems) })
                    }
                }
            }"""
new_drill = """            } else { // [46v19] 榜单钻入：榜内歌曲网格（Peek 式卡片，无名次）
                if (tab == 1 && chartDetail != null) {
                    Text(
                        text = "← 返回榜单",
                        style = MaterialTheme.typography.bodyMedium,
                        color = musicColors().accent,
                        modifier = Modifier
                            .clickable { chartDetail = null }
                            .padding(horizontal = 16.dp, vertical = 8.dp)
                    )
                }
                LazyVerticalGrid(
                    columns = GridCells.Fixed(3),
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(16.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    items(gridItems, key = { it.sourceKey + ":" + it.id }) { track ->
                        SubPeekCard(pic = track.pic, title = track.title, badge = SubMusicBridge.countOf(track.remark), onOpen = { playTrack(track, gridItems) }, onPlay = { playTrack(track, gridItems) })
                    }
                }
            }"""
rep(old_drill, new_drill, "drill")

# 11) SubGridCard 改 SubPeekCard
old_gridcard = """@Composable
private fun SubGridCard(track: SubMusicBridge.SubTrack, rank: Int? = null, onPlay: () -> Unit) { // [46v12] rank 非空=榜单名次
    val accent = musicColors().accent
    val accentText = musicColors().accentText
    val cardBg = musicColors().card
    Column(modifier = Modifier.clickable { onPlay() }) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .aspectRatio(1f)
                .clip(MaterialTheme.shapes.medium)
                .background(cardBg.copy(alpha = 0.45f)) // [46v14] 磨砂卡片（同设置页）
                .border(0.5.dp, Color.White.copy(alpha = 0.15f), MaterialTheme.shapes.medium)
        ) {
            if (track.pic.isNotBlank()) {
                AsyncImage(
                    model = track.pic,
                    contentDescription = null,
                    contentScale = ContentScale.Crop,
                    modifier = Modifier.fillMaxSize()
                )
            } else {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = track.title.take(1),
                        color = musicColors().textSecondary
                    )
                }
            }
            if (track.remark.isNotBlank()) {
                Text(
                    text = track.remark,
                    style = MaterialTheme.typography.bodySmall,
                    color = musicColors().textPrimary,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier
                        .align(Alignment.TopStart)
                        .padding(6.dp)
                        .clip(MaterialTheme.shapes.small)
                        .background(cardBg.copy(alpha = 0.8f))
                        .padding(horizontal = 6.dp, vertical = 2.dp)
                )
            }
            if (rank != null) {
                Text(
                    text = rank.toString(),
                    style = MaterialTheme.typography.bodySmall,
                    color = musicColors().textPrimary,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier
                        .align(Alignment.TopEnd) // [46v13] 名次统一右上角
                        .padding(6.dp)
                        .clip(MaterialTheme.shapes.small)
                        .background(cardBg.copy(alpha = 0.8f))
                        .padding(horizontal = 6.dp, vertical = 2.dp)
                )
            }
            Box(
                modifier = Modifier
                    .align(Alignment.BottomEnd)
                    .padding(8.dp)
                    .size(32.dp)
                    .clip(androidx.compose.foundation.shape.CircleShape)
                    .background(accent)
                    .clickable { onPlay() },
                contentAlignment = Alignment.Center
            ) {
                Canvas(modifier = Modifier.size(14.dp)) {
                    val p = androidx.compose.ui.graphics.Path().apply {
                        moveTo(4.dp.toPx(), 2.dp.toPx())
                        lineTo(4.dp.toPx(), 12.dp.toPx())
                        lineTo(12.dp.toPx(), 7.dp.toPx())
                        close()
                    }
                    drawPath(path = p, color = accentText)
                }
            }
        }
        Spacer(modifier = Modifier.height(6.dp))
        Text(
            text = track.title,
            style = MaterialTheme.typography.bodyMedium,
            color = musicColors().textPrimary,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis
        )
    }
}"""
new_peekcard = """@Composable
private fun SubPeekCard(pic: String, title: String, badge: String?, onOpen: () -> Unit, onPlay: () -> Unit) { // [46v19] Peek 式卡片：方形封面＋左上徽标＋右下圆播＋单行标题（点卡打开、点播播放）
    val accent = musicColors().accent
    val accentText = musicColors().accentText
    val cardBg = musicColors().card
    Column(modifier = Modifier.clickable { onOpen() }) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .aspectRatio(1f)
                .clip(MaterialTheme.shapes.medium)
                .background(cardBg.copy(alpha = 0.45f)) // [46v14] 磨砂卡片（同设置页）
                .border(0.5.dp, Color.White.copy(alpha = 0.15f), MaterialTheme.shapes.medium)
        ) {
            if (pic.isNotBlank()) {
                AsyncImage(
                    model = pic,
                    contentDescription = null,
                    contentScale = ContentScale.Crop,
                    modifier = Modifier.fillMaxSize()
                )
            } else {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = title.take(1),
                        color = musicColors().textSecondary
                    )
                }
            }
            if (badge != null) {
                Text(
                    text = badge,
                    style = MaterialTheme.typography.bodySmall,
                    color = musicColors().textPrimary,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier
                        .align(Alignment.TopStart)
                        .padding(6.dp)
                        .clip(MaterialTheme.shapes.small)
                        .background(cardBg.copy(alpha = 0.8f))
                        .padding(horizontal = 6.dp, vertical = 2.dp)
                )
            }
            Box(
                modifier = Modifier
                    .align(Alignment.BottomEnd)
                    .padding(8.dp)
                    .size(32.dp)
                    .clip(androidx.compose.foundation.shape.CircleShape)
                    .background(accent)
                    .clickable { onPlay() },
                contentAlignment = Alignment.Center
            ) {
                Canvas(modifier = Modifier.size(14.dp)) {
                    val p = androidx.compose.ui.graphics.Path().apply {
                        moveTo(4.dp.toPx(), 2.dp.toPx())
                        lineTo(4.dp.toPx(), 12.dp.toPx())
                        lineTo(12.dp.toPx(), 7.dp.toPx())
                        close()
                    }
                    drawPath(path = p, color = accentText)
                }
            }
        }
        Spacer(modifier = Modifier.height(6.dp))
        Text(
            text = title,
            style = MaterialTheme.typography.bodyMedium,
            color = musicColors().textPrimary,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis
        )
    }
}"""
rep(old_gridcard, new_peekcard, "gridcard")

# 12) 删 SubArtistCard
old_artistcard = """@Composable
private fun SubArtistCard(name: String, pic: String, onClick: () -> Unit) { // [46v12] 歌手卡：封面＋名，点开搜该歌手
    val cardBg = musicColors().card
    Column(modifier = Modifier.clickable { onClick() }) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .aspectRatio(1f)
                .clip(MaterialTheme.shapes.medium)
                .background(cardBg.copy(alpha = 0.45f)) // [46v14] 磨砂卡片（同设置页）
                .border(0.5.dp, Color.White.copy(alpha = 0.15f), MaterialTheme.shapes.medium),
            contentAlignment = Alignment.Center
        ) {
            if (pic.isNotBlank()) {
                AsyncImage(
                    model = pic,
                    contentDescription = null,
                    contentScale = ContentScale.Crop,
                    modifier = Modifier.fillMaxSize()
                )
            } else {
                Text(
                    text = name.take(1),
                    color = musicColors().textSecondary
                )
            }
        }
        Spacer(modifier = Modifier.height(6.dp))
        Text(
            text = name,
            style = MaterialTheme.typography.bodyMedium,
            color = musicColors().textPrimary,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis
        )
    }
}

"""
rep(old_artistcard, "", "artistcard")

# 13) 删 SubSectionCard
old_sectioncard = """@Composable
private fun SubSectionCard(track: SubMusicBridge.SubTrack, rank: Int, onPlay: () -> Unit) { // [46v13] 榜单段内横滑卡：竖版＋右上角名次，点卡播本段队列
    val cardBg = musicColors().card
    Column(modifier = Modifier.width(120.dp).clickable { onPlay() }) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .aspectRatio(3f / 4f)
                .clip(MaterialTheme.shapes.medium)
                .background(cardBg.copy(alpha = 0.45f)) // [46v14] 磨砂卡片（同设置页）
                .border(0.5.dp, Color.White.copy(alpha = 0.15f), MaterialTheme.shapes.medium),
            contentAlignment = Alignment.Center
        ) {
            if (track.pic.isNotBlank()) {
                AsyncImage(
                    model = track.pic,
                    contentDescription = null,
                    contentScale = ContentScale.Crop,
                    modifier = Modifier.fillMaxSize()
                )
            } else {
                Text(
                    text = track.title.take(1),
                    color = musicColors().textSecondary
                )
            }
            Text(
                text = rank.toString(),
                style = MaterialTheme.typography.bodySmall,
                color = musicColors().textPrimary,
                fontWeight = FontWeight.Bold,
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .padding(6.dp)
                    .clip(MaterialTheme.shapes.small)
                    .background(cardBg.copy(alpha = 0.8f))
                    .padding(horizontal = 6.dp, vertical = 2.dp)
            )
        }
        Spacer(modifier = Modifier.height(6.dp))
        Text(
            text = track.title,
            style = MaterialTheme.typography.bodyMedium,
            color = musicColors().textPrimary,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis
        )
    }
}
"""
rep(old_sectioncard, "", "sectioncard")

assert "SubGridCard" not in src and "SubArtistCard" not in src and "SubSectionCard" not in src
assert "showingArtistTracks" not in src and "openArtist" not in src and "artistsOf" not in src
assert "tab == 2" not in src
open(path, "w", encoding="utf-8").write(src)
print("OK 46v19 screen")
PYEOF46V19S
python3 - << 'PYEOF46V19M'
import sys

# 46 v19（MH 顶栏，订阅模式）：Peek 式——标题改音符＋“音乐”，源选择改 pill（卡片底＋源名＋下箭头）
path = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"
src = open(path, encoding="utf-8").read()
if "// [46v19]" in src:
    print("MH already 46v19, skip")
    sys.exit(0)
assert "Alignment.CenterVertically" in src, "MH lacks Alignment.CenterVertically usage"

old_title = """                title = {
                    Text(
                        "音乐专区",
                        color = musicColors().textPrimary,
                        fontWeight = FontWeight.Bold
                    )
                },"""
assert src.count(old_title) == 1, "MH title anchor %d" % src.count(old_title)
new_title = """                title = {
                    if (contentMode == "sub") { // [46v19] Peek 式：音符＋音乐
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            val noteTint = musicColors().accent
                            Canvas(modifier = Modifier.size(22.dp)) {
                                val sw = 2.dp.toPx()
                                drawOval(color = noteTint, topLeft = androidx.compose.ui.geometry.Offset(4.dp.toPx(), 15.dp.toPx()), size = androidx.compose.ui.geometry.Size(8.dp.toPx(), 6.dp.toPx()))
                                drawLine(color = noteTint, start = androidx.compose.ui.geometry.Offset(11.dp.toPx(), 15.5.dp.toPx()), end = androidx.compose.ui.geometry.Offset(11.dp.toPx(), 4.dp.toPx()), strokeWidth = sw, cap = androidx.compose.ui.graphics.StrokeCap.Round)
                            }
                            Spacer(modifier = Modifier.width(6.dp))
                            Text(
                                "音乐",
                                color = musicColors().textPrimary,
                                fontWeight = FontWeight.Bold
                            )
                        }
                    } else {
                        Text(
                            "音乐专区",
                            color = musicColors().textPrimary,
                            fontWeight = FontWeight.Bold
                        )
                    }
                },"""
src = src.replace(old_title, new_title, 1)

old_src = """                    if (contentMode == "sub") {
                        // [46v9] 顶栏源内源：点开按订阅顺序排的 Sheet，选中驱动曲库/搜索
                        TextButton(onClick = { showSourceSheet = true }) {
                            Text(
                                subSources.firstOrNull { it.key == selectedSubKey }?.displayName ?: "选择源",
                                color = musicColors().textPrimary,
                                fontWeight = FontWeight.Bold
                            )
                        }
                    } else {"""
assert src.count(old_src) == 1, "MH source anchor %d" % src.count(old_src)
new_src = """                    if (contentMode == "sub") {
                        // [46v19] Peek 式源 pill：点开按订阅顺序排的 Sheet，选中驱动曲库/搜索
                        Box(
                            modifier = Modifier
                                .clip(RoundedCornerShape(50))
                                .background(musicColors().card)
                                .clickable { showSourceSheet = true }
                                .padding(horizontal = 12.dp, vertical = 8.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Text(
                                    subSources.firstOrNull { it.key == selectedSubKey }?.displayName ?: "选择源",
                                    color = musicColors().textPrimary,
                                    fontWeight = FontWeight.Bold
                                )
                                Spacer(modifier = Modifier.width(4.dp))
                                val chevTint = musicColors().textSecondary
                                Canvas(modifier = Modifier.size(12.dp)) {
                                    val sw = 1.8.dp.toPx()
                                    drawLine(color = chevTint, start = androidx.compose.ui.geometry.Offset(2.dp.toPx(), 4.dp.toPx()), end = androidx.compose.ui.geometry.Offset(6.dp.toPx(), 8.dp.toPx()), strokeWidth = sw, cap = androidx.compose.ui.graphics.StrokeCap.Round)
                                    drawLine(color = chevTint, start = androidx.compose.ui.geometry.Offset(6.dp.toPx(), 8.dp.toPx()), end = androidx.compose.ui.geometry.Offset(10.dp.toPx(), 4.dp.toPx()), strokeWidth = sw, cap = androidx.compose.ui.graphics.StrokeCap.Round)
                                }
                            }
                        }
                    } else {"""
src = src.replace(old_src, new_src, 1)

open(path, "w", encoding="utf-8").write(src)
print("OK 46v19 MH")
PYEOF46V19M
grep -q "46v19" avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicBridge.kt || { echo "X 46v19 bridge"; exit 1; }
grep -q "46v19" avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicScreen.kt || { echo "X 46v19 screen"; exit 1; }
grep -q "46v19" avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt || { echo "X 46v19 MH"; exit 1; }
echo "OK 46v19"
echo "=== 46 v19 done ==="

# === 46 v21: 订阅搜索页并进曲库（用户确认：结果卡片网格） ===
echo "=== 46 v21 ==="
cat > /tmp/patch_screen46v21.py << 'PYEOF46V21'
import sys

# 46 v21（屏幕侧）：订阅搜索页并进曲库——曲库顶搜索框由假框改真输入框（BasicTextField，圆角外观同 v19，键盘搜索触发），
# 出结果时结果卡片网格替代表格区（点卡播本页队列，复用 SubPeekCard/playTrack），pill tab 搜时隐藏，×/返回浏览回浏览；
# 换源时清空搜索；onSearchClick 参数删除（MH 侧同步删调用）
path = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicScreen.kt"
src = open(path, encoding="utf-8").read()
if "// [46v21]" in src:
    print("screen already 46v21, skip")
    sys.exit(0)

def rep(old, new, tag):
    global src
    assert src.count(old) == 1, "%s anchor %d" % (tag, src.count(old))
    src = src.replace(old, new, 1)

# 0) 新 import（BasicTextField/KeyboardOptions/KeyboardActions/ImeAction/SolidColor 均在 PlayerSheets.kt 有同款用法）
rep(
    "import androidx.compose.foundation.clickable",
    "import androidx.compose.foundation.clickable\n"
    "import androidx.compose.foundation.text.BasicTextField\n"
    "import androidx.compose.foundation.text.KeyboardActions\n"
    "import androidx.compose.foundation.text.KeyboardOptions",
    "imports-text",
)
rep(
    "import androidx.compose.ui.graphics.Color",
    "import androidx.compose.ui.graphics.Color\n"
    "import androidx.compose.ui.graphics.SolidColor",
    "imports-solid",
)
rep(
    "import androidx.compose.ui.text.font.FontWeight",
    "import androidx.compose.ui.text.font.FontWeight\n"
    "import androidx.compose.ui.text.input.ImeAction",
    "imports-ime",
)

# 1) 签名删 onSearchClick
rep(
    """fun SubMusicScreen(
    sources: List<SubMusicBridge.SubSource>,
    selectedKey: String?,
    diag: SubMusicBridge.SourceDiag?,
    onSearchClick: () -> Unit
) {""",
    """fun SubMusicScreen(
    sources: List<SubMusicBridge.SubSource>,
    selectedKey: String?,
    diag: SubMusicBridge.SourceDiag?
) { // [46v21] 搜索已并进本页，onSearchClick 参数删除""",
    "signature",
)

# 2) 搜索状态（放在 notice 之后）
rep(
    '    var notice by remember { mutableStateOf("") }',
    '    var notice by remember { mutableStateOf("") }\n'
    '    var keyword by remember { mutableStateOf("") } // [46v21] 曲库内搜\n'
    '    var searching by remember { mutableStateOf(false) } // [46v21] 曲库内搜\n'
    '    var searched by remember { mutableStateOf(false) } // [46v21] 曲库内搜\n'
    '    var searchResults by remember { mutableStateOf<List<SubMusicBridge.SubTrack>>(emptyList()) } // [46v21] 曲库内搜',
    "search-states",
)

# 3) doSearch/clearSearch（放在 scope 之后、pool 之前；loadBrowse 在后调用 clearSearch，故须先声明）
rep(
    "    val scope = rememberCoroutineScope()",
    """    val scope = rememberCoroutineScope()

    fun clearSearch() { // [46v21] 曲库内搜：回浏览
        keyword = ""
        searchResults = emptyList()
        searched = false
        searching = false
    }

    fun doSearch() { // [46v21] 曲库内搜：搜当前源（同 SubSearchScreen 的 searchInSource 链）
        val kw = keyword.trim()
        val src = selected
        if (kw.isEmpty() || searching || src == null) return
        searching = true
        searched = false
        notice = ""
        scope.launch {
            try {
                searchResults = SubMusicBridge.searchInSource(src.key, kw)
                searched = true
            } catch (e: Exception) {
                notice = "搜索失败：" + e.message
            } finally {
                searching = false
            }
        }
    }""",
    "search-funs",
)

# 4) loadBrowse：换源清空搜索
rep(
    """    fun loadBrowse(src: SubMusicBridge.SubSource) {
        gridLoading = true
        gridNote = """"",
    """    fun loadBrowse(src: SubMusicBridge.SubSource) {
        clearSearch() // [46v21] 换源回浏览
        gridLoading = true
        gridNote = """"",
    "loadbrowse-clear",
)

# 5) 假搜索框改真输入框（放大镜 Canvas 原样保留；光标色用 accent，颜色在 Canvas 外提升）
rep(
    """            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 8.dp)
                    .clip(androidx.compose.foundation.shape.RoundedCornerShape(50))
                    .background(musicColors().card)
                    .clickable { onSearchClick() }
                    .padding(horizontal = 16.dp, vertical = 12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) { // [46v19] Peek 式圆角搜索框
                val searchTint = musicColors().textSecondary
                Canvas(modifier = Modifier.size(20.dp)) {
                    val sw = 2.dp.toPx()
                    drawCircle(
                        color = searchTint,
                        radius = 6.dp.toPx(),
                        center = androidx.compose.ui.geometry.Offset(8.dp.toPx(), 8.dp.toPx()),
                        style = androidx.compose.ui.graphics.drawscope.Stroke(width = sw)
                    )
                    drawLine(
                        color = searchTint,
                        start = androidx.compose.ui.geometry.Offset(12.5.dp.toPx(), 12.5.dp.toPx()),
                        end = androidx.compose.ui.geometry.Offset(17.dp.toPx(), 17.dp.toPx()),
                        strokeWidth = sw,
                        cap = androidx.compose.ui.graphics.StrokeCap.Round
                    )
                }
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = "搜索歌曲、歌手…",
                    style = MaterialTheme.typography.bodyLarge,
                    color = musicColors().textSecondary
                )
            }""",
    """            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 8.dp)
                    .clip(androidx.compose.foundation.shape.RoundedCornerShape(50))
                    .background(musicColors().card)
                    .padding(horizontal = 16.dp, vertical = 12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) { // [46v21] 曲库内搜：真输入框（圆角外观同 v19）
                val searchTint = musicColors().textSecondary
                Canvas(modifier = Modifier.size(20.dp)) {
                    val sw = 2.dp.toPx()
                    drawCircle(
                        color = searchTint,
                        radius = 6.dp.toPx(),
                        center = androidx.compose.ui.geometry.Offset(8.dp.toPx(), 8.dp.toPx()),
                        style = androidx.compose.ui.graphics.drawscope.Stroke(width = sw)
                    )
                    drawLine(
                        color = searchTint,
                        start = androidx.compose.ui.geometry.Offset(12.5.dp.toPx(), 12.5.dp.toPx()),
                        end = androidx.compose.ui.geometry.Offset(17.dp.toPx(), 17.dp.toPx()),
                        strokeWidth = sw,
                        cap = androidx.compose.ui.graphics.StrokeCap.Round
                    )
                }
                Spacer(modifier = Modifier.width(8.dp))
                BasicTextField(
                    value = keyword,
                    onValueChange = { keyword = it },
                    singleLine = true,
                    textStyle = MaterialTheme.typography.bodyLarge.copy(color = musicColors().textPrimary),
                    keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
                    keyboardActions = KeyboardActions(onSearch = { doSearch() }),
                    cursorBrush = SolidColor(musicColors().accent),
                    decorationBox = { inner ->
                        if (keyword.isEmpty()) {
                            Text(
                                text = "搜索歌曲、歌手…",
                                style = MaterialTheme.typography.bodyLarge,
                                color = musicColors().textSecondary
                            )
                        }
                        inner()
                    },
                    modifier = Modifier.weight(1f)
                )
                if (keyword.isNotEmpty()) {
                    val clearTint = musicColors().textSecondary
                    Box(
                        modifier = Modifier
                            .size(20.dp)
                            .clickable { clearSearch() },
                        contentAlignment = Alignment.Center
                    ) {
                        Canvas(modifier = Modifier.size(12.dp)) {
                            val sw = 2.dp.toPx()
                            drawLine(color = clearTint, start = androidx.compose.ui.geometry.Offset(2.dp.toPx(), 2.dp.toPx()), end = androidx.compose.ui.geometry.Offset(10.dp.toPx(), 10.dp.toPx()), strokeWidth = sw, cap = androidx.compose.ui.graphics.StrokeCap.Round)
                            drawLine(color = clearTint, start = androidx.compose.ui.geometry.Offset(10.dp.toPx(), 2.dp.toPx()), end = androidx.compose.ui.geometry.Offset(2.dp.toPx(), 10.dp.toPx()), strokeWidth = sw, cap = androidx.compose.ui.graphics.StrokeCap.Round)
                        }
                    }
                }
            }""",
    "search-box",
)

# 6) pill tab：搜结果时隐藏（返回浏览再现）
rep(
    """            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) { // [46v19] Peek 式 pill tab：选中绿底＋对勾，未选中卡片底""",
    """            if (!searched && !searching) { // [46v21] 搜结果时藏 pill tab
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) { // [46v19] Peek 式 pill tab：选中绿底＋对勾，未选中卡片底""",
    "pills-hide-open",
)
rep(
    """                    }
                }
            }
            if (notice.isNotBlank()) {""",
    """                    }
                }
            }
            } // [46v21] 搜结果时藏 pill tab
            if (notice.isNotBlank()) {""",
    "pills-hide-close",
)

# 7) 内容链首分支：搜结果卡片网格（在榜单/歌单/钻入之前）
rep(
    '            if (tab == 1 && chartDetail == null) { // [46v19] Peek 式榜单：平铺榜单卡网格（一段一卡，点卡钻入、点播播本榜）',
    """            if (searched || searching) { // [46v21] 曲库内搜：结果卡片网格（点卡播本页队列）
                if (searching) {
                    Text(
                        text = "正在搜索…",
                        style = MaterialTheme.typography.bodyMedium,
                        color = musicColors().textSecondary,
                        modifier = Modifier.padding(16.dp)
                    )
                } else if (searchResults.isEmpty()) {
                    Text(
                        text = "没有搜到结果",
                        style = MaterialTheme.typography.bodyMedium,
                        color = musicColors().textSecondary,
                        modifier = Modifier.padding(16.dp)
                    )
                } else {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 16.dp, vertical = 4.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = "搜「" + keyword.trim() + "」· " + searchResults.size + " 条",
                            style = MaterialTheme.typography.bodySmall,
                            color = musicColors().textSecondary,
                            modifier = Modifier.weight(1f)
                        )
                        Text(
                            text = "返回浏览",
                            style = MaterialTheme.typography.bodySmall,
                            color = musicColors().accent,
                            modifier = Modifier.clickable { clearSearch() }
                        )
                    }
                    LazyVerticalGrid(
                        columns = GridCells.Fixed(3),
                        modifier = Modifier.fillMaxSize(),
                        contentPadding = PaddingValues(16.dp),
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        items(searchResults, key = { it.sourceKey + ":" + it.id }) { track ->
                            SubPeekCard(pic = track.pic, title = track.title, badge = track.remark.takeIf { it.isNotBlank() }, onOpen = { playTrack(track, searchResults) }, onPlay = { playTrack(track, searchResults) })
                        }
                    }
                }
            } else if (tab == 1 && chartDetail == null) { // [46v19] Peek 式榜单：平铺榜单卡网格（一段一卡，点卡钻入、点播播本榜）""",
    "search-results-branch",
)

assert src.count("[46v21]") >= 10
assert "onSearchClick: () -> Unit" not in src  # 注释里提一句参数名不算残留，只查签名与调用
assert ".clickable { onSearchClick() }" not in src
open(path, "w", encoding="utf-8").write(src)
print("OK 46v21 screen")
PYEOF46V21
cat > /tmp/patch_mh46v21.py << 'PYEOF46V21'
import sys

# 46 v21（MH 侧）：订阅模式拿掉“搜索”底栏 tab——
# ① setContentMode 切到 sub 时 SEARCH 回落到 QUKU；② effectiveTab 的 sub 集去掉 SEARCH；③ QUKU 分支删 onSearchClick 传参；
# ④ SEARCH 分支删 sub 臂（SubSearchScreen 调用），只剩脚本模式的 SearchTabLanding；⑤ sub 的 tabDefs97 删 SEARCH 一项。
# 脚本模式的搜索 tab 与 SEARCH 枚举值不动。
path = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"
src = open(path, encoding="utf-8").read()
if "// [46v21]" in src:
    print("MH already 46v21, skip")
    sys.exit(0)

def rep(old, new, tag):
    global src
    assert src.count(old) == 1, "%s anchor %d" % (tag, src.count(old))
    src = src.replace(old, new, 1)

# 1) 切模式回落：sub 集去掉 SEARCH
rep(
    "            if (selectedTab != MusicTab.QUKU && selectedTab != MusicTab.SEARCH && selectedTab != MusicTab.MINE && selectedTab != MusicTab.SETTINGS && selectedTab != MusicTab.HOME) selectedTab = MusicTab.QUKU",
    "            if (selectedTab != MusicTab.QUKU && selectedTab != MusicTab.MINE && selectedTab != MusicTab.SETTINGS && selectedTab != MusicTab.HOME) selectedTab = MusicTab.QUKU // [46v21] 订阅模式无搜索 tab",
    "mode-fallback",
)

# 2) effectiveTab 的 sub 集去掉 SEARCH
rep(
    "                if (selectedTab == MusicTab.QUKU || selectedTab == MusicTab.SEARCH || selectedTab == MusicTab.MINE || selectedTab == MusicTab.SETTINGS || selectedTab == MusicTab.HOME) selectedTab else MusicTab.QUKU",
    "                if (selectedTab == MusicTab.QUKU || selectedTab == MusicTab.MINE || selectedTab == MusicTab.SETTINGS || selectedTab == MusicTab.HOME) selectedTab else MusicTab.QUKU // [46v21] 订阅模式无搜索 tab",
    "effective-tab",
)

# 3) QUKU 分支删 onSearchClick 传参
rep(
    """                    SubMusicScreen(
                        sources = subSources,
                        selectedKey = subSources.firstOrNull { it.key == selectedSubKey }?.key,
                        diag = sourceDiag,
                        onSearchClick = { selectedTab = MusicTab.SEARCH }
                    ) // [46v9]""",
    """                    SubMusicScreen(
                        sources = subSources,
                        selectedKey = subSources.firstOrNull { it.key == selectedSubKey }?.key,
                        diag = sourceDiag
                    ) // [46v9] // [46v21] 搜索已并进曲库页""",
    "quku-callsite",
)

# 4) SEARCH 分支删 sub 臂，只剩脚本模式
rep(
    """                MusicTab.SEARCH -> {
                    if (contentMode == "sub") {
                        SubSearchScreen(
                            sources = subSources,
                            selectedKey = subSources.firstOrNull { it.key == selectedSubKey }?.key,
                            diag = sourceDiag
                        ) // [46v9]
                    } else {
                        // 搜索：新版 SearchScreen（数据：SearchTabLanding 的热词/关键词逻辑）
                        SearchTabLanding(
                            platform = selectedPlatform,
                            onSearch = { kw ->
                                context.startActivity(
                                    Intent(context, LxMusicSearchActivity::class.java).apply {
                                        putExtra("platform", selectedPlatform)
                                        putExtra("keyword", kw)
                                    }
                                )
                            },
                            onBrowseChart = { chartId ->
                                pendingChartId = chartId
                                selectedTab = MusicTab.RANKING
                            }
                        )
                    }
                }""",
    """                MusicTab.SEARCH -> { // [46v21] 搜索 tab 只剩脚本模式（订阅模式的搜索已并进曲库页，SubSearchScreen 已删）
                    // 搜索：新版 SearchScreen（数据：SearchTabLanding 的热词/关键词逻辑）
                    SearchTabLanding(
                        platform = selectedPlatform,
                        onSearch = { kw ->
                            context.startActivity(
                                Intent(context, LxMusicSearchActivity::class.java).apply {
                                    putExtra("platform", selectedPlatform)
                                    putExtra("keyword", kw)
                                }
                            )
                        },
                        onBrowseChart = { chartId ->
                            pendingChartId = chartId
                            selectedTab = MusicTab.RANKING
                        }
                    )
                }""",
    "search-branch",
)

# 5) sub 的 tabDefs97 删 SEARCH 一项（QUKU/MINE 夹住，唯一）
rep(
    """                            MusicTab.QUKU to "曲库",
                            MusicTab.SEARCH to "搜索",
                            MusicTab.MINE to "我的",""",
    """                            MusicTab.QUKU to "曲库",
                            MusicTab.MINE to "我的", // [46v21] 订阅模式无搜索 tab""",
    "tabdefs-sub",
)

assert src.count("[46v21]") >= 5
assert "SubSearchScreen(" not in src  # 注释里提一句文件名不算残留，只查调用
open(path, "w", encoding="utf-8").write(src)
print("OK 46v21 MH")
PYEOF46V21
python3 /tmp/patch_screen46v21.py
python3 /tmp/patch_mh46v21.py
rm -f avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubSearchScreen.kt
[ ! -f avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubSearchScreen.kt ] || { echo "X 46v21 search file still there"; exit 1; }
grep -rq "SubSearchScreen(" avbox/app/src/main/java/ && { echo "X 46v21 SubSearchScreen refs remain"; exit 1; } || true
grep -q "46v21" avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicScreen.kt || { echo "X 46v21 screen"; exit 1; }
grep -q "46v21" avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt || { echo "X 46v21 MH"; exit 1; }
echo "OK 46v21"
echo "=== 46 v21 done ==="

# === 46 v22: 点卡进详情歌单＋钻入分页＋下拉刷新（用户确认，全量卡片） ===
echo "=== 46 v22 ==="
cat > /tmp/patch_bridge46v22.py << 'PYEOF46V22'
import sys

# 46 v22（桥接侧）：点卡进详情歌单＋钻入分页——
# ① category 加 pg 参数（默认 "1"，旧调用不动），钻入分页靠它拉下一页；
# ② 新 parsePlayParts（详情分集解析：flag + 每集名 + 每集播放 id，$$$ 取第一组、# 分集、$ 分名/地址，空白集过滤）；
# ③ 新 detailEpisodes（详情拆全部分集成 SubTrack，id = 原 id + "#" + 集号，标题取集名、缺名补“原标题 集号”）；
# ④ episodeCache（详情只拉一次：detailEpisodes 与 resolvePlay 共享，超 20 条清掉）；
# ⑤ resolvePlay 改走 parsePlayParts + 缓存：id 带 "#" 按集号取播放 id，越界报“该分集不存在”；其余播放链（playerContent/vip 标志/parse=1 拒绝）与旧版逐字一致
path = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicBridge.kt"
src = open(path, encoding="utf-8").read()
if "// [46v22]" in src:
    print("bridge already 46v22, skip")
    sys.exit(0)

def rep(old, new, tag):
    global src
    assert src.count(old) == 1, "%s anchor %d" % (tag, src.count(old))
    src = src.replace(old, new, 1)

# 1) category 加页码
rep(
    '''    suspend fun category(sourceKey: String, tid: String): List<SubTrack> = withContext(Dispatchers.IO) {
        try {
            val bean = ApiConfig.get().getSource(sourceKey) ?: return@withContext emptyList()
            val sp = ApiConfig.get().getCSP(bean)
            val json = sp.categoryContent(tid, "1", false, HashMap()) ?: return@withContext emptyList()''',
    '''    suspend fun category(sourceKey: String, tid: String, pg: String = "1"): List<SubTrack> = withContext(Dispatchers.IO) { // [46v22] 钻入分页：页码参数，默认 "1"
        try {
            val bean = ApiConfig.get().getSource(sourceKey) ?: return@withContext emptyList()
            val sp = ApiConfig.get().getCSP(bean)
            val json = sp.categoryContent(tid, pg, false, HashMap()) ?: return@withContext emptyList()''',
    "category-page",
)

# 2) 分集解析 + 缓存 + detailEpisodes + resolvePlay 改走缓存
rep(
    '''    suspend fun resolvePlay(track: SubTrack): PlayResult = withContext(Dispatchers.IO) {
        try {
            val bean = ApiConfig.get().getSource(track.sourceKey)
                ?: return@withContext PlayResult.Fail("源已不存在")
            val sp = ApiConfig.get().getCSP(bean)
            val detail = sp.detailContent(listOf(track.id))
                ?: return@withContext PlayResult.Fail("详情为空")
            val d = JSONObject(detail)
            val item = d.optJSONArray("list")?.optJSONObject(0) ?: d
            val from = item.optString("vod_play_from")
            val urls = item.optString("vod_play_url")
            if (from.isBlank() || urls.isBlank()) return@withContext PlayResult.Fail("该条目无播放地址")
            val flag = from.split("$$$")[0]
            val firstGroup = urls.split("$$$")[0]
            val firstEp = firstGroup.split("#")[0]
            val playId = firstEp.substringAfter("$", firstEp)
            val pr = sp.playerContent(flag, playId, ApiConfig.get().getVipParseFlags())
                ?: return@withContext PlayResult.Fail("取播放地址失败")
            val pj = JSONObject(pr)
            val parse = pj.optInt("parse", 0)
            val url = pj.optString("url")
            if (url.isBlank()) return@withContext PlayResult.Fail("播放地址为空")
            if (parse == 1) return@withContext PlayResult.Fail("该源需要解析，源内音乐 v1 暂不支持解析播放")
            PlayResult.Ok(url)
        } catch (e: Exception) {
            PlayResult.Fail("播放失败：${e.message}")
        }
    }''',
    '''    private data class PlayParts(val flag: String, val names: List<String>, val playIds: List<String>) // [46v22] 详情分集解析结果

    private fun parsePlayParts(item: JSONObject): PlayParts? { // [46v22] 详情分集解析：$$$ 取第一组、# 分集、$ 分名/地址，空白集过滤
        val from = item.optString("vod_play_from")
        val urls = item.optString("vod_play_url")
        if (from.isBlank() || urls.isBlank()) return null
        val flag = from.split("$$$")[0]
        val firstGroup = urls.split("$$$")[0]
        val pairs = firstGroup.split("#").filter { it.isNotBlank() }.map { ep ->
            ep.substringBefore("$", "") to ep.substringAfter("$", ep)
        }.filter { it.second.isNotBlank() }
        if (pairs.isEmpty()) return null
        return PlayParts(flag, pairs.map { it.first }, pairs.map { it.second })
    }

    private val episodeCache = mutableMapOf<String, Pair<String, List<String>>>() // [46v22] 详情只拉一次：key = 源:条目 id，value = flag to 播放 id 列表

    suspend fun detailEpisodes(track: SubTrack): List<SubTrack> = withContext(Dispatchers.IO) { // [46v22] 详情拆全部分集（点卡进歌单用）
        try {
            val baseId = track.id.substringBefore("#")
            val bean = ApiConfig.get().getSource(track.sourceKey) ?: return@withContext emptyList()
            val sp = ApiConfig.get().getCSP(bean)
            val detail = sp.detailContent(listOf(baseId)) ?: return@withContext emptyList()
            val d = JSONObject(detail)
            val item = d.optJSONArray("list")?.optJSONObject(0) ?: d
            val parts = parsePlayParts(item) ?: return@withContext emptyList()
            val key = track.sourceKey + ":" + baseId
            if (episodeCache.size > 20) episodeCache.clear()
            episodeCache[key] = parts.flag to parts.playIds
            parts.playIds.mapIndexed { i, _ ->
                val name = parts.names.getOrNull(i)?.takeIf { it.isNotBlank() } ?: (track.title + " " + (i + 1))
                SubTrack(track.sourceKey, track.sourceName, baseId + "#" + i, name, track.pic, "", track.title)
            }
        } catch (e: Exception) {
            emptyList()
        }
    }

    suspend fun resolvePlay(track: SubTrack): PlayResult = withContext(Dispatchers.IO) {
        try {
            val bean = ApiConfig.get().getSource(track.sourceKey)
                ?: return@withContext PlayResult.Fail("源已不存在")
            val sp = ApiConfig.get().getCSP(bean)
            val hash = track.id.indexOf("#")
            val baseId = if (hash >= 0) track.id.substring(0, hash) else track.id
            val wantIdx = if (hash >= 0) track.id.substring(hash + 1).toIntOrNull() ?: 0 else 0
            val key = track.sourceKey + ":" + baseId
            val cached = episodeCache[key]
            val parts: Pair<String, List<String>>
            if (cached != null) {
                parts = cached
            } else {
                val detail = sp.detailContent(listOf(baseId))
                    ?: return@withContext PlayResult.Fail("详情为空")
                val d = JSONObject(detail)
                val item = d.optJSONArray("list")?.optJSONObject(0) ?: d
                val pp = parsePlayParts(item)
                    ?: return@withContext PlayResult.Fail("该条目无播放地址")
                if (episodeCache.size > 20) episodeCache.clear()
                episodeCache[key] = pp.flag to pp.playIds
                parts = pp.flag to pp.playIds
            }
            val playId = parts.second.getOrNull(wantIdx)
                ?: return@withContext PlayResult.Fail("该分集不存在")
            val pr = sp.playerContent(parts.first, playId, ApiConfig.get().getVipParseFlags())
                ?: return@withContext PlayResult.Fail("取播放地址失败")
            val pj = JSONObject(pr)
            val parse = pj.optInt("parse", 0)
            val url = pj.optString("url")
            if (url.isBlank()) return@withContext PlayResult.Fail("播放地址为空")
            if (parse == 1) return@withContext PlayResult.Fail("该源需要解析，源内音乐 v1 暂不支持解析播放")
            PlayResult.Ok(url)
        } catch (e: Exception) {
            PlayResult.Fail("播放失败：${e.message}")
        }
    }''',
    "resolveplay-episodes",
)

assert src.count("[46v22]") >= 5
open(path, "w", encoding="utf-8").write(src)
print("OK 46v22 bridge")
PYEOF46V22
cat > /tmp/patch_screen46v22.py << 'PYEOF46V22'
import sys

# 46 v22（屏幕侧）：点卡进详情歌单＋钻入分页＋下拉刷新——
# ① openItem：点卡探详情（detailEpisodes），多集进分集网格、单集直接播、拉不到报提示；歌单/钻入/搜索三处网格的 onOpen 全改 openItem，圆播 onPlay 保持直接播；
# ② 分集网格分支（detailTracks 非空时替代表格区，← 返回回原列表，点集走现有建队列）；
# ③ 钻入分页：滑到底（末项合成时）拉下一页追加，全重/空页即止；段卡点开重置分页；
# ④ 钻入下拉刷新：PullToRefreshBox 包钻入网格（同 PlaylistScreen/RecommendScreen 的三参用法），重拉第一页；
# ⑤ 换 tab/清空搜索/换源时退出分集网格
path = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicScreen.kt"
src = open(path, encoding="utf-8").read()
if "// [46v22]" in src:
    print("screen already 46v22, skip")
    sys.exit(0)

def rep(old, new, tag):
    global src
    assert src.count(old) == 1, "%s anchor %d" % (tag, src.count(old))
    src = src.replace(old, new, 1)

# 0) 新 import + OptIn（PullToRefreshBox 三参用法同 PlaylistScreen.kt:139；@OptIn 同 RecommendScreen.kt:84）
rep(
    "import androidx.compose.material3.MaterialTheme",
    "import androidx.compose.material3.ExperimentalMaterial3Api\n"
    "import androidx.compose.material3.MaterialTheme",
    "imports-optin",
)
rep(
    "import androidx.compose.material3.Text",
    "import androidx.compose.material3.Text\n"
    "import androidx.compose.material3.pulltorefresh.PullToRefreshBox",
    "imports-ptr",
)
rep(
    "import androidx.compose.foundation.lazy.grid.items\n",
    "import androidx.compose.foundation.lazy.grid.item\n"
    "import androidx.compose.foundation.lazy.grid.items\n",
    "imports-grid-item",
)
rep(
    """@Composable
fun SubMusicScreen(""",
    """@OptIn(ExperimentalMaterial3Api::class) // [46v22] 下拉刷新用 PullToRefreshBox
@Composable
fun SubMusicScreen(""",
    "optin-fun",
)

# 1) 分集 + 分页状态（放在 searchResults 之后）
rep(
    '    var searchResults by remember { mutableStateOf<List<SubMusicBridge.SubTrack>>(emptyList()) } // [46v21] 曲库内搜',
    '    var searchResults by remember { mutableStateOf<List<SubMusicBridge.SubTrack>>(emptyList()) } // [46v21] 曲库内搜\n'
    '    var detailTitle by remember { mutableStateOf("") } // [46v22] 详情分集：点卡进来的合集标题\n'
    '    var detailTracks by remember { mutableStateOf<List<SubMusicBridge.SubTrack>>(emptyList()) } // [46v22] 详情分集列表（多集才进）\n'
    '    var drillPage by remember { mutableStateOf(1) } // [46v22] 钻入分页：当前页\n'
    '    var drillHasMore by remember { mutableStateOf(true) } // [46v22] 钻入分页：还有下一页\n'
    '    var drillLoadingMore by remember { mutableStateOf(false) } // [46v22] 钻入分页：正在拉下一页\n'
    '    var drillRefreshing by remember { mutableStateOf(false) } // [46v22] 钻入下拉刷新',
    "detail-states",
)

# 2) clearSearch：退出分集网格
rep(
    """    fun clearSearch() { // [46v21] 曲库内搜：回浏览
        keyword = ""
        searchResults = emptyList()
        searched = false
        searching = false
    }""",
    """    fun clearSearch() { // [46v21] 曲库内搜：回浏览
        keyword = ""
        searchResults = emptyList()
        searched = false
        searching = false
        detailTitle = "" // [46v22] 退出详情分集
        detailTracks = emptyList()
    }""",
    "clearsearch-detail",
)

# 3) openItem / loadMoreDrill / refreshDrill（放在 playTrack 之后、Column 之前；调用点都在其后）
rep(
    """    fun playTrack(track: SubMusicBridge.SubTrack, list: List<SubMusicBridge.SubTrack>) { // [46v12] 点卡片建队列：当前页从点中那首起
        notice = "正在取播放地址…"
        val maps = SubMusicBridge.toQueueMaps(list)
        val idx = list.indexOfFirst { it.sourceKey == track.sourceKey && it.id == track.id }.takeIf { it >= 0 } ?: 0
        LxPlayerManager.playQueue = maps
        LxPlayerManager.queueIndex = idx
        scope.launch {
            when (val r = SubMusicBridge.resolvePlay(track)) {
                is SubMusicBridge.PlayResult.Ok -> {
                    LxPlayerManager.play(r.url, track.title, track.sourceName, track.pic)
                    notice = ""
                }
                is SubMusicBridge.PlayResult.Fail -> {
                    notice = r.msg
                }
            }
        }
    }""",
    """    fun playTrack(track: SubMusicBridge.SubTrack, list: List<SubMusicBridge.SubTrack>) { // [46v12] 点卡片建队列：当前页从点中那首起
        notice = "正在取播放地址…"
        val maps = SubMusicBridge.toQueueMaps(list)
        val idx = list.indexOfFirst { it.sourceKey == track.sourceKey && it.id == track.id }.takeIf { it >= 0 } ?: 0
        LxPlayerManager.playQueue = maps
        LxPlayerManager.queueIndex = idx
        scope.launch {
            when (val r = SubMusicBridge.resolvePlay(track)) {
                is SubMusicBridge.PlayResult.Ok -> {
                    LxPlayerManager.play(r.url, track.title, track.sourceName, track.pic)
                    notice = ""
                }
                is SubMusicBridge.PlayResult.Fail -> {
                    notice = r.msg
                }
            }
        }
    }

    fun openItem(track: SubMusicBridge.SubTrack, list: List<SubMusicBridge.SubTrack>) { // [46v22] 点卡探详情：多集进列表，单集直接播
        notice = "正在取详情…"
        scope.launch {
            val eps = SubMusicBridge.detailEpisodes(track)
            if (eps.size > 1) {
                detailTitle = track.title
                detailTracks = eps
                notice = ""
            } else if (eps.size == 1) {
                playTrack(track, list)
            } else {
                notice = "拉取详情失败"
            }
        }
    }

    fun loadMoreDrill() { // [46v22] 钻入分页：滑到底拉下一页追加
        val sec = chartDetail ?: return
        val src = selected ?: return
        if (drillLoadingMore || !drillHasMore) return
        drillLoadingMore = true
        scope.launch {
            try {
                val next = drillPage + 1
                val items = SubMusicBridge.category(src.key, sec.first, next.toString()).filter { !SubMusicBridge.isJunkName(it.title) }
                val fresh = items.filter { ni -> gridItems.none { it.sourceKey == ni.sourceKey && it.id == ni.id } }
                if (fresh.isEmpty()) {
                    drillHasMore = false
                } else {
                    val merged = gridItems + fresh
                    drillPage = next
                    gridItems = merged
                    chartDetail = Triple(sec.first, sec.second, merged)
                }
            } catch (e: Exception) {
                // 拉更多失败：留在本页，下次滑到底再试
            } finally {
                drillLoadingMore = false
            }
        }
    }

    fun refreshDrill() { // [46v22] 钻入下拉刷新：重拉第一页
        val sec = chartDetail ?: return
        val src = selected ?: return
        if (drillRefreshing) return
        drillRefreshing = true
        scope.launch {
            try {
                val items = SubMusicBridge.category(src.key, sec.first, "1").filter { !SubMusicBridge.isJunkName(it.title) }
                gridItems = items
                chartDetail = Triple(sec.first, sec.second, items)
                drillPage = 1
                drillHasMore = items.isNotEmpty()
            } catch (e: Exception) {
                // 刷新失败：留在本页
            } finally {
                drillRefreshing = false
            }
        }
    }""",
    "openitem-funs",
)

# 4) applyTab：换 tab 退出分集网格
rep(
    "        chartDetail = null // [46v13] 回榜单视图",
    "        chartDetail = null // [46v13] 回榜单视图\n"
    "        detailTitle = \"\" // [46v22] 换 tab 退出详情分集\n"
    "        detailTracks = emptyList()",
    "applytab-detail",
)

# 5) 段卡点开：重置钻入分页
rep(
    "                                onOpen = { chartDetail = sec; gridItems = sec.third },",
    "                                onOpen = { chartDetail = sec; gridItems = sec.third; drillPage = 1; drillHasMore = true; drillLoadingMore = false }, // [46v22] 钻入分页重置",
    "section-open-reset",
)

# 6) 三处网格 onOpen 改 openItem（圆播 onPlay 不动，仍直接播；标记必须放行尾闭合符号之后，绝不能插在调用中间——// 会吃掉后半行）
rep(
    "SubPeekCard(pic = track.pic, title = track.title, badge = track.remark.takeIf { it.isNotBlank() }, onOpen = { playTrack(track, searchResults) }, onPlay = { playTrack(track, searchResults) })",
    "SubPeekCard(pic = track.pic, title = track.title, badge = track.remark.takeIf { it.isNotBlank() }, onOpen = { openItem(track, searchResults) }, onPlay = { playTrack(track, searchResults) }) // [46v22] 点卡探详情",
    "search-open",
)
rep(
    "SubPeekCard(pic = track.pic, title = track.title, badge = SubMusicBridge.countOf(track.remark), onOpen = { playTrack(track, playlists) }, onPlay = { playTrack(track, playlists) })",
    "SubPeekCard(pic = track.pic, title = track.title, badge = SubMusicBridge.countOf(track.remark), onOpen = { openItem(track, playlists) }, onPlay = { playTrack(track, playlists) }) // [46v22] 点卡探详情",
    "playlist-open",
)

# 7) 分集网格分支（插在搜索分支之后、榜单分支之前）
rep(
    '            } else if (tab == 1 && chartDetail == null) { // [46v19] Peek 式榜单：平铺榜单卡网格（一段一卡，点卡钻入、点播播本榜）',
    """            } else if (detailTracks.isNotEmpty()) { // [46v22] 详情分集列表（歌手/歌单点卡进来）
                Text(
                    text = "← 返回",
                    style = MaterialTheme.typography.bodyMedium,
                    color = musicColors().accent,
                    modifier = Modifier
                        .clickable { detailTracks = emptyList(); detailTitle = "" }
                        .padding(horizontal = 16.dp, vertical = 8.dp)
                )
                Text(
                    text = detailTitle + " · " + detailTracks.size + " 首",
                    style = MaterialTheme.typography.bodySmall,
                    color = musicColors().textSecondary,
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 4.dp)
                )
                LazyVerticalGrid(
                    columns = GridCells.Fixed(3),
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(16.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    items(detailTracks, key = { it.sourceKey + ":" + it.id }) { track ->
                        SubPeekCard(pic = track.pic, title = track.title, badge = null, onOpen = { playTrack(track, detailTracks) }, onPlay = { playTrack(track, detailTracks) })
                    }
                }
            } else if (tab == 1 && chartDetail == null) { // [46v19] Peek 式榜单：平铺榜单卡网格（一段一卡，点卡钻入、点播播本榜）""",
    "detail-branch",
)

# 8) 钻入网格：包 PullToRefreshBox + 末项触发拉下一页 + 加载中尾巴 + onOpen 改 openItem
rep(
    """            } else { // [46v19] 榜单钻入：榜内歌曲网格（Peek 式卡片，无名次）
                if (tab == 1 && chartDetail != null) {
                    Text(
                        text = "← 返回榜单",
                        style = MaterialTheme.typography.bodyMedium,
                        color = musicColors().accent,
                        modifier = Modifier
                            .clickable { chartDetail = null }
                            .padding(horizontal = 16.dp, vertical = 8.dp)
                    )
                }
                LazyVerticalGrid(
                    columns = GridCells.Fixed(3),
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(16.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    items(gridItems, key = { it.sourceKey + ":" + it.id }) { track ->
                        SubPeekCard(pic = track.pic, title = track.title, badge = SubMusicBridge.countOf(track.remark), onOpen = { playTrack(track, gridItems) }, onPlay = { playTrack(track, gridItems) })
                    }
                }
            }""",
    """            } else { // [46v19] 榜单钻入：榜内歌曲网格（Peek 式卡片，无名次）
                if (tab == 1 && chartDetail != null) {
                    Text(
                        text = "← 返回榜单",
                        style = MaterialTheme.typography.bodyMedium,
                        color = musicColors().accent,
                        modifier = Modifier
                            .clickable { chartDetail = null }
                            .padding(horizontal = 16.dp, vertical = 8.dp)
                    )
                }
                PullToRefreshBox( // [46v22] 钻入下拉刷新
                    isRefreshing = drillRefreshing,
                    onRefresh = { refreshDrill() },
                    modifier = Modifier.fillMaxSize()
                ) {
                    LazyVerticalGrid(
                        columns = GridCells.Fixed(3),
                        modifier = Modifier.fillMaxSize(),
                        contentPadding = PaddingValues(16.dp),
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        items(gridItems, key = { it.sourceKey + ":" + it.id }) { track ->
                            if (track.id == gridItems.lastOrNull()?.id) { // [46v22] 滑到底拉下一页
                                LaunchedEffect(track.id) { loadMoreDrill() }
                            }
                            SubPeekCard(pic = track.pic, title = track.title, badge = SubMusicBridge.countOf(track.remark), onOpen = { openItem(track, gridItems) }, onPlay = { playTrack(track, gridItems) })
                        }
                        if (drillLoadingMore) {
                            item {
                                Text(
                                    text = "正在加载更多…",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = musicColors().textSecondary,
                                    modifier = Modifier.padding(16.dp)
                                )
                            }
                        }
                    }
                }
            }""",
    "drill-paging-refresh",
)

assert src.count("[46v22]") >= 12
open(path, "w", encoding="utf-8").write(src)
print("OK 46v22 screen")
PYEOF46V22
python3 /tmp/patch_bridge46v22.py
python3 /tmp/patch_screen46v22.py
grep -q "46v22" avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicBridge.kt || { echo "X 46v22 bridge"; exit 1; }
grep -q "46v22" avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicScreen.kt || { echo "X 46v22 screen"; exit 1; }
echo "OK 46v22"
echo "=== 46 v22 done ==="

# === 46 v23: 歌单首次就拉出来（用户确认：首次打开歌单空、去榜单回来才有） ===
echo "=== 46 v23 ==="
cat > /tmp/patch_screen46v23.py << 'PYEOF46V23'
import sys

# 46 v23（屏幕侧）：歌单首次就拉出来——
# 根因：歌单 tab 是 chartItems 的派生视图（pool=home.items+chartItems），但分段拉取只在 applyTab(t==1) 里跑；
# 首次停在歌单 tab 时 chartItems 为空，且该源 home.items 里没有歌单型条目，故首次空、去榜单走一圈才出现。
# 改法：① 新 loadSections（分段拉取，换源时就启动，与 tab 无关；一源只拉一次，sectionsKey 守卫）；
# ② loadBrowse 在 home 到手后先调 loadSections 再调 applyTab；③ applyTab(t==1) 不再自带拉取循环，只做兜底；
# ④ 换源失败时清 sectionsKey/分段，容后重试；⑤ 歌单 tab 空时：还在拉分段显示“正在加载歌单…”，拉完仍空才说“该源暂无歌单”；
# ⑥ 附带：换源时清 chartItems，避免旧源条目留在新源歌单池里
path = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicScreen.kt"
src = open(path, encoding="utf-8").read()
if "// [46v23]" in src:
    print("screen already 46v23, skip")
    sys.exit(0)

def rep(old, new, tag):
    global src
    assert src.count(old) == 1, "%s anchor %d" % (tag, src.count(old))
    src = src.replace(old, new, 1)

# 1) sectionsKey 状态（放在 sectionsLoading 之后）
rep(
    "    var sectionsLoading by remember { mutableStateOf(false) } // [46v13] 分段加载中",
    "    var sectionsLoading by remember { mutableStateOf(false) } // [46v13] 分段加载中\n"
    "    var sectionsKey by remember { mutableStateOf<String?>(null) } // [46v23] 分段已拉的源 key（换源重拉，同源不重拉）",
    "sections-key-state",
)

# 2) loadSections（插在 applyTab 之前；applyTab/loadBrowse 在其后调用）
rep(
    """    fun applyTab(src: SubMusicBridge.SubSource, t: Int, h: SubMusicBridge.SubHome?) { // [46v19] Peek 式两 tab：0=歌单，1=榜单（歌手 tab 拿掉）
        chartDetail = null // [46v13] 回榜单视图
        detailTitle = "" // [46v22] 换 tab 退出详情分集
        detailTracks = emptyList()
        if (t == 0) { // [46v16] 歌单 tab：派生视图，不拉数据
            gridItems = emptyList()
            gridNote = ""
            return
        }
        if (h == null || h.classes.isEmpty()) {
            chartSections = emptyList()
            chartItems = emptyList()
            gridNote = "该源暂无分类"
            return
        }
        gridNote = ""
        chartSections = emptyList()
        sectionsLoading = true
        scope.launch {
            try {
                for (cls in h.classes) { // [46v15] 只拉有用的分类：杂项分类、歌手类分类跳过不拉
                    if (SubMusicBridge.isJunkName(cls.name) || cls.name.contains("歌手") || SubMusicBridge.isNavTitle(cls.name)) continue // [46v18] 导航类分类跳过不拉
                    try {
                        val items = SubMusicBridge.category(src.key, cls.id).filter { !SubMusicBridge.isJunkName(it.title) } // [46v15] 段内杂项条目过滤
                        if (items.isNotEmpty()) {
                            val ns = chartSections + Triple(cls.id, cls.name, items)
                            chartSections = ns
                            chartItems = ns.flatMap { it.third } // [46v13] 歌手推导覆盖全部分段
                        }
                    } catch (e: Exception) {
                        // 单段失败跳过，不拦后段
                    }
                }
            } finally {
                sectionsLoading = false
            }
        }
    }""",
    """    fun loadSections(src: SubMusicBridge.SubSource, h: SubMusicBridge.SubHome?) { // [46v23] 分段拉取：换源时就拉，与 tab 无关
        if (h == null || h.classes.isEmpty()) return
        if (sectionsKey == src.key) return
        sectionsKey = src.key
        chartSections = emptyList()
        chartItems = emptyList()
        sectionsLoading = true
        scope.launch {
            try {
                for (cls in h.classes) { // [46v15] 只拉有用的分类：杂项分类、歌手类分类跳过不拉
                    if (SubMusicBridge.isJunkName(cls.name) || cls.name.contains("歌手") || SubMusicBridge.isNavTitle(cls.name)) continue // [46v18] 导航类分类跳过不拉
                    try {
                        val items = SubMusicBridge.category(src.key, cls.id).filter { !SubMusicBridge.isJunkName(it.title) } // [46v15] 段内杂项条目过滤
                        if (items.isNotEmpty()) {
                            val ns = chartSections + Triple(cls.id, cls.name, items)
                            chartSections = ns
                            chartItems = ns.flatMap { it.third } // [46v13] 歌手推导覆盖全部分段
                        }
                    } catch (e: Exception) {
                        // 单段失败跳过，不拦后段
                    }
                }
            } finally {
                sectionsLoading = false
            }
        }
    }

    fun applyTab(src: SubMusicBridge.SubSource, t: Int, h: SubMusicBridge.SubHome?) { // [46v19] Peek 式两 tab：0=歌单，1=榜单（歌手 tab 拿掉）
        chartDetail = null // [46v13] 回榜单视图
        detailTitle = "" // [46v22] 换 tab 退出详情分集
        detailTracks = emptyList()
        if (t == 0) { // [46v16] 歌单 tab：派生视图（分段已在换源时拉起）
            gridItems = emptyList()
            gridNote = ""
            return
        }
        if (h == null || h.classes.isEmpty()) {
            chartSections = emptyList()
            chartItems = emptyList()
            gridNote = "该源暂无分类"
            return
        }
        gridNote = ""
        loadSections(src, h) // [46v23] 分段已在换源时拉起，这里只做兜底（未拉过才拉）
    }""",
    "loadsections-applytab",
)

# 3) loadBrowse：home 到手后先拉分段；失败时清分段 key，容后重试
rep(
    """    fun loadBrowse(src: SubMusicBridge.SubSource) {
        clearSearch() // [46v21] 换源回浏览
        gridLoading = true
        gridNote = ""
        scope.launch {
            try {
                val h = SubMusicBridge.home(src.key)
                home = h
                gridLoading = false
                applyTab(src, tab, h)
            } catch (e: Exception) {
                gridLoading = false
                home = null
                gridItems = emptyList()
                gridNote = "加载失败：${e.message}"
            }
        }
    }""",
    """    fun loadBrowse(src: SubMusicBridge.SubSource) {
        clearSearch() // [46v21] 换源回浏览
        gridLoading = true
        gridNote = ""
        scope.launch {
            try {
                val h = SubMusicBridge.home(src.key)
                home = h
                gridLoading = false
                loadSections(src, h) // [46v23] 换源就拉分段，歌单 tab 不用先去榜单
                applyTab(src, tab, h)
            } catch (e: Exception) {
                gridLoading = false
                home = null
                gridItems = emptyList()
                sectionsKey = null // [46v23] 换源失败：清分段 key，容后重试
                chartSections = emptyList()
                chartItems = emptyList()
                gridNote = "加载失败：${e.message}"
            }
        }
    }""",
    "loadbrowse-sections",
)

# 4) 歌单 tab 空态：还在拉分段时说“正在加载歌单…”，拉完仍空才说暂无
rep(
    """            } else if (tab == 0) { // [46v19] 歌单 tab：Peek 式紧致网格
                if (playlists.isEmpty()) {
                    Text(
                        text = "该源暂无歌单",""",
    """            } else if (tab == 0) { // [46v19] 歌单 tab：Peek 式紧致网格
                if (playlists.isEmpty()) {
                    Text(
                        text = if (sectionsLoading) "正在加载歌单…" else "该源暂无歌单", // [46v23] 加载中不说暂无""",
    "playlist-empty-loading",
)

assert src.count("[46v23]") >= 6
open(path, "w", encoding="utf-8").write(src)
print("OK 46v23 screen")
PYEOF46V23
python3 /tmp/patch_screen46v23.py
grep -q "46v23" avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicScreen.kt || { echo "X 46v23 screen"; exit 1; }
echo "OK 46v23"
echo "=== 46 v23 done ==="

# === 46 v24: 构建红修复——删 v22 误加的 lazy.grid.item import（用户截图“别猜”，唯一报错 27:46） ===
echo "=== 46 v24 ==="
cat > /tmp/patch_screen46v24.py << 'PYEOF46V24'
import sys

# 46 v24（构建红修复）：删 v22 误加的 import 行——
# 实锤：2026-11-05 18:24 构建红，唯一报错 SubMusicScreen.kt:27:46 Unresolved reference 'item'（27 行就是这行 import，
# 46 脚本步骤本身已过、构建步骤 10 秒即红、错误摘要只有这一条）；
# 根因：`item` 是 LazyGridScope/LazyListScope 的成员函数（作用域内直接用，不用 import），只有 List 版 `items`/`itemsIndexed`
# 才是顶层扩展函数才要 import；全仓无人 import 过 lazy.grid.item（v22 那行是唯一一处），而 LazyColumn 里的 `item {`
# （MusicHomeActivity.kt:1905、LxArtistDetailActivity.kt:277 等）全都不带 import——同款实证；
# 修法：只删 import 行，钻入网格底的 `item { "正在加载更多…" }` 尾巴原样保留（它是作用域成员调用）
path = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicScreen.kt"
src = open(path, encoding="utf-8").read()
if "// [46v24]" in src:
    print("screen already 46v24, skip")
    sys.exit(0)

old = "import androidx.compose.foundation.lazy.grid.item\n"
assert src.count(old) == 1, "bad-import anchor %d" % src.count(old)
src = src.replace(old, "", 1)
assert "lazy.grid.item\n" not in src, "import still present"
assert "item {\n" in src, "loading footer item block missing"
assert "46v22" in src and "46v23" in src
open(path, "w", encoding="utf-8").write(src)
print("OK 46v24 screen")
PYEOF46V24
python3 /tmp/patch_screen46v24.py
grep -q "46v22" avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicScreen.kt || { echo "X 46v24 screen"; exit 1; }
echo "OK 46v24"
echo "=== 46 v24 done ==="

# === 46 v25: 榜单只留真榜单＋歌手全进歌单（用户确认；歌手管理弹窗是源站自带的） ===
echo "=== 46 v25 ==="
cat > /tmp/patch_screen46v25.py << 'PYEOF46V25'
import sys

# 46 v25（屏幕侧）：榜单只留真榜单＋歌手全进歌单（用户确认；弹窗是源站自带的，不在 AVBox 里）——
# 背景：歌单 tab 的 5 张歌手卡就是源站首页透过来的管理名单（桥接只读源站首页＋分类）；
# 藏在分类里的歌手此前整段跳过（loadSections 跳含“歌手”的分类），进不了任何 tab。
# 改法：① loadSections 不再跳过歌手分类（其条目进池子）；② 榜单 tab 只显分类名含榜单信号词的段
# （新增 chartOnlySections 派生，isChartLike 既有口径：榜/排行/飙升/新歌/畅听/会员/热歌/金曲/视频）；
# ③ 歌单 tab＝isCollection(pool)＋非榜单类段的条目全并入（去重，歌手类段条目必进歌单、不依赖备注）；
# ④ 不建歌手 tab、不猜人名、不逐卡探详情；歌单仍只取各段第 1 页
path = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicScreen.kt"
src = open(path, encoding="utf-8").read()
if "// [46v25]" in src:
    print("screen already 46v25, skip")
    sys.exit(0)

def rep(old, new, tag):
    global src
    assert src.count(old) == 1, "%s anchor %d" % (tag, src.count(old))
    src = src.replace(old, new, 1)

# 1) loadSections：歌手分类不再跳过
rep(
    '                    if (SubMusicBridge.isJunkName(cls.name) || cls.name.contains("歌手") || SubMusicBridge.isNavTitle(cls.name)) continue // [46v18] 导航类分类跳过不拉',
    '                    if (SubMusicBridge.isJunkName(cls.name) || SubMusicBridge.isNavTitle(cls.name)) continue // [46v25] 歌手分类不再跳过（其条目进歌单），导航类仍跳过',
    "unskip-singer-class",
)

# 2) 歌单桶：并入非榜单类段条目；榜单派生：只留真榜单段
rep(
    """    val playlists = remember(pool) { // [46v16] 歌单桶：合集型条目（人名合集除外，归歌手）
        pool.filter { SubMusicBridge.isCollection(it) }
    }""",
    """    val playlists = remember(pool, chartSections) { // [46v25] 歌单桶：合集型条目＋非榜单类段的条目全并入（歌手类段条目必进歌单）
        (pool.filter { SubMusicBridge.isCollection(it) } + chartSections.filter { !SubMusicBridge.isChartLike(it.second) }.flatMap { it.third }.filter { it.title.trim() != "热门歌曲" })
            .distinctBy { it.sourceKey + ":" + it.id }
    }

    val chartOnlySections = remember(chartSections) { // [46v25] 榜单只留真榜单：分类名含榜单信号词的段
        chartSections.filter { SubMusicBridge.isChartLike(it.second) }
    }""",
    "playlists-chartonly",
)

# 3) 榜单段卡网格：只显 chartOnlySections；空态区分（加载中/无分类/无榜单类段）
rep(
    """                } else if (chartSections.isEmpty()) {
                    Text(
                        text = if (sectionsLoading) "正在加载榜单…" else "该源暂无分类内容",""",
    """                } else if (chartOnlySections.isEmpty()) {
                    Text(
                        text = if (sectionsLoading) "正在加载榜单…" else if (chartSections.isEmpty()) "该源暂无分类内容" else "该源暂无榜单", // [46v25] 有分类但无榜单类段""",
    "chart-empty-text",
)
rep(
    "                        items(chartSections, key = { it.first }) { sec ->",
    "                        items(chartOnlySections, key = { it.first }) { sec -> // [46v25] 只显真榜单段",
    "chart-grid-only",
)

assert src.count("[46v25]") >= 5
open(path, "w", encoding="utf-8").write(src)
print("OK 46v25 screen")
PYEOF46V25
python3 /tmp/patch_screen46v25.py
grep -q "46v25" avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicScreen.kt || { echo "X 46v25 screen"; exit 1; }
echo "OK 46v25"
echo "=== 46 v25 done ==="

echo "=== 46 v26 ==="
cat > /tmp/patch_screen46v26.py << 'PYEOF46V26'
import sys

# 46 v26（屏幕侧）：分类横条＋当页内容（用户确认“按这个做 v26”，取代纵向分段旧版方案）——
# 删两 pill 与 tab 分流（tab/applyTab/playlists/chartOnlySections/pool/chartItems/sectionsLoading 全删），
# 顶部横向可滑分类条（源站自己的分类：歌手/歌单/榜单/250榜……按源站顺序向右延伸），点分类只换当页内容、不跳新页；
# 内容区复用钻入网格（chartDetail/gridItems/分页/下拉刷新），点分类即以前段卡点开的动作，去掉“← 返回榜单”；
# 首页条目放第一个分类片“推荐”（管理那 5 张歌手走的就是这条）；数据层不动，仍只取各段第 1 页
path = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicScreen.kt"
src = open(path, encoding="utf-8").read()
if "// [46v26]" in src:
    print("screen already 46v26, skip")
    sys.exit(0)

def rep(old, new, tag):
    global src
    assert src.count(old) == 1, "%s anchor %d" % (tag, src.count(old))
    src = src.replace(old, new, 1)

# 1) 删 tab 状态
rep(
    """    var tab by remember { mutableStateOf(0) }
""",
    "",
    "drop-tab-state",
)

# 2) 删 chartItems 状态
rep(
    """    var chartItems by remember { mutableStateOf<List<SubMusicBridge.SubTrack>>(emptyList()) } // [46v12] 榜单 items（进歌单池）
""",
    "",
    "drop-chartItems-state",
)

# 3) 删 sectionsLoading 状态
rep(
    """    var sectionsLoading by remember { mutableStateOf(false) } // [46v13] 分段加载中
""",
    "",
    "drop-sectionsLoading-state",
)

# 4) chartDetail 注释改义
rep(
    '    var chartDetail by remember { mutableStateOf<Triple<String, String, List<SubMusicBridge.SubTrack>>?>(null) } // [46v13] 榜单“全部”钻入的段，null=分段视图',
    '    var chartDetail by remember { mutableStateOf<Triple<String, String, List<SubMusicBridge.SubTrack>>?>(null) } // [46v26] 当前选中的分类（null=推荐）',
    "chartDetail-comment",
)

# 5) pool/playlists/chartOnlySections → homeItems（推荐）
rep(
    """    val pool = remember(home, chartItems) { // [46v16] 分桶原料：首页＋全部分段，去杂项、去重
        val names = home?.classes?.map { it.name } ?: emptyList()
        ((home?.items ?: emptyList()) + chartItems)
            .filter { !SubMusicBridge.isJunkName(it.title) && !names.contains(it.title.trim()) && it.title.trim() != "热门歌曲" }
            .distinctBy { it.sourceKey + ":" + it.id }
    }

    val playlists = remember(pool, chartSections) { // [46v25] 歌单桶：合集型条目＋非榜单类段的条目全并入（歌手类段条目必进歌单）
        (pool.filter { SubMusicBridge.isCollection(it) } + chartSections.filter { !SubMusicBridge.isChartLike(it.second) }.flatMap { it.third }.filter { it.title.trim() != "热门歌曲" })
            .distinctBy { it.sourceKey + ":" + it.id }
    }

    val chartOnlySections = remember(chartSections) { // [46v25] 榜单只留真榜单：分类名含榜单信号词的段
        chartSections.filter { SubMusicBridge.isChartLike(it.second) }
    }""",
    """    val homeItems = remember(home) { // [46v26] 推荐：首页条目（管理那 5 张歌手走的就是这条），去杂项
        (home?.items ?: emptyList())
            .filter { !SubMusicBridge.isJunkName(it.title) && it.title.trim() != "热门歌曲" }
    }""",
    "pool-to-homeItems",
)

# 6) loadSections 全量改写：去 chartItems/sectionsLoading 写入，去外层 try/finally
rep(
    """    fun loadSections(src: SubMusicBridge.SubSource, h: SubMusicBridge.SubHome?) { // [46v23] 分段拉取：换源时就拉，与 tab 无关
        if (h == null || h.classes.isEmpty()) return
        if (sectionsKey == src.key) return
        sectionsKey = src.key
        chartSections = emptyList()
        chartItems = emptyList()
        sectionsLoading = true
        scope.launch {
            try {
                for (cls in h.classes) { // [46v15] 只拉有用的分类：杂项分类、歌手类分类跳过不拉
                    if (SubMusicBridge.isJunkName(cls.name) || SubMusicBridge.isNavTitle(cls.name)) continue // [46v25] 歌手分类不再跳过（其条目进歌单），导航类仍跳过
                    try {
                        val items = SubMusicBridge.category(src.key, cls.id).filter { !SubMusicBridge.isJunkName(it.title) } // [46v15] 段内杂项条目过滤
                        if (items.isNotEmpty()) {
                            val ns = chartSections + Triple(cls.id, cls.name, items)
                            chartSections = ns
                            chartItems = ns.flatMap { it.third } // [46v13] 歌手推导覆盖全部分段
                        }
                    } catch (e: Exception) {
                        // 单段失败跳过，不拦后段
                    }
                }
            } finally {
                sectionsLoading = false
            }
        }
    }""",
    """    fun loadSections(src: SubMusicBridge.SubSource, h: SubMusicBridge.SubHome?) { // [46v23] 分段拉取：换源时就拉，与 tab 无关
        if (h == null || h.classes.isEmpty()) return
        if (sectionsKey == src.key) return
        sectionsKey = src.key
        chartSections = emptyList()
        scope.launch {
            for (cls in h.classes) { // [46v26] 只拉有用的分类：杂项、导航类跳过，歌手分类照拉
                if (SubMusicBridge.isJunkName(cls.name) || SubMusicBridge.isNavTitle(cls.name)) continue // [46v25] 歌手分类不再跳过，导航类仍跳过
                try {
                    val items = SubMusicBridge.category(src.key, cls.id).filter { !SubMusicBridge.isJunkName(it.title) } // [46v15] 段内杂项条目过滤
                    if (items.isNotEmpty()) {
                        chartSections = chartSections + Triple(cls.id, cls.name, items)
                    }
                } catch (e: Exception) {
                    // 单段失败跳过，不拦后段
                }
            }
        }
    }""",
    "loadSections-v26",
)

# 7) 删 applyTab 整段
rep(
    """    fun applyTab(src: SubMusicBridge.SubSource, t: Int, h: SubMusicBridge.SubHome?) { // [46v19] Peek 式两 tab：0=歌单，1=榜单（歌手 tab 拿掉）
        chartDetail = null // [46v13] 回榜单视图
        detailTitle = "" // [46v22] 换 tab 退出详情分集
        detailTracks = emptyList()
        if (t == 0) { // [46v16] 歌单 tab：派生视图（分段已在换源时拉起）
            gridItems = emptyList()
            gridNote = ""
            return
        }
        if (h == null || h.classes.isEmpty()) {
            chartSections = emptyList()
            chartItems = emptyList()
            gridNote = "该源暂无分类"
            return
        }
        gridNote = ""
        loadSections(src, h) // [46v23] 分段已在换源时拉起，这里只做兜底（未拉过才拉）
    }

""",
    "",
    "drop-applyTab",
)

# 8) loadBrowse 全量改写：换源回推荐，无分类时清分段＋明说
rep(
    """    fun loadBrowse(src: SubMusicBridge.SubSource) {
        clearSearch() // [46v21] 换源回浏览
        gridLoading = true
        gridNote = ""
        scope.launch {
            try {
                val h = SubMusicBridge.home(src.key)
                home = h
                gridLoading = false
                loadSections(src, h) // [46v23] 换源就拉分段，歌单 tab 不用先去榜单
                applyTab(src, tab, h)
            } catch (e: Exception) {
                gridLoading = false
                home = null
                gridItems = emptyList()
                sectionsKey = null // [46v23] 换源失败：清分段 key，容后重试
                chartSections = emptyList()
                chartItems = emptyList()
                gridNote = "加载失败：${e.message}"
            }
        }
    }""",
    """    fun loadBrowse(src: SubMusicBridge.SubSource) {
        clearSearch() // [46v21] 换源回浏览
        gridLoading = true
        gridNote = ""
        chartDetail = null // [46v26] 换源回推荐
        detailTitle = ""
        detailTracks = emptyList()
        gridItems = emptyList()
        scope.launch {
            try {
                val h = SubMusicBridge.home(src.key)
                home = h
                gridLoading = false
                if (h == null || h.classes.isEmpty()) {
                    chartSections = emptyList()
                    gridNote = "该源暂无分类"
                } else {
                    gridNote = ""
                    loadSections(src, h) // [46v23] 换源就拉分段
                }
            } catch (e: Exception) {
                gridLoading = false
                home = null
                gridItems = emptyList()
                sectionsKey = null // [46v23] 换源失败：清分段 key，容后重试
                chartSections = emptyList()
                gridNote = "加载失败：${e.message}"
            }
        }
    }""",
    "loadBrowse-v26",
)

# 9) pill 行 → 分类横条 LazyRow（推荐片＋每分类一片）
rep(
    """            if (!searched && !searching) { // [46v21] 搜结果时藏 pill tab
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) { // [46v19] Peek 式 pill tab：选中绿底＋对勾，未选中卡片底
                listOf("歌单", "榜单").forEachIndexed { i, label ->
                    val sel = tab == i
                    Row(
                        modifier = Modifier
                            .padding(end = 12.dp)
                            .clip(androidx.compose.foundation.shape.RoundedCornerShape(50))
                            .background(if (sel) musicColors().accent else musicColors().card)
                            .clickable {
                                if (!sel) {
                                    tab = i
                                    val src = selected
                                    if (src != null) applyTab(src, i, home)
                                }
                            }
                            .padding(horizontal = 16.dp, vertical = 8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        val checkTint = musicColors().accentText
                        if (sel) {
                            Canvas(modifier = Modifier.size(14.dp)) {
                                val sw = 2.dp.toPx()
                                drawLine(color = checkTint, start = androidx.compose.ui.geometry.Offset(2.dp.toPx(), 7.dp.toPx()), end = androidx.compose.ui.geometry.Offset(6.dp.toPx(), 11.dp.toPx()), strokeWidth = sw, cap = androidx.compose.ui.graphics.StrokeCap.Round)
                                drawLine(color = checkTint, start = androidx.compose.ui.geometry.Offset(6.dp.toPx(), 11.dp.toPx()), end = androidx.compose.ui.geometry.Offset(12.dp.toPx(), 3.dp.toPx()), strokeWidth = sw, cap = androidx.compose.ui.graphics.StrokeCap.Round)
                            }
                            Spacer(modifier = Modifier.width(6.dp))
                        }
                        Text(
                            text = label,
                            style = MaterialTheme.typography.bodyLarge,
                            fontWeight = if (sel) FontWeight.Bold else FontWeight.Normal,
                            color = if (sel) musicColors().accentText else musicColors().textSecondary
                        )
                    }
                }
            }
            } // [46v21] 搜结果时藏 pill tab""",
    """            if (!searched && !searching) { // [46v21] 搜结果时藏分类条
            LazyRow( // [46v26] 分类横条：源站自己的分类向右延伸，点分类只换当页内容、不跳新页
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 8.dp),
                contentPadding = PaddingValues(horizontal = 16.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                item { // [46v26] 推荐片：首页条目
                    ClassChip(
                        label = "推荐",
                        selected = chartDetail == null,
                        onClick = {
                            if (chartDetail != null) {
                                chartDetail = null
                                gridItems = emptyList()
                                detailTitle = ""
                                detailTracks = emptyList()
                            }
                        }
                    )
                }
                items(chartSections, key = { it.first }) { sec ->
                    ClassChip(
                        label = sec.second,
                        selected = chartDetail?.first == sec.first,
                        onClick = {
                            if (chartDetail?.first != sec.first) {
                                chartDetail = sec
                                gridItems = sec.third
                                drillPage = 1
                                drillHasMore = true
                                drillLoadingMore = false
                                detailTitle = ""
                                detailTracks = emptyList()
                            }
                        }
                    )
                }
            }
            } // [46v21] 搜结果时藏分类条""",
    "pill-to-classstrip",
)

# 10) 删榜单段卡分支（tab==1 平铺网格）
rep(
    """            } else if (tab == 1 && chartDetail == null) { // [46v19] Peek 式榜单：平铺榜单卡网格（一段一卡，点卡钻入、点播播本榜）
                if (gridNote.isNotBlank()) {
                    Text(
                        text = gridNote,
                        style = MaterialTheme.typography.bodyMedium,
                        color = musicColors().textSecondary,
                        modifier = Modifier.padding(16.dp)
                    )
                } else if (chartOnlySections.isEmpty()) {
                    Text(
                        text = if (sectionsLoading) "正在加载榜单…" else if (chartSections.isEmpty()) "该源暂无分类内容" else "该源暂无榜单", // [46v25] 有分类但无榜单类段
                        style = MaterialTheme.typography.bodyMedium,
                        color = musicColors().textSecondary,
                        modifier = Modifier.padding(16.dp)
                    )
                } else {
                    if (sectionsLoading) {
                        Text(
                            text = "正在加载更多分类…",
                            style = MaterialTheme.typography.bodySmall,
                            color = musicColors().textSecondary,
                            modifier = Modifier.padding(horizontal = 16.dp, vertical = 4.dp)
                        )
                    }
                    LazyVerticalGrid(
                        columns = GridCells.Fixed(3),
                        modifier = Modifier.fillMaxSize(),
                        contentPadding = PaddingValues(16.dp),
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        items(chartOnlySections, key = { it.first }) { sec -> // [46v25] 只显真榜单段
                            val first = sec.third.firstOrNull()
                            SubPeekCard(
                                pic = first?.pic ?: "",
                                title = sec.second,
                                badge = "榜单",
                                onOpen = { chartDetail = sec; gridItems = sec.third; drillPage = 1; drillHasMore = true; drillLoadingMore = false }, // [46v22] 钻入分页重置
                                onPlay = { if (sec.third.isNotEmpty()) playTrack(sec.third.first(), sec.third) }
                            )
                        }
                    }
                }
            } else if (gridLoading) {""",
    """            } else if (gridLoading) {""",
    "drop-sections-branch",
)

# 11) 删歌单分支，钻入 else 改 else-if（分类内容）
rep(
    """            } else if (tab == 0) { // [46v19] 歌单 tab：Peek 式紧致网格
                if (playlists.isEmpty()) {
                    Text(
                        text = if (sectionsLoading) "正在加载歌单…" else "该源暂无歌单", // [46v23] 加载中不说暂无
                        style = MaterialTheme.typography.bodyMedium,
                        color = musicColors().textSecondary,
                        modifier = Modifier.padding(16.dp)
                    )
                } else {
                    LazyVerticalGrid(
                        columns = GridCells.Fixed(3),
                        modifier = Modifier.fillMaxSize(),
                        contentPadding = PaddingValues(16.dp),
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        items(playlists, key = { it.sourceKey + ":" + it.id }) { track ->
                            SubPeekCard(pic = track.pic, title = track.title, badge = SubMusicBridge.countOf(track.remark), onOpen = { openItem(track, playlists) }, onPlay = { playTrack(track, playlists) }) // [46v22] 点卡探详情
                        }
                    }
                }
            } else { // [46v19] 榜单钻入：榜内歌曲网格（Peek 式卡片，无名次）""",
    """            } else if (chartDetail != null) { // [46v26] 分类内容：当前选中的分类（当页切换，不跳新页）""",
    "playlist-to-classcontent",
)

# 12) 删钻入内“← 返回榜单”
rep(
    """                if (tab == 1 && chartDetail != null) {
                    Text(
                        text = "← 返回榜单",
                        style = MaterialTheme.typography.bodyMedium,
                        color = musicColors().accent,
                        modifier = Modifier
                            .clickable { chartDetail = null }
                            .padding(horizontal = 16.dp, vertical = 8.dp)
                    )
                }
""",
    "",
    "drop-drill-backlink",
)

# 13) 钻入尾巴后追加推荐分支
rep(
    """                        if (drillLoadingMore) {
                            item {
                                Text(
                                    text = "正在加载更多…",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = musicColors().textSecondary,
                                    modifier = Modifier.padding(16.dp)
                                )
                            }
                        }
                    }
                }
            }""",
    """                        if (drillLoadingMore) {
                            item {
                                Text(
                                    text = "正在加载更多…",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = musicColors().textSecondary,
                                    modifier = Modifier.padding(16.dp)
                                )
                            }
                        }
                    }
                }
            } else { // [46v26] 推荐：首页条目
                if (homeItems.isEmpty()) {
                    Text(
                        text = "该源暂无推荐",
                        style = MaterialTheme.typography.bodyMedium,
                        color = musicColors().textSecondary,
                        modifier = Modifier.padding(16.dp)
                    )
                } else {
                    LazyVerticalGrid(
                        columns = GridCells.Fixed(3),
                        modifier = Modifier.fillMaxSize(),
                        contentPadding = PaddingValues(16.dp),
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        items(homeItems, key = { it.sourceKey + ":" + it.id }) { track ->
                            SubPeekCard(pic = track.pic, title = track.title, badge = SubMusicBridge.countOf(track.remark), onOpen = { openItem(track, homeItems) }, onPlay = { playTrack(track, homeItems) })
                        }
                    }
                }
            }""",
    "append-recommend-branch",
)

# 14) SubPeekCard 之前插入 ClassChip（分类片：同 v19 pill 样式）
rep(
    """@Composable
private fun SubPeekCard(pic: String, title: String, badge: String?, onOpen: () -> Unit, onPlay: () -> Unit) { // [46v19] Peek 式卡片：方形封面＋左上徽标＋右下圆播＋单行标题（点卡打开、点播播放）""",
    """@Composable
private fun ClassChip(label: String, selected: Boolean, onClick: () -> Unit) { // [46v26] 分类片：选中绿底＋对勾，未选中卡片底（同 v19 pill 样式）
    Row(
        modifier = Modifier
            .clip(androidx.compose.foundation.shape.RoundedCornerShape(50))
            .background(if (selected) musicColors().accent else musicColors().card)
            .clickable { onClick() }
            .padding(horizontal = 16.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        val checkTint = musicColors().accentText
        if (selected) {
            Canvas(modifier = Modifier.size(14.dp)) {
                val sw = 2.dp.toPx()
                drawLine(color = checkTint, start = androidx.compose.ui.geometry.Offset(2.dp.toPx(), 7.dp.toPx()), end = androidx.compose.ui.geometry.Offset(6.dp.toPx(), 11.dp.toPx()), strokeWidth = sw, cap = androidx.compose.ui.graphics.StrokeCap.Round)
                drawLine(color = checkTint, start = androidx.compose.ui.geometry.Offset(6.dp.toPx(), 11.dp.toPx()), end = androidx.compose.ui.geometry.Offset(12.dp.toPx(), 3.dp.toPx()), strokeWidth = sw, cap = androidx.compose.ui.graphics.StrokeCap.Round)
            }
            Spacer(modifier = Modifier.width(6.dp))
        }
        Text(
            text = label,
            style = MaterialTheme.typography.bodyLarge,
            fontWeight = if (selected) FontWeight.Bold else FontWeight.Normal,
            color = if (selected) musicColors().accentText else musicColors().textSecondary
        )
    }
}

@Composable
private fun SubPeekCard(pic: String, title: String, badge: String?, onOpen: () -> Unit, onPlay: () -> Unit) { // [46v19] Peek 式卡片：方形封面＋左上徽标＋右下圆播＋单行标题（点卡打开、点播播放）""",
    "insert-ClassChip",
)

# 后验：死代码全清，v26 标记在位，括号平衡，标记注释不吞码
for dead in ["applyTab", "chartOnlySections", "playlists", "chartItems", "sectionsLoading", "var tab by"]:
    assert dead not in src, "dead remains: %s" % dead
assert src.count("[46v26]") >= 9
assert src.count("(") - src.count(")") == 0
assert src.count("{") - src.count("}") == 0
assert src.count("[") - src.count("]") == 0
for line in src.splitlines():
    if "// [46v26]" in line:
        after = line.split("// [46v26]", 1)[1]
        assert "{" not in after and "}" not in after and "(" not in after and ")" not in after and "," not in after, "comment-eaten: %s" % line
open(path, "w", encoding="utf-8").write(src)
print("patched 46v26")

PYEOF46V26
python3 /tmp/patch_screen46v26.py
grep -q "46v26" avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicScreen.kt || { echo "X 46v26 screen"; exit 1; }
echo "OK 46v26"
echo "=== 46 v26 done ==="

echo "=== 46 v27 ==="
cat > /tmp/patch_screen46v27.py << 'PYEOF46V27'
import sys

# 46 v27（桥接＋曲库屏）：订阅带头播放（主体能播、专区报网络异常的根因修法；配 21 v56）——
# 探针用浏览器 UA＋Range 能拿到文件头（498kbps 已量出），ExoPlayer 用默认 UA、什么头都不带，被源站挡了→onPlayerError 网络类分支报网络异常；
# 主体在 PlayLoader.mergeSiteHeaders＋PlayUrlResolver.jsonParse 把源站 header 与结果里的 UA/Referer 带上。
# 修法：resolvePlay 从 playerContent 返回里取头（header/headers 对象＋user-agent/referer，data 包裹也认；源站 header 只补没有的键），随 Ok 一起带出；
# 曲库 playTrack 把头传进 LxPlayerManager.play()（headers 参数，21 v56 接）；切歌/自动下一首走 21 v55 的 resolveAndPlay，同样带头（21 v56 改）
path = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicBridge.kt"
src = open(path, encoding="utf-8").read()
if "// [46v27]" in src:
    print("bridge already 46v27, skip")
    sys.exit(0)

def rep(old, new, tag):
    global src
    assert src.count(old) == 1, "%s anchor %d" % (tag, src.count(old))
    src = src.replace(old, new, 1)

# 1) Ok 带头返回（默认空 map，老调用点不用改）
rep(
    "        data class Ok(val url: String) : PlayResult",
    "        data class Ok(val url: String, val headers: Map<String, String> = emptyMap()) : PlayResult // [46v27] 订阅带头播放：playerContent 返回的头一起带出",
    "ok-with-headers",
)

# 2) resolvePlay 之前插入 extractPlayHeaders
rep(
    "    suspend fun resolvePlay(track: SubTrack): PlayResult = withContext(Dispatchers.IO) {",
    """    // [46v27] 订阅带头播放：取 playerContent 返回里的头（主体 PlayUrlResolver.jsonParse＋mergeSiteHeaders 口径：结果里的 header/headers 对象＋user-agent/referer，data 包裹也认；源站 header 只补没有的键）
    private fun extractPlayHeaders(pj: JSONObject, siteHeader: Map<String, String>?): Map<String, String> {
        val map = LinkedHashMap<String, String>()
        val data = pj.optJSONObject("data")
        for (o in listOf(pj, data)) {
            if (o == null) continue
            val h = o.optJSONObject("header") ?: o.optJSONObject("headers")
            if (h != null) {
                val keys = h.keys()
                while (keys.hasNext()) {
                    val k = keys.next()
                    val v = h.optString(k)
                    if (v.isNotBlank()) map[k] = v
                }
            }
            val ua = o.optString("user-agent")
            if (ua.isNotBlank()) map["User-Agent"] = ua
            val ref = o.optString("referer")
            if (ref.isNotBlank()) map["Referer"] = ref
        }
        siteHeader?.forEach { (k, v) -> if (!map.containsKey(k) && v.isNotBlank()) map[k] = v }
        return map
    }

    suspend fun resolvePlay(track: SubTrack): PlayResult = withContext(Dispatchers.IO) {""",
    "insert-extractPlayHeaders",
)

# 3) resolvePlay 返回带头
rep(
    "            PlayResult.Ok(url)",
    "            PlayResult.Ok(url, extractPlayHeaders(pj, bean.header)) // [46v27] 带头返回",
    "ok-return-headers",
)

# 后验：标记在位，括号平衡，标记注释不吞码
assert src.count("[46v27]") >= 3
assert src.count("(") - src.count(")") == 0
assert src.count("{") - src.count("}") == 0
assert src.count("[") - src.count("]") == 0
for line in src.splitlines():
    if "// [46v27]" in line:
        after = line.split("// [46v27]", 1)[1]
        assert "{" not in after and "}" not in after and "(" not in after and ")" not in after and "," not in after, "comment-eaten: %s" % line
open(path, "w", encoding="utf-8").write(src)
print("patched 46v27 bridge")

PYEOF46V27
python3 /tmp/patch_screen46v27.py
grep -q "46v27" avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicBridge.kt || { echo "X 46v27 bridge"; exit 1; }
echo "OK 46v27 bridge"

cat > /tmp/patch_screen46v27b.py << 'PYEOF46V27B'
import sys

# 46 v27（曲库屏）：playTrack 把桥接返回的头传进播放器
path = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicScreen.kt"
src = open(path, encoding="utf-8").read()
if "// [46v27]" in src:
    print("screen already 46v27, skip")
    sys.exit(0)

def rep(old, new, tag):
    global src
    assert src.count(old) == 1, "%s anchor %d" % (tag, src.count(old))
    src = src.replace(old, new, 1)

rep(
    "                    LxPlayerManager.play(r.url, track.title, track.sourceName, track.pic)",
    "                    LxPlayerManager.play(r.url, track.title, track.sourceName, track.pic, headers = r.headers) // [46v27] 订阅带头播放",
    "playTrack-headers",
)

assert src.count("[46v27]") >= 1
assert src.count("(") - src.count(")") == 0
assert src.count("{") - src.count("}") == 0
assert src.count("[") - src.count("]") == 0
for line in src.splitlines():
    if "// [46v27]" in line:
        after = line.split("// [46v27]", 1)[1]
        assert "{" not in after and "}" not in after and "(" not in after and ")" not in after and "," not in after, "comment-eaten: %s" % line
open(path, "w", encoding="utf-8").write(src)
print("patched 46v27 screen")

PYEOF46V27B
python3 /tmp/patch_screen46v27b.py
grep -q "46v27" avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicScreen.kt || { echo "X 46v27 screen"; exit 1; }
echo "OK 46v27 screen"
echo "=== 46 v27 done ==="

echo "=== 46 v28 ==="
cat > /tmp/patch_screen46v28.py << 'PYEOF46V28'
import sys

# 46 v28（桥接）：详情封面回填——列表条目常不带 vod_pic（歌手卡全是首字占位），详情对象里一般有 vod_pic（跟播放地址同一个对象）；
# 修法：detailEpisodes 顺带把详情 vod_pic 带回来（分集封面＝列表图，没有就用详情图）；episodeCache 一并存封面（flag to 播放 id 列表 to 详情封面），
# resolvePlay 经缓存命中也能拿到封面，随 Ok 一起带出（Ok 加 pic 字段，默认空串）；不多花一次请求。配 21 v57（切歌也用详情封面）
path = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicBridge.kt"
src = open(path, encoding="utf-8").read()
if "[46v28]" in src: # [46v28] 守卫用裸标记：多处标记写作 [46v27][46v28] 连写，"// [46v28]" 子串匹配不到
    print("bridge already 46v28, skip")
    sys.exit(0)

def rep(old, new, tag):
    global src
    assert src.count(old) == 1, "%s anchor %d" % (tag, src.count(old))
    src = src.replace(old, new, 1)

# 1) Ok 带详情封面
rep(
    "        data class Ok(val url: String, val headers: Map<String, String> = emptyMap()) : PlayResult // [46v27] 订阅带头播放：playerContent 返回的头一起带出",
    "        data class Ok(val url: String, val headers: Map<String, String> = emptyMap(), val pic: String = \"\") : PlayResult // [46v27][46v28] 订阅带头播放＋详情封面：Ok 带头与详情 vod_pic 一起返回",
    "ok-with-pic",
)

# 2) episodeCache 一并存封面
rep(
    "    private val episodeCache = mutableMapOf<String, Pair<String, List<String>>>() // [46v22] 详情只拉一次：key = 源:条目 id，value = flag to 播放 id 列表",
    "    private val episodeCache = mutableMapOf<String, Triple<String, List<String>, String>>() // [46v22][46v28] 详情只拉一次：key = 源:条目 id，value = flag to 播放 id 列表 to 详情封面",
    "cache-with-pic",
)

# 3) detailEpisodes 整函数换：返回 (分集列表，详情封面)，分集封面＝列表图，没有就用详情图
rep(
    """    suspend fun detailEpisodes(track: SubTrack): List<SubTrack> = withContext(Dispatchers.IO) { // [46v22] 详情拆全部分集（点卡进歌单用）
        try {
            val baseId = track.id.substringBefore("#")
            val bean = ApiConfig.get().getSource(track.sourceKey) ?: return@withContext emptyList()
            val sp = ApiConfig.get().getCSP(bean)
            val detail = sp.detailContent(listOf(baseId)) ?: return@withContext emptyList()
            val d = JSONObject(detail)
            val item = d.optJSONArray("list")?.optJSONObject(0) ?: d
            val parts = parsePlayParts(item) ?: return@withContext emptyList()
            val key = track.sourceKey + ":" + baseId
            if (episodeCache.size > 20) episodeCache.clear()
            episodeCache[key] = parts.flag to parts.playIds
            parts.playIds.mapIndexed { i, _ ->
                val name = parts.names.getOrNull(i)?.takeIf { it.isNotBlank() } ?: (track.title + " " + (i + 1))
                SubTrack(track.sourceKey, track.sourceName, baseId + "#" + i, name, track.pic, "", track.title)
            }
        } catch (e: Exception) {
            emptyList()
        }
    }""",
    """    suspend fun detailEpisodes(track: SubTrack): Pair<List<SubTrack>, String> = withContext(Dispatchers.IO) { // [46v22][46v28] 详情拆全部分集＋详情封面（点卡进歌单用）
        try {
            val baseId = track.id.substringBefore("#")
            val bean = ApiConfig.get().getSource(track.sourceKey) ?: return@withContext (emptyList() to "")
            val sp = ApiConfig.get().getCSP(bean)
            val detail = sp.detailContent(listOf(baseId)) ?: return@withContext (emptyList() to "")
            val d = JSONObject(detail)
            val item = d.optJSONArray("list")?.optJSONObject(0) ?: d
            val parts = parsePlayParts(item) ?: return@withContext (emptyList() to "")
            val detailPic = item.optString("vod_pic") // [46v28] 详情封面：跟播放地址同一个对象里
            val key = track.sourceKey + ":" + baseId
            if (episodeCache.size > 20) episodeCache.clear()
            episodeCache[key] = Triple(parts.flag, parts.playIds, detailPic)
            parts.playIds.mapIndexed { i, _ ->
                val name = parts.names.getOrNull(i)?.takeIf { it.isNotBlank() } ?: (track.title + " " + (i + 1))
                SubTrack(track.sourceKey, track.sourceName, baseId + "#" + i, name, track.pic.ifBlank { detailPic }, "", track.title)
            } to detailPic
        } catch (e: Exception) {
            emptyList() to ""
        }
    }""",
    "detailEpisodes-with-pic",
)

# 4) resolvePlay：parts 改 Triple（缓存命中也有封面）
rep(
    "            val parts: Pair<String, List<String>>",
    "            val parts: Triple<String, List<String>, String>",
    "resolvePlay-parts-triple",
)

# 5) resolvePlay 未命中时存封面
rep(
    "                parts = pp.flag to pp.playIds",
    "                parts = Triple(pp.flag, pp.playIds, item.optString(\"vod_pic\"))",
    "resolvePlay-store-pic",
)

# 6) resolvePlay 返回带封面
rep(
    "            PlayResult.Ok(url, extractPlayHeaders(pj, bean.header)) // [46v27] 带头返回",
    "            PlayResult.Ok(url, headers = extractPlayHeaders(pj, bean.header), pic = parts.third) // [46v27][46v28] 带头返回＋详情封面",
    "ok-return-pic",
)

# 后验：标记在位，括号平衡，标记注释不吞码
assert src.count("[46v28]") >= 5
assert src.count("(") - src.count(")") == 0
assert src.count("{") - src.count("}") == 0
assert src.count("[") - src.count("]") == 0
for line in src.splitlines():
    if "// [46v28]" in line:
        after = line.split("// [46v28]", 1)[1]
        assert "{" not in after and "}" not in after and "(" not in after and ")" not in after and "," not in after, "comment-eaten: %s" % line
open(path, "w", encoding="utf-8").write(src)
print("patched 46v28 bridge")

PYEOF46V28
python3 /tmp/patch_screen46v28.py
grep -q "46v28" avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicBridge.kt || { echo "X 46v28 bridge"; exit 1; }
echo "OK 46v28 bridge"

cat > /tmp/patch_screen46v28b.py << 'PYEOF46V28B'
import sys

# 46 v28（曲库屏）：详情封面回填到卡片与播放页——点卡一次就把详情 vod_pic 存进 picOverrides（key = 源:条目 id 去 #），
# 四处卡片（搜索/分集/钻入/推荐）统一走 picOf（回填优先、列表原图次之）；点播时封面＝picOf，没有再用 resolvePlay 返回的详情封面
path = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicScreen.kt"
src = open(path, encoding="utf-8").read()
if "[46v28]" in src: # [46v28] 守卫用裸标记：多处标记写作 [46v27][46v28] 连写，"// [46v28]" 子串匹配不到
    print("screen already 46v28, skip")
    sys.exit(0)

def rep(old, new, tag):
    global src
    assert src.count(old) == 1, "%s anchor %d" % (tag, src.count(old))
    src = src.replace(old, new, 1)

def repAll(old, new, tag, n):
    global src
    assert src.count(old) == n, "%s anchor %d" % (tag, src.count(old))
    src = src.replace(old, new)

# 1) 回填状态：key = 源:条目 id（去 #），value = 详情的 vod_pic
rep(
    "    var sectionsKey by remember { mutableStateOf<String?>(null) } // [46v23] 分段已拉的源 key（换源重拉，同源不重拉）",
    "    var sectionsKey by remember { mutableStateOf<String?>(null) } // [46v23] 分段已拉的源 key（换源重拉，同源不重拉）\n    var picOverrides by remember { mutableStateOf<Map<String, String>>(emptyMap()) } // [46v28] 详情封面回填：key = 源:条目 id（去 #），value = 详情的 vod_pic",
    "picOverrides-state",
)

# 2) picOf：回填优先，列表原图次之
rep(
    "    fun doSearch() { // [46v21] 曲库内搜：搜当前源（同 SubSearchScreen 的 searchInSource 链）",
    """    fun picOf(track: SubMusicBridge.SubTrack): String { // [46v28] 卡片封面：详情回填优先，列表原图次之
        return picOverrides[track.sourceKey + ":" + track.id.substringBefore("#")] ?: track.pic
    }

    fun doSearch() { // [46v21] 曲库内搜：搜当前源（同 SubSearchScreen 的 searchInSource 链）""",
    "picOf-helper",
)

# 3) 点播封面：picOf，没有再用 resolvePlay 返回的详情封面
rep(
    "                    LxPlayerManager.play(r.url, track.title, track.sourceName, track.pic, headers = r.headers) // [46v27] 订阅带头播放",
    "                    LxPlayerManager.play(r.url, track.title, track.sourceName, picOf(track).ifBlank { r.pic }, headers = r.headers) // [46v27][46v28] 订阅带头播放＋详情封面",
    "playTrack-pic",
)

# 4) openItem：点卡一次就把详情封面存进回填表（单集直接播也存，列表卡照样回填）
rep(
    """            val eps = SubMusicBridge.detailEpisodes(track)
            if (eps.size > 1) {""",
    """            val (eps, detailPic) = SubMusicBridge.detailEpisodes(track) // [46v28] 详情封面回填：点卡一次就把详情 vod_pic 带回来
            if (detailPic.isNotBlank()) {
                val key = track.sourceKey + ":" + track.id.substringBefore("#")
                picOverrides = picOverrides + (key to detailPic)
            }
            if (eps.size > 1) {""",
    "openItem-store-pic",
)

# 5) 四处卡片统一走 picOf（搜索/分集/钻入/推荐）
repAll("pic = track.pic", "pic = picOf(track)", "cards-picOf", 4)

assert src.count("[46v28]") >= 4
assert src.count("(") - src.count(")") == 0
assert src.count("{") - src.count("}") == 0
assert src.count("[") - src.count("]") == 0
for line in src.splitlines():
    if "// [46v28]" in line:
        after = line.split("// [46v28]", 1)[1]
        assert "{" not in after and "}" not in after and "(" not in after and ")" not in after and "," not in after, "comment-eaten: %s" % line
open(path, "w", encoding="utf-8").write(src)
print("patched 46v28 screen")

PYEOF46V28B
python3 /tmp/patch_screen46v28b.py
grep -q "46v28" avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicScreen.kt || { echo "X 46v28 screen"; exit 1; }
echo "OK 46v28 screen"
echo "=== 46 v28 done ==="

echo "=== 46 v29 ==="
cat > /tmp/patch_screen46v29.py << 'PYEOF46V29'
import sys

# 46 v29（构建红修复，两处都是 v28 留下的）：
# ① resolvePlay 未命中分支：episodeCache 存的还是 Pair（pp.flag to pp.playIds），缓存类型已改 Triple，漏改这一行→269:37 Argument type mismatch；
# ② detailEpisodes 的 (emptyList() to "") 推不出类型：to 是双泛型中缀函数，期望类型 Pair<List<SubTrack>, String> 流不回 emptyList 的元素类型 T，
#    也流不回 to 自身的 A，致 202/205/207/210/220 五处 Cannot infer type（202 是 withContext 的 T，级联）；v22 原版只写 emptyList() 能推，是因期望类型直达。
#    修法：四处全写死 emptyList<SubTrack>()。仿真不编译 Kotlin，抓不出这类错（同 v24 教训）
path = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicBridge.kt"
src = open(path, encoding="utf-8").read()
if "[46v29]" in src:
    print("bridge already 46v29, skip")
    sys.exit(0)

def rep(old, new, tag):
    global src
    assert src.count(old) == 1, "%s anchor %d" % (tag, src.count(old))
    src = src.replace(old, new, 1)

def repAll(old, new, tag, n):
    global src
    assert src.count(old) == n, "%s anchor %d" % (tag, src.count(old))
    src = src.replace(old, new)

# 1) 签名行补版本标记（其余改动行不便插注释，此处留痕）
rep(
    "    suspend fun detailEpisodes(track: SubTrack): Pair<List<SubTrack>, String> = withContext(Dispatchers.IO) { // [46v22][46v28] 详情拆全部分集＋详情封面（点卡进歌单用）",
    "    suspend fun detailEpisodes(track: SubTrack): Pair<List<SubTrack>, String> = withContext(Dispatchers.IO) { // [46v22][46v28][46v29] 详情拆全部分集＋详情封面（点卡进歌单用）",
    "signature-marker",
)

# 2) 三处提前返回：写死元素类型
repAll("return@withContext (emptyList() to \"\")", "return@withContext (emptyList<SubTrack>() to \"\")", "early-returns-typed", 3)

# 3) catch：写死元素类型
rep(
    "            emptyList() to \"\"",
    "            emptyList<SubTrack>() to \"\"",
    "catch-typed",
)

# 4) resolvePlay 未命中分支：缓存存 Triple（漏改行）
rep(
    "                episodeCache[key] = pp.flag to pp.playIds",
    "                episodeCache[key] = Triple(pp.flag, pp.playIds, item.optString(\"vod_pic\")) // [46v29] 构建红修复：缓存存 Triple，Pair 塞不进去",
    "cache-store-triple",
)

# 后验：标记在位，括号平衡，标记注释不吞码；确认无残留 Pair 存法与无类型 emptyList
assert src.count("[46v29]") >= 2
assert src.count("pp.flag to pp.playIds") == 0
assert src.count("emptyList() to") == 0
assert src.count("(") - src.count(")") == 0
assert src.count("{") - src.count("}") == 0
assert src.count("[") - src.count("]") == 0
for line in src.splitlines():
    if "// [46v29]" in line:
        after = line.split("// [46v29]", 1)[1]
        assert "{" not in after and "}" not in after and "(" not in after and ")" not in after and "," not in after, "comment-eaten: %s" % line
open(path, "w", encoding="utf-8").write(src)
print("patched 46v29 bridge")

PYEOF46V29
python3 /tmp/patch_screen46v29.py
grep -q "46v29" avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicBridge.kt || { echo "X 46v29 bridge"; exit 1; }
echo "OK 46v29 bridge"
echo "=== 46 v29 done ==="

echo "=== 46 v30 ==="
cat > /tmp/patch_screen46v30.py << 'PYEOF46V30'
import sys

# 46 v30（曲库屏）：点歌防串——订阅解析慢（裸 play 无预取，每首现取详情＋地址），点歌后 1~3 秒才出声，用户常连点第二首；
# playTrack/openItem 原先各起一个无 guard 的协程，先点的解析慢回包、后点的解析先回包，最后执行的 play() 获胜——不是最后点的获胜，
# 先点的歌会盖掉后点的歌，放的歌和点的歌不一样。修法：点歌取号（playReq 单调递增），只认最新一号的解析结果，过期的直接丢弃、不播也不改提示；
# 队列是同步赋值的（点即换队），本来就是最后点的获胜，只乱序回包要堵。配 21 v58（切歌那边同款问题）
path = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicScreen.kt"
src = open(path, encoding="utf-8").read()
if "[46v30]" in src:
    print("screen already 46v30, skip")
    sys.exit(0)

def rep(old, new, tag):
    global src
    assert src.count(old) == 1, "%s anchor %d" % (tag, src.count(old))
    src = src.replace(old, new, 1)

# 1) 取号状态：与 picOverrides 同处
rep(
    "    var picOverrides by remember { mutableStateOf<Map<String, String>>(emptyMap()) } // [46v28] 详情封面回填：key = 源:条目 id（去 #），value = 详情的 vod_pic",
    "    var picOverrides by remember { mutableStateOf<Map<String, String>>(emptyMap()) } // [46v28] 详情封面回填：key = 源:条目 id（去 #），value = 详情的 vod_pic\n    var playReq by remember { mutableStateOf(0) } // [46v30] 点歌防串：每次点歌取号，只认最新一号的解析结果，订阅解析慢、连点会乱序回包",
    "playReq-state",
)

# 2) playTrack：取号，过期结果丢弃
rep(
    """    fun playTrack(track: SubMusicBridge.SubTrack, list: List<SubMusicBridge.SubTrack>) { // [46v12] 点卡片建队列：当前页从点中那首起
        notice = "正在取播放地址…"
        val maps = SubMusicBridge.toQueueMaps(list)
        val idx = list.indexOfFirst { it.sourceKey == track.sourceKey && it.id == track.id }.takeIf { it >= 0 } ?: 0
        LxPlayerManager.playQueue = maps
        LxPlayerManager.queueIndex = idx
        scope.launch {
            when (val r = SubMusicBridge.resolvePlay(track)) {""",
    """    fun playTrack(track: SubMusicBridge.SubTrack, list: List<SubMusicBridge.SubTrack>) { // [46v12] 点卡片建队列：当前页从点中那首起
        val myReq = ++playReq
        notice = "正在取播放地址…"
        val maps = SubMusicBridge.toQueueMaps(list)
        val idx = list.indexOfFirst { it.sourceKey == track.sourceKey && it.id == track.id }.takeIf { it >= 0 } ?: 0
        LxPlayerManager.playQueue = maps
        LxPlayerManager.queueIndex = idx
        scope.launch {
            val r = SubMusicBridge.resolvePlay(track)
            if (myReq != playReq) return@launch // [46v30] 已被更新的点歌取代，不播不改提示
            when (r) {""",
    "playTrack-guard",
)

# 3) openItem：取号，过期结果丢弃（单集进 playTrack 时 playTrack 自己再取一号）
rep(
    """    fun openItem(track: SubMusicBridge.SubTrack, list: List<SubMusicBridge.SubTrack>) { // [46v22] 点卡探详情：多集进列表，单集直接播
        notice = "正在取详情…"
        scope.launch {
            val (eps, detailPic) = SubMusicBridge.detailEpisodes(track) // [46v28] 详情封面回填：点卡一次就把详情 vod_pic 带回来""",
    """    fun openItem(track: SubMusicBridge.SubTrack, list: List<SubMusicBridge.SubTrack>) { // [46v22] 点卡探详情：多集进列表，单集直接播
        val myReq = ++playReq
        notice = "正在取详情…"
        scope.launch {
            val (eps, detailPic) = SubMusicBridge.detailEpisodes(track) // [46v28] 详情封面回填：点卡一次就把详情 vod_pic 带回来
            if (myReq != playReq) return@launch // [46v30] 已被更新的点歌取代，不改列表""",
    "openItem-guard",
)

# 后验：标记在位，括号平衡，标记注释不吞码
assert src.count("[46v30]") >= 3
assert src.count("(") - src.count(")") == 0
assert src.count("{") - src.count("}") == 0
assert src.count("[") - src.count("]") == 0
for line in src.splitlines():
    if "// [46v30]" in line:
        after = line.split("// [46v30]", 1)[1]
        assert "{" not in after and "}" not in after and "(" not in after and ")" not in after and "," not in after, "comment-eaten: %s" % line
open(path, "w", encoding="utf-8").write(src)
print("patched 46v30 screen")

PYEOF46V30
python3 /tmp/patch_screen46v30.py
grep -q "46v30" avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicScreen.kt || { echo "X 46v30 screen"; exit 1; }
echo "OK 46v30 screen"
echo "=== 46 v30 done ==="

echo "=== 46 v31 ==="
cat > /tmp/patch_player46v31.py << 'PYEOF46V31'
import sys

# 46 v31（播放页回调）：playSongFromQueue 是播放页（LxPlayerActivity）给管理器挂的回调，切歌/自动下一首/开播失败回落都走它；
# 但它的订阅分支（46 v12 加的）一直没跟上 21 v56/v57：play() 没传 headers（源站挡 UA、无头就报网络异常），封面只用 t.pic（不认 r.pic 的详情封面），
# 也没有 21 v58 的取号防串。后果：曲库点歌（playTrack，走管理器、有头）能播的歌，一进播放页切歌/自动下一首就掉回无头播放、又报网络异常；
# 连点切歌时旧解析也可能盖回。修法：与管理器 resolveAndPlay 订阅分支对齐——带头、封面回落、取号防串
path = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt"
src = open(path, encoding="utf-8").read()
if "[46v31]" in src:
    print("player already 46v31, skip")
    sys.exit(0)

def rep(old, new, tag):
    global src
    assert src.count(old) == 1, "%s anchor %d" % (tag, src.count(old))
    src = src.replace(old, new, 1)

# 1) 取号字段：playSongFromQueue 是 Activity 成员函数，字段放它前面（类成员位）
rep(
    "    private fun playSongFromQueue(song: Map<String, String>) {",
    "    private var subPlayReq = 0 // [46v31] 播放页回调防串：只认最新一次切歌的解析结果\n    private fun playSongFromQueue(song: Map<String, String>) {",
    "subPlayReq-field",
)

# 2) 订阅分支：取号、过期丢弃、带头＋详情封面
rep(
    """        if (song["sub"] == "1") { // [46v12] 订阅条目走桥接解析，不走落雪链
            val t = SubMusicBridge.trackFromMap(song) ?: return
            LxPlayerManager.setLoading(true)
            Thread {
                try {
                    val r = kotlinx.coroutines.runBlocking { SubMusicBridge.resolvePlay(t) }
                    if (r is SubMusicBridge.PlayResult.Ok) {
                        runOnUiThread { LxPlayerManager.play(r.url, t.title, t.sourceName, t.pic); LxPlayerManager.setLoading(false) }""",
    """        if (song["sub"] == "1") { // [46v12] 订阅条目走桥接解析，不走落雪链
            val t = SubMusicBridge.trackFromMap(song) ?: return
            val myReq = ++subPlayReq // [46v31] 切歌取号
            LxPlayerManager.setLoading(true)
            Thread {
                try {
                    val r = kotlinx.coroutines.runBlocking { SubMusicBridge.resolvePlay(t) }
                    if (myReq != subPlayReq) return@Thread // [46v31] 已被更新的切歌取代，不播
                    if (r is SubMusicBridge.PlayResult.Ok) {
                        runOnUiThread { LxPlayerManager.play(r.url, t.title, t.sourceName, t.pic.ifBlank { r.pic }, headers = r.headers); LxPlayerManager.setLoading(false) } // [46v31] 回调解析也带头＋详情封面""",
    "callback-guard-headers",
)

# 后验：标记在位，括号平衡，标记注释不吞码
assert src.count("[46v31]") >= 4
assert src.count("(") - src.count(")") == 0
assert src.count("{") - src.count("}") == 0
assert src.count("[") - src.count("]") == 0
for line in src.splitlines():
    if "// [46v31]" in line:
        after = line.split("// [46v31]", 1)[1]
        assert "{" not in after and "}" not in after and "(" not in after and ")" not in after and "," not in after, "comment-eaten: %s" % line
open(path, "w", encoding="utf-8").write(src)
print("patched 46v31 player")

PYEOF46V31
python3 /tmp/patch_player46v31.py
grep -q "46v31" avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt || { echo "X 46v31 player"; exit 1; }
echo "OK 46v31 player"
echo "=== 46 v31 done ==="

echo "=== 46 v32 ==="
cat > /tmp/patch_bridge46v32.py << 'PYEOF46V32'
import sys

# 46 v32（诊断，临时）：初心源播错歌——用户实测只有初心这样，别源正常；歌单名是对的、音频全不是该歌手的，
# 说明错在取地址层（resolvePlay 回来的 URL 不是该集的），不是防串。根因待定：可能是初心详情的 vod_play_url 里
# 名字与地址本来就错位，也可能是第一组 $$$ 不是音乐组、也可能是 playerContent 对 playId 回了别的歌。
# 修法先不猜：把原始分集映射和取址结果写进运行日志（设置源管理里的日志抽屉能看到），点一次陈奕迅的歌、截一张日志图，
# 就能钉死是源数据错位、还是解析错位、还是取址错位。诊断完可随时删这两行日志
path = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicBridge.kt"
src = open(path, encoding="utf-8").read()
if "[46v32]" in src:
    print("bridge already 46v32, skip")
    sys.exit(0)

def rep(old, new, tag):
    global src
    assert src.count(old) == 1, "%s anchor %d" % (tag, src.count(old))
    src = src.replace(old, new, 1)

# 1) 导运行日志（与管理器同款 import，用法同款 try 包裹）
rep(
    "import org.json.JSONObject",
    "import org.json.JSONObject\nimport com.github.tvbox.osc.util.LxRuntimeLog // [46v32] 诊断：分集映射与取址结果写运行日志",
    "runtime-log-import",
)

# 2) parsePlayParts：详情解析完就记一笔——条目名、线路 flag、共几集、前 3 组“名=>地址 id”
rep(
    "        return PlayParts(flag, pairs.map { it.first }, pairs.map { it.second })",
    "        try { LxRuntimeLog.add(\"[46v32] 分集 \" + item.optString(\"vod_name\").take(20) + \" flag=\" + flag + \" 共\" + pairs.size + \"集：\" + pairs.take(3).joinToString(\" | \") { it.first.take(12) + \"=>\" + it.second.take(24) }) } catch (_: Exception) { } // [46v32] 诊断：原始分集映射\n        return PlayParts(flag, pairs.map { it.first }, pairs.map { it.second })",
    "parsePlayParts-log",
)

# 3) resolvePlay：取到地址后记一笔——点的歌名、集号、用的 playId、地址尾巴
rep(
    '            PlayResult.Ok(url, headers = extractPlayHeaders(pj, bean.header), pic = parts.third) // [46v27][46v28] 带头返回＋详情封面',
    '            try { LxRuntimeLog.add("[46v32] 取址 " + track.title.take(12) + " #" + wantIdx + " playId=" + playId.take(24) + " url尾=" + url.takeLast(48)) } catch (_: Exception) { } // [46v32] 诊断：取址结果\n            PlayResult.Ok(url, headers = extractPlayHeaders(pj, bean.header), pic = parts.third) // [46v27][46v28] 带头返回＋详情封面',
    "resolvePlay-log",
)

# 后验：标记在位，括号平衡，标记注释不吞码
assert src.count("[46v32]") >= 4
assert src.count("(") - src.count(")") == 0
assert src.count("{") - src.count("}") == 0
assert src.count("[") - src.count("]") == 0
for line in src.splitlines():
    if "// [46v32]" in line:
        after = line.split("// [46v32]", 1)[1]
        assert "{" not in after and "}" not in after and "(" not in after and ")" not in after and "," not in after, "comment-eaten: %s" % line
open(path, "w", encoding="utf-8").write(src)
print("patched 46v32 bridge")

PYEOF46V32
python3 /tmp/patch_bridge46v32.py
grep -q "46v32" avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicBridge.kt || { echo "X 46v32 bridge"; exit 1; }
echo "OK 46v32 bridge"
echo "=== 46 v32 done ==="

echo "=== 46 v33 ==="
cat > /tmp/patch_bridge46v33.py << 'PYEOF46V33'
import sys

# 46 v33：头收敛到主体口径——主体 SourceHelper.extractPlayHeaders 只读结果里 header/headers 对象（对象或 JSON 文本都认），
# 不读顶层 user-agent/referer、不看 data 包裹；我们 v27 多读了顶层 user-agent/referer＋data 包裹，等于比主体多发一个 Referer，
# 若那个 Referer 不对、反而会被源站挡（DJ 歌 HQ·497kbps 仍网络异常的嫌疑之一；主体用更少的头能播）。修法：只读 header/headers 对象，
# 对象或 JSON 文本都认（与主体 appendJsonHeaders 同款）；源站 header 仍只补没有的键；UA 不动（仍走 v56 浏览器 UA 回落，探针已证能通）
path = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicBridge.kt"
src = open(path, encoding="utf-8").read()
if "[46v33]" in src:
    print("bridge already 46v33, skip")
    sys.exit(0)

def rep(old, new, tag):
    global src
    assert src.count(old) == 1, "%s anchor %d" % (tag, src.count(old))
    src = src.replace(old, new, 1)

# 1) 函数头注释改口径（v27 的旧口径已作废）
rep(
    "    // [46v27] 订阅带头播放：取 playerContent 返回里的头（主体 PlayUrlResolver.jsonParse＋mergeSiteHeaders 口径：结果里的 header/headers 对象＋user-agent/referer，data 包裹也认；源站 header 只补没有的键）",
    "    // [46v27][46v33] 订阅带头播放：取 playerContent 返回里的头（主体 SourceHelper.extractPlayHeaders＋mergeSiteHeaders 口径：只读 header/headers 对象，对象或 JSON 文本都认；源站 header 只补没有的键；顶层 user-agent/referer 与 data 包裹不再读）",
    "header-comment",
)

# 2) 取头逻辑收敛：只读 pj 的 header/headers 对象（或 JSON 文本），不再读 data 包裹与顶层 user-agent/referer
rep(
    """        val map = LinkedHashMap<String, String>()
        val data = pj.optJSONObject("data")
        for (o in listOf(pj, data)) {
            if (o == null) continue
            val h = o.optJSONObject("header") ?: o.optJSONObject("headers")
            if (h != null) {
                val keys = h.keys()
                while (keys.hasNext()) {
                    val k = keys.next()
                    val v = h.optString(k)
                    if (v.isNotBlank()) map[k] = v
                }
            }
            val ua = o.optString("user-agent")
            if (ua.isNotBlank()) map["User-Agent"] = ua
            val ref = o.optString("referer")
            if (ref.isNotBlank()) map["Referer"] = ref
        }""",
    """        val map = LinkedHashMap<String, String>()
        for (key in listOf("header", "headers")) { // [46v33] 只读 header/headers 对象，与主体 extractPlayHeaders 同口径；顶层 user-agent/referer 与 data 包裹不再读
            val raw = pj.opt(key)
            if (raw == null || raw === JSONObject.NULL) continue
            val h = when (raw) {
                is JSONObject -> raw
                is String -> try { JSONObject(raw) } catch (_: Exception) { null }
                else -> null
            } ?: continue
            val keys = h.keys()
            while (keys.hasNext()) {
                val k = keys.next()
                val v = h.optString(k)
                if (v.isNotBlank()) map[k] = v
            }
        }""",
    "extract-headers-converge",
)

# 后验：标记在位，括号平衡，标记注释不吞码
assert src.count("[46v33]") >= 2
assert src.count("(") - src.count(")") == 0
assert src.count("{") - src.count("}") == 0
assert src.count("[") - src.count("]") == 0
for line in src.splitlines():
    if "// [46v33]" in line:
        after = line.split("// [46v33]", 1)[1]
        assert "{" not in after and "}" not in after and "(" not in after and ")" not in after and "," not in after, "comment-eaten: %s" % line
open(path, "w", encoding="utf-8").write(src)
print("patched 46v33 bridge")

PYEOF46V33
python3 /tmp/patch_bridge46v33.py
grep -q "46v33" avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/SubMusicBridge.kt || { echo "X 46v33 bridge"; exit 1; }
echo "OK 46v33 bridge"
echo "=== 46 v33 done ==="
