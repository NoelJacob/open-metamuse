import 'package:material_ui/material_ui.dart';

import '../../../widgets/card.dart';
import '../../../widgets/row.dart';
import '../frame.dart';

class ConnectorDefaultsScreen extends StatefulWidget {
  const ConnectorDefaultsScreen({super.key});

  @override
  State<ConnectorDefaultsScreen> createState() =>
      _ConnectorDefaultsScreenState();
}

class _ConnectorDefaultsScreenState extends State<ConnectorDefaultsScreen> {
  String _mode = 'some';

  @override
  Widget build(BuildContext context) {
    return SubPage(
      title: 'Connector defaults',
      children: [
        RadioGroup<String>(
          groupValue: _mode,
          onChanged: (v) => setState(() => _mode = v!),
          child: const MuseCard(
            children: [
              MuseRow(
                label: 'Ask for some actions',
                trailing: Radio<String>(value: 'some'),
              ),
              Divider(height: 1),
              MuseRow(
                label: 'Before every write and some read actions',
                trailing: Radio<String>(value: 'write'),
              ),
              Divider(height: 1),
              MuseRow(
                label: 'Always ask',
                trailing: Radio<String>(value: 'always'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
