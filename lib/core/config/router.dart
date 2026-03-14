import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../services/supabase_service.dart';

part 'router.g.dart';

// ==========================================
// AUTH STATE PROVIDER
// Notifier sederhana: apakah user sudah login?
// ==========================================
@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  Future<bool> build() async {
    final authService = ref.read(authServiceProvider);
    return authService.restoreSession();
  }

  Future<void> logout() async {
    final authService = ref.read(authServiceProvider);
    await authService.logout();
    state = const AsyncValue.data(false);
  }

  void setLoggedIn() {
    state = const AsyncValue.data(true);
  }
}

// ==========================================
// ROUTER PROVIDER
// ==========================================
@riverpod
GoRouter router(Ref ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final isLoggedIn = authState.valueOrNull ?? false;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (isLoading) return null;
      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/dashboard';
      return null;
    },
    routes: [
      // ==========================================
      // AUTH ROUTES
      // ==========================================
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => _fadeTransition(
          state, const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        pageBuilder: (context, state) => _fadeTransition(
          state, const RegisterScreen(),
        ),
      ),

      // ==========================================
      // MAIN APP — Shell dengan BottomNavigationBar
      // ==========================================
      ShellRoute(
        builder: (context, state, child) => AppScaffold(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            pageBuilder: (context, state) => _slideTransition(state, _placeholder('Dashboard')),
          ),
          GoRoute(
            path: '/transactions',
            name: 'transactions',
            pageBuilder: (context, state) => _slideTransition(state, _placeholder('Transaksi')),
          ),
          GoRoute(
            path: '/wallets',
            name: 'wallets',
            pageBuilder: (context, state) => _slideTransition(state, _placeholder('Dompet')),
          ),
          GoRoute(
            path: '/portfolios',
            name: 'portfolios',
            pageBuilder: (context, state) => _slideTransition(state, _placeholder('Portofolio')),
            routes: [
              GoRoute(
                path: 'assets',
                name: 'portfolio-assets',
                pageBuilder: (context, state) => _slideTransition(state, _placeholder('Data Aset')),
              ),
              GoRoute(
                path: 'transactions',
                name: 'portfolio-transactions',
                pageBuilder: (context, state) => _slideTransition(state, _placeholder('Transaksi Investasi')),
              ),
            ],
          ),
          GoRoute(
            path: '/categories',
            name: 'categories',
            pageBuilder: (context, state) => _slideTransition(state, _placeholder('Kategori')),
          ),
          GoRoute(
            path: '/goals',
            name: 'goals',
            pageBuilder: (context, state) => _slideTransition(state, _placeholder('Target Impian')),
          ),
          GoRoute(
            path: '/budgets',
            name: 'budgets',
            pageBuilder: (context, state) => _slideTransition(state, _placeholder('Anggaran')),
          ),
        ],
      ),
    ],
  );
}

// ==========================================
// TRANSITION HELPERS
// ==========================================
CustomTransitionPage _fadeTransition(GoRouterState state, Widget child) =>
    CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 300),
    );

CustomTransitionPage _slideTransition(GoRouterState state, Widget child) =>
    CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (_, animation, __, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.05, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
        child: FadeTransition(opacity: animation, child: child),
      ),
      transitionDuration: const Duration(milliseconds: 250),
    );

// Placeholder sementara untuk screen yang belum dibuat
Widget _placeholder(String title) => Scaffold(
      body: Center(
        child: Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ),
    );
