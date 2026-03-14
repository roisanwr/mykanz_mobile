import '../../../categories/data/models/category_model.dart';
import '../../../wallets/data/models/wallet_model.dart';

class FiatTransactionModel {
  final String id;
  final String userId;
  final String walletId;
  final String? categoryId;
  final String? toWalletId;
  final String transactionType; // 'PEMASUKAN', 'PENGELUARAN', 'TRANSFER'
  final double amount;
  final double exchangeRate;
  final String? description;
  final DateTime transactionDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined fields
  final CategoryModel? category;
  final WalletModel? wallet;
  final WalletModel? toWallet;

  const FiatTransactionModel({
    required this.id,
    required this.userId,
    required this.walletId,
    this.categoryId,
    this.toWalletId,
    required this.transactionType,
    required this.amount,
    required this.exchangeRate,
    this.description,
    required this.transactionDate,
    required this.createdAt,
    required this.updatedAt,
    this.category,
    this.wallet,
    this.toWallet,
  });

  factory FiatTransactionModel.fromJson(Map<String, dynamic> json) {
    return FiatTransactionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      walletId: json['wallet_id'] as String,
      categoryId: json['category_id'] as String?,
      toWalletId: json['to_wallet_id'] as String?,
      transactionType: json['transaction_type'] as String,
      amount: double.parse(json['amount'].toString()),
      exchangeRate: double.parse((json['exchange_rate'] ?? 1.0).toString()),
      description: json['description'] as String?,
      transactionDate: DateTime.parse(json['transaction_date']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      category: json['categories'] != null ? CategoryModel.fromJson(json['categories']) : null,
      wallet: json['wallet'] != null ? WalletModel.fromJson(json['wallet']) : null,
      toWallet: json['to_wallet'] != null ? WalletModel.fromJson(json['to_wallet']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'wallet_id': walletId,
      'category_id': categoryId,
      'to_wallet_id': toWalletId,
      'transaction_type': transactionType,
      'amount': amount,
      'exchange_rate': exchangeRate,
      'description': description,
      'transaction_date': transactionDate.toIso8601String(),
    };
  }
}
