class Ledger {
  final String id;
  final String name;
  final String groupId;
  final double openingBalance;
  final double currentBalance;
  final DateTime createdAt;

  Ledger({
    required this.id,
    required this.name,
    required this.groupId,
    required this.openingBalance,
    required this.currentBalance,
    required this.createdAt,
  });

  factory Ledger.fromJson(Map<String, dynamic> json) {
    return Ledger(
      id: json['id'].toString(),
      name: json['name'] as String,
      groupId: json['group_id'].toString(),
      openingBalance: (json['opening_balance'] as num).toDouble(),
      currentBalance: (json['current_balance'] as num).toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
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
