import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

// ponytail: one try/call helper + canned offline map; no codegen, no interceptors.
class ApiError implements Exception {
  final String message;
  final int status;
  ApiError(this.message, [this.status = 500]);
  @override
  String toString() => 'ApiError($status): $message';
}

String _ts() => DateTime.now().toUtc().toIso8601String();

List<Map<String, dynamic>> _cannedThreads() => [
  {'id': 't1', 'title': 'Weekend plans', 'updated_at': _ts(), 'unread': 0},
  {'id': 't2', 'title': 'Trip ideas', 'updated_at': _ts(), 'unread': 2},
  {'id': 't3', 'title': 'Shopping list', 'updated_at': _ts(), 'unread': 0},
];

List<Map<String, dynamic>> _cannedFeed() => [
  {
    'id': 'f1',
    'kind': 'suggestion',
    'title': 'Plan your weekend',
    'subtitle': 'Ask Muse for ideas near you',
  },
  {
    'id': 'f2',
    'kind': 'reminder',
    'title': 'Reconnect WhatsApp',
    'subtitle': 'Keep your chats in sync',
  },
  {
    'id': 'f3',
    'kind': 'spotlight',
    'title': 'Try voice mode',
    'subtitle': 'Talk it out hands-free',
  },
  {
    'id': 'f4',
    'kind': 'tip',
    'title': 'New connectors',
    'subtitle': 'Link Telegram and Messenger',
  },
];

class ApiClient {
  final String baseUrl;
  final Duration timeout;
  String? accessToken;

  ApiClient({
    this.baseUrl = 'http://localhost:8787',
    this.timeout = const Duration(seconds: 5),
  });

  Map<String, String> get _headers => {
    'content-type': 'application/json',
    if (accessToken != null) 'authorization': 'Bearer $accessToken',
  };

  Map<String, dynamic> _decode(int status, String body) {
    final m = body.isEmpty
        ? <String, dynamic>{}
        : (jsonDecode(body) as Map<String, dynamic>);
    if (status >= 400) {
      throw ApiError((m['error'] ?? 'request failed').toString(), status);
    }
    return m;
  }

  Future<Map<String, dynamic>> _get(String path) async {
    try {
      final r = await http
          .get(Uri.parse('$baseUrl$path'), headers: _headers)
          .timeout(timeout);
      return _decode(r.statusCode, r.body);
    } on ApiError {
      rethrow;
    } catch (_) {
      return _offline(path, null);
    }
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final r = await http
          .post(
            Uri.parse('$baseUrl$path'),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(timeout);
      return _decode(r.statusCode, r.body);
    } on ApiError {
      rethrow;
    } catch (_) {
      return _offline(path, body);
    }
  }

