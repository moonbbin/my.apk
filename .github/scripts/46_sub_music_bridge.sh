#!/bin/bash
set -e
cd "$(dirname "$0")/../.." 2>/dev/null || true

# === 46 v6: 订阅源内音乐桥接（修 v5 两处注释吞码：40 在枚举末行留了 // [40rec]，v5 往行尾追 SUBMUSIC 被注释吃掉致编译报 SUBMUSIC 未解析；签名行尾的 // [46v6] 吃掉了 { 致 MusicSettingsList 无函数体；v6 枚举改为注释前插入、签名标记移到 { 之后，并加注释吞码后验） ===

echo "=== 46 v6 ==="

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
                ?: return@withContext Fail("源已不存在")
            val sp = ApiConfig.get().getCSP(bean)
            val detail = sp.detailContent(listOf(track.id))
                ?: return@withContext Fail("详情为空")
            val d = JSONObject(detail)
            val item = d.optJSONArray("list")?.optJSONObject(0) ?: d
            val from = item.optString("vod_play_from")
            val urls = item.optString("vod_play_url")
            if (from.isBlank() || urls.isBlank()) return@withContext Fail("该条目无播放地址")
            val flag = from.split("$$$")[0]
            val firstGroup = urls.split("$$$")[0]
            val firstEp = firstGroup.split("#")[0]
            val playId = firstEp.substringAfter("$", firstEp)
            val pr = sp.playerContent(flag, playId, ApiConfig.get().getVipParseFlags())
                ?: return@withContext Fail("取播放地址失败")
            val pj = JSONObject(pr)
            val parse = pj.optInt("parse", 0)
            val url = pj.optString("url")
            if (url.isBlank()) return@withContext Fail("播放地址为空")
            if (parse == 1) return@withContext Fail("该源需要解析，源内音乐 v1 暂不支持解析播放")
            Ok(url)
        } catch (e: Exception) {
            Fail("播放失败：${e.message}")
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

echo "=== 46 v6 done ==="
