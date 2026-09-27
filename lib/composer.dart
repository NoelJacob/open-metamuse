import 'package:material_ui/material_ui.dart';
import 'package:permission_handler/permission_handler.dart';

import 'state.dart';

// ponytail: pill input + stub buttons; no recorder/uploader code.
class ComposerBar extends StatefulWidget {
  final AppState state;
  const ComposerBar({super.key, required this.state});

  @override
  State<ComposerBar> createState() => _ComposerBarState();
}

final replyTarget = ValueNotifier<String?>(null);

class _ComposerBarState extends State<ComposerBar> {
  final _ctl = TextEditingController();
  bool _sending = false;
  String? _replyTo;
  final List<Map<String, dynamic>> _picked = [];

  @override
  void initState() {
    super.initState();
    replyTarget.addListener(_onReply);
  }

  void _onReply() => setState(() {
    _replyTo = replyTarget.value;
    replyTarget.value = null;
  });

  @override
  void dispose() {
    replyTarget.removeListener(_onReply);
    _ctl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      final target = _replyTo;
      await widget.state.sendMessage(
        target == null ? text : '[replying to $target] $text',
        attachments: List<Map<String, dynamic>>.from(_picked),
      );
      _ctl.clear();
      setState(() {
        _replyTo = null;
        _picked.clear();
      });
    } catch (e) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Send failed'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    const hint = 'Message';
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 4, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_replyTo != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Replying to Muse', style: tt.labelSmall),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _replyTo = null),
                      child: const Icon(Icons.close, size: 18),
                    ),
                  ],
                ),
              ),
            if (_picked.isNotEmpty)
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final a in _picked)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Chip(
                          label: Text((a['name'] ?? '').toString()),
                          onDeleted: () => setState(() => _picked.remove(a)),
                        ),
                      ),
                  ],
                ),
              ),
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Attach',
                    icon: Icon(Icons.add, color: cs.onSurface),
                    onPressed: () {
                      final box = context.findRenderObject() as RenderBox?;
                      final pos = box == null
                          ? const RelativeRect.fromLTRB(24, 900, 200, 300)
                          : RelativeRect.fromLTRB(
                              24,
                              box.localToGlobal(Offset.zero).dy - 260,
                              200,
                              box.localToGlobal(Offset.zero).dy - 8,
                            );
                      showMenu<String>(
                        context: context,
                        position: pos,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        items: [
                          for (final e in [
                            (
                              Icons.photo_camera_outlined,
                              'Camera',
                              'assets/demo.jpg',
                              'image/jpeg',
                            ),
                            (
                              Icons.image_outlined,
                              'Photos',
                              'assets/muse-wordmark.png',
                              'image/png',
                            ),
                            (
                              Icons.play_circle_outlined,
                              'Videos',
                              'assets/demo.jpg',
                              'image/jpeg',
                            ),
                            (
                              Icons.attach_file_outlined,
                              'Files',
                              'assets/muse-wordmark.png',
                              'image/png',
                            ),
                          ])
                            PopupMenuItem(
                              value: e.$2,
                              child: Row(
                                children: [
                                  Icon(e.$1),
                                  const SizedBox(width: 12),
                                  Text(e.$2),
                                ],
                              ),
                              onTap: () async {
                                final data = await DefaultAssetBundle.of(
                                  context,
                                ).load(e.$3);
                                if (!context.mounted) return;
                                setState(
                                  () => _picked.add({
                                    'name': e.$3.split('/').last,
                                    'mime': e.$4,
                                    'bytes': data.buffer.asUint8List(),
                                  }),
                                );
                              },
                            ),
                        ],
                      );
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _ctl,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _send(),
                      style: tt.bodyLarge,
                      decoration: const InputDecoration(
                        hintText: hint,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  if (_ctl.text.trim().isNotEmpty)
                    _sending
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: cs.primary,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              tooltip: 'Send',
                              icon: Icon(
                                Icons.arrow_upward,
                                color: cs.onPrimary,
                              ),
                              onPressed: _send,
                            ),
                          )
                  else
                    IconButton(
                      tooltip: 'Mic',
                      icon: Icon(Icons.mic_none, color: cs.onSurface),
                      onPressed: () async {
                        final status = await Permission.microphone.request();
                        if (!context.mounted) return;
                        final denied =
                            status.isDenied ||
                            status.isPermanentlyDenied ||
                            status.isRestricted;
                        showDialog(
                          context: context,
                          builder: (_) => Dialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                28,
                                24,
                                20,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    denied
                                        ? 'Microphone access denied'
                                        : 'Voice input',
                                    textAlign: TextAlign.center,
                                    style: tt.headlineSmall,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    denied
                                        ? 'Microphone access has been denied. Please enable it in Settings to use voice features.'
                                        : 'Listening… speak now. Voice transcription has no offline fixture.',
                                    textAlign: TextAlign.center,
                                    style: tt.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  if (denied)
                                    SizedBox(
                                      height: 52,
                                      child: FilledButton(
                                        onPressed: () async {
                                          await openAppSettings();
                                        },

                                        child: Text(
                                          'Open settings',
                                          style: tt.labelLarge,
                                        ),
                                      ),
                                    ),
                                  if (denied) const SizedBox(height: 4),
                                  SizedBox(
                                    height: 48,
                                    child: FilledButton.tonal(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(
                                        denied ? 'Cancel' : 'Close',
                                        style: tt.labelLarge,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
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
