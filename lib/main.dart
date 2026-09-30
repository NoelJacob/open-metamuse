import 'package:go_router/go_router.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';

import './chat/chat.dart';
import './feed/feed.dart';
import './goals/library.dart';
import './goals/tasks.dart';
import './internal/state.dart';
import './settings/settings.dart';
import './shell/shell.dart';
import './src/rust/frb_generated.dart';
import './theme.dart';
import './tos/tos.dart';
import './welcome/otp.dart';
import './welcome/welcome.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final AppState state = await AppState.create();
  await RustLib.init();
  runApp(MuseApp(state: state));
}

class MuseApp extends StatelessWidget {
  final AppState state;
  MuseApp({super.key, required this.state});

  late final GoRouter _router = GoRouter(
    initialLocation: '/welcome',
    refreshListenable: state.sessionStage,
    redirect: (context, routerState) {
      final loggedIn = state.sessionStage.value == SessionStage.loggedIn;
      final onWelcome = routerState.matchedLocation.startsWith('/welcome');

      if (!loggedIn && !onWelcome) return '/welcome';
      if (loggedIn && onWelcome) return '/';
      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, routerState, navigationShell) =>
            AdaptiveShell(state: state, navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, routerState) => ChatScreen(state: state),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/feed',
                builder: (context, routerState) => FeedScreen(state: state),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/goals',
                builder: (context, routerState) => TasksScreen(state: state),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/library',
                builder: (context, routerState) => LibraryScreen(state: state),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        builder: (context, routerState) => SettingsScreen(state: state),
      ),
      GoRoute(
        path: '/tos',
        builder: (context, routerState) => TosScreen(state: state),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, routerState) => const Welcome(),
        routes: [
          GoRoute(
            path: 'otp',
            builder: (context, routerState) => Otp(state: state),
          ),
        ],
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([state.themeMode, state.sessionStage]),
      builder: (context, _) => MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Muse',
        theme: museLightTheme(),
        darkTheme: museDarkTheme(),
        themeMode: state.themeMode.value,
        routerConfig: _router,
      ),
    );
  }
}

class StartupLoader extends StatelessWidget {
  const StartupLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: M3ECircularProgressIndicator());
  }
}
