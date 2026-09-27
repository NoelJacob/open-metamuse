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
    'authorization': 'Bearer $accessToken',
  };

  Map<String, dynamic> _decode(int status, String body) {
    final m = body.isEmpty
        ? <String, dynamic>{}
        : (jsonDecode(body) as Map<String, dynamic>);
    if (status != 200) {
      throw ApiError((m['error'] ?? 'cannot parse body').toString(), status);
    }
    return m;
  }

  Future<Map<String, dynamic>> _get(String path) async {
    try {
      final r = await http
          .get(Uri.parse('$baseUrl$path'), headers: _headers)
          .timeout(timeout);
      return _decode(r.statusCode, r.body);
    } on http.ClientException catch (e) {
      throw ApiError('Cannot get: ${e.message}');
    } catch (e) {
      throw ApiError(e.toString());
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
    } on http.ClientException catch (e) {
      throw ApiError('Cannot send: ${e.message}');
    } catch (e) {
      throw ApiError(e.toString());
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
    'bytes_b64': base64Encode(bytes),
  });
  Future<Map<String, dynamic>> feed() => _get('/api/feed');
  Future<Map<String, dynamic>> connectors() => _get('/api/connectors');
  Future<Map<String, dynamic>> subscription() => _get('/hatch/subscription');
  Future<Map<String, dynamic>> viewerProfile() => _get('/hatch/viewer/profile');
  Future<Map<String, dynamic>> acceptTos() => _post('/hatch/accept_tos', {});
}
