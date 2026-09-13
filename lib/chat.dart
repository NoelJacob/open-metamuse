import 'package:flutter/material.dart';

import 'composer.dart';
import 'state.dart';

// ponytail: one card switch + stock dialogs; no custom renderers per kind.
class ChatScreen extends StatelessWidget {
  final AppState state;
  const ChatScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return _ChatBody(state: state);
  }
}

// ponytail: HH:MM AM timestamp per measured bubble headers.
String _stamp(Map<String, dynamic> msg) {
  try {
    final dt = DateTime.parse(msg['ts'].toString()).toLocal();
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ap = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ap';
  } catch (_) {
    return '';
  }
}

class _ChatBody extends StatelessWidget {
  final AppState state;
  const _ChatBody({required this.state});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final statusTop = MediaQuery.paddingOf(context).top;
        return Scaffold(
        // ponytail: measured chrome — 60dp menu circle; main centers avatar
        // block, threads use title row (orig-13 vs thread dumps).
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(52 + 64 - statusTop),
          child: SafeArea(
            bottom: false,
            child: state.currentThreadId == null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 22),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE5E6E8),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text('Muse',
                          style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: Colors.black)),
                    ],
                  )
                : Padding(
                    padding: EdgeInsets.only(
                        top: 80 - statusTop - 16, left: 16, right: 16),
                    child: SizedBox(
                      height: 56,
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () =>
                                Scaffold.of(context).openDrawer(),
                            customBorder: const CircleBorder(),
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: const Color(0xFFE2E3E8),
                                    width: 1.5),
                              ),
                              child: const Icon(Icons.menu, size: 24),
                            ),
                          ),
                          Expanded(
                            child: Text(state.currentTitle,
                                style: const TextStyle(
                                    fontSize: 19,
                                    height: 1.0,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black)),
                          ),
                          const Icon(Icons.more_vert, size: 24),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
        drawer: _ThreadDrawer(state: state),
        body: Column(
          children: [
            Expanded(
              child: state.currentMessages.isEmpty
                  ? const Center(
                      child: Text('Start a conversation with Muse'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: state.currentMessages.length,
                      itemBuilder: (context, i) {
                        final msg = state.currentMessages[i];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(_stamp(msg),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF6F7278))),
                            const SizedBox(height: 4),
                            _Bubble(msg: msg),
                          ],
                        );
                      },
                    ),
            ),
            ComposerBar(state: state),
          ],
        ),
      );
    },
    );
  }
}

class _Bubble extends StatelessWidget {
  final Map<String, dynamic> msg;
  const _Bubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final mine = msg['role'] == 'user';
    final cards = ((msg['cards'] as List?) ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final bubble = Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        constraints: const BoxConstraints(maxWidth: 520),
        decoration: BoxDecoration(
          color: mine
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text((msg['text'] ?? '').toString()),
      ),
    );
    if (cards.isEmpty) return bubble;
    return Column(
      crossAxisAlignment:
          mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        bubble,
        for (final c in cards) _CardView(card: c),
      ],
    );
  }
}

class _CardView extends StatelessWidget {
  final Map<String, dynamic> card;
  const _CardView({required this.card});

  @override
  Widget build(BuildContext context) {
    final kind = (card['kind'] ?? card['type'] ?? 'text').toString();
    final title = (card['title'] ?? '').toString();
    final subtitle = (card['subtitle'] ?? '').toString();
    switch (kind) {
      case 'agent-activity':
        return Card(
          child: ListTile(
            leading: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2)),
            title: Text(title.isEmpty ? 'Working…' : title),
            subtitle: subtitle.isEmpty ? null : Text(subtitle),
          ),
        );
      case 'connector-link':
        return Card(
          child: ListTile(
            leading: const Icon(Icons.link),
            title: Text(title.isEmpty ? 'Connect' : title),
            subtitle: subtitle.isEmpty ? null : Text(subtitle),
            trailing: TextButton(
              child: const Text('Link'),
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link is a stub'))),
            ),
          ),
        );
      case 'marketplace':
        return Card(
          child: ListTile(
            leading: const Icon(Icons.storefront_outlined),
            title: Text(title.isEmpty ? 'Marketplace' : title),
            subtitle: subtitle.isEmpty ? null : Text(subtitle),
            trailing: TextButton(
              child: const Text('Get'),
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Get is a stub'))),
            ),
          ),
        );
      case 'image':
        final url = (card['url'] ?? card['image_url'] ?? '').toString();
        return Card(
          child: url.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Icon(Icons.image_outlined, size: 48),
                )
              : Image.network(url, errorBuilder: (_, _, _) =>
                  const Icon(Icons.broken_image_outlined, size: 48)),
        );
      default:
        if (title.isEmpty && subtitle.isEmpty) return const SizedBox.shrink();
        return Card(
          child: ListTile(
              title: title.isEmpty ? null : Text(title),
              subtitle: subtitle.isEmpty ? null : Text(subtitle)),
        );
    }
  }
}

class _ThreadDrawer extends StatelessWidget {
  final AppState state;
  const _ThreadDrawer({required this.state});

  void _rename(BuildContext context, Map<String, dynamic> t) {
    final ctl =
        TextEditingController(text: (t['title'] ?? '').toString());
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rename thread'),
        content: TextField(controller: ctl, autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await state.renameThread(t['id'].toString(), ctl.text);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirm(BuildContext context, String verb,
      Map<String, dynamic> t, Future<void> Function() fn) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('$verb thread?'),
        content: Text((t['title'] ?? '').toString()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await fn();
            },
            child: Text(verb),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search threads',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: state.setSearch,
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  for (final t in state.visibleThreads)
                    ListTile(
                      selected: t['id'].toString() ==
                          state.currentThreadId,
                      title: Text((t['title'] ?? 'Chat').toString()),
                      subtitle: ((t['unread'] as num?) ?? 0) != 0
                          ? Text('${t['unread']} unread')
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        state.loadThread(t['id'].toString());
                      },
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) {
                          if (v == 'rename') {
                            _rename(context, t);
                          } else if (v == 'delete') {
                            _confirm(context, 'Delete', t,
                                () => state.deleteThread(
                                    t['id'].toString()));
                          } else if (v == 'archive') {
                            _confirm(context, 'Archive', t,
                                () => state.archiveThread(
                                    t['id'].toString()));
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                              value: 'rename',
                              child: Text('Rename')),
                          PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete')),
                          PopupMenuItem(
                              value: 'archive',
                              child: Text('Archive')),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
