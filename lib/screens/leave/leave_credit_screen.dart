import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/leave_credit_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/main_layout.dart';
import '../../models/leave_credit.dart';
import 'package:intl/intl.dart';

class LeaveCreditScreen extends StatefulWidget {
  const LeaveCreditScreen({super.key});

  @override
  State<LeaveCreditScreen> createState() => _LeaveCreditScreenState();
}

class _LeaveCreditScreenState extends State<LeaveCreditScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final uidno = context.read<AuthService>().uin;
    if (uidno != null) {
      await context.read<LeaveCreditService>().loadLeaveCreditHistory(uidno);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Leave Credits'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadData,
            ),
          ],
        ),
        body: Consumer<LeaveCreditService>(
          builder: (context, service, _) {
            if (service.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _buildCurrentBalance(service.currentBalance),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Leave Credit History',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildHistoryCard(service.history[index], index),
                    childCount: service.history.length,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCurrentBalance(Map<String, int> balance) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Leave Balance',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildBalanceItem(
                    'EL',
                    balance['el'] ?? 0,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildBalanceItem(
                    'HPL',
                    balance['hpl'] ?? 0,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildBalanceItem(
                    'CL',
                    balance['cl'] ?? 0,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceItem(String label, int value, Color color) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 800),
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      curve: Curves.easeOutCubic,
      builder: (context, double animatedValue, child) {
        return Column(
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                animatedValue.toInt().toString(),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHistoryCard(LeaveCredit credit, int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 100)), // Staggered animation
      curve: Curves.easeOutQuad,
      transform: Matrix4.translationValues(0, 0, 0)..translate(0.0, 0.0, 0.0),
      child: TweenAnimationBuilder(
        duration: const Duration(milliseconds: 500),
        tween: Tween<double>(begin: 0, end: 1),
        builder: (context, double value, child) {
          return Transform.translate(
            offset: Offset(0, 50 * (1 - value)),
            child: Opacity(
              opacity: value,
              child: child,
            ),
          );
        },
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent, // Removes the expansion tile divider
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              expandedAlignment: Alignment.topLeft,
              childrenPadding: EdgeInsets.zero,
              title: Text(
                '${DateFormat('dd MMM yyyy').format(credit.dateFrom)} - '
                '${DateFormat('dd MMM yyyy').format(credit.dateTo)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Text(
                credit.entryType ?? 'Regular Credit',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildLeaveRow('EL', credit.previousEl, credit.creditEl, 
                            credit.availEl, credit.balanceEl),
                        const Divider(),
                        _buildLeaveRow('HPL', credit.previousHpl, credit.creditHpl, 
                            credit.availHpl, credit.balanceHpl),
                        const Divider(),
                        _buildLeaveRow('CL', credit.previousCl, credit.creditCl, 
                            credit.availCl, credit.balanceCl),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeaveRow(String type, int previous, int credit, int availed, int balance) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(type),
        Row(
          children: [
            _buildLeaveDetail('Previous', previous, Colors.grey[600]),
            _buildLeaveDetail(
              'Credit', 
              credit, 
              Colors.green[700],
              isPositive: true,
            ),
            _buildLeaveDetail(
              'Availed', 
              availed, 
              Colors.red[700],
              isPositive: false,
            ),
            _buildLeaveDetail(
              'Balance', 
              balance, 
              balance > 0 ? Colors.blue[700] : Colors.orange[700],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLeaveDetail(String label, int value, Color? color, {bool? isPositive}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            isPositive == null 
                ? value.toString()
                : (isPositive ? '+$value' : '-$value'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
} 