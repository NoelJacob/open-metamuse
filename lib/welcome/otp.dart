import 'package:flutter/gestures.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:openmetamuse/helpers.dart';
import 'package:openmetamuse/theme.dart';
import 'package:openmetamuse/widgets/logo.dart';

import '../../widgets/button.dart';

class Otp extends StatelessWidget {
  const Otp({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 48),
                  Center(child: MuseLogo.large()),
                  const SizedBox(height: 20),
                  Text(
                    'Enter your code',
                    textAlign: TextAlign.center,
                    style: tt.displayMedium,
                  ),
                  const SizedBox(height: 12),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: tt.bodySmall,
                      children: [
                        const TextSpan(
                          text: 'To confirm your account, enter the 6-digit code we sent to you. ',
                        ),
                        TextSpan(
                          text: 'Resend code',
                          style: tt.bodySmall!.copyWith(
                            color: MusePalette.linkLight,
                          ),
                          // TODO: resend otp
                          recognizer: TapGestureRecognizer()..onTap = () {},
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  const OtpForm(),
                ],
              ),
            ),
            Positioned(
              top: 8,
              left: 16,
              child: MuseBackButton.medium(onPressed: () => context.pop()),
            ),
          ],
        ),
      ),
    );
  }
}

class OtpForm extends StatefulWidget {
  const OtpForm({super.key});

  @override
  State<OtpForm> createState() => _OtpFormState();
}

class _OtpFormState extends State<OtpForm> with RunAsync<OtpForm> {
  String _code = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _OtpBoxes(onChanged: (c) => setState(() => _code = c)),
        const SizedBox(height: 28),
        MuseButton.primary(
          onPressed: _code.length == 6
              ? () {
                  // TODO: confirm otp
                  context.push('');
                }
              : null,
          busy: busyAsync,
          child: const Text('Confirm'),
        ),
        ...errorMessageAsync(),
      ],
    );
  }
}

/// Six filled cells, one hidden focus chain; no packages.
class _OtpBoxes extends StatefulWidget {
  final ValueChanged<String> onChanged;
  const _OtpBoxes({required this.onChanged});

  @override
  State<_OtpBoxes> createState() => _OtpBoxesState();
}

class _OtpBoxesState extends State<_OtpBoxes> {
  final _nodes = List.generate(6, (_) => FocusNode());
  final _ctls = List.generate(6, (_) => TextEditingController());

  @override
  void dispose() {
    for (final n in _nodes) {
      n.dispose();
    }
    for (final c in _ctls) {
      c.dispose();
    }
    super.dispose();
  }

  void _changed(int i, String v) {
    if (v.length > 1) {
      final chars = v.characters.toList();
      for (var j = 0; j < 6; j++) {
        _ctls[j].text = j < chars.length ? chars[j] : '';
      }
      setState(() {});
      _nodes[5].requestFocus();
    } else if (v.isNotEmpty && i < 5) {
      setState(() {});
      _nodes[i + 1].requestFocus();
    } else if (v.isEmpty && i > 0) {
      setState(() {});
      _nodes[i - 1].requestFocus();
    } else {
      setState(() {});
    }
    widget.onChanged(_ctls.map((c) => c.text).join());
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 6; i++) ...[
          Expanded(
            child: SizedBox(
              height: 62,
              child: TextField(
                controller: _ctls[i],
                focusNode: _nodes[i],
                autofocus: i == 0,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: Theme.of(context).textTheme.headlineMedium,
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (v) => _changed(i, v),
              ),
            ),
          ),
          if (i < 5) const SizedBox(width: 10),
        ],
      ],
    );
  }
}
