import 'package:material_ui/material_ui.dart';

import '../../../widgets/button.dart';
import '../../../widgets/card.dart';
import '../../../widgets/field.dart';
import '../../../widgets/section_label.dart';
import '../frame.dart';

class ReportIssueScreen extends StatelessWidget {
  const ReportIssueScreen({super.key});

  static const _cats = [
    (Icons.account_circle_outlined, 'Accounts/Activation'),
    (Icons.bolt_outlined, 'Agent status and activity'),
    (Icons.folder_outlined, 'Artifacts'),
    (Icons.image_outlined, 'Media'),
    (Icons.auto_awesome_outlined, 'Connectors'),
    (Icons.chat_bubble_outline, 'Main chat'),
    (Icons.chat_outlined, 'Side chats'),
    (Icons.track_changes_outlined, 'Goals'),
    (Icons.lightbulb_outline, 'Ideas'),
    (Icons.settings_outlined, 'Settings'),
    (Icons.graphic_eq, 'Voice'),
    (Icons.more_horiz, 'Other'),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return SubPage(
      title: 'Report an issue',
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Text('What went wrong?', style: tt.headlineSmall),
        ),
        MuseCard(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: MuseField(
                hintText: 'Describe the bug you encountered...',
                maxLines: 5,
                minLines: 5,
                variant: MuseFieldVariant.bare,
              ),
            ),
          ],
        ),
        const SectionLabel('Attachments'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(
            Icons.add_photo_alternate_outlined,
            size: 36,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SectionLabel('Category'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (icon, label) in _cats)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: cs.outlineVariant, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 18, color: cs.onSurface),
                    const SizedBox(width: 6),
                    Text(label, style: tt.titleSmall),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 32),
        MuseButton.primary(onPressed: null, child: const Text('Submit Report')),
      ],
    );
  }
}
