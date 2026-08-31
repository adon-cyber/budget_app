import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/report_balance.dart';

class ReportProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<ReportBalance> _reportBalances = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ReportBalance> get reportBalances => _reportBalances;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchReportBalances() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabase.from('report_balances').select();
      _reportBalances = (response as List)
          .map((json) => ReportBalance.fromJson(json))
          .toList();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  double get totalIncome {
    return _reportBalances
        .where((item) => item.nature.toLowerCase() == 'income')
        .fold(0.0, (sum, item) => sum + item.currentBalance);
  }

  double get totalExpenses {
    return _reportBalances
        .where((item) => item.nature.toLowerCase() == 'expense')
        .fold(0.0, (sum, item) => sum + item.currentBalance);
  }

  double get netProfit {
    return totalIncome - totalExpenses;
  }

  double get totalAssets {
    return _reportBalances
        .where((item) => item.nature.toLowerCase() == 'asset')
        .fold(0.0, (sum, item) => sum + item.currentBalance);
  }

  double get totalLiabilities {
    return _reportBalances
        .where((item) => item.nature.toLowerCase() == 'liability')
        .fold(0.0, (sum, item) => sum + item.currentBalance);
  }
}
