#!/bin/bash
set -e
# 37 - 均衡器页（新功能，须排在 15 之后、35 之前；build.yml 调用行由用户手动加在 36 后、35 前）
# 写 LxEqSettingsActivity（6 维滑块+预设+开关；只写 eq_settings prefs 并调 Manager.applyEqFromPrefs，
# 频段映射/钳制在 21 v32 的 Manager 侧）；manifest 注册 Activity + 补 MODIFY_AUDIO_SETTINGS 权限；
# 设置页「均衡器」入口改跳本页。Manager 侧挂载在 21 v32，本脚本不碰 Manager。

cd "$(dirname "$0")/../.."
echo "=== 37 EQ 页 ==="

mkdir -p avbox/app/src/main/java/com/github/tvbox/osc/ui/activity

TMPB64=$(mktemp)
    printf '%s' 'cGFja2FnZSBjb20uZ2l0aHViLnR2Ym94Lm9zYy51aS5hY3Rpdml0eQoKaW1wb3J0IGFuZHJvaWQu' >> "$TMPB64"
    printf '%s' 'Y29udGVudC5Db250ZXh0CmltcG9ydCBhbmRyb2lkLmNvbnRlbnQuSW50ZW50CmltcG9ydCBhbmRy' >> "$TMPB64"
    printf '%s' 'b2lkLm9zLkJ1bmRsZQppbXBvcnQgYW5kcm9pZHguYWN0aXZpdHkuQ29tcG9uZW50QWN0aXZpdHkK' >> "$TMPB64"
    printf '%s' 'aW1wb3J0IGFuZHJvaWR4LmFjdGl2aXR5LmNvbXBvc2Uuc2V0Q29udGVudAppbXBvcnQgYW5kcm9p' >> "$TMPB64"
    printf '%s' 'ZHguY29tcG9zZS5mb3VuZGF0aW9uLmJhY2tncm91bmQKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2Uu' >> "$TMPB64"
    printf '%s' 'Zm91bmRhdGlvbi5jbGlja2FibGUKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UuZm91bmRhdGlvbi5o' >> "$TMPB64"
    printf '%s' 'b3Jpem9udGFsU2Nyb2xsCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLmZvdW5kYXRpb24ubGF5b3V0' >> "$TMPB64"
    printf '%s' 'LioKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UuZm91bmRhdGlvbi5yZW1lbWJlclNjcm9sbFN0YXRl' >> "$TMPB64"
    printf '%s' 'CmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLmZvdW5kYXRpb24udmVydGljYWxTY3JvbGwKaW1wb3J0' >> "$TMPB64"
    printf '%s' 'IGFuZHJvaWR4LmNvbXBvc2UubWF0ZXJpYWwzLioKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UucnVu' >> "$TMPB64"
    printf '%s' 'dGltZS4qCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLnVpLkFsaWdubWVudAppbXBvcnQgYW5kcm9p' >> "$TMPB64"
    printf '%s' 'ZHguY29tcG9zZS51aS5Nb2RpZmllcgppbXBvcnQgYW5kcm9pZHguY29tcG9zZS51aS5wbGF0Zm9y' >> "$TMPB64"
    printf '%s' 'bS5Mb2NhbENvbnRleHQKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UudWkudGV4dC5mb250LkZvbnRX' >> "$TMPB64"
    printf '%s' 'ZWlnaHQKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UudWkudW5pdC5kcAppbXBvcnQgYW5kcm9pZHgu' >> "$TMPB64"
    printf '%s' 'Y29yZS52aWV3LldpbmRvd0NvbXBhdAoKLy8gWzM3ZXExXSDlnYfooaHlmajpobXvvJo2IOe7tOaE' >> "$TMPB64"
    printf '%s' 'n+efpea7keWdl++8iOi2heS9jumikS/kvY7popEv5Lit6aKRL+a4heaZsOW6pi/pq5jpopEv5rCb' >> "$TMPB64"
    printf '%s' '5Zu05oSf77yJKyDpooTorr7jgIIKLy8g6aG16Z2i5Y+q5YaZIFNoYXJlZFByZWZlcmVuY2VzKCJl' >> "$TMPB64"
    printf '%s' 'cV9zZXR0aW5ncyIpIOW5tuiwgyBMeFBsYXllck1hbmFnZXIuYXBwbHlFcUZyb21QcmVmcygpIOmH' >> "$TMPB64"
    printf '%s' 'jeW6lOeUqO+8mwovLyDpopHmrrXmmKDlsITkuI7lop7nm4rpkrPliLblhajpg6jlnKggTWFuYWdl' >> "$TMPB64"
    printf '%s' 'ciDkvqfmjInorr7lpIflrp7mtYvlrozmiJDvvIhnZXRCYW5kL2dldEJhbmRMZXZlbFJhbmdl77yJ' >> "$TMPB64"
    printf '%s' '77yM5pys6aG15LiN56KwIEVxdWFsaXplcuOAggpjbGFzcyBMeEVxU2V0dGluZ3NBY3Rpdml0eSA6' >> "$TMPB64"
    printf '%s' 'IENvbXBvbmVudEFjdGl2aXR5KCkgewogICAgb3ZlcnJpZGUgZnVuIG9uQ3JlYXRlKHNhdmVkSW5z' >> "$TMPB64"
    printf '%s' 'dGFuY2VTdGF0ZTogQnVuZGxlPykgewogICAgICAgIHN1cGVyLm9uQ3JlYXRlKHNhdmVkSW5zdGFu' >> "$TMPB64"
    printf '%s' 'Y2VTdGF0ZSkKICAgICAgICB2YWwgYXBwQ3R4ID0gYXBwbGljYXRpb25Db250ZXh0CiAgICAgICAg' >> "$TMPB64"
    printf '%s' 'TXVzaWNUaGVtZU1hbmFnZXIuaW5pdChhcHBDdHgpCiAgICAgICAgc2V0Q29udGVudCB7CiAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgIHZhbCBpc0RhcmsgYnkgTXVzaWNUaGVtZU1hbmFnZXIuaXNEYXJrVGhlbWUKICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgdmFsIHdpbmRvdyA9IHRoaXNATHhFcVNldHRpbmdzQWN0aXZpdHkud2luZG93CiAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgIFNpZGVFZmZlY3QgewogICAgICAgICAgICAgICAgV2luZG93Q29tcGF0LmdldEluc2V0' >> "$TMPB64"
    printf '%s' 'c0NvbnRyb2xsZXIod2luZG93LCB3aW5kb3cuZGVjb3JWaWV3KQogICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'IC5pc0FwcGVhcmFuY2VMaWdodFN0YXR1c0JhcnMgPSAhaXNEYXJrCiAgICAgICAgICAgIH0KICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgTHhNdXNpY1RoZW1lKGlzRGFya1RoZW1lID0gaXNEYXJrKSB7CiAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICBFcVNldHRpbmdzU2NyZWVuKG9uQmFjayA9IHsgZmluaXNoKCkgfSkKICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'fQogICAgICAgIH0KICAgIH0KfQoKcHJpdmF0ZSB2YWwgRVFfS0VZUyA9IGxpc3RPZigic3ViIiwg' >> "$TMPB64"
    printf '%s' 'ImxvdyIsICJtaWQiLCAiY2xhcml0eSIsICJoaWdoIiwgImFtYiIpCnByaXZhdGUgdmFsIEVRX0xB' >> "$TMPB64"
    printf '%s' 'QkVMUyA9IGxpc3RPZigKICAgICLotoXkvY7popEiIHRvICI2MEh6IMK3IOS4i+a9nCIsCiAgICAi' >> "$TMPB64"
    printf '%s' '5L2O6aKRIiB0byAiMjMwSHogwrcg5Yqb6YePIiwKICAgICLkuK3popEiIHRvICI5MTBIeiDCtyDk' >> "$TMPB64"
    printf '%s' 'urrlo7AiLAogICAgIua4heaZsOW6piIgdG8gIjNrSHogwrcg5ZCQ5a2XIiwKICAgICLpq5jpopEi' >> "$TMPB64"
    printf '%s' 'IHRvICIxNGtIeiDCtyDmmI7kuq4iLAogICAgIuawm+WbtOaEnyIgdG8gIjNrKzE0ayDCtyDnjrDl' >> "$TMPB64"
    printf '%s' 'nLoiCikKCi8vIOmihOiuvumhuuW6j+S4jiBFUV9LRVlTIOWvuem9kO+8mnN1YiwgbG93LCBtaWQs' >> "$TMPB64"
    printf '%s' 'IGNsYXJpdHksIGhpZ2gsIGFtYu+8iOWNleS9jSBkQu+8iQpwcml2YXRlIHZhbCBFUV9QUkVTRVRT' >> "$TMPB64"
    printf '%s' 'OiBMaXN0PFBhaXI8U3RyaW5nLCBMaXN0PEZsb2F0Pj4+ID0gbGlzdE9mKAogICAgIuW5s+ebtCIg' >> "$TMPB64"
    printf '%s' 'dG8gbGlzdE9mKDBmLCAwZiwgMGYsIDBmLCAwZiwgMGYpLAogICAgIuS9jumfs+WinuW8uiIgdG8g' >> "$TMPB64"
    printf '%s' 'bGlzdE9mKDZmLCA0ZiwgMGYsIDBmLCAwZiwgMWYpLAogICAgIuS6uuWjsOeqgeWHuiIgdG8gbGlz' >> "$TMPB64"
    printf '%s' 'dE9mKC0yZiwgMGYsIDNmLCA1ZiwgMmYsIDBmKSwKICAgICLmkYfmu5oiIHRvIGxpc3RPZig1Ziwg' >> "$TMPB64"
    printf '%s' 'M2YsIC0xZiwgM2YsIDVmLCAyZiksCiAgICAi5Y+k5YW4IiB0byBsaXN0T2YoM2YsIDJmLCAwZiwg' >> "$TMPB64"
    printf '%s' 'MmYsIDRmLCAzZiksCiAgICAi5piO5LquIiB0byBsaXN0T2YoMGYsIDBmLCAxZiwgNGYsIDdmLCAz' >> "$TMPB64"
    printf '%s' 'ZikKKQoKcHJpdmF0ZSBmdW4gbG9hZEVxR2FpbnMoY29udGV4dDogQ29udGV4dCk6IExpc3Q8Rmxv' >> "$TMPB64"
    printf '%s' 'YXQ+IHsKICAgIHZhbCBwcmVmcyA9IGNvbnRleHQuZ2V0U2hhcmVkUHJlZmVyZW5jZXMoImVxX3Nl' >> "$TMPB64"
    printf '%s' 'dHRpbmdzIiwgQ29udGV4dC5NT0RFX1BSSVZBVEUpCiAgICByZXR1cm4gRVFfS0VZUy5tYXAgeyBr' >> "$TMPB64"
    printf '%s' 'IC0+IHRyeSB7IHByZWZzLmdldEZsb2F0KGssIDBmKSB9IGNhdGNoIChfOiBFeGNlcHRpb24pIHsg' >> "$TMPB64"
    printf '%s' 'MGYgfSB9Cn0KCnByaXZhdGUgZnVuIHNhdmVFcShjb250ZXh0OiBDb250ZXh0LCBlbmFibGVkOiBC' >> "$TMPB64"
    printf '%s' 'b29sZWFuLCBnYWluczogTGlzdDxGbG9hdD4pIHsKICAgIHRyeSB7CiAgICAgICAgdmFsIGUgPSBj' >> "$TMPB64"
    printf '%s' 'b250ZXh0LmdldFNoYXJlZFByZWZlcmVuY2VzKCJlcV9zZXR0aW5ncyIsIENvbnRleHQuTU9ERV9Q' >> "$TMPB64"
    printf '%s' 'UklWQVRFKS5lZGl0KCkKICAgICAgICBlLnB1dEJvb2xlYW4oIm9uIiwgZW5hYmxlZCkKICAgICAg' >> "$TMPB64"
    printf '%s' 'ICBFUV9LRVlTLmZvckVhY2hJbmRleGVkIHsgaSwgayAtPiBlLnB1dEZsb2F0KGssIGdhaW5zLmdl' >> "$TMPB64"
    printf '%s' 'dE9yRWxzZShpKSB7IDBmIH0pIH0KICAgICAgICBlLmFwcGx5KCkKICAgIH0gY2F0Y2ggKF86IEV4' >> "$TMPB64"
    printf '%s' 'Y2VwdGlvbikgewogICAgfQogICAgTHhQbGF5ZXJNYW5hZ2VyLmFwcGx5RXFGcm9tUHJlZnMoKQp9' >> "$TMPB64"
    printf '%s' 'CgpAQ29tcG9zYWJsZQpmdW4gRXFTZXR0aW5nc1NjcmVlbihvbkJhY2s6ICgpIC0+IFVuaXQpIHsK' >> "$TMPB64"
    printf '%s' 'ICAgIHZhbCBjb250ZXh0ID0gTG9jYWxDb250ZXh0LmN1cnJlbnQKICAgIHZhciBlbmFibGVkIGJ5' >> "$TMPB64"
    printf '%s' 'IHJlbWVtYmVyIHsKICAgICAgICBtdXRhYmxlU3RhdGVPZigKICAgICAgICAgICAgdHJ5IHsKICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgIGNvbnRleHQuZ2V0U2hhcmVkUHJlZmVyZW5jZXMoImVxX3NldHRpbmdzIiwg' >> "$TMPB64"
    printf '%s' 'Q29udGV4dC5NT0RFX1BSSVZBVEUpLmdldEJvb2xlYW4oIm9uIiwgZmFsc2UpCiAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'IH0gY2F0Y2ggKF86IEV4Y2VwdGlvbikgewogICAgICAgICAgICAgICAgZmFsc2UKICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgfQogICAgICAgICkKICAgIH0KICAgIHZhciBnYWlucyBieSByZW1lbWJlciB7IG11dGFibGVT' >> "$TMPB64"
    printf '%s' 'dGF0ZU9mKGxvYWRFcUdhaW5zKGNvbnRleHQpKSB9CiAgICB2YXIgcHJlc2V0TmFtZSBieSByZW1l' >> "$TMPB64"
    printf '%s' 'bWJlciB7IG11dGFibGVTdGF0ZU9mKCLoh6rlrprkuYkiKSB9CgogICAgQ29sdW1uKAogICAgICAg' >> "$TMPB64"
    printf '%s' 'IG1vZGlmaWVyID0gTW9kaWZpZXIKICAgICAgICAgICAgLmZpbGxNYXhTaXplKCkKICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgLmJhY2tncm91bmQobXVzaWNDb2xvcnMoKS5iYWNrZ3JvdW5kKQogICAgICAgICAgICAudmVy' >> "$TMPB64"
    printf '%s' 'dGljYWxTY3JvbGwocmVtZW1iZXJTY3JvbGxTdGF0ZSgpKQogICAgICAgICAgICAucGFkZGluZyho' >> "$TMPB64"
    printf '%s' 'b3Jpem9udGFsID0gMTYuZHApCiAgICApIHsKICAgICAgICBSb3coCiAgICAgICAgICAgIG1vZGlm' >> "$TMPB64"
    printf '%s' 'aWVyID0gTW9kaWZpZXIKICAgICAgICAgICAgICAgIC5maWxsTWF4V2lkdGgoKQogICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgLnBhZGRpbmcodG9wID0gMjQuZHAsIGJvdHRvbSA9IDguZHApLAogICAgICAgICAgICB2' >> "$TMPB64"
    printf '%s' 'ZXJ0aWNhbEFsaWdubWVudCA9IEFsaWdubWVudC5DZW50ZXJWZXJ0aWNhbGx5CiAgICAgICAgKSB7' >> "$TMPB64"
    printf '%s' 'CiAgICAgICAgICAgIFRleHQoCiAgICAgICAgICAgICAgICAi4oC5IiwKICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'IHN0eWxlID0gTWF0ZXJpYWxUaGVtZS50eXBvZ3JhcGh5LmhlYWRsaW5lTGFyZ2UsCiAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICBjb2xvciA9IG11c2ljQ29sb3JzKCkudGV4dFByaW1hcnksCiAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICBtb2RpZmllciA9IE1vZGlmaWVyCiAgICAgICAgICAgICAgICAgICAgLnBhZGRpbmcoZW5kID0g' >> "$TMPB64"
    printf '%s' 'OC5kcCkKICAgICAgICAgICAgICAgICAgICAuY2xpY2thYmxlIHsgb25CYWNrKCkgfQogICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICApCiAgICAgICAgICAgIFRleHQoCiAgICAgICAgICAgICAgICAi5Z2H6KGh5ZmoIiwKICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgIHN0eWxlID0gTWF0ZXJpYWxUaGVtZS50eXBvZ3JhcGh5LnRpdGxlTGFyZ2Us' >> "$TMPB64"
    printf '%s' 'CiAgICAgICAgICAgICAgICBmb250V2VpZ2h0ID0gRm9udFdlaWdodC5Cb2xkLAogICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgY29sb3IgPSBtdXNpY0NvbG9ycygpLnRleHRQcmltYXJ5CiAgICAgICAgICAgICkKICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgU3BhY2VyKE1vZGlmaWVyLndlaWdodCgxZikpCiAgICAgICAgICAgIFRleHRCdXR0' >> "$TMPB64"
    printf '%s' 'b24ob25DbGljayA9IHsKICAgICAgICAgICAgICAgIGdhaW5zID0gTGlzdCg2KSB7IDBmIH0KICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgIHByZXNldE5hbWUgPSAi5bmz55u0IgogICAgICAgICAgICAgICAgc2F2ZUVx' >> "$TMPB64"
    printf '%s' 'KGNvbnRleHQsIGVuYWJsZWQsIGdhaW5zKQogICAgICAgICAgICB9KSB7CiAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICBUZXh0KCLph43nva4iLCBjb2xvciA9IG11c2ljQ29sb3JzKCkuYWNjZW50KQogICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICB9CiAgICAgICAgfQoKICAgICAgICBDYXJkKAogICAgICAgICAgICBtb2RpZmllciA9IE1vZGlm' >> "$TMPB64"
    printf '%s' 'aWVyLmZpbGxNYXhXaWR0aCgpLAogICAgICAgICAgICBzaGFwZSA9IE1hdGVyaWFsVGhlbWUuc2hh' >> "$TMPB64"
    printf '%s' 'cGVzLmxhcmdlLAogICAgICAgICAgICBjb2xvcnMgPSBDYXJkRGVmYXVsdHMuY2FyZENvbG9ycyhj' >> "$TMPB64"
    printf '%s' 'b250YWluZXJDb2xvciA9IG11c2ljQ29sb3JzKCkuY2FyZCkKICAgICAgICApIHsKICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgUm93KAogICAgICAgICAgICAgICAgbW9kaWZpZXIgPSBNb2RpZmllcgogICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgIC5maWxsTWF4V2lkdGgoKQogICAgICAgICAgICAgICAgICAgIC5wYWRkaW5nKGhvcml6' >> "$TMPB64"
    printf '%s' 'b250YWwgPSAxNi5kcCwgdmVydGljYWwgPSAxNC5kcCksCiAgICAgICAgICAgICAgICB2ZXJ0aWNh' >> "$TMPB64"
    printf '%s' 'bEFsaWdubWVudCA9IEFsaWdubWVudC5DZW50ZXJWZXJ0aWNhbGx5CiAgICAgICAgICAgICkgewog' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgQ29sdW1uKE1vZGlmaWVyLndlaWdodCgxZikpIHsKICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICBUZXh0KAogICAgICAgICAgICAgICAgICAgICAgICAi5ZCv55So5Z2H6KGh5ZmoIiwK' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgc3R5bGUgPSBNYXRlcmlhbFRoZW1lLnR5cG9ncmFwaHku' >> "$TMPB64"
    printf '%s' 'Ym9keUxhcmdlLAogICAgICAgICAgICAgICAgICAgICAgICBjb2xvciA9IG11c2ljQ29sb3JzKCku' >> "$TMPB64"
    printf '%s' 'dGV4dFByaW1hcnkKICAgICAgICAgICAgICAgICAgICApCiAgICAgICAgICAgICAgICAgICAgVGV4' >> "$TMPB64"
    printf '%s' 'dCgKICAgICAgICAgICAgICAgICAgICAgICAgIuWFs+mXreWQjueri+WNs+aBouWkjeWOn+WjsCIs' >> "$TMPB64"
    printf '%s' 'CiAgICAgICAgICAgICAgICAgICAgICAgIHN0eWxlID0gTWF0ZXJpYWxUaGVtZS50eXBvZ3JhcGh5' >> "$TMPB64"
    printf '%s' 'LmJvZHlTbWFsbCwKICAgICAgICAgICAgICAgICAgICAgICAgY29sb3IgPSBtdXNpY0NvbG9ycygp' >> "$TMPB64"
    printf '%s' 'LnRleHRTZWNvbmRhcnkKICAgICAgICAgICAgICAgICAgICApCiAgICAgICAgICAgICAgICB9CiAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICBTd2l0Y2goCiAgICAgICAgICAgICAgICAgICAgY2hlY2tlZCA9IGVuYWJs' >> "$TMPB64"
    printf '%s' 'ZWQsCiAgICAgICAgICAgICAgICAgICAgb25DaGVja2VkQ2hhbmdlID0gewogICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICBlbmFibGVkID0gaXQKICAgICAgICAgICAgICAgICAgICAgICAgc2F2ZUVxKGNv' >> "$TMPB64"
    printf '%s' 'bnRleHQsIGVuYWJsZWQsIGdhaW5zKQogICAgICAgICAgICAgICAgICAgIH0sCiAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgY29sb3JzID0gU3dpdGNoRGVmYXVsdHMuY29sb3JzKAogICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICBjaGVja2VkVGh1bWJDb2xvciA9IG11c2ljQ29sb3JzKCkuYWNjZW50VGV4dCwKICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgY2hlY2tlZFRyYWNrQ29sb3IgPSBtdXNpY0NvbG9ycygpLmFj' >> "$TMPB64"
    printf '%s' 'Y2VudCwKICAgICAgICAgICAgICAgICAgICAgICAgdW5jaGVja2VkVGh1bWJDb2xvciA9IG11c2lj' >> "$TMPB64"
    printf '%s' 'Q29sb3JzKCkudGV4dFNlY29uZGFyeSwKICAgICAgICAgICAgICAgICAgICAgICAgdW5jaGVja2Vk' >> "$TMPB64"
    printf '%s' 'VHJhY2tDb2xvciA9IG11c2ljQ29sb3JzKCkuY2FyZFNlY29uZGFyeQogICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICkKICAgICAgICAgICAgICAgICkKICAgICAgICAgICAgfQogICAgICAgIH0KCiAgICAgICAg' >> "$TMPB64"
    printf '%s' 'U3BhY2VyKE1vZGlmaWVyLmhlaWdodCgxNi5kcCkpCiAgICAgICAgVGV4dCgKICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'IumihOiuviIsCiAgICAgICAgICAgIHN0eWxlID0gTWF0ZXJpYWxUaGVtZS50eXBvZ3JhcGh5LnRp' >> "$TMPB64"
    printf '%s' 'dGxlU21hbGwsCiAgICAgICAgICAgIGNvbG9yID0gbXVzaWNDb2xvcnMoKS50ZXh0U2Vjb25kYXJ5' >> "$TMPB64"
    printf '%s' 'LAogICAgICAgICAgICBtb2RpZmllciA9IE1vZGlmaWVyLnBhZGRpbmcoc3RhcnQgPSA0LmRwLCBi' >> "$TMPB64"
    printf '%s' 'b3R0b20gPSA4LmRwKQogICAgICAgICkKICAgICAgICBSb3coCiAgICAgICAgICAgIG1vZGlmaWVy' >> "$TMPB64"
    printf '%s' 'ID0gTW9kaWZpZXIKICAgICAgICAgICAgICAgIC5maWxsTWF4V2lkdGgoKQogICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgLmhvcml6b250YWxTY3JvbGwocmVtZW1iZXJTY3JvbGxTdGF0ZSgpKSwKICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'aG9yaXpvbnRhbEFycmFuZ2VtZW50ID0gQXJyYW5nZW1lbnQuc3BhY2VkQnkoOC5kcCkKICAgICAg' >> "$TMPB64"
    printf '%s' 'ICApIHsKICAgICAgICAgICAgRVFfUFJFU0VUUy5mb3JFYWNoIHsgKG5hbWUsIHZhbHVlcykgLT4K' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgIEZpbHRlckNoaXAoCiAgICAgICAgICAgICAgICAgICAgc2VsZWN0ZWQg' >> "$TMPB64"
    printf '%s' 'PSBwcmVzZXROYW1lID09IG5hbWUsCiAgICAgICAgICAgICAgICAgICAgb25DbGljayA9IHsKICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgZ2FpbnMgPSB2YWx1ZXMKICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgcHJlc2V0TmFtZSA9IG5hbWUKICAgICAgICAgICAgICAgICAgICAgICAgc2F2ZUVxKGNvbnRl' >> "$TMPB64"
    printf '%s' 'eHQsIGVuYWJsZWQsIGdhaW5zKQogICAgICAgICAgICAgICAgICAgIH0sCiAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgbGFiZWwgPSB7IFRleHQobmFtZSkgfSwKICAgICAgICAgICAgICAgICAgICBjb2xvcnMg' >> "$TMPB64"
    printf '%s' 'PSBGaWx0ZXJDaGlwRGVmYXVsdHMuZmlsdGVyQ2hpcENvbG9ycygKICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgY29udGFpbmVyQ29sb3IgPSBtdXNpY0NvbG9ycygpLmNhcmQsCiAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgIGxhYmVsQ29sb3IgPSBtdXNpY0NvbG9ycygpLnRleHRTZWNvbmRhcnksCiAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgIHNlbGVjdGVkQ29udGFpbmVyQ29sb3IgPSBtdXNpY0NvbG9ycygp' >> "$TMPB64"
    printf '%s' 'LmFjY2VudCwKICAgICAgICAgICAgICAgICAgICAgICAgc2VsZWN0ZWRMYWJlbENvbG9yID0gbXVz' >> "$TMPB64"
    printf '%s' 'aWNDb2xvcnMoKS5hY2NlbnRUZXh0CiAgICAgICAgICAgICAgICAgICAgKSwKICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICBib3JkZXIgPSBudWxsCiAgICAgICAgICAgICAgICApCiAgICAgICAgICAgIH0KICAg' >> "$TMPB64"
    printf '%s' 'ICAgICB9CgogICAgICAgIFNwYWNlcihNb2RpZmllci5oZWlnaHQoMTYuZHApKQogICAgICAgIENh' >> "$TMPB64"
    printf '%s' 'cmQoCiAgICAgICAgICAgIG1vZGlmaWVyID0gTW9kaWZpZXIuZmlsbE1heFdpZHRoKCksCiAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgIHNoYXBlID0gTWF0ZXJpYWxUaGVtZS5zaGFwZXMubGFyZ2UsCiAgICAgICAgICAgIGNv' >> "$TMPB64"
    printf '%s' 'bG9ycyA9IENhcmREZWZhdWx0cy5jYXJkQ29sb3JzKGNvbnRhaW5lckNvbG9yID0gbXVzaWNDb2xv' >> "$TMPB64"
    printf '%s' 'cnMoKS5jYXJkKQogICAgICAgICkgewogICAgICAgICAgICBDb2x1bW4oTW9kaWZpZXIucGFkZGlu' >> "$TMPB64"
    printf '%s' 'Zyhob3Jpem9udGFsID0gMTYuZHAsIHZlcnRpY2FsID0gOC5kcCkpIHsKICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'IEVRX0xBQkVMUy5mb3JFYWNoSW5kZXhlZCB7IGluZGV4LCAobGFiZWwsIGhpbnQpIC0+CiAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgdmFsIHZhbHVlID0gZ2FpbnMuZ2V0T3JFbHNlKGluZGV4KSB7IDBmIH0K' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICBSb3coCiAgICAgICAgICAgICAgICAgICAgICAgIG1vZGlmaWVy' >> "$TMPB64"
    printf '%s' 'ID0gTW9kaWZpZXIKICAgICAgICAgICAgICAgICAgICAgICAgICAgIC5maWxsTWF4V2lkdGgoKQog' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgLnBhZGRpbmcodG9wID0gMTAuZHApLAogICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICB2ZXJ0aWNhbEFsaWdubWVudCA9IEFsaWdubWVudC5DZW50ZXJWZXJ0' >> "$TMPB64"
    printf '%s' 'aWNhbGx5CiAgICAgICAgICAgICAgICAgICAgKSB7CiAgICAgICAgICAgICAgICAgICAgICAgIFRl' >> "$TMPB64"
    printf '%s' 'eHQoCiAgICAgICAgICAgICAgICAgICAgICAgICAgICBsYWJlbCwKICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgIHN0eWxlID0gTWF0ZXJpYWxUaGVtZS50eXBvZ3JhcGh5LmJvZHlMYXJnZSwKICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgIGNvbG9yID0gbXVzaWNDb2xvcnMoKS50ZXh0UHJpbWFy' >> "$TMPB64"
    printf '%s' 'eSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgIG1vZGlmaWVyID0gTW9kaWZpZXIud2lkdGgo' >> "$TMPB64"
    printf '%s' 'NTYuZHApCiAgICAgICAgICAgICAgICAgICAgICAgICkKICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'VGV4dCgKICAgICAgICAgICAgICAgICAgICAgICAgICAgIGhpbnQsCiAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICBzdHlsZSA9IE1hdGVyaWFsVGhlbWUudHlwb2dyYXBoeS5ib2R5U21hbGwsCiAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICBjb2xvciA9IG11c2ljQ29sb3JzKCkudGV4dEhpbnQs' >> "$TMPB64"
    printf '%s' 'CiAgICAgICAgICAgICAgICAgICAgICAgICAgICBtb2RpZmllciA9IE1vZGlmaWVyLndlaWdodCgx' >> "$TMPB64"
    printf '%s' 'ZikKICAgICAgICAgICAgICAgICAgICAgICAgKQogICAgICAgICAgICAgICAgICAgICAgICBUZXh0' >> "$TMPB64"
    printf '%s' 'KAogICAgICAgICAgICAgICAgICAgICAgICAgICAgKGlmICh2YWx1ZSA+IDBmKSAiKyIgZWxzZSAi' >> "$TMPB64"
    printf '%s' 'IikgKyBTdHJpbmcuZm9ybWF0KCIlLjFmIiwgdmFsdWUpICsgIiBkQiIsCiAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICBzdHlsZSA9IE1hdGVyaWFsVGhlbWUudHlwb2dyYXBoeS5ib2R5TWVkaXVt' >> "$TMPB64"
    printf '%s' 'LAogICAgICAgICAgICAgICAgICAgICAgICAgICAgY29sb3IgPSBpZiAodmFsdWUgIT0gMGYpIG11' >> "$TMPB64"
    printf '%s' 'c2ljQ29sb3JzKCkuYWNjZW50IGVsc2UgbXVzaWNDb2xvcnMoKS50ZXh0U2Vjb25kYXJ5CiAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICkKICAgICAgICAgICAgICAgICAgICB9CiAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgU2xpZGVyKAogICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZSA9IHZhbHVlLAogICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICBvblZhbHVlQ2hhbmdlID0geyB2IC0+CiAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICB2YWwgbmcgPSBnYWlucy50b011dGFibGVMaXN0KCkKICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgIG5nW2luZGV4XSA9IHYKICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'IGdhaW5zID0gbmcKICAgICAgICAgICAgICAgICAgICAgICAgICAgIHByZXNldE5hbWUgPSAi6Ieq' >> "$TMPB64"
    printf '%s' '5a6a5LmJIgogICAgICAgICAgICAgICAgICAgICAgICAgICAgc2F2ZUVxKGNvbnRleHQsIGVuYWJs' >> "$TMPB64"
    printf '%s' 'ZWQsIGdhaW5zKQogICAgICAgICAgICAgICAgICAgICAgICB9LAogICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICB2YWx1ZVJhbmdlID0gLTEyZi4uMTJmLAogICAgICAgICAgICAgICAgICAgICAgICBzdGVw' >> "$TMPB64"
    printf '%s' 'cyA9IDQ3LAogICAgICAgICAgICAgICAgICAgICAgICBlbmFibGVkID0gZW5hYmxlZCwKICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgY29sb3JzID0gU2xpZGVyRGVmYXVsdHMuY29sb3JzKAogICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgdGh1bWJDb2xvciA9IG11c2ljQ29sb3JzKCkuYWNjZW50LAog' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgYWN0aXZlVHJhY2tDb2xvciA9IG11c2ljQ29sb3Jz' >> "$TMPB64"
    printf '%s' 'KCkuYWNjZW50LAogICAgICAgICAgICAgICAgICAgICAgICAgICAgaW5hY3RpdmVUcmFja0NvbG9y' >> "$TMPB64"
    printf '%s' 'ID0gbXVzaWNDb2xvcnMoKS5zbGlkZXJUcmFjaywKICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'IGRpc2FibGVkVGh1bWJDb2xvciA9IG11c2ljQ29sb3JzKCkudGV4dEhpbnQsCiAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICBkaXNhYmxlZEFjdGl2ZVRyYWNrQ29sb3IgPSBtdXNpY0NvbG9ycygp' >> "$TMPB64"
    printf '%s' 'LnRleHRIaW50LAogICAgICAgICAgICAgICAgICAgICAgICAgICAgZGlzYWJsZWRJbmFjdGl2ZVRy' >> "$TMPB64"
    printf '%s' 'YWNrQ29sb3IgPSBtdXNpY0NvbG9ycygpLnNsaWRlclRyYWNrCiAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICksCiAgICAgICAgICAgICAgICAgICAgICAgIG1vZGlmaWVyID0gTW9kaWZpZXIuZmlsbE1h' >> "$TMPB64"
    printf '%s' 'eFdpZHRoKCkKICAgICAgICAgICAgICAgICAgICApCiAgICAgICAgICAgICAgICB9CiAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgIH0KICAgICAgICB9CgogICAgICAgIFNwYWNlcihNb2RpZmllci5oZWlnaHQoMTIuZHApKQog' >> "$TMPB64"
    printf '%s' 'ICAgICAgIFRleHQoCiAgICAgICAgICAgICLmi5bliqjmu5HlnZflrp7ml7bnlJ/mlYjjgILpopHm' >> "$TMPB64"
    printf '%s' 'rrXmjInkvaDnmoTorr7lpIflrp7mtYvoh6rliqjpgILphY3vvIznvLrlpLHnmoTpopHmrrXkvJro' >> "$TMPB64"
    printf '%s' 't7Pov4fvvJvkuI7ns7vnu5/lnYfooaHlmajlkIzml7blvIDlkK/ml7blj6/og73kupLnm7jopobn' >> "$TMPB64"
    printf '%s' 'm5bjgIIiLAogICAgICAgICAgICBzdHlsZSA9IE1hdGVyaWFsVGhlbWUudHlwb2dyYXBoeS5ib2R5' >> "$TMPB64"
    printf '%s' 'U21hbGwsCiAgICAgICAgICAgIGNvbG9yID0gbXVzaWNDb2xvcnMoKS50ZXh0SGludCwKICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgbW9kaWZpZXIgPSBNb2RpZmllci5wYWRkaW5nKGhvcml6b250YWwgPSA0LmRwKQogICAg' >> "$TMPB64"
    printf '%s' 'ICAgICkKICAgICAgICBTcGFjZXIoTW9kaWZpZXIuaGVpZ2h0KDI0LmRwKSkKICAgIH0KfQo=' >> "$TMPB64"
