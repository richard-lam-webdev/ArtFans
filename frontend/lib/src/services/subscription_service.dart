import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class SubscriptionService {
  final String _baseUrl;
  final FlutterSecureStorage _secureStorage;

  SubscriptionService()
    : _secureStorage = const FlutterSecureStorage(),
      _baseUrl ='';

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
