#!/bin/bash
set -e
cd avbox
F='app/src/main/java/com/github/tvbox/osc/ui/page/SettingsAppInfoCard.kt'
sed -i 's/text = "AVBox"/text = "清风"/' "$F"
echo "=== 验证修改 ==="
grep -n 'text = "清风"' "$F"
