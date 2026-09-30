import 'package:material_ui/material_ui.dart';

import '../../internal/state.dart';
import 'library.dart';
import '../../widgets/empty_state.dart';

class TasksScreen extends StatelessWidget {
  final AppState state;
  const TasksScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tasks')),
      floatingActionButton: Builder(
        builder: (fab) => FloatingActionButton(
          tooltip: 'New goal',
          onPressed: () => showModalBottomSheet(
            context: fab,
            isScrollControlled: true,
            builder: (_) => GoalSheet(state: state),
          ),
          child: const Icon(Icons.add),
        ),
      ),
      body: ListenableBuilder(
        listenable: state.goals,
        builder: (context, _) {
          if (state.goals.value.isEmpty) {
            return const EmptyState('No tasks yet');
          }
          return ListView.builder(
            itemCount: state.goals.value.length,
            itemBuilder: (context, i) => ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: Text(state.goals.value[i]),
            ),
          );
        },
      ),
    );
  }
}
