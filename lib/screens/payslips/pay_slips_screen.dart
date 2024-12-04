import 'package:flutter/material.dart';
import '../../widgets/main_layout.dart';
import '../../models/pay_slip.dart';

class PaySlipsScreen extends StatefulWidget {
  const PaySlipsScreen({super.key});

  @override
  State<PaySlipsScreen> createState() => _PaySlipsScreenState();
}

class _PaySlipsScreenState extends State<PaySlipsScreen> {
  bool _isLoading = false;
  List<PaySlip> _paySlips = [];

  @override
  void initState() {
    super.initState();
    _loadPaySlips();
  }

  Future<void> _loadPaySlips() async {
    setState(() => _isLoading = true);
    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(seconds: 1));
      _paySlips = [
        PaySlip(
          id: '1',
          month: 'March',
          year: '2024',
          basicPay: 50000,
          allowances: 10000,
          deductions: 5000,
          netPay: 55000,
        ),
        PaySlip(
          id: '2',
          month: 'February',
          year: '2024',
          basicPay: 50000,
          allowances: 10000,
          deductions: 5000,
          netPay: 55000,
        ),
      ];
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading pay slips: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pay Slips'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadPaySlips,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _paySlips.length,
                itemBuilder: (context, index) {
                  final paySlip = _paySlips[index];
                  return Card(
                    child: ListTile(
                      title: Text('${paySlip.month} ${paySlip.year}'),
                      subtitle: Text(
                        'Net Pay: ₹${paySlip.netPay.toStringAsFixed(2)}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.visibility),
                            onPressed: () => _viewPaySlip(paySlip),
                          ),
                          IconButton(
                            icon: const Icon(Icons.download),
                            onPressed: () => _downloadPaySlip(paySlip),
                          ),
                        ],
                      ),
                      onTap: () => _viewPaySlip(paySlip),
                    ),
                  );
                },
              ),
      ),
    );
  }

  void _viewPaySlip(PaySlip paySlip) {
    showModalBottomSheet(
      context: context,
      builder: (context) => PaySlipDetailSheet(paySlip: paySlip),
    );
  }

  Future<void> _downloadPaySlip(PaySlip paySlip) async {
    // TODO: Implement PDF generation and download
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Downloading pay slip...')),
    );
  }
}

class PaySlipDetailSheet extends StatelessWidget {
  final PaySlip paySlip;

  const PaySlipDetailSheet({super.key, required this.paySlip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${paySlip.month} ${paySlip.year} Pay Slip',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _buildPaySlipRow('Basic Pay', paySlip.basicPay),
          _buildPaySlipRow('Allowances', paySlip.allowances),
          _buildPaySlipRow('Deductions', paySlip.deductions),
          const Divider(),
          _buildPaySlipRow('Net Pay', paySlip.netPay, isBold: true),
        ],
      ),
    );
  }

  Widget _buildPaySlipRow(String label, double amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
} 