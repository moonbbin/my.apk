#!/bin/bash
# 17_music_cover.sh - 真实歌曲封面（Coil 依赖）
set -e
cd avbox

echo "=== 添加 Coil 依赖 ==="

# 找 Gradle 文件（兼容 .gradle 和 .gradle.kts）
if [ -f "app/build.gradle.kts" ]; then
  GRADLE_FILE="app/build.gradle.kts"
  COIL_DEP='    implementation("io.coil-kt:coil-compose:2.5.0")'
elif [ -f "app/build.gradle" ]; then
  GRADLE_FILE="app/build.gradle"
  COIL_DEP="    implementation 'io.coil-kt:coil-compose:2.5.0'"
else
  echo "❌ 找不到 app/build.gradle(.kts)"
  ls app/ | head -10
  exit 1
fi

echo "Gradle 文件: $GRADLE_FILE"

if grep -q "coil-compose" "$GRADLE_FILE"; then
  echo "Coil 已存在，跳过"
else
  # 在 dependencies { 后加一行
  if grep -q "dependencies {" "$GRADLE_FILE"; then
    # 用 awk 在 dependencies { 后插入
    awk -v dep="$COIL_DEP" '
      /dependencies \{/ && !done { print; print dep; done=1; next }
      { print }
    ' "$GRADLE_FILE" > /tmp/build.gradle.tmp && mv /tmp/build.gradle.tmp "$GRADLE_FILE"
    echo "✅ Coil 依赖已加"
  else
    echo "❌ 没找到 dependencies 块"
    exit 1
  fi
fi

echo "=== 完成 ==="
