#!/bin/bash
set -e
cd avbox
F='app/src/main/java/com/github/tvbox/osc/ui/page/HomePage.kt'
# 26.dp -> 20.dp (仅 capsule logo 那一行，通过下一行 drawBehind 定位)
# 将唯一的 .size(26.dp) 改为 20.dp 并加圆角
sed -i 's/\.size(26\.dp)/.size(20.dp)\n                            .clip(RoundedCornerShape(6.dp))/' "$F"
echo "=== 验证修改 ==="
sed -n '169,175p' "$F"
