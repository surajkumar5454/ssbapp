import 'package:flutter/foundation.dart';
import '../models/leave_credit.dart';
import 'database_helper.dart';

class LeaveCreditService extends ChangeNotifier {
  final DatabaseHelper _db;
  List<LeaveCredit> _history = [];
  Map<String, int> _currentBalance = {
    'el': 0,
    'hpl': 0,
    'cl': 0,
  };
  bool _isLoading = false;

  LeaveCreditService(this._db);

  List<LeaveCredit> get history => _history;
  Map<String, int> get currentBalance => _currentBalance;
  bool get isLoading => _isLoading;

  Future<void> loadLeaveCreditHistory(String uidno) async {
    _isLoading = true;
    notifyListeners();

    try {
      _history = await _db.getLeaveCreditHistory(uidno);
      
      // Sort by date in descending order (newest first)
      _history.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
      
      _currentBalance = await _db.getCurrentLeaveBalance(uidno);
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 