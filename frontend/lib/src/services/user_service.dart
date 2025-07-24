import 'dart:convert';
import 'package:http/http.dart' as http;

import 'auth_service.dart';

class UserService {
  final String _baseUrl;
  final AuthService _authService;

  UserService(this._authService)
    : _baseUrl = '';

  Future<Map<String, dynamic>> getProfile() async {
    final token = await _authService.getToken();
    final uri = Uri.parse("$_baseUrl/api/users/me");
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['user'] as Map<String, dynamic>;
    } else {
      try {
        final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(errorBody['error'] ?? "Erreur inattendue");
      } catch (_) {
        throw Exception("Échec du chargement du profil");
      }
    }
  }
}
