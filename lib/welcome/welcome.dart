import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:openmetamuse/helpers.dart';

import '../widgets/button.dart';
import '../widgets/logo.dart';

class Welcome extends StatelessWidget {
  const Welcome({super.key});

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
                  const SizedBox(height: 28),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'Welcome to Muse',
                      textAlign: TextAlign.center,
                      style: tt.displayLarge,
                    ),
                  ),
                  const SizedBox(height: 24),
                  EmailForm(),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 16,
              // TODO open loggedOutSettings
              child: MuseGearButton.medium(onPressed: () {}),
            ),
          ],
        ),
      ),
    );
  }
}

class EmailForm extends StatefulWidget {
  const EmailForm({super.key});

  @override
  State<EmailForm> createState() => _EmailFormState();
}

class _EmailFormState extends State<EmailForm> with RunAsync<EmailForm> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            keyboardType: TextInputType.emailAddress,
            style: tt.bodyLarge,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Enter your email';
              }

              final isValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                  .hasMatch(v.trim());

              if (!isValid) {
                return 'Enter a valid email';
              }
              return null;
            },
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Email address',
              filled: true,
              fillColor: cs.surfaceContainerHigh,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(31),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          MuseButton.primary(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                // TODO: submit with the validated email, then route to OTP.
                context.push("/welcome/otp");
              }
            },
            busy: busyAsync,
            child: const Text('Continue'),
          ),
          ...errorMessageAsync(),
        ],
      ),
    );
  }
}
