#!/bin/bash
set -e
# 38 - 内置 DSP 处理器（新功能，build.yml 调用行由用户手动加，建议排在 37 之后）
# 只写 EqDspProcessor.kt 一个文件：30Hz 高通 + 6 段 Biquad + 包络限制器，默认旁路，
# 异常闩锁透传。挂载与仲裁在 21 v34（sink 处理器数组 + applyEqFromPrefs 分流），开关在 37 v4。

cd "$(dirname "$0")/../.."
echo "=== 38 DSP 处理器 ==="

mkdir -p avbox/app/src/main/java/com/github/tvbox/osc/ui/activity

TMPB64=$(mktemp)
    printf '%s' 'cGFja2FnZSBjb20uZ2l0aHViLnR2Ym94Lm9zYy51aS5hY3Rpdml0eQoKaW1wb3J0IGFuZHJvaWR4' >> "$TMPB64"
    printf '%s' 'Lm1lZGlhMy5jb21tb24uQwppbXBvcnQgYW5kcm9pZHgubWVkaWEzLmNvbW1vbi5hdWRpby5BdWRp' >> "$TMPB64"
    printf '%s' 'b1Byb2Nlc3NvcgppbXBvcnQgYW5kcm9pZHgubWVkaWEzLmNvbW1vbi5hdWRpby5BdWRpb1Byb2Nl' >> "$TMPB64"
    printf '%s' 'c3Nvci5BdWRpb0Zvcm1hdAppbXBvcnQgYW5kcm9pZHgubWVkaWEzLmNvbW1vbi51dGlsLlVuc3Rh' >> "$TMPB64"
    printf '%s' 'YmxlQXBpCmltcG9ydCBqYXZhLm5pby5CeXRlQnVmZmVyCmltcG9ydCBqYXZhLm5pby5CeXRlT3Jk' >> "$TMPB64"
    printf '%s' 'ZXIKaW1wb3J0IGtvdGxpbi5tYXRoLlBJCmltcG9ydCBrb3RsaW4ubWF0aC5hYnMKaW1wb3J0IGtv' >> "$TMPB64"
    printf '%s' 'dGxpbi5tYXRoLmNvcwppbXBvcnQga290bGluLm1hdGguZXhwCmltcG9ydCBrb3RsaW4ubWF0aC5t' >> "$TMPB64"
    printf '%s' 'aW4KaW1wb3J0IGtvdGxpbi5tYXRoLnBvdwppbXBvcnQga290bGluLm1hdGguc2luCmltcG9ydCBr' >> "$TMPB64"
    printf '%s' 'b3RsaW4ubWF0aC5zcXJ0CgovLyBbMzhkc3AxXSDlhoXnva4gRFNQIOWdh+ihoeWkhOeQhuWZqO+8' >> "$TMPB64"
    printf '%s' 'mjMwSHog6auY6YCaICsgNiDmrrUgQmlxdWFk77yIUkJKIOWFrOW8j++8iSsg5YyF57uc6ZmQ5Yi2' >> "$TMPB64"
    printf '%s' '5Zmo44CCCi8vIOehrOaAp+WFnOW6le+8muKRoCBkc3BFbmFibGVkIOm7mOiupCBmYWxzZe+8jOS4' >> "$TMPB64"
    printf '%s' 'jeW8gOWQr+e7neS4jeaUuemfs++8m+KRoSDlpITnkIblvILluLjnq4vliLvpl6nplIEgaXNGYWls' >> "$TMPB64"
    printf '%s' 'ZWTvvIwKLy8g5LmL5ZCO5rC45LmF6YCP5Lyg4oCU4oCU5a6B5Y+vIEVRIOWkseaViO+8jOe7neS4' >> "$TMPB64"
    printf '%s' 'jeiDveayoeWjsOmfs+OAguivu+WPlui1sCBkdXBsaWNhdGXvvIzlvILluLjpgI/kvKDkuI3kuKLm' >> "$TMPB64"
    printf '%s' 'oLfjgIIKQFVuc3RhYmxlQXBpCmNsYXNzIEVxRHNwUHJvY2Vzc29yIDogQXVkaW9Qcm9jZXNzb3Ig' >> "$TMPB64"
    printf '%s' 'ewoKICAgIEBWb2xhdGlsZQogICAgdmFyIGRzcEVuYWJsZWQ6IEJvb2xlYW4gPSBmYWxzZQoKICAg' >> "$TMPB64"
    printf '%s' 'IEBWb2xhdGlsZQogICAgdmFyIGlzRmFpbGVkOiBCb29sZWFuID0gZmFsc2UKICAgICAgICBwcml2' >> "$TMPB64"
    printf '%s' 'YXRlIHNldAoKICAgIEBWb2xhdGlsZQogICAgcHJpdmF0ZSB2YXIgZ2FpbnNEYjogRmxvYXRBcnJh' >> "$TMPB64"
    printf '%s' 'eSA9IEZsb2F0QXJyYXkoNikKCiAgICBAVm9sYXRpbGUKICAgIHByaXZhdGUgdmFyIGNvbmZpZ1Zl' >> "$TMPB64"
    printf '%s' 'cnNpb246IEludCA9IDAKICAgIHByaXZhdGUgdmFyIGFwcGxpZWRWZXJzaW9uOiBJbnQgPSAtMQoK' >> "$TMPB64"
    printf '%s' 'ICAgIHByaXZhdGUgdmFyIGF1ZGlvRm9ybWF0OiBBdWRpb0Zvcm1hdCA9IEF1ZGlvRm9ybWF0Lk5P' >> "$TMPB64"
    printf '%s' 'VF9TRVQKICAgIHByaXZhdGUgdmFyIG91dHB1dEJ1ZmZlcjogQnl0ZUJ1ZmZlciA9IEF1ZGlvUHJv' >> "$TMPB64"
    printf '%s' 'Y2Vzc29yLkVNUFRZX0JVRkZFUgogICAgcHJpdmF0ZSB2YXIgd29ya0J1ZmZlcjogQnl0ZUJ1ZmZl' >> "$TMPB64"
    printf '%s' 'ciA9IEF1ZGlvUHJvY2Vzc29yLkVNUFRZX0JVRkZFUgogICAgcHJpdmF0ZSB2YXIgaW5wdXRFbmRl' >> "$TMPB64"
    printf '%s' 'ZDogQm9vbGVhbiA9IGZhbHNlCgogICAgcHJpdmF0ZSB2YXIgc2FtcGxlUmF0ZTogSW50ID0gNDQx' >> "$TMPB64"
    printf '%s' 'MDAKICAgIHByaXZhdGUgdmFyIGNoYW5uZWxzOiBJbnQgPSAyCiAgICBwcml2YXRlIHZhciBlbmNv' >> "$TMPB64"
    printf '%s' 'ZGluZzogSW50ID0gQy5FTkNPRElOR19QQ01fMTZCSVQKCiAgICAvLyDmu6Tms6Llmajnu4TvvJow' >> "$TMPB64"
    printf '%s' 'PTMwSHog6auY6YCa77yMMS4uNj3otoXkvY7popEv5L2O6aKRL+S4remikS/muIXmmbDluqYv6auY' >> "$TMPB64"
    printf '%s' '6aKRL+awm+WbtOaEnwogICAgcHJpdmF0ZSB2YWwgZmlsdGVycyA9IEFycmF5KDcpIHsgQmlxdWFk' >> "$TMPB64"
    printf '%s' 'KCkgfQogICAgcHJpdmF0ZSB2YWwgZnJhbWVCdWYgPSBGbG9hdEFycmF5KDgpCiAgICBwcml2YXRl' >> "$TMPB64"
    printf '%s' 'IHZhciBsaW1pdGVyR2FpbjogRmxvYXQgPSAxZgogICAgcHJpdmF0ZSB2YXIgcmVsZWFzZUNvZWY6' >> "$TMPB64"
    printf '%s' 'IEZsb2F0ID0gMC4wMDFmCgogICAgZnVuIHNldEdhaW5zKHN1YjogRmxvYXQsIGxvdzogRmxvYXQs' >> "$TMPB64"
    printf '%s' 'IG1pZDogRmxvYXQsIGNsYXJpdHk6IEZsb2F0LCBoaWdoOiBGbG9hdCwgYW1iOiBGbG9hdCkgewog' >> "$TMPB64"
    printf '%s' 'ICAgICAgIGdhaW5zRGIgPSBmbG9hdEFycmF5T2Yoc3ViLCBsb3csIG1pZCwgY2xhcml0eSwgaGln' >> "$TMPB64"
    printf '%s' 'aCwgYW1iKQogICAgICAgIGNvbmZpZ1ZlcnNpb24rKwogICAgfQoKICAgIG92ZXJyaWRlIGZ1biBj' >> "$TMPB64"
    printf '%s' 'b25maWd1cmUoaW5wdXRBdWRpb0Zvcm1hdDogQXVkaW9Gb3JtYXQpOiBBdWRpb0Zvcm1hdCB7CiAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgYXVkaW9Gb3JtYXQgPSBpbnB1dEF1ZGlvRm9ybWF0CiAgICAgICAgc2FtcGxlUmF0ZSA9' >> "$TMPB64"
    printf '%s' 'IGlucHV0QXVkaW9Gb3JtYXQuc2FtcGxlUmF0ZQogICAgICAgIGNoYW5uZWxzID0gaW5wdXRBdWRp' >> "$TMPB64"
    printf '%s' 'b0Zvcm1hdC5jaGFubmVsQ291bnQKICAgICAgICBlbmNvZGluZyA9IGlucHV0QXVkaW9Gb3JtYXQu' >> "$TMPB64"
    printf '%s' 'ZW5jb2RpbmcKICAgICAgICBhcHBsaWVkVmVyc2lvbiA9IC0xCiAgICAgICAgcmVsZWFzZUNvZWYg' >> "$TMPB64"
    printf '%s' 'PSBpZiAoc2FtcGxlUmF0ZSA+IDApIHsKICAgICAgICAgICAgKDEuMCAtIGV4cCgtMS4wIC8gKDAu' >> "$TMPB64"
    printf '%s' 'MTUgKiBzYW1wbGVSYXRlKSkpLnRvRmxvYXQoKQogICAgICAgIH0gZWxzZSB7CiAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'IDAuMDAxZgogICAgICAgIH0KICAgICAgICByZXNldFN0YXRlKCkKICAgICAgICByZXR1cm4gaW5w' >> "$TMPB64"
    printf '%s' 'dXRBdWRpb0Zvcm1hdAogICAgfQoKICAgIG92ZXJyaWRlIGZ1biBpc0FjdGl2ZSgpOiBCb29sZWFu' >> "$TMPB64"
    printf '%s' 'IHsKICAgICAgICByZXR1cm4gYXVkaW9Gb3JtYXQgIT0gQXVkaW9Gb3JtYXQuTk9UX1NFVCAmJgog' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICBjaGFubmVscyBpbiAxLi44ICYmCiAgICAgICAgICAgIChlbmNvZGluZyA9PSBD' >> "$TMPB64"
    printf '%s' 'LkVOQ09ESU5HX1BDTV8xNkJJVCB8fCBlbmNvZGluZyA9PSBDLkVOQ09ESU5HX1BDTV9GTE9BVCkg' >> "$TMPB64"
    printf '%s' 'JiYKICAgICAgICAgICAgc2FtcGxlUmF0ZSA+IDAKICAgIH0KCiAgICBvdmVycmlkZSBmdW4gcXVl' >> "$TMPB64"
    printf '%s' 'dWVJbnB1dChpbnB1dEJ1ZmZlcjogQnl0ZUJ1ZmZlcikgewogICAgICAgIHZhbCBzaXplID0gaW5w' >> "$TMPB64"
    printf '%s' 'dXRCdWZmZXIucmVtYWluaW5nKCkKICAgICAgICBpZiAoc2l6ZSA9PSAwKSB7CiAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'IG91dHB1dEJ1ZmZlciA9IEF1ZGlvUHJvY2Vzc29yLkVNUFRZX0JVRkZFUgogICAgICAgICAgICBy' >> "$TMPB64"
    printf '%s' 'ZXR1cm4KICAgICAgICB9CiAgICAgICAgaWYgKGlzRmFpbGVkIHx8ICFkc3BFbmFibGVkIHx8ICFp' >> "$TMPB64"
    printf '%s' 'c0FjdGl2ZSgpKSB7CiAgICAgICAgICAgIG91dHB1dEJ1ZmZlciA9IGlucHV0QnVmZmVyCiAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgIHJldHVybgogICAgICAgIH0KICAgICAgICB0cnkgewogICAgICAgICAgICBpZiAoYXBw' >> "$TMPB64"
    printf '%s' 'bGllZFZlcnNpb24gIT0gY29uZmlnVmVyc2lvbikgewogICAgICAgICAgICAgICAgdXBkYXRlQ29l' >> "$TMPB64"
    printf '%s' 'ZmZpY2llbnRzKCkKICAgICAgICAgICAgICAgIGFwcGxpZWRWZXJzaW9uID0gY29uZmlnVmVyc2lv' >> "$TMPB64"
    printf '%s' 'bgogICAgICAgICAgICB9CiAgICAgICAgICAgIGlmICh3b3JrQnVmZmVyLmNhcGFjaXR5KCkgPCBz' >> "$TMPB64"
    printf '%s' 'aXplKSB7CiAgICAgICAgICAgICAgICB3b3JrQnVmZmVyID0gQnl0ZUJ1ZmZlci5hbGxvY2F0ZURp' >> "$TMPB64"
    printf '%s' 'cmVjdChzaXplKS5vcmRlcihCeXRlT3JkZXIubmF0aXZlT3JkZXIoKSkKICAgICAgICAgICAgfSBl' >> "$TMPB64"
    printf '%s' 'bHNlIHsKICAgICAgICAgICAgICAgIHdvcmtCdWZmZXIuY2xlYXIoKQogICAgICAgICAgICB9CiAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgIHZhbCBzcmMgPSBpbnB1dEJ1ZmZlci5kdXBsaWNhdGUoKS5vcmRlcihCeXRlT3Jk' >> "$TMPB64"
    printf '%s' 'ZXIubmF0aXZlT3JkZXIoKSkKICAgICAgICAgICAgdmFsIHRvdGFsID0gaWYgKGVuY29kaW5nID09' >> "$TMPB64"
    printf '%s' 'IEMuRU5DT0RJTkdfUENNX0ZMT0FUKSB7CiAgICAgICAgICAgICAgICBwcm9jZXNzRmxvYXQoc3Jj' >> "$TMPB64"
    printf '%s' 'KQogICAgICAgICAgICB9IGVsc2UgewogICAgICAgICAgICAgICAgcHJvY2VzczE2KHNyYykKICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgfQogICAgICAgICAgICB3b3JrQnVmZmVyLmxpbWl0KHRvdGFsKQogICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICB3b3JrQnVmZmVyLnBvc2l0aW9uKDApCiAgICAgICAgICAgIG91dHB1dEJ1ZmZlciA9IHdvcmtC' >> "$TMPB64"
    printf '%s' 'dWZmZXIKICAgICAgICB9IGNhdGNoIChlOiBFeGNlcHRpb24pIHsKICAgICAgICAgICAgaXNGYWls' >> "$TMPB64"
    printf '%s' 'ZWQgPSB0cnVlCiAgICAgICAgICAgIG91dHB1dEJ1ZmZlciA9IGlucHV0QnVmZmVyCiAgICAgICAg' >> "$TMPB64"
    printf '%s' 'fQogICAgfQoKICAgIG92ZXJyaWRlIGZ1biBxdWV1ZUVuZE9mU3RyZWFtKCkgewogICAgICAgIGlu' >> "$TMPB64"
    printf '%s' 'cHV0RW5kZWQgPSB0cnVlCiAgICB9CgogICAgb3ZlcnJpZGUgZnVuIGdldE91dHB1dCgpOiBCeXRl' >> "$TMPB64"
    printf '%s' 'QnVmZmVyIHsKICAgICAgICB2YWwgb3V0ID0gb3V0cHV0QnVmZmVyCiAgICAgICAgb3V0cHV0QnVm' >> "$TMPB64"
    printf '%s' 'ZmVyID0gQXVkaW9Qcm9jZXNzb3IuRU1QVFlfQlVGRkVSCiAgICAgICAgcmV0dXJuIG91dAogICAg' >> "$TMPB64"
    printf '%s' 'fQoKICAgIG92ZXJyaWRlIGZ1biBpc0VuZGVkKCk6IEJvb2xlYW4gPSBpbnB1dEVuZGVkICYmIG91' >> "$TMPB64"
    printf '%s' 'dHB1dEJ1ZmZlciA9PT0gQXVkaW9Qcm9jZXNzb3IuRU1QVFlfQlVGRkVSCgogICAgb3ZlcnJpZGUg' >> "$TMPB64"
    printf '%s' 'ZnVuIGZsdXNoKCkgewogICAgICAgIG91dHB1dEJ1ZmZlciA9IEF1ZGlvUHJvY2Vzc29yLkVNUFRZ' >> "$TMPB64"
    printf '%s' 'X0JVRkZFUgogICAgICAgIGlucHV0RW5kZWQgPSBmYWxzZQogICAgICAgIHJlc2V0U3RhdGUoKQog' >> "$TMPB64"
    printf '%s' 'ICAgfQoKICAgIG92ZXJyaWRlIGZ1biByZXNldCgpIHsKICAgICAgICBmbHVzaCgpCiAgICAgICAg' >> "$TMPB64"
    printf '%s' 'YXVkaW9Gb3JtYXQgPSBBdWRpb0Zvcm1hdC5OT1RfU0VUCiAgICB9CgogICAgcHJpdmF0ZSBmdW4g' >> "$TMPB64"
    printf '%s' 'cmVzZXRTdGF0ZSgpIHsKICAgICAgICBmb3IgKGYgaW4gZmlsdGVycykgZi5yZXNldCgpCiAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgbGltaXRlckdhaW4gPSAxZgogICAgfQoKICAgIHByaXZhdGUgZnVuIHJ1bkNoYWluKGNoOiBJ' >> "$TMPB64"
    printf '%s' 'bnQsIHg6IEZsb2F0KTogRmxvYXQgewogICAgICAgIHZhciB5ID0geAogICAgICAgIGZvciAoZiBp' >> "$TMPB64"
    printf '%s' 'biBmaWx0ZXJzKSB5ID0gZi5wcm9jZXNzKGNoLCB5KQogICAgICAgIHJldHVybiB5CiAgICB9Cgog' >> "$TMPB64"
    printf '%s' 'ICAgLy8g6ZmQ5Yi25Zmo77ya5bin5bOw5YC86LaFIC0xLjVkQkZTIOeerOaXtuWOi+S4i++8jOS5' >> "$TMPB64"
    printf '%s' 'i+WQjue6piAxNTBtcyDnvJPmhaLph4rmlL7vvJvmnKvnq6/noazpkrPlhZzlupUKICAgIHByaXZh' >> "$TMPB64"
    printf '%s' 'dGUgZnVuIGZyYW1lR2FpbigpOiBGbG9hdCB7CiAgICAgICAgdmFsIHRocmVzaG9sZCA9IDAuODQx' >> "$TMPB64"
    printf '%s' 'NGYKICAgICAgICB2YXIgcGVhayA9IDBmCiAgICAgICAgZm9yIChjaCBpbiAwIHVudGlsIGNoYW5u' >> "$TMPB64"
    printf '%s' 'ZWxzKSB7CiAgICAgICAgICAgIHZhbCBhID0gYWJzKGZyYW1lQnVmW2NoXSkKICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'aWYgKGEgPiBwZWFrKSBwZWFrID0gYQogICAgICAgIH0KICAgICAgICB2YWwgdGFyZ2V0ID0gaWYg' >> "$TMPB64"
    printf '%s' 'KHBlYWsgPiB0aHJlc2hvbGQpIHRocmVzaG9sZCAvIHBlYWsgZWxzZSAxZgogICAgICAgIGxpbWl0' >> "$TMPB64"
    printf '%s' 'ZXJHYWluID0gaWYgKHRhcmdldCA8IGxpbWl0ZXJHYWluKSB7CiAgICAgICAgICAgIHRhcmdldAog' >> "$TMPB64"
    printf '%s' 'ICAgICAgIH0gZWxzZSB7CiAgICAgICAgICAgIGxpbWl0ZXJHYWluICsgKDFmIC0gbGltaXRlckdh' >> "$TMPB64"
    printf '%s' 'aW4pICogcmVsZWFzZUNvZWYKICAgICAgICB9CiAgICAgICAgcmV0dXJuIGxpbWl0ZXJHYWluCiAg' >> "$TMPB64"
    printf '%s' 'ICB9CgogICAgcHJpdmF0ZSBmdW4gcHJvY2VzczE2KHNyYzogQnl0ZUJ1ZmZlcik6IEludCB7CiAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgdmFsIGJ5dGVzUGVyRnJhbWUgPSAyICogY2hhbm5lbHMKICAgICAgICB2YWwgZnJhbWVz' >> "$TMPB64"
    printf '%s' 'ID0gc3JjLnJlbWFpbmluZygpIC8gYnl0ZXNQZXJGcmFtZQogICAgICAgIHZhbCBiYXNlID0gc3Jj' >> "$TMPB64"
    printf '%s' 'LnBvc2l0aW9uKCkKICAgICAgICBmb3IgKGYgaW4gMCB1bnRpbCBmcmFtZXMpIHsKICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgdmFsIGZyYW1lU3RhcnQgPSBiYXNlICsgZiAqIGJ5dGVzUGVyRnJhbWUKICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'Zm9yIChjaCBpbiAwIHVudGlsIGNoYW5uZWxzKSB7CiAgICAgICAgICAgICAgICB2YWwgcyA9IHNy' >> "$TMPB64"
    printf '%s' 'Yy5nZXRTaG9ydChmcmFtZVN0YXJ0ICsgY2ggKiAyKS50b0Zsb2F0KCkgLyAzMjc2OGYKICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgIGZyYW1lQnVmW2NoXSA9IHJ1bkNoYWluKGNoLCBzKQogICAgICAgICAgICB9CiAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgIHZhbCBnYWluID0gZnJhbWVHYWluKCkKICAgICAgICAgICAgZm9yIChjaCBpbiAw' >> "$TMPB64"
    printf '%s' 'IHVudGlsIGNoYW5uZWxzKSB7CiAgICAgICAgICAgICAgICB2YXIgeSA9IGZyYW1lQnVmW2NoXSAq' >> "$TMPB64"
    printf '%s' 'IGdhaW4KICAgICAgICAgICAgICAgIGlmICh5ID4gMC45OTlmKSB5ID0gMC45OTlmIGVsc2UgaWYg' >> "$TMPB64"
    printf '%s' 'KHkgPCAtMC45OTlmKSB5ID0gLTAuOTk5ZgogICAgICAgICAgICAgICAgdmFsIHYgPSAoeSAqIDMy' >> "$TMPB64"
    printf '%s' 'NzY3ZikudG9JbnQoKS5jb2VyY2VJbigtMzI3NjgsIDMyNzY3KQogICAgICAgICAgICAgICAgd29y' >> "$TMPB64"
    printf '%s' 'a0J1ZmZlci5wdXRTaG9ydCgoZiAqIGNoYW5uZWxzICsgY2gpICogMiwgdi50b1Nob3J0KCkpCiAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgIH0KICAgICAgICB9CiAgICAgICAgcmV0dXJuIGZyYW1lcyAqIGJ5dGVzUGVyRnJh' >> "$TMPB64"
    printf '%s' 'bWUKICAgIH0KCiAgICBwcml2YXRlIGZ1biBwcm9jZXNzRmxvYXQoc3JjOiBCeXRlQnVmZmVyKTog' >> "$TMPB64"
    printf '%s' 'SW50IHsKICAgICAgICB2YWwgYnl0ZXNQZXJGcmFtZSA9IDQgKiBjaGFubmVscwogICAgICAgIHZh' >> "$TMPB64"
    printf '%s' 'bCBmcmFtZXMgPSBzcmMucmVtYWluaW5nKCkgLyBieXRlc1BlckZyYW1lCiAgICAgICAgdmFsIGJh' >> "$TMPB64"
    printf '%s' 'c2UgPSBzcmMucG9zaXRpb24oKQogICAgICAgIGZvciAoZiBpbiAwIHVudGlsIGZyYW1lcykgewog' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICB2YWwgZnJhbWVTdGFydCA9IGJhc2UgKyBmICogYnl0ZXNQZXJGcmFtZQogICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICBmb3IgKGNoIGluIDAgdW50aWwgY2hhbm5lbHMpIHsKICAgICAgICAgICAgICAgIHZh' >> "$TMPB64"
    printf '%s' 'bCBzID0gc3JjLmdldEZsb2F0KGZyYW1lU3RhcnQgKyBjaCAqIDQpCiAgICAgICAgICAgICAgICBm' >> "$TMPB64"
    printf '%s' 'cmFtZUJ1ZltjaF0gPSBydW5DaGFpbihjaCwgcykKICAgICAgICAgICAgfQogICAgICAgICAgICB2' >> "$TMPB64"
    printf '%s' 'YWwgZ2FpbiA9IGZyYW1lR2FpbigpCiAgICAgICAgICAgIGZvciAoY2ggaW4gMCB1bnRpbCBjaGFu' >> "$TMPB64"
    printf '%s' 'bmVscykgewogICAgICAgICAgICAgICAgdmFyIHkgPSBmcmFtZUJ1ZltjaF0gKiBnYWluCiAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICBpZiAoeSA+IDAuOTk5ZikgeSA9IDAuOTk5ZiBlbHNlIGlmICh5IDwgLTAuOTk5' >> "$TMPB64"
    printf '%s' 'ZikgeSA9IC0wLjk5OWYKICAgICAgICAgICAgICAgIHdvcmtCdWZmZXIucHV0RmxvYXQoKGYgKiBj' >> "$TMPB64"
    printf '%s' 'aGFubmVscyArIGNoKSAqIDQsIHkpCiAgICAgICAgICAgIH0KICAgICAgICB9CiAgICAgICAgcmV0' >> "$TMPB64"
    printf '%s' 'dXJuIGZyYW1lcyAqIGJ5dGVzUGVyRnJhbWUKICAgIH0KCiAgICBwcml2YXRlIGZ1biB1cGRhdGVD' >> "$TMPB64"
    printf '%s' 'b2VmZmljaWVudHMoKSB7CiAgICAgICAgdmFsIHNyID0gc2FtcGxlUmF0ZS50b0RvdWJsZSgpCiAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgc2V0SGlnaHBhc3MoZmlsdGVyc1swXSwgMzAuMCwgMC43MDcxLCBzcikKICAgICAgICB2' >> "$TMPB64"
    printf '%s' 'YWwgZyA9IGdhaW5zRGIKICAgICAgICBzZXRMb3dzaGVsZihmaWx0ZXJzWzFdLCA2MC4wLCBnWzBd' >> "$TMPB64"
    printf '%s' 'LnRvRG91YmxlKCksIHNyKQogICAgICAgIHNldFBlYWtpbmcoZmlsdGVyc1syXSwgMjMwLjAsIDAu' >> "$TMPB64"
    printf '%s' 'OSwgZ1sxXS50b0RvdWJsZSgpLCBzcikKICAgICAgICBzZXRQZWFraW5nKGZpbHRlcnNbM10sIDkx' >> "$TMPB64"
    printf '%s' 'MC4wLCAwLjksIGdbMl0udG9Eb3VibGUoKSwgc3IpCiAgICAgICAgc2V0UGVha2luZyhmaWx0ZXJz' >> "$TMPB64"
    printf '%s' 'WzRdLCAzMDAwLjAsIDEuMSwgZ1szXS50b0RvdWJsZSgpLCBzcikKICAgICAgICBzZXRQZWFraW5n' >> "$TMPB64"
    printf '%s' 'KGZpbHRlcnNbNV0sIDE0MDAwLjAsIDAuNywgZ1s0XS50b0RvdWJsZSgpLCBzcikKICAgICAgICBz' >> "$TMPB64"
    printf '%s' 'ZXRQZWFraW5nKGZpbHRlcnNbNl0sIDE2MDAwLjAsIDAuNSwgZ1s1XS50b0RvdWJsZSgpLCBzcikK' >> "$TMPB64"
    printf '%s' 'ICAgIH0KCiAgICBwcml2YXRlIGZ1biBzZXRQZWFraW5nKGY6IEJpcXVhZCwgZnJlcTogRG91Ymxl' >> "$TMPB64"
    printf '%s' 'LCBxOiBEb3VibGUsIGdhaW5EYjogRG91YmxlLCBzcjogRG91YmxlKSB7CiAgICAgICAgdmFsIGZx' >> "$TMPB64"
    printf '%s' 'ID0gbWluKGZyZXEsIHNyICogMC40NSkKICAgICAgICB2YWwgYSA9IDEwLjAucG93KGdhaW5EYiAv' >> "$TMPB64"
    printf '%s' 'IDQwLjApCiAgICAgICAgdmFsIHcgPSAyLjAgKiBQSSAqIGZxIC8gc3IKICAgICAgICB2YWwgYWxw' >> "$TMPB64"
    printf '%s' 'aGEgPSBzaW4odykgLyAoMi4wICogcSkKICAgICAgICB2YWwgYyA9IGNvcyh3KQogICAgICAgIHZh' >> "$TMPB64"
    printf '%s' 'bCBiMCA9IDEuMCArIGFscGhhICogYQogICAgICAgIHZhbCBiMSA9IC0yLjAgKiBjCiAgICAgICAg' >> "$TMPB64"
    printf '%s' 'dmFsIGIyID0gMS4wIC0gYWxwaGEgKiBhCiAgICAgICAgdmFsIGEwID0gMS4wICsgYWxwaGEgLyBh' >> "$TMPB64"
    printf '%s' 'CiAgICAgICAgdmFsIGExID0gLTIuMCAqIGMKICAgICAgICB2YWwgYTIgPSAxLjAgLSBhbHBoYSAv' >> "$TMPB64"
    printf '%s' 'IGEKICAgICAgICBmLnNldCgoYjAgLyBhMCkudG9GbG9hdCgpLCAoYjEgLyBhMCkudG9GbG9hdCgp' >> "$TMPB64"
    printf '%s' 'LCAoYjIgLyBhMCkudG9GbG9hdCgpLCAoYTEgLyBhMCkudG9GbG9hdCgpLCAoYTIgLyBhMCkudG9G' >> "$TMPB64"
    printf '%s' 'bG9hdCgpKQogICAgfQoKICAgIHByaXZhdGUgZnVuIHNldExvd3NoZWxmKGY6IEJpcXVhZCwgZnJl' >> "$TMPB64"
    printf '%s' 'cTogRG91YmxlLCBnYWluRGI6IERvdWJsZSwgc3I6IERvdWJsZSkgewogICAgICAgIHZhbCBmcSA9' >> "$TMPB64"
    printf '%s' 'IG1pbihmcmVxLCBzciAqIDAuNDUpCiAgICAgICAgdmFsIGEgPSAxMC4wLnBvdyhnYWluRGIgLyA0' >> "$TMPB64"
    printf '%s' 'MC4wKQogICAgICAgIHZhbCB3ID0gMi4wICogUEkgKiBmcSAvIHNyCiAgICAgICAgdmFsIGMgPSBj' >> "$TMPB64"
    printf '%s' 'b3ModykKICAgICAgICB2YWwgYWxwaGEgPSBzaW4odykgLyAyLjAgKiBzcXJ0KDIuMCkKICAgICAg' >> "$TMPB64"
    printf '%s' 'ICB2YWwgc3FBID0gc3FydChhKQogICAgICAgIHZhbCBiMCA9IGEgKiAoKGEgKyAxKSAtIChhIC0g' >> "$TMPB64"
    printf '%s' 'MSkgKiBjICsgMiAqIHNxQSAqIGFscGhhKQogICAgICAgIHZhbCBiMSA9IDIgKiBhICogKChhIC0g' >> "$TMPB64"
    printf '%s' 'MSkgLSAoYSArIDEpICogYykKICAgICAgICB2YWwgYjIgPSBhICogKChhICsgMSkgLSAoYSAtIDEp' >> "$TMPB64"
    printf '%s' 'ICogYyAtIDIgKiBzcUEgKiBhbHBoYSkKICAgICAgICB2YWwgYTAgPSAoYSArIDEpICsgKGEgLSAx' >> "$TMPB64"
    printf '%s' 'KSAqIGMgKyAyICogc3FBICogYWxwaGEKICAgICAgICB2YWwgYTEgPSAtMi4wICogKChhIC0gMSkg' >> "$TMPB64"
    printf '%s' 'KyAoYSArIDEpICogYykKICAgICAgICB2YWwgYTIgPSAoYSArIDEpICsgKGEgLSAxKSAqIGMgLSAy' >> "$TMPB64"
    printf '%s' 'ICogc3FBICogYWxwaGEKICAgICAgICBmLnNldCgoYjAgLyBhMCkudG9GbG9hdCgpLCAoYjEgLyBh' >> "$TMPB64"
    printf '%s' 'MCkudG9GbG9hdCgpLCAoYjIgLyBhMCkudG9GbG9hdCgpLCAoYTEgLyBhMCkudG9GbG9hdCgpLCAo' >> "$TMPB64"
    printf '%s' 'YTIgLyBhMCkudG9GbG9hdCgpKQogICAgfQoKICAgIHByaXZhdGUgZnVuIHNldEhpZ2hwYXNzKGY6' >> "$TMPB64"
    printf '%s' 'IEJpcXVhZCwgZnJlcTogRG91YmxlLCBxOiBEb3VibGUsIHNyOiBEb3VibGUpIHsKICAgICAgICB2' >> "$TMPB64"
    printf '%s' 'YWwgZnEgPSBtaW4oZnJlcSwgc3IgKiAwLjQ1KQogICAgICAgIHZhbCB3ID0gMi4wICogUEkgKiBm' >> "$TMPB64"
    printf '%s' 'cSAvIHNyCiAgICAgICAgdmFsIGMgPSBjb3ModykKICAgICAgICB2YWwgYWxwaGEgPSBzaW4odykg' >> "$TMPB64"
    printf '%s' 'LyAoMi4wICogcSkKICAgICAgICB2YWwgYjAgPSAoMS4wICsgYykgLyAyLjAKICAgICAgICB2YWwg' >> "$TMPB64"
    printf '%s' 'YjEgPSAtKDEuMCArIGMpCiAgICAgICAgdmFsIGIyID0gKDEuMCArIGMpIC8gMi4wCiAgICAgICAg' >> "$TMPB64"
    printf '%s' 'dmFsIGEwID0gMS4wICsgYWxwaGEKICAgICAgICB2YWwgYTEgPSAtMi4wICogYwogICAgICAgIHZh' >> "$TMPB64"
    printf '%s' 'bCBhMiA9IDEuMCAtIGFscGhhCiAgICAgICAgZi5zZXQoKGIwIC8gYTApLnRvRmxvYXQoKSwgKGIx' >> "$TMPB64"
    printf '%s' 'IC8gYTApLnRvRmxvYXQoKSwgKGIyIC8gYTApLnRvRmxvYXQoKSwgKGExIC8gYTApLnRvRmxvYXQo' >> "$TMPB64"
    printf '%s' 'KSwgKGEyIC8gYTApLnRvRmxvYXQoKSkKICAgIH0KCiAgICBwcml2YXRlIGNsYXNzIEJpcXVhZCB7' >> "$TMPB64"
    printf '%s' 'CiAgICAgICAgcHJpdmF0ZSB2YXIgYjAgPSAxZgogICAgICAgIHByaXZhdGUgdmFyIGIxID0gMGYK' >> "$TMPB64"
    printf '%s' 'ICAgICAgICBwcml2YXRlIHZhciBiMiA9IDBmCiAgICAgICAgcHJpdmF0ZSB2YXIgYTEgPSAwZgog' >> "$TMPB64"
    printf '%s' 'ICAgICAgIHByaXZhdGUgdmFyIGEyID0gMGYKICAgICAgICBwcml2YXRlIHZhbCB4MSA9IEZsb2F0' >> "$TMPB64"
    printf '%s' 'QXJyYXkoOCkKICAgICAgICBwcml2YXRlIHZhbCB4MiA9IEZsb2F0QXJyYXkoOCkKICAgICAgICBw' >> "$TMPB64"
    printf '%s' 'cml2YXRlIHZhbCB5MSA9IEZsb2F0QXJyYXkoOCkKICAgICAgICBwcml2YXRlIHZhbCB5MiA9IEZs' >> "$TMPB64"
    printf '%s' 'b2F0QXJyYXkoOCkKCiAgICAgICAgZnVuIHNldChuYjA6IEZsb2F0LCBuYjE6IEZsb2F0LCBuYjI6' >> "$TMPB64"
    printf '%s' 'IEZsb2F0LCBuYTE6IEZsb2F0LCBuYTI6IEZsb2F0KSB7CiAgICAgICAgICAgIGIwID0gbmIwOyBi' >> "$TMPB64"
    printf '%s' 'MSA9IG5iMTsgYjIgPSBuYjI7IGExID0gbmExOyBhMiA9IG5hMgogICAgICAgIH0KCiAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ZnVuIHByb2Nlc3MoY2g6IEludCwgeDogRmxvYXQpOiBGbG9hdCB7CiAgICAgICAgICAgIHZhbCB5' >> "$TMPB64"
    printf '%s' 'ID0gYjAgKiB4ICsgYjEgKiB4MVtjaF0gKyBiMiAqIHgyW2NoXSAtIGExICogeTFbY2hdIC0gYTIg' >> "$TMPB64"
    printf '%s' 'KiB5MltjaF0KICAgICAgICAgICAgeDJbY2hdID0geDFbY2hdOyB4MVtjaF0gPSB4CiAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgIHkyW2NoXSA9IHkxW2NoXTsgeTFbY2hdID0geQogICAgICAgICAgICByZXR1cm4geQogICAg' >> "$TMPB64"
    printf '%s' 'ICAgIH0KCiAgICAgICAgZnVuIHJlc2V0KCkgewogICAgICAgICAgICB4MS5maWxsKDBmKTsgeDIu' >> "$TMPB64"
    printf '%s' 'ZmlsbCgwZik7IHkxLmZpbGwoMGYpOyB5Mi5maWxsKDBmKQogICAgICAgIH0KICAgIH0KfQo=' >> "$TMPB64"
