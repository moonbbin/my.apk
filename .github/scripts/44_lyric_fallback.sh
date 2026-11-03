#!/bin/bash
# 44_lyric_fallback.sh
# 播放页歌词跨平台兜底（35 后补丁）：本平台取空后，按歌名+歌手在其他平台搜一次，精确匹配才取词
set -e
cd "$(dirname "$0")/../.." 2>/dev/null || true
PA="avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt"

if grep -q "fetchLyricFallback" "$PA" 2>/dev/null; then
  echo "跳过（44v1 歌词兜底已写入）"
  exit 0
fi

python3 << 'PYEOF'
import sys

path = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt"
with open(path, encoding="utf-8") as f:
    src = f.read()

MARK = "// [44v1]"
if MARK in src:
    print("skip: 44v1 already present")
    sys.exit(0)


def rep(old, new, cnt=1):
    global src
    assert src.count(old) == cnt, f"anchor count {src.count(old)}: {old[:70]!r}"
    src = src.replace(old, new, cnt)


# 1. import withTimeoutOrNull（独占一行，44v1 前该文件无此 import）
rep(
    "import kotlinx.coroutines.withContext",
    "import kotlinx.coroutines.withContext\nimport kotlinx.coroutines.withTimeoutOrNull  // [44v1]",
)

# 2. 兜底函数：放在 fetchWyLyric 之前
helper = """// [44v1] 歌词跨平台兜底：本平台取空后，按歌名+歌手在其他平台搜一次，精确匹配才取词
private suspend fun fetchLyricFallback(title: String, artist: String, excludePlat: String): List<LyricLine> {
    return try {
        val norm = { s: String -> s.replace("\\\\s+".toRegex(), "").lowercase() }
        val candidates = withTimeoutOrNull(20000) { LxMusicSearchApi.searchFull(title) } ?: emptyList()
        val order = listOf("wy", "tx", "kg", "kw", "mg").filter { it != excludePlat }
        for (plat in order) {
            val hit = candidates.firstOrNull { c ->
                c.platform == plat && norm(c.title) == norm(title) &&
                    (norm(c.artist).isEmpty() || norm(artist).isEmpty() || norm(c.artist) == norm(artist))
            } ?: continue
            val sid = when (plat) {
                "wy" -> hit.id.takeIf { it.all { ch -> ch.isDigit() } } ?: ""
                "tx" -> hit.songmid.ifBlank { hit.id }
                "kg" -> hit.hash.ifBlank { hit.id }
                "kw" -> hit.id
                "mg" -> hit.copyrightId.ifBlank { hit.id }
                else -> ""
            }
            if (sid.isBlank()) continue
            val lines = when (plat) {
                "wy" -> fetchWyLyric(sid)
                "tx" -> fetchTxLyric(sid)
                "kg" -> fetchKgLyric(sid)
                "kw" -> fetchKwLyric(sid)
                "mg" -> fetchMgLyric(sid)
                else -> emptyList()
            }
            if (lines.isNotEmpty()) return lines
        }
        emptyList()
    } catch (e: Exception) {
        emptyList()
    }
}

"""
rep("private fun fetchWyLyric(songId: String): List<LyricLine> {", helper + "private fun fetchWyLyric(songId: String): List<LyricLine> {")

# 3. 歌词 effect：主取空后走兜底；sid 为空但歌名有效时也走兜底
old_effect = """        // 按平台路由歌词接口
        if (sid.isNotEmpty()) {
            lyricLoading = true
            lyricLines = withContext(Dispatchers.IO) {
                try {
                    when (plat) {
                        "tx" -> fetchTxLyric(sid)
                        "kg" -> fetchKgLyric(sid)
                        "kw" -> fetchKwLyric(sid)
                        "mg" -> fetchMgLyric(sid)
                        else -> if (sid.all { it.isDigit() }) fetchWyLyric(sid) else emptyList()
                    }
                } catch (e: Exception) {
                    android.util.Log.w("LxPlayer", "歌词获取失败", e)
                    emptyList()
                }
            }
            lyricLoading = false
        }"""
new_effect = """        // 按平台路由歌词接口，主取空后跨平台兜底 [44v1]
        if (sid.isNotEmpty() || (displayTitle.isNotBlank() && displayTitle != "未知歌曲")) {
            lyricLoading = true
            lyricLines = withContext(Dispatchers.IO) {
                try {
                    val primary = if (sid.isNotEmpty()) {
                        when (plat) {
                            "tx" -> fetchTxLyric(sid)
                            "kg" -> fetchKgLyric(sid)
                            "kw" -> fetchKwLyric(sid)
                            "mg" -> fetchMgLyric(sid)
                            else -> if (sid.all { it.isDigit() }) fetchWyLyric(sid) else emptyList()
                        }
                    } else {
                        emptyList()
                    }
                    if (primary.isNotEmpty()) {
                        primary
                    } else if (displayTitle.isNotBlank() && displayTitle != "未知歌曲") {
                        fetchLyricFallback(displayTitle, artist, plat)
                    } else {
                        emptyList()
                    }
                } catch (e: Exception) {
                    android.util.Log.w("LxPlayer", "歌词获取失败", e)
                    emptyList()
                }
            }
            lyricLoading = false
        }"""
rep(old_effect, new_effect)

assert src.count("{") == src.count("}")
with open(path, "w", encoding="utf-8") as f:
    f.write(src)
print("OK 44v1")
PYEOF

echo "=== 44 v1 done ==="
