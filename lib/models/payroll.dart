class PayrollItem {
  final String id;
  final String payrollId;
  final String employeeId;
  final String? employeeName;
  final double baseSalary;
  final double allowances;
  final double deductions;
  final double netPay;
  final DateTime createdAt;

  PayrollItem({
    required this.id,
    required this.payrollId,
    required this.employeeId,
    this.employeeName,
    required this.baseSalary,
    required this.allowances,
    required this.deductions,
    required this.netPay,
    required this.createdAt,
  });

  factory PayrollItem.fromJson(Map<String, dynamic> json) {
    // If employee details are joined, handle them safely
    String? empName;
    if (json['employees'] != null && json['employees'] is Map) {
      empName = json['employees']['name'] as String?;
    } else if (json['employee_name'] != null) {
      empName = json['employee_name'] as String?;
    }

    return PayrollItem(
      id: json['id']?.toString() ?? '',
      payrollId: json['payroll_id']?.toString() ?? '',
      employeeId: json['employee_id']?.toString() ?? '',
      employeeName: empName,
      baseSalary: (json['base_salary'] as num?)?.toDouble() ?? 0.0,
      allowances: (json['allowances'] as num?)?.toDouble() ?? 0.0,
      deductions: (json['deductions'] as num?)?.toDouble() ?? 0.0,
      netPay: (json['net_pay'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'payroll_id': payrollId,
      'employee_id': employeeId,
      'base_salary': baseSalary,
      'allowances': allowances,
      'deductions': deductions,
      'net_pay': netPay,
    };
  }
}

class Payroll {
  final String id;
  final String payPeriod; // e.g. "2026-09"
  final double totalAmount;
  final String status; // 'draft', 'posted'
  final String? voucherId;
  final DateTime createdAt;
  final List<PayrollItem> items;

  Payroll({
    required this.id,
    required this.payPeriod,
    required this.totalAmount,
    required this.status,
    this.voucherId,
    required this.createdAt,
    required this.items,
  });

  factory Payroll.fromJson(Map<String, dynamic> json) {
    var rawItems = json['payroll_items'];
    List<PayrollItem> parsedItems = [];
    if (rawItems != null && rawItems is List) {
      parsedItems = rawItems
          .map((item) => PayrollItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return Payroll(
      id: json['id']?.toString() ?? '',
      payPeriod: json['pay_period'] as String? ?? '',
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'draft',
      voucherId: json['voucher_id']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      items: parsedItems,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'pay_period': payPeriod,
      'total_amount': totalAmount,
      'status': status,
      if (voucherId != null) 'voucher_id': voucherId,
    };
  }

  Payroll copyWith({
    String? id,
    String? payPeriod,
    double? totalAmount,
    String? status,
    String? voucherId,
    DateTime? createdAt,
    List<PayrollItem>? items,
  }) {
    return Payroll(
      id: id ?? this.id,
      payPeriod: payPeriod ?? this.payPeriod,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      voucherId: voucherId ?? this.voucherId,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
    );
  }
}
