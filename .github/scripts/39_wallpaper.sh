#!/bin/bash
# 39_wallpaper.sh [39wp5] 自定义壁纸：Manager(图/渐变双模式+Peek三件:文字模式/不透明度/模糊) + 设置页(效果调整) + 在线壁纸库(真实源:搜图神器) + MusicHome 根注入(壁纸层+Scrim+Local色覆盖) + 六页根透出 + 搜索框玻璃化
set -e
cd "$(dirname "$0")/../.." 2>/dev/null || true
mkdir -p avbox/app/src/main/java/com/github/tvbox/osc/ui/activity
TMPB64=$(mktemp)
    printf '%s' 'cGFja2FnZSBjb20uZ2l0aHViLnR2Ym94Lm9zYy51aS5hY3Rpdml0eQoKaW1wb3J0IGFuZHJvaWQuY29udGVudC5Db250ZXh0Cmlt' >> "$TMPB64"
    printf '%s' 'cG9ydCBhbmRyb2lkLmdyYXBoaWNzLkJpdG1hcAppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5ydW50aW1lLkNvbXBvc2FibGUKaW1w' >> "$TMPB64"
    printf '%s' 'b3J0IGFuZHJvaWR4LmNvbXBvc2UucnVudGltZS5jb2xsZWN0QXNTdGF0ZQppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5ydW50aW1l' >> "$TMPB64"
    printf '%s' 'LmdldFZhbHVlCmltcG9ydCBrb3RsaW54LmNvcm91dGluZXMuZmxvdy5NdXRhYmxlU3RhdGVGbG93CmltcG9ydCBrb3RsaW54LmNv' >> "$TMPB64"
    printf '%s' 'cm91dGluZXMuZmxvdy5TdGF0ZUZsb3cKCi8vIFszOXdwNV0g5aOB57q45qih57OK5Y+Y5o2iKENvaWwgY29pbC50cmFuc2Zvcm0u' >> "$TMPB64"
    printf '%s' 'VHJhbnNmb3JtYXRpb24g5o6l5Y+jLCBkZXgg5a6e6K+B562+5ZCNKTog57yp5bCPICsg5LiJ6L2u5Y+v5YiG56a755uS5byP5qih' >> "$TMPB64"
    printf '%s' '57OKKOi/keS8vOmrmOaWrywg5a+56b2QIFBlZWsg55qEIEltYWdlRmlsdGVyIOmrmOaWryBzaWdtYSDor63kuYkp5YaN5pS+5aSn' >> "$TMPB64"
    printf '%s' 'LCDlhaggQVBJIOWPr+eUqDsg5Y2K5b6E6L+b57yT5a2Y6ZSu6Ziy5Liy5Zu+CmNsYXNzIFdwQmx1clRyYW5zZm9ybWF0aW9uKHBy' >> "$TMPB64"
    printf '%s' 'aXZhdGUgdmFsIHJhZGl1czogSW50KSA6IGNvaWwudHJhbnNmb3JtLlRyYW5zZm9ybWF0aW9uIHsKICAgIG92ZXJyaWRlIHZhbCBj' >> "$TMPB64"
    printf '%s' 'YWNoZUtleTogU3RyaW5nID0gIndwYmx1cl92Ml8kcmFkaXVzIgogICAgb3ZlcnJpZGUgc3VzcGVuZCBmdW4gdHJhbnNmb3JtKGlu' >> "$TMPB64"
    printf '%s' 'cHV0OiBCaXRtYXAsIHNpemU6IGNvaWwuc2l6ZS5TaXplKTogQml0bWFwIHsKICAgICAgICBpZiAocmFkaXVzIDw9IDApIHJldHVy' >> "$TMPB64"
    printf '%s' 'biBpbnB1dAogICAgICAgIHZhbCBzcmMgPSBpZiAoaW5wdXQuY29uZmlnID09IEJpdG1hcC5Db25maWcuSEFSRFdBUkUpIGlucHV0' >> "$TMPB64"
    printf '%s' 'LmNvcHkoQml0bWFwLkNvbmZpZy5BUkdCXzg4ODgsIGZhbHNlKSBlbHNlIGlucHV0CiAgICAgICAgdmFsIHcgPSBzcmMud2lkdGg7' >> "$TMPB64"
    printf '%s' 'IHZhbCBoID0gc3JjLmhlaWdodAogICAgICAgIGlmICh3IDw9IDAgfHwgaCA8PSAwKSByZXR1cm4gc3JjCiAgICAgICAgLy8g5YWI' >> "$TMPB64"
    printf '%s' '57yp5Yiw5a69IDw9NTQwKOWPjOe6v+aApyk6IOaPkOmAnzsg6auY5pavIHNpZ21hIOaMiee8qeaUvuavlOaKmOeul+i/m+Wwj+Wb' >> "$TMPB64"
    printf '%s' 'vuepuumXtAogICAgICAgIHZhbCBzY2FsZSA9IGlmICh3ID4gNTQwKSA1NDBmIC8gdyBlbHNlIDFmCiAgICAgICAgdmFsIHNtYWxs' >> "$TMPB64"
    printf '%s' 'MCA9IGlmIChzY2FsZSA8IDFmKSBCaXRtYXAuY3JlYXRlU2NhbGVkQml0bWFwKHNyYywgbWF4T2YoMSwgKHcgKiBzY2FsZSkudG9J' >> "$TMPB64"
    printf '%s' 'bnQoKSksIG1heE9mKDEsIChoICogc2NhbGUpLnRvSW50KCkpLCB0cnVlKSBlbHNlIHNyYwogICAgICAgIHZhbCBzaWdtYVMgPSBy' >> "$TMPB64"
    printf '%s' 'YWRpdXMgKiBzY2FsZQogICAgICAgIHZhbCBiciA9IGJveFJhZGl1c0ZvcihzaWdtYVMpCiAgICAgICAgdmFyIHNtYWxsID0gc21h' >> "$TMPB64"
    printf '%s' 'bGwwCiAgICAgICAgaWYgKGJyID4gMCkgcmVwZWF0KDMpIHsgc21hbGwgPSBib3hCbHVyKHNtYWxsLCBicikgfQogICAgICAgIHZh' >> "$TMPB64"
    printf '%s' 'bCB1cCA9IGlmIChzY2FsZSA8IDFmKSBCaXRtYXAuY3JlYXRlU2NhbGVkQml0bWFwKHNtYWxsLCB3LCBoLCB0cnVlKSBlbHNlIHNt' >> "$TMPB64"
    printf '%s' 'YWxsCiAgICAgICAgaWYgKHNtYWxsICE9PSBzcmMgJiYgc21hbGwgIT09IHVwKSBzbWFsbC5yZWN5Y2xlKCkKICAgICAgICByZXR1' >> "$TMPB64"
    printf '%s' 'cm4gdXAKICAgIH0KICAgIC8vIFszOXdwNV0g5LiJ6L2u55uS5byP6L+R5Ly86auY5pav5pe2LCDljZXova7nm5LljYrlvoTkuI7n' >> "$TMPB64"
    printf '%s' 'm67moIcgc2lnbWEg55qE5o2i566XOiB3PXNxcnQoMTIqc2lnbWFeMi8zKzEpLCByPSh3LTEpLzIKICAgIHByaXZhdGUgZnVuIGJv' >> "$TMPB64"
    printf '%s' 'eFJhZGl1c0ZvcihzaWdtYTogRmxvYXQpOiBJbnQgewogICAgICAgIGlmIChzaWdtYSA8IDAuNWYpIHJldHVybiAwCiAgICAgICAg' >> "$TMPB64"
    printf '%s' 'dmFsIGJ3ID0ga290bGluLm1hdGguc3FydCgxMmYgKiBzaWdtYSAqIHNpZ21hIC8gM2YgKyAxZikKICAgICAgICByZXR1cm4gKChi' >> "$TMPB64"
    printf '%s' 'dyAtIDFmKSAvIDJmKS50b0ludCgpLmNvZXJjZUluKDEsIDYwKQogICAgfQogICAgLy8gWzM5d3A1XSDlj6/liIbnprvnm5LlvI/m' >> "$TMPB64"
    printf '%s' 'qKHns4o6IOa7keeql+Wdh+WAvCwg5qiq56uW5ZCE5LiA6LafCiAgICBwcml2YXRlIGZ1biBib3hCbHVyKHNyY0JtcDogQml0bWFw' >> "$TMPB64"
    printf '%s' 'LCByOiBJbnQpOiBCaXRtYXAgewogICAgICAgIHZhbCB3ID0gc3JjQm1wLndpZHRoCiAgICAgICAgdmFsIGggPSBzcmNCbXAuaGVp' >> "$TMPB64"
    printf '%s' 'Z2h0CiAgICAgICAgdmFsIGNudCA9IDIgKiByICsgMQogICAgICAgIHZhbCBweCA9IEludEFycmF5KHcgKiBoKQogICAgICAgIHNy' >> "$TMPB64"
    printf '%s' 'Y0JtcC5nZXRQaXhlbHMocHgsIDAsIHcsIDAsIDAsIHcsIGgpCiAgICAgICAgdmFsIHRtcCA9IEludEFycmF5KHcgKiBoKQogICAg' >> "$TMPB64"
    printf '%s' 'ICAgIGZvciAoeSBpbiAwIHVudGlsIGgpIHsKICAgICAgICAgICAgdmFsIHJvdyA9IHkgKiB3CiAgICAgICAgICAgIHZhciBzYSA9' >> "$TMPB64"
    printf '%s' 'IDA7IHZhciBzciA9IDA7IHZhciBzZyA9IDA7IHZhciBzYiA9IDAKICAgICAgICAgICAgZm9yIChpIGluIC1yLi5yKSB7IHZhbCBj' >> "$TMPB64"
    printf '%s' 'ID0gcHhbcm93ICsgaS5jb2VyY2VJbigwLCB3IC0gMSldOyBzYSArPSBjIHVzaHIgMjQ7IHNyICs9IChjIHNociAxNikgYW5kIDB4' >> "$TMPB64"
    printf '%s' 'RkY7IHNnICs9IChjIHNociA4KSBhbmQgMHhGRjsgc2IgKz0gYyBhbmQgMHhGRiB9CiAgICAgICAgICAgIGZvciAoeCBpbiAwIHVu' >> "$TMPB64"
    printf '%s' 'dGlsIHcpIHsKICAgICAgICAgICAgICAgIHRtcFtyb3cgKyB4XSA9ICgoc2EgLyBjbnQpIHNobCAyNCkgb3IgKChzciAvIGNudCkg' >> "$TMPB64"
    printf '%s' 'c2hsIDE2KSBvciAoKHNnIC8gY250KSBzaGwgOCkgb3IgKHNiIC8gY250KQogICAgICAgICAgICAgICAgdmFsIGNhID0gcHhbcm93' >> "$TMPB64"
    printf '%s' 'ICsgKHggKyByICsgMSkuY29lcmNlSW4oMCwgdyAtIDEpXQogICAgICAgICAgICAgICAgdmFsIGNzID0gcHhbcm93ICsgKHggLSBy' >> "$TMPB64"
    printf '%s' 'KS5jb2VyY2VJbigwLCB3IC0gMSldCiAgICAgICAgICAgICAgICBzYSArPSAoY2EgdXNociAyNCkgLSAoY3MgdXNociAyNCk7IHNy' >> "$TMPB64"
    printf '%s' 'ICs9ICgoY2Egc2hyIDE2KSBhbmQgMHhGRikgLSAoKGNzIHNociAxNikgYW5kIDB4RkYpOyBzZyArPSAoKGNhIHNociA4KSBhbmQg' >> "$TMPB64"
    printf '%s' 'MHhGRikgLSAoKGNzIHNociA4KSBhbmQgMHhGRik7IHNiICs9IChjYSBhbmQgMHhGRikgLSAoY3MgYW5kIDB4RkYpCiAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgIH0KICAgICAgICB9CiAgICAgICAgdmFsIG91dCA9IEludEFycmF5KHcgKiBoKQogICAgICAgIGZvciAoeCBpbiAwIHVudGls' >> "$TMPB64"
    printf '%s' 'IHcpIHsKICAgICAgICAgICAgdmFyIHNhID0gMDsgdmFyIHNyID0gMDsgdmFyIHNnID0gMDsgdmFyIHNiID0gMAogICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICBmb3IgKGkgaW4gLXIuLnIpIHsgdmFsIGMgPSB0bXBbaS5jb2VyY2VJbigwLCBoIC0gMSkgKiB3ICsgeF07IHNhICs9IGMgdXNo' >> "$TMPB64"
    printf '%s' 'ciAyNDsgc3IgKz0gKGMgc2hyIDE2KSBhbmQgMHhGRjsgc2cgKz0gKGMgc2hyIDgpIGFuZCAweEZGOyBzYiArPSBjIGFuZCAweEZG' >> "$TMPB64"
    printf '%s' 'IH0KICAgICAgICAgICAgZm9yICh5IGluIDAgdW50aWwgaCkgewogICAgICAgICAgICAgICAgb3V0W3kgKiB3ICsgeF0gPSAoKHNh' >> "$TMPB64"
    printf '%s' 'IC8gY250KSBzaGwgMjQpIG9yICgoc3IgLyBjbnQpIHNobCAxNikgb3IgKChzZyAvIGNudCkgc2hsIDgpIG9yIChzYiAvIGNudCkK' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgIHZhbCBjYSA9IHRtcFsoeSArIHIgKyAxKS5jb2VyY2VJbigwLCBoIC0gMSkgKiB3ICsgeF0KICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgIHZhbCBjcyA9IHRtcFsoeSAtIHIpLmNvZXJjZUluKDAsIGggLSAxKSAqIHcgKyB4XQogICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'c2EgKz0gKGNhIHVzaHIgMjQpIC0gKGNzIHVzaHIgMjQpOyBzciArPSAoKGNhIHNociAxNikgYW5kIDB4RkYpIC0gKChjcyBzaHIg' >> "$TMPB64"
    printf '%s' 'MTYpIGFuZCAweEZGKTsgc2cgKz0gKChjYSBzaHIgOCkgYW5kIDB4RkYpIC0gKChjcyBzaHIgOCkgYW5kIDB4RkYpOyBzYiArPSAo' >> "$TMPB64"
    printf '%s' 'Y2EgYW5kIDB4RkYpIC0gKGNzIGFuZCAweEZGKQogICAgICAgICAgICB9CiAgICAgICAgfQogICAgICAgIHZhbCBibXAgPSBCaXRt' >> "$TMPB64"
    printf '%s' 'YXAuY3JlYXRlQml0bWFwKHcsIGgsIEJpdG1hcC5Db25maWcuQVJHQl84ODg4KQogICAgICAgIGJtcC5zZXRQaXhlbHMob3V0LCAw' >> "$TMPB64"
    printf '%s' 'LCB3LCAwLCAwLCB3LCBoKQogICAgICAgIHJldHVybiBibXAKICAgIH0KfQoKLy8gWzM5d3AxXSDoh6rlrprkuYnlo4HnurjvvJrn' >> "$TMPB64"
    printf '%s' 'irbmgIEgKyDmjIHkuYXljJbvvIjojIPlvI/lkIwgTXVzaWNUaGVtZU1hbmFnZXLvvJpvYmplY3QgKyBwcmVmcyArIFN0YXRlRmxv' >> "$TMPB64"
    printf '%s' 'd++8iQpvYmplY3QgV2FsbHBhcGVyTWFuYWdlciB7CiAgICBwcml2YXRlIGNvbnN0IHZhbCBQUkVGUyA9ICJ3YWxscGFwZXJfcHJl' >> "$TMPB64"
    printf '%s' 'ZnMiCiAgICBwcml2YXRlIGNvbnN0IHZhbCBLRVlfRU5BQkxFRCA9ICJlbmFibGVXYWxscGFwZXIiCiAgICBwcml2YXRlIGNvbnN0' >> "$TMPB64"
    printf '%s' 'IHZhbCBLRVlfVVJMID0gIndhbGxwYXBlclVybCIKICAgIHByaXZhdGUgY29uc3QgdmFsIEtFWV9ISVNUT1JZID0gIndhbGxwYXBl' >> "$TMPB64"
    printf '%s' 'ckhpc3RvcnkiCiAgICBwcml2YXRlIGNvbnN0IHZhbCBLRVlfTU9ERSA9ICJ3YWxscGFwZXJNb2RlIgogICAgcHJpdmF0ZSBjb25z' >> "$TMPB64"
    printf '%s' 'dCB2YWwgS0VZX0dSQURJRU5UID0gImdyYWRpZW50Q29sb3JzIgogICAgcHJpdmF0ZSBjb25zdCB2YWwgS0VZX1RFWFRNT0RFID0g' >> "$TMPB64"
    printf '%s' 'IndhbGxwYXBlclRleHRNb2RlIgogICAgcHJpdmF0ZSBjb25zdCB2YWwgS0VZX1NDUklNID0gIndhbGxwYXBlclNjcmltIgogICAg' >> "$TMPB64"
    printf '%s' 'cHJpdmF0ZSBjb25zdCB2YWwgS0VZX09QQUNJVFkgPSAid2FsbHBhcGVyT3BhY2l0eSIKICAgIHByaXZhdGUgY29uc3QgdmFsIEtF' >> "$TMPB64"
    printf '%s' 'WV9CTFVSID0gIndhbGxwYXBlckJsdXIiCgogICAgZGF0YSBjbGFzcyBTdGF0ZSgKICAgICAgICB2YWwgZW5hYmxlZDogQm9vbGVh' >> "$TMPB64"
    printf '%s' 'biA9IGZhbHNlLAogICAgICAgIHZhbCB1cmw6IFN0cmluZyA9ICIiLAogICAgICAgIHZhbCBoaXN0b3J5OiBMaXN0PFN0cmluZz4g' >> "$TMPB64"
    printf '%s' 'PSBlbXB0eUxpc3QoKSwKICAgICAgICB2YWwgbW9kZTogU3RyaW5nID0gImltYWdlIiwKICAgICAgICB2YWwgZ3JhZGllbnQ6IFN0' >> "$TMPB64"
    printf '%s' 'cmluZyA9ICIiLAogICAgICAgIHZhbCB0ZXh0TW9kZTogU3RyaW5nID0gImF1dG8iLAogICAgICAgIHZhbCBzY3JpbTogSW50ID0g' >> "$TMPB64"
    printf '%s' 'MCwKICAgICAgICB2YWwgb3BhY2l0eTogSW50ID0gMTAwLAogICAgICAgIHZhbCBibHVyOiBJbnQgPSAwLAogICAgKQoKICAgIHBy' >> "$TMPB64"
    printf '%s' 'aXZhdGUgdmFsIF9zdGF0ZSA9IE11dGFibGVTdGF0ZUZsb3coU3RhdGUoKSkKICAgIHZhbCBzdGF0ZTogU3RhdGVGbG93PFN0YXRl' >> "$TMPB64"
    printf '%s' 'PiA9IF9zdGF0ZQoKICAgIHByaXZhdGUgZnVuIHByZWZzKGN0eDogQ29udGV4dCkgPSBjdHguZ2V0U2hhcmVkUHJlZmVyZW5jZXMo' >> "$TMPB64"
    printf '%s' 'UFJFRlMsIENvbnRleHQuTU9ERV9QUklWQVRFKQoKICAgIGZ1biBpbml0KGN0eDogQ29udGV4dCkgewogICAgICAgIHRyeSB7CiAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgIHZhbCBwID0gcHJlZnMoY3R4KQogICAgICAgICAgICB2YWwgaGlzdCA9IChwLmdldFN0cmluZyhLRVlfSElTVE9S' >> "$TMPB64"
    printf '%s' 'WSwgIiIpID86ICIiKS5zcGxpdCgiXG4iKS5maWx0ZXIgeyBpdC5pc05vdEJsYW5rKCkgfQogICAgICAgICAgICBfc3RhdGUudmFs' >> "$TMPB64"
    printf '%s' 'dWUgPSBTdGF0ZSgKICAgICAgICAgICAgICAgIGVuYWJsZWQgPSBwLmdldEJvb2xlYW4oS0VZX0VOQUJMRUQsIGZhbHNlKSwKICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgIHVybCA9IHAuZ2V0U3RyaW5nKEtFWV9VUkwsICIiKSA/OiAiIiwKICAgICAgICAgICAgICAgIGhpc3Rvcnkg' >> "$TMPB64"
    printf '%s' 'PSBoaXN0LAogICAgICAgICAgICAgICAgbW9kZSA9IHAuZ2V0U3RyaW5nKEtFWV9NT0RFLCAiaW1hZ2UiKSA/OiAiaW1hZ2UiLAog' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgZ3JhZGllbnQgPSBwLmdldFN0cmluZyhLRVlfR1JBRElFTlQsICIiKSA/OiAiIiwKICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgIHRleHRNb2RlID0gcC5nZXRTdHJpbmcoS0VZX1RFWFRNT0RFLCAiYXV0byIpID86ICJhdXRvIiwKICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'IHNjcmltID0gcC5nZXRJbnQoS0VZX1NDUklNLCAwKS5jb2VyY2VBdExlYXN0KDApLCAvLyBbMzl3cDVdIOWtmOmHjyAtMSjml6fo' >> "$TMPB64"
    printf '%s' 'h6rliqgpIOW9kiAwIOaXoOe6sQogICAgICAgICAgICAgICAgb3BhY2l0eSA9IHAuZ2V0SW50KEtFWV9PUEFDSVRZLCAxMDApLAog' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgYmx1ciA9IHAuZ2V0SW50KEtFWV9CTFVSLCAwKSwKICAgICAgICAgICAgKQogICAgICAgIH0gY2F0Y2gg' >> "$TMPB64"
    printf '%s' 'KGU6IEV4Y2VwdGlvbikgewogICAgICAgICAgICBhbmRyb2lkLnV0aWwuTG9nLncoIldhbGxwYXBlciIsICLlo4HnurjnirbmgIHo' >> "$TMPB64"
    printf '%s' 'r7vlj5blpLHotKUiLCBlKQogICAgICAgIH0KICAgIH0KCiAgICBmdW4gc2V0RW5hYmxlZChjdHg6IENvbnRleHQsIG9uOiBCb29s' >> "$TMPB64"
    printf '%s' 'ZWFuKSB7CiAgICAgICAgdHJ5IHsKICAgICAgICAgICAgcHJlZnMoY3R4KS5lZGl0KCkucHV0Qm9vbGVhbihLRVlfRU5BQkxFRCwg' >> "$TMPB64"
    printf '%s' 'b24pLmFwcGx5KCkKICAgICAgICB9IGNhdGNoIChlOiBFeGNlcHRpb24pIHsKICAgICAgICAgICAgYW5kcm9pZC51dGlsLkxvZy53' >> "$TMPB64"
    printf '%s' 'KCJXYWxscGFwZXIiLCAi5aOB57q45byA5YWz5L+d5a2Y5aSx6LSlIiwgZSkKICAgICAgICB9CiAgICAgICAgX3N0YXRlLnZhbHVl' >> "$TMPB64"
    printf '%s' 'ID0gX3N0YXRlLnZhbHVlLmNvcHkoZW5hYmxlZCA9IG9uKQogICAgfQoKICAgIC8vIOW6lOeUqOS4gOW8oOWjgee6uO+8iFVSTCDm' >> "$TMPB64"
    printf '%s' 'iJbmnKzlnLAgVVJJ77yJ77ya5a2Y5Li65b2T5YmN44CB6aG25Yiw5Y6G5Y+y5pyA5YmN77yI5Y676YeN44CB5LiK6ZmQIDbvvInj' >> "$TMPB64"
    printf '%s' 'gIHoh6rliqjlvIDlkK8KICAgIGZ1biBhcHBseShjdHg6IENvbnRleHQsIHVybDogU3RyaW5nKSB7CiAgICAgICAgdmFsIHUgPSB1' >> "$TMPB64"
    printf '%s' 'cmwudHJpbSgpCiAgICAgICAgaWYgKHUuaXNCbGFuaygpKSByZXR1cm4KICAgICAgICB2YWwgaGlzdCA9IChsaXN0T2YodSkgKyBf' >> "$TMPB64"
    printf '%s' 'c3RhdGUudmFsdWUuaGlzdG9yeS5maWx0ZXIgeyBpdCAhPSB1IH0pLnRha2UoNikKICAgICAgICB0cnkgewogICAgICAgICAgICBw' >> "$TMPB64"
    printf '%s' 'cmVmcyhjdHgpLmVkaXQoKQogICAgICAgICAgICAgICAgLnB1dFN0cmluZyhLRVlfVVJMLCB1KQogICAgICAgICAgICAgICAgLnB1' >> "$TMPB64"
    printf '%s' 'dFN0cmluZyhLRVlfSElTVE9SWSwgaGlzdC5qb2luVG9TdHJpbmcoIlxuIikpCiAgICAgICAgICAgICAgICAucHV0U3RyaW5nKEtF' >> "$TMPB64"
    printf '%s' 'WV9NT0RFLCAiaW1hZ2UiKQogICAgICAgICAgICAgICAgLnB1dEJvb2xlYW4oS0VZX0VOQUJMRUQsIHRydWUpCiAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAuYXBwbHkoKQogICAgICAgIH0gY2F0Y2ggKGU6IEV4Y2VwdGlvbikgewogICAgICAgICAgICBhbmRyb2lkLnV0aWwuTG9n' >> "$TMPB64"
    printf '%s' 'LncoIldhbGxwYXBlciIsICLlo4HnurjlupTnlKjkv53lrZjlpLHotKUiLCBlKQogICAgICAgIH0KICAgICAgICBfc3RhdGUudmFs' >> "$TMPB64"
    printf '%s' 'dWUgPSBfc3RhdGUudmFsdWUuY29weShlbmFibGVkID0gdHJ1ZSwgdXJsID0gdSwgaGlzdG9yeSA9IGhpc3QsIG1vZGUgPSAiaW1h' >> "$TMPB64"
    printf '%s' 'Z2UiKQogICAgfQoKICAgIC8vIFszOXdwMl0g5bqU55So5riQ5Y+Y6IOM5pmvOiDlrZjkuKTkuKogSGV4KOmAl+WPt+aLvOaOpSkg' >> "$TMPB64"
    printf '%s' 'KyDliIfmqKHlvI8gKyDoh6rliqjlvIDlkK8KICAgIGZ1biBhcHBseUdyYWRpZW50KGN0eDogQ29udGV4dCwgaGV4UGFpcjogU3Ry' >> "$TMPB64"
    printf '%s' 'aW5nKSB7CiAgICAgICAgdmFsIGcgPSBoZXhQYWlyLnRyaW0oKQogICAgICAgIGlmIChnLmlzQmxhbmsoKSkgcmV0dXJuCiAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgdHJ5IHsKICAgICAgICAgICAgcHJlZnMoY3R4KS5lZGl0KCkKICAgICAgICAgICAgICAgIC5wdXRTdHJpbmcoS0VZX0dSQURJ' >> "$TMPB64"
    printf '%s' 'RU5ULCBnKQogICAgICAgICAgICAgICAgLnB1dFN0cmluZyhLRVlfTU9ERSwgImdyYWRpZW50IikKICAgICAgICAgICAgICAgIC5w' >> "$TMPB64"
    printf '%s' 'dXRCb29sZWFuKEtFWV9FTkFCTEVELCB0cnVlKQogICAgICAgICAgICAgICAgLmFwcGx5KCkKICAgICAgICB9IGNhdGNoIChlOiBF' >> "$TMPB64"
    printf '%s' 'eGNlcHRpb24pIHsKICAgICAgICAgICAgYW5kcm9pZC51dGlsLkxvZy53KCJXYWxscGFwZXIiLCAi5riQ5Y+Y5bqU55So5L+d5a2Y' >> "$TMPB64"
    printf '%s' '5aSx6LSlIiwgZSkKICAgICAgICB9CiAgICAgICAgX3N0YXRlLnZhbHVlID0gX3N0YXRlLnZhbHVlLmNvcHkoZW5hYmxlZCA9IHRy' >> "$TMPB64"
    printf '%s' 'dWUsIG1vZGUgPSAiZ3JhZGllbnQiLCBncmFkaWVudCA9IGcpCiAgICB9CgogICAgLy8gWzM5d3A0XSDmloflrZfpopzoibLmqKHl' >> "$TMPB64"
    printf '%s' 'vI86IGF1dG8g6Lef6ZqP5Li76aKYIC8gbGlnaHQg5rWF6Imy5paH5a2XKOW8uuWItua3seiJsuadvykgLyBkYXJrIOa3seiJsuaW' >> "$TMPB64"
    printf '%s' 'h+WtlyjlvLrliLbmtYXoibLmnb8pCiAgICBmdW4gc2V0VGV4dE1vZGUoY3R4OiBDb250ZXh0LCBtb2RlOiBTdHJpbmcpIHsKICAg' >> "$TMPB64"
    printf '%s' 'ICAgICB0cnkgewogICAgICAgICAgICBwcmVmcyhjdHgpLmVkaXQoKS5wdXRTdHJpbmcoS0VZX1RFWFRNT0RFLCBtb2RlKS5hcHBs' >> "$TMPB64"
    printf '%s' 'eSgpCiAgICAgICAgfSBjYXRjaCAoZTogRXhjZXB0aW9uKSB7CiAgICAgICAgICAgIGFuZHJvaWQudXRpbC5Mb2cudygiV2FsbHBh' >> "$TMPB64"
    printf '%s' 'cGVyIiwgIuaWh+Wtl+aooeW8j+S/neWtmOWksei0pSIsIGUpCiAgICAgICAgfQogICAgICAgIF9zdGF0ZS52YWx1ZSA9IF9zdGF0' >> "$TMPB64"
    printf '%s' 'ZS52YWx1ZS5jb3B5KHRleHRNb2RlID0gbW9kZSkKICAgIH0KCiAgICAvLyBbMzl3cDRdIOmBrue9qea1k+W6pijnmb7liIbmr5Qg' >> "$TMPB64"
    printf '%s' 'MC05MDsgLTEgPSDoh6rliqg6IOa3seiJsuadvyA2MCAvIOa1heiJsuadvyA3MCkKICAgIGZ1biBzZXRTY3JpbShjdHg6IENvbnRl' >> "$TMPB64"
    printf '%s' 'eHQsIHBjdDogSW50KSB7CiAgICAgICAgdHJ5IHsKICAgICAgICAgICAgcHJlZnMoY3R4KS5lZGl0KCkucHV0SW50KEtFWV9TQ1JJ' >> "$TMPB64"
    printf '%s' 'TSwgcGN0KS5hcHBseSgpCiAgICAgICAgfSBjYXRjaCAoZTogRXhjZXB0aW9uKSB7CiAgICAgICAgICAgIGFuZHJvaWQudXRpbC5M' >> "$TMPB64"
    printf '%s' 'b2cudygiV2FsbHBhcGVyIiwgIumBrue9qea1k+W6puS/neWtmOWksei0pSIsIGUpCiAgICAgICAgfQogICAgICAgIF9zdGF0ZS52' >> "$TMPB64"
    printf '%s' 'YWx1ZSA9IF9zdGF0ZS52YWx1ZS5jb3B5KHNjcmltID0gcGN0KQogICAgfQoKICAgIC8vIFszOXdwNV0g5Zu+54mH5LiN6YCP5piO' >> "$TMPB64"
    printf '%s' '5bqmKOeZvuWIhuavlCAyMC0xMDA7IOm7mOiupCAxMDAgPSBQZWVrIHdhbGxwYXBlck9wYWNpdHkgMS4wKQogICAgZnVuIHNldE9w' >> "$TMPB64"
    printf '%s' 'YWNpdHkoY3R4OiBDb250ZXh0LCBwY3Q6IEludCkgewogICAgICAgIHRyeSB7CiAgICAgICAgICAgIHByZWZzKGN0eCkuZWRpdCgp' >> "$TMPB64"
    printf '%s' 'LnB1dEludChLRVlfT1BBQ0lUWSwgcGN0KS5hcHBseSgpCiAgICAgICAgfSBjYXRjaCAoZTogRXhjZXB0aW9uKSB7CiAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgIGFuZHJvaWQudXRpbC5Mb2cudygiV2FsbHBhcGVyIiwgIuS4jemAj+aYjuW6puS/neWtmOWksei0pSIsIGUpCiAgICAgICAg' >> "$TMPB64"
    printf '%s' 'fQogICAgICAgIF9zdGF0ZS52YWx1ZSA9IF9zdGF0ZS52YWx1ZS5jb3B5KG9wYWNpdHkgPSBwY3QpCiAgICB9CgogICAgLy8gWzM5' >> "$TMPB64"
    printf '%s' 'd3A1XSDmqKHns4rnqIvluqYoMC0yMDsg6buY6K6kIDAgPSBQZWVrIHdhbGxwYXBlckJsdXIgMC4wKQogICAgZnVuIHNldEJsdXIo' >> "$TMPB64"
    printf '%s' 'Y3R4OiBDb250ZXh0LCB2YWx1ZTogSW50KSB7CiAgICAgICAgdHJ5IHsKICAgICAgICAgICAgcHJlZnMoY3R4KS5lZGl0KCkucHV0' >> "$TMPB64"
    printf '%s' 'SW50KEtFWV9CTFVSLCB2YWx1ZSkuYXBwbHkoKQogICAgICAgIH0gY2F0Y2ggKGU6IEV4Y2VwdGlvbikgewogICAgICAgICAgICBh' >> "$TMPB64"
    printf '%s' 'bmRyb2lkLnV0aWwuTG9nLncoIldhbGxwYXBlciIsICLmqKHns4rnqIvluqbkv53lrZjlpLHotKUiLCBlKQogICAgICAgIH0KICAg' >> "$TMPB64"
    printf '%s' 'ICAgICBfc3RhdGUudmFsdWUgPSBfc3RhdGUudmFsdWUuY29weShibHVyID0gdmFsdWUpCiAgICB9CgogICAgZnVuIHJlbW92ZUhp' >> "$TMPB64"
    printf '%s' 'c3RvcnkoY3R4OiBDb250ZXh0LCB1cmw6IFN0cmluZykgewogICAgICAgIHZhbCBoaXN0ID0gX3N0YXRlLnZhbHVlLmhpc3Rvcnku' >> "$TMPB64"
    printf '%s' 'ZmlsdGVyIHsgaXQgIT0gdXJsIH0KICAgICAgICB0cnkgewogICAgICAgICAgICBwcmVmcyhjdHgpLmVkaXQoKS5wdXRTdHJpbmco' >> "$TMPB64"
    printf '%s' 'S0VZX0hJU1RPUlksIGhpc3Quam9pblRvU3RyaW5nKCJcbiIpKS5hcHBseSgpCiAgICAgICAgfSBjYXRjaCAoZTogRXhjZXB0aW9u' >> "$TMPB64"
    printf '%s' 'KSB7CiAgICAgICAgICAgIGFuZHJvaWQudXRpbC5Mb2cudygiV2FsbHBhcGVyIiwgIuWjgee6uOWOhuWPsuWIoOmZpOWksei0pSIs' >> "$TMPB64"
    printf '%s' 'IGUpCiAgICAgICAgfQogICAgICAgIF9zdGF0ZS52YWx1ZSA9IF9zdGF0ZS52YWx1ZS5jb3B5KGhpc3RvcnkgPSBoaXN0KQogICAg' >> "$TMPB64"
    printf '%s' 'fQoKICAgIC8vIOmhtemdouagueW6leiJsueUqO+8muWjgee6uOeUn+aViOS4reWImemAj+WHuuW6leWxguWjgee6uO+8iOmhtemd' >> "$TMPB64"
    printf '%s' 'ouagueaUuemAj+aYju+8iQogICAgQENvbXBvc2FibGUKICAgIGZ1biBpc0FjdGl2ZSgpOiBCb29sZWFuIHsKICAgICAgICB2YWwg' >> "$TMPB64"
    printf '%s' 'cyBieSBzdGF0ZS5jb2xsZWN0QXNTdGF0ZSgpCiAgICAgICAgcmV0dXJuIHMuZW5hYmxlZCAmJiAocy51cmwuaXNOb3RCbGFuaygp' >> "$TMPB64"
    printf '%s' 'IHx8IHMubW9kZSA9PSAiZ3JhZGllbnQiKQogICAgfQp9Cg==' >> "$TMPB64"
