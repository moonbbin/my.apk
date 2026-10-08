#!/bin/bash
set -e
# 用法: bash 00_version.sh v1.2.3-alpha02
# 将 Release 版本号同步到 App 的 versionName

VERSION="$1"
cd avbox

# 去掉开头的 v（如果有）
APP_VERSION="${VERSION#v}"

echo "设置应用版本为: $APP_VERSION"

# 更新 versionName
sed -i "s/versionName = \".*\"/versionName = \"$APP_VERSION\"/" app/build.gradle.kts

# versionCode +1（基于当前值）
CURRENT_CODE=$(grep -oP 'versionCode = \K\d+' app/build.gradle.kts | head -1)
NEW_CODE=$((CURRENT_CODE + 1))
sed -i "s/versionCode = $CURRENT_CODE/versionCode = $NEW_CODE/" app/build.gradle.kts

echo "versionName=$APP_VERSION, versionCode=$NEW_CODE"
grep -n "versionName\|versionCode" app/build.gradle.kts | head -3
