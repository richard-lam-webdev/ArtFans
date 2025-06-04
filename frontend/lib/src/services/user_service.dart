// frontend/lib/src/services/user_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_service.dart';

class UserService {
  final String _baseUrl = dotenv.env['API_URL'] ?? "http://localhost:8080";
  final AuthService _authService;

  // On passe une instance d'AuthService pour récupérer le token
  UserService(this._authService);

  /// Récupère le profil de l'utilisateur connecté via GET /api/users/me
  Future<Map<String, dynamic>> getProfile() async {
    // 1) Lire le token stocké
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception("Utilisateur non authentifié");
    }

    // 2) Construire la requête GET avec le header Authorization
    final uri = Uri.parse("$_baseUrl/api/users/me");
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    // 3) Si tout va bien (200), décoder le JSON et renvoyer le champ "user"
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['user'] as Map<String, dynamic>;
    } else {
      // En cas d’erreur (401, 500, etc.), tenter de lire { error: "..." }
      try {
        final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(
          errorBody['error'] ??
              "Erreur inconnue lors de la récupération du profil",
        );
      } catch (_) {
        throw Exception("Erreur inattendue : code HTTP ${response.statusCode}");
      }
    }
  }
}
