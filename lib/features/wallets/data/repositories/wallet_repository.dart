import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/services/supabase_service.dart';
import '../models/wallet_model.dart';
import '../models/wallet_balance_model.dart';

part 'wallet_repository.g.dart';

class WalletRepository {
  final SupabaseClient _client;

  final AuthService _authService;

  WalletRepository(this._client, this._authService);

  Future<List<WalletBalanceModel>> getWalletBalances() async {
    if (_authService.currentUserId == null) return [];
    final response = await _client.from('wallet_balances').select().eq('user_id', _authService.currentUserId!);
    return (response as List).map((e) => WalletBalanceModel.fromJson(e)).toList();
  }

  Future<List<WalletModel>> getWallets() async {
    if (_authService.currentUserId == null) return [];
    final response = await _client.from('wallets').select().eq('user_id', _authService.currentUserId!).isFilter('deleted_at', null).order('created_at');
    return (response as List).map((e) => WalletModel.fromJson(e)).toList();
  }

  Future<WalletModel> createWallet({
    required String name,
    required String type,
    String currency = 'IDR',
  }) async {
    final response = await _client.from('wallets').insert({
      'name': name,
      'type': type,
      'currency': currency,
      'user_id': _authService.currentUserId,
    }).select().single();
    
    return WalletModel.fromJson(response);
  }

  Future<WalletModel> updateWallet(String id, {required String name, required String type}) async {
    final response = await _client.from('wallets').update({
      'name': name,
      'type': type,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id).eq('user_id', _authService.currentUserId!).select().single();
    
    return WalletModel.fromJson(response);
  }

  Future<void> deleteWallet(String id) async {
    // Soft delete — hanya milik user sendiri
    await _client.from('wallets').update({
      'deleted_at': DateTime.now().toIso8601String(),
    }).eq('id', id).eq('user_id', _authService.currentUserId!);
  }
}

@riverpod
WalletRepository walletRepository(Ref ref) {
  return WalletRepository(ref.watch(supabaseClientProvider), ref.watch(authServiceProvider));
}
