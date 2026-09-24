import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'settings.dart';

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

class _ChatBody extends StatelessWidget {
  final AppState state;
  const _ChatBody({required this.state});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        return Scaffold(
          // ponytail: measured chrome — 60dp menu circle; main centers avatar
          // block, threads use title row (orig-13 vs thread dumps).
          appBar: PreferredSize(
            // ponytail: fixed 116dp chrome + status bar via SafeArea.
            preferredSize: const Size.fromHeight(159),
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
                        const Text(
                          'Muse',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    )
                  : Padding(
                      padding: EdgeInsets.only(top: 8, left: 16, right: 16),
                      child: SizedBox(
                        height: 100,
                        child: Builder(
                          builder: (scaffoldCtx) {
                            return Row(
                              children: [
                                InkWell(
                                  onTap: () =>
                                      Scaffold.of(scaffoldCtx).openDrawer(),
                                  customBorder: const CircleBorder(),
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFFE2E3E8),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: const Icon(Icons.menu, size: 24),
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        state.currentTitle,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 19,
                                          height: 1.0,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF0F1F5),
                                          borderRadius: BorderRadius.circular(
                                            500,
                                          ),
                                        ),
                                        child: const Text(
                                          'Active now',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF6F7278),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 24),
                              ],
                            );
                          },
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
                        child: Text('Start a conversation with Muse'),
                      )
                    : AutoScrollList(
                        // ponytail: top inset aligns row 1 with the original (559px).
                        padding: const EdgeInsets.only(
                          top: 20,
                          left: 16,
                          right: 16,
                          bottom: 12,
                        ),
                        itemCount: state.currentMessages.length,
                        itemBuilder: (context, i) {
                          final msg = state.currentMessages[i];
                          // ponytail: original shows one full-width date
                          // divider, not per-message stamps.
                          if (i == 0) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'SEP 8, 8:23 AM',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF6F7278),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _Bubble(
                                  msg: msg,
                                  baseUrl: state.api.baseUrl,
                                  showReply: true,
                                ),
                              ],
                            );
                          }
                          // ponytail: original groups consecutive agent
                          // messages under ONE reply row + quote card.
                          final prev = i > 0
                              ? state.currentMessages[i - 1]
                              : null;
                          // ponytail: original gives one reply row + quote
                          // per assistant TURN, not per consecutive message.
                          final showReply =
                              prev == null ||
                              prev['role'] != 'agent' ||
                              (msg['reply_group'] ?? '') !=
                                  (prev['reply_group'] ?? '');
                          return _Bubble(
                            msg: msg,
                            baseUrl: state.api.baseUrl,
                            showReply: showReply,
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
  final String baseUrl;
  final bool showReply;
  const _Bubble({
    required this.msg,
    required this.baseUrl,
    this.showReply = true,
  });

  @override
  Widget build(BuildContext context) {
    final mine = msg['role'] == 'user';
    final cards = ((msg['cards'] as List?) ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    // ponytail: measured original — 16x12 inner pad, min 68x44, black
    // right with 32dp margin / grey left with 32dp margin, 6dp tail.
    Widget bubble(bool selecting) => Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 2,
          bottom: 2,
          left: mine ? 0 : 16,
          right: 0,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          minWidth: 68,
          minHeight: 44,
          // ponytail: original BubbleWidthRatio 0.85 of screen width.
          maxWidth: MediaQuery.sizeOf(context).width * 0.85,
        ),
        decoration: BoxDecoration(
          color: mine ? const Color(0xFF000000) : const Color(0xFFE9EAED),
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: mine
                ? const Radius.circular(6)
                : const Radius.circular(20),
            bottomLeft: mine
                ? const Radius.circular(20)
                : const Radius.circular(6),
          ),
        ),
        child: _BubbleText(
          text: (msg['text'] ?? '').toString(),
          mine: mine,
          selecting: selecting,
        ),
      ),
    );
    if (cards.isEmpty && (msg['reply_to'] ?? '').toString().isEmpty) {
      return _MenuBubble(msg: msg, baseUrl: baseUrl, bubble: bubble);
    }
    // ponytail: measured original — reply row at 40dp, quote card at 16dp.
    final replyTo = (msg['reply_to'] ?? '').toString();
    return Column(
      crossAxisAlignment: mine
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        if (!mine && replyTo.isNotEmpty && showReply) ...[
          const Padding(
            padding: EdgeInsets.only(left: 24),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.reply, size: 14, color: Color(0xFF6F7278)),
                SizedBox(width: 4),
                Text(
                  'Muse replied to you',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.2,
                    color: Color(0xFF6F7278),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.only(left: 0, bottom: 2),
              constraints: const BoxConstraints(maxWidth: 350),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFE9EAED),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                replyTo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 17, color: Color(0xFF232937)),
              ),
            ),
          ),
        ],
        _MenuBubble(msg: msg, baseUrl: baseUrl, bubble: bubble),
        for (final c in cards) _CardView(card: c, baseUrl: baseUrl),
      ],
    );
  }
}

