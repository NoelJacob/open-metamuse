import 'package:go_router/go_router.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';

import './internal/state.dart';
import './theme.dart';
import './welcome/welcome.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final AppState state = await AppState.create();
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
      final onWelcome = routerState.matchedLocation == '/welcome';

      if (!loggedIn && !onWelcome) return '/welcome';
      if (loggedIn && onWelcome) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => Welcome(),
        // routes: [GoRoute(path: 'otp', builder: (context, state) => Otp)],
      ),
      // GoRoute(
      //   path: '/',
      // builder: (context, state) => AdaptiveShell(state: this.state),
      // ),
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
