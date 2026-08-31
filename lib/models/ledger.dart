class Ledger {
  final String id;
  final String name;
  final String groupId;
  final String? groupName;
  final double openingBalance;
  final double currentBalance;
  final DateTime createdAt;

  Ledger({
    required this.id,
    required this.name,
    required this.groupId,
    this.groupName,
    required this.openingBalance,
    required this.currentBalance,
    required this.createdAt,
  });

  factory Ledger.fromJson(Map<String, dynamic> json) {
    return Ledger(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      groupId: json['group_id']?.toString() ?? '',
      groupName: json['account_groups'] is Map
          ? (json['account_groups'] as Map)['name']?.toString()
          : json['group_name']?.toString(),
      openingBalance: (json['opening_balance'] as num?)?.toDouble() ?? 0.0,
      currentBalance: (json['current_balance'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'group_id': groupId,
      'opening_balance': openingBalance,
      'current_balance': currentBalance,
    };
  }
}
