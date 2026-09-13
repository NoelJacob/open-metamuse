import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// ponytail: single seed + two scaffold colors covers brand theming.
const museBlue = Color(0xFF5890FF);

ThemeData museLightTheme() => ThemeData(
      useMaterial3: true,
      fontFamily: 'Optimistic',
      colorScheme: ColorScheme.fromSeed(seedColor: museBlue),
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    );

ThemeData museDarkTheme() => ThemeData(
      useMaterial3: true,
      fontFamily: 'Optimistic',
      colorScheme: ColorScheme.fromSeed(
          seedColor: museBlue, brightness: Brightness.dark),
      scaffoldBackgroundColor: const Color(0xFF1A1A1A),
    );

/// Exact Muse tab vectors (24px viewport) rendered via inline SVG strings.
class MuseTabIcons {
  static const String chatFilledPath =
      'M12,1.375C18.363,1.375 23.875,5.729 23.875,11.5C23.875,17.271 18.363,21.625 12,21.625C10.191,21.625 8.472,21.279 6.931,20.658C5.638,21.584 4.026,22.205 2.07,22.472C1.591,22.537 1.123,22.289 0.909,21.855C0.695,21.422 0.783,20.899 1.126,20.559C1.744,19.945 2.124,19.1 2.124,18.164C2.124,17.6 1.984,17.068 1.741,16.602C0.723,15.115 0.125,13.373 0.125,11.5C0.125,5.729 5.637,1.375 12,1.375Z';
  // ponytail: outline = filled path + evenOdd cutout, one element, no extra asset.
  static const String chatCutoutPath =
      'M12,3.625C6.489,3.625 2.375,7.33 2.375,11.5C2.375,12.815 2.773,14.062 3.489,15.168L3.637,15.388L3.705,15.499C4.131,16.293 4.374,17.203 4.374,18.164C4.374,18.667 4.307,19.154 4.183,19.617C4.914,19.317 5.527,18.939 6.039,18.504L6.171,18.408C6.491,18.208 6.895,18.179 7.244,18.342C8.643,18.996 10.264,19.375 12,19.375C17.511,19.375 21.625,15.67 21.625,11.5C21.625,7.33 17.511,3.625 12,3.625Z';

  static String _svg(String d, {bool evenOdd = false}) =>
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">'
      '<path d="$d" fill="#000000"${evenOdd ? ' fill-rule="evenodd"' : ''}/></svg>';

  static Widget chatFilled({double size = 24, Color? color}) =>
      SvgPicture.string(_svg(chatFilledPath),
          width: size,
          height: size,
          colorFilter: color == null
              ? null
              : ColorFilter.mode(color, BlendMode.srcIn));

  static Widget chatOutline({double size = 24, Color? color}) =>
      SvgPicture.string(_svg('$chatFilledPath $chatCutoutPath', evenOdd: true),
          width: size,
          height: size,
          colorFilter: color == null
              ? null
              : ColorFilter.mode(color, BlendMode.srcIn));

  // ponytail: remaining tabs are APK vectors; asset files beat inline strings.
  static Widget _asset(String name, {double size = 24, Color? color}) =>
      SvgPicture.asset('assets/$name.svg',
          width: size,
          height: size,
          colorFilter: color == null
              ? null
              : ColorFilter.mode(color, BlendMode.srcIn));

  static Widget bulb({double size = 24, Color? color}) =>
      _asset('muse_bulb', size: size, color: color);
  static Widget check({double size = 24, Color? color}) =>
      _asset('muse_check', size: size, color: color);
  static Widget checkFilled({double size = 24, Color? color}) =>
      _asset('muse_check_filled', size: size, color: color);
  static Widget grid({double size = 24, Color? color}) =>
      _asset('muse_grid', size: size, color: color);
}
