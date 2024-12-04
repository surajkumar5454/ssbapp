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
    final trainingService = context.read<TrainingService>();
    final authService = context.read<AuthService>();
    await trainingService.loadTrainings(authService.uin!);
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

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: trainings.length,
              itemBuilder: (context, index) {
                final training = trainings[index];
                return Card(
                  child: ListTile(
                    title: Text(training.course_nm ?? 'Unknown Course'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (training.duration != null)
                          Text('Duration: ${training.duration}'),
                        if (training.fromDate != null)
                          Text('From: ${training.fromDate}'),
                        if (training.toDate != null)
                          Text('To: ${training.toDate}'),
                        if (training.category != null)
                          Text('Category: ${training.category}'),
                        if (training.position != null)
                          Text('Position: ${training.position}'),
                        if (training.remarks != null)
                          Text('Remarks: ${training.remarks}'),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
} 