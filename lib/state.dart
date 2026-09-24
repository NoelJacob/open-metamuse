import 'package:material_ui/material_ui.dart';

import 'api.dart';

// ponytail: one ChangeNotifier holds gate + lists; no providers/get_it.
enum SessionStage { loggedOut, onboarding, activation, main }

class AppState extends ChangeNotifier {
  final ApiClient api;
  AppState({ApiClient? api}) : api = api ?? ApiClient();

  SessionStage stage = SessionStage.loggedOut;
  ThemeMode themeMode = ThemeMode.system;
  bool loading = false;
  String? challengeId;
  String? userId;
  String userName = 'Muse User';
  String plan = 'free';
  int credits = 100;
  String? vmId;
  String vmStatus = 'unknown';
  List<Map<String, dynamic>> threads = [];
  String? currentThreadId;
  final Map<String, List<Map<String, dynamic>>> messages = {};
  List<Map<String, dynamic>> feedUnits = [];
  List<String> goals = [];

  void setTheme(ThemeMode mode) {
    themeMode = mode;
    notifyListeners();
  }

  void addGoal(String title) {
    final t = title.trim();
    if (t.isEmpty) return;
    goals.add(t);
    notifyListeners();
  }

  List<Map<String, dynamic>> connectorList = [];
  bool tosAccepted = false;
  bool gatewayError = false;
  List<Map<String, dynamic>> get currentMessages =>
      currentThreadId == null ? [] : (messages[currentThreadId] ?? []);

  String get currentTitle {
    if (currentThreadId == null) return 'New chat';
    for (final t in threads) {
      if (t['id'].toString() == currentThreadId) {
        return (t['title'] ?? 'Chat').toString();
      }
    }
    return 'Chat';
  }

  void setStage(SessionStage s) {
    stage = s;
    notifyListeners();
  }

  void setTosAccepted(bool v) {
    tosAccepted = v;
    notifyListeners();
  }

  void setGatewayError(bool v) {
    gatewayError = v;
    notifyListeners();
  }

  void beginOnboarding() => setStage(SessionStage.onboarding);
  void _authed(Map<String, dynamic> m) {
    if (m['access_token'] != null) {
      api.accessToken = m['access_token'].toString();
    }
    if (m['user_id'] != null) userId = m['user_id'].toString();
  }