base64 -d "$TMPB64" > avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxEqSettingsActivity.kt
rm -f "$TMPB64"
grep -q 'class LxEqSettingsActivity' avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxEqSettingsActivity.kt || { echo "X 37 EQ 页写入失败"; exit 1; }
echo "OK EQ 页已写入"

python3 << 'PYEOF37'
import sys

# ---- manifest：注册 Activity + 权限（幂等） ----
MP = "avbox/app/src/main/AndroidManifest.xml"
with open(MP, encoding="utf-8") as f:
    m = f.read()
if "MODIFY_AUDIO_SETTINGS" not in m:
    perm = '<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />'
    if "<application" in m:
        m = m.replace("<application", perm + "\n    <application", 1)
    else:
        print("X 37 manifest 无 <application 锚点")
        sys.exit(1)
    print("  OK manifest 权限已加")
if "LxEqSettingsActivity" not in m:
    act = '<activity android:name=".ui.activity.LxEqSettingsActivity" android:exported="false" />'
    if "</application>" not in m:
        print("X 37 manifest 无 </application> 锚点")
        sys.exit(1)
    m = m.replace("</application>", "        " + act + "\n    </application>", 1)
    print("  OK manifest Activity 已注册")
with open(MP, "w", encoding="utf-8") as f:
    f.write(m)

