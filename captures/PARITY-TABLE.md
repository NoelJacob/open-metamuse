# Parity table — original Aura vs Flutter clone (contrarian audit)

Method: original-first sweep on Pixel_9 (emulator-5554) with stubs healthy,
every control tapped, captures plus dumps per screen; code back-check in
`muse-decompiled/`; clone driven to the same state and scored with
`scripts/vd.sh` (core-native −t 0.1 −a pixel gate, MS-SSIM report, interpret
regions). Evidence: `captures/orig-<screen>.png` + `captures/ui_orig_<screen>.xml`,
`captures/flutter-<screen>.png`, `scripts/vd.sh` diffs.
No fixes proposed. Clock/keyboard/scroll contamination is noted, never scored.

## A. Verified pairs (same-state captures + scores)

| # | Original screen | Clone screen | Status | Evidence |
|---|---|---|---|---|
| A1 | Landing: logo, `Welcome to Muse`, pill field, SMS notice + Learn more, `Continue` pill, gear circle | Landing: same chrome, Continue disabled until non-empty | MATCHED | Re-verified this session: MS-SSIM 0.931 / SSIM 0.926 / pixel 1.60% (within ±0.01/±0.3px of 0.934/1.54%) |
| A2 | OTP: back circle, logo, `Enter your code`, instruction + Resend, 6 cells, `Confirm`, `Try another way`, numeric keypad | OTP: same rows, Confirm disabled until 6 digits, keyevents accepted | PARTIAL | CONTRARIAN FLAG: `orig-otp-real.png` on disk is a consent screen, not an OTP screen — the recorded 0.838/8.84% cannot be a same-state OTP triple (state-mismatch, unscoreable until a true orig OTP is captured past the ToS gate); clone `flutter-otp.png` matches the prior keyboard-free audit state |
| A3 | Main chat: hamburger, `Muse`, status pill, date divider, user black / assistant grey bubbles, reply rows + quotes, composer `+`/`Message`/mic, 4-tab icon row | Same transcript, AutoScroll, turn-grouped reply/quote, ↩ reply-row arrows, single-line full-width quote cards, plain `Message` hint | PARTIAL | Triple MS-SSIM 0.648 / SSIM 0.639 / pixel 5.94%; user-bubble anchor `559-674` exact, anchor-2 `1226-1341` (shifted −63px by the original-true quote fix); residuals: `is reconnecting` header (backend-driven), font rendering; pixel gate broken by tighter layout shifting scroll vs the wrapped-layout original |
| A4 | ToS: `Before you get started`, 3 disclosure rows, legal links, Continue | `TosScreen`: same rows, `Muse Terms`/`Meta's AI Terms`/`Meta Privacy Policy` links, Continue | PARTIAL | `orig-tos.png` vs `flutter-tos.png`: capture-only, no `vd.sh` pair run this pass; legal links open Chrome (502 on facebook.com via stub) vs static text |
| A5 | Notification permission: `Allow Muse to send you notifications?`, Allow / Don't allow | First-run gate over main chat: bell icon, bold-`Muse` title, blue Allow pill, grey Don't-allow pill; either answer proceeds | PARTIAL | `orig-notif-permission.png` vs `flutter-notif-gate.png`: MS-SSIM 0.708, pixel 12.67%; single-shot semantics verified (no re-show); main chat untouched after dismiss  Residuals vs original: grey bell icon (original filled blue) and grey Don\u2019t-allow pill white label (original dark-blue pill); behavior (once-only, either answer proceeds, main untouched) verified. |
| A6 | Side thread (`Paris weekend`): title row, `Message in Paris weekend` composer | Drawer switches threads; title row plus per-thread placeholder shown | PARTIAL | `orig-side-thread.png` vs `flutter-audit-thread.png`: capture-only, no score run |

## B. Drawer, thread management, composer, message interactions

