import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_config.dart';
import '../core/exceptions.dart';
import '../domain/models/walk_entry.dart';

/// Cliente HTTP del backend: añade el token de sesión, el día local del
/// usuario y traduce errores de red/servidor a [AppException].
class ApiClient {
  static const _tokenKey = 'session_token';

  final http.Client _http;
  String? _token;

  ApiClient([http.Client? client]) : _http = client ?? http.Client();

  Future<bool> loadSession() async {
    _token = (await SharedPreferences.getInstance()).getString(_tokenKey);
    return _token != null;
  }

  Future<void> saveSession(String token) async {
    _token = token;
    await (await SharedPreferences.getInstance()).setString(_tokenKey, token);
  }

  Future<void> clearSession() async {
    _token = null;
    await (await SharedPreferences.getInstance()).remove(_tokenKey);
  }

  Future<dynamic> get(String path, {Map<String, String>? query}) => _send('GET', path, query: query);
  Future<dynamic> post(String path, [Object? body]) => _send('POST', path, body: body);
  Future<dynamic> put(String path, Object? body) => _send('PUT', path, body: body);
  Future<dynamic> delete(String path) => _send('DELETE', path);

  Future<dynamic> _send(String method, String path, {Object? body, Map<String, String>? query}) async {
    final uri = Uri.parse('${AppConfig.apiUrl}/api$path')
        .replace(queryParameters: {...?query, 'day': dayKey(DateTime.now())});
    final request = http.Request(method, uri)
      ..headers['content-type'] = 'application/json'
      ..headers['authorization'] = 'Bearer ${_token ?? ''}';
    if (body != null) request.body = jsonEncode(body);

    final http.Response response;
    try {
      response = await http.Response.fromStream(await _http.send(request).timeout(const Duration(seconds: 15)));
    } on TimeoutException catch (e) {
      throw StorageException('El servidor tardó demasiado en responder.', e);
    } catch (e) {
      throw StorageException('Sin conexión con el servidor. Revisa tu internet.', e);
    }

    if (response.statusCode == 204) return null;
    final decoded = response.body.isEmpty ? null : jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode >= 400) {
      final message = decoded is Map ? decoded['error'] as String? : null;
      if (response.statusCode == 401 && _token != null) {
        await clearSession();
        throw AuthException(message ?? 'Sesión expirada.');
      }
      throw StorageException(message ?? 'Error del servidor (${response.statusCode}).');
    }
    return decoded;
  }
}
