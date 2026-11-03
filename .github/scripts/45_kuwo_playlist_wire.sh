#!/bin/bash
# 45_kuwo_playlist_wire.sh
# 歌单页放行酷我（35 后补丁无关，改的是歌单页 MusicHomeActivity）：列表/分类/详情三处接线
set -e
cd "$(dirname "$0")/../.." 2>/dev/null || true
PA="avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"

if grep -q "LxMusicSearchApi.getKuwoPlaylist" "$PA" 2>/dev/null; then
  echo "跳过（45v1 酷我歌单接线已写入）"
  exit 0
fi

python3 << 'PYEOF'
import sys

path = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"
with open(path, encoding="utf-8") as f:
    src = f.read()

MARK = "// [45v1]"
if MARK in src:
    print("skip: 45v1 already present")
    sys.exit(0)


def rep(old, new, cnt=1):
    global src
    assert src.count(old) == cnt, f"anchor count {src.count(old)}: {old[:70]!r}"
    src = src.replace(old, new, cnt)


# 1. 三处平台 gate 放行 kw（NEW4 实测 3 处；缺失则大声失败，多了也全换）
old_gate = 'if (platform !in listOf("wy", "tx", "kg"))'
gate_count = src.count(old_gate)
assert gate_count >= 1, "playlist gate anchor count 0"
src = src.replace(old_gate, 'if (platform !in listOf("wy", "tx", "kg", "kw"))')
print(f"gates opened: {gate_count}")

# 2. 列表分发加 kw
rep(
    '"kg" -> LxMusicSearchApi.getKugouPlaylists(cat, offset).map { PlaylistInfo(it.id, it.name, it.coverUrl, it.playCount) }',
    '"kg" -> LxMusicSearchApi.getKugouPlaylists(cat, offset).map { PlaylistInfo(it.id, it.name, it.coverUrl, it.playCount) }\n'
    '                "kw" -> LxMusicSearchApi.getKuwoPlaylists(cat, offset).map { PlaylistInfo(it.id, it.name, it.coverUrl, it.playCount) }  // [45v1]',
)

# 3. 分类分发加 kw
rep(
    '"kg" -> LxMusicSearchApi.getKugouCategories()',
    '"kg" -> LxMusicSearchApi.getKugouCategories()\n'
    '                    "kw" -> LxMusicSearchApi.getKuwoCategories()  // [45v1]',
)

# 4. 详情分发加 kw
rep(
    '"kg" -> LxMusicSearchApi.getKugouPlaylist(playlistId)',
    '"kg" -> LxMusicSearchApi.getKugouPlaylist(playlistId)\n'
    '                    "kw" -> LxMusicSearchApi.getKuwoPlaylist(playlistId)  // [45v1]',
)

assert src.count("{") == src.count("}")
with open(path, "w", encoding="utf-8") as f:
    f.write(src)
print("OK 45v1")
PYEOF

echo "=== 45 v1 done ==="
