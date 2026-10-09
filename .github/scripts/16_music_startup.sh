#!/bin/bash
# 16 - App 启动时后台预热音乐引擎
set -e
cd avbox

PKG_DIR="app/src/main/java/com/github/tvbox/osc/util"
MANIFEST="app/src/main/AndroidManifest.xml"

echo "[16] 写入引擎自启动 Provider..."
echo "cGFja2FnZSBjb20uZ2l0aHViLnR2Ym94Lm9zYy51dGlsCgppbXBvcnQgYW5kcm9pZC5jb250ZW50LkNvbnRlbnRQcm92aWRlcgppbXBvcnQgYW5kcm9pZC5jb250ZW50LkNvbnRlbnRWYWx1ZXMKaW1wb3J0IGFuZHJvaWQuZGF0YWJhc2UuQ3Vyc29yCmltcG9ydCBhbmRyb2lkLm5ldC5VcmkKaW1wb3J0IGFuZHJvaWQub3MuSGFuZGxlcgppbXBvcnQgYW5kcm9pZC5vcy5Mb29wZXIKaW1wb3J0IGFuZHJvaWQudXRpbC5Mb2cKaW1wb3J0IGNvbS5naXRodWIudHZib3gub3NjLnVpLmFjdGl2aXR5Lkx4RW5naW5lSG9sZGVyCgovKioKICogQXBwIOWQr+WKqOaXtuiHquWKqOmihOeDremfs+S5kOW8leaTju+8iOaXoOmcgOaUuSBBcHBsaWNhdGlvbiDnsbvvvIkKICog5bu26L+fIDMg56eS77yM562JIEFwcCDlkK/liqjlrozmiJDlho3pooTng63vvIzpgb/lhY3mi5bmhaLlvIDmnLoKICovCmNsYXNzIEx4RW5naW5lSW5pdFByb3ZpZGVyIDogQ29udGVudFByb3ZpZGVyKCkgewogICAgb3ZlcnJpZGUgZnVuIG9uQ3JlYXRlKCk6IEJvb2xlYW4gewogICAgICAgIHRyeSB7CiAgICAgICAgICAgIHZhbCBhcHBDdHggPSBjb250ZXh0Py5hcHBsaWNhdGlvbkNvbnRleHQgPzogcmV0dXJuIHRydWUKICAgICAgICAgICAgTG9nLmkoIkx4RW5naW5lSW5pdCIsICJBcHAg5ZCv5Yqo77yMMyDnp5LlkI7lkI7lj7DpooTng63pn7PkuZDlvJXmk44iKQogICAgICAgICAgICBIYW5kbGVyKExvb3Blci5nZXRNYWluTG9vcGVyKCkpLnBvc3REZWxheWVkKHsKICAgICAgICAgICAgICAgIHRyeSB7CiAgICAgICAgICAgICAgICAgICAgTHhFbmdpbmVIb2xkZXIud2FybVVwKGFwcEN0eCkKICAgICAgICAgICAgICAgICAgICBMb2cuaSgiTHhFbmdpbmVJbml0IiwgIuWQjuWPsOmihOeDreW3suinpuWPkSIpCiAgICAgICAgICAgICAgICB9IGNhdGNoIChlOiBFeGNlcHRpb24pIHsKICAgICAgICAgICAgICAgICAgICBMb2cuZSgiTHhFbmdpbmVJbml0IiwgIuWQjuWPsOmihOeDreWksei0pSIsIGUpCiAgICAgICAgICAgICAgICB9CiAgICAgICAgICAgIH0sIDMwMDApCiAgICAgICAgfSBjYXRjaCAoZTogRXhjZXB0aW9uKSB7CiAgICAgICAgICAgIExvZy5lKCJMeEVuZ2luZUluaXQiLCAi5Yid5aeL5YyW5aSx6LSlIiwgZSkKICAgICAgICB9CiAgICAgICAgcmV0dXJuIHRydWUKICAgIH0KCiAgICBvdmVycmlkZSBmdW4gcXVlcnkodXJpOiBVcmksIHByb2plY3Rpb246IEFycmF5PG91dCBTdHJpbmc+Pywgc2VsZWN0aW9uOiBTdHJpbmc/LCBzZWxlY3Rpb25BcmdzOiBBcnJheTxvdXQgU3RyaW5nPj8sIHNvcnRPcmRlcjogU3RyaW5nPyk6IEN1cnNvcj8gPSBudWxsCiAgICBvdmVycmlkZSBmdW4gZ2V0VHlwZSh1cmk6IFVyaSk6IFN0cmluZz8gPSBudWxsCiAgICBvdmVycmlkZSBmdW4gaW5zZXJ0KHVyaTogVXJpLCB2YWx1ZXM6IENvbnRlbnRWYWx1ZXM/KTogVXJpPyA9IG51bGwKICAgIG92ZXJyaWRlIGZ1biBkZWxldGUodXJpOiBVcmksIHNlbGVjdGlvbjogU3RyaW5nPywgc2VsZWN0aW9uQXJnczogQXJyYXk8b3V0IFN0cmluZz4/KTogSW50ID0gMAogICAgb3ZlcnJpZGUgZnVuIHVwZGF0ZSh1cmk6IFVyaSwgdmFsdWVzOiBDb250ZW50VmFsdWVzPywgc2VsZWN0aW9uOiBTdHJpbmc/LCBzZWxlY3Rpb25BcmdzOiBBcnJheTxvdXQgU3RyaW5nPj8pOiBJbnQgPSAwCn0K" | base64 -d > "$PKG_DIR/LxEngineInitProvider.kt"
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
