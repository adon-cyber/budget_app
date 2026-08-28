class TransactionModel {
  final String id;
  final String title;
  final double amount;
  final String category;
  final String type; // 'income' | 'expense'
  final DateTime createdAt;
  final String? receiptUrl;

  TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.type,
    required this.createdAt,
    this.receiptUrl,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'].toString(),
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
      type: json['type'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      receiptUrl: json['receipt_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'amount': amount,
      'category': category,
      'type': type,
      'receipt_url': receiptUrl,
    };
  }
}
