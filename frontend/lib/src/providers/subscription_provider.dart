// lib/src/providers/subscription_provider.dart

import 'package:flutter/foundation.dart';
import '../services/subscription_service.dart';

enum SubscriptionStatus { initial, loading, loaded, error }

class SubscriptionProvider extends ChangeNotifier {
  final SubscriptionService _subscriptionService;

  SubscriptionProvider({required SubscriptionService subscriptionService})
      : _subscriptionService = subscriptionService;

  SubscriptionStatus _status = SubscriptionStatus.initial;
  List<Map<String, dynamic>> _mySubscriptions = [];
  final Map<String, bool> _subscriptionCache = {}; // Cache pour éviter les appels répétés
  Map<String, dynamic>? _creatorStats;
  String? _errorMessage;

  // Getters
  SubscriptionStatus get status => _status;
  List<Map<String, dynamic>> get mySubscriptions => _mySubscriptions;
  Map<String, dynamic>? get creatorStats => _creatorStats;
  String? get errorMessage => _errorMessage;

  /// S'abonner à un créateur
  Future<bool> subscribeToCreator(String creatorId) async {
    _status = SubscriptionStatus.loading;
    notifyListeners();

    try {
      await _subscriptionService.subscribeToCreator(creatorId);
      
      // Mettre à jour le cache
      _subscriptionCache[creatorId] = true;
      
      _status = SubscriptionStatus.loaded;
      _errorMessage = null;
      notifyListeners();
      
      // Rafraîchir la liste des abonnements
      await fetchMySubscriptions();
      
      return true;
    } catch (e) {
      _status = SubscriptionStatus.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Se désabonner d'un créateur
  Future<bool> unsubscribeFromCreator(String creatorId) async {
    _status = SubscriptionStatus.loading;
    notifyListeners();

    try {
      await _subscriptionService.unsubscribeFromCreator(creatorId);
      
      // Mettre à jour le cache
      _subscriptionCache[creatorId] = false;
      
      _status = SubscriptionStatus.loaded;
      _errorMessage = null;
      notifyListeners();
      
      // Rafraîchir la liste des abonnements
      await fetchMySubscriptions();
      
      return true;
    } catch (e) {
      _status = SubscriptionStatus.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Vérifier si abonné à un créateur (avec cache)
  Future<bool> isSubscribedToCreator(String creatorId) async {
    // Vérifier le cache d'abord
    if (_subscriptionCache.containsKey(creatorId)) {
      return _subscriptionCache[creatorId]!;
    }

    try {
      final result = await _subscriptionService.checkSubscription(creatorId);
      final isSubscribed = result['subscribed'] as bool? ?? false;
      
      // Mettre en cache
      _subscriptionCache[creatorId] = isSubscribed;
      
      return isSubscribed;
    } catch (e) {
      debugPrint('Erreur vérification abonnement: $e');
      return false;
    }
  }

  /// Récupérer mes abonnements
  Future<void> fetchMySubscriptions() async {
    try {
      final result = await _subscriptionService.getMySubscriptions();
      _mySubscriptions = List<Map<String, dynamic>>.from(result['subscriptions'] ?? []);
      
      // Mettre à jour le cache avec les abonnements actuels
      _subscriptionCache.clear();
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

  /// Récupérer les stats créateur (pour les créateurs)
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

  /// Vider le cache (utile lors de la déconnexion)
  void clearCache() {
    _subscriptionCache.clear();
    _mySubscriptions.clear();
    _creatorStats = null;
    _status = SubscriptionStatus.initial;
    _errorMessage = null;
    notifyListeners();
  }

  /// Obtenir les détails d'un abonnement spécifique
  Map<String, dynamic>? getSubscriptionDetails(String creatorId) {
    try {
      return _mySubscriptions.firstWhere(
        (sub) => sub['creator_id'].toString() == creatorId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Calculer le coût total des abonnements
  int getTotalMonthlyCost() {
    return _mySubscriptions.where((sub) => sub['is_active'] == true).length * 30;
  }

  /// Obtenir le nombre d'abonnements actifs
  int getActiveSubscriptionCount() {
    return _mySubscriptions.where((sub) => sub['is_active'] == true).length;
  }

  /// Formater les jours restants
  String formatDaysRemaining(int days) {
    if (days <= 0) return 'Expiré';
    if (days == 1) return '1 jour restant';
    return '$days jours restants';
  }

  /// Formater la date de fin
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