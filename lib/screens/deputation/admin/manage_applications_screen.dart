import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/deputation_application.dart';
import '../../../models/deputation_opening.dart';
import '../../../services/deputation_service.dart';
import 'package:intl/intl.dart';

class ManageApplicationsScreen extends StatefulWidget {
  const ManageApplicationsScreen({super.key});

  @override
  State<ManageApplicationsScreen> createState() => _ManageApplicationsScreenState();
}

class _ManageApplicationsScreenState extends State<ManageApplicationsScreen> {
  DeputationOpening? _selectedOpening;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final service = context.read<DeputationService>();
    await service.loadActiveOpenings();
    if (service.activeOpenings.isNotEmpty) {
      setState(() {
        _selectedOpening = service.activeOpenings.first;
      });
      await service.loadApplicationsForOpening(_selectedOpening!.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Applications'),
      ),
      body: Column(
        children: [
          _buildOpeningSelector(),
          Expanded(
            child: _buildApplicationsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOpeningSelector() {
    return Consumer<DeputationService>(
      builder: (context, service, _) {
        if (service.activeOpenings.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No active openings found'),
          );
        }

        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Opening',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<DeputationOpening>(
                  value: _selectedOpening,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  items: service.activeOpenings.map((opening) {
                    return DropdownMenuItem(
                      value: opening,
                      child: Text(
                        '${opening.title} - ${opening.organization}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (opening) {
                    setState(() => _selectedOpening = opening);
                    if (opening != null) {
                      service.loadApplicationsForOpening(opening.id!);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildApplicationsList() {
    return Consumer<DeputationService>(
      builder: (context, service, _) {
        if (service.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_selectedOpening == null) {
          return const Center(child: Text('Please select an opening'));
        }

        final applications = service.openingApplications;
        if (applications.isEmpty) {
          return const Center(child: Text('No applications found'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: applications.length,
          itemBuilder: (context, index) {
            return _buildApplicationCard(applications[index]);
          },
        );
      },
    );
  }

  Widget _buildApplicationCard(DeputationApplication application) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        application.applicantName ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (application.applicantRank != null)
                        Text(
                          '${application.applicantRank} • ${application.applicantUnit ?? 'N/A'}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
                _buildStatusChip(application.status),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Applied on', DateFormat('dd MMM yyyy').format(application.appliedDate)),
            if (application.experience != null)
              _buildInfoRow('Experience', '${application.experience} years'),
            if (application.remarks != null) ...[
              const SizedBox(height: 8),
              Text(
                'Remarks:',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(application.remarks!),
            ],
            if (application.status == ApplicationStatus.pending)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _showRejectDialog(application),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Reject'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _showApproveDialog(application),
                    child: const Text('Approve'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(ApplicationStatus status) {
    // Same as in MyApplicationsScreen
    // ... (reuse the code)
  }

  Widget _buildInfoRow(String label, String value) {
    // Same as in MyApplicationsScreen
    // ... (reuse the code)
  }

  Future<void> _showApproveDialog(DeputationApplication application) async {
    final remarksController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Application'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to approve this application?'),
            const SizedBox(height: 16),
            TextField(
              controller: remarksController,
              decoration: const InputDecoration(
                labelText: 'Remarks (Optional)',
                border: OutlineInputBorder(),
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
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final success = await context.read<DeputationService>().approveApplication(
        application.id!,
        remarks: remarksController.text,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application approved successfully')),
        );
      }
    }
  }

  Future<void> _showRejectDialog(DeputationApplication application) async {
    final remarksController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Application'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to reject this application?'),
            const SizedBox(height: 16),
            TextField(
              controller: remarksController,
              decoration: const InputDecoration(
                labelText: 'Reason for rejection*',
                border: OutlineInputBorder(),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (result == true && remarksController.text.isNotEmpty && mounted) {
      final success = await context.read<DeputationService>().rejectApplication(
        application.id!,
        remarksController.text,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application rejected')),
        );
      }
    }
  }
} 