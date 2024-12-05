enum GrievanceStatus {
  pending('Pending'),
  inProgress('In Progress'),
  resolved('Resolved'),
  selfResolved('Self-resolved'),
  returned('Returned'),
  closed('Closed');

  final String label;
  const GrievanceStatus(this.label);

  static GrievanceStatus fromString(String status) {
    return GrievanceStatus.values.firstWhere(
      (e) => e.label.toLowerCase() == status.toLowerCase(),
      orElse: () => GrievanceStatus.pending,
    );
  }
} 