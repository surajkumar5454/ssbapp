import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/deputation_application.dart';
import '../../services/deputation_service.dart';
import '../../services/auth_service.dart';
import 'package:intl/intl.dart';

class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    final authService = context.read<AuthService>();
    await context.read<DeputationService>().loadUserApplications(authService.uin!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Applications'),
      ),
      body: Consumer<DeputationService>(
        builder: (context, service, _) {
          if (service.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (service.userApplications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.folder_open_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No applications yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/deputation_openings'),
                    child: const Text('Browse Openings'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadApplications,
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: service.userApplications.length,
              itemBuilder: (context, index) {
                return _buildApplicationCard(service.userApplications[index]);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildApplicationCard(DeputationApplication application) {
    return Card(
      child: ListTile(
        title: Text(application.opening.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(application.opening.organization),
            Text('Notification: ${application.opening.notificationNumber}'),
            Text(
              'Applied on: ${DateFormat('dd MMM yyyy').format(application.appliedDate)}',
            ),
          ],
        ),
        // ... rest of the code
      ),
    );
  }

  Widget _buildStatusChip(ApplicationStatus status) {
    Color color;
    switch (status) {
      case ApplicationStatus.pending:
        color = Colors.orange;
        break;
      case ApplicationStatus.approved:
        color = Colors.green;
        break;
      case ApplicationStatus.rejected:
        color = Colors.red;
        break;
      case ApplicationStatus.withdrawn:
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 