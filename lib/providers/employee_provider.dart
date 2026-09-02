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
          .order('name', ascending: true);
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
    required double baseSalary,
    required double allowances,
    required double deductions,
    String? bankAccount,
    String? ledgerId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from('employees')
          .insert({
            'name': name,
            'email': email,
            'phone': phone,
            'department': department,
            'designation': designation,
            'base_salary': baseSalary,
            'allowances': allowances,
            'deductions': deductions,
            'bank_account': bankAccount,
            'ledger_id': ledgerId,
            'is_active': true,
          })
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
    required double baseSalary,
    required double allowances,
    required double deductions,
    String? bankAccount,
    String? ledgerId,
    required bool isActive,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from('employees')
          .update({
            'name': name,
            'email': email,
            'phone': phone,
            'department': department,
            'designation': designation,
            'base_salary': baseSalary,
            'allowances': allowances,
            'deductions': deductions,
            'bank_account': bankAccount,
            'ledger_id': ledgerId,
            'is_active': isActive,
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
