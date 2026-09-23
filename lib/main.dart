import 'package:material_ui/material_ui.dart';

import 'gate_error.dart';
import 'onboarding.dart';
import 'shell.dart';
import 'state.dart';
import 'theme.dart';
import 'tos.dart';

void main() => runApp(const MuseApp());

class MuseApp extends StatefulWidget {
  const MuseApp({super.key});

  @override
  State<MuseApp> createState() => _MuseAppState();
}

class _MuseAppState extends State<MuseApp> {
  late final AppState state = AppState();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => state.bootstrap());
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Muse',
        theme: museLightTheme(),
        darkTheme: museDarkTheme(),
        themeMode: state.themeMode,
        home: state.gatewayError
            ? GateErrorScreen(state: state, showGear: false)
            : state.stage == SessionStage.main && !state.tosAccepted
                ? TosScreen(state: state)
                : state.stage == SessionStage.main
                    ? AdaptiveShell(state: state)
                    : OnboardingFlow(state: state),
      ),
    );
  }
}