base64 -d "$TMPB64" > avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/WallpaperManager.kt
rm -f "$TMPB64"
grep -q 'object WallpaperManager' avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/WallpaperManager.kt || { echo "X 39 object WallpaperManager 写入失败"; exit 1; }
TMPB64=$(mktemp)
    printf '%s' 'cGFja2FnZSBjb20uZ2l0aHViLnR2Ym94Lm9zYy51aS5hY3Rpdml0eQoKaW1wb3J0IGFuZHJvaWQuY29udGVudC5Db250ZXh0Cmlt' >> "$TMPB64"
    printf '%s' 'cG9ydCBjb20uZ2l0aHViLnR2Ym94Lm9zYy51aS5tdXNpYy5nbGFzcy5Db21wYWN0U2xpZGVyIC8vIFszOXdwc2xpZGVyXQppbXBv' >> "$TMPB64"
    printf '%s' 'cnQgYW5kcm9pZC5jb250ZW50LkludGVudAppbXBvcnQgYW5kcm9pZC5vcy5CdW5kbGUKaW1wb3J0IGFuZHJvaWR4LmFjdGl2aXR5' >> "$TMPB64"
    printf '%s' 'LkNvbXBvbmVudEFjdGl2aXR5CmltcG9ydCBhbmRyb2lkeC5hY3Rpdml0eS5jb21wb3NlLnJlbWVtYmVyTGF1bmNoZXJGb3JBY3Rp' >> "$TMPB64"
    printf '%s' 'dml0eVJlc3VsdAppbXBvcnQgYW5kcm9pZHguYWN0aXZpdHkuY29tcG9zZS5zZXRDb250ZW50CmltcG9ydCBhbmRyb2lkeC5hY3Rp' >> "$TMPB64"
    printf '%s' 'dml0eS5yZXN1bHQuY29udHJhY3QuQWN0aXZpdHlSZXN1bHRDb250cmFjdHMKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UuZm91bmRh' >> "$TMPB64"
    printf '%s' 'dGlvbi5iYWNrZ3JvdW5kCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLmZvdW5kYXRpb24uYm9yZGVyCmltcG9ydCBhbmRyb2lkeC5j' >> "$TMPB64"
    printf '%s' 'b21wb3NlLmZvdW5kYXRpb24uY2xpY2thYmxlCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLmZvdW5kYXRpb24ubGF5b3V0LkFycmFu' >> "$TMPB64"
    printf '%s' 'Z2VtZW50CmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLmZvdW5kYXRpb24ubGF5b3V0LkJveAppbXBvcnQgYW5kcm9pZHguY29tcG9z' >> "$TMPB64"
    printf '%s' 'ZS5mb3VuZGF0aW9uLmxheW91dC5Db2x1bW4KaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UuZm91bmRhdGlvbi5sYXlvdXQuRXhwZXJp' >> "$TMPB64"
    printf '%s' 'bWVudGFsTGF5b3V0QXBpCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLmZvdW5kYXRpb24ubGF5b3V0LkZsb3dSb3cKaW1wb3J0IGFu' >> "$TMPB64"
    printf '%s' 'ZHJvaWR4LmNvbXBvc2UuZm91bmRhdGlvbi5sYXlvdXQuUGFkZGluZ1ZhbHVlcwppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5mb3Vu' >> "$TMPB64"
    printf '%s' 'ZGF0aW9uLmxheW91dC5Sb3cKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UuZm91bmRhdGlvbi5sYXlvdXQuU3BhY2VyCmltcG9ydCBh' >> "$TMPB64"
    printf '%s' 'bmRyb2lkeC5jb21wb3NlLmZvdW5kYXRpb24ubGF5b3V0LmZpbGxNYXhTaXplCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLmZvdW5k' >> "$TMPB64"
    printf '%s' 'YXRpb24ubGF5b3V0LmZpbGxNYXhXaWR0aAppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5mb3VuZGF0aW9uLmxheW91dC5oZWlnaHQK' >> "$TMPB64"
    printf '%s' 'aW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UuZm91bmRhdGlvbi5sYXlvdXQucGFkZGluZwppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5m' >> "$TMPB64"
    printf '%s' 'b3VuZGF0aW9uLmxheW91dC5zaXplCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLmZvdW5kYXRpb24ubGF5b3V0LndpZHRoCmltcG9y' >> "$TMPB64"
    printf '%s' 'dCBhbmRyb2lkeC5jb21wb3NlLmZvdW5kYXRpb24ubGF6eS5MYXp5Q29sdW1uCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLmZvdW5k' >> "$TMPB64"
    printf '%s' 'YXRpb24ubGF6eS5MYXp5Um93CmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLmZvdW5kYXRpb24ubGF6eS5pdGVtcwppbXBvcnQgYW5k' >> "$TMPB64"
    printf '%s' 'cm9pZHguY29tcG9zZS5mb3VuZGF0aW9uLnNoYXBlLlJvdW5kZWRDb3JuZXJTaGFwZQppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5t' >> "$TMPB64"
    printf '%s' 'YXRlcmlhbDMuQnV0dG9uCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLm1hdGVyaWFsMy5CdXR0b25EZWZhdWx0cwppbXBvcnQgYW5k' >> "$TMPB64"
    printf '%s' 'cm9pZHguY29tcG9zZS5tYXRlcmlhbDMuQ2FyZAppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5tYXRlcmlhbDMuQ2FyZERlZmF1bHRz' >> "$TMPB64"
    printf '%s' 'CmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLm1hdGVyaWFsMy5NYXRlcmlhbFRoZW1lCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLm1h' >> "$TMPB64"
    printf '%s' 'dGVyaWFsMy5PdXRsaW5lZEJ1dHRvbgppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5tYXRlcmlhbDMuT3V0bGluZWRUZXh0RmllbGQK' >> "$TMPB64"
    printf '%s' 'aW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UubWF0ZXJpYWwzLk91dGxpbmVkVGV4dEZpZWxkRGVmYXVsdHMKaW1wb3J0IGFuZHJvaWR4' >> "$TMPB64"
    printf '%s' 'LmNvbXBvc2UubWF0ZXJpYWwzLlNsaWRlcgppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5tYXRlcmlhbDMuU2xpZGVyRGVmYXVsdHMK' >> "$TMPB64"
    printf '%s' 'aW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UubWF0ZXJpYWwzLlN3aXRjaAppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5tYXRlcmlhbDMu' >> "$TMPB64"
    printf '%s' 'U3dpdGNoRGVmYXVsdHMKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UubWF0ZXJpYWwzLlRleHQKaW1wb3J0IGFuZHJvaWR4LmNvbXBv' >> "$TMPB64"
    printf '%s' 'c2UucnVudGltZS5Db21wb3NhYmxlCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLnJ1bnRpbWUuU2lkZUVmZmVjdAppbXBvcnQgYW5k' >> "$TMPB64"
    printf '%s' 'cm9pZHguY29tcG9zZS5ydW50aW1lLmNvbGxlY3RBc1N0YXRlCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLnJ1bnRpbWUuZ2V0VmFs' >> "$TMPB64"
    printf '%s' 'dWUKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UucnVudGltZS5tdXRhYmxlU3RhdGVPZgppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5y' >> "$TMPB64"
    printf '%s' 'dW50aW1lLnJlbWVtYmVyCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLnJ1bnRpbWUuc2V0VmFsdWUKaW1wb3J0IGFuZHJvaWR4LmNv' >> "$TMPB64"
    printf '%s' 'bXBvc2UudWkuQWxpZ25tZW50CmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLnVpLk1vZGlmaWVyCmltcG9ydCBhbmRyb2lkeC5jb21w' >> "$TMPB64"
    printf '%s' 'b3NlLnVpLmRyYXcuY2xpcAppbXBvcnQgYW5kcm9pZHguY29tcG9zZS51aS5ncmFwaGljcy5CcnVzaAppbXBvcnQgYW5kcm9pZHgu' >> "$TMPB64"
    printf '%s' 'Y29tcG9zZS51aS5ncmFwaGljcy5Db2xvcgppbXBvcnQgYW5kcm9pZHguY29tcG9zZS51aS5sYXlvdXQuQ29udGVudFNjYWxlCmlt' >> "$TMPB64"
    printf '%s' 'cG9ydCBhbmRyb2lkeC5jb21wb3NlLnVpLnBsYXRmb3JtLkxvY2FsQ29udGV4dAppbXBvcnQgYW5kcm9pZHguY29tcG9zZS51aS50' >> "$TMPB64"
    printf '%s' 'ZXh0LmZvbnQuRm9udFdlaWdodAppbXBvcnQgYW5kcm9pZHguY29tcG9zZS51aS51bml0LmRwCmltcG9ydCBhbmRyb2lkeC5jb3Jl' >> "$TMPB64"
    printf '%s' 'LnZpZXcuV2luZG93Q29tcGF0CmltcG9ydCBjb2lsLmNvbXBvc2UuQXN5bmNJbWFnZQppbXBvcnQgY29pbC5yZXF1ZXN0LkltYWdl' >> "$TMPB64"
    printf '%s' 'UmVxdWVzdAoKLy8gWzM5d3AyXSDmuJDlj5jpooTorr46IOWQjeensCArIOi1t+atoiBIZXgo5YaF5a655pWw5o2u5pys6LqrLCDp' >> "$TMPB64"
    printf '%s' 'nZ4gVUkg6ZOs6ImyKQpwcml2YXRlIHZhbCBXUF9HUkFESUVOVF9QUkVTRVRTID0gbGlzdE9mKAogICAgVHJpcGxlKCLmt7Hmtbfo' >> "$TMPB64"
    printf '%s' 'k50iLCAiIzBGMjAyNyIsICIjMkM1MzY0IiksCiAgICBUcmlwbGUoIuaZmumcnue6oiIsICIjRkY5OTY2IiwgIiNGRjVFNjIiKSwK' >> "$TMPB64"
    printf '%s' 'ICAgIFRyaXBsZSgi5p6B5YWJ57u/IiwgIiMxMTk5OEUiLCAiIzM4RUY3RCIpLAopCgovLyBbMzl3cDRdIOaWh+Wtl+minOiJsuao' >> "$TMPB64"
    printf '%s' 'oeW8j+mAiemhuTog5YC8IC0+IOaYvuekuuWQjQpwcml2YXRlIHZhbCBXUF9URVhUX01PREVTID0gbGlzdE9mKAogICAgImF1dG8i' >> "$TMPB64"
    printf '%s' 'IHRvICLot5/pmo/kuLvpopgiLAogICAgImxpZ2h0IiB0byAi5rWF6Imy5paH5a2XIiwKICAgICJkYXJrIiB0byAi5rex6Imy5paH' >> "$TMPB64"
    printf '%s' '5a2XIiwKKQoKcHJpdmF0ZSBmdW4gd3BQYXJzZUNvbG9yKGhleDogU3RyaW5nKTogQ29sb3IgPQogICAgdHJ5IHsgQ29sb3IoYW5k' >> "$TMPB64"
    printf '%s' 'cm9pZC5ncmFwaGljcy5Db2xvci5wYXJzZUNvbG9yKGhleCkpIH0gY2F0Y2ggKGU6IEV4Y2VwdGlvbikgeyBDb2xvci5HcmF5IH0K' >> "$TMPB64"
    printf '%s' 'Ci8vIFszOXdwMV0g5aOB57q46K6+572u6aG177ya5byA5YWzICsgVVJMIOi+k+WFpSArIOacrOWcsOmAieWbvu+8iOaMgeS5heaO' >> "$TMPB64"
    printf '%s' 'iOadg++8iSsg5Y6G5Y+y5qiq5o6S44CC5Y+q5YaZIFdhbGxwYXBlck1hbmFnZXLjgIIKY2xhc3MgTHhXYWxscGFwZXJTZXR0aW5n' >> "$TMPB64"
    printf '%s' 'c0FjdGl2aXR5IDogQ29tcG9uZW50QWN0aXZpdHkoKSB7CiAgICBvdmVycmlkZSBmdW4gb25DcmVhdGUoc2F2ZWRJbnN0YW5jZVN0' >> "$TMPB64"
    printf '%s' 'YXRlOiBCdW5kbGU/KSB7CiAgICAgICAgc3VwZXIub25DcmVhdGUoc2F2ZWRJbnN0YW5jZVN0YXRlKQogICAgICAgIHZhbCBhcHBD' >> "$TMPB64"
    printf '%s' 'dHggPSBhcHBsaWNhdGlvbkNvbnRleHQKICAgICAgICBNdXNpY1RoZW1lTWFuYWdlci5pbml0KGFwcEN0eCkKICAgICAgICBXYWxs' >> "$TMPB64"
    printf '%s' 'cGFwZXJNYW5hZ2VyLmluaXQoYXBwQ3R4KQogICAgICAgIHNldENvbnRlbnQgewogICAgICAgICAgICB2YWwgaXNEYXJrIGJ5IE11' >> "$TMPB64"
    printf '%s' 'c2ljVGhlbWVNYW5hZ2VyLmlzRGFya1RoZW1lCiAgICAgICAgICAgIHZhbCB3aW5kb3cgPSB0aGlzQEx4V2FsbHBhcGVyU2V0dGlu' >> "$TMPB64"
    printf '%s' 'Z3NBY3Rpdml0eS53aW5kb3cKICAgICAgICAgICAgU2lkZUVmZmVjdCB7CiAgICAgICAgICAgICAgICBXaW5kb3dDb21wYXQuZ2V0' >> "$TMPB64"
    printf '%s' 'SW5zZXRzQ29udHJvbGxlcih3aW5kb3csIHdpbmRvdy5kZWNvclZpZXcpCiAgICAgICAgICAgICAgICAgICAgLmlzQXBwZWFyYW5j' >> "$TMPB64"
    printf '%s' 'ZUxpZ2h0U3RhdHVzQmFycyA9ICFpc0RhcmsKICAgICAgICAgICAgfQogICAgICAgICAgICBMeE11c2ljVGhlbWUoaXNEYXJrVGhl' >> "$TMPB64"
    printf '%s' 'bWUgPSBpc0RhcmspIHsKICAgICAgICAgICAgICAgIFdhbGxwYXBlclNldHRpbmdzU2NyZWVuKG9uQmFjayA9IHsgZmluaXNoKCkg' >> "$TMPB64"
    printf '%s' 'fSkKICAgICAgICAgICAgfQogICAgICAgIH0KICAgIH0KfQoKQE9wdEluKEV4cGVyaW1lbnRhbExheW91dEFwaTo6Y2xhc3MpIC8v' >> "$TMPB64"
    printf '%s' 'IFszOXdwYWRhcHRdIEZsb3dSb3cg6ZyA5a6e6aqMIEFQSSDmoIforrAKQENvbXBvc2FibGUKZnVuIFdhbGxwYXBlclNldHRpbmdz' >> "$TMPB64"
    printf '%s' 'U2NyZWVuKG9uQmFjazogKCkgLT4gVW5pdCkgewogICAgdmFsIGNvbnRleHQgPSBMb2NhbENvbnRleHQuY3VycmVudAogICAgdmFs' >> "$TMPB64"
    printf '%s' 'IHdwU3RhdGUgYnkgV2FsbHBhcGVyTWFuYWdlci5zdGF0ZS5jb2xsZWN0QXNTdGF0ZSgpCiAgICB2YXIgdXJsVGV4dCBieSByZW1l' >> "$TMPB64"
    printf '%s' 'bWJlciB7IG11dGFibGVTdGF0ZU9mKHdwU3RhdGUudXJsKSB9CiAgICB2YWwgcGlja2VyID0gcmVtZW1iZXJMYXVuY2hlckZvckFj' >> "$TMPB64"
    printf '%s' 'dGl2aXR5UmVzdWx0KEFjdGl2aXR5UmVzdWx0Q29udHJhY3RzLk9wZW5Eb2N1bWVudCgpKSB7IHVyaSAtPgogICAgICAgIGlmICh1' >> "$TMPB64"
    printf '%s' 'cmkgIT0gbnVsbCkgewogICAgICAgICAgICB0cnkgewogICAgICAgICAgICAgICAgY29udGV4dC5jb250ZW50UmVzb2x2ZXIudGFr' >> "$TMPB64"
    printf '%s' 'ZVBlcnNpc3RhYmxlVXJpUGVybWlzc2lvbih1cmksIEludGVudC5GTEFHX0dSQU5UX1JFQURfVVJJX1BFUk1JU1NJT04pCiAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgIH0gY2F0Y2ggKGU6IEV4Y2VwdGlvbikgewogICAgICAgICAgICAgICAgYW5kcm9pZC51dGlsLkxvZy53KCJXYWxscGFw' >> "$TMPB64"
    printf '%s' 'ZXIiLCAi5pys5Zyw5Zu+5oyB5LmF5o6I5p2D5aSx6LSlIiwgZSkKICAgICAgICAgICAgfQogICAgICAgICAgICBXYWxscGFwZXJN' >> "$TMPB64"
    printf '%s' 'YW5hZ2VyLmFwcGx5KGNvbnRleHQsIHVyaS50b1N0cmluZygpKQogICAgICAgICAgICB1cmxUZXh0ID0gdXJpLnRvU3RyaW5nKCkK' >> "$TMPB64"
    printf '%s' 'ICAgICAgICB9CiAgICB9CiAgICBDb2x1bW4oCiAgICAgICAgbW9kaWZpZXIgPSBNb2RpZmllcgogICAgICAgICAgICAuZmlsbE1h' >> "$TMPB64"
    printf '%s' 'eFNpemUoKQogICAgICAgICAgICAuYmFja2dyb3VuZChtdXNpY0NvbG9ycygpLmJhY2tncm91bmQpCiAgICApIHsKICAgICAgICBS' >> "$TMPB64"
    printf '%s' 'b3coCiAgICAgICAgICAgIG1vZGlmaWVyID0gTW9kaWZpZXIKICAgICAgICAgICAgICAgIC5maWxsTWF4V2lkdGgoKQogICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgLnBhZGRpbmcoc3RhcnQgPSA4LmRwLCBlbmQgPSAxNi5kcCwgdG9wID0gNDguZHAsIGJvdHRvbSA9IDguZHApLAog' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICB2ZXJ0aWNhbEFsaWdubWVudCA9IEFsaWdubWVudC5DZW50ZXJWZXJ0aWNhbGx5LAogICAgICAgICkgewogICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICBUZXh0KAogICAgICAgICAgICAgICAgdGV4dCA9ICLigLkiLAogICAgICAgICAgICAgICAgc3R5bGUgPSBNYXRlcmlh' >> "$TMPB64"
    printf '%s' 'bFRoZW1lLnR5cG9ncmFwaHkuaGVhZGxpbmVNZWRpdW0sCiAgICAgICAgICAgICAgICBjb2xvciA9IG11c2ljQ29sb3JzKCkudGV4' >> "$TMPB64"
    printf '%s' 'dFByaW1hcnksCiAgICAgICAgICAgICAgICBtb2RpZmllciA9IE1vZGlmaWVyCiAgICAgICAgICAgICAgICAgICAgLmNsaWNrYWJs' >> "$TMPB64"
    printf '%s' 'ZSB7IG9uQmFjaygpIH0KICAgICAgICAgICAgICAgICAgICAucGFkZGluZyhob3Jpem9udGFsID0gMTIuZHAsIHZlcnRpY2FsID0g' >> "$TMPB64"
    printf '%s' 'NC5kcCksCiAgICAgICAgICAgICkKICAgICAgICAgICAgVGV4dCgKICAgICAgICAgICAgICAgIHRleHQgPSAi5aOB57q46K6+572u' >> "$TMPB64"
    printf '%s' 'IiwKICAgICAgICAgICAgICAgIHN0eWxlID0gTWF0ZXJpYWxUaGVtZS50eXBvZ3JhcGh5LnRpdGxlTWVkaXVtLmNvcHkoZm9udFdl' >> "$TMPB64"
    printf '%s' 'aWdodCA9IEZvbnRXZWlnaHQuQm9sZCksCiAgICAgICAgICAgICAgICBjb2xvciA9IG11c2ljQ29sb3JzKCkudGV4dFByaW1hcnks' >> "$TMPB64"
    printf '%s' 'CiAgICAgICAgICAgICkKICAgICAgICB9CiAgICAgICAgTGF6eUNvbHVtbigKICAgICAgICAgICAgbW9kaWZpZXIgPSBNb2RpZmll' >> "$TMPB64"
    printf '%s' 'ci5maWxsTWF4U2l6ZSgpLAogICAgICAgICAgICBjb250ZW50UGFkZGluZyA9IFBhZGRpbmdWYWx1ZXMoMTYuZHApLAogICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICB2ZXJ0aWNhbEFycmFuZ2VtZW50ID0gQXJyYW5nZW1lbnQuc3BhY2VkQnkoMTIuZHApLAogICAgICAgICkgewogICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICBpdGVtIHsKICAgICAgICAgICAgICAgIENhcmQoCiAgICAgICAgICAgICAgICAgICAgY29sb3JzID0gQ2FyZERlZmF1bHRz' >> "$TMPB64"
    printf '%s' 'LmNhcmRDb2xvcnMoY29udGFpbmVyQ29sb3IgPSBtdXNpY0NvbG9ycygpLmNhcmQpLAogICAgICAgICAgICAgICAgICAgIHNoYXBl' >> "$TMPB64"
    printf '%s' 'ID0gUm91bmRlZENvcm5lclNoYXBlKDE2LmRwKSwKICAgICAgICAgICAgICAgICkgewogICAgICAgICAgICAgICAgICAgIFJvdygK' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgbW9kaWZpZXIgPSBNb2RpZmllcgogICAgICAgICAgICAgICAgICAgICAgICAgICAgLmZp' >> "$TMPB64"
    printf '%s' 'bGxNYXhXaWR0aCgpCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAucGFkZGluZygxMi5kcCksCiAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgIHZlcnRpY2FsQWxpZ25tZW50ID0gQWxpZ25tZW50LkNlbnRlclZlcnRpY2FsbHksCiAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'KSB7CiAgICAgICAgICAgICAgICAgICAgICAgIENvbHVtbihtb2RpZmllciA9IE1vZGlmaWVyLndlaWdodCgxZikpIHsKICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgIFRleHQoIuWQr+eUqOWjgee6uOiDjOaZryIsIHN0eWxlID0gTWF0ZXJpYWxUaGVtZS50eXBv' >> "$TMPB64"
    printf '%s' 'Z3JhcGh5LmJvZHlNZWRpdW0sIGNvbG9yID0gbXVzaWNDb2xvcnMoKS50ZXh0UHJpbWFyeSkKICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgIFNwYWNlcihtb2RpZmllciA9IE1vZGlmaWVyLmhlaWdodCgyLmRwKSkKICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'IFRleHQoIumfs+S5kOS4k+WMuuW6leWxguiDjOaZr+Wbvu+8iOW4puWPr+ivu+aAp+mBrue9qe+8iSIsIHN0eWxlID0gTWF0ZXJp' >> "$TMPB64"
    printf '%s' 'YWxUaGVtZS50eXBvZ3JhcGh5LmJvZHlTbWFsbCwgY29sb3IgPSBtdXNpY0NvbG9ycygpLnRleHRTZWNvbmRhcnkpCiAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgIH0KICAgICAgICAgICAgICAgICAgICAgICAgU3dpdGNoKAogICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgY2hlY2tlZCA9IHdwU3RhdGUuZW5hYmxlZCwKICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hlY2tlZENoYW5nZSA9' >> "$TMPB64"
    printf '%s' 'IHsgV2FsbHBhcGVyTWFuYWdlci5zZXRFbmFibGVkKGNvbnRleHQsIGl0KSB9LAogICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'Y29sb3JzID0gU3dpdGNoRGVmYXVsdHMuY29sb3JzKAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNoZWNrZWRUaHVt' >> "$TMPB64"
    printf '%s' 'YkNvbG9yID0gQ29sb3IuV2hpdGUsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgY2hlY2tlZFRyYWNrQ29sb3IgPSBt' >> "$TMPB64"
    printf '%s' 'dXNpY0NvbG9ycygpLmFjY2VudCwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB1bmNoZWNrZWRUaHVtYkNvbG9yID0g' >> "$TMPB64"
    printf '%s' 'Q29sb3IuV2hpdGUsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgdW5jaGVja2VkVHJhY2tDb2xvciA9IG11c2ljQ29s' >> "$TMPB64"
    printf '%s' 'b3JzKCkuY2FyZFNlY29uZGFyeSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICksCiAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICkKICAgICAgICAgICAgICAgICAgICB9CiAgICAgICAgICAgICAgICB9CiAgICAgICAgICAgIH0KICAgICAgICAgICAgaXRlbSB7' >> "$TMPB64"
    printf '%s' 'CiAgICAgICAgICAgICAgICBDYXJkKAogICAgICAgICAgICAgICAgICAgIGNvbG9ycyA9IENhcmREZWZhdWx0cy5jYXJkQ29sb3Jz' >> "$TMPB64"
    printf '%s' 'KGNvbnRhaW5lckNvbG9yID0gbXVzaWNDb2xvcnMoKS5jYXJkKSwKICAgICAgICAgICAgICAgICAgICBzaGFwZSA9IFJvdW5kZWRD' >> "$TMPB64"
    printf '%s' 'b3JuZXJTaGFwZSgxNi5kcCksCiAgICAgICAgICAgICAgICApIHsKICAgICAgICAgICAgICAgICAgICBDb2x1bW4obW9kaWZpZXIg' >> "$TMPB64"
    printf '%s' 'PSBNb2RpZmllci5wYWRkaW5nKDEyLmRwKSkgewogICAgICAgICAgICAgICAgICAgICAgICBUZXh0KCLnvZHnu5zlo4HnurgiLCBz' >> "$TMPB64"
    printf '%s' 'dHlsZSA9IE1hdGVyaWFsVGhlbWUudHlwb2dyYXBoeS5ib2R5TWVkaXVtLCBjb2xvciA9IG11c2ljQ29sb3JzKCkudGV4dFByaW1h' >> "$TMPB64"
    printf '%s' 'cnkpCiAgICAgICAgICAgICAgICAgICAgICAgIFNwYWNlcihtb2RpZmllciA9IE1vZGlmaWVyLmhlaWdodCg4LmRwKSkKICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgT3V0bGluZWRUZXh0RmllbGQoCiAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZSA9IHVy' >> "$TMPB64"
    printf '%s' 'bFRleHQsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICBvblZhbHVlQ2hhbmdlID0geyB1cmxUZXh0ID0gaXQgfSwKICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgIGxhYmVsID0geyBUZXh0KCLlm77niYcgVVJM77yIaHR0cC9odHRwc++8iSIpIH0sCiAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICBzaW5nbGVMaW5lID0gdHJ1ZSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgIG1vZGlm' >> "$TMPB64"
    printf '%s' 'aWVyID0gTW9kaWZpZXIuZmlsbE1heFdpZHRoKCksCiAgICAgICAgICAgICAgICAgICAgICAgICAgICBjb2xvcnMgPSBPdXRsaW5l' >> "$TMPB64"
    printf '%s' 'ZFRleHRGaWVsZERlZmF1bHRzLmNvbG9ycygKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBmb2N1c2VkQm9yZGVyQ29s' >> "$TMPB64"
    printf '%s' 'b3IgPSBtdXNpY0NvbG9ycygpLmFjY2VudCwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB1bmZvY3VzZWRCb3JkZXJD' >> "$TMPB64"
    printf '%s' 'b2xvciA9IG11c2ljQ29sb3JzKCkuZGl2aWRlciwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBjdXJzb3JDb2xvciA9' >> "$TMPB64"
    printf '%s' 'IG11c2ljQ29sb3JzKCkuYWNjZW50LAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGZvY3VzZWRMYWJlbENvbG9yID0g' >> "$TMPB64"
    printf '%s' 'bXVzaWNDb2xvcnMoKS5hY2NlbnQsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgdW5mb2N1c2VkTGFiZWxDb2xvciA9' >> "$TMPB64"
    printf '%s' 'IG11c2ljQ29sb3JzKCkudGV4dFNlY29uZGFyeSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBmb2N1c2VkVGV4dENv' >> "$TMPB64"
    printf '%s' 'bG9yID0gbXVzaWNDb2xvcnMoKS50ZXh0UHJpbWFyeSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB1bmZvY3VzZWRU' >> "$TMPB64"
    printf '%s' 'ZXh0Q29sb3IgPSBtdXNpY0NvbG9ycygpLnRleHRQcmltYXJ5LAogICAgICAgICAgICAgICAgICAgICAgICAgICAgKSwKICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgKQogICAgICAgICAgICAgICAgICAgICAgICBTcGFjZXIobW9kaWZpZXIgPSBNb2RpZmllci5oZWln' >> "$TMPB64"
    printf '%s' 'aHQoOC5kcCkpCiAgICAgICAgICAgICAgICAgICAgICAgIFJvdyhob3Jpem9udGFsQXJyYW5nZW1lbnQgPSBBcnJhbmdlbWVudC5z' >> "$TMPB64"
    printf '%s' 'cGFjZWRCeSgxMC5kcCkpIHsgLy8gWzM5d3BhZGFwdF0g5Lik5oyJ6ZKu5Z2H5YiGLCDlsI/lsY/kuI3muqLlh7oKICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgIEJ1dHRvbigKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBtb2RpZmllciA9IE1vZGlm' >> "$TMPB64"
    printf '%s' 'aWVyLndlaWdodCgxZiksCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgb25DbGljayA9IHsgV2FsbHBhcGVyTWFuYWdl' >> "$TMPB64"
    printf '%s' 'ci5hcHBseShjb250ZXh0LCB1cmxUZXh0KSB9LAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNvbG9ycyA9IEJ1dHRv' >> "$TMPB64"
    printf '%s' 'bkRlZmF1bHRzLmJ1dHRvbkNvbG9ycygKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgY29udGFpbmVyQ29sb3Ig' >> "$TMPB64"
    printf '%s' 'PSBtdXNpY0NvbG9ycygpLmFjY2VudCwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgY29udGVudENvbG9yID0g' >> "$TMPB64"
    printf '%s' 'bXVzaWNDb2xvcnMoKS5hY2NlbnRUZXh0LAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICksCiAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICApIHsgVGV4dCgi5bqU55So5q2kIFVSTCIpIH0KICAgICAgICAgICAgICAgICAgICAgICAgICAgIE91dGxp' >> "$TMPB64"
    printf '%s' 'bmVkQnV0dG9uKAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIG1vZGlmaWVyID0gTW9kaWZpZXIud2VpZ2h0KDFmKSwK' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBvbkNsaWNrID0geyBwaWNrZXIubGF1bmNoKGFycmF5T2YoImltYWdlLyoi' >> "$TMPB64"
    printf '%s' 'KSkgfSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICkgewogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIFRleHQo' >> "$TMPB64"
    printf '%s' 'IuacrOWcsOmAieWbviIsIGNvbG9yID0gbXVzaWNDb2xvcnMoKS50ZXh0UHJpbWFyeSkKICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgIH0KICAgICAgICAgICAgICAgICAgICAgICAgfQogICAgICAgICAgICAgICAgICAgIH0KICAgICAgICAgICAgICAgIH0KICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgfQogICAgICAgICAgICBpdGVtIHsKICAgICAgICAgICAgICAgIENhcmQoCiAgICAgICAgICAgICAgICAgICAgY29s' >> "$TMPB64"
    printf '%s' 'b3JzID0gQ2FyZERlZmF1bHRzLmNhcmRDb2xvcnMoY29udGFpbmVyQ29sb3IgPSBtdXNpY0NvbG9ycygpLmNhcmQpLAogICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgIHNoYXBlID0gUm91bmRlZENvcm5lclNoYXBlKDE2LmRwKSwKICAgICAgICAgICAgICAgICAgICBtb2RpZmll' >> "$TMPB64"
    printf '%s' 'ciA9IE1vZGlmaWVyCiAgICAgICAgICAgICAgICAgICAgICAgIC5maWxsTWF4V2lkdGgoKQogICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAuY2xpY2thYmxlIHsKICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNvbnRleHQuc3RhcnRBY3Rpdml0eShJbnRlbnQoY29u' >> "$TMPB64"
    printf '%s' 'dGV4dCwgV2FsbHBhcGVyTGlicmFyeUFjdGl2aXR5OjpjbGFzcy5qYXZhKSkKICAgICAgICAgICAgICAgICAgICAgICAgfSwKICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICkgewogICAgICAgICAgICAgICAgICAgIFJvdygKICAgICAgICAgICAgICAgICAgICAgICAgbW9kaWZpZXIg' >> "$TMPB64"
    printf '%s' 'PSBNb2RpZmllcgogICAgICAgICAgICAgICAgICAgICAgICAgICAgLmZpbGxNYXhXaWR0aCgpCiAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAucGFkZGluZygxMi5kcCksCiAgICAgICAgICAgICAgICAgICAgICAgIHZlcnRpY2FsQWxpZ25tZW50ID0gQWxpZ25t' >> "$TMPB64"
    printf '%s' 'ZW50LkNlbnRlclZlcnRpY2FsbHksCiAgICAgICAgICAgICAgICAgICAgKSB7CiAgICAgICAgICAgICAgICAgICAgICAgIENvbHVt' >> "$TMPB64"
    printf '%s' 'bihtb2RpZmllciA9IE1vZGlmaWVyLndlaWdodCgxZikpIHsKICAgICAgICAgICAgICAgICAgICAgICAgICAgIFRleHQoIuWcqOe6' >> "$TMPB64"
    printf '%s' 'v+Wjgee6uOW6kyIsIHN0eWxlID0gTWF0ZXJpYWxUaGVtZS50eXBvZ3JhcGh5LmJvZHlNZWRpdW0sIGNvbG9yID0gbXVzaWNDb2xv' >> "$TMPB64"
    printf '%s' 'cnMoKS50ZXh0UHJpbWFyeSkKICAgICAgICAgICAgICAgICAgICAgICAgICAgIFNwYWNlcihtb2RpZmllciA9IE1vZGlmaWVyLmhl' >> "$TMPB64"
    printf '%s' 'aWdodCgyLmRwKSkKICAgICAgICAgICAgICAgICAgICAgICAgICAgIFRleHQoIueyvumAiee9kee7nOWjgee6uO+8jOeCueWHu+WN' >> "$TMPB64"
    printf '%s' 's+W6lOeUqCIsIHN0eWxlID0gTWF0ZXJpYWxUaGVtZS50eXBvZ3JhcGh5LmJvZHlTbWFsbCwgY29sb3IgPSBtdXNpY0NvbG9ycygp' >> "$TMPB64"
    printf '%s' 'LnRleHRTZWNvbmRhcnkpCiAgICAgICAgICAgICAgICAgICAgICAgIH0KICAgICAgICAgICAgICAgICAgICAgICAgVGV4dCgi4oC6' >> "$TMPB64"
    printf '%s' 'Iiwgc3R5bGUgPSBNYXRlcmlhbFRoZW1lLnR5cG9ncmFwaHkuaGVhZGxpbmVNZWRpdW0sIGNvbG9yID0gbXVzaWNDb2xvcnMoKS50' >> "$TMPB64"
    printf '%s' 'ZXh0U2Vjb25kYXJ5KQogICAgICAgICAgICAgICAgICAgIH0KICAgICAgICAgICAgICAgIH0KICAgICAgICAgICAgfQogICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICBpdGVtIHsKICAgICAgICAgICAgICAgIENhcmQoCiAgICAgICAgICAgICAgICAgICAgY29sb3JzID0gQ2FyZERlZmF1bHRz' >> "$TMPB64"
    printf '%s' 'LmNhcmRDb2xvcnMoY29udGFpbmVyQ29sb3IgPSBtdXNpY0NvbG9ycygpLmNhcmQpLAogICAgICAgICAgICAgICAgICAgIHNoYXBl' >> "$TMPB64"
    printf '%s' 'ID0gUm91bmRlZENvcm5lclNoYXBlKDE2LmRwKSwKICAgICAgICAgICAgICAgICkgewogICAgICAgICAgICAgICAgICAgIENvbHVt' >> "$TMPB64"
    printf '%s' 'bihtb2RpZmllciA9IE1vZGlmaWVyLnBhZGRpbmcoMTIuZHApKSB7CiAgICAgICAgICAgICAgICAgICAgICAgIFRleHQoIua4kOWP' >> "$TMPB64"
    printf '%s' 'mOiDjOaZryIsIHN0eWxlID0gTWF0ZXJpYWxUaGVtZS50eXBvZ3JhcGh5LmJvZHlNZWRpdW0sIGNvbG9yID0gbXVzaWNDb2xvcnMo' >> "$TMPB64"
    printf '%s' 'KS50ZXh0UHJpbWFyeSkKICAgICAgICAgICAgICAgICAgICAgICAgU3BhY2VyKG1vZGlmaWVyID0gTW9kaWZpZXIuaGVpZ2h0KDIu' >> "$TMPB64"
    printf '%s' 'ZHApKQogICAgICAgICAgICAgICAgICAgICAgICBUZXh0KCLkuI3nlKjlm77niYfvvIzkuIDlsYLmuJDlj5jkvZzlupXvvIjlkIzm' >> "$TMPB64"
    printf '%s' 'oLfluKblj6/or7vmgKfpga7nvanvvIkiLCBzdHlsZSA9IE1hdGVyaWFsVGhlbWUudHlwb2dyYXBoeS5ib2R5U21hbGwsIGNvbG9y' >> "$TMPB64"
    printf '%s' 'ID0gbXVzaWNDb2xvcnMoKS50ZXh0U2Vjb25kYXJ5KQogICAgICAgICAgICAgICAgICAgICAgICBTcGFjZXIobW9kaWZpZXIgPSBN' >> "$TMPB64"
    printf '%s' 'b2RpZmllci5oZWlnaHQoOC5kcCkpCiAgICAgICAgICAgICAgICAgICAgICAgIFJvdyhob3Jpem9udGFsQXJyYW5nZW1lbnQgPSBB' >> "$TMPB64"
    printf '%s' 'cnJhbmdlbWVudC5zcGFjZWRCeSgxMi5kcCkpIHsKICAgICAgICAgICAgICAgICAgICAgICAgICAgIFdQX0dSQURJRU5UX1BSRVNF' >> "$TMPB64"
    printf '%s' 'VFMuZm9yRWFjaCB7IChuYW1lLCBoMSwgaDIpIC0+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgdmFsIHBhaXIgPSAi' >> "$TMPB64"
    printf '%s' 'JGgxLCRoMiIKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWwgaXNDdXJyZW50ID0gd3BTdGF0ZS5tb2RlID09ICJn' >> "$TMPB64"
    printf '%s' 'cmFkaWVudCIgJiYgd3BTdGF0ZS5ncmFkaWVudCA9PSBwYWlyCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgQ29sdW1u' >> "$TMPB64"
    printf '%s' 'KGhvcml6b250YWxBbGlnbm1lbnQgPSBBbGlnbm1lbnQuQ2VudGVySG9yaXpvbnRhbGx5KSB7CiAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgIEJveCgKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIG1vZGlmaWVyID0gTW9k' >> "$TMPB64"
    printf '%s' 'aWZpZXIKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAuc2l6ZSg1Ni5kcCkKICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAuY2xpcChSb3VuZGVkQ29ybmVyU2hhcGUoMTIuZHApKQogICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIC5iYWNrZ3JvdW5kKEJydXNoLmxpbmVhckdyYWRpZW50KGxpc3RPZih3' >> "$TMPB64"
    printf '%s' 'cFBhcnNlQ29sb3IoaDEpLCB3cFBhcnNlQ29sb3IoaDIpKSkpCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgLnRoZW4oCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGlmIChpc0N1cnJlbnQp' >> "$TMPB64"
    printf '%s' 'IE1vZGlmaWVyLmJvcmRlcigyLmRwLCBtdXNpY0NvbG9ycygpLmFjY2VudCwgUm91bmRlZENvcm5lclNoYXBlKDEyLmRwKSkKICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZWxzZSBNb2RpZmllcgogICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICkKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAu' >> "$TMPB64"
    printf '%s' 'Y2xpY2thYmxlIHsKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgV2FsbHBhcGVyTWFuYWdl' >> "$TMPB64"
    printf '%s' 'ci5hcHBseUdyYWRpZW50KGNvbnRleHQsIHBhaXIpCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgIGFuZHJvaWQud2lkZ2V0LlRvYXN0Lm1ha2VUZXh0KGNvbnRleHQsICLmuJDlj5jlt7LlupTnlKgiLCBhbmRyb2lkLndpZGdl' >> "$TMPB64"
    printf '%s' 'dC5Ub2FzdC5MRU5HVEhfU0hPUlQpLnNob3coKQogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIH0s' >> "$TMPB64"
    printf '%s' 'CiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICkKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'U3BhY2VyKG1vZGlmaWVyID0gTW9kaWZpZXIuaGVpZ2h0KDYuZHApKQogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICBUZXh0KG5hbWUsIHN0eWxlID0gTWF0ZXJpYWxUaGVtZS50eXBvZ3JhcGh5LmJvZHlTbWFsbCwgY29sb3IgPSBtdXNpY0NvbG9y' >> "$TMPB64"
    printf '%s' 'cygpLnRleHRQcmltYXJ5KQogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIH0KICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgIH0KICAgICAgICAgICAgICAgICAgICAgICAgfQogICAgICAgICAgICAgICAgICAgIH0KICAgICAgICAgICAgICAgIH0KICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgfQogICAgICAgICAgICBpdGVtIHsKICAgICAgICAgICAgICAgIC8vIFszOXdwNF0g5pWI5p6c6LCD5pW0OiDmlofl' >> "$TMPB64"
    printf '%s' 'rZfpopzoibLmqKHlvI8gKyDpga7nvanmtZPluqYKICAgICAgICAgICAgICAgIC8vIFszOXdwNV0g6YGu572p5a+56b2QIFBlZWsg' >> "$TMPB64"
    printf '%s' 'ZGFya092ZXJsYXk6IOe6r+m7kSwg6buY6K6kIDAg5peg57qxLCDmmL7npLrnnJ/lrp7lgLwKICAgICAgICAgICAgICAgIHZhbCBl' >> "$TMPB64"
    printf '%s' 'ZmZTY3JpbSA9IHdwU3RhdGUuc2NyaW0uY29lcmNlQXRMZWFzdCgwKQogICAgICAgICAgICAgICAgdmFyIHNjcmltU2xpZGVyIGJ5' >> "$TMPB64"
    printf '%s' 'IHJlbWVtYmVyKHdwU3RhdGUuc2NyaW0pIHsgbXV0YWJsZVN0YXRlT2YoZWZmU2NyaW0udG9GbG9hdCgpKSB9CiAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICB2YXIgb3BhY2l0eVNsaWRlciBieSByZW1lbWJlcih3cFN0YXRlLm9wYWNpdHkpIHsgbXV0YWJsZVN0YXRlT2Yod3BTdGF0' >> "$TMPB64"
    printf '%s' 'ZS5vcGFjaXR5LnRvRmxvYXQoKSkgfQogICAgICAgICAgICAgICAgdmFyIGJsdXJTbGlkZXIgYnkgcmVtZW1iZXIod3BTdGF0ZS5i' >> "$TMPB64"
    printf '%s' 'bHVyKSB7IG11dGFibGVTdGF0ZU9mKHdwU3RhdGUuYmx1ci50b0Zsb2F0KCkpIH0KICAgICAgICAgICAgICAgIENhcmQoCiAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgY29sb3JzID0gQ2FyZERlZmF1bHRzLmNhcmRDb2xvcnMoY29udGFpbmVyQ29sb3IgPSBtdXNpY0NvbG9y' >> "$TMPB64"
    printf '%s' 'cygpLmNhcmQpLAogICAgICAgICAgICAgICAgICAgIHNoYXBlID0gUm91bmRlZENvcm5lclNoYXBlKDE2LmRwKSwKICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICkgewogICAgICAgICAgICAgICAgICAgIENvbHVtbihtb2RpZmllciA9IE1vZGlmaWVyLnBhZGRpbmcoMTIuZHApKSB7' >> "$TMPB64"
    printf '%s' 'CiAgICAgICAgICAgICAgICAgICAgICAgIFRleHQoIuaViOaenOiwg+aVtCIsIHN0eWxlID0gTWF0ZXJpYWxUaGVtZS50eXBvZ3Jh' >> "$TMPB64"
    printf '%s' 'cGh5LmJvZHlNZWRpdW0sIGNvbG9yID0gbXVzaWNDb2xvcnMoKS50ZXh0UHJpbWFyeSkKICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'U3BhY2VyKG1vZGlmaWVyID0gTW9kaWZpZXIuaGVpZ2h0KDguZHApKQogICAgICAgICAgICAgICAgICAgICAgICBUZXh0KCLmlofl' >> "$TMPB64"
    printf '%s' 'rZfpopzoibLmqKHlvI8iLCBzdHlsZSA9IE1hdGVyaWFsVGhlbWUudHlwb2dyYXBoeS5ib2R5U21hbGwsIGNvbG9yID0gbXVzaWND' >> "$TMPB64"
    printf '%s' 'b2xvcnMoKS50ZXh0U2Vjb25kYXJ5KQogICAgICAgICAgICAgICAgICAgICAgICBTcGFjZXIobW9kaWZpZXIgPSBNb2RpZmllci5o' >> "$TMPB64"
    printf '%s' 'ZWlnaHQoOC5kcCkpCiAgICAgICAgICAgICAgICAgICAgICAgIEZsb3dSb3coIC8vIFszOXdwYWRhcHRdIOaooeW8jyBwaWxsIOWw' >> "$TMPB64"
    printf '%s' 'j+Wxj+iHquWKqOaKmOihjCwg5LiN5YaN56uW5Y+g5oyk5a2XCiAgICAgICAgICAgICAgICAgICAgICAgICAgICBob3Jpem9udGFs' >> "$TMPB64"
    printf '%s' 'QXJyYW5nZW1lbnQgPSBBcnJhbmdlbWVudC5zcGFjZWRCeSg4LmRwKSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZlcnRp' >> "$TMPB64"
    printf '%s' 'Y2FsQXJyYW5nZW1lbnQgPSBBcnJhbmdlbWVudC5zcGFjZWRCeSg4LmRwKSwKICAgICAgICAgICAgICAgICAgICAgICAgKSB7CiAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICBXUF9URVhUX01PREVTLmZvckVhY2ggeyAodmFsdWUsIGxhYmVsKSAtPgogICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgIHZhbCBzZWxlY3RlZCA9IHdwU3RhdGUudGV4dE1vZGUgPT0gdmFsdWUKICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICBCb3goCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIG1vZGlmaWVyID0g' >> "$TMPB64"
    printf '%s' 'TW9kaWZpZXIKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIC5jbGlwKFJvdW5kZWRDb3JuZXJTaGFwZSg1' >> "$TMPB64"
    printf '%s' 'MCkpCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAuYmFja2dyb3VuZChpZiAoc2VsZWN0ZWQpIG11c2lj' >> "$TMPB64"
    printf '%s' 'Q29sb3JzKCkuYWNjZW50IGVsc2UgbXVzaWNDb2xvcnMoKS5jYXJkU2Vjb25kYXJ5KQogICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgLmNsaWNrYWJsZSB7IFdhbGxwYXBlck1hbmFnZXIuc2V0VGV4dE1vZGUoY29udGV4dCwgdmFsdWUpIH0K' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIC5wYWRkaW5nKGhvcml6b250YWwgPSAxMi5kcCwgdmVydGlj' >> "$TMPB64"
    printf '%s' 'YWwgPSA2LmRwKSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICApIHsKICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgVGV4dCgKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHRleHQgPSBsYWJlbCwKICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHN0eWxlID0gTWF0ZXJpYWxUaGVtZS50eXBvZ3JhcGh5LmJvZHlTbWFs' >> "$TMPB64"
    printf '%s' 'bCwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNvbG9yID0gaWYgKHNlbGVjdGVkKSBtdXNpY0NvbG9y' >> "$TMPB64"
    printf '%s' 'cygpLmFjY2VudFRleHQgZWxzZSBtdXNpY0NvbG9ycygpLnRleHRTZWNvbmRhcnksCiAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICkKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB9CiAgICAgICAgICAgICAgICAgICAgICAgICAgICB9' >> "$TMPB64"
    printf '%s' 'CiAgICAgICAgICAgICAgICAgICAgICAgIH0KICAgICAgICAgICAgICAgICAgICAgICAgU3BhY2VyKG1vZGlmaWVyID0gTW9kaWZp' >> "$TMPB64"
    printf '%s' 'ZXIuaGVpZ2h0KDQuZHApKQogICAgICAgICAgICAgICAgICAgICAgICBUZXh0KAogICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'dGV4dCA9ICLlo4HnurjlgY/mt7HpgInmtYXoibLmloflrZfvvIzlgY/mtYXpgInmt7HoibLmloflrZfvvIzlnKjlo4HnurjkuIrm' >> "$TMPB64"
    printf '%s' 'iY3nnIvlvpfmuIXvvJvot5/pmo/kuLvpopjliJnnlKjkuLvpopjmt7HmtYXjgIIiLAogICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgc3R5bGUgPSBNYXRlcmlhbFRoZW1lLnR5cG9ncmFwaHkuYm9keVNtYWxsLAogICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'Y29sb3IgPSBtdXNpY0NvbG9ycygpLnRleHRTZWNvbmRhcnksCiAgICAgICAgICAgICAgICAgICAgICAgICkKICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgU3BhY2VyKG1vZGlmaWVyID0gTW9kaWZpZXIuaGVpZ2h0KDEyLmRwKSkKICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgUm93KAogICAgICAgICAgICAgICAgICAgICAgICAgICAgbW9kaWZpZXIgPSBNb2RpZmllci5maWxsTWF4V2lkdGgoKSwKICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgIHZlcnRpY2FsQWxpZ25tZW50ID0gQWxpZ25tZW50LkNlbnRlclZlcnRpY2FsbHksCiAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICkgewogICAgICAgICAgICAgICAgICAgICAgICAgICAgVGV4dCgi6YGu572p5rWT5bqmIiwg' >> "$TMPB64"
    printf '%s' 'c3R5bGUgPSBNYXRlcmlhbFRoZW1lLnR5cG9ncmFwaHkuYm9keVNtYWxsLCBjb2xvciA9IG11c2ljQ29sb3JzKCkudGV4dFNlY29u' >> "$TMPB64"
    printf '%s' 'ZGFyeSkKICAgICAgICAgICAgICAgICAgICAgICAgICAgIFNwYWNlcihtb2RpZmllciA9IE1vZGlmaWVyLndlaWdodCgxZikpCiAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICBUZXh0KAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHRleHQgPSAiJHtz' >> "$TMPB64"
    printf '%s' 'Y3JpbVNsaWRlci50b0ludCgpfSUiLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHN0eWxlID0gTWF0ZXJpYWxUaGVt' >> "$TMPB64"
    printf '%s' 'ZS50eXBvZ3JhcGh5LmJvZHlTbWFsbCwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBjb2xvciA9IG11c2ljQ29sb3Jz' >> "$TMPB64"
    printf '%s' 'KCkudGV4dFByaW1hcnksCiAgICAgICAgICAgICAgICAgICAgICAgICAgICApCiAgICAgICAgICAgICAgICAgICAgICAgIH0KICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgQ29tcGFjdFNsaWRlcigKICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlID0gc2Ny' >> "$TMPB64"
    printf '%s' 'aW1TbGlkZXIsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICBvblZhbHVlQ2hhbmdlID0geyBzY3JpbVNsaWRlciA9IGl0IH0s' >> "$TMPB64"
    printf '%s' 'CiAgICAgICAgICAgICAgICAgICAgICAgICAgICBvblZhbHVlQ2hhbmdlRmluaXNoZWQgPSB7IFdhbGxwYXBlck1hbmFnZXIuc2V0' >> "$TMPB64"
    printf '%s' 'U2NyaW0oY29udGV4dCwgc2NyaW1TbGlkZXIudG9JbnQoKSkgfSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlUmFu' >> "$TMPB64"
    printf '%s' 'Z2UgPSAwZi4uOTBmLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgc3RlcHMgPSA4LAogICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICApCiAgICAgICAgICAgICAgICAgICAgICAgIFRleHQoCiAgICAgICAgICAgICAgICAgICAgICAgICAgICB0ZXh0ID0gIuWjgee6' >> "$TMPB64"
    printf '%s' 'uOS5i+S4iueahOS4gOWxgum7keiJsumBrue9qe+8mui2iumrmOWjgee6uOi2iuaal+OAgeaWh+Wtl+i2iua4heOAgum7mOiupCAw' >> "$TMPB64"
    printf '%s' 'IOS4jemBruaMoeOAgiIsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICBzdHlsZSA9IE1hdGVyaWFsVGhlbWUudHlwb2dyYXBo' >> "$TMPB64"
    printf '%s' 'eS5ib2R5U21hbGwsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICBjb2xvciA9IG11c2ljQ29sb3JzKCkudGV4dFNlY29uZGFy' >> "$TMPB64"
    printf '%s' 'eSwKICAgICAgICAgICAgICAgICAgICAgICAgKQogICAgICAgICAgICAgICAgICAgICAgICBTcGFjZXIobW9kaWZpZXIgPSBNb2Rp' >> "$TMPB64"
    printf '%s' 'Zmllci5oZWlnaHQoMTIuZHApKQogICAgICAgICAgICAgICAgICAgICAgICBSb3coCiAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICBtb2RpZmllciA9IE1vZGlmaWVyLmZpbGxNYXhXaWR0aCgpLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgdmVydGljYWxB' >> "$TMPB64"
    printf '%s' 'bGlnbm1lbnQgPSBBbGlnbm1lbnQuQ2VudGVyVmVydGljYWxseSwKICAgICAgICAgICAgICAgICAgICAgICAgKSB7CiAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICBUZXh0KCLlo4HnurjkuI3pgI/mmI7luqYiLCBzdHlsZSA9IE1hdGVyaWFsVGhlbWUudHlwb2dy' >> "$TMPB64"
    printf '%s' 'YXBoeS5ib2R5U21hbGwsIGNvbG9yID0gbXVzaWNDb2xvcnMoKS50ZXh0U2Vjb25kYXJ5KQogICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgU3BhY2VyKG1vZGlmaWVyID0gTW9kaWZpZXIud2VpZ2h0KDFmKSkKICAgICAgICAgICAgICAgICAgICAgICAgICAgIFRl' >> "$TMPB64"
    printf '%s' 'eHQoCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgdGV4dCA9ICIke29wYWNpdHlTbGlkZXIudG9JbnQoKX0lIiwKICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICBzdHlsZSA9IE1hdGVyaWFsVGhlbWUudHlwb2dyYXBoeS5ib2R5U21hbGwsCiAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgY29sb3IgPSBtdXNpY0NvbG9ycygpLnRleHRQcmltYXJ5LAogICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgKQogICAgICAgICAgICAgICAgICAgICAgICB9CiAgICAgICAgICAgICAgICAgICAgICAgIENvbXBh' >> "$TMPB64"
    printf '%s' 'Y3RTbGlkZXIoCiAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZSA9IG9wYWNpdHlTbGlkZXIsCiAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICBvblZhbHVlQ2hhbmdlID0geyBvcGFjaXR5U2xpZGVyID0gaXQgfSwKICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgIG9uVmFsdWVDaGFuZ2VGaW5pc2hlZCA9IHsgV2FsbHBhcGVyTWFuYWdlci5zZXRPcGFjaXR5KGNvbnRleHQsIG9wYWNp' >> "$TMPB64"
    printf '%s' 'dHlTbGlkZXIudG9JbnQoKSkgfSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlUmFuZ2UgPSAwZi4uMTAwZiwKICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgIHN0ZXBzID0gOSwKICAgICAgICAgICAgICAgICAgICAgICAgKQogICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICBSb3coCiAgICAgICAgICAgICAgICAgICAgICAgICAgICBtb2RpZmllciA9IE1vZGlmaWVyLmZpbGxNYXhXaWR0' >> "$TMPB64"
    printf '%s' 'aCgpLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgdmVydGljYWxBbGlnbm1lbnQgPSBBbGlnbm1lbnQuQ2VudGVyVmVydGlj' >> "$TMPB64"
    printf '%s' 'YWxseSwKICAgICAgICAgICAgICAgICAgICAgICAgKSB7CiAgICAgICAgICAgICAgICAgICAgICAgICAgICBUZXh0KCLmqKHns4rn' >> "$TMPB64"
    printf '%s' 'qIvluqYiLCBzdHlsZSA9IE1hdGVyaWFsVGhlbWUudHlwb2dyYXBoeS5ib2R5U21hbGwsIGNvbG9yID0gbXVzaWNDb2xvcnMoKS50' >> "$TMPB64"
    printf '%s' 'ZXh0U2Vjb25kYXJ5KQogICAgICAgICAgICAgICAgICAgICAgICAgICAgU3BhY2VyKG1vZGlmaWVyID0gTW9kaWZpZXIud2VpZ2h0' >> "$TMPB64"
    printf '%s' 'KDFmKSkKICAgICAgICAgICAgICAgICAgICAgICAgICAgIFRleHQoCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgdGV4' >> "$TMPB64"
    printf '%s' 'dCA9ICIke2JsdXJTbGlkZXIudG9JbnQoKX0iLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHN0eWxlID0gTWF0ZXJp' >> "$TMPB64"
    printf '%s' 'YWxUaGVtZS50eXBvZ3JhcGh5LmJvZHlTbWFsbCwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBjb2xvciA9IG11c2lj' >> "$TMPB64"
    printf '%s' 'Q29sb3JzKCkudGV4dFByaW1hcnksCiAgICAgICAgICAgICAgICAgICAgICAgICAgICApCiAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'IH0KICAgICAgICAgICAgICAgICAgICAgICAgQ29tcGFjdFNsaWRlcigKICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVl' >> "$TMPB64"
    printf '%s' 'ID0gYmx1clNsaWRlciwKICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uVmFsdWVDaGFuZ2UgPSB7IGJsdXJTbGlkZXIgPSBp' >> "$TMPB64"
    printf '%s' 'dCB9LAogICAgICAgICAgICAgICAgICAgICAgICAgICAgb25WYWx1ZUNoYW5nZUZpbmlzaGVkID0geyBXYWxscGFwZXJNYW5hZ2Vy' >> "$TMPB64"
    printf '%s' 'LnNldEJsdXIoY29udGV4dCwgYmx1clNsaWRlci50b0ludCgpKSB9LAogICAgICAgICAgICAgICAgICAgICAgICAgICAgdmFsdWVS' >> "$TMPB64"
    printf '%s' 'YW5nZSA9IDBmLi4yMGYsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICBzdGVwcyA9IDE5LAogICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICApCiAgICAgICAgICAgICAgICAgICAgICAgIFRleHQoCiAgICAgICAgICAgICAgICAgICAgICAgICAgICB0ZXh0ID0gIuS4' >> "$TMPB64"
    printf '%s' 'jemAj+aYjuW6puiwg+S9ju+8jOWjgee6uOS8muiejei/m+mhtemdouW6leiJsu+8m+aooeeziuiuqeeFp+eJh+mAgOaIkOawm+Wb' >> "$TMPB64"
    printf '%s' 'tOW6le+8jOaWh+Wtl+abtOeqgeWHuu+8iOWPqueziuWjgee6uO+8jOS4jeeziueVjOmdou+8ieOAgiIsCiAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICBzdHlsZSA9IE1hdGVyaWFsVGhlbWUudHlwb2dyYXBoeS5ib2R5U21hbGwsCiAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICBjb2xvciA9IG11c2ljQ29sb3JzKCkudGV4dFNlY29uZGFyeSwKICAgICAgICAgICAgICAgICAgICAgICAgKQog' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgIH0KICAgICAgICAgICAgICAgIH0KICAgICAgICAgICAgfQogICAgICAgICAgICBpZiAod3BTdGF0' >> "$TMPB64"
    printf '%s' 'ZS5oaXN0b3J5LmlzTm90RW1wdHkoKSkgewogICAgICAgICAgICAgICAgaXRlbSB7CiAgICAgICAgICAgICAgICAgICAgVGV4dCgK' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgdGV4dCA9ICLljoblj7Llo4HnurgiLAogICAgICAgICAgICAgICAgICAgICAgICBzdHls' >> "$TMPB64"
    printf '%s' 'ZSA9IE1hdGVyaWFsVGhlbWUudHlwb2dyYXBoeS50aXRsZU1lZGl1bS5jb3B5KGZvbnRXZWlnaHQgPSBGb250V2VpZ2h0LkJvbGQp' >> "$TMPB64"
    printf '%s' 'LAogICAgICAgICAgICAgICAgICAgICAgICBjb2xvciA9IG11c2ljQ29sb3JzKCkudGV4dFByaW1hcnksCiAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgKQogICAgICAgICAgICAgICAgfQogICAgICAgICAgICAgICAgaXRlbSB7CiAgICAgICAgICAgICAgICAgICAgTGF6eVJv' >> "$TMPB64"
    printf '%s' 'dyhob3Jpem9udGFsQXJyYW5nZW1lbnQgPSBBcnJhbmdlbWVudC5zcGFjZWRCeSgxMC5kcCkpIHsKICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgaXRlbXMod3BTdGF0ZS5oaXN0b3J5LCBrZXkgPSB7IGl0IH0pIHsgdSAtPgogICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgdmFsIGlzQ3VycmVudCA9IHUgPT0gd3BTdGF0ZS51cmwKICAgICAgICAgICAgICAgICAgICAgICAgICAgIEJveCgKICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICBtb2RpZmllciA9IE1vZGlmaWVyCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgIC5zaXplKDg0LmRwKQogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAuY2xpcChSb3VuZGVkQ29ybmVy' >> "$TMPB64"
    printf '%s' 'U2hhcGUoMTIuZHApKQogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAuYmFja2dyb3VuZChtdXNpY0NvbG9ycygp' >> "$TMPB64"
    printf '%s' 'LmNhcmRTZWNvbmRhcnkpCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIC50aGVuKAogICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgaWYgKGlzQ3VycmVudCkgTW9kaWZpZXIuYm9yZGVyKDIuZHAsIG11c2ljQ29sb3JzKCku' >> "$TMPB64"
    printf '%s' 'YWNjZW50LCBSb3VuZGVkQ29ybmVyU2hhcGUoMTIuZHApKQogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ZWxzZSBNb2RpZmllcgogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICApCiAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgIC5jbGlja2FibGUgewogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgV2FsbHBhcGVy' >> "$TMPB64"
    printf '%s' 'TWFuYWdlci5hcHBseShjb250ZXh0LCB1KQogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgdXJsVGV4dCA9' >> "$TMPB64"
    printf '%s' 'IHUKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgfSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICkgewog' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIEFzeW5jSW1hZ2UoCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgIG1vZGVsID0gSW1hZ2VSZXF1ZXN0LkJ1aWxkZXIoY29udGV4dCkuZGF0YSh1KS5zaXplKDI0MCkuYnVpbGQoKSwKICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgY29udGVudERlc2NyaXB0aW9uID0gbnVsbCwKICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgY29udGVudFNjYWxlID0gQ29udGVudFNjYWxlLkNyb3AsCiAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgIG1vZGlmaWVyID0gTW9kaWZpZXIuZmlsbE1heFNpemUoKSwKICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICApCiAgICAgICAgICAgICAgICAgICAgICAgICAgICB9CiAgICAgICAgICAgICAgICAgICAgICAgIH0KICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICB9CiAgICAgICAgICAgICAgICB9CiAgICAgICAgICAgIH0KICAgICAgICAgICAgaXRlbSB7CiAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICBUZXh0KAogICAgICAgICAgICAgICAgICAgIHRleHQgPSAi5aOB57q45L2N5LqO6Z+z5LmQ5LiT5Yy65pyA5bqV5bGC77yM5YW2' >> "$TMPB64"
    printf '%s' '5LiK55uW5pyJ5Y+v6K+75oCn6YGu572p77yb6IOM5pmv5Zu+5oyJ5bGP5bmV5bC65a+45bCB6aG25Yqg6L2977yM5LiN5b2x5ZON' >> "$TMPB64"
    printf '%s' '5YiX6KGo5ruR5Yqo44CC5pys5Zyw5Zu+54mH5L2/55So57O757uf5paH5Lu26YCJ5oup5Zmo5bm255Sz6K+35oyB5LmF5o6I5p2D' >> "$TMPB64"
    printf '%s' '77yM6YeN5ZCv5LiN5aSx5pWI44CCIiwKICAgICAgICAgICAgICAgICAgICBzdHlsZSA9IE1hdGVyaWFsVGhlbWUudHlwb2dyYXBo' >> "$TMPB64"
    printf '%s' 'eS5ib2R5U21hbGwsCiAgICAgICAgICAgICAgICAgICAgY29sb3IgPSBtdXNpY0NvbG9ycygpLnRleHRTZWNvbmRhcnksCiAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICApCiAgICAgICAgICAgIH0KICAgICAgICB9CiAgICB9Cn0K' >> "$TMPB64"
