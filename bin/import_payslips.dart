import 'dart:io';
import 'package:excel/excel.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as path;

void main(List<String> arguments) async {
  // Initialize SQLite
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
    final startTime = DateTime.now();
    print('Starting import at ${startTime.toString()}');
    
    // Open database
    final dbPath = path.join(Directory.current.path, 'pims_2Dec.db');
    final db = await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) async {
          // Enable foreign keys and optimize for performance
          await db.execute('PRAGMA foreign_keys = ON');
          await db.execute('PRAGMA journal_mode = WAL');
          await db.execute('PRAGMA synchronous = NORMAL');
          await db.execute('PRAGMA cache_size = 10000');
          await db.execute('PRAGMA temp_store = MEMORY');
        },
      ),
    );

    // Add this after opening the database and before starting import
    print('\nClearing existing pay slips data...');
    await db.execute('DELETE FROM pay_slips');
    await db.execute('DELETE FROM sqlite_sequence WHERE name="pay_slips"'); // Reset auto-increment
    print('Pay slips table cleared');

    // Create pay_slips table if it doesn't exist
    print('Creating pay_slips table if not exists...');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pay_slips (
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

    print('\nReading Excel file: $filePath');
    final bytes = File(filePath).readAsBytesSync();
    print('File loaded into memory. Parsing Excel data...');
    
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables[excel.tables.keys.first];
    if (sheet == null) {
      print('No data found in Excel file');
      exit(1);
    }

    final totalRows = sheet.rows.length - 1; // Minus header row
    print('\nFound $totalRows rows to process');
    
    int importedCount = 0;
    bool isFirstRow = true;
    final batchSize = 1000;
    List<Map<String, dynamic>> batch = [];

    print('\nStarting batch import process...');
    await db.transaction((txn) async {
      for (var row in sheet.rows) {
        if (isFirstRow) {
          isFirstRow = false;
          continue;
        }
        
        if (row.isEmpty) continue;

        final payslipData = {
          'FYID': row[0]?.value?.toString() ?? '',
          'MonthId': int.tryParse(row[1]?.value?.toString() ?? '0') ?? 0,
          'Year_Main': int.tryParse(row[2]?.value?.toString() ?? '0') ?? 0,
          'MonthFullName': row[3]?.value?.toString() ?? '',
          'EmpType': row[4]?.value?.toString() ?? '',
          'UnitName': row[5]?.value?.toString() ?? '',
          'PERNo': row[6]?.value?.toString() ?? '',
          'EmpName': row[7]?.value?.toString() ?? '',
          'RankShortName': row[8]?.value?.toString() ?? '',
          'PFType': row[9]?.value?.toString() ?? '',
          'SeniortyNo': row[10]?.value?.toString() ?? '',
          'PhoneNo1': row[11]?.value?.toString() ?? '',
          'PanCardNo': row[12]?.value?.toString() ?? '',
          'Vender': row[13]?.value?.toString() ?? '',
          'OldGPFNo': row[14]?.value?.toString() ?? '',
          'NewGPFNo': row[15]?.value?.toString() ?? '',
          'GPF_Head': row[16]?.value?.toString() ?? '',
          'Bank_AC_No': row[17]?.value?.toString() ?? '',
          'PPAN': row[18]?.value?.toString() ?? '',
          'PRAN_No': row[19]?.value?.toString() ?? '',
          'AAN': row[20]?.value?.toString() ?? '',
          'SBFNo': row[21]?.value?.toString() ?? '',
          'GROSS': double.tryParse(row[22]?.value?.toString() ?? '0') ?? 0.0,
          'DEDUCTION': double.tryParse(row[23]?.value?.toString() ?? '0') ?? 0.0,
          'NETPAY': double.tryParse(row[24]?.value?.toString() ?? '0') ?? 0.0,
          'NetBankAmount': double.tryParse(row[25]?.value?.toString() ?? '0') ?? 0.0,
          'New_BP': double.tryParse(row[26]?.value?.toString() ?? '0') ?? 0.0,
          'NPA': double.tryParse(row[27]?.value?.toString() ?? '0') ?? 0.0,
          'Basic_Pay': double.tryParse(row[28]?.value?.toString() ?? '0') ?? 0.0,
          'Grade_Pay': double.tryParse(row[29]?.value?.toString() ?? '0') ?? 0.0,
          'DA': double.tryParse(row[30]?.value?.toString() ?? '0') ?? 0.0,
          'DA_on_TPT': double.tryParse(row[31]?.value?.toString() ?? '0') ?? 0.0,
          'TPT': double.tryParse(row[32]?.value?.toString() ?? '0') ?? 0.0,
          'FAA': double.tryParse(row[33]?.value?.toString() ?? '0') ?? 0.0,
          'Special_pay': double.tryParse(row[34]?.value?.toString() ?? '0') ?? 0.0,
          'FPA': double.tryParse(row[35]?.value?.toString() ?? '0') ?? 0.0,
          'HRA': double.tryParse(row[36]?.value?.toString() ?? '0') ?? 0.0,
          'CILQ': double.tryParse(row[37]?.value?.toString() ?? '0') ?? 0.0,
          'KMA': double.tryParse(row[38]?.value?.toString() ?? '0') ?? 0.0,
          'WA': double.tryParse(row[39]?.value?.toString() ?? '0') ?? 0.0,
          'Medal_allow': double.tryParse(row[40]?.value?.toString() ?? '0') ?? 0.0,
          'Depu_Allow': double.tryParse(row[41]?.value?.toString() ?? '0') ?? 0.0,
          'PCA': double.tryParse(row[42]?.value?.toString() ?? '0') ?? 0.0,
          'SCA': double.tryParse(row[43]?.value?.toString() ?? '0') ?? 0.0,
          'RLA': double.tryParse(row[44]?.value?.toString() ?? '0') ?? 0.0,
          'SDA': double.tryParse(row[45]?.value?.toString() ?? '0') ?? 0.0,
          'NEHRA': double.tryParse(row[46]?.value?.toString() ?? '0') ?? 0.0,
          'Training_Allow': double.tryParse(row[47]?.value?.toString() ?? '0') ?? 0.0,
          'Cash_Handling_Allow': double.tryParse(row[48]?.value?.toString() ?? '0') ?? 0.0,
          'Hardship_allow': double.tryParse(row[49]?.value?.toString() ?? '0') ?? 0.0,
          'Risk_allow': double.tryParse(row[50]?.value?.toString() ?? '0') ?? 0.0,
          'CIOps_Allow': double.tryParse(row[51]?.value?.toString() ?? '0') ?? 0.0,
          'Other_Allow1': double.tryParse(row[52]?.value?.toString() ?? '0') ?? 0.0,
          'Sumptuary_Allow': double.tryParse(row[53]?.value?.toString() ?? '0') ?? 0.0,
          'Security_Allow': double.tryParse(row[54]?.value?.toString() ?? '0') ?? 0.0,
          'Medical_allow': double.tryParse(row[55]?.value?.toString() ?? '0') ?? 0.0,
          'PLI': double.tryParse(row[56]?.value?.toString() ?? '0') ?? 0.0,
          'LIC': double.tryParse(row[57]?.value?.toString() ?? '0') ?? 0.0,
          'Tution_Fee': double.tryParse(row[58]?.value?.toString() ?? '0') ?? 0.0,
          'Less_Pension': double.tryParse(row[59]?.value?.toString() ?? '0') ?? 0.0,
          'GPF_NPS_sub': double.tryParse(row[60]?.value?.toString() ?? '0') ?? 0.0,
          'CGEGIS': double.tryParse(row[61]?.value?.toString() ?? '0') ?? 0.0,
          'Kit_Deduction': double.tryParse(row[62]?.value?.toString() ?? '0') ?? 0.0,
          'Licence_fee': double.tryParse(row[63]?.value?.toString() ?? '0') ?? 0.0,
          'ARGIS': double.tryParse(row[64]?.value?.toString() ?? '0') ?? 0.0,
          'Other_Recovery': double.tryParse(row[65]?.value?.toString() ?? '0') ?? 0.0,
          'Pay_Recovery': double.tryParse(row[66]?.value?.toString() ?? '0') ?? 0.0,
          'Computer_Adv': double.tryParse(row[67]?.value?.toString() ?? '0') ?? 0.0,
          'GPF_adv': double.tryParse(row[68]?.value?.toString() ?? '0') ?? 0.0,
          'Fes_adv': double.tryParse(row[69]?.value?.toString() ?? '0') ?? 0.0,
          'HBA': double.tryParse(row[70]?.value?.toString() ?? '0') ?? 0.0,
          'Pay_adv': double.tryParse(row[71]?.value?.toString() ?? '0') ?? 0.0,
          'Motor_adv': double.tryParse(row[72]?.value?.toString() ?? '0') ?? 0.0,
          'Income_tax': double.tryParse(row[73]?.value?.toString() ?? '0') ?? 0.0,
          'HigEdu_Cess1': double.tryParse(row[74]?.value?.toString() ?? '0') ?? 0.0,
          'PrimEdu_Cess2': double.tryParse(row[75]?.value?.toString() ?? '0') ?? 0.0,
          'RMR': double.tryParse(row[76]?.value?.toString() ?? '0') ?? 0.0,
          'RMA': double.tryParse(row[77]?.value?.toString() ?? '0') ?? 0.0,
          'HCA': double.tryParse(row[78]?.value?.toString() ?? '0') ?? 0.0,
          'STA': double.tryParse(row[79]?.value?.toString() ?? '0') ?? 0.0,
          'TLA': double.tryParse(row[80]?.value?.toString() ?? '0') ?? 0.0,
          'RA': double.tryParse(row[81]?.value?.toString() ?? '0') ?? 0.0,
          'Dress_Allow': double.tryParse(row[82]?.value?.toString() ?? '0') ?? 0.0,
          'High_Altit_Allow': double.tryParse(row[83]?.value?.toString() ?? '0') ?? 0.0,
          'Health_edu_cess': double.tryParse(row[84]?.value?.toString() ?? '0') ?? 0.0,
          'SBF': double.tryParse(row[85]?.value?.toString() ?? '0') ?? 0.0,
          'CWF': double.tryParse(row[86]?.value?.toString() ?? '0') ?? 0.0,
          'Sports_Fund': double.tryParse(row[87]?.value?.toString() ?? '0') ?? 0.0,
          'Battlion_Fund': double.tryParse(row[88]?.value?.toString() ?? '0') ?? 0.0,
          'GIA_FUND': double.tryParse(row[89]?.value?.toString() ?? '0') ?? 0.0,
          'Farewell': double.tryParse(row[90]?.value?.toString() ?? '0') ?? 0.0,
          'Other_Deduction': double.tryParse(row[91]?.value?.toString() ?? '0') ?? 0.0,
          'Profesional_Tax': double.tryParse(row[92]?.value?.toString() ?? '0') ?? 0.0,
          'HQ_OFFICER_Mess': double.tryParse(row[93]?.value?.toString() ?? '0') ?? 0.0,
          'HQ_JCO_Mess': double.tryParse(row[94]?.value?.toString() ?? '0') ?? 0.0,
          'HQ_ORS_Mess': double.tryParse(row[95]?.value?.toString() ?? '0') ?? 0.0,
          'A_Coy': double.tryParse(row[96]?.value?.toString() ?? '0') ?? 0.0,
          'Wet_Canteen': double.tryParse(row[97]?.value?.toString() ?? '0') ?? 0.0,
          'CPC': double.tryParse(row[98]?.value?.toString() ?? '0') ?? 0.0,
          'B_Coy': double.tryParse(row[99]?.value?.toString() ?? '0') ?? 0.0,
          'C_Coy': double.tryParse(row[100]?.value?.toString() ?? '0') ?? 0.0,
          'D_Coy': double.tryParse(row[101]?.value?.toString() ?? '0') ?? 0.0,
          'E_Coy': double.tryParse(row[102]?.value?.toString() ?? '0') ?? 0.0,
          'F_Coy': double.tryParse(row[103]?.value?.toString() ?? '0') ?? 0.0,
          'G_Coy': double.tryParse(row[104]?.value?.toString() ?? '0') ?? 0.0,
          'SP_Coy': double.tryParse(row[105]?.value?.toString() ?? '0') ?? 0.0,
          'BN_Fund_Loan': double.tryParse(row[106]?.value?.toString() ?? '0') ?? 0.0,
          'Family': double.tryParse(row[107]?.value?.toString() ?? '0') ?? 0.0,
          'MISC': double.tryParse(row[108]?.value?.toString() ?? '0') ?? 0.0,
          'CGHS': double.tryParse(row[109]?.value?.toString() ?? '0') ?? 0.0,
        };

        batch.add(payslipData);
        importedCount++;

        // Process batch when it reaches batchSize
        if (batch.length >= batchSize) {
          final batch1 = txn.batch();
          for (var data in batch) {
            batch1.insert('pay_slips', data);
          }
          await batch1.commit(noResult: true);
          
          final percentage = (importedCount * 100 / totalRows).toStringAsFixed(1);
          final currentTime = DateTime.now();
          final elapsedMinutes = currentTime.difference(startTime).inMinutes;
          final estimatedTotalMinutes = (elapsedMinutes * totalRows / importedCount).round();
          final remainingMinutes = estimatedTotalMinutes - elapsedMinutes;
          
          print('''
Progress: $importedCount/$totalRows ($percentage%)
Time elapsed: $elapsedMinutes minutes
Estimated time remaining: $remainingMinutes minutes
Current speed: ${(importedCount / elapsedMinutes).round()} records/minute
''');
          
          batch.clear();
        }

        // Also add debug logging to check values:
        if (importedCount < 2) {  // Print first 2 records for debugging
          print('\n========= Detailed data for row $importedCount =========');
          print('Row length: ${row.length}');
          
          // Print raw Excel data
          print('\nRAW EXCEL DATA:');
          for (int i = 0; i < row.length; i++) {
            var value = row[i]?.value;
            var type = value?.runtimeType;
            print('Column $i: Value="$value" (Type=$type)');
          }
          
          // Print processed data
          print('\nPROCESSED DATA:');
          print('FY ID: ${payslipData['FYID']}');
          print('Month ID: ${payslipData['MonthId']}');
          print('Year: ${payslipData['Year_Main']}');
          print('Month Name: ${payslipData['MonthFullName']}');
          print('Employee: ${payslipData['EmpName']}');
          print('PER No: ${payslipData['PERNo']}');
          print('Rank: ${payslipData['RankShortName']}');
          print('Unit: ${payslipData['UnitName']}');
          
          // Print all numeric values
          print('\nNUMERIC VALUES:');
          print('Basic Pay: ${payslipData['Basic_Pay']}');
          print('Grade Pay: ${payslipData['Grade_Pay']}');
          print('DA: ${payslipData['DA']}');
          print('HRA: ${payslipData['HRA']}');
          print('TPT: ${payslipData['TPT']}');
          print('Gross: ${payslipData['GROSS']}');
          print('Deductions: ${payslipData['DEDUCTION']}');
          print('Net Pay: ${payslipData['NETPAY']}');
          
          print('=================================================\n');
        }
      }

      if (batch.isNotEmpty) {
        final finalBatch = txn.batch();
        for (var data in batch) {
          finalBatch.insert('pay_slips', data);
        }
        await finalBatch.commit(noResult: true);
        batch.clear();
      }
    });

    print('\nCreating indexes for better query performance...');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_pay_slips_perno ON pay_slips(PERNo)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_pay_slips_year_month ON pay_slips(Year_Main, MonthId)');

    await db.close();
    
    final endTime = DateTime.now();
    final totalMinutes = endTime.difference(startTime).inMinutes;
    final recordsPerMinute = (importedCount / totalMinutes).round();
    
    print('''
Import completed successfully!
Total records imported: $importedCount
Total time taken: $totalMinutes minutes
Average speed: $recordsPerMinute records/minute
Started at: ${startTime.toString()}
Finished at: ${endTime.toString()}
''');
    
    exit(0);
  } catch (e, stackTrace) {
    print('\nError during import: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
} 