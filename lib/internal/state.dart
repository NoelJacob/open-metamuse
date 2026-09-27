import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';

Future<String?> _getStringSafe(SharedPreferencesAsync prefs, String key) async {
  try {
    return await prefs.getString(key);
  } catch (_) {
    return null;
  }
}

enum SessionStage { loggedIn, welcome }

class AppState {
  final ApiClient api;
  final SharedPreferencesAsync prefs;
  final FlutterSecureStorage secure;

  late final ValueNotifier<ThemeMode> themeMode;
  late final ValueNotifier<String?> userId;
  late final ValueNotifier<SessionStage> sessionStage;

  AppState({
    required this.api,
    required this.prefs,
    required this.secure,
    required ThemeMode themeMode,
    required String? userId,
    required SessionStage sessionStage,
  }) {
    this.themeMode = ValueNotifier<ThemeMode>(themeMode);
    this.userId = ValueNotifier<String?>(userId);
    this.sessionStage = ValueNotifier<SessionStage>(sessionStage);
  }

  static Future<AppState> create() async {
    final SharedPreferencesAsync prefs = SharedPreferencesAsync();
    final FlutterSecureStorage secure = FlutterSecureStorage();

    final ThemeMode themeMode = ThemeMode.values.byName(
      await _getStringSafe(prefs, 'themeMode') ?? ThemeMode.light.name,
    );
    final String? userId = await secure.read(key: 'userId');
    final String? accessToken = await secure.read(key: 'accessToken');
    SessionStage sessionStage = .welcome;
    if (accessToken != null) {
      sessionStage = SessionStage.loggedIn;
    }

    final ApiClient apiClient = ApiClient(accessToken: accessToken);

    return AppState(
      api: apiClient,
      prefs: prefs,
      secure: secure,
      themeMode: themeMode,
      userId: userId,
      sessionStage: sessionStage,
    );
  }

  void setThemeMode(ThemeMode mode) {
    if (themeMode.value == mode) return;
    themeMode.value = mode;
    unawaited(prefs.setString("themeMode", mode.name));
  }

  void setUserId(String? id) {
    if (userId.value == id) return;
    userId.value = id;
    unawaited(secure.write(key: 'userId', value: id));
  }

  void setSessionStage(SessionStage stage) {
    if (sessionStage.value == stage) return;
    sessionStage.value = stage;
    unawaited(prefs.setString("sessionStage", stage.name));
  }

  void dispose() {
    themeMode.dispose();
    sessionStage.dispose();
    userId.dispose();
  }
}
