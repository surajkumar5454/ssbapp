import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/profile_service.dart';
import '../../services/auth_service.dart';
import '../../services/family_service.dart';
import '../../widgets/main_layout.dart';
import '../../models/user_profile.dart';

class PersonalDetailsScreen extends StatefulWidget {
  const PersonalDetailsScreen({super.key});

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final authService = context.read<AuthService>();
    if (authService.uin != null) {
      await Future.wait([
        context.read<ProfileService>().loadProfile(authService.uin!),
        context.read<FamilyService>().loadFamilyMembers(authService.uin!),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Personal Details'),
        ),
        body: Consumer2<ProfileService, FamilyService>(
          builder: (context, profileService, familyService, _) {
            if (profileService.isLoading || familyService.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final profile = profileService.profile;
            if (profile == null) {
              return const Center(child: Text('No profile data found'));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(
                    title: 'Basic Information',
                    children: [
                      _buildInfoRow('Name', profile.name),
                      _buildInfoRow('UIN', profile.uidno),
                      _buildInfoRow('Rank', profile.rankName),
                      _buildInfoRow('Gender', profile.gen ?? 'N/A'),
                      _buildInfoRow('Blood Group', profile.bloodgr ?? 'N/A'),
                      _buildInfoRow('Date of Birth', profile.dob ?? 'N/A'),
                      _buildInfoRow('Marital Status', profile.marital_st ?? 'N/A'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    title: 'Family Information',
                    children: [
                      _buildInfoRow("Father's Name", profile.fathername ?? 'N/A'),
                      _buildInfoRow("Mother's Name", profile.mothername ?? 'N/A'),
                      ...familyService.familyMembers
                          .where((member) => member.relationship == 7.0 || member.relationship == 8.0)
                          .map((spouse) => _buildInfoRow(
                                "Spouse's Name",
                                spouse.name ?? 'N/A',
                              ))
                          .take(1),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    title: 'Contact Information',
                    children: [
                      _buildInfoRow('Email', profile.eMail ?? 'N/A'),
                      _buildInfoRow('Phone', profile.mobno ?? 'N/A'),
                      _buildInfoRow('Address', profile.paddress ?? 'N/A'),
                      _buildInfoRow('District', profile.district ?? 'N/A'),
                      _buildInfoRow('State', profile.state ?? 'N/A'),
                      _buildInfoRow('Pincode', profile.pincode ?? 'N/A'),
                      if (profile.homephone != null)
                        _buildInfoRow('Home Phone', profile.homephone!),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
} 