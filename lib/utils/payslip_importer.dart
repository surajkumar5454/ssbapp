import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path/path.dart';
import '../services/database_helper.dart';

class PayslipImporter {
  final DatabaseHelper _dbHelper;

  PayslipImporter(this._dbHelper);

  Future<void> importFromExcel(String filePath) async {
    try {
      print('Starting import from: $filePath');
      print('Reading Excel file...');

      final bytes = File(filePath).readAsBytesSync();
      final excel = Excel.decodeBytes(bytes);
      
      // Assuming first sheet contains data
      final sheet = excel.tables[excel.tables.keys.first];
      
      // Skip header row
      bool isFirstRow = true;
      
      int importedCount = 0;
      
      for (var row in sheet.rows) {
        if (isFirstRow) {
          isFirstRow = false;
          continue;
        }
        
        if (row.isEmpty) continue;

        // Map Excel columns to database fields
        final payslipData = {
          'fy_id': row[0]?.value?.toString() ?? '',
          'month_id': int.tryParse(row[1]?.value?.toString() ?? '0') ?? 0,
          'year_main': int.tryParse(row[2]?.value?.toString() ?? '0') ?? 0,
          'month_full_name': row[3]?.value?.toString() ?? '',
          'emp_type': row[4]?.value?.toString() ?? '',
          'unit_name': row[5]?.value?.toString() ?? '',
          'per_no': row[6]?.value?.toString() ?? '',
          'emp_name': row[7]?.value?.toString() ?? '',
          'rank_short_name': row[8]?.value?.toString() ?? '',
          'pf_type': row[9]?.value?.toString() ?? '',
          'seniority_no': row[10]?.value?.toString() ?? '',
          'phone_no': row[11]?.value?.toString() ?? '',
          'pan_card_no': row[12]?.value?.toString() ?? '',
          'vender': row[13]?.value?.toString() ?? '',
          'old_gpf_no': row[14]?.value?.toString() ?? '',
          'new_gpf_no': row[15]?.value?.toString() ?? '',
          'gpf_head': row[16]?.value?.toString() ?? '',
          'bank_ac_no': row[17]?.value?.toString() ?? '',
          'ppan': row[18]?.value?.toString() ?? '',
          'pran_no': row[19]?.value?.toString() ?? '',
          'aan': row[20]?.value?.toString() ?? '',
          'sbf_no': row[21]?.value?.toString() ?? '',
          'gross': double.tryParse(row[22]?.value?.toString() ?? '0') ?? 0.0,
          'deduction': double.tryParse(row[23]?.value?.toString() ?? '0') ?? 0.0,
          'net_pay': double.tryParse(row[24]?.value?.toString() ?? '0') ?? 0.0,
          'net_bank_amount': double.tryParse(row[25]?.value?.toString() ?? '0') ?? 0.0,
          'new_bp': double.tryParse(row[26]?.value?.toString() ?? '0') ?? 0.0,
          'npa': double.tryParse(row[27]?.value?.toString() ?? '0') ?? 0.0,
          'basic_pay': double.tryParse(row[28]?.value?.toString() ?? '0') ?? 0.0,
          'grade_pay': double.tryParse(row[29]?.value?.toString() ?? '0') ?? 0.0,
          'da': double.tryParse(row[30]?.value?.toString() ?? '0') ?? 0.0,
          'da_on_tpt': double.tryParse(row[31]?.value?.toString() ?? '0') ?? 0.0,
          'tpt': double.tryParse(row[32]?.value?.toString() ?? '0') ?? 0.0,
          'faa': double.tryParse(row[33]?.value?.toString() ?? '0') ?? 0.0,
          'special_pay': double.tryParse(row[34]?.value?.toString() ?? '0') ?? 0.0,
          'fpa': double.tryParse(row[35]?.value?.toString() ?? '0') ?? 0.0,
          'hra': double.tryParse(row[36]?.value?.toString() ?? '0') ?? 0.0,
          'cghs': double.tryParse(row[89]?.value?.toString() ?? '0') ?? 0.0,
        };

        await _dbHelper.insert('pay_slips', payslipData);
        importedCount++;
        if (importedCount % 100 == 0) {
          print('Imported $importedCount records...');
        }
      }

      print('Found ${sheet.rows.length - 1} records to import');
      print('Import completed. Total records imported: $importedCount');
    } catch (e) {
      print('Error importing payslip data: $e');
      rethrow;
    }
  }
} 