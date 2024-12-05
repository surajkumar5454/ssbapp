import 'package:flutter/foundation.dart';
import 'deputation_opening.dart';

enum ApplicationStatus {
  pending('Pending'),
  approved('Approved'),
  rejected('Rejected'),
  withdrawn('Withdrawn');

  final String label;
  const ApplicationStatus(this.label);

  static ApplicationStatus fromString(String status) {
    return ApplicationStatus.values.firstWhere(
      (e) => e.label.toLowerCase() == status.toLowerCase(),
      orElse: () => ApplicationStatus.pending,
    );
  }
}

class DeputationApplication {
  final int? id;
  final int openingId;
  final DeputationOpening opening;
  final String applicantUin;
  final ApplicationStatus status;
  final DateTime appliedDate;
  final String? remarks;
  final String? applicantName;
  final String? applicantRank;
  final String? applicantUnit;
  final int? experience;

  DeputationApplication({
    this.id,
    required this.openingId,
    required this.opening,
    required this.applicantUin,
    this.status = ApplicationStatus.pending,
    required this.appliedDate,
    this.remarks,
    this.applicantName,
    this.applicantRank,
    this.applicantUnit,
    this.experience,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'opening_id': openingId,
      'applicant_uin': applicantUin,
      'status': status.label,
      'applied_date': appliedDate.toIso8601String(),
      'remarks': remarks,
    };
  }

  factory DeputationApplication.fromMap(Map<String, dynamic> map) {
    return DeputationApplication(
      id: map['id'] as int?,
      openingId: map['opening_id'] as int,
      opening: DeputationOpening.fromMap(map),
      applicantUin: map['applicant_uin'] as String,
      status: ApplicationStatus.fromString(map['status'] as String),
      appliedDate: DateTime.parse(map['applied_date'] as String),
      remarks: map['remarks'] as String?,
      applicantName: map['applicant_name'] as String?,
      applicantRank: map['applicant_rank'] as String?,
      applicantUnit: map['applicant_unit'] as String?,
      experience: map['experience'] as int?,
    );
  }
} 