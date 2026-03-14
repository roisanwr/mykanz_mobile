import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/app_colors.dart';
import '../../data/models/wallet_balance_model.dart';
import '../../data/repositories/wallet_repository.dart';
import 'add_wallet_sheet.dart';

// Provider untuk wallet dengan balance
final walletBalancesProvider = FutureProvider<List<WalletBalanceModel>>((ref) async {
  final repo = ref.watch(walletRepositoryProvider);
  return repo.getWalletBalances();
});

// Legacy provider untuk backward compatibility (digunakan di login_screen)
final walletsProvider = walletBalancesProvider;

class WalletsScreen extends ConsumerWidget {
  const WalletsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(walletBalancesProvider);
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dompet & Rekening',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus),
            onPressed: () async {
              final saved = await showModalBottomSheet<bool>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const AddWalletSheet(),
              );
              if (saved == true) {
                ref.invalidate(walletBalancesProvider);
              }
            },
          ),
        ],
      ),
      body: walletsAsync.when(
        data: (wallets) {
          if (wallets.isEmpty) {
            return _buildEmptyState(context, ref);
          }

          final totalBalance = wallets.fold<double>(0, (sum, w) => sum + w.balance);

          return RefreshIndicator(
            onRefresh: () => ref.refresh(walletBalancesProvider.future),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Total Balance card
                _buildTotalBalanceCard(context, totalBalance, currency),
                const Gap(20),
                // Wallet cards
                ...wallets.map((wallet) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _WalletCard(wallet: wallet, currency: currency),
                )),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Gagal memuat: $e',
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.wallet,
            size: 64,
            color: Colors.grey.withOpacity(0.5),
          ),
          const Gap(16),
          const Text(
            'Belum ada dompet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Gap(8),
          const Text(
            'Tambahkan bank atau e-wallet pertamamu.',
            style: TextStyle(color: Colors.grey),
          ),
          const Gap(24),
          ElevatedButton.icon(
            onPressed: () async {
              final saved = await showModalBottomSheet<bool>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const AddWalletSheet(),
              );
              if (saved == true) {
                ref.invalidate(walletBalancesProvider);
              }
            },
            icon: const Icon(LucideIcons.plus, size: 18),
            label: const Text('Tambah Dompet'),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalBalanceCard(BuildContext context, double total, NumberFormat currency) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Saldo',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Gap(8),
          Text(
            currency.format(total),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Gap(4),
          const Text(
            'Semua rekening & dompet',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// Wallet Card dengan menu edit & hapus
// =====================================================================
class _WalletCard extends ConsumerWidget {
  final WalletBalanceModel wallet;
  final NumberFormat currency;

  const _WalletCard({required this.wallet, required this.currency});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    IconData getIcon(String name) {
      final lower = name.toLowerCase();
      if (lower.contains('bank') || lower.contains('bca') || lower.contains('bri') ||
          lower.contains('bni') || lower.contains('mandiri') || lower.contains('cimb')) {
        return LucideIcons.building;
      }
      if (lower.contains('gopay') || lower.contains('ovo') || lower.contains('dana') ||
          lower.contains('linkaja') || lower.contains('shopeepay') || lower.contains('digital')) {
        return LucideIcons.smartphone;
      }
      return LucideIcons.banknote;
    }

    Color getColor(String name) {
      final lower = name.toLowerCase();
      if (lower.contains('bank') || lower.contains('bca') || lower.contains('bri') ||
          lower.contains('bni') || lower.contains('mandiri') || lower.contains('cimb')) {
        return Colors.blue;
      }
      if (lower.contains('gopay') || lower.contains('ovo') || lower.contains('dana') ||
          lower.contains('linkaja') || lower.contains('shopeepay') || lower.contains('digital')) {
        return Colors.purple;
      }
      return Colors.green;
    }

    final color = getColor(wallet.name);
    final icon = getIcon(wallet.name);
    final isPositive = wallet.balance >= 0;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const Gap(14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    wallet.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    currency.format(wallet.balance),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isPositive ? AppColors.income : AppColors.danger,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(LucideIcons.moreVertical, size: 20, color: Colors.grey),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(LucideIcons.pencil, size: 16),
                      Gap(8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(LucideIcons.trash2, size: 16, color: Colors.red),
                      Gap(8),
                      Text('Hapus', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (action) async {
                if (action == 'edit') {
                  // Fetch full wallet model to open edit sheet
                  final wallets = await ref.read(walletRepositoryProvider).getWallets();
                  final fullWallet = wallets.where((w) => w.id == wallet.walletId).firstOrNull;
                  if (fullWallet != null && context.mounted) {
                    final saved = await showModalBottomSheet<bool>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => AddWalletSheet(wallet: fullWallet),
                    );
                    if (saved == true) {
                      ref.invalidate(walletBalancesProvider);
                    }
                  }
                } else if (action == 'delete') {
                  if (context.mounted) {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: const Text('Hapus Dompet'),
                        content: Text(
                          'Yakin ingin menghapus dompet "${wallet.name}"? Aksi ini tidak bisa dibatalkan.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Batal'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.danger,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Hapus'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await ref.read(walletRepositoryProvider).deleteWallet(wallet.walletId);
                      ref.invalidate(walletBalancesProvider);
                    }
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