base64 -d "$TMPB64" > avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxWallpaperSettingsActivity.kt
rm -f "$TMPB64"
grep -q 'class LxWallpaperSettingsActivity' avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxWallpaperSettingsActivity.kt || { echo "X 39 class LxWallpaperSettingsActivity 写入失败"; exit 1; }
TMPB64=$(mktemp)
    printf '%s' 'cGFja2FnZSBjb20uZ2l0aHViLnR2Ym94Lm9zYy51aS5hY3Rpdml0eQoKaW1wb3J0IGFuZHJvaWQuY29udGVudC5Db250ZXh0Cmlt' >> "$TMPB64"
    printf '%s' 'cG9ydCBhbmRyb2lkLm9zLkJ1bmRsZQppbXBvcnQgYW5kcm9pZC53aWRnZXQuVG9hc3QKaW1wb3J0IGFuZHJvaWR4LmFjdGl2aXR5' >> "$TMPB64"
    printf '%s' 'LkNvbXBvbmVudEFjdGl2aXR5CmltcG9ydCBhbmRyb2lkeC5hY3Rpdml0eS5jb21wb3NlLnNldENvbnRlbnQKaW1wb3J0IGFuZHJv' >> "$TMPB64"
    printf '%s' 'aWR4LmNvbXBvc2UuZm91bmRhdGlvbi5iYWNrZ3JvdW5kCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLmZvdW5kYXRpb24uY2xpY2th' >> "$TMPB64"
    printf '%s' 'YmxlCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLmZvdW5kYXRpb24ubGF5b3V0LkFycmFuZ2VtZW50CmltcG9ydCBhbmRyb2lkeC5j' >> "$TMPB64"
    printf '%s' 'b21wb3NlLmZvdW5kYXRpb24ubGF5b3V0LkJveAppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5mb3VuZGF0aW9uLmxheW91dC5Db2x1' >> "$TMPB64"
    printf '%s' 'bW4KaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UuZm91bmRhdGlvbi5sYXlvdXQuUGFkZGluZ1ZhbHVlcwppbXBvcnQgYW5kcm9pZHgu' >> "$TMPB64"
    printf '%s' 'Y29tcG9zZS5mb3VuZGF0aW9uLmxheW91dC5Sb3cKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UuZm91bmRhdGlvbi5sYXlvdXQuYXNw' >> "$TMPB64"
    printf '%s' 'ZWN0UmF0aW8KaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UuZm91bmRhdGlvbi5sYXlvdXQuZmlsbE1heFNpemUKaW1wb3J0IGFuZHJv' >> "$TMPB64"
    printf '%s' 'aWR4LmNvbXBvc2UuZm91bmRhdGlvbi5sYXlvdXQuZmlsbE1heFdpZHRoCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLmZvdW5kYXRp' >> "$TMPB64"
    printf '%s' 'b24ubGF5b3V0LnBhZGRpbmcKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UuZm91bmRhdGlvbi5sYXp5LkxhenlSb3cKaW1wb3J0IGFu' >> "$TMPB64"
    printf '%s' 'ZHJvaWR4LmNvbXBvc2UuZm91bmRhdGlvbi5sYXp5LmdyaWQuR3JpZENlbGxzCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLmZvdW5k' >> "$TMPB64"
    printf '%s' 'YXRpb24ubGF6eS5ncmlkLkdyaWRJdGVtU3BhbgppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5mb3VuZGF0aW9uLmxhenkuZ3JpZC5M' >> "$TMPB64"
    printf '%s' 'YXp5VmVydGljYWxHcmlkCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLmZvdW5kYXRpb24ubGF6eS5ncmlkLml0ZW1zCmltcG9ydCBh' >> "$TMPB64"
    printf '%s' 'bmRyb2lkeC5jb21wb3NlLmZvdW5kYXRpb24ubGF6eS5pdGVtcwppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5mb3VuZGF0aW9uLnNo' >> "$TMPB64"
    printf '%s' 'YXBlLlJvdW5kZWRDb3JuZXJTaGFwZQppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5tYXRlcmlhbDMuQnV0dG9uCmltcG9ydCBhbmRy' >> "$TMPB64"
    printf '%s' 'b2lkeC5jb21wb3NlLm1hdGVyaWFsMy5CdXR0b25EZWZhdWx0cwppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5tYXRlcmlhbDMuQ2Fy' >> "$TMPB64"
    printf '%s' 'ZAppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5tYXRlcmlhbDMuQ2lyY3VsYXJQcm9ncmVzc0luZGljYXRvcgppbXBvcnQgYW5kcm9p' >> "$TMPB64"
    printf '%s' 'ZHguY29tcG9zZS5tYXRlcmlhbDMuTWF0ZXJpYWxUaGVtZQppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5tYXRlcmlhbDMuVGV4dApp' >> "$TMPB64"
    printf '%s' 'bXBvcnQgYW5kcm9pZHguY29tcG9zZS5ydW50aW1lLkNvbXBvc2FibGUKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UucnVudGltZS5M' >> "$TMPB64"
    printf '%s' 'YXVuY2hlZEVmZmVjdAppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5ydW50aW1lLlNpZGVFZmZlY3QKaW1wb3J0IGFuZHJvaWR4LmNv' >> "$TMPB64"
    printf '%s' 'bXBvc2UucnVudGltZS5nZXRWYWx1ZQppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5ydW50aW1lLm11dGFibGVTdGF0ZU9mCmltcG9y' >> "$TMPB64"
    printf '%s' 'dCBhbmRyb2lkeC5jb21wb3NlLnJ1bnRpbWUucmVtZW1iZXIKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UucnVudGltZS5yZW1lbWJl' >> "$TMPB64"
    printf '%s' 'ckNvcm91dGluZVNjb3BlCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLnJ1bnRpbWUuc2V0VmFsdWUKaW1wb3J0IGFuZHJvaWR4LmNv' >> "$TMPB64"
    printf '%s' 'bXBvc2UudWkuQWxpZ25tZW50CmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLnVpLk1vZGlmaWVyCmltcG9ydCBhbmRyb2lkeC5jb21w' >> "$TMPB64"
    printf '%s' 'b3NlLnVpLmRyYXcuY2xpcAppbXBvcnQgYW5kcm9pZHguY29tcG9zZS51aS5ncmFwaGljcy5Db2xvcgppbXBvcnQgYW5kcm9pZHgu' >> "$TMPB64"
    printf '%s' 'Y29tcG9zZS51aS5sYXlvdXQuQ29udGVudFNjYWxlCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLnVpLnBsYXRmb3JtLkxvY2FsQ29u' >> "$TMPB64"
    printf '%s' 'dGV4dAppbXBvcnQgYW5kcm9pZHguY29tcG9zZS51aS50ZXh0LmZvbnQuRm9udFdlaWdodAppbXBvcnQgYW5kcm9pZHguY29tcG9z' >> "$TMPB64"
    printf '%s' 'ZS51aS50ZXh0LnN0eWxlLlRleHRPdmVyZmxvdwppbXBvcnQgYW5kcm9pZHguY29tcG9zZS51aS51bml0LmRwCmltcG9ydCBhbmRy' >> "$TMPB64"
    printf '%s' 'b2lkeC5jb3JlLnZpZXcuV2luZG93Q29tcGF0CmltcG9ydCBjb2lsLmNvbXBvc2UuQXN5bmNJbWFnZQppbXBvcnQgamF2YS5uZXQu' >> "$TMPB64"
    printf '%s' 'SHR0cFVSTENvbm5lY3Rpb24KaW1wb3J0IGphdmEubmV0LlVSTAppbXBvcnQgamF2YS5uZXQuVVJMRW5jb2RlcgppbXBvcnQgamF2' >> "$TMPB64"
    printf '%s' 'YS5zZWN1cml0eS5NZXNzYWdlRGlnZXN0CmltcG9ydCBqYXZhLnNlY3VyaXR5LlNlY3VyZVJhbmRvbQppbXBvcnQga290bGlueC5j' >> "$TMPB64"
    printf '%s' 'b3JvdXRpbmVzLkRpc3BhdGNoZXJzCmltcG9ydCBrb3RsaW54LmNvcm91dGluZXMubGF1bmNoCmltcG9ydCBrb3RsaW54LmNvcm91' >> "$TMPB64"
    printf '%s' 'dGluZXMud2l0aENvbnRleHQKaW1wb3J0IG9yZy5qc29uLkpTT05PYmplY3QKCi8vIFszOXdwM10g5Zyo57q/5aOB57q45bqT77yI' >> "$TMPB64"
    printf '%s' '55yf5a6e5rqQ77ya5pCc5Zu+56We5Zmo6IGa5ZCI5Zu+5rGg77yM562+5ZCN5Y2P6K6u5bey6YCG5ZCR6aqM6K+BIGNvZGU9MjAw' >> "$TMPB64"
    printf '%s' '77yJ44CCCmRhdGEgY2xhc3MgV3BJdGVtKAogICAgdmFsIGlkOiBMb25nLAogICAgdmFsIHRpdGxlOiBTdHJpbmcsCiAgICB2YWwg' >> "$TMPB64"
    printf '%s' 'dGh1bWI6IFN0cmluZywKICAgIHZhbCBsYXJnZTogU3RyaW5nLAogICAgdmFsIHdpZHRoOiBJbnQsCiAgICB2YWwgaGVpZ2h0OiBJ' >> "$TMPB64"
    printf '%s' 'bnQsCikKCmRhdGEgY2xhc3MgV3BDYXQoCiAgICB2YWwgbmFtZTogU3RyaW5nLAogICAgdmFsIHBhdGg6IFN0cmluZywKICAgIHZh' >> "$TMPB64"
    printf '%s' 'bCBiYXNlUGFyYW1zOiBNYXA8U3RyaW5nLCBTdHJpbmc+LAogICAgdmFsIHBhZ2VTaXplOiBJbnQsCikKCnByaXZhdGUgZnVuIGZl' >> "$TMPB64"
    printf '%s' 'ZWRDYXQobmFtZTogU3RyaW5nLCBzaXplVHlwZTogU3RyaW5nKSA9IFdwQ2F0KAogICAgbmFtZSwgIi92Mi9ob21lL2ZlZWQiLAog' >> "$TMPB64"
    printf '%s' 'ICAgbWFwT2YoCiAgICAgICAgInNpemVfdHlwZSIgdG8gc2l6ZVR5cGUsICJzb3J0X3R5cGUiIHRvICI0IiwKICAgICAgICAibGFy' >> "$TMPB64"
    printf '%s' 'Z2VTY2FsZSIgdG8gImZhbHNlIiwgImlzX2xhcmdlX3NjYWxlIiB0byAiMCIsCiAgICApLAogICAgNjAsCikKCi8vIFszOXdwY2F0' >> "$TMPB64"
    printf '%s' 'c10g5qiq5bGPL+eUteiEkeWjgee6uOi1sOWPpuS4gOadoemTviAvdjEvc2VhcmNoL3BjU2NyZWVu77yIUGVla1BpbGkg5ZCM5rqQ' >> "$TMPB64"
    printf '%s' '5pWw5o2u77yJCnByaXZhdGUgZnVuIHBjQ2F0KG5hbWU6IFN0cmluZywgc2l6ZVR5cGU6IFN0cmluZykgPSBXcENhdCgKICAgIG5h' >> "$TMPB64"
    printf '%s' 'bWUsICIvdjEvc2VhcmNoL3BjU2NyZWVuIiwKICAgIG1hcE9mKAogICAgICAgICJzaXplX3R5cGUiIHRvIHNpemVUeXBlLCAic29y' >> "$TMPB64"
    printf '%s' 'dF90eXBlIiB0byAiNCIsCiAgICAgICAgImxhcmdlU2NhbGUiIHRvICJ0cnVlIiwgImlzX2xhcmdlX3NjYWxlIiB0byAiLTEiLAog' >> "$TMPB64"
    printf '%s' 'ICAgKSwKICAgIDMwLAopCgpwcml2YXRlIHZhbCBXUF9DQVRTOiBMaXN0PFdwQ2F0PiA9IGxpc3RPZigKICAgIGZlZWRDYXQoIuey' >> "$TMPB64"
    printf '%s' 'vumAiSIsICIwIiksCiAgICBmZWVkQ2F0KCLpq5jmuIUiLCAiMjEiKSwKICAgIGZlZWRDYXQoIuWFqOmdouWxjyIsICIxIiksCiAg' >> "$TMPB64"
    printf '%s' 'ICBmZWVkQ2F0KCIySyIsICIyIiksCiAgICBmZWVkQ2F0KCI0SyIsICI1IiksCiAgICBmZWVkQ2F0KCI1SyIsICI2IiksIC8vIFsz' >> "$TMPB64"
    printf '%s' 'OXdwY2F0c10KICAgIGZlZWRDYXQoIjhLIiwgIjciKSwgLy8gWzM5d3BjYXRzXQogICAgZmVlZENhdCgiMUvmqKrlsY8iLCAiMyIp' >> "$TMPB64"
    printf '%s' 'LCAvLyBbMzl3cGNhdHNdCiAgICBwY0NhdCgi55S16ISR5aOB57q4IiwgIjAiKSwgLy8gWzM5d3BjYXRzXQogICAgcGNDYXQoIjJL' >> "$TMPB64"
    printf '%s' '5qiq5bGPIiwgIjIyIiksIC8vIFszOXdwY2F0c10KICAgIHBjQ2F0KCI0S+aoquWxjyIsICIyNiIpLCAvLyBbMzl3cGNhdHNdCiAg' >> "$TMPB64"
    printf '%s' 'ICBwY0NhdCgiNUvmqKrlsY8iLCAiMjkiKSwgLy8gWzM5d3BjYXRzXQogICAgcGNDYXQoIjhL5qiq5bGPIiwgIjMxIiksIC8vIFsz' >> "$TMPB64"
    printf '%s' 'OXdwY2F0c10KICAgIFdwQ2F0KAogICAgICAgICJBSee7mOeUuyIsICIvYXBpL3dhbGxwYXBlci9jbGllbnQvYnlUYWciLAogICAg' >> "$TMPB64"
    printf '%s' 'ICAgIG1hcE9mKAogICAgICAgICAgICAidGFnIiB0byAiQUnnu5jnlLsiLCAic29ydF90eXBlIiB0byAiNCIsCiAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICJpc19sYXJnZV9zY2FsZSIgdG8gIi0xIiwgImxhcmdlU2NhbGUiIHRvICJ0cnVlIiwKICAgICAgICAgICAgInNpemVfdHlwZV9s' >> "$TMPB64"
    printf '%s' 'aXN0IiB0byAiWzIxLDIzLDI0LDI3LDMwLDMyXSIsICJzY2VuZV90eXBlX2xpc3QiIHRvICJbMF0iLAogICAgICAgICksCiAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgMzAsCiAgICApLAogICAgV3BDYXQoCiAgICAgICAgIuW5s+advyIsICIvdjIvc2VhcmNoL2NvbW1vbkxpc3QiLAogICAgICAg' >> "$TMPB64"
    printf '%s' 'IG1hcE9mKAogICAgICAgICAgICAidGFibGVfdHlwZSIgdG8gIjgiLCAic29ydF90eXBlIiB0byAiNCIsCiAgICAgICAgICAgICJs' >> "$TMPB64"
    printf '%s' 'YXJnZVNjYWxlIiB0byAidHJ1ZSIsICJpc19sYXJnZV9zY2FsZSIgdG8gIi0xIiwgInNlYXJjaF93b3JkIiB0byAiIiwKICAgICAg' >> "$TMPB64"
    printf '%s' 'ICApLAogICAgICAgIDMwLAogICAgKSwKICAgIFdwQ2F0KAogICAgICAgICLogYrlpKnog4zmma8iLCAiL3YyL3NlYXJjaC9jb21t' >> "$TMPB64"
    printf '%s' 'b25MaXN0IiwKICAgICAgICBtYXBPZigKICAgICAgICAgICAgInRhYmxlX3R5cGUiIHRvICI0IiwgInNvcnRfdHlwZSIgdG8gIjQi' >> "$TMPB64"
    printf '%s' 'LAogICAgICAgICAgICAibGFyZ2VTY2FsZSIgdG8gInRydWUiLCAiaXNfbGFyZ2Vfc2NhbGUiIHRvICItMSIsICJzZWFyY2hfd29y' >> "$TMPB64"
    printf '%s' 'ZCIgdG8gIiIsCiAgICAgICAgKSwKICAgICAgICAzMCwKICAgICksCikKCm9iamVjdCBXcEFwaSB7CiAgICBwcml2YXRlIGNvbnN0' >> "$TMPB64"
    printf '%s' 'IHZhbCBIT1NUID0gImh0dHBzOi8vd2FsbHBhcGVyLnNvdXR1c2hlbnFpLmNvbSIKICAgIHByaXZhdGUgY29uc3QgdmFsIFNJR05f' >> "$TMPB64"
    printf '%s' 'S0VZID0gImQ5ZmQzZWMzOTQiCgogICAgcHJpdmF0ZSBmdW4gZGV2aWNlSWQoY29udGV4dDogQ29udGV4dCk6IFN0cmluZyB7CiAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgdmFsIHNwID0gY29udGV4dC5nZXRTaGFyZWRQcmVmZXJlbmNlcygid2FsbHBhcGVyX3ByZWZzIiwgQ29udGV4dC5NT0RF' >> "$TMPB64"
    printf '%s' 'X1BSSVZBVEUpCiAgICAgICAgdmFsIHNhdmVkID0gc3AuZ2V0U3RyaW5nKCJ3cF9kZXZpY2VfaWQiLCBudWxsKQogICAgICAgIGlm' >> "$TMPB64"
    printf '%s' 'ICghc2F2ZWQuaXNOdWxsT3JCbGFuaygpKSByZXR1cm4gc2F2ZWQKICAgICAgICB2YWwgYnl0ZXMgPSBCeXRlQXJyYXkoMTYpCiAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgU2VjdXJlUmFuZG9tKCkubmV4dEJ5dGVzKGJ5dGVzKQogICAgICAgIHZhbCBpZCA9IGJ5dGVzLmpvaW5Ub1N0cmluZygi' >> "$TMPB64"
    printf '%s' 'IikgeyAiJTAyeCIuZm9ybWF0KGl0KSB9CiAgICAgICAgc3AuZWRpdCgpLnB1dFN0cmluZygid3BfZGV2aWNlX2lkIiwgaWQpLmFw' >> "$TMPB64"
    printf '%s' 'cGx5KCkKICAgICAgICByZXR1cm4gaWQKICAgIH0KCiAgICBwcml2YXRlIGZ1biBzY3JhbWJsZWRUaW1lKCk6IFN0cmluZyB7CiAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgdmFsIHMgPSBTeXN0ZW0uY3VycmVudFRpbWVNaWxsaXMoKSAvIDEwMDAKICAgICAgICByZXR1cm4gKHMgKiAxMDAwICsg' >> "$TMPB64"
    printf '%s' 'KChzIHhvciAzMzRMKSAlIDEwMDApKS50b1N0cmluZygpCiAgICB9CgogICAgcHJpdmF0ZSBmdW4gbWQ1KHRleHQ6IFN0cmluZyk6' >> "$TMPB64"
    printf '%s' 'IFN0cmluZyB7CiAgICAgICAgdmFsIGRpZ2VzdCA9IE1lc3NhZ2VEaWdlc3QuZ2V0SW5zdGFuY2UoIk1ENSIpLmRpZ2VzdCh0ZXh0' >> "$TMPB64"
    printf '%s' 'LnRvQnl0ZUFycmF5KENoYXJzZXRzLlVURl84KSkKICAgICAgICByZXR1cm4gZGlnZXN0LmpvaW5Ub1N0cmluZygiIikgeyAiJTAy' >> "$TMPB64"
    printf '%s' 'eCIuZm9ybWF0KGl0KSB9CiAgICB9CgogICAgc3VzcGVuZCBmdW4gZmV0Y2goY29udGV4dDogQ29udGV4dCwgY2F0OiBXcENhdCwg' >> "$TMPB64"
    printf '%s' 'cGFnZTogSW50KTogUmVzdWx0PExpc3Q8V3BJdGVtPj4gPQogICAgICAgIHdpdGhDb250ZXh0KERpc3BhdGNoZXJzLklPKSB7CiAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgIHRyeSB7CiAgICAgICAgICAgICAgICB2YWwgdGltZSA9IHNjcmFtYmxlZFRpbWUoKQogICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'dmFsIHBhcmFtcyA9IHNvcnRlZE1hcE9mPFN0cmluZywgU3RyaW5nPigpCiAgICAgICAgICAgICAgICBwYXJhbXNbInBsYXRmb3Jt' >> "$TMPB64"
    printf '%s' 'Il0gPSAiMCIKICAgICAgICAgICAgICAgIHBhcmFtc1sidmVyc2lvbl9jb2RlIl0gPSAiMTkzIgogICAgICAgICAgICAgICAgcGFy' >> "$TMPB64"
    printf '%s' 'YW1zWyJwcm9kdWN0X2lkIl0gPSAiMjAzIgogICAgICAgICAgICAgICAgcGFyYW1zWyJkZXZpY2VfaWQiXSA9IGRldmljZUlkKGNv' >> "$TMPB64"
    printf '%s' 'bnRleHQpCiAgICAgICAgICAgICAgICBwYXJhbXNbImlzX2VuY3J5cHQiXSA9ICJmYWxzZSIKICAgICAgICAgICAgICAgIHBhcmFt' >> "$TMPB64"
    printf '%s' 'c1sidGltZSJdID0gdGltZQogICAgICAgICAgICAgICAgcGFyYW1zLnB1dEFsbChjYXQuYmFzZVBhcmFtcykKICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgIHBhcmFtc1sicGFnZSJdID0gcGFnZS50b1N0cmluZygpCiAgICAgICAgICAgICAgICBwYXJhbXNbInBhZ2Vfc2l6ZSJdID0g' >> "$TMPB64"
    printf '%s' 'Y2F0LnBhZ2VTaXplLnRvU3RyaW5nKCkKICAgICAgICAgICAgICAgIHZhbCBzaWduU3JjID0gcGFyYW1zLmVudHJpZXMuam9pblRv' >> "$TMPB64"
    printf '%s' 'U3RyaW5nKCImIikgeyAiJHtpdC5rZXl9PSR7aXQudmFsdWV9IiB9ICsKICAgICAgICAgICAgICAgICAgICAiJmtleT0iICsgU0lH' >> "$TMPB64"
    printf '%s' 'Tl9LRVkKICAgICAgICAgICAgICAgIHBhcmFtc1sic2lnbiJdID0gbWQ1KHNpZ25TcmMpCiAgICAgICAgICAgICAgICB2YWwgYm9k' >> "$TMPB64"
    printf '%s' 'eSA9IHBhcmFtcy5lbnRyaWVzLmpvaW5Ub1N0cmluZygiJiIpIHsKICAgICAgICAgICAgICAgICAgICAiJHtpdC5rZXl9PSR7VVJM' >> "$TMPB64"
    printf '%s' 'RW5jb2Rlci5lbmNvZGUoaXQudmFsdWUsICJVVEYtOCIpfSIKICAgICAgICAgICAgICAgIH0KICAgICAgICAgICAgICAgIHZhbCBj' >> "$TMPB64"
    printf '%s' 'b25uID0gVVJMKEhPU1QgKyBjYXQucGF0aCkub3BlbkNvbm5lY3Rpb24oKSBhcyBIdHRwVVJMQ29ubmVjdGlvbgogICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgY29ubi5yZXF1ZXN0TWV0aG9kID0gIlBPU1QiCiAgICAgICAgICAgICAgICBjb25uLmNvbm5lY3RUaW1lb3V0ID0gMTAw' >> "$TMPB64"
    printf '%s' 'MDAKICAgICAgICAgICAgICAgIGNvbm4ucmVhZFRpbWVvdXQgPSAyNTAwMAogICAgICAgICAgICAgICAgY29ubi5kb091dHB1dCA9' >> "$TMPB64"
    printf '%s' 'IHRydWUKICAgICAgICAgICAgICAgIGNvbm4uc2V0UmVxdWVzdFByb3BlcnR5KCJVc2VyLUFnZW50IiwgIm9raHR0cC8zLjEyLjYi' >> "$TMPB64"
    printf '%s' 'KQogICAgICAgICAgICAgICAgY29ubi5zZXRSZXF1ZXN0UHJvcGVydHkoIkNvbnRlbnQtVHlwZSIsICJhcHBsaWNhdGlvbi94LXd3' >> "$TMPB64"
    printf '%s' 'dy1mb3JtLXVybGVuY29kZWQiKQogICAgICAgICAgICAgICAgY29ubi5zZXRSZXF1ZXN0UHJvcGVydHkoInRpbWVzdGFtcCIsIHRp' >> "$TMPB64"
    printf '%s' 'bWUpCiAgICAgICAgICAgICAgICBjb25uLm91dHB1dFN0cmVhbS51c2UgeyBpdC53cml0ZShib2R5LnRvQnl0ZUFycmF5KENoYXJz' >> "$TMPB64"
    printf '%s' 'ZXRzLlVURl84KSkgfQogICAgICAgICAgICAgICAgdmFsIHRleHQgPSBjb25uLmlucHV0U3RyZWFtLmJ1ZmZlcmVkUmVhZGVyKCku' >> "$TMPB64"
    printf '%s' 'cmVhZFRleHQoKQogICAgICAgICAgICAgICAgdmFsIGpzb24gPSBKU09OT2JqZWN0KHRleHQpCiAgICAgICAgICAgICAgICBpZiAo' >> "$TMPB64"
    printf '%s' 'anNvbi5vcHRJbnQoImNvZGUiKSAhPSAyMDApIHsKICAgICAgICAgICAgICAgICAgICByZXR1cm5Ad2l0aENvbnRleHQgUmVzdWx0' >> "$TMPB64"
    printf '%s' 'LmZhaWx1cmUoRXhjZXB0aW9uKGpzb24ub3B0U3RyaW5nKCJlcnJvcl9tc2ciLCAi5o6l5Y+j6ZSZ6K+vIikpKQogICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgfQogICAgICAgICAgICAgICAgdmFsIGFyciA9IGpzb24ub3B0SlNPTkFycmF5KCJkYXRhIikKICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICA/OiByZXR1cm5Ad2l0aENvbnRleHQgUmVzdWx0LnN1Y2Nlc3MoZW1wdHlMaXN0KCkpCiAgICAgICAgICAgICAgICB2YWwg' >> "$TMPB64"
    printf '%s' 'b3V0ID0gQXJyYXlMaXN0PFdwSXRlbT4oKQogICAgICAgICAgICAgICAgZm9yIChpIGluIDAgdW50aWwgYXJyLmxlbmd0aCgpKSB7' >> "$TMPB64"
    printf '%s' 'CiAgICAgICAgICAgICAgICAgICAgdmFsIG8gPSBhcnIub3B0SlNPTk9iamVjdChpKSA/OiBjb250aW51ZQogICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgIHZhbCBsYXJnZSA9IG8ub3B0U3RyaW5nKCJsYXJnZVVybCIpCiAgICAgICAgICAgICAgICAgICAgdmFsIHRodW1iID0g' >> "$TMPB64"
    printf '%s' 'by5vcHRTdHJpbmcoInRodW1iVXJsIikKICAgICAgICAgICAgICAgICAgICBpZiAobGFyZ2UuaXNCbGFuaygpICYmIHRodW1iLmlz' >> "$TMPB64"
    printf '%s' 'QmxhbmsoKSkgY29udGludWUKICAgICAgICAgICAgICAgICAgICAvLyBbMzl3cG51bGxdIOWQjuerr+aXoOagh+mimOaXtui/lOWb' >> "$TMPB64"
    printf '%s' 'nuWtl+espuS4siAibnVsbCLvvIzkuZ/lvZPnqbrlpITnkIYKICAgICAgICAgICAgICAgICAgICB2YWwgdGl0bGUgPSBvLm9wdFN0' >> "$TMPB64"
    printf '%s' 'cmluZygidGl0bGUiKS50YWtlVW5sZXNzIHsgaXQuaXNCbGFuaygpIHx8IGl0ID09ICJudWxsIiB9CiAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgID86IG8ub3B0U3RyaW5nKCJkZXRhaWxJbmZvIikudGFrZVVubGVzcyB7IGl0LmlzQmxhbmsoKSB8fCBpdCA9PSAibnVs' >> "$TMPB64"
    printf '%s' 'bCIgfQogICAgICAgICAgICAgICAgICAgICAgICA/OiAi5aOB57q4ICMke28ub3B0TG9uZygiaWQiKX0iCiAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgb3V0LmFkZCgKICAgICAgICAgICAgICAgICAgICAgICAgV3BJdGVtKAogICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'aWQgPSBvLm9wdExvbmcoImlkIiksCiAgICAgICAgICAgICAgICAgICAgICAgICAgICB0aXRsZSA9IHRpdGxlLAogICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgdGh1bWIgPSB0aHVtYi5pZkJsYW5rIHsgbGFyZ2UgfSwKICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgIGxhcmdlID0gbGFyZ2UuaWZCbGFuayB7IHRodW1iIH0sCiAgICAgICAgICAgICAgICAgICAgICAgICAgICB3aWR0aCA9IG8u' >> "$TMPB64"
    printf '%s' 'b3B0SW50KCJ3aWR0aCIpLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgaGVpZ2h0ID0gby5vcHRJbnQoImhlaWdodCIpLAog' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICApCiAgICAgICAgICAgICAgICAgICAgKQogICAgICAgICAgICAgICAgfQogICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgUmVzdWx0LnN1Y2Nlc3Mob3V0KQogICAgICAgICAgICB9IGNhdGNoIChlOiBFeGNlcHRpb24pIHsKICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgIFJlc3VsdC5mYWlsdXJlKGUpCiAgICAgICAgICAgIH0KICAgICAgICB9Cn0KCmNsYXNzIFdhbGxwYXBlckxpYnJhcnlBY3Rp' >> "$TMPB64"
    printf '%s' 'dml0eSA6IENvbXBvbmVudEFjdGl2aXR5KCkgewogICAgb3ZlcnJpZGUgZnVuIG9uQ3JlYXRlKHNhdmVkSW5zdGFuY2VTdGF0ZTog' >> "$TMPB64"
    printf '%s' 'QnVuZGxlPykgewogICAgICAgIHN1cGVyLm9uQ3JlYXRlKHNhdmVkSW5zdGFuY2VTdGF0ZSkKICAgICAgICB2YWwgYXBwQ3R4ID0g' >> "$TMPB64"
    printf '%s' 'YXBwbGljYXRpb25Db250ZXh0CiAgICAgICAgTXVzaWNUaGVtZU1hbmFnZXIuaW5pdChhcHBDdHgpCiAgICAgICAgV2FsbHBhcGVy' >> "$TMPB64"
    printf '%s' 'TWFuYWdlci5pbml0KGFwcEN0eCkKICAgICAgICBzZXRDb250ZW50IHsKICAgICAgICAgICAgdmFsIGlzRGFyayBieSBNdXNpY1Ro' >> "$TMPB64"
    printf '%s' 'ZW1lTWFuYWdlci5pc0RhcmtUaGVtZQogICAgICAgICAgICB2YWwgd2luZG93ID0gdGhpc0BXYWxscGFwZXJMaWJyYXJ5QWN0aXZp' >> "$TMPB64"
    printf '%s' 'dHkud2luZG93CiAgICAgICAgICAgIFNpZGVFZmZlY3QgewogICAgICAgICAgICAgICAgV2luZG93Q29tcGF0LmdldEluc2V0c0Nv' >> "$TMPB64"
    printf '%s' 'bnRyb2xsZXIod2luZG93LCB3aW5kb3cuZGVjb3JWaWV3KQogICAgICAgICAgICAgICAgICAgIC5pc0FwcGVhcmFuY2VMaWdodFN0' >> "$TMPB64"
    printf '%s' 'YXR1c0JhcnMgPSAhaXNEYXJrCiAgICAgICAgICAgIH0KICAgICAgICAgICAgTHhNdXNpY1RoZW1lKGlzRGFya1RoZW1lID0gaXNE' >> "$TMPB64"
    printf '%s' 'YXJrKSB7CiAgICAgICAgICAgICAgICBXYWxscGFwZXJMaWJyYXJ5U2NyZWVuKG9uQmFjayA9IHsgZmluaXNoKCkgfSkKICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgfQogICAgICAgIH0KICAgIH0KfQoKQENvbXBvc2FibGUKZnVuIFdhbGxwYXBlckxpYnJhcnlTY3JlZW4ob25CYWNrOiAo' >> "$TMPB64"
    printf '%s' 'KSAtPiBVbml0KSB7CiAgICB2YWwgY29udGV4dCA9IExvY2FsQ29udGV4dC5jdXJyZW50CiAgICB2YWwgc2NvcGUgPSByZW1lbWJl' >> "$TMPB64"
    printf '%s' 'ckNvcm91dGluZVNjb3BlKCkKICAgIHZhciBjYXQgYnkgcmVtZW1iZXIgeyBtdXRhYmxlU3RhdGVPZihXUF9DQVRTWzBdKSB9CiAg' >> "$TMPB64"
    printf '%s' 'ICB2YXIgaXRlbXMgYnkgcmVtZW1iZXIgeyBtdXRhYmxlU3RhdGVPZjxMaXN0PFdwSXRlbT4+KGVtcHR5TGlzdCgpKSB9CiAgICB2' >> "$TMPB64"
    printf '%s' 'YXIgbG9hZGluZyBieSByZW1lbWJlciB7IG11dGFibGVTdGF0ZU9mKGZhbHNlKSB9CiAgICB2YXIgZXJyb3IgYnkgcmVtZW1iZXIg' >> "$TMPB64"
    printf '%s' 'eyBtdXRhYmxlU3RhdGVPZjxTdHJpbmc/PihudWxsKSB9CiAgICB2YXIgcGFnZSBieSByZW1lbWJlciB7IG11dGFibGVTdGF0ZU9m' >> "$TMPB64"
    printf '%s' 'KDEpIH0KICAgIHZhciBlbmRSZWFjaGVkIGJ5IHJlbWVtYmVyIHsgbXV0YWJsZVN0YXRlT2YoZmFsc2UpIH0KCiAgICBmdW4gbG9h' >> "$TMPB64"
    printf '%s' 'ZCh0YXJnZXQ6IFdwQ2F0LCB0YXJnZXRQYWdlOiBJbnQsIGFwcGVuZDogQm9vbGVhbikgewogICAgICAgIGxvYWRpbmcgPSB0cnVl' >> "$TMPB64"
    printf '%s' 'CiAgICAgICAgaWYgKCFhcHBlbmQpIGVycm9yID0gbnVsbAogICAgICAgIHNjb3BlLmxhdW5jaCB7CiAgICAgICAgICAgIHZhbCBy' >> "$TMPB64"
    printf '%s' 'ZXN1bHQgPSBXcEFwaS5mZXRjaChjb250ZXh0LCB0YXJnZXQsIHRhcmdldFBhZ2UpCiAgICAgICAgICAgIGxvYWRpbmcgPSBmYWxz' >> "$TMPB64"
    printf '%s' 'ZQogICAgICAgICAgICByZXN1bHQub25TdWNjZXNzIHsgbGlzdCAtPgogICAgICAgICAgICAgICAgaXRlbXMgPSBpZiAoYXBwZW5k' >> "$TMPB64"
    printf '%s' 'KSB7CiAgICAgICAgICAgICAgICAgICAgdmFsIGtub3duID0gaXRlbXMubWFwIHsgaXQuaWQgfS50b0hhc2hTZXQoKQogICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgIGl0ZW1zICsgbGlzdC5maWx0ZXIgeyBpdC5pZCAhaW4ga25vd24gfQogICAgICAgICAgICAgICAgfSBlbHNl' >> "$TMPB64"
    printf '%s' 'IHsKICAgICAgICAgICAgICAgICAgICBsaXN0CiAgICAgICAgICAgICAgICB9CiAgICAgICAgICAgICAgICBwYWdlID0gdGFyZ2V0' >> "$TMPB64"
    printf '%s' 'UGFnZQogICAgICAgICAgICAgICAgZW5kUmVhY2hlZCA9IGxpc3Quc2l6ZSA8IHRhcmdldC5wYWdlU2l6ZQogICAgICAgICAgICB9' >> "$TMPB64"
    printf '%s' 'Lm9uRmFpbHVyZSB7CiAgICAgICAgICAgICAgICBpZiAoIWFwcGVuZCkgZXJyb3IgPSAi5Yqg6L295aSx6LSl77yM6K+35qOA5p+l' >> "$TMPB64"
    printf '%s' '572R57uc5ZCO6YeN6K+VIgogICAgICAgICAgICB9CiAgICAgICAgfQogICAgfQoKICAgIExhdW5jaGVkRWZmZWN0KGNhdCkgewog' >> "$TMPB64"
    printf '%s' 'ICAgICAgIGl0ZW1zID0gZW1wdHlMaXN0KCkKICAgICAgICBwYWdlID0gMQogICAgICAgIGVuZFJlYWNoZWQgPSBmYWxzZQogICAg' >> "$TMPB64"
    printf '%s' 'ICAgIGxvYWQoY2F0LCAxLCBmYWxzZSkKICAgIH0KCiAgICBDb2x1bW4oCiAgICAgICAgbW9kaWZpZXIgPSBNb2RpZmllcgogICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAuZmlsbE1heFNpemUoKQogICAgICAgICAgICAuYmFja2dyb3VuZChtdXNpY0NvbG9ycygpLmJhY2tncm91bmQpCiAg' >> "$TMPB64"
    printf '%s' 'ICApIHsKICAgICAgICBSb3coCiAgICAgICAgICAgIG1vZGlmaWVyID0gTW9kaWZpZXIKICAgICAgICAgICAgICAgIC5maWxsTWF4' >> "$TMPB64"
    printf '%s' 'V2lkdGgoKQogICAgICAgICAgICAgICAgLnBhZGRpbmcoc3RhcnQgPSA4LmRwLCBlbmQgPSAxNi5kcCwgdG9wID0gNDguZHAsIGJv' >> "$TMPB64"
    printf '%s' 'dHRvbSA9IDguZHApLAogICAgICAgICAgICB2ZXJ0aWNhbEFsaWdubWVudCA9IEFsaWdubWVudC5DZW50ZXJWZXJ0aWNhbGx5LAog' >> "$TMPB64"
    printf '%s' 'ICAgICAgICkgewogICAgICAgICAgICBUZXh0KAogICAgICAgICAgICAgICAgdGV4dCA9ICLigLkiLAogICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'c3R5bGUgPSBNYXRlcmlhbFRoZW1lLnR5cG9ncmFwaHkuaGVhZGxpbmVNZWRpdW0sCiAgICAgICAgICAgICAgICBjb2xvciA9IG11' >> "$TMPB64"
    printf '%s' 'c2ljQ29sb3JzKCkudGV4dFByaW1hcnksCiAgICAgICAgICAgICAgICBtb2RpZmllciA9IE1vZGlmaWVyCiAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgLmNsaWNrYWJsZSB7IG9uQmFjaygpIH0KICAgICAgICAgICAgICAgICAgICAucGFkZGluZyhob3Jpem9udGFsID0gMTIu' >> "$TMPB64"
    printf '%s' 'ZHAsIHZlcnRpY2FsID0gNC5kcCksCiAgICAgICAgICAgICkKICAgICAgICAgICAgVGV4dCgKICAgICAgICAgICAgICAgIHRleHQg' >> "$TMPB64"
    printf '%s' 'PSAi5Zyo57q/5aOB57q45bqTIiwKICAgICAgICAgICAgICAgIHN0eWxlID0gTWF0ZXJpYWxUaGVtZS50eXBvZ3JhcGh5LnRpdGxl' >> "$TMPB64"
    printf '%s' 'TGFyZ2UuY29weShmb250V2VpZ2h0ID0gRm9udFdlaWdodC5Cb2xkKSwKICAgICAgICAgICAgICAgIGNvbG9yID0gbXVzaWNDb2xv' >> "$TMPB64"
    printf '%s' 'cnMoKS50ZXh0UHJpbWFyeSwKICAgICAgICAgICAgKQogICAgICAgIH0KICAgICAgICBMYXp5Um93KAogICAgICAgICAgICBjb250' >> "$TMPB64"
    printf '%s' 'ZW50UGFkZGluZyA9IFBhZGRpbmdWYWx1ZXMoaG9yaXpvbnRhbCA9IDE2LmRwKSwKICAgICAgICAgICAgaG9yaXpvbnRhbEFycmFu' >> "$TMPB64"
    printf '%s' 'Z2VtZW50ID0gQXJyYW5nZW1lbnQuc3BhY2VkQnkoMTAuZHApLAogICAgICAgICkgewogICAgICAgICAgICBpdGVtcyhXUF9DQVRT' >> "$TMPB64"
    printf '%s' 'LCBrZXkgPSB7IGl0Lm5hbWUgfSkgeyBjIC0+CiAgICAgICAgICAgICAgICB2YWwgc2VsZWN0ZWQgPSBjLm5hbWUgPT0gY2F0Lm5h' >> "$TMPB64"
    printf '%s' 'bWUKICAgICAgICAgICAgICAgIEJveCgKICAgICAgICAgICAgICAgICAgICBtb2RpZmllciA9IE1vZGlmaWVyCiAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgIC5jbGlwKFJvdW5kZWRDb3JuZXJTaGFwZSg1MCkpCiAgICAgICAgICAgICAgICAgICAgICAgIC5iYWNrZ3Jv' >> "$TMPB64"
    printf '%s' 'dW5kKGlmIChzZWxlY3RlZCkgbXVzaWNDb2xvcnMoKS5hY2NlbnQgZWxzZSBtdXNpY0NvbG9ycygpLmNhcmRTZWNvbmRhcnkpCiAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgIC5jbGlja2FibGUgeyBjYXQgPSBjIH0KICAgICAgICAgICAgICAgICAgICAgICAgLnBhZGRp' >> "$TMPB64"
    printf '%s' 'bmcoaG9yaXpvbnRhbCA9IDE4LmRwLCB2ZXJ0aWNhbCA9IDguZHApLAogICAgICAgICAgICAgICAgKSB7CiAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgVGV4dCgKICAgICAgICAgICAgICAgICAgICAgICAgdGV4dCA9IGMubmFtZSwKICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'c3R5bGUgPSBNYXRlcmlhbFRoZW1lLnR5cG9ncmFwaHkuYm9keU1lZGl1bSwKICAgICAgICAgICAgICAgICAgICAgICAgY29sb3Ig' >> "$TMPB64"
    printf '%s' 'PSBpZiAoc2VsZWN0ZWQpIG11c2ljQ29sb3JzKCkuYWNjZW50VGV4dCBlbHNlIG11c2ljQ29sb3JzKCkudGV4dFNlY29uZGFyeSwK' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICApCiAgICAgICAgICAgICAgICB9CiAgICAgICAgICAgIH0KICAgICAgICB9CiAgICAgICAgQm94' >> "$TMPB64"
    printf '%s' 'KG1vZGlmaWVyID0gTW9kaWZpZXIuZmlsbE1heFNpemUoKSkgewogICAgICAgICAgICB3aGVuIHsKICAgICAgICAgICAgICAgIGxv' >> "$TMPB64"
    printf '%s' 'YWRpbmcgJiYgaXRlbXMuaXNFbXB0eSgpIC0+IHsKICAgICAgICAgICAgICAgICAgICBDaXJjdWxhclByb2dyZXNzSW5kaWNhdG9y' >> "$TMPB64"
    printf '%s' 'KAogICAgICAgICAgICAgICAgICAgICAgICBjb2xvciA9IG11c2ljQ29sb3JzKCkuYWNjZW50LAogICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICBtb2RpZmllciA9IE1vZGlmaWVyLmFsaWduKEFsaWdubWVudC5DZW50ZXIpLAogICAgICAgICAgICAgICAgICAgICkKICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgIH0KICAgICAgICAgICAgICAgIGVycm9yICE9IG51bGwgJiYgaXRlbXMuaXNFbXB0eSgpIC0+IHsKICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICBDb2x1bW4oCiAgICAgICAgICAgICAgICAgICAgICAgIG1vZGlmaWVyID0gTW9kaWZpZXIuYWxpZ24oQWxp' >> "$TMPB64"
    printf '%s' 'Z25tZW50LkNlbnRlciksCiAgICAgICAgICAgICAgICAgICAgICAgIGhvcml6b250YWxBbGlnbm1lbnQgPSBBbGlnbm1lbnQuQ2Vu' >> "$TMPB64"
    printf '%s' 'dGVySG9yaXpvbnRhbGx5LAogICAgICAgICAgICAgICAgICAgICkgewogICAgICAgICAgICAgICAgICAgICAgICBUZXh0KAogICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgdGV4dCA9IGVycm9yID86ICIiLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgc3R5' >> "$TMPB64"
    printf '%s' 'bGUgPSBNYXRlcmlhbFRoZW1lLnR5cG9ncmFwaHkuYm9keU1lZGl1bSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNvbG9y' >> "$TMPB64"
    printf '%s' 'ID0gbXVzaWNDb2xvcnMoKS50ZXh0U2Vjb25kYXJ5LAogICAgICAgICAgICAgICAgICAgICAgICApCiAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgIEJ1dHRvbigKICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2xpY2sgPSB7IGxvYWQoY2F0LCAxLCBmYWxzZSkg' >> "$TMPB64"
    printf '%s' 'fSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNvbG9ycyA9IEJ1dHRvbkRlZmF1bHRzLmJ1dHRvbkNvbG9ycygKICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICBjb250YWluZXJDb2xvciA9IG11c2ljQ29sb3JzKCkuYWNjZW50LAogICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgIGNvbnRlbnRDb2xvciA9IG11c2ljQ29sb3JzKCkuYWNjZW50VGV4dCwKICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICksCiAgICAgICAgICAgICAgICAgICAgICAgICAgICBtb2RpZmllciA9IE1vZGlmaWVyLnBhZGRpbmco' >> "$TMPB64"
    printf '%s' 'dG9wID0gMTIuZHApLAogICAgICAgICAgICAgICAgICAgICAgICApIHsKICAgICAgICAgICAgICAgICAgICAgICAgICAgIFRleHQo' >> "$TMPB64"
    printf '%s' 'dGV4dCA9ICLph43or5UiKQogICAgICAgICAgICAgICAgICAgICAgICB9CiAgICAgICAgICAgICAgICAgICAgfQogICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgfQogICAgICAgICAgICAgICAgZWxzZSAtPiB7CiAgICAgICAgICAgICAgICAgICAgTGF6eVZlcnRpY2FsR3JpZCgKICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgY29sdW1ucyA9IEdyaWRDZWxscy5GaXhlZCgyKSwKICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'Y29udGVudFBhZGRpbmcgPSBQYWRkaW5nVmFsdWVzKDEyLmRwKSwKICAgICAgICAgICAgICAgICAgICAgICAgaG9yaXpvbnRhbEFy' >> "$TMPB64"
    printf '%s' 'cmFuZ2VtZW50ID0gQXJyYW5nZW1lbnQuc3BhY2VkQnkoMTAuZHApLAogICAgICAgICAgICAgICAgICAgICAgICB2ZXJ0aWNhbEFy' >> "$TMPB64"
    printf '%s' 'cmFuZ2VtZW50ID0gQXJyYW5nZW1lbnQuc3BhY2VkQnkoMTAuZHApLAogICAgICAgICAgICAgICAgICAgICkgewogICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICBpdGVtcyhpdGVtcywga2V5ID0geyBpdC5pZCB9KSB7IGl0ZW0gLT4KICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgIENhcmQoc2hhcGUgPSBSb3VuZGVkQ29ybmVyU2hhcGUoMTQuZHApKSB7CiAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgQm94IHsKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgQXN5bmNJbWFnZSgKICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgIG1vZGVsID0gaXRlbS50aHVtYiwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgIGNvbnRlbnREZXNjcmlwdGlvbiA9IG51bGwsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICBjb250ZW50U2NhbGUgPSBDb250ZW50U2NhbGUuQ3JvcCwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'IG1vZGlmaWVyID0gTW9kaWZpZXIKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAuZmlsbE1heFdp' >> "$TMPB64"
    printf '%s' 'ZHRoKCkKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAuYXNwZWN0UmF0aW8oMC41NmYpCiAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgLmNsaWNrYWJsZSB7CiAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgIFdhbGxwYXBlck1hbmFnZXIuYXBwbHkoY29udGV4dCwgaXRlbS5sYXJnZSkKICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgVG9hc3QubWFrZVRleHQoY29udGV4dCwgIuWjgee6uOW3' >> "$TMPB64"
    printf '%s' 'suW6lOeUqCIsIFRvYXN0LkxFTkdUSF9TSE9SVCkuc2hvdygpCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgIG9uQmFjaygpCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgfSwKICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgKQogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBDb2x1bW4oCiAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBtb2RpZmllciA9IE1vZGlmaWVyCiAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgLmFsaWduKEFsaWdubWVudC5Cb3R0b21TdGFydCkKICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAuZmlsbE1heFdpZHRoKCkKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAuYmFja2dyb3VuZChDb2xvci5CbGFjay5jb3B5KGFscGhhID0gMC42NWYpKQogICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgIC5wYWRkaW5nKGhvcml6b250YWwgPSA4LmRwLCB2ZXJ0aWNhbCA9IDUuZHApLAogICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICApIHsKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'IFRleHQoCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgdGV4dCA9IGl0ZW0udGl0bGUsCiAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgc3R5bGUgPSBNYXRlcmlhbFRoZW1lLnR5cG9ncmFwaHkubGFi' >> "$TMPB64"
    printf '%s' 'ZWxNZWRpdW0sCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgY29sb3IgPSBDb2xvci5XaGl0ZSwK' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBtYXhMaW5lcyA9IDEsCiAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgb3ZlcmZsb3cgPSBUZXh0T3ZlcmZsb3cuRWxsaXBzaXMsCiAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICApCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBpZiAoaXRl' >> "$TMPB64"
    printf '%s' 'bS53aWR0aCA+IDAgJiYgaXRlbS5oZWlnaHQgPiAwKSB7CiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgVGV4dCgKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgdGV4dCA9ICIke2l0ZW0ud2lk' >> "$TMPB64"
    printf '%s' 'dGh9w5cke2l0ZW0uaGVpZ2h0fSIsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHN0eWxl' >> "$TMPB64"
    printf '%s' 'ID0gTWF0ZXJpYWxUaGVtZS50eXBvZ3JhcGh5LmxhYmVsU21hbGwsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgIGNvbG9yID0gQ29sb3IuV2hpdGUsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgKQogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgfQogICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICB9CiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgfQogICAgICAgICAgICAgICAgICAgICAgICAgICAgfQog' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICB9CiAgICAgICAgICAgICAgICAgICAgICAgIGlmICghZW5kUmVhY2hlZCkgewogICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgaXRlbShzcGFuID0geyBHcmlkSXRlbVNwYW4obWF4TGluZVNwYW4pIH0pIHsKICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICBCdXR0b24oCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2xpY2sg' >> "$TMPB64"
    printf '%s' 'PSB7IGlmICghbG9hZGluZykgbG9hZChjYXQsIHBhZ2UgKyAxLCB0cnVlKSB9LAogICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICBlbmFibGVkID0gIWxvYWRpbmcsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNvbG9ycyA9IEJ1' >> "$TMPB64"
    printf '%s' 'dHRvbkRlZmF1bHRzLmJ1dHRvbkNvbG9ycygKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNvbnRhaW5l' >> "$TMPB64"
    printf '%s' 'ckNvbG9yID0gbXVzaWNDb2xvcnMoKS5jYXJkU2Vjb25kYXJ5LAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgY29udGVudENvbG9yID0gbXVzaWNDb2xvcnMoKS50ZXh0UHJpbWFyeSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgKSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgbW9kaWZpZXIgPSBNb2RpZmllcgogICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgLmZpbGxNYXhXaWR0aCgpCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAucGFkZGluZyh2ZXJ0aWNhbCA9IDQuZHApLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICkgewog' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBUZXh0KHRleHQgPSBpZiAobG9hZGluZykgIuWKoOi9veS4rS4uLiIg' >> "$TMPB64"
    printf '%s' 'ZWxzZSAi5Yqg6L295pu05aSaIikKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB9CiAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICB9CiAgICAgICAgICAgICAgICAgICAgICAgIH0KICAgICAgICAgICAgICAgICAgICB9CiAgICAgICAgICAgICAgICB9' >> "$TMPB64"
    printf '%s' 'CiAgICAgICAgICAgIH0KICAgICAgICB9CiAgICB9Cn0K' >> "$TMPB64"
