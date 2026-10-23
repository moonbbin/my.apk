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
    printf '%s' 'Ly8gWzM3ZXE4XSDkuIDmrKHmgKfmuIXmoaPvvJrml6fniYjkuInlpITliIbmlaPokL3nm5jlj6/o' >> "$TMPB64"
    printf '%s' 'g73lt7LmioogZXFfc2V0dGluZ3Mg5YaZ5Z2P77yM5riF5LiA5qyh6YeN5p2l77yI5qCH6K6w6Ziy' >> "$TMPB64"
    printf '%s' '6YeN5aSN5riF77yJCiAgICAgICAgdHJ5IHsKICAgICAgICAgICAgdmFsIGVwID0gYXBwQ3R4Lmdl' >> "$TMPB64"
    printf '%s' 'dFNoYXJlZFByZWZlcmVuY2VzKCJlcV9zZXR0aW5ncyIsIENvbnRleHQuTU9ERV9QUklWQVRFKQog' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICBpZiAoIWVwLmdldEJvb2xlYW4oImVxX3Y4X2NsZWFuIiwgZmFsc2UpKSB7CiAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICBlcC5lZGl0KCkuY2xlYXIoKS5wdXRCb29sZWFuKCJlcV92OF9jbGVhbiIs' >> "$TMPB64"
    printf '%s' 'IHRydWUpLmNvbW1pdCgpCiAgICAgICAgICAgIH0KICAgICAgICB9IGNhdGNoIChfOiBFeGNlcHRp' >> "$TMPB64"
    printf '%s' 'b24pIHsKICAgICAgICB9CiAgICAgICAgTXVzaWNUaGVtZU1hbmFnZXIuaW5pdChhcHBDdHgpCiAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgc2V0Q29udGVudCB7CiAgICAgICAgICAgIHZhbCBpc0RhcmsgYnkgTXVzaWNUaGVtZU1h' >> "$TMPB64"
    printf '%s' 'bmFnZXIuaXNEYXJrVGhlbWUKICAgICAgICAgICAgdmFsIHdpbmRvdyA9IHRoaXNATHhFcVNldHRp' >> "$TMPB64"
    printf '%s' 'bmdzQWN0aXZpdHkud2luZG93CiAgICAgICAgICAgIFNpZGVFZmZlY3QgewogICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgV2luZG93Q29tcGF0LmdldEluc2V0c0NvbnRyb2xsZXIod2luZG93LCB3aW5kb3cuZGVjb3JW' >> "$TMPB64"
    printf '%s' 'aWV3KQogICAgICAgICAgICAgICAgICAgIC5pc0FwcGVhcmFuY2VMaWdodFN0YXR1c0JhcnMgPSAh' >> "$TMPB64"
    printf '%s' 'aXNEYXJrCiAgICAgICAgICAgIH0KICAgICAgICAgICAgTHhNdXNpY1RoZW1lKGlzRGFya1RoZW1l' >> "$TMPB64"
    printf '%s' 'ID0gaXNEYXJrKSB7CiAgICAgICAgICAgICAgICBFcVNldHRpbmdzU2NyZWVuKG9uQmFjayA9IHsg' >> "$TMPB64"
    printf '%s' 'ZmluaXNoKCkgfSkKICAgICAgICAgICAgfQogICAgICAgIH0KICAgIH0KfQoKcHJpdmF0ZSB2YWwg' >> "$TMPB64"
    printf '%s' 'RVFfS0VZUyA9IGxpc3RPZigic3ViIiwgImxvdyIsICJtaWQiLCAiY2xhcml0eSIsICJoaWdoIiwg' >> "$TMPB64"
    printf '%s' 'ImFtYiIpCnByaXZhdGUgdmFsIEVRX0xBQkVMUyA9IGxpc3RPZigKICAgICLotoXkvY7popEiIHRv' >> "$TMPB64"
    printf '%s' 'ICI2MEh6IMK3IOS4i+a9nCIsCiAgICAi5L2O6aKRIiB0byAiMjMwSHogwrcg5Yqb6YePIiwKICAg' >> "$TMPB64"
    printf '%s' 'ICLkuK3popEiIHRvICI5MTBIeiDCtyDkurrlo7AiLAogICAgIua4heaZsOW6piIgdG8gIjNrSHog' >> "$TMPB64"
    printf '%s' 'wrcg5ZCQ5a2XIiwKICAgICLpq5jpopEiIHRvICIxNGtIeiDCtyDmmI7kuq4iLAogICAgIuawm+Wb' >> "$TMPB64"
    printf '%s' 'tOaEnyIgdG8gIjNrKzE0ayDCtyDnjrDlnLoiCikKCi8vIOmihOiuvumhuuW6j+S4jiBFUV9LRVlT' >> "$TMPB64"
    printf '%s' 'IOWvuem9kO+8mnN1YiwgbG93LCBtaWQsIGNsYXJpdHksIGhpZ2gsIGFtYu+8iOWNleS9jSBkQu+8' >> "$TMPB64"
    printf '%s' 'iQovLyBbMzdlcTJdIOmihOiuvuaMiemYsueziuabsue6v+mHjeiwg++8muWFqOmDqCA8PSDCsTNk' >> "$TMPB64"
    printf '%s' 'Qu+8iOWPpOWFuOWcqOeVjOWGheacquWKqO+8iQpwcml2YXRlIHZhbCBFUV9QUkVTRVRTOiBMaXN0' >> "$TMPB64"
    printf '%s' 'PFBhaXI8U3RyaW5nLCBMaXN0PEZsb2F0Pj4+ID0gbGlzdE9mKAogICAgIuW5s+ebtCIgdG8gbGlz' >> "$TMPB64"
    printf '%s' 'dE9mKDBmLCAwZiwgMGYsIDBmLCAwZiwgMGYpLAogICAgIuWKqOaEn+S9jumfsyIgdG8gbGlzdE9m' >> "$TMPB64"
    printf '%s' 'KDRmLCAtMWYsIDBmLCAxZiwgMmYsIDBmKSwgLy8gWzM3ZXEzXQogICAgIuS6uuWjsOeqgeWHuiIg' >> "$TMPB64"
    printf '%s' 'dG8gbGlzdE9mKDBmLCAwZiwgM2YsIDJmLCAxZiwgMGYpLAogICAgIuaRh+a7miIgdG8gbGlzdE9m' >> "$TMPB64"
    printf '%s' 'KDBmLCAzZiwgLTFmLCAwZiwgMmYsIDBmKSwKICAgICLlj6TlhbgiIHRvIGxpc3RPZigzZiwgMmYs' >> "$TMPB64"
    printf '%s' 'IDBmLCAyZiwgNGYsIDNmKSwKICAgICLmmI7kuq4iIHRvIGxpc3RPZigwZiwgMGYsIDBmLCAyZiwg' >> "$TMPB64"
    printf '%s' 'M2YsIDBmKQopCgovLyBbMzdlcTNdIOmihOiuvuivtOaYjuWwj+Wtl++8iOS7hemFjeaWh+ahiOea' >> "$TMPB64"
    printf '%s' 'hOmihOiuvuaYvuekuu+8iQpwcml2YXRlIHZhbCBFUV9QUkVTRVRfSElOVFM6IE1hcDxTdHJpbmcs' >> "$TMPB64"
    printf '%s' 'IFN0cmluZz4gPSBtYXBPZigKICAgICLliqjmhJ/kvY7pn7MiIHRvICLliIfpmaTkuobmtZHmtYrk' >> "$TMPB64"
    printf '%s' 'vY7popHvvIzmj5DljYfkuobpq5jpopHnqbrmsJTmhJ/vvIzojrflvpflubLlh4DlvLnmgKfnmoTk' >> "$TMPB64"
    printf '%s' 'vY7pn7PkuIvmvZzjgIIiCikKCnByaXZhdGUgZnVuIGxvYWRFcUdhaW5zKGNvbnRleHQ6IENvbnRl' >> "$TMPB64"
    printf '%s' 'eHQpOiBMaXN0PEZsb2F0PiB7CiAgICB2YWwgcHJlZnMgPSBjb250ZXh0LmdldFNoYXJlZFByZWZl' >> "$TMPB64"
    printf '%s' 'cmVuY2VzKCJlcV9zZXR0aW5ncyIsIENvbnRleHQuTU9ERV9QUklWQVRFKQogICAgcmV0dXJuIEVR' >> "$TMPB64"
    printf '%s' 'X0tFWVMubWFwIHsgayAtPiB0cnkgeyBwcmVmcy5nZXRGbG9hdChrLCAwZikgfSBjYXRjaCAoXzog' >> "$TMPB64"
    printf '%s' 'RXhjZXB0aW9uKSB7IDBmIH0gfQp9CgovLyBbMzdlcTZdIOWKqOaAgemHj+eoi++8mkRTUCDCsTEy' >> "$TMPB64"
    printf '%s' 'IC8g57O757ufIMKxOO+8m+WIh+aNouS4juWKoOi9veaXtue7n+S4gOmSs+WItgpwcml2YXRlIGZ1' >> "$TMPB64"
    printf '%s' 'biBjbGFtcEdhaW5zKGdhaW5zOiBMaXN0PEZsb2F0PiwgbGltOiBGbG9hdCk6IExpc3Q8RmxvYXQ+' >> "$TMPB64"
    printf '%s' 'ID0gZ2FpbnMubWFwIHsgaXQuY29lcmNlSW4oLWxpbSwgbGltKSB9Cgpwcml2YXRlIGZ1biBsb2Fk' >> "$TMPB64"
    printf '%s' 'RXFHYWluc0NsYW1wZWQoY29udGV4dDogQ29udGV4dCk6IExpc3Q8RmxvYXQ+IHsKICAgIHZhbCBk' >> "$TMPB64"
    printf '%s' 'c3BPbiA9IHRyeSB7CiAgICAgICAgY29udGV4dC5nZXRTaGFyZWRQcmVmZXJlbmNlcygiZXFfc2V0' >> "$TMPB64"
    printf '%s' 'dGluZ3MiLCBDb250ZXh0Lk1PREVfUFJJVkFURSkuZ2V0Qm9vbGVhbigiZHNwIiwgZmFsc2UpCiAg' >> "$TMPB64"
    printf '%s' 'ICB9IGNhdGNoIChfOiBFeGNlcHRpb24pIHsKICAgICAgICBmYWxzZQogICAgfQogICAgcmV0dXJu' >> "$TMPB64"
    printf '%s' 'IGNsYW1wR2FpbnMobG9hZEVxR2FpbnMoY29udGV4dCksIDEyZikgLy8gWzM3ZXE4XSDnuq8gRFNQ' >> "$TMPB64"
    printf '%s' 'IOWbuuWumiDCsTEyCn0KCi8vIFszN2VxOF0g57qvIERTUCDniYjvvJrlhajpobXllK/kuIDokL3n' >> "$TMPB64"
    printf '%s' 'm5jot6/lvoTjgIJkc3AvNiDlop7nm4rlkIzkuIAgZWRpdG9yIOWOn+WtkOWGmeOAgWNvbW1pdCDl' >> "$TMPB64"
    printf '%s' 'kIzmraXokL3nm5jvvJsKLy8g57O757ufIEVRIOW3suenu+mZpO+8jCJvbiIg5oGS5YaZIGZhbHNl' >> "$TMPB64"
    printf '%s' 'IOWPquS4uua4hemBl+eVmeeKtuaAge+8jE1hbmFnZXIg5LiN5YaN6K+75a6D44CCCnByaXZhdGUg' >> "$TMPB64"
    printf '%s' 'ZnVuIHBlcnNpc3RFcShjb250ZXh0OiBDb250ZXh0LCBkc3A6IEJvb2xlYW4sIGdhaW5zOiBMaXN0' >> "$TMPB64"
    printf '%s' 'PEZsb2F0PikgewogICAgdHJ5IHsKICAgICAgICB2YWwgZSA9IGNvbnRleHQuZ2V0U2hhcmVkUHJl' >> "$TMPB64"
    printf '%s' 'ZmVyZW5jZXMoImVxX3NldHRpbmdzIiwgQ29udGV4dC5NT0RFX1BSSVZBVEUpLmVkaXQoKQogICAg' >> "$TMPB64"
    printf '%s' 'ICAgIGUucHV0Qm9vbGVhbigib24iLCBmYWxzZSkKICAgICAgICBlLnB1dEJvb2xlYW4oImRzcCIs' >> "$TMPB64"
    printf '%s' 'IGRzcCkKICAgICAgICBFUV9LRVlTLmZvckVhY2hJbmRleGVkIHsgaSwgayAtPiBlLnB1dEZsb2F0' >> "$TMPB64"
    printf '%s' 'KGssIGdhaW5zLmdldE9yRWxzZShpKSB7IDBmIH0pIH0KICAgICAgICBlLmNvbW1pdCgpCiAgICB9' >> "$TMPB64"
    printf '%s' 'IGNhdGNoIChfOiBFeGNlcHRpb24pIHsKICAgIH0KICAgIEx4UGxheWVyTWFuYWdlci5hcHBseUVx' >> "$TMPB64"
    printf '%s' 'RnJvbVByZWZzKCkKfQoKQENvbXBvc2FibGUKZnVuIEVxU2V0dGluZ3NTY3JlZW4ob25CYWNrOiAo' >> "$TMPB64"
    printf '%s' 'KSAtPiBVbml0KSB7CiAgICB2YWwgY29udGV4dCA9IExvY2FsQ29udGV4dC5jdXJyZW50CiAgICB2' >> "$TMPB64"
    printf '%s' 'YXIgZ2FpbnMgYnkgcmVtZW1iZXIgeyBtdXRhYmxlU3RhdGVPZihsb2FkRXFHYWluc0NsYW1wZWQo' >> "$TMPB64"
    printf '%s' 'Y29udGV4dCkpIH0gLy8gWzM3ZXE2XQogICAgdmFyIHByZXNldE5hbWUgYnkgcmVtZW1iZXIgeyBt' >> "$TMPB64"
    printf '%s' 'dXRhYmxlU3RhdGVPZigi6Ieq5a6a5LmJIikgfQogICAgLy8gWzM3ZXE0XSBEU1Ag5byA5YWz6buY' >> "$TMPB64"
    printf '%s' '6K6kIGZhbHNl77ya55So5oi35omL5Yqo5byA5ZCv5omN55Sx5YaF572uIERTUCDmjqXnrqEKICAg' >> "$TMPB64"
    printf '%s' 'IHZhciBkc3AgYnkgcmVtZW1iZXIgewogICAgICAgIG11dGFibGVTdGF0ZU9mKAogICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICB0cnkgewogICAgICAgICAgICAgICAgY29udGV4dC5nZXRTaGFyZWRQcmVmZXJlbmNlcygiZXFf' >> "$TMPB64"
    printf '%s' 'c2V0dGluZ3MiLCBDb250ZXh0Lk1PREVfUFJJVkFURSkuZ2V0Qm9vbGVhbigiZHNwIiwgZmFsc2Up' >> "$TMPB64"
    printf '%s' 'CiAgICAgICAgICAgIH0gY2F0Y2ggKF86IEV4Y2VwdGlvbikgewogICAgICAgICAgICAgICAgZmFs' >> "$TMPB64"
    printf '%s' 'c2UKICAgICAgICAgICAgfQogICAgICAgICkKICAgIH0KCiAgICBDb2x1bW4oCiAgICAgICAgbW9k' >> "$TMPB64"
    printf '%s' 'aWZpZXIgPSBNb2RpZmllcgogICAgICAgICAgICAuZmlsbE1heFNpemUoKQogICAgICAgICAgICAu' >> "$TMPB64"
    printf '%s' 'YmFja2dyb3VuZChtdXNpY0NvbG9ycygpLmJhY2tncm91bmQpCiAgICAgICAgICAgIC52ZXJ0aWNh' >> "$TMPB64"
    printf '%s' 'bFNjcm9sbChyZW1lbWJlclNjcm9sbFN0YXRlKCkpCiAgICAgICAgICAgIC5wYWRkaW5nKGhvcml6' >> "$TMPB64"
    printf '%s' 'b250YWwgPSAxNi5kcCkKICAgICkgewogICAgICAgIFJvdygKICAgICAgICAgICAgbW9kaWZpZXIg' >> "$TMPB64"
    printf '%s' 'PSBNb2RpZmllcgogICAgICAgICAgICAgICAgLmZpbGxNYXhXaWR0aCgpCiAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAucGFkZGluZyh0b3AgPSAyNC5kcCwgYm90dG9tID0gOC5kcCksCiAgICAgICAgICAgIHZlcnRp' >> "$TMPB64"
    printf '%s' 'Y2FsQWxpZ25tZW50ID0gQWxpZ25tZW50LkNlbnRlclZlcnRpY2FsbHkKICAgICAgICApIHsKICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgVGV4dCgKICAgICAgICAgICAgICAgICLigLkiLAogICAgICAgICAgICAgICAgc3R5' >> "$TMPB64"
    printf '%s' 'bGUgPSBNYXRlcmlhbFRoZW1lLnR5cG9ncmFwaHkuaGVhZGxpbmVMYXJnZSwKICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgIGNvbG9yID0gbXVzaWNDb2xvcnMoKS50ZXh0UHJpbWFyeSwKICAgICAgICAgICAgICAgIG1v' >> "$TMPB64"
    printf '%s' 'ZGlmaWVyID0gTW9kaWZpZXIKICAgICAgICAgICAgICAgICAgICAucGFkZGluZyhlbmQgPSA4LmRw' >> "$TMPB64"
    printf '%s' 'KQogICAgICAgICAgICAgICAgICAgIC5jbGlja2FibGUgeyBvbkJhY2soKSB9CiAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICkKICAgICAgICAgICAgVGV4dCgKICAgICAgICAgICAgICAgICLlnYfooaHlmagiLAogICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgc3R5bGUgPSBNYXRlcmlhbFRoZW1lLnR5cG9ncmFwaHkudGl0bGVMYXJnZSwKICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgIGZvbnRXZWlnaHQgPSBGb250V2VpZ2h0LkJvbGQsCiAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICBjb2xvciA9IG11c2ljQ29sb3JzKCkudGV4dFByaW1hcnkKICAgICAgICAgICAgKQogICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICBTcGFjZXIoTW9kaWZpZXIud2VpZ2h0KDFmKSkKICAgICAgICAgICAgVGV4dEJ1dHRvbihv' >> "$TMPB64"
    printf '%s' 'bkNsaWNrID0gewogICAgICAgICAgICAgICAgZ2FpbnMgPSBMaXN0KDYpIHsgMGYgfQogICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgcHJlc2V0TmFtZSA9ICLlubPnm7QiCiAgICAgICAgICAgICAgICBwZXJzaXN0RXEo' >> "$TMPB64"
    printf '%s' 'Y29udGV4dCwgZHNwLCBnYWlucykKICAgICAgICAgICAgfSkgewogICAgICAgICAgICAgICAgVGV4' >> "$TMPB64"
    printf '%s' 'dCgi6YeN572uIiwgY29sb3IgPSBtdXNpY0NvbG9ycygpLmFjY2VudCkKICAgICAgICAgICAgfQog' >> "$TMPB64"
    printf '%s' 'ICAgICAgIH0KCgogICAgICAgIENhcmQoCiAgICAgICAgICAgIG1vZGlmaWVyID0gTW9kaWZpZXIu' >> "$TMPB64"
    printf '%s' 'ZmlsbE1heFdpZHRoKCksCiAgICAgICAgICAgIHNoYXBlID0gTWF0ZXJpYWxUaGVtZS5zaGFwZXMu' >> "$TMPB64"
    printf '%s' 'bGFyZ2UsCiAgICAgICAgICAgIGNvbG9ycyA9IENhcmREZWZhdWx0cy5jYXJkQ29sb3JzKGNvbnRh' >> "$TMPB64"
    printf '%s' 'aW5lckNvbG9yID0gbXVzaWNDb2xvcnMoKS5jYXJkKQogICAgICAgICkgewogICAgICAgICAgICBS' >> "$TMPB64"
    printf '%s' 'b3coCiAgICAgICAgICAgICAgICBtb2RpZmllciA9IE1vZGlmaWVyCiAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgLmZpbGxNYXhXaWR0aCgpCiAgICAgICAgICAgICAgICAgICAgLnBhZGRpbmcoaG9yaXpvbnRh' >> "$TMPB64"
    printf '%s' 'bCA9IDE2LmRwLCB2ZXJ0aWNhbCA9IDE0LmRwKSwKICAgICAgICAgICAgICAgIHZlcnRpY2FsQWxp' >> "$TMPB64"
    printf '%s' 'Z25tZW50ID0gQWxpZ25tZW50LkNlbnRlclZlcnRpY2FsbHkKICAgICAgICAgICAgKSB7CiAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICBDb2x1bW4oTW9kaWZpZXIud2VpZ2h0KDFmKSkgewogICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgIFRleHQoCiAgICAgICAgICAgICAgICAgICAgICAgICLmnoHoh7Tpn7PotKjvvIhEU1Ag5byV' >> "$TMPB64"
    printf '%s' '5pOO77yJIiwKICAgICAgICAgICAgICAgICAgICAgICAgc3R5bGUgPSBNYXRlcmlhbFRoZW1lLnR5' >> "$TMPB64"
    printf '%s' 'cG9ncmFwaHkuYm9keUxhcmdlLAogICAgICAgICAgICAgICAgICAgICAgICBjb2xvciA9IG11c2lj' >> "$TMPB64"
    printf '%s' 'Q29sb3JzKCkudGV4dFByaW1hcnkKICAgICAgICAgICAgICAgICAgICApCiAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgVGV4dCgKICAgICAgICAgICAgICAgICAgICAgICAgIuWUr+S4gOeahOWdh+ihoeW8leaT' >> "$TMPB64"
    printf '%s' 'ju+8mjYg5q615YaF572uIERTUCDlpITnkIbvvIzCsTEyZEIg5rex5bqm6LCD6IqC77yMTGltaXRl' >> "$TMPB64"
    printf '%s' 'ciDkv53miqTkuI3noLTpn7PvvIzlpITnkIblvILluLjoh6rliqjml4Hot68iLAogICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICBzdHlsZSA9IE1hdGVyaWFsVGhlbWUudHlwb2dyYXBoeS5ib2R5U21hbGws' >> "$TMPB64"
    printf '%s' 'CiAgICAgICAgICAgICAgICAgICAgICAgIGNvbG9yID0gbXVzaWNDb2xvcnMoKS50ZXh0U2Vjb25k' >> "$TMPB64"
    printf '%s' 'YXJ5CiAgICAgICAgICAgICAgICAgICAgKQogICAgICAgICAgICAgICAgfQogICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgU3dpdGNoKAogICAgICAgICAgICAgICAgICAgIGNoZWNrZWQgPSBkc3AsCiAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgb25DaGVja2VkQ2hhbmdlID0gewogICAgICAgICAgICAgICAgICAgICAgICBkc3Ag' >> "$TMPB64"
    printf '%s' 'PSBpdAogICAgICAgICAgICAgICAgICAgICAgICBwZXJzaXN0RXEoY29udGV4dCwgZHNwLCBnYWlu' >> "$TMPB64"
    printf '%s' 'cykgLy8gWzM3ZXE4XSDnuq8gRFNQ77ya5byA5YWz5Y2z5byV5pOOCiAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgfSwKICAgICAgICAgICAgICAgICAgICBjb2xvcnMgPSBTd2l0Y2hEZWZhdWx0cy5jb2xvcnMo' >> "$TMPB64"
    printf '%s' 'CiAgICAgICAgICAgICAgICAgICAgICAgIGNoZWNrZWRUaHVtYkNvbG9yID0gbXVzaWNDb2xvcnMo' >> "$TMPB64"
    printf '%s' 'KS5hY2NlbnRUZXh0LAogICAgICAgICAgICAgICAgICAgICAgICBjaGVja2VkVHJhY2tDb2xvciA9' >> "$TMPB64"
    printf '%s' 'IG11c2ljQ29sb3JzKCkuYWNjZW50LAogICAgICAgICAgICAgICAgICAgICAgICB1bmNoZWNrZWRU' >> "$TMPB64"
    printf '%s' 'aHVtYkNvbG9yID0gbXVzaWNDb2xvcnMoKS50ZXh0U2Vjb25kYXJ5LAogICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICB1bmNoZWNrZWRUcmFja0NvbG9yID0gbXVzaWNDb2xvcnMoKS5jYXJkU2Vjb25kYXJ5' >> "$TMPB64"
    printf '%s' 'CiAgICAgICAgICAgICAgICAgICAgKQogICAgICAgICAgICAgICAgKQogICAgICAgICAgICB9CiAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgfQoKICAgICAgICBTcGFjZXIoTW9kaWZpZXIuaGVpZ2h0KDE2LmRwKSkKICAgICAgICBU' >> "$TMPB64"
    printf '%s' 'ZXh0KAogICAgICAgICAgICAi6aKE6K6+IiwKICAgICAgICAgICAgc3R5bGUgPSBNYXRlcmlhbFRo' >> "$TMPB64"
    printf '%s' 'ZW1lLnR5cG9ncmFwaHkudGl0bGVTbWFsbCwKICAgICAgICAgICAgY29sb3IgPSBtdXNpY0NvbG9y' >> "$TMPB64"
    printf '%s' 'cygpLnRleHRTZWNvbmRhcnksCiAgICAgICAgICAgIG1vZGlmaWVyID0gTW9kaWZpZXIucGFkZGlu' >> "$TMPB64"
    printf '%s' 'ZyhzdGFydCA9IDQuZHAsIGJvdHRvbSA9IDguZHApCiAgICAgICAgKQogICAgICAgIFJvdygKICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgbW9kaWZpZXIgPSBNb2RpZmllcgogICAgICAgICAgICAgICAgLmZpbGxNYXhXaWR0' >> "$TMPB64"
    printf '%s' 'aCgpCiAgICAgICAgICAgICAgICAuaG9yaXpvbnRhbFNjcm9sbChyZW1lbWJlclNjcm9sbFN0YXRl' >> "$TMPB64"
    printf '%s' 'KCkpLAogICAgICAgICAgICBob3Jpem9udGFsQXJyYW5nZW1lbnQgPSBBcnJhbmdlbWVudC5zcGFj' >> "$TMPB64"
    printf '%s' 'ZWRCeSg4LmRwKQogICAgICAgICkgewogICAgICAgICAgICBFUV9QUkVTRVRTLmZvckVhY2ggeyAo' >> "$TMPB64"
    printf '%s' 'bmFtZSwgdmFsdWVzKSAtPgogICAgICAgICAgICAgICAgRmlsdGVyQ2hpcCgKICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICBzZWxlY3RlZCA9IHByZXNldE5hbWUgPT0gbmFtZSwKICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICBvbkNsaWNrID0gewogICAgICAgICAgICAgICAgICAgICAgICBnYWlucyA9IHZhbHVlcwogICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICBwcmVzZXROYW1lID0gbmFtZQogICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICBwZXJzaXN0RXEoY29udGV4dCwgZHNwLCBnYWlucykKICAgICAgICAgICAgICAgICAgICB9' >> "$TMPB64"
    printf '%s' 'LAogICAgICAgICAgICAgICAgICAgIGxhYmVsID0geyBUZXh0KG5hbWUpIH0sCiAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgY29sb3JzID0gRmlsdGVyQ2hpcERlZmF1bHRzLmZpbHRlckNoaXBDb2xvcnMoCiAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgIGNvbnRhaW5lckNvbG9yID0gbXVzaWNDb2xvcnMoKS5jYXJk' >> "$TMPB64"
    printf '%s' 'LAogICAgICAgICAgICAgICAgICAgICAgICBsYWJlbENvbG9yID0gbXVzaWNDb2xvcnMoKS50ZXh0' >> "$TMPB64"
    printf '%s' 'U2Vjb25kYXJ5LAogICAgICAgICAgICAgICAgICAgICAgICBzZWxlY3RlZENvbnRhaW5lckNvbG9y' >> "$TMPB64"
    printf '%s' 'ID0gbXVzaWNDb2xvcnMoKS5hY2NlbnQsCiAgICAgICAgICAgICAgICAgICAgICAgIHNlbGVjdGVk' >> "$TMPB64"
    printf '%s' 'TGFiZWxDb2xvciA9IG11c2ljQ29sb3JzKCkuYWNjZW50VGV4dAogICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICksCiAgICAgICAgICAgICAgICAgICAgYm9yZGVyID0gbnVsbAogICAgICAgICAgICAgICAgKQog' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICB9CiAgICAgICAgfQoKICAgICAgICB2YWwgcHJlc2V0SGludCA9IEVRX1BSRVNF' >> "$TMPB64"
    printf '%s' 'VF9ISU5UU1twcmVzZXROYW1lXSAvLyBbMzdlcTNdCiAgICAgICAgaWYgKHByZXNldEhpbnQgIT0g' >> "$TMPB64"
    printf '%s' 'bnVsbCkgewogICAgICAgICAgICBUZXh0KAogICAgICAgICAgICAgICAgcHJlc2V0SGludCwKICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgIHN0eWxlID0gTWF0ZXJpYWxUaGVtZS50eXBvZ3JhcGh5LmJvZHlTbWFsbCwK' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgIGNvbG9yID0gbXVzaWNDb2xvcnMoKS50ZXh0SGludCwKICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgIG1vZGlmaWVyID0gTW9kaWZpZXIucGFkZGluZyhzdGFydCA9IDQuZHAsIHRvcCA9IDgu' >> "$TMPB64"
    printf '%s' 'ZHApCiAgICAgICAgICAgICkKICAgICAgICB9CgogICAgICAgIFNwYWNlcihNb2RpZmllci5oZWln' >> "$TMPB64"
    printf '%s' 'aHQoMTYuZHApKQogICAgICAgIENhcmQoCiAgICAgICAgICAgIG1vZGlmaWVyID0gTW9kaWZpZXIu' >> "$TMPB64"
    printf '%s' 'ZmlsbE1heFdpZHRoKCksCiAgICAgICAgICAgIHNoYXBlID0gTWF0ZXJpYWxUaGVtZS5zaGFwZXMu' >> "$TMPB64"
    printf '%s' 'bGFyZ2UsCiAgICAgICAgICAgIGNvbG9ycyA9IENhcmREZWZhdWx0cy5jYXJkQ29sb3JzKGNvbnRh' >> "$TMPB64"
    printf '%s' 'aW5lckNvbG9yID0gbXVzaWNDb2xvcnMoKS5jYXJkKQogICAgICAgICkgewogICAgICAgICAgICBD' >> "$TMPB64"
    printf '%s' 'b2x1bW4oTW9kaWZpZXIucGFkZGluZyhob3Jpem9udGFsID0gMTYuZHAsIHZlcnRpY2FsID0gOC5k' >> "$TMPB64"
    printf '%s' 'cCkpIHsKICAgICAgICAgICAgICAgIEVRX0xBQkVMUy5mb3JFYWNoSW5kZXhlZCB7IGluZGV4LCAo' >> "$TMPB64"
    printf '%s' 'bGFiZWwsIGhpbnQpIC0+CiAgICAgICAgICAgICAgICAgICAgdmFsIHZhbHVlID0gZ2FpbnMuZ2V0' >> "$TMPB64"
    printf '%s' 'T3JFbHNlKGluZGV4KSB7IDBmIH0KICAgICAgICAgICAgICAgICAgICBSb3coCiAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgIG1vZGlmaWVyID0gTW9kaWZpZXIKICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgIC5maWxsTWF4V2lkdGgoKQogICAgICAgICAgICAgICAgICAgICAgICAgICAgLnBhZGRpbmco' >> "$TMPB64"
    printf '%s' 'dG9wID0gMTAuZHApLAogICAgICAgICAgICAgICAgICAgICAgICB2ZXJ0aWNhbEFsaWdubWVudCA9' >> "$TMPB64"
    printf '%s' 'IEFsaWdubWVudC5DZW50ZXJWZXJ0aWNhbGx5CiAgICAgICAgICAgICAgICAgICAgKSB7CiAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgIFRleHQoCiAgICAgICAgICAgICAgICAgICAgICAgICAgICBsYWJl' >> "$TMPB64"
    printf '%s' 'bCwKICAgICAgICAgICAgICAgICAgICAgICAgICAgIHN0eWxlID0gTWF0ZXJpYWxUaGVtZS50eXBv' >> "$TMPB64"
    printf '%s' 'Z3JhcGh5LmJvZHlMYXJnZSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNvbG9yID0gbXVz' >> "$TMPB64"
    printf '%s' 'aWNDb2xvcnMoKS50ZXh0UHJpbWFyeSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgIG1vZGlm' >> "$TMPB64"
    printf '%s' 'aWVyID0gTW9kaWZpZXIud2lkdGgoNTYuZHApCiAgICAgICAgICAgICAgICAgICAgICAgICkKICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgVGV4dCgKICAgICAgICAgICAgICAgICAgICAgICAgICAgIGhp' >> "$TMPB64"
    printf '%s' 'bnQsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICBzdHlsZSA9IE1hdGVyaWFsVGhlbWUudHlw' >> "$TMPB64"
    printf '%s' 'b2dyYXBoeS5ib2R5U21hbGwsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICBjb2xvciA9IG11' >> "$TMPB64"
    printf '%s' 'c2ljQ29sb3JzKCkudGV4dEhpbnQsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICBtb2RpZmll' >> "$TMPB64"
    printf '%s' 'ciA9IE1vZGlmaWVyLndlaWdodCgxZikKICAgICAgICAgICAgICAgICAgICAgICAgKQogICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICBUZXh0KAogICAgICAgICAgICAgICAgICAgICAgICAgICAgKGlmICh2' >> "$TMPB64"
    printf '%s' 'YWx1ZSA+IDBmKSAiKyIgZWxzZSAiIikgKyBTdHJpbmcuZm9ybWF0KCIlLjFmIiwgdmFsdWUpICsg' >> "$TMPB64"
    printf '%s' 'IiBkQiIsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICBzdHlsZSA9IE1hdGVyaWFsVGhlbWUu' >> "$TMPB64"
    printf '%s' 'dHlwb2dyYXBoeS5ib2R5TWVkaXVtLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgY29sb3Ig' >> "$TMPB64"
    printf '%s' 'PSBpZiAodmFsdWUgIT0gMGYpIG11c2ljQ29sb3JzKCkuYWNjZW50IGVsc2UgbXVzaWNDb2xvcnMo' >> "$TMPB64"
    printf '%s' 'KS50ZXh0U2Vjb25kYXJ5CiAgICAgICAgICAgICAgICAgICAgICAgICkKICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICB9CiAgICAgICAgICAgICAgICAgICAgU2xpZGVyKAogICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICB2YWx1ZSA9IHZhbHVlLAogICAgICAgICAgICAgICAgICAgICAgICBvblZhbHVlQ2hhbmdlID0g' >> "$TMPB64"
    printf '%s' 'eyB2IC0+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWwgbmcgPSBnYWlucy50b011dGFi' >> "$TMPB64"
    printf '%s' 'bGVMaXN0KCkKICAgICAgICAgICAgICAgICAgICAgICAgICAgIG5nW2luZGV4XSA9IHYKICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgIGdhaW5zID0gbmcKICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgIHByZXNldE5hbWUgPSAi6Ieq5a6a5LmJIgogICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'cGVyc2lzdEVxKGNvbnRleHQsIGRzcCwgZ2FpbnMpCiAgICAgICAgICAgICAgICAgICAgICAgIH0s' >> "$TMPB64"
    printf '%s' 'CiAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlUmFuZ2UgPSAtMTJmLi4xMmYsIC8vIFszN2Vx' >> "$TMPB64"
    printf '%s' 'OF0g57qvIERTUCDlm7rlrpogwrExMgogICAgICAgICAgICAgICAgICAgICAgICBzdGVwcyA9IDQ3' >> "$TMPB64"
    printf '%s' 'LAogICAgICAgICAgICAgICAgICAgICAgICBlbmFibGVkID0gZHNwLAogICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICBjb2xvcnMgPSBTbGlkZXJEZWZhdWx0cy5jb2xvcnMoCiAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICB0aHVtYkNvbG9yID0gbXVzaWNDb2xvcnMoKS5hY2NlbnQsCiAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICBhY3RpdmVUcmFja0NvbG9yID0gbXVzaWNDb2xvcnMoKS5hY2NlbnQs' >> "$TMPB64"
    printf '%s' 'CiAgICAgICAgICAgICAgICAgICAgICAgICAgICBpbmFjdGl2ZVRyYWNrQ29sb3IgPSBtdXNpY0Nv' >> "$TMPB64"
    printf '%s' 'bG9ycygpLmNhcmRTZWNvbmRhcnksIC8vIFszN2VxN10g5Y6757u/54K577ya6L2o6YGT5LiO5Yi7' >> "$TMPB64"
    printf '%s' '5bqm5YWoIFRva2VuIOWMlgogICAgICAgICAgICAgICAgICAgICAgICAgICAgYWN0aXZlVGlja0Nv' >> "$TMPB64"
    printf '%s' 'bG9yID0gbXVzaWNDb2xvcnMoKS5hY2NlbnRUZXh0LmNvcHkoYWxwaGEgPSAwLjRmKSwKICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgIGluYWN0aXZlVGlja0NvbG9yID0gbXVzaWNDb2xvcnMoKS5j' >> "$TMPB64"
    printf '%s' 'YXJkU2Vjb25kYXJ5LAogICAgICAgICAgICAgICAgICAgICAgICAgICAgZGlzYWJsZWRUaHVtYkNv' >> "$TMPB64"
    printf '%s' 'bG9yID0gbXVzaWNDb2xvcnMoKS50ZXh0SGludCwKICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'IGRpc2FibGVkQWN0aXZlVHJhY2tDb2xvciA9IG11c2ljQ29sb3JzKCkudGV4dEhpbnQsCiAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICBkaXNhYmxlZEluYWN0aXZlVHJhY2tDb2xvciA9IG11c2lj' >> "$TMPB64"
    printf '%s' 'Q29sb3JzKCkuY2FyZFNlY29uZGFyeSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRpc2Fi' >> "$TMPB64"
    printf '%s' 'bGVkQWN0aXZlVGlja0NvbG9yID0gbXVzaWNDb2xvcnMoKS50ZXh0SGludCwKICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgIGRpc2FibGVkSW5hY3RpdmVUaWNrQ29sb3IgPSBtdXNpY0NvbG9ycygp' >> "$TMPB64"
    printf '%s' 'LnRleHRIaW50CiAgICAgICAgICAgICAgICAgICAgICAgICksCiAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgIG1vZGlmaWVyID0gTW9kaWZpZXIuZmlsbE1heFdpZHRoKCkKICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICApCiAgICAgICAgICAgICAgICB9CiAgICAgICAgICAgIH0KICAgICAgICB9CgogICAgICAgIFNw' >> "$TMPB64"
    printf '%s' 'YWNlcihNb2RpZmllci5oZWlnaHQoMTIuZHApKQogICAgICAgIFRleHQoCiAgICAgICAgICAgICLm' >> "$TMPB64"
    printf '%s' 'i5bliqjmu5HlnZflrp7ml7bnlJ/mlYjjgILpopHmrrXnlLHlhoXnva4gRFNQIOW8leaTjuWkhOeQ' >> "$TMPB64"
    printf '%s' 'hu+8jOS4jeS+nei1luiuvuWkh+ezu+e7n+Wdh+ihoeWZqO+8jOiuvue9ruiHquWKqOS/neWtmOOA' >> "$TMPB64"
    printf '%s' 'giIsCiAgICAgICAgICAgIHN0eWxlID0gTWF0ZXJpYWxUaGVtZS50eXBvZ3JhcGh5LmJvZHlTbWFs' >> "$TMPB64"
    printf '%s' 'bCwKICAgICAgICAgICAgY29sb3IgPSBtdXNpY0NvbG9ycygpLnRleHRIaW50LAogICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICBtb2RpZmllciA9IE1vZGlmaWVyLnBhZGRpbmcoaG9yaXpvbnRhbCA9IDQuZHApCiAgICAgICAg' >> "$TMPB64"
    printf '%s' 'KQogICAgICAgIFNwYWNlcihNb2RpZmllci5oZWlnaHQoMjQuZHApKQogICAgfQp9Cg==' >> "$TMPB64"
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

# === 37 v8: 纯 DSP 版（系统 EQ 已移除） ===
# 页面只剩 DSP 一个引擎开关；persistEq 唯一落盘（原子写 + commit）；onCreate 一次性清档 eq_v8_clean。
echo "=== 37 v8 完成 ==="