base64 -d "$TMPB64" > avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/EqDspProcessor.kt
rm -f "$TMPB64"
grep -q 'class EqDspProcessor' avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/EqDspProcessor.kt || { echo "X 38 DSP 文件写入失败"; exit 1; }
echo "OK EqDspProcessor.kt 已写入"
echo "=== 38 完成 ==="

# === 38 v2: DSP 自愈包（NaN 消毒 + 输出看门狗 + 声道门 + 超时熔断 + attack 平滑 + 去 duplicate + 值守卫） ===
python3 << 'PYEOF38B'
import sys

P38 = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/EqDspProcessor.kt"
with open(P38, encoding="utf-8") as f:
    c = f.read()

if "[38v2]" in c:
    print("38 v2: 已应用，跳过")
    sys.exit(0)

def rep(old, new, tag):
    global c
    if c.count(old) != 1:
        print(f"X 38 v2 锚点计数异常 [{tag}]: {c.count(old)}")
        sys.exit(1)
    c = c.replace(old, new)
    print(f"  OK {tag}")

rep("""    private var limiterGain: Float = 1f
    private var releaseCoef: Float = 0.001f""",
    """    private var limiterGain: Float = 1f
    private var releaseCoef: Float = 0.001f
    private var attackCoef: Float = 0.5f // [38v2]
    private var silentStrikes: Int = 0 // [38v2]
    private var slowStrikes: Int = 0 // [38v2]
    private var inputPeak: Float = 0f // [38v2]
    private var outputPeak: Float = 0f // [38v2]""",
    "熔断/看门狗字段")

