import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../models/feature.dart';

class FeatureFlagService {
  final String _baseUrl;
  final FlutterSecureStorage _secureStorage;
  final http.Client _client;

  FeatureFlagService({http.Client? client})
    : _secureStorage = const FlutterSecureStorage(),
      _client = client ?? http.Client(),
      _baseUrl = '';


  Future<List<Feature>> getFeatures() async {
    final token = await _secureStorage.read(key: 'jwt_token');
    if (token == null) throw Exception('Pas de token');

    final uri = Uri.parse('$_baseUrl/api/admin/features');
    final res = await _client.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode != 200) {
      final err = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(err['error'] ?? 'Erreur ${res.statusCode}');
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final list = body['features'] as List<dynamic>;
    return list
        .map((e) => Feature.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateFeature(String key, bool enabled) async {
    final token = await _secureStorage.read(key: 'jwt_token');
    if (token == null) throw Exception('Pas de token');

    final uri = Uri.parse('$_baseUrl/api/admin/features/$key');
    final res = await _client.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'enabled': enabled}),
    );

    if (res.statusCode != 200) {
      final err = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(err['error'] ?? 'Erreur ${res.statusCode}');
    }
  }
}
