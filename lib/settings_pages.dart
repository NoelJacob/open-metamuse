import 'package:material_ui/material_ui.dart';
import 'package:permission_handler/permission_handler.dart';

import 'state.dart';

// ponytail: static grouped-card ports; form submits stay disabled, no backend.

/// Shared sub-screen frame: grey bg, back-circle button, centered title.
class _SubPage extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SubPage({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: cs.surface,
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
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cs.surfaceContainerLow,
                        ),
                        child: Icon(Icons.arrow_back, color: cs.onSurface),
                      ),
                    ),
                  ),
                  Text(title, style: tt.headlineSmall),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
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
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(28),
      ),
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
              child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
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
  child: Divider(height: 1),
);

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
      child: Text(
        label,
        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
      ),
    );
  }
}

Widget _disabledPill(BuildContext context, String label) {
  final cs = Theme.of(context).colorScheme;
  final tt = Theme.of(context).textTheme;
  return SizedBox(
    height: 56,
    child: FilledButton(
      onPressed: null,

      child: Text(label, style: tt.labelLarge),
    ),
  );
}

Icon _chev(BuildContext context) => Icon(
  Icons.chevron_right,
  color: Theme.of(context).colorScheme.outline,
  size: 24,
);
Icon _ext(BuildContext context) => Icon(
  Icons.north_east,
  color: Theme.of(context).colorScheme.outline,
  size: 20,
);

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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return _SubPage(
      title: 'Legal info',
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: RichText(
            text: TextSpan(
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              children: [
                const TextSpan(
                  text: 'Responses are generated by AI. Some may be inaccurate or inappropriate. ',
                ),
                TextSpan(
                  text: 'Learn more',
                  style: tt.bodySmall?.copyWith(color: cs.secondary),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _Card(
          children: [
            for (var i = 0; i < _rows.length; i++) ...[
              _Row(label: _rows[i], trailing: _ext(context), onTap: null),
              if (i != _rows.length - 1) _divider(),
            ],
          ],
        ),
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
        _Card(
          children: [
            _Row(
              label: 'Muse Help Center',
              trailing: _ext(context),
              onTap: null,
            ),
            _divider(),
            _Row(
              label: 'Submit feedback',
              trailing: _chev(context),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SubmitFeedbackScreen()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _Card(
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
    return _SubPage(
      title: 'Submit feedback',
      children: [
        const _SectionLabel('Contact info'),
        const _Card(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Full name',
                  border: InputBorder.none,
                ),
              ),
            ),
            _Divider(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: TextField(
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Email',
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
        const _SectionLabel('Select a topic'),
        _Card(
          children: [
            for (var i = 0; i < _topics.length; i++) ...[
              _Row(
                label: _topics[i],
                trailing: Icon(
                  _topic == i ? Icons.check_circle : Icons.circle_outlined,
                  color: _topic == i ? cs.primary : cs.outlineVariant,
                ),
                onTap: () => setState(() => _topic = i),
              ),
              if (i != _topics.length - 1) _divider(),
            ],
          ],
        ),
        const _SectionLabel('Describe your issue'),
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(28),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              maxLines: 5,
              minLines: 5,
              decoration: InputDecoration(
                hintText: 'Describe your issue',
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _disabledPill(context, 'Submit'),
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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return _SubPage(
      title: 'Report an issue',
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Text('What went wrong?', style: tt.headlineSmall),
        ),
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(28),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              maxLines: 5,
              minLines: 5,
              decoration: InputDecoration(
                hintText: 'Describe the bug you encountered...',
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        const _SectionLabel('Attachments'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(
            Icons.add_photo_alternate_outlined,
            size: 36,
            color: cs.onSurfaceVariant,
          ),
        ),
        const _SectionLabel('Category'),
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
        _disabledPill(context, 'Submit Report'),
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
        _Card(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Allow notifications',
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
            'Get notified when your agent responds or completes a task.',
            style: Theme.of(context).textTheme.labelSmall,
          ),
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
        _Card(
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
    return _SubPage(
      title: 'Data controls',
      children: [
        _Card(
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
        _Card(
          children: [
            _Row(
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
                child: Text(
                  'Allow us to use your interactions with Muse to develop and improve AI at Meta.',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
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
        _Card(
          children: const [
            _Row(label: 'Import memory to Muse', trailing: SizedBox.shrink()),
          ],
        ),
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

class _ConnectorDefaultsScreenState extends State<ConnectorDefaultsScreen> {
  String _mode = 'some';

  @override
  Widget build(BuildContext context) {
    return _SubPage(
      title: 'Connector defaults',
      children: [
        RadioGroup<String>(
          groupValue: _mode,
          onChanged: (v) => setState(() => _mode = v!),
          child: _Card(
            children: [
              const _Row(
                label: 'Ask for some actions',
                trailing: Radio<String>(value: 'some'),
              ),
              _divider(),
              const _Row(
                label: 'Before every write and some read actions',
                trailing: Radio<String>(value: 'write'),
              ),
              _divider(),
              const _Row(
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

/// ponytail: original hub rows — Devices (honest offline empty state),
/// Appearance (wires to the real app ThemeMode), Default assistant (opens
/// OS settings; assistant choice itself is OS-owned).
class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return _SubPage(
      title: 'Devices',
      children: [
        _Card(
          children: [
            Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No devices connected',
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            ),
          ],
        ),
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
            child: _Card(
              children: [
                const _Row(
                  label: 'Light',
                  trailing: Radio<ThemeMode>(value: ThemeMode.light),
                ),
                _divider(),
                const _Row(
                  label: 'Dark',
                  trailing: Radio<ThemeMode>(value: ThemeMode.dark),
                ),
                _divider(),
                const _Row(
                  label: 'System',
                  trailing: Radio<ThemeMode>(value: ThemeMode.system),
                ),
              ],
            ),
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
        _Card(
          children: [
            _Row(
              label: 'Open system settings',
              trailing: _chev(context),
              onTap: () {
                openAppSettings();
              },
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
