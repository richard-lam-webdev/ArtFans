// lib/src/services/subscription_service.dart

import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class SubscriptionService {
  final String _baseUrl;
  final FlutterSecureStorage _secureStorage;

  SubscriptionService()
      : _secureStorage = const FlutterSecureStorage(),
        _baseUrl = (() {
          try {
            return dotenv.env['API_URL'] ?? 'http://localhost:8080';
          } catch (_) {
            return 'http://localhost:8080';
          }
        })();

  /// S'abonner à un créateur (30€ fixe)
  Future<Map<String, dynamic>> subscribeToCreator(String creatorId) async {
    final token = await _secureStorage.read(key: 'jwt_token');
    if (token == null) throw Exception('Pas de token');

    final uri = Uri.parse('$_baseUrl/api/subscriptions/$creatorId');
    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 201) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } else {
      final errBody = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(errBody['error'] ?? 'Erreur ${res.statusCode}');
    }
  }

  /// Se désabonner d'un créateur
  Future<Map<String, dynamic>> unsubscribeFromCreator(String creatorId) async {
    final token = await _secureStorage.read(key: 'jwt_token');
    if (token == null) throw Exception('Pas de token');

    final uri = Uri.parse('$_baseUrl/api/subscriptions/$creatorId');
    final res = await http.delete(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } else {
      final errBody = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(errBody['error'] ?? 'Erreur ${res.statusCode}');
    }
  }

  /// Vérifier si abonné à un créateur
  Future<Map<String, dynamic>> checkSubscription(String creatorId) async {
    final token = await _secureStorage.read(key: 'jwt_token');
    if (token == null) throw Exception('Pas de token');

    final uri = Uri.parse('$_baseUrl/api/subscriptions/$creatorId');
    final res = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } else {
      final errBody = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(errBody['error'] ?? 'Erreur ${res.statusCode}');
    }
  }

  /// Obtenir mes abonnements détaillés
  Future<Map<String, dynamic>> getMySubscriptions() async {
    final token = await _secureStorage.read(key: 'jwt_token');
    if (token == null) throw Exception('Pas de token');

    final uri = Uri.parse('$_baseUrl/api/subscriptions/my');
    final res = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } else {
      final errBody = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(errBody['error'] ?? 'Erreur ${res.statusCode}');
    }
  }

  /// Obtenir les IDs des créateurs suivis
  Future<List<String>> getFollowedCreatorIds() async {
    final token = await _secureStorage.read(key: 'jwt_token');
    if (token == null) throw Exception('Pas de token');

    final uri = Uri.parse('$_baseUrl/api/subscriptions');
    final res = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final creatorIds = body['creator_ids'] as List<dynamic>;
      return creatorIds.map((id) => id.toString()).toList();
    } else {
      final errBody = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(errBody['error'] ?? 'Erreur ${res.statusCode}');
    }
  }

  /// Obtenir les stats pour un créateur (si on est créateur)
  Future<Map<String, dynamic>> getCreatorStats() async {
    final token = await _secureStorage.read(key: 'jwt_token');
    if (token == null) throw Exception('Pas de token');

    final uri = Uri.parse('$_baseUrl/api/creator/stats');
    final res = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } else {
      final errBody = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(errBody['error'] ?? 'Erreur ${res.statusCode}');
    }
  }
}