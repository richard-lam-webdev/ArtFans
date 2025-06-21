import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AdminContentService {
  final String _baseUrl;
  final FlutterSecureStorage _secureStorage;

  AdminContentService()
    : _secureStorage = const FlutterSecureStorage(),
      _baseUrl =
          (() {
            try {
              // si dotenv n'est pas initialisé, on tombe dans le catch
              return dotenv.env['API_URL'] ?? 'http://localhost:8080';
            } catch (_) {
              return 'http://localhost:8080';
            }
          })();

  Future<List<Map<String, dynamic>>> fetchContents() async {
    final token = await _secureStorage.read(key: 'jwt_token');
    if (token == null) throw Exception('Pas de token');

    final uri = Uri.parse('$_baseUrl/api/admin/contents');
    final res = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode != 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Erreur HTTP ${res.statusCode}');
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;

    // 🔒 Sécurité ici
    final contents = body['contents'];
    if (contents is! List) {
      return []; // ou throw Exception("Données inattendues")
    }

    return List<Map<String, dynamic>>.from(contents);
  }

  Future<void> deleteContent(String contentId) async {
    final token = await _secureStorage.read(key: 'jwt_token');
    if (token == null) throw Exception('Pas de token');

    final res = await http.delete(
      Uri.parse('$_baseUrl/api/admin/contents/$contentId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode != 200) {
      final err = jsonDecode(res.body)['error'];
      throw Exception(err ?? 'Échec de la suppression');
    }
  }
}
