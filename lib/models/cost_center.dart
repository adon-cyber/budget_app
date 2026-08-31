class CostCenter {
  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;

  CostCenter({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
  });

  factory CostCenter.fromJson(Map<String, dynamic> json) {
    return CostCenter(
      id: json['id'].toString(),
      name: json['name'] as String,
      description: json['description'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'description': description};
  }
}
