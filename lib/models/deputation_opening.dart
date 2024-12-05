enum DeputationStatus {
  active('Active'),
  closed('Closed'),
  cancelled('Cancelled');

  final String label;
  const DeputationStatus(this.label);

  static DeputationStatus fromString(String status) {
    return DeputationStatus.values.firstWhere(
      (e) => e.label.toLowerCase() == status.toLowerCase(),
      orElse: () => DeputationStatus.active,
    );
  }
}

class DeputationOpening {
  final String? id;
  final String title;
  final String description;
  final String organization;
  final String notificationNumber;
  final DateTime notificationDate;
  final DateTime startDate;
  final DateTime endDate;
  final String? requiredRank;
  final String? requiredRankName;
  final String? requiredBranch;
  final String? requiredBranchName;
  final int? requiredExperience;
  final String? otherCriteria;
  final DeputationStatus status;
  final String? experienceFromRank;
  final String? experienceFromRankName;

  DeputationOpening({
    this.id,
    required this.title,
    required this.description,
    required this.organization,
    required this.notificationNumber,
    required this.notificationDate,
    required this.startDate,
    required this.endDate,
    this.requiredRank,
    this.requiredRankName,
    this.requiredBranch,
    this.requiredBranchName,
    this.requiredExperience,
    this.otherCriteria,
    this.status = DeputationStatus.active,
    this.experienceFromRank,
    this.experienceFromRankName,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'organization': organization,
      'notification_number': notificationNumber,
      'notification_date': notificationDate.toIso8601String(),
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'required_rank': requiredRank,
      'required_rank_name': requiredRankName,
      'required_branch': requiredBranch,
      'required_branch_name': requiredBranchName,
      'required_experience': requiredExperience,
      'other_criteria': otherCriteria,
      'status': status.name,
      'experience_from_rank': experienceFromRank,
      'experience_from_rank_name': experienceFromRankName,
    };
  }

  factory DeputationOpening.fromMap(Map<String, dynamic> map) {
    return DeputationOpening(
      id: map['id']?.toString(),
      title: map['title'],
      description: map['description'],
      organization: map['organization'],
      notificationNumber: map['notification_number'],
      notificationDate: DateTime.parse(map['notification_date']),
      startDate: DateTime.parse(map['start_date']),
      endDate: DateTime.parse(map['end_date']),
      requiredRank: map['required_rank'],
      requiredRankName: map['required_rank_name'],
      requiredBranch: map['required_branch'],
      requiredBranchName: map['required_branch_name'],
      requiredExperience: map['required_experience'],
      otherCriteria: map['other_criteria'],
      status: DeputationStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => DeputationStatus.active,
      ),
      experienceFromRank: map['experience_from_rank'],
      experienceFromRankName: map['experience_from_rank_name'],
    );
  }
} 