rep("""    fun setGains(sub: Float, low: Float, mid: Float, clarity: Float, high: Float, amb: Float) {
        gainsDb = floatArrayOf(sub, low, mid, clarity, high, amb)
        configVersion++
    }""",
    """    fun setGains(sub: Float, low: Float, mid: Float, clarity: Float, high: Float, amb: Float) {
        val ng = floatArrayOf(sub, low, mid, clarity, high, amb)
        if (!ng.contentEquals(gainsDb)) { // [38v2] 值守卫：没变不重算系数
            gainsDb = ng
            configVersion++
        }
    }""",
    "setGains 值守卫")

rep("""        if (isFailed || !dspEnabled || !isActive()) {
            outputBuffer = inputBuffer
            return
        }""",
    """        if (isFailed || !dspEnabled || !isActive() || channels != 2) { // [38v2] 声道门：仅双声道走 DSP
            outputBuffer = inputBuffer
            return
        }""",
    "声道门")

rep("""            val src = inputBuffer.duplicate().order(ByteOrder.nativeOrder())
            val total = if (encoding == C.ENCODING_PCM_FLOAT) {
                processFloat(src)
            } else {
                process16(src)
            }
            workBuffer.limit(total)""",
    """            inputPeak = 0f
            outputPeak = 0f
            val t0 = System.nanoTime() // [38v2] 超时熔断计时（绝对索引直读，去掉多余 duplicate）
            val total = if (encoding == C.ENCODING_PCM_FLOAT) {
                processFloat(inputBuffer)
            } else {
                process16(inputBuffer)
            }
            // [38v2] 输出看门狗：输入有声而输出全零/空，连续 2 次闩锁透传——持续静音结构性不可能
            if (total <= 0 || (inputPeak > 0.02f && outputPeak == 0f)) {
                silentStrikes++
                if (silentStrikes >= 2) {
                    isFailed = true
                    outputBuffer = inputBuffer
                    return
                }
            } else {
                silentStrikes = 0
            }
            // [38v2] 超时熔断：单次处理慢于该 buffer 自身时长，连续 2 次闩锁
            val frames = total / (if (encoding == C.ENCODING_PCM_FLOAT) 4 else 2) / channels
            val budgetNs = if (sampleRate > 0) frames * 1_000_000_000L / sampleRate else 20_000_000L
            if (System.nanoTime() - t0 > budgetNs) {
                slowStrikes++
                if (slowStrikes >= 2) {
                    isFailed = true
                    outputBuffer = inputBuffer
                    return
                }
            } else {
                slowStrikes = 0
            }
            workBuffer.limit(total)""",
    "看门狗+熔断+去 duplicate")

