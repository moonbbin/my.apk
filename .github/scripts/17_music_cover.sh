#!/bin/bash
# 17_music_cover.sh - 真实歌曲封面（Coil + 酷狗封面API）
set -e
cd avbox

echo "=== 添加 Coil 依赖 ==="
GRADLE_FILE="app/build.gradle"
if ! grep -q "coil-compose" "$GRADLE_FILE"; then
  # 在 dependencies 块里加
  python3 << 'PYEOF'
with open('app/build.gradle', 'r') as f:
    content = f.read()
# 找 dependencies { 的第一行 implementation，加 Coil
old = "dependencies {"
new = """dependencies {
    implementation("io.coil-kt:coil-compose:2.5.0")"""
if old in content:
    content = content.replace(old, new, 1)
    with open('app/build.gradle', 'w') as f:
        f.write(content)
    print("✅ Coil 依赖已加")
else:
    print("❌ 没找到 dependencies")
PYEOF
else
  echo "Coil 已存在，跳过"
fi

echo "=== 修改播放器：获取并显示真实封面 ==="
# 这里需要修改 LxPlayerActivity.kt，逻辑：
# 1. 用 hash 调酷狗 API 拿 album_img
# 2. 用 Coil AsyncImage 显示
# 具体实现由 14 脚本里的 kt 文件修改（避免重复 base64）
echo "封面逻辑需在 14_music_search.sh 的 kt 里实现"
echo "=== 完成 ==="
