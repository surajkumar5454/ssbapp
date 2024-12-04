import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/main_layout.dart';
import '../../services/training_service.dart';
import '../../services/auth_service.dart';
import 'package:intl/intl.dart';

class TrainingsScreen extends StatefulWidget {
  const TrainingsScreen({super.key});

  @override
  State<TrainingsScreen> createState() => _TrainingsScreenState();
}

class _TrainingsScreenState extends State<TrainingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTrainings();
    });
  }

  Future<void> _loadTrainings() async {
    final authService = context.read<AuthService>();
    await context.read<TrainingService>().loadTrainings(authService.uin!);
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Training History'),
        ),
        body: Consumer<TrainingService>(
          builder: (context, trainingService, _) {
            if (trainingService.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (trainingService.error != null) {
              return Center(child: Text(trainingService.error!));
            }

            final trainings = trainingService.trainings;
            if (trainings.isEmpty) {
              return const Center(child: Text('No training history found'));
            }

            return RefreshIndicator(
              onRefresh: _loadTrainings,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: trainings.length,
                itemBuilder: (context, index) {
                  final training = trainings[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Training Header
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _getCategoryIcon(training.category),
                                color: Theme.of(context).colorScheme.primary,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      training.course_nm ?? 'Unknown Course',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (training.category != null)
                                      Text(
                                        training.category!,
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Training Details
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildTrainingInfo(
                                context,
                                icon: Icons.calendar_today,
                                label: 'Duration',
                                value: _formatDuration(
                                  training.fromDate,
                                  training.toDate,
                                ),
                              ),
                              if (training.duration != null) ...[
                                const SizedBox(height: 8),
                                _buildTrainingInfo(
                                  context,
                                  icon: Icons.timer,
                                  label: 'Total Hours',
                                  value: '${training.duration} hours',
                                ),
                              ],
                              if (training.position != null) ...[
                                const SizedBox(height: 8),
                                _buildTrainingInfo(
                                  context,
                                  icon: Icons.grade,
                                  label: 'Position',
                                  value: training.position!,
                                ),
                              ],
                              if (training.remarks != null && training.remarks!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                _buildTrainingInfo(
                                  context,
                                  icon: Icons.note,
                                  label: 'Remarks',
                                  value: training.remarks!,
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

  IconData _getCategoryIcon(String? category) {
    if (category == null) return Icons.school;
    
    switch (category.toLowerCase()) {
      case 'technical':
        return Icons.computer;
      case 'management':
        return Icons.business;
      case 'soft skills':
        return Icons.people;
      case 'professional':
        return Icons.work;
      default:
        return Icons.school;
    }
  }

  String _formatDuration(String? fromDate, String? toDate) {
    if (fromDate == null || toDate == null) return 'Duration not available';
    
    try {
      print('From Date: $fromDate');
      print('To Date: $toDate');
      
      DateTime? start;
      DateTime? end;
      
      try {
        final parts1 = fromDate.split('/');
        final parts2 = toDate.split('/');
        
        if (parts1.length == 3 && parts2.length == 3) {
          start = DateTime(
            int.parse(parts1[2]),
            int.parse(parts1[1]),
            int.parse(parts1[0]),
          );
          end = DateTime(
            int.parse(parts2[2]),
            int.parse(parts2[1]),
            int.parse(parts2[0]),
          );
        }
      } catch (e) {
        print('Error parsing dates: $e');
      }

      if (start != null && end != null) {
        return '${DateFormat('dd MMM yyyy').format(start)} - ${DateFormat('dd MMM yyyy').format(end)}';
      }
      
      return 'Invalid date format';
    } catch (e) {
      print('Error formatting dates: $e');
      return 'Error processing dates';
    }
  }

  Widget _buildTrainingInfo(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Column(
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
      ],
    );
  }
} 