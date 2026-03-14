import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/config/app_colors.dart';
import '../../data/models/wallet_model.dart';
import '../../data/repositories/wallet_repository.dart';

// =====================================================================
// AddWalletSheet — Bottom sheet untuk tambah / edit dompet
// =====================================================================
class AddWalletSheet extends ConsumerStatefulWidget {
  /// Jika [wallet] diisi, mode edit. Jika null, mode tambah.
  final WalletModel? wallet;

  const AddWalletSheet({super.key, this.wallet});

  @override
  ConsumerState<AddWalletSheet> createState() => _AddWalletSheetState();
}

class _AddWalletSheetState extends ConsumerState<AddWalletSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  String _type = 'TUNAI';
  String _currency = 'IDR';
  bool _isLoading = false;
  String? _errorMessage;

  bool get _isEdit => widget.wallet != null;

  static const _currencies = ['IDR', 'USD', 'EUR', 'SGD', 'MYR', 'JPY'];

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _nameCtrl.text = widget.wallet!.name;
      _type = widget.wallet!.type;
      _currency = widget.wallet!.currency;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final repo = ref.read(walletRepositoryProvider);
      if (_isEdit) {
        await repo.updateWallet(
          widget.wallet!.id,
          name: _nameCtrl.text.trim(),
          type: _type,
        );
      } else {
        await repo.createWallet(
          name: _nameCtrl.text.trim(),
          type: _type,
          currency: _currency,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal menyimpan: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Text(
                _isEdit ? 'Edit Dompet' : 'Tambah Dompet',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const Gap(20),

              // Error message
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
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.danger, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(12),
              ],

              // Nama dompet
              const Text(
                'Nama Dompet',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey),
              ),
              const Gap(6),
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  hintText: 'Contoh: BCA, GoPay, Dompet Tunai',
                  prefixIcon: const Icon(LucideIcons.wallet, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Nama dompet wajib diisi';
                  return null;
                },
              ),
              const Gap(16),

              // Tipe wallet
              const Text(
                'Tipe Dompet',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey),
              ),
              const Gap(8),
              Row(
                children: [
                  _TypeButton(
                    label: 'Tunai',
                    icon: LucideIcons.banknote,
                    color: Colors.green,
                    selected: _type == 'TUNAI',
                    onTap: () => setState(() => _type = 'TUNAI'),
                  ),
                  const Gap(8),
                  _TypeButton(
                    label: 'Bank',
                    icon: LucideIcons.building,
                    color: Colors.blue,
                    selected: _type == 'BANK',
                    onTap: () => setState(() => _type = 'BANK'),
                  ),
                  const Gap(8),
                  _TypeButton(
                    label: 'E-Wallet',
                    icon: LucideIcons.smartphone,
                    color: Colors.purple,
                    selected: _type == 'DOMPET_DIGITAL',
                    onTap: () => setState(() => _type = 'DOMPET_DIGITAL'),
                  ),
                ],
              ),
              const Gap(16),

              // Mata uang (only saat mode tambah)
              if (!_isEdit) ...[
                const Text(
                  'Mata Uang',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey),
                ),
                const Gap(6),
                DropdownButtonFormField<String>(
                  value: _currency,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(LucideIcons.coins, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  items: _currencies.map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c),
                  )).toList(),
                  onChanged: (v) => setState(() => _currency = v ?? 'IDR'),
                ),
                const Gap(16),
              ],

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _isEdit ? 'Simpan Perubahan' : 'Simpan Dompet',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// Type selector button
// =====================================================================
class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : Colors.grey.withOpacity(0.3),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? color : Colors.grey, size: 20),
              const Gap(4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? color : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
