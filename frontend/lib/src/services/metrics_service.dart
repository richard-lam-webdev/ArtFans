import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class MetricsService {
  static final String _baseUrl = (() {
      try {
        return dotenv.env['API_URL'] != null
            ? '${dotenv.env['API_URL']}/api/metrics/client'
            : 'http://localhost:8080/api/metrics/client';
      } catch (_) {
        return 'http://localhost:8080/api/metrics/client';
      }
    })();  
  // Mesurer le temps de chargement d'une page
  static Future<void> reportPageLoad(String pageName, int durationMs) async {
    try {
      await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'type': 'page_load',
          'value': durationMs.toDouble(),
          'labels': {
            'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
            'page': pageName,
          }
        }),
      );
    } catch (_) {
      // Ignorer les erreurs pour ne pas impacter l'UX
    }
  }

  // Mesurer la latence des appels API
  static Future<void> reportAPILatency(String endpoint, int latencyMs) async {
    try {
      await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'type': 'api_latency',
          'value': latencyMs.toDouble(),
          'labels': {
            'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
            'endpoint': endpoint,
          }
        }),
      );
    } catch (_) {}
  }

  // Reporter une erreur
  static Future<void> reportError(String errorType) async {
    try {
      await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'type': 'error',
          'value': 1,
          'labels': {
            'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
            'error_type': errorType,
          }
        }),
      );
    } catch (_) {}
  }
}