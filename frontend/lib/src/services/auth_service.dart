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
      _baseUrl =
          (() {
            try {
              // Si dotenv a été chargé (mobile/desktop), on récupère API_URL.
              // En Web, dotenv n’est pas initialisé et cela lèvera NotInitializedError.
              return dotenv.env['API_URL'] ?? "http://localhost:8080";
            } catch (_) {
              // Fallback si dotenv n’est pas chargé
              return "http://localhost:8080";
            }
          })();

  /// Inscription : envoie POST /api/auth/register
  /// - Si HTTP 201, succès → on retourne simplement `void`.
  /// - Sinon, on tente d’extraire le champ `error` du JSON et on jette une Exception.
  Future<void> register({
    required String username,
    required String email,
    required String password,
    required String role,
  }) async {
    final uri = Uri.parse("$_baseUrl/api/auth/register");
    final Map<String, dynamic> payload = {
      'username': username,
      'email': email,
      'password': password,
      'role': role,
    };

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode == 201) {
      // Succès : l’API a renvoyé 201 et un JSON { user: {...} } sans token
      return;
    } else {
      // En cas d’erreur (400, 409, etc.), on tente de récupérer le message depuis { error: "..." }
      try {
        final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
        final msg = errorBody['error'] as String?;
        throw Exception(msg ?? "Erreur inconnue lors de l'inscription");
      } catch (_) {
        // Si le corps n’est pas un JSON valide ou qu’il n’y a pas de champ error
        throw Exception("Erreur inattendue : code HTTP ${response.statusCode}");
      }
    }
  }

  /// Connexion : envoie POST /api/auth/login
  /// - Si HTTP 200, l’API renvoie { token: "..." } → on stocke et retourne ce token.
  /// - Sinon, on jette une Exception avec le message d'erreur.
  Future<String> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse("$_baseUrl/api/auth/login");
    final Map<String, dynamic> payload = {'email': email, 'password': password};

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      // Le corps doit contenir { token: "..." }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final token = body['token'] as String?;
      if (token == null) {
        throw Exception("Réponse invalide du serveur : pas de token");
      }
      // Stockage sécurisé du token
      await _secureStorage.write(key: 'jwt_token', value: token);
      return token;
    } else {
      // Tentative de récupérer le champ `error` du JSON de réponse
      try {
        final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
        final msg = errorBody['error'] as String?;
        throw Exception(msg ?? "Erreur inconnue lors de la connexion");
      } catch (_) {
        throw Exception("Erreur inattendue : code HTTP ${response.statusCode}");
      }
    }
  }

  /// Récupère le token JWT stocké (ou `null` si aucun)
  Future<String?> getToken() async {
    return _secureStorage.read(key: 'jwt_token');
  }

  /// Supprime le token en mémoire → déconnexion
  Future<void> logout() async {
    await _secureStorage.delete(key: 'jwt_token');
  }
}
