import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class CommentService {
  final _storage = const FlutterSecureStorage();
  final String _baseUrl =
      (() {
        try {
          return dotenv.env['API_URL'] ?? 'http://localhost:8080';
        } catch (_) {
          return 'http://localhost:8080';
        }
      })();

  String get baseUrl => _baseUrl;

  Future<String?> _getToken() => _storage.read(key: 'jwt_token');

  Future<List<Map<String, dynamic>>> fetchComments(String contentId) async {
    final token = await _getToken();
    final resp = await http.get(
      Uri.parse('$_baseUrl/api/contents/$contentId/comments'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (resp.statusCode == 200) {
      final List<dynamic> body = jsonDecode(resp.body);
      return body.cast<Map<String, dynamic>>();
    }
    throw Exception('Erreur fetchComments: ${resp.statusCode}');
  }

  Future<void> postComment(
    String contentId,
    String text, {
    String? parentId,
  }) async {
    final token = await _getToken();
    final Map<String, dynamic> body = {'text': text};
    if (parentId != null) body['parent_id'] = parentId;
    final resp = await http.post(
      Uri.parse('$_baseUrl/api/contents/$contentId/comments'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    if (resp.statusCode != 201) {
      throw Exception('Erreur postComment: ${resp.statusCode}');
    }
  }

  Future<void> likeComment(String commentId) async {
    final token = await _getToken();
    final resp = await http.post(
      Uri.parse('$_baseUrl/api/comments/$commentId/like'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (resp.statusCode != 204) throw Exception('Erreur likeComment');
  }

  Future<void> unlikeComment(String commentId) async {
    final token = await _getToken();
    final resp = await http.delete(
      Uri.parse('$_baseUrl/api/comments/$commentId/like'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (resp.statusCode != 204) throw Exception('Erreur unlikeComment');
  }
}
