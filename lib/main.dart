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
import 'screens/home/home_screen.dart';
import 'screens/leave/leave_credit_screen.dart';
import 'services/leave_credit_service.dart';

class CustomPageRoute<T> extends MaterialPageRoute<T> {
  CustomPageRoute({
    required WidgetBuilder builder,
    RouteSettings? settings,
  }) : super(builder: builder, settings: settings);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Fade and slide transition
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.0, 0.1),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ),
      ),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }
}

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
        ChangeNotifierProvider(
          create: (context) => LeaveCreditService(DatabaseHelper.instance),
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
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeService.themeMode,
          initialRoute: '/',
          onGenerateRoute: (settings) {
            Widget page;
            switch (settings.name) {
              case '/':
                page = const HomeScreen();
                break;
              case '/login':
                page = const LoginScreen();
                break;
              case '/dashboard':
                page = const DashboardScreen();
                break;
              case '/personal_details':
                page = const PersonalDetailsScreen();
                break;
              case '/service_details':
                page = const ServiceDetailsScreen();
                break;
              case '/pay_slips':
                page = const PaySlipsScreen();
                break;
              case '/trainings':
                page = const TrainingsScreen();
                break;
              case '/deputation':
                page = const DeputationScreen();
                break;
              case '/deputation_openings':
                page = const DeputationOpeningsScreen();
                break;
              case '/my_applications':
                page = const MyApplicationsScreen();
                break;
              case '/create_deputation':
                page = const CreateDeputationScreen();
                break;
              case '/settings':
                page = const SettingsScreen();
                break;
              case '/leave':
                page = const LeaveScreen();
                break;
              case '/family':
                page = const FamilyScreen();
                break;
              case '/grievances':
                page = const ViewGrievancesScreen();
                break;
              case '/submit_grievance':
                page = const SubmitGrievanceScreen();
                break;
              case '/grievance_history':
                page = const GrievanceHistoryScreen();
                break;
              case '/manage_admins':
                page = const ManageAdminsScreen();
                break;
              case '/leave_credits':
                page = const LeaveCreditScreen();
                break;
              default:
                page = const DashboardScreen();
            }

            return CustomPageRoute(
              builder: (_) => page,
              settings: settings,
            );
          },
        );
      },
    );
  }
}