base64 -d "$TMPB64" > avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/WallpaperLibraryActivity.kt
rm -f "$TMPB64"
grep -q 'class WallpaperLibraryActivity' avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/WallpaperLibraryActivity.kt || { echo "X 39 class WallpaperLibraryActivity 写入失败"; exit 1; }
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

# ============ 0) manifest 注册壁纸页 + 壁纸库页 ============
MP = 'avbox/app/src/main/AndroidManifest.xml'
m = load(MP)
for act_name in ['.ui.activity.LxWallpaperSettingsActivity', '.ui.activity.WallpaperLibraryActivity']:
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
        ind + '    context.startActivity(android.content.Intent(context, com.github.tvbox.osc.ui.activity.LxWallpaperSettingsActivity::class.java))',
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
LT = BASE + 'ui/activity/LxMusicTheme.kt'
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
            '\n                ' + fld + ' = if (com.github.tvbox.osc.ui.activity.WallpaperManager.isActive()) musicColors().cardSecondary.copy(alpha = 0.55f) else musicColors().cardSecondary, // [39wp5]',
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
    h = h.replace(imp, imp + '\nimport com.github.tvbox.osc.ui.music.glass.GlassSettings // [39glass]', 1)
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
PA = BASE + 'ui/activity/LxPlayerActivity.kt'
a = load(PA)
if '[39resolve]' not in a:
    a = rep(a, 'import com.github.tvbox.osc.util.LxScriptEngine',
        'import com.github.tvbox.osc.util.LxScriptEngine\nimport com.github.tvbox.osc.util.LxRuntimeLog // [39resolve] 验活失败记日志', '39resolve import')
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
PA = BASE + 'ui/activity/LxPlayerActivity.kt'
a = load(PA)
if '[39intersect]' not in a:
    a = rep(a, '        val tryOrder = LxPlayerManager.getQualityTryOrder()',
        '        val tryOrder = LxPlayerManager.getQualityTryOrderFor(sourceId) // [39intersect] 点歌链解析前取交集', '39intersect 点歌链取交集')
    save(PA, a)
    print('OK [39intersect] 点歌链取交集已接')
