import 'package:flutter/material.dart';

// ponytail: static grouped-card ports; form submits stay disabled, no backend.
const _bg = Color(0xFFF0F1F5);
const _muted = Color(0xFF6F7278);
const _link = Color(0xFF0064E0);
const _paleBlue = Color(0xFFB4CFFC);

/// Shared sub-screen frame: grey bg, back-circle button, centered title.
class _SubPage extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SubPage({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: Colors.white),
                        child: const Icon(Icons.arrow_back,
                            color: Colors.black),
                      ),
                    ),
                  ),
                  Text(title,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(28)),
      child: Column(children: children),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final Widget trailing;
  final VoidCallback? onTap;
  const _Row({required this.label, required this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 17, color: Colors.black)),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

Widget _divider() => const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Divider(height: 1, color: Color(0xFFE8E9ED)),
    );

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
      child: Text(label,
          style: const TextStyle(fontSize: 15, color: _muted)),
    );
  }
}

Widget _disabledPill(String label) => SizedBox(
      height: 56,
      child: FilledButton(
        onPressed: null,
        style: FilledButton.styleFrom(
          shape: const StadiumBorder(),
          disabledBackgroundColor: _paleBlue,
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white70)),
      ),
    );

void _stub(BuildContext context, String what) {
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text('$what is a stub')));
}

const _chev =
    Icon(Icons.chevron_right, color: Color(0xFFC7C9D1), size: 24);
const _ext = Icon(Icons.north_east, color: Color(0xFFC7C9D1), size: 20);

class LegalInfoScreen extends StatelessWidget {
  const LegalInfoScreen({super.key});

  static const _rows = [
    'Muse Supplemental Terms',
    'Muse Supplemental Privacy Policy',
    "Meta's AI Terms of Service",
    'Meta Terms of Service',
    'Meta Privacy Policy',
    'Meta Platform Technologies Supplemental Terms',
    'Meta Platform Technologies Supplemental Privacy Policy',
  ];

  @override
  Widget build(BuildContext context) {
    return _SubPage(
      title: 'Legal info',
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 15, color: _muted, height: 1.35),
              children: [
                TextSpan(
                    text:
                        'Responses are generated by AI. Some may be inaccurate or inappropriate. '),
                TextSpan(
                    text: 'Learn more',
                    style: TextStyle(color: _link)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _Card(children: [
          for (var i = 0; i < _rows.length; i++) ...[
            _Row(
                label: _rows[i],
                trailing: _ext,
                onTap: () => _stub(context, _rows[i])),
            if (i != _rows.length - 1) _divider(),
          ],
        ]),
      ],
    );
  }
}

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  bool _shake = true; // ponytail: local-only default ON per capture.

  @override
  Widget build(BuildContext context) {
    return _SubPage(
      title: 'Help & support',
      children: [
        _Card(children: [
          _Row(
              label: 'Muse Help Center',
              trailing: _ext,
              onTap: () => _stub(context, 'Muse Help Center')),
          _divider(),
          _Row(
              label: 'Contact customer support',
              trailing: _chev,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const SubmitFeedbackScreen()))),
        ]),
        const SizedBox(height: 16),
        _Card(children: [
          _Row(
              label: 'Report an issue',
              trailing: _chev,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const ReportIssueScreen()))),
          _divider(),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Shake phone to report an issue',
                      style:
                          TextStyle(fontSize: 17, color: Colors.black)),
                ),
                Switch(
                  value: _shake,
                  activeThumbColor: _link,
                  onChanged: (v) => setState(() => _shake = v),
                ),
              ],
            ),
          ),
        ]),
      ],
    );
  }
}

class SubmitFeedbackScreen extends StatelessWidget {
  const SubmitFeedbackScreen({super.key});

  static const _topics = [
    'Account access and sign-in',
    "Something's not working",
    'Safety and privacy',
  ];

  @override
  Widget build(BuildContext context) {
    return _SubPage(
      title: 'Submit feedback',
      children: [
        const _SectionLabel('Contact info'),
        const _Card(children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: TextField(
              decoration: InputDecoration(
                  hintText: 'Full name',
                  hintStyle: TextStyle(fontSize: 17, color: _muted),
                  border: InputBorder.none),
            ),
          ),
          _Divider(),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: TextField(
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                  hintText: 'Email',
                  hintStyle: TextStyle(fontSize: 17, color: _muted),
                  border: InputBorder.none),
            ),
          ),
        ]),
        const _SectionLabel('Select a topic'),
        _Card(children: [
          for (var i = 0; i < _topics.length; i++) ...[
            _Row(
                label: _topics[i],
                trailing: const SizedBox.shrink(),
                onTap: () => _stub(context, _topics[i])),
            if (i != _topics.length - 1) _divider(),
          ],
        ]),
        const _SectionLabel('Describe your issue'),
        Container(
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28)),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              maxLines: 5,
              minLines: 5,
              decoration: InputDecoration(
                  hintText: 'Describe your issue',
                  hintStyle: TextStyle(fontSize: 17, color: _muted),
                  border: InputBorder.none),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _disabledPill('Submit'),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => _divider();
}

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
    return _SubPage(
      title: 'Report an issue',
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Text('What went wrong?',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black)),
        ),
        Container(
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28)),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              maxLines: 5,
              minLines: 5,
              decoration: InputDecoration(
                  hintText: 'Describe the bug you encountered...',
                  hintStyle: TextStyle(fontSize: 17, color: _muted),
                  border: InputBorder.none),
            ),
          ),
        ),
        const _SectionLabel('Attachments'),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.add_photo_alternate_outlined,
              size: 36, color: _muted),
        ),
        const _SectionLabel('Category'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (icon, label) in _cats)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                      color: const Color(0xFFE2E3E8), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 18, color: Colors.black),
                    const SizedBox(width: 6),
                    Text(label,
                        style: const TextStyle(
                            fontSize: 15, color: Colors.black)),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 32),
        _disabledPill('Submit Report'),
      ],
    );
  }
}
