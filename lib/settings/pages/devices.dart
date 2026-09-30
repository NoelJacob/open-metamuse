import 'package:material_ui/material_ui.dart';

import '../../../widgets/card.dart';
import '../../../widgets/muted_text.dart';
import '../frame.dart';

class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return SubPage(
      title: 'Devices',
      children: [
        MuseCard(
          children: [
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: MutedText('No devices connected', style: tt.bodyMedium!),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
