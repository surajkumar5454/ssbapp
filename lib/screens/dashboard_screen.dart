class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final authService = context.read<AuthService>();
      final deputationService = context.read<DeputationService>();
      final grievanceService = context.read<GrievanceService>();
      
      // Load all required data
      await Future.wait([
        deputationService.loadEligibleOpenings(authService.uin!),
        grievanceService.loadGrievances(),
        // ... other data loading
      ]);
      
      // Start periodic refresh for deputation
      deputationService.startPeriodicRefresh();
    } catch (e) {
      print('Error loading dashboard data: $e');
    }
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
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildUserInfo(),
              _buildQuickActions(),
              // Remove _buildDeputationNotifications() if not defined
              // ... other widgets
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildActionItem(
                  icon: Icons.description,
                  label: 'Submit\nGrievance',
                  onTap: () => Navigator.pushNamed(context, '/submit_grievance'),
                ),
                _buildActionItem(
                  icon: Icons.business_center,
                  label: 'e-DAS',
                  badge: _buildDeputationBadge(),
                  onTap: () => Navigator.pushNamed(context, '/deputation'),
                ),
                _buildActionItem(
                  icon: Icons.calendar_today,
                  label: 'Apply\nLeave',
                  onTap: () => Navigator.pushNamed(context, '/leave'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Widget? badge,
  }) {
    return Stack(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 100,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 24),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (badge != null)
          Positioned(
            top: 0,
            right: 0,
            child: badge,
          ),
      ],
    );
  }

  Widget? _buildDeputationBadge() {
    return Consumer<DeputationService>(
      builder: (context, service, _) {
        if (!service.hasNewOpenings) return null;
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
} 