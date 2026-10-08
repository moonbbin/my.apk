#!/bin/bash
set -e
cd avbox
F='app/src/main/java/com/github/tvbox/osc/ui/page/SettingsAppInfoCard.kt'
# 加 import
sed -i '/import androidx.compose.foundation.background/a import androidx.compose.foundation.Image' "$F"
sed -i '/import androidx.compose.foundation.shape.RoundedCornerShape/a import androidx.compose.foundation.shape.CircleShape' "$F"
sed -i '/import androidx.compose.ui.draw.scale/a import androidx.compose.ui.layout.ContentScale' "$F"
# 齿轮形 -> 圆形
sed -i 's/.clip(MaterialShapes.Cookie12Sided.toShape())/.clip(CircleShape)/' "$F"
# Icon -> Image (perl 多行替换)
perl -0777 -i -pe 's/                Icon\(\n                    painter = painterResource\(R\.drawable\.ic_launcher_foreground\),\n                    contentDescription = null,\n                    tint = contentColor,\n                    modifier = Modifier\n                        \.size\(AppBadgeSize\)\n                        \.scale\(AppIconGlyphScale\),\n                \)/                Image(\n                    painter = painterResource(R.drawable.ic_cat_avatar),\n                    contentDescription = null,\n                    contentScale = ContentScale.Crop,\n                    modifier = Modifier.size(AppBadgeSize),\n                )/s' "$F"
echo "头像 Icon 已替换为 Image" 
echo "=== 验证 ==="
grep -n "CircleShape\|ic_cat_avatar" "$F" | head -5
