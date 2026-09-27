import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

enum MuseIconAsset {
  avatar('muse_avatar'),
  bulb('muse_bulb'),
  chatFilled('muse_chat_filled'),
  chatOutline('muse_chat_outline'),
  check('muse_check'),
  checkFilled('muse_check_filled'),
  clock('muse_clock'),
  close('muse_close'),
  eye('muse_eye'),
  gear('muse_gear'),
  grid('muse_grid'),
  help('muse_help'),
  logo('muse_logo'),
  mic('muse_mic'),
  plus('muse_plus'),
  rectangleAlert('muse_rectangle_alert'),
  search('muse_search'),
  settingsGear('muse_settings_gear'),
  shieldCheck('muse_shield_check'),
  shieldSmall('muse_shield_small');

  const MuseIconAsset(this.file);
  final String file;
}

class MuseIcon extends StatelessWidget {
  const MuseIcon(this.asset, {super.key, this.size = 24, this.color});

  final MuseIconAsset asset;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    'assets/icons/${asset.file}.svg',
    width: size,
    height: size,
    colorFilter: color == null
        ? null
        : ColorFilter.mode(color!, BlendMode.srcIn),
  );
}
