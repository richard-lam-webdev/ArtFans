import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend/src/services/user_service.dart';

enum UserStatus { initial, loading, loaded, error }

class UserProvider extends ChangeNotifier {
  final UserService _userService;
  Map<String, dynamic>? _user;
  UserStatus _status = UserStatus.initial;
  String? _errorMessage;

  UserProvider({required UserService userService}) : _userService = userService;

  UserStatus get status => _status;
  Map<String, dynamic>? get user => _user;
  String? get errorMessage => _errorMessage;

  Future<void> fetchUserProfile() async {
    _status = UserStatus.loading;
    notifyListeners();

    try {
      final profile = await _userService.getProfile();
      _user = profile;
      _status = UserStatus.loaded;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _status = UserStatus.error;
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      notifyListeners();
    }
  }
}
