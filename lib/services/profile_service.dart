import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import 'database_helper.dart';
import '../services/auth_service.dart';

class ProfileService extends ChangeNotifier {
  final DatabaseHelper _dbHelper;
  UserProfile? _profile;
  Uint8List? _profileImage;
  bool _isLoading = false;
  String? _error;

  ProfileService(this._dbHelper);

  UserProfile? get profile => _profile;
  Uint8List? get profileImage => _profileImage;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadProfile(String uin) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userData = await _dbHelper.getPersonalInfo(uin);
      if (userData != null) {
        _profile = UserProfile.fromJson(userData);
        _profileImage = await _dbHelper.getProfileImage(uin);
        _error = null;
      } else {
        _error = 'Profile not found';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(UserProfile profile) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _dbHelper.updatePersonalInfo(profile.toJson());
      _profile = profile;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePhoto(String photoPath) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_profile != null) {
        final updatedProfile = _profile!.copyWith(photo: photoPath);
        await _dbHelper.updatePersonalInfo(updatedProfile.toJson());
        _profile = updatedProfile;
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 