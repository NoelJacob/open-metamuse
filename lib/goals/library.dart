import 'package:material_ui/material_ui.dart';

import '../../helpers.dart';
import '../../internal/state.dart';
import '../../widgets/button.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/field.dart';

class LibraryScreen extends StatefulWidget {
  final AppState state;
  const LibraryScreen({super.key, required this.state});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  int _seg = 0;
  bool _sysFiles = false;

  @override
  Widget build(BuildContext context) {
    if (_sysFiles) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back),
            onPressed: () => setState(() => _sysFiles = false),
          ),
          title: const Text('System Files'),
        ),
        body: const EmptyState('No system files'),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'More options',
            onSelected: (v) {
              if (v == 'sys') setState(() => _sysFiles = true);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'sys', child: Text('System Files')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Artifacts')),
                ButtonSegment(value: 1, label: Text('Media')),
              ],
              selected: {_seg},
              onSelectionChanged: (s) => setState(() => _seg = s.first),
            ),
          ),
          Expanded(
            child: EmptyState(
              _seg == 0
                  ? 'Nothing created yet\nWhen you create something like a document, it will appear here.'
                  : 'No Media yet\nWhen you capture photos or videos, they will appear here.',
            ),
          ),
        ],
      ),
    );
  }
}

class GoalSheet extends StatefulWidget {
  final AppState state;
  const GoalSheet({super.key, required this.state});

  @override
  State<GoalSheet> createState() => _GoalSheetState();
}

class _GoalSheetState extends State<GoalSheet> with RunAsync<GoalSheet> {
  final _title = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'New goal',
              textAlign: TextAlign.center,
              style: tt.headlineSmall,
            ),
            const SizedBox(height: 8),
            MuseField(
              controller: _title,
              autofocus: true,
              hintText: 'What do you want to achieve?',
              variant: MuseFieldVariant.filled,
            ),
            const SizedBox(height: 16),
            MuseButton.primary(
              onPressed: () async {
                // TODO(backend): state.addGoal(_title.text)
                Navigator.pop(context);
              },
              busy: busyAsync,
              child: const Text('Create goal'),
            ),
            ...errorMessageAsync(),
          ],
        ),
      ),
    );
  }
}
