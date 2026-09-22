import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
      'assets/icons/muse_shield_check.svg',
      'Can take actions for you',
      "With your approval, your agent can send messages, edit files, make purchases, and take actions in apps you've connected. You control what it can access in Settings.",
    ),
    (
      'assets/icons/muse_clock.svg',
      'Works around the clock',
      'Your agent can continue working on tasks after you close the app. Check in to keep it on track and intervene if needed.',
    ),
    (
      'assets/icons/muse_eye.svg',
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
    return Scaffold(
      backgroundColor: Colors.white,
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
                          child: SvgPicture.asset('assets/icons/muse_logo.svg',
                              width: 76, height: 76),
                        ),
                        const SizedBox(height: 24),
                        const Text('Before you get started',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                                height: 1.1)),
                        const SizedBox(height: 28),
                        for (final (icon, title, body) in _rows) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SvgPicture.asset(icon, width: 28, height: 28),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(title,
                                        style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black)),
                                    const SizedBox(height: 4),
                                    Text(body,
                                        style: const TextStyle(
                                            fontSize: 15,
                                            color: Color(0xFF6F7278),
                                            height: 1.35)),
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
                    text: const TextSpan(
                      style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6F7278),
                          height: 1.4),
                      children: [
                        TextSpan(
                            text:
                                'By using this product, you agree to the '),
                        TextSpan(
                            text: 'Muse Terms',
                            style: TextStyle(color: Color(0xFF0064E0))),
                        TextSpan(
                            text:
                                ', which contains important information about your rights and responsibilities. Muse is subject to '),
                        TextSpan(
                            text: "Meta's AI Terms",
                            style: TextStyle(color: Color(0xFF0064E0))),
                        TextSpan(text: ' and the '),
                        TextSpan(
                            text: 'Meta Privacy Policy',
                            style: TextStyle(color: Color(0xFF0064E0))),
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
                      style: FilledButton.styleFrom(
                        shape: const StadiumBorder(),
                        backgroundColor: const Color(0xFF0064E0),
                        disabledBackgroundColor: const Color(0xFFB4CFFC),
                      ),
                      child: _busy
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Continue',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
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
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) =>
                        SettingsScreen(state: widget.state))),
                customBorder: const CircleBorder(),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: const Color(0xFFE2E3E8), width: 1.5),
                  ),
                  child: Center(
                    child: SvgPicture.asset('assets/icons/muse_gear.svg',
                        width: 24, height: 24),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
