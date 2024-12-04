class FamilyMember {
  final int? sno;
  final String? uidno;
  final String? name;
  final DateTime? dob;
  final double? relationship;
  final String? dependent;
  final String? income;
  final String? maritalStatus;
  final String? disability;
  final String? fmemberStatus;
  final String? dod;
  final String? memberGovtService;
  final String? departmentName;
  final String? memberGender;
  final String? ayushmanEligibility;
  final String? familyMemAadhar;
  final String? remarks;

  FamilyMember({
    this.sno,
    this.uidno,
    this.name,
    this.dob,
    this.relationship,
    this.dependent,
    this.income,
    this.maritalStatus,
    this.disability,
    this.fmemberStatus,
    this.dod,
    this.memberGovtService,
    this.departmentName,
    this.memberGender,
    this.ayushmanEligibility,
    this.familyMemAadhar,
    this.remarks,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      sno: json['sno'],
      uidno: json['uidno'],
      name: json['name'],
      dob: json['dob'] != null ? DateTime.parse(json['dob']) : null,
      relationship: json['relationship']?.toDouble(),
      dependent: json['dependent'],
      income: json['income'],
      maritalStatus: json['maritalStatus'],
      disability: json['disability'],
      fmemberStatus: json['fmember_status'],
      dod: json['dod'],
      memberGovtService: json['member_govt_service'],
      departmentName: json['department_name'],
      memberGender: json['Member_Gender'],
      ayushmanEligibility: json['Ayushman_eligibility'],
      familyMemAadhar: json['family_mem_aadhar'],
      remarks: json['Remarks'],
    );
  }

  String getRelationshipText() {
    final relationshipMap = {
      1.0: 'Mother',
      2.0: 'Father',
      3.0: 'Brother',
      4.0: 'Sister',
      5.0: 'Son',
      6.0: 'Daughter',
      7.0: 'Husband',
      8.0: 'Wife',
      9.0: 'Step Mother',
      10.0: 'Step Father',
      11.0: 'Step Sister',
      12.0: 'Step Son',
      13.0: 'Step Daughter',
      14.0: 'Adopted Son',
      15.0: 'Adopted Daughter',
      16.0: 'Widow of deceased Son',
      17.0: 'Grand Father',
      18.0: 'Grand Mother',
      19.0: 'Father in Law',
      20.0: 'Mother in Law',
      21.0: 'Widow Daughter',
      22.0: 'Widow Sister',
    };
    return relationshipMap[relationship] ?? 'Unknown';
  }
} 