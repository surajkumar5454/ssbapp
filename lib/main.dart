import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/personal/personal_details_screen.dart';
import 'screens/service/service_details_screen.dart';
import 'screens/payslips/pay_slips_screen.dart';
import 'screens/trainings/trainings_screen.dart';
import 'screens/deputation/deputation_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/leave/leave_screen.dart';
import 'screens/family/family_screen.dart';
import 'screens/grievance/view_grievances_screen.dart';
import 'screens/grievance/submit_grievance_screen.dart';
import 'screens/grievance/grievance_history_screen.dart';
import 'screens/deputation/deputation_openings_screen.dart';
import 'screens/deputation/my_applications_screen.dart';
import 'screens/deputation/create_deputation_screen.dart';
import 'screens/deputation/admin/manage_admins_screen.dart';
import 'services/auth_service.dart';
import 'services/theme_service.dart';
import 'services/api_service.dart';
import 'services/profile_service.dart';
import 'theme/app_theme.dart';
import 'services/database_helper.dart';
import 'services/posting_service.dart';
import 'services/training_service.dart';
import 'services/document_service.dart';
import 'services/leave_service.dart';
import 'services/family_service.dart';
import 'services/grievance_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/deputation_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  final authService = AuthService(prefs);
  await authService.checkAuthState();

  final dbHelper = DatabaseHelper.instance;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider(create: (_) => ThemeService()),
        Provider<DatabaseHelper>(
          create: (_) => DatabaseHelper.instance,
          dispose: (_, db) => db.clearCache(),
        ),
        ChangeNotifierProvider(
          create: (context) => ProfileService(dbHelper),
        ),
        ChangeNotifierProvider(
          create: (context) => PostingService(dbHelper),
        ),
        ChangeNotifierProvider(
          create: (context) => TrainingService(dbHelper),
        ),
        ChangeNotifierProvider(
          create: (context) => DocumentService(dbHelper),
        ),
        ChangeNotifierProvider(
          create: (context) => LeaveService(dbHelper),
        ),
        ChangeNotifierProvider(
          create: (context) => FamilyService(dbHelper),
        ),
        ChangeNotifierProvider(
          create: (context) => GrievanceService(dbHelper),
        ),
        ChangeNotifierProvider(
          create: (context) => DeputationService(DatabaseHelper.instance),
        ),
      ],
      child: const EmployeeApp(),
    ),
  );
}

class EmployeeApp extends StatelessWidget {
  const EmployeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, _) {
        return MaterialApp(
          title: 'Employee Management',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeService.themeMode,
          home: Consumer<AuthService>(
            builder: (context, authService, _) {
              return authService.isAuthenticated
                  ? const DashboardScreen()
                  : const LoginScreen();
            },
          ),
          routes: {
            '/dashboard': (context) => const DashboardScreen(),
            '/personal_details': (context) => const PersonalDetailsScreen(),
            '/service_details': (context) => const ServiceDetailsScreen(),
            '/pay_slips': (context) => const PaySlipsScreen(),
            '/trainings': (context) => const TrainingsScreen(),
            '/deputation': (context) => const DeputationScreen(),
            '/deputation_openings': (context) => const DeputationOpeningsScreen(),
            '/my_applications': (context) => const MyApplicationsScreen(),
            '/create_deputation': (context) => const CreateDeputationScreen(),
            '/settings': (context) => const SettingsScreen(),
            '/leave': (context) => const LeaveScreen(),
            '/family': (context) => const FamilyScreen(),
            '/grievances': (context) => const ViewGrievancesScreen(),
            '/submit_grievance': (context) => const SubmitGrievanceScreen(),
            '/grievance_history': (context) => const GrievanceHistoryScreen(),
            '/manage_admins': (context) => const ManageAdminsScreen(),
          },
        );
      },
    );
  }
}
