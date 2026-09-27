# UI Pattern

How screens in this repo are built. Follow it for every new screen; do not invent rival patterns. Each rule names the file that satisfies it and the violation it forbids.

## 1. One screen per file (`lib/welcome/welcome.dart`, `lib/welcome/otp.dart`)

Each file is one route: a stateless shell (scaffold, chrome, layout) plus one stateful form (inputs, validation, submit). `Welcome` + `EmailForm` share `welcome.dart`; `Otp` + `OtpForm` share `otp.dart`. Never put two routes in one file, never split one route across files. The old `onboarding.dart` (357 lines, every step in one `_step` switch) is the deleted anti-pattern, not a reference.

## 2. Shell owns layout, form owns state (`welcome.dart:8-51`, `otp.dart:10-69`)

The shell is a `StatelessWidget`: `Scaffold` → `SafeArea` → `SingleChildScrollView(horizontal: 16)` → `Column(stretch)`. It renders titles (`displayLarge`/`displayMedium`), icons (`MuseLogo.large`, `MuseGearButton.medium`), static text, and embeds exactly one form. The form (`EmailForm`, `OtpForm`) is a `StatefulWidget` with `RunAsync`: controllers, `_formKey`, `_code`, validation, submit. The shell never holds a controller; the form never renders a scaffold.

## 3. Shared chrome lives in `lib/widgets/` (`button.dart`, `logo.dart`)

`MuseButton.primary` owns height 48, the `busy` spinner, and `styleFrom` — screens pass `onPressed`/`busy`/`child` and nothing else. `MuseGearButton`/`MuseBackButton.medium` own the 48 circle and `onSurfaceVariant` icon. `MuseLogo.large` owns the logo. Screens never hand-roll `FilledButton.styleFrom`, `BoxDecoration` circles, or `SvgPicture.asset` paths. If chrome appears twice, it moves to `lib/widgets/` on the second use.

## 4. Async work goes through `RunAsync` (`helpers.dart:5-69`)

`class _XFormState extends State<XForm> with RunAsync<XForm>`. The mixin owns `_busy`/`_error` — the widget declares neither. Read via `busyAsync`/`errorAsync`, run work via `runAsync(() async { ... })`, render errors with `...errorMessageAsync()`. `ApiError` is caught inside the mixin; the form only sees the message string. No `setState` for busy/error outside the mixin.

## 5. Theme reads, never literals (`welcome.dart:12-13`, `otp.dart:15-16`)

Each `build` starts with `final cs = Theme.of(context).colorScheme;` and `final tt = Theme.of(context).textTheme;`. Colors come from `cs.*`, text from `tt.*`, artwork from `MuseIconAsset`. Link blue is `cs.secondary` (the scheme wires `brandBlue` there in both brightnesses) — never `MusePalette.*` directly from a screen. `grep -n 'Color(0xFF\|Colors\.\|MusePalette' lib/welcome/*.dart` must print nothing. Violation on disk: `otp.dart:46` uses `MusePalette.linkLight`, a light-only constant, so it paints the same blue on the dark background. `lib/theme.dart` is generated/decoded work — screens consume it through the scheme, never extend it.

## 6. Router moves between screens (`main.dart:20-42`)

Routes are path-based nested `GoRoute`s: `/welcome` with child `otp`. The guard uses `matchedLocation.startsWith('/welcome')` so the whole subtree stays reachable while logged out; plain `== '/welcome'` would bounce `/welcome/otp` straight back. Navigation is `context.push('/welcome/otp')` (keeps a back entry for `context.pop()`) — never `pushNamed` without a route `name:`, never a `_step` switch. `AppState.create()` runs before `runApp` (`main.dart:10-14`), and the router refreshes off `sessionStage` + `themeMode` via `Listenable.merge`.

## 7. State owns persistence, screens own nothing (`internal/state.dart:19-84`)

`AppState` holds `ValueNotifier`s (`themeMode`, `userId`, `sessionStage`); every setter writes through (`setThemeMode` → prefs, `setUserId` → secure storage, `setSessionStage` → prefs) with `unawaited` fire-and-forget, guarded by early-return on no-change. Secrets (`userId`) live in `FlutterSecureStorage`, plain values in `SharedPreferencesAsync`; `_getStringSafe` swallows storage failures so a broken store can never block launch. Screens never touch storage directly — they read notifiers and call setters. `TODO:` one-liners name the exact missing call (`confirmOtp`, `startPhone`). A file is done when it analyzes clean with only TODOs remaining.
