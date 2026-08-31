class AccountGroup {
  final String id;
  final String name;
  final String? parentId;
  final String type; // 'asset', 'liability', 'income', 'expense'
  final DateTime createdAt;

  AccountGroup({
    required this.id,
    required this.name,
    this.parentId,
    required this.type,
    required this.createdAt,
  });

  factory AccountGroup.fromJson(Map<String, dynamic> json) {
    return AccountGroup(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      parentId: json['parent_id']?.toString(),
      type: json['type']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'parent_id': parentId,
      'type': type,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
