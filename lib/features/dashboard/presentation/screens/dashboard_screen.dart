import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/config/app_colors.dart';
import '../../../wallets/data/repositories/wallet_repository.dart';
import '../../../transactions/data/repositories/transaction_repository.dart';

final dashboardBalanceProvider = FutureProvider<double>((ref) async {
  final repo = ref.watch(walletRepositoryProvider);
  final balances = await repo.getWalletBalances();
  return balances.fold<double>(0.0, (double sum, wallet) => sum + wallet.balance);
});

final dashboardTransactionsProvider = FutureProvider((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  return repo.getTransactions(startDate: startOfMonth, endDate: endOfMonth, limit: 5);
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(dashboardBalanceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header with App Bar
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.heroGradient,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Gap(20),
                        Text(
                          'Total Kekayaan',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 16,
                          ),
                        ),
                        const Gap(8),
                        balanceAsync.when(
                          data: (balance) {
                            return Text(
                              NumberFormat.currency(
                                locale: 'id_ID',
                                symbol: 'Rp ',
                                decimalDigits: 0,
                              ).format(balance),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -1,
                              ),
                            );
                          },
                          loading: () => const CircularProgressIndicator(color: Colors.white),
                          error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.redAccent)),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            _actionButton(context, LucideIcons.arrowDownLeft, 'Pemasukan', AppColors.income),
                            const Gap(16),
                            _actionButton(context, LucideIcons.arrowUpRight, 'Pengeluaran', AppColors.danger),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Body Stats & Chart
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Arus Kas Bulan Ini', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Gap(24),
                  
                  // Simple Mock Chart
                  SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: const [
                              FlSpot(0, 3),
                              FlSpot(1, 1),
                              FlSpot(2, 4),
                              FlSpot(3, 2),
                              FlSpot(4, 5),
                              FlSpot(5, 3),
                              FlSpot(6, 4),
                            ],
                            isCurved: true,
                            color: AppColors.primary,
                            barWidth: 4,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppColors.primary.withOpacity(0.2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const Gap(40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Transaksi Terakhir', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton(onPressed: () {}, child: const Text('Lihat Semua')),
                    ],
                  ),
                  const Gap(16),
                  
                  // Recent Transactions list
                  ref.watch(dashboardTransactionsProvider).when(
                    data: (txs) {
                      if (txs.isEmpty) return const Center(child: Text('Belum ada transaksi'));
                      return Column(
                        children: txs.map((tx) {
                          final isIncome = tx.transactionType == 'PEMASUKAN';
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isIncome ? AppColors.income.withOpacity(0.1) : AppColors.danger.withOpacity(0.1),
                              child: Icon(
                                isIncome ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight,
                                color: isIncome ? AppColors.income : AppColors.danger,
                              ),
                            ),
                            title: Text(tx.category?.name ?? 'Tanpa Kategori', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(DateFormat('dd MMM yyyy').format(tx.transactionDate)),
                            trailing: Text(
                              '${isIncome ? '+' : '-'} ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(tx.amount)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isIncome ? AppColors.income : AppColors.danger,
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Gagal memuat: $e')),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _actionButton(BuildContext context, IconData icon, String label, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Expanded(
      child: Material(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 20),
                const Gap(8),
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
