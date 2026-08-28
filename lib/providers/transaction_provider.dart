import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/transaction.dart';

class TransactionState {
  final List<TransactionModel> transactions;
  final bool isLoading;
  final String? error;

  TransactionState({
    this.transactions = const [],
    this.isLoading = false,
    this.error,
  });

  TransactionState copyWith({
    List<TransactionModel>? transactions,
    bool? isLoading,
    String? error,
  }) {
    return TransactionState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class TransactionNotifier extends StateNotifier<TransactionState> {
  TransactionNotifier() : super(TransactionState()) {
    fetchTransactions();
  }

  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> fetchTransactions() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = _supabase.auth.currentUser;
      var query = _supabase.from('transactions').select();

      if (user != null) {
        query = query.eq('user_id', user.id);
      }

      final response = await query.order('created_at', ascending: false);

      final List<TransactionModel> loadedTransactions = (response as List)
          .map(
            (item) => TransactionModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();

      state = state.copyWith(
        transactions: loadedTransactions,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addTransaction({
    required String title,
    required double amount,
    required String category,
    required String type,
    String? receiptUrl,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = _supabase.auth.currentUser;

      final Map<String, dynamic> data = {
        'title': title,
        'amount': amount,
        'category': category,
        'type': type,
        'receipt_url': receiptUrl,
      };

      if (user != null) {
        data['user_id'] = user.id;
      }

      await _supabase.from('transactions').insert(data);

      // Auto-refresh state upon adding transaction
      await fetchTransactions();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteTransaction(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _supabase.from('transactions').delete().eq('id', id);

      // Auto-refresh state upon deleting transaction
      await fetchTransactions();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final transactionProvider =
    StateNotifierProvider<TransactionNotifier, TransactionState>((ref) {
      return TransactionNotifier();
    });