| # | Original | Clone | Status | Evidence |
|---|---|---|---|---|
| B1 | Drawer: `Muse` header, `Main chat`, `Side chats`, thread rows, Settings gear, `Archived`, `New side chat` | Drawer with rows, Archived entry, working settings gear, per-thread menus | PARTIAL | `orig-drawer.png` vs `flutter-drawer.png`: drawer pair MS-SSIM 0.672, pixel 7.79%; gear verified opening Settings hub; new-chat entry still open (no create-thread endpoint offline) |
| B2 | Chat overflow: `September 8, 2025 at 8:30 AM` header, Rename / Pin / Archive / Delete | PopupMenu: Rename / Pin / Archive / Delete; Pin reorders via `pinThread` | PARTIAL | Date header still absent; Pin + ordering verified in code, device pass owed |
| B3 | Rename dialog: `Rename side chat`, prefilled field, Cancel / Save | AlertDialog `Rename thread`, prefilled field, Cancel / Save | MATCHED | `orig-chat-rename.png` rows match; copy differs only in "side chat" vs "thread" |
| B4 | Archive confirm: `Archive this side chat?`, `Any recurring tasks will be moved…`, Cancel / Archive | `_confirm` dialog with original recurring-tasks copy | MATCHED | Copy aligned in `lib/chat.dart`; dialog renders the original's warning text |
| B5 | Attach (`+`): white popover above composer, Camera / Photos / Videos / Files, outline icons | Same popover (Camera/Photos/Videos/Files, camera/image/circle-play/paperclip); picks upload real fixture bytes via `POST /api/fs/upload` (measured `bytes_written`) and render from `/api/fs/raw` | MATCHED | `orig-attach-menu.png` vs `flutter-attach-popover.png`: MS-SSIM 0.701; round-trip proven (`muse-wordmark.png`, 5943 bytes identical); fixture picks stand in for real pickers |
| B6 | Voice input: `Allow Muse to record audio?` → `Microphone access denied` → `Open settings` / Cancel | Real `RECORD_AUDIO` request; deny path shows the floating denial dialog with original copy; Open settings launches OS settings (verified via dumpsys); granted path shows listening state (no recorder fixture offline) | PARTIAL | `orig-mic-permission.png`, `orig-voice-denied.png` + XMLs vs `flutter-mic-denied.png`; permission+denial+settings-nav verified on-device |
| B7 | Message long-press menu: Reply / Copy / Select / Share | `_MenuBubble` with 7-emoji reaction bar + outlined-icon rows, left-anchored; Copy writes real clipboard, Reply opens banner, Select swaps in-bubble select-all highlight, Share fires system sheet (ChooserActivity intent) | PARTIAL | Menu chrome matches (`flutter-msg-menu.png` MS-SSIM 0.679 / pixel 4.78%, pixel gate passes); reaction taps dismiss-only (no stub endpoint); full-screen MS-SSIM blocked by transcript contamination |
| B8 | Inline reply: `Replying to Muse` composer state | Banner with quoted target, sent prefix `[replying to …]`, cleared on send (verified: `[replying to Day 1…] noted` in `chat/send`) | MATCHED | Send-clear circuit closed on-device (`flutter-wave1-sent.png`); structured quote card remains a polish item |
| B9 | Share sheet / text select | Chat `_MenuBubble` (reaction bar + Reply/Copy/Select/Share icon rows), `Share.share(text)` system sheet (intent-verified), select-all highlight in-bubble | PARTIAL | Menu `flutter-msg-menu.png` vs `orig-msg-menu.png`: MS-SSIM 0.679 / pixel 4.78% (pixel gate passes; MS-SSIM blocked by transcript scroll + header contamination); reaction taps dismiss-only (no stub endpoint) |

## C. Tabs, library, goals, ideas