class _CardView extends StatelessWidget {
  final Map<String, dynamic> card;
  final String baseUrl;
  const _CardView({required this.card, required this.baseUrl});

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
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
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
            trailing: Text(
              'Link',
              style: TextStyle(fontSize: 15, color: Colors.black38),
            ),
          ),
        );
      case 'marketplace':
        return Card(
          child: ListTile(
            leading: const Icon(Icons.storefront_outlined),
            title: Text(title.isEmpty ? 'Marketplace' : title),
            subtitle: subtitle.isEmpty ? null : Text(subtitle),
            trailing: Text(
              'Get',
              style: TextStyle(fontSize: 15, color: Colors.black38),
            ),
          ),
        );
      case 'image':
        final raw = (card['url'] ?? card['image_url'] ?? '').toString();
        // ponytail: mock sends root-relative paths; Image.network needs
        // absolute, so resolve against the client base.
        final url = raw.startsWith('/') ? '$baseUrl$raw' : raw;
        return Padding(
          padding: const EdgeInsets.only(left: 32, top: 2, bottom: 2),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: url.isEmpty
                ? const SizedBox.shrink()
                : Image.network(
                    url,
                    width: 220,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
          ),
        );
      default:
        if (title.isEmpty && subtitle.isEmpty) return const SizedBox.shrink();
        return Card(
          child: ListTile(
            title: title.isEmpty ? null : Text(title),
            subtitle: subtitle.isEmpty ? null : Text(subtitle),
          ),
        );
    }
  }
}

class _ThreadDrawer extends StatelessWidget {
  final AppState state;
  const _ThreadDrawer({required this.state});

