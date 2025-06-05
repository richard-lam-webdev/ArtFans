// lib/src/providers/auth_provider.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend/src/services/auth_service.dart';

enum AuthStatus { authenticated, unauthenticated, loading, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  String? _token;
  String? _errorMessage;
  AuthStatus _status = AuthStatus.unauthenticated;

  AuthProvider({required AuthService authService}) : _authService = authService;

  AuthStatus get status => _status;
  String? get token => _token;
  String? get errorMessage => _errorMessage;

  /// Tente de se connecter ; en cas de succès on stocke le token
  Future<void> login({required String email, required String password}) async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final jwt = await _authService.login(email: email, password: password);
      _token = jwt;
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      notifyListeners();
    }
  }

  /// Inscription (on ne stocke pas de token ici)
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String role,
  }) async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      await _authService.register(
        username: username,
        email: email,
        password: password,
        role: role,
      );
      _status = AuthStatus.unauthenticated;
      // L'inscription réussie redirigera vers login
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      notifyListeners();
      return false;
    }
  }

  /// Déconnecte (supprime le token)
  Future<void> logout() async {
    _token = null;
    _status = AuthStatus.unauthenticated;
    await _authService.logout();
    notifyListeners();
  }
}
