import 'package:flutter/material.dart';

import 'state.dart';

// ponytail: two static stub tabs; real lists arrive with the server.
class TasksScreen extends StatelessWidget {
  final AppState state;
  const TasksScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tasks')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No tasks yet',
              style: TextStyle(fontSize: 16, color: Color(0xFF6F7278))),
        ),
      ),
    );
  }
}

class LibraryScreen extends StatelessWidget {
  final AppState state;
  const LibraryScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Library')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No library items yet',
              style: TextStyle(fontSize: 16, color: Color(0xFF6F7278))),
        ),
      ),
    );
  }
}
