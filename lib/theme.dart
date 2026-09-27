import 'package:material_ui/material_ui.dart';

// Sole hex source: captures/COLOR-TABLE.md via scripts/decode_colors.py.
// Every value below carries its table row name. `unverified` rows (toast,
// tab-unselected, switch, menu popover, link-dark) are never consumed here.

/// Decoded Aura palette: one const per COLOR-TABLE.md row, per brightness.
class MusePalette {
  // App background (surface.background)
  static const appBackgroundLight = Color(0xFFFCFCFC);
  static const appBackgroundDark = Color(0xFF050505);

  // Chat background (painted canvas)
  static const chatBackgroundLight = Color(0xFFFCFCFC);
  static const chatBackgroundDark = Color(0xFF050505);

  // Chat background (conversation default, unpainted)
  static const chatDefaultLight = Color(0xFFF5F5F5);
  static const chatDefaultDark = Color(0xFF1A1A1A);

  // User bubble
  static const userBubbleLight = Color(0xFF000000);
  static const userBubbleDark = Color(0xFFFFFFFF);

  // User text
  static const userTextLight = Color(0xFFFFFFFF);
  static const userTextDark = Color(0xFF111112);

  // Agent bubble
  static const agentBubbleLight = Color(0xFFE9EAEB);
  static const agentBubbleDark = Color(0xFF1F1F1F);

  // Agent text
  static const agentTextLight = Color(0xFF111112);
  static const agentTextDark = Color(0xFFF5F5F5);

  // Quote card fill (surface.bubble)
  static const quoteFillLight = Color(0xFFE9EAEB);
  static const quoteFillDark = Color(0xFF1F1F1F);

  // Reply attribution text
  static const replyAttributionLight = Color(0x99000409);
  static const replyAttributionDark = Color(0x66F1F6FF);

  // Primary button bg
  static const primaryButtonLight = Color(0xFF0064D4);
  static const primaryButtonDark = Color(0xFF007FFD);

  // Primary button text
  static const primaryButtonTextLight = Color(0xFFFFFFFF);
  static const primaryButtonTextDark = Color(0xFF000000);

  // Brand blue (links, resend, icons)
  static const brandBlue = Color(0xFF0064E0);

  // Destructive button bg
  static const destructiveLight = Color(0xFFC01F37);
  static const destructiveDark = Color(0xFFE7354A);

  // Secondary pill bg
  static const secondaryPillLight = Color(0xFFF3F4F5);
  static const secondaryPillDark = Color(0xFF1F1F1F);

  // Settings card fill (surface.card)
  static const cardLight = Color(0xFFFFFFFF);
  static const cardDark = Color(0xFF1F1F1F);

  // Elevated surface
  static const elevatedLight = Color(0xFFEEEFF0);
  static const elevatedDark = Color(0xFF343638);

  // Dialog/modal surface
  static const dialogLight = Color(0xFFFFFFFF);
  static const dialogDark = Color(0xFF1F1F1F);

  // Divider
  static const dividerLight = Color(0x1A000000);
  static const dividerDark = Color(0x1FFFFFFF);

  // Border (OTP boxes, text fields)
  static const borderLight = Color(0xFF343434);
  static const borderDark = Color(0xFFA1A1A1);

  // Primary text
  static const primaryTextLight = Color(0xFF111112);
  static const primaryTextDark = Color(0xFFF5F5F5);

  // Secondary text
  static const secondaryTextLight = Color(0x99000409);
  static const secondaryTextDark = Color(0x99F2F7FF);

  // Tertiary text
  static const tertiaryTextLight = Color(0x59000711);
  static const tertiaryTextDark = Color(0x66F1F6FF);

  // Quaternary text
  static const quaternaryTextLight = Color(0x4A000814);
  static const quaternaryTextDark = Color(0x4FF0F6FF);

  // Hint / placeholder
  static const hintLight = Color(0xFFA1A4A8);
  static const hintDark = Color(0xFFA1A1A1);

  // Cursor
  static const cursor = Color(0xFF638FFF);

