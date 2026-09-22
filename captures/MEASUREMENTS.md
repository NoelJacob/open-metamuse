# Flutter clone ↔ original Aura parity record

Pixel_9 emulator (emulator-5554), 420dpi, screenshots 1080x2424. dp = px ÷ 2.625.
Diff method: `scripts/vd.sh <orig> <clone> <label>` — `blazediff-cli core-native -t 0.1 -a`
(pixel gate, antialiasing excluded), `msssim` (size-aware perceptual report),
`interpret --source pixel` (region table with change classification).
Row positions: `scripts/rows.py <image>`.

## Verified screens (shipped build)

| Screen | Original | Clone | MS-SSIM | Pixel diff | Anchors |
|---|---|---|---|---|---|
| Landing | `orig-landing.png` | `flutter-landing.png` | **0.931** | **1.60%** | logo/title/field/Continue |
| OTP | `orig-otp-real.png` (wrong-state: consent screen, needs true OTP redrive) | `flutter-otp.png` (keyboard-free, matches prior audit state) | n/a | n/a | Confirm `[457,1135]`, Try another way `[391,1297]` |
| Main chat | `orig-main-chat.png` | `flutter-main-chat.png` | 0.648 | 5.94% | user bubbles `559-674` (exact), `1226-1341` (anchor-2 shifted −63px by the original-true single-line quote fix; old `1289-1404` belonged to the wrapped layout) |
| ToS | not captured on original | `flutter-tos.png` | n/a | n/a | — |

## Close-gaps wave (this session): full triples MS-SSIM / SSIM / pixel

| Pair | MS-SSIM | SSIM | Pixel | Verdict |
|---|---|---|---|---|
| Notifications `orig-settings-row1` | **0.943** | **0.939** | **0.94%** | MATCHED (copy fixed: Allow notifications + OFF + caption) |
| App lock `orig-settings-row2` | **0.944** | **0.941** | **0.89%** | MATCHED (copy fixed: Require biometrics + caption) |
| Data controls `orig-settings-row4` content | 0.845 | 0.848 | **1.68%** | PARTIAL (rebuilt; component-rendering residual) |
| Help hub `orig-settings-row3` content | 0.834 | 0.842 | **1.82%** | PARTIAL (rows fixed; row-height residual) |
| Hub scrolled `orig-settings-scrolled` | 0.696 | 0.709 | **2.86%** | PARTIAL (9-row hub complete; font/icon-rendering ceiling ~0.70) |
| Msg menu `orig-msg-menu` | 0.679 | 0.670 | **4.78%** | PARTIAL (reaction bar + icon rows; transcript contamination) |
| Attach `orig-attach-open` | 0.680 | 0.674 | **4.65%** | PARTIAL (popover matches; transcript contamination) |
| Text select `orig-text-select` | 0.651 | 0.641 | 5.80% | PARTIAL (select-all highlight; no OS toolbar + header) |
| Mic permission `orig-mic-permission` | 0.644 | 0.634 | 13.92% | PARTIAL (same-state OS dialog; app-name wrap structural) |
| Share `orig-share-sheet` (wrong-state: plain transcript) | 0.611 | — | 53.5% | PARTIAL (clone sheet proven real via ChooserActivity intent; orig needs redrive) |
| Voice live `orig-voice-live` (wrong-state: keyboard + reply banner) | 0.525 | — | 82.1% | PARTIAL (clone granted sheet proven real; orig needs redrive) |
| IDEAS `orig-tab-ideas` (wrong-state: spinner) | 0.805 | 0.808 | **2.26%** | PARTIAL (clone 4-card body proven; orig needs populated redrive) |
| GOALS `orig-tab-goals` (wrong-state: spinner) | 0.933 | 0.939 | **1.64%** | FALSE PASS (empty-vs-empty; orig needs populated redrive) |
| Gate variant `orig-main-audit` (wrong-state: consent) | 0.548 | 0.451 | 77.2% | PARTIAL (clone gate-over-transcript proven; orig needs gate redrive) |

Note: `orig-settings-row3` holds Help content and `orig-settings-row4` holds
Data content (files swapped at capture time); the table rows cite content,
not filenames. `vd.sh` reports MS-SSIM + pixel; SSIM via
`blazediff-cli ssim <orig> <clone>`.

## Main chat: measured original geometry (from `ui_orig_main.xml`)

Header `Muse` [490,349][591,398]; status pill [415,409][665,451].
Date divider `SEP 8, 8:23 AM` [0,477][1080,517].

User bubbles (black `#000000`, white 15sp text), right edge **x1037** = 16dp margin:
`[256,591..][1037,644]`, `[462,1321..][1037,1374]`.

Reply attribution `Muse replied to you` (13sp `#6F7278`), left **x106** = 40dp:
y 718, 1448, 1692 — one per assistant **turn** (718 covers m2/m3/m4).

Quote cards (grey, 630px wide), left **x42** = 16dp: y 771, 1480, 1724.

Assistant bubbles (grey `#E9EAED`, 15sp `#232937`), left **x84** = 32dp:
y 914, 1009, 1162, 1596, 1840.

Composer: `+` left, placeholder `Message` [179,2085][906,2141], mic right.
Tab row (icon-only, 4): chat filled, bulb, check, grid — selected icon is **black**, unselected grey.

## Gutter system (derived, now matches within 1–4px)

ListView inset **16dp**; user bubble 0 extra right; assistant +16dp left;
quote 0 extra left; reply label +24dp left.

## Clone implementation notes

- Fonts: Optimistic Regular/Medium/Bold (`assets/fonts/`), family `Optimistic`.
- Vectors copied from the APK: `assets/icons/` (wordmark, chat filled/outline, bulb, check, grid, plus, mic, gear, help, clock, eye, avatar, logo). SVG viewBox read from each VectorDrawable's `viewportWidth/Height`.
- Brand blue `#0064E0`; assistant bubble `#E9EAED`; chat background `#F6F7F8`.
- Consecutive assistant messages sharing a `reply_group` render under one reply row + quote card (matches the original's 3 reply rows).
- Seeded history is text-only at `m6` (like the original); live sends still return an image card, and relative card URLs resolve against `ApiClient.baseUrl`.

## Known deviations

- **Header status pill**: original screenshot reads `is reconnecting` (its backend was blocked); the clone shows the honest connected state.
- Main chat residual 3.63% is concentrated in text rasterization (Flutter/Skia vs Compose glyph hinting) and the OTP keypad region; no structural additions remain.
- OTP 8.84% residual: hardware keyboard shown instead of the original's on-screen keypad, plus Confirm disabled/enabled timing.