| # | Original | Clone | Status | Evidence |
|---|---|---|---|---|
| C1 | IDEAS tab content (empty in stub state) | `FeedScreen`: Ideas list, share/status sheets, settings gear | PARTIAL | `orig-tab-ideas.png` + `ui_orig_ideas.xml` vs `flutter-audit-tabs.png`: capture-only; original tab body near-empty, clone renders feed units |
| C2 | GOALS tab content (empty in stub state) | `TasksScreen` empty state + `_GoalSheet` creation sheet (FAB → title field → Create) with `AppState.goals`/`addGoal` persistence + `ListenableBuilder` rows | PARTIAL | Creation loop proven on-device (`flutter-goal-sheet.png` sheet, `flutter-goal-created.png` persisted row); detail sheets blocked: no `GoalDetailScreenKey` in `lib/` or `server/data/` (no per-goal stub shapes) |
| C3 | LIBRARY: `Artifacts` / `Media` segmented tabs, `More options`, `Muse` header, `Connection Error` pill | Segmented Artifacts/Media with both empty states, `More options` → `System Files` | MATCHED | `orig-tab-library.png` vs `flutter-library.png`: MS-SSIM 0.883, pixel 2.26% |
| C4 | Artifacts empty state: `Nothing created yet`, `When you create something…` | Same empty state in Artifacts segment | MATCHED | Covered by the C3 pair |
| C5 | Media empty state: `No Media yet`, `When you capture photos…` | Same empty state in Media segment | MATCHED | `orig-library-media.png` vs `flutter-library-media.png`: MS-SSIM 0.854, pixel 2.65% |
| C6 | Library overflow → `System Files` (empty screen) | Overflow `System Files` entry plus empty screen with back navigation | MATCHED | `orig-system-files.png` vs `flutter-library-sysfiles.png`: MS-SSIM 0.953, pixel 0.55% |
| C7 | Deep links `hatch://chat|feed|goals|library|settings|status|memory|search|connectors|explore|invite|activity|artifacts` all land in `AuraMainActivity` | No deep-link handling | NOT APPLICABLE | Probe log: every intent resolves to main activity; per-route effects need per-route state fixtures the stubs do not provide |

## D. Settings hub and sub-screens

| # | Original | Clone | Status | Evidence |
|---|---|---|---|---|
| D1 | Hub rows reached by tap: Notifications, Appearance, App lock, Set as default assistant, Data controls, Report an issue, Help & support, Legal info, Connector defaults, Accounts Center | Hub with all rows in orig order + back-arrow header + bare rows; Notifications MATCHED 0.943/0.94%, App lock MATCHED 0.944/0.89% | PARTIAL | New rows verified on-device (Devices empty-state, Appearance theme radios, DefaultAssistant OS-settings row, Report-issue destination); hub triple 0.696/2.86% (font-rendering ceiling) |
| D2 | Legal hub rows: `Muse Supplemental Terms`, `Muse Supplemental Privacy Policy`, `Meta's AI Terms of Service`, `Meta Terms of Service`, `Meta Privacy Policy`, `Meta Platform Technologies…` (from `LegalInfoScreen._rows`, matches `LegalSafetySettingsEntryProvider`) | Same 7-row list with north-east icons, stub taps | MATCHED | `lib/settings_pages.dart` rows vs provider registry; no original legal-subscreen capture in this pass |
| D3 | Help hub rows + destinations | HelpSupportScreen (Help Center ext, Submit feedback → form, shake ON) + ReportIssueScreen (existing destination wired as hub row) | MATCHED | `flutter-settings-row4.png` proves the fixed hub rows; Submit feedback and Report-an-issue forms pre-verified |
| D4 | Logout dialog | `Log out` / `Are you sure you want to log out?` / red Log out / Cancel (`settings.dart` `_logoutDialog`, signOut + popToFirst) | PARTIAL | Clone `flutter-logout-dialog.png` proves the dialog; original dialog behind the ToS gate this boot — needs orig redrive unlocked |
| D5 | Wallet/payments, subscription hub/paywall, devices/permissions, memory, search, account-center internals, app lock overlay, voice-call screens, spaces, wearables, invite/waitlist/age/geo branches | None | NOT APPLICABLE | Keys exist (`WalletSettingsScreenKey`, `AuraSubscriptionSheetKey`, `ConnectedDevicesScreenKey`, `DevicePermissionsSettingsScreenKey`, `ImportMemoryToHatch…`, `VoiceCall…`, `SpacesModal…`, activation states) but need permissions, payment, account-link, or live backends unavailable offline |

