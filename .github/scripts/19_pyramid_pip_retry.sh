#!/bin/bash
# 19_pyramid_pip_retry.sh
# 给 pyramid 模块 chaquopy pip 安装加重试+备用镜像，缓解 installDebugPythonRequirements 间歇性失败（网络抖动）
#
# 做了三件事：
#   1. pip 重试 --retries 10、超时 --timeout 120
#   2. --no-cache-dir 避免缓存损坏导致反复失败
#   3. pip 主镜像切到清华（默认），可用 PIP_INDEX_URL 环境变量覆盖
#
# 用法：PIP_INDEX_URL="https://mirrors.aliyun.com/pypi/simple/" bash 19_pyramid_pip_retry.sh
set -e
cd avbox
echo "=== pyramid pip 重试补丁 ==="

GRADLE_FILE="pyramid/build.gradle.kts"
BACKUP_FILE="pyramid/build.gradle.kts.bak"

# 默认用清华备用镜像；环境变量可覆盖（如需切回阿里云）
PIP_MIRROR="${PIP_INDEX_URL:-https://pypi.tuna.tsinghua.edu.cn/simple/}"
echo "pip 主镜像: $PIP_MIRROR"

if [ ! -f "$GRADLE_FILE" ]; then
    echo "❌ 找不到 $GRADLE_FILE"
    exit 1
fi

# 备份
cp "$GRADLE_FILE" "$BACKUP_FILE"
echo "✅ 已备份到 $BACKUP_FILE"

# 改 pip 配置（幂等：已是目标状态则跳过；旧值 5/60 自动升级到 10/120）
PIP_MIRROR="$PIP_MIRROR" python3 << 'PYEOF'
import os

path = "pyramid/build.gradle.kts"
with open(path, "r") as f:
    content = f.read()

target_mirror = os.environ.get("PIP_MIRROR", "https://pypi.tuna.tsinghua.edu.cn/simple/")
aliyun = "https://mirrors.aliyun.com/pypi/simple/"
changed = []

# 1. 镜像切换：aliyun -> 目标镜像（目标已是 tuna 时跳过）
if target_mirror != aliyun and aliyun in content:
    content = content.replace(aliyun, target_mirror)
    changed.append("镜像切换: aliyun -> %s" % target_mirror)

# 2. 升级旧重试值 5/60 -> 10/120
for old, new in [
    ('options("--retries", "5")', 'options("--retries", "10")'),
    ('options("--timeout", "60")', 'options("--timeout", "120")'),
]:
    if old in content:
        content = content.replace(old, new)
        changed.append("%s -> %s" % (old, new))

# 3. 补齐缺失的 options（插在 pip 块锚点之后）
anchor = 'options("--extra-index-url", "https://chaquo.com/pypi-13.1")'
needed = [
    'options("--retries", "10")',
    'options("--timeout", "120")',
    'options("--no-cache-dir")',
]
missing = [n for n in needed if n not in content]
if missing:
    if anchor not in content:
        print("❌ 没找到 pip options 锚点")
        raise SystemExit(1)
    insert = "".join("\n            " + m for m in missing)
    content = content.replace(anchor, anchor + insert, 1)
    changed.append("补齐: " + ", ".join(missing))

with open(path, "w") as f:
    f.write(content)

if changed:
    for c in changed:
        print("✅ " + c)
else:
    print("无需修改，已是最新状态")
PYEOF

# 验证
OK=1
grep -q 'options("--retries", "10")' "$GRADLE_FILE" || OK=0
grep -q 'options("--timeout", "120")' "$GRADLE_FILE" || OK=0
grep -q 'options("--no-cache-dir")' "$GRADLE_FILE" || OK=0
if [ "$PIP_MIRROR" != "https://mirrors.aliyun.com/pypi/simple/" ]; then
    grep -q "mirrors.aliyun.com" "$GRADLE_FILE" && OK=0
fi

if [ "$OK" = "1" ]; then
    echo "✅ 验证通过：重试/超时/no-cache-dir/镜像均已写入"
else
    echo "❌ 验证失败，恢复备份"
    cp "$BACKUP_FILE" "$GRADLE_FILE"
    exit 1
fi

echo "=== pyramid pip 重试补丁完成 ==="
