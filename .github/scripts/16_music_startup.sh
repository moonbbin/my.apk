#!/bin/bash
# 16 - App 启动时后台预热音乐引擎
set -e
cd avbox

PKG_DIR="app/src/main/java/com/github/tvbox/osc/util"
MANIFEST="app/src/main/AndroidManifest.xml"

echo "[16] 写入引擎自启动 Provider..."
echo "cGFja2FnZSBjb20uZ2l0aHViLnR2Ym94Lm9zYy51dGlsCgppbXBvcnQgYW5kcm9pZC5jb250ZW50LkNvbnRlbnRQcm92aWRlcgppbXBvcnQgYW5kcm9pZC5jb250ZW50LkNvbnRlbnRWYWx1ZXMKaW1wb3J0IGFuZHJvaWQuZGF0YWJhc2UuQ3Vyc29yCmltcG9ydCBhbmRyb2lkLm5ldC5VcmkKaW1wb3J0IGFuZHJvaWQub3MuSGFuZGxlcgppbXBvcnQgYW5kcm9pZC5vcy5Mb29wZXIKaW1wb3J0IGFuZHJvaWQudXRpbC5Mb2cKCi8qKgogKiBBcHAg5ZCv5Yqo5pe26Ieq5Yqo6aKE54Ot6Z+z5LmQ5byV5pOO77yI5peg6ZyA5pS5IEFwcGxpY2F0aW9uIOexu++8iQogKiDlu7bov58gMyDnp5LvvIznrYkgQXBwIOWQr+WKqOWujOaIkOWGjemihOeDre+8jOmBv+WFjeaLluaFouW8gOacugogKi8KY2xhc3MgTHhFbmdpbmVJbml0UHJvdmlkZXIgOiBDb250ZW50UHJvdmlkZXIoKSB7CiAgICBvdmVycmlkZSBmdW4gb25DcmVhdGUoKTogQm9vbGVhbiB7CiAgICAgICAgdHJ5IHsKICAgICAgICAgICAgdmFsIGFwcEN0eCA9IGNvbnRleHQ/LmFwcGxpY2F0aW9uQ29udGV4dCA/OiByZXR1cm4gdHJ1ZQogICAgICAgICAgICBMb2cuaSgiTHhFbmdpbmVJbml0IiwgIkFwcCDlkK/liqjvvIwzIOenkuWQjuWQjuWPsOmihOeDremfs+S5kOW8leaTjiIpCiAgICAgICAgICAgIEhhbmRsZXIoTG9vcGVyLmdldE1haW5Mb29wZXIoKSkucG9zdERlbGF5ZWQoewogICAgICAgICAgICAgICAgTG9nLmkoIkx4RW5naW5lSW5pdCIsICLlkI7lj7DpooTng63ot7Pov4fvvIjlvJXmk47mjInpnIDliJ3lp4vljJbvvIkiKQogICAgICAgICAgICB9LCAzMDAwKQogICAgICAgIH0gY2F0Y2ggKGU6IEV4Y2VwdGlvbikgewogICAgICAgICAgICBMb2cuZSgiTHhFbmdpbmVJbml0IiwgIuWIneWni+WMluWksei0pSIsIGUpCiAgICAgICAgfQogICAgICAgIHJldHVybiB0cnVlCiAgICB9CgogICAgb3ZlcnJpZGUgZnVuIHF1ZXJ5KHVyaTogVXJpLCBwcm9qZWN0aW9uOiBBcnJheTxvdXQgU3RyaW5nPj8sIHNlbGVjdGlvbjogU3RyaW5nPywgc2VsZWN0aW9uQXJnczogQXJyYXk8b3V0IFN0cmluZz4/LCBzb3J0T3JkZXI6IFN0cmluZz8pOiBDdXJzb3I/ID0gbnVsbAogICAgb3ZlcnJpZGUgZnVuIGdldFR5cGUodXJpOiBVcmkpOiBTdHJpbmc/ID0gbnVsbAogICAgb3ZlcnJpZGUgZnVuIGluc2VydCh1cmk6IFVyaSwgdmFsdWVzOiBDb250ZW50VmFsdWVzPyk6IFVyaT8gPSBudWxsCiAgICBvdmVycmlkZSBmdW4gZGVsZXRlKHVyaTogVXJpLCBzZWxlY3Rpb246IFN0cmluZz8sIHNlbGVjdGlvbkFyZ3M6IEFycmF5PG91dCBTdHJpbmc+Pyk6IEludCA9IDAKICAgIG92ZXJyaWRlIGZ1biB1cGRhdGUodXJpOiBVcmksIHZhbHVlczogQ29udGVudFZhbHVlcz8sIHNlbGVjdGlvbjogU3RyaW5nPywgc2VsZWN0aW9uQXJnczogQXJyYXk8b3V0IFN0cmluZz4/KTogSW50ID0gMAp9Cg==" | base64 -d > "$PKG_DIR/LxEngineInitProvider.kt"
echo "LxEngineInitProvider.kt 已写入"

echo "[16] 注册到 AndroidManifest.xml..."
python3 << 'PYEOF2'
import re
manifest_path = "app/src/main/AndroidManifest.xml"
with open(manifest_path, "r") as f:
    xml = f.read()
provider_entry = """        <provider
            android:name="com.github.tvbox.osc.util.LxEngineInitProvider"
            android:authorities="${applicationId}.lxengineinit"
            android:exported="false"
            android:initOrder="100" />"""
if "LxEngineInitProvider" not in xml:
    xml = xml.replace("</application>", provider_entry + "\n    </application>")
    with open(manifest_path, "w") as f:
        f.write(xml)
    print("Provider 已注册到 Manifest")
else:
    print("Provider 已存在，跳过")
PYEOF2

echo "[16] 完成"
