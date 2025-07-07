// lib/src/services/admin_stats_service.dart

import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AdminStatsService {
  final String _baseUrl;
  final FlutterSecureStorage _secureStorage;

  AdminStatsService()
      : _secureStorage = const FlutterSecureStorage(),
        _baseUrl = (() {
          try {
            return dotenv.env['API_URL'] ?? 'http://localhost:8080';
          } catch (_) {
            return 'http://localhost:8080';
          }
        })();

  /// Récupère les statistiques générales pour une période donnée
  Future<Map<String, dynamic>> getStats({int days = 30}) async {
    final token = await _secureStorage.read(key: 'jwt_token');
    if (token == null) throw Exception('Pas de token');

    final uri = Uri.parse('$_baseUrl/api/admin/stats?days=$days');
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
    return body['data'] as Map<String, dynamic>;
  }

  /// Récupère le dashboard complet (stats + tops + graphiques)
  Future<Map<String, dynamic>> getDashboard({int days = 30}) async {
    final token = await _secureStorage.read(key: 'jwt_token');
    if (token == null) throw Exception('Pas de token');

    final uri = Uri.parse('$_baseUrl/api/admin/dashboard?days=$days');
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
    return body['data'] as Map<String, dynamic>;
  }

  /// Récupère le top des créateurs
  Future<List<Map<String, dynamic>>> getTopCreators({
    int limit = 10,
    int days = 30,
  }) async {
    final token = await _secureStorage.read(key: 'jwt_token');
    if (token == null) throw Exception('Pas de token');

    final uri = Uri.parse('$_baseUrl/api/admin/top-creators?limit=$limit&days=$days');
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
    final list = body['data'] as List<dynamic>;
    return List<Map<String, dynamic>>.from(list);
  }

  /// Récupère les données pour le graphique des revenus
  Future<List<Map<String, dynamic>>> getRevenueChart({int days = 7}) async {
    final token = await _secureStorage.read(key: 'jwt_token');
    if (token == null) throw Exception('Pas de token');

    final uri = Uri.parse('$_baseUrl/api/admin/revenue-chart?days=$days');
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
    final list = body['data'] as List<dynamic>;
    return List<Map<String, dynamic>>.from(list);
  }

  /// Récupère les stats rapides (pour affichage temps réel)
  Future<Map<String, dynamic>> getQuickStats() async {
    final token = await _secureStorage.read(key: 'jwt_token');
    if (token == null) throw Exception('Pas de token');

    final uri = Uri.parse('$_baseUrl/api/admin/quick-stats');
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
    return body['data'] as Map<String, dynamic>;
  }
}