rep("""    private fun runChain(ch: Int, x: Float): Float {
        var y = x
        for (f in filters) y = f.process(ch, y)
        return y
    }""",
    """    private fun runChain(ch: Int, x: Float): Float {
        var y = x
        for (f in filters) {
            y = f.process(ch, y)
            if (!y.isFinite()) { // [38v2] NaN/Inf 消毒：清该级状态、用原样顶替，污染活不过一个采样
                f.reset()
                y = x
            }
        }
        return y
    }""",
    "runChain NaN 消毒")

rep("""        limiterGain = if (target < limiterGain) {
            target
        } else {""",
    """        limiterGain = if (target < limiterGain) {
            limiterGain + (target - limiterGain) * attackCoef // [38v2] attack 一阶平滑，消增益台阶哒声
        } else {""",
    "attack 平滑")

rep("""                val s = src.getShort(frameStart + ch * 2).toFloat() / 32768f
                frameBuf[ch] = runChain(ch, s)""",
    """                val s = src.getShort(frameStart + ch * 2).toFloat() / 32768f
                val aIn = abs(s) // [38v2] 看门狗输入峰值
                if (aIn > inputPeak) inputPeak = aIn
                frameBuf[ch] = runChain(ch, s)""",
    "16 位输入峰值")

rep("""                var y = frameBuf[ch] * gain
                if (y > 0.999f) y = 0.999f else if (y < -0.999f) y = -0.999f
                val v = (y * 32767f).toInt().coerceIn(-32768, 32767)""",
    """                var y = frameBuf[ch] * gain
                if (y > 0.999f) y = 0.999f else if (y < -0.999f) y = -0.999f
                val aOut = abs(y) // [38v2] 看门狗输出峰值
                if (aOut > outputPeak) outputPeak = aOut
                val v = (y * 32767f).toInt().coerceIn(-32768, 32767)""",
    "16 位输出峰值")

rep("""                val s = src.getFloat(frameStart + ch * 4)
                frameBuf[ch] = runChain(ch, s)""",
    """                val s = src.getFloat(frameStart + ch * 4)
                val aIn = abs(s) // [38v2] 看门狗输入峰值
                if (aIn > inputPeak) inputPeak = aIn
                frameBuf[ch] = runChain(ch, s)""",
    "float 输入峰值")

rep("""                var y = frameBuf[ch] * gain
                if (y > 0.999f) y = 0.999f else if (y < -0.999f) y = -0.999f
                workBuffer.putFloat((f * channels + ch) * 4, y)""",
    """                var y = frameBuf[ch] * gain
                if (y > 0.999f) y = 0.999f else if (y < -0.999f) y = -0.999f
                val aOut = abs(y) // [38v2] 看门狗输出峰值
                if (aOut > outputPeak) outputPeak = aOut
                workBuffer.putFloat((f * channels + ch) * 4, y)""",
    "float 输出峰值")

assert "[38v2]" in c and "isFinite" in c
with open(P38, "w", encoding="utf-8") as f:
    f.write(c)
print("OK 38 v2 完成")
PYEOF38B

echo "=== 38 v2 完成 ==="
