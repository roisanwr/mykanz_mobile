import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/config/app_colors.dart';
import '../../../categories/data/models/category_model.dart';
import '../../../categories/data/repositories/category_repository.dart';
import '../../../wallets/data/models/wallet_balance_model.dart';
import '../../../wallets/data/repositories/wallet_repository.dart';
import '../../data/repositories/transaction_repository.dart';

// =====================================================================
// Rupiah text input formatter
// =====================================================================
class _RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.isEmpty) return newValue.copyWith(text: '');
    final num = int.parse(text);
    final formatted = NumberFormat('#,###', 'id_ID').format(num);
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// =====================================================================
// Provider untuk kategoris dan wallets di dalam bottom sheet
// =====================================================================
final _categoriesProvider = FutureProvider.family<List<CategoryModel>, String>(
  (ref, type) => ref.watch(categoryRepositoryProvider).getCategories(type: type),
);

final _walletBalancesSheetProvider = FutureProvider<List<WalletBalanceModel>>(
  (ref) => ref.watch(walletRepositoryProvider).getWalletBalances(),
);

// =====================================================================
// AddTransactionSheet Widget
// =====================================================================
class AddTransactionSheet extends ConsumerStatefulWidget {
  const AddTransactionSheet({super.key});

  @override
  ConsumerState<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Form controllers
  final _amountCtrl = TextEditingController();
  final _adminFeeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _txType = 'PENGELUARAN'; // PENGELUARAN | PEMASUKAN | TRANSFER
  DateTime _selectedDate = DateTime.now();
  String? _selectedWalletId;
  String? _selectedToWalletId;
  CategoryModel? _selectedCategory;
  bool _isLoading = false;
  String? _errorMessage;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final types = ['PENGELUARAN', 'PEMASUKAN', 'TRANSFER'];
        setState(() {
          _txType = types[_tabController.index];
          _selectedCategory = null; // reset kategori saat ganti tab
          _selectedWalletId = null;
          _selectedToWalletId = null;
          _errorMessage = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountCtrl.dispose();
    _adminFeeCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  double _parseAmount(String text) {
    final clean = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) return 0;
    return double.parse(clean);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Validasi tambahan
    if (_selectedWalletId == null) {
      setState(() => _errorMessage = 'Pilih dompet terlebih dahulu');
      return;
    }
    if (_txType == 'TRANSFER' && _selectedToWalletId == null) {
      setState(() => _errorMessage = 'Pilih dompet tujuan terlebih dahulu');
      return;
    }
    if (_txType == 'TRANSFER' && _selectedWalletId == _selectedToWalletId) {
      setState(() => _errorMessage = 'Dompet asal dan tujuan tidak boleh sama');
      return;
    }
    if (_txType != 'TRANSFER' && _selectedCategory == null) {
      setState(() => _errorMessage = 'Pilih kategori terlebih dahulu');
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final repo = ref.read(transactionRepositoryProvider);
      final catRepo = ref.read(categoryRepositoryProvider);
      final amount = _parseAmount(_amountCtrl.text);
      final adminFee = _parseAmount(_adminFeeCtrl.text);

      // Buat transaksi utama
      await repo.createTransaction(
        walletId: _selectedWalletId!,
        toWalletId: _txType == 'TRANSFER' ? _selectedToWalletId : null,
        categoryId: _txType != 'TRANSFER' ? _selectedCategory?.id : null,
        transactionType: _txType,
        amount: amount,
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        transactionDate: _selectedDate,
      );

      // Jika ada admin fee (transfer only) → buat PENGELUARAN tambahan
      if (_txType == 'TRANSFER' && adminFee > 0) {
        // Cari/buat kategori 'Biaya Admin' type PENGELUARAN
        final categories = await catRepo.getCategories(type: 'PENGELUARAN');
        CategoryModel? adminCat;
        try {
          adminCat = categories.firstWhere(
            (c) => c.name.toLowerCase() == 'biaya admin',
          );
        } catch (_) {
          adminCat = await catRepo.createCategory(
            name: 'Biaya Admin',
            type: 'PENGELUARAN',
          );
        }

        await repo.createTransaction(
          walletId: _selectedWalletId!,
          categoryId: adminCat.id,
          transactionType: 'PENGELUARAN',
          amount: adminFee,
          description: 'Biaya admin transfer',
          transactionDate: _selectedDate,
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
    final walletsAsync = ref.watch(_walletBalancesSheetProvider);
    final categoryType = _txType == 'TRANSFER' ? 'PENGELUARAN' : _txType;
    final categoriesAsync = ref.watch(_categoriesProvider(categoryType));

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollCtrl) {
          return Form(
            key: _formKey,
            child: ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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

                // Title
                const Text(
                  'Tambah Transaksi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const Gap(16),

                // Tab tipe transaksi
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: _txType == 'PEMASUKAN'
                          ? AppColors.income
                          : _txType == 'PENGELUARAN'
                              ? AppColors.danger
                              : Colors.blueAccent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey,
                    dividerColor: Colors.transparent,
                    labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    tabs: const [
                      Tab(text: 'PENGELUARAN'),
                      Tab(text: 'PEMASUKAN'),
                      Tab(text: 'TRANSFER'),
                    ],
                  ),
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

                // Date Picker
                _SectionLabel('Tanggal'),
                const Gap(6),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.calendar, size: 18, color: Colors.grey),
                        const Gap(10),
                        Text(
                          DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(_selectedDate),
                          style: const TextStyle(fontSize: 14),
                        ),
                        const Spacer(),
                        const Icon(LucideIcons.chevronDown, size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const Gap(16),

                // Wallet selector
                walletsAsync.when(
                  data: (wallets) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel(_txType == 'TRANSFER' ? 'Dompet Asal' : 'Dompet'),
                      const Gap(6),
                      _WalletDropdown(
                        wallets: wallets,
                        value: _selectedWalletId,
                        onChanged: (v) => setState(() => _selectedWalletId = v),
                        hint: 'Pilih dompet',
                        isDark: isDark,
                      ),
                      if (_txType == 'TRANSFER') ...[
                        const Gap(12),
                        _SectionLabel('Dompet Tujuan'),
                        const Gap(6),
                        _WalletDropdown(
                          wallets: wallets,
                          value: _selectedToWalletId,
                          onChanged: (v) => setState(() => _selectedToWalletId = v),
                          hint: 'Pilih dompet tujuan',
                          isDark: isDark,
                        ),
                      ],
                    ],
                  ),
                  loading: () => const SizedBox(height: 60, child: Center(child: CircularProgressIndicator())),
                  error: (e, _) => Text('Gagal memuat dompet: $e', style: const TextStyle(color: Colors.red)),
                ),
                const Gap(16),

                // Kategori (only for non-transfer)
                if (_txType != 'TRANSFER') ...[
                  categoriesAsync.when(
                    data: (cats) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionLabel('Kategori'),
                        const Gap(6),
                        DropdownButtonFormField<CategoryModel>(
                          value: _selectedCategory,
                          decoration: InputDecoration(
                            hintText: 'Pilih kategori',
                            prefixIcon: const Icon(LucideIcons.tag, size: 18),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          ),
                          items: cats.map((cat) => DropdownMenuItem(
                            value: cat,
                            child: Text(cat.name),
                          )).toList(),
                          onChanged: (v) => setState(() => _selectedCategory = v),
                        ),
                      ],
                    ),
                    loading: () => const SizedBox(height: 60, child: Center(child: CircularProgressIndicator())),
                    error: (e, _) => Text('Gagal memuat kategori: $e'),
                  ),
                  const Gap(16),
                ],

                // Jumlah
                _SectionLabel('Jumlah'),
                const Gap(6),
                TextFormField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [_RupiahInputFormatter()],
                  decoration: InputDecoration(
                    prefixText: 'Rp ',
                    hintText: '0',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Jumlah wajib diisi';
                    if (_parseAmount(v) <= 0) return 'Jumlah harus lebih dari 0';
                    return null;
                  },
                ),
                const Gap(16),

                // Admin fee (transfer only)
                if (_txType == 'TRANSFER') ...[
                  _SectionLabel('Biaya Admin (opsional)'),
                  const Gap(6),
                  TextFormField(
                    controller: _adminFeeCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [_RupiahInputFormatter()],
                    decoration: InputDecoration(
                      prefixText: 'Rp ',
                      hintText: '0',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const Gap(16),
                ],

                // Deskripsi
                _SectionLabel('Deskripsi (opsional)'),
                const Gap(6),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 2,
                  maxLength: 200,
                  decoration: InputDecoration(
                    hintText: 'Catatan tambahan...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const Gap(24),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _txType == 'PEMASUKAN'
                          ? AppColors.income
                          : _txType == 'PENGELUARAN'
                              ? AppColors.danger
                              : Colors.blueAccent,
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
                        : const Text(
                            'Simpan Transaksi',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// =====================================================================
// Helper Widgets
// =====================================================================
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        color: Colors.grey,
      ),
    );
  }
}

class _WalletDropdown extends StatelessWidget {
  final List<WalletBalanceModel> wallets;
  final String? value;
  final ValueChanged<String?> onChanged;
  final String hint;
  final bool isDark;

  const _WalletDropdown({
    required this.wallets,
    required this.value,
    required this.onChanged,
    required this.hint,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(LucideIcons.wallet, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      items: wallets.map((w) => DropdownMenuItem(
        value: w.walletId,
        child: Text(
          '${w.name}  •  ${currency.format(w.balance)}',
          overflow: TextOverflow.ellipsis,
        ),
      )).toList(),
      onChanged: onChanged,
    );
  }
}