  // Offline canned fallback: every screen stays usable with zero server.
  Map<String, dynamic> _offline(String path, Map<String, dynamic>? body) {
    final p = path.split('?').first;
    switch (p) {
      case '/hatch/login':
        return {'access_token': 'offline-token', 'user_id': 'u1'};
      case '/hatch/auth/start':
        return {'challenge_id': 'c-offline'};
      case '/hatch/auth/send_otp':
        return {'ok': true};
      case '/hatch/auth/confirm_otp':
        if (body?['code'] != '123456') {
          throw ApiError('invalid code', 401);
        }
        return {'access_token': 'offline-token', 'user_id': 'u1'};
      case '/hatch/auth/select_account':
        return {
          'access_token': 'offline-token',
          'user_id': (body?['account_id'] ?? 'u1').toString(),
        };
      case '/hatch/fetch_vms':
        return {
          'vms': [
            {
              'vm_id': 'vm-offline',
              'ws_url': 'ws://localhost:8787/vm',
              'status': 'active',
            },
          ],
        };
      case '/hatch/lease_vm':
        return {
          'vm_id': 'vm-offline',
          'ws_url': 'ws://localhost:8787/vm',
          'status': 'active',
        };
      case '/hatch/vm/wake':
        return {
          'vm_id': (body?['vm_id'] ?? 'vm-offline').toString(),
          'status': 'active',
        };
      case '/graphql':
        final vars = (body?['variables'] as Map?) ?? {};
        final prompt = (vars['prompt'] ?? '').toString();
        if (prompt.contains('feed')) {
          return {
            'data': {
              'feed': {'units': _cannedFeed()},
            },
          };
        }
        return {
          'data': {
            'reply': {'text': prompt, 'cards': []},
          },
        };
      case '/api/session/list':
        return {'threads': _cannedThreads()};
      case '/api/session/rename':
      case '/api/session/delete':
      case '/api/session/archive':
        return {'ok': true};
      case '/api/chat/history':
        return {
          'messages': [
            {
              'id': 'm1',
              'role': 'user',
              'text': 'Hey Muse, plan my weekend in Paris',
              'ts': '2026-09-08T08:20:00Z',
              'cards': [],
            },
            {
              'id': 'm2',
              'role': 'agent',
              'text': 'Here is a 2-day plan.',
              'ts': '2026-09-08T08:21:00Z',
              'reply_to': 'Hey Muse, plan my weekend in Paris',
              'cards': [],
            },
            {
              'id': 'm3',
              'role': 'agent',
              'text': 'Day 1: Louvre in the morning, Seine cruise at sunset.',
              'ts': '2026-09-08T08:21:10Z',
              'reply_to': 'Hey Muse, plan my weekend in Paris',
              'cards': [],
            },
            {
              'id': 'm4',
              'role': 'agent',
              'text': 'Day 2: Montmartre and the Marais.',
              'ts': '2026-09-08T08:21:20Z',
              'reply_to': 'Hey Muse, plan my weekend in Paris',
              'cards': [],
            },
            {
              'id': 'm5',
              'role': 'user',
              'text': 'Thanks! That looks great.',
              'ts': '2026-09-08T08:22:00Z',
              'cards': [],
            },
            {
              'id': 'm6',
              'role': 'agent',
              'text': 'Here is the demo picture.',
              'ts': '2026-09-08T08:23:00Z',
              'reply_to': 'Thanks! That looks great.',
              'cards': [],
            },
            {
              'id': 'm7',
              'role': 'agent',
              'text': 'Glad you like it! Anything else I can plan for you?',
              'ts': '2026-09-08T08:24:00Z',
              'reply_to': 'Thanks! That looks great.',
              'cards': [],
            },
          ],
        };
      case '/api/feed':
        return {'units': _cannedFeed()};
      case '/api/connectors':
        return {
          'connectors': [
            {'id': 'whatsapp', 'name': 'WhatsApp', 'linked': false},
            {'id': 'telegram', 'name': 'Telegram', 'linked': false},
            {'id': 'messenger', 'name': 'Messenger', 'linked': false},
          ],
        };
      case '/hatch/subscription':
        return {'plan': 'free', 'credits': 100};
      case '/hatch/viewer/profile':
        return {
          'user': {'id': 'u1', 'name': 'Muse User'},
        };
      case '/hatch/accept_tos':
        return {'ok': true};
      default:
        throw ApiError('unknown endpoint $p', 404);
    }
  }

  Future<Map<String, dynamic>> hatchLogin(String metaToken) =>
      _post('/hatch/login', {'meta_token': metaToken});
  Future<Map<String, dynamic>> authStart(String phone) =>
      _post('/hatch/auth/start', {'phone': phone});
  Future<Map<String, dynamic>> sendOtp(String challengeId) =>
      _post('/hatch/auth/send_otp', {'challenge_id': challengeId});
  Future<Map<String, dynamic>> confirmOtp(String challengeId, String code) =>
      _post('/hatch/auth/confirm_otp', {
        'challenge_id': challengeId,
        'code': code,
      });
  Future<Map<String, dynamic>> fetchVms() =>
      _get('/hatch/fetch_vms?notary_token=true');
  Future<Map<String, dynamic>> leaseVm() => _post('/hatch/lease_vm', {});
  Future<Map<String, dynamic>> graphql(
    String query, [
    Map<String, dynamic>? variables,
  ]) => _post('/graphql', {'query': query, 'variables': variables ?? {}});
  Future<Map<String, dynamic>> sessionList() => _get('/api/session/list');
  Future<Map<String, dynamic>> sessionRename(String id, String title) =>
      _post('/api/session/rename', {'id': id, 'title': title});
  Future<Map<String, dynamic>> sessionDelete(String id) =>
      _post('/api/session/delete', {'id': id});
  Future<Map<String, dynamic>> sessionArchive(String id) =>
      _post('/api/session/archive', {'id': id});
  Future<Map<String, dynamic>> chatHistory(String threadId) =>
      _get('/api/chat/history?thread_id=$threadId');
  Future<Map<String, dynamic>> chatSend(String threadId, String text) =>
      _post('/api/chat/send', {'thread_id': threadId, 'text': text});

  Future<Map<String, dynamic>> uploadAttachment({
    required String name,
    required String mime,
    required List<int> bytes,
  }) => _post('/api/fs/upload', {
    'name': name,
    'mime': mime,
    // ponytail: JSON envelope (not real multipart) because the mock body
    // parser is JSON-only; the original posts binary to fs/upload.
    'bytes_b64': base64Encode(bytes),
  });
  Future<Map<String, dynamic>> feed() => _get('/api/feed');
  Future<Map<String, dynamic>> connectors() => _get('/api/connectors');
  Future<Map<String, dynamic>> subscription() => _get('/hatch/subscription');
  Future<Map<String, dynamic>> viewerProfile() => _get('/hatch/viewer/profile');
  Future<Map<String, dynamic>> acceptTos() => _post('/hatch/accept_tos', {});
}
