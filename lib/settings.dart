import 'package:material_ui/material_ui.dart';

import 'icons/muse.dart';
import 'settings_pages.dart';
import 'state.dart';

class SettingsScreen extends StatelessWidget {
  final AppState state;
  const SettingsScreen({super.key, required this.state});

  void _logoutDialog(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    showDialog<void>(
      context: context,
      barrierColor: cs.scrim,
      builder: (d) => Dialog(
        backgroundColor: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Log out',
                textAlign: TextAlign.center,
                style: tt.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to log out?',
                textAlign: TextAlign.center,
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(d).pop();
                    state.signOut();
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  },
                  style: FilledButton.styleFrom(backgroundColor: cs.error),
                  child: Text(
                    'Log out',
                    style: tt.titleMedium?.copyWith(color: cs.onError),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.of(d).pop(),
                child: Text('Cancel', style: tt.bodyLarge),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ponytail: logged-out hub shows only Help/Legal/Account/Logout.
    final loggedOut = state.stage != SessionStage.main;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      onTap: () => Navigator.of(context).maybePop(),
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cs.surfaceContainerLow,
                        ),
                        child: Icon(Icons.arrow_back, color: cs.onSurface),
                      ),
                    ),
                  ),
                  Text('Settings', style: tt.headlineSmall),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Column(
                        children: [
                          if (!loggedOut)
                            _HubRow(
                              icon: const Icon(
                                Icons.devices_outlined,
                                size: 28,
                              ),
                              label: 'Devices',
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const DevicesScreen(),
                                ),
                              ),
                            ),
                          if (!loggedOut)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: Divider(height: 1),
                            ),
                          if (!loggedOut)
                            _HubRow(
                              icon: const Icon(
                                Icons.notifications_outlined,
                                size: 28,
                              ),
                              label: 'Notifications',
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const NotificationsScreen(),
                                ),
                              ),
                            ),
                          if (!loggedOut)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: Divider(height: 1),
                            ),
                          if (!loggedOut)
                            _HubRow(
                              icon: const Icon(Icons.edit_outlined, size: 28),
                              label: 'Appearance',
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AppearanceScreen(state: state),
                                ),
                              ),
                            ),
                          if (!loggedOut)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: Divider(height: 1),
                            ),
                          if (!loggedOut)
                            _HubRow(
                              icon: const Icon(Icons.lock_outlined, size: 28),
                              label: 'App lock',
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const AppLockScreen(),
                                ),
                              ),
                            ),
                          if (!loggedOut)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: Divider(height: 1),
                            ),
                          if (!loggedOut)
                            _HubRow(
                              icon: const Icon(
                                Icons.phone_android_outlined,
                                size: 28,
                              ),
                              label: 'Set as default assistant',
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const DefaultAssistantScreen(),
                                ),
                              ),
                            ),
                          if (!loggedOut)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: Divider(height: 1),
                            ),
                          if (!loggedOut)
                            _HubRow(
                              icon: const Icon(Icons.shield_outlined, size: 28),
                              label: 'Data controls',
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const DataControlsScreen(),
                                ),
                              ),
                            ),
                          if (!loggedOut)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: Divider(height: 1),
                            ),
                          if (!loggedOut)
                            _HubRow(
                              icon: const Icon(Icons.info_outlined, size: 28),
                              label: 'Report an issue',
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ReportIssueScreen(),
                                ),
                              ),
                            ),
                          if (!loggedOut)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: Divider(height: 1),
                            ),
                          _HubRow(
                            icon: MuseIcon(MuseIconAsset.help, size: 28),
                            label: 'Help & support',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const HelpSupportScreen(),
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Divider(height: 1),
                          ),
                          _HubRow(
                            icon: MuseIcon(MuseIconAsset.shieldSmall, size: 28),
                            label: 'Legal info',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const LegalInfoScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!loggedOut)
                      Container(
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: _HubRow(
                          icon: const Icon(Icons.tune_outlined, size: 28),
                          label: 'Connector defaults',
                          subtitle: 'Ask for some actions',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ConnectorDefaultsScreen(),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
                      child: Row(
                        children: [
                          Text(
                            'Your account',
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: _HubRow(
                        icon: MuseIcon(
                          MuseIconAsset.avatar,
                          size: 28,
                          color: cs.onSurface,
                        ),
                        label: 'Accounts Center',
                        subtitle: 'Password, security, personal details',
                        onTap: null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: InkWell(
                        onTap: () => _logoutDialog(context),
                        borderRadius: BorderRadius.circular(28),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
                          ),
                          child: Text(
                            'Log out',
                            style: tt.titleMedium?.copyWith(color: cs.error),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HubRow extends StatelessWidget {
  final Widget icon;
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;
  const _HubRow({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: tt.titleMedium),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: tt.labelMedium),
                  ],
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right, color: cs.outline, size: 24),
          ],
        ),
      ),
    );
  }
}
