import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'metrics_service.dart';

class AuthService {
  final String _baseUrl;
  final FlutterSecureStorage _secureStorage;

  AuthService()
    : _secureStorage = const FlutterSecureStorage(),
      _baseUrl ='';


  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/auth/register');
    final payload = jsonEncode({
      'username': username,
      'email': email,
      'password': password,
      'confirmPassword': password,
    });

    final response = await _performRequest(
      '/auth/register',
      () => http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: payload,
      ),
    );

    if (response.statusCode != 201) {
      final err =
          _extractError(response.body) ??
          'Erreur HTTP ${response.statusCode} à l’inscription';
      throw Exception(err);
    }
  }

  Future<String> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/auth/login');
    final response = await _performRequest(
      '/auth/login',
      () => http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ),
    );

    if (response.statusCode != 200) {
      final err =
          _extractError(response.body) ??
          'Erreur HTTP ${response.statusCode} au login';
      throw Exception(err);
    }

    final map = jsonDecode(response.body) as Map<String, dynamic>;
    final token = map['token'] as String?;
    if (token == null) {
      throw Exception('Réponse sans token');
    }

    await _secureStorage.write(key: 'jwt_token', value: token);
    return token;
  }

  Future<String?> getToken() => _secureStorage.read(key: 'jwt_token');

  Future<String?> getUsername() async {
    final token = await getToken();
    if (token == null) return null;

    try {
      final parts = token.split('.');
      if (parts.length == 3) {
        final payload =
            jsonDecode(
                  utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
                )
                as Map<String, dynamic>;
        if (payload.containsKey('username')) {
          return payload['username'] as String;
        }
      }
    } catch (_) {}
    try {
      final profile = await fetchProfile();
      return (profile['username'] ?? profile['Username']) as String?;
    } catch (_) {
      return null;
    }
  }

  Future<String?> getUserId() async {
    final token = await getToken();
    if (token == null) return null;

    try {
      final parts = token.split('.');
      if (parts.length == 3) {
        final payload =
            jsonDecode(
                  utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
                )
                as Map<String, dynamic>;

        const possibleClaims = ['sub', 'userId', 'user_id', 'uid', 'id'];
        for (final k in possibleClaims) {
          final v = payload[k];
          if (v != null && (v as String).isNotEmpty) return v.toString();
        }
      }
    } catch (_) {}

    try {
      final profile = await fetchProfile();
      const fields = ['id', 'ID', 'userId', 'user_id', 'uid'];
      for (final k in fields) {
        final v = profile[k];
        if (v != null && (v as String).isNotEmpty) return v.toString();
      }
    } catch (_) {
      /* ignore */
    }

    return null;
  }

  Future<Map<String, dynamic>> fetchProfile() async {
    final token = await getToken();
    if (token == null) throw Exception('Pas de token');

    final uri = Uri.parse('$_baseUrl/api/users/me');
    final res = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode != 200) {
      throw Exception(
        _extractError(res.body) ?? 'Erreur HTTP ${res.statusCode} profil',
      );
    }

    final map = jsonDecode(res.body) as Map<String, dynamic>;
    return map['user'] as Map<String, dynamic>;
  }

  Future<void> logout() async {
    await _secureStorage.delete(key: 'jwt_token');
  }

  String? _extractError(String body) {
    try {
      final map = jsonDecode(body) as Map<String, dynamic>;
      return map['error'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<http.Response> _performRequest(
  String endpoint,
  Future<http.Response> Function() request,
) async {
  final start = DateTime.now();
  try {
    final response = await request();

    final latency = DateTime.now().difference(start).inMilliseconds;
    MetricsService.reportAPILatency(endpoint, latency);

    if (response.statusCode >= 500) {
      MetricsService.reportError('http_5xx');
    } else if (response.statusCode >= 400) {
      MetricsService.reportError('http_4xx');
    }

    return response;
  } catch (e) {
    MetricsService.reportError('network_error');
    rethrow;
  }
}
}


