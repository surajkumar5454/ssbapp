import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/database_helper.dart';
import '../../widgets/main_layout.dart';

class ServiceHistoryScreen extends StatefulWidget {
  const ServiceHistoryScreen({super.key});

  @override
  State<ServiceHistoryScreen> createState() => _ServiceHistoryScreenState();
}

class _ServiceHistoryScreenState extends State<ServiceHistoryScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _serviceHistory = [];

  @override
  void initState() {
    super.initState();
    _loadServiceHistory();
  }

  Future<void> _loadServiceHistory() async {
    setState(() => _isLoading = true);
    try {
      final perNo = context.read<AuthService>().uin;
      print('Loading service history for UIN: $perNo');
      
      if (perNo != null) {
        List<Map<String, dynamic>> postings = [];
        List<Map<String, dynamic>> trainings = [];

        try {
          print('Fetching posting history...');
          postings = await DatabaseHelper.instance.getPostingHistory(perNo);
          print('Postings received: ${postings.length}');
        } catch (e) {
          print('Error fetching postings: $e');
        }

        try {
          print('Fetching training history...');
          trainings = await DatabaseHelper.instance.getTrainingHistory(perNo);
          print('Trainings received: ${trainings.length}');
        } catch (e) {
          print('Error fetching trainings: $e');
        }

        // Convert postings to timeline format with nested trainings
        List<Map<String, dynamic>> timeline = postings.map((posting) {
          final postingStartDate = DateTime.parse(posting['dateofjoin']);
          final postingEndDate = posting['dateofrelv'] != null 
              ? DateTime.parse(posting['dateofrelv'])
              : null;

          // Find trainings during this posting
          final relatedTrainings = trainings.where((training) {
            final trainingStartDate = _parseDate(training['fromDate']?.toString());
            if (trainingStartDate == null) return false;

            bool isWithinPosting = trainingStartDate.isAfter(postingStartDate) || 
                                  trainingStartDate.isAtSameMomentAs(postingStartDate);
            
            if (postingEndDate != null) {
              isWithinPosting = isWithinPosting && 
                              (trainingStartDate.isBefore(postingEndDate) || 
                               trainingStartDate.isAtSameMomentAs(postingEndDate));
            }
            
            return isWithinPosting;
          }).map((training) {
            final startDate = _parseDate(training['fromDate']?.toString());
            final endDate = _parseDate(training['toDate']?.toString());
            
            return {
              'title': training['course_nm'] ?? 'Unknown Course',
              'subtitle': training['institute_name'] ?? '',
              'location': training['location'] ?? '',
              'start_date': startDate?.toIso8601String(),
              'end_date': endDate?.toIso8601String(),
              'type': 'training',
              'remarks': training['remarks'],
              'additional_info': {
                'Position': training['position'],
                'Performance': {
                  'Professional': training['prof'],
                  'Theory': training['theory'],
                  'Instruction Ability': training['instruction_ability']
                },
                'Status': training['flgapproved'] == 1 ? 'Approved' : 'Pending',
                'Approved By': training['approvedbyname'],
                'Approved On': training['approvedondt'],
              }
            };
          }).toList();

          return {
            'title': posting['unit_nm'] ?? '',
            'subtitle': '${posting['rnk_nm']} - ${posting['brn_nm']}',
            'location': '', // Can be added if available
            'start_date': posting['dateofjoin'],
            'end_date': posting['dateofrelv'],
            'type': 'posting',
            'remarks': posting['joiningremark'],
            'trainings': relatedTrainings.where((t) => 
              t['start_date'] != null && t['title'] != null
            ).toList(), // Filter out invalid training entries
          };
        }).toList();

        // Sort by date
        timeline.sort((a, b) {
          final aDate = DateTime.parse(a['start_date'].toString());
          final bDate = DateTime.parse(b['start_date'].toString());
          return bDate.compareTo(aDate);
        });

        setState(() => _serviceHistory = timeline);
      }
    } catch (e) {
      print('Error in _loadServiceHistory: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading service history: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Scaffold(
      appBar: AppBar(
        title: const Text('Service History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadServiceHistory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _serviceHistory.isEmpty
              ? const Center(child: Text('No service history found'))
              : ListView.builder(
                  itemCount: _serviceHistory.length,
                  itemBuilder: (context, index) => _buildTimelineCard(_serviceHistory[index]),
                ),
    );

    return MainLayout(child: content);
  }

  Widget _buildTimelineCard(Map<String, dynamic> record) {
    final startDate = DateTime.parse(record['start_date'].toString());
    final endDate = record['end_date'] != null 
        ? DateTime.parse(record['end_date'].toString())
        : null;
    final trainings = (record['trainings'] as List?)
        ?.map((item) => item as Map<String, dynamic>)
        .toList() ?? [];

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getTimelineColor('posting').withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Main posting card
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Timeline indicator with colored bar
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: _getTimelineColor('posting'),
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                  ),
                ),
                // Date column
                Container(
                  width: 70,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: Colors.grey.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('MMM').format(startDate),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('yyyy').format(startDate),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (endDate != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          width: 2,
                          height: 16,
                          color: Colors.grey.withOpacity(0.3),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM').format(endDate),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          DateFormat('yyyy').format(endDate),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getTimelineColor('posting').withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.account_balance,
                            color: _getTimelineColor('posting'),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                record['title'] ?? '',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                record['subtitle'] ?? '',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                              if (record['location']?.isNotEmpty ?? false) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: 14,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        record['location'],
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (record['remarks']?.isNotEmpty ?? false) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    record['remarks'],
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey[700],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Training sub-items
          if (trainings.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.only(left: 74),
              child: Column(
                children: trainings.map((training) => _buildTrainingItem(training)).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrainingItem(Map<String, dynamic> training) {
    final startDate = DateTime.parse(training['start_date']);
    final endDate = training['end_date'] != null 
        ? DateTime.parse(training['end_date'])
        : null;

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _getTimelineColor('training').withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getTrainingIcon(training['title']),
              color: _getTimelineColor('training'),
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  training['title'],
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${DateFormat('MMM yyyy').format(startDate)} - ${endDate != null ? DateFormat('MMM yyyy').format(endDate) : 'Present'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                if (training['location']?.isNotEmpty ?? false)
                  Text(
                    training['location'],
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTrainingIcon(String title) {
    final lowercaseTitle = title.toLowerCase();
    if (lowercaseTitle.contains('weapon') || lowercaseTitle.contains('firing')) {
      return Icons.gps_fixed;
    } else if (lowercaseTitle.contains('computer') || lowercaseTitle.contains('it')) {
      return Icons.computer;
    } else if (lowercaseTitle.contains('leadership') || lowercaseTitle.contains('management')) {
      return Icons.psychology;
    } else if (lowercaseTitle.contains('physical') || lowercaseTitle.contains('fitness')) {
      return Icons.fitness_center;
    }
    return Icons.school;
  }

  Color _getTimelineColor(String type) {
    switch (type) {
      case 'posting':
        return Colors.blue.shade700;
      case 'training':
        return Colors.green.shade600;
      default:
        return Colors.grey;
    }
  }

  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    
    try {
      // First try standard ISO format
      return DateTime.parse(dateStr);
    } catch (e) {
      try {
        // Try dd/MM/yyyy format
        final parts = dateStr.split('/');
        if (parts.length == 3) {
          return DateTime(
            int.parse(parts[2]), // year
            int.parse(parts[1]), // month
            int.parse(parts[0]), // day
          );
        }
      } catch (e) {
        print('Error parsing date $dateStr: $e');
      }
      return null;
    }
  }
} 