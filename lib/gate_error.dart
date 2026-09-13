import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'settings.dart';
import 'state.dart';

// ponytail: one screen, gear flag; no retry logic (button stays disabled).
class GateErrorScreen extends StatelessWidget {
  final AppState state;
  final bool showGear;
  const GateErrorScreen(
      {super.key, required this.state, required this.showGear});

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
                const Spacer(flex: 3),
                Center(
                  child: showGear
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF6F7278)))
                      : const SizedBox(
                          width: 72,
                          height: 72,
                          child: CircularProgressIndicator(
                              strokeWidth: 7,
                              color: Color(0xFF0064E0))),
                ),
                const SizedBox(height: 28),
                const Text('Something went wrong. Please try again.',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 16, color: Color(0xFF6F7278))),
                const Spacer(flex: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    height: 56,
                    child: FilledButton(
                      onPressed: null,
                      style: FilledButton.styleFrom(
                        shape: const StadiumBorder(),
                        disabledBackgroundColor:
                            const Color(0xFFF0F1F5),
                      ),
                      child: const Text('Try again',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
            if (showGear)
              Positioned(
                top: 8,
                right: 16,
                child: InkWell(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) =>
                          SettingsScreen(state: state))),
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
                      child: SvgPicture.asset('assets/muse_gear.svg',
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
