#!/bin/bash
# 39_wallpaper.sh [39wp1] 自定义壁纸一期：WallpaperManager + 设置页 + MusicHomeActivity 根注入（壁纸层+Scrim）+ 五 Tab 根底色条件透明
set -e
cd "$(dirname "$0")/../.." 2>/dev/null || true
mkdir -p avbox/app/src/main/java/com/github/tvbox/osc/ui/activity
TMPB64=$(mktemp)
    printf '%s' 'cGFja2FnZSBjb20uZ2l0aHViLnR2Ym94Lm9zYy51aS5hY3Rpdml0eQoKaW1wb3J0IGFuZHJvaWQu' >> "$TMPB64"
    printf '%s' 'Y29udGVudC5Db250ZXh0CmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLnJ1bnRpbWUuQ29tcG9zYWJs' >> "$TMPB64"
    printf '%s' 'ZQppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5ydW50aW1lLmNvbGxlY3RBc1N0YXRlCmltcG9ydCBh' >> "$TMPB64"
    printf '%s' 'bmRyb2lkeC5jb21wb3NlLnJ1bnRpbWUuZ2V0VmFsdWUKaW1wb3J0IGtvdGxpbnguY29yb3V0aW5l' >> "$TMPB64"
    printf '%s' 'cy5mbG93Lk11dGFibGVTdGF0ZUZsb3cKaW1wb3J0IGtvdGxpbnguY29yb3V0aW5lcy5mbG93LlN0' >> "$TMPB64"
    printf '%s' 'YXRlRmxvdwoKLy8gWzM5d3AxXSDoh6rlrprkuYnlo4HnurjvvJrnirbmgIEgKyDmjIHkuYXljJbv' >> "$TMPB64"
    printf '%s' 'vIjojIPlvI/lkIwgTXVzaWNUaGVtZU1hbmFnZXLvvJpvYmplY3QgKyBwcmVmcyArIFN0YXRlRmxv' >> "$TMPB64"
    printf '%s' 'd++8iQpvYmplY3QgV2FsbHBhcGVyTWFuYWdlciB7CiAgICBwcml2YXRlIGNvbnN0IHZhbCBQUkVG' >> "$TMPB64"
    printf '%s' 'UyA9ICJ3YWxscGFwZXJfcHJlZnMiCiAgICBwcml2YXRlIGNvbnN0IHZhbCBLRVlfRU5BQkxFRCA9' >> "$TMPB64"
    printf '%s' 'ICJlbmFibGVXYWxscGFwZXIiCiAgICBwcml2YXRlIGNvbnN0IHZhbCBLRVlfVVJMID0gIndhbGxw' >> "$TMPB64"
    printf '%s' 'YXBlclVybCIKICAgIHByaXZhdGUgY29uc3QgdmFsIEtFWV9ISVNUT1JZID0gIndhbGxwYXBlckhp' >> "$TMPB64"
    printf '%s' 'c3RvcnkiCgogICAgZGF0YSBjbGFzcyBTdGF0ZSgKICAgICAgICB2YWwgZW5hYmxlZDogQm9vbGVh' >> "$TMPB64"
    printf '%s' 'biA9IGZhbHNlLAogICAgICAgIHZhbCB1cmw6IFN0cmluZyA9ICIiLAogICAgICAgIHZhbCBoaXN0' >> "$TMPB64"
    printf '%s' 'b3J5OiBMaXN0PFN0cmluZz4gPSBlbXB0eUxpc3QoKSwKICAgICkKCiAgICBwcml2YXRlIHZhbCBf' >> "$TMPB64"
    printf '%s' 'c3RhdGUgPSBNdXRhYmxlU3RhdGVGbG93KFN0YXRlKCkpCiAgICB2YWwgc3RhdGU6IFN0YXRlRmxv' >> "$TMPB64"
    printf '%s' 'dzxTdGF0ZT4gPSBfc3RhdGUKCiAgICBwcml2YXRlIGZ1biBwcmVmcyhjdHg6IENvbnRleHQpID0g' >> "$TMPB64"
    printf '%s' 'Y3R4LmdldFNoYXJlZFByZWZlcmVuY2VzKFBSRUZTLCBDb250ZXh0Lk1PREVfUFJJVkFURSkKCiAg' >> "$TMPB64"
    printf '%s' 'ICBmdW4gaW5pdChjdHg6IENvbnRleHQpIHsKICAgICAgICB0cnkgewogICAgICAgICAgICB2YWwg' >> "$TMPB64"
    printf '%s' 'cCA9IHByZWZzKGN0eCkKICAgICAgICAgICAgdmFsIGhpc3QgPSAocC5nZXRTdHJpbmcoS0VZX0hJ' >> "$TMPB64"
    printf '%s' 'U1RPUlksICIiKSA/OiAiIikuc3BsaXQoIlxuIikuZmlsdGVyIHsgaXQuaXNOb3RCbGFuaygpIH0K' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgX3N0YXRlLnZhbHVlID0gU3RhdGUoCiAgICAgICAgICAgICAgICBlbmFibGVk' >> "$TMPB64"
    printf '%s' 'ID0gcC5nZXRCb29sZWFuKEtFWV9FTkFCTEVELCBmYWxzZSksCiAgICAgICAgICAgICAgICB1cmwg' >> "$TMPB64"
    printf '%s' 'PSBwLmdldFN0cmluZyhLRVlfVVJMLCAiIikgPzogIiIsCiAgICAgICAgICAgICAgICBoaXN0b3J5' >> "$TMPB64"
    printf '%s' 'ID0gaGlzdCwKICAgICAgICAgICAgKQogICAgICAgIH0gY2F0Y2ggKGU6IEV4Y2VwdGlvbikgewog' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICBhbmRyb2lkLnV0aWwuTG9nLncoIldhbGxwYXBlciIsICLlo4HnurjnirbmgIHo' >> "$TMPB64"
    printf '%s' 'r7vlj5blpLHotKUiLCBlKQogICAgICAgIH0KICAgIH0KCiAgICBmdW4gc2V0RW5hYmxlZChjdHg6' >> "$TMPB64"
    printf '%s' 'IENvbnRleHQsIG9uOiBCb29sZWFuKSB7CiAgICAgICAgdHJ5IHsKICAgICAgICAgICAgcHJlZnMo' >> "$TMPB64"
    printf '%s' 'Y3R4KS5lZGl0KCkucHV0Qm9vbGVhbihLRVlfRU5BQkxFRCwgb24pLmFwcGx5KCkKICAgICAgICB9' >> "$TMPB64"
    printf '%s' 'IGNhdGNoIChlOiBFeGNlcHRpb24pIHsKICAgICAgICAgICAgYW5kcm9pZC51dGlsLkxvZy53KCJX' >> "$TMPB64"
    printf '%s' 'YWxscGFwZXIiLCAi5aOB57q45byA5YWz5L+d5a2Y5aSx6LSlIiwgZSkKICAgICAgICB9CiAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgX3N0YXRlLnZhbHVlID0gX3N0YXRlLnZhbHVlLmNvcHkoZW5hYmxlZCA9IG9uKQogICAgfQoK' >> "$TMPB64"
    printf '%s' 'ICAgIC8vIOW6lOeUqOS4gOW8oOWjgee6uO+8iFVSTCDmiJbmnKzlnLAgVVJJ77yJ77ya5a2Y5Li6' >> "$TMPB64"
    printf '%s' '5b2T5YmN44CB6aG25Yiw5Y6G5Y+y5pyA5YmN77yI5Y676YeN44CB5LiK6ZmQIDbvvInjgIHoh6rl' >> "$TMPB64"
    printf '%s' 'iqjlvIDlkK8KICAgIGZ1biBhcHBseShjdHg6IENvbnRleHQsIHVybDogU3RyaW5nKSB7CiAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgdmFsIHUgPSB1cmwudHJpbSgpCiAgICAgICAgaWYgKHUuaXNCbGFuaygpKSByZXR1cm4KICAg' >> "$TMPB64"
    printf '%s' 'ICAgICB2YWwgaGlzdCA9IChsaXN0T2YodSkgKyBfc3RhdGUudmFsdWUuaGlzdG9yeS5maWx0ZXIg' >> "$TMPB64"
    printf '%s' 'eyBpdCAhPSB1IH0pLnRha2UoNikKICAgICAgICB0cnkgewogICAgICAgICAgICBwcmVmcyhjdHgp' >> "$TMPB64"
    printf '%s' 'LmVkaXQoKQogICAgICAgICAgICAgICAgLnB1dFN0cmluZyhLRVlfVVJMLCB1KQogICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgLnB1dFN0cmluZyhLRVlfSElTVE9SWSwgaGlzdC5qb2luVG9TdHJpbmcoIlxuIikpCiAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAucHV0Qm9vbGVhbihLRVlfRU5BQkxFRCwgdHJ1ZSkKICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgIC5hcHBseSgpCiAgICAgICAgfSBjYXRjaCAoZTogRXhjZXB0aW9uKSB7CiAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'IGFuZHJvaWQudXRpbC5Mb2cudygiV2FsbHBhcGVyIiwgIuWjgee6uOW6lOeUqOS/neWtmOWksei0' >> "$TMPB64"
    printf '%s' 'pSIsIGUpCiAgICAgICAgfQogICAgICAgIF9zdGF0ZS52YWx1ZSA9IFN0YXRlKGVuYWJsZWQgPSB0' >> "$TMPB64"
    printf '%s' 'cnVlLCB1cmwgPSB1LCBoaXN0b3J5ID0gaGlzdCkKICAgIH0KCiAgICBmdW4gcmVtb3ZlSGlzdG9y' >> "$TMPB64"
    printf '%s' 'eShjdHg6IENvbnRleHQsIHVybDogU3RyaW5nKSB7CiAgICAgICAgdmFsIGhpc3QgPSBfc3RhdGUu' >> "$TMPB64"
    printf '%s' 'dmFsdWUuaGlzdG9yeS5maWx0ZXIgeyBpdCAhPSB1cmwgfQogICAgICAgIHRyeSB7CiAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgIHByZWZzKGN0eCkuZWRpdCgpLnB1dFN0cmluZyhLRVlfSElTVE9SWSwgaGlzdC5qb2luVG9T' >> "$TMPB64"
    printf '%s' 'dHJpbmcoIlxuIikpLmFwcGx5KCkKICAgICAgICB9IGNhdGNoIChlOiBFeGNlcHRpb24pIHsKICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgYW5kcm9pZC51dGlsLkxvZy53KCJXYWxscGFwZXIiLCAi5aOB57q45Y6G5Y+y5Yig' >> "$TMPB64"
    printf '%s' '6Zmk5aSx6LSlIiwgZSkKICAgICAgICB9CiAgICAgICAgX3N0YXRlLnZhbHVlID0gX3N0YXRlLnZh' >> "$TMPB64"
    printf '%s' 'bHVlLmNvcHkoaGlzdG9yeSA9IGhpc3QpCiAgICB9CgogICAgLy8g6aG16Z2i5qC55bqV6Imy55So' >> "$TMPB64"
    printf '%s' '77ya5aOB57q455Sf5pWI5Lit5YiZ6YCP5Ye65bqV5bGC5aOB57q477yI6aG16Z2i5qC55pS56YCP' >> "$TMPB64"
    printf '%s' '5piO77yJCiAgICBAQ29tcG9zYWJsZQogICAgZnVuIGlzQWN0aXZlKCk6IEJvb2xlYW4gewogICAg' >> "$TMPB64"
    printf '%s' 'ICAgIHZhbCBzIGJ5IHN0YXRlLmNvbGxlY3RBc1N0YXRlKCkKICAgICAgICByZXR1cm4gcy5lbmFi' >> "$TMPB64"
    printf '%s' 'bGVkICYmIHMudXJsLmlzTm90QmxhbmsoKQogICAgfQp9Cg==' >> "$TMPB64"
