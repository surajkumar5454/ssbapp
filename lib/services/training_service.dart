import 'package:flutter/foundation.dart';
import '../models/training.dart';
import 'database_helper.dart';

class TrainingService extends ChangeNotifier {
  final DatabaseHelper _dbHelper;
  List<Training> _trainings = [];
  bool _isLoading = false;
  String? _error;

  TrainingService(this._dbHelper);

  List<Training> get trainings => _trainings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadTrainings(String uidno) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _dbHelper.getTrainings(uidno);
      _trainings = data.map((json) => Training.fromJson(json)).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 