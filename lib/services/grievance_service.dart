import 'package:flutter/foundation.dart';
import '../models/grievance.dart';
import '../models/grievance_status.dart';
import 'database_helper.dart';

class GrievanceService extends ChangeNotifier {
  final DatabaseHelper _dbHelper;
  List<Grievance> _submittedGrievances = [];
  List<Grievance> _receivedGrievances = [];
  bool _isLoading = false;

  GrievanceService(this._dbHelper);

  List<Grievance> get submittedGrievances => _submittedGrievances;
  List<Grievance> get receivedGrievances => _receivedGrievances;
  bool get isLoading => _isLoading;

  Future<void> loadGrievances(String uin) async {
    _isLoading = true;
    notifyListeners();

    try {
      final submitted = await _dbHelper.getSubmittedGrievances(uin);
      final received = await _dbHelper.getReceivedGrievances(uin);
      
      _submittedGrievances = submitted
          .map((g) => Grievance.fromMap(g as Map<String, dynamic>))
          .toList();
      _receivedGrievances = received
          .map((g) => Grievance.fromMap(g as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading grievances: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitGrievance(Grievance grievance) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _dbHelper.createGrievance(grievance.toMap());
      return true;
    } catch (e) {
      print('Error submitting grievance: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    return await _dbHelper.searchUsers(query);
  }

  Future<bool> forwardGrievance(
    Grievance grievance,
    String newToUin,
    String handlerName,
    String handlerRank,
    String handlerUnit,
  ) async {
    return await _dbHelper.forwardGrievance(
      grievance.id!,
      newToUin,
      handlerName,
      handlerRank,
      handlerUnit,
    );
  }

  Future<bool> returnGrievance(Grievance grievance, String remarks) async {
    return await _dbHelper.returnGrievance(grievance.id!, remarks);
  }

  Future<bool> resolveGrievance(Grievance grievance, String remarks) async {
    return await _dbHelper.resolveGrievance(grievance.id!, remarks);
  }

  Future<bool> closeGrievance(Grievance grievance, String remarks) async {
    return await _dbHelper.closeGrievance(grievance.id!, remarks);
  }

  Future<bool> updateGrievanceStatus(
    Grievance grievance,
    String status, {
    String? remarks,
  }) async {
    return await _dbHelper.updateGrievanceStatus(
      grievance.id!,
      status,
      remarks: remarks,
    );
  }

  Future<bool> resubmitGrievance(Grievance grievance, String remarks) async {
    return await _dbHelper.updateGrievanceStatus(
      grievance.id!,
      GrievanceStatus.pending.label,
      remarks: remarks,
    );
  }

  Future<bool> resolveOwnGrievance(Grievance grievance, String remarks) async {
    return await _dbHelper.selfResolveGrievance(grievance.id!, remarks);
  }

  void clearData() {
    _submittedGrievances = [];
    _receivedGrievances = [];
    notifyListeners();
  }
} 