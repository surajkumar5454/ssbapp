import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/main_layout.dart';
import '../../models/deputation.dart';

class DeputationScreen extends StatefulWidget {
  const DeputationScreen({super.key});

  @override
  State<DeputationScreen> createState() => _DeputationScreenState();
}

class _DeputationScreenState extends State<DeputationScreen> {
  bool _isLoading = false;
  List<Deputation> _deputations = [];
  final _dateFormat = DateFormat('MMM dd, yyyy');

  @override
  void initState() {
    super.initState();
    _loadDeputations();
  }

  Future<void> _loadDeputations() async {
    setState(() => _isLoading = true);
    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(seconds: 1));
      _deputations = [
        Deputation(
          id: '1',
          targetOrganization: 'Tech Solutions Ltd',
          position: 'Senior Developer',
          reason: 'Project collaboration and knowledge sharing',
          requestDate: DateTime(2024, 1, 15),
          status: 'Pending',
        ),
        Deputation(
          id: '2',
          targetOrganization: 'Digital Innovations Inc',
          position: 'Technical Lead',
          reason: 'Leading cross-functional team for new project',
          requestDate: DateTime(2024, 2, 1),
          status: 'Approved',
          remarks: 'Approved for 6 months duration',
        ),
      ];
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading deputations: $e')),
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
          title: const Text('Deputation Requests'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadDeputations,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _deputations.length,
                itemBuilder: (context, index) {
                  final deputation = _deputations[index];
                  return Card(
                    child: ExpansionTile(
                      title: Text(deputation.targetOrganization),
                      subtitle: Text(
                        '${deputation.position} - ${_dateFormat.format(deputation.requestDate)}',
                      ),
                      trailing: _buildStatusChip(deputation.status),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow('Reason', deputation.reason),
                              if (deputation.remarks.isNotEmpty)
                                _buildInfoRow('Remarks', deputation.remarks),
                              const SizedBox(height: 8),
                              if (deputation.status == 'Pending')
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () => _withdrawRequest(deputation),
                                      child: const Text('Withdraw Request'),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showDeputationRequestDialog(),
          child: const Icon(Icons.add),
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
      case 'pending':
        color = Colors.orange;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(
        status,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: color,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }

  Future<void> _withdrawRequest(Deputation deputation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw Request'),
        content: const Text('Are you sure you want to withdraw this request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // TODO: Implement withdrawal logic
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request withdrawn successfully')),
      );
      _loadDeputations();
    }
  }

  void _showDeputationRequestDialog() {
    showDialog(
      context: context,
      builder: (context) => const DeputationRequestDialog(),
    );
  }
}

class DeputationRequestDialog extends StatefulWidget {
  const DeputationRequestDialog({super.key});

  @override
  State<DeputationRequestDialog> createState() => _DeputationRequestDialogState();
}

class _DeputationRequestDialogState extends State<DeputationRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _organizationController = TextEditingController();
  final _positionController = TextEditingController();
  final _reasonController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Deputation Request'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _organizationController,
                decoration: const InputDecoration(
                  labelText: 'Target Organization',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter organization name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _positionController,
                decoration: const InputDecoration(
                  labelText: 'Position',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter position';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason for Deputation',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter reason';
                  }
                  return null;
                },
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
          onPressed: _submitRequest,
          child: const Text('Submit'),
        ),
      ],
    );
  }

  void _submitRequest() {
    if (_formKey.currentState!.validate()) {
      // TODO: Implement request submission
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deputation request submitted')),
      );
    }
  }

  @override
  void dispose() {
    _organizationController.dispose();
    _positionController.dispose();
    _reasonController.dispose();
    super.dispose();
  }
} 