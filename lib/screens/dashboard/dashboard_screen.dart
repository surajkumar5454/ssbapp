import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';
import '../../widgets/main_layout.dart';
import '../../services/profile_service.dart';
import '../../services/posting_service.dart';
import '../../services/auth_service.dart';
import 'package:intl/intl.dart';
import '../../widgets/image_viewer_dialog.dart';
import '../../services/deputation_service.dart';
import '../profile/service_history_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final authService = context.read<AuthService>();
    final uin = authService.uin!;
    
    await Future.wait([
      context.read<ProfileService>().loadProfile(uin),
      context.read<PostingService>().loadPostings(uin),
      context.read<DeputationService>().loadEligibleOpenings(uin),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard'),
        ),
        body: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileCard(),
                  const SizedBox(height: 16),
                  _buildCurrentPostingCard(),
                  const SizedBox(height: 16),
                  _buildQuickActions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Consumer<ProfileService>(
      builder: (context, profileService, _) {
        final profile = profileService.profile;
        final profileImage = profileService.profileImage;
        
        if (profile == null) return const SizedBox.shrink();

        return Card(
          child: Column(
            children: [
              // Profile Header
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: profileImage != null 
                          ? () => _showEnlargedImage(context, profileImage)
                          : null,
                      child: CircleAvatar(
                        radius: 40,
                        backgroundImage: profileImage != null
                            ? MemoryImage(profileImage)
                            : null,
                        child: profileImage == null
                            ? const Icon(Icons.person, size: 40)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.name,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            profile.rankName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                          Text(
                            'UIN: ${profile.uidno}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Service Information
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildServiceInfoRow(
                      context,
                      icon: Icons.calendar_today,
                      title: 'Service Period',
                      value1: profile.dateOfJoining != null 
                          ? 'Joined: ${DateFormat('dd MMM yyyy').format(profile.dateOfJoining!)}'
                          : 'Join date not available',
                      value2: profile.dateOfRetirement != null
                          ? 'Retires: ${DateFormat('dd MMM yyyy').format(profile.dateOfRetirement!)}'
                          : 'Retirement date not available',
                    ),
                    const Divider(height: 24),
                    _buildServiceInfoRow(
                      context,
                      icon: Icons.access_time,
                      title: 'Service Duration',
                      value1: 'Completed: ${profile.lengthOfService}',
                      value2: 'Remaining: ${profile.remainingService}',
                      isHighlighted: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildServiceInfoRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value1,
    required String value2,
    bool isHighlighted = false,
  }) {
    final color = isHighlighted 
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurface;

    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value1,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                value2,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentPostingCard() {
    return Consumer<PostingService>(
      builder: (context, postingService, _) {
        final postings = postingService.postings;
        if (postings.isEmpty) return const SizedBox.shrink();

        final currentPosting = postings.first;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_city,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Current Posting',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildPostingInfo('Unit', currentPosting.unitName),
                _buildPostingInfo('Rank', currentPosting.rankName),
                _buildPostingInfo('Cadre', currentPosting.branchName),
                if (currentPosting.dateofjoin != null)
                  _buildPostingInfo(
                    'Since',
                    DateFormat('dd MMM yyyy').format(currentPosting.dateofjoin!),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPostingInfo(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.person,
                  label: 'Profile',
                  onTap: () => Navigator.pushNamed(context, '/personal_details'),
                ),
                _buildActionButton(
                  icon: Icons.business_center,
                  label: 'e-DAS',
                  badge: _buildDeputationBadge(),
                  onTap: () => Navigator.pushNamed(context, '/deputation'),
                ),
                _buildActionButton(
                  icon: Icons.history,
                  label: 'Service\nHistory',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ServiceHistoryScreen(),
                    ),
                  ),
                ),
                _buildActionButton(
                  icon: Icons.school,
                  label: 'Trainings',
                  onTap: () => Navigator.pushNamed(context, '/trainings'),
                ),
                _buildActionButton(
                  icon: Icons.family_restroom,
                  label: 'Family',
                  onTap: () => Navigator.pushNamed(context, '/family'),
                ),
                _buildActionButton(
                  icon: Icons.event_available,
                  label: 'Leave\nCredits',
                  onTap: () => Navigator.pushNamed(context, '/leave_credits'),
                ),
                _buildActionButton(
                  icon: Icons.report_problem,
                  label: 'Grievances',
                  onTap: () => Navigator.pushNamed(context, '/grievances'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Widget? badge,
  }) {
    return SizedBox(
      width: 80,
      child: Stack(
        children: [
          InkWell(
            onTap: onTap,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (badge != null)
            Positioned(
              top: 0,
              right: 0,
              child: badge,
            ),
        ],
      ),
    );
  }

  Widget _buildDeputationBadge() {
    return Consumer<DeputationService>(
      builder: (context, service, _) {
        if (service.eligibleOpenings.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${service.eligibleOpenings.length}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  void _showEnlargedImage(BuildContext context, Uint8List imageData) {
    showDialog(
      context: context,
      builder: (context) => ImageViewerDialog(imageData: imageData),
    );
  }
} 