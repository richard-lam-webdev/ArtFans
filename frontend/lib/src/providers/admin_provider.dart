import 'package:flutter/foundation.dart';
import '../services/admin_service.dart';

enum AdminStatus { initial, loading, loaded, error }

class AdminProvider extends ChangeNotifier {
  final AdminService _adminService;

  AdminProvider({required AdminService adminService})
    : _adminService = adminService;

  AdminStatus _status = AdminStatus.initial;
  List<Map<String, dynamic>> _users = [];
  String? _errorMessage;

  AdminStatus get status => _status;
  List<Map<String, dynamic>> get users => _users;
  String? get errorMessage => _errorMessage;

  /// Charge la liste des utilisateurs depuis l’API.
  Future<void> fetchUsers() async {
    _status = AdminStatus.loading;
    notifyListeners();
    try {
      _users = await _adminService.fetchUsers();
      _status = AdminStatus.loaded;
      _errorMessage = null;
    } catch (e) {
      _status = AdminStatus.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }
    notifyListeners();
  }

  /// Met à jour le rôle d’un utilisateur (creator <-> subscriber).
  ///
  /// newRole doit être soit "creator" soit "subscriber".
  Future<void> updateRole(String userId, String newRole) async {
    _status = AdminStatus.loading;
    notifyListeners();
    try {
      await _adminService.updateUserRole(userId, newRole);
      // Mise à jour locale pour UX instantanée
      final idx = _users.indexWhere((u) => u['ID'] == userId);
      if (idx != -1) {
        _users[idx]['Role'] = newRole;
      }
      _status = AdminStatus.loaded;
      _errorMessage = null;
    } catch (e) {
      _status = AdminStatus.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      rethrow; // pour que l’UI puisse catcher et afficher un SnackBar
    } finally {
      notifyListeners();
    }
  }
}
