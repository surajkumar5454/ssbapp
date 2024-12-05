import 'package:flutter/material.dart';
import '../../../services/database_helper.dart';
import '../../../widgets/main_layout.dart';
import 'package:intl/intl.dart';

class ManageAdminsScreen extends StatefulWidget {
  const ManageAdminsScreen({super.key});

  @override
  State<ManageAdminsScreen> createState() => _ManageAdminsScreenState();
}

class _ManageAdminsScreenState extends State<ManageAdminsScreen> {
  List<Map<String, dynamic>> _admins = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAdmins();
  }

  Future<void> _loadAdmins() async {
    setState(() => _isLoading = true);
    try {
      _admins = await DatabaseHelper.instance.getDeputationAdmins();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage e-DAS Admins'),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton.icon(
                      onPressed: _showAddAdminDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Admin'),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _admins.length,
                      itemBuilder: (context, index) {
                        final admin = _admins[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            title: Text(admin['name'] ?? 'Unknown'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('UIN: ${admin['uin']}'),
                                if (admin['rank_name'] != null)
                                  Text('Current Rank: ${admin['rank_name']}'),
                                if (admin['unit_name'] != null)
                                  Text('Current Unit: ${admin['unit_name']}'),
                                if (admin['posting_date'] != null)
                                  Text('Posted since: ${DateFormat('dd MMM yyyy').format(DateTime.parse(admin['posting_date']))}'),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _showRemoveDialog(admin),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _showAddAdminDialog() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Admin'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'UIN',
              hintText: 'Enter UIN of new admin',
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter a UIN';
              }
              if (_admins.any((a) => a['uin'] == value)) {
                return 'This UIN is already an admin';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() => _isLoading = true);
      try {
        final success = await DatabaseHelper.instance
            .addDeputationAdmin(controller.text);
        
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Admin added successfully')),
          );
          _loadAdmins();
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showRemoveDialog(Map<String, dynamic> admin) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Admin'),
        content: Text(
          'Are you sure you want to remove ${admin['name']} as admin?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() => _isLoading = true);
      try {
        final success = await DatabaseHelper.instance
            .removeDeputationAdmin(admin['uin']);
        
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Admin removed successfully')),
          );
          _loadAdmins();
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }
} 