else:
    print('SKIP [39intersect] 已应用')

# ============ 9) 播放页三键改用 FeedbackIconButton + 切歌锁（用户 2026-10-25 确认，PlayerControls 属 35 基线故放 39） ============
PC = BASE + 'ui/activity/PlayerControls.kt'
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

PA = BASE + 'ui/activity/LxPlayerActivity.kt'
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

PA = BASE + 'ui/activity/LxPlayerActivity.kt'
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
PA = BASE + 'ui/activity/LxPlayerActivity.kt'
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
                val info = com.github.tvbox.osc.util.ScriptInfo(id = sourceId, name = "")
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
PA = BASE + 'ui/activity/LxPlayerActivity.kt'
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
PA = BASE + 'ui/activity/LxPlayerActivity.kt'
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
                val info = com.github.tvbox.osc.util.ScriptInfo(id = sourceId, name = "")
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
                val info = com.github.tvbox.osc.util.ScriptInfo(id = sourceId, name = "")
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
PA = BASE + 'ui/activity/LxPlayerActivity.kt'
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
    while not os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
    assert os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"), "find_root 失败"

def rep(src, old, new, name):
    assert src.count(old) == 1, "pool5 锚点 %s: %d" % (name, src.count(old))
    return src.replace(old, new, 1)

