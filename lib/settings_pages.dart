import 'package:flutter/material.dart';

import 'state.dart';
import 'package:permission_handler/permission_handler.dart';

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
                onTap: null),
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
              onTap: null),
          _divider(),
          _Row(
              label: 'Submit feedback',
              trailing: _chev,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const SubmitFeedbackScreen()))),
        ]),
        const SizedBox(height: 16),
        _Card(children: [
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
                trailing: Icon(
                    _topic == i
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                    color: _topic == i
                        ? const Color(0xFF0064E0)
                        : const Color(0xFFC7C9D1)),
                onTap: () => setState(() => _topic = i)),
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

/// ponytail: tapped original rows — Notifications, App lock, Data controls,
/// Connector defaults. Controls are local-only; no backend exists offline.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // ponytail: original defaults OFF with the caption below the card.
  bool _enabled = false;

  @override
  Widget build(BuildContext context) {
    return _SubPage(
      title: 'Notifications',
      children: [
        _Card(children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Allow notifications',
                      style: TextStyle(fontSize: 17, color: Colors.black)),
                ),
                Switch(
                  value: _enabled,
                  activeThumbColor: _link,
                  onChanged: (v) => setState(() => _enabled = v),
                ),
              ],
            ),
          ),
        ]),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Text(
              'Get notified when your agent responds or completes a task.',
              style: TextStyle(fontSize: 13, color: Color(0xFF6F7278))),
        ),
      ],
    );
  }
}

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  bool _enabled = false;

  @override
  Widget build(BuildContext context) {
    return _SubPage(
      title: 'App lock',
      children: [
        _Card(children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Require biometrics',
                      style: TextStyle(fontSize: 17, color: Colors.black)),
                ),
                Switch(
                  value: _enabled,
                  activeThumbColor: _link,
                  onChanged: (v) => setState(() => _enabled = v),
                ),
              ],
            ),
          ),
        ]),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Text(
              "You'll need to use your face or fingerprint to open the Muse app.",
              style: TextStyle(fontSize: 13, color: Color(0xFF6F7278))),
        ),
      ],
    );
  }
}

class DataControlsScreen extends StatefulWidget {
  const DataControlsScreen({super.key});

  @override
  State<DataControlsScreen> createState() => _DataControlsScreenState();
}

class _DataControlsScreenState extends State<DataControlsScreen> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return _SubPage(
      title: 'Data controls',
      children: [
        _Card(children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.shield_outlined,
                    size: 28, color: Colors.black),
                const SizedBox(width: 12),
                Expanded(
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(
                          fontSize: 15,
                          color: Colors.black,
                          height: 1.35),
                      children: [
                        TextSpan(
                            text: 'Your privacy is important to us\n',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        TextSpan(
                            text:
                                'Learn about the steps we take to keep your information private and secure. '),
                        TextSpan(
                            text: 'Learn more',
                            style: TextStyle(color: Color(0xFF0064E0))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ]),
        const SizedBox(height: 16),
        _Card(children: [
          _Row(
              label: 'Help improve our AI models',
              trailing: Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: const Color(0xFFC7C9D1),
                  size: 24),
              onTap: () => setState(() => _expanded = !_expanded)),
          if (_expanded)
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 18),
              child: Text(
                  'Allow us to use your interactions with Muse to develop and improve AI at Meta.',
                  style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF6F7278),
                      height: 1.35)),
            ),
        ]),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Text(
              'Allow us to use your interactions with Muse to develop and improve AI at Meta.',
              style: TextStyle(fontSize: 13, color: Color(0xFF6F7278))),
        ),
        const SizedBox(height: 16),
        _Card(children: const [
          _Row(
              label: 'Import memory to Muse',
              trailing: SizedBox.shrink()),
        ]),
      ],
    );
  }
}

class ConnectorDefaultsScreen extends StatefulWidget {
  const ConnectorDefaultsScreen({super.key});

  @override
  State<ConnectorDefaultsScreen> createState() =>
      _ConnectorDefaultsScreenState();
}

class _ConnectorDefaultsScreenState
    extends State<ConnectorDefaultsScreen> {
  String _mode = 'some';

  @override
  Widget build(BuildContext context) {
    return _SubPage(
      title: 'Connector defaults',
      children: [
        RadioGroup<String>(
          groupValue: _mode,
          onChanged: (v) => setState(() => _mode = v!),
          child: _Card(children: [
            const _Row(
                label: 'Ask for some actions',
                trailing: Radio<String>(value: 'some')),
            _divider(),
            const _Row(
                label: 'Before every write and some read actions',
                trailing: Radio<String>(value: 'write')),
            _divider(),
            const _Row(
                label: 'Always ask',
                trailing: Radio<String>(value: 'always')),
          ]),
        ),
      ],
    );
  }
}

/// ponytail: original hub rows — Devices (honest offline empty state),
/// Appearance (wires to the real app ThemeMode), Default assistant (opens
/// OS settings; assistant choice itself is OS-owned).
class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _SubPage(
      title: 'Devices',
      children: const [
        _Card(children: [
          Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Text('No devices connected',
                  style: TextStyle(fontSize: 16, color: Color(0xFF6F7278))),
            ),
          ),
        ]),
      ],
    );
  }
}

class AppearanceScreen extends StatelessWidget {
  final AppState state;
  const AppearanceScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) => _SubPage(
        title: 'Appearance',
        children: [
          RadioGroup<ThemeMode>(
            groupValue: state.themeMode,
            onChanged: (v) => state.setTheme(v!),
            child: _Card(children: [
              const _Row(
                  label: 'Light',
                  trailing: Radio<ThemeMode>(value: ThemeMode.light)),
              _divider(),
              const _Row(
                  label: 'Dark',
                  trailing: Radio<ThemeMode>(value: ThemeMode.dark)),
              _divider(),
              const _Row(
                  label: 'System',
                  trailing: Radio<ThemeMode>(value: ThemeMode.system)),
            ]),
          ),
        ],
      ),
    );
  }
}

class DefaultAssistantScreen extends StatelessWidget {
  const DefaultAssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _SubPage(
      title: 'Set as default assistant',
      children: [
        _Card(children: [
          _Row(
              label: 'Open system settings',
              trailing: _chev,
              onTap: () { openAppSettings(); }),
        ]),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Text(
              'Choose Muse as your default assistant app in system settings.',
              style: TextStyle(fontSize: 13, color: Color(0xFF6F7278))),
        ),
      ],
    );
  }
}
