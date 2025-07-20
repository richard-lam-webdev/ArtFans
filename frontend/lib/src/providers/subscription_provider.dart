import 'package:flutter/foundation.dart';
import '../services/subscription_service.dart';

enum SubscriptionStatus { initial, loading, loaded, error }

class SubscriptionProvider extends ChangeNotifier {
  final SubscriptionService _subscriptionService;

  SubscriptionProvider({required SubscriptionService subscriptionService})
    : _subscriptionService = subscriptionService;

  SubscriptionStatus _status = SubscriptionStatus.initial;
  List<Map<String, dynamic>> _mySubscriptions = [];
  final Map<String, bool> _subscriptionCache = {};
  Map<String, dynamic>? _creatorStats;
  String? _errorMessage;

  SubscriptionStatus get status => _status;
  List<Map<String, dynamic>> get mySubscriptions => _mySubscriptions;
  Map<String, dynamic>? get creatorStats => _creatorStats;
  String? get errorMessage => _errorMessage;

  void initializeFeedSubscriptions(List<Map<String, dynamic>> feedItems) {
    debugPrint('🔄 Initialisation des abonnements depuis le feed...');
    for (final item in feedItems) {
      final creatorId = item['creator_id']?.toString();
      final isSubscribed = item['is_subscribed'] as bool? ?? false;

      if (creatorId != null) {
        _subscriptionCache[creatorId] = isSubscribed;
        debugPrint('📝 Cache: Creator $creatorId -> $isSubscribed');
      }
    }
    debugPrint(
      '✅ Cache initialisé avec ${_subscriptionCache.length} créateurs',
    );
  }

  void setSubscriptionStatus(String creatorId, bool isSubscribed) {
    debugPrint('🔄 Mise à jour manuelle: Creator $creatorId -> $isSubscribed');
    _subscriptionCache[creatorId] = isSubscribed;
    notifyListeners();
  }

  Future<bool> subscribeToCreator(String creatorId) async {
    debugPrint('📝 Tentative d\'abonnement à $creatorId');
    _status = SubscriptionStatus.loading;
    notifyListeners();

    try {
      await _subscriptionService.subscribeToCreator(creatorId);

      _subscriptionCache[creatorId] = true;
      debugPrint(
        '✅ Abonnement réussi: Cache mis à jour pour $creatorId -> true',
      );

      _status = SubscriptionStatus.loaded;
      _errorMessage = null;
      notifyListeners();

      fetchMySubscriptions();

      return true;
    } catch (e) {
      debugPrint('❌ Erreur abonnement: $e');
      _status = SubscriptionStatus.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> unsubscribeFromCreator(String creatorId) async {
    debugPrint('📝 Tentative de désabonnement de $creatorId');
    _status = SubscriptionStatus.loading;
    notifyListeners();

    try {
      await _subscriptionService.unsubscribeFromCreator(creatorId);

      _subscriptionCache[creatorId] = false;
      debugPrint(
        '✅ Désabonnement réussi: Cache mis à jour pour $creatorId -> false',
      );

      _status = SubscriptionStatus.loaded;
      _errorMessage = null;
      notifyListeners();

      fetchMySubscriptions();

      return true;
    } catch (e) {
      debugPrint('❌ Erreur désabonnement: $e');
      _status = SubscriptionStatus.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> isSubscribedToCreator(String creatorId) async {
    if (_subscriptionCache.containsKey(creatorId)) {
      return _subscriptionCache[creatorId]!;
    }

    try {
      final result = await _subscriptionService.checkSubscription(creatorId);
      final isSubscribed = result['subscribed'] as bool? ?? false;

      _subscriptionCache[creatorId] = isSubscribed;
      notifyListeners();

      return isSubscribed;
    } catch (e) {
      debugPrint('Erreur vérification abonnement: $e');
      return false;
    }
  }

  bool isSubscribed(String creatorId) {
    final result = _subscriptionCache[creatorId] ?? false;
    debugPrint('🔍 Vérification cache: Creator $creatorId -> $result');
    return result;
  }

  Future<void> fetchMySubscriptions() async {
    try {
      final result = await _subscriptionService.getMySubscriptions();
      _mySubscriptions = List<Map<String, dynamic>>.from(
        result['subscriptions'] ?? [],
      );

      for (final subscription in _mySubscriptions) {
        final creatorId = subscription['creator_id'].toString();
        final isActive = subscription['is_active'] as bool? ?? false;
        _subscriptionCache[creatorId] = isActive;
      }

      _status = SubscriptionStatus.loaded;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _status = SubscriptionStatus.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> refreshSubscriptionStatus(String creatorId) async {
    try {
      final result = await _subscriptionService.checkSubscription(creatorId);
      final isSubscribed = result['subscribed'] as bool? ?? false;

      if (_subscriptionCache[creatorId] != isSubscribed) {
        _subscriptionCache[creatorId] = isSubscribed;
        debugPrint('🔄 Refresh: Creator $creatorId -> $isSubscribed');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erreur refresh subscription: $e');
    }
  }

  Future<void> fetchCreatorStats() async {
    try {
      final result = await _subscriptionService.getCreatorStats();
      _creatorStats = result['data'] as Map<String, dynamic>?;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  void clearCache() {
    _subscriptionCache.clear();
    _mySubscriptions.clear();
    _creatorStats = null;
    _status = SubscriptionStatus.initial;
    _errorMessage = null;
    notifyListeners();
  }

  Map<String, dynamic>? getSubscriptionDetails(String creatorId) {
    try {
      return _mySubscriptions.firstWhere(
        (sub) => sub['creator_id'].toString() == creatorId,
      );
    } catch (e) {
      return null;
    }
  }

  int getTotalMonthlyCost() {
    return _mySubscriptions.where((sub) => sub['is_active'] == true).length *
        30;
  }

  int getActiveSubscriptionCount() {
    return _mySubscriptions.where((sub) => sub['is_active'] == true).length;
  }

  String formatDaysRemaining(int days) {
    if (days <= 0) return 'Expiré';
    if (days == 1) return '1 jour restant';
    return '$days jours restants';
  }

  String formatEndDate(String endDateStr) {
    try {
      final endDate = DateTime.parse(endDateStr);
      final now = DateTime.now();
      final difference = endDate.difference(now).inDays;

      if (difference <= 0) return 'Expiré';
      if (difference == 1) return 'Expire demain';
      if (difference <= 7) return 'Expire dans $difference jours';

      return 'Expire le ${endDate.day}/${endDate.month}/${endDate.year}';
    } catch (e) {
      return 'Date invalide';
    }
  }
}
