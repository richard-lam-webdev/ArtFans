// lib/src/services/report_service.dart

import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ReportService {
  final String _baseUrl;
  final FlutterSecureStorage _secureStorage;

  ReportService()
    : _secureStorage = const FlutterSecureStorage(),
      _baseUrl =
          (() {
            try {
              return dotenv.env['API_URL'] ?? 'http://localhost:8080';
            } catch (_) {
              return 'http://localhost:8080';
            }
          })();

  /// Signale un contenu donné.
  ///
  /// [contentId] : l'ID du contenu à signaler.
  /// [reason]    : raison facultative du signalement.
  ///
  /// Lance une Exception en cas d'erreur.
  Future<void> reportContent(String contentId, {String? reason}) async {
    final token = await _secureStorage.read(key: 'jwt_token');

    if (token == null) throw Exception('Pas de token');

    final uri = Uri.parse('$_baseUrl/api/contents/$contentId/report');
    final body = reason != null ? {'reason': reason} : {};

    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (res.statusCode != 201) {
      // Tenter de récupérer le message d'erreur retourné par le backend
      String msg;
      try {
        final err = jsonDecode(res.body) as Map<String, dynamic>;
        msg = err['error'] ?? 'Erreur HTTP ${res.statusCode}';
      } catch (_) {
        msg = 'Erreur HTTP ${res.statusCode}';
      }
      throw Exception(msg);
    }
    // En cas de succès, le backend renvoie { "message": "report created" }
  }

  /// Récupère la liste des signalements pour l'admin.
  ///
  /// Lance une Exception en cas d'erreur.
  Future<List<Map<String, dynamic>>> fetchReports() async {
    final token = await _secureStorage.read(key: 'jwt_token');
    if (token == null) throw Exception('Pas de token');

    final uri = Uri.parse('$_baseUrl/api/admin/reports');
    final res = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode != 200) {
      String msg;
      try {
        final err = jsonDecode(res.body) as Map<String, dynamic>;
        msg = err['error'] ?? 'Erreur HTTP ${res.statusCode}';
      } catch (_) {
        msg = 'Erreur HTTP ${res.statusCode}';
      }
      throw Exception(msg);
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final list = data['reports'] as List<dynamic>? ?? [];
    return List<Map<String, dynamic>>.from(list);
  }
}
