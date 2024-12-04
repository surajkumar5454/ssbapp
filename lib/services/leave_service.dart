import 'package:flutter/foundation.dart';
import '../models/leave_application.dart';
import 'database_helper.dart';

class LeaveService extends ChangeNotifier {
  final DatabaseHelper _dbHelper;
  List<LeaveApplication> _leaveApplications = [];
  bool _isLoading = false;
  String? _error;

  LeaveService(this._dbHelper);

  List<LeaveApplication> get leaveApplications => _leaveApplications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadLeaveHistory(String uidno) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _dbHelper.getLeaveHistory(uidno);
      _leaveApplications = data.map((json) => LeaveApplication.fromJson(json)).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> applyLeave(LeaveApplication leave) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _dbHelper.applyLeave(leave.toJson());
      _leaveApplications.insert(0, leave);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cancelLeave(int leaveId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _dbHelper.updateLeave({
        'id': leaveId,
        'status': 'Cancelled',
      });
      
      final index = _leaveApplications.indexWhere((leave) => leave.id == leaveId);
      if (index != -1) {
        _leaveApplications[index] = LeaveApplication(
          id: leaveId,
          uidno: _leaveApplications[index].uidno,
          leaveType: _leaveApplications[index].leaveType,
          startDate: _leaveApplications[index].startDate,
          endDate: _leaveApplications[index].endDate,
          reason: _leaveApplications[index].reason,
          status: 'Cancelled',
          appliedDate: _leaveApplications[index].appliedDate,
        );
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