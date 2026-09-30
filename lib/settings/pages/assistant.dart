import 'package:material_ui/material_ui.dart';

import '../../../widgets/card.dart';
import '../../../widgets/row.dart';

import 'package:permission_handler/permission_handler.dart';

import '../frame.dart';

class DefaultAssistantScreen extends StatelessWidget {
  const DefaultAssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SubPage(
      title: 'Set as default assistant',
      children: [
        MuseCard(
          children: [
            MuseRow(
              label: 'Open system settings',
              trailing: Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.outline,
                size: 24,
              ),
              onTap: () => openAppSettings(),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Text(
            'Choose Muse as your default assistant app in system settings.',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
      ],
    );
  }
}
