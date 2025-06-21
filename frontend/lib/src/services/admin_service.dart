import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AdminService {
  final String _baseUrl;
  final FlutterSecureStorage _secureStorage;

  AdminService()
    : _secureStorage = const FlutterSecureStorage(),
      _baseUrl =
          (() {
            try {
              return dotenv.env['API_URL'] ?? 'http://localhost:8080';
            } catch (_) {
              return 'http://localhost:8080';
            }
          })();

  /// Récupère la liste des utilisateurs (admin only).
  Future<List<Map<String, dynamic>>> fetchUsers() async {
    final token = await _secureStorage.read(key: 'jwt_token');
    if (token == null) throw Exception('Pas de token');
    final uri = Uri.parse('$_baseUrl/api/admin/users');
    final res = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode != 200) {
      final errBody = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(errBody['error'] ?? 'Erreur ${res.statusCode}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final list = body['users'] as List<dynamic>;
    return List<Map<String, dynamic>>.from(list);
  }

  /// Met à jour le rôle d’un utilisateur (admin only).
  ///
  /// [newRole] doit être 'creator' ou 'subscriber'.
  Future<void> updateUserRole(String userId, String newRole) async {
    final token = await _secureStorage.read(key: 'jwt_token');
    if (token == null) throw Exception('Pas de token');
    final uri = Uri.parse('$_baseUrl/api/admin/users/$userId/role');
    final res = await http.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'role': newRole}),
    );
    if (res.statusCode != 200) {
      final err = _extractError(res.body);
      throw Exception(err ?? 'Échec de la mise à jour du rôle');
    }
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