# ---- 设置页入口接线（MusicHomeActivity，15 号产物） ----
MH = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"
with open(MH, encoding="utf-8") as f:
    h = f.read()
if "[37eq1]" in h:
    print("37 入口已接线，跳过")
else:
    old = """                SettingItem("均衡器", "跳转外部均衡器") {
                    onComingSoon("均衡器")
                },"""
    new = """                SettingItem("均衡器", "6 维自定义均衡") { // [37eq1]
                    context.startActivity(android.content.Intent(context, com.github.tvbox.osc.ui.activity.LxEqSettingsActivity::class.java))
                },"""
    if h.count(old) != 1:
        print(f"X 37 入口锚点计数异常: {h.count(old)}")
        sys.exit(1)
    h = h.replace(old, new)
    with open(MH, "w", encoding="utf-8") as f:
        f.write(h)
    print("  OK 均衡器入口已接线")
print("OK 37 完成")
PYEOF37

echo "=== 37 完成 ==="

# === 37 v2: EQ 防失真（滑块量程 ±12 -> ±8、预设曲线调平缓，全 <= ±3dB） ===
python3 << 'PYEOF37B'
import sys

P37 = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxEqSettingsActivity.kt"
with open(P37, encoding="utf-8") as f:
    c = f.read()

if "[37eq2]" in c:
    print("37 v2: 已应用，跳过")
    sys.exit(0)

