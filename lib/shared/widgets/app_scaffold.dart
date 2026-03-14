import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/config/app_colors.dart';

/// AppScaffold — Wrapper utama app dengan BottomNavigationBar
/// Analog dengan DashboardLayout.tsx di web
class AppScaffold extends ConsumerWidget {
  final Widget child;
  const AppScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
            ),
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _getSelectedIndex(location),
          onDestinationSelected: (index) => _onTap(context, index),
          backgroundColor: Colors.transparent,
          elevation: 0,
          shadowColor: Colors.transparent,
          indicatorColor: AppColors.primary.withOpacity(
            isDark ? 0.2 : 0.1,
          ),
          destinations: [
            _buildDestination(LucideIcons.layoutDashboard, 'Dashboard'),
            _buildDestination(LucideIcons.arrowLeftRight, 'Transaksi'),
            _buildDestination(LucideIcons.wallet, 'Dompet'),
            _buildDestination(LucideIcons.barChart2, 'Portofolio'),
            _buildDestination(LucideIcons.moreHorizontal, 'Lainnya'),
          ],
        ),
      ),
    );
  }

  NavigationDestination _buildDestination(IconData icon, String label) {
    return NavigationDestination(
      icon: Icon(icon),
      selectedIcon: Icon(icon, color: AppColors.primary),
      label: label,
    );
  }

  int _getSelectedIndex(String location) {
    if (location.startsWith('/dashboard'))    return 0;
    if (location.startsWith('/transactions')) return 1;
    if (location.startsWith('/wallets'))      return 2;
    if (location.startsWith('/portfolios'))   return 3;
    return 4; // Lainnya: categories, goals, budgets
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0: context.go('/dashboard');    break;
      case 1: context.go('/transactions'); break;
      case 2: context.go('/wallets');      break;
      case 3: context.go('/portfolios');   break;
      case 4: _showMoreMenu(context);      break;
    }
  }

  void _showMoreMenu(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _MoreMenuSheet(),
    );
  }
}

class _MoreMenuSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = [
      (LucideIcons.tags,  'Kategori',      '/categories'),
      (LucideIcons.target,'Target Impian', '/goals'),
      (LucideIcons.pieChart, 'Anggaran',   '/budgets'),
      (LucideIcons.settings, 'Pengaturan',  '/settings'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          ...items.map((item) => ListTile(
            leading: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.$1, color: AppColors.primary, size: 20),
            ),
            title: Text(
              item.$2,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            trailing: const Icon(LucideIcons.chevronRight, size: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onTap: () {
              Navigator.pop(context);
              context.go(item.$3);
            },
          )),
        ],
      ),
    );
  }
}
