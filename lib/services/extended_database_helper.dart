import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class ExtendedDatabaseHelper {
  static final ExtendedDatabaseHelper instance = ExtendedDatabaseHelper._init();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('extended_data.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Documents table
    await db.execute('''
      CREATE TABLE documents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uidno TEXT,
        title TEXT,
        type TEXT,
        file_path TEXT,
        upload_date TEXT,
        expiry_date TEXT,
        verification_status TEXT
      )
    ''');

    // Leave applications table
    await db.execute('''
      CREATE TABLE leave_applications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uidno TEXT,
        leave_type TEXT,
        start_date TEXT,
        end_date TEXT,
        reason TEXT,
        status TEXT,
        applied_date TEXT
      )
    ''');

    // Family members table
    await db.execute('''
      CREATE TABLE family_members (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uidno TEXT,
        name TEXT,
        relation TEXT,
        dob TEXT,
        occupation TEXT,
        contact TEXT
      )
    ''');

    // Qualifications table
    await db.execute('''
      CREATE TABLE qualifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uidno TEXT,
        degree TEXT,
        institution TEXT,
        year TEXT,
        percentage TEXT,
        documents TEXT
      )
    ''');

    // Notifications table
    await db.execute('''
      CREATE TABLE notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uidno TEXT,
        title TEXT,
        message TEXT,
        type TEXT,
        date TEXT,
        read INTEGER
      )
    ''');
  }

  // Document management methods
  Future<int> addDocument(Map<String, dynamic> doc) async {
    final db = await database;
    return await db.insert('documents', doc);
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

  // Leave management methods
  Future<int> applyLeave(Map<String, dynamic> leave) async {
    final db = await database;
    return await db.insert('leave_applications', leave);
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

  // Family member methods
  Future<int> addFamilyMember(Map<String, dynamic> member) async {
    final db = await database;
    return await db.insert('family_members', member);
  }

  Future<List<Map<String, dynamic>>> getFamilyMembers(String uidno) async {
    final db = await database;
    return await db.query(
      'family_members',
      where: 'uidno = ?',
      whereArgs: [uidno],
    );
  }

  // Qualification methods
  Future<int> addQualification(Map<String, dynamic> qual) async {
    final db = await database;
    return await db.insert('qualifications', qual);
  }

  Future<List<Map<String, dynamic>>> getQualifications(String uidno) async {
    final db = await database;
    return await db.query(
      'qualifications',
      where: 'uidno = ?',
      whereArgs: [uidno],
    );
  }

  // Notification methods
  Future<int> addNotification(Map<String, dynamic> notif) async {
    final db = await database;
    return await db.insert('notifications', notif);
  }

  Future<List<Map<String, dynamic>>> getNotifications(String uidno) async {
    final db = await database;
    return await db.query(
      'notifications',
      where: 'uidno = ?',
      whereArgs: [uidno],
      orderBy: 'date DESC',
    );
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

  Future<void> updateNotification(Map<String, dynamic> notification) async {
    final db = await database;
    await db.update(
      'notifications',
      notification,
      where: 'id = ?',
      whereArgs: [notification['id']],
    );
  }

  Future<void> clearNotifications() async {
    final db = await database;
    await db.delete('notifications');
  }
} 