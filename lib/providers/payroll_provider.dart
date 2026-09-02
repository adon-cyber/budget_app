import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/employee.dart';
import '../models/payroll.dart';
import 'voucher_provider.dart';

class PayrollProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final VoucherProvider _voucherProvider;

  PayrollProvider(this._voucherProvider);

  List<Payroll> _payrolls = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Payroll> get payrolls => _payrolls;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchPayrolls() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from('payrolls')
          .select('*, payroll_items(*, employees(name))')
          .order('created_at', ascending: false);

      _payrolls = (response as List)
          .map((json) => Payroll.fromJson(json))
          .toList();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> generatePayroll(String payPeriod) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Pull all active employees
      final empResponse = await _supabase
          .from('employees')
          .select()
          .eq('is_active', true);

      final List<Employee> activeEmployees = (empResponse as List)
          .map((json) => Employee.fromJson(json))
          .toList();

      if (activeEmployees.isEmpty) {
        throw Exception('No active employees found to generate payroll.');
      }

      // 2. Calculate total amount and individual items
      double totalPayrollAmount = 0.0;
      List<Map<String, dynamic>> itemsData = [];

      for (var emp in activeEmployees) {
        double baseSalary = emp.baseSalary;
        double allowances = emp.allowances;
        double deductions = emp.deductions;
        double netPay = baseSalary + allowances - deductions;

        totalPayrollAmount += netPay;

        itemsData.add({
          'employee_id': emp.id,
          'base_salary': baseSalary,
          'allowances': allowances,
          'deductions': deductions,
          'net_pay': netPay,
        });
      }

      // 3. Save record into payrolls table
      final payrollResponse = await _supabase
          .from('payrolls')
          .insert({
            'pay_period': payPeriod,
            'total_amount': totalPayrollAmount,
            'status': 'draft',
          })
          .select()
          .single();

      final payrollId = payrollResponse['id'].toString();

      // 4. Save records into payroll_items table
      for (var item in itemsData) {
        item['payroll_id'] = payrollId;
        await _supabase.from('payroll_items').insert(item);
      }

      // 5. Refresh list
      await fetchPayrolls();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> postPayrollToAccounting(String payrollId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Fetch payroll and its items with employee details
      final payrollResponse = await _supabase
          .from('payrolls')
          .select('*, payroll_items(*, employees(name, ledger_id))')
          .eq('id', payrollId)
          .single();

      final payroll = Payroll.fromJson(payrollResponse);

      if (payroll.status == 'processed' || payroll.status == 'posted') {
        throw Exception('Payroll is already processed or posted.');
      }

      final rawItems = payrollResponse['payroll_items'] as List;

      // Calculate totals across all items
      double totalGrossPay = 0.0;
      double totalDeductions = 0.0;
      double totalNetPay = 0.0;

      for (var rawItem in rawItems) {
        final baseSalary = (rawItem['base_salary'] as num?)?.toDouble() ?? 0.0;
        final allowances = (rawItem['allowances'] as num?)?.toDouble() ?? 0.0;
        final gross = baseSalary + allowances;
        final deductions = (rawItem['deductions'] as num?)?.toDouble() ?? 0.0;
        final netPay =
            (rawItem['net_pay'] as num?)?.toDouble() ?? (gross - deductions);

        totalGrossPay += gross;
        totalDeductions += deductions;
        totalNetPay += netPay;
      }

      // 2. Fetch specific HR Ledgers by their exact names:
      // Debit: 'Salaries & Wages' (Amount = Total Gross Pay)
      // Credit: 'PAYE / Tax Payable' (Amount = Total Deductions)
      // Credit: 'Net Salary Payable' (Amount = Total Net Pay)
      final ledgersResponse = await _supabase
          .from('ledgers')
          .select('id, name');
      final ledgers = ledgersResponse as List;

      String? getLedgerIdByName(String name) {
        final match = ledgers.firstWhere(
          (l) => (l['name'] as String).toLowerCase() == name.toLowerCase(),
          orElse: () => null,
        );
        return match != null ? match['id'].toString() : null;
      }

      final salariesWagesId = getLedgerIdByName('Salaries & Wages');
      final payeTaxPayableId = getLedgerIdByName('PAYE / Tax Payable');
      final netSalaryPayableId = getLedgerIdByName('Net Salary Payable');

      if (salariesWagesId == null) {
        throw Exception(
          "Ledger 'Salaries & Wages' not found in Chart of Accounts.",
        );
      }
      if (payeTaxPayableId == null) {
        throw Exception(
          "Ledger 'PAYE / Tax Payable' not found in Chart of Accounts.",
        );
      }
      if (netSalaryPayableId == null) {
        throw Exception(
          "Ledger 'Net Salary Payable' not found in Chart of Accounts.",
        );
      }

      // Construct balanced voucher payload (Total Debits must exactly equal Total Credits)
      // Total Debits: Salaries & Wages = totalGrossPay
      // Total Credits: PAYE / Tax Payable = totalDeductions, Net Salary Payable = totalNetPay
      // Note: totalGrossPay should equal totalDeductions + totalNetPay.
      List<Map<String, dynamic>> voucherItems = [
        {
          'ledger_id': salariesWagesId,
          'debit': totalGrossPay,
          'credit': 0.0,
          'description': 'Salaries & Wages for period ${payroll.payPeriod}',
        },
        {
          'ledger_id': payeTaxPayableId,
          'debit': 0.0,
          'credit': totalDeductions,
          'description': 'PAYE / Tax Payable for period ${payroll.payPeriod}',
        },
        {
          'ledger_id': netSalaryPayableId,
          'debit': 0.0,
          'credit': totalNetPay,
          'description': 'Net Salary Payable for period ${payroll.payPeriod}',
        },
      ];

      // 3. Create Voucher using VoucherProvider
      final voucherNumber =
          'PAY-${payroll.payPeriod}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

      final voucherSuccess = await _voucherProvider.createVoucher(
        voucherNumber: voucherNumber,
        voucherType: 'Journal',
        date: DateTime.now(),
        narration: 'Payroll auto-posting for period ${payroll.payPeriod}',
        items: voucherItems,
      );

      if (!voucherSuccess) {
        throw Exception(
          'Failed to create accounting voucher: ${_voucherProvider.errorMessage}',
        );
      }

      // Get the newly created voucher id
      final createdVoucher = await _supabase
          .from('vouchers')
          .select('id')
          .eq('voucher_number', voucherNumber)
          .single();

      final voucherId = createdVoucher['id'].toString();

      // 4. Mark the payroll record status as 'processed' and link the voucher_id
      await _supabase
          .from('payrolls')
          .update({'status': 'processed', 'voucher_id': voucherId})
          .eq('id', payrollId);

      await fetchPayrolls();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