def rep(old, new, tag):
    global c
    if c.count(old) != 1:
        print(f"X 37 v2 锚点计数异常 [{tag}]: {c.count(old)}")
        sys.exit(1)
    c = c.replace(old, new)
    print(f"  OK {tag}")

rep("""                        valueRange = -12f..12f,
                        steps = 47,""",
    """                        valueRange = -8f..8f, // [37eq2]
                        steps = 31,""",
    "滑块量程 ±8")

rep("""private val EQ_PRESETS: List<Pair<String, List<Float>>> = listOf(
    "平直" to listOf(0f, 0f, 0f, 0f, 0f, 0f),
    "低音增强" to listOf(6f, 4f, 0f, 0f, 0f, 1f),
    "人声突出" to listOf(-2f, 0f, 3f, 5f, 2f, 0f),
    "摇滚" to listOf(5f, 3f, -1f, 3f, 5f, 2f),
    "古典" to listOf(3f, 2f, 0f, 2f, 4f, 3f),
    "明亮" to listOf(0f, 0f, 1f, 4f, 7f, 3f)
)""",
    """// [37eq2] 预设按防糊曲线重调：全部 <= ±3dB（古典在界内未动）
private val EQ_PRESETS: List<Pair<String, List<Float>>> = listOf(
    "平直" to listOf(0f, 0f, 0f, 0f, 0f, 0f),
    "低音增强" to listOf(3f, 2f, -1f, 0f, 0f, 0f),
    "人声突出" to listOf(0f, 0f, 3f, 2f, 1f, 0f),
    "摇滚" to listOf(0f, 3f, -1f, 0f, 2f, 0f),
    "古典" to listOf(3f, 2f, 0f, 2f, 4f, 3f),
    "明亮" to listOf(0f, 0f, 0f, 2f, 3f, 0f)
)""",
    "预设重调")

