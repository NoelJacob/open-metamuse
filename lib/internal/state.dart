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
  // TODO(backend): loaders live here once the API port lands —
  // bootstrap, loadThreads, loadThread, sendMessage, loadFeed, loadHub.
  final threads = ValueNotifier<List<Map<String, dynamic>>>([]);
  final currentThreadId = ValueNotifier<String?>(null);
  final currentMessages = ValueNotifier<List<Map<String, dynamic>>>([]);
  final feedUnits = ValueNotifier<List<Map<String, dynamic>>>([]);
  final goals = ValueNotifier<List<String>>([]);

  String get currentTitle {
    final id = currentThreadId.value;
    if (id == null) return 'New chat';
    for (final t in threads.value) {
      if (t['id'].toString() == id) return (t['title'] ?? 'Chat').toString();
    }
    return 'Chat';
  }

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
    SessionStage sessionStage = SessionStage.welcome;
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

  Future<void> setThemeMode(ThemeMode mode) async {
    if (themeMode.value == mode) return;
    themeMode.value = mode;
    await prefs.setString("themeMode", mode.name);
  }

  Future<void> setUserId(String? id) async {
    if (userId.value == id) return;
    userId.value = id;
    await secure.write(key: 'userId', value: id);
  }

  Future<void> setAccessToken(String? token) async {
    await secure.write(key: 'accessToken', value: token);
    sessionStage.value = token == null
        ? SessionStage.welcome
        : SessionStage.loggedIn;
  }

  void dispose() {
    themeMode.dispose();
    sessionStage.dispose();
    userId.dispose();
    threads.dispose();
    currentThreadId.dispose();
    currentMessages.dispose();
    feedUnits.dispose();
    goals.dispose();
  }
}
