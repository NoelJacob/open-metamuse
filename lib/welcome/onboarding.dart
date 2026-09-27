import 'package:flutter/gestures.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../icons/muse.dart';
import '../internal/state.dart';
import '../theme.dart';
import 'welcome.dart';

class OnboardingFlow extends StatefulWidget {
  final AppState state;
  const OnboardingFlow({super.key, required this.state});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  int _step = 0; // 0 landing 1 phone 2 otp 3 accounts 4 connectors 5 identity 6 activation 7 pin
  final _phone = TextEditingController();
  String _code = '';
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  AppState get _s => widget.state;

  void _activationDone() {
    _s.setSessionStage(SessionStage.loggedIn);
  }

  @override
  Widget build(BuildContext context) {
    // if (_step == 0)
    return _landing();
    // return Scaffold(
    //   body: SafeArea(
    //     child: Center(
    //       child: ConstrainedBox(
    //         constraints: const BoxConstraints(maxWidth: 480),
    //         child: Padding(
    //           padding: const EdgeInsets.all(24),
    //           child: _busy
    //               ? const Center(child: CircularProgressIndicator())
    //               : _body(),
    //         ),
    //       ),
    //     ),
    //   ),
    // );
  }

  Widget _landing() => Welcome(
    // phone: _phone,
    // busy: _busy,
    // error: _error,
    // onPhoneChanged: () => setState(() {}),
    // onContinue: () => _run(() async {
    //   await _s.startPhone(_phone.text.trim());
    //   setState(() => _step = 2);
    // }),
    // onOpenSettings: _loggedOutSettings,
  );

  void _loggedOutSettings() {
    // Navigator.of(
    //   context,
    // ).push(MaterialPageRoute<void>(builder: (_) => SettingsScreen(state: _s)));
  }

  // Widget _body() {
  //   final cs = Theme.of(context).colorScheme;
  //   switch (_step) {
  //     case 2:
  //       return _otpPage();
  //     case 3:
  //     case 4:
  //     case 5:
  //     case 7:
  //       return _frame('Activating…', const [
  //         Center(child: CircularProgressIndicator()),
  //       ]);
  //   }
  // }

  // ponytail: port of NativeLoginOtpScreen (code cells + Confirm + Try another way).
  @Preview()
  Widget _otpPage() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final id = _phone.text.trim().isEmpty ? 'your phone' : _phone.text.trim();
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          // padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  onTap: () => setState(() => _step = 0),
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: cs.outline, width: 1.5),
                    ),
                    child: const Icon(Icons.arrow_back, size: 22),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: MuseIcon(
                  MuseIconAsset.logo,
                  size: 64,
                  color: cs.secondary,
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Enter your code',
                  textAlign: TextAlign.center,
                  style: tt.displayMedium,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: tt.bodySmall!.copyWith(color: cs.onSurfaceVariant),
                    children: [
                      TextSpan(
                        text:
                            'To confirm your account, enter the 6-digit code we sent to $id. You may need to check your spam or social mail folder. ',
                      ),
                      TextSpan(
                        text: 'Resend code',
                        style: tt.bodySmall!.copyWith(
                          color: MusePalette.linkLight,
                        ),
                        recognizer: TapGestureRecognizer()..onTap = () => {},
                        // _run(() => _s.startPhone(_phone.text.trim())),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _OtpBoxes(
                onUpdate: (c) => setState(() => _code = c),
                onDone: (code) {
                  // _run(() async {
                  //   await _s.confirmOtp(code);
                  //   _s.setStage(SessionStage.activation);
                  //   await _s.activateVm();
                  //   _s.setStage(SessionStage.main);
                  //   await _s.bootstrap();
                  // });
                },
              ),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: () {},
                    // _busy || _code.length < 6
                    //     ? null
                    //     : () {
                    //         _run(() async {
                    //           await _s.confirmOtp(_code);
                    //           _s.setStage(SessionStage.activation);
                    //           await _s.activateVm();
                    //           _s.setStage(SessionStage.main);
                    //           await _s.bootstrap();
                    //         });
                    //       },
                    child: _busy
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: cs.onPrimary,
                            ),
                          )
                        : Text('Confirm', style: tt.labelLarge),
                  ),
                ),
              ),

              if (_error != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    _error!,
                    style: tt.labelSmall!.copyWith(color: cs.error),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _frame(String title, List<Widget> kids) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        for (final k in kids) ...[k, const SizedBox(height: 12)],
        if (_error != null)
          Text(
            _error!,
            style: Theme.of(context).textTheme.labelSmall!
                .copyWith(color: Theme.of(context).colorScheme.error),
          ),
      ],
    );
  }

  Widget _go(String label, Future<void> Function() fn) {
    return FilledButton(onPressed: () => _run(fn), child: Text(label));
  }
}

class _SmsNotice extends StatelessWidget {
  const _SmsNotice();

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return RichText(
      text: TextSpan(
        style: tt.labelSmall,
        children: [
          TextSpan(
            text: 'You may receive SMS notifications from us by using your mobile number. ',
          ),
          TextSpan(
            text: 'Learn more',
            style: tt.labelSmall!.copyWith(color: cs.secondary),
          ),
        ],
      ),
    );
  }
}

// ponytail: six filled cells, one hidden focus chain; no packages.
class _OtpBoxes extends StatefulWidget {
  final ValueChanged<String> onDone;
  final ValueChanged<String> onUpdate;
  const _OtpBoxes({required this.onDone, required this.onUpdate});
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
    final code = _ctls.map((c) => c.text).join();
    widget.onUpdate(code);
    if (code.length == 6) widget.onDone(code);
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
