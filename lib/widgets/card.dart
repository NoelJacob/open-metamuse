import 'package:material_ui/material_ui.dart';

class MuseCard extends StatelessWidget {
  final List<Widget> children;
  const MuseCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(children: children),
    );
  }
}
