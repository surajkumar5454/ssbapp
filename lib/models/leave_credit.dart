class LeaveCredit {
  final int id;
  final String uidno;
  final DateTime dateFrom;
  final DateTime dateTo;
  
  // EL (Earned Leave)
  final String typeEl;
  final int previousEl;
  final int creditEl;
  final int availEl;
  final int balanceEl;
  
  // HPL (Half Pay Leave)
  final String typeHpl;
  final int previousHpl;
  final int creditHpl;
  final int availHpl;
  final int balanceHpl;
  
  // Current Balances
  final int hplBalance;
  final int elBalance;
  
  // CL (Casual Leave)
  final int previousCl;
  final int creditCl;
  final int availCl;
  final int balanceCl;
  
  // Additional Info
  final String? entryType;
  final String? ltc;
  final String? kindOfLeave;
  final bool isApproved;
  final String? approvedByRank;
  final String? approvedByUidno;
  final String? approvedByName;
  final DateTime? approvedOn;

  LeaveCredit({
    required this.id,
    required this.uidno,
    required this.dateFrom,
    required this.dateTo,
    required this.typeEl,
    required this.previousEl,
    required this.creditEl,
    required this.availEl,
    required this.balanceEl,
    required this.typeHpl,
    required this.previousHpl,
    required this.creditHpl,
    required this.availHpl,
    required this.balanceHpl,
    required this.hplBalance,
    required this.elBalance,
    required this.previousCl,
    required this.creditCl,
    required this.availCl,
    required this.balanceCl,
    this.entryType,
    this.ltc,
    this.kindOfLeave,
    this.isApproved = false,
    this.approvedByRank,
    this.approvedByUidno,
    this.approvedByName,
    this.approvedOn,
  });

  factory LeaveCredit.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(String? dateStr) {
      if (dateStr == null) throw FormatException('Date string is null');
      
      // Try dd/MM/yyyy format first
      try {
        final parts = dateStr.split('/');
        if (parts.length == 3) {
          return DateTime(
            int.parse(parts[2]), // year
            int.parse(parts[1]), // month
            int.parse(parts[0]), // day
          );
        }
      } catch (e) {
        print('Error parsing date $dateStr in dd/MM/yyyy format: $e');
      }

      // Try standard ISO format
      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        print('Error parsing date $dateStr in ISO format: $e');
        rethrow;
      }
    }

    return LeaveCredit(
      id: map['id'] as int,
      uidno: map['uidno'] as String,
      dateFrom: parseDate(map['dt_frm'] as String),
      dateTo: parseDate(map['dt_to'] as String),
      typeEl: map['type_el'] as String,
      previousEl: map['prvs_el'] as int,
      creditEl: map['credit_el'] as int,
      availEl: map['avail_el'] as int,
      balanceEl: map['bal_el'] as int,
      typeHpl: map['type_hpl'] as String,
      previousHpl: map['prvs_hpl'] as int,
      creditHpl: map['credit_hpl'] as int,
      availHpl: map['avail_hpl'] as int,
      balanceHpl: map['bal_hpl'] as int,
      hplBalance: map['hpl_bal'] as int,
      elBalance: map['el_bal'] as int,
      previousCl: map['prvs_cl'] as int,
      creditCl: map['credit_cl'] as int,
      availCl: map['avail_cl'] as int,
      balanceCl: map['bal_cl'] as int,
      entryType: map['entry_type'] as String?,
      ltc: map['ltc'] as String?,
      kindOfLeave: map['kind_of_leave'] as String?,
      isApproved: map['flgapproved'] == '1',
      approvedByRank: map['approvedbyrank'] as String?,
      approvedByUidno: map['approvedbyuidno'] as String?,
      approvedByName: map['approvedbyname'] as String?,
      approvedOn: map['approvedondt'] != null 
          ? parseDate(map['approvedondt'] as String)
          : null,
    );
  }
} 