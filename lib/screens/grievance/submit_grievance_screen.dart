import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/grievance_service.dart';
import '../../services/auth_service.dart';
import '../../models/grievance.dart';
import '../../models/grievance_status.dart';
import '../../widgets/main_layout.dart';

class SubmitGrievanceScreen extends StatefulWidget {
  const SubmitGrievanceScreen({super.key});

  @override
  State<SubmitGrievanceScreen> createState() => _SubmitGrievanceScreenState();
}

class _SubmitGrievanceScreenState extends State<SubmitGrievanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'Administrative';
  String _selectedPriority = 'Normal';

  final List<String> _categories = [
    'Administrative',
    'Technical',
    'Personal',
    'Other'
  ];

  final List<String> _priorities = [
    'Low',
    'Normal',
    'High',
    'Urgent'
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitGrievance() async {
    if (_formKey.currentState?.validate() ?? false) {
      final authService = context.read<AuthService>();
      final grievance = Grievance(
        fromUin: authService.uin!,
        toUin: '16020013',  // Fixed supervisor UIN
        subject: _subjectController.text,
        description: _descriptionController.text,
        category: _selectedCategory,
        priority: _selectedPriority,
        status: GrievanceStatus.pending,
        submittedDate: DateTime.now(),
      );

      final success = await context.read<GrievanceService>().submitGrievance(grievance);

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Grievance submitted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit grievance')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Submit Grievance'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _subjectController,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter a subject';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedPriority,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                  items: _priorities.map((priority) {
                    return DropdownMenuItem(
                      value: priority,
                      child: Text(priority),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPriority = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitGrievance,
                    child: const Text('Submit Grievance'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 