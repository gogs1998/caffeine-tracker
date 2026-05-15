import 'package:flutter/material.dart';

abstract class AppColors {
  static const bg = Color(0xFF12121A);
  static const surface = Color(0xFF1E1E2E);
  static const surfaceHigh = Color(0xFF252542);
  static const surfaceLow = Color(0xFF181826);

  static const amber = Color(0xFFFFC107);
  static const amberSoft = Color(0xFFFFD54F);
  static const orange = Color(0xFFFF9800);

  static const safe = Color(0xFF4ADE80);
  static const caution = Color(0xFFFBBF24);
  static const danger = Color(0xFFF87171);
  static const purple = Color(0xFFA78BFA);

  // Glass layer — white with low alpha
  static const glassLayer = Color(0x0DFFFFFF); // ~5%
  static const glassBorder = Color(0x1AFFFFFF); // ~10%
  static const glassBorderStrong = Color(0x33FFFFFF); // ~20%

  // Text
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xB3FFFFFF); // 70%
  static const textTertiary = Color(0x73FFFFFF); // 45%
  static const textDisabled = Color(0x40FFFFFF); // 25%
}

class AppTheme {
  static ThemeData build() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.amber,
        secondary: AppColors.orange,
        surface: AppColors.surface,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: const CardTheme(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.amber,
        foregroundColor: Colors.black,
        elevation: 12,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.amber, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textDisabled),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.amber,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: 0.2,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.amber),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: AppColors.glassBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.amber.withAlpha(40),
        side: const BorderSide(color: AppColors.glassBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.glassBorder,
        thickness: 1,
      ),
      useMaterial3: true,
    );
  }
}

// Reusable card decoration
BoxDecoration surfaceCard({
  Color? color,
  double radius = 20,
  Color? borderColor,
  List<BoxShadow>? shadows,
}) {
  return BoxDecoration(
    color: color ?? AppColors.surface,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: borderColor ?? AppColors.glassBorder),
    boxShadow: shadows ??
        [
          BoxShadow(
            color: Colors.black.withAlpha(60),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
  );
}
