import 'package:material_ui/material_ui.dart';

import 'state.dart';

// ponytail: Library segments mirror the original (Artifacts/Media segmented
// tabs, More options -> System Files, both empty states). Goals stays a
// static empty state until the goal sheets land.
class TasksScreen extends StatelessWidget {
  final AppState state;
  const TasksScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tasks')),
      floatingActionButton: Builder(
        builder: (fab) {
          return FloatingActionButton(
            tooltip: 'New goal',
            onPressed: () => showModalBottomSheet(
              context: fab,
              isScrollControlled: true,
              builder: (_) => _GoalSheet(state: state),
            ),
            child: const Icon(Icons.add),
          );
        },
      ),
      body: ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          if (state.goals.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No tasks yet',
                  style: TextStyle(fontSize: 16, color: Color(0xFF6F7278)),
                ),
              ),
            );
          }
          return ListView.builder(
            itemCount: state.goals.length,
            itemBuilder: (context, i) => ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: Text(state.goals[i]),
            ),
          );
        },
      ),
    );
  }
}

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
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'No system files',
              style: TextStyle(fontSize: 16, color: Color(0xFF6F7278)),
            ),
          ),
        ),
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
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  _seg == 0
                      ? 'Nothing created yet\nWhen you create something like a document, it will appear here.'
                      : 'No Media yet\nWhen you capture photos or videos, they will appear here.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6F7278),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalSheet extends StatefulWidget {
  final AppState state;
  const _GoalSheet({required this.state});

  @override
  State<_GoalSheet> createState() => _GoalSheetState();
}

class _GoalSheetState extends State<_GoalSheet> {
  final _title = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            const Text(
              'New goal',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _title,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'What do you want to achieve?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: () {
                  widget.state.addGoal(_title.text);
                  Navigator.pop(context);
                },
                style: FilledButton.styleFrom(
                  shape: const StadiumBorder(),
                  backgroundColor: const Color(0xFF0064E0),
                ),
                child: const Text(
                  'Create goal',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
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