assert "[37eq2]" in c
with open(P37, "w", encoding="utf-8") as f:
    f.write(c)
print("OK 37 v2 完成")
PYEOF37B

echo "=== 37 v2 完成 ==="

# === 37 v3: 动感低音预设（减法低音曲线 + 预设说明小字） ===
python3 << 'PYEOF37C'
import sys

P37 = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxEqSettingsActivity.kt"
with open(P37, encoding="utf-8") as f:
    c = f.read()

if "[37eq3]" in c:
    print("37 v3: 已应用，跳过")
    sys.exit(0)

def rep(old, new, tag):
    global c
    if c.count(old) != 1:
        print(f"X 37 v3 锚点计数异常 [{tag}]: {c.count(old)}")
        sys.exit(1)
    c = c.replace(old, new)
    print(f"  OK {tag}")

rep('"低音增强" to listOf(3f, 2f, -1f, 0f, 0f, 0f),',
    '"动感低音" to listOf(4f, -1f, 0f, 1f, 2f, 0f), // [37eq3]',
    "动感低音数值")

rep("""    "明亮" to listOf(0f, 0f, 0f, 2f, 3f, 0f)
)

private fun loadEqGains""",
    """    "明亮" to listOf(0f, 0f, 0f, 2f, 3f, 0f)
)

// [37eq3] 预设说明小字（仅配文案的预设显示）
private val EQ_PRESET_HINTS: Map<String, String> = mapOf(
    "动感低音" to "切除了浑浊低频，提升了高频空气感，获得干净弹性的低音下潜。"
)

private fun loadEqGains""",
    "EQ_PRESET_HINTS 映射")

