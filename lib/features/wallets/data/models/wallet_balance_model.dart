class WalletBalanceModel {
  final String walletId;
  final String userId;
  final String name;
  final double balance;

  const WalletBalanceModel({
    required this.walletId,
    required this.userId,
    required this.name,
    required this.balance,
  });

  factory WalletBalanceModel.fromJson(Map<String, dynamic> json) {
    return WalletBalanceModel(
      walletId: json['wallet_id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      balance: double.parse(json['balance'].toString()),
    );
  }
}
