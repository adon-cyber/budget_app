import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/employee.dart';

class EmployeeProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Employee> _employees = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Employee> get employees => _employees;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchEmployees() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from('employees')
          .select()
          .order('first_name', ascending: true);
      _employees = (response as List)
          .map((json) => Employee.fromJson(json))
          .toList();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addEmployee({
    required String name,
    required String email,
    String? phone,
    String? department,
    String? designation,
    required dynamic baseSalary,
    required dynamic allowances,
    required dynamic deductions,
    String? bankAccount,
    String? ledgerId,
    String? costCenterId,
    String? employeeCode,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final parts = name.trim().split(' ');
      final firstName = parts.isNotEmpty ? parts.first : name.trim();
      final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

      final parsedBaseSalary = baseSalary is num
          ? baseSalary.toDouble()
          : double.tryParse(baseSalary?.toString() ?? '') ?? 0.0;
      final parsedAllowances = allowances is num
          ? allowances.toDouble()
          : double.tryParse(allowances?.toString() ?? '') ?? 0.0;
      final parsedDeductions = deductions is num
          ? deductions.toDouble()
          : double.tryParse(deductions?.toString() ?? '') ?? 0.0;

      final employee = Employee(
        id: '',
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        department: department,
        designation: designation,
        baseSalary: parsedBaseSalary,
        allowances: parsedAllowances,
        deductions: parsedDeductions,
        bankAccount: bankAccount,
        ledgerId: ledgerId,
        costCenterId: costCenterId?.isNotEmpty == true ? costCenterId : null,
        employeeCode:
            employeeCode ??
            'EMP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final response = await _supabase
          .from('employees')
          .insert(employee.toJson())
          .select()
          .single();

      final newEmployee = Employee.fromJson(response);
      _employees.add(newEmployee);
      _employees.sort((a, b) => a.name.compareTo(b.name));
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateEmployee({
    required String id,
    required String name,
    required String email,
    String? phone,
    String? department,
    String? designation,
    required dynamic baseSalary,
    required dynamic allowances,
    required dynamic deductions,
    String? bankAccount,
    String? ledgerId,
    String? costCenterId,
    String? employeeCode,
    required bool isActive,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final parts = name.trim().split(' ');
      final firstName = parts.isNotEmpty ? parts.first : name.trim();
      final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

      final parsedBaseSalary = baseSalary is num
          ? baseSalary.toDouble()
          : double.tryParse(baseSalary?.toString() ?? '') ?? 0.0;
      final parsedAllowances = allowances is num
          ? allowances.toDouble()
          : double.tryParse(allowances?.toString() ?? '') ?? 0.0;
      final parsedDeductions = deductions is num
          ? deductions.toDouble()
          : double.tryParse(deductions?.toString() ?? '') ?? 0.0;

      final employee = Employee(
        id: id,
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        department: department,
        designation: designation,
        baseSalary: parsedBaseSalary,
        allowances: parsedAllowances,
        deductions: parsedDeductions,
        bankAccount: bankAccount,
        ledgerId: ledgerId,
        costCenterId: costCenterId?.isNotEmpty == true ? costCenterId : null,
        employeeCode: employeeCode,
        isActive: isActive,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final data = employee.toJson();
      data['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('employees')
          .update(data)
          .eq('id', id)
          .select()
          .single();

      final updatedEmployee = Employee.fromJson(response);
      final index = _employees.indexWhere((emp) => emp.id == id);
      if (index != -1) {
        _employees[index] = updatedEmployee;
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deactivateEmployee(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from('employees')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .select()
          .single();

      final updatedEmployee = Employee.fromJson(response);
      final index = _employees.indexWhere((emp) => emp.id == id);
      if (index != -1) {
        _employees[index] = updatedEmployee;
      }
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
