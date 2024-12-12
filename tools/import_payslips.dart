import 'dart:io';
import 'package:path/path.dart';
import '../lib/services/database_helper.dart';
import '../lib/utils/payslip_importer.dart';

void main(List<String> arguments) async {
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
    final dbHelper = DatabaseHelper.instance;
    final importer = PayslipImporter(dbHelper);
    
    print('Starting import...');
    await importer.importFromExcel(filePath);
    print('Import completed successfully');
    
    exit(0);
  } catch (e) {
    print('Error during import: $e');
    exit(1);
  }
} 