class AppNotification {
  final int? id;
  final String uidno;
  final String title;
  final String message;
  final String type;
  final DateTime date;
  final bool read;

  AppNotification({
    this.id,
    required this.uidno,
    required this.title,
    required this.message,
    required this.type,
    required this.date,
    required this.read,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      uidno: json['uidno'],
      title: json['title'],
      message: json['message'],
      type: json['type'],
      date: DateTime.parse(json['date']),
      read: json['read'] == 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'uidno': uidno,
    'title': title,
    'message': message,
    'type': type,
    'date': date.toIso8601String(),
    'read': read ? 1 : 0,
  };
} 