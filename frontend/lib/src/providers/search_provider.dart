// lib/src/providers/search_provider.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../services/api_service.dart';

// ---------------------------------------------------------------------------
// Debouncer utilitaire (300 ms par défaut)
// ---------------------------------------------------------------------------
class _Debouncer {
  _Debouncer();
  final Duration _delay = const Duration(milliseconds: 300);
  Timer? _timer;

  void call(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(_delay, action);
  }

  void dispose() => _timer?.cancel();
}

// ---------------------------------------------------------------------------
// Modèles de données (créateurs & contenus) – IDs en String
// ---------------------------------------------------------------------------
class Creator {
  Creator({
    required this.id,
    required this.username,
    required this.avatarUrl,
    required this.isFollowed,
  });

  final String id;
  final String username;
  final String avatarUrl;
  bool isFollowed;

  factory Creator.fromJson(Map<String, dynamic> j) => Creator(
    id: j['id'] as String,
    username: j['username'] as String? ?? '',
    avatarUrl: j['avatar_url'] as String? ?? '',
    isFollowed: j['is_followed'] as bool? ?? false,
  );
}

class Content {
  Content({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.creatorName,
  });

  final String id;
  final String title;
  final String thumbnailUrl;
  final String creatorName;

  factory Content.fromJson(Map<String, dynamic> j) => Content(
    id: j['id'] as String,
    title: j['title'] as String? ?? '',
    thumbnailUrl: j['thumbnail_url'] as String? ?? '',
    creatorName: j['creator_name'] as String? ?? '',
  );
}

// ---------------------------------------------------------------------------
// SearchProvider – logique principale
// ---------------------------------------------------------------------------

class SearchProvider extends ChangeNotifier {
  SearchProvider({required this.token, http.Client? client})
    : _client = client ?? http.Client();

  final String token;
  final http.Client _client;
  final _debouncer = _Debouncer();

  // --- état exposé ---
  bool isLoading = false;
  String query = '';
  String? error;
  List<Creator> creators = [];
  List<Content> contents = [];

  /// Appelé à chaque frappe dans le champ de recherche
  void onQueryChanged(String q) {
    query = q;
    if (q.trim().isEmpty) {
      creators = [];
      contents = [];
      notifyListeners();
      return;
    }
    _debouncer(_search);
  }

  /// Interroge le backend (/api/search)
  Future<void> _search() async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final uri = Uri.parse(
        '${ApiService.baseUrl}/api/search',
      ).replace(queryParameters: {'q': trimmed, 'type': 'creators,contents'});

      // 2) on injecte le token dans les headers
      final res = await _client
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 5));

      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}');
      }

      final Map<String, dynamic> jsonData = jsonDecode(res.body);

      creators =
          (jsonData['creators'] as List<dynamic>)
              .map((e) => Creator.fromJson(e as Map<String, dynamic>))
              .toList();

      contents =
          (jsonData['contents'] as List<dynamic>)
              .map((e) => Content.fromJson(e as Map<String, dynamic>))
              .toList();
    } on TimeoutException {
      error = 'Délai dépassé';
    } catch (e) {
      error = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _debouncer.dispose();
    _client.close();
    super.dispose();
  }
}
