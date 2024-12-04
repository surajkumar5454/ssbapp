import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../widgets/main_layout.dart';
import '../../services/family_service.dart';
import '../../services/auth_service.dart';
import '../../models/family_member.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFamilyMembers();
    });
  }

  Future<void> _loadFamilyMembers() async {
    final familyService = context.read<FamilyService>();
    final authService = context.read<AuthService>();
    await familyService.loadFamilyMembers(authService.uin!);
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Family Details'),
        ),
        body: Consumer<FamilyService>(
          builder: (context, familyService, _) {
            if (familyService.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (familyService.error != null) {
              return Center(child: Text(familyService.error!));
            }

            final members = familyService.familyMembers;
            if (members.isEmpty) {
              return const Center(child: Text('No family members found'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: members.length,
              itemBuilder: (context, index) {
                final member = members[index];
                return _buildFamilyMemberCard(member);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildFamilyMemberCard(FamilyMember member) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name ?? 'N/A',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        member.getRelationshipText(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Gender', member.memberGender),
            _buildInfoRow('Date of Birth', member.dob != null 
                ? DateFormat('dd MMM yyyy').format(member.dob!)
                : null),
            _buildInfoRow('Marital Status', member.maritalStatus),
            _buildInfoRow('Dependent', member.dependent),
            if (member.disability != null && member.disability!.isNotEmpty)
              _buildInfoRow('Disability', member.disability),
            if (member.memberGovtService == 'Y')
              _buildInfoRow('Department', member.departmentName),
            if (member.income != null && member.income!.isNotEmpty)
              _buildInfoRow('Income', member.income),
            if (member.ayushmanEligibility != null)
              _buildInfoRow('Ayushman Eligible', member.ayushmanEligibility),
            if (member.remarks != null && member.remarks!.isNotEmpty)
              _buildInfoRow('Remarks', member.remarks),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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