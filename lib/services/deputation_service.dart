import 'package:flutter/foundation.dart';
import '../models/deputation_opening.dart';
import '../models/deputation_application.dart';
import 'database_helper.dart';
import 'dart:async';

class DeputationError extends Error {
  final String message;
  final String code;
  final dynamic details;

  DeputationError(this.message, this.code, [this.details]);
}

enum ApplicationStage {
  submitted('Submitted'),
  underReview('Under Review'),
  shortlisted('Shortlisted'),
  interviewScheduled('Interview Scheduled'),
  selected('Selected'),
  rejected('Rejected'),
  withdrawn('Withdrawn');

  final String label;
  const ApplicationStage(this.label);
}

class DeputationService extends ChangeNotifier {
  final DatabaseHelper _dbHelper;
  List<DeputationOpening> _activeOpenings = [];
  List<DeputationOpening> _eligibleOpenings = [];
  List<DeputationApplication> _userApplications = [];
  bool _isLoading = false;
  String? _error;

  DeputationService(this._dbHelper);

  List<DeputationOpening> get activeOpenings => _activeOpenings;
  List<DeputationOpening> get eligibleOpenings => _eligibleOpenings;
  List<DeputationApplication> get userApplications => _userApplications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadActiveOpenings() async {
    _isLoading = true;
    notifyListeners();

    try {
      final openings = await _dbHelper.getActiveDeputationOpenings();
      _activeOpenings = openings.map((o) => DeputationOpening.fromMap(o)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadEligibleOpenings(String uin) async {
    _isLoading = true;
    notifyListeners();

    try {
      final openings = await _dbHelper.getEligibleDeputationOpenings(uin);
      _eligibleOpenings = openings.map((o) => DeputationOpening.fromMap(o)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUserApplications(String uin) async {
    _isLoading = true;
    notifyListeners();

    try {
      final applications = await _dbHelper.getUserDeputationApplications(uin);
      _userApplications = applications.map((a) => DeputationApplication.fromMap(a)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> applyForOpening(Map<String, dynamic> application) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _dbHelper.applyForDeputation(application);
      if (success) {
        await loadUserApplications(application['applicant_uin']);
      }
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createOpening(DeputationOpening opening) async {
    _isLoading = true;
    notifyListeners();

    try {
      final id = await _dbHelper.createDeputationOpening(opening.toMap());
      if (id > 0) {
        await loadActiveOpenings();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
} 