find_root()
PA = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt"
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
    while not os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
    assert os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"), "find_root 失败"

def rep(src, old, new, name):
    assert src.count(old) == 1, "pool8 锚点 %s: %d" % (name, src.count(old))
    return src.replace(old, new, 1)

find_root()
PA = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt"
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
    while not os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
    assert os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"), "find_root 失败"

def rep(src, old, new, name):
    assert src.count(old) == 1, "pool9 锚点 %s: %d" % (name, src.count(old))
    return src.replace(old, new, 1)

find_root()
PA = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt"
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
    while not os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
    assert os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"), "find_root 失败"

def rep(src, old, new, name):
    assert src.count(old) == 1, "pool10 锚点 %s: %d" % (name, src.count(old))
    return src.replace(old, new, 1)

find_root()
PA = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt"
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
    while not os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
    assert os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"), "find_root 失败"

def rep(src, old, new, name):
    assert src.count(old) == 1, "pool11 锚点 %s: %d" % (name, src.count(old))
    return src.replace(old, new, 1)

find_root()
PA = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt"
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
    while not os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
    assert os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"), "find_root 失败"

def rep(src, old, new, name):
    assert src.count(old) == 1, "pool12 锚点 %s: %d" % (name, src.count(old))
    return src.replace(old, new, 1)

