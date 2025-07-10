// lib/src/services/creator_service.dart

import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class CreatorService {
  final String _baseUrl;

  CreatorService()
      : _baseUrl = dotenv.env['API_URL'] ?? 'http://localhost:8080';

  Future<Map<String, dynamic>> fetchPublicCreatorProfile(String username) async {
    final uri = Uri.parse("$_baseUrl/api/creators/$username");

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Erreur inconnue');
    }
  }
}
