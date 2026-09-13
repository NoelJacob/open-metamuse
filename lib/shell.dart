import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'chat.dart';
import 'feed.dart';
import 'settings.dart';
import 'state.dart';
import 'tabs.dart';
import 'theme.dart';

// ponytail: kIsWeb-guarded Platform check; three layouts, one tab index.
bool get _isApple =>
    !kIsWeb && (Platform.isIOS || Platform.isMacOS);

class AdaptiveShell extends StatefulWidget {
  final AppState state;
  const AdaptiveShell({super.key, required this.state});

  @override
  State<AdaptiveShell> createState() => _AdaptiveShellState();
}

class _AdaptiveShellState extends State<AdaptiveShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    if (_isApple) return _cupertino();
    final wide = MediaQuery.widthOf(context) >= 800;
    if (wide) return _desktop();
    return _android();
  }

  List<Widget> get _tabs => [
        ChatScreen(state: widget.state),
        FeedScreen(state: widget.state),
        TasksScreen(state: widget.state),
        LibraryScreen(state: widget.state),
      ];

  Widget _centered(Widget child) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: child,
        ),
      );
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
                Expanded(child: _TabCell(
                  index: i,
                  selected: i == _tab,
                  onTap: () => setState(() => _tab = i),
                )),
            ],
          ),
        ),
      ),
    );
  }


  // Desktop: NavigationRail + centered 720px content.
  Widget _desktop() {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() => _tab = i),
            labelType: NavigationRailLabelType.all,
            destinations: [
              NavigationRailDestination(
                icon: MuseTabIcons.chatOutline(color: cs.onSurfaceVariant),
                selectedIcon: MuseTabIcons.chatFilled(color: cs.primary),
                label: const Text('CHAT'),
              ),
              NavigationRailDestination(
                icon: MuseTabIcons.bulb(color: cs.onSurfaceVariant),
                selectedIcon: MuseTabIcons.bulb(color: cs.primary),
                label: const Text('IDEAS'),
              ),
              NavigationRailDestination(
                icon: MuseTabIcons.check(color: cs.onSurfaceVariant),
                selectedIcon: MuseTabIcons.checkFilled(color: cs.primary),
                label: const Text('GOALS'),
              ),
              NavigationRailDestination(
                icon: MuseTabIcons.grid(color: cs.onSurfaceVariant),
                selectedIcon: MuseTabIcons.grid(color: cs.primary),
                label: const Text('LIBRARY'),
              ),
            ],
            trailing: IconButton(
              tooltip: 'Settings',
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => SettingsScreen(state: widget.state))),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
              child: _centered(IndexedStack(index: _tab, children: _tabs))),
        ],
      ),
    );
  }

  // iOS/macOS: CupertinoTabBar.
  Widget _cupertino() {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: [
          BottomNavigationBarItem(
            icon:
                MuseTabIcons.chatOutline(color: CupertinoColors.inactiveGray),
            activeIcon:
                MuseTabIcons.chatFilled(color: CupertinoColors.activeBlue),
            label: 'CHAT',
          ),
          BottomNavigationBarItem(
            icon: MuseTabIcons.bulb(color: CupertinoColors.inactiveGray),
            activeIcon: MuseTabIcons.bulb(color: CupertinoColors.activeBlue),
            label: 'IDEAS',
          ),
          BottomNavigationBarItem(
            icon: MuseTabIcons.check(color: CupertinoColors.inactiveGray),
            activeIcon:
                MuseTabIcons.checkFilled(color: CupertinoColors.activeBlue),
            label: 'GOALS',
          ),
          BottomNavigationBarItem(
            icon: MuseTabIcons.grid(color: CupertinoColors.inactiveGray),
            activeIcon: MuseTabIcons.grid(color: CupertinoColors.activeBlue),
            label: 'LIBRARY',
          ),
        ],
      ),
      tabBuilder: (context, i) => CupertinoTabView(
        builder: (_) => _centered(_tabs[i]),
      ),
    );
  }
}
// ponytail: measured 30dp glyphs, icon-only row; labels kept for semantics.
class _TabCell extends StatelessWidget {
  final int index;
  final bool selected;
  final VoidCallback onTap;
  const _TabCell(
      {required this.index, required this.selected, required this.onTap});

  static const _labels = ['CHAT', 'IDEAS', 'GOALS', 'LIBRARY'];

  Widget _icon(Color color) {
    switch (index) {
      case 1:
        return MuseTabIcons.bulb(size: 30, color: color);
      case 2:
        return selected
            ? MuseTabIcons.checkFilled(size: 30, color: color)
            : MuseTabIcons.check(size: 30, color: color);
      case 3:
        return MuseTabIcons.grid(size: 30, color: color);
      default:
        return selected
            ? MuseTabIcons.chatFilled(size: 30, color: color)
            : MuseTabIcons.chatOutline(size: 30, color: color);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = selected ? cs.primary : cs.onSurfaceVariant;
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
