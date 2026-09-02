class Employee {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? department;
  final String? designation;
  final double baseSalary;
  final double allowances;
  final double deductions;
  final String? bankAccount;
  final String? ledgerId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Employee({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.department,
    this.designation,
    required this.baseSalary,
    required this.allowances,
    required this.deductions,
    this.bankAccount,
    this.ledgerId,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      department: json['department'] as String?,
      designation: json['designation'] as String?,
      baseSalary: (json['base_salary'] as num?)?.toDouble() ?? 0.0,
      allowances: (json['allowances'] as num?)?.toDouble() ?? 0.0,
      deductions: (json['deductions'] as num?)?.toDouble() ?? 0.0,
      bankAccount: json['bank_account'] as String?,
      ledgerId: json['ledger_id']?.toString(),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'name': name,
      'email': email,
      if (phone != null) 'phone': phone,
      if (department != null) 'department': department,
      if (designation != null) 'designation': designation,
      'base_salary': baseSalary,
      'allowances': allowances,
      'deductions': deductions,
      if (bankAccount != null) 'bank_account': bankAccount,
      if (ledgerId != null) 'ledger_id': ledgerId,
      'is_active': isActive,
    };
  }

  Employee copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? department,
    String? designation,
    double? baseSalary,
    double? allowances,
    double? deductions,
    String? bankAccount,
    String? ledgerId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      department: department ?? this.department,
      designation: designation ?? this.designation,
      baseSalary: baseSalary ?? this.baseSalary,
      allowances: allowances ?? this.allowances,
      deductions: deductions ?? this.deductions,
      bankAccount: bankAccount ?? this.bankAccount,
      ledgerId: ledgerId ?? this.ledgerId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