rep("""        Spacer(Modifier.height(16.dp))
        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = MaterialTheme.shapes.large,
            colors = CardDefaults.cardColors(containerColor = musicColors().card)
        ) {
            Column(Modifier.padding(horizontal = 16.dp, vertical = 8.dp)) {""",
    """        val presetHint = EQ_PRESET_HINTS[presetName] // [37eq3]
        if (presetHint != null) {
            Text(
                presetHint,
                style = MaterialTheme.typography.bodySmall,
                color = musicColors().textHint,
                modifier = Modifier.padding(start = 4.dp, top = 8.dp)
            )
        }

        Spacer(Modifier.height(16.dp))
        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = MaterialTheme.shapes.large,
            colors = CardDefaults.cardColors(containerColor = musicColors().card)
        ) {
            Column(Modifier.padding(horizontal = 16.dp, vertical = 8.dp)) {""",
    "说明小字渲染")

assert "[37eq3]" in c and "动感低音" in c
with open(P37, "w", encoding="utf-8") as f:
    f.write(c)
print("OK 37 v3 完成")
PYEOF37C

echo "=== 37 v3 完成 ==="

# === 37 v4: 极致音质（DSP 引擎）开关卡（默认关） ===
python3 << 'PYEOF37D'
import sys

P37 = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxEqSettingsActivity.kt"
with open(P37, encoding="utf-8") as f:
    c = f.read()