find_root()
PA = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt"
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
    while not os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
    assert os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"), "find_root 失败"

def rep(src, old, new, name):
    assert src.count(old) == 1, "pool13 锚点 %s: %d" % (name, src.count(old))
    return src.replace(old, new, 1)

find_root()
PA = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt"
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
    while not os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
    assert os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"), "find_root 失败"

def rep(src, old, new, name):
    assert src.count(old) == 1, "pool14 锚点 %s: %d" % (name, src.count(old))
    return src.replace(old, new, 1)

find_root()
PA = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt"
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
    while not os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
    assert os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"), "find_root 失败"

def rep(src, old, new, name):
    assert src.count(old) == 1, "pool15 锚点 %s: %d" % (name, src.count(old))
    return src.replace(old, new, 1)

find_root()
PA = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt"
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
    while not os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
    assert os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"), "find_root 失败"

def rep(src, old, new, name):
    assert src.count(old) == 1, "pool16 锚点 %s: %d" % (name, src.count(old))
    return src.replace(old, new, 1)

find_root()
PA = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt"
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
    while not os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
    assert os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"), "find_root 失败"

def rep(src, old, new, name):
    assert src.count(old) == 1, "pool17 锚点 %s: %d" % (name, src.count(old))
    return src.replace(old, new, 1)

