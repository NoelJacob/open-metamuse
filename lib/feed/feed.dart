import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

import '../../icons/muse.dart';
import '../../internal/state.dart';

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
                final text = '${u['title'] ?? ''}\n${u['subtitle'] ?? ''}'
                    .trim();
                Navigator.pop(context);
                SharePlus.instance.share(ShareParams(text: text));
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
              Text(
                (u['title'] ?? '').toString(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text((u['subtitle'] ?? '').toString()),
              const SizedBox(height: 8),
              Text(
                'Kind: ${(u['kind'] ?? '').toString()} • '
                'Status: active',
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ideas'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const MuseIcon(MuseIconAsset.settingsGear),
            onPressed: () {
              // TODO(backend): push settings route once it exists.
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: state.feedUnits,
        builder: (context, _) => RefreshIndicator(
          // TODO(backend): state.loadFeed
          onRefresh: () async {},
          child: state.feedUnits.value.isEmpty
              ? ListView(
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: Text('No feed units yet')),
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: state.feedUnits.value.length,
                  itemBuilder: (context, i) {
                    final u = state.feedUnits.value[i];
                    return Card(
                      child: ListTile(
                        title: Text((u['title'] ?? '').toString()),
                        subtitle: Text((u['subtitle'] ?? '').toString()),
                        leading: Chip(
                          label: Text((u['kind'] ?? '').toString()),
                        ),
                        onTap: () => _statusSheet(context, u),
                        trailing: IconButton(
                          tooltip: 'Share',
                          icon: const Icon(Icons.share_outlined),
                          onPressed: () => _shareSheet(context, u),
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
