import 'package:intl/intl.dart';

/// Format angka menjadi format Rupiah Indonesia
/// Contoh: 1500000 → "Rp 1.500.000"
String formatRupiah(num angka, {bool compact = false}) {
  if (compact && angka.abs() >= 1000000000) {
    return 'Rp ${(angka / 1000000000).toStringAsFixed(1)}M';
  }
  if (compact && angka.abs() >= 1000000) {
    return 'Rp ${(angka / 1000000).toStringAsFixed(1)}Jt';
  }
  if (compact && angka.abs() >= 1000) {
    return 'Rp ${(angka / 1000).toStringAsFixed(0)}rb';
  }

  final formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  return formatter.format(angka);
}

/// Format angka saja (tanpa simbol Rp)
String formatAngka(num angka) {
  return NumberFormat('#,##0', 'id_ID').format(angka);
}

/// Format tanggal ke "12 Mar 2025"
String formatTanggal(DateTime? date) {
  if (date == null) return '-';
  return DateFormat('d MMM yyyy', 'id_ID').format(date);
}

/// Format tanggal ke "12 Mar"
String formatTanggalPendek(DateTime? date) {
  if (date == null) return '-';
  return DateFormat('d MMM', 'id_ID').format(date);
}

/// Format tanggal ke "Senin, 12 Maret 2025"
String formatTanggalLengkap(DateTime? date) {
  if (date == null) return '-';
  return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);
}

/// Parse string angka (dari Supabase) ke double
double parseDecimal(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}
