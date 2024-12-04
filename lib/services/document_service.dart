import 'package:flutter/foundation.dart';
import '../models/document.dart';
import 'database_helper.dart';

class DocumentService extends ChangeNotifier {
  final DatabaseHelper _dbHelper;
  List<Document> _documents = [];
  bool _isLoading = false;
  String? _error;

  DocumentService(this._dbHelper);

  List<Document> get documents => _documents;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadDocuments(String uidno) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _dbHelper.getDocuments(uidno);
      _documents = data.map((json) => Document.fromJson(json)).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addDocument(Document document) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _dbHelper.addDocument(document.toJson());
      _documents.insert(0, document);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 