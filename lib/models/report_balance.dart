class ReportBalance {
  final String ledgerId;
  final String ledgerName;
  final String groupName;
  final String nature;
  final double currentBalance;
  final String defaultBalanceType;

  ReportBalance({
    required this.ledgerId,
    required this.ledgerName,
    required this.groupName,
    required this.nature,
    required this.currentBalance,
    required this.defaultBalanceType,
  });

  factory ReportBalance.fromJson(Map<String, dynamic> json) {
    return ReportBalance(
      ledgerId:
          json['ledgerId']?.toString() ?? json['ledger_id']?.toString() ?? '',
      ledgerName:
          json['ledgerName'] as String? ?? json['ledger_name'] as String? ?? '',
      groupName:
          json['groupName'] as String? ?? json['group_name'] as String? ?? '',
      nature: json['nature'] as String? ?? '',
      currentBalance:
          (json['currentBalance'] as num?)?.toDouble() ??
          (json['current_balance'] as num?)?.toDouble() ??
          0.0,
      defaultBalanceType:
          json['defaultBalanceType'] as String? ??
          json['default_balance_type'] as String? ??
          '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ledgerId': ledgerId,
      'ledgerName': ledgerName,
      'groupName': groupName,
      'nature': nature,
      'currentBalance': currentBalance,
      'defaultBalanceType': defaultBalanceType,
    };
  }
}
