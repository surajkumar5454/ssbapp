import 'package:flutter/foundation.dart';
import '../models/family_member.dart';
import 'database_helper.dart';

class FamilyService extends ChangeNotifier {
  final DatabaseHelper _dbHelper;
  List<FamilyMember> _familyMembers = [];
  bool _isLoading = false;
  String? _error;

  FamilyService(this._dbHelper);

  List<FamilyMember> get familyMembers => _familyMembers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadFamilyMembers(String uidno) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _dbHelper.getFamilyMembers(uidno);
      _familyMembers = data.map((json) => FamilyMember.fromJson(json)).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearData() {
    _familyMembers = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
} 