// lib/src/services/auth_service.dart
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthService {
  final String _baseUrl;
  final FlutterSecureStorage _secureStorage;

  AuthService()
      : _secureStorage = const FlutterSecureStorage(),
        _baseUrl = (() {
          try {
            return dotenv.env['API_URL'] ?? 'http://localhost:8080';
          } catch (_) {
            return 'http://localhost:8080';
          }
        })();

  Future<void> register({
    required String username,
    required String email,
    required String password,
    required String role,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/auth/register');
    final payload = jsonEncode({
      'username': username,
      'email': email,
      'password': password,
      'role': role,
    });

    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: payload,
    );

    if (res.statusCode != 201) {
      throw Exception(
        _extractError(res.body) ??
            'Erreur HTTP ${res.statusCode} à l’inscription',
      );
    }
  }

  Future<String> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/auth/login');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (res.statusCode != 200) {
      throw Exception(
        _extractError(res.body) ?? 'Erreur HTTP ${res.statusCode} au login',
      );
    }

    final map = jsonDecode(res.body) as Map<String, dynamic>;
    final token = map['token'] as String?;
    if (token == null) throw Exception('Réponse sans token');

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
        final payload = jsonDecode(
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
        ) as Map<String, dynamic>;
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
}
