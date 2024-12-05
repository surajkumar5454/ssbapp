import 'grievance_status.dart';

class Grievance {
  final int? id;
  final String? grievanceId;
  final String fromUin;
  final String toUin;
  final String subject;
  final String description;
  final String category;
  final String priority;
  final GrievanceStatus status;
  final DateTime submittedDate;
  final String? attachmentPath;
  final String? remarks;
  final String? handlerName;
  final String? handlerRank;
  final String? handlerUnit;
  final int? daysElapsed;
  final String? senderName;
  final String? senderRank;
  final String? senderUnit;

  Grievance({
    this.id,
    this.grievanceId,
    required this.fromUin,
    required this.toUin,
    required this.subject,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    required this.submittedDate,
    this.attachmentPath,
    this.remarks,
    this.handlerName,
    this.handlerRank,
    this.handlerUnit,
    this.daysElapsed,
    this.senderName,
    this.senderRank,
    this.senderUnit,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'grievance_id': grievanceId,
      'from_uin': fromUin,
      'to_uin': toUin,
      'subject': subject,
      'description': description,
      'category': category,
      'priority': priority,
      'status': status.label,
      'submitted_date': submittedDate.toIso8601String(),
      'attachment_path': attachmentPath,
      'remarks': remarks,
      'handler_name': handlerName,
      'handler_rank': handlerRank,
      'handler_unit': handlerUnit,
      'days_elapsed': daysElapsed,
      'sender_name': senderName,
      'sender_rank': senderRank,
      'sender_unit': senderUnit,
    };
  }

  factory Grievance.fromMap(Map<String, dynamic> map) {
    return Grievance(
      id: map['id'] as int?,
      grievanceId: map['grievance_id'] as String?,
      fromUin: map['from_uin'] as String,
      toUin: map['to_uin'] as String,
      subject: map['subject'] as String,
      description: map['description'] as String,
      category: map['category'] as String,
      priority: map['priority'] as String,
      status: GrievanceStatus.fromString(map['status'] as String),
      submittedDate: DateTime.parse(map['submitted_date'] as String),
      attachmentPath: map['attachment_path'] as String?,
      remarks: map['remarks'] as String?,
      handlerName: map['handler_name'] as String?,
      handlerRank: map['handler_rank'] as String?,
      handlerUnit: map['handler_unit'] as String?,
      daysElapsed: map['days_elapsed'] as int?,
      senderName: map['sender_name'] as String?,
      senderRank: map['sender_rank'] as String?,
      senderUnit: map['sender_unit'] as String?,
    );
  }

  @override
  String toString() {
    return 'Grievance{id: $id, grievanceId: $grievanceId, status: ${status.label}}';
  }
} 