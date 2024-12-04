import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';
import '../../widgets/main_layout.dart';
import '../../services/profile_service.dart';
import '../../services/posting_service.dart';
import '../../services/training_service.dart';
import '../../services/auth_service.dart';
import 'package:intl/intl.dart';
import '../../widgets/image_viewer_dialog.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to load data after the build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final authService = context.read<AuthService>();
    final uin = authService.uin!;
    
    // Load all required data
    await Future.wait([
      context.read<PostingService>().loadPostings(uin),
      context.read<TrainingService>().loadTrainings(uin),
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
                  const SizedBox(height: 16),
                  _buildRecentTrainings(),
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
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            profile.rankName,
                            style: Theme.of(context).textTheme.titleMedium,
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
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrentPostingCard() {
    return Consumer<PostingService>(
      builder: (context, postingService, _) {
        final postings = postingService.postings;
        if (postings.isEmpty) return const SizedBox.shrink();

        final currentPosting = postings.first; // Most recent posting
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Posting',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text('Unit: ${currentPosting.unitName ?? 'N/A'}'),
                Text('Rank: ${currentPosting.rankName ?? 'N/A'}'),
                Text('Branch: ${currentPosting.branchName ?? 'N/A'}'),
                if (currentPosting.dateofjoin != null)
                  Text('Since: ${DateFormat('dd MMM yyyy').format(currentPosting.dateofjoin!)}'),
                if (currentPosting.dateofrelv != null)
                  Text('Until: ${DateFormat('dd MMM yyyy').format(currentPosting.dateofrelv!)}'),
              ],
            ),
          ),
        );
      },
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                  icon: Icons.person,
                  label: 'Profile',
                  onTap: () => Navigator.pushNamed(context, '/personal_details'),
                ),
                _buildActionButton(
                  icon: Icons.receipt_long,
                  label: 'Pay Slips',
                  onTap: () => Navigator.pushNamed(context, '/pay_slips'),
                ),
                _buildActionButton(
                  icon: Icons.school,
                  label: 'Trainings',
                  onTap: () => Navigator.pushNamed(context, '/trainings'),
                ),
                _buildActionButton(
                  icon: Icons.settings,
                  label: 'Settings',
                  onTap: () => Navigator.pushNamed(context, '/settings'),
                ),
                _buildActionButton(
                  icon: Icons.family_restroom,
                  label: 'Family',
                  onTap: () => Navigator.pushNamed(context, '/family'),
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
  }) {
    return InkWell(
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
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildRecentTrainings() {
    return Consumer<TrainingService>(
      builder: (context, trainingService, _) {
        final trainings = trainingService.trainings;
        if (trainings.isEmpty) return const SizedBox.shrink();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Trainings',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/trainings'),
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: trainings.length.clamp(0, 3), // Show max 3 recent trainings
                  itemBuilder: (context, index) {
                    final training = trainings[index];
                    return ListTile(
                      title: Text(training.course_nm ?? 'Unknown Course'),
                      subtitle: Text(
                        '${training.fromDate ?? ''} - ${training.toDate ?? ''}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.pushNamed(context, '/trainings'),
                    );
                  },
                ),
              ],
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