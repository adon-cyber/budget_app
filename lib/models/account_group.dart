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
      id: json['id'].toString(),
      name: json['name'] as String,
      parentId: json['parent_id']?.toString(),
      type: json['type'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
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
