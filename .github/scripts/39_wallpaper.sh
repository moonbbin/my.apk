#!/bin/bash
# 39_wallpaper.sh [39wp2] 自定义壁纸：Manager(图/渐变双模式) + 设置页 + 在线壁纸库 + MusicHome 根注入(壁纸层+Scrim) + 六页根透出
set -e
cd "$(dirname "$0")/../.." 2>/dev/null || true
mkdir -p avbox/app/src/main/java/com/github/tvbox/osc/ui/activity
TMPB64=$(mktemp)
    printf '%s' 'cGFja2FnZSBjb20uZ2l0aHViLnR2Ym94Lm9zYy51aS5hY3Rpdml0eQoKaW1wb3J0IGFuZHJvaWQuY29udGVudC5Db250ZXh0Cmlt' >> "$TMPB64"
    printf '%s' 'cG9ydCBhbmRyb2lkeC5jb21wb3NlLnJ1bnRpbWUuQ29tcG9zYWJsZQppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5ydW50aW1lLmNv' >> "$TMPB64"
    printf '%s' 'bGxlY3RBc1N0YXRlCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLnJ1bnRpbWUuZ2V0VmFsdWUKaW1wb3J0IGtvdGxpbnguY29yb3V0' >> "$TMPB64"
    printf '%s' 'aW5lcy5mbG93Lk11dGFibGVTdGF0ZUZsb3cKaW1wb3J0IGtvdGxpbnguY29yb3V0aW5lcy5mbG93LlN0YXRlRmxvdwoKLy8gWzM5' >> "$TMPB64"
    printf '%s' 'd3AxXSDoh6rlrprkuYnlo4HnurjvvJrnirbmgIEgKyDmjIHkuYXljJbvvIjojIPlvI/lkIwgTXVzaWNUaGVtZU1hbmFnZXLvvJpv' >> "$TMPB64"
    printf '%s' 'YmplY3QgKyBwcmVmcyArIFN0YXRlRmxvd++8iQpvYmplY3QgV2FsbHBhcGVyTWFuYWdlciB7CiAgICBwcml2YXRlIGNvbnN0IHZh' >> "$TMPB64"
    printf '%s' 'bCBQUkVGUyA9ICJ3YWxscGFwZXJfcHJlZnMiCiAgICBwcml2YXRlIGNvbnN0IHZhbCBLRVlfRU5BQkxFRCA9ICJlbmFibGVXYWxs' >> "$TMPB64"
    printf '%s' 'cGFwZXIiCiAgICBwcml2YXRlIGNvbnN0IHZhbCBLRVlfVVJMID0gIndhbGxwYXBlclVybCIKICAgIHByaXZhdGUgY29uc3QgdmFs' >> "$TMPB64"
    printf '%s' 'IEtFWV9ISVNUT1JZID0gIndhbGxwYXBlckhpc3RvcnkiCiAgICBwcml2YXRlIGNvbnN0IHZhbCBLRVlfTU9ERSA9ICJ3YWxscGFw' >> "$TMPB64"
    printf '%s' 'ZXJNb2RlIgogICAgcHJpdmF0ZSBjb25zdCB2YWwgS0VZX0dSQURJRU5UID0gImdyYWRpZW50Q29sb3JzIgoKICAgIGRhdGEgY2xh' >> "$TMPB64"
    printf '%s' 'c3MgU3RhdGUoCiAgICAgICAgdmFsIGVuYWJsZWQ6IEJvb2xlYW4gPSBmYWxzZSwKICAgICAgICB2YWwgdXJsOiBTdHJpbmcgPSAi' >> "$TMPB64"
    printf '%s' 'IiwKICAgICAgICB2YWwgaGlzdG9yeTogTGlzdDxTdHJpbmc+ID0gZW1wdHlMaXN0KCksCiAgICAgICAgdmFsIG1vZGU6IFN0cmlu' >> "$TMPB64"
    printf '%s' 'ZyA9ICJpbWFnZSIsCiAgICAgICAgdmFsIGdyYWRpZW50OiBTdHJpbmcgPSAiIiwKICAgICkKCiAgICBwcml2YXRlIHZhbCBfc3Rh' >> "$TMPB64"
    printf '%s' 'dGUgPSBNdXRhYmxlU3RhdGVGbG93KFN0YXRlKCkpCiAgICB2YWwgc3RhdGU6IFN0YXRlRmxvdzxTdGF0ZT4gPSBfc3RhdGUKCiAg' >> "$TMPB64"
    printf '%s' 'ICBwcml2YXRlIGZ1biBwcmVmcyhjdHg6IENvbnRleHQpID0gY3R4LmdldFNoYXJlZFByZWZlcmVuY2VzKFBSRUZTLCBDb250ZXh0' >> "$TMPB64"
    printf '%s' 'Lk1PREVfUFJJVkFURSkKCiAgICBmdW4gaW5pdChjdHg6IENvbnRleHQpIHsKICAgICAgICB0cnkgewogICAgICAgICAgICB2YWwg' >> "$TMPB64"
    printf '%s' 'cCA9IHByZWZzKGN0eCkKICAgICAgICAgICAgdmFsIGhpc3QgPSAocC5nZXRTdHJpbmcoS0VZX0hJU1RPUlksICIiKSA/OiAiIiku' >> "$TMPB64"
    printf '%s' 'c3BsaXQoIlxuIikuZmlsdGVyIHsgaXQuaXNOb3RCbGFuaygpIH0KICAgICAgICAgICAgX3N0YXRlLnZhbHVlID0gU3RhdGUoCiAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICBlbmFibGVkID0gcC5nZXRCb29sZWFuKEtFWV9FTkFCTEVELCBmYWxzZSksCiAgICAgICAgICAgICAgICB1' >> "$TMPB64"
    printf '%s' 'cmwgPSBwLmdldFN0cmluZyhLRVlfVVJMLCAiIikgPzogIiIsCiAgICAgICAgICAgICAgICBoaXN0b3J5ID0gaGlzdCwKICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgIG1vZGUgPSBwLmdldFN0cmluZyhLRVlfTU9ERSwgImltYWdlIikgPzogImltYWdlIiwKICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'IGdyYWRpZW50ID0gcC5nZXRTdHJpbmcoS0VZX0dSQURJRU5ULCAiIikgPzogIiIsCiAgICAgICAgICAgICkKICAgICAgICB9IGNh' >> "$TMPB64"
    printf '%s' 'dGNoIChlOiBFeGNlcHRpb24pIHsKICAgICAgICAgICAgYW5kcm9pZC51dGlsLkxvZy53KCJXYWxscGFwZXIiLCAi5aOB57q454q2' >> "$TMPB64"
    printf '%s' '5oCB6K+75Y+W5aSx6LSlIiwgZSkKICAgICAgICB9CiAgICB9CgogICAgZnVuIHNldEVuYWJsZWQoY3R4OiBDb250ZXh0LCBvbjog' >> "$TMPB64"
    printf '%s' 'Qm9vbGVhbikgewogICAgICAgIHRyeSB7CiAgICAgICAgICAgIHByZWZzKGN0eCkuZWRpdCgpLnB1dEJvb2xlYW4oS0VZX0VOQUJM' >> "$TMPB64"
    printf '%s' 'RUQsIG9uKS5hcHBseSgpCiAgICAgICAgfSBjYXRjaCAoZTogRXhjZXB0aW9uKSB7CiAgICAgICAgICAgIGFuZHJvaWQudXRpbC5M' >> "$TMPB64"
    printf '%s' 'b2cudygiV2FsbHBhcGVyIiwgIuWjgee6uOW8gOWFs+S/neWtmOWksei0pSIsIGUpCiAgICAgICAgfQogICAgICAgIF9zdGF0ZS52' >> "$TMPB64"
    printf '%s' 'YWx1ZSA9IF9zdGF0ZS52YWx1ZS5jb3B5KGVuYWJsZWQgPSBvbikKICAgIH0KCiAgICAvLyDlupTnlKjkuIDlvKDlo4HnurjvvIhV' >> "$TMPB64"
    printf '%s' 'Ukwg5oiW5pys5ZywIFVSSe+8ie+8muWtmOS4uuW9k+WJjeOAgemhtuWIsOWOhuWPsuacgOWJje+8iOWOu+mHjeOAgeS4iumZkCA2' >> "$TMPB64"
    printf '%s' '77yJ44CB6Ieq5Yqo5byA5ZCvCiAgICBmdW4gYXBwbHkoY3R4OiBDb250ZXh0LCB1cmw6IFN0cmluZykgewogICAgICAgIHZhbCB1' >> "$TMPB64"
    printf '%s' 'ID0gdXJsLnRyaW0oKQogICAgICAgIGlmICh1LmlzQmxhbmsoKSkgcmV0dXJuCiAgICAgICAgdmFsIGhpc3QgPSAobGlzdE9mKHUp' >> "$TMPB64"
    printf '%s' 'ICsgX3N0YXRlLnZhbHVlLmhpc3RvcnkuZmlsdGVyIHsgaXQgIT0gdSB9KS50YWtlKDYpCiAgICAgICAgdHJ5IHsKICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgcHJlZnMoY3R4KS5lZGl0KCkKICAgICAgICAgICAgICAgIC5wdXRTdHJpbmcoS0VZX1VSTCwgdSkKICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'IC5wdXRTdHJpbmcoS0VZX0hJU1RPUlksIGhpc3Quam9pblRvU3RyaW5nKCJcbiIpKQogICAgICAgICAgICAgICAgLnB1dFN0cmlu' >> "$TMPB64"
    printf '%s' 'ZyhLRVlfTU9ERSwgImltYWdlIikKICAgICAgICAgICAgICAgIC5wdXRCb29sZWFuKEtFWV9FTkFCTEVELCB0cnVlKQogICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgLmFwcGx5KCkKICAgICAgICB9IGNhdGNoIChlOiBFeGNlcHRpb24pIHsKICAgICAgICAgICAgYW5kcm9pZC51dGls' >> "$TMPB64"
    printf '%s' 'LkxvZy53KCJXYWxscGFwZXIiLCAi5aOB57q45bqU55So5L+d5a2Y5aSx6LSlIiwgZSkKICAgICAgICB9CiAgICAgICAgX3N0YXRl' >> "$TMPB64"
    printf '%s' 'LnZhbHVlID0gX3N0YXRlLnZhbHVlLmNvcHkoZW5hYmxlZCA9IHRydWUsIHVybCA9IHUsIGhpc3RvcnkgPSBoaXN0LCBtb2RlID0g' >> "$TMPB64"
    printf '%s' 'ImltYWdlIikKICAgIH0KCiAgICAvLyBbMzl3cDJdIOW6lOeUqOa4kOWPmOiDjOaZrzog5a2Y5Lik5LiqIEhleCjpgJflj7fmi7zm' >> "$TMPB64"
    printf '%s' 'jqUpICsg5YiH5qih5byPICsg6Ieq5Yqo5byA5ZCvCiAgICBmdW4gYXBwbHlHcmFkaWVudChjdHg6IENvbnRleHQsIGhleFBhaXI6' >> "$TMPB64"
    printf '%s' 'IFN0cmluZykgewogICAgICAgIHZhbCBnID0gaGV4UGFpci50cmltKCkKICAgICAgICBpZiAoZy5pc0JsYW5rKCkpIHJldHVybgog' >> "$TMPB64"
    printf '%s' 'ICAgICAgIHRyeSB7CiAgICAgICAgICAgIHByZWZzKGN0eCkuZWRpdCgpCiAgICAgICAgICAgICAgICAucHV0U3RyaW5nKEtFWV9H' >> "$TMPB64"
    printf '%s' 'UkFESUVOVCwgZykKICAgICAgICAgICAgICAgIC5wdXRTdHJpbmcoS0VZX01PREUsICJncmFkaWVudCIpCiAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAucHV0Qm9vbGVhbihLRVlfRU5BQkxFRCwgdHJ1ZSkKICAgICAgICAgICAgICAgIC5hcHBseSgpCiAgICAgICAgfSBjYXRjaCAo' >> "$TMPB64"
    printf '%s' 'ZTogRXhjZXB0aW9uKSB7CiAgICAgICAgICAgIGFuZHJvaWQudXRpbC5Mb2cudygiV2FsbHBhcGVyIiwgIua4kOWPmOW6lOeUqOS/' >> "$TMPB64"
    printf '%s' 'neWtmOWksei0pSIsIGUpCiAgICAgICAgfQogICAgICAgIF9zdGF0ZS52YWx1ZSA9IF9zdGF0ZS52YWx1ZS5jb3B5KGVuYWJsZWQg' >> "$TMPB64"
    printf '%s' 'PSB0cnVlLCBtb2RlID0gImdyYWRpZW50IiwgZ3JhZGllbnQgPSBnKQogICAgfQoKICAgIGZ1biByZW1vdmVIaXN0b3J5KGN0eDog' >> "$TMPB64"
    printf '%s' 'Q29udGV4dCwgdXJsOiBTdHJpbmcpIHsKICAgICAgICB2YWwgaGlzdCA9IF9zdGF0ZS52YWx1ZS5oaXN0b3J5LmZpbHRlciB7IGl0' >> "$TMPB64"
    printf '%s' 'ICE9IHVybCB9CiAgICAgICAgdHJ5IHsKICAgICAgICAgICAgcHJlZnMoY3R4KS5lZGl0KCkucHV0U3RyaW5nKEtFWV9ISVNUT1JZ' >> "$TMPB64"
    printf '%s' 'LCBoaXN0LmpvaW5Ub1N0cmluZygiXG4iKSkuYXBwbHkoKQogICAgICAgIH0gY2F0Y2ggKGU6IEV4Y2VwdGlvbikgewogICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICBhbmRyb2lkLnV0aWwuTG9nLncoIldhbGxwYXBlciIsICLlo4Hnurjljoblj7LliKDpmaTlpLHotKUiLCBlKQogICAgICAg' >> "$TMPB64"
    printf '%s' 'IH0KICAgICAgICBfc3RhdGUudmFsdWUgPSBfc3RhdGUudmFsdWUuY29weShoaXN0b3J5ID0gaGlzdCkKICAgIH0KCiAgICAvLyDp' >> "$TMPB64"
    printf '%s' 'obXpnaLmoLnlupXoibLnlKjvvJrlo4HnurjnlJ/mlYjkuK3liJnpgI/lh7rlupXlsYLlo4HnurjvvIjpobXpnaLmoLnmlLnpgI/m' >> "$TMPB64"
    printf '%s' 'mI7vvIkKICAgIEBDb21wb3NhYmxlCiAgICBmdW4gaXNBY3RpdmUoKTogQm9vbGVhbiB7CiAgICAgICAgdmFsIHMgYnkgc3RhdGUu' >> "$TMPB64"
    printf '%s' 'Y29sbGVjdEFzU3RhdGUoKQogICAgICAgIHJldHVybiBzLmVuYWJsZWQgJiYgKHMudXJsLmlzTm90QmxhbmsoKSB8fCBzLm1vZGUg' >> "$TMPB64"
    printf '%s' 'PT0gImdyYWRpZW50IikKICAgIH0KfQo=' >> "$TMPB64"
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
    printf '%s' 'bGluZWRUZXh0RmllbGREZWZhdWx0cwppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5tYXRlcmlhbDMuU3dpdGNoCmltcG9ydCBhbmRy' >> "$TMPB64"
    printf '%s' 'b2lkeC5jb21wb3NlLm1hdGVyaWFsMy5Td2l0Y2hEZWZhdWx0cwppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5tYXRlcmlhbDMuVGV4' >> "$TMPB64"
    printf '%s' 'dAppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5ydW50aW1lLkNvbXBvc2FibGUKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UucnVudGlt' >> "$TMPB64"
    printf '%s' 'ZS5TaWRlRWZmZWN0CmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLnJ1bnRpbWUuY29sbGVjdEFzU3RhdGUKaW1wb3J0IGFuZHJvaWR4' >> "$TMPB64"
    printf '%s' 'LmNvbXBvc2UucnVudGltZS5nZXRWYWx1ZQppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5ydW50aW1lLm11dGFibGVTdGF0ZU9mCmlt' >> "$TMPB64"
    printf '%s' 'cG9ydCBhbmRyb2lkeC5jb21wb3NlLnJ1bnRpbWUucmVtZW1iZXIKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UucnVudGltZS5zZXRW' >> "$TMPB64"
    printf '%s' 'YWx1ZQppbXBvcnQgYW5kcm9pZHguY29tcG9zZS51aS5BbGlnbm1lbnQKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UudWkuTW9kaWZp' >> "$TMPB64"
    printf '%s' 'ZXIKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UudWkuZHJhdy5jbGlwCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLnVpLmdyYXBoaWNz' >> "$TMPB64"
    printf '%s' 'LkJydXNoCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLnVpLmdyYXBoaWNzLkNvbG9yCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLnVp' >> "$TMPB64"
    printf '%s' 'LmxheW91dC5Db250ZW50U2NhbGUKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UudWkucGxhdGZvcm0uTG9jYWxDb250ZXh0CmltcG9y' >> "$TMPB64"
    printf '%s' 'dCBhbmRyb2lkeC5jb21wb3NlLnVpLnRleHQuZm9udC5Gb250V2VpZ2h0CmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLnVpLnVuaXQu' >> "$TMPB64"
    printf '%s' 'ZHAKaW1wb3J0IGFuZHJvaWR4LmNvcmUudmlldy5XaW5kb3dDb21wYXQKaW1wb3J0IGNvaWwuY29tcG9zZS5Bc3luY0ltYWdlCmlt' >> "$TMPB64"
    printf '%s' 'cG9ydCBjb2lsLnJlcXVlc3QuSW1hZ2VSZXF1ZXN0CgovLyBbMzl3cDJdIOa4kOWPmOmihOiuvjog5ZCN56ewICsg6LW35q2iIEhl' >> "$TMPB64"
    printf '%s' 'eCjlhoXlrrnmlbDmja7mnKzouqssIOmdniBVSSDpk6zoibIpCnByaXZhdGUgdmFsIFdQX0dSQURJRU5UX1BSRVNFVFMgPSBsaXN0' >> "$TMPB64"
    printf '%s' 'T2YoCiAgICBUcmlwbGUoIua3sea1t+iTnSIsICIjMEYyMDI3IiwgIiMyQzUzNjQiKSwKICAgIFRyaXBsZSgi5pma6Zye57qiIiwg' >> "$TMPB64"
    printf '%s' 'IiNGRjk5NjYiLCAiI0ZGNUU2MiIpLAogICAgVHJpcGxlKCLmnoHlhYnnu78iLCAiIzExOTk4RSIsICIjMzhFRjdEIiksCikKCnBy' >> "$TMPB64"
    printf '%s' 'aXZhdGUgZnVuIHdwUGFyc2VDb2xvcihoZXg6IFN0cmluZyk6IENvbG9yID0KICAgIHRyeSB7IENvbG9yKGFuZHJvaWQuZ3JhcGhp' >> "$TMPB64"
    printf '%s' 'Y3MuQ29sb3IucGFyc2VDb2xvcihoZXgpKSB9IGNhdGNoIChlOiBFeGNlcHRpb24pIHsgQ29sb3IuR3JheSB9CgovLyBbMzl3cDFd' >> "$TMPB64"
    printf '%s' 'IOWjgee6uOiuvue9rumhte+8muW8gOWFsyArIFVSTCDovpPlhaUgKyDmnKzlnLDpgInlm77vvIjmjIHkuYXmjojmnYPvvIkrIOWO' >> "$TMPB64"
    printf '%s' 'huWPsuaoquaOkuOAguWPquWGmSBXYWxscGFwZXJNYW5hZ2Vy44CCCmNsYXNzIEx4V2FsbHBhcGVyU2V0dGluZ3NBY3Rpdml0eSA6' >> "$TMPB64"
    printf '%s' 'IENvbXBvbmVudEFjdGl2aXR5KCkgewogICAgb3ZlcnJpZGUgZnVuIG9uQ3JlYXRlKHNhdmVkSW5zdGFuY2VTdGF0ZTogQnVuZGxl' >> "$TMPB64"
    printf '%s' 'PykgewogICAgICAgIHN1cGVyLm9uQ3JlYXRlKHNhdmVkSW5zdGFuY2VTdGF0ZSkKICAgICAgICB2YWwgYXBwQ3R4ID0gYXBwbGlj' >> "$TMPB64"
    printf '%s' 'YXRpb25Db250ZXh0CiAgICAgICAgTXVzaWNUaGVtZU1hbmFnZXIuaW5pdChhcHBDdHgpCiAgICAgICAgV2FsbHBhcGVyTWFuYWdl' >> "$TMPB64"
    printf '%s' 'ci5pbml0KGFwcEN0eCkKICAgICAgICBzZXRDb250ZW50IHsKICAgICAgICAgICAgdmFsIGlzRGFyayBieSBNdXNpY1RoZW1lTWFu' >> "$TMPB64"
    printf '%s' 'YWdlci5pc0RhcmtUaGVtZQogICAgICAgICAgICB2YWwgd2luZG93ID0gdGhpc0BMeFdhbGxwYXBlclNldHRpbmdzQWN0aXZpdHku' >> "$TMPB64"
    printf '%s' 'd2luZG93CiAgICAgICAgICAgIFNpZGVFZmZlY3QgewogICAgICAgICAgICAgICAgV2luZG93Q29tcGF0LmdldEluc2V0c0NvbnRy' >> "$TMPB64"
    printf '%s' 'b2xsZXIod2luZG93LCB3aW5kb3cuZGVjb3JWaWV3KQogICAgICAgICAgICAgICAgICAgIC5pc0FwcGVhcmFuY2VMaWdodFN0YXR1' >> "$TMPB64"
    printf '%s' 'c0JhcnMgPSAhaXNEYXJrCiAgICAgICAgICAgIH0KICAgICAgICAgICAgTHhNdXNpY1RoZW1lKGlzRGFya1RoZW1lID0gaXNEYXJr' >> "$TMPB64"
    printf '%s' 'KSB7CiAgICAgICAgICAgICAgICBXYWxscGFwZXJTZXR0aW5nc1NjcmVlbihvbkJhY2sgPSB7IGZpbmlzaCgpIH0pCiAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgIH0KICAgICAgICB9CiAgICB9Cn0KCkBDb21wb3NhYmxlCmZ1biBXYWxscGFwZXJTZXR0aW5nc1NjcmVlbihvbkJhY2s6ICgp' >> "$TMPB64"
    printf '%s' 'IC0+IFVuaXQpIHsKICAgIHZhbCBjb250ZXh0ID0gTG9jYWxDb250ZXh0LmN1cnJlbnQKICAgIHZhbCB3cFN0YXRlIGJ5IFdhbGxw' >> "$TMPB64"
    printf '%s' 'YXBlck1hbmFnZXIuc3RhdGUuY29sbGVjdEFzU3RhdGUoKQogICAgdmFyIHVybFRleHQgYnkgcmVtZW1iZXIgeyBtdXRhYmxlU3Rh' >> "$TMPB64"
    printf '%s' 'dGVPZih3cFN0YXRlLnVybCkgfQogICAgdmFsIHBpY2tlciA9IHJlbWVtYmVyTGF1bmNoZXJGb3JBY3Rpdml0eVJlc3VsdChBY3Rp' >> "$TMPB64"
    printf '%s' 'dml0eVJlc3VsdENvbnRyYWN0cy5PcGVuRG9jdW1lbnQoKSkgeyB1cmkgLT4KICAgICAgICBpZiAodXJpICE9IG51bGwpIHsKICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgdHJ5IHsKICAgICAgICAgICAgICAgIGNvbnRleHQuY29udGVudFJlc29sdmVyLnRha2VQZXJzaXN0YWJsZVVyaVBl' >> "$TMPB64"
    printf '%s' 'cm1pc3Npb24odXJpLCBJbnRlbnQuRkxBR19HUkFOVF9SRUFEX1VSSV9QRVJNSVNTSU9OKQogICAgICAgICAgICB9IGNhdGNoIChl' >> "$TMPB64"
    printf '%s' 'OiBFeGNlcHRpb24pIHsKICAgICAgICAgICAgICAgIGFuZHJvaWQudXRpbC5Mb2cudygiV2FsbHBhcGVyIiwgIuacrOWcsOWbvuaM' >> "$TMPB64"
    printf '%s' 'geS5heaOiOadg+Wksei0pSIsIGUpCiAgICAgICAgICAgIH0KICAgICAgICAgICAgV2FsbHBhcGVyTWFuYWdlci5hcHBseShjb250' >> "$TMPB64"
    printf '%s' 'ZXh0LCB1cmkudG9TdHJpbmcoKSkKICAgICAgICAgICAgdXJsVGV4dCA9IHVyaS50b1N0cmluZygpCiAgICAgICAgfQogICAgfQog' >> "$TMPB64"
    printf '%s' 'ICAgQ29sdW1uKAogICAgICAgIG1vZGlmaWVyID0gTW9kaWZpZXIKICAgICAgICAgICAgLmZpbGxNYXhTaXplKCkKICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgLmJhY2tncm91bmQobXVzaWNDb2xvcnMoKS5iYWNrZ3JvdW5kKQogICAgKSB7CiAgICAgICAgUm93KAogICAgICAgICAgICBt' >> "$TMPB64"
    printf '%s' 'b2RpZmllciA9IE1vZGlmaWVyCiAgICAgICAgICAgICAgICAuZmlsbE1heFdpZHRoKCkKICAgICAgICAgICAgICAgIC5wYWRkaW5n' >> "$TMPB64"
    printf '%s' 'KHN0YXJ0ID0gOC5kcCwgZW5kID0gMTYuZHAsIHRvcCA9IDQ4LmRwLCBib3R0b20gPSA4LmRwKSwKICAgICAgICAgICAgdmVydGlj' >> "$TMPB64"
    printf '%s' 'YWxBbGlnbm1lbnQgPSBBbGlnbm1lbnQuQ2VudGVyVmVydGljYWxseSwKICAgICAgICApIHsKICAgICAgICAgICAgVGV4dCgKICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgIHRleHQgPSAi4oC5IiwKICAgICAgICAgICAgICAgIHN0eWxlID0gTWF0ZXJpYWxUaGVtZS50eXBvZ3JhcGh5' >> "$TMPB64"
    printf '%s' 'LmhlYWRsaW5lTWVkaXVtLAogICAgICAgICAgICAgICAgY29sb3IgPSBtdXNpY0NvbG9ycygpLnRleHRQcmltYXJ5LAogICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgbW9kaWZpZXIgPSBNb2RpZmllcgogICAgICAgICAgICAgICAgICAgIC5jbGlja2FibGUgeyBvbkJhY2soKSB9CiAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgLnBhZGRpbmcoaG9yaXpvbnRhbCA9IDEyLmRwLCB2ZXJ0aWNhbCA9IDQuZHApLAogICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICApCiAgICAgICAgICAgIFRleHQoCiAgICAgICAgICAgICAgICB0ZXh0ID0gIuWjgee6uOiuvue9riIsCiAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICBzdHlsZSA9IE1hdGVyaWFsVGhlbWUudHlwb2dyYXBoeS50aXRsZUxhcmdlLmNvcHkoZm9udFdlaWdodCA9IEZvbnRXZWlnaHQu' >> "$TMPB64"
    printf '%s' 'Qm9sZCksCiAgICAgICAgICAgICAgICBjb2xvciA9IG11c2ljQ29sb3JzKCkudGV4dFByaW1hcnksCiAgICAgICAgICAgICkKICAg' >> "$TMPB64"
    printf '%s' 'ICAgICB9CiAgICAgICAgTGF6eUNvbHVtbigKICAgICAgICAgICAgbW9kaWZpZXIgPSBNb2RpZmllci5maWxsTWF4U2l6ZSgpLAog' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICBjb250ZW50UGFkZGluZyA9IFBhZGRpbmdWYWx1ZXMoMTYuZHApLAogICAgICAgICAgICB2ZXJ0aWNhbEFycmFu' >> "$TMPB64"
    printf '%s' 'Z2VtZW50ID0gQXJyYW5nZW1lbnQuc3BhY2VkQnkoMTYuZHApLAogICAgICAgICkgewogICAgICAgICAgICBpdGVtIHsKICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgIENhcmQoCiAgICAgICAgICAgICAgICAgICAgY29sb3JzID0gQ2FyZERlZmF1bHRzLmNhcmRDb2xvcnMoY29udGFp' >> "$TMPB64"
    printf '%s' 'bmVyQ29sb3IgPSBtdXNpY0NvbG9ycygpLmNhcmQpLAogICAgICAgICAgICAgICAgICAgIHNoYXBlID0gUm91bmRlZENvcm5lclNo' >> "$TMPB64"
    printf '%s' 'YXBlKDE2LmRwKSwKICAgICAgICAgICAgICAgICkgewogICAgICAgICAgICAgICAgICAgIFJvdygKICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgbW9kaWZpZXIgPSBNb2RpZmllcgogICAgICAgICAgICAgICAgICAgICAgICAgICAgLmZpbGxNYXhXaWR0aCgpCiAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAucGFkZGluZygxNi5kcCksCiAgICAgICAgICAgICAgICAgICAgICAgIHZlcnRpY2FsQWxp' >> "$TMPB64"
    printf '%s' 'Z25tZW50ID0gQWxpZ25tZW50LkNlbnRlclZlcnRpY2FsbHksCiAgICAgICAgICAgICAgICAgICAgKSB7CiAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgIENvbHVtbihtb2RpZmllciA9IE1vZGlmaWVyLndlaWdodCgxZikpIHsKICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgIFRleHQoIuWQr+eUqOWjgee6uOiDjOaZryIsIHN0eWxlID0gTWF0ZXJpYWxUaGVtZS50eXBvZ3JhcGh5LmJvZHlMYXJnZSwg' >> "$TMPB64"
    printf '%s' 'Y29sb3IgPSBtdXNpY0NvbG9ycygpLnRleHRQcmltYXJ5KQogICAgICAgICAgICAgICAgICAgICAgICAgICAgU3BhY2VyKG1vZGlm' >> "$TMPB64"
    printf '%s' 'aWVyID0gTW9kaWZpZXIuaGVpZ2h0KDIuZHApKQogICAgICAgICAgICAgICAgICAgICAgICAgICAgVGV4dCgi6Z+z5LmQ5LiT5Yy6' >> "$TMPB64"
    printf '%s' '5bqV5bGC6IOM5pmv5Zu+77yI5bim5Y+v6K+75oCn6YGu572p77yJIiwgc3R5bGUgPSBNYXRlcmlhbFRoZW1lLnR5cG9ncmFwaHku' >> "$TMPB64"
    printf '%s' 'Ym9keVNtYWxsLCBjb2xvciA9IG11c2ljQ29sb3JzKCkudGV4dFNlY29uZGFyeSkKICAgICAgICAgICAgICAgICAgICAgICAgfQog' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICBTd2l0Y2goCiAgICAgICAgICAgICAgICAgICAgICAgICAgICBjaGVja2VkID0gd3BTdGF0' >> "$TMPB64"
    printf '%s' 'ZS5lbmFibGVkLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgb25DaGVja2VkQ2hhbmdlID0geyBXYWxscGFwZXJNYW5hZ2Vy' >> "$TMPB64"
    printf '%s' 'LnNldEVuYWJsZWQoY29udGV4dCwgaXQpIH0sCiAgICAgICAgICAgICAgICAgICAgICAgICAgICBjb2xvcnMgPSBTd2l0Y2hEZWZh' >> "$TMPB64"
    printf '%s' 'dWx0cy5jb2xvcnMoCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgY2hlY2tlZFRodW1iQ29sb3IgPSBDb2xvci5XaGl0' >> "$TMPB64"
    printf '%s' 'ZSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBjaGVja2VkVHJhY2tDb2xvciA9IG11c2ljQ29sb3JzKCkuYWNjZW50' >> "$TMPB64"
    printf '%s' 'LAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHVuY2hlY2tlZFRodW1iQ29sb3IgPSBDb2xvci5XaGl0ZSwKICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICB1bmNoZWNrZWRUcmFja0NvbG9yID0gbXVzaWNDb2xvcnMoKS5jYXJkU2Vjb25kYXJ5' >> "$TMPB64"
    printf '%s' 'LAogICAgICAgICAgICAgICAgICAgICAgICAgICAgKSwKICAgICAgICAgICAgICAgICAgICAgICAgKQogICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgIH0KICAgICAgICAgICAgICAgIH0KICAgICAgICAgICAgfQogICAgICAgICAgICBpdGVtIHsKICAgICAgICAgICAgICAgIENh' >> "$TMPB64"
    printf '%s' 'cmQoCiAgICAgICAgICAgICAgICAgICAgY29sb3JzID0gQ2FyZERlZmF1bHRzLmNhcmRDb2xvcnMoY29udGFpbmVyQ29sb3IgPSBt' >> "$TMPB64"
    printf '%s' 'dXNpY0NvbG9ycygpLmNhcmQpLAogICAgICAgICAgICAgICAgICAgIHNoYXBlID0gUm91bmRlZENvcm5lclNoYXBlKDE2LmRwKSwK' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICkgewogICAgICAgICAgICAgICAgICAgIENvbHVtbihtb2RpZmllciA9IE1vZGlmaWVyLnBhZGRpbmco' >> "$TMPB64"
    printf '%s' 'MTYuZHApKSB7CiAgICAgICAgICAgICAgICAgICAgICAgIFRleHQoIue9kee7nOWjgee6uCIsIHN0eWxlID0gTWF0ZXJpYWxUaGVt' >> "$TMPB64"
    printf '%s' 'ZS50eXBvZ3JhcGh5LmJvZHlMYXJnZSwgY29sb3IgPSBtdXNpY0NvbG9ycygpLnRleHRQcmltYXJ5KQogICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICBTcGFjZXIobW9kaWZpZXIgPSBNb2RpZmllci5oZWlnaHQoMTAuZHApKQogICAgICAgICAgICAgICAgICAgICAgICBP' >> "$TMPB64"
    printf '%s' 'dXRsaW5lZFRleHRGaWVsZCgKICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlID0gdXJsVGV4dCwKICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgIG9uVmFsdWVDaGFuZ2UgPSB7IHVybFRleHQgPSBpdCB9LAogICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgbGFiZWwgPSB7IFRleHQoIuWbvueJhyBVUkzvvIhodHRwL2h0dHBz77yJIikgfSwKICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgIHNpbmdsZUxpbmUgPSB0cnVlLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgbW9kaWZpZXIgPSBNb2RpZmllci5maWxs' >> "$TMPB64"
    printf '%s' 'TWF4V2lkdGgoKSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNvbG9ycyA9IE91dGxpbmVkVGV4dEZpZWxkRGVmYXVsdHMu' >> "$TMPB64"
    printf '%s' 'Y29sb3JzKAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGZvY3VzZWRCb3JkZXJDb2xvciA9IG11c2ljQ29sb3JzKCku' >> "$TMPB64"
    printf '%s' 'YWNjZW50LAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHVuZm9jdXNlZEJvcmRlckNvbG9yID0gbXVzaWNDb2xvcnMo' >> "$TMPB64"
    printf '%s' 'KS5kaXZpZGVyLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGN1cnNvckNvbG9yID0gbXVzaWNDb2xvcnMoKS5hY2Nl' >> "$TMPB64"
    printf '%s' 'bnQsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZm9jdXNlZExhYmVsQ29sb3IgPSBtdXNpY0NvbG9ycygpLmFjY2Vu' >> "$TMPB64"
    printf '%s' 'dCwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB1bmZvY3VzZWRMYWJlbENvbG9yID0gbXVzaWNDb2xvcnMoKS50ZXh0' >> "$TMPB64"
    printf '%s' 'U2Vjb25kYXJ5LAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGZvY3VzZWRUZXh0Q29sb3IgPSBtdXNpY0NvbG9ycygp' >> "$TMPB64"
    printf '%s' 'LnRleHRQcmltYXJ5LAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHVuZm9jdXNlZFRleHRDb2xvciA9IG11c2ljQ29s' >> "$TMPB64"
    printf '%s' 'b3JzKCkudGV4dFByaW1hcnksCiAgICAgICAgICAgICAgICAgICAgICAgICAgICApLAogICAgICAgICAgICAgICAgICAgICAgICAp' >> "$TMPB64"
    printf '%s' 'CiAgICAgICAgICAgICAgICAgICAgICAgIFNwYWNlcihtb2RpZmllciA9IE1vZGlmaWVyLmhlaWdodCgxMi5kcCkpCiAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgIFJvdyB7CiAgICAgICAgICAgICAgICAgICAgICAgICAgICBCdXR0b24oCiAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgb25DbGljayA9IHsgV2FsbHBhcGVyTWFuYWdlci5hcHBseShjb250ZXh0LCB1cmxUZXh0KSB9LAogICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNvbG9ycyA9IEJ1dHRvbkRlZmF1bHRzLmJ1dHRvbkNvbG9ycygKICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgY29udGFpbmVyQ29sb3IgPSBtdXNpY0NvbG9ycygpLmFjY2VudCwKICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgY29udGVudENvbG9yID0gbXVzaWNDb2xvcnMoKS5hY2NlbnRUZXh0LAogICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICksCiAgICAgICAgICAgICAgICAgICAgICAgICAgICApIHsgVGV4dCgi5bqU55So5q2k' >> "$TMPB64"
    printf '%s' 'IFVSTCIpIH0KICAgICAgICAgICAgICAgICAgICAgICAgICAgIFNwYWNlcihtb2RpZmllciA9IE1vZGlmaWVyLndpZHRoKDEwLmRw' >> "$TMPB64"
    printf '%s' 'KSkKICAgICAgICAgICAgICAgICAgICAgICAgICAgIE91dGxpbmVkQnV0dG9uKG9uQ2xpY2sgPSB7IHBpY2tlci5sYXVuY2goYXJy' >> "$TMPB64"
    printf '%s' 'YXlPZigiaW1hZ2UvKiIpKSB9KSB7CiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgVGV4dCgi5pys5Zyw6YCJ5Zu+Iiwg' >> "$TMPB64"
    printf '%s' 'Y29sb3IgPSBtdXNpY0NvbG9ycygpLnRleHRQcmltYXJ5KQogICAgICAgICAgICAgICAgICAgICAgICAgICAgfQogICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICB9CiAgICAgICAgICAgICAgICAgICAgfQogICAgICAgICAgICAgICAgfQogICAgICAgICAgICB9CiAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgIGl0ZW0gewogICAgICAgICAgICAgICAgQ2FyZCgKICAgICAgICAgICAgICAgICAgICBjb2xvcnMgPSBDYXJkRGVmYXVs' >> "$TMPB64"
    printf '%s' 'dHMuY2FyZENvbG9ycyhjb250YWluZXJDb2xvciA9IG11c2ljQ29sb3JzKCkuY2FyZCksCiAgICAgICAgICAgICAgICAgICAgc2hh' >> "$TMPB64"
    printf '%s' 'cGUgPSBSb3VuZGVkQ29ybmVyU2hhcGUoMTYuZHApLAogICAgICAgICAgICAgICAgICAgIG1vZGlmaWVyID0gTW9kaWZpZXIKICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgLmZpbGxNYXhXaWR0aCgpCiAgICAgICAgICAgICAgICAgICAgICAgIC5jbGlja2FibGUgewog' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgY29udGV4dC5zdGFydEFjdGl2aXR5KEludGVudChjb250ZXh0LCBXYWxscGFwZXJM' >> "$TMPB64"
    printf '%s' 'aWJyYXJ5QWN0aXZpdHk6OmNsYXNzLmphdmEpKQogICAgICAgICAgICAgICAgICAgICAgICB9LAogICAgICAgICAgICAgICAgKSB7' >> "$TMPB64"
    printf '%s' 'CiAgICAgICAgICAgICAgICAgICAgUm93KAogICAgICAgICAgICAgICAgICAgICAgICBtb2RpZmllciA9IE1vZGlmaWVyCiAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAuZmlsbE1heFdpZHRoKCkKICAgICAgICAgICAgICAgICAgICAgICAgICAgIC5wYWRkaW5n' >> "$TMPB64"
    printf '%s' 'KDE2LmRwKSwKICAgICAgICAgICAgICAgICAgICAgICAgdmVydGljYWxBbGlnbm1lbnQgPSBBbGlnbm1lbnQuQ2VudGVyVmVydGlj' >> "$TMPB64"
    printf '%s' 'YWxseSwKICAgICAgICAgICAgICAgICAgICApIHsKICAgICAgICAgICAgICAgICAgICAgICAgQ29sdW1uKG1vZGlmaWVyID0gTW9k' >> "$TMPB64"
    printf '%s' 'aWZpZXIud2VpZ2h0KDFmKSkgewogICAgICAgICAgICAgICAgICAgICAgICAgICAgVGV4dCgi5Zyo57q/5aOB57q45bqTIiwgc3R5' >> "$TMPB64"
    printf '%s' 'bGUgPSBNYXRlcmlhbFRoZW1lLnR5cG9ncmFwaHkuYm9keUxhcmdlLCBjb2xvciA9IG11c2ljQ29sb3JzKCkudGV4dFByaW1hcnkp' >> "$TMPB64"
    printf '%s' 'CiAgICAgICAgICAgICAgICAgICAgICAgICAgICBTcGFjZXIobW9kaWZpZXIgPSBNb2RpZmllci5oZWlnaHQoMi5kcCkpCiAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICBUZXh0KCLnsr7pgInnvZHnu5zlo4HnurjvvIzngrnlh7vljbPlupTnlKgiLCBzdHlsZSA9' >> "$TMPB64"
    printf '%s' 'IE1hdGVyaWFsVGhlbWUudHlwb2dyYXBoeS5ib2R5U21hbGwsIGNvbG9yID0gbXVzaWNDb2xvcnMoKS50ZXh0U2Vjb25kYXJ5KQog' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICB9CiAgICAgICAgICAgICAgICAgICAgICAgIFRleHQoIuKAuiIsIHN0eWxlID0gTWF0ZXJp' >> "$TMPB64"
    printf '%s' 'YWxUaGVtZS50eXBvZ3JhcGh5LmhlYWRsaW5lTWVkaXVtLCBjb2xvciA9IG11c2ljQ29sb3JzKCkudGV4dFNlY29uZGFyeSkKICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICB9CiAgICAgICAgICAgICAgICB9CiAgICAgICAgICAgIH0KICAgICAgICAgICAgaXRlbSB7CiAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICBDYXJkKAogICAgICAgICAgICAgICAgICAgIGNvbG9ycyA9IENhcmREZWZhdWx0cy5jYXJkQ29sb3JzKGNvbnRh' >> "$TMPB64"
    printf '%s' 'aW5lckNvbG9yID0gbXVzaWNDb2xvcnMoKS5jYXJkKSwKICAgICAgICAgICAgICAgICAgICBzaGFwZSA9IFJvdW5kZWRDb3JuZXJT' >> "$TMPB64"
    printf '%s' 'aGFwZSgxNi5kcCksCiAgICAgICAgICAgICAgICApIHsKICAgICAgICAgICAgICAgICAgICBDb2x1bW4obW9kaWZpZXIgPSBNb2Rp' >> "$TMPB64"
    printf '%s' 'Zmllci5wYWRkaW5nKDE2LmRwKSkgewogICAgICAgICAgICAgICAgICAgICAgICBUZXh0KCLmuJDlj5jog4zmma8iLCBzdHlsZSA9' >> "$TMPB64"
    printf '%s' 'IE1hdGVyaWFsVGhlbWUudHlwb2dyYXBoeS5ib2R5TGFyZ2UsIGNvbG9yID0gbXVzaWNDb2xvcnMoKS50ZXh0UHJpbWFyeSkKICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgU3BhY2VyKG1vZGlmaWVyID0gTW9kaWZpZXIuaGVpZ2h0KDIuZHApKQogICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICBUZXh0KCLkuI3nlKjlm77niYfvvIzkuIDlsYLmuJDlj5jkvZzlupXvvIjlkIzmoLfluKblj6/or7vmgKfpga7n' >> "$TMPB64"
    printf '%s' 'vanvvIkiLCBzdHlsZSA9IE1hdGVyaWFsVGhlbWUudHlwb2dyYXBoeS5ib2R5U21hbGwsIGNvbG9yID0gbXVzaWNDb2xvcnMoKS50' >> "$TMPB64"
    printf '%s' 'ZXh0U2Vjb25kYXJ5KQogICAgICAgICAgICAgICAgICAgICAgICBTcGFjZXIobW9kaWZpZXIgPSBNb2RpZmllci5oZWlnaHQoMTIu' >> "$TMPB64"
    printf '%s' 'ZHApKQogICAgICAgICAgICAgICAgICAgICAgICBSb3coaG9yaXpvbnRhbEFycmFuZ2VtZW50ID0gQXJyYW5nZW1lbnQuc3BhY2Vk' >> "$TMPB64"
    printf '%s' 'QnkoMTQuZHApKSB7CiAgICAgICAgICAgICAgICAgICAgICAgICAgICBXUF9HUkFESUVOVF9QUkVTRVRTLmZvckVhY2ggeyAobmFt' >> "$TMPB64"
    printf '%s' 'ZSwgaDEsIGgyKSAtPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbCBwYWlyID0gIiRoMSwkaDIiCiAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgdmFsIGlzQ3VycmVudCA9IHdwU3RhdGUubW9kZSA9PSAiZ3JhZGllbnQiICYmIHdwU3Rh' >> "$TMPB64"
    printf '%s' 'dGUuZ3JhZGllbnQgPT0gcGFpcgogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIENvbHVtbihob3Jpem9udGFsQWxpZ25t' >> "$TMPB64"
    printf '%s' 'ZW50ID0gQWxpZ25tZW50LkNlbnRlckhvcml6b250YWxseSkgewogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBC' >> "$TMPB64"
    printf '%s' 'b3goCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBtb2RpZmllciA9IE1vZGlmaWVyCiAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgLnNpemUoNjQuZHApCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgLmNsaXAoUm91bmRlZENvcm5lclNoYXBlKDE0LmRwKSkKICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAuYmFja2dyb3VuZChCcnVzaC5saW5lYXJHcmFkaWVudChsaXN0T2Yod3BQYXJzZUNvbG9yKGgxKSwg' >> "$TMPB64"
    printf '%s' 'd3BQYXJzZUNvbG9yKGgyKSkpKQogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIC50aGVuKAogICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBpZiAoaXNDdXJyZW50KSBNb2RpZmllci5ib3JkZXIo' >> "$TMPB64"
    printf '%s' 'Mi5kcCwgbXVzaWNDb2xvcnMoKS5hY2NlbnQsIFJvdW5kZWRDb3JuZXJTaGFwZSgxNC5kcCkpCiAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgIGVsc2UgTW9kaWZpZXIKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICApCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgLmNsaWNrYWJsZSB7CiAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIFdhbGxwYXBlck1hbmFnZXIuYXBwbHlHcmFkaWVudChj' >> "$TMPB64"
    printf '%s' 'b250ZXh0LCBwYWlyKQogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBhbmRyb2lkLndpZGdl' >> "$TMPB64"
    printf '%s' 'dC5Ub2FzdC5tYWtlVGV4dChjb250ZXh0LCAi5riQ5Y+Y5bey5bqU55SoIiwgYW5kcm9pZC53aWRnZXQuVG9hc3QuTEVOR1RIX1NI' >> "$TMPB64"
    printf '%s' 'T1JUKS5zaG93KCkKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB9LAogICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICApCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIFNwYWNlcihtb2RpZmllciA9' >> "$TMPB64"
    printf '%s' 'IE1vZGlmaWVyLmhlaWdodCg2LmRwKSkKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgVGV4dChuYW1lLCBzdHls' >> "$TMPB64"
    printf '%s' 'ZSA9IE1hdGVyaWFsVGhlbWUudHlwb2dyYXBoeS5ib2R5U21hbGwsIGNvbG9yID0gbXVzaWNDb2xvcnMoKS50ZXh0UHJpbWFyeSkK' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB9CiAgICAgICAgICAgICAgICAgICAgICAgICAgICB9CiAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgIH0KICAgICAgICAgICAgICAgICAgICB9CiAgICAgICAgICAgICAgICB9CiAgICAgICAgICAgIH0KICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgaWYgKHdwU3RhdGUuaGlzdG9yeS5pc05vdEVtcHR5KCkpIHsKICAgICAgICAgICAgICAgIGl0ZW0gewogICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgIFRleHQoCiAgICAgICAgICAgICAgICAgICAgICAgIHRleHQgPSAi5Y6G5Y+y5aOB57q4IiwKICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgc3R5bGUgPSBNYXRlcmlhbFRoZW1lLnR5cG9ncmFwaHkudGl0bGVNZWRpdW0uY29weShmb250V2VpZ2h0ID0g' >> "$TMPB64"
    printf '%s' 'Rm9udFdlaWdodC5Cb2xkKSwKICAgICAgICAgICAgICAgICAgICAgICAgY29sb3IgPSBtdXNpY0NvbG9ycygpLnRleHRQcmltYXJ5' >> "$TMPB64"
    printf '%s' 'LAogICAgICAgICAgICAgICAgICAgICkKICAgICAgICAgICAgICAgIH0KICAgICAgICAgICAgICAgIGl0ZW0gewogICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgIExhenlSb3coaG9yaXpvbnRhbEFycmFuZ2VtZW50ID0gQXJyYW5nZW1lbnQuc3BhY2VkQnkoMTAuZHApKSB7CiAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgIGl0ZW1zKHdwU3RhdGUuaGlzdG9yeSwga2V5ID0geyBpdCB9KSB7IHUgLT4KICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgIHZhbCBpc0N1cnJlbnQgPSB1ID09IHdwU3RhdGUudXJsCiAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICBCb3goCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgbW9kaWZpZXIgPSBNb2RpZmllcgogICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAuc2l6ZSg4NC5kcCkKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgLmNs' >> "$TMPB64"
    printf '%s' 'aXAoUm91bmRlZENvcm5lclNoYXBlKDEyLmRwKSkKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgLmJhY2tncm91' >> "$TMPB64"
    printf '%s' 'bmQobXVzaWNDb2xvcnMoKS5jYXJkU2Vjb25kYXJ5KQogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAudGhlbigK' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGlmIChpc0N1cnJlbnQpIE1vZGlmaWVyLmJvcmRlcigyLmRw' >> "$TMPB64"
    printf '%s' 'LCBtdXNpY0NvbG9ycygpLmFjY2VudCwgUm91bmRlZENvcm5lclNoYXBlKDEyLmRwKSkKICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgIGVsc2UgTW9kaWZpZXIKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgKQogICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAuY2xpY2thYmxlIHsKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgIFdhbGxwYXBlck1hbmFnZXIuYXBwbHkoY29udGV4dCwgdSkKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgIHVybFRleHQgPSB1CiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIH0sCiAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICApIHsKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBBc3luY0ltYWdlKAogICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICBtb2RlbCA9IEltYWdlUmVxdWVzdC5CdWlsZGVyKGNvbnRleHQpLmRhdGEodSkuc2l6ZSgyNDAp' >> "$TMPB64"
    printf '%s' 'LmJ1aWxkKCksCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNvbnRlbnREZXNjcmlwdGlvbiA9IG51bGwsCiAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNvbnRlbnRTY2FsZSA9IENvbnRlbnRTY2FsZS5Dcm9wLAogICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICBtb2RpZmllciA9IE1vZGlmaWVyLmZpbGxNYXhTaXplKCksCiAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAgICAgKQogICAgICAgICAgICAgICAgICAgICAgICAgICAgfQogICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICB9CiAgICAgICAgICAgICAgICAgICAgfQogICAgICAgICAgICAgICAgfQogICAgICAgICAgICB9CiAgICAgICAgICAgIGl0ZW0g' >> "$TMPB64"
    printf '%s' 'ewogICAgICAgICAgICAgICAgVGV4dCgKICAgICAgICAgICAgICAgICAgICB0ZXh0ID0gIuWjgee6uOS9jeS6jumfs+S5kOS4k+WM' >> "$TMPB64"
    printf '%s' 'uuacgOW6leWxgu+8jOWFtuS4iuebluacieWPr+ivu+aAp+mBrue9qe+8iOa3seiJsiA2MCUg6buRIC8g5rWF6ImyIDcwJSDnmb3v' >> "$TMPB64"
    printf '%s' 'vInvvIzmloflrZflp4vnu4jmuIXmmbDvvJvog4zmma/lm77mjInlsY/luZXlsLrlr7jlsIHpobbliqDovb3vvIzkuI3lvbHlk43l' >> "$TMPB64"
    printf '%s' 'iJfooajmu5HliqjjgILmnKzlnLDlm77niYfkvb/nlKjns7vnu5/mlofku7bpgInmi6nlmajlubbnlLPor7fmjIHkuYXmjojmnYPv' >> "$TMPB64"
    printf '%s' 'vIzph43lkK/kuI3lpLHmlYjjgIIiLAogICAgICAgICAgICAgICAgICAgIHN0eWxlID0gTWF0ZXJpYWxUaGVtZS50eXBvZ3JhcGh5' >> "$TMPB64"
    printf '%s' 'LmJvZHlTbWFsbCwKICAgICAgICAgICAgICAgICAgICBjb2xvciA9IG11c2ljQ29sb3JzKCkudGV4dFNlY29uZGFyeSwKICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICkKICAgICAgICAgICAgfQogICAgICAgIH0KICAgIH0KfQo=' >> "$TMPB64"
