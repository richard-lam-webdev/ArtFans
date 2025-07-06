// lib/providers/search_provider.dart
// --------------------------------------------------------------
// Provider de recherche : debounce (300 ms) + appel HTTP
// Expose un état typé : List<Creator> & List<Content> + isLoading/error.
// --------------------------------------------------------------

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// ---------------------------------------------------------------------------
// Debouncer utilitaire (300 ms par défaut)
// ---------------------------------------------------------------------------
class _Debouncer {
  _Debouncer({this.delay = const Duration(milliseconds: 300)});
  final Duration delay;
  Timer? _timer;

  void call(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() => _timer?.cancel();
}

// ---------------------------------------------------------------------------
// Modèles de données (créateurs & contenus)
// ---------------------------------------------------------------------------
class Creator {
  Creator({
    required this.id,
    required this.username,
    required this.avatarUrl,
    required this.isFollowed,
  });

  final int id;
  final String username;
  final String avatarUrl;
  bool isFollowed;

  factory Creator.fromJson(Map<String, dynamic> j) => Creator(
    id: j['id'] as int,
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

  final int id;
  final String title;
  final String thumbnailUrl;
  final String creatorName;

  factory Content.fromJson(Map<String, dynamic> j) => Content(
    id: j['id'] as int,
    title: j['title'] as String? ?? '',
    thumbnailUrl: j['thumbnail_url'] as String? ?? '',
    creatorName: j['creator_name'] as String? ?? '',
  );
}

// ---------------------------------------------------------------------------
// SearchProvider – logique principale
// ---------------------------------------------------------------------------
class SearchProvider extends ChangeNotifier {
  SearchProvider({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final _debouncer = _Debouncer();

  // --- état exposé ---
  bool isLoading = false;
  String query = '';
  String? error;
  List<Creator> creators = [];
  List<Content> contents = [];

  // -----------------------------------------------------------------------
  // Méthode appelée par le TextField
  // -----------------------------------------------------------------------
  void onQueryChanged(String q) {
    query = q;

    // Si champ vide, reset immédiat sans requête réseau
    if (q.trim().isEmpty) {
      creators = [];
      contents = [];
      notifyListeners();
      return;
    }

    // Lance la recherche après debounce
    _debouncer(_search);
  }

  // -----------------------------------------------------------------------
  // Interroge le backend (/api/search)
  // -----------------------------------------------------------------------
  Future<void> _search() async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final uri = Uri.parse(
        '/api/search',
      ).replace(queryParameters: {'q': trimmed, 'type': 'creators,contents'});

      final res = await _client
          .get(uri)
          .timeout(const Duration(seconds: 5)); // timeout client

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