  // Error text / bg
  static const errorTextLight = Color(0xFFFF453A);
  static const errorTextDark = Color(0xFFFF6877);
  static const errorBg = Color(0xFFFF3040);

  // Success
  static const successLight = Color(0xFF25B159);
  static const successDark = Color(0xFF00EA57);

  // Success icon
  static const successIcon = Color(0xFF008200);

  // Inactive / disabled
  static const inactive = Color(0xFF8E8E93);

  // Negative accent
  static const negativeAccent = Color(0xFFF05F69);

  // Scrim
  static const scrimLight = Color(0x4D000000);
  static const scrimDark = Color(0x80000000);

  // Shadow
  static const shadow = Color(0x33000000);

  // Shimmer base / highlight
  static const shimmerBaseLight = Color(0xFFDCE0E5);
  static const shimmerHighlightLight = Color(0xFFF1F4F7);
  static const shimmerBaseDark = Color(0xFF1C2B33);
  static const shimmerHighlightDark = Color(0xFF30424B);

  // Avatar border
  static const avatarBorderLight = Color(0x0F000000);
  static const avatarBorderDark = Color(0x0FFFFFFF);

  // Tab selected
  static const tabSelectedLight = Color(0xFF000000);
  static const tabSelectedDark = Color(0xFFFFFFFF);

  // Notification badge
  static const badge = Color(0xFFFF3040);

  // Composer pill fill (surface.bubble)
  static const composerLight = Color(0xFFE9EAEB);
  static const composerDark = Color(0xFF1F1F1F);

  // Date divider text (same tokens as secondary text)
  static const dateDividerLight = Color(0x99000409);
  static const dateDividerDark = Color(0x99F2F7FF);

  // Link / accent text (light only; dark unverified)
  static const linkLight = Color(0xFF0064E0);
}

/// Conversation tokens, outside ColorScheme like HatchConversationTheme.
class MuseChatColors {
  final Color background;
  final Color userBubble;
  final Color userText;
  final Color agentBubble;
  final Color agentText;
  final Color quoteFill;
  final Color replyAttribution;

  const MuseChatColors({
    required this.background,
    required this.userBubble,
    required this.userText,
    required this.agentBubble,
    required this.agentText,
    required this.quoteFill,
    required this.replyAttribution,
  });

  static MuseChatColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const MuseChatColors(
          background: MusePalette.chatBackgroundDark,
          userBubble: MusePalette.userBubbleDark,
          userText: MusePalette.userTextDark,
          agentBubble: MusePalette.agentBubbleDark,
          agentText: MusePalette.agentTextDark,
          quoteFill: MusePalette.quoteFillDark,
          replyAttribution: MusePalette.replyAttributionDark,
        )
      : const MuseChatColors(
          background: MusePalette.chatBackgroundLight,
          userBubble: MusePalette.userBubbleLight,
          userText: MusePalette.userTextLight,
          agentBubble: MusePalette.agentBubbleLight,
          agentText: MusePalette.agentTextLight,
          quoteFill: MusePalette.quoteFillLight,
          replyAttribution: MusePalette.replyAttributionLight,
        );
}

TextTheme _museTextTheme(Brightness b) {
  final dark = b == Brightness.dark;
  final onSurface = dark
      ? MusePalette.primaryTextDark
      : MusePalette.primaryTextLight;
  final onVariant = dark
      ? MusePalette.secondaryTextDark
      : MusePalette.secondaryTextLight;
  return TextTheme(
    displayLarge: TextStyle(
      fontSize: 34,
      fontWeight: FontWeight.w700,
      height: 1.02,
    ),
    displayMedium: TextStyle(
      fontSize: 30,
      fontWeight: FontWeight.w700,
      height: 1.1,
    ),
    headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
    headlineSmall: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      height: 1.25,
    ),
    titleLarge: TextStyle(
      fontSize: 19,
      fontWeight: FontWeight.w700,
      height: 1.0,
    ),
    titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
    titleSmall: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(fontSize: 17, height: 1.35),
    bodyMedium: TextStyle(fontSize: 16, height: 1.35),
    bodySmall: TextStyle(fontSize: 15, height: 1.35, color: onVariant),
    labelLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    labelMedium: TextStyle(fontSize: 14),
    labelSmall: TextStyle(fontSize: 13, height: 1.35, color: onVariant),
  );
}

