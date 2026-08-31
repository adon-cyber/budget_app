class Bill {
  final String id;
  final String ledgerId;
  final String? ledgerName;
  final String referenceNo;
  final DateTime billDate;
  final DateTime dueDate;
  final double totalAmount;
  final double clearedAmount;
  final double pendingAmount;
  final String? agingBracket;
  final String? billType; // 'receivable' or 'payable'
  final DateTime createdAt;

  Bill({
    required this.id,
    required this.ledgerId,
    this.ledgerName,
    required this.referenceNo,
    required this.billDate,
    required this.dueDate,
    required this.totalAmount,
    required this.clearedAmount,
    required this.pendingAmount,
    this.agingBracket,
    this.billType,
    required this.createdAt,
  });

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['id']?.toString() ?? '',
      ledgerId: json['ledger_id']?.toString() ?? '',
      ledgerName: json['ledger_name'] as String?,
      referenceNo: json['reference_no'] as String? ?? '',
      billDate: json['bill_date'] != null
          ? DateTime.parse(json['bill_date'] as String)
          : DateTime.now(),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : DateTime.now(),
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      clearedAmount: (json['cleared_amount'] as num?)?.toDouble() ?? 0.0,
      pendingAmount: (json['pending_amount'] as num?)?.toDouble() ?? 0.0,
      agingBracket: json['aging_bracket'] as String?,
      billType: json['bill_type'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ledger_id': ledgerId,
      'reference_no': referenceNo,
      'bill_date': billDate.toIso8601String().split('T')[0],
      'due_date': dueDate.toIso8601String().split('T')[0],
      'total_amount': totalAmount,
      'cleared_amount': clearedAmount,
      if (billType != null) 'bill_type': billType,
    };
  }
}
