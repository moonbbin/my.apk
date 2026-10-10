#!/bin/bash
# 19_pyramid_pip_retry.sh
# 给 pyramid 模块 chaquopy pip 安装加重试，缓解 installDebugPythonRequirements 间歇性失败（网络抖动）
set -e
cd avbox
echo "=== pyramid pip 重试补丁 ==="

GRADLE_FILE="pyramid/build.gradle.kts"
BACKUP_FILE="pyramid/build.gradle.kts.bak"

if [ ! -f "$GRADLE_FILE" ]; then
    echo "❌ 找不到 $GRADLE_FILE"
    exit 1
fi

# 备份
cp "$GRADLE_FILE" "$BACKUP_FILE"
echo "✅ 已备份到 $BACKUP_FILE"

# 插入重试选项（幂等：已存在则跳过）
python3 << 'PYEOF'
path = "pyramid/build.gradle.kts"
with open(path, "r") as f:
    content = f.read()

if 'options("--retries"' in content and 'options("--timeout"' in content:
    print("重试选项已存在，跳过")
else:
    anchor = 'options("--extra-index-url", "https://chaquo.com/pypi-13.1")'
    retry_lines = '\n            options("--retries", "5")\n            options("--timeout", "60")'
    if anchor in content:
        content = content.replace(anchor, anchor + retry_lines, 1)
        with open(path, "w") as f:
            f.write(content)
        print("✅ 已添加重试选项")
    else:
        print("❌ 没找到 pip options 锚点")
        raise SystemExit(1)
PYEOF

# 验证
if grep -q 'options("--retries", "5")' "$GRADLE_FILE" && grep -q 'options("--timeout", "60")' "$GRADLE_FILE"; then
    echo "✅ 验证通过：重试选项已写入"
else
    echo "❌ 验证失败，恢复备份"
    cp "$BACKUP_FILE" "$GRADLE_FILE"
    exit 1
fi

echo "=== pyramid pip 重试补丁完成 ==="
