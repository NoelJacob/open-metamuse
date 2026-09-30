import 'package:material_ui/material_ui.dart';

import 'button.dart';

Future<bool> showMuseDialog(
  BuildContext context, {
  required String title,
  String? body,
  Widget? content,
  required String verb,
  bool dismissible = true,
  Color? backgroundColor,
  bool destructive = false,
}) async {
  final cs = Theme.of(context).colorScheme;
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: dismissible,
    builder: (d) => Dialog(
      backgroundColor: backgroundColor ?? cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (body != null || content != null) ...[
              const SizedBox(height: 8),
              content ?? Text(body!, textAlign: TextAlign.center),
            ],
            const SizedBox(height: 20),
            if (destructive)
              MuseButton.destructive(
                onPressed: () => Navigator.pop(d, true),
                child: Text(verb),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(d, false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(d, true),
                      child: Text(verb),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}
