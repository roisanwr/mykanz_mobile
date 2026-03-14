import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/config/router.dart';
import '../../../core/services/supabase_service.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    final result = await ref.read(authServiceProvider).register(
      _nameCtrl.text.trim(),
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.isSuccess) {
      ref.read(authNotifierProvider.notifier).setLoggedIn();
      if (mounted) context.go('/dashboard');
    } else {
      setState(() => _errorMessage = result.errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Gap(20),

                // Back button
                FadeIn(
                  child: GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: const Icon(LucideIcons.chevronLeft, color: Colors.white, size: 20),
                    ),
                  ),
                ),

                const Gap(32),

                FadeInDown(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Buat akun baru ✨',
                        style: TextStyle(
                          fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white,
                        ),
                      ),
                      const Gap(8),
                      Text('Mulai perjalanan finansialmu bersama Kanz.',
                        style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.6)),
                      ),
                    ],
                  ),
                ),

                const Gap(32),

                FadeInUp(
                  delay: const Duration(milliseconds: 100),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurface.withOpacity(0.95)
                          : Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.danger.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(LucideIcons.alertCircle, color: AppColors.danger, size: 16),
                                  const Gap(8),
                                  Expanded(
                                    child: Text(_errorMessage!,
                                      style: const TextStyle(color: AppColors.danger, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Gap(16),
                          ],

                          TextFormField(
                            controller: _nameCtrl,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Nama Lengkap',
                              prefixIcon: Icon(LucideIcons.user, size: 18),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Nama wajib diisi';
                              return null;
                            },
                          ),
                          const Gap(16),

                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(LucideIcons.mail, size: 18),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Email wajib diisi';
                              if (!v.contains('@')) return 'Format email tidak valid';
                              return null;
                            },
                          ),
                          const Gap(16),

                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(LucideIcons.lock, size: 18),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                                  size: 18,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Password wajib diisi';
                              if (v.length < 8) return 'Password minimal 8 karakter';
                              return null;
                            },
                          ),
                          const Gap(16),

                          TextFormField(
                            controller: _confirmPasswordCtrl,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _register(),
                            decoration: const InputDecoration(
                              labelText: 'Konfirmasi Password',
                              prefixIcon: Icon(LucideIcons.lock, size: 18),
                            ),
                            validator: (v) {
                              if (v != _passwordCtrl.text) return 'Password tidak cocok';
                              return null;
                            },
                          ),
                          const Gap(24),

                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _register,
                              style: ElevatedButton.styleFrom(
                                shadowColor: AppColors.primary.withOpacity(0.4),
                                elevation: _isLoading ? 0 : 8,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20, height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white,
                                      ),
                                    )
                                  : const Text('Daftar Sekarang'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const Gap(24),

                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: Center(
                    child: GestureDetector(
                      onTap: () => context.pop(),
                      child: RichText(
                        text: TextSpan(
                          text: 'Sudah punya akun? ',
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                          children: const [
                            TextSpan(
                              text: 'Masuk',
                              style: TextStyle(
                                color: AppColors.primary, fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const Gap(40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
