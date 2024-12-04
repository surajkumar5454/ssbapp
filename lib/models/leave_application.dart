class LeaveApplication {
  final int? id;
  final String uidno;
  final String leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final String status;
  final DateTime appliedDate;

  LeaveApplication({
    this.id,
    required this.uidno,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
    required this.appliedDate,
  });

  factory LeaveApplication.fromJson(Map<String, dynamic> json) {
    return LeaveApplication(
      id: json['id'],
      uidno: json['uidno'],
      leaveType: json['leave_type'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      reason: json['reason'],
      status: json['status'],
      appliedDate: DateTime.parse(json['applied_date']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'uidno': uidno,
    'leave_type': leaveType,
    'start_date': startDate.toIso8601String(),
    'end_date': endDate.toIso8601String(),
    'reason': reason,
    'status': status,
    'applied_date': appliedDate.toIso8601String(),
  };
} 