base64 -d "$TMPB64" > avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/WallpaperManager.kt
rm -f "$TMPB64"
grep -q 'object WallpaperManager' avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/WallpaperManager.kt || { echo "X 39 object WallpaperManager 写入失败"; exit 1; }
TMPB64=$(mktemp)
    printf '%s' 'cGFja2FnZSBjb20uZ2l0aHViLnR2Ym94Lm9zYy51aS5hY3Rpdml0eQoKaW1wb3J0IGFuZHJvaWQu' >> "$TMPB64"
    printf '%s' 'Y29udGVudC5Db250ZXh0CmltcG9ydCBhbmRyb2lkLmNvbnRlbnQuSW50ZW50CmltcG9ydCBhbmRy' >> "$TMPB64"
    printf '%s' 'b2lkLm9zLkJ1bmRsZQppbXBvcnQgYW5kcm9pZHguYWN0aXZpdHkuQ29tcG9uZW50QWN0aXZpdHkK' >> "$TMPB64"
    printf '%s' 'aW1wb3J0IGFuZHJvaWR4LmFjdGl2aXR5LmNvbXBvc2UucmVtZW1iZXJMYXVuY2hlckZvckFjdGl2' >> "$TMPB64"
    printf '%s' 'aXR5UmVzdWx0CmltcG9ydCBhbmRyb2lkeC5hY3Rpdml0eS5jb21wb3NlLnNldENvbnRlbnQKaW1w' >> "$TMPB64"
    printf '%s' 'b3J0IGFuZHJvaWR4LmFjdGl2aXR5LnJlc3VsdC5jb250cmFjdC5BY3Rpdml0eVJlc3VsdENvbnRy' >> "$TMPB64"
    printf '%s' 'YWN0cwppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5mb3VuZGF0aW9uLmJhY2tncm91bmQKaW1wb3J0' >> "$TMPB64"
    printf '%s' 'IGFuZHJvaWR4LmNvbXBvc2UuZm91bmRhdGlvbi5ib3JkZXIKaW1wb3J0IGFuZHJvaWR4LmNvbXBv' >> "$TMPB64"
    printf '%s' 'c2UuZm91bmRhdGlvbi5jbGlja2FibGUKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UuZm91bmRhdGlv' >> "$TMPB64"
    printf '%s' 'bi5sYXlvdXQuQXJyYW5nZW1lbnQKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UuZm91bmRhdGlvbi5s' >> "$TMPB64"
    printf '%s' 'YXlvdXQuQm94CmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLmZvdW5kYXRpb24ubGF5b3V0LkNvbHVt' >> "$TMPB64"
    printf '%s' 'bgppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5mb3VuZGF0aW9uLmxheW91dC5QYWRkaW5nVmFsdWVz' >> "$TMPB64"
    printf '%s' 'CmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLmZvdW5kYXRpb24ubGF5b3V0LlJvdwppbXBvcnQgYW5k' >> "$TMPB64"
    printf '%s' 'cm9pZHguY29tcG9zZS5mb3VuZGF0aW9uLmxheW91dC5TcGFjZXIKaW1wb3J0IGFuZHJvaWR4LmNv' >> "$TMPB64"
    printf '%s' 'bXBvc2UuZm91bmRhdGlvbi5sYXlvdXQuZmlsbE1heFNpemUKaW1wb3J0IGFuZHJvaWR4LmNvbXBv' >> "$TMPB64"
    printf '%s' 'c2UuZm91bmRhdGlvbi5sYXlvdXQuZmlsbE1heFdpZHRoCmltcG9ydCBhbmRyb2lkeC5jb21wb3Nl' >> "$TMPB64"
    printf '%s' 'LmZvdW5kYXRpb24ubGF5b3V0LmhlaWdodAppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5mb3VuZGF0' >> "$TMPB64"
    printf '%s' 'aW9uLmxheW91dC5wYWRkaW5nCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLmZvdW5kYXRpb24ubGF5' >> "$TMPB64"
    printf '%s' 'b3V0LnNpemUKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UuZm91bmRhdGlvbi5sYXlvdXQud2lkdGgK' >> "$TMPB64"
    printf '%s' 'aW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UuZm91bmRhdGlvbi5sYXp5LkxhenlDb2x1bW4KaW1wb3J0' >> "$TMPB64"
    printf '%s' 'IGFuZHJvaWR4LmNvbXBvc2UuZm91bmRhdGlvbi5sYXp5LkxhenlSb3cKaW1wb3J0IGFuZHJvaWR4' >> "$TMPB64"
    printf '%s' 'LmNvbXBvc2UuZm91bmRhdGlvbi5sYXp5Lml0ZW1zCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLmZv' >> "$TMPB64"
    printf '%s' 'dW5kYXRpb24uc2hhcGUuUm91bmRlZENvcm5lclNoYXBlCmltcG9ydCBhbmRyb2lkeC5jb21wb3Nl' >> "$TMPB64"
    printf '%s' 'Lm1hdGVyaWFsMy5CdXR0b24KaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UubWF0ZXJpYWwzLkJ1dHRv' >> "$TMPB64"
    printf '%s' 'bkRlZmF1bHRzCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLm1hdGVyaWFsMy5DYXJkCmltcG9ydCBh' >> "$TMPB64"
    printf '%s' 'bmRyb2lkeC5jb21wb3NlLm1hdGVyaWFsMy5DYXJkRGVmYXVsdHMKaW1wb3J0IGFuZHJvaWR4LmNv' >> "$TMPB64"
    printf '%s' 'bXBvc2UubWF0ZXJpYWwzLk1hdGVyaWFsVGhlbWUKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UubWF0' >> "$TMPB64"
    printf '%s' 'ZXJpYWwzLk91dGxpbmVkQnV0dG9uCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLm1hdGVyaWFsMy5P' >> "$TMPB64"
    printf '%s' 'dXRsaW5lZFRleHRGaWVsZAppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5tYXRlcmlhbDMuT3V0bGlu' >> "$TMPB64"
    printf '%s' 'ZWRUZXh0RmllbGREZWZhdWx0cwppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5tYXRlcmlhbDMuU3dp' >> "$TMPB64"
    printf '%s' 'dGNoCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLm1hdGVyaWFsMy5Td2l0Y2hEZWZhdWx0cwppbXBv' >> "$TMPB64"
    printf '%s' 'cnQgYW5kcm9pZHguY29tcG9zZS5tYXRlcmlhbDMuVGV4dAppbXBvcnQgYW5kcm9pZHguY29tcG9z' >> "$TMPB64"
    printf '%s' 'ZS5ydW50aW1lLkNvbXBvc2FibGUKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UucnVudGltZS5TaWRl' >> "$TMPB64"
    printf '%s' 'RWZmZWN0CmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLnJ1bnRpbWUuY29sbGVjdEFzU3RhdGUKaW1w' >> "$TMPB64"
    printf '%s' 'b3J0IGFuZHJvaWR4LmNvbXBvc2UucnVudGltZS5nZXRWYWx1ZQppbXBvcnQgYW5kcm9pZHguY29t' >> "$TMPB64"
    printf '%s' 'cG9zZS5ydW50aW1lLm11dGFibGVTdGF0ZU9mCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLnJ1bnRp' >> "$TMPB64"
    printf '%s' 'bWUucmVtZW1iZXIKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UucnVudGltZS5zZXRWYWx1ZQppbXBv' >> "$TMPB64"
    printf '%s' 'cnQgYW5kcm9pZHguY29tcG9zZS51aS5BbGlnbm1lbnQKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2Uu' >> "$TMPB64"
    printf '%s' 'dWkuTW9kaWZpZXIKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UudWkuZHJhdy5jbGlwCmltcG9ydCBh' >> "$TMPB64"
    printf '%s' 'bmRyb2lkeC5jb21wb3NlLnVpLmdyYXBoaWNzLkNvbG9yCmltcG9ydCBhbmRyb2lkeC5jb21wb3Nl' >> "$TMPB64"
    printf '%s' 'LnVpLmxheW91dC5Db250ZW50U2NhbGUKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UudWkucGxhdGZv' >> "$TMPB64"
    printf '%s' 'cm0uTG9jYWxDb250ZXh0CmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLnVpLnRleHQuZm9udC5Gb250' >> "$TMPB64"
    printf '%s' 'V2VpZ2h0CmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLnVpLnVuaXQuZHAKaW1wb3J0IGFuZHJvaWR4' >> "$TMPB64"
    printf '%s' 'LmNvcmUudmlldy5XaW5kb3dDb21wYXQKaW1wb3J0IGNvaWwuY29tcG9zZS5Bc3luY0ltYWdlCmlt' >> "$TMPB64"
    printf '%s' 'cG9ydCBjb2lsLnJlcXVlc3QuSW1hZ2VSZXF1ZXN0CgovLyBbMzl3cDFdIOWjgee6uOiuvue9rumh' >> "$TMPB64"
    printf '%s' 'te+8muW8gOWFsyArIFVSTCDovpPlhaUgKyDmnKzlnLDpgInlm77vvIjmjIHkuYXmjojmnYPvvIkr' >> "$TMPB64"
    printf '%s' 'IOWOhuWPsuaoquaOkuOAguWPquWGmSBXYWxscGFwZXJNYW5hZ2Vy44CCCmNsYXNzIEx4V2FsbHBh' >> "$TMPB64"
    printf '%s' 'cGVyU2V0dGluZ3NBY3Rpdml0eSA6IENvbXBvbmVudEFjdGl2aXR5KCkgewogICAgb3ZlcnJpZGUg' >> "$TMPB64"
    printf '%s' 'ZnVuIG9uQ3JlYXRlKHNhdmVkSW5zdGFuY2VTdGF0ZTogQnVuZGxlPykgewogICAgICAgIHN1cGVy' >> "$TMPB64"
    printf '%s' 'Lm9uQ3JlYXRlKHNhdmVkSW5zdGFuY2VTdGF0ZSkKICAgICAgICB2YWwgYXBwQ3R4ID0gYXBwbGlj' >> "$TMPB64"
    printf '%s' 'YXRpb25Db250ZXh0CiAgICAgICAgTXVzaWNUaGVtZU1hbmFnZXIuaW5pdChhcHBDdHgpCiAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgV2FsbHBhcGVyTWFuYWdlci5pbml0KGFwcEN0eCkKICAgICAgICBzZXRDb250ZW50IHsKICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgdmFsIGlzRGFyayBieSBNdXNpY1RoZW1lTWFuYWdlci5pc0RhcmtUaGVtZQogICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICB2YWwgd2luZG93ID0gdGhpc0BMeFdhbGxwYXBlclNldHRpbmdzQWN0aXZpdHkud2lu' >> "$TMPB64"
    printf '%s' 'ZG93CiAgICAgICAgICAgIFNpZGVFZmZlY3QgewogICAgICAgICAgICAgICAgV2luZG93Q29tcGF0' >> "$TMPB64"
    printf '%s' 'LmdldEluc2V0c0NvbnRyb2xsZXIod2luZG93LCB3aW5kb3cuZGVjb3JWaWV3KQogICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgIC5pc0FwcGVhcmFuY2VMaWdodFN0YXR1c0JhcnMgPSAhaXNEYXJrCiAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgIH0KICAgICAgICAgICAgTHhNdXNpY1RoZW1lKGlzRGFya1RoZW1lID0gaXNEYXJrKSB7CiAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICBXYWxscGFwZXJTZXR0aW5nc1NjcmVlbihvbkJhY2sgPSB7IGZpbmlzaCgp' >> "$TMPB64"
    printf '%s' 'IH0pCiAgICAgICAgICAgIH0KICAgICAgICB9CiAgICB9Cn0KCkBDb21wb3NhYmxlCmZ1biBXYWxs' >> "$TMPB64"
    printf '%s' 'cGFwZXJTZXR0aW5nc1NjcmVlbihvbkJhY2s6ICgpIC0+IFVuaXQpIHsKICAgIHZhbCBjb250ZXh0' >> "$TMPB64"
    printf '%s' 'ID0gTG9jYWxDb250ZXh0LmN1cnJlbnQKICAgIHZhbCB3cFN0YXRlIGJ5IFdhbGxwYXBlck1hbmFn' >> "$TMPB64"
    printf '%s' 'ZXIuc3RhdGUuY29sbGVjdEFzU3RhdGUoKQogICAgdmFyIHVybFRleHQgYnkgcmVtZW1iZXIgeyBt' >> "$TMPB64"
    printf '%s' 'dXRhYmxlU3RhdGVPZih3cFN0YXRlLnVybCkgfQogICAgdmFsIHBpY2tlciA9IHJlbWVtYmVyTGF1' >> "$TMPB64"
    printf '%s' 'bmNoZXJGb3JBY3Rpdml0eVJlc3VsdChBY3Rpdml0eVJlc3VsdENvbnRyYWN0cy5PcGVuRG9jdW1l' >> "$TMPB64"
    printf '%s' 'bnQoKSkgeyB1cmkgLT4KICAgICAgICBpZiAodXJpICE9IG51bGwpIHsKICAgICAgICAgICAgdHJ5' >> "$TMPB64"
    printf '%s' 'IHsKICAgICAgICAgICAgICAgIGNvbnRleHQuY29udGVudFJlc29sdmVyLnRha2VQZXJzaXN0YWJs' >> "$TMPB64"
    printf '%s' 'ZVVyaVBlcm1pc3Npb24odXJpLCBJbnRlbnQuRkxBR19HUkFOVF9SRUFEX1VSSV9QRVJNSVNTSU9O' >> "$TMPB64"
    printf '%s' 'KQogICAgICAgICAgICB9IGNhdGNoIChlOiBFeGNlcHRpb24pIHsKICAgICAgICAgICAgICAgIGFu' >> "$TMPB64"
    printf '%s' 'ZHJvaWQudXRpbC5Mb2cudygiV2FsbHBhcGVyIiwgIuacrOWcsOWbvuaMgeS5heaOiOadg+Wksei0' >> "$TMPB64"
    printf '%s' 'pSIsIGUpCiAgICAgICAgICAgIH0KICAgICAgICAgICAgV2FsbHBhcGVyTWFuYWdlci5hcHBseShj' >> "$TMPB64"
    printf '%s' 'b250ZXh0LCB1cmkudG9TdHJpbmcoKSkKICAgICAgICAgICAgdXJsVGV4dCA9IHVyaS50b1N0cmlu' >> "$TMPB64"
    printf '%s' 'ZygpCiAgICAgICAgfQogICAgfQogICAgQ29sdW1uKAogICAgICAgIG1vZGlmaWVyID0gTW9kaWZp' >> "$TMPB64"
    printf '%s' 'ZXIKICAgICAgICAgICAgLmZpbGxNYXhTaXplKCkKICAgICAgICAgICAgLmJhY2tncm91bmQobXVz' >> "$TMPB64"
    printf '%s' 'aWNDb2xvcnMoKS5iYWNrZ3JvdW5kKQogICAgKSB7CiAgICAgICAgUm93KAogICAgICAgICAgICBt' >> "$TMPB64"
    printf '%s' 'b2RpZmllciA9IE1vZGlmaWVyCiAgICAgICAgICAgICAgICAuZmlsbE1heFdpZHRoKCkKICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgIC5wYWRkaW5nKHN0YXJ0ID0gOC5kcCwgZW5kID0gMTYuZHAsIHRvcCA9IDQ4LmRw' >> "$TMPB64"
    printf '%s' 'LCBib3R0b20gPSA4LmRwKSwKICAgICAgICAgICAgdmVydGljYWxBbGlnbm1lbnQgPSBBbGlnbm1l' >> "$TMPB64"
    printf '%s' 'bnQuQ2VudGVyVmVydGljYWxseSwKICAgICAgICApIHsKICAgICAgICAgICAgVGV4dCgKICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgIHRleHQgPSAi4oC5IiwKICAgICAgICAgICAgICAgIHN0eWxlID0gTWF0ZXJpYWxU' >> "$TMPB64"
    printf '%s' 'aGVtZS50eXBvZ3JhcGh5LmhlYWRsaW5lTWVkaXVtLAogICAgICAgICAgICAgICAgY29sb3IgPSBt' >> "$TMPB64"
    printf '%s' 'dXNpY0NvbG9ycygpLnRleHRQcmltYXJ5LAogICAgICAgICAgICAgICAgbW9kaWZpZXIgPSBNb2Rp' >> "$TMPB64"
    printf '%s' 'ZmllcgogICAgICAgICAgICAgICAgICAgIC5jbGlja2FibGUgeyBvbkJhY2soKSB9CiAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgLnBhZGRpbmcoaG9yaXpvbnRhbCA9IDEyLmRwLCB2ZXJ0aWNhbCA9IDQuZHAp' >> "$TMPB64"
    printf '%s' 'LAogICAgICAgICAgICApCiAgICAgICAgICAgIFRleHQoCiAgICAgICAgICAgICAgICB0ZXh0ID0g' >> "$TMPB64"
    printf '%s' 'IuWjgee6uOiuvue9riIsCiAgICAgICAgICAgICAgICBzdHlsZSA9IE1hdGVyaWFsVGhlbWUudHlw' >> "$TMPB64"
    printf '%s' 'b2dyYXBoeS50aXRsZUxhcmdlLmNvcHkoZm9udFdlaWdodCA9IEZvbnRXZWlnaHQuQm9sZCksCiAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICBjb2xvciA9IG11c2ljQ29sb3JzKCkudGV4dFByaW1hcnksCiAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICkKICAgICAgICB9CiAgICAgICAgTGF6eUNvbHVtbigKICAgICAgICAgICAgbW9kaWZpZXIg' >> "$TMPB64"
    printf '%s' 'PSBNb2RpZmllci5maWxsTWF4U2l6ZSgpLAogICAgICAgICAgICBjb250ZW50UGFkZGluZyA9IFBh' >> "$TMPB64"
    printf '%s' 'ZGRpbmdWYWx1ZXMoMTYuZHApLAogICAgICAgICAgICB2ZXJ0aWNhbEFycmFuZ2VtZW50ID0gQXJy' >> "$TMPB64"
    printf '%s' 'YW5nZW1lbnQuc3BhY2VkQnkoMTYuZHApLAogICAgICAgICkgewogICAgICAgICAgICBpdGVtIHsK' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgIENhcmQoCiAgICAgICAgICAgICAgICAgICAgY29sb3JzID0gQ2FyZERl' >> "$TMPB64"
    printf '%s' 'ZmF1bHRzLmNhcmRDb2xvcnMoY29udGFpbmVyQ29sb3IgPSBtdXNpY0NvbG9ycygpLmNhcmQpLAog' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgIHNoYXBlID0gUm91bmRlZENvcm5lclNoYXBlKDE2LmRwKSwKICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICkgewogICAgICAgICAgICAgICAgICAgIFJvdygKICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgbW9kaWZpZXIgPSBNb2RpZmllcgogICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'LmZpbGxNYXhXaWR0aCgpCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAucGFkZGluZygxNi5k' >> "$TMPB64"
    printf '%s' 'cCksCiAgICAgICAgICAgICAgICAgICAgICAgIHZlcnRpY2FsQWxpZ25tZW50ID0gQWxpZ25tZW50' >> "$TMPB64"
    printf '%s' 'LkNlbnRlclZlcnRpY2FsbHksCiAgICAgICAgICAgICAgICAgICAgKSB7CiAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgIENvbHVtbihtb2RpZmllciA9IE1vZGlmaWVyLndlaWdodCgxZikpIHsKICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgIFRleHQoIuWQr+eUqOWjgee6uOiDjOaZryIsIHN0eWxlID0g' >> "$TMPB64"
    printf '%s' 'TWF0ZXJpYWxUaGVtZS50eXBvZ3JhcGh5LmJvZHlMYXJnZSwgY29sb3IgPSBtdXNpY0NvbG9ycygp' >> "$TMPB64"
    printf '%s' 'LnRleHRQcmltYXJ5KQogICAgICAgICAgICAgICAgICAgICAgICAgICAgU3BhY2VyKG1vZGlmaWVy' >> "$TMPB64"
    printf '%s' 'ID0gTW9kaWZpZXIuaGVpZ2h0KDIuZHApKQogICAgICAgICAgICAgICAgICAgICAgICAgICAgVGV4' >> "$TMPB64"
    printf '%s' 'dCgi6Z+z5LmQ5LiT5Yy65bqV5bGC6IOM5pmv5Zu+77yI5bim5Y+v6K+75oCn6YGu572p77yJIiwg' >> "$TMPB64"
    printf '%s' 'c3R5bGUgPSBNYXRlcmlhbFRoZW1lLnR5cG9ncmFwaHkuYm9keVNtYWxsLCBjb2xvciA9IG11c2lj' >> "$TMPB64"
    printf '%s' 'Q29sb3JzKCkudGV4dFNlY29uZGFyeSkKICAgICAgICAgICAgICAgICAgICAgICAgfQogICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICBTd2l0Y2goCiAgICAgICAgICAgICAgICAgICAgICAgICAgICBjaGVj' >> "$TMPB64"
    printf '%s' 'a2VkID0gd3BTdGF0ZS5lbmFibGVkLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgb25DaGVj' >> "$TMPB64"
    printf '%s' 'a2VkQ2hhbmdlID0geyBXYWxscGFwZXJNYW5hZ2VyLnNldEVuYWJsZWQoY29udGV4dCwgaXQpIH0s' >> "$TMPB64"
    printf '%s' 'CiAgICAgICAgICAgICAgICAgICAgICAgICAgICBjb2xvcnMgPSBTd2l0Y2hEZWZhdWx0cy5jb2xv' >> "$TMPB64"
    printf '%s' 'cnMoCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgY2hlY2tlZFRodW1iQ29sb3IgPSBD' >> "$TMPB64"
    printf '%s' 'b2xvci5XaGl0ZSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBjaGVja2VkVHJhY2tD' >> "$TMPB64"
    printf '%s' 'b2xvciA9IG11c2ljQ29sb3JzKCkuYWNjZW50LAogICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgIHVuY2hlY2tlZFRodW1iQ29sb3IgPSBDb2xvci5XaGl0ZSwKICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICB1bmNoZWNrZWRUcmFja0NvbG9yID0gbXVzaWNDb2xvcnMoKS5jYXJkU2Vj' >> "$TMPB64"
    printf '%s' 'b25kYXJ5LAogICAgICAgICAgICAgICAgICAgICAgICAgICAgKSwKICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgKQogICAgICAgICAgICAgICAgICAgIH0KICAgICAgICAgICAgICAgIH0KICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgfQogICAgICAgICAgICBpdGVtIHsKICAgICAgICAgICAgICAgIENhcmQoCiAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgY29sb3JzID0gQ2FyZERlZmF1bHRzLmNhcmRDb2xvcnMoY29udGFpbmVyQ29sb3Ig' >> "$TMPB64"
    printf '%s' 'PSBtdXNpY0NvbG9ycygpLmNhcmQpLAogICAgICAgICAgICAgICAgICAgIHNoYXBlID0gUm91bmRl' >> "$TMPB64"
    printf '%s' 'ZENvcm5lclNoYXBlKDE2LmRwKSwKICAgICAgICAgICAgICAgICkgewogICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgIENvbHVtbihtb2RpZmllciA9IE1vZGlmaWVyLnBhZGRpbmcoMTYuZHApKSB7CiAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgIFRleHQoIue9kee7nOWjgee6uCIsIHN0eWxlID0gTWF0ZXJpYWxUaGVt' >> "$TMPB64"
    printf '%s' 'ZS50eXBvZ3JhcGh5LmJvZHlMYXJnZSwgY29sb3IgPSBtdXNpY0NvbG9ycygpLnRleHRQcmltYXJ5' >> "$TMPB64"
    printf '%s' 'KQogICAgICAgICAgICAgICAgICAgICAgICBTcGFjZXIobW9kaWZpZXIgPSBNb2RpZmllci5oZWln' >> "$TMPB64"
    printf '%s' 'aHQoMTAuZHApKQogICAgICAgICAgICAgICAgICAgICAgICBPdXRsaW5lZFRleHRGaWVsZCgKICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlID0gdXJsVGV4dCwKICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgIG9uVmFsdWVDaGFuZ2UgPSB7IHVybFRleHQgPSBpdCB9LAogICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgbGFiZWwgPSB7IFRleHQoIuWbvueJhyBVUkzvvIhodHRwL2h0dHBz' >> "$TMPB64"
    printf '%s' '77yJIikgfSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgIHNpbmdsZUxpbmUgPSB0cnVlLAog' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgbW9kaWZpZXIgPSBNb2RpZmllci5maWxsTWF4V2lk' >> "$TMPB64"
    printf '%s' 'dGgoKSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNvbG9ycyA9IE91dGxpbmVkVGV4dEZp' >> "$TMPB64"
    printf '%s' 'ZWxkRGVmYXVsdHMuY29sb3JzKAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGZvY3Vz' >> "$TMPB64"
    printf '%s' 'ZWRCb3JkZXJDb2xvciA9IG11c2ljQ29sb3JzKCkuYWNjZW50LAogICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgIHVuZm9jdXNlZEJvcmRlckNvbG9yID0gbXVzaWNDb2xvcnMoKS5kaXZpZGVy' >> "$TMPB64"
    printf '%s' 'LAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGN1cnNvckNvbG9yID0gbXVzaWNDb2xv' >> "$TMPB64"
    printf '%s' 'cnMoKS5hY2NlbnQsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZm9jdXNlZExhYmVs' >> "$TMPB64"
    printf '%s' 'Q29sb3IgPSBtdXNpY0NvbG9ycygpLmFjY2VudCwKICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICB1bmZvY3VzZWRMYWJlbENvbG9yID0gbXVzaWNDb2xvcnMoKS50ZXh0U2Vjb25kYXJ5LAog' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGZvY3VzZWRUZXh0Q29sb3IgPSBtdXNpY0Nv' >> "$TMPB64"
    printf '%s' 'bG9ycygpLnRleHRQcmltYXJ5LAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHVuZm9j' >> "$TMPB64"
    printf '%s' 'dXNlZFRleHRDb2xvciA9IG11c2ljQ29sb3JzKCkudGV4dFByaW1hcnksCiAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICApLAogICAgICAgICAgICAgICAgICAgICAgICApCiAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgIFNwYWNlcihtb2RpZmllciA9IE1vZGlmaWVyLmhlaWdodCgxMi5kcCkpCiAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgIFJvdyB7CiAgICAgICAgICAgICAgICAgICAgICAgICAgICBCdXR0' >> "$TMPB64"
    printf '%s' 'b24oCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgb25DbGljayA9IHsgV2FsbHBhcGVy' >> "$TMPB64"
    printf '%s' 'TWFuYWdlci5hcHBseShjb250ZXh0LCB1cmxUZXh0KSB9LAogICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgIGNvbG9ycyA9IEJ1dHRvbkRlZmF1bHRzLmJ1dHRvbkNvbG9ycygKICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgY29udGFpbmVyQ29sb3IgPSBtdXNpY0NvbG9ycygp' >> "$TMPB64"
    printf '%s' 'LmFjY2VudCwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgY29udGVudENvbG9y' >> "$TMPB64"
    printf '%s' 'ID0gbXVzaWNDb2xvcnMoKS5hY2NlbnRUZXh0LAogICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICksCiAgICAgICAgICAgICAgICAgICAgICAgICAgICApIHsgVGV4dCgi5bqU55So5q2kIFVS' >> "$TMPB64"
    printf '%s' 'TCIpIH0KICAgICAgICAgICAgICAgICAgICAgICAgICAgIFNwYWNlcihtb2RpZmllciA9IE1vZGlm' >> "$TMPB64"
    printf '%s' 'aWVyLndpZHRoKDEwLmRwKSkKICAgICAgICAgICAgICAgICAgICAgICAgICAgIE91dGxpbmVkQnV0' >> "$TMPB64"
    printf '%s' 'dG9uKG9uQ2xpY2sgPSB7IHBpY2tlci5sYXVuY2goYXJyYXlPZigiaW1hZ2UvKiIpKSB9KSB7CiAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgVGV4dCgi5pys5Zyw6YCJ5Zu+IiwgY29sb3Ig' >> "$TMPB64"
    printf '%s' 'PSBtdXNpY0NvbG9ycygpLnRleHRQcmltYXJ5KQogICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'fQogICAgICAgICAgICAgICAgICAgICAgICB9CiAgICAgICAgICAgICAgICAgICAgfQogICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgfQogICAgICAgICAgICB9CiAgICAgICAgICAgIGlmICh3cFN0YXRlLmhpc3Rvcnku' >> "$TMPB64"
    printf '%s' 'aXNOb3RFbXB0eSgpKSB7CiAgICAgICAgICAgICAgICBpdGVtIHsKICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICBUZXh0KAogICAgICAgICAgICAgICAgICAgICAgICB0ZXh0ID0gIuWOhuWPsuWjgee6uCIsCiAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgIHN0eWxlID0gTWF0ZXJpYWxUaGVtZS50eXBvZ3JhcGh5LnRp' >> "$TMPB64"
    printf '%s' 'dGxlTWVkaXVtLmNvcHkoZm9udFdlaWdodCA9IEZvbnRXZWlnaHQuQm9sZCksCiAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgIGNvbG9yID0gbXVzaWNDb2xvcnMoKS50ZXh0UHJpbWFyeSwKICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICApCiAgICAgICAgICAgICAgICB9CiAgICAgICAgICAgICAgICBpdGVtIHsKICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICBMYXp5Um93KGhvcml6b250YWxBcnJhbmdlbWVudCA9IEFycmFuZ2Vt' >> "$TMPB64"
    printf '%s' 'ZW50LnNwYWNlZEJ5KDEwLmRwKSkgewogICAgICAgICAgICAgICAgICAgICAgICBpdGVtcyh3cFN0' >> "$TMPB64"
    printf '%s' 'YXRlLmhpc3RvcnksIGtleSA9IHsgaXQgfSkgeyB1IC0+CiAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICB2YWwgaXNDdXJyZW50ID0gdSA9PSB3cFN0YXRlLnVybAogICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgQm94KAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIG1vZGlmaWVyID0g' >> "$TMPB64"
    printf '%s' 'TW9kaWZpZXIKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgLnNpemUoODQuZHAp' >> "$TMPB64"
    printf '%s' 'CiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIC5jbGlwKFJvdW5kZWRDb3JuZXJT' >> "$TMPB64"
    printf '%s' 'aGFwZSgxMi5kcCkpCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIC5iYWNrZ3Jv' >> "$TMPB64"
    printf '%s' 'dW5kKG11c2ljQ29sb3JzKCkuY2FyZFNlY29uZGFyeSkKICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgLnRoZW4oCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICBpZiAoaXNDdXJyZW50KSBNb2RpZmllci5ib3JkZXIoMi5kcCwgbXVzaWNDb2xvcnMoKS5hY2Nl' >> "$TMPB64"
    printf '%s' 'bnQsIFJvdW5kZWRDb3JuZXJTaGFwZSgxMi5kcCkpCiAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICBlbHNlIE1vZGlmaWVyCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICkKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgLmNsaWNrYWJsZSB7' >> "$TMPB64"
    printf '%s' 'CiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBXYWxscGFwZXJNYW5hZ2Vy' >> "$TMPB64"
    printf '%s' 'LmFwcGx5KGNvbnRleHQsIHUpCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICB1cmxUZXh0ID0gdQogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB9LAogICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgKSB7CiAgICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgQXN5bmNJbWFnZSgKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgbW9kZWwg' >> "$TMPB64"
    printf '%s' 'PSBJbWFnZVJlcXVlc3QuQnVpbGRlcihjb250ZXh0KS5kYXRhKHUpLnNpemUoMjQwKS5idWlsZCgp' >> "$TMPB64"
    printf '%s' 'LAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBjb250ZW50RGVzY3JpcHRpb24g' >> "$TMPB64"
    printf '%s' 'PSBudWxsLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBjb250ZW50U2NhbGUg' >> "$TMPB64"
    printf '%s' 'PSBDb250ZW50U2NhbGUuQ3JvcCwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'bW9kaWZpZXIgPSBNb2RpZmllci5maWxsTWF4U2l6ZSgpLAogICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICkKICAgICAgICAgICAgICAgICAgICAgICAgICAgIH0KICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgfQogICAgICAgICAgICAgICAgICAgIH0KICAgICAgICAgICAgICAgIH0KICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgfQogICAgICAgICAgICBpdGVtIHsKICAgICAgICAgICAgICAgIFRleHQoCiAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgdGV4dCA9ICLlo4HnurjkvY3kuo7pn7PkuZDkuJPljLrmnIDlupXlsYLvvIzl' >> "$TMPB64"
    printf '%s' 'hbbkuIrnm5bmnInlj6/or7vmgKfpga7nvanvvIjmt7HoibIgNjAlIOm7kSAvIOa1heiJsiA3MCUg' >> "$TMPB64"
    printf '%s' '55m977yJ77yM5paH5a2X5aeL57uI5riF5pmw77yb6IOM5pmv5Zu+5oyJ5bGP5bmV5bC65a+45bCB' >> "$TMPB64"
    printf '%s' '6aG25Yqg6L2977yM5LiN5b2x5ZON5YiX6KGo5ruR5Yqo44CC5pys5Zyw5Zu+54mH5L2/55So57O7' >> "$TMPB64"
    printf '%s' '57uf5paH5Lu26YCJ5oup5Zmo5bm255Sz6K+35oyB5LmF5o6I5p2D77yM6YeN5ZCv5LiN5aSx5pWI' >> "$TMPB64"
    printf '%s' '44CCIiwKICAgICAgICAgICAgICAgICAgICBzdHlsZSA9IE1hdGVyaWFsVGhlbWUudHlwb2dyYXBo' >> "$TMPB64"
    printf '%s' 'eS5ib2R5U21hbGwsCiAgICAgICAgICAgICAgICAgICAgY29sb3IgPSBtdXNpY0NvbG9ycygpLnRl' >> "$TMPB64"
    printf '%s' 'eHRTZWNvbmRhcnksCiAgICAgICAgICAgICAgICApCiAgICAgICAgICAgIH0KICAgICAgICB9CiAg' >> "$TMPB64"
    printf '%s' 'ICB9Cn0K' >> "$TMPB64"
