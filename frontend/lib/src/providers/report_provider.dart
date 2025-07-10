// lib/src/providers/report_provider.dart

import 'package:flutter/foundation.dart';
import '../services/report_service.dart';

/// Fournit la liste des signalements pour le back-office admin.
class ReportProvider with ChangeNotifier {
  final ReportService reportService;

  ReportProvider({required this.reportService});

  List<Map<String, dynamic>> _reports = [];
  bool _loading = false;
  String? _error;

  /// Signalements récupérés
  List<Map<String, dynamic>> get reports => _reports;

  /// Indique qu’une requête est en cours
  bool get loading => _loading;

  /// Message d’erreur, ou null si tout va bien
  String? get error => _error;

  /// Charge la liste des signalements depuis l’API admin
  Future<void> fetchReports() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await reportService.fetchReports();
      _reports = data;
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }

  /// Soumet un nouveau signalement pour un contenu donné
  Future<void> submitReport(String contentId, {String? reason}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // appel positionnel + named pour `reason`
      await reportService.reportContent(contentId, reason: reason);
      // facultatif : recharger la liste des reports pour l’admin
      await fetchReports();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
