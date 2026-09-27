import 'package:material_ui/material_ui.dart';
import 'package:openmetamuse/icons/muse.dart';

class GateErrorScreen extends StatelessWidget {
  const GateErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(flex: 3),
            Center(
              child: MuseIcon(
                MuseIconAsset.rectangleAlert,
                size: 72,
                color: cs.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Something went wrong.\nPlease try again.',
              textAlign: TextAlign.center,
              style: tt.bodyMedium!.copyWith(color: cs.onSurfaceVariant),
            ),
            const Spacer(flex: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: null,
                  child: Text('Try again', style: tt.labelLarge),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
