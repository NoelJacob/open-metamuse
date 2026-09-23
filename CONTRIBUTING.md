# Contributing: running the original Muse app (`com.facebook.aura`)

Terse path from cold checkout to manually explorable original on `Pixel_9` (`emulator-5554`).

## 0. Prerequisites

- Android SDK (`adb`, `emulator`), Flutter SDK, `mitmdump`, `openssl`, `blazediff-cli`.
- The emulator trusts the mitmproxy CA (one-time host setup, outside this doc).
- APK under test: `muse.apk` at repo root (package `com.facebook.aura`).

## Flutter clone quick loop (UI usable from `flutter run`)

```sh
python3 server/flutter-backend.py      # terminal 1: fixture mock on :8787
flutter run -d emulator-5554           # terminal 2: debug build + hot reload
adb -s emulator-5554 reverse tcp:8787 tcp:8787   # bridge app localhost → host
```

The app hardcodes `http://localhost:8787` (`lib/api.dart:56`); without the reverse bridge every screen fails into the offline canned fallback. First launch shows the notification gate (fresh install has no grants) — dismiss once, then landing → OTP (`123456`) → ToS → main chat all serve from the backend.

## 1. Boot the emulator

```sh
scripts/emu.sh start && scripts/emu.sh wait
```

## 2. Start the orig backend (one command)

Boot the emulator yourself first, then:

```sh
python3 server/backend.py orig
```

It waits for `emulator-5554`, sets the device proxy to `10.0.2.2:8080`, silences Talkback, pre-grants every `com.facebook.aura` permission, mints the mitm-CA-signed `:9443` leaf if `/tmp/gwprobe` was wiped, and brings up mitmdump (`:8080`) plus the gateway stub (`:9443`). When it prints `OK`, launch the Muse app in the emulator and browse. Ctrl-C stops both. (The `gateway` / `probe` / `intercept` modes remain for debugging; the Flutter clone is served by `python3 server/flutter-backend.py` on `:8787`.)

## 3. Wire the device

```sh
adb -s emulator-5554 shell settings put global http_proxy 10.0.2.2:8080
adb -s emulator-5554 reverse tcp:8787 tcp:8787
# Silence the screen reader so it never steals focus:
adb -s emulator-5554 shell settings put secure accessibility_enabled 0
adb -s emulator-5554 shell pm disable-user --user 0 com.google.android.marvin.talkback
```

## 4. Clear-boot and pre-grant the original

```sh
adb -s emulator-5554 shell pm clear com.facebook.aura
for PM in $(adb -s emulator-5554 shell dumpsys package com.facebook.aura | grep -oE 'android\.permission\.[A-Z_]+' | sort -u); do
  adb -s emulator-5554 shell pm grant com.facebook.aura $PM
done
adb -s emulator-5554 shell appops set com.facebook.aura POST_NOTIFICATION allow
```

`pm clear` revokes grants — re-run this block after every clear.

## 5. Launch and drive to OTP

```sh
adb -s emulator-5554 shell monkey -p com.facebook.aura -c android.intent.category.LAUNCHER 1
python3 server/driver.py --app orig to_otp test@example.com
python3 server/driver.py --app orig submit_otp 123456
```

Driver scenarios: `to_otp <email>`, `submit_otp <code>`, `shot`, `dump`, `tap_text` (native nodes only — Flutter surfaces are invisible to it), `measure`, `cold`. Raw taps elsewhere: `adb -s emulator-5554 shell input tap X Y` (device pixels, 1080x2424), long-press via `input swipe X Y X Y 1200`.

## 6. Reachable states today

- Landing, OTP, ToS (renders from the disclosure stub), logged-out Settings (gear icon).
- **Boundary:** ToS Continue does not advance (endpoint `POST /hatch/accept_tos` confirmed in `muse-decompiled/.../network/api/StefiPath.java`). Anything past ToS is unreachable until that is diagnosed via mitm stdout.

## 7. Capture for the parity table

```sh
python3 server/driver.py --app orig shot   # -> /tmp/drive2/shot.png
adb -s emulator-5554 shell uiautomator dump /sdcard/ui.xml
scripts/vd.sh captures/orig-<screen>.png captures/flutter-<screen>.png <label>  # MS-SSIM + SSIM + pixel
python3 scripts/rows.py <image>                  # row anchors
```

Rules: same-state pairs only (clocks/scroll/keyboard are contamination, never parity); every new row in `captures/PARITY-TABLE.md` cites its `orig-*.png` + `flutter-*.png` + triple or named blocker; never invent scores.

## 8. Verify the clone still builds

```sh
flutter analyze && flutter test
```