base64 -d "$TMPB64" > avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxWallpaperSettingsActivity.kt
rm -f "$TMPB64"
grep -q 'class LxWallpaperSettingsActivity' avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxWallpaperSettingsActivity.kt || { echo "X 39 class LxWallpaperSettingsActivity 写入失败"; exit 1; }
echo "[39] MusicHome 外壳接壁纸层 + 六页根背景透出 + 设置入口"
echo "[39] MusicHome 外壳接壁纸层 + 六页根背景透出 + 设置入口"
echo "[39] MusicHome 外壳接壁纸层 + 六页根背景透出 + 设置入口"
python3 << 'PYEOF39'
import io, sys, os
while not os.path.exists('avbox/app/src/main/AndroidManifest.xml') and os.getcwd() != '/':
    os.chdir('..')

BASE = 'avbox/app/src/main/java/com/github/tvbox/osc/'
FQ_COLOR = 'androidx.compose.ui.graphics.Color.Transparent'
WP_CHECK = 'com.github.tvbox.osc.ui.activity.WallpaperManager.isActive()'

def load(p):
    with io.open(p, encoding='utf-8') as f:
        return f.read()

def save(p, s):
    with io.open(p, 'w', encoding='utf-8', newline='\n') as f:
        f.write(s)

def rep(s, old, new, tag, cnt=1):
    n = s.count(old)
    assert n == cnt, '❌ [39] %s 锚点数量异常: %d' % (tag, n)
    return s.replace(old, new, cnt)

