import 'package:flutter/foundation.dart';
import '../models/feature.dart';
import '../services/feature_flag_service.dart';

class FeatureFlagProvider extends ChangeNotifier {
  final FeatureFlagService _service;

  List<Feature> _features = [];
  bool _loading = false;
  String? _error;

  FeatureFlagProvider({required FeatureFlagService service})
    : _service = service;

  List<Feature> get features => _features;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadFeatures() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _features = await _service.getFeatures();
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }

  Future<bool> updateFeature(String key, bool enabled) async {
    final idx = _features.indexWhere((f) => f.key == key);
    final prev = _features[idx].enabled;
    _features[idx].enabled = enabled;
    notifyListeners();

    try {
      await _service.updateFeature(key, enabled);
      return true;
    } catch (e) {
      _error = e.toString();
      _features[idx].enabled = prev;
      notifyListeners();
      return false;
    }
  }
}
