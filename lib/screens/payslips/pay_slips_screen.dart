import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_helper.dart';
import 'package:intl/intl.dart';
import '../../services/pdf_service.dart';
import '../../widgets/main_layout.dart';

class PaySlipsScreen extends StatefulWidget {
  const PaySlipsScreen({super.key});

  @override
  State<PaySlipsScreen> createState() => _PaySlipsScreenState();
}

class _PaySlipsScreenState extends State<PaySlipsScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _payslips = [];

  @override
  void initState() {
    super.initState();
    _loadPayslips();
  }

  Future<void> _loadPayslips() async {
    setState(() => _isLoading = true);
    try {
      final uidno = context.read<AuthService>().uin;
      print('Current auth state:');
      print('UIN: $uidno');
      print('Is authenticated: ${context.read<AuthService>().isAuthenticated}');
      
      if (uidno != null) {
        final payslips = await DatabaseHelper.instance.getUserPayslips(uidno);
        print('Payslips returned from DB: ${payslips.length}');
        print('First payslip (if any): ${payslips.isNotEmpty ? payslips.first : 'none'}');
        setState(() => _payslips = payslips);
      } else {
        print('No UIN available - user not logged in?');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to view your pay slips')),
        );
      }
    } catch (e, stackTrace) {
      print('Error in _loadPayslips: $e');
      print('Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading payslips: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showPayslipDetails(Map<String, dynamic> payslip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, controller) => PayslipDetailsSheet(
          payslip: payslip,
          scrollController: controller,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Scaffold(
      appBar: AppBar(
        title: const Text('Pay Slips'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPayslips,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _payslips.isEmpty
              ? const Center(child: Text('No pay slips found'))
              : ListView.builder(
                  itemCount: _payslips.length,
                  itemBuilder: (context, index) {
                    final payslip = _payslips[index];
                    return PayslipCard(
                      payslip: payslip,
                      onTap: () => _showPayslipDetails(payslip),
                    );
                  },
                ),
    );

    return MainLayout(child: content);
  }
}

class PayslipCard extends StatelessWidget {
  final Map<String, dynamic> payslip;
  final VoidCallback onTap;

  const PayslipCard({
    super.key,
    required this.payslip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    print('Full Payslip Data: ${payslip.toString()}');
    print('Keys in payslip: ${payslip.keys.toList()}');
    print('NETPAY value: ${payslip['NETPAY']}');
    
    final monthName = payslip['MonthFullName'];
    final year = payslip['Year_Main'];
    final netPay = payslip['NETPAY'];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text('$monthName $year'),
        subtitle: Text(
          'Net Pay: ₹${NumberFormat('#,##,###.##').format(netPay ?? 0)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class PayslipDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> payslip;
  final ScrollController scrollController;

  const PayslipDetailsSheet({
    super.key,
    required this.payslip,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: () async {
                  try {
                    await PDFService.generatePayslipPDF(payslip);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error generating PDF: $e')),
                      );
                    }
                  }
                },
                tooltip: 'Download PDF',
              ),
            ],
          ),
          Expanded(
            child: ListView(
              controller: scrollController,
              children: [
                _buildHeader(context),
                const Divider(height: 32),
                _buildEarningsSection(context),
                const SizedBox(height: 16),
                _buildDeductionsSection(context),
                const SizedBox(height: 16),
                _buildNetPaySection(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pay Slip - ${payslip['MonthFullName']} ${payslip['Year_Main']}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Employee: ${payslip['EmpName']}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text('Rank: ${payslip['RankShortName']}'),
        Text('PER No: ${payslip['PERNo']}'),
        Text('Unit: ${payslip['UnitName']}'),
      ],
    );
  }

  Widget _buildEarningsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Earnings',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.green,
              ),
        ),
        const SizedBox(height: 8),
        _buildPayItem('Basic Pay', payslip['Basic_Pay']),
        _buildPayItem('Grade Pay', payslip['Grade_Pay']),
        _buildPayItem('DA', payslip['DA']),
        _buildPayItem('HRA', payslip['HRA']),
        _buildPayItem('Transport Allowance', payslip['TPT']),
        // Add other earnings...
        const Divider(),
        _buildPayItem('Gross Salary', payslip['GROSS'], isBold: true),
      ],
    );
  }

  Widget _buildDeductionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Deductions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.red,
              ),
        ),
        const SizedBox(height: 8),
        _buildPayItem('GPF/NPS', payslip['GPF_NPS_sub']),
        _buildPayItem('Income Tax', payslip['Income_tax']),
        _buildPayItem('CGHS', payslip['CGHS']),
        // Add other deductions...
        const Divider(),
        _buildPayItem('Total Deductions', payslip['DEDUCTION'], isBold: true),
      ],
    );
  }

  Widget _buildNetPaySection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            'Net Pay',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '₹${NumberFormat('#,##,###.##').format(payslip['NETPAY'] ?? 0)}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayItem(String label, dynamic amount, {bool isBold = false}) {
    // Handle null or invalid amount
    final double numericAmount = amount != null ? 
        (amount is double ? amount : double.tryParse(amount.toString()) ?? 0.0) : 
        0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
            '₹${NumberFormat('#,##,###.##').format(numericAmount)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
} 