if "[37eq4]" in c:
    print("37 v4: 已应用，跳过")
    sys.exit(0)

def rep(old, new, tag):
    global c
    if c.count(old) != 1:
        print(f"X 37 v4 锚点计数异常 [{tag}]: {c.count(old)}")
        sys.exit(1)
    c = c.replace(old, new)
    print(f"  OK {tag}")

DSP_STATE = '    var presetName by remember { mutableStateOf("自定义") }\n    // [37eq4] DSP 开关默认 false：用户手动开启才由内置 DSP 接管\n    var dsp by remember {\n        mutableStateOf(\n            try {\n                context.getSharedPreferences("eq_settings", Context.MODE_PRIVATE).getBoolean("dsp", false)\n            } catch (_: Exception) {\n                false\n            }\n        )\n    }'
rep('    var presetName by remember { mutableStateOf("自定义") }', DSP_STATE, "dsp 状态（默认关）")

CARD = """        Spacer(Modifier.height(12.dp))
        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = MaterialTheme.shapes.large,
            colors = CardDefaults.cardColors(containerColor = musicColors().card)
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 14.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column(Modifier.weight(1f)) {
                    Text(
                        "极致音质（DSP 引擎）",
                        style = MaterialTheme.typography.bodyLarge,
                        color = musicColors().textPrimary
                    )
                    Text(
                        "内置 DSP 接管均衡，系统 EQ 停用；处理异常自动旁路",
                        style = MaterialTheme.typography.bodySmall,
                        color = musicColors().textSecondary
                    )
                }
                Switch(
                    checked = dsp,
                    onCheckedChange = {
                        dsp = it
                        try {
                            context.getSharedPreferences("eq_settings", Context.MODE_PRIVATE)
                                .edit().putBoolean("dsp", it).apply()
                        } catch (_: Exception) {
                        }
                        LxPlayerManager.applyEqFromPrefs()
                    },
                    colors = SwitchDefaults.colors(
                        checkedThumbColor = musicColors().accentText,
                        checkedTrackColor = musicColors().accent,
                        uncheckedThumbColor = musicColors().textSecondary,
                        uncheckedTrackColor = musicColors().cardSecondary
                    )
                )
            }
        }

"""
OLD_HEAD = """        Spacer(Modifier.height(16.dp))
        Text(
            "预设","""
