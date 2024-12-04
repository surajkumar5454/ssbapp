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
    );
  }
} 