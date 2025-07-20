import 'package:flutter/foundation.dart';
import '../services/admin_stats_service.dart';

enum AdminStatsStatus { initial, loading, loaded, error }

class AdminStatsProvider extends ChangeNotifier {
  final AdminStatsService _adminStatsService;

  AdminStatsProvider({required AdminStatsService adminStatsService})
    : _adminStatsService = adminStatsService;

  AdminStatsStatus _status = AdminStatsStatus.initial;
  Map<String, dynamic> _dashboard = {};
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _topCreators = [];
  List<Map<String, dynamic>> _revenueChart = [];
  Map<String, dynamic> _quickStats = {};
  String? _errorMessage;
  int _selectedPeriod = 30;

  AdminStatsStatus get status => _status;
  Map<String, dynamic> get dashboard => _dashboard;
  Map<String, dynamic> get stats => _stats;
  List<Map<String, dynamic>> get topCreators => _topCreators;
  List<Map<String, dynamic>> get revenueChart => _revenueChart;
  Map<String, dynamic> get quickStats => _quickStats;
  String? get errorMessage => _errorMessage;
  int get selectedPeriod => _selectedPeriod;

  void setPeriod(int days) {
    if (_selectedPeriod != days) {
      _selectedPeriod = days;
      fetchDashboard();
    }
  }

  Future<void> fetchDashboard() async {
    _status = AdminStatsStatus.loading;
    notifyListeners();

    try {
      _dashboard = await _adminStatsService.getDashboard(days: _selectedPeriod);
      _status = AdminStatsStatus.loaded;
      _errorMessage = null;
    } catch (e) {
      _status = AdminStatsStatus.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }
    notifyListeners();
  }

  Future<void> fetchStats() async {
    _status = AdminStatsStatus.loading;
    notifyListeners();

    try {
      _stats = await _adminStatsService.getStats(days: _selectedPeriod);
      _status = AdminStatsStatus.loaded;
      _errorMessage = null;
    } catch (e) {
      _status = AdminStatsStatus.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }
    notifyListeners();
  }

  Future<void> fetchTopCreators({int limit = 10}) async {
    try {
      _topCreators = await _adminStatsService.getTopCreators(
        limit: limit,
        days: _selectedPeriod,
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }
    notifyListeners();
  }

  Future<void> fetchRevenueChart({int days = 7}) async {
    try {
      _revenueChart = await _adminStatsService.getRevenueChart(days: days);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }
    notifyListeners();
  }

  Future<void> fetchQuickStats() async {
    try {
      _quickStats = await _adminStatsService.getQuickStats();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }
    notifyListeners();
  }

  Future<void> refreshAll() async {
    await Future.wait([fetchDashboard(), fetchRevenueChart()]);
  }

  String formatCurrency(int centimes) {
    return '${(centimes / 100).toStringAsFixed(2)}€';
  }

  String formatPercentage(double value) {
    return '${value.toStringAsFixed(1)}%';
  }

  String formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    );
  }
}
