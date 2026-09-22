#!/usr/bin/env bash
# Clean-boot funnel for the Flutter clone on Pixel_9 (emulator-5554).
# Usage: funnel.sh [landing|otp|main]  (default: main)
# Leaves the app on the requested screen; prints the visible text nodes.
set -u
DEV=emulator-5554
PKG=com.metamuse.flutter.openmetamuse
adb -s "$DEV" reverse tcp:8787 tcp:8787 >/dev/null 2>&1
adb -s "$DEV" shell pm clear "$PKG" >/dev/null 2>&1; sleep 2
# ponytail: pm clear revokes grants — re-grant so no OS prompt interrupts the loop.
adb -s "$DEV" shell pm grant "$PKG" android.permission.RECORD_AUDIO >/dev/null 2>&1
adb -s "$DEV" shell appops set "$PKG" POST_NOTIFICATION allow >/dev/null 2>&1
adb -s "$DEV" shell pm grant "$PKG" android.permission.POST_NOTIFICATIONS >/dev/null 2>&1
adb -s "$DEV" shell am start -n "$PKG"/.MainActivity >/dev/null 2>&1; sleep 7
tap3264() { adb -s "$DEV" shell input tap 540 "$1"; sleep "$2"; }
case "${1:-main}" in
  landing) ;;
  *)
    tap3264 820 1
    adb -s "$DEV" shell 'input text "test@example.com"'; sleep 1
    tap3264 1050 4
    for d in 1 2 3 4 5 6; do adb -s "$DEV" shell input keyevent KEYCODE_$d; sleep 0.2; done
    sleep 10
    ;;
esac
case "${1:-main}" in
  landing|otp) ;;
  *) tap3264 2260 7 ;;
esac
adb -s "$DEV" shell uiautomator dump --compressed /sdcard/ui_fun.xml >/dev/null 2>&1
adb -s "$DEV" pull /sdcard/ui_fun.xml /tmp/ui_fun.xml >/dev/null 2>&1
python3 -c "
import re
x = open('/tmp/ui_fun.xml').read()
seen=[]
for m in re.finditer(r'<node[^>]*>', x):
    t = m.group(0)
    txt = re.search(r'text=\"([^\"]*)\"', t)
    if txt and txt.group(1).strip() and txt.group(1) not in seen:
        seen.append(txt.group(1)); print(repr(txt.group(1)[:45]))
" 2>/dev/null | head -n 8
