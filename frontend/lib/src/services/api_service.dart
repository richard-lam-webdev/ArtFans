import 'package:flutter/foundation.dart';

/// Fournit dynamiquement la base URL de l'API :
/// - En dev Web   => http://localhost:8080
/// - En dev mobile=> http://10.0.2.2:8080
/// - En prod      => '' (URL relative)
class ApiService {
  static String get baseUrl {
    if (kReleaseMode) return '';
    return kIsWeb ? 'http://localhost:8080' : 'http://10.0.2.2:8080';
  }
}
