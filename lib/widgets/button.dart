import 'package:material_ui/material_ui.dart';

import '../icons/muse.dart';

class MuseButton extends StatelessWidget {
  const MuseButton.primary({
    super.key,
    required this.onPressed,
    required this.child,
    this.busy = false,
  }) : height = 48;

  final VoidCallback? onPressed;
  final Widget child;
  final double height;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FilledButton(
      onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(minimumSize: Size.fromHeight(height)),
      child: busy
          ? CircularProgressIndicator(
              constraints: BoxConstraints(
                minWidth: height / 2,
                minHeight: height / 2,
              ),
              strokeWidth: 2,
              color: cs.onPrimary,
            )
          : child,
    );
  }
}

class MuseGearButton extends StatelessWidget {
  const MuseGearButton.medium({super.key, required this.onPressed}) : size = 48;

  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onPressed,
      customBorder: const CircleBorder(),
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: MuseIcon(
            MuseIconAsset.gear,
            size: size / 2,
            color: cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class MuseBackButton extends StatelessWidget {
  const MuseBackButton.medium({super.key, required this.onPressed}) : size = 48;

  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onPressed,
      customBorder: const CircleBorder(),
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Icon(
            Icons.arrow_back,
            size: size / 2,
            color: cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