## E. Contradictions and extras checked

| # | Claim tested | Verdict | Evidence |
|---|---|---|---|
| E1 | Clone `_accounts` (u1 `Muse User`, u2 `Work Profile`) needs real APK account data | CONTRADICTED | Clone list is a stub for the offline `select_account` contract (`server/index.js`, `lib/api.dart`); the original skips account selection offline (`account_selection_required: False`), so no original account structure exists to copy |
| E2 | Clone needs a real tab-bar mapping review | CONTRADICTED | Clone already carries copied APK vectors and black selected tint (`lib/theme.dart` `MuseTabIcons`, `lib/shell.dart` `_TabCell`); original dump confirms icon-only row plus selected states |
| E3 | OTP field content / status-bar clocks / scroll position / keyboard visibility as parity failures | CONTRADICTED | Contamination to control, per plan; scores reuse masked pairs only |
| E4 | Clone has no Pin screen / ToS accept path | CONTRADICTED | `lib/onboarding.dart` step 7 PIN plus `completePin`, `TosScreen` accept call exist and were driven in the funnel |

## F. Future work — unscored on-disk pairs (no scores invented)

| # | Original screen | Clone screen | Status | Evidence |
|---|---|---|---|---|
| F1 | ToS post-OTP state (orig-tos.png + ui_orig_tos.xml) | flutter-tos-state.png | FUTURE | Original: `orig-tos.png` + `ui_orig_tos.xml`; clone target: `flutter-tos-state.png`; drive: drive2.py to_otp + submit_otp; triple: MS-SSIM — / SSIM — / pixel — |
| F2 | Post-OTP transitional (orig-postotp.png + ui_orig_postotp.xml) | flutter-postotp.png | FUTURE | Original: `orig-postotp.png` + `ui_orig_postotp.xml`; clone target: `flutter-postotp.png`; drive: drive2.py submit_otp, capture pre-activation; triple: MS-SSIM — / SSIM — / pixel — |
| F3 | Try-another-way error (orig-tryanother.png + ui_orig_tryanother.xml) | flutter-tryanother.png | FUTURE | Original: `orig-tryanother.png` + `ui_orig_tryanother.xml`; clone target: `flutter-tryanother.png`; drive: drive2.py tap_text Try another way; clone 401 state; triple: MS-SSIM — / SSIM — / pixel — |
| F4 | Logged-out Settings (orig-loggedout-settings-true.png: Help & support / Legal info / Accounts Center / Log out) | flutter-loggedout-settings.png | PARTIAL | Audit find: clone showed the full post-login hub when logged out — fixed by `loggedOut` guards in `SettingsScreen` (`state.stage != SessionStage.main` hides 7 inner rows + Connector card); triple MS-SSIM 0.865 / SSIM 0.872 / pixel 1.32%; residual is header (back-arrow vs gear) + font rendering |
| F5 | Landing fresh-boot variant (orig-landing-fresh.png + ui_orig_landing_fresh.xml) | DUPLICATE-OF-A1 | FUTURE | Original: `orig-landing-fresh.png` + `ui_orig_landing_fresh.xml`; clone target: `DUPLICATE-OF-A1`; drive: drive2.py cold; no capture needed; triple: MS-SSIM — / SSIM — / pixel — |
| F6 | Drawer full state (orig-drawer-full.png + ui_orig_drawer.xml) | flutter-drawer-full.png | FUTURE | Original: `orig-drawer-full.png` + `ui_orig_drawer.xml`; clone target: `flutter-drawer-full.png`; drive: drive2.py tap_text Open side panel; triple: MS-SSIM — / SSIM — / pixel — |
| F7 | Drawer post-archive (orig-drawer-postarchive.png + ui_orig_drawer_postarchive.xml) | flutter-drawer-archived.png | FUTURE | Original: `orig-drawer-postarchive.png` + `ui_orig_drawer_postarchive.xml`; clone target: `flutter-drawer-archived.png`; drive: drive2.py archive flow; clone _confirm Archive; triple: MS-SSIM — / SSIM — / pixel — |
| F8 | Chat overflow menu (orig-chat-overflow.png + ui_orig_chat_overflow.xml) | flutter-chat-overflow.png | FUTURE | Original: `orig-chat-overflow.png` + `ui_orig_chat_overflow.xml`; clone target: `flutter-chat-overflow.png`; drive: drive2.py tap_text More options; triple: MS-SSIM — / SSIM — / pixel — |
| F9 | Rename dialog (orig-chat-rename.png + ui_orig_rename.xml) | flutter-rename.png | FUTURE | Original: `orig-chat-rename.png` + `ui_orig_rename.xml`; clone target: `flutter-rename.png`; drive: drive2.py tap_text Rename; clone _rename; triple: MS-SSIM — / SSIM — / pixel — |
| F10 | Library overflow (orig-library-overflow.png + ui_orig_overflow.xml) | flutter-library-overflow.png | FUTURE | Original: `orig-library-overflow.png` + `ui_orig_overflow.xml`; clone target: `flutter-library-overflow.png`; drive: drive2.py More options; clone Library popup; triple: MS-SSIM — / SSIM — / pixel — |
| F11 | Message long-press menu (orig-msg-menu.png + ui_orig_msgmenu.xml) | flutter-msg-menu.png | PARTIAL | Clone `_MenuBubble` now matches structure (7-emoji reaction bar + Reply/Copy/Select/Share outlined-icon rows, left-anchored); triple MS-SSIM 0.679 / pixel 4.78% (pixel gate passes); residual is transcript scroll + header contamination, not menu chrome |
| F12 | Inline reply state (orig-inline-reply.png + ui_orig_inlinereply.xml) | flutter-inline-reply.png | FUTURE | Original: `orig-inline-reply.png` + `ui_orig_inlinereply.xml`; clone target: `flutter-inline-reply.png`; drive: adb long-press + Reply; clone replyTarget banner; triple: MS-SSIM — / SSIM — / pixel — |
| F13 | Share sheet (orig-share-sheet.png + ui_orig_share.xml) | flutter-share-sheet.png | PARTIAL | Clone `flutter-share-sheet.png` shows the real system chooser with bubble text (ChooserActivity intent in logcat); `orig-share-sheet.png` is wrong-state (plain transcript, no sheet) — needs orig redrive past the ToS gate; triple vs wrong-state pair: MS-SSIM 0.611 / pixel 53.5% (state mismatch, not a parity gap) |
| F14 | Text select (orig-text-select.png + ui_orig_textselect.xml) | flutter-text-select.png | PARTIAL | Clone `flutter-text-select.png` shows in-bubble blue select-all highlight (same transcript as orig); triple MS-SSIM 0.651 / pixel 5.8%; residual: no floating OS toolbar (long-press on field keeps selection, summons nothing) + `is reconnecting` header present in orig only; user-bubble rows exact (559-674 vs 559-675) |
| F15 | Attach popover (orig-attach-open.png + ui_orig_attach.xml) | flutter-attach-closed.png | PARTIAL | Clone `flutter-attach-closed.png` shows the open popover (Photos/Videos/Files + Camera cut off above — card taller than crop); triple MS-SSIM 0.680 / pixel 4.65% (pixel gate passes); residual is transcript scroll contamination |
| F16 | Voice live granted (orig-voice-live.png + ui_orig_voicelive.xml) | flutter-voice-live.png | PARTIAL | Clone `flutter-voice-live.png` shows the real granted sheet (`Voice input / Listening... speak now`, permission grant via uiautomator bounds tap); `orig-voice-live.png` is wrong-state (open keyboard + reply banner, no voice UI) — needs orig redrive unlocked; triple vs wrong-state pair MS-SSIM 0.525 / pixel 82.1% (state mismatch, not a parity gap); no recorder offline (honest fixture note kept) |
| F17 | Mic permission dialog (orig-mic-permission.png + ui_orig_micperm.xml) | flutter-mic-permission.png | PARTIAL | Same-state OS dialog pair; triple MS-SSIM 0.644 / pixel 13.92%; residuals structural: OS-owned app-name line wrap (`openmetamuse` vs `Muse`), `is reconnecting` header present in orig only, clock contamination; this wave also fixed two real gaps visible in the pair (reply-row ↩ arrow, plain `Message` hint) |
| F18 | IDEAS tab (orig-tab-ideas.png + ui_orig_ideas.xml) | flutter-ideas.png | PARTIAL | Clone `flutter-ideas.png` shows the real 4-card fixture body; `orig-tab-ideas.png` is wrong-state (loading spinner + `is reconnecting`, no body) — needs populated orig redrive; triple vs wrong-state pair MS-SSIM 0.805 / SSIM 0.808 / pixel 2.26% (two mostly-white screens agreeing) |
| F19 | GOALS tab (orig-tab-goals.png + ui_orig_goals.xml) | flutter-goals.png | PARTIAL | Clone `flutter-goals.png` shows the real empty state + FAB; `orig-tab-goals.png` is wrong-state (reconnecting spinner, no body) — needs populated orig redrive; triple vs wrong-state pair MS-SSIM 0.933 / SSIM 0.939 / pixel 1.64% is a FALSE PASS (empty-vs-empty), not a GOALS-body proof |
| F20 | Settings Notifications (orig-settings-row1.png) | flutter-settings-row1.png | MATCHED | Same-state pair; copy fixed to `Allow notifications` + OFF default + caption below card; triple MS-SSIM 0.943 / SSIM 0.939 / pixel 0.94% — all gates pass |
| F21 | Settings App lock (orig-settings-row2.png) | flutter-settings-row2.png | MATCHED | Same-state pair; copy fixed to `Require biometrics` + caption; triple MS-SSIM 0.944 / SSIM 0.941 / pixel 0.89% — all gates pass |
| F22 | Settings Data controls (orig-settings-row4.png content; row3/row4 files swapped at capture) | flutter-settings-row3.png | PARTIAL | Structure + copy rebuilt (privacy shield card, expandable improve row, caption, import row); triple MS-SSIM 0.845 / SSIM 0.848 / pixel 1.68%; residual is component rendering (switch/chevron glyphs, body font), not layout |
| F23 | Settings Help hub (orig-settings-row3.png content; row3/row4 files swapped at capture) | flutter-settings-row4.png | PARTIAL | Rows fixed (`Muse Help Center` + `Submit feedback` + shake ON); triple MS-SSIM 0.834 / SSIM 0.842 / pixel 1.82%; residual is row-height/typography bands, not structure |
| F24 | Settings hub scrolled (orig-settings-scrolled.png) | flutter-settings-scrolled.png | PARTIAL | Hub completed to 9 rows in orig order (Devices/Appearance/Set-default/Report-issue added; Devices empty-state, Appearance wires real themeMode, DefaultAssistant opens OS settings) + back-arrow header + bare rows; triple MS-SSIM 0.696 / SSIM 0.709 / pixel 2.86%; residual is font/icon rendering across the dense frame (systematic ~0.70 ceiling; sparse screens pass, dense cannot) |
| F25 | Notif gate scrolled bg (orig-main-audit.png) | flutter-notif-gate-scrolled.png | PARTIAL | Clone capture is the real gate over a scrolled transcript; `orig-main-audit.png` is wrong-state (`Before you get started` consent, no gate) — needs orig gate-over-chat redrive unlocked; triple vs wrong-state pair MS-SSIM 0.548 / SSIM 0.451 / pixel 77.2% (state mismatch) |

