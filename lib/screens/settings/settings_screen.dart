import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/main_layout.dart';
import '../../services/auth_service.dart';
import '../../services/theme_service.dart';
import '../../services/profile_service.dart';
import '../../services/posting_service.dart';
import '../../services/training_service.dart';
import '../../services/family_service.dart';
import '../../services/grievance_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                title: const Text('Theme'),
                trailing: Consumer<ThemeService>(
                  builder: (context, themeService, _) {
                    return Switch(
                      value: themeService.isDarkMode,
                      onChanged: (value) {
                        themeService.toggleTheme();
                      },
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () async {
                  // Clear all service data
                  context.read<ProfileService>().clearData();
                  context.read<PostingService>().clearData();
                  context.read<TrainingService>().clearData();
                  context.read<FamilyService>().clearData();
                  context.read<GrievanceService>().clearData();
                  
                  // Logout
                  await context.read<AuthService>().logout();
                  
                  // Navigate to login screen
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/',
                    (route) => false,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} 