ColorScheme _museScheme(Brightness b) {
  final dark = b == Brightness.dark;
  return ColorScheme(
    brightness: b,
    primary: dark
        ? MusePalette.primaryButtonDark
        : MusePalette.primaryButtonLight,
    onPrimary: dark
        ? MusePalette.primaryButtonTextDark
        : MusePalette.primaryButtonTextLight,
    secondary: MusePalette.brandBlue,
    onSecondary: dark
        ? MusePalette.primaryButtonTextDark
        : MusePalette.primaryButtonTextLight,
    tertiary: dark ? MusePalette.successDark : MusePalette.successLight,
    onTertiary: MusePalette.userBubbleLight,
    error: dark ? MusePalette.destructiveDark : MusePalette.destructiveLight,
    onError: dark
        ? MusePalette.primaryButtonTextDark
        : MusePalette.primaryButtonTextLight,
    surface: dark
        ? MusePalette.appBackgroundDark
        : MusePalette.appBackgroundLight,
    onSurface: dark
        ? MusePalette.primaryTextDark
        : MusePalette.primaryTextLight,
    onSurfaceVariant: dark
        ? MusePalette.secondaryTextDark
        : MusePalette.secondaryTextLight,
    surfaceContainerLow: dark ? MusePalette.cardDark : MusePalette.cardLight,
    surfaceContainerHigh: dark
        ? MusePalette.elevatedDark
        : MusePalette.elevatedLight,
    secondaryContainer: dark
        ? MusePalette.secondaryPillDark
        : MusePalette.secondaryPillLight,
    onSecondaryContainer: dark
        ? MusePalette.primaryTextDark
        : MusePalette.primaryTextLight,
    outline: dark ? MusePalette.borderDark : MusePalette.borderLight,
    outlineVariant: dark ? MusePalette.dividerDark : MusePalette.dividerLight,
    scrim: dark ? MusePalette.scrimDark : MusePalette.scrimLight,
    shadow: MusePalette.shadow,
  );
}

ColorScheme _museSchemeFromSeed(Brightness b) {
  final dark = b == Brightness.dark;
  return ColorScheme.fromSeed(
    seedColor: dark
        ? MusePalette.primaryButtonDark
        : MusePalette.primaryButtonLight,
    dynamicSchemeVariant: .vibrant,
    brightness: b,
    surface: dark
        ? MusePalette.appBackgroundDark
        : MusePalette.appBackgroundLight,
  );
}

ThemeData _museTheme(Brightness b) {
  // final dark = b == Brightness.dark;
  // final scheme = _museScheme(b);
  // final hint = dark ? MusePalette.hintDark : MusePalette.hintLight;
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Optimistic',
    colorScheme: _museSchemeFromSeed(b),
    textTheme: _museTextTheme(b),
    // scaffoldBackgroundColor: scheme.surface,
    // hintColor: hint,
    // disabledColor: MusePalette.inactive,
    // filledButtonTheme: FilledButtonThemeData(
    //   style: FilledButton.styleFrom(
    //     shape: const StadiumBorder(),
    //     disabledBackgroundColor: scheme.surfaceContainerHigh,
    //     disabledForegroundColor: MusePalette.inactive,
    //   ),
    // ),
    // dialogTheme: DialogThemeData(
    //   backgroundColor: dark ? MusePalette.dialogDark : MusePalette.dialogLight,
    // ),
    // dividerTheme: DividerThemeData(
    //   color: scheme.outlineVariant,
    //   thickness: 1,
    //   space: 1,
    // ),
    // textSelectionTheme: TextSelectionThemeData(cursorColor: MusePalette.cursor),
    // inputDecorationTheme: InputDecorationTheme(
    //   hintStyle: TextStyle(fontSize: 17, color: hint),
    // ),
  );
}

ThemeData museLightTheme() => _museTheme(Brightness.light);

ThemeData museDarkTheme() => _museTheme(Brightness.dark);