## G. Unlock pass — new stub routes plus deep-link results (no clone changes)

Stub routes added this pass (`server/orig/addon.py` `request()`, mirrored in
`server/orig/gwhttps.py` `_route()`; all verified via direct curl against
:9443 with `result` envelopes): `api/feed/units`, `api/goals/list`,
`api/goals/detail`, `api/library/artifacts`, `api/library/media`,
`api/spaces/list`, `api/memory/list`, `api/connectors/list`,
`api/subscription`, `api/settings/notifications`, `api/settings/data-controls`,
`api/search`. All 8+ routes fire at app boot (prefetch hits in `mitmorig.log`),
but tab bodies render header chrome only — bodies key off other
endpoint/envelope shapes (unverified — confirm first).

Deep links fired (27 total, `hatch://chat|feed|goals|library|settings|status|memory|search|connectors|spaces|invite|explore|subscription_hub|thread|connect|homehub|activity|artifacts|item|media|paywall|settings/devices`): every one lands in `AuraMainActivity` with no distinct content change; per-route sessioned intents with params remain unverified.

New evidence this pass: `orig-ideas-body.png`, `orig-notif-gate2.png` + `ui_orig_notif2.xml`, `orig-tos-terms-webview2.png`, `orig-drawer-current.png` + `ui_orig_drawer_full2.xml`.

