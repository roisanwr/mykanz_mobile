import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ==========================================
  // BRAND — sama persis dengan web (TailwindCSS)
  // ==========================================
  static const Color primary   = Color(0xFFF97316); // orange-500
  static const Color indigo    = Color(0xFF6366F1); // indigo-500
  static const Color emerald   = Color(0xFF10B981); // emerald-500
  static const Color danger    = Color(0xFFEF4444); // red-500
  static const Color blue      = Color(0xFF3B82F6); // blue-500

  // ==========================================
  // LIGHT MODE — slate palette
  // ==========================================
  static const Color lightBackground = Color(0xFFF8FAFC); // slate-50
  static const Color lightSurface    = Color(0xFFFFFFFF); // white
  static const Color lightBorder     = Color(0xFFE2E8F0); // slate-200
  static const Color lightText       = Color(0xFF0F172A); // slate-900
  static const Color lightSubtext    = Color(0xFF64748B); // slate-500

  // ==========================================
  // DARK MODE — slate palette
  // ==========================================
  static const Color darkBackground  = Color(0xFF0F172A); // slate-900
  static const Color darkSurface     = Color(0xFF1E293B); // slate-800
  static const Color darkBorder      = Color(0xFF334155); // slate-700
  static const Color darkText        = Color(0xFFF1F5F9); // slate-100
  static const Color darkSubtext     = Color(0xFF94A3B8); // slate-400

  // ==========================================
  // SEMANTIC (income/expense/transfer)
  // ==========================================
  static const Color income   = emerald;
  static const Color expense  = danger;
  static const Color transfer = blue;

  // ==========================================
  // GRADIENT
  // ==========================================
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFF8C00), Color(0xFFF97316)], // orange gradient
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF0F172A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
