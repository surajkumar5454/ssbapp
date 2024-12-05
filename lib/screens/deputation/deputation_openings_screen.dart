import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/deputation_service.dart';
import '../../services/auth_service.dart';
import '../../models/deputation_opening.dart';
import '../../models/deputation_application.dart';
import '../../widgets/main_layout.dart';

class DeputationOpeningsScreen extends StatefulWidget {
  const DeputationOpeningsScreen({super.key});

  @override
  State<DeputationOpeningsScreen> createState() => _DeputationOpeningsScreenState();
}

class _DeputationOpeningsScreenState extends State<DeputationOpeningsScreen> {
  final _searchController = TextEditingController();
  String? _selectedLocation;
  String? _selectedOrganization;
  
  @override
  Widget build(BuildContext context) {
    return MainLayout(
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Deputation Openings'),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'All Openings'),
                Tab(text: 'Eligible For Me'),
              ],
            ),
          ),
          body: Column(
            children: [
              _buildSearchBar(),
              _buildFilters(),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildOpeningsList(isEligibleOnly: false),
                    _buildOpeningsList(isEligibleOnly: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search openings...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildFilterChip(
            label: 'Location',
            value: _selectedLocation,
            onSelected: (value) => setState(() => _selectedLocation = value),
            options: const ['Delhi', 'Mumbai', 'Bangalore', 'Chennai'],
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Organization',
            value: _selectedOrganization,
            onSelected: (value) => setState(() => _selectedOrganization = value),
            options: const ['Ministry', 'Department', 'PSU', 'Other'],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String? value,
    required Function(String?) onSelected,
    required List<String> options,
  }) {
    return PopupMenuButton<String>(
      child: Chip(
        label: Text(value ?? label),
        deleteIcon: value != null ? const Icon(Icons.close, size: 18) : null,
        onDeleted: value != null ? () => onSelected(null) : null,
      ),
      itemBuilder: (context) => [
        if (value != null)
          const PopupMenuItem(
            value: null,
            child: Text('Clear'),
          ),
        ...options.map((option) => PopupMenuItem(
          value: option,
          child: Text(option),
        )),
      ],
      onSelected: onSelected,
    );
  }

  void _onSearchChanged(String query) {
    final deputationService = context.read<DeputationService>();
    deputationService.loadActiveOpenings();
  }

  Widget _buildOpeningsList({required bool isEligibleOnly}) {
    return Consumer<DeputationService>(
      builder: (context, service, _) {
        final openings = isEligibleOnly 
            ? service.eligibleOpenings 
            : service.activeOpenings;

        if (service.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (openings.isEmpty) {
          return const Center(
            child: Text('No openings found'),
          );
        }

        return ListView.builder(
          itemCount: openings.length,
          itemBuilder: (context, index) => _buildOpeningCard(openings[index]),
        );
      },
    );
  }

  Widget _buildOpeningCard(DeputationOpening opening) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              opening.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              opening.organization,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  opening.notificationNumber,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => _showApplicationDialog(opening),
                  child: const Text('Apply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showApplicationDialog(DeputationOpening opening) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apply for Deputation'),
        content: Text(
          'Are you sure you want to apply for "${opening.title}" at ${opening.organization}?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Apply'),
          ),
        ],
      ),
    );

    if (result == true) {
      final authService = context.read<AuthService>();
      final application = {
        'opening_id': opening.id!,
        'applicant_uin': authService.uin!,
        'applied_date': DateTime.now().toIso8601String(),
      };

      final success = await context
          .read<DeputationService>()
          .applyForOpening(application);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application submitted successfully')),
        );
      }
    }
  }
} 