  void _rename(BuildContext context, Map<String, dynamic> t) {
    final ctl = TextEditingController(text: (t['title'] ?? '').toString());
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rename thread'),
        content: TextField(controller: ctl, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
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

  void _confirm(
    BuildContext context,
    String verb,
    Map<String, dynamic> t,
    Future<void> Function() fn,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('$verb thread?'),
        content: Text(
          verb == 'Archive'
              ? 'Any recurring tasks will be moved to the main chat.'
              : (t['title'] ?? '').toString(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
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
            Align(
              alignment: Alignment.centerLeft,
              child: Builder(
                builder: (drawerCtx) {
                  return IconButton(
                    tooltip: 'Settings',
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () => Navigator.of(drawerCtx).push(
                      MaterialPageRoute(
                        builder: (_) => SettingsScreen(state: state),
                      ),
                    ),
                  );
                },
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
                children: const [
                  Text(
                    'Muse',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 4),
                  Text('Main chat', style: TextStyle(fontSize: 17)),
                  SizedBox(height: 8),
                  Text(
                    'Side chats',
                    style: TextStyle(fontSize: 15, color: Color(0xFF6F7278)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    title: const Text(
                      'Archived',
                      style: TextStyle(color: Colors.black38),
                    ),
                  ),
                  const Divider(height: 1),
                  for (final t in state.threads)
                    ListTile(
                      selected: t['id'].toString() == state.currentThreadId,
                      title: Text((t['title'] ?? 'Chat').toString()),
                      subtitle: () {
                        // ponytail: coerce at the boundary; a shape change
                        // in the fixture must never red-screen the drawer.
                        final u = t['unread'];
                        final n = u is num ? u : 0;
                        return n != 0 ? Text('$n unread') : null;
                      }(),
                      onTap: () {
                        Navigator.pop(context);
                        state.loadThread(t['id'].toString());
                      },
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) {
                          if (v == 'pin') {
                            state.pinThread(t['id'].toString());
                          } else if (v == 'rename') {
                            _rename(context, t);
                          } else if (v == 'delete') {
                            _confirm(
                              context,
                              'Delete',
                              t,
                              () => state.deleteThread(t['id'].toString()),
                            );
                          } else if (v == 'archive') {
                            _confirm(
                              context,
                              'Archive',
                              t,
                              () => state.archiveThread(t['id'].toString()),
                            );
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'rename',
                            child: Text('Rename'),
                          ),
                          const PopupMenuItem(value: 'pin', child: Text('Pin')),
                          const PopupMenuItem(
                            value: 'archive',
                            child: Text('Archive'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
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

/// ponytail: keeps the newest message in view after a send, like the original.
class AutoScrollList extends StatefulWidget {
  final int itemCount;
  final EdgeInsets padding;
  final Widget Function(BuildContext, int) itemBuilder;
  const AutoScrollList({
    super.key,
    required this.itemCount,
    required this.padding,
    required this.itemBuilder,
  });

  @override
  State<AutoScrollList> createState() => _AutoScrollListState();
}

class _AutoScrollListState extends State<AutoScrollList> {
  final _ctl = ScrollController();

  @override
  void didUpdateWidget(covariant AutoScrollList old) {
    super.didUpdateWidget(old);
    if (widget.itemCount > old.itemCount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_ctl.hasClients) return;
        _ctl.animateTo(
          _ctl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView.builder(
    controller: _ctl,
    padding: widget.padding,
    itemCount: widget.itemCount,
    itemBuilder: widget.itemBuilder,
  );
}

/// ponytail: original Reply/Copy/Select/Share long-press menu per bubble.
/// Select swaps the bubble text for an autofocused SelectableText so the OS
/// selection handles appear on that bubble, like the original.
class _MenuBubble extends StatefulWidget {
  final Map<String, dynamic> msg;
  final String baseUrl;
  final Widget Function(bool selecting) bubble;
  const _MenuBubble({
    required this.msg,
    required this.baseUrl,
    required this.bubble,
  });

  @override
  State<_MenuBubble> createState() => _MenuBubbleState();
}

class _MenuBubbleState extends State<_MenuBubble> {
  bool _selecting = false;

  @override
  Widget build(BuildContext context) {
    if (_selecting) {
      return GestureDetector(
        onTap: () => setState(() => _selecting = false),
        child: widget.bubble(true),
      );
    }
    return GestureDetector(
      onLongPress: () =>
          showMenu<String>(
            context: context,
            position: const RelativeRect.fromLTRB(72, 640, 72, 640),
            items: [
              // ponytail: original reaction bar; taps dismiss (no stub endpoint).
              const PopupMenuItem(
                enabled: false,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('👍', style: TextStyle(fontSize: 22)),
                    SizedBox(width: 6),
                    Text('❤️', style: TextStyle(fontSize: 22)),
                    SizedBox(width: 6),
                    Text('😂', style: TextStyle(fontSize: 22)),
                    SizedBox(width: 6),
                    Text('😮', style: TextStyle(fontSize: 22)),
                    SizedBox(width: 6),
                    Text('😢', style: TextStyle(fontSize: 22)),
                    SizedBox(width: 6),
                    Text('🙏', style: TextStyle(fontSize: 22)),
                    SizedBox(width: 6),
                    Text('🔥', style: TextStyle(fontSize: 22)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reply',
                child: Row(
                  children: [
                    Icon(Icons.reply_outlined, size: 22),
                    SizedBox(width: 12),
                    Text('Reply'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'copy',
                child: Row(
                  children: [
                    Icon(Icons.content_copy_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Copy'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'select',
                child: Row(
                  children: [
                    Icon(Icons.select_all_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Select'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.ios_share_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Share'),
                  ],
                ),
              ),
            ],
          ).then((v) {
            final text = (widget.msg['text'] ?? '').toString();
            if (v == 'copy') {
              Clipboard.setData(ClipboardData(text: text));
            } else if (v == 'reply') {
              replyTarget.value = text;
            } else if (v == 'select') {
              setState(() => _selecting = true);
            } else if (v == 'share') {
              Share.share(text);
            }
          }),
      child: widget.bubble(false),
    );
  }
}

/// ponytail: identical type in both modes; select mode swaps in OS handles.
class _BubbleText extends StatelessWidget {
  final String text;
  final bool mine;
  final bool selecting;
  const _BubbleText({
    required this.text,
    required this.mine,
    required this.selecting,
  });

  TextStyle get _style => TextStyle(
    fontSize: 15,
    // ponytail: measured original line height 1.0.
    height: 1.0,
    color: mine ? Colors.white : const Color(0xFF232937),
  );

  @override
  Widget build(BuildContext context) {
    if (selecting) {
      // ponytail: real SelectableText — OS handles + toolbar on long-press,
      // the original's Select UX. Safe here: select mode shows no showMenu
      // to hijack (default mode stays Text so our menu owns long-press).
      return SelectableText(
        text,
        style: _style,
        autofocus: true,
        showCursor: true,
      );
    }
    return Text(text, style: _style);
  }
}
