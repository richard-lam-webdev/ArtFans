import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  // On lit l'URL de l'API depuis .env (ou localhost:8080 par défaut).
  final String _baseUrl = dotenv.env['API_URL'] ?? "http://localhost:8080";

  // Stockage sécurisé du JWT : Keychain/Keystore sur mobile, localStorage sur le Web.
  // La version 8.x de flutter_secure_storage n'accepte plus aOptions/webOptions dans le constructeur.
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

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
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final token = body['token'] as String;
      await _secureStorage.write(key: 'jwt_token', value: token);
    } else {
      final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(
        errorBody['error'] ?? "Erreur inconnue lors de l'inscription",
      );
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

  /// Récupérer le token JWT stocké (ou null si non connecté)
  Future<String?> getToken() async {
    return _secureStorage.read(key: 'jwt_token');
  }

  /// Déconnexion : supprime le token en mémoire
  Future<void> logout() async {
    await _secureStorage.delete(key: 'jwt_token');
  }
}
