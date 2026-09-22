# Flutter-only surfaces — present in the clone, absent in the original

Method: every `lib/` screen, control, dialog, sheet, state, and behavior was
checked against the original sweep (`captures/orig-*.png`,
`captures/ui_orig_*.xml`), the destination registries
(`AuraDeeplinkRouteMapper`, `navigation/key/`, `navigation/entries/`), and the
audit table in `captures/PARITY-TABLE.md`. Items below have no original-side
counterpart in evidence or in the decompiled route universe. Audit-only: no
fixes proposed.

## F. Flutter-only screens and flows

| # | Clone surface | Original counterpart | Verdict | Evidence |
|---|---|---|---|---|
| F1 | Onboarding account chooser: `Choose an account`, u1 `Muse User` / u2 `Work Profile` (`lib/onboarding.dart` step 3) | None — original skips selection offline (`account_selection_required: False` in `server/orig/addon.py` `confirm_otp`) | EXTRA, keep as offline stand-in | Audit E1; no original account-selection capture exists |
| F2 | Onboarding connectors: `Link connectors (optional)`, WhatsApp/Telegram/Messenger switches, local-only toggle (`onboarding.dart` step 4) | No connectors screen reached offline; connector permission sheets exist only as keys (`ConnectorPermissionsScreenKey`, `ChannelConnectScreenKey`) | EXTRA | No original capture; stubs carry no connector UI |
| F3 | Onboarding identity: `What should Muse call you?` name field (`onboarding.dart` step 5) | Identity onboarding exists only as a key (`OnboardingIdentity…` in `navigation/entries/`); never reached in the sweep | EXTRA | No original capture; key only |
| F4 | Onboarding PIN: `Set a 4-digit PIN` (`onboarding.dart` step 7, `state.completePin`) | PIN entry exists only as keys (`ConfidentialVmRegisterPin…`, `MessengerPin/ResetPin`); the sweep's PIN submits went through the mock, no original PIN screen captured | EXTRA | No original capture; keys only |
| F5 | Hidden token shortcut: step-6 `Welcome to Muse` + `Get started` + `Meta token` field + `Login with token` (`onboarding.dart` default, `state.loginWithMetaToken`) | No equivalent screen; original token exchange is internal (`AuraTokenExchanger`) | EXTRA, dev-only | Reachable only transiently under `_busy`; invisible in normal funnel |
| F6 | `GateErrorScreen`: `Something went wrong. Please try again.`, disabled `Try again`, optional gear (`lib/gate_error.dart`) | Original error surfaces are per-branch `HatchScreenErrorState` plus retry, not a standalone gate screen | EXTRA | No original capture of a matching gate screen |
| F7 | Desktop `NavigationRail` + 720px centered content and Apple `CupertinoTabScaffold` (`lib/shell.dart` `_desktop`, `_cupertino`) | Original is a single-activity Android phone app; no rail/Cupertino chrome | EXTRA, platform-only | Out of the Pixel_9 audit universe by construction |
| F8 | Feed `Ideas` list with share/status bottom sheets (`lib/feed.dart` `_shareSheet`, `_statusSheet`) | Original IDEAS tab body near-empty in stub state; `FeedShareSheetKey`/`FeedStatusSheetKey` exist but were never opened | EXTRA | Clone renders feed units the original never showed offline |

## G. Flutter-only controls, states, and behaviors

| # | Clone behavior | Original counterpart | Verdict | Evidence |
|---|---|---|---|---|
| G1 | Thread search field in drawer (`_ThreadDrawer` TextField + `state.setSearch`/`visibleThreads`) | Drawer has no search in any capture or dump (`orig-drawer.png`, `ui_orig_drawer.xml`) | EXTRA | No original search control observed |
| G2 | Drawer `PopupMenuButton` rename/delete/archive (no Pin, no date header) | Overflow menu has Rename/**Pin**/Archive/Delete plus `September 8, 2025 at 8:30 AM` header | PARTIAL overlap: delete/archive/rename exist, Pin + date header are original-only | `orig-chat-overflow.png` vs clone menu |
| G3 | `_CardView` kinds: agent-activity spinner, connector-link, marketplace, image-via-`Image.network`, generic card | Original renders widget presentations through its own renderer; image shows text-only offline | EXTRA renderer | Clone card switch has no per-kind original counterpart in evidence |
| G4 | `AutoScrollList` animate-to-bottom on new message | Original keeps position; newest-message scroll behavior never isolated in the sweep | EXTRA behavior | No original scroll-behavior capture |
| G5 | Composer fake attachments (`fileN` chips) + `Attachment picker` / `Mic` snackbars, conditional black send circle | Attach `+` opens no menu in the sweep (`HatchAttachmentsMenu` never opened); voice goes through permission + denial overlay | EXTRA stubs | `orig-attach-open.png`, `orig-mic-permission.png`, `orig-voice-denied.png` |
| G6 | Seeded image card on `m6` in the offline fixture (`lib/api.dart` `_offline` history) | Original history is text-only at `m6` (`Here is the demo picture.`) | EXTRA fixture (documented superset) | `server/data/messages.json` now seeds `cards: []`; offline fallback still carries the card |
| G7 | `Echo: $prompt` offline GraphQL reply and `offline-token`/`vm-offline` identities | Original offline path is the stub servers, not canned fallbacks | EXTRA fixture | `lib/api.dart` `_offline` vs `server/index.js` + `server/orig/*` |
| G8 | Dead controls: Learn-more `onTap(){}` (`onboarding.dart`), `Try another way` `onPressed:{}` (`onboarding.dart`), `more_vert` header icon with no handler (`chat.dart`), theme switcher with zero call sites (`state.setThemeMode`), unread `loading` flag, unused `wakeVm` path | Original counterparts exist as keys/screens (consent pages, overflow actions, appearance settings) but were not opened | EXTRA dead ends | Zero-callsite symbols in `lib/`; keys without captures on the original side |
| G9 | `Accounts Center is a stub` snackbar; `Share is a stub` / `Copy link is a stub` / `Link is a stub` / `Get is a stub` snackbars; disabled Submit pills on feedback/report forms | Original opens real sheets, forms, and account flows | EXTRA stubs | Every snackbar callsite in `lib/`; original flows reachable only as keys |
| G10 | `Shake phone to report an issue` switch defaulting ON, local-only | Original `ShakeToReport` sheet exists as a key; default state never observed | EXTRA default | `lib/settings_pages.dart` vs unopened sheet key |
