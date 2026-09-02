import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/voucher.dart';

class VoucherProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Voucher> _vouchers = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Voucher> get vouchers => _vouchers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Callback references for cross-provider synchronization
  Future<void> Function()? _fetchLedgersCallback;
  Future<void> Function()? _fetchBillsCallback;
  Future<void> Function()? _fetchReportsCallback;

  void setCallbacks({
    Future<void> Function()? fetchLedgers,
    Future<void> Function()? fetchBills,
    Future<void> Function()? fetchReports,
  }) {
    if (fetchLedgers != null) _fetchLedgersCallback = fetchLedgers;
    if (fetchBills != null) _fetchBillsCallback = fetchBills;
    if (fetchReports != null) _fetchReportsCallback = fetchReports;
  }

  Future<void> fetchVouchers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from('vouchers')
          .select('*, voucher_items(*)')
          .order('date', ascending: false);

      _vouchers = (response as List)
          .map((json) => Voucher.fromJson(json))
          .toList();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createVoucher({
    required String voucherNumber,
    required String voucherType,
    required DateTime date,
    String? narration,
    required List<Map<String, dynamic>> items, // Each item: { 'ledger_id': ..., 'debit': ..., 'credit': ..., 'description': ..., 'cost_center_id': ... }
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Validate total debits equal total credits
      double totalDebit = 0;
      double totalCredit = 0;
      for (var item in items) {
        totalDebit += (item['debit'] as num).toDouble();
        totalCredit += (item['credit'] as num).toDouble();
      }

      if ((totalDebit - totalCredit).abs() > 0.01) {
        throw Exception(
          'Total Debits ($totalDebit) must equal Total Credits ($totalCredit)',
        );
      }

      // 2. Insert voucher record
      final voucherResponse = await _supabase
          .from('vouchers')
          .insert({
            'voucher_number': voucherNumber,
            'voucher_type': voucherType,
            'date': date.toIso8601String().split('T')[0],
            'narration': narration,
          })
          .select()
          .single();

      final voucherId = voucherResponse['id'].toString();

      // 3. Insert voucher items and update ledger balances
      for (var item in items) {
        final ledgerId = item['ledger_id'].toString();
        final debit = (item['debit'] as num).toDouble();
        final credit = (item['credit'] as num).toDouble();
        final description = item['description'] as String?;
        final costCenterId =
            (item['cost_center_id'] == null ||
                (item['cost_center_id'] as String).isEmpty ||
                item['cost_center_id'] == 'None')
            ? null
            : item['cost_center_id'] as String?;
        final billId =
            (item['bill_id'] == null ||
                (item['bill_id'] as String).isEmpty ||
                item['bill_id'] == 'No Bill')
            ? null
            : item['bill_id'] as String?;

        await _supabase.from('voucher_items').insert({
          'voucher_id': voucherId,
          'ledger_id': ledgerId,
          'debit': debit,
          'credit': credit,
          'description': description,
          'cost_center_id': costCenterId,
          if (billId != null) 'bill_id': billId,
        });

        // Fetch current ledger balance and account group type to properly update current_balance
        final ledgerData = await _supabase
            .from('ledgers')
            .select('*, account_groups(type)')
            .eq('id', ledgerId)
            .single();

        final currentBalance = (ledgerData['current_balance'] as num)
            .toDouble();
        final groupType = ledgerData['account_groups']['type'] as String;

        double netChange = 0;
        if (groupType == 'asset' || groupType == 'expense') {
          netChange = debit - credit;
        } else {
          netChange = credit - debit;
        }

        final newBalance = currentBalance + netChange;

        await _supabase
            .from('ledgers')
            .update({'current_balance': newBalance})
            .eq('id', ledgerId);
      }

      // 4. Fetch vouchers and trigger cross-provider sync callbacks
      await fetchVouchers();

      if (_fetchLedgersCallback != null) {
        await _fetchLedgersCallback!();
      }
      if (_fetchBillsCallback != null) {
        await _fetchBillsCallback!();
      }
      if (_fetchReportsCallback != null) {
        await _fetchReportsCallback!();
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

  // Alias for backward compatibility if needed, or point to createVoucher
  Future<bool> postVoucher({
    required String voucherNumber,
    required String voucherType,
    required DateTime date,
    String? narration,
    required List<Map<String, dynamic>> items,
  }) async {
    return createVoucher(
      voucherNumber: voucherNumber,
      voucherType: voucherType,
      date: date,
      narration: narration,
      items: items,
    );
  }
}
