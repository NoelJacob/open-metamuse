import 'package:material_ui/material_ui.dart';

import '../../../widgets/card.dart';
import '../frame.dart';

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  bool _enabled = false;

  @override
  Widget build(BuildContext context) {
    return SubPage(
      title: 'App lock',
      children: [
        MuseCard(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Require biometrics',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  Switch(
                    value: _enabled,
                    onChanged: (v) => setState(() => _enabled = v),
                  ),
                ],
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Text(
            "You'll need to use your face or fingerprint to open the Muse app.",
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
      ],
    );
  }
}