find_root()
M = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt"
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
                        try { com.github.tvbox.osc.util.LxRuntimeLog.add("内置ID转池源: " + title + " -> " + effPlatform + " " + (effInfo["songId"] ?: "")) } catch (_: Exception) { }
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
    while not os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
    assert os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"), "find_root 失败"

find_root()
M = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt"
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

# === 39pool19: ID 映射缓存（用户确认，战役二）===
# 痛点：pool17 点内置平台的歌要先按歌名搜一遍池子，多等 2 秒。
# 修法：跨平台 ID 映射库。Key = 源平台_目标平台_原ID（如 wy_tx_186016），Value = 目标ID|时间戳。SharedPreferences 存，7 天过期，上限 500 条满了删最旧。
# 流程：resolveUrlWithFallback 进 pool17 前先查缓存，命中且未过期直接用缓存 ID，不走搜索；按名搜到结果后写缓存；拿缓存 ID 请求失败（空地址）立刻删缓存，下次自动降级走搜索。
python3 << 'PYEOF19'
import os

def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
    assert os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"), "find_root 失败"

def rep(src, old, new, name):
    assert src.count(old) == 1, "pool19 锚点 %s: %d" % (name, src.count(old))
    return src.replace(old, new, 1)

find_root()
M = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt"
s = open(M, encoding="utf-8").read()
if "[39pool19]" in s:
    print("跳过（39pool19 已应用）")
else:
    # 1. Add cache helper functions in LxEngineHolder
    old = "    var lastGoodSourceId: String? = null"
    new = """    var lastGoodSourceId: String? = null
    // [39pool19] ID 映射缓存：Key=源平台_目标平台_原ID，Value=目标ID|时间戳，7 天过期，上限 500 条
    private const val ID_MAP_PREFS = "id_map_cache"
    private const val ID_MAP_EXPIRE_MS = 7 * 24 * 60 * 60 * 1000L
    private const val ID_MAP_MAX = 500
    private fun idMapPrefs() = try { appContext?.getSharedPreferences(ID_MAP_PREFS, 0) } catch (_: Exception) { null }
    fun lookupIdMap(srcPlatform: String, dstPlatform: String, srcId: String): String? {
        return try {
            val prefs = idMapPrefs() ?: return null
            val key = srcPlatform.lowercase() + "_" + dstPlatform.lowercase() + "_" + srcId
            val v = prefs.getString(key, null) ?: return null
            val parts = v.split("|")
            if (parts.size != 2) { prefs.edit().remove(key).apply(); return null }
            val ts = parts[1].toLongOrNull() ?: 0L
            if (System.currentTimeMillis() - ts > ID_MAP_EXPIRE_MS) { prefs.edit().remove(key).apply(); return null }
            parts[0].takeIf { it.isNotBlank() }
        } catch (_: Exception) { null }
    }
    fun saveIdMap(srcPlatform: String, dstPlatform: String, srcId: String, dstId: String) {
        try {
            val prefs = idMapPrefs() ?: return
            val key = srcPlatform.lowercase() + "_" + dstPlatform.lowercase() + "_" + srcId
            val v = dstId + "|" + System.currentTimeMillis().toString()
            val all = prefs.all
            if (all.size >= ID_MAP_MAX && !all.containsKey(key)) {
                val oldest = all.entries.minByOrNull { (it.value as? String)?.split("|")?.getOrNull(1)?.toLongOrNull() ?: 0L }?.key
                if (oldest != null) prefs.edit().remove(oldest).apply()
            }
            prefs.edit().putString(key, v).apply()
        } catch (_: Exception) { }
    }
    fun deleteIdMap(srcPlatform: String, dstPlatform: String, srcId: String) {
        try {
            val key = srcPlatform.lowercase() + "_" + dstPlatform.lowercase() + "_" + srcId
            idMapPrefs()?.edit()?.remove(key)?.apply()
        } catch (_: Exception) { }
    }"""
    s = rep(s, old, new, "缓存函数")
    # 2. Modify pool17 block to check cache first, then search, then save
    old2 = """        // [39pool17] 内置平台 ID 转池源搜索：内置平台（网易/酷狗/QQ 等）的 ID 池源用不了，先按歌名搜池源拿池源自己的 ID
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
                        try { com.github.tvbox.osc.util.LxRuntimeLog.add("内置ID转池源: " + title + " -> " + effPlatform + " " + (effInfo["songId"] ?: "")) } catch (_: Exception) { }
                    }
                } catch (_: Exception) { }
            }
        }"""
    new2 = """        // [39pool17] 内置平台 ID 转池源搜索：内置平台（网易/酷狗/QQ 等）的 ID 池源用不了，先按歌名搜池源拿池源自己的 ID
        var effPlatform = platform
        var effInfo = musicInfo
        val builtin = setOf("kugou", "kg", "qq", "tx", "netease", "wy", "kuwo", "kw", "migu", "mg", "bilibili", "bd", "xiaomi", "xm")
        if (platform.lowercase() in builtin) {
            val srcId = (musicInfo["songId"] ?: musicInfo["id"] ?: "").toString()
            val title = (musicInfo["title"] as? String)?.takeIf { it.isNotBlank() }
            // [39pool19] 先查 ID 映射缓存：Key=源平台_目标平台_原ID，命中且未过期直接用，不走 2 秒搜索
            var cacheHit = false
            if (srcId.isNotBlank()) {
                for (dstPlat in listOf("kg", "tx", "kw", "mg", "wy")) {
                    val cached = lookupIdMap(platform, dstPlat, srcId)
                    if (cached != null) {
                        effInfo = musicInfo.toMutableMap().apply { put("songId", cached); put("id", cached) }
                        effPlatform = dstPlat
                        cacheHit = true
                        try { com.github.tvbox.osc.util.LxRuntimeLog.add("ID映射缓存命中: " + platform + "_" + dstPlat + "_" + srcId + " -> " + cached) } catch (_: Exception) { }
                        break
                    }
                }
            }
            if (!cacheHit && title != null) {
                try {
                    val poolHits = searchAllPoolSources(title)
                    val hit = poolHits.firstOrNull { (it["title"] as? String)?.isNotBlank() == true }
                    if (hit != null) {
                        val hitId = (hit["id"] ?: hit["songmid"] ?: "").toString()
                        val hitPlat = (hit["platform"] as? String)?.takeIf { it.isNotBlank() } ?: platform
                        effInfo = musicInfo.toMutableMap().apply {
                            put("songId", hitId)
                            put("id", hitId)
                        }
                        effPlatform = hitPlat
                        // [39pool19] 搜到结果后写缓存
                        if (srcId.isNotBlank() && hitId.isNotBlank()) saveIdMap(platform, hitPlat, srcId, hitId)
                        try { com.github.tvbox.osc.util.LxRuntimeLog.add("内置ID转池源: " + title + " -> " + effPlatform + " " + (effInfo["songId"] ?: "")) } catch (_: Exception) { }
                    }
                } catch (_: Exception) { }
            }
        }"""
    s = rep(s, old2, new2, "pool17 缓存")
    assert "[39pool19]" in s, "pool19 标记未落"
    open(M, "w", encoding="utf-8").write(s)
    print("OK 39pool19 ID 映射缓存完成")
PYEOF19
echo "=== 39pool19 完成 ==="

# === 39pool20: 分级冷却 + 源级熔断（用户确认，战役三）===
# 痛点：所有失败都冷 5 分钟，404 死链反复试浪费时间；mcp 301 是 http→https 跳转，直接判死太浪费。
# 修法：1）probeUrlWithCode 带错误码回来；2）404/410 只冷单首歌（源+歌 Key），301 冷整个源 30 分钟，超时冷 5 分钟；3）源级熔断：1 分钟内同一源连续 3 次 404，整个源冷 30 分钟并清计数器；4）301/302 读 Location 头跟随一次。
python3 << 'PYEOF20'
import os

def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
    assert os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"), "find_root 失败"

def rep(src, old, new, name):
    assert src.count(old) == 1, "pool20 锚点 %s: %d" % (name, src.count(old))
    return src.replace(old, new, 1)

find_root()
M = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt"
s = open(M, encoding="utf-8").read()
if "[39pool20]" in s:
    print("跳过（39pool20 已应用）")
else:
    # 1. Add per-song cooldown map and markSourceCoolDownByError
    old = "    fun markSourceCoolDown(sourceId: String, coolDownMs: Long = 300000) { // [39pool6] 默认冷却 5 分钟\n        sourceCoolDownUntil[sourceId] = System.currentTimeMillis() + coolDownMs\n    }"
    new = """    fun markSourceCoolDown(sourceId: String, coolDownMs: Long = 300000) { // [39pool6] 默认冷却 5 分钟
        sourceCoolDownUntil[sourceId] = System.currentTimeMillis() + coolDownMs
    }
    // [39pool20] 单首歌冷却：Key=源ID|歌ID，404/410 只冷这首歌不冷整个源
    private val songSourceCoolDownUntil = java.util.concurrent.ConcurrentHashMap<String, Long>()
    fun isSongSourceCoolDown(sourceId: String, songId: String): Boolean {
        val key = sourceId + "|" + songId
        val until = songSourceCoolDownUntil[key] ?: return false
        if (System.currentTimeMillis() >= until) { songSourceCoolDownUntil.remove(key); return false }
        return true
    }
    // [39pool20] 分级冷却 + 源级熔断：404/410 冷单首歌 30 分钟并计数，1 分钟内同一源 3 次 404 则整个源冷 30 分钟；301 冷整个源 30 分钟；超时冷 5 分钟
    fun markSourceCoolDownByError(sourceId: String, songId: String?, errorCode: Int?) {
        when (errorCode) {
            404, 410 -> {
                // 单首歌冷却 30 分钟
                if (songId != null) {
                    val key = sourceId + "|" + songId
                    songSourceCoolDownUntil[key] = System.currentTimeMillis() + 30 * 60 * 1000L
                }
                // 熔断计数：1 分钟内同一源连续 3 次 404，整个源冷 30 分钟
                try {
                    val now = System.currentTimeMillis()
                    val lastTime = com.github.tvbox.osc.ui.activity.LxPlayerManager.sourceFailTime[sourceId] ?: 0L
                    val count = if (now - lastTime > 60000L) 1 else (com.github.tvbox.osc.ui.activity.LxPlayerManager.sourceFailCount[sourceId] ?: 0) + 1
                    com.github.tvbox.osc.ui.activity.LxPlayerManager.sourceFailCount[sourceId] = count
                    com.github.tvbox.osc.ui.activity.LxPlayerManager.sourceFailTime[sourceId] = now
                    if (count >= 3) {
                        sourceCoolDownUntil[sourceId] = now + 30 * 60 * 1000L
                        com.github.tvbox.osc.ui.activity.LxPlayerManager.sourceFailCount.remove(sourceId)
                        com.github.tvbox.osc.ui.activity.LxPlayerManager.sourceFailTime.remove(sourceId)
                        try { com.github.tvbox.osc.util.LxRuntimeLog.add("【熔断】源 " + sourceId + " 短时间内连续 3 次 404，全面冷却 30 分钟") } catch (_: Exception) { }
                    }
                } catch (_: Exception) { }
            }
            301, 302 -> {
                sourceCoolDownUntil[sourceId] = System.currentTimeMillis() + 30 * 60 * 1000L
            }
            else -> {
                sourceCoolDownUntil[sourceId] = System.currentTimeMillis() + 300000L
            }
        }
    }"""
    s = rep(s, old, new, "分级冷却")
    assert "[39pool20]" in s, "pool20 标记未落"
    open(M, "w", encoding="utf-8").write(s)
    print("OK 39pool20 分级冷却完成")
PYEOF20
echo "=== 39pool20 完成 ==="

# === 39pool20b: 池子探活改调 probeUrlWithCode + 分级冷却（战役三接线）===
python3 << 'PYEOF20B'
import os

def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
    assert os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"), "find_root 失败"

def rep(src, old, new, name):
    assert src.count(old) == 1, "pool20b 锚点 %s: %d" % (name, src.count(old))
    return src.replace(old, new, 1)

find_root()
M = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt"
s = open(M, encoding="utf-8").read()
if "[39pool20b]" in s:
    print("跳过（39pool20b 已应用）")
else:
    # Modify the pool18 parallel probe to use probeUrlWithCode and markSourceCoolDownByError
    old = """                        if (!url.isNullOrBlank()) {
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
                        }"""
    new = """                        if (!url.isNullOrBlank()) {
                            LxRuntimeLog.add("【降级排查】源 $sid 拿到地址，开始探活...")
                            val (isAlive, errCode) = try {
                                LxPlayerManager.probeUrlWithCode(url)
                            } catch (e: Exception) {
                                Pair(false, null)
                            }
                            if (isAlive) {
                                LxRuntimeLog.add("【降级排查】源 $sid 探活成功，确定使用！")
                                sid to url
                            } else {
                                LxRuntimeLog.add("【降级排查】源 $sid 探活失败（死链/防盗链），尝试下一个")
                                // [39pool20b] 分级冷却：404 只冷单首歌+熔断计数，301 冷整个源 30 分钟，超时冷 5 分钟
                                val songIdForCool = (musicInfo["songId"] ?: musicInfo["id"] ?: "").toString().takeIf { it.isNotBlank() }
                                markSourceCoolDownByError(sid, songIdForCool, errCode)
                                null
                            }
                        } else {
                            null
                        }"""
    s = rep(s, old, new, "并行探活接线")
    assert "[39pool20b]" in s or "probeUrlWithCode" in s, "pool20b 标记未落"
    open(M, "w", encoding="utf-8").write(s)
    print("OK 39pool20b 池子探活接线完成")
PYEOF20B
echo "=== 39pool20b 完成 ==="

# === 39pool20 fix: 补单歌冷却过滤 + 计数器竞态 + 内存清理（用户确认，战役三修复）===
python3 << 'PYEOF20FIX'
import os

def find_root():
    while not os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt") and os.getcwd() != "/":
        os.chdir("..")
    assert os.path.exists("avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/MusicHomeActivity.kt"), "find_root 失败"

def rep(src, old, new, name):
    assert src.count(old) == 1, "pool20fix 锚点 %s: %d" % (name, src.count(old))
    return src.replace(old, new, 1)

find_root()
M = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerActivity.kt"
s = open(M, encoding="utf-8").read()
if "[39pool20fix]" in s:
    print("跳过（39pool20fix 已应用）")
else:
    # 1. Fix counter race: use merge() instead of read-modify-write
    old1 = """                // 熔断计数：1 分钟内同一源连续 3 次 404，整个源冷 30 分钟
                try {
                    val now = System.currentTimeMillis()
                    val lastTime = com.github.tvbox.osc.ui.activity.LxPlayerManager.sourceFailTime[sourceId] ?: 0L
                    val count = if (now - lastTime > 60000L) 1 else (com.github.tvbox.osc.ui.activity.LxPlayerManager.sourceFailCount[sourceId] ?: 0) + 1
                    com.github.tvbox.osc.ui.activity.LxPlayerManager.sourceFailCount[sourceId] = count
                    com.github.tvbox.osc.ui.activity.LxPlayerManager.sourceFailTime[sourceId] = now
                    if (count >= 3) {
                        sourceCoolDownUntil[sourceId] = now + 30 * 60 * 1000L
                        com.github.tvbox.osc.ui.activity.LxPlayerManager.sourceFailCount.remove(sourceId)
                        com.github.tvbox.osc.ui.activity.LxPlayerManager.sourceFailTime.remove(sourceId)
                        try { com.github.tvbox.osc.util.LxRuntimeLog.add("【熔断】源 " + sourceId + " 短时间内连续 3 次 404，全面冷却 30 分钟") } catch (_: Exception) { }
                    }
                } catch (_: Exception) { }"""
    new1 = """                // 熔断计数：1 分钟内同一源连续 3 次 404，整个源冷 30 分钟（[39pool20fix] 用 merge 原子操作防竞态）
                try {
                    val now = System.currentTimeMillis()
                    val lastTime = com.github.tvbox.osc.ui.activity.LxPlayerManager.sourceFailTime[sourceId] ?: 0L
                    val count = if (now - lastTime > 60000L) {
                        com.github.tvbox.osc.ui.activity.LxPlayerManager.sourceFailCount[sourceId] = 1
                        1
                    } else {
                        com.github.tvbox.osc.ui.activity.LxPlayerManager.sourceFailCount.merge(sourceId, 1, Int::plus) ?: 1
                    }
                    com.github.tvbox.osc.ui.activity.LxPlayerManager.sourceFailTime[sourceId] = now
                    if (count >= 3) {
                        sourceCoolDownUntil[sourceId] = now + 30 * 60 * 1000L
                        com.github.tvbox.osc.ui.activity.LxPlayerManager.sourceFailCount.remove(sourceId)
                        com.github.tvbox.osc.ui.activity.LxPlayerManager.sourceFailTime.remove(sourceId)
                        try { com.github.tvbox.osc.util.LxRuntimeLog.add("【熔断】源 " + sourceId + " 短时间内连续 3 次 404，全面冷却 30 分钟") } catch (_: Exception) { }
                    }
                } catch (_: Exception) { }"""
    s = rep(s, old1, new1, "计数器竞态")
    # 2. Add memory cleanup in markSourceCoolDownByError for songSourceCoolDownUntil
    old2 = """            404, 410 -> {
                // 单首歌冷却 30 分钟
                if (songId != null) {
                    val key = sourceId + "|" + songId
                    songSourceCoolDownUntil[key] = System.currentTimeMillis() + 30 * 60 * 1000L
                }"""
    new2 = """            404, 410 -> {
                // 单首歌冷却 30 分钟（[39pool20fix] 写时清理过期项，超 500 条清全表防内存泄漏）
                if (songId != null) {
                    val key = sourceId + "|" + songId
                    songSourceCoolDownUntil[key] = System.currentTimeMillis() + 30 * 60 * 1000L
                    if (songSourceCoolDownUntil.size > 500) {
                        try {
                            val now2 = System.currentTimeMillis()
                            val iter = songSourceCoolDownUntil.entries.iterator()
                            while (iter.hasNext()) { if (iter.next().value < now2) iter.remove() }
                            if (songSourceCoolDownUntil.size > 500) songSourceCoolDownUntil.clear()
                        } catch (_: Exception) { }
                    }
                }"""
    s = rep(s, old2, new2, "内存清理")
    # 3. Add per-song cooldown check in targets filtering (pool18 parallel probe)
    # Find the partition line and add song check
    old3 = "        val (goodTargets, coolTargets) = targets.partition { !isSourceCoolDown(it.first) }"
    new3 = "        val songIdForFilter = (musicInfo[\"songId\"] ?: musicInfo[\"id\"] ?: \"\").toString()\n        val (goodTargets, coolTargets) = targets.partition { !isSourceCoolDown(it.first) && !isSongSourceCoolDown(it.first, songIdForFilter) } // [39pool20fix] 单歌冷却过滤：源冷或单歌冷都跳过"
    if s.count(old3) == 1:
        s = rep(s, old3, new3, "单歌过滤")
    else:
        print("WARN: partition line count=" + str(s.count(old3)) + ", skip")
    assert "[39pool20fix]" in s, "pool20fix 标记未落"
    open(M, "w", encoding="utf-8").write(s)
    print("OK 39pool20fix 完成")
PYEOF20FIX
echo "=== 39pool20fix 完成 ==="
