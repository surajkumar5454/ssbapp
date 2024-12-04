import 'package:flutter/foundation.dart';
import '../models/posting.dart';
import 'database_helper.dart';

class PostingService extends ChangeNotifier {
  final DatabaseHelper _dbHelper;
  List<Posting> _postings = [];
  bool _isLoading = false;
  String? _error;

  PostingService(this._dbHelper);

  List<Posting> get postings => _postings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadPostings(String uidno) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _dbHelper.getPostingHistory(uidno);
      _postings = data.map((json) => Posting.fromJson(json)).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 