class VoucherItem {
  final String id;
  final String voucherId;
  final String ledgerId;
  final double debit;
  final double credit;
  final String? description;

  VoucherItem({
    required this.id,
    required this.voucherId,
    required this.ledgerId,
    required this.debit,
    required this.credit,
    this.description,
  });

  factory VoucherItem.fromJson(Map<String, dynamic> json) {
    return VoucherItem(
      id: json['id'].toString(),
      voucherId: json['voucher_id'].toString(),
      ledgerId: json['ledger_id'].toString(),
      debit: (json['debit'] as num).toDouble(),
      credit: (json['credit'] as num).toDouble(),
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ledger_id': ledgerId,
      'debit': debit,
      'credit': credit,
      'description': description,
    };
  }
}
