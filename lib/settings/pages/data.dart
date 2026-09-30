import 'package:material_ui/material_ui.dart';

import '../../../widgets/card.dart';
import '../../../widgets/muted_text.dart';
import '../../../widgets/row.dart';
import '../frame.dart';

class DataControlsScreen extends StatefulWidget {
  const DataControlsScreen({super.key});

  @override
  State<DataControlsScreen> createState() => _DataControlsScreenState();
}

class _DataControlsScreenState extends State<DataControlsScreen> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return SubPage(
      title: 'Data controls',
      children: [
        MuseCard(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_outlined, size: 28, color: cs.onSurface),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: tt.bodySmall?.copyWith(color: cs.onSurface),
                        children: [
                          TextSpan(
                            text: 'Your privacy is important to us\n',
                            style: tt.titleSmall,
                          ),
                          const TextSpan(
                            text: 'Learn about the steps we take to keep your information private and secure. ',
                          ),
                          TextSpan(
                            text: 'Learn more',
                            style: tt.bodySmall?.copyWith(color: cs.secondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        MuseCard(
          children: [
            MuseRow(
              label: 'Help improve our AI models',
              trailing: Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                color: cs.outline,
                size: 24,
              ),
              onTap: () => setState(() => _expanded = !_expanded),
            ),
            if (_expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                child: MutedText(
                  'Allow us to use your interactions with Muse to develop and improve AI at Meta.',
                  style: tt.bodySmall!,
                ),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Text(
            'Allow us to use your interactions with Muse to develop and improve AI at Meta.',
            style: tt.labelSmall,
          ),
        ),
        const SizedBox(height: 16),
        const MuseCard(
          children: [
            MuseRow(
              label: 'Import memory to Muse',
              trailing: SizedBox.shrink(),
            ),
          ],
        ),
      ],
    );
  }
}
