import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/cost_center.dart';

class CostCenterProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<CostCenter> _costCenters = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CostCenter> get costCenters => _costCenters;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchCostCenters() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabase.from('cost_centers').select();
      _costCenters = (response as List)
          .map((json) => CostCenter.fromJson(json))
          .toList();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addCostCenter({
    required String name,
    String? description,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from('cost_centers')
          .insert({'name': name, 'description': description})
          .select()
          .single();

      final newCostCenter = CostCenter.fromJson(response);
      _costCenters.add(newCostCenter);
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
