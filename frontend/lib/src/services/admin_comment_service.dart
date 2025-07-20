import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/src/services/auth_service.dart';

class AdminCommentService {
  final String _baseUrl = dotenv.env['API_BASE_URL'] ?? '';
  Future<Map<String, String>> _headers() async {
    final token = await AuthService().getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<Map<String, dynamic>>> fetchComments({
    int page = 1,
    int pageSize = 20,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/api/admin/comments?page=$page&page_size=$pageSize',
    );
    final resp = await http.get(uri, headers: await _headers());
    if (resp.statusCode != 200) {
      throw Exception('Erreur ${resp.statusCode} : ${resp.body}');
    }
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    return (body['comments'] as List<dynamic>).cast<Map<String, dynamic>>();
  }

  /// Supprime définitivement le commentaire d’ID [id].
  Future<void> deleteComment(String id) async {
    final uri = Uri.parse('$_baseUrl/api/admin/comments/$id');
    final resp = await http.delete(uri, headers: await _headers());
    if (resp.statusCode != 204) {
      throw Exception('Erreur ${resp.statusCode} : ${resp.body}');
    }
  }
}