rep(OLD_HEAD, CARD + OLD_HEAD, "DSP 开关卡")

assert "[37eq4]" in c
with open(P37, "w", encoding="utf-8") as f:
    f.write(c)
print("OK 37 v4 完成")
PYEOF37D

echo "=== 37 v4 完成 ==="

# === 37 v5: 双引擎互斥联动（开一灭一）+ 滑块门放开 + DSP 小字 ===
python3 << 'PYEOF37E'
import sys

P37 = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxEqSettingsActivity.kt"
with open(P37, encoding="utf-8") as f:
    c = f.read()

if "[37eq5]" in c:
    print("37 v5: 已应用，跳过")
    sys.exit(0)

def rep(old, new, tag):
    global c
    if c.count(old) != 1:
        print(f"X 37 v5 锚点计数异常 [{tag}]: {c.count(old)}")
        sys.exit(1)
    c = c.replace(old, new)
    print(f"  OK {tag}")

OLD_MASTER = """                    onCheckedChange = {
                        enabled = it
                        saveEq(context, enabled, gains)
                    },"""
NEW_MASTER = """                    onCheckedChange = {
                        enabled = it
                        if (it) {
                            // [37eq5] 互斥联动：开系统 EQ 必须灭 DSP（状态+落盘）
                            dsp = false
                            try {
                                context.getSharedPreferences("eq_settings", Context.MODE_PRIVATE)
                                    .edit().putBoolean("dsp", false).apply()
                            } catch (_: Exception) {
                            }
                        }
                        saveEq(context, enabled, gains)
                    },"""
rep(OLD_MASTER, NEW_MASTER, "系统 EQ 开关联动")

OLD_DSP = """                    onCheckedChange = {
                        dsp = it
                        try {
                            context.getSharedPreferences("eq_settings", Context.MODE_PRIVATE)
                                .edit().putBoolean("dsp", it).apply()
                        } catch (_: Exception) {
                        }
                        LxPlayerManager.applyEqFromPrefs()
                    },"""
NEW_DSP = """                    onCheckedChange = {
                        dsp = it
                        // [37eq5] 互斥联动：开 DSP 必须灭系统 EQ（状态），再统一 saveEq 落盘 on 并触发仲裁
                        if (it) enabled = false
                        try {
                            context.getSharedPreferences("eq_settings", Context.MODE_PRIVATE)
                                .edit().putBoolean("dsp", it).apply()
                        } catch (_: Exception) {
                        }
                        saveEq(context, enabled, gains)
                    },"""
rep(OLD_DSP, NEW_DSP, "DSP 开关联动")

rep("                        enabled = enabled,",
    "                        enabled = enabled || dsp, // [37eq5] 任一引擎开都能调",
    "滑块门放开")

rep('"内置 DSP 接管均衡，系统 EQ 停用；处理异常自动旁路",',
    '"开启后系统 EQ 自动关闭；处理异常自动旁路",',
    "DSP 小字")

assert "[37eq5]" in c
with open(P37, "w", encoding="utf-8") as f:
    f.write(c)
print("OK 37 v5 完成")
PYEOF37E

echo "=== 37 v5 完成 ==="
