import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/bill.dart';

class BillProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Bill> _bills = [];
  List<Bill> _agingBills = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Bill> get bills => _bills;
  List<Bill> get agingBills => _agingBills;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchBills() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabase.from('bills').select();
      _bills = (response as List).map((json) => Bill.fromJson(json)).toList();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAgingAnalysis() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabase.from('bill_aging_analysis').select();
      _agingBills = (response as List)
          .map((json) => Bill.fromJson(json))
          .toList();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addBill({
    required String ledgerId,
    required String referenceNo,
    required DateTime billDate,
    required DateTime dueDate,
    required double totalAmount,
    String? billType,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from('bills')
          .insert({
            'ledger_id': ledgerId,
            'reference_no': referenceNo,
            'bill_date': billDate.toIso8601String().split('T')[0],
            'due_date': dueDate.toIso8601String().split('T')[0],
            'total_amount': totalAmount,
            'cleared_amount': 0.0,
            ...?(billType != null ? {'bill_type': billType} : null),
          })
          .select()
          .single();

      final newBill = Bill.fromJson(response);
      _bills.add(newBill);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateClearedAmount({
    required String billId,
    required double additionalClearedAmount,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Find current bill
      final billIndex = _bills.indexWhere((b) => b.id == billId);
      if (billIndex == -1) return false;

      final bill = _bills[billIndex];
      final newClearedAmount = bill.clearedAmount + additionalClearedAmount;

      final response = await _supabase
          .from('bills')
          .update({'cleared_amount': newClearedAmount})
          .eq('id', billId)
          .select()
          .single();

      _bills[billIndex] = Bill.fromJson(response);
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
