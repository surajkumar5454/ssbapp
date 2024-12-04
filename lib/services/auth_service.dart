import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';

class AuthService extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _uin;
  String? _token;
  Map<String, dynamic>? _userData;
  
  bool get isAuthenticated => _isAuthenticated;
  String? get uin => _uin;
  String? get token => _token;
  Map<String, dynamic>? get userData => _userData;

  Future<void> checkAuthState() async {
    // Auto login with specified credentials
    await login("16020013", "1");
  }

  Future<void> login(String uin, String password) async {
    try {
      if (password == "1") {
        final userData = await DatabaseHelper.instance.getUserByCredentials(uin);
        if (userData != null) {
          _isAuthenticated = true;
          _uin = uin;
          _token = 'dummy_token';
          _userData = userData;
          await _saveAuthState();
          notifyListeners();
        } else {
          throw Exception('Invalid credentials');
        }
      } else {
        throw Exception('Invalid credentials');
      }
    } catch (e) {
      _isAuthenticated = false;
      _uin = null;
      _token = null;
      _userData = null;
      rethrow;
    }
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _uin = null;
    _token = null;
    await _clearAuthState();
    notifyListeners();
  }

  Future<void> _saveAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAuthenticated', _isAuthenticated);
    await prefs.setString('uin', _uin ?? '');
    await prefs.setString('token', _token ?? '');
  }

  Future<void> _clearAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isAuthenticated');
    await prefs.remove('uin');
    await prefs.remove('token');
  }
} 