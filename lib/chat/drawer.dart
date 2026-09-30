import 'package:material_ui/material_ui.dart';

import '../../icons/muse.dart';
import '../../internal/state.dart';
import '../../widgets/dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/field.dart';
import '../../widgets/muted_text.dart';

class ThreadDrawer extends StatelessWidget {
  final AppState state;
  const ThreadDrawer({super.key, required this.state});

  Future<void> _rename(BuildContext context, Map<String, dynamic> t) async {
    final ctl = TextEditingController(text: (t['title'] ?? '').toString());
    final ok = await showMuseDialog(
      context,
      title: 'Rename thread',
      content: MuseField(controller: ctl, autofocus: true),
      verb: 'Save',
    );
    if (ok) {
      // TODO(backend): state.renameThread(t['id'], ctl.text)
    }
  }

  Future<void> _confirm(
    BuildContext context,
    String verb,
    Map<String, dynamic> t,
    VoidCallback fn,
  ) async {
    final ok = await showMuseDialog(
      context,
      title: '$verb thread?',
      body: verb == 'Archive'
          ? 'Any recurring tasks will be moved to the main chat.'
          : (t['title'] ?? '').toString(),
      verb: verb,
    );
    if (ok) fn();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Builder(
                builder: (drawerCtx) => IconButton(
                  tooltip: 'Settings',
                  icon: const MuseIcon(MuseIconAsset.settingsGear),
                  onPressed: () => Navigator.of(drawerCtx).push(
                    MaterialPageRoute(
                      builder: (_) => const EmptyState('Settings'),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                top: 20,
                left: 16,
                right: 16,
                bottom: 12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Muse', style: tt.titleLarge),
                  const SizedBox(height: 4),
                  Text('Main chat', style: tt.bodyLarge),
                  const SizedBox(height: 8),
                  MutedText('Side chats', style: tt.bodySmall!),
                ],
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: state.threads,
                builder: (context, _) => ListView(
                  children: [
                    ListTile(
                      title: MutedText('Archived', style: tt.bodyMedium!),
                    ),
                    const Divider(height: 1),
                    // TODO(backend): state.threads / loadThread / pin /
                    // rename / delete / archive once AppState owns them.
                    const EmptyState('No threads yet'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
