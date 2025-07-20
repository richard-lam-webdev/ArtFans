import 'package:flutter/foundation.dart';
import '../services/report_service.dart';

class ReportProvider with ChangeNotifier {
  final ReportService reportService;

  ReportProvider({required this.reportService});

  List<Map<String, dynamic>> _reports = [];
  bool _loading = false;
  String? _error;

  List<Map<String, dynamic>> get reports => _reports;

  bool get loading => _loading;

  String? get error => _error;

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

  Future<void> submitReport(String contentId, {String? reason}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await reportService.reportContent(contentId, reason: reason);
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
