// lib/src/services/auth_service.dart

import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthService {
  // On ne lit pas directement dotenv.env ici, mais dans le constructeur (avec try/catch)
  final String _baseUrl;
  final FlutterSecureStorage _secureStorage;

  AuthService()
    : _secureStorage = const FlutterSecureStorage(),
      _baseUrl =
          (() {
            try {
              // Si dotenv a été chargé (mobile/desktop), on prend API_URL.
              // Si dotenv n'a pas été initialisé (cas Web), on retombe sur localhost:8080.
              return dotenv.env['API_URL'] ?? "http://localhost:8080";
            } catch (_) {
              return "http://localhost:8080";
            }
          })();

  /// Inscription : POST /api/auth/register
  Future<void> register({
    required String username,
    required String email,
    required String password,
    required String role,
  }) async {
    final uri = Uri.parse("$_baseUrl/api/auth/register");
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'role': role,
      }),
    );

    if (response.statusCode == 201) {
      return;
    } else {
      try {
        final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(
          errorBody['error'] ?? "Erreur inconnue lors de l'inscription",
        );
      } catch (_) {
        throw Exception("Erreur inattendue : code HTTP ${response.statusCode}");
      }
    }
  }

  /// Connexion : POST /api/auth/login
  Future<String> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse("$_baseUrl/api/auth/login");
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final token = body['token'] as String;
      await _secureStorage.write(key: 'jwt_token', value: token);
      return token;
    } else {
      final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(
        errorBody['error'] ?? "Erreur inconnue lors de la connexion",
      );
    }
  }

  Future<String?> getToken() async {
    return _secureStorage.read(key: 'jwt_token');
  }

  Future<void> logout() async {
    await _secureStorage.delete(key: 'jwt_token');
  }
}
