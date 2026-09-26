import 'package:flutter/widget_previews.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:openmetamuse/internal/state.dart';

import 'gate_error.dart';
import 'onboarding/onboarding.dart';
import 'shell.dart';
import 'theme.dart';

void main() => runApp(const MuseApp());

class MuseApp extends StatefulWidget {
  const MuseApp({super.key});

  @override
  State<MuseApp> createState() => _MuseAppState();
}

class _MuseAppState extends State<MuseApp> {
  final Future<AppState> _future = AppState.create();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return StartupLoader();
        }
        if (snap.hasError) {
          return GateErrorScreen();
        }
        final state = snap.requireData;
        return ListenableBuilder(
          listenable: Listenable.merge([state.themeMode, state.sessionStage]),
          builder: (context, _) => MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Muse',
            theme: museLightTheme(),
            darkTheme: museDarkTheme(),
            themeMode: state.themeMode.value,
            home: state.sessionStage.value == SessionStage.loggedIn
                ? AdaptiveShell(state: state)
                : OnboardingFlow(state: state),
          ),
        );
      },
    );
  }
}

class StartupLoader extends StatelessWidget {
  @Preview()
  const StartupLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: M3ECircularProgressIndicator()));
  }
}
