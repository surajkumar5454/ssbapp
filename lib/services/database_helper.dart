import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../models/grievance.dart';
import '../models/deputation_opening.dart';
import '../models/deputation_application.dart';
import '../models/grievance_status.dart';
import '../models/leave_credit.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static Database? _imagesDatabase;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> get imagesDatabase async {
    if (_imagesDatabase != null) return _imagesDatabase!;
    _imagesDatabase = await _initImagesDB('images_resize.db');
    return _imagesDatabase!;
  }

  Future<Database> _initDB() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "pims_2Dec.db");

    print('Database path: $path');
    bool dbExists = await File(path).exists();
    print('Database exists: $dbExists');

    if (!dbExists) {
      try {
        // Copy from asset
        ByteData data = await rootBundle.load(join('assets', 'database', 'pims_2Dec.db'));
        List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await File(path).writeAsBytes(bytes, flush: true);
        print('Database copied successfully');
      } catch (e) {
        print('Error copying database: $e');
      }
    }

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onOpen: (db) async {
        // Verify tables
        var tables = await db.rawQuery('SELECT name FROM sqlite_master WHERE type="table"');
        print('Available tables: $tables');
      },
    );
  }

  Future<Database> _initImagesDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path);
  }

  Future<void> _onOpen(Database db) async {
    try {
      // Check if all required columns exist and add them if they don't
      var columns = await db.rawQuery('PRAGMA table_info(grievances)');
      var columnNames = columns.map((c) => c['name'] as String).toList();
      
      if (!columnNames.contains('grievances')) {
        await _createDB(db, 1);
      }
      
      // Add any missing columns
      var requiredColumns = {
        'handler_rank': 'TEXT',
        'handler_unit': 'TEXT',
        'days_elapsed': 'INTEGER',
        'sender_name': 'TEXT',
        'sender_rank': 'TEXT',
        'sender_unit': 'TEXT'
      };
      
      for (var column in requiredColumns.entries) {
        if (!columnNames.contains(column.key)) {
          await db.execute('ALTER TABLE grievances ADD COLUMN ${column.key} ${column.value}');
          print('Added column ${column.key} to grievances table');
        }
      }

      // Update grievances without IDs
      await _updateMissingGrievanceIds(db);
      
    } catch (e) {
      print('Error in _onOpen: $e');
    }
  }

  Future<void> _updateMissingGrievanceIds(Database db) async {
    try {
      // Get all grievances without IDs
      final grievancesWithoutIds = await db.query(
        'grievances',
        where: 'grievance_id IS NULL',
        orderBy: 'submitted_date ASC'
      );

      if (grievancesWithoutIds.isEmpty) {
        print('No grievances without IDs found');
        return;
      }

      print('Found ${grievancesWithoutIds.length} grievances without IDs');

      // Group grievances by month
      final grievancesByMonth = <String, List<Map<String, dynamic>>>{};
      
      for (var grievance in grievancesWithoutIds) {
        final submittedDate = DateTime.parse(grievance['submitted_date'] as String);
        final key = '${submittedDate.year}-${submittedDate.month.toString().padLeft(2, '0')}';
        grievancesByMonth[key] = [...(grievancesByMonth[key] ?? []), grievance];
      }

      // Update each grievance with a new ID
      for (var entry in grievancesByMonth.entries) {
        final yearMonth = entry.key.split('-');
        final year = yearMonth[0].substring(2); // Last 2 digits of year
        final month = yearMonth[1];
        
        int count = 1;
        for (var grievance in entry.value) {
          final grievanceId = 'GR-$year-$month-${count.toString().padLeft(4, '0')}';
          
          await db.update(
            'grievances',
            {'grievance_id': grievanceId},
            where: 'id = ?',
            whereArgs: [grievance['id']],
          );
          
          print('Updated grievance ${grievance['id']} with new ID: $grievanceId');
          count++;
        }
      }
    } catch (e) {
      print('Error updating missing grievance IDs: $e');
    }
  }

  Future<String> generateGrievanceId(Database db, DateTime date) async {
    final year = date.year.toString().substring(2);
    final month = date.month.toString().padLeft(2, '0');
    
    // Get count of grievances for this month
    final count = Sqflite.firstIntValue(await db.rawQuery('''
      SELECT COUNT(*) + 1 FROM grievances 
      WHERE strftime('%Y-%m', submitted_date) = ?
    ''', ['${date.year}-$month'])) ?? 1;

    return 'GR-$year-$month-${count.toString().padLeft(4, '0')}';
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS deputation_openings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        organization TEXT NOT NULL,
        description TEXT NOT NULL,
        location TEXT NOT NULL,
        required_rank TEXT,
        required_experience INTEGER,
        other_criteria TEXT,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        status TEXT NOT NULL,
        created_by TEXT NOT NULL
      )
    ''');

    // Create deputation_applications table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS deputation_applications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        opening_id INTEGER NOT NULL,
        applicant_uin TEXT NOT NULL,
        applied_date TEXT NOT NULL,
        FOREIGN KEY (opening_id) REFERENCES deputation_openings (id),
        UNIQUE (opening_id, applicant_uin)
      )
    ''');

    // Create deputation_admins table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS deputation_admins (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uin TEXT NOT NULL UNIQUE,
        created_at TEXT NOT NULL
      )
    ''');

    // Check if default admin exists before inserting
    final adminExists = await db.query(
      'deputation_admins',
      where: 'uin = ?',
      whereArgs: ['16020013'],
    );

    // Insert default admin only if it doesn't exist
    if (adminExists.isEmpty) {
      try {
        await db.insert('deputation_admins', {
          'uin': '16020013',  // Default admin UIN
          'created_at': DateTime.now().toIso8601String(),
        });
        print('Default admin inserted successfully');
      } catch (e) {
        print('Error inserting default admin: $e');
      }
    }

    // Create grievances table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS grievances (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        grievance_no TEXT,
        subject TEXT,
        description TEXT,
        status TEXT,
        priority TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        submitted_by TEXT,
        handler_id TEXT,
        category TEXT,
        sub_category TEXT,
        attachments TEXT,
        remarks TEXT,
        expected_resolution_date DATE,
        actual_resolution_date DATE,
        is_anonymous INTEGER DEFAULT 0,
        FOREIGN KEY (handler_id) REFERENCES personnel(uid_no),
        FOREIGN KEY (submitted_by) REFERENCES personnel(uid_no)
      )
    ''');

    // Create indices for grievances table
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_grievances_handler_id ON grievances(handler_id)'
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_grievances_submitted_by ON grievances(submitted_by)'
    );

    // Create service_history table
    await createServiceHistoryTable(db);
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

  Future<Map<String, dynamic>?> getPersonalInfo(String uin) async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT 
        p.*, 
        r.rnk_nm as rank_name,
        d.dist_nm, 
        d.state_nm,
        (SELECT MIN(dateofjoin) FROM joininfo WHERE uidno = p.uidno) as first_doj,
        p.doretd as dor
      FROM parmanentinfo p
      LEFT JOIN rnk_brn_mas r ON p.rank = r.rnk_cd
      LEFT JOIN district d ON p.district = d.dist_cd
      WHERE p.uidno = ?
    ''', [uin]);

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
    if (results.isNotEmpty) {
      return results.first['image'] as Uint8List?;
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

  Future<int> submitGrievance(Map<String, dynamic> grievance) async {
    final db = await database;
    
    // Get current year and month
    final now = DateTime.now();
    final year = now.year.toString().substring(2); // Last 2 digits of year
    final month = now.month.toString().padLeft(2, '0');
    
    // Get count of grievances for this month
    final count = Sqflite.firstIntValue(await db.rawQuery('''
      SELECT COUNT(*) + 1 FROM grievances 
      WHERE strftime('%Y-%m', submitted_date) = ?
    ''', ['${now.year}-$month'])) ?? 1;

    // Generate grievance ID: GR-YY-MM-XXXX
    final grievanceId = 'GR-$year-$month-${count.toString().padLeft(4, '0')}';
    
    print('Generated grievance ID: $grievanceId');
    
    // Create the insert data with the generated ID
    final insertData = {
      ...grievance,
      'grievance_id': grievanceId,
      'submitted_date': now.toIso8601String(),  // Ensure consistent date format
    };
    
    final id = await db.insert('grievances', insertData);
    print('Inserted grievance with ID: $id, grievance_id: $grievanceId');
    return id;
  }

  Future<List<Map<String, dynamic>>> getSubmittedGrievances(String fromUin) async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT DISTINCT
        g.*,
        p.name as handler_name,
        r.rnk_nm as handler_rank,
        u.unit_nm as handler_unit,
        CAST(julianday('now') - julianday(g.submitted_date) AS INTEGER) as days_elapsed
      FROM grievances g
      LEFT JOIN parmanentinfo p ON g.to_uin = p.uidno
      LEFT JOIN (
        SELECT DISTINCT uidno, rank, unit, MAX(dateofjoin) as latest_join
        FROM joininfo 
        GROUP BY uidno
      ) j ON p.uidno = j.uidno
      LEFT JOIN rnk_brn_mas r ON j.rank = r.rnk_cd
      LEFT JOIN unitdep u ON j.unit = u.unit_cd
      WHERE g.from_uin = ?
      GROUP BY g.id
      ORDER BY g.submitted_date DESC
    ''', [fromUin]);
    
    print('Loaded ${results.length} submitted grievances');
    for (var grievance in results) {
      print('Grievance ID: ${grievance['grievance_id']}, Status: ${grievance['status']}');
    }
    
    return results;
  }

  Future<List<Map<String, dynamic>>> getReceivedGrievances(String toUin) async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT 
        g.*,
        p.name as sender_name,
        r.rnk_nm as sender_rank,
        u.unit_nm as sender_unit,
        CAST(julianday('now') - julianday(g.submitted_date) AS INTEGER) as days_elapsed
      FROM grievances g
      LEFT JOIN parmanentinfo p ON g.from_uin = p.uidno
      LEFT JOIN (
        SELECT DISTINCT uidno, rank, unit, MAX(dateofjoin) as latest_join
        FROM joininfo 
        GROUP BY uidno
      ) j ON p.uidno = j.uidno
      LEFT JOIN rnk_brn_mas r ON j.rank = r.rnk_cd
      LEFT JOIN unitdep u ON j.unit = u.unit_cd
      WHERE g.to_uin = ?
      GROUP BY g.id
      ORDER BY g.submitted_date DESC
    ''', [toUin]);
    
    print('Loaded ${results.length} received grievances');
    for (var grievance in results) {
      print('Grievance ID: ${grievance['grievance_id']}, Status: ${grievance['status']}');
    }
    
    return results;
  }

  Future<void> updateGrievance(Map<String, dynamic> grievance) async {
    try {
      final db = await database;
      
      // Create a copy of the grievance map for the update
      final updateData = Map<String, dynamic>.from(grievance);
      
      // Ensure the status is stored as a string
      if (updateData['status'] != null) {
        if (updateData['status'] is GrievanceStatus) {
          updateData['status'] = (updateData['status'] as GrievanceStatus).label;
        } else {
          updateData['status'] = updateData['status'].toString();
        }
      }
      
      print('Updating grievance ${updateData['id']} with status: ${updateData['status']}');
      
      final result = await db.update(
        'grievances',
        updateData,
        where: 'id = ?',
        whereArgs: [grievance['id']],
      );
      
      print('Update result: $result rows affected');
      
      // Verify the update
      final updated = await db.query(
        'grievances',
        where: 'id = ?',
        whereArgs: [grievance['id']],
      );
      
      if (updated.isNotEmpty) {
        print('Verified status after update: ${updated.first['status']}');
      }
    } catch (e) {
      print('Error updating grievance: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserDetails(String uidno) async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT DISTINCT 
        p.name,
        r.rnk_nm as rank_name,
        u.unit_nm
      FROM parmanentinfo p
      LEFT JOIN joininfo j ON p.uidno = j.uidno
      LEFT JOIN rnk_brn_mas r ON j.rank = r.rnk_cd
      LEFT JOIN unitdep u ON j.unit = u.unit_cd
      WHERE p.uidno = ?
      ORDER BY j.dateofjoin DESC
      LIMIT 1
    ''', [uidno]);

    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT DISTINCT 
        p.uidno,
        p.name,
        r.rnk_nm as rank_name,
        u.unit_nm as unit_name
      FROM parmanentinfo p
      LEFT JOIN joininfo j ON p.uidno = j.uidno
      LEFT JOIN rnk_brn_mas r ON j.rank = r.rnk_cd
      LEFT JOIN unitdep u ON j.unit = u.unit_cd
      WHERE p.name LIKE ? OR p.uidno LIKE ?
      GROUP BY p.uidno
      ORDER BY p.name
      LIMIT 10
    ''', ['%$query%', '%$query%']);
  }

  Future<void> clearCache() async {
    // Close database connections
    final db = await database;
    final imagesDb = await imagesDatabase;
    
    await db.close();
    await imagesDb.close();
    
    // Clear the database instances
    _database = null;
    _imagesDatabase = null;
  }

  // New Grievance Methods
  Future<int> createGrievance(Map<String, dynamic> grievance) async {
    final db = await database;
    return await db.insert('grievances', {
      'grievance_id': grievance['grievance_id'],
      'from_uin': grievance['from_uin'],
      'to_uin': grievance['to_uin'],
      'subject': grievance['subject'],
      'description': grievance['description'],
      'category': grievance['category'],
      'priority': grievance['priority'],
      'status': 'Pending',  // Initial status is always Pending
      'submitted_date': DateTime.now().toIso8601String(),
      'attachment_path': grievance['attachment_path'],
      'remarks': grievance['remarks'],
      'handler_name': grievance['handler_name'],
      'handler_rank': grievance['handler_rank'],
      'handler_unit': grievance['handler_unit'],
      'sender_name': grievance['sender_name'],
      'sender_rank': grievance['sender_rank'],
      'sender_unit': grievance['sender_unit']
    });
  }

  Future<bool> updateGrievanceStatus(int id, String newStatus, {String? remarks, String? handlerName}) async {
    try {
      final db = await database;
      
      // Get the existing grievance first
      final grievance = await getGrievanceById(id);
      if (grievance == null) {
        print('Grievance not found with id: $id');
        return false;
      }

      // Only update the fields that are changing
      final updateData = <String, dynamic>{
        'status': newStatus,
      };
      
      // Only add these fields if they are provided
      if (remarks != null) updateData['remarks'] = remarks;
      if (handlerName != null) updateData['handler_name'] = handlerName;
      
      print('Updating grievance ${grievance['grievance_id']} (ID: $id) with status: $newStatus');
      
      final result = await db.update(
        'grievances',
        updateData,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (result > 0) {
        print('Successfully updated grievance status to: $newStatus');
        return true;
      }
      
      print('Failed to update grievance status');
      return false;
    } catch (e) {
      print('Error updating grievance status: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getGrievanceById(int id) async {
    final db = await database;
    final results = await db.query(
      'grievances',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<bool> forwardGrievance(int id, String newToUin, String handlerName, String handlerRank, String handlerUnit) async {
    try {
      final db = await database;
      
      // Get the existing grievance first
      final grievance = await getGrievanceById(id);
      if (grievance == null) return false;

      final updateData = {
        'to_uin': newToUin,
        'handler_name': handlerName,
        'handler_rank': handlerRank,
        'handler_unit': handlerUnit,
        'status': GrievanceStatus.inProgress.label,  // Use the enum value
      };
      
      print('Forwarding grievance ${grievance['grievance_id']} to UIN: $newToUin');
      
      final result = await db.update(
        'grievances',
        updateData,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (result > 0) {
        print('Successfully forwarded grievance');
        return true;
      }
      
      print('Failed to forward grievance');
      return false;
    } catch (e) {
      print('Error forwarding grievance: $e');
      return false;
    }
  }

  Future<bool> resolveGrievance(int id, String remarks) async {
    print('Resolving grievance $id');
    return await updateGrievanceStatus(id, GrievanceStatus.resolved.label, remarks: remarks);
  }

  Future<bool> returnGrievance(int id, String remarks) async {
    print('Returning grievance $id');
    return await updateGrievanceStatus(id, GrievanceStatus.returned.label, remarks: remarks);
  }

  Future<bool> closeGrievance(int id, String remarks) async {
    print('Closing grievance $id');
    return await updateGrievanceStatus(id, GrievanceStatus.closed.label, remarks: remarks);
  }

  Future<bool> selfResolveGrievance(int id, String remarks) async {
    print('Self-resolving grievance $id');
    return await updateGrievanceStatus(id, GrievanceStatus.selfResolved.label, remarks: remarks);
  }

  Future<Map<String, dynamic>> insertGrievance(Map<String, dynamic> grievance) async {
    final db = await database;
    
    // Generate grievance ID only if this is a new submission (not a movement/update)
    if (grievance['grievance_id'] == null) {
      final now = DateTime.now();
      final year = now.year.toString().substring(2);
      final month = now.month.toString().padLeft(2, '0');
      
      final count = Sqflite.firstIntValue(await db.rawQuery('''
        SELECT COUNT(*) + 1 FROM grievances 
        WHERE strftime('%Y-%m', submitted_date) = ?
      ''', ['${now.year}-$month'])) ?? 1;

      grievance['grievance_id'] = 'GR-$year-$month-${count.toString().padLeft(4, '0')}';
    }
    
    // Ensure submitted_date is set for new submissions only
    grievance['submitted_date'] ??= DateTime.now().toIso8601String();
    
    final id = await db.insert('grievances', grievance);
    
    return {
      'id': id,
      'grievance_id': grievance['grievance_id']
    };
  }

  // Deputation Opening Methods
  Future<int> createDeputationOpening(Map<String, dynamic> opening) async {
    final db = await database;
    return await db.insert('deputation_openings', opening);
  }

  Future<List<Map<String, dynamic>>> getEligibleDeputationOpenings(String uin) async {
    final db = await database;
    final userInfo = await getUserByCredentials(uin);
    if (userInfo == null) return [];

    final rank = userInfo['rank'];
    final experience = await calculateExperience(uin);

    return await db.query(
      'deputation_openings',
      where: '''
        status = ? 
        AND end_date >= ? 
        AND (required_rank = ? OR required_rank IS NULL)
        AND (required_experience <= ? OR required_experience IS NULL)
      ''',
      whereArgs: ['Active', DateTime.now().toIso8601String(), rank, experience],
      orderBy: 'created_at DESC',
    );
  }

  // Deputation Application Methods
  Future<bool> applyForDeputation(Map<String, dynamic> application) async {
    final db = await database;
    try {
      await db.insert('deputation_applications', application);
      return true;
    } catch (e) {
      print('Error applying for deputation: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getUserDeputationApplications(String uin) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        a.*,
        o.title,
        o.organization,
        o.location,
        o.start_date,
        o.end_date
      FROM deputation_applications a
      JOIN deputation_openings o ON a.opening_id = o.id
      WHERE a.applicant_uin = ?
      ORDER BY a.applied_date DESC
    ''', [uin]);
  }

  // Helper method to calculate user's experience
  Future<int> calculateExperience(String uin) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT MIN(dateofjoin) as first_join
      FROM joininfo
      WHERE uidno = ?
    ''', [uin]);
    
    if (result.isEmpty || result.first['first_join'] == null) return 0;
    
    final firstJoin = DateTime.parse(result.first['first_join'] as String);
    return DateTime.now().difference(firstJoin).inDays ~/ 365;
  }

  Future<List<Map<String, dynamic>>> getApplicationsForOpening(int openingId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        a.*,
        p.name as applicant_name,
        r.rnk_nm as applicant_rank,
        u.unit_nm as applicant_unit,
        (
          SELECT CAST(((julianday('now') - julianday(MIN(dateofjoin))) / 365) AS INTEGER)
          FROM joininfo
          WHERE uidno = a.applicant_uin
        ) as experience
      FROM deputation_applications a
      JOIN parmanentinfo p ON a.applicant_uin = p.uidno
      LEFT JOIN joininfo j ON a.applicant_uin = j.uidno
      LEFT JOIN rnk_brn_mas r ON j.rank = r.rnk_cd
      LEFT JOIN unitdep u ON j.unit = u.unit_cd
      WHERE a.opening_id = ?
      GROUP BY a.id
      ORDER BY a.applied_date DESC
    ''', [openingId]);
  }

  Future<bool> updateApplicationStatus(
    int applicationId,
    String newStatus, {
    String? remarks,
  }) async {
    try {
      final db = await database;
      
      final updateData = <String, dynamic>{
        'status': newStatus,
      };
      
      if (remarks != null) {
        updateData['remarks'] = remarks;
      }
      
      final result = await db.update(
        'deputation_applications',
        updateData,
        where: 'id = ?',
        whereArgs: [applicationId],
      );
      
      // Also update the applicant's notification
      if (result > 0) {
        final application = await db.query(
          'deputation_applications',
          where: 'id = ?',
          whereArgs: [applicationId],
        );
        
        if (application.isNotEmpty) {
          final opening = await db.query(
            'deputation_openings',
            where: 'id = ?',
            whereArgs: [application.first['opening_id']],
          );
          
          if (opening.isNotEmpty) {
            await createNotification(
              application.first['applicant_uin'] as String,
              'Deputation Application Update',
              'Your application for ${opening.first['title']} has been $newStatus',
              'deputation_application',
              applicationId,
            );
          }
        }
      }
      
      return result > 0;
    } catch (e) {
      print('Error updating application status: $e');
      return false;
    }
  }

  Future<bool> withdrawApplication(int applicationId, String remarks) async {
    try {
      final db = await database;
      
      final result = await db.update(
        'deputation_applications',
        {
          'status': ApplicationStatus.withdrawn.label,
          'remarks': remarks,
        },
        where: 'id = ?',
        whereArgs: [applicationId],
      );
      
      return result > 0;
    } catch (e) {
      print('Error withdrawing application: $e');
      return false;
    }
  }

  // Helper method for notifications
  Future<void> createNotification(
    String userUin,
    String title,
    String message,
    String type,
    int referenceId,
  ) async {
    final db = await database;
    
    await db.insert('notifications', {
      'user_uin': userUin,
      'title': title,
      'message': message,
      'type': type,
      'reference_id': referenceId,
      'created_at': DateTime.now().toIso8601String(),
      'is_read': 0,
    });
  }

  // Method to check if user has already applied
  Future<bool> hasUserApplied(String uin, int openingId) async {
    final db = await database;
    final result = await db.query(
      'deputation_applications',
      where: 'applicant_uin = ? AND opening_id = ?',
      whereArgs: [uin, openingId],
    );
    return result.isNotEmpty;
  }

  // Method to get application statistics
  Future<Map<String, int>> getApplicationStatistics(int openingId) async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT 
        status,
        COUNT(*) as count
      FROM deputation_applications
      WHERE opening_id = ?
      GROUP BY status
    ''', [openingId]);
    
    final stats = <String, int>{};
    for (final row in results) {
      stats[row['status'] as String] = row['count'] as int;
    }
    return stats;
  }

  // Method to get applicant details
  Future<Map<String, dynamic>?> getApplicantDetails(String uin) async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT 
        p.*,
        r.rnk_nm as rank_name,
        u.unit_nm as unit_name,
        (
          SELECT CAST(((julianday('now') - julianday(MIN(dateofjoin))) / 365) AS INTEGER)
          FROM joininfo
          WHERE uidno = p.uidno
        ) as experience
      FROM parmanentinfo p
      LEFT JOIN joininfo j ON p.uidno = j.uidno
      LEFT JOIN rnk_brn_mas r ON j.rank = r.rnk_cd
      LEFT JOIN unitdep u ON j.unit = u.unit_cd
      WHERE p.uidno = ?
      LIMIT 1
    ''', [uin]);
    
    return results.isNotEmpty ? results.first : null;
  }

  Future<List<Map<String, dynamic>>> searchDeputationOpenings({
    String? query,
    String? location,
    String? organization,
    int? minExperience,
    int? maxExperience,
    String? rank,
  }) async {
    final db = await database;
    final whereConditions = <String>[];
    final whereArgs = <dynamic>[];

    if (query != null) {
      whereConditions.add('(title LIKE ? OR description LIKE ?)');
      whereArgs.addAll(['%$query%', '%$query%']);
    }

    if (location != null) {
      whereConditions.add('location LIKE ?');
      whereArgs.add('%$location%');
    }

    // Add other filters...

    final whereClause = whereConditions.isEmpty 
      ? '' 
      : 'WHERE ${whereConditions.join(' AND ')}';

    return await db.rawQuery('''
      SELECT * FROM deputation_openings 
      $whereClause
      ORDER BY created_at DESC
    ''', whereArgs);
  }

  Future<bool> isDeputationAdmin(String uin) async {
    final db = await database;
    final results = await db.query(
      'deputation_admins',  // You'll need to create this table
      where: 'uin = ?',
      whereArgs: [uin],
    );
    return results.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> getDeputationAdmins() async {
    final db = await database;
    try {
      // First get all admins with basic info
      final adminCount = await db.query('deputation_admins');
      print('Total admins in deputation_admins table: ${adminCount.length}');
      
      // Print admin UINs for debugging
      for (var admin in adminCount) {
        print('Admin UIN in table: ${admin['uin']}');
      }

      final results = await db.rawQuery('''
        SELECT DISTINCT
          a.id,
          a.uin,
          a.created_at,
          p.name,
          r.rnk_nm as rank_name,
          u.unit_nm as unit_name,
          j.dateofjoin as posting_date
        FROM deputation_admins a
        LEFT JOIN parmanentinfo p ON a.uin = p.uidno
        LEFT JOIN (
          SELECT j1.*
          FROM joininfo j1
          INNER JOIN (
            SELECT uidno, MAX(dateofjoin) as max_date
            FROM joininfo
            GROUP BY uidno
          ) j2 ON j1.uidno = j2.uidno AND j1.dateofjoin = j2.max_date
        ) j ON p.uidno = j.uidno
        LEFT JOIN rnk_brn_mas r ON j.rank = r.rnk_cd
        LEFT JOIN unitdep u ON j.unit = u.unit_cd
        ORDER BY a.created_at DESC
      ''');
      
      print('Query results: ${results.length} admins found');
      for (var admin in results) {
        print('Admin: ${admin['name']}, UIN: ${admin['uin']}, Rank: ${admin['rank_name']}, Unit: ${admin['unit_name']}');
      }
      return results;
    } catch (e) {
      print('Error getting deputation admins: $e');
      print('Stack trace: ${e is Error ? e.stackTrace : ''}');
      return [];
    }
  }

  Future<bool> addDeputationAdmin(String uin) async {
    try {
      final db = await database;
      await db.insert('deputation_admins', {
        'uin': uin,
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('Error adding deputation admin: $e');
      return false;
    }
  }

  Future<bool> removeDeputationAdmin(String uin) async {
    try {
      final db = await database;
      final result = await db.delete(
        'deputation_admins',
        where: 'uin = ?',
        whereArgs: [uin],
      );
      return result > 0;
    } catch (e) {
      print('Error removing deputation admin: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getRanks(String? query) async {
    final db = await database;
    if (query == null || query.isEmpty) {
      return await db.query(
        'rnk_brn_mas',
        distinct: true,
        columns: ['rnk_cd', 'rnk_nm'],
        groupBy: 'rnk_cd',
        orderBy: 'rnk_nm',
      );
    }
    
    return await db.query(
      'rnk_brn_mas',
      distinct: true,
      columns: ['rnk_cd', 'rnk_nm'],
      where: 'rnk_nm LIKE ?',
      whereArgs: ['%$query%'],
      groupBy: 'rnk_cd',
      orderBy: 'rnk_nm',
    );
  }

  Future<List<Map<String, dynamic>>> getBranches(String rankCode, String? query) async {
    final db = await database;
    if (query == null || query.isEmpty) {
      return await db.query(
        'rnk_brn_mas',
        distinct: true,
        columns: ['brn_cd', 'brn_nm'],
        where: 'rnk_cd = ?',
        whereArgs: [rankCode],
        groupBy: 'brn_cd',
        orderBy: 'brn_nm',
      );
    }
    
    return await db.query(
      'rnk_brn_mas',
      distinct: true,
      columns: ['brn_cd', 'brn_nm'],
      where: 'rnk_cd = ? AND brn_nm LIKE ?',
      whereArgs: [rankCode, '%$query%'],
      groupBy: 'brn_cd',
      orderBy: 'brn_nm',
    );
  }

  Future<List<Map<String, dynamic>>> getActiveDeputationOpenings() async {
    final db = await database;
    return await db.query(
      'deputation_openings',
      where: 'status = ?',
      whereArgs: ['active'],
    );
  }

  Future<void> createDeputationOpeningsTable(Database db) async {
    await db.execute('''
      CREATE TABLE deputation_openings(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        organization TEXT NOT NULL,
        notification_number TEXT NOT NULL,
        notification_date TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        required_rank TEXT NOT NULL,
        required_rank_name TEXT NOT NULL,
        required_branch TEXT NOT NULL,
        required_branch_name TEXT NOT NULL,
        experience_from_rank TEXT,
        experience_from_rank_name TEXT,
        required_experience INTEGER,
        other_criteria TEXT,
        status TEXT NOT NULL
      )
    ''');
  }

  // Add method to get subordinate ranks
  Future<List<Map<String, dynamic>>> getSubordinateRanks(String rankCode) async {
    final db = await database;
    
    // Return all ranks without any restrictions
    return await db.query(
      'rnk_brn_mas',
      distinct: true,
      columns: ['rnk_cd', 'rnk_nm'],
      groupBy: 'rnk_cd',
      orderBy: 'rnk_nm',
    );
  }

  Future<void> createGrievancesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS grievances (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        grievance_no TEXT,
        subject TEXT,
        description TEXT,
        status TEXT,
        priority TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        submitted_by TEXT,
        handler_id TEXT,
        category TEXT,
        sub_category TEXT,
        attachments TEXT,
        remarks TEXT,
        expected_resolution_date DATE,
        actual_resolution_date DATE,
        is_anonymous INTEGER DEFAULT 0,
        FOREIGN KEY (handler_id) REFERENCES personnel(uid_no),
        FOREIGN KEY (submitted_by) REFERENCES personnel(uid_no)
      )
    ''');

    // Create indices
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_grievances_handler_id ON grievances(handler_id)'
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_grievances_submitted_by ON grievances(submitted_by)'
    );
  }

  Future<void> createPaySlipsTable(Database db) async {
    await db.execute('''
      CREATE TABLE pay_slips (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        FYID TEXT,
        MonthId INTEGER,
        Year_Main INTEGER,
        MonthFullName TEXT,
        EmpType TEXT,
        UnitName TEXT,
        PERNo TEXT,
        EmpName TEXT,
        RankShortName TEXT,
        PFType TEXT,
        SeniortyNo TEXT,
        PhoneNo1 TEXT,
        PanCardNo TEXT,
        Vender TEXT,
        OldGPFNo TEXT,
        NewGPFNo TEXT,
        GPF_Head TEXT,
        Bank_AC_No TEXT,
        PPAN TEXT,
        PRAN_No TEXT,
        AAN TEXT,
        SBFNo TEXT,
        GROSS REAL,
        DEDUCTION REAL,
        NETPAY REAL,
        NetBankAmount REAL,
        New_BP REAL,
        NPA REAL,
        Basic_Pay REAL,
        Grade_Pay REAL,
        DA REAL,
        DA_on_TPT REAL,
        TPT REAL,
        FAA REAL,
        Special_pay REAL,
        FPA REAL,
        HRA REAL,
        CILQ REAL,
        KMA REAL,
        WA REAL,
        Medal_allow REAL,
        Depu_Allow REAL,
        PCA REAL,
        SCA REAL,
        RLA REAL,
        SDA REAL,
        NEHRA REAL,
        Training_Allow REAL,
        Cash_Handling_Allow REAL,
        Hardship_allow REAL,
        Risk_allow REAL,
        CIOps_Allow REAL,
        Other_Allow1 REAL,
        Sumptuary_Allow REAL,
        Security_Allow REAL,
        Medical_allow REAL,
        PLI REAL,
        LIC REAL,
        Tution_Fee REAL,
        Less_Pension REAL,
        GPF_NPS_sub REAL,
        CGEGIS REAL,
        Kit_Deduction REAL,
        Licence_fee REAL,
        ARGIS REAL,
        Other_Recovery REAL,
        Pay_Recovery REAL,
        Computer_Adv REAL,
        GPF_adv REAL,
        Fes_adv REAL,
        HBA REAL,
        Pay_adv REAL,
        Motor_adv REAL,
        Income_tax REAL,
        HigEdu_Cess1 REAL,
        PrimEdu_Cess2 REAL,
        RMR REAL,
        RMA REAL,
        HCA REAL,
        STA REAL,
        TLA REAL,
        RA REAL,
        Dress_Allow REAL,
        High_Altit_Allow REAL,
        Health_edu_cess REAL,
        SBF REAL,
        CWF REAL,
        Sports_Fund REAL,
        Battlion_Fund REAL,
        GIA_FUND REAL,
        Farewell REAL,
        Other_Deduction REAL,
        Profesional_Tax REAL,
        HQ_OFFICER_Mess REAL,
        HQ_JCO_Mess REAL,
        HQ_ORS_Mess REAL,
        A_Coy REAL,
        Wet_Canteen REAL,
        CPC REAL,
        B_Coy REAL,
        C_Coy REAL,
        D_Coy REAL,
        E_Coy REAL,
        F_Coy REAL,
        G_Coy REAL,
        SP_Coy REAL,
        BN_Fund_Loan REAL,
        Family REAL,
        MISC REAL,
        CGHS REAL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  Future<List<Map<String, dynamic>>> getPaySlips(String uin) async {
    final db = await database;
    return await db.query(
      'pay_slips',
      where: 'PERNo = ?',
      whereArgs: [uin],
      orderBy: 'Year_Main DESC, MonthId DESC',
    );
  }

  Future<Map<String, dynamic>?> getPaySlip(String uin, int month, int year) async {
    final db = await database;
    final results = await db.query(
      'pay_slips',
      where: 'PERNo = ? AND MonthId = ? AND Year_Main = ?',
      whereArgs: [uin, month, year],
      limit: 1,
    );
    
    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getUserPayslips(String uidno) async {
    final db = await database;
    try {
      print('Querying payslips for uidno: $uidno'); // Debug print
      
      // First, let's check if the table exists and has data
      final tableCheck = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='pay_slips'"
      );
      print('Table check result: $tableCheck'); // Debug print
      
      // Let's check total records in the table
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM pay_slips')
      );
      print('Total records in pay_slips table: $count'); // Debug print
      
      // Let's check records for this specific user
      final userCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM pay_slips WHERE PERNo = ?', [uidno])
      );
      print('Records for user $uidno: $userCount'); // Debug print
      
      // Now perform the actual query
      final results = await db.query(
        'pay_slips',
        where: 'PERNo = ?',
        whereArgs: [uidno],
        orderBy: 'Year_Main DESC, MonthId DESC',
      );
      
      print('Query results: $results'); // Debug print
      return results;
    } catch (e) {
      print('Error fetching payslips for user $uidno: $e');
      print('Stack trace: ${StackTrace.current}'); // Added stack trace
      return [];
    }
  }

  Future<void> createServiceHistoryTable(Database db) async {
    await db.execute('''
      CREATE TABLE service_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        per_no TEXT NOT NULL,
        posting_unit TEXT,
        designation TEXT,
        location TEXT,
        start_date DATE,
        end_date DATE,
        order_no TEXT,
        remarks TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create index for faster queries
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_service_history_per_no ON service_history(per_no)'
    );
  }

  Future<List<Map<String, dynamic>>> getServiceHistory(String perNo) async {
    final db = await database;
    return await db.query(
      'service_history',
      where: 'per_no = ?',
      whereArgs: [perNo],
      orderBy: 'start_date DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getTrainingHistory(String uidno) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        t.*,
        tc.course_nm,
        c.tc_nm as institute_name,
        c.tc_adr as location
      FROM training t
      LEFT JOIN trainingcourse tc ON t.course = tc.id
      LEFT JOIN trainingCenter c ON t.trainingCenter = c.tc_cd
      WHERE t.uidno = ?
      ORDER BY t.fromDate DESC
    ''', [uidno]);
  }

  Future<List<LeaveCredit>> getLeaveCreditHistory(String uidno) async {
    final db = await database;
    final results = await db.query(
      'tbl_leave_credit',
      where: 'uidno = ?',
      whereArgs: [uidno],
      orderBy: 'dt_frm DESC',
    );
    
    return results.map((map) => LeaveCredit.fromMap(map)).toList();
  }

  Future<Map<String, int>> getCurrentLeaveBalance(String uidno) async {
    final db = await database;
    final result = await db.query(
      'tbl_leave_credit',
      where: 'uidno = ?',
      whereArgs: [uidno],
      orderBy: 'dt_to DESC',
      limit: 1,
    );
    
    if (result.isEmpty) {
      return {
        'el': 0,
        'hpl': 0,
        'cl': 0,
      };
    }
    
    return {
      'el': result.first['el_bal'] as int,
      'hpl': result.first['hpl_bal'] as int,
      'cl': result.first['bal_cl'] as int,
    };
  }
} 