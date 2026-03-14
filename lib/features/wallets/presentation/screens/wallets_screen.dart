import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/app_colors.dart';
import '../../data/models/wallet_model.dart';
import '../../data/repositories/wallet_repository.dart';

final walletsProvider = FutureProvider<List<WalletModel>>((ref) async {
  final repo = ref.watch(walletRepositoryProvider);
  return repo.getWallets();
});

class WalletsScreen extends ConsumerWidget {
  const WalletsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(walletsProvider);

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
            onPressed: () {
              // TODO: Open bottom sheet to add wallet
            },
          ),
        ],
      ),
      body: walletsAsync.when(
        data: (wallets) {
          if (wallets.isEmpty) {
            return _buildEmptyState(context);
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(walletsProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: wallets.length,
              separatorBuilder: (_, _) => const Gap(16),
              itemBuilder: (context, index) {
                final wallet = wallets[index];
                return _buildWalletCard(context, wallet);
              },
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

  Widget _buildEmptyState(BuildContext context) {
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
        ],
      ),
    );
  }

  Widget _buildWalletCard(BuildContext context, WalletModel wallet) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBank = wallet.type == 'BANK';
    final isEWallet = wallet.type == 'DOMPET_DIGITAL';

    IconData getIcon() {
      if (isBank) return LucideIcons.building;
      if (isEWallet) return LucideIcons.smartphone;
      return LucideIcons.banknote;
    }

    Color getColor() {
      if (isBank) return Colors.blue;
      if (isEWallet) return Colors.purple;
      return Colors.green;
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: getColor().withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(getIcon(), color: getColor()),
                ),
                const Gap(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        wallet.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        wallet.type.replaceAll('_', ' '),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(LucideIcons.chevronRight, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
