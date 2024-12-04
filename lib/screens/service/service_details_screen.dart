import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../widgets/main_layout.dart';
import '../../services/posting_service.dart';
import '../../services/auth_service.dart';

class ServiceDetailsScreen extends StatefulWidget {
  const ServiceDetailsScreen({super.key});

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPostings();
    });
  }

  Future<void> _loadPostings() async {
    final authService = context.read<AuthService>();
    await context.read<PostingService>().loadPostings(authService.uin!);
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Service History'),
        ),
        body: Consumer<PostingService>(
          builder: (context, postingService, _) {
            if (postingService.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (postingService.error != null) {
              return Center(child: Text(postingService.error!));
            }

            final postings = postingService.postings;
            if (postings.isEmpty) {
              return const Center(child: Text('No posting history found'));
            }

            return RefreshIndicator(
              onRefresh: _loadPostings,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: postings.length,
                itemBuilder: (context, index) {
                  final posting = postings[index];
                  final isCurrentPosting = index == 0;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      children: [
                        // Posting Header
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isCurrentPosting 
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(context).colorScheme.surfaceVariant,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isCurrentPosting
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.outline,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.location_on,
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      posting.unitName ?? 'Unknown Unit',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (isCurrentPosting)
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'Current Posting',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Theme.of(context).colorScheme.onPrimary,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Posting Details
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildPostingInfo(
                                context,
                                icon: Icons.military_tech,
                                label: 'Rank',
                                value: posting.rankName ?? 'N/A',
                              ),
                              const SizedBox(height: 8),
                              _buildPostingInfo(
                                context,
                                icon: Icons.category,
                                label: 'Branch',
                                value: posting.branchName ?? 'N/A',
                              ),
                              const SizedBox(height: 8),
                              _buildPostingInfo(
                                context,
                                icon: Icons.calendar_today,
                                label: 'Period',
                                value: _formatPostingPeriod(
                                  posting.dateofjoin,
                                  posting.dateofrelv,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildPostingInfo(
                                context,
                                icon: Icons.timer,
                                label: 'Tenure',
                                value: _calculateTenure(
                                  posting.dateofjoin,
                                  posting.dateofrelv,
                                ),
                              ),
                              if (posting.joiningremark?.isNotEmpty ?? false) ...[
                                const SizedBox(height: 8),
                                _buildPostingInfo(
                                  context,
                                  icon: Icons.note,
                                  label: 'Remarks',
                                  value: posting.joiningremark!,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatPostingPeriod(DateTime? start, DateTime? end) {
    if (start == null) return 'Period not available';
    
    final startStr = DateFormat('dd MMM yyyy').format(start);
    if (end == null) return 'Since $startStr';
    
    final endStr = DateFormat('dd MMM yyyy').format(end);
    return '$startStr - $endStr';
  }

  String _calculateTenure(DateTime? start, DateTime? end) {
    if (start == null) return 'N/A';
    
    final endDate = end ?? DateTime.now();  // Use current date if still posted
    final difference = endDate.difference(start);
    
    final years = difference.inDays ~/ 365;
    final remainingDays = difference.inDays % 365;
    final months = remainingDays ~/ 30;
    
    if (years > 0) {
      return months > 0 
          ? '$years years, $months months' 
          : '$years years';
    } else {
      return '$months months';
    }
  }

  Widget _buildPostingInfo(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
} 