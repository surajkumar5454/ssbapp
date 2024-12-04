import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:typed_data';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static Database? _imagesDatabase;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pims_2Dec.db');
    return _database!;
  }

  Future<Database> get imagesDatabase async {
    if (_imagesDatabase != null) return _imagesDatabase!;
    _imagesDatabase = await _initImagesDB('images_resize.db');
    return _imagesDatabase!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = '/data/data/com.example.app_test/databases/pims_2Dec.db';
    return await openDatabase(dbPath);
  }

  Future<Database> _initImagesDB(String filePath) async {
    final dbPath = '/data/data/com.example.app_test/databases/images_resize.db';
    return await openDatabase(dbPath);
  }

  Future<void> _createDB(Database db, int version) async {
    // Tables will be created here if needed
  }

  Future<Map<String, dynamic>?> getUserByCredentials(String uidno) async {
    final db = await database;
    final results = await db.query(
      'parmanentinfo',
      where: 'uidno = ?',
      whereArgs: [uidno],
    );

    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  Future<Map<String, dynamic>?> getPersonalInfo(String uidno) async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT p.*, r.rnk_nm as rank_name,
             d.dist_nm, d.state_nm
      FROM parmanentinfo p
      LEFT JOIN rnk_brn_mas r ON p.rank = r.rnk_cd
      LEFT JOIN district d ON p.district = d.dist_cd
      WHERE p.uidno = ?
    ''', [uidno]);

    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getPostingHistory(String uidno) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT DISTINCT 
        j.uidno, 
        j.name, 
        j.unit,
        u.unit_nm as unit_nm, 
        j.rank,
        r.rnk_nm as rnk_nm,
        j.branch,
        r.brn_nm as brn_nm,
        j.dateofjoin, 
        j.dateofrelv,
        j.typeofjoin,
        j.joiningremark,
        j.status,
        j.jodrnondt
      FROM joininfo j 
      JOIN unitdep u ON u.unit_cd = j.unit 
      JOIN rnk_brn_mas r ON j.rank = r.rnk_cd AND j.branch = r.brn_cd 
      WHERE j.uidno = ? 
      ORDER BY j.dateofjoin DESC
    ''', [uidno]);
  }

  Future<List<Map<String, dynamic>>> getTrainings(String uidno) async {
    final db = await database;
    final trainings = await db.rawQuery('''
      SELECT t.*, tc.course_nm, tc.duration, tc.category
      FROM training t
      LEFT JOIN trainingcourse tc ON t.course = tc.id
      WHERE t.uidno = ?
      ORDER BY t.fromDate DESC
    ''', [uidno]);
    
    return trainings;
  }

  Future<void> updatePersonalInfo(Map<String, dynamic> data) async {
    final db = await database;
    await db.update(
      'parmanentinfo',
      data,
      where: 'uidno = ?',
      whereArgs: [data['uidno']],
    );
  }

  Future<Uint8List?> getProfileImage(String uidno) async {
    final db = await imagesDatabase;
    final results = await db.query(
      'images',
      columns: ['image'],
      where: 'uidno = ?',
      whereArgs: [uidno],
    );

    if (results.isNotEmpty && results.first['image'] != null) {
      return results.first['image'] as Uint8List;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getFamilyMembers(String uidno) async {
    final db = await database;
    return await db.query(
      'familymember',
      where: 'uidno = ?',
      whereArgs: [uidno],
      orderBy: 'sno ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getDocuments(String uidno) async {
    final db = await database;
    return await db.query(
      'documents',
      where: 'uidno = ?',
      whereArgs: [uidno],
      orderBy: 'upload_date DESC',
    );
  }

  Future<int> addDocument(Map<String, dynamic> doc) async {
    final db = await database;
    return await db.insert('documents', doc);
  }

  Future<List<Map<String, dynamic>>> getLeaveHistory(String uidno) async {
    final db = await database;
    return await db.query(
      'leave_applications',
      where: 'uidno = ?',
      whereArgs: [uidno],
      orderBy: 'applied_date DESC',
    );
  }

  Future<int> applyLeave(Map<String, dynamic> leave) async {
    final db = await database;
    return await db.insert('leave_applications', leave);
  }

  Future<void> updateLeave(Map<String, dynamic> leave) async {
    final db = await database;
    await db.update(
      'leave_applications',
      leave,
      where: 'id = ?',
      whereArgs: [leave['id']],
    );
  }
} 