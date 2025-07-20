import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend/src/services/auth_service.dart';

enum AuthStatus { authenticated, unauthenticated, loading, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  String? _token;
  String? _errorMessage;
  AuthStatus _status = AuthStatus.loading;
  bool _isInitialized = false;

  AuthProvider({required AuthService authService})
    : _authService = authService {
    _initializeAuth();
  }

  AuthStatus get status => _status;
  String? get token => _token;
  String? get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;

  Future<void> _initializeAuth() async {
    try {
      final storedToken = await _authService.getToken();
      if (storedToken != null && storedToken.isNotEmpty) {
        await _validateToken(storedToken);
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation de l\'auth: $e');
      _status = AuthStatus.unauthenticated;
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _validateToken(String token) async {
    try {
      await _authService.fetchProfile();
      _token = token;
      _status = AuthStatus.authenticated;
      _errorMessage = null;
    } catch (e) {
      debugPrint('Token invalide: $e');
      await _authService.logout();
      _token = null;
      _status = AuthStatus.unauthenticated;
    }
  }

  Future<void> checkAuthStatus() async {
    if (_status == AuthStatus.loading) return;

    _status = AuthStatus.loading;
    notifyListeners();

    await _initializeAuth();
  }

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

  Future<bool> register({
    required String username,
    required String email,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      await _authService.register(
        username: username,
        email: email,
        password: password,
      );
      _status = AuthStatus.unauthenticated;
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

  Future<void> logout() async {
    _token = null;
    _status = AuthStatus.unauthenticated;
    await _authService.logout();
    notifyListeners();
  }
}
