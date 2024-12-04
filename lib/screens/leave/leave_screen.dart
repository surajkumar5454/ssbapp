import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../widgets/main_layout.dart';
import '../../services/leave_service.dart';
import '../../services/auth_service.dart';
import '../../models/leave_application.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLeaveHistory();
    });
  }

  Future<void> _loadLeaveHistory() async {
    final leaveService = context.read<LeaveService>();
    final authService = context.read<AuthService>();
    await leaveService.loadLeaveHistory(authService.uin!);
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Leave Management'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showApplyLeaveDialog(context),
            ),
          ],
        ),
        body: Consumer<LeaveService>(
          builder: (context, leaveService, _) {
            if (leaveService.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (leaveService.error != null) {
              return Center(child: Text(leaveService.error!));
            }

            final leaves = leaveService.leaveApplications;
            if (leaves.isEmpty) {
              return const Center(child: Text('No leave history found'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: leaves.length,
              itemBuilder: (context, index) {
                final leave = leaves[index];
                return _buildLeaveCard(leave);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildLeaveCard(LeaveApplication leave) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  leave.leaveType,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                _buildStatusChip(leave.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'From: ${DateFormat('dd MMM yyyy').format(leave.startDate)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              'To: ${DateFormat('dd MMM yyyy').format(leave.endDate)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (leave.reason.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Reason: ${leave.reason}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (leave.status == 'Pending') ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _cancelLeave(leave.id!),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'approved':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      case 'cancelled':
        color = Colors.grey;
        break;
      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status,
        style: TextStyle(color: color),
      ),
    );
  }

  Future<void> _showApplyLeaveDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    String leaveType = 'Casual Leave';
    DateTime? startDate;
    DateTime? endDate;
    final reasonController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apply Leave'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: leaveType,
                  decoration: const InputDecoration(labelText: 'Leave Type'),
                  items: ['Casual Leave', 'Sick Leave', 'Earned Leave']
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                  onChanged: (value) => leaveType = value!,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Start Date',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      startDate = date;
                    }
                  },
                  validator: (value) =>
                      startDate == null ? 'Please select start date' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'End Date',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: startDate ?? DateTime.now(),
                      firstDate: startDate ?? DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      endDate = date;
                    }
                  },
                  validator: (value) =>
                      endDate == null ? 'Please select end date' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Reason',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Please enter reason' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final authService = context.read<AuthService>();
                final leave = LeaveApplication(
                  uidno: authService.uin!,
                  leaveType: leaveType,
                  startDate: startDate!,
                  endDate: endDate!,
                  reason: reasonController.text,
                  status: 'Pending',
                  appliedDate: DateTime.now(),
                );
                await context.read<LeaveService>().applyLeave(leave);
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelLeave(int leaveId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Leave'),
        content: const Text('Are you sure you want to cancel this leave?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await context.read<LeaveService>().cancelLeave(leaveId);
    }
  }
} 