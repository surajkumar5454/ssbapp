import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/deputation_opening.dart';
import '../../models/deputation_application.dart';
import '../../services/deputation_service.dart';
import '../../services/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

class DeputationDetailsScreen extends StatelessWidget {
  final DeputationOpening opening;

  const DeputationDetailsScreen({super.key, required this.opening});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deputation Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildDetailsCard(),
            const SizedBox(height: 16),
            _buildRequirementsCard(),
            const SizedBox(height: 16),
            _buildDescriptionCard(),
            const SizedBox(height: 24),
            _buildActionButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          opening.title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          opening.organization,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildDetailRow('Notification Number', opening.notificationNumber),
            _buildDetailRow(
              'Notification Date', 
              DateFormat('dd MMM yyyy').format(opening.notificationDate),
            ),
            _buildDetailRow(
              'Application Period',
              '${DateFormat('dd MMM yyyy').format(opening.startDate)} - '
              '${DateFormat('dd MMM yyyy').format(opening.endDate)}',
            ),
            _buildDetailRow('Status', opening.status.label),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirementsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Requirements',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (opening.requiredRank != null)
              _buildDetailRow('Required Rank', opening.requiredRank!),
            if (opening.requiredExperience != null)
              _buildDetailRow(
                'Required Experience',
                '${opening.requiredExperience} years',
              ),
            if (opening.otherCriteria != null)
              _buildDetailRow('Other Criteria', opening.otherCriteria!),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(opening.description),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
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

  Widget _buildActionButton(BuildContext context) {
    if (opening.status != DeputationStatus.active) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: () => _showApplicationDialog(context),
        child: const Text('Apply Now'),
      ),
    );
  }

  void _showApplicationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Application'),
        content: const Text(
          'Are you sure you want to apply for this deputation position?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _submitApplication(context),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitApplication(BuildContext context) async {
    final authService = context.read<AuthService>();
    final application = DeputationApplication(
      openingId: opening.id!,
      applicantUin: authService.uin!,
      appliedDate: DateTime.now(),
    );

    final success = await context
        .read<DeputationService>()
        .applyForOpening(application);

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application submitted successfully')),
      );
      Navigator.pop(context); // Close dialog
      Navigator.pop(context); // Go back to listings
    }
  }
} 