  Future<void> bootstrap() async {
    loading = true;
    notifyListeners();
    try {
      await Future.wait([loadThreads(), loadFeed(), loadHub()]);
      currentThreadId ??= threads.isNotEmpty
          ? threads.first['id'].toString()
          : 't1';
      if (currentThreadId != null && !messages.containsKey(currentThreadId)) {
        await loadThread(currentThreadId!);
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> startPhone(String phone) async {
    final m = await api.authStart(phone);
    challengeId = m['challenge_id']?.toString();
    await api.sendOtp(challengeId ?? '');
    notifyListeners();
  }

  Future<void> confirmOtp(String code) async {
    _authed(await api.confirmOtp(challengeId ?? '', code));
    notifyListeners();
  }

  Future<void> activateVm() async {
    try {
      final vms = await api.fetchVms();
      final list = (vms['vms'] as List?) ?? [];
      if (list.isNotEmpty) {
        vmId = (list.first as Map)['vm_id']?.toString();
        vmStatus = (list.first as Map)['status']?.toString() ?? 'active';
      } else {
        final vm = await api.leaseVm();
        vmId = vm['vm_id']?.toString();
        vmStatus = (vm['status'] ?? 'active').toString();
      }
    } catch (_) {
      final vm = await api.leaseVm();
      vmId = vm['vm_id']?.toString();
      vmStatus = (vm['status'] ?? 'active').toString();
    }
    notifyListeners();
  }

  Future<void> loadThreads() async {
    try {
      final m = await api.sessionList();
      threads = ((m['threads'] as List?) ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadThread(String id) async {
    currentThreadId = id;
    notifyListeners();
    try {
      final m = await api.chatHistory(id);
      messages[id] = ((m['messages'] as List?) ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {
      messages.putIfAbsent(id, () => []);
    }
    notifyListeners();
  }

  Future<void> sendMessage(
    String text, {
    List<Map<String, dynamic>> attachments = const [],
  }) async {
    final tid = currentThreadId ?? 't1';
    currentThreadId = tid;
    final cards = <Map<String, dynamic>>[];
    for (final a in attachments) {
      final up = await api.uploadAttachment(
        name: (a['name'] ?? 'upload.bin').toString(),
        mime: (a['mime'] ?? 'application/octet-stream').toString(),
        bytes: List<int>.from(a['bytes'] as List),
      );
      cards.add({
        'kind': 'image',
        'title': (up['name'] ?? '').toString(),
        'url':
            '/api/fs/raw?name=${Uri.encodeComponent((up['name'] ?? '').toString())}',
      });
    }
    final user = {
      'id': 'u${DateTime.now().millisecondsSinceEpoch}',
      'role': 'user',
      'text': text,
      'ts': DateTime.now().toUtc().toIso8601String(),
      'cards': cards,
    };
    messages.putIfAbsent(tid, () => []).add(user);
    notifyListeners();
    try {
      final m = await api.chatSend(tid, text);
      messages[tid]!.add(Map<String, dynamic>.from(m['message'] as Map));
    } catch (_) {
      messages[tid]!.add({
        'id': 'a${DateTime.now().millisecondsSinceEpoch}',
        'role': 'agent',
        'text': text,
        'ts': DateTime.now().toUtc().toIso8601String(),
        'cards': [],
      });
    }
    notifyListeners();
  }

  void pinThread(String id) {
    final i = threads.indexWhere((t) => t['id'].toString() == id);
    if (i <= 0) return;
    final t = threads.removeAt(i);
    threads.insert(0, t);
    if (currentThreadId == null && threads.isNotEmpty) {
      currentThreadId = threads.first['id'].toString();
    }
    notifyListeners();
  }

  Future<void> renameThread(String id, String title) async {
    await api.sessionRename(id, title);
    for (final t in threads) {
      if (t['id'].toString() == id) t['title'] = title;
    }
    notifyListeners();
  }

  Future<void> deleteThread(String id) async {
    await api.sessionDelete(id);
    threads.removeWhere((t) => t['id'].toString() == id);
    messages.remove(id);
    if (currentThreadId == id) {
      currentThreadId = threads.isNotEmpty
          ? threads.first['id'].toString()
          : null;
    }
    notifyListeners();
  }

  Future<void> archiveThread(String id) async {
    await api.sessionArchive(id);
    threads.removeWhere((t) => t['id'].toString() == id);
    if (currentThreadId == id) {
      currentThreadId = threads.isNotEmpty
          ? threads.first['id'].toString()
          : null;
    }
    notifyListeners();
  }

  Future<void> loadFeed() async {
    try {
      final m = await api.feed();
      feedUnits = ((m['units'] as List?) ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadHub() async {
    try {
      final s = await api.subscription();
      plan = (s['plan'] ?? 'free').toString();
      credits = (s['credits'] as num?)?.toInt() ?? 100;
    } catch (_) {}
    try {
      final p = await api.viewerProfile();
      userName = ((p['user'] as Map?)?['name'] ?? 'Muse User').toString();
    } catch (_) {}
    try {
      final c = await api.connectors();
      connectorList = ((c['connectors'] as List?) ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {}
    try {
      final v = await api.fetchVms();
      final list = (v['vms'] as List?) ?? [];
      if (list.isNotEmpty) {
        vmId = (list.first as Map)['vm_id']?.toString();
        vmStatus = (list.first as Map)['status']?.toString() ?? 'active';
      }
    } catch (_) {}
    notifyListeners();
  }

  void signOut() {
    api.accessToken = null;
    userId = null;
    userName = 'Muse User';
    challengeId = null;
    threads = [];
    messages.clear();
    currentThreadId = null;
    feedUnits = [];
    connectorList = [];
    vmId = null;
    vmStatus = 'unknown';
    tosAccepted = false;
    gatewayError = false;
    setStage(SessionStage.loggedOut);
  }
}
