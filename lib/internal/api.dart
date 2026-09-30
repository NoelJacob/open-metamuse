import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiError implements Exception {
  final String message;
  final int status;
  ApiError(this.message, [this.status = 500]);
  @override
  String toString() => 'ApiError($status): $message';
}

class Thread {
  final String id;
  final String title;
  final int unread;
  const Thread({required this.id, required this.title, this.unread = 0});

  factory Thread.fromJson(Map<String, dynamic> m) => Thread(
    id: (m['id'] ?? '').toString(),
    title: (m['title'] ?? 'Chat').toString(),
    unread: (m['unread'] as num?)?.toInt() ?? 0,
  );
}

class Message {
  final String id;
  final String role;
  final String text;
  const Message({required this.id, required this.role, required this.text});

  factory Message.fromJson(Map<String, dynamic> m) => Message(
    id: (m['id'] ?? '').toString(),
    role: (m['role'] ?? 'agent').toString(),
    text: (m['text'] ?? '').toString(),
  );
}

class FeedUnit {
  final String title;
  final String subtitle;
  final String kind;
  const FeedUnit({
    required this.title,
    required this.subtitle,
    required this.kind,
  });

  factory FeedUnit.fromJson(Map<String, dynamic> m) => FeedUnit(
    title: (m['title'] ?? '').toString(),
    subtitle: (m['subtitle'] ?? '').toString(),
    kind: (m['kind'] ?? '').toString(),
  );
}

class ApiClient {
  final String baseUrl;
  final Duration timeout;
  String? accessToken;

  ApiClient({
    this.baseUrl = 'http://localhost:8787',
    this.timeout = const Duration(seconds: 5),
    this.accessToken,
  });

  Map<String, String> get _headers => {
    'content-type': 'application/json',
    if (accessToken != null) 'authorization': 'Bearer $accessToken',
  };

  Future<Map<String, dynamic>> _call(
    String method,
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final r = method == 'GET'
          ? await http.get(uri, headers: _headers).timeout(timeout)
          : await http
                .post(uri, headers: _headers, body: jsonEncode(body))
                .timeout(timeout);
      final m = r.body.isEmpty
          ? <String, dynamic>{}
          : (jsonDecode(r.body) as Map<String, dynamic>);
      if (r.statusCode != 200) {
        throw ApiError(
          (m['error'] ?? 'request failed').toString(),
          r.statusCode,
        );
      }
      return m;
    } on ApiError {
      rethrow;
    } catch (e) {
      throw ApiError(e.toString());
    }
  }

  static List<T> _list<T>(
    Map<String, dynamic> m,
    String key,
    T Function(Map<String, dynamic>) from,
  ) => ((m[key] as List?) ?? [])
      .map((e) => from(Map<String, dynamic>.from(e as Map)))
      .toList();

  /// Email -> OTP challenge id.
  Future<String> startOtp(String email) async {
    final m = await _call('POST', '/auth/otp', {'email': email});
    return (m['challenge_id'] ?? '').toString();
  }

  /// Challenge + code -> session token. Caller stores it via setUserId.
  Future<String> verifyOtp(String challengeId, String code) async {
    final m = await _call('POST', '/auth/verify', {
      'challenge_id': challengeId,
      'code': code,
    });
    return (m['access_token'] ?? '').toString();
  }

  Future<List<Thread>> threads() async =>
      _list(await _call('GET', '/threads'), 'threads', Thread.fromJson);

  Future<Thread?> thread(String id) async {
    final m = await _call('GET', '/threads/$id');
    final t = m['thread'];
    return t == null
        ? null
        : Thread.fromJson(Map<String, dynamic>.from(t as Map));
  }

  Future<void> renameThread(String id, String title) async {
    await _call('POST', '/threads/$id/rename', {'title': title});
  }

  Future<void> deleteThread(String id) async {
    await _call('POST', '/threads/$id/delete', {});
  }

  Future<void> archiveThread(String id) async {
    await _call('POST', '/threads/$id/archive', {});
  }

  Future<List<Message>> messages(String threadId) async => _list(
    await _call('GET', '/threads/$threadId/messages'),
    'messages',
    Message.fromJson,
  );

  Future<Message> sendMessage(String threadId, String text) async {
    final m = await _call('POST', '/threads/$threadId/send', {'text': text});
    final raw = m['message'] as Map? ?? <String, dynamic>{};
    return Message.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<List<FeedUnit>> feed() async =>
      _list(await _call('GET', '/feed'), 'units', FeedUnit.fromJson);
}
