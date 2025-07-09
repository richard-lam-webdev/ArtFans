import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:universal_platform/universal_platform.dart';
import 'metrics_service.dart';

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
    final response = await _performRequest(
      '/contents/$id',
      () => http.get(
        Uri.parse('$_baseUrl/api/contents/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ),
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
  final request = http.MultipartRequest('POST', uri)
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

  final start = DateTime.now();
  late http.StreamedResponse streamed;
  try {
    streamed = await request.send();
    final latency = DateTime.now().difference(start).inMilliseconds;
    MetricsService.reportAPILatency('/contents (multipart)', latency);

    if (streamed.statusCode != 201) {
      if (streamed.statusCode >= 500) {
        MetricsService.reportError('http_5xx');
      } else {
        MetricsService.reportError('http_4xx');
      }
      final respBody = await streamed.stream.bytesToString();
      throw Exception('Erreur ${streamed.statusCode} : $respBody');
    }
  } catch (e) {
    MetricsService.reportError('network_error');
    rethrow;
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

  // — Likes
  Future<void> likeContent(String contentId) async {
    final token = await _getToken();
    final resp = await http.post(
      Uri.parse('$_baseUrl/api/contents/$contentId/like'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (resp.statusCode != 200) {
      throw Exception('Erreur like: ${resp.statusCode}');
    }
  }

  Future<void> unlikeContent(String contentId) async {
    final token = await _getToken();
    final resp = await http.delete(
      Uri.parse('$_baseUrl/api/contents/$contentId/like'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (resp.statusCode != 200) {
      throw Exception('Erreur unlike: ${resp.statusCode}');
    }
  }

  // — Commentaires
  Future<List<Map<String, dynamic>>> fetchComments(String contentId) async {
    final token = await _getToken();
    final resp = await http.get(
      Uri.parse('$_baseUrl/api/contents/$contentId/comments'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (resp.statusCode == 200) {
      final body = jsonDecode(resp.body) as List<dynamic>;
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
    final body = {'text': text, if (parentId != null) 'parent_id': parentId};
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

  Future<Map<String, dynamic>> getContentDetailById(String id) async {
    // On récupère d’abord le JSON brut
    final raw = (await getContentById(id))!;

    // On extrait et met en forme :
    final author = raw['author'] as Map<String, dynamic>? ?? {};
    return {
      'id': raw['id'],
      'title': raw['title'],
      'body': raw['body'],
      'price': raw['price'],
      'image_url': raw['image_url'],
      'created_at': raw['created_at'],
      'author_id': author['id'],
      'author_name': author['username'],
    };
  }
}

 Future<http.Response> _performRequest(
    String endpoint,
    Future<http.Response> Function() request,
  ) async {
    final start = DateTime.now();
    try {
      final response = await request();
      
      // Mesurer la latence pour tous les appels
      final latency = DateTime.now().difference(start).inMilliseconds;
      MetricsService.reportAPILatency(endpoint, latency);
      
      // Reporter les erreurs HTTP
      if (response.statusCode >= 500) {
        MetricsService.reportError('http_5xx');
      } else if (response.statusCode >= 400) {
        MetricsService.reportError('http_4xx');
      }
      
      return response;
    } catch (e) {
      MetricsService.reportError('network_error');
      rethrow;
    }
  }