Baselines still reproduce after the stub work: landing 0.934/1.54%, OTP 0.836/8.88%, main chat 0.698/3.62% with both anchors exact (559-674, 1289-1404).

## H. New-screen scores (unlock pass, gate-down captures)

| # | Original screen | Clone screen | Status | Evidence |
|---|---|---|---|---|
| H1 | IDEAS tab body (`orig-ideas-body.png`) | `flutter-new-ideas.png` (IDEAS tab, same boot) | PARTIAL | MS-SSIM 0.807, pixel 2.25%, 17 regions; tab body renders header chrome on both, bodies differ by stub data |
| H2 | LIBRARY tab (`orig-tab-library.png`) | `flutter-new-library.png` (Artifacts segment) | MATCHED | MS-SSIM 0.884, pixel 2.25%, 16 regions; segments plus empty states align |
| H3 | Drawer full state (`orig-drawer-current.png`) | `flutter-new-drawer.png` (open drawer) | PARTIAL | MS-SSIM 0.862, pixel 2.42%, 19 regions; rows align, gear-row placement delta noted in B1 |
| F26 | ToS full unlocked (orig-tos-true.png: `Terms of Service (stub)` + 3 disclosure sections + Continue, rendered from the fixed disclosure stub) | flutter-tos-full.png | PARTIAL | Original now renders past `tos_status` (disclosure stub works); accept does not advance after 4 measured attempts (2 taps + press-hold + scroll-then-tap on `primary_button` [53,2182][1027,2308], endpoint POST `/hatch/accept_tos` confirmed in `StefiPath.java:16`) — blocker: accept-tos no-advance, needs supervised-proxy mitm stdout to distinguish button vs POST vs follow-up |
| F27 | Notification gate fresh (orig-f-notif.png) | flutter-notif-gate-fresh.png | PARTIAL | Gate proven rendering on this build (edge-swipe capture); gate now suppressed in the funnel loop by pre-grants (user instruction) + `Permission.notification.isGranted` early return; original pair needs same-state comparison in an unlocked session |

