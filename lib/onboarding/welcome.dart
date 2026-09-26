import 'package:material_ui/material_ui.dart';

import '../../icons/muse.dart';

class Landing extends StatelessWidget {
  const new({super.key});

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
                  Center(
                    child: MuseIcon(
                      MuseIconAsset.logo,
                      size: 84,
                      color: cs.onSurface,
                    ),
                  ),
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
              child: InkWell(
                // onTap: onOpenSettings,
                customBorder: const CircleBorder(),
                child: Container(
                  width: 48,
                  height: 48,
                  // decoration: BoxDecoration(
                  //   shape: BoxShape.circle,
                  //   border: Border.all(color: cs.outlineVariant, width: 0.5),
                  // ),
                  child: Center(
                    child: MuseIcon(
                      MuseIconAsset.gear,
                      size: 24,
                      color: cs.onSurfaceVariant,
                    ),
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

class EmailForm extends StatefulWidget {
  const EmailForm({super.key});

  @override
  State<EmailForm> createState() => _EmailFormState();
}

class _EmailFormState extends State<EmailForm> {
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
          FilledButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                // TODO: submit with the validated email, then route to OTP.
              }
            },
            style: FilledButton.styleFrom(minimumSize: Size.fromHeight(48)),
            child: const Text('Continue'),
          ),
          // if (_err != null) ...[
          //   SizedBox(height: 12),
          //   Text(_err!, style: tt.labelSmall!.copyWith(color: cs.error)),
          // ],
        ],
      ),
    );
  }
}
