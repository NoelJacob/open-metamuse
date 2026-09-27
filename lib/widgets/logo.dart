import 'package:material_ui/material_ui.dart';

import '../icons/muse.dart';

class MuseLogo extends StatelessWidget {
  const MuseLogo.large({super.key}) : size = 84;

  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return MuseIcon(MuseIconAsset.logo, size: size, color: cs.onSurface);
  }
}
