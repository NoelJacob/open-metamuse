import 'package:material_ui/material_ui.dart';
import 'package:permission_handler/permission_handler.dart';

import './icons/muse.dart';
import './internal/state.dart';
import 'chat.dart';
import 'feed.dart';
import 'tabs.dart';
import 'theme.dart';

// ponytail: Android-only shell; desktop rail and Cupertino chrome removed.
class AdaptiveShell extends StatefulWidget {
  final AppState state;
  const AdaptiveShell({super.key, required this.state});

  @override
  State<AdaptiveShell> createState() => _AdaptiveShellState();
}

class _AdaptiveShellState extends State<AdaptiveShell> {
  int _tab = 0;
  bool _gateShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _notifGate());
  }

  // ponytail: original asks once over first-run main chat; either answer
  // proceeds, and the showing flag survives rebuilds for this session.
  // ponytail: pre-granted at install/funnel (user instruction) — never ask twice.
  void _notifGate() async {
    if (_gateShown || !mounted) return;
    _gateShown = true;
    if (await Permission.notification.isGranted) return;
    if (!mounted) return;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Icon(
                  Icons.notifications_outlined,
                  size: 40,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: tt.headlineSmall,
                  children: [
                    const TextSpan(text: 'Allow '),
                    TextSpan(
                      text: 'Muse',
                      style: tt.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const TextSpan(text: ' to send you\nnotifications?'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Allow', style: tt.labelLarge),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 52,
                child: FilledButton.tonal(
                  onPressed: () => Navigator.pop(context),

                  child: Text('Don\u2019t allow', style: tt.labelLarge),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _android();
  }

  List<Widget> get _tabs => [
    ChatScreen(state: widget.state),
    FeedScreen(state: widget.state),
    TasksScreen(state: widget.state),
    LibraryScreen(state: widget.state),
  ];

  // Android: custom 48dp tab row (measured: y2219-2345 content).
  Widget _android() {
    return Scaffold(
      body: IndexedStack(index: _tab, children: _tabs),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 30),
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              for (var i = 0; i < 4; i++)
                Expanded(
                  child: _TabCell(
                    index: i,
                    selected: i == _tab,
                    onTap: () => setState(() => _tab = i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ponytail: measured 30dp glyphs, icon-only row; labels kept for semantics.
class _TabCell extends StatelessWidget {
  final int index;
  final bool selected;
  final VoidCallback onTap;
  const _TabCell({
    required this.index,
    required this.selected,
    required this.onTap,
  });

  static const _labels = ['CHAT', 'IDEAS', 'GOALS', 'LIBRARY'];

  Widget _icon(Color color) {
    switch (index) {
      case 1:
        return MuseIcon(MuseIconAsset.bulb, size: 30, color: color);
      case 2:
        return MuseIcon(
          selected ? MuseIconAsset.checkFilled : MuseIconAsset.check,
          size: 30,
          color: color,
        );
      case 3:
        return MuseIcon(MuseIconAsset.grid, size: 30, color: color);
      default:
        return MuseIcon(
          selected ? MuseIconAsset.chatFilled : MuseIconAsset.chatOutline,
          size: 30,
          color: color,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // ponytail: original selected tab is near-black, not brand blue.
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = selected
        ? (dark ? MusePalette.tabSelectedDark : MusePalette.tabSelectedLight)
        : cs.onSurfaceVariant;
    return Semantics(
      label: _labels[index],
      button: true,
      child: InkWell(
        key: ValueKey('tab-$index'),
        onTap: onTap,
        child: Center(child: _icon(color)),
      ),
    );
  }
}
