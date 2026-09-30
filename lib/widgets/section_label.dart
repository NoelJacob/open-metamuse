import 'package:material_ui/material_ui.dart';

class SectionLabel extends StatelessWidget {
  final String label;
  const SectionLabel(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
      child: Text(label, style: tt.bodySmall),
    );
  }
}
