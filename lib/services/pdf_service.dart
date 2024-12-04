import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/pay_slip.dart';
import '../models/training.dart';

class PdfService {
  Future<File> generatePaySlip(PaySlip paySlip) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Header(
              level: 0,
              child: pw.Text('Pay Slip', style: pw.TextStyle(fontSize: 24)),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Month: ${paySlip.month} ${paySlip.year}'),
            pw.SizedBox(height: 20),
            _buildPaySlipDetails(paySlip),
          ],
        ),
      ),
    );

    return _saveDocument('payslip_${paySlip.month}_${paySlip.year}.pdf', pdf);
  }

  Future<File> generateTrainingCertificate(Training training) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Header(
              level: 0,
              child: pw.Text('Certificate of Completion',
                  style: pw.TextStyle(fontSize: 24)),
            ),
            pw.SizedBox(height: 40),
            pw.Text('This is to certify that'),
            pw.SizedBox(height: 20),
            pw.Text('[Employee Name]',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            pw.Text('has successfully completed'),
            pw.SizedBox(height: 20),
            pw.Text(training.name,
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            pw.Text(
                'from ${_formatDate(training.startDate)} to ${_formatDate(training.endDate)}'),
            pw.SizedBox(height: 40),
            _buildTrainingTopics(training),
          ],
        ),
      ),
    );

    return _saveDocument('certificate_${training.id}.pdf', pdf);
  }

  pw.Widget _buildPaySlipDetails(PaySlip paySlip) {
    return pw.Column(
      children: [
        _buildPaySlipRow('Basic Pay', paySlip.basicPay),
        _buildPaySlipRow('Allowances', paySlip.allowances),
        _buildPaySlipRow('Deductions', paySlip.deductions),
        pw.Divider(),
        _buildPaySlipRow('Net Pay', paySlip.netPay, isBold: true),
      ],
    );
  }

  pw.Widget _buildPaySlipRow(String label, double amount,
      {bool isBold = false}) {
    final style =
        isBold ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : const pw.TextStyle();

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text('₹${amount.toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }

  pw.Widget _buildTrainingTopics(Training training) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Topics Covered:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        ...training.topics.map((topic) => pw.Text('• $topic')),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<File> _saveDocument(String fileName, pw.Document pdf) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
} 