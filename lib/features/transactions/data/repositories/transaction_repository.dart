import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';
import '../models/fiat_transaction_model.dart';

part 'transaction_repository.g.dart';

class TransactionRepository {
  final SupabaseClient _client;

  final AuthService _authService;

  TransactionRepository(this._client, this._authService);

  Future<List<FiatTransactionModel>> getTransactions({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    if (_authService.currentUserId == null) return [];
    final response = await _client
        .from('fiat_transactions')
        .select('*, categories(*), wallet:wallets!fiat_transactions_wallet_id_fkey(*), to_wallet:wallets!fiat_transactions_to_wallet_id_fkey(*)')
        .eq('user_id', _authService.currentUserId!)
        .gte('transaction_date', startDate.toIso8601String())
        .lte('transaction_date', endDate.toIso8601String())
        .order('transaction_date', ascending: false)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
        
    return (response as List).map((e) => FiatTransactionModel.fromJson(e)).toList();
  }

  Future<FiatTransactionModel> createTransaction({
    required String walletId,
    String? categoryId,
    String? toWalletId,
    required String transactionType,
    required double amount,
    double exchangeRate = 1.0,
    String? description,
    required DateTime transactionDate,
  }) async {
    final response = await _client.from('fiat_transactions').insert({
      'user_id': _authService.currentUserId,
      'wallet_id': walletId,
      'category_id': categoryId,
      'to_wallet_id': toWalletId,
      'transaction_type': transactionType,
      'amount': amount,
      'exchange_rate': exchangeRate,
      'description': description,
      'transaction_date': transactionDate.toIso8601String(),
    }).select('*, categories(*), wallet:wallets!fiat_transactions_wallet_id_fkey(*), to_wallet:wallets!fiat_transactions_to_wallet_id_fkey(*)').single();
    
    return FiatTransactionModel.fromJson(response);
  }

  Future<void> deleteTransaction(String id) async {
    await _client.from('fiat_transactions').delete().eq('id', id).eq('user_id', _authService.currentUserId!);
  }
}

@riverpod
TransactionRepository transactionRepository(Ref ref) {
  return TransactionRepository(ref.watch(supabaseClientProvider), ref.watch(authServiceProvider));
}
