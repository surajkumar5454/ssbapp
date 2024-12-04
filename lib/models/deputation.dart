class Deputation {
  final String id;
  final String targetOrganization;
  final String position;
  final String reason;
  final DateTime requestDate;
  final String status;
  final String remarks;

  Deputation({
    required this.id,
    required this.targetOrganization,
    required this.position,
    required this.reason,
    required this.requestDate,
    required this.status,
    this.remarks = '',
  });

  factory Deputation.fromJson(Map<String, dynamic> json) {
    return Deputation(
      id: json['id'],
      targetOrganization: json['targetOrganization'],
      position: json['position'],
      reason: json['reason'],
      requestDate: DateTime.parse(json['requestDate']),
      status: json['status'],
      remarks: json['remarks'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'targetOrganization': targetOrganization,
      'position': position,
      'reason': reason,
      'requestDate': requestDate.toIso8601String(),
      'status': status,
      'remarks': remarks,
    };
  }
} 