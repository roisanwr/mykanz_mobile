import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../../core/config/app_colors.dart';
import '../../data/models/fiat_transaction_model.dart';
import '../../data/repositories/transaction_repository.dart';
import 'add_transaction_sheet.dart';

final transactionsProvider = FutureProvider<List<FiatTransactionModel>>((
  ref,
) async {
  final repo = ref.watch(transactionRepositoryProvider);
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  return repo.getTransactions(
    startDate: startOfMonth,
    endDate: endOfMonth,
    limit: 100,
  );
});

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txsAsync = ref.watch(transactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Transaksi',
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
                builder: (_) => const AddTransactionSheet(),
              );
              if (saved == true) {
                ref.invalidate(transactionsProvider);
              }
            },
          ),
        ],
      ),
      body: txsAsync.when(
        data: (txs) {
          if (txs.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(transactionsProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: txs.length,
              separatorBuilder: (_, _) => const Gap(16),
              itemBuilder: (context, index) {
                return _buildTransactionCard(context, ref, txs[index]);
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.receipt,
            size: 64,
            color: Colors.grey.withOpacity(0.5),
          ),
          const Gap(16),
          const Text(
            'Belum ada transaksi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Gap(8),
          const Text(
            'Ayo catat pemasukan atau pengeluaranmu!',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(
    BuildContext context,
    WidgetRef ref,
    FiatTransactionModel tx,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIncome = tx.transactionType == 'PEMASUKAN';
    final isTransfer = tx.transactionType == 'TRANSFER';

    IconData getIcon() {
      if (isTransfer) return LucideIcons.arrowRightLeft;
      if (isIncome) return LucideIcons.arrowDownLeft;
      return LucideIcons.arrowUpRight;
    }

    Color getColor() {
      if (isTransfer) return Colors.blueAccent;
      if (isIncome) return AppColors.income;
      return AppColors.danger;
    }

    return Slidable(
      key: ValueKey(tx.id),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) async {
              await ref
                  .read(transactionRepositoryProvider)
                  .deleteTransaction(tx.id);
              ref.refresh(transactionsProvider.future);
            },
            backgroundColor: AppColors.danger,
            foregroundColor: Colors.white,
            icon: LucideIcons.trash2,
            label: 'Hapus',
            borderRadius: BorderRadius.circular(16),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
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
                      tx.category?.name ??
                          (isTransfer ? 'Transfer' : 'Lain-lain'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      DateFormat(
                        'dd MMM yyyy, HH:mm',
                      ).format(tx.transactionDate),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    if (tx.description != null && tx.description!.isNotEmpty)
                      Text(
                        tx.description!,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                '${isIncome ? '+' : (isTransfer ? '' : '-')} ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(tx.amount)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isTransfer
                      ? Colors.blueAccent
                      : (isIncome ? AppColors.income : AppColors.danger),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
