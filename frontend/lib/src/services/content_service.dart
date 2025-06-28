import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ContentService {
  final _baseUrl = const String.fromEnvironment(
    "API_BASE_URL",
    defaultValue: "http://localhost:8080/api",
  );
  final _storage = const FlutterSecureStorage();

  Future<String?> _getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<Map<String, dynamic>?> getContentById(String id) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse("$_baseUrl/contents/$id"),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Map<String, dynamic>.from(data);
    } else {
      throw Exception("Erreur ${response.statusCode} : ${response.body}");
    }
  }

  Future<void> updateContent(
    String id,
    String title,
    String body,
    int price,
  ) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse("$_baseUrl/contents/$id"),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({"title": title, "body": body, "price": price}),
    );
    if (response.statusCode != 200) {
      throw Exception("Erreur ${response.statusCode} : ${response.body}");
    }
  }

  Future<void> deleteContent(String id) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse("$_baseUrl/contents/$id"),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode != 204) {
      throw Exception("Erreur ${response.statusCode} : ${response.body}");
    }
  }

  Future<List<Map<String, dynamic>>> fetchMyContents() async {
    final token = await _getToken();
    if (token == null) throw Exception("Token JWT manquant");

    final response = await http.get(
      Uri.parse("$_baseUrl/contents"),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Erreur ${response.statusCode} : ${response.body}");
    }

    final body = jsonDecode(response.body);
    final contents = body['contents'];
    if (contents is! List) return [];

    return List<Map<String, dynamic>>.from(contents);
  }
}
