import 'package:material_ui/material_ui.dart';

import 'icons/muse.dart';
import 'settings.dart';
import 'state.dart';

// ponytail: static disclosure + one accept call; no webview for legal links.
class TosScreen extends StatefulWidget {
  final AppState state;
  const TosScreen({super.key, required this.state});

  @override
  State<TosScreen> createState() => _TosScreenState();
}

class _TosScreenState extends State<TosScreen> {
  bool _busy = false;

  static const _rows = [
    (
      MuseIconAsset.shieldCheck,
      'Can take actions for you',
      "With your approval, your agent can send messages, edit files, make purchases, and take actions in apps you've connected. You control what it can access in Settings.",
    ),
    (
      MuseIconAsset.clock,
      'Works around the clock',
      'Your agent can continue working on tasks after you close the app. Check in to keep it on track and intervene if needed.',
    ),
    (
      MuseIconAsset.eye,
      'Smart, but still learning',
      "It may make mistakes or take unexpected actions. It's built to ask before taking sensitive actions, but supervision is recommended.",
    ),
  ];

  Future<void> _continue() async {
    setState(() => _busy = true);
    try {
      await widget.state.api.acceptTos();
    } catch (_) {
      // ponytail: best-effort server record; local acceptance still counts.
    } finally {
      widget.state.setTosAccepted(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 64),
                        Center(
                          child: MuseIcon(
                            MuseIconAsset.logo,
                            size: 76,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Before you get started',
                          textAlign: TextAlign.center,
                          style: tt.displayMedium,
                        ),
                        const SizedBox(height: 28),
                        for (final (icon, title, body) in _rows) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              MuseIcon(icon, size: 28),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(title, style: tt.titleMedium),
                                    const SizedBox(height: 4),
                                    Text(
                                      body,
                                      style: tt.bodySmall!.copyWith(
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: RichText(
                    text: TextSpan(
                      style: tt.labelSmall,
                      children: [
                        TextSpan(
                          text: 'By using this product, you agree to the ',
                        ),
                        TextSpan(
                          text: 'Muse Terms',
                          style: tt.labelSmall!.copyWith(color: cs.secondary),
                        ),
                        TextSpan(
                          text: ', which contains important information about your rights and responsibilities. Muse is subject to ',
                        ),
                        TextSpan(
                          text: "Meta's AI Terms",
                          style: tt.labelSmall!.copyWith(color: cs.secondary),
                        ),
                        TextSpan(text: ' and the '),
                        TextSpan(
                          text: 'Meta Privacy Policy',
                          style: tt.labelSmall!.copyWith(color: cs.secondary),
                        ),
                        TextSpan(text: '.'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    height: 56,
                    child: FilledButton(
                      onPressed: _busy ? null : _continue,
                      child: _busy
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: cs.onPrimary,
                              ),
                            )
                          : Text('Continue', style: tt.labelLarge),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
            Positioned(
              top: 8,
              right: 16,
              child: InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SettingsScreen(state: widget.state),
                  ),
                ),
                customBorder: const CircleBorder(),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: cs.outline, width: 1.5),
                  ),
                  child: Center(child: MuseIcon(MuseIconAsset.gear, size: 24)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
