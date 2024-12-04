class Training {
  final String? uidno;
  final String? course;
  final String? course_nm;
  final String? fromDate;
  final String? toDate;
  final String? duration;
  final String? category;
  final String? position;
  final String? remarks;

  Training({
    this.uidno,
    this.course,
    this.course_nm,
    this.fromDate,
    this.toDate,
    this.duration,
    this.category,
    this.position,
    this.remarks,
  });

  factory Training.fromJson(Map<String, dynamic> json) {
    return Training(
      uidno: json['uidno'],
      course: json['course']?.toString(),
      course_nm: json['course_nm'],
      fromDate: json['fromDate'],
      toDate: json['toDate'],
      duration: json['duration']?.toString(),
      category: json['category'],
      position: json['position'],
      remarks: json['remarks'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uidno': uidno,
      'course': course,
      'course_nm': course_nm,
      'fromDate': fromDate,
      'toDate': toDate,
      'duration': duration,
      'category': category,
      'position': position,
      'remarks': remarks,
    };
  }
} 