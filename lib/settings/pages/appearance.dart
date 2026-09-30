import 'package:material_ui/material_ui.dart';

import '../../../internal/state.dart';
import '../../../widgets/card.dart';
import '../../../widgets/row.dart';
import '../frame.dart';

class AppearanceScreen extends StatelessWidget {
  final AppState state;
  const AppearanceScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: state.themeMode,
      builder: (context, mode, _) => SubPage(
        title: 'Appearance',
        children: [
          RadioGroup<ThemeMode>(
            groupValue: mode,
            onChanged: (v) {
              if (v != null) state.setThemeMode(v);
            },
            child: const MuseCard(
              children: [
                MuseRow(
                  label: 'Light',
                  trailing: Radio<ThemeMode>(value: ThemeMode.light),
                ),
                Divider(height: 1),
                MuseRow(
                  label: 'Dark',
                  trailing: Radio<ThemeMode>(value: ThemeMode.dark),
                ),
                Divider(height: 1),
                MuseRow(
                  label: 'System',
                  trailing: Radio<ThemeMode>(value: ThemeMode.system),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
