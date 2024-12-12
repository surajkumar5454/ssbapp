import 'dart:io';
import 'package:excel/excel.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as path;

void main(List<String> arguments) async {
  sqfliteFfiInit();
  final databaseFactory = databaseFactoryFfi;

  if (arguments.isEmpty) {
    print('Please provide the path to the Excel file');
    exit(1);
  }

  final filePath = arguments[0];
  if (!FileSystemEntity.isFileSync(filePath)) {
    print('File not found: $filePath');
    exit(1);
  }

  try {
    final bytes = File(filePath).readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables[excel.tables.keys.first];

    if (sheet == null) {
      print('No sheet found in Excel file');
      exit(1);
    }

    final startTime = DateTime.now();
    print('Starting service history import at ${startTime.toString()}');
    
    // Open database
    final dbPath = path.join(Directory.current.path, 'pims_2Dec.db');
    final db = await databaseFactory.openDatabase(dbPath);

    print('\nClearing existing service history data...');
    await db.execute('DELETE FROM service_history');
    await db.execute('DELETE FROM sqlite_sequence WHERE name="service_history"');
    print('Service history table cleared');

    int importedCount = 0;
    int errorCount = 0;
    final List<Map<String, dynamic>> batch = [];
    final int batchSize = 100;

    // Skip header row
    for (var row in sheet.rows.skip(1)) {
      try {
        if (row[0]?.value == null) continue;  // Skip empty rows

        final data = {
          'per_no': row[0]?.value?.toString().trim(),
          'posting_unit': row[1]?.value?.toString().trim(),
          'designation': row[2]?.value?.toString().trim(),
          'location': row[3]?.value?.toString().trim(),
          'start_date': row[4]?.value?.toString().trim(),
          'end_date': row[5]?.value?.toString().trim(),
          'order_no': row[6]?.value?.toString().trim(),
          'remarks': row[7]?.value?.toString().trim(),
        };

        batch.add(data);
        importedCount++;

        if (batch.length >= batchSize) {
          await db.transaction((txn) async {
            final batchOp = txn.batch();
            for (var record in batch) {
              batchOp.insert('service_history', record);
            }
            await batchOp.commit(noResult: true);
          });
          batch.clear();
          print('Imported $importedCount records...');
        }
      } catch (e) {
        errorCount++;
        print('Error importing row: $e');
      }
    }

    // Insert remaining records
    if (batch.isNotEmpty) {
      await db.transaction((txn) async {
        final batchOp = txn.batch();
        for (var record in batch) {
          batchOp.insert('service_history', record);
        }
        await batchOp.commit(noResult: true);
      });
    }

    await db.close();
    
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    
    print('''
Import completed!
Total records imported: $importedCount
Errors encountered: $errorCount
Time taken: ${duration.inMinutes} minutes and ${duration.inSeconds % 60} seconds
''');
    
    exit(0);
  } catch (e) {
    print('Error during import: $e');
    exit(1);
  }
} 