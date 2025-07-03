import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:universal_platform/universal_platform.dart';

class ContentService {
  final String _baseUrl;
  final _storage = const FlutterSecureStorage();

  ContentService()
    : _baseUrl =
          (() {
            try {
              return dotenv.env['API_URL'] ?? 'http://localhost:8080';
            } catch (_) {
              return 'http://localhost:8080';
            }
          })();

  String get baseUrl => _baseUrl;

  Future<String?> _getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<Map<String, dynamic>?> getContentById(String id) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse("$_baseUrl/api/contents/$id"),
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
      Uri.parse("$_baseUrl/api/contents/$id"),
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
      Uri.parse("$_baseUrl/api/contents/$id"),
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
      Uri.parse("$_baseUrl/api/contents"),
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

  Future<void> addContent({
    required String token,
    required String username,
    required String title,
    required String body,
    required String price,
    required String role,
    required String fileName,
    required Uint8List? fileBytes,
    String? filePath,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/contents');
    final request =
        http.MultipartRequest('POST', uri)
          ..headers['Authorization'] = 'Bearer $token'
          ..fields['username'] = username
          ..fields['role'] = role
          ..fields['title'] = title.trim()
          ..fields['body'] = body.trim()
          ..fields['price'] = price.trim();

    if (UniversalPlatform.isWeb || filePath == null) {
      if (fileBytes == null) throw Exception('Impossible de lire le fichier.');
      request.files.add(
        http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
      );
    } else {
      request.files.add(
        await http.MultipartFile.fromPath('file', filePath, filename: fileName),
      );
    }

    final streamed = await request.send();
    if (streamed.statusCode != 201) {
      final respBody = await streamed.stream.bytesToString();
      throw Exception('Erreur ${streamed.statusCode} : $respBody');
    }
  }

  Future<List<Map<String, dynamic>>> fetchFeed() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse("$_baseUrl/api/feed"),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode != 200) {
      throw Exception("Erreur ${response.statusCode} : ${response.body}");
    }

    final body = jsonDecode(response.body);
    final feed = body['feed'];
    if (feed is! List) return [];

    return List<Map<String, dynamic>>.from(feed);
  }

  Future<void> subscribe(String creatorId) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse("$_baseUrl/api/subscriptions/$creatorId"),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 201 && response.statusCode != 204) {
      final message =
          response.body.isNotEmpty ? response.body : "Erreur inconnue";
      throw Exception("Erreur abonnement : $message");
    }
  }

  Future<void> unsubscribe(String creatorId) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse("$_baseUrl/api/subscriptions/$creatorId"),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      final msg = response.body.isNotEmpty ? response.body : 'Erreur inconnue';
      throw Exception("Erreur désabonnement : $msg");
    }
  }

  Future<Uint8List> fetchProtectedImage(String contentId) async {
    final token = await _getToken();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final uri = Uri.parse("$_baseUrl/api/contents/$contentId/image?ts=$ts");
    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token', 'Accept': 'image/png'},
    );
    if (response.statusCode == 200) {
      return response.bodyBytes;
    }
    throw Exception("Erreur ${response.statusCode}");
  }
}
