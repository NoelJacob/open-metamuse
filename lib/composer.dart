import 'package:flutter/material.dart';

import 'state.dart';

// ponytail: pill input + stub buttons; no recorder/uploader code.
class ComposerBar extends StatefulWidget {
  final AppState state;
  const ComposerBar({super.key, required this.state});

  @override
  State<ComposerBar> createState() => _ComposerBarState();
}

class _ComposerBarState extends State<ComposerBar> {
  final _ctl = TextEditingController();
  final List<String> _attachments = [];
  bool _sending = false;

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  void _stub(String what) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$what is a visual stub')));
  }

  Future<void> _send() async {
    final text = _ctl.text.trim();
    if (text.isEmpty && _attachments.isEmpty) return;
    setState(() => _sending = true);
    try {
      await widget.state.sendMessage(
          _attachments.isEmpty ? text : '[${_attachments.join(', ')}] $text');
      _ctl.clear();
      setState(() => _attachments.clear());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hint = widget.state.currentTitle == 'New chat' ||
            widget.state.currentTitle == 'Chat'
        ? 'Message'
        : 'Message in ${widget.state.currentTitle}';
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 4, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_attachments.isNotEmpty)
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final a in _attachments)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Chip(
                          label: Text(a),
                          onDeleted: () =>
                              setState(() => _attachments.remove(a)),
                        ),
                      ),
                  ],
                ),
              ),
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F1F5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Attach',
                    icon: const Icon(Icons.add, color: Colors.black),
                    onPressed: () {
                      setState(() =>
                          _attachments.add('file${_attachments.length + 1}'));
                      _stub('Attachment picker');
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
                      style: const TextStyle(
                          fontSize: 17, color: Colors.black),
                      decoration: InputDecoration(
                        hintText: hint,
                        hintStyle: const TextStyle(
                            fontSize: 17, color: Color(0xFF9AA0A6)),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
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
                                child: CircularProgressIndicator(
                                    strokeWidth: 2)),
                          )
                        : Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              tooltip: 'Send',
                              icon: const Icon(Icons.arrow_upward,
                                  color: Colors.white),
                              onPressed: _send,
                            ),
                          )
                  else
                    IconButton(
                      tooltip: 'Mic',
                      icon: const Icon(Icons.mic_none, color: Colors.black),
                      onPressed: () => _stub('Mic'),
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