## I. Implementation status per table row (finding only, no scores invented)

| Row | Backing in `lib/` | Verdict |
|---|---|---|
| F1 ToS post-OTP | `TosScreen` (`lib/tos.dart`) renders rows + links + Continue | IMPLEMENTED |
| F2 Post-OTP transition | No transition frame widget; `OnboardingFlow` jumps activation→main | NOT IMPLEMENTED (`lib/onboarding.dart`: no transition state) |
| F3 Try-another state | No error-state screen; OTP shows inline `_error` text only | PARTIAL (`_otpPage` error text; no dedicated state) |
| F4 Logged-out Settings | `SettingsScreen` pushed from landing gear (`_loggedOutSettings`) | IMPLEMENTED |
| F5 Landing fresh-boot | Same `OnboardingFlow` landing | IMPLEMENTED (duplicate of A1) |
| F6 Drawer full | `_ThreadDrawer` (`lib/chat.dart`) with rows + gear + menus | IMPLEMENTED |
| F7 Drawer post-archive | Same drawer; archived row is static text, no filtered view | PARTIAL (no archived-view state in `AppState`) |
| F8 Chat overflow | Thread `PopupMenuButton` Rename/Pin/Archive/Delete, no date header | PARTIAL (date header absent) |
| F9 Rename dialog | `_rename` AlertDialog, prefilled + Cancel/Save | IMPLEMENTED |
| F10 Library overflow | Library `PopupMenuButton` System Files entry | IMPLEMENTED |
| F11 Long-press menu | `_MenuBubble` reaction bar + outlined-icon rows; Copy/Reply/Select/Share real, reaction taps dismiss-only (no stub endpoint) | PARTIAL (reaction taps dismiss-only) |
| F12 Inline reply | Reply banner + quoted send + clear (`replyTarget`, `_replyTo`) | IMPLEMENTED |
| F13 Share sheet | `Share.share(text)` (`lib/chat.dart:656`), `share_plus` (`pubspec.yaml:40`); system chooser proven via ChooserActivity intent | IMPLEMENTED |
| F14 Text select | `_BubbleText` select-all + `_MenuBubbleState._selecting` (`lib/chat.dart:577,665`); highlight proven, no OS toolbar/handles | PARTIAL (no OS toolbar/handles) |
| F15 Attach popover | `ComposerBar` popover (Camera/Photos/Videos/Files); open state proven on-device | PARTIAL (Camera row cut off above capture crop) |
| F16 Voice live | Granted branch shows listening sheet, no recorder | PARTIAL (no recorder fixture offline) |
| F17 Mic permission dialog | System dialog is OS-owned; denial overlay implemented | IMPLEMENTED (overlay) + NOT APPLICABLE (OS dialog) |
| F18 IDEAS tab | `FeedScreen` 4-card fixture body proven on-device | PARTIAL (orig capture is a reconnecting spinner, needs populated redrive) |
| F19 GOALS tab | `TasksScreen` empty + FAB + `_GoalSheet` with `AppState.goals`/`addGoal` persistence, creation loop proven | PARTIAL (no detail sheets; orig capture is a spinner, needs populated redrive) |
| F20 Notifications screen | `NotificationsScreen` (`Allow notifications` + OFF + caption) | MATCHED (0.943/0.939/0.94%) |
| F21 App lock screen | `AppLockScreen` (`Require biometrics` + caption) | MATCHED (0.944/0.941/0.89%) |
| F22 Data controls screen | rebuilt (privacy shield card, expandable improve row, caption, import row) | PARTIAL (0.845/0.848/1.68%; component-rendering residual) |
| F23 Help hub screen | rows fixed (Help Center + Submit feedback + shake ON) | PARTIAL (0.834/0.842/1.82%; row-height residual) |
| F24 Scrolled hub | 9-row hub in orig order (Devices/Appearance/Set-default/Report-issue added) + back-arrow header + bare rows | PARTIAL (0.696/0.709/2.86%; font-rendering ceiling) |
| F25 Gate scrolled-bg variant | Shell `_notifGate` dialog (any transcript behind) | IMPLEMENTED |
| F26 ToS full + scrolled | `TosScreen` scrollable rows + legal footer | IMPLEMENTED |
| F27 Gate pre-dismiss | Same shell `_notifGate` dialog | IMPLEMENTED (same dialog) |
