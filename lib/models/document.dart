class Document {
  final int? id;
  final String uidno;
  final String title;
  final String type;
  final String filePath;
  final DateTime uploadDate;
  final DateTime? expiryDate;
  final String verificationStatus;

  Document({
    this.id,
    required this.uidno,
    required this.title,
    required this.type,
    required this.filePath,
    required this.uploadDate,
    this.expiryDate,
    required this.verificationStatus,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'],
      uidno: json['uidno'],
      title: json['title'],
      type: json['type'],
      filePath: json['file_path'],
      uploadDate: DateTime.parse(json['upload_date']),
      expiryDate: json['expiry_date'] != null 
          ? DateTime.parse(json['expiry_date']) 
          : null,
      verificationStatus: json['verification_status'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'uidno': uidno,
    'title': title,
    'type': type,
    'file_path': filePath,
    'upload_date': uploadDate.toIso8601String(),
    'expiry_date': expiryDate?.toIso8601String(),
    'verification_status': verificationStatus,
  };
} 