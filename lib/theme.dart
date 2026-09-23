import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';

// ponytail: original Aura roles — brand BLUE_650, near-black user bubble,
// GRAY_100 assistant bubble, chat background; no seed guessing.
const museBlue = Color(0xFF0064E0);
const museUserBubble = Color(0xFF000000);
const museAgentBubble = Color(0xFFE9EAED);
const museChatBackground = Color(0xFFF6F7F8);
const musePrimaryText = Color(0xFF232937);

ThemeData museLightTheme() => ThemeData(
      useMaterial3: true,
      fontFamily: 'Optimistic',
      colorScheme: const ColorScheme.light(
        primary: museBlue,
        onPrimary: Colors.white,
        surface: Colors.white,
        onSurface: musePrimaryText,
      ),
      scaffoldBackgroundColor: museChatBackground,
    );

ThemeData museDarkTheme() => ThemeData(
      useMaterial3: true,
      fontFamily: 'Optimistic',
      colorScheme: ColorScheme.fromSeed(
          seedColor: museBlue, brightness: Brightness.dark),
      scaffoldBackgroundColor: const Color(0xFF1A1A1A),
    );

/// Muse tab vectors converted from the original APK (aura_tab_*_24.xml).
class MuseTabIcons {
  static Widget _asset(String name, {double size = 24, Color? color}) =>
      SvgPicture.asset('assets/icons/$name.svg',
          width: size,
          height: size,
          colorFilter: color == null
              ? null
              : ColorFilter.mode(color, BlendMode.srcIn));

  static Widget chatFilled({double size = 24, Color? color}) =>
      _asset('muse_chat_filled', size: size, color: color);

  static Widget chatOutline({double size = 24, Color? color}) =>
      _asset('muse_chat_outline', size: size, color: color);


  static Widget bulb({double size = 24, Color? color}) =>
      _asset('muse_bulb', size: size, color: color);
  static Widget check({double size = 24, Color? color}) =>
      _asset('muse_check', size: size, color: color);
  static Widget checkFilled({double size = 24, Color? color}) =>
      _asset('muse_check_filled', size: size, color: color);
  static Widget grid({double size = 24, Color? color}) =>
      _asset('muse_grid', size: size, color: color);
}
