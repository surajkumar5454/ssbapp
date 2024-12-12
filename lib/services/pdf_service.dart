import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter/services.dart' show rootBundle, ByteData;

class PDFService {
  static Future<void> generatePayslipPDF(Map<String, dynamic> payslip) async {
    final pdf = pw.Document();

    try {
      // Load and resize logo
      final ByteData logoData = await rootBundle.load('assets/images/SSBlogo.png');
      final Uint8List logoBytes = logoData.buffer.asUint8List();
      final logoImage = pw.MemoryImage(logoBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header with Logo
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Image(logoImage, width: 60, height: 60),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'SASHASTRA SEEMA BAL',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'PAY SLIP',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Employee Details
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.blue900),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildPDFRow('Month & Year', '${payslip['MonthFullName']} ${payslip['Year_Main']}'),
                      _buildPDFRow('Employee Name', payslip['EmpName']?.toString() ?? ''),
                      _buildPDFRow('PER No', payslip['PERNo']?.toString() ?? ''),
                      _buildPDFRow('Rank', payslip['RankShortName']?.toString() ?? ''),
                      _buildPDFRow('Unit', payslip['UnitName']?.toString() ?? ''),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Two Column Layout for Earnings and Deductions
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Earnings Section
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.green900),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Earnings',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.green900,
                              ),
                            ),
                            pw.SizedBox(height: 10),
                            _buildPDFAmountRow('Basic Pay', payslip['Basic_Pay']),
                            _buildPDFAmountRow('Grade Pay', payslip['Grade_Pay']),
                            _buildPDFAmountRow('DA', payslip['DA']),
                            _buildPDFAmountRow('HRA', payslip['HRA']),
                            _buildPDFAmountRow('Transport', payslip['TPT']),
                            pw.Divider(color: PdfColors.green900),
                            _buildPDFAmountRow('Gross', payslip['GROSS'], isBold: true),
                          ],
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    // Deductions Section
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.red900),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Deductions',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.red900,
                              ),
                            ),
                            pw.SizedBox(height: 10),
                            _buildPDFAmountRow('GPF/NPS', payslip['GPF_NPS_sub']),
                            _buildPDFAmountRow('Income Tax', payslip['Income_tax']),
                            _buildPDFAmountRow('CGHS', payslip['CGHS']),
                            pw.Divider(color: PdfColors.red900),
                            _buildPDFAmountRow('Total', payslip['DEDUCTION'], isBold: true),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Net Pay Section
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.blue900),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                    color: PdfColors.blue50,
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'Net Pay',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Rs. ${NumberFormat('#,##,###.##').format(payslip['NETPAY'] ?? 0)}',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                    ],
                  ),
                ),

                // Footer
                pw.Spacer(),
                pw.Divider(color: PdfColors.blue900),
                pw.SizedBox(height: 5),
                pw.Center(
                  child: pw.Text(
                    'This is a computer generated pay slip',
                    style: pw.TextStyle(
                      color: PdfColors.grey700,
                      fontSize: 8,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Save PDF
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/payslip_${payslip['MonthFullName']}_${payslip['Year_Main']}.pdf');
      await file.writeAsBytes(await pdf.save());

      // Open PDF
      await OpenFile.open(file.path);
    } catch (e) {
      print('Error generating PDF: $e');
    }
  }

  static pw.Widget _buildPDFRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.Text(
            '$label: ',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(value),
        ],
      ),
    );
  }

  static pw.Widget _buildPDFAmountRow(String label, dynamic amount, {bool isBold = false}) {
    final style = isBold ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : const pw.TextStyle();
    final value = amount != null ? 
        (amount is num ? amount : double.tryParse(amount.toString()) ?? 0.0) : 
        0.0;

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text(
            'Rs. ${NumberFormat('#,##,###.##').format(value)}',
            style: style,
          ),
        ],
      ),
    );
  }
} 