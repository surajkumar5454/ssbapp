import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/grievance_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/main_layout.dart';
import '../../models/grievance.dart';
import 'package:intl/intl.dart';
import '../../models/grievance_status.dart';

class ViewGrievancesScreen extends StatefulWidget {
  const ViewGrievancesScreen({super.key});

  @override
  State<ViewGrievancesScreen> createState() => _ViewGrievancesScreenState();
}

class _ViewGrievancesScreenState extends State<ViewGrievancesScreen> {
  final List<GrievanceStatus> _statusTabs = [
    GrievanceStatus.pending,
    GrievanceStatus.inProgress,
    GrievanceStatus.resolved,
    GrievanceStatus.returned,
    GrievanceStatus.closed,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGrievances();
    });
  }

  Future<void> _loadGrievances() async {
    final authService = context.read<AuthService>();
    await context.read<GrievanceService>().loadGrievances(authService.uin!);
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Grievances'),
            actions: [
              IconButton(
                icon: const Icon(Icons.history),
                onPressed: () => Navigator.pushNamed(context, '/grievance_history'),
              ),
            ],
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(kToolbarHeight),
              child: TabBar(
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.upload_outlined),
                        SizedBox(width: 8),
                        Text('Submitted'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.download_outlined),
                        SizedBox(width: 8),
                        Text('Received'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: TabBarView(
            children: [
              _buildStatusFilteredList(isSubmitted: true),
              _buildStatusFilteredList(isSubmitted: false),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => Navigator.pushNamed(context, '/submit_grievance'),
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusFilteredList({required bool isSubmitted}) {
    return Consumer<GrievanceService>(
      builder: (context, grievanceService, _) {
        final allGrievances = isSubmitted
            ? grievanceService.submittedGrievances
            : grievanceService.receivedGrievances;

        final stats = _calculateStats(allGrievances);

        return DefaultTabController(
          length: _statusTabs.length,
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TabBar(
                  isScrollable: true,
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor: Colors.grey,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  ),
                  tabs: _statusTabs.map((status) {
                    final count = stats[status] ?? 0;
                    return Tab(
                      height: 36,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: count > 0 
                                ? _getStatusColor(status)
                                : Colors.grey.withOpacity(0.3),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getStatusIcon(status),
                              size: 16,
                              color: count > 0 
                                  ? _getStatusColor(status)
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              status.label,
                              style: TextStyle(
                                fontSize: 13,
                                color: count > 0 
                                    ? _getStatusColor(status)
                                    : Colors.grey,
                              ),
                            ),
                            if (count > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(status),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  count.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: _statusTabs.map((status) {
                    return _buildGrievanceList(
                      context,
                      isSubmitted: isSubmitted,
                      status: status,
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper method to calculate statistics
  Map<GrievanceStatus, int> _calculateStats(List<Grievance> grievances) {
    final stats = <GrievanceStatus, int>{};
    for (final grievance in grievances) {
      stats[grievance.status] = (stats[grievance.status] ?? 0) + 1;
    }
    return stats;
  }

  Widget _buildGrievanceList(
    BuildContext context, {
    required bool isSubmitted,
    required GrievanceStatus status,
  }) {
    return Consumer<GrievanceService>(
      builder: (context, grievanceService, _) {
        if (grievanceService.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final allGrievances = isSubmitted
            ? grievanceService.submittedGrievances
            : grievanceService.receivedGrievances;

        final grievances = allGrievances
            .where((g) => g.status == status)
            .toList();

        if (grievances.isEmpty) {
          return Center(
            child: Text(
              'No ${status.label.toLowerCase()} grievances',
              style: TextStyle(color: Colors.grey[600]),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadGrievances,
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: grievances.length,
            itemBuilder: (context, index) {
              final grievance = grievances[index];
              return Card(
                child: Column(
                  children: [
                    ListTile(
                      title: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (grievance.grievanceId != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'ID: ${grievance.grievanceId}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  grievance.subject,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(
                              grievance.priority,
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: _getPriorityColor(grievance.priority),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          if (!isSubmitted) ...[
                            Row(
                              children: [
                                const Icon(Icons.person_outline, size: 16),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'From: ${grievance.senderName ?? 'N/A'}',
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                            if (grievance.senderRank != null || grievance.senderUnit != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 20),
                                child: Text(
                                  '${grievance.senderRank ?? ''} ${grievance.senderUnit != null ? '• ${grievance.senderUnit}' : ''}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),
                          ],
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('dd MMM yyyy, HH:mm').format(grievance.submittedDate),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.info_outline, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'Status: ${grievance.status.label}',
                                style: TextStyle(
                                  color: _getStatusColor(grievance.status),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          if (grievance.daysElapsed != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Days Elapsed: ${grievance.daysElapsed}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                      onTap: () => _showGrievanceDetails(context, grievance),
                    ),
                    if (!isSubmitted)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: _buildActionButtons(grievance),
                      ),
                    if (grievance.status == GrievanceStatus.returned)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Resubmit with Additional Information'),
                          onPressed: () => _showResubmitDialog(grievance),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(Grievance grievance) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Forward Button
          if (grievance.status == GrievanceStatus.pending || 
              grievance.status == GrievanceStatus.inProgress)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.forward, size: 16),
                label: const Text(
                  'Forward',
                  style: TextStyle(fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: const Size(0, 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                onPressed: () => _showForwardDialog(grievance),
              ),
            ),

          // Return Button
          if (grievance.status == GrievanceStatus.pending || 
              grievance.status == GrievanceStatus.inProgress)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.reply, size: 16),
                label: const Text(
                  'Return',
                  style: TextStyle(fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: const Size(0, 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                onPressed: () => _showReturnDialog(grievance),
              ),
            ),

          // Resolve Button
          if (grievance.status == GrievanceStatus.pending || 
              grievance.status == GrievanceStatus.inProgress)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline, size: 16),
                label: const Text(
                  'Resolve',
                  style: TextStyle(fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: const Size(0, 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                onPressed: () => _showResolveDialog(grievance),
              ),
            ),

          // Close Button
          if (grievance.status == GrievanceStatus.resolved || 
              grievance.status == GrievanceStatus.selfResolved)
            ElevatedButton.icon(
              icon: const Icon(Icons.close, size: 16),
              label: const Text(
                'Close',
                style: TextStyle(fontSize: 12),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: const Size(0, 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: () => _showCloseDialog(grievance),
            ),
        ],
      ),
    );
  }

  // Helper method to get button color based on status
  Color _getActionButtonColor(GrievanceStatus status) {
    switch (status) {
      case GrievanceStatus.pending:
        return Colors.blue;
      case GrievanceStatus.inProgress:
        return Colors.orange;
      case GrievanceStatus.resolved:
      case GrievanceStatus.selfResolved:
        return Colors.green;
      case GrievanceStatus.returned:
        return Colors.amber;
      case GrievanceStatus.closed:
        return Colors.grey;
    }
  }

  Future<void> _showGrievanceDetails(BuildContext context, Grievance grievance) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (grievance.grievanceId != null)
              Text(
                grievance.grievanceId!,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            Text(grievance.subject),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (grievance.senderName != null) ...[
                Text(
                  'Sender Details:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(grievance.senderName!),
                  subtitle: Text(
                    '${grievance.senderRank} • ${grievance.senderUnit}',
                  ),
                ),
                const Divider(),
              ],
              Text('Category: ${grievance.category}'),
              const SizedBox(height: 8),
              Text('Priority: ${grievance.priority}'),
              const SizedBox(height: 8),
              Text('Status: ${grievance.status.label}'),
              const SizedBox(height: 16),
              Text('Description:'),
              const SizedBox(height: 4),
              Text(grievance.description),
              if (grievance.remarks != null) ...[
                const SizedBox(height: 16),
                Text('Remarks:'),
                const SizedBox(height: 4),
                Text(grievance.remarks!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showForwardDialog(Grievance grievance) {
    final controller = TextEditingController();
    List<Map<String, dynamic>> searchResults = [];

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Forward Grievance'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                            labelText: 'Enter UIN or Name',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          if (controller.text.isNotEmpty) {
                            final results = await context
                                .read<GrievanceService>()
                                .searchUsers(controller.text);
                            setState(() {
                              searchResults = results;
                              _forwardToDetails = null; // Clear previous selection
                            });
                          }
                        },
                        child: const Text('Search'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (searchResults.isNotEmpty) ...[
                    const Text(
                      'Search Results:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: searchResults.length,
                          itemBuilder: (context, index) {
                            final user = searchResults[index];
                            return Card(
                              child: ListTile(
                                title: Text(user['name'] ?? 'N/A'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('UIN: ${user['uidno']}'),
                                    Text('${user['rank_name']} - ${user['unit_nm']}'),
                                  ],
                                ),
                                onTap: () {
                                  setState(() {
                                    _forwardToDetails = user;
                                    searchResults = []; // Clear search results
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                  if (_forwardToDetails != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selected User:',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Name: ${_forwardToDetails!['name']}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Rank: ${_forwardToDetails!['rank_name']}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Unit: ${_forwardToDetails!['unit_nm']}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _forwardToDetails = null;
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _forwardToDetails != null
                    ? () {
                        context.read<GrievanceService>().forwardGrievance(
                          grievance,
                          _forwardToDetails!['uidno'] as String,
                          _forwardToDetails!['name'] as String,
                          _forwardToDetails!['rank_name'] as String? ?? '',
                          _forwardToDetails!['unit_name'] as String? ?? '',
                        );
                        Navigator.pop(context);
                        _forwardToDetails = null;
                      }
                    : null,
                child: const Text('Forward'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showReturnDialog(Grievance grievance) async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Return Grievance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please specify what additional information is required:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Required Information',
                border: OutlineInputBorder(),
                hintText: 'Explain what information is needed',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Return'),
          ),
        ],
      ),
    );

    if (result == true && controller.text.isNotEmpty) {
      final success = await context
          .read<GrievanceService>()
          .returnGrievance(grievance, controller.text);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Grievance returned for additional information')),
        );
      }
    }
  }

  Future<void> _showResolveDialog(Grievance grievance) async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resolve Grievance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to resolve this grievance?',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Resolution Remarks',
                border: OutlineInputBorder(),
                hintText: 'Please provide resolution details',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Resolve'),
          ),
        ],
      ),
    );

    if (result == true && controller.text.isNotEmpty) {
      final success = await context
          .read<GrievanceService>()
          .resolveGrievance(grievance, controller.text);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Grievance resolved successfully')),
        );
      }
    }
  }

  Future<void> _showCloseDialog(Grievance grievance) async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close Grievance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to close this grievance?',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Closing Remarks',
                border: OutlineInputBorder(),
                hintText: 'Add any final remarks (optional)',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Close'),
          ),
        ],
      ),
    );

    if (result == true) {
      final remarks = controller.text.isNotEmpty 
          ? controller.text 
          : 'Grievance closed by admin';
          
      final success = await context
          .read<GrievanceService>()
          .closeGrievance(grievance, remarks);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Grievance closed successfully')),
        );
      }
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return Colors.green[100]!;
      case 'normal':
        return Colors.blue[100]!;
      case 'high':
        return Colors.orange[100]!;
      case 'urgent':
        return Colors.red[100]!;
      default:
        return Colors.grey[100]!;
    }
  }

  Color _getStatusColor(GrievanceStatus status) {
    switch (status) {
      case GrievanceStatus.resolved:
      case GrievanceStatus.selfResolved:
        return Colors.green;
      case GrievanceStatus.pending:
        return Colors.orange;
      case GrievanceStatus.inProgress:
        return Colors.blue;
      case GrievanceStatus.returned:
        return Colors.amber;
      case GrievanceStatus.closed:
        return Colors.grey;
    }
  }

  Map<String, dynamic>? _forwardToDetails;

  Future<void> _updateStatus(
    Grievance grievance,
    GrievanceStatus newStatus,
    String remarks,
  ) async {
    final success = await context.read<GrievanceService>().updateGrievanceStatus(
      grievance,
      newStatus.label,
      remarks: remarks,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to ${newStatus.label}')),
      );
    }
  }

  Future<void> _showResubmitDialog(Grievance grievance) async {
    final controller = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resubmit Grievance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Original Remarks: ${grievance.remarks ?? "No remarks"}',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Additional Information',
                border: OutlineInputBorder(),
                hintText: 'Please provide the requested information',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Resubmit'),
          ),
        ],
      ),
    );

    if (result == true && controller.text.isNotEmpty) {
      final success = await context
          .read<GrievanceService>()
          .resubmitGrievance(grievance, controller.text);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Grievance resubmitted successfully')),
        );
      }
    }
  }

  // Add this helper method to get status-specific icons
  IconData _getStatusIcon(GrievanceStatus status) {
    switch (status) {
      case GrievanceStatus.pending:
        return Icons.pending_outlined;
      case GrievanceStatus.inProgress:
        return Icons.trending_up_outlined;
      case GrievanceStatus.resolved:
      case GrievanceStatus.selfResolved:
        return Icons.check_circle_outline;
      case GrievanceStatus.returned:
        return Icons.replay_outlined;
      case GrievanceStatus.closed:
        return Icons.lock_outline;
    }
  }
} 