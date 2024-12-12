import 'package:flutter/material.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/payslips/pay_slips_screen.dart';
import '../screens/service/service_details_screen.dart';
import '../screens/trainings/trainings_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../main.dart'; // Import for CustomPageRoute

class MainLayout extends StatefulWidget {
  final Widget child;
  
  const MainLayout({super.key, required this.child});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  final List<NavigationDestination> _destinations = const [
    NavigationDestination(
      icon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    NavigationDestination(
      icon: Icon(Icons.receipt_long),
      label: 'Pay Slips',
    ),
    NavigationDestination(
      icon: Icon(Icons.transfer_within_a_station),
      label: 'Postings',
    ),
    NavigationDestination(
      icon: Icon(Icons.school),
      label: 'Trainings',
    ),
    NavigationDestination(
      icon: Icon(Icons.settings),
      label: 'Settings',
    ),
  ];

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    final route = switch (index) {
      0 => '/dashboard',
      1 => '/pay_slips',
      2 => '/service_details',
      3 => '/trainings',
      4 => '/settings',
      _ => '/dashboard',
    };

    Navigator.pushReplacement(
      context,
      CustomPageRoute(
        builder: (_) => _buildPage(route),
        settings: RouteSettings(name: route),
      ),
    );
  }

  Widget _buildPage(String route) {
    return switch (route) {
      '/dashboard' => const DashboardScreen(),
      '/pay_slips' => const PaySlipsScreen(),
      '/service_details' => const ServiceDetailsScreen(),
      '/trainings' => const TrainingsScreen(),
      '/settings' => const SettingsScreen(),
      _ => const DashboardScreen(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        destinations: _destinations,
        onDestinationSelected: _onDestinationSelected,
      ),
    );
  }
} 