base64 -d "$TMPB64" > avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxWallpaperSettingsActivity.kt
rm -f "$TMPB64"
grep -q 'class LxWallpaperSettingsActivity' avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxWallpaperSettingsActivity.kt || { echo "X 39 class LxWallpaperSettingsActivity 写入失败"; exit 1; }
TMPB64=$(mktemp)
    printf '%s' 'cGFja2FnZSBjb20uZ2l0aHViLnR2Ym94Lm9zYy51aS5hY3Rpdml0eQoKaW1wb3J0IGFuZHJvaWQub3MuQnVuZGxlCmltcG9ydCBh' >> "$TMPB64"
    printf '%s' 'bmRyb2lkLndpZGdldC5Ub2FzdAppbXBvcnQgYW5kcm9pZHguYWN0aXZpdHkuQ29tcG9uZW50QWN0aXZpdHkKaW1wb3J0IGFuZHJv' >> "$TMPB64"
    printf '%s' 'aWR4LmFjdGl2aXR5LmNvbXBvc2Uuc2V0Q29udGVudAppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5mb3VuZGF0aW9uLmJhY2tncm91' >> "$TMPB64"
    printf '%s' 'bmQKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UuZm91bmRhdGlvbi5jbGlja2FibGUKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UuZm91' >> "$TMPB64"
    printf '%s' 'bmRhdGlvbi5sYXlvdXQuQXJyYW5nZW1lbnQKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UuZm91bmRhdGlvbi5sYXlvdXQuQm94Cmlt' >> "$TMPB64"
    printf '%s' 'cG9ydCBhbmRyb2lkeC5jb21wb3NlLmZvdW5kYXRpb24ubGF5b3V0LkNvbHVtbgppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5mb3Vu' >> "$TMPB64"
    printf '%s' 'ZGF0aW9uLmxheW91dC5QYWRkaW5nVmFsdWVzCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLmZvdW5kYXRpb24ubGF5b3V0LlJvdwpp' >> "$TMPB64"
    printf '%s' 'bXBvcnQgYW5kcm9pZHguY29tcG9zZS5mb3VuZGF0aW9uLmxheW91dC5hc3BlY3RSYXRpbwppbXBvcnQgYW5kcm9pZHguY29tcG9z' >> "$TMPB64"
    printf '%s' 'ZS5mb3VuZGF0aW9uLmxheW91dC5maWxsTWF4U2l6ZQppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5mb3VuZGF0aW9uLmxheW91dC5m' >> "$TMPB64"
    printf '%s' 'aWxsTWF4V2lkdGgKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UuZm91bmRhdGlvbi5sYXlvdXQucGFkZGluZwppbXBvcnQgYW5kcm9p' >> "$TMPB64"
    printf '%s' 'ZHguY29tcG9zZS5mb3VuZGF0aW9uLmxhenkuTGF6eVJvdwppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5mb3VuZGF0aW9uLmxhenku' >> "$TMPB64"
    printf '%s' 'Z3JpZC5HcmlkQ2VsbHMKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UuZm91bmRhdGlvbi5sYXp5LmdyaWQuTGF6eVZlcnRpY2FsR3Jp' >> "$TMPB64"
    printf '%s' 'ZAppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5mb3VuZGF0aW9uLmxhenkuZ3JpZC5pdGVtcwppbXBvcnQgYW5kcm9pZHguY29tcG9z' >> "$TMPB64"
    printf '%s' 'ZS5mb3VuZGF0aW9uLmxhenkuaXRlbXMKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UuZm91bmRhdGlvbi5zaGFwZS5Sb3VuZGVkQ29y' >> "$TMPB64"
    printf '%s' 'bmVyU2hhcGUKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UubWF0ZXJpYWwzLkNhcmQKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UubWF0' >> "$TMPB64"
    printf '%s' 'ZXJpYWwzLk1hdGVyaWFsVGhlbWUKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UubWF0ZXJpYWwzLlRleHQKaW1wb3J0IGFuZHJvaWR4' >> "$TMPB64"
    printf '%s' 'LmNvbXBvc2UucnVudGltZS5Db21wb3NhYmxlCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLnJ1bnRpbWUuU2lkZUVmZmVjdAppbXBv' >> "$TMPB64"
    printf '%s' 'cnQgYW5kcm9pZHguY29tcG9zZS5ydW50aW1lLmdldFZhbHVlCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLnJ1bnRpbWUubXV0YWJs' >> "$TMPB64"
    printf '%s' 'ZVN0YXRlT2YKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UucnVudGltZS5yZW1lbWJlcgppbXBvcnQgYW5kcm9pZHguY29tcG9zZS5y' >> "$TMPB64"
    printf '%s' 'dW50aW1lLnNldFZhbHVlCmltcG9ydCBhbmRyb2lkeC5jb21wb3NlLnVpLkFsaWdubWVudAppbXBvcnQgYW5kcm9pZHguY29tcG9z' >> "$TMPB64"
    printf '%s' 'ZS51aS5Nb2RpZmllcgppbXBvcnQgYW5kcm9pZHguY29tcG9zZS51aS5kcmF3LmNsaXAKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2Uu' >> "$TMPB64"
    printf '%s' 'dWkubGF5b3V0LkNvbnRlbnRTY2FsZQppbXBvcnQgYW5kcm9pZHguY29tcG9zZS51aS5wbGF0Zm9ybS5Mb2NhbENvbnRleHQKaW1w' >> "$TMPB64"
    printf '%s' 'b3J0IGFuZHJvaWR4LmNvbXBvc2UudWkudGV4dC5mb250LkZvbnRXZWlnaHQKaW1wb3J0IGFuZHJvaWR4LmNvbXBvc2UudWkudW5p' >> "$TMPB64"
    printf '%s' 'dC5kcAppbXBvcnQgYW5kcm9pZHguY29yZS52aWV3LldpbmRvd0NvbXBhdAppbXBvcnQgY29pbC5jb21wb3NlLkFzeW5jSW1hZ2UK' >> "$TMPB64"
    printf '%s' 'Ci8vIFszOXdwMl0g5Zyo57q/5aOB57q45bqT77yITW9jayDmlbDmja7vvJpwaWNzdW0g5a6aIElEIOWbvu+8jOWFjei0ueWFjemJ' >> "$TMPB64"
    printf '%s' 'tOadg++8jOW3suWunua1i+WPr+i+vu+8ieOAggpwcml2YXRlIHZhbCBXUF9DQVRTID0gbGlzdE9mKCLnsr7pgIkiLCAi54yc5L2g' >> "$TMPB64"
    printf '%s' '5Zac5qyiIiwgIumrmOa4heWjgee6uCIpCgpwcml2YXRlIGZ1biB3cFVybChpZDogSW50KSA9ICJodHRwczovL3BpY3N1bS5waG90' >> "$TMPB64"
    printf '%s' 'b3MvaWQvJGlkLzEwODAvMTkyMCIKCnByaXZhdGUgdmFsIFdQX01PQ0s6IE1hcDxTdHJpbmcsIExpc3Q8U3RyaW5nPj4gPSBtYXBP' >> "$TMPB64"
    printf '%s' 'ZigKICAgICLnsr7pgIkiIHRvIGxpc3RPZigxMDE1LCAxMDE2LCAxMDE4LCAxMDE5LCAxMDIwLCAxMDI1LCAxMDI5LCAxMDM1KS5t' >> "$TMPB64"
    printf '%s' 'YXAgeyB3cFVybChpdCkgfSwKICAgICLnjJzkvaDllpzmrKIiIHRvIGxpc3RPZigxMDM2LCAxMDM5LCAxMDQxLCAxMDQzLCAxMDQ0' >> "$TMPB64"
    printf '%s' 'LCAxMDQ3LCAxMDQ5LCAxMDUwKS5tYXAgeyB3cFVybChpdCkgfSwKICAgICLpq5jmuIXlo4HnurgiIHRvIGxpc3RPZigxMDUzLCAx' >> "$TMPB64"
    printf '%s' 'MDU3LCAxMDYwLCAxMDYyLCAxMDY3LCAxMDY5LCAxMDc0LCAxMDgwKS5tYXAgeyB3cFVybChpdCkgfSwKKQoKY2xhc3MgV2FsbHBh' >> "$TMPB64"
    printf '%s' 'cGVyTGlicmFyeUFjdGl2aXR5IDogQ29tcG9uZW50QWN0aXZpdHkoKSB7CiAgICBvdmVycmlkZSBmdW4gb25DcmVhdGUoc2F2ZWRJ' >> "$TMPB64"
    printf '%s' 'bnN0YW5jZVN0YXRlOiBCdW5kbGU/KSB7CiAgICAgICAgc3VwZXIub25DcmVhdGUoc2F2ZWRJbnN0YW5jZVN0YXRlKQogICAgICAg' >> "$TMPB64"
    printf '%s' 'IHZhbCBhcHBDdHggPSBhcHBsaWNhdGlvbkNvbnRleHQKICAgICAgICBNdXNpY1RoZW1lTWFuYWdlci5pbml0KGFwcEN0eCkKICAg' >> "$TMPB64"
    printf '%s' 'ICAgICBXYWxscGFwZXJNYW5hZ2VyLmluaXQoYXBwQ3R4KQogICAgICAgIHNldENvbnRlbnQgewogICAgICAgICAgICB2YWwgaXNE' >> "$TMPB64"
    printf '%s' 'YXJrIGJ5IE11c2ljVGhlbWVNYW5hZ2VyLmlzRGFya1RoZW1lCiAgICAgICAgICAgIHZhbCB3aW5kb3cgPSB0aGlzQFdhbGxwYXBl' >> "$TMPB64"
    printf '%s' 'ckxpYnJhcnlBY3Rpdml0eS53aW5kb3cKICAgICAgICAgICAgU2lkZUVmZmVjdCB7CiAgICAgICAgICAgICAgICBXaW5kb3dDb21w' >> "$TMPB64"
    printf '%s' 'YXQuZ2V0SW5zZXRzQ29udHJvbGxlcih3aW5kb3csIHdpbmRvdy5kZWNvclZpZXcpCiAgICAgICAgICAgICAgICAgICAgLmlzQXBw' >> "$TMPB64"
    printf '%s' 'ZWFyYW5jZUxpZ2h0U3RhdHVzQmFycyA9ICFpc0RhcmsKICAgICAgICAgICAgfQogICAgICAgICAgICBMeE11c2ljVGhlbWUoaXNE' >> "$TMPB64"
    printf '%s' 'YXJrVGhlbWUgPSBpc0RhcmspIHsKICAgICAgICAgICAgICAgIFdhbGxwYXBlckxpYnJhcnlTY3JlZW4ob25CYWNrID0geyBmaW5p' >> "$TMPB64"
    printf '%s' 'c2goKSB9KQogICAgICAgICAgICB9CiAgICAgICAgfQogICAgfQp9CgpAQ29tcG9zYWJsZQpmdW4gV2FsbHBhcGVyTGlicmFyeVNj' >> "$TMPB64"
    printf '%s' 'cmVlbihvbkJhY2s6ICgpIC0+IFVuaXQpIHsKICAgIHZhbCBjb250ZXh0ID0gTG9jYWxDb250ZXh0LmN1cnJlbnQKICAgIHZhciBj' >> "$TMPB64"
    printf '%s' 'YXQgYnkgcmVtZW1iZXIgeyBtdXRhYmxlU3RhdGVPZihXUF9DQVRTWzBdKSB9CiAgICB2YWwgbGlzdCA9IFdQX01PQ0tbY2F0XSA/' >> "$TMPB64"
    printf '%s' 'OiBlbXB0eUxpc3QoKQogICAgQ29sdW1uKAogICAgICAgIG1vZGlmaWVyID0gTW9kaWZpZXIKICAgICAgICAgICAgLmZpbGxNYXhT' >> "$TMPB64"
    printf '%s' 'aXplKCkKICAgICAgICAgICAgLmJhY2tncm91bmQobXVzaWNDb2xvcnMoKS5iYWNrZ3JvdW5kKQogICAgKSB7CiAgICAgICAgUm93' >> "$TMPB64"
    printf '%s' 'KAogICAgICAgICAgICBtb2RpZmllciA9IE1vZGlmaWVyCiAgICAgICAgICAgICAgICAuZmlsbE1heFdpZHRoKCkKICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgIC5wYWRkaW5nKHN0YXJ0ID0gOC5kcCwgZW5kID0gMTYuZHAsIHRvcCA9IDQ4LmRwLCBib3R0b20gPSA4LmRwKSwKICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgdmVydGljYWxBbGlnbm1lbnQgPSBBbGlnbm1lbnQuQ2VudGVyVmVydGljYWxseSwKICAgICAgICApIHsKICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgVGV4dCgKICAgICAgICAgICAgICAgIHRleHQgPSAi4oC5IiwKICAgICAgICAgICAgICAgIHN0eWxlID0gTWF0ZXJpYWxU' >> "$TMPB64"
    printf '%s' 'aGVtZS50eXBvZ3JhcGh5LmhlYWRsaW5lTWVkaXVtLAogICAgICAgICAgICAgICAgY29sb3IgPSBtdXNpY0NvbG9ycygpLnRleHRQ' >> "$TMPB64"
    printf '%s' 'cmltYXJ5LAogICAgICAgICAgICAgICAgbW9kaWZpZXIgPSBNb2RpZmllcgogICAgICAgICAgICAgICAgICAgIC5jbGlja2FibGUg' >> "$TMPB64"
    printf '%s' 'eyBvbkJhY2soKSB9CiAgICAgICAgICAgICAgICAgICAgLnBhZGRpbmcoaG9yaXpvbnRhbCA9IDEyLmRwLCB2ZXJ0aWNhbCA9IDQu' >> "$TMPB64"
    printf '%s' 'ZHApLAogICAgICAgICAgICApCiAgICAgICAgICAgIFRleHQoCiAgICAgICAgICAgICAgICB0ZXh0ID0gIuWcqOe6v+Wjgee6uOW6' >> "$TMPB64"
    printf '%s' 'kyIsCiAgICAgICAgICAgICAgICBzdHlsZSA9IE1hdGVyaWFsVGhlbWUudHlwb2dyYXBoeS50aXRsZUxhcmdlLmNvcHkoZm9udFdl' >> "$TMPB64"
    printf '%s' 'aWdodCA9IEZvbnRXZWlnaHQuQm9sZCksCiAgICAgICAgICAgICAgICBjb2xvciA9IG11c2ljQ29sb3JzKCkudGV4dFByaW1hcnks' >> "$TMPB64"
    printf '%s' 'CiAgICAgICAgICAgICkKICAgICAgICB9CiAgICAgICAgTGF6eVJvdygKICAgICAgICAgICAgY29udGVudFBhZGRpbmcgPSBQYWRk' >> "$TMPB64"
    printf '%s' 'aW5nVmFsdWVzKGhvcml6b250YWwgPSAxNi5kcCksCiAgICAgICAgICAgIGhvcml6b250YWxBcnJhbmdlbWVudCA9IEFycmFuZ2Vt' >> "$TMPB64"
    printf '%s' 'ZW50LnNwYWNlZEJ5KDEwLmRwKSwKICAgICAgICApIHsKICAgICAgICAgICAgaXRlbXMoV1BfQ0FUUywga2V5ID0geyBpdCB9KSB7' >> "$TMPB64"
    printf '%s' 'IGMgLT4KICAgICAgICAgICAgICAgIHZhbCBzZWxlY3RlZCA9IGMgPT0gY2F0CiAgICAgICAgICAgICAgICBCb3goCiAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgbW9kaWZpZXIgPSBNb2RpZmllcgogICAgICAgICAgICAgICAgICAgICAgICAuY2xpcChSb3VuZGVkQ29ybmVy' >> "$TMPB64"
    printf '%s' 'U2hhcGUoNTApKQogICAgICAgICAgICAgICAgICAgICAgICAuYmFja2dyb3VuZChpZiAoc2VsZWN0ZWQpIG11c2ljQ29sb3JzKCku' >> "$TMPB64"
    printf '%s' 'YWNjZW50IGVsc2UgbXVzaWNDb2xvcnMoKS5jYXJkU2Vjb25kYXJ5KQogICAgICAgICAgICAgICAgICAgICAgICAuY2xpY2thYmxl' >> "$TMPB64"
    printf '%s' 'IHsgY2F0ID0gYyB9CiAgICAgICAgICAgICAgICAgICAgICAgIC5wYWRkaW5nKGhvcml6b250YWwgPSAxOC5kcCwgdmVydGljYWwg' >> "$TMPB64"
    printf '%s' 'PSA4LmRwKSwKICAgICAgICAgICAgICAgICkgewogICAgICAgICAgICAgICAgICAgIFRleHQoCiAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgIHRleHQgPSBjLAogICAgICAgICAgICAgICAgICAgICAgICBzdHlsZSA9IE1hdGVyaWFsVGhlbWUudHlwb2dyYXBoeS5ib2R5' >> "$TMPB64"
    printf '%s' 'TWVkaXVtLAogICAgICAgICAgICAgICAgICAgICAgICBjb2xvciA9IGlmIChzZWxlY3RlZCkgbXVzaWNDb2xvcnMoKS5hY2NlbnRU' >> "$TMPB64"
    printf '%s' 'ZXh0IGVsc2UgbXVzaWNDb2xvcnMoKS50ZXh0U2Vjb25kYXJ5LAogICAgICAgICAgICAgICAgICAgICkKICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'IH0KICAgICAgICAgICAgfQogICAgICAgIH0KICAgICAgICBMYXp5VmVydGljYWxHcmlkKAogICAgICAgICAgICBjb2x1bW5zID0g' >> "$TMPB64"
    printf '%s' 'R3JpZENlbGxzLkZpeGVkKDIpLAogICAgICAgICAgICBjb250ZW50UGFkZGluZyA9IFBhZGRpbmdWYWx1ZXMoMTIuZHApLAogICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICBob3Jpem9udGFsQXJyYW5nZW1lbnQgPSBBcnJhbmdlbWVudC5zcGFjZWRCeSgxMC5kcCksCiAgICAgICAgICAgIHZl' >> "$TMPB64"
    printf '%s' 'cnRpY2FsQXJyYW5nZW1lbnQgPSBBcnJhbmdlbWVudC5zcGFjZWRCeSgxMC5kcCksCiAgICAgICAgKSB7CiAgICAgICAgICAgIGl0' >> "$TMPB64"
    printf '%s' 'ZW1zKGxpc3QsIGtleSA9IHsgaXQgfSkgeyB1cmwgLT4KICAgICAgICAgICAgICAgIENhcmQoc2hhcGUgPSBSb3VuZGVkQ29ybmVy' >> "$TMPB64"
    printf '%s' 'U2hhcGUoMTQuZHApKSB7CiAgICAgICAgICAgICAgICAgICAgQXN5bmNJbWFnZSgKICAgICAgICAgICAgICAgICAgICAgICAgbW9k' >> "$TMPB64"
    printf '%s' 'ZWwgPSB1cmwucmVwbGFjZSgiLzEwODAvMTkyMCIsICIvNTQwLzk2MCIpLAogICAgICAgICAgICAgICAgICAgICAgICBjb250ZW50' >> "$TMPB64"
    printf '%s' 'RGVzY3JpcHRpb24gPSBudWxsLAogICAgICAgICAgICAgICAgICAgICAgICBjb250ZW50U2NhbGUgPSBDb250ZW50U2NhbGUuQ3Jv' >> "$TMPB64"
    printf '%s' 'cCwKICAgICAgICAgICAgICAgICAgICAgICAgbW9kaWZpZXIgPSBNb2RpZmllcgogICAgICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'LmZpbGxNYXhXaWR0aCgpCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAuYXNwZWN0UmF0aW8oMC41NmYpCiAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICAgICAgICAuY2xpY2thYmxlIHsKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBXYWxscGFwZXJNYW5h' >> "$TMPB64"
    printf '%s' 'Z2VyLmFwcGx5KGNvbnRleHQsIHVybCkKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBUb2FzdC5tYWtlVGV4dChjb250' >> "$TMPB64"
    printf '%s' 'ZXh0LCAi5aOB57q45bey5bqU55SoIiwgVG9hc3QuTEVOR1RIX1NIT1JUKS5zaG93KCkKICAgICAgICAgICAgICAgICAgICAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICBvbkJhY2soKQogICAgICAgICAgICAgICAgICAgICAgICAgICAgfSwKICAgICAgICAgICAgICAgICAgICApCiAgICAg' >> "$TMPB64"
    printf '%s' 'ICAgICAgICAgICB9CiAgICAgICAgICAgIH0KICAgICAgICB9CiAgICB9Cn0K' >> "$TMPB64"
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
echo "=== 39 wp2 完成 ==="
