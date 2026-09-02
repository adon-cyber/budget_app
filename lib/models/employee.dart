class Employee {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? department;
  final String? designation;
  final double baseSalary;
  final double allowances;
  final double deductions;
  final String? bankAccount;
  final String? ledgerId;
  final String? costCenterId;
  final String? employeeCode;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Employee({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.department,
    this.designation,
    required this.baseSalary,
    required this.allowances,
    required this.deductions,
    this.bankAccount,
    this.ledgerId,
    this.costCenterId,
    this.employeeCode,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  String get name => '$firstName $lastName'.trim();

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id']?.toString() ?? '',
      firstName: json['first_name'] as String? ?? json['name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      department: json['department'] as String?,
      designation: json['designation'] as String?,
      baseSalary: (json['base_salary'] as num?)?.toDouble() ?? 0.0,
      allowances: (json['allowances'] as num?)?.toDouble() ?? 0.0,
      deductions: (json['deductions'] as num?)?.toDouble() ?? 0.0,
      bankAccount: json['bank_account'] as String?,
      ledgerId: json['ledger_id']?.toString(),
      costCenterId: json['cost_center_id']?.toString(),
      employeeCode: json['employee_code'] as String?,
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
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      if (phone != null) 'phone': phone,
      if (department != null) 'department': department,
      if (designation != null) 'designation': designation,
      'base_salary': baseSalary,
      'allowances': allowances,
      'deductions': deductions,
      if (bankAccount != null) 'bank_account': bankAccount,
      if (ledgerId != null) 'ledger_id': ledgerId,
      'cost_center_id': costCenterId?.isNotEmpty == true ? costCenterId : null,
      'employee_code':
          employeeCode ??
          'EMP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      'is_active': isActive,
    };
  }

  Employee copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? department,
    String? designation,
    double? baseSalary,
    double? allowances,
    double? deductions,
    String? bankAccount,
    String? ledgerId,
    String? costCenterId,
    String? employeeCode,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Employee(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      department: department ?? this.department,
      designation: designation ?? this.designation,
      baseSalary: baseSalary ?? this.baseSalary,
      allowances: allowances ?? this.allowances,
      deductions: deductions ?? this.deductions,
      bankAccount: bankAccount ?? this.bankAccount,
      ledgerId: ledgerId ?? this.ledgerId,
      costCenterId: costCenterId ?? this.costCenterId,
      employeeCode: employeeCode ?? this.employeeCode,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
