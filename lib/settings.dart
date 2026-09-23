import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'settings_pages.dart';
import 'state.dart';

class SettingsScreen extends StatelessWidget {
  final AppState state;
  const SettingsScreen({super.key, required this.state});

  void _logoutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (d) => Dialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Log out',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black)),
              const SizedBox(height: 8),
              const Text('Are you sure you want to log out?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Color(0xFF6F7278))),
              const SizedBox(height: 20),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(d).pop();
                    state.signOut();
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  },
                  style: FilledButton.styleFrom(
                    shape: const StadiumBorder(),
                    backgroundColor: const Color(0xFFD81E2E),
                  ),
                  child: const Text('Log out',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.of(d).pop(),
                child: const Text('Cancel',
                    style:
                        TextStyle(fontSize: 17, color: Colors.black)),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF0F1F5),
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
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: Colors.white),
                        child: const Icon(Icons.arrow_back,
                            color: Colors.black),
                      ),
                    ),
                  ),
                  const Text('Settings',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black)),
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28)),
                      child: Column(
                        children: [
                          if (!loggedOut)
                          _HubRow(
                            icon: const Icon(Icons.devices_outlined,
                                size: 28),
                            label: 'Devices',
                            onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const DevicesScreen())),
                          ),
                          if (!loggedOut)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Divider(
                                height: 1, color: Color(0xFFE8E9ED)),
                          ),
                          if (!loggedOut)
                          _HubRow(
                            icon: const Icon(Icons.notifications_outlined,
                                size: 28),
                            label: 'Notifications',
                            onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const NotificationsScreen())),
                          ),
                          if (!loggedOut)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Divider(
                                height: 1, color: Color(0xFFE8E9ED)),
                          ),
                          if (!loggedOut)
                          _HubRow(
                            icon: const Icon(Icons.edit_outlined,
                                size: 28),
                            label: 'Appearance',
                            onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => AppearanceScreen(
                                        state: state))),
                          ),
                          if (!loggedOut)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Divider(
                                height: 1, color: Color(0xFFE8E9ED)),
                          ),
                          if (!loggedOut)
                          _HubRow(
                            icon: const Icon(Icons.lock_outlined, size: 28),
                            label: 'App lock',
                            onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const AppLockScreen())),
                          ),
                          if (!loggedOut)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Divider(
                                height: 1, color: Color(0xFFE8E9ED)),
                          ),
                          if (!loggedOut)
                          _HubRow(
                            icon: const Icon(
                                Icons.phone_android_outlined,
                                size: 28),
                            label: 'Set as default assistant',
                            onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const DefaultAssistantScreen())),
                          ),
                          if (!loggedOut)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Divider(
                                height: 1, color: Color(0xFFE8E9ED)),
                          ),
                          if (!loggedOut)
                          _HubRow(
                            icon: const Icon(Icons.shield_outlined,
                                size: 28),
                            label: 'Data controls',
                            onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const DataControlsScreen())),
                          ),
                          if (!loggedOut)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Divider(
                                height: 1, color: Color(0xFFE8E9ED)),
                          ),
                          if (!loggedOut)
                          _HubRow(
                            icon: const Icon(Icons.info_outlined,
                                size: 28),
                            label: 'Report an issue',
                            onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const ReportIssueScreen())),
                          ),
                          if (!loggedOut)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Divider(
                                height: 1, color: Color(0xFFE8E9ED)),
                          ),
                          _HubRow(
                            icon: SvgPicture.asset(
                                'assets/icons/muse_help.svg',
                                width: 28,
                                height: 28),
                            label: 'Help & support',
                            onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const HelpSupportScreen())),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Divider(
                                height: 1, color: Color(0xFFE8E9ED)),
                          ),
                          _HubRow(
                            icon: SvgPicture.asset(
                                'assets/icons/muse_shield_small.svg',
                                width: 28,
                                height: 28),
                            label: 'Legal info',
                            onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const LegalInfoScreen())),
                          ),
                        ],
                      ),
                    ),
                    if (!loggedOut)
                    Container(
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28)),
                      child: _HubRow(
                        icon: const Icon(Icons.tune_outlined, size: 28),
                        label: 'Connector defaults',
                        subtitle: 'Ask for some actions',
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) =>
                                    const ConnectorDefaultsScreen())),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(8, 20, 8, 8),
                      child: Row(
                        children: [
                          const Text('Your account',
                              style: TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF6F7278))),
                          const Spacer()
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28)),
                      child: _HubRow(
                        icon: SvgPicture.asset(
                            'assets/icons/muse_avatar.svg',
                            width: 28,
                            height: 28),
                        label: 'Accounts Center',
                        subtitle:
                            'Password, security, personal details',
                        onTap: null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28)),
                      child: InkWell(
                        onTap: () => _logoutDialog(context),
                        borderRadius: BorderRadius.circular(28),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 18),
                          child: Text('Log out',
                              style: TextStyle(
                                  fontSize: 17,
                                  color: Color(0xFFD81E2E))),
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
  const _HubRow(
      {required this.icon,
      required this.label,
      this.subtitle,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 17, color: Colors.black)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6F7278))),
                  ],
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right,
                  color: Color(0xFFC7C9D1), size: 24),
          ],
        ),
      ),
    );
  }
}
