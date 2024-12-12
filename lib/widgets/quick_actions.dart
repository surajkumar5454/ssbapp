import 'package:flutter/material.dart';
import '../screens/profile/service_history_screen.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with centered title
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.flash_on,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Grid layout with 4x2 grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1,
              children: [
                _buildActionCard(
                  context,
                  icon: Icons.person,
                  label: 'Profile',
                  color: Colors.blue.shade600,
                  onTap: () => Navigator.pushNamed(context, '/personal_details'),
                ),
                _buildActionCard(
                  context,
                  icon: Icons.business_center,
                  label: 'e-DAS',
                  color: Colors.orange.shade600,
                  badge: _buildBadge(context, '3'),
                  onTap: () => Navigator.pushNamed(context, '/deputation'),
                ),
                _buildActionCard(
                  context,
                  icon: Icons.history,
                  label: 'Service\nHistory',
                  color: Colors.purple.shade600,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ServiceHistoryScreen(),
                    ),
                  ),
                ),
                _buildActionCard(
                  context,
                  icon: Icons.school,
                  label: 'Trainings',
                  color: Colors.teal.shade600,
                  onTap: () => Navigator.pushNamed(context, '/trainings'),
                ),
                _buildActionCard(
                  context,
                  icon: Icons.family_restroom,
                  label: 'Family',
                  color: Colors.pink.shade600,
                  onTap: () => Navigator.pushNamed(context, '/family'),
                ),
                _buildActionCard(
                  context,
                  icon: Icons.event_available,
                  label: 'Leave\nCredits',
                  color: Colors.green.shade600,
                  onTap: () => Navigator.pushNamed(context, '/leave_credits'),
                ),
                _buildActionCard(
                  context,
                  icon: Icons.report_problem,
                  label: 'Grievances',
                  color: Colors.red.shade600,
                  onTap: () => Navigator.pushNamed(context, '/grievances'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    Widget? badge,
    required VoidCallback onTap,
  }) {
    return Stack(
      children: [
        Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: color.withOpacity(0.2),
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withOpacity(0.15),
                    color.withOpacity(0.05),
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (badge != null)
          Positioned(
            top: 4,
            right: 4,
            child: badge,
          ),
      ],
    );
  }

  Widget _buildBadge(BuildContext context, String count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        count,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onError,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
} 