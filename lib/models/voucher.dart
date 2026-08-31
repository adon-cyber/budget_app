import 'voucher_item.dart';

class Voucher {
  final String id;
  final String voucherNumber;
  final String voucherType; // 'Payment', 'Receipt', 'Contra', 'Journal'
  final DateTime date;
  final String? narration;
  final List<VoucherItem> items;
  final DateTime createdAt;

  Voucher({
    required this.id,
    required this.voucherNumber,
    required this.voucherType,
    required this.date,
    this.narration,
    required this.items,
    required this.createdAt,
  });

  factory Voucher.fromJson(Map<String, dynamic> json) {
    var itemsList = <VoucherItem>[];
    if (json['voucher_items'] != null) {
      itemsList = (json['voucher_items'] as List)
          .map((item) => VoucherItem.fromJson(item))
          .toList();
    }
    return Voucher(
      id: json['id'].toString(),
      voucherNumber: json['voucher_number'] as String,
      voucherType: json['voucher_type'] as String,
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : DateTime.now(),
      narration: json['narration'] as String?,
      items: itemsList,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'voucher_number': voucherNumber,
      'voucher_type': voucherType,
      'date': date.toIso8601String().split('T')[0],
      'narration': narration,
    };
  }
}
