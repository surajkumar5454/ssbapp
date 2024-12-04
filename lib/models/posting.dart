class Posting {
  final String uidno;
  final String? regno;
  final String? name;
  final int? unitCode;
  final String? unitName;
  final int? rankCode;
  final String? rankName;
  final int? branchCode;
  final String? branchName;
  final String? typeofjoin;
  final DateTime? dateofjoin;
  final DateTime? dateofrelv;
  final String? joiningremark;
  final String? status;
  final String? jodrnondt;

  Posting({
    required this.uidno,
    this.regno,
    this.name,
    this.unitCode,
    this.unitName,
    this.rankCode,
    this.rankName,
    this.branchCode,
    this.branchName,
    this.typeofjoin,
    this.dateofjoin,
    this.dateofrelv,
    this.joiningremark,
    this.status,
    this.jodrnondt,
  });

  factory Posting.fromJson(Map<String, dynamic> json) {
    return Posting(
      uidno: json['uidno'] ?? '',
      regno: json['regno'],
      name: json['name'],
      unitCode: json['unit'],
      unitName: json['unit_nm'],
      rankCode: json['rank'],
      rankName: json['rnk_nm'],
      branchCode: json['branch'],
      branchName: json['brn_nm'],
      typeofjoin: json['typeofjoin'],
      dateofjoin: json['dateofjoin'] != null 
          ? DateTime.parse(json['dateofjoin']) 
          : null,
      dateofrelv: json['dateofrelv'] != null 
          ? DateTime.parse(json['dateofrelv']) 
          : null,
      joiningremark: json['joiningremark'],
      status: json['status'],
      jodrnondt: json['jodrnondt'],
    );
  }
} 