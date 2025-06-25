import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:universal_platform/universal_platform.dart';

class ContentService {
  final String _baseUrl;

  ContentService()
      : _baseUrl = (() {
          try {
            return dotenv.env['API_URL'] ?? 'http://localhost:8080';
          } catch (_) {
            return 'http://localhost:8080';
          }
        })();

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
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
        ),
      );
    } else {
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          filePath,
          filename: fileName,
        ),
      );
    }

    final streamed = await request.send();
    if (streamed.statusCode != 201) {
      final respBody = await streamed.stream.bytesToString();
      throw Exception('Erreur ${streamed.statusCode} : $respBody');
    }
  }
}
