import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/account_group.dart';
import '../models/ledger.dart';

class LedgerProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<AccountGroup> _accountGroups = [];
  List<Ledger> _ledgers = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<AccountGroup> get accountGroups => _accountGroups;
  List<Ledger> get ledgers => _ledgers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchLedgers() async {
    try {
      final ledgersResponse = await _supabase.from('ledgers').select();
      _ledgers = (ledgersResponse as List)
          .map((json) => Ledger.fromJson(json))
          .toList();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> fetchAccountGroups() async {
    try {
      final groupsResponse = await _supabase.from('account_groups').select();
      _accountGroups = (groupsResponse as List)
          .map((json) => AccountGroup.fromJson(json))
          .toList();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> fetchChartOfAccounts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.wait([fetchAccountGroups(), fetchLedgers()]);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addLedger({
    required String name,
    required String groupId,
    required double openingBalance,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from('ledgers')
          .insert({
            'name': name,
            'group_id': groupId,
            'opening_balance': openingBalance,
            'current_balance': openingBalance,
          })
          .select()
          .single();

      final newLedger = Ledger.fromJson(response);
      _ledgers.add(newLedger);
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