# ============ 0) manifest 注册壁纸页 ============
MP = 'avbox/app/src/main/AndroidManifest.xml'
m = load(MP)
if 'LxWallpaperSettingsActivity' not in m:
    assert '</application>' in m, '❌ [39] manifest 无 </application>'
    act = '<activity android:name=".ui.activity.LxWallpaperSettingsActivity" android:exported="false" />'
    m = m.replace('</application>', '        ' + act + '\n    </application>', 1)
    save(MP, m)
    print('OK manifest 壁纸页已注册')
else:
    print('SKIP manifest 已注册')

# ============ 1) MusicHomeActivity ============
MH = BASE + 'ui/activity/MusicHomeActivity.kt'
h = load(MH)
if '[39wp1]' not in h:
    h = rep(h,
        'fun MusicHomeScreen(initialTab: MusicTab = MusicTab.SEARCH, onBackToAppHome: () -> Unit) { // [15tab1]\n    val context = LocalContext.current\n',
        'fun MusicHomeScreen(initialTab: MusicTab = MusicTab.SEARCH, onBackToAppHome: () -> Unit) { // [15tab1]\n    val context = LocalContext.current\n'
        '    val wpState by WallpaperManager.state.collectAsState() // [39wp1] 壁纸状态\n'
        '    val wpActive = wpState.enabled && wpState.url.isNotBlank() // [39wp1]\n'
        '    val wpDark by MusicThemeManager.isDarkTheme // [39wp1]\n'
        '    val wpReq = remember(wpState.url) { // [39wp1] 背景请求: 尺寸上限+稳定缓存键\n'
        '        if (wpState.url.isBlank()) null else coil.request.ImageRequest.Builder(context).data(wpState.url).size(1080, 2400).memoryCacheKey("wp_" + wpState.url.hashCode()).build()\n'
        '    }\n'
        '    LaunchedEffect(Unit) { WallpaperManager.init(context) } // [39wp1]\n',
        'MH-init')
    h = rep(h,
        '        containerColor = musicColors().background,',
        '        containerColor = if (wpActive) Color.Transparent else musicColors().background, // [39wp1]',
        'MH-scaffold')
    # 整框包裹 Scaffold: 壁纸+遮罩垫底(顶栏已经32改透明, 底栏半透, 均可透出)
    assert h.count('    Scaffold(') == 1, '❌ [39] MH-wrap Scaffold 数量异常'
    base = h.index('fun MusicHomeScreen')
    si = h.index('    Scaffold(', base)
    layer = ('    Box(modifier = Modifier.fillMaxSize()) { // [39wp1] 壁纸底层(图+遮罩)\n'
             '        if (wpActive && wpReq != null) {\n'
             '            coil.compose.AsyncImage(model = wpReq, contentDescription = null, contentScale = androidx.compose.ui.layout.ContentScale.Crop, modifier = Modifier.fillMaxSize())\n'
             '            Box(modifier = Modifier.fillMaxSize().background(if (wpDark) Color.Black.copy(alpha = 0.6f) else Color.White.copy(alpha = 0.7f)))\n'
             '        }\n')
    h = h[:si] + layer + h[si:]
    i = si + len(layer)
    dp = 0; db = 0; seen_close = False; end = -1; j = i
    while j < len(h):
        c = h[j]
        if c == '(':
            dp += 1
        elif c == ')':
            dp -= 1
            if dp == 0:
                seen_close = True
        elif c == '{':
            db += 1
        elif c == '}':
            db -= 1
            if seen_close and db == 0:
                end = j; break
        j += 1
    assert end > 0, '❌ [39] MH-wrap 找不到 Scaffold 结尾'
    h = h[:end + 1] + '\n    } // [39wp1] 壁纸底层 Box 结束' + h[end + 1:]
    print('OK MH 壁纸层整框包裹完成')
    # 设置入口: 播放历史之前插入(沿用该行缩进)
    lines = h.split('\n')
    idx = [k for k, ln in enumerate(lines) if 'SettingItem("播放历史", "最近播放的歌曲")' in ln]
    assert len(idx) == 1, '❌ [39] MH-entry 锚点数量异常: %d' % len(idx)
    k = idx[0]
    ind = lines[k][:len(lines[k]) - len(lines[k].lstrip())]
    block = [
        ind + 'SettingItem("壁纸设置", "自定义背景图") { // [39wp1]',
        ind + '    context.startActivity(android.content.Intent(context, com.github.tvbox.osc.ui.activity.LxWallpaperSettingsActivity::class.java))',
        ind + '},',
    ]
    lines[k:k] = block
    h = '\n'.join(lines)
    save(MH, h)
    print('OK MusicHomeActivity 壁纸接线完成')
