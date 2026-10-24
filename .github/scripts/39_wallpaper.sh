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
    printf '%s' 'cG9ydCBhbmRyb2lkLmNvbnRlbnQuSW50ZW50CmltcG9ydCBhbmRyb2lkLm9zLkJ1bmRsZQppbXBvcnQgYW5kcm9pZHguYWN0aXZp' >> "$TMPB64"
    printf '%s' 'dHkuQ29tcG9uZW50QWN0aXZpdHkKaW1wb3J0IGFuZHJvaWR4LmFjdGl2aXR5LmNvbXBvc2UucmVtZW1iZXJMYXVuY2hlckZvckFj' >> "$TMPB64"
    printf '%s' 'dGl2aXR5UmVzdWx0CmltcG9ydCBhbmRyb2lkeC5hY3Rpdml0eS5jb21wb3NlLnNldENvbnRlbnQKaW1wb3J0IGFuZHJvaWR4LmFj' >> "$TMPB64"
    printf '%s' 'dGl2aXR5LnJlc3VsdC5jb250cmFjdC5BY3Rpdml0eVJlc3VsdENvbnRyYWN0cwppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5mb3Vu' >> "$TMPB64"
    printf '%s' 'ZGF0aW9uLmJhY2tncm91bmQKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UuZm91bmRhdGlvbi5ib3JkZXIKaW1wb3J0IGFuZHJvaWR4' >> "$TMPB64"
    printf '%s' 'LmNvbXBvc2UuZm91bmRhdGlvbi5jbGlja2FibGUKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UuZm91bmRhdGlvbi5sYXlvdXQuQXJy' >> "$TMPB64"
    printf '%s' 'YW5nZW1lbnQKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UuZm91bmRhdGlvbi5sYXlvdXQuQm94CmltcG9ydCBhbmRyb2lkeC5jb21w' >> "$TMPB64"
    printf '%s' 'b3NlLmZvdW5kYXRpb24ubGF5b3V0LkNvbHVtbgppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5mb3VuZGF0aW9uLmxheW91dC5QYWRk' >> "$TMPB64"
    printf '%s' 'aW5nVmFsdWVzCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLmZvdW5kYXRpb24ubGF5b3V0LlJvdwppbXBvcnQgYW5kcm9pZHguY29t' >> "$TMPB64"
    printf '%s' 'cG9zZS5mb3VuZGF0aW9uLmxheW91dC5TcGFjZXIKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UuZm91bmRhdGlvbi5sYXlvdXQuZmls' >> "$TMPB64"
    printf '%s' 'bE1heFNpemUKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UuZm91bmRhdGlvbi5sYXlvdXQuZmlsbE1heFdpZHRoCmltcG9ydCBhbmRy' >> "$TMPB64"
    printf '%s' 'b2lkeC5jb21wb3NlLmZvdW5kYXRpb24ubGF5b3V0LmhlaWdodAppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5mb3VuZGF0aW9uLmxh' >> "$TMPB64"
    printf '%s' 'eW91dC5wYWRkaW5nCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLmZvdW5kYXRpb24ubGF5b3V0LnNpemUKaW1wb3J0IGFuZHJvaWR4' >> "$TMPB64"
    printf '%s' 'LmNvbXBvc2UuZm91bmRhdGlvbi5sYXlvdXQud2lkdGgKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UuZm91bmRhdGlvbi5sYXp5Lkxh' >> "$TMPB64"
    printf '%s' 'enlDb2x1bW4KaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UuZm91bmRhdGlvbi5sYXp5LkxhenlSb3cKaW1wb3J0IGFuZHJvaWR4LmNv' >> "$TMPB64"
    printf '%s' 'bXBvc2UuZm91bmRhdGlvbi5sYXp5Lml0ZW1zCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLmZvdW5kYXRpb24uc2hhcGUuUm91bmRl' >> "$TMPB64"
    printf '%s' 'ZENvcm5lclNoYXBlCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLm1hdGVyaWFsMy5CdXR0b24KaW1wb3J0IGFuZHJvaWR4LmNvbXBv' >> "$TMPB64"
    printf '%s' 'c2UubWF0ZXJpYWwzLkJ1dHRvbkRlZmF1bHRzCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLm1hdGVyaWFsMy5DYXJkCmltcG9ydCBh' >> "$TMPB64"
    printf '%s' 'bmRyb2lkeC5jb21wb3NlLm1hdGVyaWFsMy5DYXJkRGVmYXVsdHMKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UubWF0ZXJpYWwzLk1h' >> "$TMPB64"
    printf '%s' 'dGVyaWFsVGhlbWUKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UubWF0ZXJpYWwzLk91dGxpbmVkQnV0dG9uCmltcG9ydCBhbmRyb2lk' >> "$TMPB64"
    printf '%s' 'eC5jb21wb3NlLm1hdGVyaWFsMy5PdXRsaW5lZFRleHRGaWVsZAppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5tYXRlcmlhbDMuT3V0' >> "$TMPB64"
    printf '%s' 'bGluZWRUZXh0RmllbGREZWZhdWx0cwppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5tYXRlcmlhbDMuU2xpZGVyCmltcG9ydCBhbmRy' >> "$TMPB64"
    printf '%s' 'b2lkeC5jb21wb3NlLm1hdGVyaWFsMy5TbGlkZXJEZWZhdWx0cwppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5tYXRlcmlhbDMuU3dp' >> "$TMPB64"
    printf '%s' 'dGNoCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLm1hdGVyaWFsMy5Td2l0Y2hEZWZhdWx0cwppbXBvcnQgYW5kcm9pZHguY29tcG9z' >> "$TMPB64"
    printf '%s' 'ZS5tYXRlcmlhbDMuVGV4dAppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5ydW50aW1lLkNvbXBvc2FibGUKaW1wb3J0IGFuZHJvaWR4' >> "$TMPB64"
    printf '%s' 'LmNvbXBvc2UucnVudGltZS5TaWRlRWZmZWN0CmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLnJ1bnRpbWUuY29sbGVjdEFzU3RhdGUK' >> "$TMPB64"
    printf '%s' 'aW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UucnVudGltZS5nZXRWYWx1ZQppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5ydW50aW1lLm11' >> "$TMPB64"
    printf '%s' 'dGFibGVTdGF0ZU9mCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLnJ1bnRpbWUucmVtZW1iZXIKaW1wb3J0IGFuZHJvaWR4LmNvbXBv' >> "$TMPB64"
    printf '%s' 'c2UucnVudGltZS5zZXRWYWx1ZQppbXBvcnQgYW5kcm9pZHguY29tcG9zZS51aS5BbGlnbm1lbnQKaW1wb3J0IGFuZHJvaWR4LmNv' >> "$TMPB64"
    printf '%s' 'bXBvc2UudWkuTW9kaWZpZXIKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UudWkuZHJhdy5jbGlwCmltcG9ydCBhbmRyb2lkeC5jb21w' >> "$TMPB64"
    printf '%s' 'b3NlLnVpLmdyYXBoaWNzLkJydXNoCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLnVpLmdyYXBoaWNzLkNvbG9yCmltcG9ydCBhbmRy' >> "$TMPB64"
    printf '%s' 'b2lkeC5jb21wb3NlLnVpLmxheW91dC5Db250ZW50U2NhbGUKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UudWkucGxhdGZvcm0uTG9j' >> "$TMPB64"
    printf '%s' 'YWxDb250ZXh0CmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLnVpLnRleHQuZm9udC5Gb250V2VpZ2h0CmltcG9ydCBhbmRyb2lkeC5j' >> "$TMPB64"
    printf '%s' 'b21wb3NlLnVpLnVuaXQuZHAKaW1wb3J0IGFuZHJvaWR4LmNvcmUudmlldy5XaW5kb3dDb21wYXQKaW1wb3J0IGNvaWwuY29tcG9z' >> "$TMPB64"
    printf '%s' 'ZS5Bc3luY0ltYWdlCmltcG9ydCBjb2lsLnJlcXVlc3QuSW1hZ2VSZXF1ZXN0CgovLyBbMzl3cDJdIOa4kOWPmOmihOiuvjog5ZCN' >> "$TMPB64"
    printf '%s' '56ewICsg6LW35q2iIEhleCjlhoXlrrnmlbDmja7mnKzouqssIOmdniBVSSDpk6zoibIpCnByaXZhdGUgdmFsIFdQX0dSQURJRU5U' >> "$TMPB64"
    printf '%s' 'X1BSRVNFVFMgPSBsaXN0T2YoCiAgICBUcmlwbGUoIua3sea1t+iTnSIsICIjMEYyMDI3IiwgIiMyQzUzNjQiKSwKICAgIFRyaXBs' >> "$TMPB64"
    printf '%s' 'ZSgi5pma6Zye57qiIiwgIiNGRjk5NjYiLCAiI0ZGNUU2MiIpLAogICAgVHJpcGxlKCLmnoHlhYnnu78iLCAiIzExOTk4RSIsICIj' >> "$TMPB64"
    printf '%s' 'MzhFRjdEIiksCikKCi8vIFszOXdwNF0g5paH5a2X6aKc6Imy5qih5byP6YCJ6aG5OiDlgLwgLT4g5pi+56S65ZCNCnByaXZhdGUg' >> "$TMPB64"
    printf '%s' 'dmFsIFdQX1RFWFRfTU9ERVMgPSBsaXN0T2YoCiAgICAiYXV0byIgdG8gIui3n+maj+S4u+mimCIsCiAgICAibGlnaHQiIHRvICLm' >> "$TMPB64"
    printf '%s' 'tYXoibLmloflrZciLAogICAgImRhcmsiIHRvICLmt7HoibLmloflrZciLAopCgpwcml2YXRlIGZ1biB3cFBhcnNlQ29sb3IoaGV4' >> "$TMPB64"
    printf '%s' 'OiBTdHJpbmcpOiBDb2xvciA9CiAgICB0cnkgeyBDb2xvcihhbmRyb2lkLmdyYXBoaWNzLkNvbG9yLnBhcnNlQ29sb3IoaGV4KSkg' >> "$TMPB64"
    printf '%s' 'fSBjYXRjaCAoZTogRXhjZXB0aW9uKSB7IENvbG9yLkdyYXkgfQoKLy8gWzM5d3AxXSDlo4Hnurjorr7nva7pobXvvJrlvIDlhbMg' >> "$TMPB64"
    printf '%s' 'KyBVUkwg6L6T5YWlICsg5pys5Zyw6YCJ5Zu+77yI5oyB5LmF5o6I5p2D77yJKyDljoblj7LmqKrmjpLjgILlj6rlhpkgV2FsbHBh' >> "$TMPB64"
    printf '%s' 'cGVyTWFuYWdlcuOAggpjbGFzcyBMeFdhbGxwYXBlclNldHRpbmdzQWN0aXZpdHkgOiBDb21wb25lbnRBY3Rpdml0eSgpIHsKICAg' >> "$TMPB64"
    printf '%s' 'IG92ZXJyaWRlIGZ1biBvbkNyZWF0ZShzYXZlZEluc3RhbmNlU3RhdGU6IEJ1bmRsZT8pIHsKICAgICAgICBzdXBlci5vbkNyZWF0' >> "$TMPB64"
    printf '%s' 'ZShzYXZlZEluc3RhbmNlU3RhdGUpCiAgICAgICAgdmFsIGFwcEN0eCA9IGFwcGxpY2F0aW9uQ29udGV4dAogICAgICAgIE11c2lj' >> "$TMPB64"
    printf '%s' 'VGhlbWVNYW5hZ2VyLmluaXQoYXBwQ3R4KQogICAgICAgIFdhbGxwYXBlck1hbmFnZXIuaW5pdChhcHBDdHgpCiAgICAgICAgc2V0' >> "$TMPB64"
    printf '%s' 'Q29udGVudCB7CiAgICAgICAgICAgIHZhbCBpc0RhcmsgYnkgTXVzaWNUaGVtZU1hbmFnZXIuaXNEYXJrVGhlbWUKICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgdmFsIHdpbmRvdyA9IHRoaXNATHhXYWxscGFwZXJTZXR0aW5nc0FjdGl2aXR5LndpbmRvdwogICAgICAgICAgICBTaWRlRWZm' >> "$TMPB64"
    printf '%s' 'ZWN0IHsKICAgICAgICAgICAgICAgIFdpbmRvd0NvbXBhdC5nZXRJbnNldHNDb250cm9sbGVyKHdpbmRvdywgd2luZG93LmRlY29y' >> "$TMPB64"
    printf '%s' 'VmlldykKICAgICAgICAgICAgICAgICAgICAuaXNBcHBlYXJhbmNlTGlnaHRTdGF0dXNCYXJzID0gIWlzRGFyawogICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICB9CiAgICAgICAgICAgIEx4TXVzaWNUaGVtZShpc0RhcmtUaGVtZSA9IGlzRGFyaykgewogICAgICAgICAgICAgICAgV2FsbHBh' >> "$TMPB64"
    printf '%s' 'cGVyU2V0dGluZ3NTY3JlZW4ob25CYWNrID0geyBmaW5pc2goKSB9KQogICAgICAgICAgICB9CiAgICAgICAgfQogICAgfQp9CgpA' >> "$TMPB64"
    printf '%s' 'Q29tcG9zYWJsZQpmdW4gV2FsbHBhcGVyU2V0dGluZ3NTY3JlZW4ob25CYWNrOiAoKSAtPiBVbml0KSB7CiAgICB2YWwgY29udGV4' >> "$TMPB64"
    printf '%s' 'dCA9IExvY2FsQ29udGV4dC5jdXJyZW50CiAgICB2YWwgd3BTdGF0ZSBieSBXYWxscGFwZXJNYW5hZ2VyLnN0YXRlLmNvbGxlY3RB' >> "$TMPB64"
    printf '%s' 'c1N0YXRlKCkKICAgIHZhciB1cmxUZXh0IGJ5IHJlbWVtYmVyIHsgbXV0YWJsZVN0YXRlT2Yod3BTdGF0ZS51cmwpIH0KICAgIHZh' >> "$TMPB64"
    printf '%s' 'bCBwaWNrZXIgPSByZW1lbWJlckxhdW5jaGVyRm9yQWN0aXZpdHlSZXN1bHQoQWN0aXZpdHlSZXN1bHRDb250cmFjdHMuT3BlbkRv' >> "$TMPB64"
    printf '%s' 'Y3VtZW50KCkpIHsgdXJpIC0+CiAgICAgICAgaWYgKHVyaSAhPSBudWxsKSB7CiAgICAgICAgICAgIHRyeSB7CiAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICBjb250ZXh0LmNvbnRlbnRSZXNvbHZlci50YWtlUGVyc2lzdGFibGVVcmlQZXJtaXNzaW9uKHVyaSwgSW50ZW50LkZMQUdf' >> "$TMPB64"
    printf '%s' 'R1JBTlRfUkVBRF9VUklfUEVSTUlTU0lPTikKICAgICAgICAgICAgfSBjYXRjaCAoZTogRXhjZXB0aW9uKSB7CiAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICBhbmRyb2lkLnV0aWwuTG9nLncoIldhbGxwYXBlciIsICLmnKzlnLDlm77mjIHkuYXmjojmnYPlpLHotKUiLCBlKQogICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICB9CiAgICAgICAgICAgIFdhbGxwYXBlck1hbmFnZXIuYXBwbHkoY29udGV4dCwgdXJpLnRvU3RyaW5nKCkpCiAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgIHVybFRleHQgPSB1cmkudG9TdHJpbmcoKQogICAgICAgIH0KICAgIH0KICAgIENvbHVtbigKICAgICAgICBtb2RpZmll' >> "$TMPB64"
    printf '%s' 'ciA9IE1vZGlmaWVyCiAgICAgICAgICAgIC5maWxsTWF4U2l6ZSgpCiAgICAgICAgICAgIC5iYWNrZ3JvdW5kKG11c2ljQ29sb3Jz' >> "$TMPB64"
    printf '%s' 'KCkuYmFja2dyb3VuZCkKICAgICkgewogICAgICAgIFJvdygKICAgICAgICAgICAgbW9kaWZpZXIgPSBNb2RpZmllcgogICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgLmZpbGxNYXhXaWR0aCgpCiAgICAgICAgICAgICAgICAucGFkZGluZyhzdGFydCA9IDguZHAsIGVuZCA9IDE2LmRw' >> "$TMPB64"
    printf '%s' 'LCB0b3AgPSA0OC5kcCwgYm90dG9tID0gOC5kcCksCiAgICAgICAgICAgIHZlcnRpY2FsQWxpZ25tZW50ID0gQWxpZ25tZW50LkNl' >> "$TMPB64"
    printf '%s' 'bnRlclZlcnRpY2FsbHksCiAgICAgICAgKSB7CiAgICAgICAgICAgIFRleHQoCiAgICAgICAgICAgICAgICB0ZXh0ID0gIuKAuSIs' >> "$TMPB64"
    printf '%s' 'CiAgICAgICAgICAgICAgICBzdHlsZSA9IE1hdGVyaWFsVGhlbWUudHlwb2dyYXBoeS5oZWFkbGluZU1lZGl1bSwKICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgIGNvbG9yID0gbXVzaWNDb2xvcnMoKS50ZXh0UHJpbWFyeSwKICAgICAgICAgICAgICAgIG1vZGlmaWVyID0gTW9kaWZp' >> "$TMPB64"
    printf '%s' 'ZXIKICAgICAgICAgICAgICAgICAgICAuY2xpY2thYmxlIHsgb25CYWNrKCkgfQogICAgICAgICAgICAgICAgICAgIC5wYWRkaW5n' >> "$TMPB64"
    printf '%s' 'KGhvcml6b250YWwgPSAxMi5kcCwgdmVydGljYWwgPSA0LmRwKSwKICAgICAgICAgICAgKQogICAgICAgICAgICBUZXh0KAogICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgdGV4dCA9ICLlo4Hnurjorr7nva4iLAogICAgICAgICAgICAgICAgc3R5bGUgPSBNYXRlcmlhbFRoZW1lLnR5' >> "$TMPB64"
    printf '%s' 'cG9ncmFwaHkudGl0bGVMYXJnZS5jb3B5KGZvbnRXZWlnaHQgPSBGb250V2VpZ2h0LkJvbGQpLAogICAgICAgICAgICAgICAgY29s' >> "$TMPB64"
    printf '%s' 'b3IgPSBtdXNpY0NvbG9ycygpLnRleHRQcmltYXJ5LAogICAgICAgICAgICApCiAgICAgICAgfQogICAgICAgIExhenlDb2x1bW4o' >> "$TMPB64"
    printf '%s' 'CiAgICAgICAgICAgIG1vZGlmaWVyID0gTW9kaWZpZXIuZmlsbE1heFNpemUoKSwKICAgICAgICAgICAgY29udGVudFBhZGRpbmcg' >> "$TMPB64"
    printf '%s' 'PSBQYWRkaW5nVmFsdWVzKDE2LmRwKSwKICAgICAgICAgICAgdmVydGljYWxBcnJhbmdlbWVudCA9IEFycmFuZ2VtZW50LnNwYWNl' >> "$TMPB64"
    printf '%s' 'ZEJ5KDE2LmRwKSwKICAgICAgICApIHsKICAgICAgICAgICAgaXRlbSB7CiAgICAgICAgICAgICAgICBDYXJkKAogICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgIGNvbG9ycyA9IENhcmREZWZhdWx0cy5jYXJkQ29sb3JzKGNvbnRhaW5lckNvbG9yID0gbXVzaWNDb2xvcnMoKS5j' >> "$TMPB64"
    printf '%s' 'YXJkKSwKICAgICAgICAgICAgICAgICAgICBzaGFwZSA9IFJvdW5kZWRDb3JuZXJTaGFwZSgxNi5kcCksCiAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICApIHsKICAgICAgICAgICAgICAgICAgICBSb3coCiAgICAgICAgICAgICAgICAgICAgICAgIG1vZGlmaWVyID0gTW9kaWZpZXIK' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgIC5maWxsTWF4V2lkdGgoKQogICAgICAgICAgICAgICAgICAgICAgICAgICAgLnBh' >> "$TMPB64"
    printf '%s' 'ZGRpbmcoMTYuZHApLAogICAgICAgICAgICAgICAgICAgICAgICB2ZXJ0aWNhbEFsaWdubWVudCA9IEFsaWdubWVudC5DZW50ZXJW' >> "$TMPB64"
    printf '%s' 'ZXJ0aWNhbGx5LAogICAgICAgICAgICAgICAgICAgICkgewogICAgICAgICAgICAgICAgICAgICAgICBDb2x1bW4obW9kaWZpZXIg' >> "$TMPB64"
    printf '%s' 'PSBNb2RpZmllci53ZWlnaHQoMWYpKSB7CiAgICAgICAgICAgICAgICAgICAgICAgICAgICBUZXh0KCLlkK/nlKjlo4Hnurjog4zm' >> "$TMPB64"
    printf '%s' 'ma8iLCBzdHlsZSA9IE1hdGVyaWFsVGhlbWUudHlwb2dyYXBoeS5ib2R5TGFyZ2UsIGNvbG9yID0gbXVzaWNDb2xvcnMoKS50ZXh0' >> "$TMPB64"
    printf '%s' 'UHJpbWFyeSkKICAgICAgICAgICAgICAgICAgICAgICAgICAgIFNwYWNlcihtb2RpZmllciA9IE1vZGlmaWVyLmhlaWdodCgyLmRw' >> "$TMPB64"
    printf '%s' 'KSkKICAgICAgICAgICAgICAgICAgICAgICAgICAgIFRleHQoIumfs+S5kOS4k+WMuuW6leWxguiDjOaZr+Wbvu+8iOW4puWPr+iv' >> "$TMPB64"
    printf '%s' 'u+aAp+mBrue9qe+8iSIsIHN0eWxlID0gTWF0ZXJpYWxUaGVtZS50eXBvZ3JhcGh5LmJvZHlTbWFsbCwgY29sb3IgPSBtdXNpY0Nv' >> "$TMPB64"
    printf '%s' 'bG9ycygpLnRleHRTZWNvbmRhcnkpCiAgICAgICAgICAgICAgICAgICAgICAgIH0KICAgICAgICAgICAgICAgICAgICAgICAgU3dp' >> "$TMPB64"
    printf '%s' 'dGNoKAogICAgICAgICAgICAgICAgICAgICAgICAgICAgY2hlY2tlZCA9IHdwU3RhdGUuZW5hYmxlZCwKICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgIG9uQ2hlY2tlZENoYW5nZSA9IHsgV2FsbHBhcGVyTWFuYWdlci5zZXRFbmFibGVkKGNvbnRleHQsIGl0KSB9' >> "$TMPB64"
    printf '%s' 'LAogICAgICAgICAgICAgICAgICAgICAgICAgICAgY29sb3JzID0gU3dpdGNoRGVmYXVsdHMuY29sb3JzKAogICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgIGNoZWNrZWRUaHVtYkNvbG9yID0gQ29sb3IuV2hpdGUsCiAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgY2hlY2tlZFRyYWNrQ29sb3IgPSBtdXNpY0NvbG9ycygpLmFjY2VudCwKICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICB1bmNoZWNrZWRUaHVtYkNvbG9yID0gQ29sb3IuV2hpdGUsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'dW5jaGVja2VkVHJhY2tDb2xvciA9IG11c2ljQ29sb3JzKCkuY2FyZFNlY29uZGFyeSwKICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICksCiAgICAgICAgICAgICAgICAgICAgICAgICkKICAgICAgICAgICAgICAgICAgICB9CiAgICAgICAgICAgICAgICB9CiAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgIH0KICAgICAgICAgICAgaXRlbSB7CiAgICAgICAgICAgICAgICBDYXJkKAogICAgICAgICAgICAgICAgICAgIGNv' >> "$TMPB64"
    printf '%s' 'bG9ycyA9IENhcmREZWZhdWx0cy5jYXJkQ29sb3JzKGNvbnRhaW5lckNvbG9yID0gbXVzaWNDb2xvcnMoKS5jYXJkKSwKICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICBzaGFwZSA9IFJvdW5kZWRDb3JuZXJTaGFwZSgxNi5kcCksCiAgICAgICAgICAgICAgICApIHsKICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICBDb2x1bW4obW9kaWZpZXIgPSBNb2RpZmllci5wYWRkaW5nKDE2LmRwKSkgewogICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICBUZXh0KCLnvZHnu5zlo4HnurgiLCBzdHlsZSA9IE1hdGVyaWFsVGhlbWUudHlwb2dyYXBoeS5ib2R5TGFyZ2UsIGNv' >> "$TMPB64"
    printf '%s' 'bG9yID0gbXVzaWNDb2xvcnMoKS50ZXh0UHJpbWFyeSkKICAgICAgICAgICAgICAgICAgICAgICAgU3BhY2VyKG1vZGlmaWVyID0g' >> "$TMPB64"
    printf '%s' 'TW9kaWZpZXIuaGVpZ2h0KDEwLmRwKSkKICAgICAgICAgICAgICAgICAgICAgICAgT3V0bGluZWRUZXh0RmllbGQoCiAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICB2YWx1ZSA9IHVybFRleHQsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICBvblZhbHVlQ2hh' >> "$TMPB64"
    printf '%s' 'bmdlID0geyB1cmxUZXh0ID0gaXQgfSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgIGxhYmVsID0geyBUZXh0KCLlm77niYcg' >> "$TMPB64"
    printf '%s' 'VVJM77yIaHR0cC9odHRwc++8iSIpIH0sCiAgICAgICAgICAgICAgICAgICAgICAgICAgICBzaW5nbGVMaW5lID0gdHJ1ZSwKICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgIG1vZGlmaWVyID0gTW9kaWZpZXIuZmlsbE1heFdpZHRoKCksCiAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICBjb2xvcnMgPSBPdXRsaW5lZFRleHRGaWVsZERlZmF1bHRzLmNvbG9ycygKICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICBmb2N1c2VkQm9yZGVyQ29sb3IgPSBtdXNpY0NvbG9ycygpLmFjY2VudCwKICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICB1bmZvY3VzZWRCb3JkZXJDb2xvciA9IG11c2ljQ29sb3JzKCkuZGl2aWRlciwKICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICBjdXJzb3JDb2xvciA9IG11c2ljQ29sb3JzKCkuYWNjZW50LAogICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgIGZvY3VzZWRMYWJlbENvbG9yID0gbXVzaWNDb2xvcnMoKS5hY2NlbnQsCiAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgdW5mb2N1c2VkTGFiZWxDb2xvciA9IG11c2ljQ29sb3JzKCkudGV4dFNlY29uZGFyeSwKICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICBmb2N1c2VkVGV4dENvbG9yID0gbXVzaWNDb2xvcnMoKS50ZXh0UHJpbWFyeSwKICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICB1bmZvY3VzZWRUZXh0Q29sb3IgPSBtdXNpY0NvbG9ycygpLnRleHRQcmltYXJ5LAogICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgKSwKICAgICAgICAgICAgICAgICAgICAgICAgKQogICAgICAgICAgICAgICAgICAgICAgICBT' >> "$TMPB64"
    printf '%s' 'cGFjZXIobW9kaWZpZXIgPSBNb2RpZmllci5oZWlnaHQoMTIuZHApKQogICAgICAgICAgICAgICAgICAgICAgICBSb3cgewogICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgQnV0dG9uKAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2xpY2sgPSB7' >> "$TMPB64"
    printf '%s' 'IFdhbGxwYXBlck1hbmFnZXIuYXBwbHkoY29udGV4dCwgdXJsVGV4dCkgfSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICBjb2xvcnMgPSBCdXR0b25EZWZhdWx0cy5idXR0b25Db2xvcnMoCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'IGNvbnRhaW5lckNvbG9yID0gbXVzaWNDb2xvcnMoKS5hY2NlbnQsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'IGNvbnRlbnRDb2xvciA9IG11c2ljQ29sb3JzKCkuYWNjZW50VGV4dCwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAp' >> "$TMPB64"
    printf '%s' 'LAogICAgICAgICAgICAgICAgICAgICAgICAgICAgKSB7IFRleHQoIuW6lOeUqOatpCBVUkwiKSB9CiAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICBTcGFjZXIobW9kaWZpZXIgPSBNb2RpZmllci53aWR0aCgxMC5kcCkpCiAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICBPdXRsaW5lZEJ1dHRvbihvbkNsaWNrID0geyBwaWNrZXIubGF1bmNoKGFycmF5T2YoImltYWdlLyoiKSkgfSkgewogICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgIFRleHQoIuacrOWcsOmAieWbviIsIGNvbG9yID0gbXVzaWNDb2xvcnMoKS50ZXh0' >> "$TMPB64"
    printf '%s' 'UHJpbWFyeSkKICAgICAgICAgICAgICAgICAgICAgICAgICAgIH0KICAgICAgICAgICAgICAgICAgICAgICAgfQogICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgIH0KICAgICAgICAgICAgICAgIH0KICAgICAgICAgICAgfQogICAgICAgICAgICBpdGVtIHsKICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgIENhcmQoCiAgICAgICAgICAgICAgICAgICAgY29sb3JzID0gQ2FyZERlZmF1bHRzLmNhcmRDb2xvcnMoY29udGFpbmVyQ29s' >> "$TMPB64"
    printf '%s' 'b3IgPSBtdXNpY0NvbG9ycygpLmNhcmQpLAogICAgICAgICAgICAgICAgICAgIHNoYXBlID0gUm91bmRlZENvcm5lclNoYXBlKDE2' >> "$TMPB64"
    printf '%s' 'LmRwKSwKICAgICAgICAgICAgICAgICAgICBtb2RpZmllciA9IE1vZGlmaWVyCiAgICAgICAgICAgICAgICAgICAgICAgIC5maWxs' >> "$TMPB64"
    printf '%s' 'TWF4V2lkdGgoKQogICAgICAgICAgICAgICAgICAgICAgICAuY2xpY2thYmxlIHsKICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'IGNvbnRleHQuc3RhcnRBY3Rpdml0eShJbnRlbnQoY29udGV4dCwgV2FsbHBhcGVyTGlicmFyeUFjdGl2aXR5OjpjbGFzcy5qYXZh' >> "$TMPB64"
    printf '%s' 'KSkKICAgICAgICAgICAgICAgICAgICAgICAgfSwKICAgICAgICAgICAgICAgICkgewogICAgICAgICAgICAgICAgICAgIFJvdygK' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgbW9kaWZpZXIgPSBNb2RpZmllcgogICAgICAgICAgICAgICAgICAgICAgICAgICAgLmZp' >> "$TMPB64"
    printf '%s' 'bGxNYXhXaWR0aCgpCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAucGFkZGluZygxNi5kcCksCiAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgIHZlcnRpY2FsQWxpZ25tZW50ID0gQWxpZ25tZW50LkNlbnRlclZlcnRpY2FsbHksCiAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'KSB7CiAgICAgICAgICAgICAgICAgICAgICAgIENvbHVtbihtb2RpZmllciA9IE1vZGlmaWVyLndlaWdodCgxZikpIHsKICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgIFRleHQoIuWcqOe6v+Wjgee6uOW6kyIsIHN0eWxlID0gTWF0ZXJpYWxUaGVtZS50eXBvZ3Jh' >> "$TMPB64"
    printf '%s' 'cGh5LmJvZHlMYXJnZSwgY29sb3IgPSBtdXNpY0NvbG9ycygpLnRleHRQcmltYXJ5KQogICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgU3BhY2VyKG1vZGlmaWVyID0gTW9kaWZpZXIuaGVpZ2h0KDIuZHApKQogICAgICAgICAgICAgICAgICAgICAgICAgICAgVGV4' >> "$TMPB64"
    printf '%s' 'dCgi57K+6YCJ572R57uc5aOB57q477yM54K55Ye75Y2z5bqU55SoIiwgc3R5bGUgPSBNYXRlcmlhbFRoZW1lLnR5cG9ncmFwaHku' >> "$TMPB64"
    printf '%s' 'Ym9keVNtYWxsLCBjb2xvciA9IG11c2ljQ29sb3JzKCkudGV4dFNlY29uZGFyeSkKICAgICAgICAgICAgICAgICAgICAgICAgfQog' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICBUZXh0KCLigLoiLCBzdHlsZSA9IE1hdGVyaWFsVGhlbWUudHlwb2dyYXBoeS5oZWFkbGlu' >> "$TMPB64"
    printf '%s' 'ZU1lZGl1bSwgY29sb3IgPSBtdXNpY0NvbG9ycygpLnRleHRTZWNvbmRhcnkpCiAgICAgICAgICAgICAgICAgICAgfQogICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgfQogICAgICAgICAgICB9CiAgICAgICAgICAgIGl0ZW0gewogICAgICAgICAgICAgICAgQ2FyZCgKICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICBjb2xvcnMgPSBDYXJkRGVmYXVsdHMuY2FyZENvbG9ycyhjb250YWluZXJDb2xvciA9IG11c2ljQ29sb3JzKCku' >> "$TMPB64"
    printf '%s' 'Y2FyZCksCiAgICAgICAgICAgICAgICAgICAgc2hhcGUgPSBSb3VuZGVkQ29ybmVyU2hhcGUoMTYuZHApLAogICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgKSB7CiAgICAgICAgICAgICAgICAgICAgQ29sdW1uKG1vZGlmaWVyID0gTW9kaWZpZXIucGFkZGluZygxNi5kcCkpIHsKICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgVGV4dCgi5riQ5Y+Y6IOM5pmvIiwgc3R5bGUgPSBNYXRlcmlhbFRoZW1lLnR5cG9ncmFwaHku' >> "$TMPB64"
    printf '%s' 'Ym9keUxhcmdlLCBjb2xvciA9IG11c2ljQ29sb3JzKCkudGV4dFByaW1hcnkpCiAgICAgICAgICAgICAgICAgICAgICAgIFNwYWNl' >> "$TMPB64"
    printf '%s' 'cihtb2RpZmllciA9IE1vZGlmaWVyLmhlaWdodCgyLmRwKSkKICAgICAgICAgICAgICAgICAgICAgICAgVGV4dCgi5LiN55So5Zu+' >> "$TMPB64"
    printf '%s' '54mH77yM5LiA5bGC5riQ5Y+Y5L2c5bqV77yI5ZCM5qC35bim5Y+v6K+75oCn6YGu572p77yJIiwgc3R5bGUgPSBNYXRlcmlhbFRo' >> "$TMPB64"
    printf '%s' 'ZW1lLnR5cG9ncmFwaHkuYm9keVNtYWxsLCBjb2xvciA9IG11c2ljQ29sb3JzKCkudGV4dFNlY29uZGFyeSkKICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgU3BhY2VyKG1vZGlmaWVyID0gTW9kaWZpZXIuaGVpZ2h0KDEyLmRwKSkKICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgUm93KGhvcml6b250YWxBcnJhbmdlbWVudCA9IEFycmFuZ2VtZW50LnNwYWNlZEJ5KDE0LmRwKSkgewogICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgV1BfR1JBRElFTlRfUFJFU0VUUy5mb3JFYWNoIHsgKG5hbWUsIGgxLCBoMikgLT4KICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICB2YWwgcGFpciA9ICIkaDEsJGgyIgogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZh' >> "$TMPB64"
    printf '%s' 'bCBpc0N1cnJlbnQgPSB3cFN0YXRlLm1vZGUgPT0gImdyYWRpZW50IiAmJiB3cFN0YXRlLmdyYWRpZW50ID09IHBhaXIKICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICBDb2x1bW4oaG9yaXpvbnRhbEFsaWdubWVudCA9IEFsaWdubWVudC5DZW50ZXJIb3Jp' >> "$TMPB64"
    printf '%s' 'em9udGFsbHkpIHsKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgQm94KAogICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgbW9kaWZpZXIgPSBNb2RpZmllcgogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgIC5zaXplKDY0LmRwKQogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIC5jbGlwKFJvdW5k' >> "$TMPB64"
    printf '%s' 'ZWRDb3JuZXJTaGFwZSgxNC5kcCkpCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgLmJhY2tncm91' >> "$TMPB64"
    printf '%s' 'bmQoQnJ1c2gubGluZWFyR3JhZGllbnQobGlzdE9mKHdwUGFyc2VDb2xvcihoMSksIHdwUGFyc2VDb2xvcihoMikpKSkKICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAudGhlbigKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgaWYgKGlzQ3VycmVudCkgTW9kaWZpZXIuYm9yZGVyKDIuZHAsIG11c2ljQ29sb3JzKCkuYWNjZW50' >> "$TMPB64"
    printf '%s' 'LCBSb3VuZGVkQ29ybmVyU2hhcGUoMTQuZHApKQogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICBlbHNlIE1vZGlmaWVyCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgKQogICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIC5jbGlja2FibGUgewogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICBXYWxscGFwZXJNYW5hZ2VyLmFwcGx5R3JhZGllbnQoY29udGV4dCwgcGFpcikKICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgYW5kcm9pZC53aWRnZXQuVG9hc3QubWFrZVRleHQoY29udGV4dCwg' >> "$TMPB64"
    printf '%s' 'Iua4kOWPmOW3suW6lOeUqCIsIGFuZHJvaWQud2lkZ2V0LlRvYXN0LkxFTkdUSF9TSE9SVCkuc2hvdygpCiAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgfSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgKQogICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBTcGFjZXIobW9kaWZpZXIgPSBNb2RpZmllci5oZWlnaHQoNi5kcCkpCiAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIFRleHQobmFtZSwgc3R5bGUgPSBNYXRlcmlhbFRoZW1lLnR5cG9ncmFw' >> "$TMPB64"
    printf '%s' 'aHkuYm9keVNtYWxsLCBjb2xvciA9IG11c2ljQ29sb3JzKCkudGV4dFByaW1hcnkpCiAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgfQogICAgICAgICAgICAgICAgICAgICAgICAgICAgfQogICAgICAgICAgICAgICAgICAgICAgICB9CiAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgfQogICAgICAgICAgICAgICAgfQogICAgICAgICAgICB9CiAgICAgICAgICAgIGl0ZW0gewogICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgLy8gWzM5d3A0XSDmlYjmnpzosIPmlbQ6IOaWh+Wtl+minOiJsuaooeW8jyArIOmBrue9qea1k+W6pgogICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgLy8gWzM5d3A1XSDpga7nvanlr7npvZAgUGVlayBkYXJrT3ZlcmxheTog57qv6buRLCDpu5jorqQgMCDml6DnurEsIOaYvuek' >> "$TMPB64"
    printf '%s' 'uuecn+WunuWAvAogICAgICAgICAgICAgICAgdmFsIGVmZlNjcmltID0gd3BTdGF0ZS5zY3JpbS5jb2VyY2VBdExlYXN0KDApCiAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICB2YXIgc2NyaW1TbGlkZXIgYnkgcmVtZW1iZXIod3BTdGF0ZS5zY3JpbSkgeyBtdXRhYmxlU3RhdGVPZihl' >> "$TMPB64"
    printf '%s' 'ZmZTY3JpbS50b0Zsb2F0KCkpIH0KICAgICAgICAgICAgICAgIHZhciBvcGFjaXR5U2xpZGVyIGJ5IHJlbWVtYmVyKHdwU3RhdGUu' >> "$TMPB64"
    printf '%s' 'b3BhY2l0eSkgeyBtdXRhYmxlU3RhdGVPZih3cFN0YXRlLm9wYWNpdHkudG9GbG9hdCgpKSB9CiAgICAgICAgICAgICAgICB2YXIg' >> "$TMPB64"
    printf '%s' 'Ymx1clNsaWRlciBieSByZW1lbWJlcih3cFN0YXRlLmJsdXIpIHsgbXV0YWJsZVN0YXRlT2Yod3BTdGF0ZS5ibHVyLnRvRmxvYXQo' >> "$TMPB64"
    printf '%s' 'KSkgfQogICAgICAgICAgICAgICAgQ2FyZCgKICAgICAgICAgICAgICAgICAgICBjb2xvcnMgPSBDYXJkRGVmYXVsdHMuY2FyZENv' >> "$TMPB64"
    printf '%s' 'bG9ycyhjb250YWluZXJDb2xvciA9IG11c2ljQ29sb3JzKCkuY2FyZCksCiAgICAgICAgICAgICAgICAgICAgc2hhcGUgPSBSb3Vu' >> "$TMPB64"
    printf '%s' 'ZGVkQ29ybmVyU2hhcGUoMTYuZHApLAogICAgICAgICAgICAgICAgKSB7CiAgICAgICAgICAgICAgICAgICAgQ29sdW1uKG1vZGlm' >> "$TMPB64"
    printf '%s' 'aWVyID0gTW9kaWZpZXIucGFkZGluZygxNi5kcCkpIHsKICAgICAgICAgICAgICAgICAgICAgICAgVGV4dCgi5pWI5p6c6LCD5pW0' >> "$TMPB64"
    printf '%s' 'Iiwgc3R5bGUgPSBNYXRlcmlhbFRoZW1lLnR5cG9ncmFwaHkuYm9keUxhcmdlLCBjb2xvciA9IG11c2ljQ29sb3JzKCkudGV4dFBy' >> "$TMPB64"
    printf '%s' 'aW1hcnkpCiAgICAgICAgICAgICAgICAgICAgICAgIFNwYWNlcihtb2RpZmllciA9IE1vZGlmaWVyLmhlaWdodCgxMi5kcCkpCiAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgIFRleHQoIuaWh+Wtl+minOiJsuaooeW8jyIsIHN0eWxlID0gTWF0ZXJpYWxUaGVtZS50eXBv' >> "$TMPB64"
    printf '%s' 'Z3JhcGh5LmJvZHlNZWRpdW0sIGNvbG9yID0gbXVzaWNDb2xvcnMoKS50ZXh0U2Vjb25kYXJ5KQogICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICBTcGFjZXIobW9kaWZpZXIgPSBNb2RpZmllci5oZWlnaHQoOC5kcCkpCiAgICAgICAgICAgICAgICAgICAgICAgIFJvdyho' >> "$TMPB64"
    printf '%s' 'b3Jpem9udGFsQXJyYW5nZW1lbnQgPSBBcnJhbmdlbWVudC5zcGFjZWRCeSgxMC5kcCkpIHsKICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgIFdQX1RFWFRfTU9ERVMuZm9yRWFjaCB7ICh2YWx1ZSwgbGFiZWwpIC0+CiAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgdmFsIHNlbGVjdGVkID0gd3BTdGF0ZS50ZXh0TW9kZSA9PSB2YWx1ZQogICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgIEJveCgKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgbW9kaWZpZXIgPSBNb2RpZmllcgogICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgLmNsaXAoUm91bmRlZENvcm5lclNoYXBlKDUwKSkKICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgIC5iYWNrZ3JvdW5kKGlmIChzZWxlY3RlZCkgbXVzaWNDb2xvcnMoKS5hY2NlbnQgZWxz' >> "$TMPB64"
    printf '%s' 'ZSBtdXNpY0NvbG9ycygpLmNhcmRTZWNvbmRhcnkpCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAuY2xp' >> "$TMPB64"
    printf '%s' 'Y2thYmxlIHsgV2FsbHBhcGVyTWFuYWdlci5zZXRUZXh0TW9kZShjb250ZXh0LCB2YWx1ZSkgfQogICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgLnBhZGRpbmcoaG9yaXpvbnRhbCA9IDE2LmRwLCB2ZXJ0aWNhbCA9IDguZHApLAogICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICkgewogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBUZXh0KAogICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgdGV4dCA9IGxhYmVsLAogICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgc3R5bGUgPSBNYXRlcmlhbFRoZW1lLnR5cG9ncmFwaHkuYm9keU1lZGl1bSwKICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgIGNvbG9yID0gaWYgKHNlbGVjdGVkKSBtdXNpY0NvbG9ycygpLmFjY2VudFRleHQgZWxz' >> "$TMPB64"
    printf '%s' 'ZSBtdXNpY0NvbG9ycygpLnRleHRTZWNvbmRhcnksCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICkKICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICB9CiAgICAgICAgICAgICAgICAgICAgICAgICAgICB9CiAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgIH0KICAgICAgICAgICAgICAgICAgICAgICAgU3BhY2VyKG1vZGlmaWVyID0gTW9kaWZpZXIuaGVpZ2h0KDQuZHApKQog' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICBUZXh0KAogICAgICAgICAgICAgICAgICAgICAgICAgICAgdGV4dCA9ICLlo4HnurjlgY/m' >> "$TMPB64"
    printf '%s' 't7HpgInmtYXoibLmloflrZfvvIzlgY/mtYXpgInmt7HoibLmloflrZfvvIzlnKjlo4HnurjkuIrmiY3nnIvlvpfmuIXvvJvot5/p' >> "$TMPB64"
    printf '%s' 'mo/kuLvpopjliJnnlKjkuLvpopjmt7HmtYXjgIIiLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgc3R5bGUgPSBNYXRlcmlh' >> "$TMPB64"
    printf '%s' 'bFRoZW1lLnR5cG9ncmFwaHkuYm9keVNtYWxsLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgY29sb3IgPSBtdXNpY0NvbG9y' >> "$TMPB64"
    printf '%s' 'cygpLnRleHRTZWNvbmRhcnksCiAgICAgICAgICAgICAgICAgICAgICAgICkKICAgICAgICAgICAgICAgICAgICAgICAgU3BhY2Vy' >> "$TMPB64"
    printf '%s' 'KG1vZGlmaWVyID0gTW9kaWZpZXIuaGVpZ2h0KDE2LmRwKSkKICAgICAgICAgICAgICAgICAgICAgICAgUm93KAogICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgbW9kaWZpZXIgPSBNb2RpZmllci5maWxsTWF4V2lkdGgoKSwKICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgIHZlcnRpY2FsQWxpZ25tZW50ID0gQWxpZ25tZW50LkNlbnRlclZlcnRpY2FsbHksCiAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICkgewogICAgICAgICAgICAgICAgICAgICAgICAgICAgVGV4dCgi6YGu572p5rWT5bqmIiwgc3R5bGUgPSBNYXRlcmlhbFRo' >> "$TMPB64"
    printf '%s' 'ZW1lLnR5cG9ncmFwaHkuYm9keU1lZGl1bSwgY29sb3IgPSBtdXNpY0NvbG9ycygpLnRleHRTZWNvbmRhcnkpCiAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICBTcGFjZXIobW9kaWZpZXIgPSBNb2RpZmllci53ZWlnaHQoMWYpKQogICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgVGV4dCgKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB0ZXh0ID0gIiR7c2NyaW1TbGlkZXIudG9JbnQo' >> "$TMPB64"
    printf '%s' 'KX0lIiwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBzdHlsZSA9IE1hdGVyaWFsVGhlbWUudHlwb2dyYXBoeS5ib2R5' >> "$TMPB64"
    printf '%s' 'TWVkaXVtLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNvbG9yID0gbXVzaWNDb2xvcnMoKS50ZXh0UHJpbWFyeSwK' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICkKICAgICAgICAgICAgICAgICAgICAgICAgfQogICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICBTbGlkZXIoCiAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZSA9IHNjcmltU2xpZGVyLAogICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgb25WYWx1ZUNoYW5nZSA9IHsgc2NyaW1TbGlkZXIgPSBpdCB9LAogICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgb25WYWx1ZUNoYW5nZUZpbmlzaGVkID0geyBXYWxscGFwZXJNYW5hZ2VyLnNldFNjcmltKGNvbnRleHQsIHNjcmltU2xp' >> "$TMPB64"
    printf '%s' 'ZGVyLnRvSW50KCkpIH0sCiAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZVJhbmdlID0gMGYuLjkwZiwKICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgIHN0ZXBzID0gOCwKICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNvbG9ycyA9IFNsaWRlckRl' >> "$TMPB64"
    printf '%s' 'ZmF1bHRzLmNvbG9ycygKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB0aHVtYkNvbG9yID0gbXVzaWNDb2xvcnMoKS5h' >> "$TMPB64"
    printf '%s' 'Y2NlbnQsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgYWN0aXZlVHJhY2tDb2xvciA9IG11c2ljQ29sb3JzKCkuYWNj' >> "$TMPB64"
    printf '%s' 'ZW50LAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGluYWN0aXZlVHJhY2tDb2xvciA9IG11c2ljQ29sb3JzKCkuY2Fy' >> "$TMPB64"
    printf '%s' 'ZFNlY29uZGFyeSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICksCiAgICAgICAgICAgICAgICAgICAgICAgICkKICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgVGV4dCgKICAgICAgICAgICAgICAgICAgICAgICAgICAgIHRleHQgPSAi5aOB57q45LmL5LiK55qE' >> "$TMPB64"
    printf '%s' '5LiA5bGC6buR6Imy6YGu572p77ya6LaK6auY5aOB57q46LaK5pqX44CB5paH5a2X6LaK5riF44CC6buY6K6kIDAg5LiN6YGu5oyh' >> "$TMPB64"
    printf '%s' '44CCIiwKICAgICAgICAgICAgICAgICAgICAgICAgICAgIHN0eWxlID0gTWF0ZXJpYWxUaGVtZS50eXBvZ3JhcGh5LmJvZHlTbWFs' >> "$TMPB64"
    printf '%s' 'bCwKICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNvbG9yID0gbXVzaWNDb2xvcnMoKS50ZXh0U2Vjb25kYXJ5LAogICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICApCiAgICAgICAgICAgICAgICAgICAgICAgIFNwYWNlcihtb2RpZmllciA9IE1vZGlmaWVyLmhlaWdo' >> "$TMPB64"
    printf '%s' 'dCgxNi5kcCkpCiAgICAgICAgICAgICAgICAgICAgICAgIFJvdygKICAgICAgICAgICAgICAgICAgICAgICAgICAgIG1vZGlmaWVy' >> "$TMPB64"
    printf '%s' 'ID0gTW9kaWZpZXIuZmlsbE1heFdpZHRoKCksCiAgICAgICAgICAgICAgICAgICAgICAgICAgICB2ZXJ0aWNhbEFsaWdubWVudCA9' >> "$TMPB64"
    printf '%s' 'IEFsaWdubWVudC5DZW50ZXJWZXJ0aWNhbGx5LAogICAgICAgICAgICAgICAgICAgICAgICApIHsKICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgIFRleHQoIuWjgee6uOS4jemAj+aYjuW6piIsIHN0eWxlID0gTWF0ZXJpYWxUaGVtZS50eXBvZ3JhcGh5LmJvZHlN' >> "$TMPB64"
    printf '%s' 'ZWRpdW0sIGNvbG9yID0gbXVzaWNDb2xvcnMoKS50ZXh0U2Vjb25kYXJ5KQogICAgICAgICAgICAgICAgICAgICAgICAgICAgU3Bh' >> "$TMPB64"
    printf '%s' 'Y2VyKG1vZGlmaWVyID0gTW9kaWZpZXIud2VpZ2h0KDFmKSkKICAgICAgICAgICAgICAgICAgICAgICAgICAgIFRleHQoCiAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgdGV4dCA9ICIke29wYWNpdHlTbGlkZXIudG9JbnQoKX0lIiwKICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICBzdHlsZSA9IE1hdGVyaWFsVGhlbWUudHlwb2dyYXBoeS5ib2R5TWVkaXVtLAogICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgIGNvbG9yID0gbXVzaWNDb2xvcnMoKS50ZXh0UHJpbWFyeSwKICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICkKICAgICAgICAgICAgICAgICAgICAgICAgfQogICAgICAgICAgICAgICAgICAgICAgICBTbGlkZXIoCiAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZSA9IG9wYWNpdHlTbGlkZXIsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICBv' >> "$TMPB64"
    printf '%s' 'blZhbHVlQ2hhbmdlID0geyBvcGFjaXR5U2xpZGVyID0gaXQgfSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uVmFsdWVD' >> "$TMPB64"
    printf '%s' 'aGFuZ2VGaW5pc2hlZCA9IHsgV2FsbHBhcGVyTWFuYWdlci5zZXRPcGFjaXR5KGNvbnRleHQsIG9wYWNpdHlTbGlkZXIudG9JbnQo' >> "$TMPB64"
    printf '%s' 'KSkgfSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlUmFuZ2UgPSAwZi4uMTAwZiwKICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgIHN0ZXBzID0gOSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNvbG9ycyA9IFNsaWRlckRlZmF1bHRzLmNv' >> "$TMPB64"
    printf '%s' 'bG9ycygKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB0aHVtYkNvbG9yID0gbXVzaWNDb2xvcnMoKS5hY2NlbnQsCiAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgYWN0aXZlVHJhY2tDb2xvciA9IG11c2ljQ29sb3JzKCkuYWNjZW50LAogICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgIGluYWN0aXZlVHJhY2tDb2xvciA9IG11c2ljQ29sb3JzKCkuY2FyZFNlY29uZGFy' >> "$TMPB64"
    printf '%s' 'eSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICksCiAgICAgICAgICAgICAgICAgICAgICAgICkKICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgUm93KAogICAgICAgICAgICAgICAgICAgICAgICAgICAgbW9kaWZpZXIgPSBNb2RpZmllci5maWxsTWF4V2lkdGgo' >> "$TMPB64"
    printf '%s' 'KSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZlcnRpY2FsQWxpZ25tZW50ID0gQWxpZ25tZW50LkNlbnRlclZlcnRpY2Fs' >> "$TMPB64"
    printf '%s' 'bHksCiAgICAgICAgICAgICAgICAgICAgICAgICkgewogICAgICAgICAgICAgICAgICAgICAgICAgICAgVGV4dCgi5qih57OK56iL' >> "$TMPB64"
    printf '%s' '5bqmIiwgc3R5bGUgPSBNYXRlcmlhbFRoZW1lLnR5cG9ncmFwaHkuYm9keU1lZGl1bSwgY29sb3IgPSBtdXNpY0NvbG9ycygpLnRl' >> "$TMPB64"
    printf '%s' 'eHRTZWNvbmRhcnkpCiAgICAgICAgICAgICAgICAgICAgICAgICAgICBTcGFjZXIobW9kaWZpZXIgPSBNb2RpZmllci53ZWlnaHQo' >> "$TMPB64"
    printf '%s' 'MWYpKQogICAgICAgICAgICAgICAgICAgICAgICAgICAgVGV4dCgKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB0ZXh0' >> "$TMPB64"
    printf '%s' 'ID0gIiR7Ymx1clNsaWRlci50b0ludCgpfSIsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgc3R5bGUgPSBNYXRlcmlh' >> "$TMPB64"
    printf '%s' 'bFRoZW1lLnR5cG9ncmFwaHkuYm9keU1lZGl1bSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBjb2xvciA9IG11c2lj' >> "$TMPB64"
    printf '%s' 'Q29sb3JzKCkudGV4dFByaW1hcnksCiAgICAgICAgICAgICAgICAgICAgICAgICAgICApCiAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'IH0KICAgICAgICAgICAgICAgICAgICAgICAgU2xpZGVyKAogICAgICAgICAgICAgICAgICAgICAgICAgICAgdmFsdWUgPSBibHVy' >> "$TMPB64"
    printf '%s' 'U2xpZGVyLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgb25WYWx1ZUNoYW5nZSA9IHsgYmx1clNsaWRlciA9IGl0IH0sCiAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICBvblZhbHVlQ2hhbmdlRmluaXNoZWQgPSB7IFdhbGxwYXBlck1hbmFnZXIuc2V0Qmx1' >> "$TMPB64"
    printf '%s' 'cihjb250ZXh0LCBibHVyU2xpZGVyLnRvSW50KCkpIH0sCiAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZVJhbmdlID0g' >> "$TMPB64"
    printf '%s' 'MGYuLjIwZiwKICAgICAgICAgICAgICAgICAgICAgICAgICAgIHN0ZXBzID0gMTksCiAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICBjb2xvcnMgPSBTbGlkZXJEZWZhdWx0cy5jb2xvcnMoCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgdGh1bWJDb2xv' >> "$TMPB64"
    printf '%s' 'ciA9IG11c2ljQ29sb3JzKCkuYWNjZW50LAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGFjdGl2ZVRyYWNrQ29sb3Ig' >> "$TMPB64"
    printf '%s' 'PSBtdXNpY0NvbG9ycygpLmFjY2VudCwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBpbmFjdGl2ZVRyYWNrQ29sb3Ig' >> "$TMPB64"
    printf '%s' 'PSBtdXNpY0NvbG9ycygpLmNhcmRTZWNvbmRhcnksCiAgICAgICAgICAgICAgICAgICAgICAgICAgICApLAogICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICApCiAgICAgICAgICAgICAgICAgICAgICAgIFRleHQoCiAgICAgICAgICAgICAgICAgICAgICAgICAgICB0ZXh0' >> "$TMPB64"
    printf '%s' 'ID0gIuS4jemAj+aYjuW6puiwg+S9ju+8jOWjgee6uOS8muiejei/m+mhtemdouW6leiJsu+8m+aooeeziuiuqeeFp+eJh+mAgOaI' >> "$TMPB64"
    printf '%s' 'kOawm+WbtOW6le+8jOaWh+Wtl+abtOeqgeWHuu+8iOWPqueziuWjgee6uO+8jOS4jeeziueVjOmdou+8ieOAgiIsCiAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICBzdHlsZSA9IE1hdGVyaWFsVGhlbWUudHlwb2dyYXBoeS5ib2R5U21hbGwsCiAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICBjb2xvciA9IG11c2ljQ29sb3JzKCkudGV4dFNlY29uZGFyeSwKICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgKQogICAgICAgICAgICAgICAgICAgIH0KICAgICAgICAgICAgICAgIH0KICAgICAgICAgICAgfQogICAgICAgICAgICBpZiAo' >> "$TMPB64"
    printf '%s' 'd3BTdGF0ZS5oaXN0b3J5LmlzTm90RW1wdHkoKSkgewogICAgICAgICAgICAgICAgaXRlbSB7CiAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'VGV4dCgKICAgICAgICAgICAgICAgICAgICAgICAgdGV4dCA9ICLljoblj7Llo4HnurgiLAogICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICBzdHlsZSA9IE1hdGVyaWFsVGhlbWUudHlwb2dyYXBoeS50aXRsZU1lZGl1bS5jb3B5KGZvbnRXZWlnaHQgPSBGb250V2VpZ2h0' >> "$TMPB64"
    printf '%s' 'LkJvbGQpLAogICAgICAgICAgICAgICAgICAgICAgICBjb2xvciA9IG11c2ljQ29sb3JzKCkudGV4dFByaW1hcnksCiAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgKQogICAgICAgICAgICAgICAgfQogICAgICAgICAgICAgICAgaXRlbSB7CiAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'TGF6eVJvdyhob3Jpem9udGFsQXJyYW5nZW1lbnQgPSBBcnJhbmdlbWVudC5zcGFjZWRCeSgxMC5kcCkpIHsKICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgaXRlbXMod3BTdGF0ZS5oaXN0b3J5LCBrZXkgPSB7IGl0IH0pIHsgdSAtPgogICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgdmFsIGlzQ3VycmVudCA9IHUgPT0gd3BTdGF0ZS51cmwKICAgICAgICAgICAgICAgICAgICAgICAgICAgIEJveCgK' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBtb2RpZmllciA9IE1vZGlmaWVyCiAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgIC5zaXplKDg0LmRwKQogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAuY2xpcChSb3VuZGVk' >> "$TMPB64"
    printf '%s' 'Q29ybmVyU2hhcGUoMTIuZHApKQogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAuYmFja2dyb3VuZChtdXNpY0Nv' >> "$TMPB64"
    printf '%s' 'bG9ycygpLmNhcmRTZWNvbmRhcnkpCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIC50aGVuKAogICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgaWYgKGlzQ3VycmVudCkgTW9kaWZpZXIuYm9yZGVyKDIuZHAsIG11c2ljQ29s' >> "$TMPB64"
    printf '%s' 'b3JzKCkuYWNjZW50LCBSb3VuZGVkQ29ybmVyU2hhcGUoMTIuZHApKQogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgZWxzZSBNb2RpZmllcgogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICApCiAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgIC5jbGlja2FibGUgewogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgV2Fs' >> "$TMPB64"
    printf '%s' 'bHBhcGVyTWFuYWdlci5hcHBseShjb250ZXh0LCB1KQogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgdXJs' >> "$TMPB64"
    printf '%s' 'VGV4dCA9IHUKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgfSwKICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICkgewogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIEFzeW5jSW1hZ2UoCiAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgIG1vZGVsID0gSW1hZ2VSZXF1ZXN0LkJ1aWxkZXIoY29udGV4dCkuZGF0YSh1KS5zaXplKDI0MCkuYnVpbGQoKSwK' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgY29udGVudERlc2NyaXB0aW9uID0gbnVsbCwKICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgY29udGVudFNjYWxlID0gQ29udGVudFNjYWxlLkNyb3AsCiAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgIG1vZGlmaWVyID0gTW9kaWZpZXIuZmlsbE1heFNpemUoKSwKICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICApCiAgICAgICAgICAgICAgICAgICAgICAgICAgICB9CiAgICAgICAgICAgICAgICAgICAgICAgIH0KICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICB9CiAgICAgICAgICAgICAgICB9CiAgICAgICAgICAgIH0KICAgICAgICAgICAgaXRlbSB7CiAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICBUZXh0KAogICAgICAgICAgICAgICAgICAgIHRleHQgPSAi5aOB57q45L2N5LqO6Z+z5LmQ5LiT5Yy65pyA5bqV5bGC' >> "$TMPB64"
    printf '%s' '77yM5YW25LiK55uW5pyJ5Y+v6K+75oCn6YGu572p77yb6IOM5pmv5Zu+5oyJ5bGP5bmV5bC65a+45bCB6aG25Yqg6L2977yM5LiN' >> "$TMPB64"
    printf '%s' '5b2x5ZON5YiX6KGo5ruR5Yqo44CC5pys5Zyw5Zu+54mH5L2/55So57O757uf5paH5Lu26YCJ5oup5Zmo5bm255Sz6K+35oyB5LmF' >> "$TMPB64"
    printf '%s' '5o6I5p2D77yM6YeN5ZCv5LiN5aSx5pWI44CCIiwKICAgICAgICAgICAgICAgICAgICBzdHlsZSA9IE1hdGVyaWFsVGhlbWUudHlw' >> "$TMPB64"
    printf '%s' 'b2dyYXBoeS5ib2R5U21hbGwsCiAgICAgICAgICAgICAgICAgICAgY29sb3IgPSBtdXNpY0NvbG9ycygpLnRleHRTZWNvbmRhcnks' >> "$TMPB64"
    printf '%s' 'CiAgICAgICAgICAgICAgICApCiAgICAgICAgICAgIH0KICAgICAgICB9CiAgICB9Cn0K' >> "$TMPB64"
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
    printf '%s' 'Z2VTY2FsZSIgdG8gImZhbHNlIiwgImlzX2xhcmdlX3NjYWxlIiB0byAiMCIsCiAgICApLAogICAgNjAsCikKCnByaXZhdGUgdmFs' >> "$TMPB64"
    printf '%s' 'IFdQX0NBVFM6IExpc3Q8V3BDYXQ+ID0gbGlzdE9mKAogICAgZmVlZENhdCgi57K+6YCJIiwgIjAiKSwKICAgIGZlZWRDYXQoIumr' >> "$TMPB64"
    printf '%s' 'mOa4hSIsICIyMSIpLAogICAgZmVlZENhdCgi5YWo6Z2i5bGPIiwgIjEiKSwKICAgIGZlZWRDYXQoIjJLIiwgIjIiKSwKICAgIGZl' >> "$TMPB64"
    printf '%s' 'ZWRDYXQoIjRLIiwgIjUiKSwKICAgIFdwQ2F0KAogICAgICAgICJBSee7mOeUuyIsICIvYXBpL3dhbGxwYXBlci9jbGllbnQvYnlU' >> "$TMPB64"
    printf '%s' 'YWciLAogICAgICAgIG1hcE9mKAogICAgICAgICAgICAidGFnIiB0byAiQUnnu5jnlLsiLCAic29ydF90eXBlIiB0byAiNCIsCiAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICJpc19sYXJnZV9zY2FsZSIgdG8gIi0xIiwgImxhcmdlU2NhbGUiIHRvICJ0cnVlIiwKICAgICAgICAgICAgInNp' >> "$TMPB64"
    printf '%s' 'emVfdHlwZV9saXN0IiB0byAiWzIxLDIzLDI0LDI3LDMwLDMyXSIsICJzY2VuZV90eXBlX2xpc3QiIHRvICJbMF0iLAogICAgICAg' >> "$TMPB64"
    printf '%s' 'ICksCiAgICAgICAgMzAsCiAgICApLAogICAgV3BDYXQoCiAgICAgICAgIuW5s+advyIsICIvdjIvc2VhcmNoL2NvbW1vbkxpc3Qi' >> "$TMPB64"
    printf '%s' 'LAogICAgICAgIG1hcE9mKAogICAgICAgICAgICAidGFibGVfdHlwZSIgdG8gIjgiLCAic29ydF90eXBlIiB0byAiNCIsCiAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICJsYXJnZVNjYWxlIiB0byAidHJ1ZSIsICJpc19sYXJnZV9zY2FsZSIgdG8gIi0xIiwgInNlYXJjaF93b3JkIiB0byAi' >> "$TMPB64"
    printf '%s' 'IiwKICAgICAgICApLAogICAgICAgIDMwLAogICAgKSwKICAgIFdwQ2F0KAogICAgICAgICLogYrlpKnog4zmma8iLCAiL3YyL3Nl' >> "$TMPB64"
    printf '%s' 'YXJjaC9jb21tb25MaXN0IiwKICAgICAgICBtYXBPZigKICAgICAgICAgICAgInRhYmxlX3R5cGUiIHRvICI0IiwgInNvcnRfdHlw' >> "$TMPB64"
    printf '%s' 'ZSIgdG8gIjQiLAogICAgICAgICAgICAibGFyZ2VTY2FsZSIgdG8gInRydWUiLCAiaXNfbGFyZ2Vfc2NhbGUiIHRvICItMSIsICJz' >> "$TMPB64"
    printf '%s' 'ZWFyY2hfd29yZCIgdG8gIiIsCiAgICAgICAgKSwKICAgICAgICAzMCwKICAgICksCikKCm9iamVjdCBXcEFwaSB7CiAgICBwcml2' >> "$TMPB64"
    printf '%s' 'YXRlIGNvbnN0IHZhbCBIT1NUID0gImh0dHBzOi8vd2FsbHBhcGVyLnNvdXR1c2hlbnFpLmNvbSIKICAgIHByaXZhdGUgY29uc3Qg' >> "$TMPB64"
    printf '%s' 'dmFsIFNJR05fS0VZID0gImQ5ZmQzZWMzOTQiCgogICAgcHJpdmF0ZSBmdW4gZGV2aWNlSWQoY29udGV4dDogQ29udGV4dCk6IFN0' >> "$TMPB64"
    printf '%s' 'cmluZyB7CiAgICAgICAgdmFsIHNwID0gY29udGV4dC5nZXRTaGFyZWRQcmVmZXJlbmNlcygid2FsbHBhcGVyX3ByZWZzIiwgQ29u' >> "$TMPB64"
    printf '%s' 'dGV4dC5NT0RFX1BSSVZBVEUpCiAgICAgICAgdmFsIHNhdmVkID0gc3AuZ2V0U3RyaW5nKCJ3cF9kZXZpY2VfaWQiLCBudWxsKQog' >> "$TMPB64"
    printf '%s' 'ICAgICAgIGlmICghc2F2ZWQuaXNOdWxsT3JCbGFuaygpKSByZXR1cm4gc2F2ZWQKICAgICAgICB2YWwgYnl0ZXMgPSBCeXRlQXJy' >> "$TMPB64"
    printf '%s' 'YXkoMTYpCiAgICAgICAgU2VjdXJlUmFuZG9tKCkubmV4dEJ5dGVzKGJ5dGVzKQogICAgICAgIHZhbCBpZCA9IGJ5dGVzLmpvaW5U' >> "$TMPB64"
    printf '%s' 'b1N0cmluZygiIikgeyAiJTAyeCIuZm9ybWF0KGl0KSB9CiAgICAgICAgc3AuZWRpdCgpLnB1dFN0cmluZygid3BfZGV2aWNlX2lk' >> "$TMPB64"
    printf '%s' 'IiwgaWQpLmFwcGx5KCkKICAgICAgICByZXR1cm4gaWQKICAgIH0KCiAgICBwcml2YXRlIGZ1biBzY3JhbWJsZWRUaW1lKCk6IFN0' >> "$TMPB64"
    printf '%s' 'cmluZyB7CiAgICAgICAgdmFsIHMgPSBTeXN0ZW0uY3VycmVudFRpbWVNaWxsaXMoKSAvIDEwMDAKICAgICAgICByZXR1cm4gKHMg' >> "$TMPB64"
    printf '%s' 'KiAxMDAwICsgKChzIHhvciAzMzRMKSAlIDEwMDApKS50b1N0cmluZygpCiAgICB9CgogICAgcHJpdmF0ZSBmdW4gbWQ1KHRleHQ6' >> "$TMPB64"
    printf '%s' 'IFN0cmluZyk6IFN0cmluZyB7CiAgICAgICAgdmFsIGRpZ2VzdCA9IE1lc3NhZ2VEaWdlc3QuZ2V0SW5zdGFuY2UoIk1ENSIpLmRp' >> "$TMPB64"
    printf '%s' 'Z2VzdCh0ZXh0LnRvQnl0ZUFycmF5KENoYXJzZXRzLlVURl84KSkKICAgICAgICByZXR1cm4gZGlnZXN0LmpvaW5Ub1N0cmluZygi' >> "$TMPB64"
    printf '%s' 'IikgeyAiJTAyeCIuZm9ybWF0KGl0KSB9CiAgICB9CgogICAgc3VzcGVuZCBmdW4gZmV0Y2goY29udGV4dDogQ29udGV4dCwgY2F0' >> "$TMPB64"
    printf '%s' 'OiBXcENhdCwgcGFnZTogSW50KTogUmVzdWx0PExpc3Q8V3BJdGVtPj4gPQogICAgICAgIHdpdGhDb250ZXh0KERpc3BhdGNoZXJz' >> "$TMPB64"
    printf '%s' 'LklPKSB7CiAgICAgICAgICAgIHRyeSB7CiAgICAgICAgICAgICAgICB2YWwgdGltZSA9IHNjcmFtYmxlZFRpbWUoKQogICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgdmFsIHBhcmFtcyA9IHNvcnRlZE1hcE9mPFN0cmluZywgU3RyaW5nPigpCiAgICAgICAgICAgICAgICBwYXJhbXNb' >> "$TMPB64"
    printf '%s' 'InBsYXRmb3JtIl0gPSAiMCIKICAgICAgICAgICAgICAgIHBhcmFtc1sidmVyc2lvbl9jb2RlIl0gPSAiMTkzIgogICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgcGFyYW1zWyJwcm9kdWN0X2lkIl0gPSAiMjAzIgogICAgICAgICAgICAgICAgcGFyYW1zWyJkZXZpY2VfaWQiXSA9IGRl' >> "$TMPB64"
    printf '%s' 'dmljZUlkKGNvbnRleHQpCiAgICAgICAgICAgICAgICBwYXJhbXNbImlzX2VuY3J5cHQiXSA9ICJmYWxzZSIKICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgIHBhcmFtc1sidGltZSJdID0gdGltZQogICAgICAgICAgICAgICAgcGFyYW1zLnB1dEFsbChjYXQuYmFzZVBhcmFtcykKICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgIHBhcmFtc1sicGFnZSJdID0gcGFnZS50b1N0cmluZygpCiAgICAgICAgICAgICAgICBwYXJhbXNbInBhZ2Vf' >> "$TMPB64"
    printf '%s' 'c2l6ZSJdID0gY2F0LnBhZ2VTaXplLnRvU3RyaW5nKCkKICAgICAgICAgICAgICAgIHZhbCBzaWduU3JjID0gcGFyYW1zLmVudHJp' >> "$TMPB64"
    printf '%s' 'ZXMuam9pblRvU3RyaW5nKCImIikgeyAiJHtpdC5rZXl9PSR7aXQudmFsdWV9IiB9ICsKICAgICAgICAgICAgICAgICAgICAiJmtl' >> "$TMPB64"
    printf '%s' 'eT0iICsgU0lHTl9LRVkKICAgICAgICAgICAgICAgIHBhcmFtc1sic2lnbiJdID0gbWQ1KHNpZ25TcmMpCiAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICB2YWwgYm9keSA9IHBhcmFtcy5lbnRyaWVzLmpvaW5Ub1N0cmluZygiJiIpIHsKICAgICAgICAgICAgICAgICAgICAiJHtpdC5r' >> "$TMPB64"
    printf '%s' 'ZXl9PSR7VVJMRW5jb2Rlci5lbmNvZGUoaXQudmFsdWUsICJVVEYtOCIpfSIKICAgICAgICAgICAgICAgIH0KICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgIHZhbCBjb25uID0gVVJMKEhPU1QgKyBjYXQucGF0aCkub3BlbkNvbm5lY3Rpb24oKSBhcyBIdHRwVVJMQ29ubmVjdGlvbgog' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgY29ubi5yZXF1ZXN0TWV0aG9kID0gIlBPU1QiCiAgICAgICAgICAgICAgICBjb25uLmNvbm5lY3RUaW1l' >> "$TMPB64"
    printf '%s' 'b3V0ID0gMTAwMDAKICAgICAgICAgICAgICAgIGNvbm4ucmVhZFRpbWVvdXQgPSAyNTAwMAogICAgICAgICAgICAgICAgY29ubi5k' >> "$TMPB64"
    printf '%s' 'b091dHB1dCA9IHRydWUKICAgICAgICAgICAgICAgIGNvbm4uc2V0UmVxdWVzdFByb3BlcnR5KCJVc2VyLUFnZW50IiwgIm9raHR0' >> "$TMPB64"
    printf '%s' 'cC8zLjEyLjYiKQogICAgICAgICAgICAgICAgY29ubi5zZXRSZXF1ZXN0UHJvcGVydHkoIkNvbnRlbnQtVHlwZSIsICJhcHBsaWNh' >> "$TMPB64"
    printf '%s' 'dGlvbi94LXd3dy1mb3JtLXVybGVuY29kZWQiKQogICAgICAgICAgICAgICAgY29ubi5zZXRSZXF1ZXN0UHJvcGVydHkoInRpbWVz' >> "$TMPB64"
    printf '%s' 'dGFtcCIsIHRpbWUpCiAgICAgICAgICAgICAgICBjb25uLm91dHB1dFN0cmVhbS51c2UgeyBpdC53cml0ZShib2R5LnRvQnl0ZUFy' >> "$TMPB64"
    printf '%s' 'cmF5KENoYXJzZXRzLlVURl84KSkgfQogICAgICAgICAgICAgICAgdmFsIHRleHQgPSBjb25uLmlucHV0U3RyZWFtLmJ1ZmZlcmVk' >> "$TMPB64"
    printf '%s' 'UmVhZGVyKCkucmVhZFRleHQoKQogICAgICAgICAgICAgICAgdmFsIGpzb24gPSBKU09OT2JqZWN0KHRleHQpCiAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICBpZiAoanNvbi5vcHRJbnQoImNvZGUiKSAhPSAyMDApIHsKICAgICAgICAgICAgICAgICAgICByZXR1cm5Ad2l0aENvbnRl' >> "$TMPB64"
    printf '%s' 'eHQgUmVzdWx0LmZhaWx1cmUoRXhjZXB0aW9uKGpzb24ub3B0U3RyaW5nKCJlcnJvcl9tc2ciLCAi5o6l5Y+j6ZSZ6K+vIikpKQog' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgfQogICAgICAgICAgICAgICAgdmFsIGFyciA9IGpzb24ub3B0SlNPTkFycmF5KCJkYXRhIikKICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICA/OiByZXR1cm5Ad2l0aENvbnRleHQgUmVzdWx0LnN1Y2Nlc3MoZW1wdHlMaXN0KCkpCiAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICB2YWwgb3V0ID0gQXJyYXlMaXN0PFdwSXRlbT4oKQogICAgICAgICAgICAgICAgZm9yIChpIGluIDAgdW50aWwgYXJyLmxl' >> "$TMPB64"
    printf '%s' 'bmd0aCgpKSB7CiAgICAgICAgICAgICAgICAgICAgdmFsIG8gPSBhcnIub3B0SlNPTk9iamVjdChpKSA/OiBjb250aW51ZQogICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgIHZhbCBsYXJnZSA9IG8ub3B0U3RyaW5nKCJsYXJnZVVybCIpCiAgICAgICAgICAgICAgICAgICAgdmFs' >> "$TMPB64"
    printf '%s' 'IHRodW1iID0gby5vcHRTdHJpbmcoInRodW1iVXJsIikKICAgICAgICAgICAgICAgICAgICBpZiAobGFyZ2UuaXNCbGFuaygpICYm' >> "$TMPB64"
    printf '%s' 'IHRodW1iLmlzQmxhbmsoKSkgY29udGludWUKICAgICAgICAgICAgICAgICAgICB2YWwgdGl0bGUgPSBvLm9wdFN0cmluZygidGl0' >> "$TMPB64"
    printf '%s' 'bGUiKS5pZkJsYW5rIHsKICAgICAgICAgICAgICAgICAgICAgICAgby5vcHRTdHJpbmcoImRldGFpbEluZm8iKS5pZkJsYW5rIHsg' >> "$TMPB64"
    printf '%s' 'IuWjgee6uCAjJHtvLm9wdExvbmcoImlkIil9IiB9CiAgICAgICAgICAgICAgICAgICAgfQogICAgICAgICAgICAgICAgICAgIG91' >> "$TMPB64"
    printf '%s' 'dC5hZGQoCiAgICAgICAgICAgICAgICAgICAgICAgIFdwSXRlbSgKICAgICAgICAgICAgICAgICAgICAgICAgICAgIGlkID0gby5v' >> "$TMPB64"
    printf '%s' 'cHRMb25nKCJpZCIpLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgdGl0bGUgPSB0aXRsZSwKICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgIHRodW1iID0gdGh1bWIuaWZCbGFuayB7IGxhcmdlIH0sCiAgICAgICAgICAgICAgICAgICAgICAgICAgICBsYXJn' >> "$TMPB64"
    printf '%s' 'ZSA9IGxhcmdlLmlmQmxhbmsgeyB0aHVtYiB9LAogICAgICAgICAgICAgICAgICAgICAgICAgICAgd2lkdGggPSBvLm9wdEludCgi' >> "$TMPB64"
    printf '%s' 'd2lkdGgiKSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgIGhlaWdodCA9IG8ub3B0SW50KCJoZWlnaHQiKSwKICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgKQogICAgICAgICAgICAgICAgICAgICkKICAgICAgICAgICAgICAgIH0KICAgICAgICAgICAgICAgIFJl' >> "$TMPB64"
    printf '%s' 'c3VsdC5zdWNjZXNzKG91dCkKICAgICAgICAgICAgfSBjYXRjaCAoZTogRXhjZXB0aW9uKSB7CiAgICAgICAgICAgICAgICBSZXN1' >> "$TMPB64"
    printf '%s' 'bHQuZmFpbHVyZShlKQogICAgICAgICAgICB9CiAgICAgICAgfQp9CgpjbGFzcyBXYWxscGFwZXJMaWJyYXJ5QWN0aXZpdHkgOiBD' >> "$TMPB64"
    printf '%s' 'b21wb25lbnRBY3Rpdml0eSgpIHsKICAgIG92ZXJyaWRlIGZ1biBvbkNyZWF0ZShzYXZlZEluc3RhbmNlU3RhdGU6IEJ1bmRsZT8p' >> "$TMPB64"
    printf '%s' 'IHsKICAgICAgICBzdXBlci5vbkNyZWF0ZShzYXZlZEluc3RhbmNlU3RhdGUpCiAgICAgICAgdmFsIGFwcEN0eCA9IGFwcGxpY2F0' >> "$TMPB64"
    printf '%s' 'aW9uQ29udGV4dAogICAgICAgIE11c2ljVGhlbWVNYW5hZ2VyLmluaXQoYXBwQ3R4KQogICAgICAgIFdhbGxwYXBlck1hbmFnZXIu' >> "$TMPB64"
    printf '%s' 'aW5pdChhcHBDdHgpCiAgICAgICAgc2V0Q29udGVudCB7CiAgICAgICAgICAgIHZhbCBpc0RhcmsgYnkgTXVzaWNUaGVtZU1hbmFn' >> "$TMPB64"
    printf '%s' 'ZXIuaXNEYXJrVGhlbWUKICAgICAgICAgICAgdmFsIHdpbmRvdyA9IHRoaXNAV2FsbHBhcGVyTGlicmFyeUFjdGl2aXR5LndpbmRv' >> "$TMPB64"
    printf '%s' 'dwogICAgICAgICAgICBTaWRlRWZmZWN0IHsKICAgICAgICAgICAgICAgIFdpbmRvd0NvbXBhdC5nZXRJbnNldHNDb250cm9sbGVy' >> "$TMPB64"
    printf '%s' 'KHdpbmRvdywgd2luZG93LmRlY29yVmlldykKICAgICAgICAgICAgICAgICAgICAuaXNBcHBlYXJhbmNlTGlnaHRTdGF0dXNCYXJz' >> "$TMPB64"
    printf '%s' 'ID0gIWlzRGFyawogICAgICAgICAgICB9CiAgICAgICAgICAgIEx4TXVzaWNUaGVtZShpc0RhcmtUaGVtZSA9IGlzRGFyaykgewog' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgV2FsbHBhcGVyTGlicmFyeVNjcmVlbihvbkJhY2sgPSB7IGZpbmlzaCgpIH0pCiAgICAgICAgICAgIH0K' >> "$TMPB64"
    printf '%s' 'ICAgICAgICB9CiAgICB9Cn0KCkBDb21wb3NhYmxlCmZ1biBXYWxscGFwZXJMaWJyYXJ5U2NyZWVuKG9uQmFjazogKCkgLT4gVW5p' >> "$TMPB64"
    printf '%s' 'dCkgewogICAgdmFsIGNvbnRleHQgPSBMb2NhbENvbnRleHQuY3VycmVudAogICAgdmFsIHNjb3BlID0gcmVtZW1iZXJDb3JvdXRp' >> "$TMPB64"
    printf '%s' 'bmVTY29wZSgpCiAgICB2YXIgY2F0IGJ5IHJlbWVtYmVyIHsgbXV0YWJsZVN0YXRlT2YoV1BfQ0FUU1swXSkgfQogICAgdmFyIGl0' >> "$TMPB64"
    printf '%s' 'ZW1zIGJ5IHJlbWVtYmVyIHsgbXV0YWJsZVN0YXRlT2Y8TGlzdDxXcEl0ZW0+PihlbXB0eUxpc3QoKSkgfQogICAgdmFyIGxvYWRp' >> "$TMPB64"
    printf '%s' 'bmcgYnkgcmVtZW1iZXIgeyBtdXRhYmxlU3RhdGVPZihmYWxzZSkgfQogICAgdmFyIGVycm9yIGJ5IHJlbWVtYmVyIHsgbXV0YWJs' >> "$TMPB64"
    printf '%s' 'ZVN0YXRlT2Y8U3RyaW5nPz4obnVsbCkgfQogICAgdmFyIHBhZ2UgYnkgcmVtZW1iZXIgeyBtdXRhYmxlU3RhdGVPZigxKSB9CiAg' >> "$TMPB64"
    printf '%s' 'ICB2YXIgZW5kUmVhY2hlZCBieSByZW1lbWJlciB7IG11dGFibGVTdGF0ZU9mKGZhbHNlKSB9CgogICAgZnVuIGxvYWQodGFyZ2V0' >> "$TMPB64"
    printf '%s' 'OiBXcENhdCwgdGFyZ2V0UGFnZTogSW50LCBhcHBlbmQ6IEJvb2xlYW4pIHsKICAgICAgICBsb2FkaW5nID0gdHJ1ZQogICAgICAg' >> "$TMPB64"
    printf '%s' 'IGlmICghYXBwZW5kKSBlcnJvciA9IG51bGwKICAgICAgICBzY29wZS5sYXVuY2ggewogICAgICAgICAgICB2YWwgcmVzdWx0ID0g' >> "$TMPB64"
    printf '%s' 'V3BBcGkuZmV0Y2goY29udGV4dCwgdGFyZ2V0LCB0YXJnZXRQYWdlKQogICAgICAgICAgICBsb2FkaW5nID0gZmFsc2UKICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgcmVzdWx0Lm9uU3VjY2VzcyB7IGxpc3QgLT4KICAgICAgICAgICAgICAgIGl0ZW1zID0gaWYgKGFwcGVuZCkgewogICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgIHZhbCBrbm93biA9IGl0ZW1zLm1hcCB7IGl0LmlkIH0udG9IYXNoU2V0KCkKICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICBpdGVtcyArIGxpc3QuZmlsdGVyIHsgaXQuaWQgIWluIGtub3duIH0KICAgICAgICAgICAgICAgIH0gZWxzZSB7CiAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgbGlzdAogICAgICAgICAgICAgICAgfQogICAgICAgICAgICAgICAgcGFnZSA9IHRhcmdldFBhZ2UKICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgIGVuZFJlYWNoZWQgPSBsaXN0LnNpemUgPCB0YXJnZXQucGFnZVNpemUKICAgICAgICAgICAgfS5vbkZhaWx1' >> "$TMPB64"
    printf '%s' 'cmUgewogICAgICAgICAgICAgICAgaWYgKCFhcHBlbmQpIGVycm9yID0gIuWKoOi9veWksei0pe+8jOivt+ajgOafpee9kee7nOWQ' >> "$TMPB64"
    printf '%s' 'jumHjeivlSIKICAgICAgICAgICAgfQogICAgICAgIH0KICAgIH0KCiAgICBMYXVuY2hlZEVmZmVjdChjYXQpIHsKICAgICAgICBp' >> "$TMPB64"
    printf '%s' 'dGVtcyA9IGVtcHR5TGlzdCgpCiAgICAgICAgcGFnZSA9IDEKICAgICAgICBlbmRSZWFjaGVkID0gZmFsc2UKICAgICAgICBsb2Fk' >> "$TMPB64"
    printf '%s' 'KGNhdCwgMSwgZmFsc2UpCiAgICB9CgogICAgQ29sdW1uKAogICAgICAgIG1vZGlmaWVyID0gTW9kaWZpZXIKICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'LmZpbGxNYXhTaXplKCkKICAgICAgICAgICAgLmJhY2tncm91bmQobXVzaWNDb2xvcnMoKS5iYWNrZ3JvdW5kKQogICAgKSB7CiAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgUm93KAogICAgICAgICAgICBtb2RpZmllciA9IE1vZGlmaWVyCiAgICAgICAgICAgICAgICAuZmlsbE1heFdpZHRoKCkK' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgIC5wYWRkaW5nKHN0YXJ0ID0gOC5kcCwgZW5kID0gMTYuZHAsIHRvcCA9IDQ4LmRwLCBib3R0b20gPSA4' >> "$TMPB64"
    printf '%s' 'LmRwKSwKICAgICAgICAgICAgdmVydGljYWxBbGlnbm1lbnQgPSBBbGlnbm1lbnQuQ2VudGVyVmVydGljYWxseSwKICAgICAgICAp' >> "$TMPB64"
    printf '%s' 'IHsKICAgICAgICAgICAgVGV4dCgKICAgICAgICAgICAgICAgIHRleHQgPSAi4oC5IiwKICAgICAgICAgICAgICAgIHN0eWxlID0g' >> "$TMPB64"
    printf '%s' 'TWF0ZXJpYWxUaGVtZS50eXBvZ3JhcGh5LmhlYWRsaW5lTWVkaXVtLAogICAgICAgICAgICAgICAgY29sb3IgPSBtdXNpY0NvbG9y' >> "$TMPB64"
    printf '%s' 'cygpLnRleHRQcmltYXJ5LAogICAgICAgICAgICAgICAgbW9kaWZpZXIgPSBNb2RpZmllcgogICAgICAgICAgICAgICAgICAgIC5j' >> "$TMPB64"
    printf '%s' 'bGlja2FibGUgeyBvbkJhY2soKSB9CiAgICAgICAgICAgICAgICAgICAgLnBhZGRpbmcoaG9yaXpvbnRhbCA9IDEyLmRwLCB2ZXJ0' >> "$TMPB64"
    printf '%s' 'aWNhbCA9IDQuZHApLAogICAgICAgICAgICApCiAgICAgICAgICAgIFRleHQoCiAgICAgICAgICAgICAgICB0ZXh0ID0gIuWcqOe6' >> "$TMPB64"
    printf '%s' 'v+Wjgee6uOW6kyIsCiAgICAgICAgICAgICAgICBzdHlsZSA9IE1hdGVyaWFsVGhlbWUudHlwb2dyYXBoeS50aXRsZUxhcmdlLmNv' >> "$TMPB64"
    printf '%s' 'cHkoZm9udFdlaWdodCA9IEZvbnRXZWlnaHQuQm9sZCksCiAgICAgICAgICAgICAgICBjb2xvciA9IG11c2ljQ29sb3JzKCkudGV4' >> "$TMPB64"
    printf '%s' 'dFByaW1hcnksCiAgICAgICAgICAgICkKICAgICAgICB9CiAgICAgICAgTGF6eVJvdygKICAgICAgICAgICAgY29udGVudFBhZGRp' >> "$TMPB64"
    printf '%s' 'bmcgPSBQYWRkaW5nVmFsdWVzKGhvcml6b250YWwgPSAxNi5kcCksCiAgICAgICAgICAgIGhvcml6b250YWxBcnJhbmdlbWVudCA9' >> "$TMPB64"
    printf '%s' 'IEFycmFuZ2VtZW50LnNwYWNlZEJ5KDEwLmRwKSwKICAgICAgICApIHsKICAgICAgICAgICAgaXRlbXMoV1BfQ0FUUywga2V5ID0g' >> "$TMPB64"
    printf '%s' 'eyBpdC5uYW1lIH0pIHsgYyAtPgogICAgICAgICAgICAgICAgdmFsIHNlbGVjdGVkID0gYy5uYW1lID09IGNhdC5uYW1lCiAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICBCb3goCiAgICAgICAgICAgICAgICAgICAgbW9kaWZpZXIgPSBNb2RpZmllcgogICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAuY2xpcChSb3VuZGVkQ29ybmVyU2hhcGUoNTApKQogICAgICAgICAgICAgICAgICAgICAgICAuYmFja2dyb3VuZChpZiAo' >> "$TMPB64"
    printf '%s' 'c2VsZWN0ZWQpIG11c2ljQ29sb3JzKCkuYWNjZW50IGVsc2UgbXVzaWNDb2xvcnMoKS5jYXJkU2Vjb25kYXJ5KQogICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAuY2xpY2thYmxlIHsgY2F0ID0gYyB9CiAgICAgICAgICAgICAgICAgICAgICAgIC5wYWRkaW5nKGhvcml6' >> "$TMPB64"
    printf '%s' 'b250YWwgPSAxOC5kcCwgdmVydGljYWwgPSA4LmRwKSwKICAgICAgICAgICAgICAgICkgewogICAgICAgICAgICAgICAgICAgIFRl' >> "$TMPB64"
    printf '%s' 'eHQoCiAgICAgICAgICAgICAgICAgICAgICAgIHRleHQgPSBjLm5hbWUsCiAgICAgICAgICAgICAgICAgICAgICAgIHN0eWxlID0g' >> "$TMPB64"
    printf '%s' 'TWF0ZXJpYWxUaGVtZS50eXBvZ3JhcGh5LmJvZHlNZWRpdW0sCiAgICAgICAgICAgICAgICAgICAgICAgIGNvbG9yID0gaWYgKHNl' >> "$TMPB64"
    printf '%s' 'bGVjdGVkKSBtdXNpY0NvbG9ycygpLmFjY2VudFRleHQgZWxzZSBtdXNpY0NvbG9ycygpLnRleHRTZWNvbmRhcnksCiAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgKQogICAgICAgICAgICAgICAgfQogICAgICAgICAgICB9CiAgICAgICAgfQogICAgICAgIEJveChtb2RpZmll' >> "$TMPB64"
    printf '%s' 'ciA9IE1vZGlmaWVyLmZpbGxNYXhTaXplKCkpIHsKICAgICAgICAgICAgd2hlbiB7CiAgICAgICAgICAgICAgICBsb2FkaW5nICYm' >> "$TMPB64"
    printf '%s' 'IGl0ZW1zLmlzRW1wdHkoKSAtPiB7CiAgICAgICAgICAgICAgICAgICAgQ2lyY3VsYXJQcm9ncmVzc0luZGljYXRvcigKICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgY29sb3IgPSBtdXNpY0NvbG9ycygpLmFjY2VudCwKICAgICAgICAgICAgICAgICAgICAgICAgbW9k' >> "$TMPB64"
    printf '%s' 'aWZpZXIgPSBNb2RpZmllci5hbGlnbihBbGlnbm1lbnQuQ2VudGVyKSwKICAgICAgICAgICAgICAgICAgICApCiAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICB9CiAgICAgICAgICAgICAgICBlcnJvciAhPSBudWxsICYmIGl0ZW1zLmlzRW1wdHkoKSAtPiB7CiAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgQ29sdW1uKAogICAgICAgICAgICAgICAgICAgICAgICBtb2RpZmllciA9IE1vZGlmaWVyLmFsaWduKEFsaWdubWVudC5D' >> "$TMPB64"
    printf '%s' 'ZW50ZXIpLAogICAgICAgICAgICAgICAgICAgICAgICBob3Jpem9udGFsQWxpZ25tZW50ID0gQWxpZ25tZW50LkNlbnRlckhvcml6' >> "$TMPB64"
    printf '%s' 'b250YWxseSwKICAgICAgICAgICAgICAgICAgICApIHsKICAgICAgICAgICAgICAgICAgICAgICAgVGV4dCgKICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgIHRleHQgPSBlcnJvciA/OiAiIiwKICAgICAgICAgICAgICAgICAgICAgICAgICAgIHN0eWxlID0gTWF0' >> "$TMPB64"
    printf '%s' 'ZXJpYWxUaGVtZS50eXBvZ3JhcGh5LmJvZHlNZWRpdW0sCiAgICAgICAgICAgICAgICAgICAgICAgICAgICBjb2xvciA9IG11c2lj' >> "$TMPB64"
    printf '%s' 'Q29sb3JzKCkudGV4dFNlY29uZGFyeSwKICAgICAgICAgICAgICAgICAgICAgICAgKQogICAgICAgICAgICAgICAgICAgICAgICBC' >> "$TMPB64"
    printf '%s' 'dXR0b24oCiAgICAgICAgICAgICAgICAgICAgICAgICAgICBvbkNsaWNrID0geyBsb2FkKGNhdCwgMSwgZmFsc2UpIH0sCiAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICBjb2xvcnMgPSBCdXR0b25EZWZhdWx0cy5idXR0b25Db2xvcnMoCiAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgY29udGFpbmVyQ29sb3IgPSBtdXNpY0NvbG9ycygpLmFjY2VudCwKICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICBjb250ZW50Q29sb3IgPSBtdXNpY0NvbG9ycygpLmFjY2VudFRleHQsCiAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICApLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgbW9kaWZpZXIgPSBNb2RpZmllci5wYWRkaW5nKHRvcCA9IDEy' >> "$TMPB64"
    printf '%s' 'LmRwKSwKICAgICAgICAgICAgICAgICAgICAgICAgKSB7CiAgICAgICAgICAgICAgICAgICAgICAgICAgICBUZXh0KHRleHQgPSAi' >> "$TMPB64"
    printf '%s' '6YeN6K+VIikKICAgICAgICAgICAgICAgICAgICAgICAgfQogICAgICAgICAgICAgICAgICAgIH0KICAgICAgICAgICAgICAgIH0K' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgIGVsc2UgLT4gewogICAgICAgICAgICAgICAgICAgIExhenlWZXJ0aWNhbEdyaWQoCiAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgIGNvbHVtbnMgPSBHcmlkQ2VsbHMuRml4ZWQoMiksCiAgICAgICAgICAgICAgICAgICAgICAgIGNvbnRlbnRQ' >> "$TMPB64"
    printf '%s' 'YWRkaW5nID0gUGFkZGluZ1ZhbHVlcygxMi5kcCksCiAgICAgICAgICAgICAgICAgICAgICAgIGhvcml6b250YWxBcnJhbmdlbWVu' >> "$TMPB64"
    printf '%s' 'dCA9IEFycmFuZ2VtZW50LnNwYWNlZEJ5KDEwLmRwKSwKICAgICAgICAgICAgICAgICAgICAgICAgdmVydGljYWxBcnJhbmdlbWVu' >> "$TMPB64"
    printf '%s' 'dCA9IEFycmFuZ2VtZW50LnNwYWNlZEJ5KDEwLmRwKSwKICAgICAgICAgICAgICAgICAgICApIHsKICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgaXRlbXMoaXRlbXMsIGtleSA9IHsgaXQuaWQgfSkgeyBpdGVtIC0+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICBD' >> "$TMPB64"
    printf '%s' 'YXJkKHNoYXBlID0gUm91bmRlZENvcm5lclNoYXBlKDE0LmRwKSkgewogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIEJv' >> "$TMPB64"
    printf '%s' 'eCB7CiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIEFzeW5jSW1hZ2UoCiAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICBtb2RlbCA9IGl0ZW0udGh1bWIsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICBjb250ZW50RGVzY3JpcHRpb24gPSBudWxsLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgY29udGVu' >> "$TMPB64"
    printf '%s' 'dFNjYWxlID0gQ29udGVudFNjYWxlLkNyb3AsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBtb2RpZmll' >> "$TMPB64"
    printf '%s' 'ciA9IE1vZGlmaWVyCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgLmZpbGxNYXhXaWR0aCgpCiAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgLmFzcGVjdFJhdGlvKDAuNTZmKQogICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIC5jbGlja2FibGUgewogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICBXYWxscGFwZXJNYW5hZ2VyLmFwcGx5KGNvbnRleHQsIGl0ZW0ubGFyZ2UpCiAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIFRvYXN0Lm1ha2VUZXh0KGNvbnRleHQsICLlo4Hnurjlt7LlupTnlKgi' >> "$TMPB64"
    printf '%s' 'LCBUb2FzdC5MRU5HVEhfU0hPUlQpLnNob3coKQogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICBvbkJhY2soKQogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIH0sCiAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICkKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgQ29sdW1uKAogICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgbW9kaWZpZXIgPSBNb2RpZmllcgogICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgIC5hbGlnbihBbGlnbm1lbnQuQm90dG9tU3RhcnQpCiAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgLmZpbGxNYXhXaWR0aCgpCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgLmJhY2tncm91bmQoQ29sb3IuQmxhY2suY29weShhbHBoYSA9IDAuNjVmKSkKICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAucGFkZGluZyhob3Jpem9udGFsID0gOC5kcCwgdmVydGljYWwgPSA1LmRwKSwKICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgKSB7CiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBUZXh0KAog' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHRleHQgPSBpdGVtLnRpdGxlLAogICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHN0eWxlID0gTWF0ZXJpYWxUaGVtZS50eXBvZ3JhcGh5LmxhYmVsTWVkaXVt' >> "$TMPB64"
    printf '%s' 'LAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNvbG9yID0gQ29sb3IuV2hpdGUsCiAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgbWF4TGluZXMgPSAxLAogICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgIG92ZXJmbG93ID0gVGV4dE92ZXJmbG93LkVsbGlwc2lzLAogICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgKQogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgaWYgKGl0ZW0ud2lkdGgg' >> "$TMPB64"
    printf '%s' 'PiAwICYmIGl0ZW0uaGVpZ2h0ID4gMCkgewogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIFRleHQo' >> "$TMPB64"
    printf '%s' 'CiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHRleHQgPSAiJHtpdGVtLndpZHRofcOXJHtp' >> "$TMPB64"
    printf '%s' 'dGVtLmhlaWdodH0iLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBzdHlsZSA9IE1hdGVy' >> "$TMPB64"
    printf '%s' 'aWFsVGhlbWUudHlwb2dyYXBoeS5sYWJlbFNtYWxsLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICBjb2xvciA9IENvbG9yLldoaXRlLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICkKICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIH0KICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'fQogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIH0KICAgICAgICAgICAgICAgICAgICAgICAgICAgIH0KICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgfQogICAgICAgICAgICAgICAgICAgICAgICBpZiAoIWVuZFJlYWNoZWQpIHsKICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgIGl0ZW0oc3BhbiA9IHsgR3JpZEl0ZW1TcGFuKG1heExpbmVTcGFuKSB9KSB7CiAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgQnV0dG9uKAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBvbkNsaWNrID0geyBpZiAo' >> "$TMPB64"
    printf '%s' 'IWxvYWRpbmcpIGxvYWQoY2F0LCBwYWdlICsgMSwgdHJ1ZSkgfSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ZW5hYmxlZCA9ICFsb2FkaW5nLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBjb2xvcnMgPSBCdXR0b25EZWZh' >> "$TMPB64"
    printf '%s' 'dWx0cy5idXR0b25Db2xvcnMoCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBjb250YWluZXJDb2xvciA9' >> "$TMPB64"
    printf '%s' 'IG11c2ljQ29sb3JzKCkuY2FyZFNlY29uZGFyeSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNvbnRl' >> "$TMPB64"
    printf '%s' 'bnRDb2xvciA9IG11c2ljQ29sb3JzKCkudGV4dFByaW1hcnksCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICks' >> "$TMPB64"
    printf '%s' 'CiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIG1vZGlmaWVyID0gTW9kaWZpZXIKICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgIC5maWxsTWF4V2lkdGgoKQogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgLnBhZGRpbmcodmVydGljYWwgPSA0LmRwKSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICApIHsKICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgVGV4dCh0ZXh0ID0gaWYgKGxvYWRpbmcpICLliqDovb3kuK0uLi4iIGVsc2UgIuWK' >> "$TMPB64"
    printf '%s' 'oOi9veabtOWkmiIpCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgfQogICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'fQogICAgICAgICAgICAgICAgICAgICAgICB9CiAgICAgICAgICAgICAgICAgICAgfQogICAgICAgICAgICAgICAgfQogICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICB9CiAgICAgICAgfQogICAgfQp9Cg==' >> "$TMPB64"
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

print('[39] 全部补丁完成')
PYEOF39
echo "=== 39 wp5 完成 ==="
