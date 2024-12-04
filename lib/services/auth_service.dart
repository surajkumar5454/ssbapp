import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';

class AuthService extends ChangeNotifier {
  String? _uin;
  bool _isAuthenticated = false;
  final SharedPreferences _prefs;

  AuthService(this._prefs);

  String? get uin => _uin;
  bool get isAuthenticated => _isAuthenticated;

  // Check initial auth state - default login with 16020013
  Future<void> checkAuthState() async {
    // Check if user was previously logged in
    final savedUin = _prefs.getString('last_login_uin');
    if (savedUin != null) {
      await login(savedUin, '1');
    } else {
      await login('16020013', '1');
    }
  }

  Future<bool> login(String uin, String password) async {
    try {
      if (password == '1') {
        final dbHelper = DatabaseHelper.instance;
        final user = await dbHelper.getUserByCredentials(uin);
        
        if (user != null) {
          _uin = uin;
          _isAuthenticated = true;
          await _prefs.setString('last_login_uin', uin);
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    _uin = null;
    _isAuthenticated = false;
    await _prefs.remove('last_login_uin');
    notifyListeners();
  }
} 