else:
    print('SKIP MusicHomeActivity 已有 [39wp1]')

# ============ 2) 六页根背景: 壁纸开启时透明 ============
def page_bg(rel, tag, after_fun=None):
    p = BASE + rel
    s = load(p)
    if '[39wp1]' in s:
        print('SKIP', tag, '已有标记'); return
    start = s.index(after_fun) if after_fun else 0
    old = '.background(musicColors().background)'
    pos = s.find(old, start)
    assert pos > 0, '❌ [39] %s 根背景锚点缺失' % tag
    new = '.background(if (' + WP_CHECK + ') ' + FQ_COLOR + ' else musicColors().background)'
    s = s[:pos] + new + s[pos + len(old):]
    # 文件级标记: package 行后加注释(幂等判据)
    pl = s.index('\n', s.index('package '))
    s = s[:pl + 1] + '// [39wp1] 本页根背景已接壁纸透出\n' + s[pl + 1:]
    save(p, s)
    print('OK', tag, '根背景已接壁纸透出')

page_bg('ui/music/settings/SettingsScreen.kt', 'SettingsScreen')
page_bg('ui/music/search/SearchResultScreen.kt', 'SearchResultScreen')
page_bg('ui/music/rank/RankScreen.kt', 'RankScreen')
page_bg('ui/music/playlist/PlaylistScreen.kt', 'PlaylistScreen')
page_bg('ui/music/playlist/UserPlaylistScreen.kt', 'UserPlaylistScreen')
page_bg('ui/music/search/SearchScreen.kt', 'SearchScreen', after_fun='fun SearchScreen(')
print('[39] 全部补丁完成')
PYEOF39

echo "=== 39 wp1 完成 ==="
