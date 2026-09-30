import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:openmetamuse/internal/api.dart';
import 'package:openmetamuse/internal/state.dart';
import 'package:openmetamuse/main.dart';

class _FakePrefs implements SharedPreferencesAsync {
  final _data = <String, Object>{};
  @override
  Future<bool> containsKey(String key) async => _data.containsKey(key);
  @override
  Future<Set<String>> getKeys({Set<String>? allowList}) async =>
      _data.keys.toSet();
  @override
  Future<Map<String, Object?>> getAll({Set<String>? allowList}) async =>
      Map.of(_data);
  @override
  Future<Object?> get(String key) async => _data[key];
  @override
  Future<bool?> getBool(String key) async => _data[key] as bool?;
  @override
  Future<double?> getDouble(String key) async => _data[key] as double?;
  @override
  Future<int?> getInt(String key) async => _data[key] as int?;
  @override
  Future<String?> getString(String key) async => _data[key] as String?;
  @override
  Future<List<String>?> getStringList(String key) async =>
      _data[key] as List<String>?;
  @override
  Future<void> setBool(String key, bool value) async {
    _data[key] = value;
  }

  @override
  Future<void> setDouble(String key, double value) async {
    _data[key] = value;
  }

  @override
  Future<void> setInt(String key, int value) async {
    _data[key] = value;
  }

  @override
  Future<void> setString(String key, String value) async {
    _data[key] = value;
  }

  @override
  Future<void> setStringList(String key, List<String> value) async {
    _data[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _data.remove(key);
  }

  @override
  Future<void> clear({Set<String>? allowList}) async {
    _data.clear();
  }
}

class _FakeSecure extends FlutterSecureStorage {
  _FakeSecure() : super();
  final _data = <String, String>{};
  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => _data[key];
  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _data.remove(key);
  }
}

void main() {
  testWidgets('Landing renders welcome entry', (WidgetTester tester) async {
    final state = AppState(
      api: ApiClient(),
      prefs: _FakePrefs(),
      secure: _FakeSecure(),
      themeMode: ThemeMode.light,
      userId: null,
      sessionStage: SessionStage.welcome,
    );
    await tester.pumpWidget(MuseApp(state: state));
    await tester.pump();
    expect(find.text('Welcome to Muse'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
}
