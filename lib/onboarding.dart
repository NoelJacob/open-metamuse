import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'api.dart';
import 'settings.dart';
import 'state.dart';

// ponytail: one widget, int step; no router/pages.
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

  Future<void> _run(Future<void> Function() fn) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await fn();
    } on ApiError catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _activationDone() {
    _s.setStage(SessionStage.main);
  }

  @override
  Widget build(BuildContext context) {
    if (_step == 0) return _landing();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _busy
                  ? const Center(child: CircularProgressIndicator())
                  : _body(),
            ),
          ),
        ),
      ),
    );
  }

  // ponytail: pixel port of Aura logged-out landing (hatch_logo vector, pill field).
  Widget _landing() {
    final ready = _phone.text.trim().isNotEmpty;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 48),
                  Center(
                    child: SvgPicture.asset('assets/icons/muse_logo.svg',
                        width: 84, height: 84),
                  ),
                  const SizedBox(height: 28),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('Welcome to Muse',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                            height: 1.02)),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _phone,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) => setState(() {}),
                    style:
                        const TextStyle(fontSize: 17, color: Colors.black),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Mobile number or email',
                      hintStyle: const TextStyle(
                          fontSize: 17, color: Color(0xFF9AA0A6)),
                      filled: true,
                      fillColor: const Color(0xFFF0F1F5),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(31),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: _SmsNotice(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: ready && !_busy
                          ? () => _run(() async {
                                await _s.startPhone(_phone.text.trim());
                                setState(() => _step = 2);
                              })
                          : null,
                      style: FilledButton.styleFrom(
                        shape: const StadiumBorder(),
                        backgroundColor: const Color(0xFF0064E0),
                        disabledBackgroundColor: const Color(0xFFB4CFFC),
                      ),
                      child: _busy
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Continue',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!,
                        style:
                            const TextStyle(color: Colors.red, fontSize: 13)),
                  ],
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 16,
              child: InkWell(
                onTap: _loggedOutSettings,
                customBorder: const CircleBorder(),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: const Color(0xFFE2E3E8), width: 1.5),
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

  void _loggedOutSettings() {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => SettingsScreen(state: _s)));
  }

  Widget _body() {
    switch (_step) {
      case 1:
        return _frame('Enter your phone number', [
          TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration:
                  const InputDecoration(labelText: 'Phone', hintText: '+1…')),
          _go('Send code', () async {
            await _s.startPhone(_phone.text.trim());
            setState(() => _step = 2);
          }),
        ]);
      case 2:
        return _otpPage();
      case 3:
      case 4:
      case 5:
      case 7:
        // ponytail: account/connectors/identity/PIN stand-ins removed;
        // original skips them offline, activation pass-through remains.
        _s.setStage(SessionStage.activation);
        Future.microtask(() async {
          await _run(() async {
            await _s.activateVm();
            _activationDone();
          });
        });
        return _frame('Activating…', const [
          Center(child: CircularProgressIndicator()),
        ]);
      default:
        return _frame('Welcome to Muse', [
          const Icon(Icons.chat_bubble, size: 64, color: Color(0xFF5890FF)),
          _go('Get started', () async {
            _s.beginOnboarding();
            await _run(() => _s.loadHub());
            setState(() => _step = 1);
          }),
        ]);
    }
  }

  // ponytail: port of NativeLoginOtpScreen (code cells + Confirm + Try another way).
  Widget _otpPage() {
    final id = _phone.text.trim().isEmpty ? 'your phone' : _phone.text.trim();
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
                      border: Border.all(
                          color: const Color(0xFFE2E3E8), width: 1.5),
                    ),
                    child: const Icon(Icons.arrow_back, size: 22),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: SvgPicture.asset('assets/icons/muse_logo.svg',
                    width: 64,
                    height: 64,
                    colorFilter: const ColorFilter.mode(
                        Color(0xFF0064E0), BlendMode.srcIn)),
              ),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('Enter your code',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                        height: 1.1)),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF6F7278),
                        height: 1.35),
                    children: [
                      TextSpan(
                          text:
                              'To confirm your account, enter the 6-digit code we sent to $id. You may need to check your spam or social mail folder. '),
                      TextSpan(
                        text: 'Resend code',
                        style:
                            const TextStyle(color: Color(0xFF0064E0)),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => _run(
                              () => _s.startPhone(_phone.text.trim())),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _OtpBoxes(
                onUpdate: (c) => setState(() => _code = c),
                onDone: (code) {
                  _run(() async {
                    await _s.confirmOtp(code);
                    _s.setStage(SessionStage.activation);
                    await _s.activateVm();
                    _s.setStage(SessionStage.main);
                    await _s.bootstrap();
                  });
                },
              ),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: _busy || _code.length < 6
                        ? null
                        : () {
                            _run(() async {
                              await _s.confirmOtp(_code);
                              _s.setStage(SessionStage.activation);
                              await _s.activateVm();
                              _s.setStage(SessionStage.main);
                              await _s.bootstrap();
                            });
                          },
                    style: FilledButton.styleFrom(
                      shape: const StadiumBorder(),
                      backgroundColor: const Color(0xFF0064E0),
                      disabledBackgroundColor: const Color(0xFFB4CFFC),
                    ),
                    child: _busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Confirm',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                  ),
                ),
              ),

              if (_error != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(_error!,
                      style: const TextStyle(
                          color: Color(0xFFD93025), fontSize: 13)),
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
          Text(_error!, style: const TextStyle(color: Colors.red)),
      ],
    );
  }

  Widget _go(String label, Future<void> Function() fn) {
    return FilledButton(
        onPressed: () => _run(fn), child: Text(label));
  }
}
class _SmsNotice extends StatelessWidget {
  const _SmsNotice();

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
            fontSize: 13, color: Color(0xFF6F7278), height: 1.2),
        children: [
          const TextSpan(
              text:
                  'You may receive SMS notifications from us by using your mobile number. '),
          const TextSpan(
            text: 'Learn more',
            style: TextStyle(color: Color(0xFF0064E0)),
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
  final _ctls =
      List.generate(6, (_) => TextEditingController());

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
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.black),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: const Color(0xFFF0F1F5),
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                          color: Color(0xFF0064E0), width: 2)),
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

