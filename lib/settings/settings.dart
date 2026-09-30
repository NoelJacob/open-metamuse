import 'package:material_ui/material_ui.dart';

import '../../icons/muse.dart';
import '../../internal/state.dart';
import '../../widgets/card.dart';
import '../../widgets/dialog.dart';
import '../../widgets/row.dart';
import 'frame.dart';
import 'pages/appearance.dart';
import 'pages/applock.dart';
import 'pages/assistant.dart';
import 'pages/connectors.dart';
import 'pages/data.dart';
import 'pages/devices.dart';
import 'pages/help.dart';
import 'pages/legal.dart';
import 'pages/notifications.dart';
import 'pages/report.dart';

class SettingsScreen extends StatelessWidget {
  final AppState state;
  const SettingsScreen({super.key, required this.state});

  Future<void> _logoutDialog(BuildContext context) async {
    final ok = await showMuseDialog(
      context,
      title: 'Log out',
      body: 'Are you sure you want to log out?',
      verb: 'Log out',
      destructive: true,
    );
    if (ok && context.mounted) {
      // TODO(backend): state.signOut() + popUntil first.
    }
  }

  @override
  Widget build(BuildContext context) {
    return SubPage(
      title: 'Settings',
      children: [
        MuseCard(
          children: [
            MuseRow(
              icon: Icon(Icons.devices_outlined, size: 28),
              label: 'Devices',
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const DevicesScreen())),
            ),
            MuseRow(
              icon: Icon(Icons.notifications_outlined, size: 28),
              label: 'Notifications',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              ),
            ),
            MuseRow(
              icon: Icon(Icons.edit_outlined, size: 28),
              label: 'Appearance',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AppearanceScreen(state: state),
                ),
              ),
            ),
            MuseRow(
              icon: Icon(Icons.lock_outlined, size: 28),
              label: 'App lock',
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const AppLockScreen())),
            ),
            MuseRow(
              icon: Icon(Icons.phone_android_outlined, size: 28),
              label: 'Set as default assistant',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const DefaultAssistantScreen(),
                ),
              ),
            ),
            MuseRow(
              icon: Icon(Icons.shield_outlined, size: 28),
              label: 'Data controls',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DataControlsScreen()),
              ),
            ),
            MuseRow(
              icon: Icon(Icons.info_outlined, size: 28),
              label: 'Report an issue',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ReportIssueScreen()),
              ),
            ),
            MuseRow(
              icon: MuseIcon(MuseIconAsset.help, size: 28),
              label: 'Help & support',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
              ),
            ),
            MuseRow(
              icon: MuseIcon(MuseIconAsset.shieldSmall, size: 28),
              label: 'Legal info',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LegalInfoScreen()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        MuseCard(
          children: [
            MuseRow(
              icon: const Icon(Icons.tune_outlined, size: 28),
              label: 'Connector defaults',
              subtitle: 'Ask for some actions',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ConnectorDefaultsScreen(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        MuseCard(
          children: [
            MuseRow(
              icon: MuseIcon(
                MuseIconAsset.avatar,
                size: 28,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              label: 'Accounts Center',
              subtitle: 'Password, security, personal details',
            ),
          ],
        ),
        const SizedBox(height: 16),
        MuseCard(
          children: [
            MuseRow(label: 'Log out', onTap: () => _logoutDialog(context)),
          ],
        ),
      ],
    );
  }
}
