import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../domain/models.dart';

class AppUser {
  final String id, name, email, role, plan, status;
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.plan,
    required this.status,
  });
  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
    id: '${j['id'] ?? ''}',
    name: '${j['name'] ?? ''}',
    email: '${j['email'] ?? ''}',
    role: '${j['role'] ?? ''}',
    plan: '${j['plan'] ?? ''}',
    status: '${j['status'] ?? ''}',
  );
}

class ApiException implements Exception {
  final int? status;
  final String message;
  ApiException(this.message, {this.status});
  @override
  String toString() => message;
}

abstract class SessionStore {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> delete();
}

class SecureSessionStore implements SessionStore {
  final FlutterSecureStorage storage;
  const SecureSessionStore([this.storage = const FlutterSecureStorage()]);
  @override
  Future<String?> read() => storage.read(key: 'fp_session');
  @override
  Future<void> write(String v) => storage.write(key: 'fp_session', value: v);
  @override
  Future<void> delete() => storage.delete(key: 'fp_session');
}

class FinanceApi {
  final Uri baseUri;
  final http.Client client;
  final SessionStore sessionStore;
  FinanceApi(this.baseUri, {http.Client? client, SessionStore? sessionStore})
    : client = client ?? http.Client(),
      sessionStore = sessionStore ?? const SecureSessionStore() {
    if (baseUri.scheme != 'https') throw ArgumentError('A API exige HTTPS.');
  }
  Future<Map<String, String>> get _headers async {
    final t = await sessionStore.read();
    return {
      'Content-Type': 'application/json',
      if (t != null) 'Cookie': 'fp_session=$t',
    };
  }

  Future<http.Response> _send(
    String method,
    String path, {
    Object? body,
  }) async {
    final h = await _headers;
    final u = baseUri.resolve(path);
    late http.Response r;
    try {
      r =
          await (method == 'GET'
                  ? client.get(u, headers: h)
                  : method == 'PUT'
                  ? client.put(u, headers: h, body: jsonEncode(body))
                  : client.post(u, headers: h, body: jsonEncode(body)))
              .timeout(const Duration(seconds: 15));
    } on SocketException {
      throw ApiException('Sem conexão com a API.');
    } on http.ClientException {
      throw ApiException('Sem conexão com a API.');
    } on TimeoutException {
      throw ApiException('A API demorou a responder. Tente novamente.');
    } on FormatException {
      throw ApiException('Resposta inválida da API.');
    }
    if (r.statusCode == 401) await sessionStore.delete();
    if (r.statusCode < 200 || r.statusCode >= 300) {
      Map? p;
      try {
        p = jsonDecode(r.body) as Map;
      } catch (_) {}
      throw ApiException(
        p?['error']?.toString() ?? 'Erro de comunicação.',
        status: r.statusCode,
      );
    }
    return r;
  }

  Future<dynamic> _request(String m, String p, {Object? body}) async {
    final r = await _send(m, p, body: body);
    if (r.body.isEmpty) return null;
    try {
      return jsonDecode(r.body);
    } on FormatException {
      throw ApiException('Resposta inválida da API.');
    }
  }

  Future<AppUser> login(String e, String p, bool legal) async {
    final r = await _send(
      'POST',
      '/api/auth/login',
      body: {'email': e, 'password': p, 'acceptedLegal': legal},
    );
    final token = _sessionToken(r.headers['set-cookie']);
    if (token == null) {
      throw ApiException('A API não enviou uma sessão válida.');
    }
    try {
      final v = jsonDecode(r.body) as Map;
      final user = AppUser.fromJson(Map<String, dynamic>.from(v['user']));
      await sessionStore.write(token);
      return user;
    } on FormatException {
      throw ApiException('Resposta inválida da API.');
    } on TypeError {
      throw ApiException('Resposta inválida da API.');
    }
  }

  Future<AppUser?> restoreSession() async {
    try {
      final v = await _request('GET', '/api/auth/me');
      return AppUser.fromJson(Map<String, dynamic>.from(v['user']));
    } on ApiException catch (e) {
      if (e.status == 401) return null;
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _request('POST', '/api/auth/logout');
    } finally {
      await sessionStore.delete();
    }
  }

  Future<FinanceData> loadData() async {
    final response = await _request('GET', '/api/finance-data');
    try {
      if (response is! Map) throw const FormatException();
      return FinanceData.fromJson(Map<String, dynamic>.from(response));
    } on FormatException {
      throw ApiException(
        'A API enviou dados financeiros inválidos. Nada foi sobrescrito.',
      );
    } on TypeError {
      throw ApiException(
        'A API enviou dados financeiros inválidos. Nada foi sobrescrito.',
      );
    }
  }

  Future<void> saveData(FinanceData d) async {
    await _request('PUT', '/api/finance-data', body: d.toJson());
  }

  Future<Map<String, dynamic>> exportPersonalData() async =>
      Map<String, dynamic>.from(await _request('GET', '/api/me/export'));

  Future<Map<String, dynamic>> requestErasure({String? reason}) async =>
      Map<String, dynamic>.from(
        await _request(
          'POST',
          '/api/me/erasure',
          body: {'reason': reason ?? ''},
        ),
      );

  Future<Map<String, dynamic>> loadAdminOverview() async =>
      Map<String, dynamic>.from(await _request('GET', '/api/admin/overview'));
}

String? _sessionToken(String? header) {
  if (header == null) return null;
  for (final part in header.split(',')) {
    final m = RegExp(r'(?:^|\s)fp_session=([^;\s]+)').firstMatch(part);
    if (m != null) return m.group(1);
  }
  return null;
}
