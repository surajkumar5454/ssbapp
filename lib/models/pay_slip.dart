class PaySlip {
  final String id;
  final String month;
  final String year;
  final double basicPay;
  final double allowances;
  final double deductions;
  final double netPay;

  PaySlip({
    required this.id,
    required this.month,
    required this.year,
    required this.basicPay,
    required this.allowances,
    required this.deductions,
    required this.netPay,
  });

  factory PaySlip.fromJson(Map<String, dynamic> json) {
    return PaySlip(
      id: json['id'],
      month: json['month'],
      year: json['year'],
      basicPay: json['basicPay'].toDouble(),
      allowances: json['allowances'].toDouble(),
      deductions: json['deductions'].toDouble(),
      netPay: json['netPay'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'month': month,
      'year': year,
      'basicPay': basicPay,
      'allowances': allowances,
      'deductions': deductions,
      'netPay': netPay,
    };
  }
} 