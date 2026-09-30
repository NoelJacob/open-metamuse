import 'package:material_ui/material_ui.dart';

import '../../../widgets/button.dart';
import '../../../widgets/card.dart';
import '../../../widgets/field.dart';
import '../../../widgets/row.dart';
import '../../../widgets/section_label.dart';
import '../frame.dart';

class SubmitFeedbackScreen extends StatefulWidget {
  const SubmitFeedbackScreen({super.key});

  @override
  State<SubmitFeedbackScreen> createState() => _SubmitFeedbackScreenState();
}

class _SubmitFeedbackScreenState extends State<SubmitFeedbackScreen> {
  static const _topics = [
    'Account access and sign-in',
    "Something's not working",
    'Safety and privacy',
  ];
  int _topic = -1;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SubPage(
      title: 'Submit feedback',
      children: [
        const SectionLabel('Contact info'),
        MuseCard(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: MuseField(
                hintText: 'Full name',
                variant: MuseFieldVariant.bare,
              ),
            ),
            Divider(height: 1),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: MuseField(
                hintText: 'Email',
                keyboardType: TextInputType.emailAddress,
                variant: MuseFieldVariant.bare,
              ),
            ),
          ],
        ),
        const SectionLabel('Select a topic'),
        MuseCard(
          children: [
            for (var i = 0; i < _topics.length; i++) ...[
              MuseRow(
                label: _topics[i],
                trailing: Icon(
                  _topic == i ? Icons.check_circle : Icons.circle_outlined,
                  color: _topic == i ? cs.primary : cs.outlineVariant,
                ),
                onTap: () => setState(() => _topic = i),
              ),
              if (i != _topics.length - 1) const Divider(height: 1),
            ],
          ],
        ),
        const SectionLabel('Describe your issue'),
        MuseCard(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: MuseField(
                hintText: 'Describe your issue',
                maxLines: 5,
                minLines: 5,
                variant: MuseFieldVariant.bare,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        MuseButton.primary(onPressed: null, child: const Text('Submit')),
      ],
    );
  }
}
