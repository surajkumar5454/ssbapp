class Training {
  final String uidno;
  final int? course;
  final String? fromDate;
  final String? toDate;
  final int? trainingCenter;
  final String? position;
  final String? prof;
  final String? theory;
  final String? instruction_ability;
  final String? remarks;
  final String? course_nm;
  final String? duration;
  final String? category;

  Training({
    required this.uidno,
    this.course,
    this.fromDate,
    this.toDate,
    this.trainingCenter,
    this.position,
    this.prof,
    this.theory,
    this.instruction_ability,
    this.remarks,
    this.course_nm,
    this.duration,
    this.category,
  });

  factory Training.fromJson(Map<String, dynamic> json) {
    return Training(
      uidno: json['uidno'] ?? '',
      course: json['course'],
      fromDate: json['fromDate'],
      toDate: json['toDate'],
      trainingCenter: json['trainingCenter'],
      position: json['position'],
      prof: json['prof'],
      theory: json['theory'],
      instruction_ability: json['instruction_ability'],
      remarks: json['remarks'],
      course_nm: json['course_nm'],
      duration: json['duration'],
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uidno': uidno,
      'course': course,
      'fromDate': fromDate,
      'toDate': toDate,
      'trainingCenter': trainingCenter,
      'position': position,
      'prof': prof,
      'theory': theory,
      'instruction_ability': instruction_ability,
      'remarks': remarks,
      'course_nm': course_nm,
      'duration': duration,
      'category': category,
    };
  }
} 