class UserProfile {
  final String uidno;
  final String name;
  final String rank;
  final String rankName;
  final String? eMail;
  final String? mobno;
  final String? paddress;
  final String? photo;
  final String? gen;
  final String? fathername;
  final String? mothername;
  final String? bloodgr;
  final String? dob;
  final String? marital_st;
  final String? homephone;
  final String? district;
  final String? state;
  final String? pincode;
  final String? firstDoj;
  final String? doretd;

  UserProfile({
    required this.uidno,
    required this.name,
    required this.rank,
    required this.rankName,
    this.eMail,
    this.mobno,
    this.paddress,
    this.photo,
    this.gen,
    this.fathername,
    this.mothername,
    this.bloodgr,
    this.dob,
    this.marital_st,
    this.homephone,
    this.district,
    this.state,
    this.pincode,
    this.firstDoj,
    this.doretd,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uidno: json['uidno'] ?? '',
      name: json['name'] ?? '',
      rank: json['rank']?.toString() ?? '',
      rankName: json['rank_name'] ?? 'Unknown Rank',
      eMail: json['eMail'],
      mobno: json['mobno'],
      paddress: json['paddress'],
      photo: json['photo'],
      gen: json['gen'],
      fathername: json['fathername'],
      mothername: json['mothername'],
      bloodgr: json['bloodgr'],
      dob: json['dob'],
      marital_st: json['marital_st'],
      homephone: json['homephone'],
      district: json['dist_nm'],
      state: json['state_nm'],
      pincode: json['pincode'],
      firstDoj: json['first_doj'],
      doretd: json['dor'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uidno': uidno,
      'name': name,
      'rank': rank,
      'rankName': rankName,
      'eMail': eMail,
      'mobno': mobno,
      'paddress': paddress,
      'photo': photo,
      'gen': gen,
      'fathername': fathername,
      'mothername': mothername,
      'bloodgr': bloodgr,
      'dob': dob,
      'marital_st': marital_st,
      'homephone': homephone,
      'district': district,
      'state': state,
      'pincode': pincode,
      'first_doj': firstDoj,
      'doretd': doretd,
    };
  }

  UserProfile copyWith({
    String? name,
    String? eMail,
    String? mobno,
    String? paddress,
    String? photo,
    String? rank,
    String? rankName,
    String? district,
    String? state,
    String? pincode,
    String? firstDoj,
    String? doretd,
  }) {
    return UserProfile(
      uidno: this.uidno,
      name: name ?? this.name,
      rank: rank ?? this.rank,
      rankName: rankName ?? this.rankName,
      eMail: eMail ?? this.eMail,
      mobno: mobno ?? this.mobno,
      paddress: paddress ?? this.paddress,
      photo: photo ?? this.photo,
      gen: this.gen,
      fathername: this.fathername,
      mothername: this.mothername,
      bloodgr: this.bloodgr,
      dob: this.dob,
      marital_st: this.marital_st,
      homephone: this.homephone,
      district: district ?? this.district,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      firstDoj: firstDoj ?? this.firstDoj,
      doretd: doretd ?? this.doretd,
    );
  }

  DateTime? get dateOfJoining => firstDoj != null ? DateTime.parse(firstDoj!) : null;
  DateTime? get dateOfRetirement => doretd != null ? DateTime.parse(doretd!) : null;

  String get lengthOfService {
    if (dateOfJoining == null) return 'N/A';
    final now = DateTime.now();
    final difference = now.difference(dateOfJoining!);
    final years = difference.inDays ~/ 365;
    final months = (difference.inDays % 365) ~/ 30;
    return '$years years, $months months';
  }

  String get remainingService {
    if (dateOfRetirement == null) return 'N/A';
    final now = DateTime.now();
    if (now.isAfter(dateOfRetirement!)) return 'Retired';
    final difference = dateOfRetirement!.difference(now);
    final years = difference.inDays ~/ 365;
    final months = (difference.inDays % 365) ~/ 30;
    return '$years years, $months months';
  }
} 