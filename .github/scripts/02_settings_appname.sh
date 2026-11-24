#!/bin/bash
# [base-a6da734e] round1 tvbox->avbox
set -e
cd avbox
F='app/src/main/java/com/github/avbox/osc/ui/page/SettingsAppInfoCard.kt'
sed -i 's/text = "AudioVideoBox"/text = "清风"/' "$F"
echo "=== 验证修改 ==="
grep -n 'text = "清风"' "$F"
