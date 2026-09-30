import 'package:material_ui/material_ui.dart';

import '../../../widgets/card.dart';
import '../../../widgets/row.dart';
import '../frame.dart';
import 'feedback.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  bool _shake = true;

  @override
  Widget build(BuildContext context) {
    return SubPage(
      title: 'Help & support',
      children: [
        MuseCard(
          children: [
            const MuseRow(
              label: 'Muse Help Center',
              trailing: Icon(Icons.north_east, size: 20),
            ),
            const Divider(height: 1),
            MuseRow(
              label: 'Submit feedback',
              trailing: Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.outline,
                size: 24,
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SubmitFeedbackScreen()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        MuseCard(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Shake phone to report an issue',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  Switch(
                    value: _shake,
                    onChanged: (v) => setState(() => _shake = v),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
