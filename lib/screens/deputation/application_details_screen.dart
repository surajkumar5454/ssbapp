class ApplicationDetailsScreen extends StatelessWidget {
  final DeputationApplication application;

  const ApplicationDetailsScreen({
    super.key,
    required this.application,
  });

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Application Details'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildStatusTimeline(),
            const SizedBox(height: 16),
            _buildApplicationDetails(),
            if (_canUpdateStatus())
              _buildStatusUpdateButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTimeline() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Application Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            for (var stage in ApplicationStage.values)
              _buildTimelineItem(stage),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(ApplicationStage stage) {
    final isCurrentStage = application.status == stage.label;
    final isPastStage = ApplicationStage.values
        .indexOf(stage) <= 
        ApplicationStage.values
        .indexWhere((s) => s.label == application.status);

    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCurrentStage
                ? Colors.blue
                : isPastStage
                    ? Colors.green
                    : Colors.grey[300],
          ),
          child: Icon(
            isCurrentStage
                ? Icons.lens
                : isPastStage
                    ? Icons.check
                    : Icons.lens_outlined,
            size: 16,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          stage.label,
          style: TextStyle(
            color: isCurrentStage ? Colors.blue : null,
            fontWeight: isCurrentStage ? FontWeight.bold : null,
          ),
        ),
      ],
    );
  }
} 