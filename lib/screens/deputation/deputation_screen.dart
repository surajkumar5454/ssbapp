import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/main_layout.dart';

class DeputationScreen extends StatelessWidget {
  const DeputationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.read<AuthService>().isDeputationAdmin;

    return MainLayout(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('e-DAS'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (isAdmin) ...[
              _buildAdminActions(context),
            ] else ...[
              _buildUserActions(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAdminActions(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.add_business),
            title: const Text('Create Opening'),
            onTap: () => Navigator.pushNamed(context, '/create_deputation'),
          ),
          ListTile(
            leading: const Icon(Icons.search),
            title: const Text('View All Openings'),
            onTap: () => Navigator.pushNamed(context, '/deputation_openings'),
          ),
          ListTile(
            leading: const Icon(Icons.admin_panel_settings),
            title: const Text('Manage Admins'),
            onTap: () => Navigator.pushNamed(context, '/manage_admins'),
          ),
        ],
      ),
    );
  }

  Widget _buildUserActions(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.search),
            title: const Text('View Openings'),
            onTap: () => Navigator.pushNamed(context, '/deputation_openings'),
          ),
          ListTile(
            leading: const Icon(Icons.folder_shared),
            title: const Text('My Applications'),
            onTap: () => Navigator.pushNamed(context, '/my_applications'),
          ),
        ],
      ),
    );
  }
} 