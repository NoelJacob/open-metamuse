import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

import '../../internal/state.dart';
import '../../theme.dart';
import '../../widgets/muted_text.dart';
import 'composer.dart';
import 'drawer.dart';

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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(159),
        child: SafeArea(
          bottom: false,
          child: ListenableBuilder(
            listenable: state.currentThreadId,
            builder: (context, _) => state.currentThreadId.value == null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 22),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHigh,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('Muse', style: tt.titleLarge),
                    ],
                  )
                : Padding(
                    padding: EdgeInsets.only(top: 8, left: 16, right: 16),
                    child: SizedBox(
                      height: 100,
                      child: Builder(
                        builder: (scaffoldCtx) => Row(
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
                                    color: cs.outline,
                                    width: 1.5,
                                  ),
                                ),
                                child: Icon(
                                  Icons.menu,
                                  size: 24,
                                  color: cs.onSurface,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    state.currentTitle,
                                    textAlign: TextAlign.center,
                                    style: tt.titleLarge,
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: cs.secondaryContainer,
                                      borderRadius: BorderRadius.circular(500),
                                    ),
                                    child: Text(
                                      'Active now',
                                      style: tt.labelSmall,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ),
      drawer: ThreadDrawer(state: state),
      body: Column(
        children: [
          Expanded(
            child: ListenableBuilder(
              listenable: state.currentMessages,
              builder: (context, _) => state.currentMessages.value.isEmpty
                  ? const Center(child: Text('Start a conversation with Muse'))
                  : AutoScrollList(
                      padding: const EdgeInsets.only(
                        top: 20,
                        left: 16,
                        right: 16,
                        bottom: 12,
                      ),
                      itemCount: state.currentMessages.value.length,
                      itemBuilder: (context, i) {
                        final msgs = state.currentMessages.value;
                        final msg = msgs[i];
                        if (i == 0) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'SEP 8, 8:23 AM',
                                textAlign: TextAlign.center,
                                style: tt.labelSmall,
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
                        final prev = msgs[i - 1];
                        final showReply =
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
          ),
          ComposerBar(state: state),
        ],
      ),
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
    final chat = MuseChatColors.of(context);
    final mine = msg['role'] == 'user';
    final cards = ((msg['cards'] as List?) ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
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
          maxWidth: MediaQuery.sizeOf(context).width * 0.85,
        ),
        decoration: BoxDecoration(
          color: mine ? chat.userBubble : chat.agentBubble,
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
    final replyTo = (msg['reply_to'] ?? '').toString();
    return Column(
      crossAxisAlignment: mine
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        if (!mine && replyTo.isNotEmpty && showReply) ...[
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.reply, size: 14, color: chat.replyAttribution),
                const SizedBox(width: 4),
                Text(
                  'Muse replied to you',
                  style: Theme.of(context).textTheme.labelSmall!
                      .copyWith(height: 1.2, color: chat.replyAttribution),
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
                color: chat.quoteFill,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                replyTo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge!
                    .copyWith(color: chat.agentText),
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
    final tt = Theme.of(context).textTheme;
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
            trailing: MutedText('Link', style: tt.bodySmall!),
          ),
        );
      case 'marketplace':
        return Card(
          child: ListTile(
            leading: const Icon(Icons.storefront_outlined),
            title: Text(title.isEmpty ? 'Marketplace' : title),
            subtitle: subtitle.isEmpty ? null : Text(subtitle),
            trailing: MutedText('Get', style: tt.bodySmall!),
          ),
        );
      case 'image':
        final raw = (card['url'] ?? card['image_url'] ?? '').toString();
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
    final emoji = Theme.of(context).textTheme.headlineMedium;
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
              PopupMenuItem(
                enabled: false,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('👍', style: emoji),
                    const SizedBox(width: 6),
                    Text('❤️', style: emoji),
                    const SizedBox(width: 6),
                    Text('😂', style: emoji),
                    const SizedBox(width: 6),
                    Text('😮', style: emoji),
                    const SizedBox(width: 6),
                    Text('😢', style: emoji),
                    const SizedBox(width: 6),
                    Text('🙏', style: emoji),
                    const SizedBox(width: 6),
                    Text('🔥', style: emoji),
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
              SharePlus.instance.share(ShareParams(text: text));
            }
          }),
      child: widget.bubble(false),
    );
  }
}

class _BubbleText extends StatelessWidget {
  final String text;
  final bool mine;
  final bool selecting;
  const _BubbleText({
    required this.text,
    required this.mine,
    required this.selecting,
  });

  @override
  Widget build(BuildContext context) {
    final chat = MuseChatColors.of(context);
    final style = Theme.of(context).textTheme.bodySmall!
        .copyWith(height: 1.0, color: mine ? chat.userText : chat.agentText);
    if (selecting) {
      return SelectableText(
        text,
        style: style,
        autofocus: true,
        showCursor: true,
      );
    }
    return Text(text, style: style);
  }
}
