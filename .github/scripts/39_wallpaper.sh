#!/bin/bash
# [base-a6da734e] round1 tvbox->avbox
# [base-a6da734e] round2 pool
# 39_wallpaper.sh [39wp5] 自定义壁纸：Manager(图/渐变双模式+Peek三件:文字模式/不透明度/模糊) + 设置页(效果调整) + 在线壁纸库(真实源:搜图神器) + MusicHome 根注入(壁纸层+Scrim+Local色覆盖) + 六页根透出 + 搜索框玻璃化
set -e
cd "$(dirname "$0")/../.." 2>/dev/null || true
mkdir -p avbox/app/src/main/java/com/github/avbox/osc/ui
TMPB64=$(mktemp)
    printf '%s' 'cGFja2FnZSBjb20uZ2l0aHViLmF2Ym94Lm9zYy51aQoKaW1wb3J0IGFuZHJvaWQuY29udGVudC5Db250ZXh0CmltcG9ydCBhbmRy' >> "$TMPB64"
    printf '%s' 'b2lkLmdyYXBoaWNzLkJpdG1hcAppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5ydW50aW1lLkNvbXBvc2FibGUKaW1wb3J0IGFuZHJv' >> "$TMPB64"
    printf '%s' 'aWR4LmNvbXBvc2UucnVudGltZS5jb2xsZWN0QXNTdGF0ZQppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5ydW50aW1lLmdldFZhbHVl' >> "$TMPB64"
    printf '%s' 'CmltcG9ydCBrb3RsaW54LmNvcm91dGluZXMuZmxvdy5NdXRhYmxlU3RhdGVGbG93CmltcG9ydCBrb3RsaW54LmNvcm91dGluZXMu' >> "$TMPB64"
    printf '%s' 'Zmxvdy5TdGF0ZUZsb3cKCi8vIFszOXdwNV0g5aOB57q45qih57OK5Y+Y5o2iKENvaWwgY29pbC50cmFuc2Zvcm0uVHJhbnNmb3Jt' >> "$TMPB64"
    printf '%s' 'YXRpb24g5o6l5Y+jLCBkZXgg5a6e6K+B562+5ZCNKTog57yp5bCPICsg5LiJ6L2u5Y+v5YiG56a755uS5byP5qih57OKKOi/keS8' >> "$TMPB64"
    printf '%s' 'vOmrmOaWrywg5a+56b2QIFBlZWsg55qEIEltYWdlRmlsdGVyIOmrmOaWryBzaWdtYSDor63kuYkp5YaN5pS+5aSnLCDlhaggQVBJ' >> "$TMPB64"
    printf '%s' 'IOWPr+eUqDsg5Y2K5b6E6L+b57yT5a2Y6ZSu6Ziy5Liy5Zu+CmNsYXNzIFdwQmx1clRyYW5zZm9ybWF0aW9uKHByaXZhdGUgdmFs' >> "$TMPB64"
    printf '%s' 'IHJhZGl1czogSW50KSA6IGNvaWwudHJhbnNmb3JtLlRyYW5zZm9ybWF0aW9uIHsKICAgIG92ZXJyaWRlIHZhbCBjYWNoZUtleTog' >> "$TMPB64"
    printf '%s' 'U3RyaW5nID0gIndwYmx1cl92Ml8kcmFkaXVzIgogICAgb3ZlcnJpZGUgc3VzcGVuZCBmdW4gdHJhbnNmb3JtKGlucHV0OiBCaXRt' >> "$TMPB64"
    printf '%s' 'YXAsIHNpemU6IGNvaWwuc2l6ZS5TaXplKTogQml0bWFwIHsKICAgICAgICBpZiAocmFkaXVzIDw9IDApIHJldHVybiBpbnB1dAog' >> "$TMPB64"
    printf '%s' 'ICAgICAgIHZhbCBzcmMgPSBpZiAoaW5wdXQuY29uZmlnID09IEJpdG1hcC5Db25maWcuSEFSRFdBUkUpIGlucHV0LmNvcHkoQml0' >> "$TMPB64"
    printf '%s' 'bWFwLkNvbmZpZy5BUkdCXzg4ODgsIGZhbHNlKSBlbHNlIGlucHV0CiAgICAgICAgdmFsIHcgPSBzcmMud2lkdGg7IHZhbCBoID0g' >> "$TMPB64"
    printf '%s' 'c3JjLmhlaWdodAogICAgICAgIGlmICh3IDw9IDAgfHwgaCA8PSAwKSByZXR1cm4gc3JjCiAgICAgICAgLy8g5YWI57yp5Yiw5a69' >> "$TMPB64"
    printf '%s' 'IDw9NTQwKOWPjOe6v+aApyk6IOaPkOmAnzsg6auY5pavIHNpZ21hIOaMiee8qeaUvuavlOaKmOeul+i/m+Wwj+WbvuepuumXtAog' >> "$TMPB64"
    printf '%s' 'ICAgICAgIHZhbCBzY2FsZSA9IGlmICh3ID4gNTQwKSA1NDBmIC8gdyBlbHNlIDFmCiAgICAgICAgdmFsIHNtYWxsMCA9IGlmIChz' >> "$TMPB64"
    printf '%s' 'Y2FsZSA8IDFmKSBCaXRtYXAuY3JlYXRlU2NhbGVkQml0bWFwKHNyYywgbWF4T2YoMSwgKHcgKiBzY2FsZSkudG9JbnQoKSksIG1h' >> "$TMPB64"
    printf '%s' 'eE9mKDEsIChoICogc2NhbGUpLnRvSW50KCkpLCB0cnVlKSBlbHNlIHNyYwogICAgICAgIHZhbCBzaWdtYVMgPSByYWRpdXMgKiBz' >> "$TMPB64"
    printf '%s' 'Y2FsZQogICAgICAgIHZhbCBiciA9IGJveFJhZGl1c0ZvcihzaWdtYVMpCiAgICAgICAgdmFyIHNtYWxsID0gc21hbGwwCiAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgaWYgKGJyID4gMCkgcmVwZWF0KDMpIHsgc21hbGwgPSBib3hCbHVyKHNtYWxsLCBicikgfQogICAgICAgIHZhbCB1cCA9IGlm' >> "$TMPB64"
    printf '%s' 'IChzY2FsZSA8IDFmKSBCaXRtYXAuY3JlYXRlU2NhbGVkQml0bWFwKHNtYWxsLCB3LCBoLCB0cnVlKSBlbHNlIHNtYWxsCiAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgaWYgKHNtYWxsICE9PSBzcmMgJiYgc21hbGwgIT09IHVwKSBzbWFsbC5yZWN5Y2xlKCkKICAgICAgICByZXR1cm4gdXAKICAg' >> "$TMPB64"
    printf '%s' 'IH0KICAgIC8vIFszOXdwNV0g5LiJ6L2u55uS5byP6L+R5Ly86auY5pav5pe2LCDljZXova7nm5LljYrlvoTkuI7nm67moIcgc2ln' >> "$TMPB64"
    printf '%s' 'bWEg55qE5o2i566XOiB3PXNxcnQoMTIqc2lnbWFeMi8zKzEpLCByPSh3LTEpLzIKICAgIHByaXZhdGUgZnVuIGJveFJhZGl1c0Zv' >> "$TMPB64"
    printf '%s' 'cihzaWdtYTogRmxvYXQpOiBJbnQgewogICAgICAgIGlmIChzaWdtYSA8IDAuNWYpIHJldHVybiAwCiAgICAgICAgdmFsIGJ3ID0g' >> "$TMPB64"
    printf '%s' 'a290bGluLm1hdGguc3FydCgxMmYgKiBzaWdtYSAqIHNpZ21hIC8gM2YgKyAxZikKICAgICAgICByZXR1cm4gKChidyAtIDFmKSAv' >> "$TMPB64"
    printf '%s' 'IDJmKS50b0ludCgpLmNvZXJjZUluKDEsIDYwKQogICAgfQogICAgLy8gWzM5d3A1XSDlj6/liIbnprvnm5LlvI/mqKHns4o6IOa7' >> "$TMPB64"
    printf '%s' 'keeql+Wdh+WAvCwg5qiq56uW5ZCE5LiA6LafCiAgICBwcml2YXRlIGZ1biBib3hCbHVyKHNyY0JtcDogQml0bWFwLCByOiBJbnQp' >> "$TMPB64"
    printf '%s' 'OiBCaXRtYXAgewogICAgICAgIHZhbCB3ID0gc3JjQm1wLndpZHRoCiAgICAgICAgdmFsIGggPSBzcmNCbXAuaGVpZ2h0CiAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgdmFsIGNudCA9IDIgKiByICsgMQogICAgICAgIHZhbCBweCA9IEludEFycmF5KHcgKiBoKQogICAgICAgIHNyY0JtcC5nZXRQ' >> "$TMPB64"
    printf '%s' 'aXhlbHMocHgsIDAsIHcsIDAsIDAsIHcsIGgpCiAgICAgICAgdmFsIHRtcCA9IEludEFycmF5KHcgKiBoKQogICAgICAgIGZvciAo' >> "$TMPB64"
    printf '%s' 'eSBpbiAwIHVudGlsIGgpIHsKICAgICAgICAgICAgdmFsIHJvdyA9IHkgKiB3CiAgICAgICAgICAgIHZhciBzYSA9IDA7IHZhciBz' >> "$TMPB64"
    printf '%s' 'ciA9IDA7IHZhciBzZyA9IDA7IHZhciBzYiA9IDAKICAgICAgICAgICAgZm9yIChpIGluIC1yLi5yKSB7IHZhbCBjID0gcHhbcm93' >> "$TMPB64"
    printf '%s' 'ICsgaS5jb2VyY2VJbigwLCB3IC0gMSldOyBzYSArPSBjIHVzaHIgMjQ7IHNyICs9IChjIHNociAxNikgYW5kIDB4RkY7IHNnICs9' >> "$TMPB64"
    printf '%s' 'IChjIHNociA4KSBhbmQgMHhGRjsgc2IgKz0gYyBhbmQgMHhGRiB9CiAgICAgICAgICAgIGZvciAoeCBpbiAwIHVudGlsIHcpIHsK' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgIHRtcFtyb3cgKyB4XSA9ICgoc2EgLyBjbnQpIHNobCAyNCkgb3IgKChzciAvIGNudCkgc2hsIDE2KSBv' >> "$TMPB64"
    printf '%s' 'ciAoKHNnIC8gY250KSBzaGwgOCkgb3IgKHNiIC8gY250KQogICAgICAgICAgICAgICAgdmFsIGNhID0gcHhbcm93ICsgKHggKyBy' >> "$TMPB64"
    printf '%s' 'ICsgMSkuY29lcmNlSW4oMCwgdyAtIDEpXQogICAgICAgICAgICAgICAgdmFsIGNzID0gcHhbcm93ICsgKHggLSByKS5jb2VyY2VJ' >> "$TMPB64"
    printf '%s' 'bigwLCB3IC0gMSldCiAgICAgICAgICAgICAgICBzYSArPSAoY2EgdXNociAyNCkgLSAoY3MgdXNociAyNCk7IHNyICs9ICgoY2Eg' >> "$TMPB64"
    printf '%s' 'c2hyIDE2KSBhbmQgMHhGRikgLSAoKGNzIHNociAxNikgYW5kIDB4RkYpOyBzZyArPSAoKGNhIHNociA4KSBhbmQgMHhGRikgLSAo' >> "$TMPB64"
    printf '%s' 'KGNzIHNociA4KSBhbmQgMHhGRik7IHNiICs9IChjYSBhbmQgMHhGRikgLSAoY3MgYW5kIDB4RkYpCiAgICAgICAgICAgIH0KICAg' >> "$TMPB64"
    printf '%s' 'ICAgICB9CiAgICAgICAgdmFsIG91dCA9IEludEFycmF5KHcgKiBoKQogICAgICAgIGZvciAoeCBpbiAwIHVudGlsIHcpIHsKICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgdmFyIHNhID0gMDsgdmFyIHNyID0gMDsgdmFyIHNnID0gMDsgdmFyIHNiID0gMAogICAgICAgICAgICBmb3IgKGkg' >> "$TMPB64"
    printf '%s' 'aW4gLXIuLnIpIHsgdmFsIGMgPSB0bXBbaS5jb2VyY2VJbigwLCBoIC0gMSkgKiB3ICsgeF07IHNhICs9IGMgdXNociAyNDsgc3Ig' >> "$TMPB64"
    printf '%s' 'Kz0gKGMgc2hyIDE2KSBhbmQgMHhGRjsgc2cgKz0gKGMgc2hyIDgpIGFuZCAweEZGOyBzYiArPSBjIGFuZCAweEZGIH0KICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgZm9yICh5IGluIDAgdW50aWwgaCkgewogICAgICAgICAgICAgICAgb3V0W3kgKiB3ICsgeF0gPSAoKHNhIC8gY250KSBz' >> "$TMPB64"
    printf '%s' 'aGwgMjQpIG9yICgoc3IgLyBjbnQpIHNobCAxNikgb3IgKChzZyAvIGNudCkgc2hsIDgpIG9yIChzYiAvIGNudCkKICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgIHZhbCBjYSA9IHRtcFsoeSArIHIgKyAxKS5jb2VyY2VJbigwLCBoIC0gMSkgKiB3ICsgeF0KICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'IHZhbCBjcyA9IHRtcFsoeSAtIHIpLmNvZXJjZUluKDAsIGggLSAxKSAqIHcgKyB4XQogICAgICAgICAgICAgICAgc2EgKz0gKGNh' >> "$TMPB64"
    printf '%s' 'IHVzaHIgMjQpIC0gKGNzIHVzaHIgMjQpOyBzciArPSAoKGNhIHNociAxNikgYW5kIDB4RkYpIC0gKChjcyBzaHIgMTYpIGFuZCAw' >> "$TMPB64"
    printf '%s' 'eEZGKTsgc2cgKz0gKChjYSBzaHIgOCkgYW5kIDB4RkYpIC0gKChjcyBzaHIgOCkgYW5kIDB4RkYpOyBzYiArPSAoY2EgYW5kIDB4' >> "$TMPB64"
    printf '%s' 'RkYpIC0gKGNzIGFuZCAweEZGKQogICAgICAgICAgICB9CiAgICAgICAgfQogICAgICAgIHZhbCBibXAgPSBCaXRtYXAuY3JlYXRl' >> "$TMPB64"
    printf '%s' 'Qml0bWFwKHcsIGgsIEJpdG1hcC5Db25maWcuQVJHQl84ODg4KQogICAgICAgIGJtcC5zZXRQaXhlbHMob3V0LCAwLCB3LCAwLCAw' >> "$TMPB64"
    printf '%s' 'LCB3LCBoKQogICAgICAgIHJldHVybiBibXAKICAgIH0KfQoKLy8gWzM5d3AxXSDoh6rlrprkuYnlo4HnurjvvJrnirbmgIEgKyDm' >> "$TMPB64"
    printf '%s' 'jIHkuYXljJbvvIjojIPlvI/lkIwgTXVzaWNUaGVtZU1hbmFnZXLvvJpvYmplY3QgKyBwcmVmcyArIFN0YXRlRmxvd++8iQpvYmpl' >> "$TMPB64"
    printf '%s' 'Y3QgV2FsbHBhcGVyTWFuYWdlciB7CiAgICBwcml2YXRlIGNvbnN0IHZhbCBQUkVGUyA9ICJ3YWxscGFwZXJfcHJlZnMiCiAgICBw' >> "$TMPB64"
    printf '%s' 'cml2YXRlIGNvbnN0IHZhbCBLRVlfRU5BQkxFRCA9ICJlbmFibGVXYWxscGFwZXIiCiAgICBwcml2YXRlIGNvbnN0IHZhbCBLRVlf' >> "$TMPB64"
    printf '%s' 'VVJMID0gIndhbGxwYXBlclVybCIKICAgIHByaXZhdGUgY29uc3QgdmFsIEtFWV9ISVNUT1JZID0gIndhbGxwYXBlckhpc3Rvcnki' >> "$TMPB64"
    printf '%s' 'CiAgICBwcml2YXRlIGNvbnN0IHZhbCBLRVlfTU9ERSA9ICJ3YWxscGFwZXJNb2RlIgogICAgcHJpdmF0ZSBjb25zdCB2YWwgS0VZ' >> "$TMPB64"
    printf '%s' 'X0dSQURJRU5UID0gImdyYWRpZW50Q29sb3JzIgogICAgcHJpdmF0ZSBjb25zdCB2YWwgS0VZX1RFWFRNT0RFID0gIndhbGxwYXBl' >> "$TMPB64"
    printf '%s' 'clRleHRNb2RlIgogICAgcHJpdmF0ZSBjb25zdCB2YWwgS0VZX1NDUklNID0gIndhbGxwYXBlclNjcmltIgogICAgcHJpdmF0ZSBj' >> "$TMPB64"
    printf '%s' 'b25zdCB2YWwgS0VZX09QQUNJVFkgPSAid2FsbHBhcGVyT3BhY2l0eSIKICAgIHByaXZhdGUgY29uc3QgdmFsIEtFWV9CTFVSID0g' >> "$TMPB64"
    printf '%s' 'IndhbGxwYXBlckJsdXIiCgogICAgZGF0YSBjbGFzcyBTdGF0ZSgKICAgICAgICB2YWwgZW5hYmxlZDogQm9vbGVhbiA9IGZhbHNl' >> "$TMPB64"
    printf '%s' 'LAogICAgICAgIHZhbCB1cmw6IFN0cmluZyA9ICIiLAogICAgICAgIHZhbCBoaXN0b3J5OiBMaXN0PFN0cmluZz4gPSBlbXB0eUxp' >> "$TMPB64"
    printf '%s' 'c3QoKSwKICAgICAgICB2YWwgbW9kZTogU3RyaW5nID0gImltYWdlIiwKICAgICAgICB2YWwgZ3JhZGllbnQ6IFN0cmluZyA9ICIi' >> "$TMPB64"
    printf '%s' 'LAogICAgICAgIHZhbCB0ZXh0TW9kZTogU3RyaW5nID0gImF1dG8iLAogICAgICAgIHZhbCBzY3JpbTogSW50ID0gMCwKICAgICAg' >> "$TMPB64"
    printf '%s' 'ICB2YWwgb3BhY2l0eTogSW50ID0gMTAwLAogICAgICAgIHZhbCBibHVyOiBJbnQgPSAwLAogICAgKQoKICAgIHByaXZhdGUgdmFs' >> "$TMPB64"
    printf '%s' 'IF9zdGF0ZSA9IE11dGFibGVTdGF0ZUZsb3coU3RhdGUoKSkKICAgIHZhbCBzdGF0ZTogU3RhdGVGbG93PFN0YXRlPiA9IF9zdGF0' >> "$TMPB64"
    printf '%s' 'ZQoKICAgIHByaXZhdGUgZnVuIHByZWZzKGN0eDogQ29udGV4dCkgPSBjdHguZ2V0U2hhcmVkUHJlZmVyZW5jZXMoUFJFRlMsIENv' >> "$TMPB64"
    printf '%s' 'bnRleHQuTU9ERV9QUklWQVRFKQoKICAgIGZ1biBpbml0KGN0eDogQ29udGV4dCkgewogICAgICAgIHRyeSB7CiAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'IHZhbCBwID0gcHJlZnMoY3R4KQogICAgICAgICAgICB2YWwgaGlzdCA9IChwLmdldFN0cmluZyhLRVlfSElTVE9SWSwgIiIpID86' >> "$TMPB64"
    printf '%s' 'ICIiKS5zcGxpdCgiXG4iKS5maWx0ZXIgeyBpdC5pc05vdEJsYW5rKCkgfQogICAgICAgICAgICBfc3RhdGUudmFsdWUgPSBTdGF0' >> "$TMPB64"
    printf '%s' 'ZSgKICAgICAgICAgICAgICAgIGVuYWJsZWQgPSBwLmdldEJvb2xlYW4oS0VZX0VOQUJMRUQsIGZhbHNlKSwKICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgIHVybCA9IHAuZ2V0U3RyaW5nKEtFWV9VUkwsICIiKSA/OiAiIiwKICAgICAgICAgICAgICAgIGhpc3RvcnkgPSBoaXN0LAog' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgbW9kZSA9IHAuZ2V0U3RyaW5nKEtFWV9NT0RFLCAiaW1hZ2UiKSA/OiAiaW1hZ2UiLAogICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgZ3JhZGllbnQgPSBwLmdldFN0cmluZyhLRVlfR1JBRElFTlQsICIiKSA/OiAiIiwKICAgICAgICAgICAgICAgIHRleHRN' >> "$TMPB64"
    printf '%s' 'b2RlID0gcC5nZXRTdHJpbmcoS0VZX1RFWFRNT0RFLCAiYXV0byIpID86ICJhdXRvIiwKICAgICAgICAgICAgICAgIHNjcmltID0g' >> "$TMPB64"
    printf '%s' 'cC5nZXRJbnQoS0VZX1NDUklNLCAwKS5jb2VyY2VBdExlYXN0KDApLCAvLyBbMzl3cDVdIOWtmOmHjyAtMSjml6foh6rliqgpIOW9' >> "$TMPB64"
    printf '%s' 'kiAwIOaXoOe6sQogICAgICAgICAgICAgICAgb3BhY2l0eSA9IHAuZ2V0SW50KEtFWV9PUEFDSVRZLCAxMDApLAogICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgYmx1ciA9IHAuZ2V0SW50KEtFWV9CTFVSLCAwKSwKICAgICAgICAgICAgKQogICAgICAgIH0gY2F0Y2ggKGU6IEV4Y2Vw' >> "$TMPB64"
    printf '%s' 'dGlvbikgewogICAgICAgICAgICBhbmRyb2lkLnV0aWwuTG9nLncoIldhbGxwYXBlciIsICLlo4HnurjnirbmgIHor7vlj5blpLHo' >> "$TMPB64"
    printf '%s' 'tKUiLCBlKQogICAgICAgIH0KICAgIH0KCiAgICBmdW4gc2V0RW5hYmxlZChjdHg6IENvbnRleHQsIG9uOiBCb29sZWFuKSB7CiAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgdHJ5IHsKICAgICAgICAgICAgcHJlZnMoY3R4KS5lZGl0KCkucHV0Qm9vbGVhbihLRVlfRU5BQkxFRCwgb24pLmFwcGx5' >> "$TMPB64"
    printf '%s' 'KCkKICAgICAgICB9IGNhdGNoIChlOiBFeGNlcHRpb24pIHsKICAgICAgICAgICAgYW5kcm9pZC51dGlsLkxvZy53KCJXYWxscGFw' >> "$TMPB64"
    printf '%s' 'ZXIiLCAi5aOB57q45byA5YWz5L+d5a2Y5aSx6LSlIiwgZSkKICAgICAgICB9CiAgICAgICAgX3N0YXRlLnZhbHVlID0gX3N0YXRl' >> "$TMPB64"
    printf '%s' 'LnZhbHVlLmNvcHkoZW5hYmxlZCA9IG9uKQogICAgfQoKICAgIC8vIOW6lOeUqOS4gOW8oOWjgee6uO+8iFVSTCDmiJbmnKzlnLAg' >> "$TMPB64"
    printf '%s' 'VVJJ77yJ77ya5a2Y5Li65b2T5YmN44CB6aG25Yiw5Y6G5Y+y5pyA5YmN77yI5Y676YeN44CB5LiK6ZmQIDbvvInjgIHoh6rliqjl' >> "$TMPB64"
    printf '%s' 'vIDlkK8KICAgIGZ1biBhcHBseShjdHg6IENvbnRleHQsIHVybDogU3RyaW5nKSB7CiAgICAgICAgdmFsIHUgPSB1cmwudHJpbSgp' >> "$TMPB64"
    printf '%s' 'CiAgICAgICAgaWYgKHUuaXNCbGFuaygpKSByZXR1cm4KICAgICAgICB2YWwgaGlzdCA9IChsaXN0T2YodSkgKyBfc3RhdGUudmFs' >> "$TMPB64"
    printf '%s' 'dWUuaGlzdG9yeS5maWx0ZXIgeyBpdCAhPSB1IH0pLnRha2UoNikKICAgICAgICB0cnkgewogICAgICAgICAgICBwcmVmcyhjdHgp' >> "$TMPB64"
    printf '%s' 'LmVkaXQoKQogICAgICAgICAgICAgICAgLnB1dFN0cmluZyhLRVlfVVJMLCB1KQogICAgICAgICAgICAgICAgLnB1dFN0cmluZyhL' >> "$TMPB64"
    printf '%s' 'RVlfSElTVE9SWSwgaGlzdC5qb2luVG9TdHJpbmcoIlxuIikpCiAgICAgICAgICAgICAgICAucHV0U3RyaW5nKEtFWV9NT0RFLCAi' >> "$TMPB64"
    printf '%s' 'aW1hZ2UiKQogICAgICAgICAgICAgICAgLnB1dEJvb2xlYW4oS0VZX0VOQUJMRUQsIHRydWUpCiAgICAgICAgICAgICAgICAuYXBw' >> "$TMPB64"
    printf '%s' 'bHkoKQogICAgICAgIH0gY2F0Y2ggKGU6IEV4Y2VwdGlvbikgewogICAgICAgICAgICBhbmRyb2lkLnV0aWwuTG9nLncoIldhbGxw' >> "$TMPB64"
    printf '%s' 'YXBlciIsICLlo4HnurjlupTnlKjkv53lrZjlpLHotKUiLCBlKQogICAgICAgIH0KICAgICAgICBfc3RhdGUudmFsdWUgPSBfc3Rh' >> "$TMPB64"
    printf '%s' 'dGUudmFsdWUuY29weShlbmFibGVkID0gdHJ1ZSwgdXJsID0gdSwgaGlzdG9yeSA9IGhpc3QsIG1vZGUgPSAiaW1hZ2UiKQogICAg' >> "$TMPB64"
    printf '%s' 'fQoKICAgIC8vIFszOXdwMl0g5bqU55So5riQ5Y+Y6IOM5pmvOiDlrZjkuKTkuKogSGV4KOmAl+WPt+aLvOaOpSkgKyDliIfmqKHl' >> "$TMPB64"
    printf '%s' 'vI8gKyDoh6rliqjlvIDlkK8KICAgIGZ1biBhcHBseUdyYWRpZW50KGN0eDogQ29udGV4dCwgaGV4UGFpcjogU3RyaW5nKSB7CiAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgdmFsIGcgPSBoZXhQYWlyLnRyaW0oKQogICAgICAgIGlmIChnLmlzQmxhbmsoKSkgcmV0dXJuCiAgICAgICAgdHJ5IHsK' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgcHJlZnMoY3R4KS5lZGl0KCkKICAgICAgICAgICAgICAgIC5wdXRTdHJpbmcoS0VZX0dSQURJRU5ULCBnKQog' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgLnB1dFN0cmluZyhLRVlfTU9ERSwgImdyYWRpZW50IikKICAgICAgICAgICAgICAgIC5wdXRCb29sZWFu' >> "$TMPB64"
    printf '%s' 'KEtFWV9FTkFCTEVELCB0cnVlKQogICAgICAgICAgICAgICAgLmFwcGx5KCkKICAgICAgICB9IGNhdGNoIChlOiBFeGNlcHRpb24p' >> "$TMPB64"
    printf '%s' 'IHsKICAgICAgICAgICAgYW5kcm9pZC51dGlsLkxvZy53KCJXYWxscGFwZXIiLCAi5riQ5Y+Y5bqU55So5L+d5a2Y5aSx6LSlIiwg' >> "$TMPB64"
    printf '%s' 'ZSkKICAgICAgICB9CiAgICAgICAgX3N0YXRlLnZhbHVlID0gX3N0YXRlLnZhbHVlLmNvcHkoZW5hYmxlZCA9IHRydWUsIG1vZGUg' >> "$TMPB64"
    printf '%s' 'PSAiZ3JhZGllbnQiLCBncmFkaWVudCA9IGcpCiAgICB9CgogICAgLy8gWzM5d3A0XSDmloflrZfpopzoibLmqKHlvI86IGF1dG8g' >> "$TMPB64"
    printf '%s' '6Lef6ZqP5Li76aKYIC8gbGlnaHQg5rWF6Imy5paH5a2XKOW8uuWItua3seiJsuadvykgLyBkYXJrIOa3seiJsuaWh+WtlyjlvLrl' >> "$TMPB64"
    printf '%s' 'iLbmtYXoibLmnb8pCiAgICBmdW4gc2V0VGV4dE1vZGUoY3R4OiBDb250ZXh0LCBtb2RlOiBTdHJpbmcpIHsKICAgICAgICB0cnkg' >> "$TMPB64"
    printf '%s' 'ewogICAgICAgICAgICBwcmVmcyhjdHgpLmVkaXQoKS5wdXRTdHJpbmcoS0VZX1RFWFRNT0RFLCBtb2RlKS5hcHBseSgpCiAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgfSBjYXRjaCAoZTogRXhjZXB0aW9uKSB7CiAgICAgICAgICAgIGFuZHJvaWQudXRpbC5Mb2cudygiV2FsbHBhcGVyIiwgIuaW' >> "$TMPB64"
    printf '%s' 'h+Wtl+aooeW8j+S/neWtmOWksei0pSIsIGUpCiAgICAgICAgfQogICAgICAgIF9zdGF0ZS52YWx1ZSA9IF9zdGF0ZS52YWx1ZS5j' >> "$TMPB64"
    printf '%s' 'b3B5KHRleHRNb2RlID0gbW9kZSkKICAgIH0KCiAgICAvLyBbMzl3cDRdIOmBrue9qea1k+W6pijnmb7liIbmr5QgMC05MDsgLTEg' >> "$TMPB64"
    printf '%s' 'PSDoh6rliqg6IOa3seiJsuadvyA2MCAvIOa1heiJsuadvyA3MCkKICAgIGZ1biBzZXRTY3JpbShjdHg6IENvbnRleHQsIHBjdDog' >> "$TMPB64"
    printf '%s' 'SW50KSB7CiAgICAgICAgdHJ5IHsKICAgICAgICAgICAgcHJlZnMoY3R4KS5lZGl0KCkucHV0SW50KEtFWV9TQ1JJTSwgcGN0KS5h' >> "$TMPB64"
    printf '%s' 'cHBseSgpCiAgICAgICAgfSBjYXRjaCAoZTogRXhjZXB0aW9uKSB7CiAgICAgICAgICAgIGFuZHJvaWQudXRpbC5Mb2cudygiV2Fs' >> "$TMPB64"
    printf '%s' 'bHBhcGVyIiwgIumBrue9qea1k+W6puS/neWtmOWksei0pSIsIGUpCiAgICAgICAgfQogICAgICAgIF9zdGF0ZS52YWx1ZSA9IF9z' >> "$TMPB64"
    printf '%s' 'dGF0ZS52YWx1ZS5jb3B5KHNjcmltID0gcGN0KQogICAgfQoKICAgIC8vIFszOXdwNV0g5Zu+54mH5LiN6YCP5piO5bqmKOeZvuWI' >> "$TMPB64"
    printf '%s' 'huavlCAyMC0xMDA7IOm7mOiupCAxMDAgPSBQZWVrIHdhbGxwYXBlck9wYWNpdHkgMS4wKQogICAgZnVuIHNldE9wYWNpdHkoY3R4' >> "$TMPB64"
    printf '%s' 'OiBDb250ZXh0LCBwY3Q6IEludCkgewogICAgICAgIHRyeSB7CiAgICAgICAgICAgIHByZWZzKGN0eCkuZWRpdCgpLnB1dEludChL' >> "$TMPB64"
    printf '%s' 'RVlfT1BBQ0lUWSwgcGN0KS5hcHBseSgpCiAgICAgICAgfSBjYXRjaCAoZTogRXhjZXB0aW9uKSB7CiAgICAgICAgICAgIGFuZHJv' >> "$TMPB64"
    printf '%s' 'aWQudXRpbC5Mb2cudygiV2FsbHBhcGVyIiwgIuS4jemAj+aYjuW6puS/neWtmOWksei0pSIsIGUpCiAgICAgICAgfQogICAgICAg' >> "$TMPB64"
    printf '%s' 'IF9zdGF0ZS52YWx1ZSA9IF9zdGF0ZS52YWx1ZS5jb3B5KG9wYWNpdHkgPSBwY3QpCiAgICB9CgogICAgLy8gWzM5d3A1XSDmqKHn' >> "$TMPB64"
    printf '%s' 's4rnqIvluqYoMC0yMDsg6buY6K6kIDAgPSBQZWVrIHdhbGxwYXBlckJsdXIgMC4wKQogICAgZnVuIHNldEJsdXIoY3R4OiBDb250' >> "$TMPB64"
    printf '%s' 'ZXh0LCB2YWx1ZTogSW50KSB7CiAgICAgICAgdHJ5IHsKICAgICAgICAgICAgcHJlZnMoY3R4KS5lZGl0KCkucHV0SW50KEtFWV9C' >> "$TMPB64"
    printf '%s' 'TFVSLCB2YWx1ZSkuYXBwbHkoKQogICAgICAgIH0gY2F0Y2ggKGU6IEV4Y2VwdGlvbikgewogICAgICAgICAgICBhbmRyb2lkLnV0' >> "$TMPB64"
    printf '%s' 'aWwuTG9nLncoIldhbGxwYXBlciIsICLmqKHns4rnqIvluqbkv53lrZjlpLHotKUiLCBlKQogICAgICAgIH0KICAgICAgICBfc3Rh' >> "$TMPB64"
    printf '%s' 'dGUudmFsdWUgPSBfc3RhdGUudmFsdWUuY29weShibHVyID0gdmFsdWUpCiAgICB9CgogICAgZnVuIHJlbW92ZUhpc3RvcnkoY3R4' >> "$TMPB64"
    printf '%s' 'OiBDb250ZXh0LCB1cmw6IFN0cmluZykgewogICAgICAgIHZhbCBoaXN0ID0gX3N0YXRlLnZhbHVlLmhpc3RvcnkuZmlsdGVyIHsg' >> "$TMPB64"
    printf '%s' 'aXQgIT0gdXJsIH0KICAgICAgICB0cnkgewogICAgICAgICAgICBwcmVmcyhjdHgpLmVkaXQoKS5wdXRTdHJpbmcoS0VZX0hJU1RP' >> "$TMPB64"
    printf '%s' 'UlksIGhpc3Quam9pblRvU3RyaW5nKCJcbiIpKS5hcHBseSgpCiAgICAgICAgfSBjYXRjaCAoZTogRXhjZXB0aW9uKSB7CiAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgIGFuZHJvaWQudXRpbC5Mb2cudygiV2FsbHBhcGVyIiwgIuWjgee6uOWOhuWPsuWIoOmZpOWksei0pSIsIGUpCiAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgfQogICAgICAgIF9zdGF0ZS52YWx1ZSA9IF9zdGF0ZS52YWx1ZS5jb3B5KGhpc3RvcnkgPSBoaXN0KQogICAgfQoKICAgIC8v' >> "$TMPB64"
    printf '%s' 'IOmhtemdouagueW6leiJsueUqO+8muWjgee6uOeUn+aViOS4reWImemAj+WHuuW6leWxguWjgee6uO+8iOmhtemdouagueaUuemA' >> "$TMPB64"
    printf '%s' 'j+aYju+8iQogICAgQENvbXBvc2FibGUKICAgIGZ1biBpc0FjdGl2ZSgpOiBCb29sZWFuIHsKICAgICAgICB2YWwgcyBieSBzdGF0' >> "$TMPB64"
    printf '%s' 'ZS5jb2xsZWN0QXNTdGF0ZSgpCiAgICAgICAgcmV0dXJuIHMuZW5hYmxlZCAmJiAocy51cmwuaXNOb3RCbGFuaygpIHx8IHMubW9k' >> "$TMPB64"
    printf '%s' 'ZSA9PSAiZ3JhZGllbnQiKQogICAgfQp9Cg==' >> "$TMPB64"
base64 -d "$TMPB64" > avbox/app/src/main/java/com/github/avbox/osc/ui/WallpaperManager.kt
rm -f "$TMPB64"
grep -q 'object WallpaperManager' avbox/app/src/main/java/com/github/avbox/osc/ui/WallpaperManager.kt || { echo "X 39 object WallpaperManager 写入失败"; exit 1; }
TMPB64=$(mktemp)
    printf '%s' 'cGFja2FnZSBjb20uZ2l0aHViLmF2Ym94Lm9zYy51aQoKaW1wb3J0IGFuZHJvaWQuY29udGVudC5Db250ZXh0CmltcG9ydCBjb20u' >> "$TMPB64"
    printf '%s' 'Z2l0aHViLmF2Ym94Lm9zYy51aS5tdXNpYy5nbGFzcy5Db21wYWN0U2xpZGVyIC8vIFszOXdwc2xpZGVyXQppbXBvcnQgYW5kcm9p' >> "$TMPB64"
    printf '%s' 'ZC5jb250ZW50LkludGVudAppbXBvcnQgYW5kcm9pZC5vcy5CdW5kbGUKaW1wb3J0IGFuZHJvaWR4LmFjdGl2aXR5LkNvbXBvbmVu' >> "$TMPB64"
    printf '%s' 'dEFjdGl2aXR5CmltcG9ydCBhbmRyb2lkeC5hY3Rpdml0eS5jb21wb3NlLnJlbWVtYmVyTGF1bmNoZXJGb3JBY3Rpdml0eVJlc3Vs' >> "$TMPB64"
    printf '%s' 'dAppbXBvcnQgYW5kcm9pZHguYWN0aXZpdHkuY29tcG9zZS5zZXRDb250ZW50CmltcG9ydCBhbmRyb2lkeC5hY3Rpdml0eS5yZXN1' >> "$TMPB64"
    printf '%s' 'bHQuY29udHJhY3QuQWN0aXZpdHlSZXN1bHRDb250cmFjdHMKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UuZm91bmRhdGlvbi5iYWNr' >> "$TMPB64"
    printf '%s' 'Z3JvdW5kCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLmZvdW5kYXRpb24uYm9yZGVyCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLmZv' >> "$TMPB64"
    printf '%s' 'dW5kYXRpb24uY2xpY2thYmxlCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLmZvdW5kYXRpb24ubGF5b3V0LkFycmFuZ2VtZW50Cmlt' >> "$TMPB64"
    printf '%s' 'cG9ydCBhbmRyb2lkeC5jb21wb3NlLmZvdW5kYXRpb24ubGF5b3V0LkJveAppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5mb3VuZGF0' >> "$TMPB64"
    printf '%s' 'aW9uLmxheW91dC5Db2x1bW4KaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UuZm91bmRhdGlvbi5sYXlvdXQuRXhwZXJpbWVudGFsTGF5' >> "$TMPB64"
    printf '%s' 'b3V0QXBpCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLmZvdW5kYXRpb24ubGF5b3V0LkZsb3dSb3cKaW1wb3J0IGFuZHJvaWR4LmNv' >> "$TMPB64"
    printf '%s' 'bXBvc2UuZm91bmRhdGlvbi5sYXlvdXQuUGFkZGluZ1ZhbHVlcwppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5mb3VuZGF0aW9uLmxh' >> "$TMPB64"
    printf '%s' 'eW91dC5Sb3cKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UuZm91bmRhdGlvbi5sYXlvdXQuU3BhY2VyCmltcG9ydCBhbmRyb2lkeC5j' >> "$TMPB64"
    printf '%s' 'b21wb3NlLmZvdW5kYXRpb24ubGF5b3V0LmZpbGxNYXhTaXplCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLmZvdW5kYXRpb24ubGF5' >> "$TMPB64"
    printf '%s' 'b3V0LmZpbGxNYXhXaWR0aAppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5mb3VuZGF0aW9uLmxheW91dC5oZWlnaHQKaW1wb3J0IGFu' >> "$TMPB64"
    printf '%s' 'ZHJvaWR4LmNvbXBvc2UuZm91bmRhdGlvbi5sYXlvdXQucGFkZGluZwppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5mb3VuZGF0aW9u' >> "$TMPB64"
    printf '%s' 'LmxheW91dC5zaXplCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLmZvdW5kYXRpb24ubGF5b3V0LndpZHRoCmltcG9ydCBhbmRyb2lk' >> "$TMPB64"
    printf '%s' 'eC5jb21wb3NlLmZvdW5kYXRpb24ubGF6eS5MYXp5Q29sdW1uCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLmZvdW5kYXRpb24ubGF6' >> "$TMPB64"
    printf '%s' 'eS5MYXp5Um93CmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLmZvdW5kYXRpb24ubGF6eS5pdGVtcwppbXBvcnQgYW5kcm9pZHguY29t' >> "$TMPB64"
    printf '%s' 'cG9zZS5mb3VuZGF0aW9uLnNoYXBlLlJvdW5kZWRDb3JuZXJTaGFwZQppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5tYXRlcmlhbDMu' >> "$TMPB64"
    printf '%s' 'QnV0dG9uCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLm1hdGVyaWFsMy5CdXR0b25EZWZhdWx0cwppbXBvcnQgYW5kcm9pZHguY29t' >> "$TMPB64"
    printf '%s' 'cG9zZS5tYXRlcmlhbDMuQ2FyZAppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5tYXRlcmlhbDMuQ2FyZERlZmF1bHRzCmltcG9ydCBh' >> "$TMPB64"
    printf '%s' 'bmRyb2lkeC5jb21wb3NlLm1hdGVyaWFsMy5NYXRlcmlhbFRoZW1lCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLm1hdGVyaWFsMy5P' >> "$TMPB64"
    printf '%s' 'dXRsaW5lZEJ1dHRvbgppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5tYXRlcmlhbDMuT3V0bGluZWRUZXh0RmllbGQKaW1wb3J0IGFu' >> "$TMPB64"
    printf '%s' 'ZHJvaWR4LmNvbXBvc2UubWF0ZXJpYWwzLk91dGxpbmVkVGV4dEZpZWxkRGVmYXVsdHMKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2Uu' >> "$TMPB64"
    printf '%s' 'bWF0ZXJpYWwzLlNsaWRlcgppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5tYXRlcmlhbDMuU2xpZGVyRGVmYXVsdHMKaW1wb3J0IGFu' >> "$TMPB64"
    printf '%s' 'ZHJvaWR4LmNvbXBvc2UubWF0ZXJpYWwzLlN3aXRjaAppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5tYXRlcmlhbDMuU3dpdGNoRGVm' >> "$TMPB64"
    printf '%s' 'YXVsdHMKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UubWF0ZXJpYWwzLlRleHQKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UucnVudGlt' >> "$TMPB64"
    printf '%s' 'ZS5Db21wb3NhYmxlCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLnJ1bnRpbWUuU2lkZUVmZmVjdAppbXBvcnQgYW5kcm9pZHguY29t' >> "$TMPB64"
    printf '%s' 'cG9zZS5ydW50aW1lLmNvbGxlY3RBc1N0YXRlCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLnJ1bnRpbWUuZ2V0VmFsdWUKaW1wb3J0' >> "$TMPB64"
    printf '%s' 'IGFuZHJvaWR4LmNvbXBvc2UucnVudGltZS5tdXRhYmxlU3RhdGVPZgppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5ydW50aW1lLnJl' >> "$TMPB64"
    printf '%s' 'bWVtYmVyCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLnJ1bnRpbWUuc2V0VmFsdWUKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UudWku' >> "$TMPB64"
    printf '%s' 'QWxpZ25tZW50CmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLnVpLk1vZGlmaWVyCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLnVpLmRy' >> "$TMPB64"
    printf '%s' 'YXcuY2xpcAppbXBvcnQgYW5kcm9pZHguY29tcG9zZS51aS5ncmFwaGljcy5CcnVzaAppbXBvcnQgYW5kcm9pZHguY29tcG9zZS51' >> "$TMPB64"
    printf '%s' 'aS5ncmFwaGljcy5Db2xvcgppbXBvcnQgYW5kcm9pZHguY29tcG9zZS51aS5sYXlvdXQuQ29udGVudFNjYWxlCmltcG9ydCBhbmRy' >> "$TMPB64"
    printf '%s' 'b2lkeC5jb21wb3NlLnVpLnBsYXRmb3JtLkxvY2FsQ29udGV4dAppbXBvcnQgYW5kcm9pZHguY29tcG9zZS51aS50ZXh0LmZvbnQu' >> "$TMPB64"
    printf '%s' 'Rm9udFdlaWdodAppbXBvcnQgYW5kcm9pZHguY29tcG9zZS51aS51bml0LmRwCmltcG9ydCBhbmRyb2lkeC5jb3JlLnZpZXcuV2lu' >> "$TMPB64"
    printf '%s' 'ZG93Q29tcGF0CmltcG9ydCBjb2lsLmNvbXBvc2UuQXN5bmNJbWFnZQppbXBvcnQgY29pbC5yZXF1ZXN0LkltYWdlUmVxdWVzdAoK' >> "$TMPB64"
    printf '%s' 'Ly8gWzM5d3AyXSDmuJDlj5jpooTorr46IOWQjeensCArIOi1t+atoiBIZXgo5YaF5a655pWw5o2u5pys6LqrLCDpnZ4gVUkg6ZOs' >> "$TMPB64"
    printf '%s' '6ImyKQpwcml2YXRlIHZhbCBXUF9HUkFESUVOVF9QUkVTRVRTID0gbGlzdE9mKAogICAgVHJpcGxlKCLmt7Hmtbfok50iLCAiIzBG' >> "$TMPB64"
    printf '%s' 'MjAyNyIsICIjMkM1MzY0IiksCiAgICBUcmlwbGUoIuaZmumcnue6oiIsICIjRkY5OTY2IiwgIiNGRjVFNjIiKSwKICAgIFRyaXBs' >> "$TMPB64"
    printf '%s' 'ZSgi5p6B5YWJ57u/IiwgIiMxMTk5OEUiLCAiIzM4RUY3RCIpLAopCgovLyBbMzl3cDRdIOaWh+Wtl+minOiJsuaooeW8j+mAiemh' >> "$TMPB64"
    printf '%s' 'uTog5YC8IC0+IOaYvuekuuWQjQpwcml2YXRlIHZhbCBXUF9URVhUX01PREVTID0gbGlzdE9mKAogICAgImF1dG8iIHRvICLot5/p' >> "$TMPB64"
    printf '%s' 'mo/kuLvpopgiLAogICAgImxpZ2h0IiB0byAi5rWF6Imy5paH5a2XIiwKICAgICJkYXJrIiB0byAi5rex6Imy5paH5a2XIiwKKQoK' >> "$TMPB64"
    printf '%s' 'cHJpdmF0ZSBmdW4gd3BQYXJzZUNvbG9yKGhleDogU3RyaW5nKTogQ29sb3IgPQogICAgdHJ5IHsgQ29sb3IoYW5kcm9pZC5ncmFw' >> "$TMPB64"
    printf '%s' 'aGljcy5Db2xvci5wYXJzZUNvbG9yKGhleCkpIH0gY2F0Y2ggKGU6IEV4Y2VwdGlvbikgeyBDb2xvci5HcmF5IH0KCi8vIFszOXdw' >> "$TMPB64"
    printf '%s' 'MV0g5aOB57q46K6+572u6aG177ya5byA5YWzICsgVVJMIOi+k+WFpSArIOacrOWcsOmAieWbvu+8iOaMgeS5heaOiOadg++8iSsg' >> "$TMPB64"
    printf '%s' '5Y6G5Y+y5qiq5o6S44CC5Y+q5YaZIFdhbGxwYXBlck1hbmFnZXLjgIIKY2xhc3MgTHhXYWxscGFwZXJTZXR0aW5nc0FjdGl2aXR5' >> "$TMPB64"
    printf '%s' 'IDogQ29tcG9uZW50QWN0aXZpdHkoKSB7CiAgICBvdmVycmlkZSBmdW4gb25DcmVhdGUoc2F2ZWRJbnN0YW5jZVN0YXRlOiBCdW5k' >> "$TMPB64"
    printf '%s' 'bGU/KSB7CiAgICAgICAgc3VwZXIub25DcmVhdGUoc2F2ZWRJbnN0YW5jZVN0YXRlKQogICAgICAgIHZhbCBhcHBDdHggPSBhcHBs' >> "$TMPB64"
    printf '%s' 'aWNhdGlvbkNvbnRleHQKICAgICAgICBNdXNpY1RoZW1lTWFuYWdlci5pbml0KGFwcEN0eCkKICAgICAgICBXYWxscGFwZXJNYW5h' >> "$TMPB64"
    printf '%s' 'Z2VyLmluaXQoYXBwQ3R4KQogICAgICAgIHNldENvbnRlbnQgewogICAgICAgICAgICB2YWwgaXNEYXJrIGJ5IE11c2ljVGhlbWVN' >> "$TMPB64"
    printf '%s' 'YW5hZ2VyLmlzRGFya1RoZW1lCiAgICAgICAgICAgIHZhbCB3aW5kb3cgPSB0aGlzQEx4V2FsbHBhcGVyU2V0dGluZ3NBY3Rpdml0' >> "$TMPB64"
    printf '%s' 'eS53aW5kb3cKICAgICAgICAgICAgU2lkZUVmZmVjdCB7CiAgICAgICAgICAgICAgICBXaW5kb3dDb21wYXQuZ2V0SW5zZXRzQ29u' >> "$TMPB64"
    printf '%s' 'dHJvbGxlcih3aW5kb3csIHdpbmRvdy5kZWNvclZpZXcpCiAgICAgICAgICAgICAgICAgICAgLmlzQXBwZWFyYW5jZUxpZ2h0U3Rh' >> "$TMPB64"
    printf '%s' 'dHVzQmFycyA9ICFpc0RhcmsKICAgICAgICAgICAgfQogICAgICAgICAgICBMeE11c2ljVGhlbWUoaXNEYXJrVGhlbWUgPSBpc0Rh' >> "$TMPB64"
    printf '%s' 'cmspIHsKICAgICAgICAgICAgICAgIFdhbGxwYXBlclNldHRpbmdzU2NyZWVuKG9uQmFjayA9IHsgZmluaXNoKCkgfSkKICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgfQogICAgICAgIH0KICAgIH0KfQoKQE9wdEluKEV4cGVyaW1lbnRhbExheW91dEFwaTo6Y2xhc3MpIC8vIFszOXdwYWRh' >> "$TMPB64"
    printf '%s' 'cHRdIEZsb3dSb3cg6ZyA5a6e6aqMIEFQSSDmoIforrAKQENvbXBvc2FibGUKZnVuIFdhbGxwYXBlclNldHRpbmdzU2NyZWVuKG9u' >> "$TMPB64"
    printf '%s' 'QmFjazogKCkgLT4gVW5pdCkgewogICAgdmFsIGNvbnRleHQgPSBMb2NhbENvbnRleHQuY3VycmVudAogICAgdmFsIHdwU3RhdGUg' >> "$TMPB64"
    printf '%s' 'YnkgV2FsbHBhcGVyTWFuYWdlci5zdGF0ZS5jb2xsZWN0QXNTdGF0ZSgpCiAgICB2YXIgdXJsVGV4dCBieSByZW1lbWJlciB7IG11' >> "$TMPB64"
    printf '%s' 'dGFibGVTdGF0ZU9mKHdwU3RhdGUudXJsKSB9CiAgICB2YWwgcGlja2VyID0gcmVtZW1iZXJMYXVuY2hlckZvckFjdGl2aXR5UmVz' >> "$TMPB64"
    printf '%s' 'dWx0KEFjdGl2aXR5UmVzdWx0Q29udHJhY3RzLk9wZW5Eb2N1bWVudCgpKSB7IHVyaSAtPgogICAgICAgIGlmICh1cmkgIT0gbnVs' >> "$TMPB64"
    printf '%s' 'bCkgewogICAgICAgICAgICB0cnkgewogICAgICAgICAgICAgICAgY29udGV4dC5jb250ZW50UmVzb2x2ZXIudGFrZVBlcnNpc3Rh' >> "$TMPB64"
    printf '%s' 'YmxlVXJpUGVybWlzc2lvbih1cmksIEludGVudC5GTEFHX0dSQU5UX1JFQURfVVJJX1BFUk1JU1NJT04pCiAgICAgICAgICAgIH0g' >> "$TMPB64"
    printf '%s' 'Y2F0Y2ggKGU6IEV4Y2VwdGlvbikgewogICAgICAgICAgICAgICAgYW5kcm9pZC51dGlsLkxvZy53KCJXYWxscGFwZXIiLCAi5pys' >> "$TMPB64"
    printf '%s' '5Zyw5Zu+5oyB5LmF5o6I5p2D5aSx6LSlIiwgZSkKICAgICAgICAgICAgfQogICAgICAgICAgICBXYWxscGFwZXJNYW5hZ2VyLmFw' >> "$TMPB64"
    printf '%s' 'cGx5KGNvbnRleHQsIHVyaS50b1N0cmluZygpKQogICAgICAgICAgICB1cmxUZXh0ID0gdXJpLnRvU3RyaW5nKCkKICAgICAgICB9' >> "$TMPB64"
    printf '%s' 'CiAgICB9CiAgICBDb2x1bW4oCiAgICAgICAgbW9kaWZpZXIgPSBNb2RpZmllcgogICAgICAgICAgICAuZmlsbE1heFNpemUoKQog' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAuYmFja2dyb3VuZChtdXNpY0NvbG9ycygpLmJhY2tncm91bmQpCiAgICApIHsKICAgICAgICBSb3coCiAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgIG1vZGlmaWVyID0gTW9kaWZpZXIKICAgICAgICAgICAgICAgIC5maWxsTWF4V2lkdGgoKQogICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'LnBhZGRpbmcoc3RhcnQgPSA4LmRwLCBlbmQgPSAxNi5kcCwgdG9wID0gNDguZHAsIGJvdHRvbSA9IDguZHApLAogICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICB2ZXJ0aWNhbEFsaWdubWVudCA9IEFsaWdubWVudC5DZW50ZXJWZXJ0aWNhbGx5LAogICAgICAgICkgewogICAgICAgICAgICBU' >> "$TMPB64"
    printf '%s' 'ZXh0KAogICAgICAgICAgICAgICAgdGV4dCA9ICLigLkiLAogICAgICAgICAgICAgICAgc3R5bGUgPSBNYXRlcmlhbFRoZW1lLnR5' >> "$TMPB64"
    printf '%s' 'cG9ncmFwaHkuaGVhZGxpbmVNZWRpdW0sCiAgICAgICAgICAgICAgICBjb2xvciA9IG11c2ljQ29sb3JzKCkudGV4dFByaW1hcnks' >> "$TMPB64"
    printf '%s' 'CiAgICAgICAgICAgICAgICBtb2RpZmllciA9IE1vZGlmaWVyCiAgICAgICAgICAgICAgICAgICAgLmNsaWNrYWJsZSB7IG9uQmFj' >> "$TMPB64"
    printf '%s' 'aygpIH0KICAgICAgICAgICAgICAgICAgICAucGFkZGluZyhob3Jpem9udGFsID0gMTIuZHAsIHZlcnRpY2FsID0gNC5kcCksCiAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICkKICAgICAgICAgICAgVGV4dCgKICAgICAgICAgICAgICAgIHRleHQgPSAi5aOB57q46K6+572uIiwKICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgIHN0eWxlID0gTWF0ZXJpYWxUaGVtZS50eXBvZ3JhcGh5LnRpdGxlTWVkaXVtLmNvcHkoZm9udFdlaWdodCA9IEZv' >> "$TMPB64"
    printf '%s' 'bnRXZWlnaHQuQm9sZCksCiAgICAgICAgICAgICAgICBjb2xvciA9IG11c2ljQ29sb3JzKCkudGV4dFByaW1hcnksCiAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICkKICAgICAgICB9CiAgICAgICAgTGF6eUNvbHVtbigKICAgICAgICAgICAgbW9kaWZpZXIgPSBNb2RpZmllci5maWxsTWF4' >> "$TMPB64"
    printf '%s' 'U2l6ZSgpLAogICAgICAgICAgICBjb250ZW50UGFkZGluZyA9IFBhZGRpbmdWYWx1ZXMoMTYuZHApLAogICAgICAgICAgICB2ZXJ0' >> "$TMPB64"
    printf '%s' 'aWNhbEFycmFuZ2VtZW50ID0gQXJyYW5nZW1lbnQuc3BhY2VkQnkoMTIuZHApLAogICAgICAgICkgewogICAgICAgICAgICBpdGVt' >> "$TMPB64"
    printf '%s' 'IHsKICAgICAgICAgICAgICAgIENhcmQoCiAgICAgICAgICAgICAgICAgICAgY29sb3JzID0gQ2FyZERlZmF1bHRzLmNhcmRDb2xv' >> "$TMPB64"
    printf '%s' 'cnMoY29udGFpbmVyQ29sb3IgPSBtdXNpY0NvbG9ycygpLmNhcmQpLAogICAgICAgICAgICAgICAgICAgIHNoYXBlID0gUm91bmRl' >> "$TMPB64"
    printf '%s' 'ZENvcm5lclNoYXBlKDE2LmRwKSwKICAgICAgICAgICAgICAgICkgewogICAgICAgICAgICAgICAgICAgIFJvdygKICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgbW9kaWZpZXIgPSBNb2RpZmllcgogICAgICAgICAgICAgICAgICAgICAgICAgICAgLmZpbGxNYXhXaWR0' >> "$TMPB64"
    printf '%s' 'aCgpCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAucGFkZGluZygxMi5kcCksCiAgICAgICAgICAgICAgICAgICAgICAgIHZl' >> "$TMPB64"
    printf '%s' 'cnRpY2FsQWxpZ25tZW50ID0gQWxpZ25tZW50LkNlbnRlclZlcnRpY2FsbHksCiAgICAgICAgICAgICAgICAgICAgKSB7CiAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgIENvbHVtbihtb2RpZmllciA9IE1vZGlmaWVyLndlaWdodCgxZikpIHsKICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgIFRleHQoIuWQr+eUqOWjgee6uOiDjOaZryIsIHN0eWxlID0gTWF0ZXJpYWxUaGVtZS50eXBvZ3JhcGh5LmJv' >> "$TMPB64"
    printf '%s' 'ZHlNZWRpdW0sIGNvbG9yID0gbXVzaWNDb2xvcnMoKS50ZXh0UHJpbWFyeSkKICAgICAgICAgICAgICAgICAgICAgICAgICAgIFNw' >> "$TMPB64"
    printf '%s' 'YWNlcihtb2RpZmllciA9IE1vZGlmaWVyLmhlaWdodCgyLmRwKSkKICAgICAgICAgICAgICAgICAgICAgICAgICAgIFRleHQoIumf' >> "$TMPB64"
    printf '%s' 's+S5kOS4k+WMuuW6leWxguiDjOaZr+Wbvu+8iOW4puWPr+ivu+aAp+mBrue9qe+8iSIsIHN0eWxlID0gTWF0ZXJpYWxUaGVtZS50' >> "$TMPB64"
    printf '%s' 'eXBvZ3JhcGh5LmJvZHlTbWFsbCwgY29sb3IgPSBtdXNpY0NvbG9ycygpLnRleHRTZWNvbmRhcnkpCiAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgIH0KICAgICAgICAgICAgICAgICAgICAgICAgU3dpdGNoKAogICAgICAgICAgICAgICAgICAgICAgICAgICAgY2hlY2tl' >> "$TMPB64"
    printf '%s' 'ZCA9IHdwU3RhdGUuZW5hYmxlZCwKICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hlY2tlZENoYW5nZSA9IHsgV2FsbHBh' >> "$TMPB64"
    printf '%s' 'cGVyTWFuYWdlci5zZXRFbmFibGVkKGNvbnRleHQsIGl0KSB9LAogICAgICAgICAgICAgICAgICAgICAgICAgICAgY29sb3JzID0g' >> "$TMPB64"
    printf '%s' 'U3dpdGNoRGVmYXVsdHMuY29sb3JzKAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNoZWNrZWRUaHVtYkNvbG9yID0g' >> "$TMPB64"
    printf '%s' 'Q29sb3IuV2hpdGUsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgY2hlY2tlZFRyYWNrQ29sb3IgPSBtdXNpY0NvbG9y' >> "$TMPB64"
    printf '%s' 'cygpLmFjY2VudCwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB1bmNoZWNrZWRUaHVtYkNvbG9yID0gQ29sb3IuV2hp' >> "$TMPB64"
    printf '%s' 'dGUsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgdW5jaGVja2VkVHJhY2tDb2xvciA9IG11c2ljQ29sb3JzKCkuY2Fy' >> "$TMPB64"
    printf '%s' 'ZFNlY29uZGFyeSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICksCiAgICAgICAgICAgICAgICAgICAgICAgICkKICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICB9CiAgICAgICAgICAgICAgICB9CiAgICAgICAgICAgIH0KICAgICAgICAgICAgaXRlbSB7CiAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICBDYXJkKAogICAgICAgICAgICAgICAgICAgIGNvbG9ycyA9IENhcmREZWZhdWx0cy5jYXJkQ29sb3JzKGNvbnRhaW5l' >> "$TMPB64"
    printf '%s' 'ckNvbG9yID0gbXVzaWNDb2xvcnMoKS5jYXJkKSwKICAgICAgICAgICAgICAgICAgICBzaGFwZSA9IFJvdW5kZWRDb3JuZXJTaGFw' >> "$TMPB64"
    printf '%s' 'ZSgxNi5kcCksCiAgICAgICAgICAgICAgICApIHsKICAgICAgICAgICAgICAgICAgICBDb2x1bW4obW9kaWZpZXIgPSBNb2RpZmll' >> "$TMPB64"
    printf '%s' 'ci5wYWRkaW5nKDEyLmRwKSkgewogICAgICAgICAgICAgICAgICAgICAgICBUZXh0KCLnvZHnu5zlo4HnurgiLCBzdHlsZSA9IE1h' >> "$TMPB64"
    printf '%s' 'dGVyaWFsVGhlbWUudHlwb2dyYXBoeS5ib2R5TWVkaXVtLCBjb2xvciA9IG11c2ljQ29sb3JzKCkudGV4dFByaW1hcnkpCiAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgIFNwYWNlcihtb2RpZmllciA9IE1vZGlmaWVyLmhlaWdodCg4LmRwKSkKICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgT3V0bGluZWRUZXh0RmllbGQoCiAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZSA9IHVybFRleHQsCiAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICBvblZhbHVlQ2hhbmdlID0geyB1cmxUZXh0ID0gaXQgfSwKICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgIGxhYmVsID0geyBUZXh0KCLlm77niYcgVVJM77yIaHR0cC9odHRwc++8iSIpIH0sCiAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICBzaW5nbGVMaW5lID0gdHJ1ZSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgIG1vZGlmaWVyID0gTW9k' >> "$TMPB64"
    printf '%s' 'aWZpZXIuZmlsbE1heFdpZHRoKCksCiAgICAgICAgICAgICAgICAgICAgICAgICAgICBjb2xvcnMgPSBPdXRsaW5lZFRleHRGaWVs' >> "$TMPB64"
    printf '%s' 'ZERlZmF1bHRzLmNvbG9ycygKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBmb2N1c2VkQm9yZGVyQ29sb3IgPSBtdXNp' >> "$TMPB64"
    printf '%s' 'Y0NvbG9ycygpLmFjY2VudCwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB1bmZvY3VzZWRCb3JkZXJDb2xvciA9IG11' >> "$TMPB64"
    printf '%s' 'c2ljQ29sb3JzKCkuZGl2aWRlciwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBjdXJzb3JDb2xvciA9IG11c2ljQ29s' >> "$TMPB64"
    printf '%s' 'b3JzKCkuYWNjZW50LAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGZvY3VzZWRMYWJlbENvbG9yID0gbXVzaWNDb2xv' >> "$TMPB64"
    printf '%s' 'cnMoKS5hY2NlbnQsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgdW5mb2N1c2VkTGFiZWxDb2xvciA9IG11c2ljQ29s' >> "$TMPB64"
    printf '%s' 'b3JzKCkudGV4dFNlY29uZGFyeSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBmb2N1c2VkVGV4dENvbG9yID0gbXVz' >> "$TMPB64"
    printf '%s' 'aWNDb2xvcnMoKS50ZXh0UHJpbWFyeSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB1bmZvY3VzZWRUZXh0Q29sb3Ig' >> "$TMPB64"
    printf '%s' 'PSBtdXNpY0NvbG9ycygpLnRleHRQcmltYXJ5LAogICAgICAgICAgICAgICAgICAgICAgICAgICAgKSwKICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgKQogICAgICAgICAgICAgICAgICAgICAgICBTcGFjZXIobW9kaWZpZXIgPSBNb2RpZmllci5oZWlnaHQoOC5kcCkp' >> "$TMPB64"
    printf '%s' 'CiAgICAgICAgICAgICAgICAgICAgICAgIFJvdyhob3Jpem9udGFsQXJyYW5nZW1lbnQgPSBBcnJhbmdlbWVudC5zcGFjZWRCeSgx' >> "$TMPB64"
    printf '%s' 'MC5kcCkpIHsgLy8gWzM5d3BhZGFwdF0g5Lik5oyJ6ZKu5Z2H5YiGLCDlsI/lsY/kuI3muqLlh7oKICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgIEJ1dHRvbigKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBtb2RpZmllciA9IE1vZGlmaWVyLndlaWdo' >> "$TMPB64"
    printf '%s' 'dCgxZiksCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgb25DbGljayA9IHsgV2FsbHBhcGVyTWFuYWdlci5hcHBseShj' >> "$TMPB64"
    printf '%s' 'b250ZXh0LCB1cmxUZXh0KSB9LAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNvbG9ycyA9IEJ1dHRvbkRlZmF1bHRz' >> "$TMPB64"
    printf '%s' 'LmJ1dHRvbkNvbG9ycygKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgY29udGFpbmVyQ29sb3IgPSBtdXNpY0Nv' >> "$TMPB64"
    printf '%s' 'bG9ycygpLmFjY2VudCwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgY29udGVudENvbG9yID0gbXVzaWNDb2xv' >> "$TMPB64"
    printf '%s' 'cnMoKS5hY2NlbnRUZXh0LAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICksCiAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICApIHsgVGV4dCgi5bqU55So5q2kIFVSTCIpIH0KICAgICAgICAgICAgICAgICAgICAgICAgICAgIE91dGxpbmVkQnV0dG9u' >> "$TMPB64"
    printf '%s' 'KAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIG1vZGlmaWVyID0gTW9kaWZpZXIud2VpZ2h0KDFmKSwKICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICBvbkNsaWNrID0geyBwaWNrZXIubGF1bmNoKGFycmF5T2YoImltYWdlLyoiKSkgfSwKICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICkgewogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIFRleHQoIuacrOWcsOmA' >> "$TMPB64"
    printf '%s' 'ieWbviIsIGNvbG9yID0gbXVzaWNDb2xvcnMoKS50ZXh0UHJpbWFyeSkKICAgICAgICAgICAgICAgICAgICAgICAgICAgIH0KICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgfQogICAgICAgICAgICAgICAgICAgIH0KICAgICAgICAgICAgICAgIH0KICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'fQogICAgICAgICAgICBpdGVtIHsKICAgICAgICAgICAgICAgIENhcmQoCiAgICAgICAgICAgICAgICAgICAgY29sb3JzID0gQ2Fy' >> "$TMPB64"
    printf '%s' 'ZERlZmF1bHRzLmNhcmRDb2xvcnMoY29udGFpbmVyQ29sb3IgPSBtdXNpY0NvbG9ycygpLmNhcmQpLAogICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgIHNoYXBlID0gUm91bmRlZENvcm5lclNoYXBlKDE2LmRwKSwKICAgICAgICAgICAgICAgICAgICBtb2RpZmllciA9IE1vZGlm' >> "$TMPB64"
    printf '%s' 'aWVyCiAgICAgICAgICAgICAgICAgICAgICAgIC5maWxsTWF4V2lkdGgoKQogICAgICAgICAgICAgICAgICAgICAgICAuY2xpY2th' >> "$TMPB64"
    printf '%s' 'YmxlIHsKICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNvbnRleHQuc3RhcnRBY3Rpdml0eShJbnRlbnQoY29udGV4dCwgV2Fs' >> "$TMPB64"
    printf '%s' 'bHBhcGVyTGlicmFyeUFjdGl2aXR5OjpjbGFzcy5qYXZhKSkKICAgICAgICAgICAgICAgICAgICAgICAgfSwKICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICkgewogICAgICAgICAgICAgICAgICAgIFJvdygKICAgICAgICAgICAgICAgICAgICAgICAgbW9kaWZpZXIgPSBNb2RpZmll' >> "$TMPB64"
    printf '%s' 'cgogICAgICAgICAgICAgICAgICAgICAgICAgICAgLmZpbGxNYXhXaWR0aCgpCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAu' >> "$TMPB64"
    printf '%s' 'cGFkZGluZygxMi5kcCksCiAgICAgICAgICAgICAgICAgICAgICAgIHZlcnRpY2FsQWxpZ25tZW50ID0gQWxpZ25tZW50LkNlbnRl' >> "$TMPB64"
    printf '%s' 'clZlcnRpY2FsbHksCiAgICAgICAgICAgICAgICAgICAgKSB7CiAgICAgICAgICAgICAgICAgICAgICAgIENvbHVtbihtb2RpZmll' >> "$TMPB64"
    printf '%s' 'ciA9IE1vZGlmaWVyLndlaWdodCgxZikpIHsKICAgICAgICAgICAgICAgICAgICAgICAgICAgIFRleHQoIuWcqOe6v+Wjgee6uOW6' >> "$TMPB64"
    printf '%s' 'kyIsIHN0eWxlID0gTWF0ZXJpYWxUaGVtZS50eXBvZ3JhcGh5LmJvZHlNZWRpdW0sIGNvbG9yID0gbXVzaWNDb2xvcnMoKS50ZXh0' >> "$TMPB64"
    printf '%s' 'UHJpbWFyeSkKICAgICAgICAgICAgICAgICAgICAgICAgICAgIFNwYWNlcihtb2RpZmllciA9IE1vZGlmaWVyLmhlaWdodCgyLmRw' >> "$TMPB64"
    printf '%s' 'KSkKICAgICAgICAgICAgICAgICAgICAgICAgICAgIFRleHQoIueyvumAiee9kee7nOWjgee6uO+8jOeCueWHu+WNs+W6lOeUqCIs' >> "$TMPB64"
    printf '%s' 'IHN0eWxlID0gTWF0ZXJpYWxUaGVtZS50eXBvZ3JhcGh5LmJvZHlTbWFsbCwgY29sb3IgPSBtdXNpY0NvbG9ycygpLnRleHRTZWNv' >> "$TMPB64"
    printf '%s' 'bmRhcnkpCiAgICAgICAgICAgICAgICAgICAgICAgIH0KICAgICAgICAgICAgICAgICAgICAgICAgVGV4dCgi4oC6Iiwgc3R5bGUg' >> "$TMPB64"
    printf '%s' 'PSBNYXRlcmlhbFRoZW1lLnR5cG9ncmFwaHkuaGVhZGxpbmVNZWRpdW0sIGNvbG9yID0gbXVzaWNDb2xvcnMoKS50ZXh0U2Vjb25k' >> "$TMPB64"
    printf '%s' 'YXJ5KQogICAgICAgICAgICAgICAgICAgIH0KICAgICAgICAgICAgICAgIH0KICAgICAgICAgICAgfQogICAgICAgICAgICBpdGVt' >> "$TMPB64"
    printf '%s' 'IHsKICAgICAgICAgICAgICAgIENhcmQoCiAgICAgICAgICAgICAgICAgICAgY29sb3JzID0gQ2FyZERlZmF1bHRzLmNhcmRDb2xv' >> "$TMPB64"
    printf '%s' 'cnMoY29udGFpbmVyQ29sb3IgPSBtdXNpY0NvbG9ycygpLmNhcmQpLAogICAgICAgICAgICAgICAgICAgIHNoYXBlID0gUm91bmRl' >> "$TMPB64"
    printf '%s' 'ZENvcm5lclNoYXBlKDE2LmRwKSwKICAgICAgICAgICAgICAgICkgewogICAgICAgICAgICAgICAgICAgIENvbHVtbihtb2RpZmll' >> "$TMPB64"
    printf '%s' 'ciA9IE1vZGlmaWVyLnBhZGRpbmcoMTIuZHApKSB7CiAgICAgICAgICAgICAgICAgICAgICAgIFRleHQoIua4kOWPmOiDjOaZryIs' >> "$TMPB64"
    printf '%s' 'IHN0eWxlID0gTWF0ZXJpYWxUaGVtZS50eXBvZ3JhcGh5LmJvZHlNZWRpdW0sIGNvbG9yID0gbXVzaWNDb2xvcnMoKS50ZXh0UHJp' >> "$TMPB64"
    printf '%s' 'bWFyeSkKICAgICAgICAgICAgICAgICAgICAgICAgU3BhY2VyKG1vZGlmaWVyID0gTW9kaWZpZXIuaGVpZ2h0KDIuZHApKQogICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICBUZXh0KCLkuI3nlKjlm77niYfvvIzkuIDlsYLmuJDlj5jkvZzlupXvvIjlkIzmoLfluKblj6/o' >> "$TMPB64"
    printf '%s' 'r7vmgKfpga7nvanvvIkiLCBzdHlsZSA9IE1hdGVyaWFsVGhlbWUudHlwb2dyYXBoeS5ib2R5U21hbGwsIGNvbG9yID0gbXVzaWND' >> "$TMPB64"
    printf '%s' 'b2xvcnMoKS50ZXh0U2Vjb25kYXJ5KQogICAgICAgICAgICAgICAgICAgICAgICBTcGFjZXIobW9kaWZpZXIgPSBNb2RpZmllci5o' >> "$TMPB64"
    printf '%s' 'ZWlnaHQoOC5kcCkpCiAgICAgICAgICAgICAgICAgICAgICAgIFJvdyhob3Jpem9udGFsQXJyYW5nZW1lbnQgPSBBcnJhbmdlbWVu' >> "$TMPB64"
    printf '%s' 'dC5zcGFjZWRCeSgxMi5kcCkpIHsKICAgICAgICAgICAgICAgICAgICAgICAgICAgIFdQX0dSQURJRU5UX1BSRVNFVFMuZm9yRWFj' >> "$TMPB64"
    printf '%s' 'aCB7IChuYW1lLCBoMSwgaDIpIC0+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgdmFsIHBhaXIgPSAiJGgxLCRoMiIK' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWwgaXNDdXJyZW50ID0gd3BTdGF0ZS5tb2RlID09ICJncmFkaWVudCIg' >> "$TMPB64"
    printf '%s' 'JiYgd3BTdGF0ZS5ncmFkaWVudCA9PSBwYWlyCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgQ29sdW1uKGhvcml6b250' >> "$TMPB64"
    printf '%s' 'YWxBbGlnbm1lbnQgPSBBbGlnbm1lbnQuQ2VudGVySG9yaXpvbnRhbGx5KSB7CiAgICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgIEJveCgKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIG1vZGlmaWVyID0gTW9kaWZpZXIKICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAuc2l6ZSg1Ni5kcCkKICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAuY2xpcChSb3VuZGVkQ29ybmVyU2hhcGUoMTIuZHApKQogICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgIC5iYWNrZ3JvdW5kKEJydXNoLmxpbmVhckdyYWRpZW50KGxpc3RPZih3cFBhcnNlQ29s' >> "$TMPB64"
    printf '%s' 'b3IoaDEpLCB3cFBhcnNlQ29sb3IoaDIpKSkpCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgLnRo' >> "$TMPB64"
    printf '%s' 'ZW4oCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGlmIChpc0N1cnJlbnQpIE1vZGlmaWVy' >> "$TMPB64"
    printf '%s' 'LmJvcmRlcigyLmRwLCBtdXNpY0NvbG9ycygpLmFjY2VudCwgUm91bmRlZENvcm5lclNoYXBlKDEyLmRwKSkKICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZWxzZSBNb2RpZmllcgogICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICkKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAuY2xpY2thYmxl' >> "$TMPB64"
    printf '%s' 'IHsKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgV2FsbHBhcGVyTWFuYWdlci5hcHBseUdy' >> "$TMPB64"
    printf '%s' 'YWRpZW50KGNvbnRleHQsIHBhaXIpCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGFuZHJv' >> "$TMPB64"
    printf '%s' 'aWQud2lkZ2V0LlRvYXN0Lm1ha2VUZXh0KGNvbnRleHQsICLmuJDlj5jlt7LlupTnlKgiLCBhbmRyb2lkLndpZGdldC5Ub2FzdC5M' >> "$TMPB64"
    printf '%s' 'RU5HVEhfU0hPUlQpLnNob3coKQogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIH0sCiAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICkKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgU3BhY2VyKG1v' >> "$TMPB64"
    printf '%s' 'ZGlmaWVyID0gTW9kaWZpZXIuaGVpZ2h0KDYuZHApKQogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBUZXh0KG5h' >> "$TMPB64"
    printf '%s' 'bWUsIHN0eWxlID0gTWF0ZXJpYWxUaGVtZS50eXBvZ3JhcGh5LmJvZHlTbWFsbCwgY29sb3IgPSBtdXNpY0NvbG9ycygpLnRleHRQ' >> "$TMPB64"
    printf '%s' 'cmltYXJ5KQogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIH0KICAgICAgICAgICAgICAgICAgICAgICAgICAgIH0KICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgfQogICAgICAgICAgICAgICAgICAgIH0KICAgICAgICAgICAgICAgIH0KICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'fQogICAgICAgICAgICBpdGVtIHsKICAgICAgICAgICAgICAgIC8vIFszOXdwNF0g5pWI5p6c6LCD5pW0OiDmloflrZfpopzoibLm' >> "$TMPB64"
    printf '%s' 'qKHlvI8gKyDpga7nvanmtZPluqYKICAgICAgICAgICAgICAgIC8vIFszOXdwNV0g6YGu572p5a+56b2QIFBlZWsgZGFya092ZXJs' >> "$TMPB64"
    printf '%s' 'YXk6IOe6r+m7kSwg6buY6K6kIDAg5peg57qxLCDmmL7npLrnnJ/lrp7lgLwKICAgICAgICAgICAgICAgIHZhbCBlZmZTY3JpbSA9' >> "$TMPB64"
    printf '%s' 'IHdwU3RhdGUuc2NyaW0uY29lcmNlQXRMZWFzdCgwKQogICAgICAgICAgICAgICAgdmFyIHNjcmltU2xpZGVyIGJ5IHJlbWVtYmVy' >> "$TMPB64"
    printf '%s' 'KHdwU3RhdGUuc2NyaW0pIHsgbXV0YWJsZVN0YXRlT2YoZWZmU2NyaW0udG9GbG9hdCgpKSB9CiAgICAgICAgICAgICAgICB2YXIg' >> "$TMPB64"
    printf '%s' 'b3BhY2l0eVNsaWRlciBieSByZW1lbWJlcih3cFN0YXRlLm9wYWNpdHkpIHsgbXV0YWJsZVN0YXRlT2Yod3BTdGF0ZS5vcGFjaXR5' >> "$TMPB64"
    printf '%s' 'LnRvRmxvYXQoKSkgfQogICAgICAgICAgICAgICAgdmFyIGJsdXJTbGlkZXIgYnkgcmVtZW1iZXIod3BTdGF0ZS5ibHVyKSB7IG11' >> "$TMPB64"
    printf '%s' 'dGFibGVTdGF0ZU9mKHdwU3RhdGUuYmx1ci50b0Zsb2F0KCkpIH0KICAgICAgICAgICAgICAgIENhcmQoCiAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgY29sb3JzID0gQ2FyZERlZmF1bHRzLmNhcmRDb2xvcnMoY29udGFpbmVyQ29sb3IgPSBtdXNpY0NvbG9ycygpLmNhcmQp' >> "$TMPB64"
    printf '%s' 'LAogICAgICAgICAgICAgICAgICAgIHNoYXBlID0gUm91bmRlZENvcm5lclNoYXBlKDE2LmRwKSwKICAgICAgICAgICAgICAgICkg' >> "$TMPB64"
    printf '%s' 'ewogICAgICAgICAgICAgICAgICAgIENvbHVtbihtb2RpZmllciA9IE1vZGlmaWVyLnBhZGRpbmcoMTIuZHApKSB7CiAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgIFRleHQoIuaViOaenOiwg+aVtCIsIHN0eWxlID0gTWF0ZXJpYWxUaGVtZS50eXBvZ3JhcGh5LmJvZHlN' >> "$TMPB64"
    printf '%s' 'ZWRpdW0sIGNvbG9yID0gbXVzaWNDb2xvcnMoKS50ZXh0UHJpbWFyeSkKICAgICAgICAgICAgICAgICAgICAgICAgU3BhY2VyKG1v' >> "$TMPB64"
    printf '%s' 'ZGlmaWVyID0gTW9kaWZpZXIuaGVpZ2h0KDguZHApKQogICAgICAgICAgICAgICAgICAgICAgICBUZXh0KCLmloflrZfpopzoibLm' >> "$TMPB64"
    printf '%s' 'qKHlvI8iLCBzdHlsZSA9IE1hdGVyaWFsVGhlbWUudHlwb2dyYXBoeS5ib2R5U21hbGwsIGNvbG9yID0gbXVzaWNDb2xvcnMoKS50' >> "$TMPB64"
    printf '%s' 'ZXh0U2Vjb25kYXJ5KQogICAgICAgICAgICAgICAgICAgICAgICBTcGFjZXIobW9kaWZpZXIgPSBNb2RpZmllci5oZWlnaHQoOC5k' >> "$TMPB64"
    printf '%s' 'cCkpCiAgICAgICAgICAgICAgICAgICAgICAgIEZsb3dSb3coIC8vIFszOXdwYWRhcHRdIOaooeW8jyBwaWxsIOWwj+Wxj+iHquWK' >> "$TMPB64"
    printf '%s' 'qOaKmOihjCwg5LiN5YaN56uW5Y+g5oyk5a2XCiAgICAgICAgICAgICAgICAgICAgICAgICAgICBob3Jpem9udGFsQXJyYW5nZW1l' >> "$TMPB64"
    printf '%s' 'bnQgPSBBcnJhbmdlbWVudC5zcGFjZWRCeSg4LmRwKSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZlcnRpY2FsQXJyYW5n' >> "$TMPB64"
    printf '%s' 'ZW1lbnQgPSBBcnJhbmdlbWVudC5zcGFjZWRCeSg4LmRwKSwKICAgICAgICAgICAgICAgICAgICAgICAgKSB7CiAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICBXUF9URVhUX01PREVTLmZvckVhY2ggeyAodmFsdWUsIGxhYmVsKSAtPgogICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgIHZhbCBzZWxlY3RlZCA9IHdwU3RhdGUudGV4dE1vZGUgPT0gdmFsdWUKICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICBCb3goCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIG1vZGlmaWVyID0gTW9kaWZpZXIK' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIC5jbGlwKFJvdW5kZWRDb3JuZXJTaGFwZSg1MCkpCiAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAuYmFja2dyb3VuZChpZiAoc2VsZWN0ZWQpIG11c2ljQ29sb3JzKCku' >> "$TMPB64"
    printf '%s' 'YWNjZW50IGVsc2UgbXVzaWNDb2xvcnMoKS5jYXJkU2Vjb25kYXJ5KQogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgLmNsaWNrYWJsZSB7IFdhbGxwYXBlck1hbmFnZXIuc2V0VGV4dE1vZGUoY29udGV4dCwgdmFsdWUpIH0KICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIC5wYWRkaW5nKGhvcml6b250YWwgPSAxMi5kcCwgdmVydGljYWwgPSA2LmRw' >> "$TMPB64"
    printf '%s' 'KSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICApIHsKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'VGV4dCgKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHRleHQgPSBsYWJlbCwKICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgIHN0eWxlID0gTWF0ZXJpYWxUaGVtZS50eXBvZ3JhcGh5LmJvZHlTbWFsbCwKICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNvbG9yID0gaWYgKHNlbGVjdGVkKSBtdXNpY0NvbG9ycygpLmFjY2Vu' >> "$TMPB64"
    printf '%s' 'dFRleHQgZWxzZSBtdXNpY0NvbG9ycygpLnRleHRTZWNvbmRhcnksCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICkKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB9CiAgICAgICAgICAgICAgICAgICAgICAgICAgICB9CiAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgIH0KICAgICAgICAgICAgICAgICAgICAgICAgU3BhY2VyKG1vZGlmaWVyID0gTW9kaWZpZXIuaGVpZ2h0' >> "$TMPB64"
    printf '%s' 'KDQuZHApKQogICAgICAgICAgICAgICAgICAgICAgICBUZXh0KAogICAgICAgICAgICAgICAgICAgICAgICAgICAgdGV4dCA9ICLl' >> "$TMPB64"
    printf '%s' 'o4HnurjlgY/mt7HpgInmtYXoibLmloflrZfvvIzlgY/mtYXpgInmt7HoibLmloflrZfvvIzlnKjlo4HnurjkuIrmiY3nnIvlvpfm' >> "$TMPB64"
    printf '%s' 'uIXvvJvot5/pmo/kuLvpopjliJnnlKjkuLvpopjmt7HmtYXjgIIiLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgc3R5bGUg' >> "$TMPB64"
    printf '%s' 'PSBNYXRlcmlhbFRoZW1lLnR5cG9ncmFwaHkuYm9keVNtYWxsLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgY29sb3IgPSBt' >> "$TMPB64"
    printf '%s' 'dXNpY0NvbG9ycygpLnRleHRTZWNvbmRhcnksCiAgICAgICAgICAgICAgICAgICAgICAgICkKICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgU3BhY2VyKG1vZGlmaWVyID0gTW9kaWZpZXIuaGVpZ2h0KDEyLmRwKSkKICAgICAgICAgICAgICAgICAgICAgICAgUm93KAog' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgbW9kaWZpZXIgPSBNb2RpZmllci5maWxsTWF4V2lkdGgoKSwKICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgIHZlcnRpY2FsQWxpZ25tZW50ID0gQWxpZ25tZW50LkNlbnRlclZlcnRpY2FsbHksCiAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICkgewogICAgICAgICAgICAgICAgICAgICAgICAgICAgVGV4dCgi6YGu572p5rWT5bqmIiwgc3R5bGUgPSBN' >> "$TMPB64"
    printf '%s' 'YXRlcmlhbFRoZW1lLnR5cG9ncmFwaHkuYm9keVNtYWxsLCBjb2xvciA9IG11c2ljQ29sb3JzKCkudGV4dFNlY29uZGFyeSkKICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgIFNwYWNlcihtb2RpZmllciA9IE1vZGlmaWVyLndlaWdodCgxZikpCiAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICBUZXh0KAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHRleHQgPSAiJHtzY3JpbVNsaWRl' >> "$TMPB64"
    printf '%s' 'ci50b0ludCgpfSUiLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHN0eWxlID0gTWF0ZXJpYWxUaGVtZS50eXBvZ3Jh' >> "$TMPB64"
    printf '%s' 'cGh5LmJvZHlTbWFsbCwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBjb2xvciA9IG11c2ljQ29sb3JzKCkudGV4dFBy' >> "$TMPB64"
    printf '%s' 'aW1hcnksCiAgICAgICAgICAgICAgICAgICAgICAgICAgICApCiAgICAgICAgICAgICAgICAgICAgICAgIH0KICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgQ29tcGFjdFNsaWRlcigKICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlID0gc2NyaW1TbGlkZXIs' >> "$TMPB64"
    printf '%s' 'CiAgICAgICAgICAgICAgICAgICAgICAgICAgICBvblZhbHVlQ2hhbmdlID0geyBzY3JpbVNsaWRlciA9IGl0IH0sCiAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICBvblZhbHVlQ2hhbmdlRmluaXNoZWQgPSB7IFdhbGxwYXBlck1hbmFnZXIuc2V0U2NyaW0oY29u' >> "$TMPB64"
    printf '%s' 'dGV4dCwgc2NyaW1TbGlkZXIudG9JbnQoKSkgfSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlUmFuZ2UgPSAwZi4u' >> "$TMPB64"
    printf '%s' 'OTBmLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgc3RlcHMgPSA4LAogICAgICAgICAgICAgICAgICAgICAgICApCiAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgIFRleHQoCiAgICAgICAgICAgICAgICAgICAgICAgICAgICB0ZXh0ID0gIuWjgee6uOS5i+S4iuea' >> "$TMPB64"
    printf '%s' 'hOS4gOWxgum7keiJsumBrue9qe+8mui2iumrmOWjgee6uOi2iuaal+OAgeaWh+Wtl+i2iua4heOAgum7mOiupCAwIOS4jemBruaM' >> "$TMPB64"
    printf '%s' 'oeOAgiIsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICBzdHlsZSA9IE1hdGVyaWFsVGhlbWUudHlwb2dyYXBoeS5ib2R5U21h' >> "$TMPB64"
    printf '%s' 'bGwsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICBjb2xvciA9IG11c2ljQ29sb3JzKCkudGV4dFNlY29uZGFyeSwKICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgKQogICAgICAgICAgICAgICAgICAgICAgICBTcGFjZXIobW9kaWZpZXIgPSBNb2RpZmllci5oZWln' >> "$TMPB64"
    printf '%s' 'aHQoMTIuZHApKQogICAgICAgICAgICAgICAgICAgICAgICBSb3coCiAgICAgICAgICAgICAgICAgICAgICAgICAgICBtb2RpZmll' >> "$TMPB64"
    printf '%s' 'ciA9IE1vZGlmaWVyLmZpbGxNYXhXaWR0aCgpLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgdmVydGljYWxBbGlnbm1lbnQg' >> "$TMPB64"
    printf '%s' 'PSBBbGlnbm1lbnQuQ2VudGVyVmVydGljYWxseSwKICAgICAgICAgICAgICAgICAgICAgICAgKSB7CiAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICBUZXh0KCLlo4HnurjkuI3pgI/mmI7luqYiLCBzdHlsZSA9IE1hdGVyaWFsVGhlbWUudHlwb2dyYXBoeS5ib2R5' >> "$TMPB64"
    printf '%s' 'U21hbGwsIGNvbG9yID0gbXVzaWNDb2xvcnMoKS50ZXh0U2Vjb25kYXJ5KQogICAgICAgICAgICAgICAgICAgICAgICAgICAgU3Bh' >> "$TMPB64"
    printf '%s' 'Y2VyKG1vZGlmaWVyID0gTW9kaWZpZXIud2VpZ2h0KDFmKSkKICAgICAgICAgICAgICAgICAgICAgICAgICAgIFRleHQoCiAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgdGV4dCA9ICIke29wYWNpdHlTbGlkZXIudG9JbnQoKX0lIiwKICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICBzdHlsZSA9IE1hdGVyaWFsVGhlbWUudHlwb2dyYXBoeS5ib2R5U21hbGwsCiAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgY29sb3IgPSBtdXNpY0NvbG9ycygpLnRleHRQcmltYXJ5LAogICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgKQogICAgICAgICAgICAgICAgICAgICAgICB9CiAgICAgICAgICAgICAgICAgICAgICAgIENvbXBhY3RTbGlkZXIo' >> "$TMPB64"
    printf '%s' 'CiAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZSA9IG9wYWNpdHlTbGlkZXIsCiAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICBvblZhbHVlQ2hhbmdlID0geyBvcGFjaXR5U2xpZGVyID0gaXQgfSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9u' >> "$TMPB64"
    printf '%s' 'VmFsdWVDaGFuZ2VGaW5pc2hlZCA9IHsgV2FsbHBhcGVyTWFuYWdlci5zZXRPcGFjaXR5KGNvbnRleHQsIG9wYWNpdHlTbGlkZXIu' >> "$TMPB64"
    printf '%s' 'dG9JbnQoKSkgfSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlUmFuZ2UgPSAwZi4uMTAwZiwKICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgIHN0ZXBzID0gOSwKICAgICAgICAgICAgICAgICAgICAgICAgKQogICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICBSb3coCiAgICAgICAgICAgICAgICAgICAgICAgICAgICBtb2RpZmllciA9IE1vZGlmaWVyLmZpbGxNYXhXaWR0aCgpLAogICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgdmVydGljYWxBbGlnbm1lbnQgPSBBbGlnbm1lbnQuQ2VudGVyVmVydGljYWxseSwKICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgKSB7CiAgICAgICAgICAgICAgICAgICAgICAgICAgICBUZXh0KCLmqKHns4rnqIvluqYiLCBz' >> "$TMPB64"
    printf '%s' 'dHlsZSA9IE1hdGVyaWFsVGhlbWUudHlwb2dyYXBoeS5ib2R5U21hbGwsIGNvbG9yID0gbXVzaWNDb2xvcnMoKS50ZXh0U2Vjb25k' >> "$TMPB64"
    printf '%s' 'YXJ5KQogICAgICAgICAgICAgICAgICAgICAgICAgICAgU3BhY2VyKG1vZGlmaWVyID0gTW9kaWZpZXIud2VpZ2h0KDFmKSkKICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgIFRleHQoCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgdGV4dCA9ICIke2Js' >> "$TMPB64"
    printf '%s' 'dXJTbGlkZXIudG9JbnQoKX0iLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHN0eWxlID0gTWF0ZXJpYWxUaGVtZS50' >> "$TMPB64"
    printf '%s' 'eXBvZ3JhcGh5LmJvZHlTbWFsbCwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBjb2xvciA9IG11c2ljQ29sb3JzKCku' >> "$TMPB64"
    printf '%s' 'dGV4dFByaW1hcnksCiAgICAgICAgICAgICAgICAgICAgICAgICAgICApCiAgICAgICAgICAgICAgICAgICAgICAgIH0KICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgQ29tcGFjdFNsaWRlcigKICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlID0gYmx1clNs' >> "$TMPB64"
    printf '%s' 'aWRlciwKICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uVmFsdWVDaGFuZ2UgPSB7IGJsdXJTbGlkZXIgPSBpdCB9LAogICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgb25WYWx1ZUNoYW5nZUZpbmlzaGVkID0geyBXYWxscGFwZXJNYW5hZ2VyLnNldEJsdXIo' >> "$TMPB64"
    printf '%s' 'Y29udGV4dCwgYmx1clNsaWRlci50b0ludCgpKSB9LAogICAgICAgICAgICAgICAgICAgICAgICAgICAgdmFsdWVSYW5nZSA9IDBm' >> "$TMPB64"
    printf '%s' 'Li4yMGYsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICBzdGVwcyA9IDE5LAogICAgICAgICAgICAgICAgICAgICAgICApCiAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgIFRleHQoCiAgICAgICAgICAgICAgICAgICAgICAgICAgICB0ZXh0ID0gIuS4jemAj+aYjuW6' >> "$TMPB64"
    printf '%s' 'puiwg+S9ju+8jOWjgee6uOS8muiejei/m+mhtemdouW6leiJsu+8m+aooeeziuiuqeeFp+eJh+mAgOaIkOawm+WbtOW6le+8jOaW' >> "$TMPB64"
    printf '%s' 'h+Wtl+abtOeqgeWHuu+8iOWPqueziuWjgee6uO+8jOS4jeeziueVjOmdou+8ieOAgiIsCiAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICBzdHlsZSA9IE1hdGVyaWFsVGhlbWUudHlwb2dyYXBoeS5ib2R5U21hbGwsCiAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICBjb2xvciA9IG11c2ljQ29sb3JzKCkudGV4dFNlY29uZGFyeSwKICAgICAgICAgICAgICAgICAgICAgICAgKQogICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgIH0KICAgICAgICAgICAgICAgIH0KICAgICAgICAgICAgfQogICAgICAgICAgICBpZiAod3BTdGF0ZS5oaXN0b3J5' >> "$TMPB64"
    printf '%s' 'LmlzTm90RW1wdHkoKSkgewogICAgICAgICAgICAgICAgaXRlbSB7CiAgICAgICAgICAgICAgICAgICAgVGV4dCgKICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgdGV4dCA9ICLljoblj7Llo4HnurgiLAogICAgICAgICAgICAgICAgICAgICAgICBzdHlsZSA9IE1hdGVy' >> "$TMPB64"
    printf '%s' 'aWFsVGhlbWUudHlwb2dyYXBoeS50aXRsZU1lZGl1bS5jb3B5KGZvbnRXZWlnaHQgPSBGb250V2VpZ2h0LkJvbGQpLAogICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICBjb2xvciA9IG11c2ljQ29sb3JzKCkudGV4dFByaW1hcnksCiAgICAgICAgICAgICAgICAgICAgKQog' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgfQogICAgICAgICAgICAgICAgaXRlbSB7CiAgICAgICAgICAgICAgICAgICAgTGF6eVJvdyhob3Jpem9u' >> "$TMPB64"
    printf '%s' 'dGFsQXJyYW5nZW1lbnQgPSBBcnJhbmdlbWVudC5zcGFjZWRCeSgxMC5kcCkpIHsKICAgICAgICAgICAgICAgICAgICAgICAgaXRl' >> "$TMPB64"
    printf '%s' 'bXMod3BTdGF0ZS5oaXN0b3J5LCBrZXkgPSB7IGl0IH0pIHsgdSAtPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgdmFsIGlz' >> "$TMPB64"
    printf '%s' 'Q3VycmVudCA9IHUgPT0gd3BTdGF0ZS51cmwKICAgICAgICAgICAgICAgICAgICAgICAgICAgIEJveCgKICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICBtb2RpZmllciA9IE1vZGlmaWVyCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIC5z' >> "$TMPB64"
    printf '%s' 'aXplKDg0LmRwKQogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAuY2xpcChSb3VuZGVkQ29ybmVyU2hhcGUoMTIu' >> "$TMPB64"
    printf '%s' 'ZHApKQogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAuYmFja2dyb3VuZChtdXNpY0NvbG9ycygpLmNhcmRTZWNv' >> "$TMPB64"
    printf '%s' 'bmRhcnkpCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIC50aGVuKAogICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgaWYgKGlzQ3VycmVudCkgTW9kaWZpZXIuYm9yZGVyKDIuZHAsIG11c2ljQ29sb3JzKCkuYWNjZW50LCBS' >> "$TMPB64"
    printf '%s' 'b3VuZGVkQ29ybmVyU2hhcGUoMTIuZHApKQogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZWxzZSBNb2Rp' >> "$TMPB64"
    printf '%s' 'ZmllcgogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICApCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgIC5jbGlja2FibGUgewogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgV2FsbHBhcGVyTWFuYWdlci5h' >> "$TMPB64"
    printf '%s' 'cHBseShjb250ZXh0LCB1KQogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgdXJsVGV4dCA9IHUKICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgfSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICkgewogICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgIEFzeW5jSW1hZ2UoCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIG1vZGVs' >> "$TMPB64"
    printf '%s' 'ID0gSW1hZ2VSZXF1ZXN0LkJ1aWxkZXIoY29udGV4dCkuZGF0YSh1KS5zaXplKDI0MCkuYnVpbGQoKSwKICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgY29udGVudERlc2NyaXB0aW9uID0gbnVsbCwKICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgY29udGVudFNjYWxlID0gQ29udGVudFNjYWxlLkNyb3AsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgIG1vZGlmaWVyID0gTW9kaWZpZXIuZmlsbE1heFNpemUoKSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICApCiAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICB9CiAgICAgICAgICAgICAgICAgICAgICAgIH0KICAgICAgICAgICAgICAgICAgICB9' >> "$TMPB64"
    printf '%s' 'CiAgICAgICAgICAgICAgICB9CiAgICAgICAgICAgIH0KICAgICAgICAgICAgaXRlbSB7CiAgICAgICAgICAgICAgICBUZXh0KAog' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgIHRleHQgPSAi5aOB57q45L2N5LqO6Z+z5LmQ5LiT5Yy65pyA5bqV5bGC77yM5YW25LiK55uW5pyJ' >> "$TMPB64"
    printf '%s' '5Y+v6K+75oCn6YGu572p77yb6IOM5pmv5Zu+5oyJ5bGP5bmV5bC65a+45bCB6aG25Yqg6L2977yM5LiN5b2x5ZON5YiX6KGo5ruR' >> "$TMPB64"
    printf '%s' '5Yqo44CC5pys5Zyw5Zu+54mH5L2/55So57O757uf5paH5Lu26YCJ5oup5Zmo5bm255Sz6K+35oyB5LmF5o6I5p2D77yM6YeN5ZCv' >> "$TMPB64"
    printf '%s' '5LiN5aSx5pWI44CCIiwKICAgICAgICAgICAgICAgICAgICBzdHlsZSA9IE1hdGVyaWFsVGhlbWUudHlwb2dyYXBoeS5ib2R5U21h' >> "$TMPB64"
    printf '%s' 'bGwsCiAgICAgICAgICAgICAgICAgICAgY29sb3IgPSBtdXNpY0NvbG9ycygpLnRleHRTZWNvbmRhcnksCiAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICApCiAgICAgICAgICAgIH0KICAgICAgICB9CiAgICB9Cn0K' >> "$TMPB64"
base64 -d "$TMPB64" > avbox/app/src/main/java/com/github/avbox/osc/ui/LxWallpaperSettingsActivity.kt
rm -f "$TMPB64"
grep -q 'class LxWallpaperSettingsActivity' avbox/app/src/main/java/com/github/avbox/osc/ui/LxWallpaperSettingsActivity.kt || { echo "X 39 class LxWallpaperSettingsActivity 写入失败"; exit 1; }
TMPB64=$(mktemp)
    printf '%s' 'cGFja2FnZSBjb20uZ2l0aHViLmF2Ym94Lm9zYy51aQoKaW1wb3J0IGFuZHJvaWQuY29udGVudC5Db250ZXh0CmltcG9ydCBhbmRy' >> "$TMPB64"
    printf '%s' 'b2lkLm9zLkJ1bmRsZQppbXBvcnQgYW5kcm9pZC53aWRnZXQuVG9hc3QKaW1wb3J0IGFuZHJvaWR4LmFjdGl2aXR5LkNvbXBvbmVu' >> "$TMPB64"
    printf '%s' 'dEFjdGl2aXR5CmltcG9ydCBhbmRyb2lkeC5hY3Rpdml0eS5jb21wb3NlLnNldENvbnRlbnQKaW1wb3J0IGFuZHJvaWR4LmNvbXBv' >> "$TMPB64"
    printf '%s' 'c2UuZm91bmRhdGlvbi5iYWNrZ3JvdW5kCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLmZvdW5kYXRpb24uY2xpY2thYmxlCmltcG9y' >> "$TMPB64"
    printf '%s' 'dCBhbmRyb2lkeC5jb21wb3NlLmZvdW5kYXRpb24ubGF5b3V0LkFycmFuZ2VtZW50CmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLmZv' >> "$TMPB64"
    printf '%s' 'dW5kYXRpb24ubGF5b3V0LkJveAppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5mb3VuZGF0aW9uLmxheW91dC5Db2x1bW4KaW1wb3J0' >> "$TMPB64"
    printf '%s' 'IGFuZHJvaWR4LmNvbXBvc2UuZm91bmRhdGlvbi5sYXlvdXQuUGFkZGluZ1ZhbHVlcwppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5m' >> "$TMPB64"
    printf '%s' 'b3VuZGF0aW9uLmxheW91dC5Sb3cKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UuZm91bmRhdGlvbi5sYXlvdXQuYXNwZWN0UmF0aW8K' >> "$TMPB64"
    printf '%s' 'aW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UuZm91bmRhdGlvbi5sYXlvdXQuZmlsbE1heFNpemUKaW1wb3J0IGFuZHJvaWR4LmNvbXBv' >> "$TMPB64"
    printf '%s' 'c2UuZm91bmRhdGlvbi5sYXlvdXQuZmlsbE1heFdpZHRoCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLmZvdW5kYXRpb24ubGF5b3V0' >> "$TMPB64"
    printf '%s' 'LnBhZGRpbmcKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UuZm91bmRhdGlvbi5sYXp5LkxhenlSb3cKaW1wb3J0IGFuZHJvaWR4LmNv' >> "$TMPB64"
    printf '%s' 'bXBvc2UuZm91bmRhdGlvbi5sYXp5LmdyaWQuR3JpZENlbGxzCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLmZvdW5kYXRpb24ubGF6' >> "$TMPB64"
    printf '%s' 'eS5ncmlkLkdyaWRJdGVtU3BhbgppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5mb3VuZGF0aW9uLmxhenkuZ3JpZC5MYXp5VmVydGlj' >> "$TMPB64"
    printf '%s' 'YWxHcmlkCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLmZvdW5kYXRpb24ubGF6eS5ncmlkLml0ZW1zCmltcG9ydCBhbmRyb2lkeC5j' >> "$TMPB64"
    printf '%s' 'b21wb3NlLmZvdW5kYXRpb24ubGF6eS5pdGVtcwppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5mb3VuZGF0aW9uLnNoYXBlLlJvdW5k' >> "$TMPB64"
    printf '%s' 'ZWRDb3JuZXJTaGFwZQppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5tYXRlcmlhbDMuQnV0dG9uCmltcG9ydCBhbmRyb2lkeC5jb21w' >> "$TMPB64"
    printf '%s' 'b3NlLm1hdGVyaWFsMy5CdXR0b25EZWZhdWx0cwppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5tYXRlcmlhbDMuQ2FyZAppbXBvcnQg' >> "$TMPB64"
    printf '%s' 'YW5kcm9pZHguY29tcG9zZS5tYXRlcmlhbDMuQ2lyY3VsYXJQcm9ncmVzc0luZGljYXRvcgppbXBvcnQgYW5kcm9pZHguY29tcG9z' >> "$TMPB64"
    printf '%s' 'ZS5tYXRlcmlhbDMuTWF0ZXJpYWxUaGVtZQppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5tYXRlcmlhbDMuVGV4dAppbXBvcnQgYW5k' >> "$TMPB64"
    printf '%s' 'cm9pZHguY29tcG9zZS5ydW50aW1lLkNvbXBvc2FibGUKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UucnVudGltZS5MYXVuY2hlZEVm' >> "$TMPB64"
    printf '%s' 'ZmVjdAppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5ydW50aW1lLlNpZGVFZmZlY3QKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UucnVu' >> "$TMPB64"
    printf '%s' 'dGltZS5nZXRWYWx1ZQppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5ydW50aW1lLm11dGFibGVTdGF0ZU9mCmltcG9ydCBhbmRyb2lk' >> "$TMPB64"
    printf '%s' 'eC5jb21wb3NlLnJ1bnRpbWUucmVtZW1iZXIKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UucnVudGltZS5yZW1lbWJlckNvcm91dGlu' >> "$TMPB64"
    printf '%s' 'ZVNjb3BlCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLnJ1bnRpbWUuc2V0VmFsdWUKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UudWku' >> "$TMPB64"
    printf '%s' 'QWxpZ25tZW50CmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLnVpLk1vZGlmaWVyCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLnVpLmRy' >> "$TMPB64"
    printf '%s' 'YXcuY2xpcAppbXBvcnQgYW5kcm9pZHguY29tcG9zZS51aS5ncmFwaGljcy5Db2xvcgppbXBvcnQgYW5kcm9pZHguY29tcG9zZS51' >> "$TMPB64"
    printf '%s' 'aS5sYXlvdXQuQ29udGVudFNjYWxlCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLnVpLnBsYXRmb3JtLkxvY2FsQ29udGV4dAppbXBv' >> "$TMPB64"
    printf '%s' 'cnQgYW5kcm9pZHguY29tcG9zZS51aS50ZXh0LmZvbnQuRm9udFdlaWdodAppbXBvcnQgYW5kcm9pZHguY29tcG9zZS51aS50ZXh0' >> "$TMPB64"
    printf '%s' 'LnN0eWxlLlRleHRPdmVyZmxvdwppbXBvcnQgYW5kcm9pZHguY29tcG9zZS51aS51bml0LmRwCmltcG9ydCBhbmRyb2lkeC5jb3Jl' >> "$TMPB64"
    printf '%s' 'LnZpZXcuV2luZG93Q29tcGF0CmltcG9ydCBjb2lsLmNvbXBvc2UuQXN5bmNJbWFnZQppbXBvcnQgamF2YS5uZXQuSHR0cFVSTENv' >> "$TMPB64"
    printf '%s' 'bm5lY3Rpb24KaW1wb3J0IGphdmEubmV0LlVSTAppbXBvcnQgamF2YS5uZXQuVVJMRW5jb2RlcgppbXBvcnQgamF2YS5zZWN1cml0' >> "$TMPB64"
    printf '%s' 'eS5NZXNzYWdlRGlnZXN0CmltcG9ydCBqYXZhLnNlY3VyaXR5LlNlY3VyZVJhbmRvbQppbXBvcnQga290bGlueC5jb3JvdXRpbmVz' >> "$TMPB64"
    printf '%s' 'LkRpc3BhdGNoZXJzCmltcG9ydCBrb3RsaW54LmNvcm91dGluZXMubGF1bmNoCmltcG9ydCBrb3RsaW54LmNvcm91dGluZXMud2l0' >> "$TMPB64"
    printf '%s' 'aENvbnRleHQKaW1wb3J0IG9yZy5qc29uLkpTT05PYmplY3QKCi8vIFszOXdwM10g5Zyo57q/5aOB57q45bqT77yI55yf5a6e5rqQ' >> "$TMPB64"
    printf '%s' '77ya5pCc5Zu+56We5Zmo6IGa5ZCI5Zu+5rGg77yM562+5ZCN5Y2P6K6u5bey6YCG5ZCR6aqM6K+BIGNvZGU9MjAw77yJ44CCCmRh' >> "$TMPB64"
    printf '%s' 'dGEgY2xhc3MgV3BJdGVtKAogICAgdmFsIGlkOiBMb25nLAogICAgdmFsIHRpdGxlOiBTdHJpbmcsCiAgICB2YWwgdGh1bWI6IFN0' >> "$TMPB64"
    printf '%s' 'cmluZywKICAgIHZhbCBsYXJnZTogU3RyaW5nLAogICAgdmFsIHdpZHRoOiBJbnQsCiAgICB2YWwgaGVpZ2h0OiBJbnQsCikKCmRh' >> "$TMPB64"
    printf '%s' 'dGEgY2xhc3MgV3BDYXQoCiAgICB2YWwgbmFtZTogU3RyaW5nLAogICAgdmFsIHBhdGg6IFN0cmluZywKICAgIHZhbCBiYXNlUGFy' >> "$TMPB64"
    printf '%s' 'YW1zOiBNYXA8U3RyaW5nLCBTdHJpbmc+LAogICAgdmFsIHBhZ2VTaXplOiBJbnQsCikKCnByaXZhdGUgZnVuIGZlZWRDYXQobmFt' >> "$TMPB64"
    printf '%s' 'ZTogU3RyaW5nLCBzaXplVHlwZTogU3RyaW5nKSA9IFdwQ2F0KAogICAgbmFtZSwgIi92Mi9ob21lL2ZlZWQiLAogICAgbWFwT2Yo' >> "$TMPB64"
    printf '%s' 'CiAgICAgICAgInNpemVfdHlwZSIgdG8gc2l6ZVR5cGUsICJzb3J0X3R5cGUiIHRvICI0IiwKICAgICAgICAibGFyZ2VTY2FsZSIg' >> "$TMPB64"
    printf '%s' 'dG8gImZhbHNlIiwgImlzX2xhcmdlX3NjYWxlIiB0byAiMCIsCiAgICApLAogICAgNjAsCikKCi8vIFszOXdwY2F0c10g5qiq5bGP' >> "$TMPB64"
    printf '%s' 'L+eUteiEkeWjgee6uOi1sOWPpuS4gOadoemTviAvdjEvc2VhcmNoL3BjU2NyZWVu77yIUGVla1BpbGkg5ZCM5rqQ5pWw5o2u77yJ' >> "$TMPB64"
    printf '%s' 'CnByaXZhdGUgZnVuIHBjQ2F0KG5hbWU6IFN0cmluZywgc2l6ZVR5cGU6IFN0cmluZykgPSBXcENhdCgKICAgIG5hbWUsICIvdjEv' >> "$TMPB64"
    printf '%s' 'c2VhcmNoL3BjU2NyZWVuIiwKICAgIG1hcE9mKAogICAgICAgICJzaXplX3R5cGUiIHRvIHNpemVUeXBlLCAic29ydF90eXBlIiB0' >> "$TMPB64"
    printf '%s' 'byAiNCIsCiAgICAgICAgImxhcmdlU2NhbGUiIHRvICJ0cnVlIiwgImlzX2xhcmdlX3NjYWxlIiB0byAiLTEiLAogICAgKSwKICAg' >> "$TMPB64"
    printf '%s' 'IDMwLAopCgpwcml2YXRlIHZhbCBXUF9DQVRTOiBMaXN0PFdwQ2F0PiA9IGxpc3RPZigKICAgIGZlZWRDYXQoIueyvumAiSIsICIw' >> "$TMPB64"
    printf '%s' 'IiksCiAgICBmZWVkQ2F0KCLpq5jmuIUiLCAiMjEiKSwKICAgIGZlZWRDYXQoIuWFqOmdouWxjyIsICIxIiksCiAgICBmZWVkQ2F0' >> "$TMPB64"
    printf '%s' 'KCIySyIsICIyIiksCiAgICBmZWVkQ2F0KCI0SyIsICI1IiksCiAgICBmZWVkQ2F0KCI1SyIsICI2IiksIC8vIFszOXdwY2F0c10K' >> "$TMPB64"
    printf '%s' 'ICAgIGZlZWRDYXQoIjhLIiwgIjciKSwgLy8gWzM5d3BjYXRzXQogICAgZmVlZENhdCgiMUvmqKrlsY8iLCAiMyIpLCAvLyBbMzl3' >> "$TMPB64"
    printf '%s' 'cGNhdHNdCiAgICBwY0NhdCgi55S16ISR5aOB57q4IiwgIjAiKSwgLy8gWzM5d3BjYXRzXQogICAgcGNDYXQoIjJL5qiq5bGPIiwg' >> "$TMPB64"
    printf '%s' 'IjIyIiksIC8vIFszOXdwY2F0c10KICAgIHBjQ2F0KCI0S+aoquWxjyIsICIyNiIpLCAvLyBbMzl3cGNhdHNdCiAgICBwY0NhdCgi' >> "$TMPB64"
    printf '%s' 'NUvmqKrlsY8iLCAiMjkiKSwgLy8gWzM5d3BjYXRzXQogICAgcGNDYXQoIjhL5qiq5bGPIiwgIjMxIiksIC8vIFszOXdwY2F0c10K' >> "$TMPB64"
    printf '%s' 'ICAgIFdwQ2F0KAogICAgICAgICJBSee7mOeUuyIsICIvYXBpL3dhbGxwYXBlci9jbGllbnQvYnlUYWciLAogICAgICAgIG1hcE9m' >> "$TMPB64"
    printf '%s' 'KAogICAgICAgICAgICAidGFnIiB0byAiQUnnu5jnlLsiLCAic29ydF90eXBlIiB0byAiNCIsCiAgICAgICAgICAgICJpc19sYXJn' >> "$TMPB64"
    printf '%s' 'ZV9zY2FsZSIgdG8gIi0xIiwgImxhcmdlU2NhbGUiIHRvICJ0cnVlIiwKICAgICAgICAgICAgInNpemVfdHlwZV9saXN0IiB0byAi' >> "$TMPB64"
    printf '%s' 'WzIxLDIzLDI0LDI3LDMwLDMyXSIsICJzY2VuZV90eXBlX2xpc3QiIHRvICJbMF0iLAogICAgICAgICksCiAgICAgICAgMzAsCiAg' >> "$TMPB64"
    printf '%s' 'ICApLAogICAgV3BDYXQoCiAgICAgICAgIuW5s+advyIsICIvdjIvc2VhcmNoL2NvbW1vbkxpc3QiLAogICAgICAgIG1hcE9mKAog' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAidGFibGVfdHlwZSIgdG8gIjgiLCAic29ydF90eXBlIiB0byAiNCIsCiAgICAgICAgICAgICJsYXJnZVNjYWxl' >> "$TMPB64"
    printf '%s' 'IiB0byAidHJ1ZSIsICJpc19sYXJnZV9zY2FsZSIgdG8gIi0xIiwgInNlYXJjaF93b3JkIiB0byAiIiwKICAgICAgICApLAogICAg' >> "$TMPB64"
    printf '%s' 'ICAgIDMwLAogICAgKSwKICAgIFdwQ2F0KAogICAgICAgICLogYrlpKnog4zmma8iLCAiL3YyL3NlYXJjaC9jb21tb25MaXN0IiwK' >> "$TMPB64"
    printf '%s' 'ICAgICAgICBtYXBPZigKICAgICAgICAgICAgInRhYmxlX3R5cGUiIHRvICI0IiwgInNvcnRfdHlwZSIgdG8gIjQiLAogICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAibGFyZ2VTY2FsZSIgdG8gInRydWUiLCAiaXNfbGFyZ2Vfc2NhbGUiIHRvICItMSIsICJzZWFyY2hfd29yZCIgdG8gIiIs' >> "$TMPB64"
    printf '%s' 'CiAgICAgICAgKSwKICAgICAgICAzMCwKICAgICksCikKCm9iamVjdCBXcEFwaSB7CiAgICBwcml2YXRlIGNvbnN0IHZhbCBIT1NU' >> "$TMPB64"
    printf '%s' 'ID0gImh0dHBzOi8vd2FsbHBhcGVyLnNvdXR1c2hlbnFpLmNvbSIKICAgIHByaXZhdGUgY29uc3QgdmFsIFNJR05fS0VZID0gImQ5' >> "$TMPB64"
    printf '%s' 'ZmQzZWMzOTQiCgogICAgcHJpdmF0ZSBmdW4gZGV2aWNlSWQoY29udGV4dDogQ29udGV4dCk6IFN0cmluZyB7CiAgICAgICAgdmFs' >> "$TMPB64"
    printf '%s' 'IHNwID0gY29udGV4dC5nZXRTaGFyZWRQcmVmZXJlbmNlcygid2FsbHBhcGVyX3ByZWZzIiwgQ29udGV4dC5NT0RFX1BSSVZBVEUp' >> "$TMPB64"
    printf '%s' 'CiAgICAgICAgdmFsIHNhdmVkID0gc3AuZ2V0U3RyaW5nKCJ3cF9kZXZpY2VfaWQiLCBudWxsKQogICAgICAgIGlmICghc2F2ZWQu' >> "$TMPB64"
    printf '%s' 'aXNOdWxsT3JCbGFuaygpKSByZXR1cm4gc2F2ZWQKICAgICAgICB2YWwgYnl0ZXMgPSBCeXRlQXJyYXkoMTYpCiAgICAgICAgU2Vj' >> "$TMPB64"
    printf '%s' 'dXJlUmFuZG9tKCkubmV4dEJ5dGVzKGJ5dGVzKQogICAgICAgIHZhbCBpZCA9IGJ5dGVzLmpvaW5Ub1N0cmluZygiIikgeyAiJTAy' >> "$TMPB64"
    printf '%s' 'eCIuZm9ybWF0KGl0KSB9CiAgICAgICAgc3AuZWRpdCgpLnB1dFN0cmluZygid3BfZGV2aWNlX2lkIiwgaWQpLmFwcGx5KCkKICAg' >> "$TMPB64"
    printf '%s' 'ICAgICByZXR1cm4gaWQKICAgIH0KCiAgICBwcml2YXRlIGZ1biBzY3JhbWJsZWRUaW1lKCk6IFN0cmluZyB7CiAgICAgICAgdmFs' >> "$TMPB64"
    printf '%s' 'IHMgPSBTeXN0ZW0uY3VycmVudFRpbWVNaWxsaXMoKSAvIDEwMDAKICAgICAgICByZXR1cm4gKHMgKiAxMDAwICsgKChzIHhvciAz' >> "$TMPB64"
    printf '%s' 'MzRMKSAlIDEwMDApKS50b1N0cmluZygpCiAgICB9CgogICAgcHJpdmF0ZSBmdW4gbWQ1KHRleHQ6IFN0cmluZyk6IFN0cmluZyB7' >> "$TMPB64"
    printf '%s' 'CiAgICAgICAgdmFsIGRpZ2VzdCA9IE1lc3NhZ2VEaWdlc3QuZ2V0SW5zdGFuY2UoIk1ENSIpLmRpZ2VzdCh0ZXh0LnRvQnl0ZUFy' >> "$TMPB64"
    printf '%s' 'cmF5KENoYXJzZXRzLlVURl84KSkKICAgICAgICByZXR1cm4gZGlnZXN0LmpvaW5Ub1N0cmluZygiIikgeyAiJTAyeCIuZm9ybWF0' >> "$TMPB64"
    printf '%s' 'KGl0KSB9CiAgICB9CgogICAgc3VzcGVuZCBmdW4gZmV0Y2goY29udGV4dDogQ29udGV4dCwgY2F0OiBXcENhdCwgcGFnZTogSW50' >> "$TMPB64"
    printf '%s' 'KTogUmVzdWx0PExpc3Q8V3BJdGVtPj4gPQogICAgICAgIHdpdGhDb250ZXh0KERpc3BhdGNoZXJzLklPKSB7CiAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'IHRyeSB7CiAgICAgICAgICAgICAgICB2YWwgdGltZSA9IHNjcmFtYmxlZFRpbWUoKQogICAgICAgICAgICAgICAgdmFsIHBhcmFt' >> "$TMPB64"
    printf '%s' 'cyA9IHNvcnRlZE1hcE9mPFN0cmluZywgU3RyaW5nPigpCiAgICAgICAgICAgICAgICBwYXJhbXNbInBsYXRmb3JtIl0gPSAiMCIK' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgIHBhcmFtc1sidmVyc2lvbl9jb2RlIl0gPSAiMTkzIgogICAgICAgICAgICAgICAgcGFyYW1zWyJwcm9k' >> "$TMPB64"
    printf '%s' 'dWN0X2lkIl0gPSAiMjAzIgogICAgICAgICAgICAgICAgcGFyYW1zWyJkZXZpY2VfaWQiXSA9IGRldmljZUlkKGNvbnRleHQpCiAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICBwYXJhbXNbImlzX2VuY3J5cHQiXSA9ICJmYWxzZSIKICAgICAgICAgICAgICAgIHBhcmFtc1sidGltZSJd' >> "$TMPB64"
    printf '%s' 'ID0gdGltZQogICAgICAgICAgICAgICAgcGFyYW1zLnB1dEFsbChjYXQuYmFzZVBhcmFtcykKICAgICAgICAgICAgICAgIHBhcmFt' >> "$TMPB64"
    printf '%s' 'c1sicGFnZSJdID0gcGFnZS50b1N0cmluZygpCiAgICAgICAgICAgICAgICBwYXJhbXNbInBhZ2Vfc2l6ZSJdID0gY2F0LnBhZ2VT' >> "$TMPB64"
    printf '%s' 'aXplLnRvU3RyaW5nKCkKICAgICAgICAgICAgICAgIHZhbCBzaWduU3JjID0gcGFyYW1zLmVudHJpZXMuam9pblRvU3RyaW5nKCIm' >> "$TMPB64"
    printf '%s' 'IikgeyAiJHtpdC5rZXl9PSR7aXQudmFsdWV9IiB9ICsKICAgICAgICAgICAgICAgICAgICAiJmtleT0iICsgU0lHTl9LRVkKICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgIHBhcmFtc1sic2lnbiJdID0gbWQ1KHNpZ25TcmMpCiAgICAgICAgICAgICAgICB2YWwgYm9keSA9IHBhcmFt' >> "$TMPB64"
    printf '%s' 'cy5lbnRyaWVzLmpvaW5Ub1N0cmluZygiJiIpIHsKICAgICAgICAgICAgICAgICAgICAiJHtpdC5rZXl9PSR7VVJMRW5jb2Rlci5l' >> "$TMPB64"
    printf '%s' 'bmNvZGUoaXQudmFsdWUsICJVVEYtOCIpfSIKICAgICAgICAgICAgICAgIH0KICAgICAgICAgICAgICAgIHZhbCBjb25uID0gVVJM' >> "$TMPB64"
    printf '%s' 'KEhPU1QgKyBjYXQucGF0aCkub3BlbkNvbm5lY3Rpb24oKSBhcyBIdHRwVVJMQ29ubmVjdGlvbgogICAgICAgICAgICAgICAgY29u' >> "$TMPB64"
    printf '%s' 'bi5yZXF1ZXN0TWV0aG9kID0gIlBPU1QiCiAgICAgICAgICAgICAgICBjb25uLmNvbm5lY3RUaW1lb3V0ID0gMTAwMDAKICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgIGNvbm4ucmVhZFRpbWVvdXQgPSAyNTAwMAogICAgICAgICAgICAgICAgY29ubi5kb091dHB1dCA9IHRydWUKICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgIGNvbm4uc2V0UmVxdWVzdFByb3BlcnR5KCJVc2VyLUFnZW50IiwgIm9raHR0cC8zLjEyLjYiKQogICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgY29ubi5zZXRSZXF1ZXN0UHJvcGVydHkoIkNvbnRlbnQtVHlwZSIsICJhcHBsaWNhdGlvbi94LXd3dy1mb3JtLXVy' >> "$TMPB64"
    printf '%s' 'bGVuY29kZWQiKQogICAgICAgICAgICAgICAgY29ubi5zZXRSZXF1ZXN0UHJvcGVydHkoInRpbWVzdGFtcCIsIHRpbWUpCiAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICBjb25uLm91dHB1dFN0cmVhbS51c2UgeyBpdC53cml0ZShib2R5LnRvQnl0ZUFycmF5KENoYXJzZXRzLlVURl84' >> "$TMPB64"
    printf '%s' 'KSkgfQogICAgICAgICAgICAgICAgdmFsIHRleHQgPSBjb25uLmlucHV0U3RyZWFtLmJ1ZmZlcmVkUmVhZGVyKCkucmVhZFRleHQo' >> "$TMPB64"
    printf '%s' 'KQogICAgICAgICAgICAgICAgdmFsIGpzb24gPSBKU09OT2JqZWN0KHRleHQpCiAgICAgICAgICAgICAgICBpZiAoanNvbi5vcHRJ' >> "$TMPB64"
    printf '%s' 'bnQoImNvZGUiKSAhPSAyMDApIHsKICAgICAgICAgICAgICAgICAgICByZXR1cm5Ad2l0aENvbnRleHQgUmVzdWx0LmZhaWx1cmUo' >> "$TMPB64"
    printf '%s' 'RXhjZXB0aW9uKGpzb24ub3B0U3RyaW5nKCJlcnJvcl9tc2ciLCAi5o6l5Y+j6ZSZ6K+vIikpKQogICAgICAgICAgICAgICAgfQog' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgdmFsIGFyciA9IGpzb24ub3B0SlNPTkFycmF5KCJkYXRhIikKICAgICAgICAgICAgICAgICAgICA/OiBy' >> "$TMPB64"
    printf '%s' 'ZXR1cm5Ad2l0aENvbnRleHQgUmVzdWx0LnN1Y2Nlc3MoZW1wdHlMaXN0KCkpCiAgICAgICAgICAgICAgICB2YWwgb3V0ID0gQXJy' >> "$TMPB64"
    printf '%s' 'YXlMaXN0PFdwSXRlbT4oKQogICAgICAgICAgICAgICAgZm9yIChpIGluIDAgdW50aWwgYXJyLmxlbmd0aCgpKSB7CiAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgdmFsIG8gPSBhcnIub3B0SlNPTk9iamVjdChpKSA/OiBjb250aW51ZQogICAgICAgICAgICAgICAgICAgIHZh' >> "$TMPB64"
    printf '%s' 'bCBsYXJnZSA9IG8ub3B0U3RyaW5nKCJsYXJnZVVybCIpCiAgICAgICAgICAgICAgICAgICAgdmFsIHRodW1iID0gby5vcHRTdHJp' >> "$TMPB64"
    printf '%s' 'bmcoInRodW1iVXJsIikKICAgICAgICAgICAgICAgICAgICBpZiAobGFyZ2UuaXNCbGFuaygpICYmIHRodW1iLmlzQmxhbmsoKSkg' >> "$TMPB64"
    printf '%s' 'Y29udGludWUKICAgICAgICAgICAgICAgICAgICAvLyBbMzl3cG51bGxdIOWQjuerr+aXoOagh+mimOaXtui/lOWbnuWtl+espuS4' >> "$TMPB64"
    printf '%s' 'siAibnVsbCLvvIzkuZ/lvZPnqbrlpITnkIYKICAgICAgICAgICAgICAgICAgICB2YWwgdGl0bGUgPSBvLm9wdFN0cmluZygidGl0' >> "$TMPB64"
    printf '%s' 'bGUiKS50YWtlVW5sZXNzIHsgaXQuaXNCbGFuaygpIHx8IGl0ID09ICJudWxsIiB9CiAgICAgICAgICAgICAgICAgICAgICAgID86' >> "$TMPB64"
    printf '%s' 'IG8ub3B0U3RyaW5nKCJkZXRhaWxJbmZvIikudGFrZVVubGVzcyB7IGl0LmlzQmxhbmsoKSB8fCBpdCA9PSAibnVsbCIgfQogICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICA/OiAi5aOB57q4ICMke28ub3B0TG9uZygiaWQiKX0iCiAgICAgICAgICAgICAgICAgICAgb3V0' >> "$TMPB64"
    printf '%s' 'LmFkZCgKICAgICAgICAgICAgICAgICAgICAgICAgV3BJdGVtKAogICAgICAgICAgICAgICAgICAgICAgICAgICAgaWQgPSBvLm9w' >> "$TMPB64"
    printf '%s' 'dExvbmcoImlkIiksCiAgICAgICAgICAgICAgICAgICAgICAgICAgICB0aXRsZSA9IHRpdGxlLAogICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgdGh1bWIgPSB0aHVtYi5pZkJsYW5rIHsgbGFyZ2UgfSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgIGxhcmdl' >> "$TMPB64"
    printf '%s' 'ID0gbGFyZ2UuaWZCbGFuayB7IHRodW1iIH0sCiAgICAgICAgICAgICAgICAgICAgICAgICAgICB3aWR0aCA9IG8ub3B0SW50KCJ3' >> "$TMPB64"
    printf '%s' 'aWR0aCIpLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgaGVpZ2h0ID0gby5vcHRJbnQoImhlaWdodCIpLAogICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICApCiAgICAgICAgICAgICAgICAgICAgKQogICAgICAgICAgICAgICAgfQogICAgICAgICAgICAgICAgUmVz' >> "$TMPB64"
    printf '%s' 'dWx0LnN1Y2Nlc3Mob3V0KQogICAgICAgICAgICB9IGNhdGNoIChlOiBFeGNlcHRpb24pIHsKICAgICAgICAgICAgICAgIFJlc3Vs' >> "$TMPB64"
    printf '%s' 'dC5mYWlsdXJlKGUpCiAgICAgICAgICAgIH0KICAgICAgICB9Cn0KCmNsYXNzIFdhbGxwYXBlckxpYnJhcnlBY3Rpdml0eSA6IENv' >> "$TMPB64"
    printf '%s' 'bXBvbmVudEFjdGl2aXR5KCkgewogICAgb3ZlcnJpZGUgZnVuIG9uQ3JlYXRlKHNhdmVkSW5zdGFuY2VTdGF0ZTogQnVuZGxlPykg' >> "$TMPB64"
    printf '%s' 'ewogICAgICAgIHN1cGVyLm9uQ3JlYXRlKHNhdmVkSW5zdGFuY2VTdGF0ZSkKICAgICAgICB2YWwgYXBwQ3R4ID0gYXBwbGljYXRp' >> "$TMPB64"
    printf '%s' 'b25Db250ZXh0CiAgICAgICAgTXVzaWNUaGVtZU1hbmFnZXIuaW5pdChhcHBDdHgpCiAgICAgICAgV2FsbHBhcGVyTWFuYWdlci5p' >> "$TMPB64"
    printf '%s' 'bml0KGFwcEN0eCkKICAgICAgICBzZXRDb250ZW50IHsKICAgICAgICAgICAgdmFsIGlzRGFyayBieSBNdXNpY1RoZW1lTWFuYWdl' >> "$TMPB64"
    printf '%s' 'ci5pc0RhcmtUaGVtZQogICAgICAgICAgICB2YWwgd2luZG93ID0gdGhpc0BXYWxscGFwZXJMaWJyYXJ5QWN0aXZpdHkud2luZG93' >> "$TMPB64"
    printf '%s' 'CiAgICAgICAgICAgIFNpZGVFZmZlY3QgewogICAgICAgICAgICAgICAgV2luZG93Q29tcGF0LmdldEluc2V0c0NvbnRyb2xsZXIo' >> "$TMPB64"
    printf '%s' 'd2luZG93LCB3aW5kb3cuZGVjb3JWaWV3KQogICAgICAgICAgICAgICAgICAgIC5pc0FwcGVhcmFuY2VMaWdodFN0YXR1c0JhcnMg' >> "$TMPB64"
    printf '%s' 'PSAhaXNEYXJrCiAgICAgICAgICAgIH0KICAgICAgICAgICAgTHhNdXNpY1RoZW1lKGlzRGFya1RoZW1lID0gaXNEYXJrKSB7CiAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICBXYWxscGFwZXJMaWJyYXJ5U2NyZWVuKG9uQmFjayA9IHsgZmluaXNoKCkgfSkKICAgICAgICAgICAgfQog' >> "$TMPB64"
    printf '%s' 'ICAgICAgIH0KICAgIH0KfQoKQENvbXBvc2FibGUKZnVuIFdhbGxwYXBlckxpYnJhcnlTY3JlZW4ob25CYWNrOiAoKSAtPiBVbml0' >> "$TMPB64"
    printf '%s' 'KSB7CiAgICB2YWwgY29udGV4dCA9IExvY2FsQ29udGV4dC5jdXJyZW50CiAgICB2YWwgc2NvcGUgPSByZW1lbWJlckNvcm91dGlu' >> "$TMPB64"
    printf '%s' 'ZVNjb3BlKCkKICAgIHZhciBjYXQgYnkgcmVtZW1iZXIgeyBtdXRhYmxlU3RhdGVPZihXUF9DQVRTWzBdKSB9CiAgICB2YXIgaXRl' >> "$TMPB64"
    printf '%s' 'bXMgYnkgcmVtZW1iZXIgeyBtdXRhYmxlU3RhdGVPZjxMaXN0PFdwSXRlbT4+KGVtcHR5TGlzdCgpKSB9CiAgICB2YXIgbG9hZGlu' >> "$TMPB64"
    printf '%s' 'ZyBieSByZW1lbWJlciB7IG11dGFibGVTdGF0ZU9mKGZhbHNlKSB9CiAgICB2YXIgZXJyb3IgYnkgcmVtZW1iZXIgeyBtdXRhYmxl' >> "$TMPB64"
    printf '%s' 'U3RhdGVPZjxTdHJpbmc/PihudWxsKSB9CiAgICB2YXIgcGFnZSBieSByZW1lbWJlciB7IG11dGFibGVTdGF0ZU9mKDEpIH0KICAg' >> "$TMPB64"
    printf '%s' 'IHZhciBlbmRSZWFjaGVkIGJ5IHJlbWVtYmVyIHsgbXV0YWJsZVN0YXRlT2YoZmFsc2UpIH0KCiAgICBmdW4gbG9hZCh0YXJnZXQ6' >> "$TMPB64"
    printf '%s' 'IFdwQ2F0LCB0YXJnZXRQYWdlOiBJbnQsIGFwcGVuZDogQm9vbGVhbikgewogICAgICAgIGxvYWRpbmcgPSB0cnVlCiAgICAgICAg' >> "$TMPB64"
    printf '%s' 'aWYgKCFhcHBlbmQpIGVycm9yID0gbnVsbAogICAgICAgIHNjb3BlLmxhdW5jaCB7CiAgICAgICAgICAgIHZhbCByZXN1bHQgPSBX' >> "$TMPB64"
    printf '%s' 'cEFwaS5mZXRjaChjb250ZXh0LCB0YXJnZXQsIHRhcmdldFBhZ2UpCiAgICAgICAgICAgIGxvYWRpbmcgPSBmYWxzZQogICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICByZXN1bHQub25TdWNjZXNzIHsgbGlzdCAtPgogICAgICAgICAgICAgICAgaXRlbXMgPSBpZiAoYXBwZW5kKSB7CiAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgdmFsIGtub3duID0gaXRlbXMubWFwIHsgaXQuaWQgfS50b0hhc2hTZXQoKQogICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgIGl0ZW1zICsgbGlzdC5maWx0ZXIgeyBpdC5pZCAhaW4ga25vd24gfQogICAgICAgICAgICAgICAgfSBlbHNlIHsKICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICBsaXN0CiAgICAgICAgICAgICAgICB9CiAgICAgICAgICAgICAgICBwYWdlID0gdGFyZ2V0UGFnZQogICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgZW5kUmVhY2hlZCA9IGxpc3Quc2l6ZSA8IHRhcmdldC5wYWdlU2l6ZQogICAgICAgICAgICB9Lm9uRmFpbHVy' >> "$TMPB64"
    printf '%s' 'ZSB7CiAgICAgICAgICAgICAgICBpZiAoIWFwcGVuZCkgZXJyb3IgPSAi5Yqg6L295aSx6LSl77yM6K+35qOA5p+l572R57uc5ZCO' >> "$TMPB64"
    printf '%s' '6YeN6K+VIgogICAgICAgICAgICB9CiAgICAgICAgfQogICAgfQoKICAgIExhdW5jaGVkRWZmZWN0KGNhdCkgewogICAgICAgIGl0' >> "$TMPB64"
    printf '%s' 'ZW1zID0gZW1wdHlMaXN0KCkKICAgICAgICBwYWdlID0gMQogICAgICAgIGVuZFJlYWNoZWQgPSBmYWxzZQogICAgICAgIGxvYWQo' >> "$TMPB64"
    printf '%s' 'Y2F0LCAxLCBmYWxzZSkKICAgIH0KCiAgICBDb2x1bW4oCiAgICAgICAgbW9kaWZpZXIgPSBNb2RpZmllcgogICAgICAgICAgICAu' >> "$TMPB64"
    printf '%s' 'ZmlsbE1heFNpemUoKQogICAgICAgICAgICAuYmFja2dyb3VuZChtdXNpY0NvbG9ycygpLmJhY2tncm91bmQpCiAgICApIHsKICAg' >> "$TMPB64"
    printf '%s' 'ICAgICBSb3coCiAgICAgICAgICAgIG1vZGlmaWVyID0gTW9kaWZpZXIKICAgICAgICAgICAgICAgIC5maWxsTWF4V2lkdGgoKQog' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgLnBhZGRpbmcoc3RhcnQgPSA4LmRwLCBlbmQgPSAxNi5kcCwgdG9wID0gNDguZHAsIGJvdHRvbSA9IDgu' >> "$TMPB64"
    printf '%s' 'ZHApLAogICAgICAgICAgICB2ZXJ0aWNhbEFsaWdubWVudCA9IEFsaWdubWVudC5DZW50ZXJWZXJ0aWNhbGx5LAogICAgICAgICkg' >> "$TMPB64"
    printf '%s' 'ewogICAgICAgICAgICBUZXh0KAogICAgICAgICAgICAgICAgdGV4dCA9ICLigLkiLAogICAgICAgICAgICAgICAgc3R5bGUgPSBN' >> "$TMPB64"
    printf '%s' 'YXRlcmlhbFRoZW1lLnR5cG9ncmFwaHkuaGVhZGxpbmVNZWRpdW0sCiAgICAgICAgICAgICAgICBjb2xvciA9IG11c2ljQ29sb3Jz' >> "$TMPB64"
    printf '%s' 'KCkudGV4dFByaW1hcnksCiAgICAgICAgICAgICAgICBtb2RpZmllciA9IE1vZGlmaWVyCiAgICAgICAgICAgICAgICAgICAgLmNs' >> "$TMPB64"
    printf '%s' 'aWNrYWJsZSB7IG9uQmFjaygpIH0KICAgICAgICAgICAgICAgICAgICAucGFkZGluZyhob3Jpem9udGFsID0gMTIuZHAsIHZlcnRp' >> "$TMPB64"
    printf '%s' 'Y2FsID0gNC5kcCksCiAgICAgICAgICAgICkKICAgICAgICAgICAgVGV4dCgKICAgICAgICAgICAgICAgIHRleHQgPSAi5Zyo57q/' >> "$TMPB64"
    printf '%s' '5aOB57q45bqTIiwKICAgICAgICAgICAgICAgIHN0eWxlID0gTWF0ZXJpYWxUaGVtZS50eXBvZ3JhcGh5LnRpdGxlTGFyZ2UuY29w' >> "$TMPB64"
    printf '%s' 'eShmb250V2VpZ2h0ID0gRm9udFdlaWdodC5Cb2xkKSwKICAgICAgICAgICAgICAgIGNvbG9yID0gbXVzaWNDb2xvcnMoKS50ZXh0' >> "$TMPB64"
    printf '%s' 'UHJpbWFyeSwKICAgICAgICAgICAgKQogICAgICAgIH0KICAgICAgICBMYXp5Um93KAogICAgICAgICAgICBjb250ZW50UGFkZGlu' >> "$TMPB64"
    printf '%s' 'ZyA9IFBhZGRpbmdWYWx1ZXMoaG9yaXpvbnRhbCA9IDE2LmRwKSwKICAgICAgICAgICAgaG9yaXpvbnRhbEFycmFuZ2VtZW50ID0g' >> "$TMPB64"
    printf '%s' 'QXJyYW5nZW1lbnQuc3BhY2VkQnkoMTAuZHApLAogICAgICAgICkgewogICAgICAgICAgICBpdGVtcyhXUF9DQVRTLCBrZXkgPSB7' >> "$TMPB64"
    printf '%s' 'IGl0Lm5hbWUgfSkgeyBjIC0+CiAgICAgICAgICAgICAgICB2YWwgc2VsZWN0ZWQgPSBjLm5hbWUgPT0gY2F0Lm5hbWUKICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgIEJveCgKICAgICAgICAgICAgICAgICAgICBtb2RpZmllciA9IE1vZGlmaWVyCiAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgIC5jbGlwKFJvdW5kZWRDb3JuZXJTaGFwZSg1MCkpCiAgICAgICAgICAgICAgICAgICAgICAgIC5iYWNrZ3JvdW5kKGlmIChz' >> "$TMPB64"
    printf '%s' 'ZWxlY3RlZCkgbXVzaWNDb2xvcnMoKS5hY2NlbnQgZWxzZSBtdXNpY0NvbG9ycygpLmNhcmRTZWNvbmRhcnkpCiAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgIC5jbGlja2FibGUgeyBjYXQgPSBjIH0KICAgICAgICAgICAgICAgICAgICAgICAgLnBhZGRpbmcoaG9yaXpv' >> "$TMPB64"
    printf '%s' 'bnRhbCA9IDE4LmRwLCB2ZXJ0aWNhbCA9IDguZHApLAogICAgICAgICAgICAgICAgKSB7CiAgICAgICAgICAgICAgICAgICAgVGV4' >> "$TMPB64"
    printf '%s' 'dCgKICAgICAgICAgICAgICAgICAgICAgICAgdGV4dCA9IGMubmFtZSwKICAgICAgICAgICAgICAgICAgICAgICAgc3R5bGUgPSBN' >> "$TMPB64"
    printf '%s' 'YXRlcmlhbFRoZW1lLnR5cG9ncmFwaHkuYm9keU1lZGl1bSwKICAgICAgICAgICAgICAgICAgICAgICAgY29sb3IgPSBpZiAoc2Vs' >> "$TMPB64"
    printf '%s' 'ZWN0ZWQpIG11c2ljQ29sb3JzKCkuYWNjZW50VGV4dCBlbHNlIG11c2ljQ29sb3JzKCkudGV4dFNlY29uZGFyeSwKICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICApCiAgICAgICAgICAgICAgICB9CiAgICAgICAgICAgIH0KICAgICAgICB9CiAgICAgICAgQm94KG1vZGlmaWVy' >> "$TMPB64"
    printf '%s' 'ID0gTW9kaWZpZXIuZmlsbE1heFNpemUoKSkgewogICAgICAgICAgICB3aGVuIHsKICAgICAgICAgICAgICAgIGxvYWRpbmcgJiYg' >> "$TMPB64"
    printf '%s' 'aXRlbXMuaXNFbXB0eSgpIC0+IHsKICAgICAgICAgICAgICAgICAgICBDaXJjdWxhclByb2dyZXNzSW5kaWNhdG9yKAogICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICBjb2xvciA9IG11c2ljQ29sb3JzKCkuYWNjZW50LAogICAgICAgICAgICAgICAgICAgICAgICBtb2Rp' >> "$TMPB64"
    printf '%s' 'ZmllciA9IE1vZGlmaWVyLmFsaWduKEFsaWdubWVudC5DZW50ZXIpLAogICAgICAgICAgICAgICAgICAgICkKICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgIH0KICAgICAgICAgICAgICAgIGVycm9yICE9IG51bGwgJiYgaXRlbXMuaXNFbXB0eSgpIC0+IHsKICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICBDb2x1bW4oCiAgICAgICAgICAgICAgICAgICAgICAgIG1vZGlmaWVyID0gTW9kaWZpZXIuYWxpZ24oQWxpZ25tZW50LkNl' >> "$TMPB64"
    printf '%s' 'bnRlciksCiAgICAgICAgICAgICAgICAgICAgICAgIGhvcml6b250YWxBbGlnbm1lbnQgPSBBbGlnbm1lbnQuQ2VudGVySG9yaXpv' >> "$TMPB64"
    printf '%s' 'bnRhbGx5LAogICAgICAgICAgICAgICAgICAgICkgewogICAgICAgICAgICAgICAgICAgICAgICBUZXh0KAogICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgdGV4dCA9IGVycm9yID86ICIiLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgc3R5bGUgPSBNYXRl' >> "$TMPB64"
    printf '%s' 'cmlhbFRoZW1lLnR5cG9ncmFwaHkuYm9keU1lZGl1bSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNvbG9yID0gbXVzaWND' >> "$TMPB64"
    printf '%s' 'b2xvcnMoKS50ZXh0U2Vjb25kYXJ5LAogICAgICAgICAgICAgICAgICAgICAgICApCiAgICAgICAgICAgICAgICAgICAgICAgIEJ1' >> "$TMPB64"
    printf '%s' 'dHRvbigKICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2xpY2sgPSB7IGxvYWQoY2F0LCAxLCBmYWxzZSkgfSwKICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgIGNvbG9ycyA9IEJ1dHRvbkRlZmF1bHRzLmJ1dHRvbkNvbG9ycygKICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICBjb250YWluZXJDb2xvciA9IG11c2ljQ29sb3JzKCkuYWNjZW50LAogICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgIGNvbnRlbnRDb2xvciA9IG11c2ljQ29sb3JzKCkuYWNjZW50VGV4dCwKICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICksCiAgICAgICAgICAgICAgICAgICAgICAgICAgICBtb2RpZmllciA9IE1vZGlmaWVyLnBhZGRpbmcodG9wID0gMTIu' >> "$TMPB64"
    printf '%s' 'ZHApLAogICAgICAgICAgICAgICAgICAgICAgICApIHsKICAgICAgICAgICAgICAgICAgICAgICAgICAgIFRleHQodGV4dCA9ICLp' >> "$TMPB64"
    printf '%s' 'h43or5UiKQogICAgICAgICAgICAgICAgICAgICAgICB9CiAgICAgICAgICAgICAgICAgICAgfQogICAgICAgICAgICAgICAgfQog' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgZWxzZSAtPiB7CiAgICAgICAgICAgICAgICAgICAgTGF6eVZlcnRpY2FsR3JpZCgKICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgY29sdW1ucyA9IEdyaWRDZWxscy5GaXhlZCgyKSwKICAgICAgICAgICAgICAgICAgICAgICAgY29udGVudFBh' >> "$TMPB64"
    printf '%s' 'ZGRpbmcgPSBQYWRkaW5nVmFsdWVzKDEyLmRwKSwKICAgICAgICAgICAgICAgICAgICAgICAgaG9yaXpvbnRhbEFycmFuZ2VtZW50' >> "$TMPB64"
    printf '%s' 'ID0gQXJyYW5nZW1lbnQuc3BhY2VkQnkoMTAuZHApLAogICAgICAgICAgICAgICAgICAgICAgICB2ZXJ0aWNhbEFycmFuZ2VtZW50' >> "$TMPB64"
    printf '%s' 'ID0gQXJyYW5nZW1lbnQuc3BhY2VkQnkoMTAuZHApLAogICAgICAgICAgICAgICAgICAgICkgewogICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICBpdGVtcyhpdGVtcywga2V5ID0geyBpdC5pZCB9KSB7IGl0ZW0gLT4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIENh' >> "$TMPB64"
    printf '%s' 'cmQoc2hhcGUgPSBSb3VuZGVkQ29ybmVyU2hhcGUoMTQuZHApKSB7CiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgQm94' >> "$TMPB64"
    printf '%s' 'IHsKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgQXN5bmNJbWFnZSgKICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgIG1vZGVsID0gaXRlbS50aHVtYiwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'IGNvbnRlbnREZXNjcmlwdGlvbiA9IG51bGwsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBjb250ZW50' >> "$TMPB64"
    printf '%s' 'U2NhbGUgPSBDb250ZW50U2NhbGUuQ3JvcCwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIG1vZGlmaWVy' >> "$TMPB64"
    printf '%s' 'ID0gTW9kaWZpZXIKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAuZmlsbE1heFdpZHRoKCkKICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAuYXNwZWN0UmF0aW8oMC41NmYpCiAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgLmNsaWNrYWJsZSB7CiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgIFdhbGxwYXBlck1hbmFnZXIuYXBwbHkoY29udGV4dCwgaXRlbS5sYXJnZSkKICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgVG9hc3QubWFrZVRleHQoY29udGV4dCwgIuWjgee6uOW3suW6lOeUqCIs' >> "$TMPB64"
    printf '%s' 'IFRvYXN0LkxFTkdUSF9TSE9SVCkuc2hvdygpCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'IG9uQmFjaygpCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgfSwKICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgKQogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBDb2x1bW4oCiAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICBtb2RpZmllciA9IE1vZGlmaWVyCiAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgLmFsaWduKEFsaWdubWVudC5Cb3R0b21TdGFydCkKICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAuZmlsbE1heFdpZHRoKCkKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAuYmFja2dyb3VuZChDb2xvci5CbGFjay5jb3B5KGFscGhhID0gMC42NWYpKQogICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgIC5wYWRkaW5nKGhvcml6b250YWwgPSA4LmRwLCB2ZXJ0aWNhbCA9IDUuZHApLAogICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICApIHsKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIFRleHQoCiAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgdGV4dCA9IGl0ZW0udGl0bGUsCiAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgc3R5bGUgPSBNYXRlcmlhbFRoZW1lLnR5cG9ncmFwaHkubGFiZWxNZWRpdW0s' >> "$TMPB64"
    printf '%s' 'CiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgY29sb3IgPSBDb2xvci5XaGl0ZSwKICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBtYXhMaW5lcyA9IDEsCiAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgb3ZlcmZsb3cgPSBUZXh0T3ZlcmZsb3cuRWxsaXBzaXMsCiAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICApCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBpZiAoaXRlbS53aWR0aCA+' >> "$TMPB64"
    printf '%s' 'IDAgJiYgaXRlbS5oZWlnaHQgPiAwKSB7CiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgVGV4dCgK' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgdGV4dCA9ICIke2l0ZW0ud2lkdGh9w5cke2l0' >> "$TMPB64"
    printf '%s' 'ZW0uaGVpZ2h0fSIsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHN0eWxlID0gTWF0ZXJp' >> "$TMPB64"
    printf '%s' 'YWxUaGVtZS50eXBvZ3JhcGh5LmxhYmVsU21hbGwsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgIGNvbG9yID0gQ29sb3IuV2hpdGUsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgKQogICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgfQogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB9' >> "$TMPB64"
    printf '%s' 'CiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgfQogICAgICAgICAgICAgICAgICAgICAgICAgICAgfQogICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICB9CiAgICAgICAgICAgICAgICAgICAgICAgIGlmICghZW5kUmVhY2hlZCkgewogICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgaXRlbShzcGFuID0geyBHcmlkSXRlbVNwYW4obWF4TGluZVNwYW4pIH0pIHsKICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICBCdXR0b24oCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2xpY2sgPSB7IGlmICgh' >> "$TMPB64"
    printf '%s' 'bG9hZGluZykgbG9hZChjYXQsIHBhZ2UgKyAxLCB0cnVlKSB9LAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBl' >> "$TMPB64"
    printf '%s' 'bmFibGVkID0gIWxvYWRpbmcsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNvbG9ycyA9IEJ1dHRvbkRlZmF1' >> "$TMPB64"
    printf '%s' 'bHRzLmJ1dHRvbkNvbG9ycygKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNvbnRhaW5lckNvbG9yID0g' >> "$TMPB64"
    printf '%s' 'bXVzaWNDb2xvcnMoKS5jYXJkU2Vjb25kYXJ5LAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgY29udGVu' >> "$TMPB64"
    printf '%s' 'dENvbG9yID0gbXVzaWNDb2xvcnMoKS50ZXh0UHJpbWFyeSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgKSwK' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgbW9kaWZpZXIgPSBNb2RpZmllcgogICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgLmZpbGxNYXhXaWR0aCgpCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAucGFkZGluZyh2ZXJ0aWNhbCA9IDQuZHApLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICkgewogICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICBUZXh0KHRleHQgPSBpZiAobG9hZGluZykgIuWKoOi9veS4rS4uLiIgZWxzZSAi5Yqg' >> "$TMPB64"
    printf '%s' '6L295pu05aSaIikKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB9CiAgICAgICAgICAgICAgICAgICAgICAgICAgICB9' >> "$TMPB64"
    printf '%s' 'CiAgICAgICAgICAgICAgICAgICAgICAgIH0KICAgICAgICAgICAgICAgICAgICB9CiAgICAgICAgICAgICAgICB9CiAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgIH0KICAgICAgICB9CiAgICB9Cn0K' >> "$TMPB64"
base64 -d "$TMPB64" > avbox/app/src/main/java/com/github/avbox/osc/ui/WallpaperLibraryActivity.kt
rm -f "$TMPB64"
grep -q 'class WallpaperLibraryActivity' avbox/app/src/main/java/com/github/avbox/osc/ui/WallpaperLibraryActivity.kt || { echo "X 39 class WallpaperLibraryActivity 写入失败"; exit 1; }
echo "[39] MusicHome 外壳接壁纸层 + 六页根背景透出 + 设置入口"
python3 << 'PYEOF39'
import io, sys, os
while not os.path.exists('avbox/app/src/main/AndroidManifest.xml') and os.getcwd() != '/':
    os.chdir('..')

BASE = 'avbox/app/src/main/java/com/github/avbox/osc/'
FQ_COLOR = 'androidx.compose.ui.graphics.Color.Transparent'
WP_CHECK = 'com.github.avbox.osc.ui.WallpaperManager.isActive()'

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

# ============ 0) manifest 注册壁纸页 + 壁纸库页 ============
MP = 'avbox/app/src/main/AndroidManifest.xml'
m = load(MP)
for act_name in ['.ui.LxWallpaperSettingsActivity', '.ui.WallpaperLibraryActivity']:
    if act_name not in m:
        assert '</application>' in m, '❌ [39] manifest 无 </application>'
        m = m.replace('</application>', '        <activity android:name="' + act_name + '" android:exported="false" />\n    </application>', 1)
        print('OK manifest 注册', act_name)
    else:
        print('SKIP manifest 已注册', act_name)
save(MP, m)
m_chk = load(MP)
assert 'LxWallpaperSettingsActivity' in m_chk and 'WallpaperLibraryActivity' in m_chk, '❌ [39] manifest 双注册校验失败'
print('OK manifest 双注册校验通过')

# ============ 1) MusicHomeActivity ============
MH = BASE + 'ui/MusicHomeActivity.kt'
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
             '        }\n'
             '        androidx.compose.runtime.CompositionLocalProvider(LocalMusicColors provides wpColors) { // [39wp5] 文字/卡片色覆盖(仅 MH 子树)\n')
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
    h = h[:end + 1] + '\n        } // [39wp5] Provider 结束\n    } // [39wp1] 壁纸底层 Box 结束' + h[end + 1:]
    print('OK MH 壁纸层整框包裹完成')
    # 设置入口: 播放历史之前插入(沿用该行缩进)
    lines = h.split('\n')
    idx = [k for k, ln in enumerate(lines) if 'SettingItem("播放历史", "最近播放的歌曲")' in ln]
    assert len(idx) == 1, '❌ [39] MH-entry 锚点数量异常: %d' % len(idx)
    k = idx[0]
    ind = lines[k][:len(lines[k]) - len(lines[k].lstrip())]
    block = [
        ind + 'SettingItem("壁纸设置", "自定义背景图") { // [39wp1]',
        ind + '    context.startActivity(android.content.Intent(context, com.github.avbox.osc.ui.LxWallpaperSettingsActivity::class.java))',
        ind + '},',
    ]
    lines[k:k] = block
    h = '\n'.join(lines)
    save(MH, h)
    print('OK MusicHomeActivity 壁纸接线完成')
else:
    print('SKIP MusicHomeActivity 已有 [39wp1]')

# ============ 1b) MusicHomeActivity [39wp2]: 渐变分支 ============
h = load(MH)
if '[39wp2]' not in h:
    h = rep(h,
        '    val wpActive = wpState.enabled && wpState.url.isNotBlank() // [39wp1]',
        '    val wpActive = wpState.enabled && (wpState.url.isNotBlank() || wpState.mode == "gradient") // [39wp2]',
        'MH2-active')
    h = rep(h,
        '        if (wpActive && wpReq != null) {\n'
        '            coil.compose.AsyncImage(model = wpReq, contentDescription = null, contentScale = androidx.compose.ui.layout.ContentScale.Crop, modifier = Modifier.fillMaxSize())\n'
        '            Box(modifier = Modifier.fillMaxSize().background(if (wpDark) Color.Black.copy(alpha = 0.6f) else Color.White.copy(alpha = 0.7f)))\n'
        '        }',
        '        if (wpActive) { // [39wp2] 渐变/图片二选一 + 遮罩\n'
        '            if (wpState.mode == "gradient") {\n'
        '                val wpCols = wpState.gradient.split(",").mapNotNull { hex -> try { Color(android.graphics.Color.parseColor(hex.trim())) } catch (e: Exception) { null } }\n'
        '                if (wpCols.size >= 2) Box(modifier = Modifier.fillMaxSize().background(androidx.compose.ui.graphics.Brush.linearGradient(wpCols)))\n'
        '            } else if (wpReq != null) {\n'
        '                coil.compose.AsyncImage(model = wpReq, contentDescription = null, contentScale = androidx.compose.ui.layout.ContentScale.Crop, modifier = Modifier.fillMaxSize())\n'
        '            }\n'
        '            Box(modifier = Modifier.fillMaxSize().background(if (wpDark) Color.Black.copy(alpha = 0.6f) else Color.White.copy(alpha = 0.7f)))\n'
        '        }',
        'MH2-layer')
    save(MH, h)
    print('OK MH [39wp2] 渐变分支完成')
else:
    print('SKIP MH 已有 [39wp2]')

# ============ 1c) MusicHomeActivity [39wp5]: 文字模式(Local 覆盖) + Peek 三件(纱色/不透明度/模糊) ============
h = load(MH)
if 'wpBaseBg' not in h:
    # (a) 变量: 纱色/浓度 + 文字色源 + MH 子树颜色覆盖(方案 B: 文字四件 + 卡片两面)
    h = rep(h,
        '    val wpDark by MusicThemeManager.isDarkTheme // [39wp1]\n',
        '    val wpDark by MusicThemeManager.isDarkTheme // [39wp1]\n'
        '    val wpScrimDark = when (wpState.textMode) { "light" -> true; "dark" -> false; else -> wpDark } // [39wp5] 纱色跟文字模式\n'
        '    val wpScrimA = if (wpState.scrim >= 0) wpState.scrim / 100f else if (wpScrimDark) 0.6f else 0.7f // [39wp5] 遮罩浓度(滑杆/自动)\n'
        '    val wpTextSrc = when (wpState.textMode) { "light" -> DarkMusicColors; "dark" -> LightMusicColors; else -> null } // [39wp5]\n'
        '    val wpColors = if (wpActive && wpTextSrc != null) musicColors().copy(textPrimary = wpTextSrc.textPrimary, textSecondary = wpTextSrc.textSecondary, textHint = wpTextSrc.textHint, iconTint = wpTextSrc.iconTint) else musicColors() // [39wp5] 文字模式仅对应文字四件, 卡片跟主题\n',
        'MH5-vars')
    # (b) 背景请求: 模糊变换 + 缓存键带半径 + remember 键带 blur
    h = rep(h,
        '    val wpReq = remember(wpState.url) { // [39wp1] 背景请求: 尺寸上限+稳定缓存键\n',
        '    val wpReq = remember(wpState.url, wpState.blur) { // [39wp5] 背景请求: 尺寸上限+稳定缓存键(带模糊)\n',
        'MH5-reqkey')
    h = rep(h,
        'coil.request.ImageRequest.Builder(context).data(wpState.url).size(1080, 2400).memoryCacheKey("wp_" + wpState.url.hashCode()).build()',
        'coil.request.ImageRequest.Builder(context).data(wpState.url).size(1080, 2400).memoryCacheKey("wp_" + wpState.url.hashCode() + "_b" + wpState.blur).transformations(if (wpState.blur > 0) listOf(WpBlurTransformation(wpState.blur)) else emptyList()).build()',
        'MH5-reqblur')
    # (c) 渐变/图片不透明度 + 遮罩浓度/纱色
    h = rep(h,
        'val wpCols = wpState.gradient.split(",").mapNotNull { hex -> try { Color(android.graphics.Color.parseColor(hex.trim())) } catch (e: Exception) { null } }',
        'val wpCols = wpState.gradient.split(",").mapNotNull { hex -> try { Color(android.graphics.Color.parseColor(hex.trim())) } catch (e: Exception) { null } }.map { col -> col.copy(alpha = wpState.opacity / 100f) } // [39wp5] 渐变不透明度',
        'MH5-gradalpha')
    h = rep(h,
        'coil.compose.AsyncImage(model = wpReq, contentDescription = null, contentScale = androidx.compose.ui.layout.ContentScale.Crop, modifier = Modifier.fillMaxSize())',
        'coil.compose.AsyncImage(model = wpReq, contentDescription = null, contentScale = androidx.compose.ui.layout.ContentScale.Crop, modifier = Modifier.fillMaxSize(), alpha = wpState.opacity / 100f) // [39wp5] 图片不透明度',
        'MH5-imgalpha')
    h = rep(h,
        'Color.Black.copy(alpha = 0.6f)',
        'Color.Black.copy(alpha = wpScrimA)',
        'MH5-scrimblack')
    h = rep(h,
        'Color.White.copy(alpha = 0.7f)',
        'Color.White.copy(alpha = wpScrimA)',
        'MH5-scrimwhite')
    h = rep(h,
        'background(if (wpDark) Color.Black.copy(alpha = wpScrimA)',
        'background(if (wpScrimDark) Color.Black.copy(alpha = wpScrimA)',
        'MH5-scrimcolor')
    # (d) 不透明度合成底: 壁纸层先刷页面底色, 照片/渐变往页面底色上溶(对齐 Peek 合成语义, 非透窗口底)
    if 'wpBaseBg' not in h:
        actOld = '        if (wpActive) { // [39wp2] 渐变/图片二选一 + 遮罩\n'
        h = rep(h, actOld,
            actOld + '            Box(modifier = Modifier.fillMaxSize().background(musicColors().background)) // [39wp5] wpBaseBg 合成底=页面底色\n',
            'MH5-basebg')
    # (e) 遮罩对齐 Peek darkOverlay: 纯黑 + 默认 0 无纱(删自动 60/70 与白纱分支)
    if 'wpScrimDark' in h:
        h = rep(h,
            '    val wpScrimDark = when (wpState.textMode) { "light" -> true; "dark" -> false; else -> wpDark } // [39wp5] 纱色跟文字模式\n    val wpScrimA = if (wpState.scrim >= 0) wpState.scrim / 100f else if (wpScrimDark) 0.6f else 0.7f // [39wp5] 遮罩浓度(滑杆/自动)',
            '    val wpScrimA = wpState.scrim.coerceAtLeast(0) / 100f // [39wp5] 遮罩浓度: 纯黑遮罩, 默认 0 无纱(对齐 Peek darkOverlay 默认 0.0)',
            'MH5-scrimalign')
        h = rep(h,
            'Box(modifier = Modifier.fillMaxSize().background(if (wpScrimDark) Color.Black.copy(alpha = wpScrimA) else Color.White.copy(alpha = wpScrimA)))',
            'Box(modifier = Modifier.fillMaxSize().background(Color.Black.copy(alpha = wpScrimA)))',
            'MH5-scrimblackonly')
    save(MH, h)
    print('OK MH [39wp5] 文字模式+Peek三件完成')
else:
    print('SKIP MH 已有 [39wp5]')

# ============ 1d) LxMusicTheme [39wp5]: musicColors() 认 Local 覆盖 ============
LT = BASE + 'ui/LxMusicTheme.kt'
t = load(LT)
if '[39wp5]' not in t:
    t = rep(t,
        '    return if (MusicThemeManager.isDarkTheme.value) DarkMusicColors else LightMusicColors',
        '    // [39wp5] MH 子树经 LocalMusicColors 覆盖时用覆盖值(壁纸文字模式); 其余场景与原逻辑一致\n'
        '    val provided = LocalMusicColors.current\n'
        '    val mgr = if (MusicThemeManager.isDarkTheme.value) DarkMusicColors else LightMusicColors\n'
        '    return if (provided === DarkMusicColors || provided === LightMusicColors) mgr else provided',
        'LT5-delegate')
    save(LT, t)
    print('OK LxMusicTheme [39wp5] musicColors 委托完成')
else:
    print('SKIP LxMusicTheme 已有 [39wp5]')

# ============ 1e) SearchScreen [39wp5]: 搜索框玻璃化 ============
SS = BASE + 'ui/music/search/SearchScreen.kt'
g = load(SS)
if '[39wp5]' not in g:
    for fld in ['focusedContainerColor', 'unfocusedContainerColor', 'disabledContainerColor']:
        g = rep(g,
            '\n                ' + fld + ' = musicColors().cardSecondary,',
            '\n                ' + fld + ' = if (com.github.avbox.osc.ui.WallpaperManager.isActive()) musicColors().cardSecondary.copy(alpha = 0.55f) else musicColors().cardSecondary, // [39wp5]',
            'SS5-' + fld)
    save(SS, g)
    print('OK SearchScreen [39wp5] 搜索框玻璃化完成')
else:
    print('SKIP SearchScreen 已有 [39wp5]')

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
# ============ 3) [39haze2] 壁纸层挂 hazeSource(与胶囊同级非祖先; 根 Box 不作源: 祖先源被 Haze 节点 require 禁采, 装机闪退实证) ============
h = load(MH)
if '[39haze2]' not in h:
    if_line = '        if (wpActive) { // [39wp2] 渐变/图片二选一 + 遮罩'
    assert h.count(if_line) == 1, '❌ [39haze2] wpActive 锚点数 ' + str(h.count(if_line))
    h = h.replace(if_line, if_line + '\n            Box(modifier = Modifier.fillMaxSize().hazeSource(hazeState)) { // [39haze2] 壁纸层作 Haze 源', 1)
    scrim = '            Box(modifier = Modifier.fillMaxSize().background(Color.Black.copy(alpha = wpScrimA)))'
    assert h.count(scrim) == 1, '❌ [39haze2] scrim 锚点数 ' + str(h.count(scrim))
    h = h.replace(scrim, scrim + '\n            } // [39haze2] 壁纸源 Box 结束', 1)
    save(MH, h)
    print('OK [39haze2] 壁纸层已挂 hazeSource')
else:
    print('SKIP [39haze2] 已应用')

# ============ 4) [39glass] 毛玻璃独立设置初始化(GlassSettings 由 32 v104 创建; 与壁纸分开) ============
h = load(MH)
if '[39glass]' not in h:
    imp = 'import dev.chrisbanes.haze.hazeSource // [32v102]'
    assert h.count(imp) == 1, '❌ [39glass] import 锚点'
    h = h.replace(imp, imp + '\nimport com.github.avbox.osc.ui.music.glass.GlassSettings // [39glass]', 1)
    init_line = '    LaunchedEffect(Unit) { WallpaperManager.init(context) } // [39wp1]'
    assert h.count(init_line) == 1, '❌ [39glass] init 锚点'
    h = h.replace(init_line, '    LaunchedEffect(Unit) { WallpaperManager.init(context); GlassSettings.init(context) } // [39wp1] // [39glass] 毛玻璃独立设置初始化', 1)
    save(MH, h)
    print('OK [39glass] GlassSettings 初始化已接')
else:
    print('SKIP [39glass] 已应用')

# ============ 5) [39glass2] 壁纸层兼作抽屉采样源(抽屉 backdrop 补全: 壁纸层+列表层同源, 空区不透原图) ============
h = load(MH)
if '[39glass2]' not in h:
    old = '            Box(modifier = Modifier.fillMaxSize().hazeSource(hazeState)) { // [39haze2] 壁纸层作 Haze 源'
    assert h.count(old) == 1, '❌ [39glass2] 壁纸源锚点数 ' + str(h.count(old))
    h = h.replace(old, '            Box(modifier = Modifier.fillMaxSize().hazeSource(hazeState).hazeSource(drawerHazeState)) { // [39haze2] 壁纸层作 Haze 源 // [39glass2] 壁纸层兼作抽屉采样源(drawerHazeState 由 32 v108 在 MH 声明)', 1)
    save(MH, h)
    print('OK [39glass2] 壁纸层已兼作抽屉采样源')
else:
    print('SKIP [39glass2] 已应用')

# ============ 6) [39upbg] 自建歌单页根背景恒主题底(独立页无壁纸层, Transparent 会透浅色窗口底) ============
UP = BASE + 'ui/music/playlist/UserPlaylistScreen.kt'
u = load(UP)
if '[39upbg]' not in u:
    old = '.background(if (' + WP_CHECK + ') ' + FQ_COLOR + ' else musicColors().background)'
    assert u.count(old) == 1, '❌ [39upbg] 锚点数 ' + str(u.count(old))
    u = u.replace(old, '.background(musicColors().background) // [39upbg] 独立页无壁纸层, 壁纸开着时 Transparent 会透出浅色窗口底(#F3EDF7), 恒用主题底', 1)
    save(UP, u)
    print('OK [39upbg] 自建歌单页根背景已恒主题底')
else:
    print('SKIP [39upbg] 已应用')

# ============ 7) [39resolve] 点歌链取地址时验活：死链自动降档（Activity 属 35 基线文件，39 在 35 后补） ============
PA = BASE + 'ui/LxPlayerActivity.kt'
a = load(PA)
if '[39resolve]' not in a:
    a = rep(a, 'import com.github.avbox.osc.util.LxScriptEngine',
        'import com.github.avbox.osc.util.LxScriptEngine\nimport com.github.avbox.osc.util.LxRuntimeLog // [39resolve] 验活失败记日志', '39resolve import')
    old = '''                        onSuccess = { url ->
                            if (url.isNotBlank()) {
                                android.util.Log.i("LxPlayer", "获取 URL 成功，音质档位: $q")
                                LxPlayerManager.setLoading(false)
                                LxPlayerManager.setError(null)
                                LxPlayerManager.recordHistory(mapOf(
                                    "songId" to musicInfo["songId"].orEmpty(), "platform" to sourceId,
                                    "title" to title, "artist" to artist, "url" to url))
                                LxPlayerManager.play(url, title, artist)
                                Thread { LxPlayerManager.probeAndSetQuality(url) }.start() // [34v57] 点歌链补探针
                                LxPlayerManager.fetchCommentsAsync(sourceId, musicInfo["songId"].orEmpty(), title, artist) // [35cmt1] 评论并行拉取（只读）
                            } else {'''
    new = '''                        onSuccess = { url ->
                            if (url.isNotBlank()) {
                                android.util.Log.i("LxPlayer", "获取 URL 成功，音质档位: $q，验活中")
                                Thread { // [39resolve] 取地址时验活：死链不交给播放器，自动降档
                                    val alive = LxPlayerManager.isStreamUrlAlive(url)
                                    runOnUiThread {
                                        if (!alive) {
                                            try { LxRuntimeLog.add("地址验活失败: " + title + " / " + artist + " | 档位 " + q + " " + url.take(80)) } catch (_: Exception) { }
                                            android.util.Log.w("LxPlayer", "音质 $q 地址验活失败，降级重试")
                                            qualityIndex++
                                            tryQuality()
                                        } else if (isFinishing || isDestroyed || (title.isNotEmpty() && (LxPlayerManager.currentTitle.value != title || LxPlayerManager.currentArtist.value != artist))) {
                                            android.util.Log.w("LxPlayer", "验活期间已切歌，丢弃旧地址")
                                        } else {
                                            LxPlayerManager.setLoading(false)
                                            LxPlayerManager.setError(null)
                                            LxPlayerManager.recordHistory(mapOf(
                                                "songId" to musicInfo["songId"].orEmpty(), "platform" to sourceId,
                                                "title" to title, "artist" to artist, "url" to url))
                                            LxPlayerManager.play(url, title, artist)
                                            Thread { LxPlayerManager.probeAndSetQuality(url) }.start() // [34v57] 点歌链补探针
                                            LxPlayerManager.fetchCommentsAsync(sourceId, musicInfo["songId"].orEmpty(), title, artist) // [35cmt1] 评论并行拉取（只读）
                                        }
                                    }
                                }.start()
                            } else {'''
    a = rep(a, old, new, '39resolve 验活')
    save(PA, a)
    print('OK [39resolve] 点歌链验活已接')
else:
    print('SKIP [39resolve] 已应用')

# ============ 8) 点歌链解析前取交集（Activity 在 35 基线内，补丁放 39） ============
PA = BASE + 'ui/LxPlayerActivity.kt'
a = load(PA)
if '[39intersect]' not in a:
    a = rep(a, '        val tryOrder = LxPlayerManager.getQualityTryOrder()',
        '        val tryOrder = LxPlayerManager.getQualityTryOrderFor(sourceId) // [39intersect] 点歌链解析前取交集', '39intersect 点歌链取交集')
    save(PA, a)
    print('OK [39intersect] 点歌链取交集已接')
else:
    print('SKIP [39intersect] 已应用')

# ============ 9) 播放页三键改用 FeedbackIconButton + 切歌锁（用户 2026-10-25 确认，PlayerControls 属 35 基线故放 39） ============
PC = BASE + 'ui/PlayerControls.kt'
c = load(PC)
if '[39fb]' not in c:
    c = rep(c, '    isLoading: Boolean,\n    sleepRemaining: Long,',
        '    isLoading: Boolean,\n    isChangingTrack: Boolean, // [39fb]\n    sleepRemaining: Long,', '39fb 签名')
    c = rep(c, '''        IconButton(
            onClick = { onPrevious() },
            modifier = Modifier.size(44.dp)
        ) {
            PlayerSkipPrevIcon(tint = primaryTextColor, modifier = Modifier.size(28.dp)) // [34v45]
        }''',
        '''        FeedbackIconButton( // [39fb]
            onClick = { onPrevious() },
            enabled = !isChangingTrack,
            size = 44.dp,
        ) {
            PlayerSkipPrevIcon(tint = if (isChangingTrack) primaryTextColor.copy(alpha = 0.35f) else primaryTextColor, modifier = Modifier.size(28.dp)) // [34v45]
        }''', '39fb 上一首')
    c = rep(c, '''        Box(
            modifier = Modifier
                .size(56.dp)
                .clip(CircleShape)
                .background(musicColors().accent) // [34v12]
                .clickable { onPlayPauseClick() },
            contentAlignment = Alignment.Center
        ) {
            if (isLoading) {
                CircularProgressIndicator(color = musicColors().card, modifier = Modifier.size(22.dp), strokeWidth = 2.dp)
            } else {
                if (isPlaying) PlayerPauseIcon(tint = Color.White, modifier = Modifier.size(30.dp)) // [34v55]
                else PlayerPlayIcon(tint = Color.White, modifier = Modifier.size(30.dp)) // [34v55]
            }
        }''',
        '''        FeedbackIconButton( // [39fb]
            onClick = { onPlayPauseClick() },
            enabled = !isChangingTrack,
            size = 56.dp,
            containerColor = musicColors().accent, // [34v12]
        ) {
            if (isLoading || isChangingTrack) {
                CircularProgressIndicator(color = musicColors().card, modifier = Modifier.size(22.dp), strokeWidth = 2.dp)
            } else {
                if (isPlaying) PlayerPauseIcon(tint = Color.White, modifier = Modifier.size(30.dp)) // [34v55]
                else PlayerPlayIcon(tint = Color.White, modifier = Modifier.size(30.dp)) // [34v55]
            }
        }''', '39fb 播放暂停')
    c = rep(c, '''        IconButton(
            onClick = { onNext() },
            modifier = Modifier.size(44.dp)
        ) {
            PlayerSkipNextIcon(tint = primaryTextColor, modifier = Modifier.size(28.dp)) // [34v45]
        }''',
        '''        FeedbackIconButton( // [39fb]
            onClick = { onNext() },
            enabled = !isChangingTrack,
            size = 44.dp,
        ) {
            PlayerSkipNextIcon(tint = if (isChangingTrack) primaryTextColor.copy(alpha = 0.35f) else primaryTextColor, modifier = Modifier.size(28.dp)) // [34v45]
        }''', '39fb 下一首')
    save(PC, c)
    print('OK [39fb] 播放页反馈按钮已接')
else:
    print('SKIP [39fb] 已应用')

PA = BASE + 'ui/LxPlayerActivity.kt'
a = load(PA)
if '[39fb]' not in a:
    a = rep(a, '    val isLoading by LxPlayerManager.isLoading.collectAsState()',
        '    val isLoading by LxPlayerManager.isLoading.collectAsState()\n    val isChangingTrack by LxPlayerManager.isChangingTrack.collectAsState() // [39fb]', '39fb 状态收集')
    a = rep(a, '            PlayerControlBar(\n                isPlaying = isPlaying,\n                isLoading = isLoading,',
        '            PlayerControlBar(\n                isPlaying = isPlaying,\n                isLoading = isLoading,\n                isChangingTrack = isChangingTrack, // [39fb]', '39fb 呼叫点')
    save(PA, a)
    print('OK [39fb] 播放页锁传参已接')
else:
    print('SKIP [39fb] 已应用')

PA = BASE + 'ui/LxPlayerActivity.kt'
a = load(PA)
if '[39rescue]' not in a:
    a = rep(a, 'import kotlinx.coroutines.withContext',
        'import kotlinx.coroutines.withContext\nimport kotlinx.coroutines.runBlocking // [39rescue]', '39rescue import')
    a = rep(a, '    private fun doResolveAndPlay(songId: String, platform: String, title: String, artist: String, hash: String = "", albumAudioId: String = "") {',
        '''    // [39rescue] 跨平台搜救：单平台全档位失败后，用同名歌曲换平台再解析一次（仅一次，allowRescue=false 防死循环）
    private fun tryCrossPlatformRescue(title: String, artist: String, failedSource: String) {
        Thread {
            val results = try {
                runBlocking { LxMusicSearchApi.searchFull(title) }
            } catch (_: Exception) {
                emptyList()
            }
            val norm = { s: String -> s.filterNot { it.isWhitespace() }.lowercase() }
            val nt = norm(title)
            val na = norm(artist)
            val artistMatch = { a: String ->
                val x = norm(a)
                x.contains(na) || na.contains(x)
            }
            val refDur = results.firstOrNull { r ->
                r.platform == "wy" && norm(r.title) == nt && artistMatch(r.artist)
            }?.duration?.takeIf { it > 0 }
            val found = listOf("kg", "tx", "kw").firstNotNullOfOrNull { p ->
                if (p == failedSource) null
                else results.firstOrNull { r ->
                    r.platform == p && norm(r.title) == nt && artistMatch(r.artist) &&
                        (refDur == null || r.duration <= 0 || kotlin.math.abs(r.duration - refDur) <= 3)
                }
            }
            runOnUiThread {
                if (isFinishing || isDestroyed) return@runOnUiThread
                if (LxPlayerManager.currentTitle.value != title) return@runOnUiThread
                if (found != null) {
                    doResolveAndPlay(found.id, found.platform, title, artist, allowRescue = false)
                } else {
                    LxPlayerManager.setLoading(false)
                    LxPlayerManager.setError("获取播放地址失败（已尝试所有音质与平台）")
                }
            }
        }.start()
    }

    private fun doResolveAndPlay(songId: String, platform: String, title: String, artist: String, hash: String = "", albumAudioId: String = "", allowRescue: Boolean = true) {''', '39rescue 搜救函数+签名')
    a = rep(a, 'tryResolveWithRetry(platform, musicInfo, title, artist, retryCount = 0)',
        'tryResolveWithRetry(platform, musicInfo, title, artist, retryCount = 0, allowRescue = allowRescue) // [39rescue]', '39rescue 透传')
    a = rep(a, '''        retryCount: Int
    ) {''',
        '''        retryCount: Int,
        allowRescue: Boolean = true // [39rescue]
    ) {''', '39rescue 试解析签名')
    a = rep(a, 'tryResolveWithRetry(sourceId, musicInfo, title, artist, retryCount + 1)',
        'tryResolveWithRetry(sourceId, musicInfo, title, artist, retryCount + 1, allowRescue) // [39rescue]', '39rescue 递归透传')
    a = rep(a, '''                android.util.Log.e("LxPlayer", "所有音质档位均失败")
                runOnUiThread {
                    LxPlayerManager.setLoading(false)
                    LxPlayerManager.setError("获取播放地址失败（已尝试所有音质）")
                }
                return''',
        '''                android.util.Log.e("LxPlayer", "所有音质档位均失败")
                if (allowRescue) { // [39rescue] 跨平台搜救：搜救期间 loading 不关、报错先不发
                    tryCrossPlatformRescue(title, artist, sourceId)
                } else {
                    runOnUiThread {
                        LxPlayerManager.setLoading(false)
                        LxPlayerManager.setError("获取播放地址失败（已尝试所有音质与平台）")
                    }
                }
                return''', '39rescue 耗尽拦截')
    save(PA, a)
    print('OK [39rescue] 点歌链跨平台搜救已接')
else:
    print('SKIP [39rescue] 已应用')

# ============ 10) [39pool] 多源引擎池：引擎不再锁死单源，播歌取地址时竞速共用多条 ============
PA = BASE + 'ui/LxPlayerActivity.kt'
a = load(PA)
if '[39pool]' not in a:
    # A) 池字段：主引擎之外，每个已启用源各一个引擎实例
    a = rep(a, '''    @Volatile
    var loadedSourceId: String? = null
        private set''',
        '''    @Volatile
    var loadedSourceId: String? = null
        private set

    // [39pool] 多源引擎池：每个已启用源各一个引擎实例，播歌取地址时竞速共用，不再锁死单源
    private val poolEngines = java.util.concurrent.ConcurrentHashMap<String, LxScriptEngine>()
    private val poolLoading = java.util.concurrent.ConcurrentHashMap<String, Boolean>()
    @Volatile
    private var poolPreloadJs: String? = null
    @Volatile
    var lastGoodSourceId: String? = null
        private set
    // [39pool6] 坏源冷却：验活失败的源搁置 5 分钟，排序时沉底，好源在前（用户指“杰翔不掺裤老就不抽风”）
    private val sourceCoolDownUntil = java.util.concurrent.ConcurrentHashMap<String, Long>()
    fun markSourceCoolDown(sourceId: String, coolDownMs: Long = 300000) { // [39pool6] 默认冷却 5 分钟
        sourceCoolDownUntil[sourceId] = System.currentTimeMillis() + coolDownMs
    }
    fun isSourceCoolDown(sourceId: String): Boolean { // [39pool6] 是否在冷却期内
        val until = sourceCoolDownUntil[sourceId] ?: return false
        if (System.currentTimeMillis() >= until) {
            sourceCoolDownUntil.remove(sourceId)
            return false
        }
        return true
    }
    fun clearSourceCoolDown(sourceId: String) { // [39pool6] 源恢复时清冷却
        sourceCoolDownUntil.remove(sourceId)
    }''', '39pool 池字段')
    # B) 主源就绪后，后台懒加载其余已启用源进池（不阻塞启动与点歌）
    a = rep(a, '''                                onSuccess = {
                                    loadedSourceId = src.id
                                    isReady = true
                                    android.util.Log.i("LxEngineHolder", "引擎就绪，当前源: ${src.name}")
                                },''',
        '''                                onSuccess = {
                                    loadedSourceId = src.id
                                    isReady = true
                                    android.util.Log.i("LxEngineHolder", "引擎就绪，当前源: ${src.name}")
                                    warmUpPoolAsync(context) // [39pool] 主源就绪后，后台懒加载其余已启用源进池
                                },''', '39pool 主源就绪后预热池')
    # C) 池方法：warmUpPoolAsync + loadPoolEngineSync + resolveMusicUrlFirst，插到 get() 之前
    a = rep(a, '''    fun get(): LxScriptEngine {''',
        '''    // [39pool] 后台懒加载其余已启用源进池（不阻塞启动与点歌；逐个同步装，失败静默跳过）
    private fun warmUpPoolAsync(context: android.content.Context) {
        Thread {
            try {
                val preload = poolPreloadJs ?: try {
                    context.assets.open("lx/preload.js").bufferedReader().use { it.readText() }
                } catch (_: Exception) { "" }
                if (preload.isBlank()) return@Thread
                poolPreloadJs = preload
                val ids = try { LxSourceManager.getEnabledSources().map { it.id } } catch (_: Exception) { emptyList<String>() }
                for (id in ids) {
                    if (id == loadedSourceId) continue
                    if (poolEngines.containsKey(id)) continue
                    if (poolLoading.putIfAbsent(id, true) != null) continue
                    try {
                        if (loadPoolEngineSync(context, preload, id)) {
                            android.util.Log.i("LxEngineHolder", "池引擎就绪: $id")
                        }
                    } catch (e: Exception) {
                        android.util.Log.w("LxEngineHolder", "池引擎异常: $id ${e.message}")
                    } finally {
                        poolLoading.remove(id)
                    }
                }
            } catch (e: Exception) {
                android.util.Log.w("LxEngineHolder", "池预热异常: ${e.message}")
            }
        }.start()
    }

    // [39pool] 同步装一个池引擎（后台线程内等回调，15 秒超时；成功进池，失败销毁）
    private fun loadPoolEngineSync(context: android.content.Context, preload: String, sourceId: String): Boolean {
        val content = try { LxSourceManager.getScriptContent(sourceId) } catch (_: Exception) { null } ?: return false
        if (content.isBlank()) return false
        val eng = LxScriptEngine()
        return try {
            eng.initialize(context)
            val latch = java.util.concurrent.CountDownLatch(1)
            val ok = java.util.concurrent.atomic.AtomicBoolean(false)
            eng.loadPreloadJs(preload) { ready ->
                if (!ready) { latch.countDown(); return@loadPreloadJs }
                val info = com.github.avbox.osc.util.ScriptInfo(id = sourceId, name = "")
                eng.loadScript(sourceId, content, info) { r ->
                    ok.set(r.isSuccess)
                    latch.countDown()
                }
            }
            latch.await(15, java.util.concurrent.TimeUnit.SECONDS)
            if (ok.get()) {
                poolEngines[sourceId] = eng
                true
            } else {
                try { eng.destroy() } catch (_: Exception) {}
                false
            }
        } catch (e: Exception) {
            try { eng.destroy() } catch (_: Exception) {}
            false
        }
    }

    // [39pool] 多源竞速取地址：同时问所有已就绪的引擎（含主引擎），谁先回可用地址用谁；全部失败才报失败
    fun resolveMusicUrlFirst(
        platform: String,
        musicInfo: Map<String, Any>,
        quality: String,
        callback: (Result<String>) -> Unit
    ) {
        val targets = ArrayList<Pair<String, LxScriptEngine>>()
        val primary = engine
        if (primary != null && isReady && loadedSourceId != null) {
            targets.add(loadedSourceId!! to primary)
        }
        for ((id, eng) in poolEngines) {
            if (id == loadedSourceId) continue
            targets.add(id to eng)
        }
        lastGoodSourceId?.let { good ->
            val idx = targets.indexOfFirst { it.first == good }
            if (idx > 0) {
                val p = targets.removeAt(idx)
                targets.add(0, p)
            }
        }
        if (targets.isEmpty()) {
            callback(Result.failure(IllegalStateException("engine not ready")))
            return
        }
        val done = java.util.concurrent.atomic.AtomicBoolean(false)
        val remaining = java.util.concurrent.atomic.AtomicInteger(targets.size)
        for ((sid, eng) in targets) {
            try {
                eng.requestMusicUrl(platform, musicInfo, quality) { r ->
                    r.fold(
                        onSuccess = { url ->
                            if (url.isNotBlank()) {
                                if (done.compareAndSet(false, true)) {
                                    lastGoodSourceId = sid
                                    callback(Result.success(url))
                                }
                            } else {
                                if (remaining.decrementAndGet() == 0 && done.compareAndSet(false, true)) {
                                    callback(Result.failure(IllegalStateException("empty music url")))
                                }
                            }
                        },
                        onFailure = { e ->
                            if (remaining.decrementAndGet() == 0 && done.compareAndSet(false, true)) {
                                callback(Result.failure(e))
                            }
                        }
                    )
                }
            } catch (e: Exception) {
                if (remaining.decrementAndGet() == 0 && done.compareAndSet(false, true)) {
                    callback(Result.failure(e))
                }
            }
        }
    }

    fun get(): LxScriptEngine {''', '39pool 池方法')
    # D) 点歌链改走多源竞速：去掉单引擎变量，取地址 call 换成池竞速
    a = rep(a, '        val engine = LxEngineHolder.get()\n',
        '', '39pool 去单引擎变量')
    a = rep(a, '            engine.requestMusicUrl(sourceId, musicInfo, q) { result ->',
        '            LxEngineHolder.resolveMusicUrlFirst(sourceId, musicInfo, q) { result -> // [39pool] 多源竞速取地址', '39pool 点歌链改竞速')
    save(PA, a)
    print('OK [39pool] 多源引擎池已接')
else:
    print('SKIP [39pool] 已应用')

# ============ 11) [39pool2] 池加载触发补强：导入新源立即进池 + 已就绪也触发 + 池状态进运行日志 ============
PA = BASE + 'ui/LxPlayerActivity.kt'
a = load(PA)
if '[39pool2]' not in a:
    # 1) warmUp 已就绪时也触发池加载（否则引擎早就绪、新源永远进不了池）
    a = rep(a, '''    fun warmUp(context: android.content.Context) {
        if (isReady) {
            maybeSwitchToVerifiedSource(context)
            return
        }''',
        '''    fun warmUp(context: android.content.Context) {
        if (isReady) {
            maybeSwitchToVerifiedSource(context)
            warmUpPoolAsync(context) // [39pool2] 引擎已就绪时也触发池加载（否则新源永远进不了池）
            return
        }''', '39pool2 warmUp 已就绪也触发池')
    # 2) 新增公开方法：导入新源时立即把该源装进池（源管理页导入成功后调用）
    a = rep(a, '''    fun get(): LxScriptEngine {''',
        '''    // [39pool2] 导入新源时立即把该源装进池（由源管理页导入成功后调用，不等下次 warmUp）
    fun warmUpPoolForSource(context: android.content.Context, sourceId: String) {
        if (sourceId == loadedSourceId) return
        if (poolEngines.containsKey(sourceId)) return
        if (poolLoading.putIfAbsent(sourceId, true) != null) return
        Thread {
            try {
                val preload = poolPreloadJs ?: try {
                    context.assets.open("lx/preload.js").bufferedReader().use { it.readText() }
                } catch (_: Exception) { "" }
                if (preload.isBlank()) return@Thread
                poolPreloadJs = preload
                if (loadPoolEngineSync(context, preload, sourceId)) {
                    android.util.Log.i("LxEngineHolder", "池引擎就绪: $sourceId")
                    try { LxRuntimeLog.add("池引擎就绪: $sourceId") } catch (_: Exception) { }
                }
            } catch (e: Exception) {
                android.util.Log.w("LxEngineHolder", "池引擎异常: $sourceId ${e.message}")
                try { LxRuntimeLog.add("池引擎异常: $sourceId ${e.message}") } catch (_: Exception) { }
            } finally {
                poolLoading.remove(sourceId)
            }
        }.start()
    }

    fun get(): LxScriptEngine {''', '39pool2 导入触发方法')
    # 3) 池状态进运行日志抽屉（此前只写 logcat，用户在抽屉里看不到）
    a = rep(a, '                            android.util.Log.i("LxEngineHolder", "池引擎就绪: $id")',
        '                            android.util.Log.i("LxEngineHolder", "池引擎就绪: $id")\n                            try { LxRuntimeLog.add("池引擎就绪: $id") } catch (_: Exception) { } // [39pool2] 池状态进运行日志抽屉', '39pool2 池就绪进日志')
    a = rep(a, '                        android.util.Log.w("LxEngineHolder", "池引擎异常: $id ${e.message}")',
        '                        android.util.Log.w("LxEngineHolder", "池引擎异常: $id ${e.message}")\n                        try { LxRuntimeLog.add("池引擎异常: $id ${e.message}") } catch (_: Exception) { } // [39pool2] 池异常进日志', '39pool2 池异常进日志')
    save(PA, a)
    print('OK [39pool2] 池加载触发补强已接')
else:
    print('SKIP [39pool2] 已应用')

# ============ 12) [39pool3] 池加载静默失败记日志 + 超时 30s + 日志带源名 ============
PA = BASE + 'ui/LxPlayerActivity.kt'
a = load(PA)
if '[39pool3]' not in a:
    # 1) 新增源名解析 helper（池日志只写 id 看不出是哪个源）
    a = rep(a, '''    private fun loadPoolEngineSync(context: android.content.Context, preload: String, sourceId: String): Boolean {''',
        '''    // [39pool3] 池日志用源名（id 看不出是哪个源）
    private fun poolSourceName(sourceId: String): String {
        return try {
            LxSourceManager.getEnabledSources().find { it.id == sourceId }?.name ?: sourceId.take(8)
        } catch (_: Exception) {
            sourceId.take(8)
        }
    }

    private fun loadPoolEngineSync(context: android.content.Context, preload: String, sourceId: String): Boolean {''', '39pool3 源名 helper')
    # 2) loadPoolEngineSync 全量重写：失败原因记运行日志（此前全部静默返回 false）+ 超时 15s→30s
    a = rep(a, '''    private fun loadPoolEngineSync(context: android.content.Context, preload: String, sourceId: String): Boolean {
        val content = try { LxSourceManager.getScriptContent(sourceId) } catch (_: Exception) { null } ?: return false
        if (content.isBlank()) return false
        val eng = LxScriptEngine()
        return try {
            eng.initialize(context)
            val latch = java.util.concurrent.CountDownLatch(1)
            val ok = java.util.concurrent.atomic.AtomicBoolean(false)
            eng.loadPreloadJs(preload) { ready ->
                if (!ready) { latch.countDown(); return@loadPreloadJs }
                val info = com.github.avbox.osc.util.ScriptInfo(id = sourceId, name = "")
                eng.loadScript(sourceId, content, info) { r ->
                    ok.set(r.isSuccess)
                    latch.countDown()
                }
            }
            latch.await(15, java.util.concurrent.TimeUnit.SECONDS)
            if (ok.get()) {
                poolEngines[sourceId] = eng
                true
            } else {
                try { eng.destroy() } catch (_: Exception) {}
                false
            }
        } catch (e: Exception) {
            try { eng.destroy() } catch (_: Exception) {}
            false
        }
    }''',
        '''    private fun loadPoolEngineSync(context: android.content.Context, preload: String, sourceId: String): Boolean { // [39pool3] 失败原因记日志 + 超时 30s
        val name = poolSourceName(sourceId)
        val content = try { LxSourceManager.getScriptContent(sourceId) } catch (_: Exception) { null }
        if (content.isNullOrBlank()) {
            try { LxRuntimeLog.add("池引擎失败: $name 脚本为空") } catch (_: Exception) { }
            return false
        }
        val eng = LxScriptEngine()
        return try {
            eng.initialize(context)
            val latch = java.util.concurrent.CountDownLatch(1)
            val ok = java.util.concurrent.atomic.AtomicBoolean(false)
            val preloadOk = java.util.concurrent.atomic.AtomicBoolean(true)
            eng.loadPreloadJs(preload) { ready ->
                if (!ready) { preloadOk.set(false); latch.countDown(); return@loadPreloadJs }
                val info = com.github.avbox.osc.util.ScriptInfo(id = sourceId, name = "")
                eng.loadScript(sourceId, content, info) { r ->
                    ok.set(r.isSuccess)
                    latch.countDown()
                }
            }
            latch.await(30, java.util.concurrent.TimeUnit.SECONDS)
            if (ok.get()) {
                poolEngines[sourceId] = eng
                true
            } else {
                try { eng.destroy() } catch (_: Exception) {}
                val reason = if (!preloadOk.get()) "预加载失败" else "30秒内未初始化"
                try { LxRuntimeLog.add("池引擎失败: $name $reason") } catch (_: Exception) { }
                false
            }
        } catch (e: Exception) {
            try { eng.destroy() } catch (_: Exception) {}
            try { LxRuntimeLog.add("池引擎失败: $name ${e.message}") } catch (_: Exception) { }
            false
        }
    }''', '39pool3 loadPoolEngineSync 重写')
    # 3) 池就绪/异常日志带源名（warmUpPoolAsync 路径）
    a = rep(a, '                            android.util.Log.i("LxEngineHolder", "池引擎就绪: $id")\n                            try { LxRuntimeLog.add("池引擎就绪: $id") } catch (_: Exception) { } // [39pool2] 池状态进运行日志抽屉',
        '                            android.util.Log.i("LxEngineHolder", "池引擎就绪: ${poolSourceName(id)}")\n                            try { LxRuntimeLog.add("池引擎就绪: ${poolSourceName(id)}") } catch (_: Exception) { } // [39pool3] 池日志带源名', '39pool3 池就绪带源名')
    a = rep(a, '                        android.util.Log.w("LxEngineHolder", "池引擎异常: $id ${e.message}")\n                        try { LxRuntimeLog.add("池引擎异常: $id ${e.message}") } catch (_: Exception) { } // [39pool2] 池异常进日志',
        '                        android.util.Log.w("LxEngineHolder", "池引擎异常: ${poolSourceName(id)} ${e.message}")\n                        try { LxRuntimeLog.add("池引擎异常: ${poolSourceName(id)} ${e.message}") } catch (_: Exception) { } // [39pool3] 池异常带源名', '39pool3 池异常带源名')
    # 4) 池就绪/异常日志带源名（warmUpPoolForSource 路径）
    a = rep(a, '                    android.util.Log.i("LxEngineHolder", "池引擎就绪: $sourceId")\n                    try { LxRuntimeLog.add("池引擎就绪: $sourceId") } catch (_: Exception) { }',
        '                    android.util.Log.i("LxEngineHolder", "池引擎就绪: ${poolSourceName(sourceId)}")\n                    try { LxRuntimeLog.add("池引擎就绪: ${poolSourceName(sourceId)}") } catch (_: Exception) { } // [39pool3] 池日志带源名', '39pool3 导入就绪带源名')
    a = rep(a, '                android.util.Log.w("LxEngineHolder", "池引擎异常: $sourceId ${e.message}")\n                try { LxRuntimeLog.add("池引擎异常: $sourceId ${e.message}") } catch (_: Exception) { }',
        '                android.util.Log.w("LxEngineHolder", "池引擎异常: ${poolSourceName(sourceId)} ${e.message}")\n                try { LxRuntimeLog.add("池引擎异常: ${poolSourceName(sourceId)} ${e.message}") } catch (_: Exception) { } // [39pool3] 导入异常带源名', '39pool3 导入异常带源名')
    save(PA, a)
    print('OK [39pool3] 池加载静默失败记日志已接')
else:
    print('SKIP [39pool3] 已应用')

# ============ 13) [39pool4] 池内轮换：验活失败换池内下一源再试（同一档位内，不直接降档） ============
PA = BASE + 'ui/LxPlayerActivity.kt'
a = load(PA)
if '[39pool4]' not in a:
    # 1) resolveMusicUrlFirst：加排除集参数 + 回源id+地址（调用方才知道是谁给的地址、失败后排除谁）
    a = rep(a, '''    fun resolveMusicUrlFirst(
        platform: String,
        musicInfo: Map<String, Any>,
        quality: String,
        callback: (Result<String>) -> Unit
    ) {
        val targets = ArrayList<Pair<String, LxScriptEngine>>()
        val primary = engine
        if (primary != null && isReady && loadedSourceId != null) {
            targets.add(loadedSourceId!! to primary)
        }
        for ((id, eng) in poolEngines) {
            if (id == loadedSourceId) continue
            targets.add(id to eng)
        }''',
        '''    fun resolveMusicUrlFirst(
        platform: String,
        musicInfo: Map<String, Any>,
        quality: String,
        excludedIds: Set<String> = emptySet(), // [39pool4] 池内轮换：验活失败的源排除掉再竞速
        callback: (Result<Pair<String, String>>) -> Unit // [39pool4] 回源id+地址
    ) {
        val targets = ArrayList<Pair<String, LxScriptEngine>>()
        val primary = engine
        if (primary != null && isReady && loadedSourceId != null && loadedSourceId !in excludedIds) {
            targets.add(loadedSourceId!! to primary)
        }
        for ((id, eng) in poolEngines) {
            if (id == loadedSourceId) continue
            if (id in excludedIds) continue
            targets.add(id to eng)
        }''', '39pool4 竞速加排除集')
    a = rep(a, '''                                if (done.compareAndSet(false, true)) {
                                    lastGoodSourceId = sid
                                    callback(Result.success(url))
                                }''',
        '''                                if (done.compareAndSet(false, true)) {
                                    lastGoodSourceId = sid
                                    callback(Result.success(sid to url)) // [39pool4] 回源id+地址
                                }''', '39pool4 竞速回源id')
    # 2) tryQuality：同一档位内排除失败源再试（不直接降档）；换档位时清空排除集
    a = rep(a, '''        var qualityIndex = 0
        fun tryQuality() {''',
        '''        var qualityIndex = 0
        var excludedSources = mutableSetOf<String>() // [39pool4] 池内轮换：同一档位内验活失败的源排除掉再试
        fun tryQuality() {''', '39pool4 排除集变量')
    a = rep(a, '            LxEngineHolder.resolveMusicUrlFirst(sourceId, musicInfo, q) { result -> // [39pool] 多源竞速取地址',
        '            LxEngineHolder.resolveMusicUrlFirst(sourceId, musicInfo, q, excludedSources) { result -> // [39pool4] 池内轮换：传排除集', '39pool4 呼叫点传排除集')
    a = rep(a, '''            LxEngineHolder.resolveMusicUrlFirst(sourceId, musicInfo, q, excludedSources) { result -> // [39pool4] 池内轮换：传排除集
                runOnUiThread {
                    result.fold(
                        onSuccess = { url ->
                            if (url.isNotBlank()) {''',
        '''            LxEngineHolder.resolveMusicUrlFirst(sourceId, musicInfo, q, excludedSources) { result -> // [39pool4] 池内轮换：传排除集
                runOnUiThread {
                    result.fold(
                        onSuccess = { (urlSourceId, url) -> // [39pool4] 竞速回源id+地址
                            if (url.isNotBlank()) {''', '39pool4 拆包源id')
    a = rep(a, '''                                        if (!alive) {
                                            try { LxRuntimeLog.add("地址验活失败: " + title + " / " + artist + " | 档位 " + q + " " + url.take(80)) } catch (_: Exception) { }
                                            android.util.Log.w("LxPlayer", "音质 $q 地址验活失败，降级重试")
                                            qualityIndex++
                                            tryQuality()''',
        '''                                        if (!alive) {
                                            try { LxRuntimeLog.add("地址验活失败: " + title + " / " + artist + " | 档位 " + q + " " + url.take(80)) } catch (_: Exception) { }
                                            android.util.Log.w("LxPlayer", "音质 $q 地址验活失败，换池内下一源重试") // [39pool4]
                                            excludedSources.add(urlSourceId) // [39pool4] 排除刚失败的源，同一档位换源再试
                                            LxEngineHolder.markSourceCoolDown(urlSourceId) // [39pool6] 坏源搁置 5 分钟，下一首不优先试
                                            tryQuality()''', '39pool4 验活失败换源')
    a = rep(a, '''                            } else {
                                android.util.Log.w("LxPlayer", "音质 $q 返回空地址，降级重试")
                                qualityIndex++
                                tryQuality()
                            }''',
        '''                            } else {
                                android.util.Log.w("LxPlayer", "音质 $q 返回空地址，换池内下一源重试") // [39pool4]
                                excludedSources.add(urlSourceId) // [39pool4]
                                LxEngineHolder.markSourceCoolDown(urlSourceId) // [39pool6] 空地址也搁置
                                tryQuality()
                            }''', '39pool4 空地址换源')
    a = rep(a, '''                            } else {
                                android.util.Log.w("LxPlayer", "音质 $q 失败: $errMsg，降级重试")
                                qualityIndex++
                                tryQuality()
                            }''',
        '''                            } else {
                                android.util.Log.w("LxPlayer", "音质 $q 失败: $errMsg，降级重试")
                                qualityIndex++
                                excludedSources.clear() // [39pool4] 换档位时清空排除集
                                tryQuality()
                            }''', '39pool4 换档位清排除集')
    save(PA, a)
    print('OK [39pool4] 池内轮换已接')
else:
    print('SKIP [39pool4] 已应用')

print('[39] 全部补丁完成')
PYEOF39
echo "=== 39 wp5 完成 ==="

# ============ 11) [39pool5] 池竞速改顺序兜底（用户明令“修复池子不能共享播放”）——并行竞速三引擎同发请求，4G 下后端限流/超时全挂，落雪单发却能播。修法：竞速改顺序试——按 lastGood→主源→池序逐个试，单个 10 秒超时即跳下一个，首个成功即回；全败才报失败。 ===
python3 << 'PYEOF39P5'
import os

def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/avbox/osc/ui/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
    assert os.path.exists("avbox/app/src/main/java/com/github/avbox/osc/ui/MusicHomeActivity.kt"), "find_root 失败"

def rep(src, old, new, name):
    assert src.count(old) == 1, "pool5 锚点 %s: %d" % (name, src.count(old))
    return src.replace(old, new, 1)

find_root()
PA = "avbox/app/src/main/java/com/github/avbox/osc/ui/LxPlayerActivity.kt"
a = open(PA, encoding="utf-8").read()
if "[39pool5]" in a:
    print("跳过（39pool5 已应用）")
else:
    old = """    fun resolveMusicUrlFirst(
        platform: String,
        musicInfo: Map<String, Any>,
        quality: String,
        excludedIds: Set<String> = emptySet(), // [39pool4] 池内轮换：验活失败的源排除掉再竞速
        callback: (Result<Pair<String, String>>) -> Unit // [39pool4] 回源id+地址
    ) {
        val targets = ArrayList<Pair<String, LxScriptEngine>>()
        val primary = engine
        if (primary != null && isReady && loadedSourceId != null && loadedSourceId !in excludedIds) {
            targets.add(loadedSourceId!! to primary)
        }
        for ((id, eng) in poolEngines) {
            if (id == loadedSourceId) continue
            if (id in excludedIds) continue
            targets.add(id to eng)
        }
        lastGoodSourceId?.let { good ->
            val idx = targets.indexOfFirst { it.first == good }
            if (idx > 0) {
                val p = targets.removeAt(idx)
                targets.add(0, p)
            }
        }
        if (targets.isEmpty()) {
            callback(Result.failure(IllegalStateException("engine not ready")))
            return
        }
        val done = java.util.concurrent.atomic.AtomicBoolean(false)
        val remaining = java.util.concurrent.atomic.AtomicInteger(targets.size)
        for ((sid, eng) in targets) {
            try {
                eng.requestMusicUrl(platform, musicInfo, quality) { r ->
                    r.fold(
                        onSuccess = { url ->
                            if (url.isNotBlank()) {
                                if (done.compareAndSet(false, true)) {
                                    lastGoodSourceId = sid
                                    callback(Result.success(sid to url)) // [39pool4] 回源id+地址
                                }
                            } else {
                                if (remaining.decrementAndGet() == 0 && done.compareAndSet(false, true)) {
                                    callback(Result.failure(IllegalStateException("empty music url")))
                                }
                            }
                        },
                        onFailure = { e ->
                            if (remaining.decrementAndGet() == 0 && done.compareAndSet(false, true)) {
                                callback(Result.failure(e))
                            }
                        }
                    )
                }
            } catch (e: Exception) {
                if (remaining.decrementAndGet() == 0 && done.compareAndSet(false, true)) {
                    callback(Result.failure(e))
                }
            }
        }
    }"""
    new = """    fun resolveMusicUrlFirst(
        platform: String,
        musicInfo: Map<String, Any>,
        quality: String,
        excludedIds: Set<String> = emptySet(), // [39pool4] 池内轮换：验活失败的源排除掉再竞速
        callback: (Result<Pair<String, String>>) -> Unit // [39pool4] 回源id+地址
    ) {
        val targets = ArrayList<Pair<String, LxScriptEngine>>()
        val primary = engine
        if (primary != null && isReady && loadedSourceId != null && loadedSourceId !in excludedIds) {
            targets.add(loadedSourceId!! to primary)
        }
        for ((id, eng) in poolEngines) {
            if (id == loadedSourceId) continue
            if (id in excludedIds) continue
            targets.add(id to eng)
        }
        lastGoodSourceId?.let { good ->
            val idx = targets.indexOfFirst { it.first == good }
            if (idx > 0) {
                val p = targets.removeAt(idx)
                targets.add(0, p)
            }
        }
        if (targets.isEmpty()) {
            callback(Result.failure(IllegalStateException("engine not ready")))
            return
        }
        // [39pool5] 顺序兜底：并行竞速三引擎同发请求，4G 下后端限流/超时全挂；改逐个试，单个 10 秒超时即跳下一个，首个成功即回
        val done = java.util.concurrent.atomic.AtomicBoolean(false)
        fun tryTarget(idx: Int) {
            if (done.get()) return
            if (idx >= targets.size) {
                if (done.compareAndSet(false, true)) {
                    callback(Result.failure(IllegalStateException("all sources failed")))
                }
                return
            }
            val (sid, eng) = targets[idx]
            val settled = java.util.concurrent.atomic.AtomicBoolean(false)
            val timer = Thread {
                try {
                    Thread.sleep(10000) // [39pool5] 单源 10 秒超时
                    if (settled.compareAndSet(false, true)) {
                        tryTarget(idx + 1)
                    }
                } catch (_: Exception) { }
            }.apply { isDaemon = true; start() }
            try {
                eng.requestMusicUrl(platform, musicInfo, quality) { r ->
                    if (!settled.compareAndSet(false, true)) return@requestMusicUrl
                    r.fold(
                        onSuccess = { url ->
                            if (url.isNotBlank()) {
                                if (done.compareAndSet(false, true)) {
                                    lastGoodSourceId = sid
                                    callback(Result.success(sid to url))
                                }
                            } else {
                                tryTarget(idx + 1)
                            }
                        },
                        onFailure = { _ ->
                            tryTarget(idx + 1)
                        }
                    )
                }
            } catch (e: Exception) {
                if (settled.compareAndSet(false, true)) {
                    tryTarget(idx + 1)
                }
            }
        }
        tryTarget(0)
    }"""
    a = rep(a, old, new, "池竞速改顺序兜底")
    assert "[39pool5]" in a, "pool5 标记未落"
    open(PA, "w", encoding="utf-8").write(a)
    print("OK [39pool5] 池竞速改顺序兜底完成")
PYEOF39P5
echo "=== 39 pool5 完成 ==="

# === 39 pool8: 并行竞速＋坏源跳过（用户指“能不能同时竞速，不要逐条”“坏的搁置”）===
# pool5 顺序太慢（单源 10 秒超时，三源全试可达 30 秒，用户报“长时间播不了直接 2004”）。
# 修法：改回并行竞速（同时发，首个成功即回），坏源由冷却跳过（pool6/pool7 机制保留）——
# 冷却期内的源直接从目标列表去掉不试，好源并行竞速，快且不被坏源拖慢。
python3 << 'PYEOF39P8'
import os

def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/avbox/osc/ui/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
    assert os.path.exists("avbox/app/src/main/java/com/github/avbox/osc/ui/MusicHomeActivity.kt"), "find_root 失败"

def rep(src, old, new, name):
    assert src.count(old) == 1, "pool8 锚点 %s: %d" % (name, src.count(old))
    return src.replace(old, new, 1)

find_root()
PA = "avbox/app/src/main/java/com/github/avbox/osc/ui/LxPlayerActivity.kt"
a = open(PA, encoding="utf-8").read()
if "[39pool8]" in a:
    print("跳过（39 pool8 已应用）")
else:
    old = """        // [39pool5] 顺序兜底：并行竞速三引擎同发请求，4G 下后端限流/超时全挂；改逐个试，单个 10 秒超时即跳下一个，首个成功即回
        val done = java.util.concurrent.atomic.AtomicBoolean(false)
        fun tryTarget(idx: Int) {
            if (done.get()) return
            if (idx >= targets.size) {
                if (done.compareAndSet(false, true)) {
                    callback(Result.failure(IllegalStateException("all sources failed")))
                }
                return
            }
            val (sid, eng) = targets[idx]
            val settled = java.util.concurrent.atomic.AtomicBoolean(false)
            val timer = Thread {
                try {
                    Thread.sleep(10000) // [39pool5] 单源 10 秒超时
                    if (settled.compareAndSet(false, true)) {
                        tryTarget(idx + 1)
                    }
                } catch (_: Exception) { }
            }.apply { isDaemon = true; start() }
            try {
                eng.requestMusicUrl(platform, musicInfo, quality) { r ->
                    if (!settled.compareAndSet(false, true)) return@requestMusicUrl
                    r.fold(
                        onSuccess = { url ->
                            if (url.isNotBlank()) {
                                if (done.compareAndSet(false, true)) {
                                    lastGoodSourceId = sid
                                    callback(Result.success(sid to url))
                                }
                            } else {
                                tryTarget(idx + 1)
                            }
                        },
                        onFailure = { _ ->
                            tryTarget(idx + 1)
                        }
                    )
                }
            } catch (e: Exception) {
                if (settled.compareAndSet(false, true)) {
                    tryTarget(idx + 1)
                }
            }
        }
        tryTarget(0)"""
    new = """        // [39pool8] 并行竞速：用户指“能不能同时竞速，不要逐条”——顺序太慢，改回并行；坏源已由冷却跳过，不再抢赢
        // [39pool8] 坏源跳过：冷却期内的源直接去掉不试，5 分钟内零耗时；全冷却时才全试（不至于无源可用）
        val (goodTargets, coolTargets) = targets.partition { !isSourceCoolDown(it.first) }
        if (goodTargets.isNotEmpty()) {
            targets.clear()
            targets.addAll(goodTargets)
            // [39pool8] 冷却源不加入，跳过不试
        }
        val done = java.util.concurrent.atomic.AtomicBoolean(false)
        val remaining = java.util.concurrent.atomic.AtomicInteger(targets.size)
        for ((sid, eng) in targets) {
            try {
                eng.requestMusicUrl(platform, musicInfo, quality) { r ->
                    r.fold(
                        onSuccess = { url ->
                            if (url.isNotBlank()) {
                                if (done.compareAndSet(false, true)) {
                                    lastGoodSourceId = sid
                                    callback(Result.success(sid to url))
                                }
                            } else {
                                if (remaining.decrementAndGet() == 0 && done.compareAndSet(false, true)) {
                                    callback(Result.failure(IllegalStateException("empty music url")))
                                }
                            }
                        },
                        onFailure = { e ->
                            if (remaining.decrementAndGet() == 0 && done.compareAndSet(false, true)) {
                                callback(Result.failure(e))
                            }
                        }
                    )
                }
            } catch (e: Exception) {
                if (remaining.decrementAndGet() == 0 && done.compareAndSet(false, true)) {
                    callback(Result.failure(e))
                }
            }
        }"""
    a = rep(a, old, new, "顺序改回并行")
    assert "[39pool8]" in a, "pool8 标记未落"
    open(PA, "w", encoding="utf-8").write(a)
    print("OK [39pool8] 并行竞速＋坏源跳过完成")
PYEOF39P8
echo "=== 39 pool8 完成 ==="

# === 39 pool9: 脚本抛错即冷却（用户指“把裤老删掉重进才能播”）===
# 根因：markSourceCoolDown 只在“取到地址后验活失败”时调，脚本直接抛错（酷狗所有音源均获取失败）没地址时不调，裤佬永不冷却，池子每首都先试裤佬、抛错、再试别的，慢且抽风。
# 修法：并行竞速时，任一源 requestMusicUrl 抛错（onFailure 或 catch）即记该源冷却 5 分钟，不再等验活。
python3 << 'PYEOF39P9'
import os

def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/avbox/osc/ui/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
    assert os.path.exists("avbox/app/src/main/java/com/github/avbox/osc/ui/MusicHomeActivity.kt"), "find_root 失败"

def rep(src, old, new, name):
    assert src.count(old) == 1, "pool9 锚点 %s: %d" % (name, src.count(old))
    return src.replace(old, new, 1)

find_root()
PA = "avbox/app/src/main/java/com/github/avbox/osc/ui/LxPlayerActivity.kt"
a = open(PA, encoding="utf-8").read()
if "[39pool9]" in a:
    print("跳过（39 pool9 已应用）")
else:
    old = """                        onFailure = { e ->
                            if (remaining.decrementAndGet() == 0 && done.compareAndSet(false, true)) {
                                callback(Result.failure(e))
                            }
                        }"""
    new = """                        onFailure = { e ->
                            markSourceCoolDown(sid) // [39pool9] 脚本抛错即冷却 5 分钟，不等验活（裤佬脚本“酷狗所有音源均获取失败”时无地址可验）
                            if (remaining.decrementAndGet() == 0 && done.compareAndSet(false, true)) {
                                callback(Result.failure(e))
                            }
                        }"""
    a = rep(a, old, new, "onFailure 记冷却")
    old = """            } catch (e: Exception) {
                if (remaining.decrementAndGet() == 0 && done.compareAndSet(false, true)) {
                    callback(Result.failure(e))
                }
            }"""
    new = """            } catch (e: Exception) {
                markSourceCoolDown(sid) // [39pool9] 脚本抛错即冷却 5 分钟，不等验活
                if (remaining.decrementAndGet() == 0 && done.compareAndSet(false, true)) {
                    callback(Result.failure(e))
                }
            }"""
    a = rep(a, old, new, "catch 记冷却")
    assert "[39pool9]" in a, "pool9 标记未落"
    open(PA, "w", encoding="utf-8").write(a)
    print("OK [39pool9] 脚本抛错即冷却完成")
PYEOF39P9
echo "=== 39 pool9 完成 ==="

# === 39 pool10: 顺序遍历降级＋防串取号（用户确认）===
# 痛点：优先级最高的脚本解析失败（空、超时、抛错）时系统直接判播放失败，不试其他已启用脚本。
# 修法：LxEngineHolder 加挂起函数 resolveUrlWithFallback——for 循环遍历源池，try-catch 抓抛错、校验空地址、withTimeout(8000L) 单源超时、失败记冷却，全挂才抛“所有音源均失效”；resolveMusicUrlFirst 改调它（回调包装协程）。
python3 << 'PYEOF39P10'
import os

def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/avbox/osc/ui/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
    assert os.path.exists("avbox/app/src/main/java/com/github/avbox/osc/ui/MusicHomeActivity.kt"), "find_root 失败"

def rep(src, old, new, name):
    assert src.count(old) == 1, "pool10 锚点 %s: %d" % (name, src.count(old))
    return src.replace(old, new, 1)

find_root()
PA = "avbox/app/src/main/java/com/github/avbox/osc/ui/LxPlayerActivity.kt"
a = open(PA, encoding="utf-8").read()
if "[39pool10]" in a:
    print("跳过（39 pool10 已应用）")
else:
    # 1) 在 LxEngineHolder 里加协程作用域（不用 GlobalScope）
    old = """    // [39pool6] 坏源冷却：验活失败的源搁置 5 分钟，排序时沉底，好源在前（用户指“杰翔不掺裤老就不抽风”）
    private val sourceCoolDownUntil = java.util.concurrent.ConcurrentHashMap<String, Long>()"""
    new = """    // [39pool6] 坏源冷却：验活失败的源搁置 5 分钟，排序时沉底，好源在前（用户指“杰翔不掺裤老就不抽风”）
    private val sourceCoolDownUntil = java.util.concurrent.ConcurrentHashMap<String, Long>()
    // [39pool10] 顺序遍历降级用协程作用域（不用 GlobalScope，不依赖外部生命周期）
    private val poolScope = kotlinx.coroutines.CoroutineScope(kotlinx.coroutines.Dispatchers.IO + kotlinx.coroutines.SupervisorJob())"""
    a = rep(a, old, new, "poolScope")
    # 2) 在 resolveMusicUrlFirst 前插入 resolveUrlWithFallback 挂起函数
    old = """    fun resolveMusicUrlFirst("""
    new = """    // [39pool10] 顺序遍历降级：for 循环一个个试，哪个先出合法地址就用哪个，全挂才抛“所有音源均失效”
    suspend fun resolveUrlWithFallback(
        platform: String,
        musicInfo: Map<String, Any>,
        quality: String,
        excludedIds: Set<String> = emptySet()
    ): Pair<String, String> {
        val targets = ArrayList<Pair<String, LxScriptEngine>>()
        val primary = engine
        if (primary != null && isReady && loadedSourceId != null && loadedSourceId !in excludedIds && !isSourceCoolDown(loadedSourceId!!)) {
            targets.add(loadedSourceId!! to primary)
        }
        for ((id, eng) in poolEngines) {
            if (id == loadedSourceId) continue
            if (id in excludedIds) continue
            if (isSourceCoolDown(id)) continue
            targets.add(id to eng)
        }
        // [39pool12] 打乱首位：若首位是冷却刚过期或上次失败的源，不让它恒占首位；lastGood 仍优先
        if (targets.size > 1) {
            val firstId = targets[0].first
            if (firstId != lastGoodSourceId && isSourceCoolDown(firstId)) {
                val p = targets.removeAt(0)
                targets.add(p)
            }
        }
        lastGoodSourceId?.let { good ->
            val idx = targets.indexOfFirst { it.first == good }
            if (idx > 0) {
                val p = targets.removeAt(idx)
                targets.add(0, p)
            }
        }
        if (targets.isEmpty()) {
            throw IllegalStateException("没有可用音源")
        }
        var lastError: Throwable? = null
        for ((sid, eng) in targets) {
            try {
                val url = kotlinx.coroutines.withTimeout(8000L) {
                    kotlin.coroutines.suspendCoroutine<String?> { cont ->
                        try {
                            eng.requestMusicUrl(platform, musicInfo, quality) { r ->
                                r.fold(
                                    onSuccess = { u -> cont.resumeWith(Result.success(u)) },
                                    onFailure = { e -> cont.resumeWith(Result.failure(e)) }
                                )
                            }
                        } catch (e: Exception) {
                            cont.resumeWith(Result.failure(e))
                        }
                    }
                }
                if (!url.isNullOrBlank()) {
                    lastGoodSourceId = sid
                    return sid to url
                } else {
                    android.util.Log.w("LxPlayer", "源 $sid 返回空地址，尝试下一个")
                }
            } catch (e: Exception) {
                android.util.Log.w("LxPlayer", "源 $sid 解析失败 (${e.javaClass.simpleName}: ${e.message})，尝试下一个")
                lastError = e
                markSourceCoolDown(sid)
                continue
            }
        }
        throw IllegalStateException("所有音源均失效", lastError)
    }

    fun resolveMusicUrlFirst("""
    a = rep(a, old, new, "resolveUrlWithFallback")
    assert "[39pool10]" in a, "pool10 标记未落"
    open(PA, "w", encoding="utf-8").write(a)
    print("OK [39pool10] 顺序遍历降级完成")
PYEOF39P10
echo "=== 39 pool10 完成 ==="

# === 39 pool11: resolveMusicUrlFirst 改调 resolveUrlWithFallback（pool10 漏接线）===
# 根因：pool10 只加了 resolveUrlWithFallback 挂起函数，没改 resolveMusicUrlFirst 去调它；调用方（tryQuality/Manager）仍走旧的并行 resolveMusicUrlFirst，裤佬死链继续锁死。
# 修法：resolveMusicUrlFirst 函数体改成 poolScope.launch 调 resolveUrlWithFallback，成功回 Pair，失败回 failure。
python3 << 'PYEOF39P11'
import os

def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/avbox/osc/ui/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
    assert os.path.exists("avbox/app/src/main/java/com/github/avbox/osc/ui/MusicHomeActivity.kt"), "find_root 失败"

def rep(src, old, new, name):
    assert src.count(old) == 1, "pool11 锚点 %s: %d" % (name, src.count(old))
    return src.replace(old, new, 1)

find_root()
PA = "avbox/app/src/main/java/com/github/avbox/osc/ui/LxPlayerActivity.kt"
a = open(PA, encoding="utf-8").read()
if "[39pool11]" in a:
    print("跳过（39 pool11 已应用）")
else:
    # Find resolveMusicUrlFirst function body and replace it with delegation to resolveUrlWithFallback
    # The function starts with "    fun resolveMusicUrlFirst(" and ends before the next "    fun " or "    }" at same level
    # Simpler: replace the entire function by finding its start and the pool8 parallel block
    old = """    fun resolveMusicUrlFirst(
        platform: String,
        musicInfo: Map<String, Any>,
        quality: String,
        excludedIds: Set<String> = emptySet(), // [39pool4] 池内轮换：验活失败的源排除掉再竞速
        callback: (Result<Pair<String, String>>) -> Unit // [39pool4] 回源id+地址
    ) {"""
    new = """    fun resolveMusicUrlFirst(
        platform: String,
        musicInfo: Map<String, Any>,
        quality: String,
        excludedIds: Set<String> = emptySet(), // [39pool4] 池内轮换：验活失败的源排除掉再竞速
        callback: (Result<Pair<String, String>>) -> Unit // [39pool4] 回源id+地址
    ) { // [39pool11] 改调 resolveUrlWithFallback（顺序遍历降级），回调包装协程
        poolScope.launch {
            try {
                val r = resolveUrlWithFallback(platform, musicInfo, quality, excludedIds)
                callback(Result.success(r))
            } catch (e: Exception) {
                callback(Result.failure(e))
            }
        }
        // [39pool11] 以下旧并行逻辑已废弃，由 resolveUrlWithFallback 接管（保留占位，永不执行）
        if (true) return
        // --- 旧逻辑开始（永不执行）---"""
    a = rep(a, old, new, "resolveMusicUrlFirst 改调 fallback")
    assert "[39pool11]" in a, "pool11 标记未落"
    open(PA, "w", encoding="utf-8").write(a)
    print("OK [39pool11] resolveMusicUrlFirst 改调 fallback 完成")
PYEOF39P11
echo "=== 39 pool11 完成 ==="

# === 39 pool12: 取消主源锁定，播放取址时所有源平等（用户指“应该是主源锁定，可以改成没有主源吗”）===
# 根因：resolveUrlWithFallback 里主源（loadedSourceId）恒排首位，裤佬为主源时先试它；若主源的 requestMusicUrl 同步抛错或回调永不回，withTimeout 也可能被绕过，池子锁死。
# 修法：播放取址时不分主源/池源，所有已启用源平等进列表，只按 lastGood 排前、其余按池序；主源仍用于搜索等其他操作，只是不再锁定播放首位。
python3 << 'PYEOF39P12'
import os

def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/avbox/osc/ui/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
    assert os.path.exists("avbox/app/src/main/java/com/github/avbox/osc/ui/MusicHomeActivity.kt"), "find_root 失败"

def rep(src, old, new, name):
    assert src.count(old) == 1, "pool12 锚点 %s: %d" % (name, src.count(old))
    return src.replace(old, new, 1)

find_root()
PA = "avbox/app/src/main/java/com/github/avbox/osc/ui/LxPlayerActivity.kt"
a = open(PA, encoding="utf-8").read()
if "[39pool12]" in a:
    print("跳过（39 pool12 已应用）")
else:
    old = """        val targets = ArrayList<Pair<String, LxScriptEngine>>()
        val primary = engine
        if (primary != null && isReady && loadedSourceId != null && loadedSourceId !in excludedIds && !isSourceCoolDown(loadedSourceId!!)) {
            targets.add(loadedSourceId!! to primary)
        }
        for ((id, eng) in poolEngines) {
            if (id == loadedSourceId) continue
            if (id in excludedIds) continue
            if (isSourceCoolDown(id)) continue
            targets.add(id to eng)
        }"""
    new = """        // [39pool12] 取消主源锁定：播放取址时所有已启用源平等，不分主源/池源；主源仍用于搜索等，只是不再锁定播放首位
        val targets = ArrayList<Pair<String, LxScriptEngine>>()
        val primary = engine
        // 主源也只是池中一员，按同样规则进列表（不再恒排首位）
        if (primary != null && isReady && loadedSourceId != null && loadedSourceId !in excludedIds && !isSourceCoolDown(loadedSourceId!!)) {
            targets.add(loadedSourceId!! to primary)
        }
        for ((id, eng) in poolEngines) {
            if (id == loadedSourceId) continue
            if (id in excludedIds) continue
            if (isSourceCoolDown(id)) continue
            targets.add(id to eng)
        }
        // [39pool12] 打乱首位：若首位是冷却刚过期或上次失败的源，不让它恒占首位；lastGood 仍优先
        if (targets.size > 1) {
            val firstId = targets[0].first
            if (firstId != lastGoodSourceId && isSourceCoolDown(firstId)) {
                val p = targets.removeAt(0)
                targets.add(p)
            }
        }"""
    a = rep(a, old, new, "取消主源锁定")
    assert "[39pool12]" in a, "pool12 标记未落"
    open(PA, "w", encoding="utf-8").write(a)
    print("OK [39pool12] 取消主源锁定完成")
PYEOF39P12
echo "=== 39 pool12 完成 ==="

# === 39 pool13: 全冷却时照常用，不抛“没有可用音源”（用户指“播着播着会抽风，所有个都播不了，重进才能播”）===
# 根因：resolveUrlWithFallback 里冷却源直接跳过，多首连败后所有源都被冷却 5 分钟，targets 为空即抛“没有可用音源”，5 分钟内所有歌都播不了；重进 App 清掉内存里的冷却表才能播。
# 修法：先按冷却过滤，若过滤后为空，则不过滤冷却、全部源都进列表（全冷却时照常用）；冷却只是排序依据，不是准入条件。
python3 << 'PYEOF39P13'
import os

def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/avbox/osc/ui/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
    assert os.path.exists("avbox/app/src/main/java/com/github/avbox/osc/ui/MusicHomeActivity.kt"), "find_root 失败"

def rep(src, old, new, name):
    assert src.count(old) == 1, "pool13 锚点 %s: %d" % (name, src.count(old))
    return src.replace(old, new, 1)

find_root()
PA = "avbox/app/src/main/java/com/github/avbox/osc/ui/LxPlayerActivity.kt"
a = open(PA, encoding="utf-8").read()
if "[39pool13]" in a:
    print("跳过（39 pool13 已应用）")
else:
    old = """        for ((id, eng) in poolEngines) {
            if (id == loadedSourceId) continue
            if (id in excludedIds) continue
            if (isSourceCoolDown(id)) continue
            targets.add(id to eng)
        }
        // [39pool12] 打乱首位：若首位是冷却刚过期或上次失败的源，不让它恒占首位；lastGood 仍优先
        if (targets.size > 1) {
            val firstId = targets[0].first
            if (firstId != lastGoodSourceId && isSourceCoolDown(firstId)) {
                val p = targets.removeAt(0)
                targets.add(p)
            }
        }
        lastGoodSourceId?.let { good ->
            val idx = targets.indexOfFirst { it.first == good }
            if (idx > 0) {
                val p = targets.removeAt(idx)
                targets.add(0, p)
            }
        }
        if (targets.isEmpty()) {
            throw IllegalStateException("没有可用音源")
        }"""
    new = """        for ((id, eng) in poolEngines) {
            if (id == loadedSourceId) continue
            if (id in excludedIds) continue
            if (isSourceCoolDown(id)) continue
            targets.add(id to eng)
        }
        // [39pool13] 全冷却时照常用：若过滤后为空（所有源都被冷却），则不过滤冷却、全部源都进列表；冷却只是排序依据，不是准入条件
        if (targets.isEmpty()) {
            if (primary != null && isReady && loadedSourceId != null && loadedSourceId !in excludedIds) {
                targets.add(loadedSourceId!! to primary)
            }
            for ((id, eng) in poolEngines) {
                if (id == loadedSourceId) continue
                if (id in excludedIds) continue
                targets.add(id to eng)
            }
        }
        lastGoodSourceId?.let { good ->
            val idx = targets.indexOfFirst { it.first == good }
            if (idx > 0) {
                val p = targets.removeAt(idx)
                targets.add(0, p)
            }
        }
        if (targets.isEmpty()) {
            throw IllegalStateException("没有可用音源")
        }"""
    a = rep(a, old, new, "全冷却时照常用")
    assert "[39pool13]" in a, "pool13 标记未落"
    open(PA, "w", encoding="utf-8").write(a)
    print("OK [39pool13] 全冷却时照常用完成")
PYEOF39P13
echo "=== 39 pool13 完成 ==="

# === 39 pool14: 彻底平级化，废弃主源+备用池分层（用户确认）===
# 痛点：主源（如裤佬）失败时降级循环没正确执行，主源特殊地位导致边界 Bug。
# 修法：resolveUrlWithFallback 重构为纯粹平级遍历——getAllEngines() 统一收集主源+池源，过滤 excludedIds 与冷却源，lastGood 排最前，for 循环一个个试，withTimeout(8000L)，失败记冷却，全挂才抛“所有音源均失效”；含【降级排查】日志。
# 注意：suspendCancellableCoroutine 在项目协程版本里签名不对，改用 suspendCoroutine + resumeWith(Result)（pool10 fix 已证实）。
python3 << 'PYEOF39P14'
import os

def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/avbox/osc/ui/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
    assert os.path.exists("avbox/app/src/main/java/com/github/avbox/osc/ui/MusicHomeActivity.kt"), "find_root 失败"

def rep(src, old, new, name):
    assert src.count(old) == 1, "pool14 锚点 %s: %d" % (name, src.count(old))
    return src.replace(old, new, 1)

find_root()
PA = "avbox/app/src/main/java/com/github/avbox/osc/ui/LxPlayerActivity.kt"
a = open(PA, encoding="utf-8").read()
if "[39pool14]" in a:
    print("跳过（39 pool14 已应用）")
else:
    # 1) 在 LxEngineHolder 里加 getAllEngines()，统一返回主源+池源
    old = """    // [39pool10] 顺序遍历降级用协程作用域（不用 GlobalScope，不依赖外部生命周期）
    private val poolScope = kotlinx.coroutines.CoroutineScope(kotlinx.coroutines.Dispatchers.IO + kotlinx.coroutines.SupervisorJob())"""
    new = """    // [39pool10] 顺序遍历降级用协程作用域（不用 GlobalScope，不依赖外部生命周期）
    private val poolScope = kotlinx.coroutines.CoroutineScope(kotlinx.coroutines.Dispatchers.IO + kotlinx.coroutines.SupervisorJob())
    // [39pool14] 统一收集所有已启用引擎（主源+池源平级化，不分主从）
    private fun getAllEngines(): List<Pair<String, LxScriptEngine>> {
        val list = ArrayList<Pair<String, LxScriptEngine>>()
        val primary = engine
        if (primary != null && isReady && loadedSourceId != null) {
            list.add(loadedSourceId!! to primary)
        }
        for ((id, eng) in poolEngines) {
            if (id == loadedSourceId) continue
            list.add(id to eng)
        }
        return list
    }"""
    a = rep(a, old, new, "getAllEngines")
    # 2) 重构 resolveUrlWithFallback 为纯粹平级遍历（替换整个函数体）
    # pool14 fix3: 精确定位 resolveUrlWithFallback 函数体（按花括号配对，不碰其它函数）
    start = a.find("    suspend fun resolveUrlWithFallback(")
    assert start != -1, "pool14 锚点 resolveUrlWithFallback 起始未找到"
    # 从函数起始的花括号开始计数，找到配对的闭合花括号
    brace_start = a.find("{", start)
    assert brace_start != -1, "pool14 锚点 resolveUrlWithFallback 花括号未找到"
    depth = 0
    end = brace_start
    for i in range(brace_start, len(a)):
        if a[i] == "{":
            depth += 1
        elif a[i] == "}":
            depth -= 1
            if depth == 0:
                end = i + 1
                break
    assert depth == 0, "pool14 锚点 resolveUrlWithFallback 花括号不配对"
    # end 指向函数闭合花括号之后，包含其后的换行
    while end < len(a) and a[end] in "\n":
        end += 1
    old_func = a[start:end]
    new_func = """    // [39pool14] 纯粹平级遍历：废弃主源+备用池分层，所有已启用源平等；for 循环一个个试，哪个先出合法地址就用哪个
    suspend fun resolveUrlWithFallback(
        platform: String,
        musicInfo: Map<String, Any>,
        quality: String,
        excludedIds: Set<String> = emptySet()
    ): Pair<String, String> {
        // 1. 获取所有引擎并平级化
        val allEngines = getAllEngines()
        val targets = mutableListOf<Pair<String, LxScriptEngine>>()
        for ((id, eng) in allEngines) {
            if (id in excludedIds) continue
            if (isSourceCoolDown(id)) continue
            targets.add(id to eng)
        }
        // [39pool13] 全冷却时照常用：若过滤后为空，则不过滤冷却、全部源都进列表
        if (targets.isEmpty()) {
            for ((id, eng) in allEngines) {
                if (id in excludedIds) continue
                targets.add(id to eng)
            }
        }
        // 2. lastGood 排最前
        lastGoodSourceId?.let { good ->
            val idx = targets.indexOfFirst { it.first == good }
            if (idx > 0) {
                val p = targets.removeAt(idx)
                targets.add(0, p)
            }
        }
        // 【降级排查】看看池子里到底有几个活着的
        android.util.Log.d("LxPlayer", "【降级排查】可用源池数量: ${targets.size}，列表: ${targets.map { it.first }}")
        if (targets.isEmpty()) {
            throw IllegalStateException("没有可用音源")
        }
        var lastError: Throwable? = null
        // 3. 纯净遍历
        for ((sid, eng) in targets) {
            try {
                android.util.Log.d("LxPlayer", "【降级排查】开始尝试源: $sid")
                val url = kotlinx.coroutines.withTimeout(8000L) {
                    kotlin.coroutines.suspendCoroutine<String?> { cont ->
                        try {
                            eng.requestMusicUrl(platform, musicInfo, quality) { r ->
                                r.fold(
                                    onSuccess = { u -> cont.resumeWith(Result.success(u)) },
                                    onFailure = { e -> cont.resumeWith(Result.failure(e)) }
                                )
                            }
                        } catch (e: Exception) {
                            cont.resumeWith(Result.failure(e))
                        }
                    }
                }
                if (!url.isNullOrBlank()) {
                    lastGoodSourceId = sid
                    android.util.Log.d("LxPlayer", "【降级排查】源 $sid 解析成功！")
                    return sid to url
                } else {
                    android.util.Log.w("LxPlayer", "【降级排查】源 $sid 返回空地址，尝试下一个")
                }
            } catch (e: Exception) {
                android.util.Log.e("LxPlayer", "【降级排查】源 $sid 异常: ${e.message}", e)
                lastError = e
                markSourceCoolDown(sid)
                continue
            }
        }
        android.util.Log.e("LxPlayer", "【降级排查】所有源遍历完毕，彻底失败")
        throw IllegalStateException("所有音源均失效", lastError)
    }

"""
    a = a[:start] + new_func + a[end:]
    assert "[39pool14]" in a, "pool14 标记未落"
    open(PA, "w", encoding="utf-8").write(a)
    print("OK [39pool14] 彻底平级化完成")
PYEOF39P14
echo "=== 39 pool14 完成 ==="

# === 39 pool15: 探活整合进降级循环（用户确认）===
# 痛点：源返回非空死链（如裤佬 mcp kg.php 的 404 地址），循环见非空就立刻 return，播放器拿死链报 2004，不降级。
# 修法：resolveUrlWithFallback 拿到 URL 后先调 LxPlayerManager.isStreamUrlAlive(url) 探活，活了才 return，死了记冷却继续试下一个；全部日志改 LxRuntimeLog（进抽屉），不用 android.util.Log。
python3 << 'PYEOF39P15'
import os

def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/avbox/osc/ui/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
    assert os.path.exists("avbox/app/src/main/java/com/github/avbox/osc/ui/MusicHomeActivity.kt"), "find_root 失败"

def rep(src, old, new, name):
    assert src.count(old) == 1, "pool15 锚点 %s: %d" % (name, src.count(old))
    return src.replace(old, new, 1)

find_root()
PA = "avbox/app/src/main/java/com/github/avbox/osc/ui/LxPlayerActivity.kt"
a = open(PA, encoding="utf-8").read()
if "[39pool15]" in a:
    print("跳过（39 pool15 已应用）")
else:
    # 精确定位 resolveUrlWithFallback 函数体（按花括号配对，不碰其它函数）
    start = a.find("    suspend fun resolveUrlWithFallback(")
    assert start != -1, "pool15 锚点 resolveUrlWithFallback 起始未找到"
    brace_start = a.find("{", start)
    assert brace_start != -1, "pool15 锚点 resolveUrlWithFallback 花括号未找到"
    depth = 0
    end = brace_start
    for i in range(brace_start, len(a)):
        if a[i] == "{":
            depth += 1
        elif a[i] == "}":
            depth -= 1
            if depth == 0:
                end = i + 1
                break
    assert depth == 0, "pool15 锚点 resolveUrlWithFallback 花括号不配对"
    while end < len(a) and a[end] in "\n":
        end += 1
    old_func = a[start:end]
    # 新函数：探活整合 + 日志全改 LxRuntimeLog
    new_func = """    // [39pool15] 探活整合：拿到 URL 先探活，活了才 return，死了记冷却继续试下一个；日志全用 LxRuntimeLog（进抽屉）
    suspend fun resolveUrlWithFallback(
        platform: String,
        musicInfo: Map<String, Any>,
        quality: String,
        excludedIds: Set<String> = emptySet()
    ): Pair<String, String> {
        // 1. 获取所有引擎并平级化
        val allEngines = getAllEngines()
        val targets = mutableListOf<Pair<String, LxScriptEngine>>()
        for ((id, eng) in allEngines) {
            if (id in excludedIds) continue
            if (isSourceCoolDown(id)) continue
            targets.add(id to eng)
        }
        // [39pool13] 全冷却时照常用：若过滤后为空，则不过滤冷却、全部源都进列表
        if (targets.isEmpty()) {
            for ((id, eng) in allEngines) {
                if (id in excludedIds) continue
                targets.add(id to eng)
            }
        }
        // 2. lastGood 排最前
        lastGoodSourceId?.let { good ->
            val idx = targets.indexOfFirst { it.first == good }
            if (idx > 0) {
                val p = targets.removeAt(idx)
                targets.add(0, p)
            }
        }
        // 【降级排查】看看池子里到底有几个活着的
        LxRuntimeLog.add("【降级排查】可用源池数量: ${targets.size}，列表: ${targets.map { it.first }}")
        if (targets.isEmpty()) {
            throw IllegalStateException("没有可用音源")
        }
        var lastError: Throwable? = null
        // 3. 纯净遍历
        for ((sid, eng) in targets) {
            try {
                LxRuntimeLog.add("【降级排查】开始尝试源: $sid")
                val url = kotlinx.coroutines.withTimeout(8000L) {
                    kotlin.coroutines.suspendCoroutine<String?> { cont ->
                        try {
                            eng.requestMusicUrl(platform, musicInfo, quality) { r ->
                                r.fold(
                                    onSuccess = { u -> cont.resumeWith(Result.success(u)) },
                                    onFailure = { e -> cont.resumeWith(Result.failure(e)) }
                                )
                            }
                        } catch (e: Exception) {
                            cont.resumeWith(Result.failure(e))
                        }
                    }
                }
                if (!url.isNullOrBlank()) {
                    // 【降级排查】拿到链接后，立刻用探针测一下是不是活的
                    LxRuntimeLog.add("【降级排查】源 $sid 拿到地址，开始探活...")
                    val isAlive = try {
                        LxPlayerManager.isStreamUrlAlive(url)
                    } catch (e: Exception) {
                        false
                    }
                    if (isAlive) {
                        lastGoodSourceId = sid
                        LxRuntimeLog.add("【降级排查】源 $sid 探活成功，确定使用！")
                        return sid to url
                    } else {
                        LxRuntimeLog.add("【降级排查】源 $sid 探活失败（死链/防盗链），尝试下一个")
                        markSourceCoolDown(sid)
                    }
                } else {
                    LxRuntimeLog.add("【降级排查】源 $sid 返回空地址，尝试下一个")
                }
            } catch (e: Exception) {
                LxRuntimeLog.add("【降级排查】源 $sid 异常: ${e.message}")
                lastError = e
                markSourceCoolDown(sid)
                continue
            }
        }
        LxRuntimeLog.add("【降级排查】所有源遍历完毕，彻底失败")
        throw IllegalStateException("所有音源均失效", lastError)
    }

"""
    a = a[:start] + new_func + a[end:]
    assert "[39pool15]" in a, "pool15 标记未落"
    open(PA, "w", encoding="utf-8").write(a)
    print("OK [39pool15] 探活整合完成")
PYEOF39P15
echo "=== 39 pool15 完成 ==="

# === 39 pool16: 并发搜所有池源，各源用自己的方式搜，不共用主源 ID（用户确认）===
# 痛点：搜歌只走主源，返回的歌 ID 是主源平台的 ID，池子拿这个 ID 去问别的源，别的源查不到。删裤佬重进能播，就是因为主源变了，ID 对上了。
# 修法：LxEngineHolder 加 searchAllPoolSources(keyword)：同时调池子里所有源的 searchMusic（每个源的 JS 脚本用自己的方式搜），2 秒限时，返回合并结果。11 号脚本 LxScriptEngine 加 searchMusic 方法。
python3 << 'PYEOF39P16'
import os

def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/avbox/osc/ui/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
    assert os.path.exists("avbox/app/src/main/java/com/github/avbox/osc/ui/MusicHomeActivity.kt"), "find_root 失败"

def rep(src, old, new, name):
    assert src.count(old) == 1, "pool16 锚点 %s: %d" % (name, src.count(old))
    return src.replace(old, new, 1)

find_root()
PA = "avbox/app/src/main/java/com/github/avbox/osc/ui/LxPlayerActivity.kt"
a = open(PA, encoding="utf-8").read()
# [39pool16] 补协程 import（async/awaitAll/coroutineScope 需 import 才能用）
if "import kotlinx.coroutines.async" not in a:
    a = a.replace("import kotlinx.coroutines.withContext", "import kotlinx.coroutines.withContext\nimport kotlinx.coroutines.async\nimport kotlinx.coroutines.awaitAll\nimport kotlinx.coroutines.coroutineScope", 1)
if "[39pool16]" in a:
    print("跳过（39 pool16 已应用）")
else:
    # 在 resolveUrlWithFallback 函数后插入 searchAllPoolSources
    start = a.find("    suspend fun resolveUrlWithFallback(")
    assert start != -1, "pool16 锚点 resolveUrlWithFallback 起始未找到"
    brace_start = a.find("{", start)
    depth = 0
    end = brace_start
    for i in range(brace_start, len(a)):
        if a[i] == "{":
            depth += 1
        elif a[i] == "}":
            depth -= 1
            if depth == 0:
                end = i + 1
                break
    assert depth == 0, "pool16 锚点 resolveUrlWithFallback 花括号不配对"
    new_func = '''
    // [39pool16] 并发搜所有池源：每个源用自己的方式搜，不共用主源 ID
    suspend fun searchAllPoolSources(keyword: String): List<Map<String, Any>> = withContext(Dispatchers.IO) {
        if (keyword.isBlank()) return@withContext emptyList()
        val engines = getAllEngines().map { it.second }
        if (engines.isEmpty()) return@withContext emptyList()
        try {
            kotlinx.coroutines.withTimeout(2000L) {
                kotlinx.coroutines.coroutineScope {
                    val jobs = engines.map { eng ->
                        async {
                            try {
                                searchOnEngine(eng, keyword)
                            } catch (e: Exception) {
                                try { LxRuntimeLog.add("【并发搜】源搜索失败: " + e.message) } catch (_: Exception) {}
                                emptyList<Map<String, Any>>()
                            }
                        }
                    }
                    jobs.awaitAll().flatten()
                }
            }
        } catch (e: Exception) {
            try { LxRuntimeLog.add("【并发搜】搜索超时，返回已完成结果") } catch (_: Exception) {}
            emptyList()
        }
    }

    // [39pool16] 在单个引擎上搜歌
    private suspend fun searchOnEngine(eng: LxScriptEngine, keyword: String): List<Map<String, Any>> {
        return kotlin.coroutines.suspendCoroutine { cont ->
            try {
                eng.searchMusic(keyword) { result ->
                    result.fold(
                        onSuccess = { list -> cont.resumeWith(Result.success(list)) },
                        onFailure = { e -> cont.resumeWith(Result.success(emptyList<Map<String, Any>>())) }
                    )
                }
            } catch (e: Exception) {
                cont.resumeWith(Result.success(emptyList<Map<String, Any>>()))
            }
        }
    }
'''
    a = a[:end] + "\n" + new_func + a[end:]
    assert "[39pool16]" in a, "pool16 标记未落"
    open(PA, "w", encoding="utf-8").write(a)
    print("OK [39pool16] 并发搜所有池源完成")
PYEOF39P16
echo "=== 39 pool16 完成 ==="

# === 39 pool17: 内置平台 ID 转池源搜索（用户确认）===
# 痛点：搜歌手名（周杰伦）出来的结果是内置平台的歌，带网易 ID 400581054；点它时池子拿网易 ID 去问裤佬/杰翔，mcp 回 301、cenguigui 超时、music.163 回 302，全被 v168 探活拦了。搜歌名能播是因为池源直接返回了它自己能用的 ID。
# 修法：resolveUrlWithFallback 开头，若 platform 是内置平台（kugou/qq/netease/kuwo/migu/wy/kg/tx/mg），先调 searchAllPoolSources 按歌名搜一遍，拿到池源自己的 ID 就用池源的 ID；搜不到才回退用原 ID。
python3 << 'PYEOF17'
import os

def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/avbox/osc/ui/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
    assert os.path.exists("avbox/app/src/main/java/com/github/avbox/osc/ui/MusicHomeActivity.kt"), "find_root 失败"

def rep(src, old, new, name):
    assert src.count(old) == 1, "pool17 锚点 %s: %d" % (name, src.count(old))
    return src.replace(old, new, 1)

find_root()
M = "avbox/app/src/main/java/com/github/avbox/osc/ui/LxPlayerActivity.kt"
s = open(M, encoding="utf-8").read()
if "[39pool17]" in s:
    print("跳过（39 pool17 已应用）")
else:
    old = """    suspend fun resolveUrlWithFallback(
        platform: String,
        musicInfo: Map<String, Any>,
        quality: String,
        excludedIds: Set<String> = emptySet()
    ): Pair<String, String> {
        // 1. 获取所有引擎并平级化
        val allEngines = getAllEngines()"""
    new = """    suspend fun resolveUrlWithFallback(
        platform: String,
        musicInfo: Map<String, Any>,
        quality: String,
        excludedIds: Set<String> = emptySet()
    ): Pair<String, String> {
        // 1. 获取所有引擎并平级化
        val allEngines = getAllEngines()
        // [39pool17] 内置平台 ID 转池源搜索：内置平台（网易/酷狗/QQ 等）的 ID 池源用不了，先按歌名搜池源拿池源自己的 ID
        var effPlatform = platform
        var effInfo = musicInfo
        val builtin = setOf("kugou", "kg", "qq", "tx", "netease", "wy", "kuwo", "kw", "migu", "mg", "bilibili", "bd", "xiaomi", "xm")
        if (platform.lowercase() in builtin) {
            val title = (musicInfo["title"] as? String)?.takeIf { it.isNotBlank() }
            if (title != null) {
                try {
                    val poolHits = searchAllPoolSources(title)
                    val hit = poolHits.firstOrNull { (it["title"] as? String)?.isNotBlank() == true }
                    if (hit != null) {
                        effInfo = musicInfo.toMutableMap().apply {
                            put("songId", (hit["id"] ?: hit["songmid"] ?: musicInfo["songId"] ?: "").toString())
                            put("id", (hit["id"] ?: hit["songmid"] ?: "").toString())
                        }
                        effPlatform = (hit["platform"] as? String)?.takeIf { it.isNotBlank() } ?: platform
                        try { com.github.avbox.osc.util.LxRuntimeLog.add("内置ID转池源: " + title + " -> " + effPlatform + " " + (effInfo["songId"] ?: "")) } catch (_: Exception) { }
                    }
                } catch (_: Exception) { }
            }
        }"""
    s = rep(s, old, new, "内置ID转池源")
    # Replace platform/musicInfo with effPlatform/effInfo in the requestMusicUrl calls within this function
    # Find the function and replace the calls
    func_start = s.find("    suspend fun resolveUrlWithFallback(")
    func_end = s.find(chr(10) + "    fun ", func_start + 100)
    if func_end == -1:
        func_end = len(s)
    func_text = s[func_start:func_end]
    # Replace the requestMusicUrl calls
    func_text = func_text.replace("eng.requestMusicUrl(platform, musicInfo, quality)", "eng.requestMusicUrl(effPlatform, effInfo, quality)")
    s = s[:func_start] + func_text + s[func_end:]
    assert "[39pool17]" in s, "pool17 标记未落"
    open(M, "w", encoding="utf-8").write(s)
    print("OK 39 pool17 内置平台 ID 转池源搜索完成")
PYEOF17
echo "=== 39 pool17 完成 ==="

# === 39 pool18: 池子并行探活（用户确认，优化 C）===
# 痛点：切歌慢。resolveUrlWithFallback 顺序遍历，一个源探活失败要等 8 秒超时才试下一个。
# 修法：改成并行探活，几个源同时拿地址+探活，哪个先活就用哪个，不用等一个失败再试下一个。用 coroutineScope + async 并行，awaitAll 等全部完成取第一个成功的。
python3 << 'PYEOF18'
import os

def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/avbox/osc/ui/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
    assert os.path.exists("avbox/app/src/main/java/com/github/avbox/osc/ui/MusicHomeActivity.kt"), "find_root 失败"

find_root()
M = "avbox/app/src/main/java/com/github/avbox/osc/ui/LxPlayerActivity.kt"
s = open(M, encoding="utf-8").read()
if "[39pool18]" in s:
    print("跳过（39 pool18 已应用）")
else:
    # Find resolveUrlWithFallback and replace the sequential loop with parallel
    start_marker = "    // [39pool15] 探活整合"
    start = s.find(start_marker)
    assert start != -1, "pool18 锚点：函数头未找到"
    brace_start = s.find("{", s.find("fun resolveUrlWithFallback", start))
    assert brace_start != -1, "pool18 锚点：函数左括号未找到"
    depth = 0
    i = brace_start
    while i < len(s):
        if s[i] == '{':
            depth += 1
        elif s[i] == '}':
            depth -= 1
            if depth == 0:
                break
        i += 1
    assert depth == 0, "pool18 锚点：括号不平衡"
    func_end = i + 1
    old_func = s[start:func_end]
    # Replace the sequential for loop with parallel version
    # The old loop is: var lastError... for ((sid, eng) in targets) { try { ... } }
    # We need to replace it with parallel async
    old_loop_start = old_func.find("        var lastError: Throwable? = null")
    assert old_loop_start != -1, "pool18 锚点：循环起始未找到"
    old_loop = old_func[old_loop_start:]
    # The loop ends with "throw IllegalStateException"
    new_loop = """        var lastError: Throwable? = null
        // [39pool18] 并行探活：几个源同时拿地址+探活，哪个先活就用哪个
        val results = kotlinx.coroutines.coroutineScope {
            val scope = this
            targets.map { (sid, eng) ->
                scope.async {
                    try {
                        LxRuntimeLog.add("【降级排查】开始尝试源: $sid")
                        val url = kotlinx.coroutines.withTimeout(8000L) {
                            kotlin.coroutines.suspendCoroutine<String?> { cont ->
                                try {
                                    eng.requestMusicUrl(effPlatform, effInfo, quality) { r ->
                                        r.fold(
                                            onSuccess = { u -> cont.resumeWith(Result.success(u)) },
                                            onFailure = { e -> cont.resumeWith(Result.failure(e)) }
                                        )
                                    }
                                } catch (e: Exception) {
                                    cont.resumeWith(Result.failure(e))
                                }
                            }
                        }
                        if (!url.isNullOrBlank()) {
                            LxRuntimeLog.add("【降级排查】源 $sid 拿到地址，开始探活...")
                            val isAlive = try {
                                LxPlayerManager.isStreamUrlAlive(url)
                            } catch (e: Exception) {
                                false
                            }
                            if (isAlive) {
                                LxRuntimeLog.add("【降级排查】源 $sid 探活成功，确定使用！")
                                sid to url
                            } else {
                                LxRuntimeLog.add("【降级排查】源 $sid 探活失败（死链/防盗链），尝试下一个")
                                markSourceCoolDown(sid)
                                null
                            }
                        } else {
                            null
                        }
                    } catch (e: Exception) {
                        lastError = e
                        markSourceCoolDown(sid)
                        null
                    }
                }
            }.mapNotNull { it.await() }.firstOrNull()
        }
        if (results != null) {
            lastGoodSourceId = results.first
            return results
        }
        throw IllegalStateException("所有音源均失效", lastError)
    }"""
    new_func = old_func[:old_loop_start] + new_loop
    # Update the function header comment to include pool18
    new_func = new_func.replace("[39pool15] 探活整合", "[39pool15] 探活整合；[39pool18] 并行探活", 1)
    s = s[:start] + new_func + s[func_end:]
    assert "[39pool18]" in s, "pool18 标记未落"
    open(M, "w", encoding="utf-8").write(s)
    print("OK 39 pool18 池子并行探活完成")
PYEOF18
echo "=== 39 pool18 完成 ==="

# === 39pool19: ID 映射缓存（重写版，用户确认执行）===
# 修法：内存版 ConcurrentHashMap，不用 SharedPreferences，不用 Context
# 转义：Kotlin 字符串引号一律用 chr(34) 替代，杜绝 " 猜转义
# 锚点：用 .replace(old, new, 1) 只替换第一次
python3 << 'PYEOF19'
import os

def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/avbox/osc/ui/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
    assert os.path.exists("avbox/app/src/main/java/com/github/avbox/osc/ui/MusicHomeActivity.kt"), "find_root 失败"

def rep(src, old, new, name):
    assert src.count(old) == 1, "pool19 锚点 %s: %d" % (name, src.count(old))
    return src.replace(old, new, 1)

find_root()
M = "avbox/app/src/main/java/com/github/avbox/osc/ui/LxPlayerActivity.kt"
s = open(M, encoding="utf-8").read()
if "[39pool19]" in s:
    print("跳过（39pool19 已应用）")
else:
    Q = chr(34)
    # 1. 在 lastGoodSourceId 后加 ID 映射缓存函数（内存版）
    old = "    var lastGoodSourceId: String? = null" + chr(10) + "        private set"
    # 用 chr(34) 拼 Kotlin 字符串，杜绝转义猜测
    new = old + chr(10)
    new += "    // [39pool19] ID 映射缓存：内存版，Key=源平台_目标平台_原ID，Value=目标ID|时间戳，7 天过期，上限 500 条" + chr(10)
    new += "    private const val ID_MAP_EXPIRE_MS = 7 * 24 * 60 * 60 * 1000L" + chr(10)
    new += "    private const val ID_MAP_MAX = 500" + chr(10)
    new += "    private val idMapCache = java.util.concurrent.ConcurrentHashMap<String, String>()" + chr(10)
    new += "    fun lookupIdMap(srcPlatform: String, dstPlatform: String, srcId: String): String? {" + chr(10)
    new += "        return try {" + chr(10)
    new += "            val key = srcPlatform.lowercase() + " + Q + "_" + Q + " + dstPlatform.lowercase() + " + Q + "_" + Q + " + srcId" + chr(10)
    new += "            val v = idMapCache[key] ?: return null" + chr(10)
    new += "            val parts = v.split(" + Q + "|" + Q + ")" + chr(10)
    new += "            if (parts.size != 2) { idMapCache.remove(key); return null }" + chr(10)
    new += "            val ts = parts[1].toLongOrNull() ?: 0L" + chr(10)
    new += "            if (System.currentTimeMillis() - ts > ID_MAP_EXPIRE_MS) { idMapCache.remove(key); return null }" + chr(10)
    new += "            parts[0].takeIf { it.isNotBlank() }" + chr(10)
    new += "        } catch (_: Exception) { null }" + chr(10)
    new += "    }" + chr(10)
    new += "    fun saveIdMap(srcPlatform: String, dstPlatform: String, srcId: String, dstId: String) {" + chr(10)
    new += "        try {" + chr(10)
    new += "            val key = srcPlatform.lowercase() + " + Q + "_" + Q + " + dstPlatform.lowercase() + " + Q + "_" + Q + " + srcId" + chr(10)
    new += "            val v = dstId + " + Q + "|" + Q + " + System.currentTimeMillis().toString()" + chr(10)
    new += "            if (idMapCache.size >= ID_MAP_MAX && !idMapCache.containsKey(key)) {" + chr(10)
    new += "                val oldestKey: String? = try {" + chr(10)
    new += "                    var oldest: String? = null" + chr(10)
    new += "                    var oldestTs = Long.MAX_VALUE" + chr(10)
    new += "                    for ((k, vv) in idMapCache) {" + chr(10)
    new += "                        val t = vv.split(" + Q + "|" + Q + ").getOrNull(1)?.toLongOrNull() ?: 0L" + chr(10)
    new += "                        if (t < oldestTs) { oldestTs = t; oldest = k }" + chr(10)
    new += "                    }" + chr(10)
    new += "                    oldest" + chr(10)
    new += "                } catch (_: Exception) { null }" + chr(10)
    new += "                if (oldestKey != null) idMapCache.remove(oldestKey)" + chr(10)
    new += "            }" + chr(10)
    new += "            idMapCache[key] = v" + chr(10)
    new += "        } catch (_: Exception) { }" + chr(10)
    new += "    }" + chr(10)
    new += "    fun deleteIdMap(srcPlatform: String, dstPlatform: String, srcId: String) {" + chr(10)
    new += "        try {" + chr(10)
    new += "            val key = srcPlatform.lowercase() + " + Q + "_" + Q + " + dstPlatform.lowercase() + " + Q + "_" + Q + " + srcId" + chr(10)
    new += "            idMapCache.remove(key)" + chr(10)
    new += "        } catch (_: Exception) { }" + chr(10)
    new += "    }"
    s = rep(s, old, new, "缓存函数")
    assert "[39pool19]" in s, "pool19 标记未落"
    open(M, "w", encoding="utf-8").write(s)
    print("OK 39pool19 ID 映射缓存完成")
    # 自检：打印插入后的 Kotlin 片段（15 行）
    print("=== 自检：插入后的 Kotlin 片段 ===")
    idx = s.find("[39pool19]")
    print(s[idx-200:idx+800])
    # 自检：大括号平衡
    open_b = s.count("{")
    close_b = s.count("}")
    print(f"=== 自检：大括号平衡 Open={open_b} Close={close_b} Diff={open_b-close_b} ===")
    assert open_b == close_b, "大括号不平衡！"
PYEOF19
echo "=== 39pool19 完成 ==="
# === 39pool20: 全场景秒播（原生直出 + 后台异步建映射）（用户确认执行）===
# 痛点：搜结果/新列表点歌，未命中 pool19 缓存时走 pool17 按名搜（2 秒）+ 探活才起播。
# 修法：1) pool19 改 key（源平台_原ID，值=目标平台|目标ID|时间戳），进来先查缓存；2) 未命中走原生快路径（原平台+原 ID 并行取址，先到先得，不探活）+ poolScope.launch 后台搜 ID 写缓存；3) 缓存 ID 失效重搜不一致才删。
# 死要求：1) 空链接绝不 complete（isNullOrBlank 判断）；2) 后台双重匹配（歌名归一化剥后缀 + 歌手），宁可不缓存；3) 后台任务只捕获不可变字符串，在途集合去重 + 上限 8，finally 释放。
python3 << 'PYEOF20'
import os

def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/avbox/osc/ui/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
    assert os.path.exists("avbox/app/src/main/java/com/github/avbox/osc/ui/MusicHomeActivity.kt"), "find_root 失败"

def rep(src, old, new, name):
    assert src.count(old) == 1, "pool20 锚点 %s: %d" % (name, src.count(old))
    return src.replace(old, new, 1)

def brace_match_end(s, brace_start):
    depth = 0
    for i in range(brace_start, len(s)):
        if s[i] == "{":
            depth += 1
        elif s[i] == "}":
            depth -= 1
            if depth == 0:
                return i + 1
    assert False, "pool20 花括号不配对"

find_root()
M = "avbox/app/src/main/java/com/github/avbox/osc/ui/LxPlayerActivity.kt"
s = open(M, encoding="utf-8").read()
if "[39pool20]" in s:
    print("跳过（39 pool20 已应用）")
else:
    Q = chr(34)
    LB = chr(12304)
    RB = chr(12305)
    DL = chr(36)
    # 0) 前置断言：新名字在文件里不存在，防重名冲突
    for nm in ["raceNativeUrl", "launchBackgroundIdSearch", "bgSearchInFlight", "normTitle", "titleMatches", "singerMatches", "hitTitleOf", "hitArtistOf", "hitPlatformOf", "hitIdOf"]:
        assert nm not in s, "pool20 名字冲突: " + nm
    # 1) pool19 改 key：Key=源平台_原ID，Value=目标平台|目标ID|时间戳；lookup 返回 Pair(目标平台, 目标ID)
    start19 = s.find("    // [39pool19] ID 映射缓存")
    assert start19 != -1, "pool20 锚点 pool19 起始未找到"
    end19 = s.find("    // [39pool6] 坏源冷却", start19)
    assert end19 != -1, "pool20 锚点 pool19 结束未找到"
    old19 = s[start19:end19]
    assert old19.count("fun lookupIdMap") == 1, "pool20 pool19 lookup 数量异常"
    assert old19.count("fun saveIdMap") == 1, "pool20 pool19 save 数量异常"
    assert old19.count("fun deleteIdMap") == 1, "pool20 pool19 delete 数量异常"
    assert old19.count("{") == old19.count("}"), "pool20 pool19 括号不平衡"
    new19 = ""
    new19 += "    // [39pool19][39pool20] ID 映射缓存：内存版，Key=源平台_原ID，Value=目标平台|目标ID|时间戳，7 天过期，上限 500 条" + chr(10)
    new19 += "    private const val ID_MAP_EXPIRE_MS = 7 * 24 * 60 * 60 * 1000L" + chr(10)
    new19 += "    private const val ID_MAP_MAX = 500" + chr(10)
    new19 += "    private val idMapCache = java.util.concurrent.ConcurrentHashMap<String, String>()" + chr(10)
    new19 += "    fun lookupIdMap(srcPlatform: String, srcId: String): Pair<String, String>? {" + chr(10)
    new19 += "        return try {" + chr(10)
    new19 += "            val key = srcPlatform.lowercase() + " + Q + "_" + Q + " + srcId" + chr(10)
    new19 += "            val v = idMapCache[key] ?: return null" + chr(10)
    new19 += "            val parts = v.split(" + Q + "|" + Q + ")" + chr(10)
    new19 += "            if (parts.size != 3) { idMapCache.remove(key); return null }" + chr(10)
    new19 += "            val ts = parts[2].toLongOrNull() ?: 0L" + chr(10)
    new19 += "            if (System.currentTimeMillis() - ts > ID_MAP_EXPIRE_MS) { idMapCache.remove(key); return null }" + chr(10)
    new19 += "            val dp = parts[0].takeIf { it.isNotBlank() } ?: return null" + chr(10)
    new19 += "            val di = parts[1].takeIf { it.isNotBlank() } ?: return null" + chr(10)
    new19 += "            dp to di" + chr(10)
    new19 += "        } catch (_: Exception) { null }" + chr(10)
    new19 += "    }" + chr(10)
    new19 += "    fun saveIdMap(srcPlatform: String, dstPlatform: String, srcId: String, dstId: String) {" + chr(10)
    new19 += "        try {" + chr(10)
    new19 += "            val key = srcPlatform.lowercase() + " + Q + "_" + Q + " + srcId" + chr(10)
    new19 += "            val v = dstPlatform.lowercase() + " + Q + "|" + Q + " + dstId + " + Q + "|" + Q + " + System.currentTimeMillis().toString()" + chr(10)
    new19 += "            if (idMapCache.size >= ID_MAP_MAX && !idMapCache.containsKey(key)) {" + chr(10)
    new19 += "                val oldestKey: String? = try {" + chr(10)
    new19 += "                    var oldest: String? = null" + chr(10)
    new19 += "                    var oldestTs = Long.MAX_VALUE" + chr(10)
    new19 += "                    for ((k, vv) in idMapCache) {" + chr(10)
    new19 += "                        val t = vv.split(" + Q + "|" + Q + ").getOrNull(2)?.toLongOrNull() ?: 0L" + chr(10)
    new19 += "                        if (t < oldestTs) { oldestTs = t; oldest = k }" + chr(10)
    new19 += "                    }" + chr(10)
    new19 += "                    oldest" + chr(10)
    new19 += "                } catch (_: Exception) { null }" + chr(10)
    new19 += "                if (oldestKey != null) idMapCache.remove(oldestKey)" + chr(10)
    new19 += "            }" + chr(10)
    new19 += "            idMapCache[key] = v" + chr(10)
    new19 += "        } catch (_: Exception) { }" + chr(10)
    new19 += "    }" + chr(10)
    new19 += "    fun deleteIdMap(srcPlatform: String, srcId: String) {" + chr(10)
    new19 += "        try {" + chr(10)
    new19 += "            val key = srcPlatform.lowercase() + " + Q + "_" + Q + " + srcId" + chr(10)
    new19 += "            idMapCache.remove(key)" + chr(10)
    new19 += "        } catch (_: Exception) { }" + chr(10)
    new19 += "    }" + chr(10)
    s = s[:start19] + new19 + s[end19:]
    # 2) resolveUrlWithFallback 整体替换（按签名 + 花括号配对定位，不动其它函数）
    start_marker = "    // [39pool15] 探活整合；[39pool18] 并行探活"
    start = s.find(start_marker)
    assert start != -1, "pool20 锚点 函数头未找到"
    assert s.count(start_marker) == 1, "pool20 锚点 函数头数量异常"
    sig = s.find("    suspend fun resolveUrlWithFallback(", start)
    assert sig != -1, "pool20 锚点 函数签名未找到"
    brace_start = s.find("{", sig)
    assert brace_start != -1, "pool20 锚点 函数左括号未找到"
    func_end = brace_match_end(s, brace_start)
    while func_end < len(s) and s[func_end] in "\n":
        func_end += 1
    new_func = ""
    new_func += "    // [39pool15] 探活整合；[39pool18] 并行探活；[39pool20] 全场景秒播：缓存先查、原生直出先到先得、后台建映射" + chr(10)
    new_func += "    suspend fun resolveUrlWithFallback(" + chr(10)
    new_func += "        platform: String," + chr(10)
    new_func += "        musicInfo: Map<String, Any>," + chr(10)
    new_func += "        quality: String," + chr(10)
    new_func += "        excludedIds: Set<String> = emptySet()" + chr(10)
    new_func += "    ): Pair<String, String> {" + chr(10)
    new_func += "        // 1. 获取所有引擎并平级化" + chr(10)
    new_func += "        val allEngines = getAllEngines()" + chr(10)
    new_func += "        var effPlatform = platform" + chr(10)
    new_func += "        var effInfo = musicInfo" + chr(10)
    new_func += "        val builtin = setOf(" + Q + "kugou" + Q + ", " + Q + "kg" + Q + ", " + Q + "qq" + Q + ", " + Q + "tx" + Q + ", " + Q + "netease" + Q + ", " + Q + "wy" + Q + ", " + Q + "kuwo" + Q + ", " + Q + "kw" + Q + ", " + Q + "migu" + Q + ", " + Q + "mg" + Q + ", " + Q + "bilibili" + Q + ", " + Q + "bd" + Q + ", " + Q + "xiaomi" + Q + ", " + Q + "xm" + Q + ")" + chr(10)
    new_func += "        val isBuiltin = platform.lowercase() in builtin" + chr(10)
    new_func += "        val songId = (musicInfo[" + Q + "songId" + Q + "]?.toString()?.takeIf { it.isNotBlank() } ?: musicInfo[" + Q + "id" + Q + "]?.toString()?.takeIf { it.isNotBlank() }) ?: " + Q + Q + chr(10)
    new_func += "        val songTitle = (musicInfo[" + Q + "title" + Q + "]?.toString())?.takeIf { it.isNotBlank() } ?: " + Q + Q + chr(10)
    new_func += "        val songArtist = ((musicInfo[" + Q + "artist" + Q + "] ?: musicInfo[" + Q + "singer" + Q + "])?.toString())?.takeIf { it.isNotBlank() } ?: " + Q + Q + chr(10)
    new_func += "        var usedCache = false" + chr(10)
    new_func += "        // [39pool20] 1. 先查 ID 映射缓存（改 key 后：源平台_原ID）：命中直接用缓存 ID 走探活循环，跳过 2 秒搜索" + chr(10)
    new_func += "        if (isBuiltin && songId.isNotBlank()) {" + chr(10)
    new_func += "            val cached = lookupIdMap(platform, songId)" + chr(10)
    new_func += "            if (cached != null) {" + chr(10)
    new_func += "                effPlatform = cached.first" + chr(10)
    new_func += "                effInfo = musicInfo.toMutableMap().apply {" + chr(10)
    new_func += "                    put(" + Q + "songId" + Q + ", cached.second)" + chr(10)
    new_func += "                    put(" + Q + "id" + Q + ", cached.second)" + chr(10)
    new_func += "                }" + chr(10)
    new_func += "                usedCache = true" + chr(10)
    new_func += "                try { LxRuntimeLog.add(" + Q + "ID映射缓存命中: " + Q + " + songTitle + " + Q + " -> " + Q + " + effPlatform + " + Q + " " + Q + " + cached.second) } catch (_: Exception) { }" + chr(10)
    new_func += "            }" + chr(10)
    new_func += "        }" + chr(10)
    new_func += "        val targets = mutableListOf<Pair<String, LxScriptEngine>>()" + chr(10)
    new_func += "        for ((id, eng) in allEngines) {" + chr(10)
    new_func += "            if (id in excludedIds) continue" + chr(10)
    new_func += "            if (isSourceCoolDown(id)) continue" + chr(10)
    new_func += "            targets.add(id to eng)" + chr(10)
    new_func += "        }" + chr(10)
    new_func += "        // [39pool13] 全冷却时照常用：若过滤后为空，则不过滤冷却、全部源都进列表" + chr(10)
    new_func += "        if (targets.isEmpty()) {" + chr(10)
    new_func += "            for ((id, eng) in allEngines) {" + chr(10)
    new_func += "                if (id in excludedIds) continue" + chr(10)
    new_func += "                targets.add(id to eng)" + chr(10)
    new_func += "            }" + chr(10)
    new_func += "        }" + chr(10)
    new_func += "        // 2. lastGood 排最前" + chr(10)
    new_func += "        lastGoodSourceId?.let { good ->" + chr(10)
    new_func += "            val idx = targets.indexOfFirst { it.first == good }" + chr(10)
    new_func += "            if (idx > 0) {" + chr(10)
    new_func += "                val p = targets.removeAt(idx)" + chr(10)
    new_func += "                targets.add(0, p)" + chr(10)
    new_func += "            }" + chr(10)
    new_func += "        }" + chr(10)
    new_func += "        // " + LB + "降级排查" + RB + "看看池子里到底有几个活着的" + chr(10)
    new_func += "        LxRuntimeLog.add(" + Q + LB + "降级排查" + RB + "可用源池数量: " + DL + "{targets.size}，列表: " + DL + "{targets.map { it.first }}" + Q + ")" + chr(10)
    new_func += "        if (targets.isEmpty()) {" + chr(10)
    new_func += "            throw IllegalStateException(" + Q + "没有可用音源" + Q + ")" + chr(10)
    new_func += "        }" + chr(10)
    new_func += "        // [39pool20] 2. 未命中缓存：原生快路径——原平台+原 ID 并行取址，先到先得，快探后播；同时后台建映射" + chr(10)
    new_func += "        if (isBuiltin && !usedCache && songId.isNotBlank()) {" + chr(10)
    new_func += "            val native = raceNativeUrl(targets, platform, musicInfo, quality)" + chr(10)
    new_func += "            if (native != null && native.second.isNotBlank()) {" + chr(10)
    new_func += "                // [39pool20] 原生地址先快探：11-08 教训，网易 ID 直出的地址可能是 301/慢链，不验就播会卡；探活不过不播，落到 pool17 搜池源 ID" + chr(10)
    new_func += "                val nativeAlive = try { LxPlayerManager.isStreamUrlAlive(native.second) } catch (_: Exception) { false }" + chr(10)
    new_func += "                if (nativeAlive) {" + chr(10)
    new_func += "                    lastGoodSourceId = native.first" + chr(10)
    new_func += "                    try { LxRuntimeLog.add(" + Q + "原生直出: " + Q + " + songTitle + " + Q + " <- " + Q + " + native.first) } catch (_: Exception) { }" + chr(10)
    new_func += "                    launchBackgroundIdSearch(platform, songId, songTitle, songArtist)" + chr(10)
    new_func += "                    return native" + chr(10)
    new_func += "                }" + chr(10)
    new_func += "                try { LxRuntimeLog.add(" + Q + "原生直出探活失败，落到池源搜索: " + Q + " + songTitle + " + Q + " <- " + Q + " + native.first) } catch (_: Exception) { }" + chr(10)
    new_func += "            }" + chr(10)
    new_func += "            // 原生快路径没拿到地址或探活失败：后台建映射照常跑（下次点直接命中），再走 pool17 搜索 + 探活循环" + chr(10)
    new_func += "            launchBackgroundIdSearch(platform, songId, songTitle, songArtist)" + chr(10)
    new_func += "        }" + chr(10)
    new_func += "        // [39pool17] 内置平台 ID 转池源搜索：内置平台（网易/酷狗/QQ 等）的 ID 池源用不了，先按歌名搜池源拿池源自己的 ID" + chr(10)
    new_func += "        if (isBuiltin && !usedCache && songTitle.isNotBlank()) {" + chr(10)
    new_func += "            try {" + chr(10)
    new_func += "                val poolHits = searchAllPoolSources(songTitle)" + chr(10)
    new_func += "                val hit = poolHits.firstOrNull { hitTitleOf(it).isNotBlank() }" + chr(10)
    new_func += "                if (hit != null) {" + chr(10)
    new_func += "                    effInfo = musicInfo.toMutableMap().apply {" + chr(10)
    new_func += "                        put(" + Q + "songId" + Q + ", hitIdOf(hit) ?: musicInfo[" + Q + "songId" + Q + "]?.toString() ?: " + Q + Q + ")" + chr(10)
    new_func += "                        put(" + Q + "id" + Q + ", hitIdOf(hit) ?: " + Q + Q + ")" + chr(10)
    new_func += "                    }" + chr(10)
    new_func += "                    effPlatform = hitPlatformOf(hit) ?: platform" + chr(10)
    new_func += "                    val hid = hitIdOf(hit)" + chr(10)
    new_func += "                    if (!hid.isNullOrBlank() && songId.isNotBlank()) {" + chr(10)
    new_func += "                        try { saveIdMap(platform, effPlatform, songId, hid) } catch (_: Exception) { }" + chr(10)
    new_func += "                    }" + chr(10)
    new_func += "                    try { com.github.avbox.osc.util.LxRuntimeLog.add(" + Q + "内置ID转池源: " + Q + " + songTitle + " + Q + " -> " + Q + " + effPlatform + " + Q + " " + Q + " + (effInfo[" + Q + "songId" + Q + "] ?: " + Q + Q + ")) } catch (_: Exception) { }" + chr(10)
    new_func += "                }" + chr(10)
    new_func += "            } catch (_: Exception) { }" + chr(10)
    new_func += "        }" + chr(10)
    new_func += "        var lastError: Throwable? = null" + chr(10)
    new_func += "        // [39pool18] 并行探活：几个源同时拿地址+探活，哪个先活就用哪个" + chr(10)
    new_func += "        val results = kotlinx.coroutines.coroutineScope {" + chr(10)
    new_func += "            val scope = this" + chr(10)
    new_func += "            targets.map { (sid, eng) ->" + chr(10)
    new_func += "                scope.async {" + chr(10)
    new_func += "                    try {" + chr(10)
    new_func += "                        LxRuntimeLog.add(" + Q + LB + "降级排查" + RB + "开始尝试源: " + DL + "sid" + Q + ")" + chr(10)
    new_func += "                        val url = kotlinx.coroutines.withTimeout(8000L) {" + chr(10)
    new_func += "                            kotlin.coroutines.suspendCoroutine<String?> { cont ->" + chr(10)
    new_func += "                                try {" + chr(10)
    new_func += "                                    eng.requestMusicUrl(effPlatform, effInfo, quality) { r ->" + chr(10)
    new_func += "                                        r.fold(" + chr(10)
    new_func += "                                            onSuccess = { u -> cont.resumeWith(Result.success(u)) }," + chr(10)
    new_func += "                                            onFailure = { e -> cont.resumeWith(Result.failure(e)) }" + chr(10)
    new_func += "                                        )" + chr(10)
    new_func += "                                    }" + chr(10)
    new_func += "                                } catch (e: Exception) {" + chr(10)
    new_func += "                                    cont.resumeWith(Result.failure(e))" + chr(10)
    new_func += "                                }" + chr(10)
    new_func += "                            }" + chr(10)
    new_func += "                        }" + chr(10)
    new_func += "                        if (!url.isNullOrBlank()) {" + chr(10)
    new_func += "                            LxRuntimeLog.add(" + Q + LB + "降级排查" + RB + "源 " + DL + "sid" + " 拿到地址，开始探活..." + Q + ")" + chr(10)
    new_func += "                            val isAlive = try {" + chr(10)
    new_func += "                                LxPlayerManager.isStreamUrlAlive(url)" + chr(10)
    new_func += "                            } catch (e: Exception) {" + chr(10)
    new_func += "                                false" + chr(10)
    new_func += "                            }" + chr(10)
    new_func += "                            if (isAlive) {" + chr(10)
    new_func += "                                LxRuntimeLog.add(" + Q + LB + "降级排查" + RB + "源 " + DL + "sid" + " 探活成功，确定使用！" + Q + ")" + chr(10)
    new_func += "                                sid to url" + chr(10)
    new_func += "                            } else {" + chr(10)
    new_func += "                                LxRuntimeLog.add(" + Q + LB + "降级排查" + RB + "源 " + DL + "sid" + " 探活失败（死链/防盗链），尝试下一个" + Q + ")" + chr(10)
    new_func += "                                markSourceCoolDown(sid)" + chr(10)
    new_func += "                                null" + chr(10)
    new_func += "                            }" + chr(10)
    new_func += "                        } else {" + chr(10)
    new_func += "                            null" + chr(10)
    new_func += "                        }" + chr(10)
    new_func += "                    } catch (e: Exception) {" + chr(10)
    new_func += "                        lastError = e" + chr(10)
    new_func += "                        markSourceCoolDown(sid)" + chr(10)
    new_func += "                        null" + chr(10)
    new_func += "                    }" + chr(10)
    new_func += "                }" + chr(10)
    new_func += "            }.mapNotNull { it.await() }.firstOrNull()" + chr(10)
    new_func += "        }" + chr(10)
    new_func += "        if (results != null) {" + chr(10)
    new_func += "            lastGoodSourceId = results.first" + chr(10)
    new_func += "            return results" + chr(10)
    new_func += "        }" + chr(10)
    new_func += "        // [39pool20] 3. 缓存 ID 全军覆没：重搜一次，若搜到的 ID 与缓存不同，说明缓存过期了，删掉它，当场用新 ID 再播一次" + chr(10)
    new_func += "        if (usedCache && songTitle.isNotBlank()) {" + chr(10)
    new_func += "            try {" + chr(10)
    new_func += "                val fresh = searchAllPoolSources(songTitle)" + chr(10)
    new_func += "                val freshHit = fresh.firstOrNull { hitTitleOf(it).isNotBlank() }" + chr(10)
    new_func += "                val freshId = freshHit?.let { hitIdOf(it) }" + chr(10)
    new_func += "                if (!freshId.isNullOrBlank() && freshId != (effInfo[" + Q + "songId" + Q + "] as? String)) {" + chr(10)
    new_func += "                    val freshPlatform = hitPlatformOf(freshHit) ?: platform" + chr(10)
    new_func += "                    var usedNewId = false" + chr(10)
    new_func += "                    deleteIdMap(platform, songId)" + chr(10)
    new_func += "                    try { LxRuntimeLog.add(" + Q + "缓存ID失效已删: " + Q + " + songTitle) } catch (_: Exception) { }" + chr(10)
    new_func += "                    if (!usedNewId) {" + chr(10)
    new_func += "                        usedNewId = true" + chr(10)
    new_func += "                        val retryInfo = musicInfo.toMutableMap().apply {" + chr(10)
    new_func += "                            put(" + Q + "songId" + Q + ", freshId)" + chr(10)
    new_func += "                            put(" + Q + "id" + Q + ", freshId)" + chr(10)
    new_func += "                        }" + chr(10)
    new_func += "                        val retryResults = kotlinx.coroutines.coroutineScope {" + chr(10)
    new_func += "                            val scope = this" + chr(10)
    new_func += "                            targets.map { (sid, eng) ->" + chr(10)
    new_func += "                                scope.async {" + chr(10)
    new_func += "                                    try {" + chr(10)
    new_func += "                                        val url = kotlinx.coroutines.withTimeout(8000L) {" + chr(10)
    new_func += "                                            kotlin.coroutines.suspendCoroutine<String?> { cont ->" + chr(10)
    new_func += "                                                try {" + chr(10)
    new_func += "                                                    eng.requestMusicUrl(freshPlatform, retryInfo, quality) { r ->" + chr(10)
    new_func += "                                                        r.fold(" + chr(10)
    new_func += "                                                            onSuccess = { u -> cont.resumeWith(Result.success(u)) }," + chr(10)
    new_func += "                                                            onFailure = { e -> cont.resumeWith(Result.failure(e)) }" + chr(10)
    new_func += "                                                        )" + chr(10)
    new_func += "                                                    }" + chr(10)
    new_func += "                                                } catch (e: Exception) {" + chr(10)
    new_func += "                                                    cont.resumeWith(Result.failure(e))" + chr(10)
    new_func += "                                                }" + chr(10)
    new_func += "                                            }" + chr(10)
    new_func += "                                        }" + chr(10)
    new_func += "                                        if (!url.isNullOrBlank()) {" + chr(10)
    new_func += "                                            val isAlive = try {" + chr(10)
    new_func += "                                                LxPlayerManager.isStreamUrlAlive(url)" + chr(10)
    new_func += "                                            } catch (e: Exception) {" + chr(10)
    new_func += "                                                false" + chr(10)
    new_func += "                                            }" + chr(10)
    new_func += "                                            if (isAlive) {" + chr(10)
    new_func += "                                                sid to url" + chr(10)
    new_func += "                                            } else {" + chr(10)
    new_func += "                                                markSourceCoolDown(sid)" + chr(10)
    new_func += "                                                null" + chr(10)
    new_func += "                                            }" + chr(10)
    new_func += "                                        } else {" + chr(10)
    new_func += "                                            null" + chr(10)
    new_func += "                                        }" + chr(10)
    new_func += "                                    } catch (e: Exception) {" + chr(10)
    new_func += "                                        lastError = e" + chr(10)
    new_func += "                                        markSourceCoolDown(sid)" + chr(10)
    new_func += "                                        null" + chr(10)
    new_func += "                                    }" + chr(10)
    new_func += "                                }" + chr(10)
    new_func += "                            }.mapNotNull { it.await() }.firstOrNull()" + chr(10)
    new_func += "                        }" + chr(10)
    new_func += "                        if (retryResults != null) {" + chr(10)
    new_func += "                            lastGoodSourceId = retryResults.first" + chr(10)
    new_func += "                            try { saveIdMap(platform, freshPlatform, songId, freshId) } catch (_: Exception) { }" + chr(10)
    new_func += "                            try { LxRuntimeLog.add(" + Q + "缓存ID失效已换新ID播出: " + Q + " + songTitle + " + Q + " -> " + Q + " + freshPlatform + " + Q + " " + Q + " + freshId) } catch (_: Exception) { }" + chr(10)
    new_func += "                            return retryResults" + chr(10)
    new_func += "                        }" + chr(10)
    new_func += "                    }" + chr(10)
    new_func += "                }" + chr(10)
    new_func += "            } catch (_: Exception) { }" + chr(10)
    new_func += "        }" + chr(10)
    new_func += "        throw IllegalStateException(" + Q + "所有音源均失效" + Q + ", lastError)" + chr(10)
    new_func += "    }" + chr(10)
    new_func += chr(10)
    assert new_func.count("{") == new_func.count("}"), "pool20 新函数括号不平衡"
    s = s[:start] + new_func + s[func_end:]
    # 3) 插入 pool20 助手函数（在 searchOnEngine 之后，resolveMusicUrlFirst 之前）
    sig3 = "    private suspend fun searchOnEngine(eng: LxScriptEngine, keyword: String): List<Map<String, Any>> {"
    assert s.count(sig3) == 1, "pool20 锚点 searchOnEngine 数量异常"
    bs3 = s.find(sig3)
    brace3 = s.find("{", bs3)
    end3 = brace_match_end(s, brace3)
    helpers = ""
    helpers += "    // [39pool20] 原生快路径：原平台+原 ID 并行取址，先到先得，不探活；空链接绝不 complete" + chr(10)
    helpers += "    private suspend fun raceNativeUrl(" + chr(10)
    helpers += "        targets: List<Pair<String, LxScriptEngine>>," + chr(10)
    helpers += "        platform: String," + chr(10)
    helpers += "        musicInfo: Map<String, Any>," + chr(10)
    helpers += "        quality: String" + chr(10)
    helpers += "    ): Pair<String, String>? {" + chr(10)
    helpers += "        val first = kotlinx.coroutines.CompletableDeferred<Pair<String, String>?>()" + chr(10)
    helpers += "        return kotlinx.coroutines.coroutineScope {" + chr(10)
    helpers += "            val scope = this" + chr(10)
    helpers += "            val jobs = targets.map { (sid, eng) ->" + chr(10)
    helpers += "                scope.async {" + chr(10)
    helpers += "                    try {" + chr(10)
    helpers += "                        val url = kotlinx.coroutines.withTimeout(8000L) {" + chr(10)
    helpers += "                            kotlin.coroutines.suspendCoroutine<String?> { cont ->" + chr(10)
    helpers += "                                try {" + chr(10)
    helpers += "                                    eng.requestMusicUrl(platform, musicInfo, quality) { r ->" + chr(10)
    helpers += "                                        r.fold(" + chr(10)
    helpers += "                                            onSuccess = { u ->" + chr(10)
    helpers += "                                                try { cont.resumeWith(Result.success(u)) } catch (_: Exception) {}" + chr(10)
    helpers += "                                            }," + chr(10)
    helpers += "                                            onFailure = { e ->" + chr(10)
    helpers += "                                                try { cont.resumeWith(Result.failure(e)) } catch (_: Exception) {}" + chr(10)
    helpers += "                                            }" + chr(10)
    helpers += "                                        )" + chr(10)
    helpers += "                                    }" + chr(10)
    helpers += "                                } catch (e: Exception) {" + chr(10)
    helpers += "                                    cont.resumeWith(Result.failure(e))" + chr(10)
    helpers += "                                }" + chr(10)
    helpers += "                            }" + chr(10)
    helpers += "                        }" + chr(10)
    helpers += "                        // 死要求 1：空链接绝不 complete，绝不给 ExoPlayer" + chr(10)
    helpers += "                        if (!url.isNullOrBlank()) {" + chr(10)
    helpers += "                            first.complete(sid to url)" + chr(10)
    helpers += "                        }" + chr(10)
    helpers += "                    } catch (_: Exception) { }" + chr(10)
    helpers += "                }" + chr(10)
    helpers += "            }" + chr(10)
    helpers += "            // 看门狗：全部源都跑完仍没地址时，用 null 唤醒等待，不傻等 9 秒" + chr(10)
    helpers += "            val watchdog = scope.async {" + chr(10)
    helpers += "                jobs.forEach { it.join() } // [39pool20] joinAll 须 import，本文件没引；forEach+Job.join() 等价且零 import" + chr(10)
    helpers += "                first.complete(null)" + chr(10)
    helpers += "            }" + chr(10)
    helpers += "            val result = try {" + chr(10)
    helpers += "                kotlinx.coroutines.withTimeout(9000L) { first.await() }" + chr(10)
    helpers += "            } catch (_: Exception) { null }" + chr(10)
    helpers += "            jobs.forEach { it.cancel() }" + chr(10)
    helpers += "            watchdog.cancel()" + chr(10)
    helpers += "            result" + chr(10)
    helpers += "        }" + chr(10)
    helpers += "    }" + chr(10)
    helpers += chr(10)
    helpers += "    // [39pool20] 后台建映射：在途去重 + 上限 8，结束后自动释放；只捕获不可变字符串，不持有外部强引用" + chr(10)
    helpers += "    private val bgSearchInFlight = java.util.concurrent.ConcurrentHashMap<String, Boolean>()" + chr(10)
    helpers += "    private fun launchBackgroundIdSearch(platform: String, songId: String, title: String, artist: String) {" + chr(10)
    helpers += "        if (title.isBlank() || songId.isBlank()) return" + chr(10)
    helpers += "        val key = platform.lowercase() + " + Q + "|" + Q + " + songId" + chr(10)
    helpers += "        if (bgSearchInFlight.putIfAbsent(key, true) != null) return" + chr(10)
    helpers += "        if (bgSearchInFlight.size > 8) {" + chr(10)
    helpers += "            bgSearchInFlight.remove(key)" + chr(10)
    helpers += "            try { LxRuntimeLog.add(" + Q + "后台建映射跳过（堆积上限）: " + Q + " + title) } catch (_: Exception) { }" + chr(10)
    helpers += "            return" + chr(10)
    helpers += "        }" + chr(10)
    helpers += "        val p = platform" + chr(10)
    helpers += "        val sid = songId" + chr(10)
    helpers += "        val t = title" + chr(10)
    helpers += "        val a = artist" + chr(10)
    helpers += "        poolScope.launch {" + chr(10)
    helpers += "            try {" + chr(10)
    helpers += "                val hits = searchAllPoolSources(t)" + chr(10)
    helpers += "                val hit = hits.firstOrNull { h -> titleMatches(t, hitTitleOf(h)) && singerMatches(a, hitArtistOf(h)) }" + chr(10)
    helpers += "                if (hit != null) {" + chr(10)
    helpers += "                    val dstPlatform = hitPlatformOf(hit) ?: p" + chr(10)
    helpers += "                    val dstId = hitIdOf(hit)" + chr(10)
    helpers += "                    if (!dstId.isNullOrBlank()) {" + chr(10)
    helpers += "                        try { saveIdMap(p, dstPlatform, sid, dstId) } catch (_: Exception) { }" + chr(10)
    helpers += "                        try { LxRuntimeLog.add(" + Q + "后台建映射: " + Q + " + t + " + Q + " -> " + Q + " + dstPlatform + " + Q + " " + Q + " + dstId) } catch (_: Exception) { }" + chr(10)
    helpers += "                    }" + chr(10)
    helpers += "                }" + chr(10)
    helpers += "            } catch (e: Exception) {" + chr(10)
    helpers += "                try { LxRuntimeLog.add(" + Q + "后台建映射失败: " + Q + " + t + " + Q + " " + Q + " + (e.message ?: " + Q + Q + ")) } catch (_: Exception) { }" + chr(10)
    helpers += "            } finally {" + chr(10)
    helpers += "                bgSearchInFlight.remove(key)" + chr(10)
    helpers += "            }" + chr(10)
    helpers += "        }" + chr(10)
    helpers += "    }" + chr(10)
    helpers += chr(10)
    helpers += "    // [39pool20] 搜索结果字段取法：脚本回的键可能是 title/name、artist/singer、platform/source、id/songmid，两种都认" + chr(10)
    helpers += "    private fun hitTitleOf(hit: Map<String, Any>): String {" + chr(10)
    helpers += "        return ((hit[" + Q + "title" + Q + "] ?: hit[" + Q + "name" + Q + "]) as? String) ?: " + Q + Q + chr(10)
    helpers += "    }" + chr(10)
    helpers += "    private fun hitArtistOf(hit: Map<String, Any>): String {" + chr(10)
    helpers += "        return ((hit[" + Q + "artist" + Q + "] ?: hit[" + Q + "singer" + Q + "]) as? String) ?: " + Q + Q + chr(10)
    helpers += "    }" + chr(10)
    helpers += "    private fun hitPlatformOf(hit: Map<String, Any>): String? {" + chr(10)
    helpers += "        return ((hit[" + Q + "platform" + Q + "] ?: hit[" + Q + "source" + Q + "]) as? String)?.takeIf { it.isNotBlank() }" + chr(10)
    helpers += "    }" + chr(10)
    helpers += "    private fun hitIdOf(hit: Map<String, Any>): String? {" + chr(10)
    helpers += "        val v = hit[" + Q + "id" + Q + "] ?: hit[" + Q + "songmid" + Q + "] ?: return null" + chr(10)
    helpers += "        return v.toString().takeIf { it.isNotBlank() }" + chr(10)
    helpers += "    }" + chr(10)
    helpers += chr(10)
    helpers += "    // [39pool20] 歌名归一化：剥掉末尾的 (Live)/[伴奏] 等后缀再比" + chr(10)
    helpers += "    private fun normTitle(raw: String): String {" + chr(10)
    helpers += "        var t = raw.trim().lowercase()" + chr(10)
    helpers += "        while (true) {" + chr(10)
    helpers += "            // [39pool20] 40 是左圆括号、91 是左方括号的码点：此处不用字面括号，免得被括号计数断言误判" + chr(10)
    helpers += "            val openIdx = listOf(t.lastIndexOf(40.toChar()), t.lastIndexOf(91.toChar()), t.lastIndexOf(" + Q + "（" + Q + "), t.lastIndexOf(" + Q + LB + Q + ")).maxOrNull() ?: -1" + chr(10)
    helpers += "            if (openIdx < 0) break" + chr(10)
    helpers += "            val tail = t.substring(openIdx)" + chr(10)
    helpers += "            val ok = (tail.startsWith(" + Q + "(" + Q + ") && tail.endsWith(" + Q + ")" + Q + ")) || (tail.startsWith(" + Q + "[" + Q + ") && tail.endsWith(" + Q + "]" + Q + ")) || (tail.startsWith(" + Q + "（" + Q + ") && tail.endsWith(" + Q + "）" + Q + ")) || (tail.startsWith(" + Q + LB + Q + ") && tail.endsWith(" + Q + RB + Q + "))" + chr(10)
    helpers += "            if (!ok) break" + chr(10)
    helpers += "            t = t.substring(0, openIdx).trim()" + chr(10)
    helpers += "            if (t.isEmpty()) break" + chr(10)
    helpers += "        }" + chr(10)
    helpers += "        return t" + chr(10)
    helpers += "    }" + chr(10)
    helpers += "    // [39pool20] 双重匹配：歌名归一化后必须相等；歌手有就必须对上，没有就不校验，宁可不缓存" + chr(10)
    helpers += "    private fun titleMatches(songTitle: String, hitTitle: String): Boolean {" + chr(10)
    helpers += "        val a = normTitle(songTitle)" + chr(10)
    helpers += "        val b = normTitle(hitTitle)" + chr(10)
    helpers += "        return a.isNotEmpty() && a == b" + chr(10)
    helpers += "    }" + chr(10)
    helpers += "    private fun singerMatches(songArtist: String, hitArtist: String): Boolean {" + chr(10)
    helpers += "        val a = songArtist.trim().lowercase()" + chr(10)
    helpers += "        val b = hitArtist.trim().lowercase()" + chr(10)
    helpers += "        if (a.isEmpty()) return true" + chr(10)
    helpers += "        if (b.isEmpty()) return false" + chr(10)
    helpers += "        return a.contains(b) || b.contains(a)" + chr(10)
    helpers += "    }" + chr(10)
    assert helpers.count("{") == helpers.count("}"), "pool20 助手函数括号不平衡"
    assert chr(92) not in helpers, "pool20 助手函数含反斜杠，转义风险"
    s = s[:end3] + chr(10) + helpers + s[end3:]
    # 自检
    assert "[39pool20]" in s, "pool20 标记未落"
    assert "[39pool19]" in s, "pool19 标记丢失"
    assert "[39pool15]" in s and "[39pool18]" in s and "[39pool17]" in s, "旧池标记丢失"
    assert s.count("fun lookupIdMap") == 1 and s.count("fun saveIdMap") == 1 and s.count("fun deleteIdMap") == 1, "缓存函数数量异常"
    assert s.count("fun raceNativeUrl") == 1 and s.count("fun launchBackgroundIdSearch") == 1, "新函数数量异常"
    assert "fun lookupIdMap(srcPlatform: String, dstPlatform: String, srcId: String)" not in s, "旧版 lookup 签名残留"
    assert "fun deleteIdMap(srcPlatform: String, dstPlatform: String, srcId: String)" not in s, "旧版 delete 签名残留"
    assert s.count("{") == s.count("}"), "pool20 全文件括号不平衡"
    print("=== 自检：新函数片段 ===")
    idx = s.find("[39pool20] 全场景秒播")
    print(s[idx:idx+600])
    print("=== 自检：竞速核心 ===")
    idx2 = s.find("val first = kotlinx.coroutines.CompletableDeferred")
    print(s[idx2-200:idx2+400])
    print("=== 自检：Key 拼接 ===")
    idx3 = s.find("fun lookupIdMap")
    print(s[idx3:idx3+500])
    open(M, "w", encoding="utf-8").write(s)
    print("OK 39pool20 全场景秒播完成")
PYEOF20
echo "=== 39pool20 完成 ==="
# === 39pool21: pool18 探活循环改先到先得 + 看门狗防死锁（用户确认执行）===
python3 << 'PYEOF21'
import os

def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/avbox/osc/ui/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
    assert os.path.exists("avbox/app/src/main/java/com/github/avbox/osc/ui/MusicHomeActivity.kt"), "find_root 失败"

find_root()
M = "avbox/app/src/main/java/com/github/avbox/osc/ui/LxPlayerActivity.kt"
s = open(M, encoding="utf-8").read()
if "[39pool21]" in s:
    print("跳过（39 pool21 已应用）")
else:
    # 锚点：pool18 收尾段，以 CI 态 pool20 生成文本为准
    # 起始 var lastError 声明全文件唯一；结束 pool20 第 3 步注释全文件唯一
    # 只换这一段：缓存查、原生直出、pool17 搜 ID、重试块一字不动
    assert s.count("        var lastError: Throwable? = null") == 1, "pool21 锚点 lastError 数量异常"
    assert s.count("        // [39pool20] 3. 缓存 ID 全军覆没") == 1, "pool21 锚点 pool20 第 3 步数量异常"
    loop_start = s.find("        var lastError: Throwable? = null")
    loop_end = s.find("        // [39pool20] 3. 缓存 ID 全军覆没", loop_start)
    assert loop_start != -1 and loop_end != -1 and loop_start < loop_end, "pool21 锚点定位失败"
    new_loop = """        var lastError: Throwable? = null
        // [39pool18][39pool21] 先到先得：谁先拿到活地址谁赢，其余 cancel；看门狗防死锁
        val firstAlive = kotlinx.coroutines.CompletableDeferred<Pair<String, String>?>()
        val raceJobs = targets.map { (sid, eng) ->
            poolScope.launch {
                try {
                    val url = kotlinx.coroutines.withTimeout(8000L) {
                        kotlin.coroutines.suspendCoroutine<String?> { cont ->
                            try {
                                eng.requestMusicUrl(effPlatform, effInfo, quality) { r ->
                                    r.fold(
                                        onSuccess = { u -> cont.resumeWith(Result.success(u)) },
                                        onFailure = { e -> cont.resumeWith(Result.failure(e)) }
                                    )
                                }
                            } catch (e: Exception) {
                                cont.resumeWith(Result.failure(e))
                            }
                        }
                    }
                    if (!url.isNullOrBlank() && LxPlayerManager.isStreamUrlAlive(url)) {
                        LxRuntimeLog.add("源 $sid 探活成功，确定使用！")
                        firstAlive.complete(sid to url)
                    } else if (!url.isNullOrBlank()) {
                        markSourceCoolDown(sid)
                    }
                } catch (e: kotlinx.coroutines.TimeoutCancellationException) {
                    markSourceCoolDown(sid) // 超时：记冷却
                } catch (e: kotlinx.coroutines.CancellationException) {
                    throw e // 真取消：必须透传
                } catch (e: Exception) {
                    lastError = e
                    markSourceCoolDown(sid)
                }
            }
        }

        // 看门狗：全部源跑完仍未成功则强制唤醒
        poolScope.launch {
            raceJobs.forEach { it.join() }
            if (!firstAlive.isCompleted) {
                firstAlive.complete(null)
            }
        }

        val results = try {
            kotlinx.coroutines.withTimeout(9000L) { firstAlive.await() }
        } catch (e: Exception) {
            null
        } finally {
            raceJobs.forEach { it.cancel() } // 绝对清理
        }

        if (results != null) {
            lastGoodSourceId = results.first
            return results
        }
"""
    # 新块自检：三括号平衡、无反斜杠、禁 joinAll、协程全限定名、超时先于取消
    assert new_loop.count("(") == new_loop.count(")"), "pool21 新块圆括号不平衡"
    assert new_loop.count("{") == new_loop.count("}"), "pool21 新块花括号不平衡"
    assert new_loop.count("[") == new_loop.count("]"), "pool21 新块方括号不平衡"
    assert chr(92) not in new_loop, "pool21 新块含反斜杠"
    assert "joinAll()" not in new_loop, "pool21 新块含禁用 joinAll"
    assert "kotlinx.coroutines.CompletableDeferred" in new_loop, "pool21 CompletableDeferred 未全限定"
    assert "kotlinx.coroutines.withTimeout" in new_loop, "pool21 withTimeout 未全限定"
    assert new_loop.find("kotlinx.coroutines.TimeoutCancellationException") < new_loop.find("kotlinx.coroutines.CancellationException"), "pool21 超时与取消顺序错误"
    assert ".mapNotNull { it.await() }.firstOrNull()" not in new_loop, "pool21 新块含废弃 await-all"
    s = s[:loop_start] + new_loop + s[loop_end:]
    # 函数头注释追加 pool21（旧标记保留）
    old_head = "；[39pool20] 全场景秒播：缓存先查、原生直出先到先得、后台建映射"
    assert s.count(old_head) == 1, "pool21 锚点函数头数量异常"
    s = s.replace(old_head, old_head + "；[39pool21] 探活循环先到先得", 1)
    # 自检
    assert "[39pool21]" in s, "pool21 标记未落"
    assert "[39pool18]" in s and "[39pool20]" in s and "[39pool19]" in s and "[39pool17]" in s, "旧池标记丢失"
    assert s.count(".mapNotNull { it.await() }.firstOrNull()") == 1, "pool21 await-all 残留异常（应只剩重试块 1 处）"
    assert s.count("val results = kotlinx.coroutines.coroutineScope") == 0, "pool21 旧 pool18 收尾残留"
    assert s.count("val firstAlive = kotlinx.coroutines.CompletableDeferred") == 1, "pool21 firstAlive 数量异常"
    assert s.count("raceJobs.forEach { it.join() }") == 1, "pool21 看门狗数量异常"
    assert s.count("firstAlive.complete(null)") == 1, "pool21 看门狗唤醒数量异常"
    assert s.count("fun resolveUrlWithFallback") == 1, "pool21 函数数量异常"
    assert s.count("fun raceNativeUrl") == 1 and s.count("fun lookupIdMap") == 1, "pool20 助手函数丢失"
    assert s.count("(") == s.count(")"), "pool21 全文件圆括号不平衡"
    assert s.count("{") == s.count("}"), "pool21 全文件花括号不平衡"
    assert s.count("[") == s.count("]"), "pool21 全文件方括号不平衡"
    print("=== 自检：pool21 新收尾 ===")
    idx = s.find("[39pool21]")
    print(s[idx-200:idx+900])
    open(M, "w", encoding="utf-8").write(s)
    print("OK 39pool21 探活循环先到先得完成")
PYEOF21
echo "=== 39pool21 完成 ==="

# === 39pool22: 推荐预取公开后台搜 ID 入口（点歌提速重构改造四）===
# launchBackgroundIdSearch 原为 private，仅 LxEngineHolder 内部可用；
# 推荐页（RecommendScreen.kt，另一文件）复用它做后台预取，须公开。只改可见性，不动逻辑。
# 39 在 40/41 之前跑，编译在全部脚本跑完后，故 41 v11 可引用。
python3 << 'PYEOF39P22'
import os
P = "avbox/app/src/main/java/com/github/avbox/osc/ui/LxPlayerActivity.kt"
while not os.path.exists(P) and os.getcwd() != "/":
    os.chdir("..")
if not os.path.exists(P):
    print("❌ 未找到 LxPlayerActivity.kt"); raise SystemExit(1)
s = open(P, encoding="utf-8").read()
if "[39pool22]" in s:
    print("跳过（39 pool22 已应用）")
else:
    old = "    private fun launchBackgroundIdSearch(platform: String, songId: String, title: String, artist: String) {"
    assert s.count(old) == 1, "pool22 锚点数量异常"
    new = "    fun launchBackgroundIdSearch(platform: String, songId: String, title: String, artist: String) { // [39pool22] 推荐预取公开：供推荐页调用"
    s = s.replace(old, new, 1)
    assert s.count("fun launchBackgroundIdSearch") == 1, "pool22 函数数量异常"
    assert s.count("private fun launchBackgroundIdSearch") == 0, "pool22 private 残留"
    assert "[39pool22]" in s, "pool22 标记未落"
    open(P, "w", encoding="utf-8").write(s)
    print("OK 39 pool22 推荐预取入口已公开")
PYEOF39P22
echo "=== 39 pool22 完成 ==="
# === 39pool23: ID 映射缓存落盘（抄洛雪做法 1：无 TTL，失败才刷新）===
# 修法：内存 ConcurrentHashMap 保留作一层缓存，save 时写透 SharedPreferences（lx_id_map），
# 首次查不到时从盘里全量懒加载一次；删 7 天过期（改无 TTL），失效靠 pool20 第 3 步“播放失败重搜删旧”刷新。
# Context 由 warmUp 存应用上下文（不持有 Activity）；warmUp 未跑过时只走内存（与现行一致）。
python3 << 'PYEOF23'
import os

def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/avbox/osc/ui/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
    assert os.path.exists("avbox/app/src/main/java/com/github/avbox/osc/ui/MusicHomeActivity.kt"), "find_root 失败"

def rep(src, old, new, name):
    assert src.count(old) == 1, "pool23 锚点 %s: %d" % (name, src.count(old))
    return src.replace(old, new, 1)

find_root()
M = "avbox/app/src/main/java/com/github/avbox/osc/ui/LxPlayerActivity.kt"
s = open(M, encoding="utf-8").read()
if "[39pool23]" in s:
    print("跳过（39pool23 已应用）")
else:
    # 1) warmUp 存应用上下文（两路都跑：已就绪早退分支也在第一行之后）
    old_warm = "    fun warmUp(context: android.content.Context) {" + chr(10) + "        if (isReady) {"
    assert s.count(old_warm) == 1, "pool23 锚点 warmUp 数量异常"
    new_warm = "    fun warmUp(context: android.content.Context) {" + chr(10) + "        try { idMapCtx = context.applicationContext } catch (_: Exception) { } // [39pool23] 落盘缓存用应用上下文" + chr(10) + "        if (isReady) {"
    s = s.replace(old_warm, new_warm, 1)
    # 2) 整块替换 pool19 缓存函数（起：pool19 注释，止：pool6 注释），与 pool20 同款定位
    start19 = s.find("    // [39pool19]")
    assert start19 != -1, "pool23 锚点 pool19 起始未找到"
    end19 = s.find("    // [39pool6] 坏源冷却", start19)
    assert end19 != -1, "pool23 锚点 pool19 结束未找到"
    old19 = s[start19:end19]
    assert old19.count("fun lookupIdMap") == 1, "pool23 pool19 lookup 数量异常"
    assert old19.count("fun saveIdMap") == 1, "pool23 pool19 save 数量异常"
    assert old19.count("fun deleteIdMap") == 1, "pool23 pool19 delete 数量异常"
    assert old19.count("{") == old19.count("}"), "pool23 pool19 括号不平衡"
    new19 = """    // [39pool19][39pool20][39pool23] ID 映射缓存：落盘版（抄洛雪做法 1），Key=源平台_原ID，Value=目标平台|目标ID|时间戳；无 TTL、播放失败才刷新（pool20 第 3 步重试分支）；上限 500 条
    private const val ID_MAP_MAX = 500
    private const val ID_MAP_PREFS = "lx_id_map"
    private val idMapCache = java.util.concurrent.ConcurrentHashMap<String, String>()
    private var idMapCtx: android.content.Context? = null
    private var idMapLoaded = false
    private fun idMapPrefs(): android.content.SharedPreferences? {
        return try { idMapCtx?.getSharedPreferences(ID_MAP_PREFS, android.content.Context.MODE_PRIVATE) } catch (_: Exception) { null }
    }
    private fun loadIdMapFromDisk() {
        if (idMapLoaded) return
        idMapLoaded = true
        try {
            val prefs = idMapPrefs() ?: return
            for ((k, v) in prefs.all) {
                val vs = v as? String ?: continue
                if (vs.split("|").size != 3) continue
                if (!idMapCache.containsKey(k)) idMapCache[k] = vs
            }
        } catch (_: Exception) { }
    }
    fun lookupIdMap(srcPlatform: String, srcId: String): Pair<String, String>? {
        return try {
            val key = srcPlatform.lowercase() + "_" + srcId
            var v = idMapCache[key]
            if (v == null) {
                loadIdMapFromDisk()
                v = idMapCache[key] ?: return null
            }
            val parts = v.split("|")
            if (parts.size != 3) { idMapCache.remove(key); return null }
            val dp = parts[0].takeIf { it.isNotBlank() } ?: return null
            val di = parts[1].takeIf { it.isNotBlank() } ?: return null
            dp to di
        } catch (_: Exception) { null }
    }
    fun saveIdMap(srcPlatform: String, dstPlatform: String, srcId: String, dstId: String) {
        try {
            val key = srcPlatform.lowercase() + "_" + srcId
            val v = dstPlatform.lowercase() + "|" + dstId + "|" + System.currentTimeMillis().toString()
            if (idMapCache.size >= ID_MAP_MAX && !idMapCache.containsKey(key)) {
                val oldestKey: String? = try {
                    var oldest: String? = null
                    var oldestTs = Long.MAX_VALUE
                    for ((k, vv) in idMapCache) {
                        val t = vv.split("|").getOrNull(2)?.toLongOrNull() ?: 0L
                        if (t < oldestTs) { oldestTs = t; oldest = k }
                    }
                    oldest
                } catch (_: Exception) { null }
                if (oldestKey != null) {
                    idMapCache.remove(oldestKey)
                    try { idMapPrefs()?.edit()?.remove(oldestKey)?.apply() } catch (_: Exception) { }
                }
            }
            idMapCache[key] = v
            try { idMapPrefs()?.edit()?.putString(key, v)?.apply() } catch (_: Exception) { }
        } catch (_: Exception) { }
    }
    fun deleteIdMap(srcPlatform: String, srcId: String) {
        try {
            val key = srcPlatform.lowercase() + "_" + srcId
            idMapCache.remove(key)
            try { idMapPrefs()?.edit()?.remove(key)?.apply() } catch (_: Exception) { }
        } catch (_: Exception) { }
    }
"""
    assert new19.count("{") == new19.count("}"), "pool23 新块括号不平衡"
    assert new19.count("(") == new19.count(")"), "pool23 新块圆括号不平衡"
    assert new19.count("[") == new19.count("]"), "pool23 新块方括号不平衡"
    s = s[:start19] + new19 + s[end19:]
    # 自检
    assert "[39pool23]" in s, "pool23 标记未落"
    assert s.count("fun lookupIdMap") == 1 and s.count("fun saveIdMap") == 1 and s.count("fun deleteIdMap") == 1, "pool23 缓存函数数量异常"
    assert "ID_MAP_EXPIRE_MS" not in s, "pool23 旧 7 天过期残留"
    assert s.count("fun idMapPrefs") == 1 and s.count("fun loadIdMapFromDisk") == 1, "pool23 落盘 helper 数量异常"
    assert s.count("idMapCtx = context.applicationContext") == 1, "pool23 warmUp 存上下文未落"
    assert s.count("(") == s.count(")"), "pool23 全文件圆括号不平衡"
    assert s.count("{") == s.count("}"), "pool23 全文件花括号不平衡"
    assert s.count("[") == s.count("]"), "pool23 全文件方括号不平衡"
    open(M, "w", encoding="utf-8").write(s)
    print("OK 39pool23 ID 映射缓存落盘完成")
PYEOF23
echo "=== 39pool23 完成 ==="
# === 39pool24: pool17 前景转换加守卫（抄 Listen1）＋原生竞速超时缩短 ===
# 修法 1（F1/F3/F6）：新增 pickPoolHit helper——前景取命中时必须歌名归一化＋歌手双重匹配（复用后台
# 已有的 titleMatches/singerMatches），且命中平台+ID 不得等于原平台+原ID，否则当作没命中、走原 ID 回落。
# 前景（pool17）与重试分支（pool20 第 3 步）两处 firstOrNull 均改调它。
# 修法 2（冷歌 9 秒等待）：原生竞速 raceNativeUrl 单源 8000L→3000L、外层 9000L→4000L；
# pool18 的 8000L/9000L 不动（那是出声路径）。定位用函数签名＋花括号配对，禁子串 find 误伤 pool18。
python3 << 'PYEOF24'
import os

def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/avbox/osc/ui/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
    assert os.path.exists("avbox/app/src/main/java/com/github/avbox/osc/ui/MusicHomeActivity.kt"), "find_root 失败"

def rep(src, old, new, name):
    assert src.count(old) == 1, "pool24 锚点 %s: %d" % (name, src.count(old))
    return src.replace(old, new, 1)

find_root()
M = "avbox/app/src/main/java/com/github/avbox/osc/ui/LxPlayerActivity.kt"
s = open(M, encoding="utf-8").read()
if "[39pool24]" in s:
    print("跳过（39pool24 已应用）")
else:
    # 1) 新增 pickPoolHit helper，挂在 singerMatches 之后
    old_singer = """    private fun singerMatches(songArtist: String, hitArtist: String): Boolean {
        val a = songArtist.trim().lowercase()
        val b = hitArtist.trim().lowercase()
        if (a.isEmpty()) return true
        if (b.isEmpty()) return false
        return a.contains(b) || b.contains(a)
    }"""
    assert s.count(old_singer) == 1, "pool24 锚点 singerMatches 数量异常"
    new_singer = old_singer + chr(10) + """    // [39pool24] 前景取命中守卫（抄 Listen1）：歌名归一化＋歌手双重匹配，且命中平台+ID 不得等于原平台+原ID，否则当作没命中（防 F1/F3/F6 毒映射）
    private fun pickPoolHit(hits: List<Map<String, Any>>, songTitle: String, songArtist: String, platform: String, songId: String): Map<String, Any>? {
        return hits.firstOrNull { h ->
            titleMatches(songTitle, hitTitleOf(h)) && singerMatches(songArtist, hitArtistOf(h)) && !(hitPlatformOf(h)?.lowercase() == platform.lowercase() && hitIdOf(h) == songId)
        }
    }"""
    s = s.replace(old_singer, new_singer, 1)
    # 2) 前景（pool17）改调 pickPoolHit
    old_fg = "                val hit = poolHits.firstOrNull { hitTitleOf(it).isNotBlank() }"
    assert s.count(old_fg) == 1, "pool24 锚点前景数量异常"
    new_fg = "                val hit = pickPoolHit(poolHits, songTitle, songArtist, platform, songId) // [39pool24] 前景守卫：双重匹配＋不得等于原值"
    s = s.replace(old_fg, new_fg, 1)
    # 3) 重试分支（pool20 第 3 步）改调 pickPoolHit
    old_rt = "                val freshHit = fresh.firstOrNull { hitTitleOf(it).isNotBlank() }"
    assert s.count(old_rt) == 1, "pool24 锚点重试数量异常"
    new_rt = "                val freshHit = pickPoolHit(fresh, songTitle, songArtist, platform, songId) // [39pool24] 重试也守卫，防再存毒映射"
    s = s.replace(old_rt, new_rt, 1)
    # 4) 原生竞速超时缩短：只动 raceNativeUrl 函数体内（函数签名＋花括号配对定位）
    sig = "    private suspend fun raceNativeUrl("
    assert s.count(sig) == 1, "pool24 raceNativeUrl 签名数量异常"
    fstart = s.find(sig)
    bstart = s.find("{", fstart)
    assert bstart != -1, "pool24 raceNativeUrl 左花括号未找到"
    depth = 0
    i = bstart
    while i < len(s):
        c = s[i]
        if c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0:
                break
        i += 1
    assert depth == 0, "pool24 raceNativeUrl 花括号配对失败"
    fend = i + 1
    region = s[fstart:fend]
    assert region.count("withTimeout(8000L)") == 1, "pool24 race 内 8000 数量异常"
    assert region.count("withTimeout(9000L)") == 1, "pool24 race 内 9000 数量异常"
    assert region.count("不傻等 9 秒") == 1, "pool24 race 内看门狗注释数量异常"
    region = region.replace("withTimeout(8000L)", "withTimeout(3000L)", 1)
    region = region.replace("withTimeout(9000L)", "withTimeout(4000L)", 1)
    region = region.replace("不傻等 9 秒", "不傻等 4 秒", 1)
    s = s[:fstart] + region + s[fend:]
    # 自检
    assert "[39pool24]" in s, "pool24 标记未落"
    assert s.count("fun pickPoolHit") == 1, "pool24 pickPoolHit 数量异常"
    assert s.count("pickPoolHit(poolHits, songTitle, songArtist, platform, songId)") == 1, "pool24 前景调用数量异常"
    assert s.count("pickPoolHit(fresh, songTitle, songArtist, platform, songId)") == 1, "pool24 重试调用数量异常"
    assert s.count("firstOrNull { hitTitleOf(it).isNotBlank() }") == 0, "pool24 旧 firstOrNull 残留"
    assert s.count("withTimeout(3000L)") == 1 and s.count("withTimeout(4000L)") == 1, "pool24 超时数量异常"
    assert s.count("withTimeout(8000L)") == 2, "pool24 pool18 的 8000 被误改（应剩 2 处）"
    assert s.count("withTimeout(9000L)") == 1, "pool24 pool18 的 9000 被误改（应剩 1 处）"
    assert s.count("(") == s.count(")"), "pool24 全文件圆括号不平衡"
    assert s.count("{") == s.count("}"), "pool24 全文件花括号不平衡"
    assert s.count("[") == s.count("]"), "pool24 全文件方括号不平衡"
    open(M, "w", encoding="utf-8").write(s)
    print("OK 39pool24 前景守卫＋原生竞速超时缩短完成")
PYEOF24
echo "=== 39pool24 完成 ==="
# === 39pool25: 原生竞速失败即冷却＋错峰＋原生探活加 3 秒上限 ===
# 根因（11-12 播歌慢 9 秒）：1) raceNativeUrl 吞失败不冷却，酷狗/网易一档失败后下一档又白跑一遍，还反复冲限速后端；
# 2) 并行 burst 两源同发，溯音酷我触发并发保护；3) 原生探活是阻塞调用、无超时，挂死会卡住整条取址链。
# 修法：1) raceNativeUrl 非取消异常即 markSourceCoolDown（与 pool21 探活循环口径一致；丢竞速的取消不冷却）；
# 2) 各源起步错峰 200ms；3) 原生探活包 withTimeoutOrNull(3000L)+IO，超时按不活处理落到池源搜索。
python3 << 'PYEOF25'
import os

def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/avbox/osc/ui/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
    assert os.path.exists("avbox/app/src/main/java/com/github/avbox/osc/ui/MusicHomeActivity.kt"), "find_root 失败"

def rep(src, old, new, name):
    assert src.count(old) == 1, "pool25 锚点 %s: %d" % (name, src.count(old))
    return src.replace(old, new, 1)

find_root()
M = "avbox/app/src/main/java/com/github/avbox/osc/ui/LxPlayerActivity.kt"
s = open(M, encoding="utf-8").read()
if "[39pool25]" in s:
    print("跳过（39 pool25 已应用）")
else:
    # 1) 错峰：各源起步错开 200ms，降并发峰值
    old_jobs = "            val jobs = targets.map { (sid, eng) ->"
    assert s.count(old_jobs) == 1, "pool25 锚点 jobs 数量异常"
    new_jobs = "            val jobs = targets.mapIndexed { idx, (sid, eng) -> // [39pool25] 错峰：各源起步错开 200ms，降并发峰值"
    s = s.replace(old_jobs, new_jobs, 1)
    # 2) 错峰生效：在 async 块开头按序号 delay
    old_async = """                scope.async {
                    try {
                        val url = kotlinx.coroutines.withTimeout(3000L) {"""
    assert s.count(old_async) == 1, "pool25 锚点 async 数量异常"
    new_async = """                scope.async {
                    if (idx > 0) kotlinx.coroutines.delay(idx * 200L) // [39pool25] 错峰：第 2 个起的源晚 200ms
                    try {
                        val url = kotlinx.coroutines.withTimeout(3000L) {"""
    s = s.replace(old_async, new_async, 1)
    # 3) 失败即冷却：非取消异常（超时/后端报错）记冷却；丢竞速的取消不冷却
    old_catch = """                        // 死要求 1：空链接绝不 complete，绝不给 ExoPlayer
                        if (!url.isNullOrBlank()) {
                            first.complete(sid to url)
                        }
                    } catch (_: Exception) { }"""
    assert s.count(old_catch) == 1, "pool25 锚点 catch 数量异常"
    new_catch = """                        // 死要求 1：空链接绝不 complete，绝不给 ExoPlayer
                        if (!url.isNullOrBlank()) {
                            first.complete(sid to url)
                        }
                    } catch (e: Exception) { // [39pool25] 失败即冷却：超时/后端报错记冷却 5 分钟，下一档不再白跑；丢竞速的取消不冷却
                        if (e is kotlinx.coroutines.TimeoutCancellationException || e !is kotlinx.coroutines.CancellationException) {
                            try { markSourceCoolDown(sid) } catch (_: Exception) { }
                        }
                    }"""
    s = s.replace(old_catch, new_catch, 1)
    # 4) 原生探活加 3 秒上限：阻塞调用，超时按不活处理
    old_probe = "                val nativeAlive = try { LxPlayerManager.isStreamUrlAlive(native.second) } catch (_: Exception) { false }"
    assert s.count(old_probe) == 1, "pool25 锚点 probe 数量异常"
    new_probe = "                val nativeAlive = try { kotlinx.coroutines.withTimeoutOrNull(3000L) { kotlinx.coroutines.withContext(kotlinx.coroutines.Dispatchers.IO) { LxPlayerManager.isStreamUrlAlive(native.second) } } ?: false } catch (_: Exception) { false } // [39pool25] 原生探活 3 秒上限，超时按不活处理"
    s = s.replace(old_probe, new_probe, 1)
    # 自检
    assert "[39pool25]" in s, "pool25 标记未落"
    assert s.count("fun raceNativeUrl") == 1, "pool25 raceNativeUrl 数量异常"
    assert s.count("withTimeoutOrNull(3000L)") == 1, "pool25 探活超时数量异常"
    assert s.count("mapIndexed") == 1, "pool25 错峰数量异常"
    assert s.count("fun resolveUrlWithFallback") == 1, "pool25 函数数量异常"
    assert s.count("(") == s.count(")"), "pool25 全文件圆括号不平衡"
    assert s.count("{") == s.count("}"), "pool25 全文件花括号不平衡"
    assert s.count("[") == s.count("]"), "pool25 全文件方括号不平衡"
    open(M, "w", encoding="utf-8").write(s)
    print("OK 39pool25 原生竞速冷却+错峰+探活上限完成")
PYEOF25
echo "=== 39pool25 完成 ==="
# === 39pool26: 点歌链去二次探活（池内已探过，直接播） ===
# 根因（11-12 播歌慢 9 秒）：resolveUrlWithFallback 回的地址在池内已探过活（原生快路径/探活循环/重试块三路都先探活才回），
# tryQuality 又在后台线程上再探一次（阻塞调用、无超时、无进度日志），慢后端上一次探活能拖 7 秒才放行或丢弃。
# 修法：去掉二次探活，拿到地址直接做切歌丢弃守卫后播；死链兜底靠 21 v54 onPlayerError 静默换源重播（已验证在位）。
# 保留：切歌丢弃守卫、空地址换源、档位失败降档、排除集逻辑一字不动。
python3 << 'PYEOF26'
import os

def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/avbox/osc/ui/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
    assert os.path.exists("avbox/app/src/main/java/com/github/avbox/osc/ui/MusicHomeActivity.kt"), "find_root 失败"

find_root()
M = "avbox/app/src/main/java/com/github/avbox/osc/ui/LxPlayerActivity.kt"
s = open(M, encoding="utf-8").read()
if "[39pool26]" in s:
    print("跳过（39 pool26 已应用）")
else:
    # 0) 修正入口日志：不再二次探活，"验活中"会误导抽屉读数
    old_log = '                                android.util.Log.i("LxPlayer", "获取 URL 成功，音质档位: $q，验活中")'
    assert s.count(old_log) == 1, "pool26 锚点 log 数量异常"
    new_log = '                                android.util.Log.i("LxPlayer", "获取 URL 成功，音质档位: $q（池内已验活，直接播）")'
    s = s.replace(old_log, new_log, 1)
    old = """                                Thread { // [39resolve] 取地址时验活：死链不交给播放器，自动降档
                                    val alive = LxPlayerManager.isStreamUrlAlive(url)
                                    runOnUiThread {
                                        if (!alive) {
                                            try { LxRuntimeLog.add("地址验活失败: " + title + " / " + artist + " | 档位 " + q + " " + url.take(80)) } catch (_: Exception) { }
                                            android.util.Log.w("LxPlayer", "音质 $q 地址验活失败，换池内下一源重试") // [39pool4]
                                            excludedSources.add(urlSourceId) // [39pool4] 排除刚失败的源，同一档位换源再试
                                            LxEngineHolder.markSourceCoolDown(urlSourceId) // [39pool6] 坏源搁置 5 分钟，下一首不优先试
                                            tryQuality()
                                        } else if (isFinishing || isDestroyed || (title.isNotEmpty() && (LxPlayerManager.currentTitle.value != title || LxPlayerManager.currentArtist.value != artist))) {
                                            android.util.Log.w("LxPlayer", "验活期间已切歌，丢弃旧地址")
                                        } else {
                                            LxPlayerManager.setLoading(false)
                                            LxPlayerManager.setError(null)
                                            LxPlayerManager.recordHistory(mapOf(
                                                "songId" to musicInfo["songId"].orEmpty(), "platform" to sourceId,
                                                "title" to title, "artist" to artist, "url" to url))
                                            LxPlayerManager.play(url, title, artist)
                                            Thread { LxPlayerManager.probeAndSetQuality(url) }.start() // [34v57] 点歌链补探针
                                            LxPlayerManager.fetchCommentsAsync(sourceId, musicInfo["songId"].orEmpty(), title, artist) // [35cmt1] 评论并行拉取（只读）
                                        }
                                    }
                                }.start()"""
    assert s.count(old) == 1, "pool26 锚点 onSuccess 数量异常"
    new = """                                // [39pool26] 验活已在池内做过（原生快路径/探活循环/重试块三路都先探活才回地址），此处不再二次探活，直接播；死链兜底靠 21 v54 onPlayerError 静默换源重播
                                if (isFinishing || isDestroyed || (title.isNotEmpty() && (LxPlayerManager.currentTitle.value != title || LxPlayerManager.currentArtist.value != artist))) {
                                    android.util.Log.w("LxPlayer", "已切歌，丢弃旧地址")
                                } else {
                                    android.util.Log.i("LxPlayer", "获取 URL 成功，音质档位: $q")
                                    LxPlayerManager.setLoading(false)
                                    LxPlayerManager.setError(null)
                                    LxPlayerManager.recordHistory(mapOf(
                                        "songId" to musicInfo["songId"].orEmpty(), "platform" to sourceId,
                                        "title" to title, "artist" to artist, "url" to url))
                                    LxPlayerManager.play(url, title, artist)
                                    Thread { LxPlayerManager.probeAndSetQuality(url) }.start() // [34v57] 点歌链补探针
                                    LxPlayerManager.fetchCommentsAsync(sourceId, musicInfo["songId"].orEmpty(), title, artist) // [35cmt1] 评论并行拉取（只读）
                                }"""
    s = s.replace(old, new, 1)
    # 自检
    assert "[39pool26]" in s, "pool26 标记未落"
    assert "val alive = LxPlayerManager.isStreamUrlAlive(url)" not in s, "pool26 二次探活残留"
    assert s.count("fun tryQuality") == 1, "pool26 tryQuality 数量异常"
    assert s.count("fun resolveUrlWithFallback") == 1, "pool26 函数数量异常"
    assert s.count("(") == s.count(")"), "pool26 全文件圆括号不平衡"
    assert s.count("{") == s.count("}"), "pool26 全文件花括号不平衡"
    assert s.count("[") == s.count("]"), "pool26 全文件方括号不平衡"
    open(M, "w", encoding="utf-8").write(s)
    print("OK 39pool26 点歌链去二次探活完成")
PYEOF26
echo "=== 39pool26 完成 ==="
# === 39pool27: 全冷却兜底加 60 秒 recency 门（酷狗每档白跑） ===
# 根因（11-12 20:35 截图，已装 53891034）：酷狗 backend 挂了，三源全挂 → 全冷却 5 分钟；
# 下一档 resolveUrlWithFallback 建 targets 时全被 isSourceCoolDown 滤掉 → targets 空 → pool13
# 兜底“全冷却时照常用”不过滤冷却、全加回来 → 三源又被重跑一遍、又挂、又冷却，8 档全是这样。
# pool25 的冷却被 pool13 兜底架空了。修法：兜底只重试冷却已久（>60 秒，可能已恢复）的源；
# 刚冷却（60 秒内，还剩 4 分钟以上）是刚死的，不重试，本档直接 fail-fast（tryQuality 进下一档也是空靶快过）。
# 保留：pool13 的防全瘫意图（冷却久了仍可重试）；excludedIds 仍尊重；不改 tryQuality 的档位循环。
python3 << 'PYEOF27'
import os

def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/avbox/osc/ui/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
    assert os.path.exists("avbox/app/src/main/java/com/github/avbox/osc/ui/MusicHomeActivity.kt"), "find_root 失败"

def rep(src, old, new, name):
    assert src.count(old) == 1, "pool27 锚点 %s: %d" % (name, src.count(old))
    return src.replace(old, new, 1)

find_root()
M = "avbox/app/src/main/java/com/github/avbox/osc/ui/LxPlayerActivity.kt"
s = open(M, encoding="utf-8").read()
if "[39pool27]" in s:
    print("跳过（39 pool27 已应用）")
else:
    old = """        // [39pool13] 全冷却时照常用：若过滤后为空，则不过滤冷却、全部源都进列表
        if (targets.isEmpty()) {
            for ((id, eng) in allEngines) {
                if (id in excludedIds) continue
                targets.add(id to eng)
            }
        }"""
    assert s.count(old) == 1, "pool27 锚点 fallback 数量异常"
    new = """        // [39pool13][39pool27] 全冷却时只重试冷却已久的源：刚冷却（60 秒内）是刚死的，不重试，免得每档白跑；冷却已久（60 秒以上）可能已恢复，才重试
        if (targets.isEmpty()) {
            val now27 = System.currentTimeMillis()
            for ((id, eng) in allEngines) {
                if (id in excludedIds) continue
                val coolUntil = sourceCoolDownUntil[id] ?: 0L
                if (coolUntil - now27 > 240000L) continue // [39pool27] 刚冷却不久（还剩 4 分钟以上），跳过不重试
                targets.add(id to eng)
            }
        }"""
    s = s.replace(old, new, 1)
    # 自检
    assert "[39pool27]" in s, "pool27 标记未落"
    assert s.count("fun resolveUrlWithFallback") == 1, "pool27 函数数量异常"
    assert s.count("fun raceNativeUrl") == 1, "pool27 raceNativeUrl 数量异常"
    assert s.count("(") == s.count(")"), "pool27 全文件圆括号不平衡"
    assert s.count("{") == s.count("}"), "pool27 全文件花括号不平衡"
    assert s.count("[") == s.count("]"), "pool27 全文件方括号不平衡"
    open(M, "w", encoding="utf-8").write(s)
    print("OK 39pool27 全冷却兜底加 60 秒 recency 门完成")
PYEOF27
echo "=== 39pool27 完成 ==="
# === 39pool28: 全冷却兜底加回剩余冷却最短的一源（pool27 回归：全刚冷却时空池） ===
# 根因（11-12 21:17 截图，已装 f2b3a76e）：pool27 的 60 秒门把刚冷却的源全滤掉；
# 三源都在 60 秒内刚冷却时，兜底加回 0 个，targets 空，8 个档位每个都抛“没有可用音源”，
# 歌播不了（“小星星”获取播放地址失败）。pool13 原来的防全瘫意图被收太紧了。
# 修法：在 pool27 过滤之后加一道最终兜底——过滤后仍为空时，加回剩余冷却最短的一源
# （coolUntil 最小、最接近恢复），保出声、不断流。只加回 1 个，不改回无条件全加
# （那会把 pool27 废掉）；excludedIds 仍尊重；不改 tryQuality 的档位循环、pool25 冷却。
python3 << 'PYEOF28'
import os

def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/avbox/osc/ui/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
    assert os.path.exists("avbox/app/src/main/java/com/github/avbox/osc/ui/MusicHomeActivity.kt"), "find_root 失败"

def rep(src, old, new, name):
    assert src.count(old) == 1, "pool28 锚点 %s: %d" % (name, src.count(old))
    return src.replace(old, new, 1)

find_root()
M = "avbox/app/src/main/java/com/github/avbox/osc/ui/LxPlayerActivity.kt"
s = open(M, encoding="utf-8").read()
if "[39pool28]" in s:
    print("跳过（39 pool28 已应用）")
else:
    old = """        // [39pool13][39pool27] 全冷却时只重试冷却已久的源：刚冷却（60 秒内）是刚死的，不重试，免得每档白跑；冷却已久（60 秒以上）可能已恢复，才重试
        if (targets.isEmpty()) {
            val now27 = System.currentTimeMillis()
            for ((id, eng) in allEngines) {
                if (id in excludedIds) continue
                val coolUntil = sourceCoolDownUntil[id] ?: 0L
                if (coolUntil - now27 > 240000L) continue // [39pool27] 刚冷却不久（还剩 4 分钟以上），跳过不重试
                targets.add(id to eng)
            }
        }"""
    assert s.count(old) == 1, "pool28 锚点 fallback 数量异常"
    new = """        // [39pool13][39pool27][39pool28] 全冷却时只重试冷却已久的源：刚冷却（60 秒内）是刚死的，不重试，免得每档白跑；冷却已久（60 秒以上）可能已恢复，才重试；若过滤后仍为空（全源刚冷却），加回剩余冷却最短的一源保出声
        if (targets.isEmpty()) {
            val now27 = System.currentTimeMillis()
            for ((id, eng) in allEngines) {
                if (id in excludedIds) continue
                val coolUntil = sourceCoolDownUntil[id] ?: 0L
                if (coolUntil - now27 > 240000L) continue // [39pool27] 刚冷却不久（还剩 4 分钟以上），跳过不重试
                targets.add(id to eng)
            }
            // [39pool28] 最终兜底：过滤后仍为空（全源都是刚冷却），加回剩余冷却最短的一源保出声、不断流
            if (targets.isEmpty()) {
                var bestPair: Pair<String, LxScriptEngine>? = null
                var bestUntil = Long.MAX_VALUE
                for ((id, eng) in allEngines) {
                    if (id in excludedIds) continue
                    val coolUntil = sourceCoolDownUntil[id] ?: 0L
                    if (coolUntil < bestUntil) {
                        bestUntil = coolUntil
                        bestPair = id to eng
                    }
                }
                if (bestPair != null) {
                    targets.add(bestPair)
                }
            }
        }"""
    s = s.replace(old, new, 1)
    # 自检
    assert "[39pool28]" in s, "pool28 标记未落"
    assert s.count("fun resolveUrlWithFallback") == 1, "pool28 函数数量异常"
    assert s.count("fun raceNativeUrl") == 1, "pool28 raceNativeUrl 数量异常"
    assert s.count("(") == s.count(")"), "pool28 全文件圆括号不平衡"
    assert s.count("{") == s.count("}"), "pool28 全文件花括号不平衡"
    assert s.count("[") == s.count("]"), "pool28 全文件方括号不平衡"
    open(M, "w", encoding="utf-8").write(s)
    print("OK 39pool28 全冷却兜底加回剩余冷却最短的一源完成")
PYEOF28
echo "=== 39pool28 完成 ==="
