import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/grievance.dart';
import '../../services/grievance_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/main_layout.dart';
import 'package:intl/intl.dart';
import '../../models/grievance_status.dart';

class GrievanceHistoryScreen extends StatefulWidget {
  const GrievanceHistoryScreen({super.key});

  @override
  State<GrievanceHistoryScreen> createState() => _GrievanceHistoryScreenState();
}

class _GrievanceHistoryScreenState extends State<GrievanceHistoryScreen> {
  @override
  void initState() {
    super.initState();
    _loadGrievances();
  }

  Future<void> _loadGrievances() async {
    final authService = context.read<AuthService>();
    await context.read<GrievanceService>().loadGrievances(authService.uin!);
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Grievances'),
        ),
        body: Consumer<GrievanceService>(
          builder: (context, service, _) {
            if (service.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final grievances = service.submittedGrievances;
            if (grievances.isEmpty) {
              return const Center(child: Text('No grievances submitted'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: grievances.length,
              itemBuilder: (context, index) {
                final grievance = grievances[index];
                return Card(
                  child: ExpansionTile(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (grievance.grievanceId != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'ID: ${grievance.grievanceId}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          grievance.subject,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      'Status: ${grievance.status.label} • ${DateFormat('dd MMM yyyy').format(grievance.submittedDate)}',
                      style: TextStyle(
                        color: _getStatusColor(grievance.status),
                      ),
                    ),
                    trailing: CircleAvatar(
                      backgroundColor: _getPriorityColor(grievance.priority),
                      radius: 12,
                      child: Text(
                        grievance.priority[0],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Currently with:',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            ListTile(
                              leading: const Icon(Icons.person_outline),
                              title: Text(grievance.handlerName ?? 'N/A'),
                              subtitle: Text(
                                '${grievance.handlerRank ?? 'N/A'} • ${grievance.handlerUnit ?? 'N/A'}',
                              ),
                            ),
                            const Divider(),
                            Text(
                              'Details:',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            Text('Category: ${grievance.category}'),
                            Text('Days Elapsed: ${grievance.daysElapsed}'),
                            if (grievance.remarks?.isNotEmpty ?? false) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Remarks:',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(grievance.remarks!),
                            ],
                            const SizedBox(height: 8),
                            _buildGrievanceActions(grievance),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Color _getStatusColor(GrievanceStatus status) {
    switch (status) {
      case GrievanceStatus.resolved:
      case GrievanceStatus.selfResolved:
        return Colors.green;
      case GrievanceStatus.pending:
        return Colors.orange;
      case GrievanceStatus.inProgress:
        return Colors.blue;
      case GrievanceStatus.returned:
        return Colors.amber;
      case GrievanceStatus.closed:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'normal':
        return Colors.blue;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildGrievanceActions(Grievance grievance) {
    if (grievance.status != GrievanceStatus.pending && 
        grievance.status != GrievanceStatus.inProgress) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton.icon(
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Mark as Resolved'),
            onPressed: () => _showResolveDialog(grievance),
          ),
        ],
      ),
    );
  }

  Future<void> _showResolveDialog(Grievance grievance) async {
    final remarksController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resolve Grievance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to mark this grievance as resolved?',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: remarksController,
              decoration: const InputDecoration(
                labelText: 'Resolution Remarks',
                border: OutlineInputBorder(),
                hintText: 'Please provide reason for resolution',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Resolve'),
          ),
        ],
      ),
    );

    if (result == true && remarksController.text.isNotEmpty) {
      final success = await context
          .read<GrievanceService>()
          .resolveOwnGrievance(grievance, remarksController.text);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Grievance marked as resolved')),
        );
      }
    }
  }
} 