import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../icons/muse.dart';
import '../../internal/state.dart';

class AdaptiveShell extends StatefulWidget {
  final AppState state;
  final StatefulNavigationShell navigationShell;
  const AdaptiveShell({
    super.key,
    required this.state,
    required this.navigationShell,
  });

  @override
  State<AdaptiveShell> createState() => _AdaptiveShellState();
}

class _AdaptiveShellState extends State<AdaptiveShell> {
  void _goBranch(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final shell = widget.navigationShell;
    return Scaffold(
      body: shell,
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 30),
        child: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: _goBranch,
          backgroundColor: Colors.transparent,
          elevation: 0,
          indicatorColor: Colors.transparent,
          indicatorShape: const CircleBorder(),
          height: 48,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
          destinations: [
            NavigationDestination(
              key: const ValueKey('tab-0'),
              icon: MuseIcon(
                MuseIconAsset.chatOutline,
                size: 30,
                color: cs.onSurfaceVariant,
              ),
              selectedIcon: MuseIcon(
                MuseIconAsset.chatFilled,
                size: 30,
                color: cs.onSurface,
              ),
              label: 'Chat',
              tooltip: 'Chat',
            ),
            // TODO add filled icons for some
            NavigationDestination(
              key: const ValueKey('tab-1'),
              icon: MuseIcon(
                MuseIconAsset.bulb,
                size: 30,
                color: cs.onSurfaceVariant,
              ),
              selectedIcon: MuseIcon(
                MuseIconAsset.bulb,
                size: 30,
                color: cs.onSurface,
              ),
              label: 'Ideas',
              tooltip: 'Ideas',
            ),
            NavigationDestination(
              key: const ValueKey('tab-2'),
              icon: MuseIcon(
                MuseIconAsset.check,
                size: 30,
                color: cs.onSurfaceVariant,
              ),
              selectedIcon: MuseIcon(
                MuseIconAsset.checkFilled,
                size: 30,
                color: cs.onSurface,
              ),
              label: 'Goals',
              tooltip: 'Goals',
            ),
            NavigationDestination(
              key: const ValueKey('tab-3'),
              icon: MuseIcon(
                MuseIconAsset.grid,
                size: 30,
                color: cs.onSurfaceVariant,
              ),
              selectedIcon: MuseIcon(
                MuseIconAsset.grid,
                size: 30,
                color: cs.onSurface,
              ),
              label: 'Library',
              tooltip: 'Library',
            ),
          ],
        ),
      ),
    );
  }
}
