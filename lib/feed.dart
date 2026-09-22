import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'settings.dart';
import 'state.dart';

// ponytail: stock cards + two bottom sheets; units carry no URL offline so
// the sheet offers Share only (no Copy-link row to invent).
class FeedScreen extends StatelessWidget {
  final AppState state;
  const FeedScreen({super.key, required this.state});

  void _shareSheet(BuildContext context, Map<String, dynamic> u) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Share'),
              onTap: () {
                final text =
                    '${u['title'] ?? ''}\n${u['subtitle'] ?? ''}'.trim();
                Navigator.pop(context);
                Share.share(text);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _statusSheet(BuildContext context, Map<String, dynamic> u) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text((u['title'] ?? '').toString(),
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text((u['subtitle'] ?? '').toString()),
              const SizedBox(height: 8),
              Text('Kind: ${(u['kind'] ?? '').toString()} • '
                  'Status: active'),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Ideas'),
          actions: [
            IconButton(
              tooltip: 'Settings',
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => SettingsScreen(state: state))),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: state.loadFeed,
          child: state.feedUnits.isEmpty
              ? ListView(children: const [
                  Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('No feed units yet')),
                  )
                ])
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: state.feedUnits.length,
                  itemBuilder: (context, i) {
                    final u = state.feedUnits[i];
                    return Card(
                      child: ListTile(
                        title:
                            Text((u['title'] ?? '').toString()),
                        subtitle:
                            Text((u['subtitle'] ?? '').toString()),
                        leading: Chip(
                            label: Text((u['kind'] ?? '').toString())),
                        onTap: () => _statusSheet(context, u),
                        trailing: IconButton(
                          tooltip: 'Share',
                          icon:
                              const Icon(Icons.share_outlined),
                          onPressed: () =>
                              _shareSheet(context, u),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
