import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  // ==========================================
  // LIGHT THEME
  // ==========================================
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
          primary: AppColors.primary,
          onPrimary: Colors.white,
          secondary: AppColors.indigo,
          surface: AppColors.lightSurface,
          onSurface: AppColors.lightText,
          error: AppColors.danger,
        ),
        scaffoldBackgroundColor: AppColors.lightBackground,
        textTheme: GoogleFonts.interTextTheme().copyWith(
          displayLarge: GoogleFonts.inter(
            fontSize: 48, fontWeight: FontWeight.w900,
            color: AppColors.lightText, letterSpacing: -1.5,
          ),
          displayMedium: GoogleFonts.inter(
            fontSize: 36, fontWeight: FontWeight.w900,
            color: AppColors.lightText, letterSpacing: -1,
          ),
          headlineLarge: GoogleFonts.inter(
            fontSize: 24, fontWeight: FontWeight.w800,
            color: AppColors.lightText,
          ),
          headlineMedium: GoogleFonts.inter(
            fontSize: 20, fontWeight: FontWeight.w700,
            color: AppColors.lightText,
          ),
          headlineSmall: GoogleFonts.inter(
            fontSize: 16, fontWeight: FontWeight.w700,
            color: AppColors.lightText,
          ),
          bodyLarge: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w500,
            color: AppColors.lightText,
          ),
          bodyMedium: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w400,
            color: AppColors.lightSubtext,
          ),
          labelLarge: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w700,
            color: AppColors.lightText,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppColors.lightBorder),
          ),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.lightBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.lightBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.lightBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.danger),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          labelStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.lightSubtext),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: AppColors.primary.withOpacity(0.3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: AppColors.primary.withOpacity(0.12),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return IconThemeData(color: AppColors.primary, size: 22);
            }
            return IconThemeData(color: AppColors.lightSubtext, size: 22);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary,
              );
            }
            return GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.lightSubtext,
            );
          }),
          elevation: 0,
          height: 72,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.lightText,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.lightText,
          ),
        ),
      );

  // ==========================================
  // DARK THEME
  // ==========================================
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
          primary: AppColors.primary,
          onPrimary: Colors.white,
          secondary: AppColors.indigo,
          surface: AppColors.darkSurface,
          onSurface: AppColors.darkText,
          error: AppColors.danger,
        ),
        scaffoldBackgroundColor: AppColors.darkBackground,
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
          displayLarge: GoogleFonts.inter(
            fontSize: 48, fontWeight: FontWeight.w900,
            color: AppColors.darkText, letterSpacing: -1.5,
          ),
          displayMedium: GoogleFonts.inter(
            fontSize: 36, fontWeight: FontWeight.w900,
            color: AppColors.darkText, letterSpacing: -1,
          ),
          headlineLarge: GoogleFonts.inter(
            fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.darkText,
          ),
          headlineMedium: GoogleFonts.inter(
            fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.darkText,
          ),
          headlineSmall: GoogleFonts.inter(
            fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkText,
          ),
          bodyLarge: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.darkText,
          ),
          bodyMedium: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.darkSubtext,
          ),
          labelLarge: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkText,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: AppColors.darkSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppColors.darkBorder),
          ),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.darkBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.darkBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.darkBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          labelStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.darkSubtext),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.darkSurface,
          indicatorColor: AppColors.primary.withOpacity(0.2),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return IconThemeData(color: AppColors.primary, size: 22);
            }
            return IconThemeData(color: AppColors.darkSubtext, size: 22);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary,
              );
            }
            return GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.darkSubtext,
            );
          }),
          elevation: 0,
          height: 72,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.darkSurface,
          foregroundColor: AppColors.darkText,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.darkText,
          ),
        ),
      );
}
