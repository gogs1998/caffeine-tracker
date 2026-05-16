import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class AppColors {
  // Surfaces
  static const bg = Color(0xFFF2EBDF);
  static const bg2 = Color(0xFFEBE3D2);
  static const card = Color(0xFFFBF7EE);
  static const cardWarm = Color(0xFFF7EFDD);
  static const line = Color(0x1A1A1410);
  static const line2 = Color(0x2E1A1410);

  // Ink
  static const ink = Color(0xFF1A1410);
  static const ink2 = Color(0xFF3A2E25);
  static const muted = Color(0xFF75665A);
  static const muted2 = Color(0xFFA0917F);

  // Brand / status
  static const crema = Color(0xFFC77D3F);
  static const cremaDk = Color(0xFF9F5E27);
  static const cremaTn = Color(0xFFF2DDC1);
  static const tea = Color(0xFF5F7A3F);
  static const teaTn = Color(0xFFDCE3CC);
  static const burnt = Color(0xFFB23A28);
  static const burntTn = Color(0xFFF2D1C9);
  static const night = Color(0xFF2B3148);
  static const night2 = Color(0xFF424A6B);

  // Legacy compat aliases
  static const surface = card;
  static const amber = crema;
  static const safe = tea;
  static const danger = burnt;
  static const caution = crema;
  static const textPrimary = ink;
  static const textSecondary = muted;
  static const textTertiary = muted2;
  static const textDisabled = Color(0xFFC0B8AD);
  static const glassBorder = line;
  static const glassLayer = Color(0x0A1A1410);
  // Extra legacy aliases
  static const orange = crema;
  static const purple = night;
}

abstract class AppFonts {
  static const display = 'Newsreader';
  static const mono = 'JetBrains Mono';
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.light(
        primary: AppColors.crema,
        secondary: AppColors.tea,
        surface: AppColors.card,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.ink,
        error: AppColors.burnt,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: const CardTheme(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.line,
        thickness: 0.5,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.crema, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.muted2),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.crema,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.crema),
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        bodyLarge: const TextStyle(color: AppColors.ink),
        bodyMedium: const TextStyle(color: AppColors.ink),
      ),
    );
  }

  // Legacy alias used by main.dart
  static ThemeData build() => light();
}

// Reusable card decoration (kept for legacy widget compat)
BoxDecoration surfaceCard({
  Color? color,
  double radius = 18,
  Color? borderColor,
  List<BoxShadow>? shadows,
}) {
  return BoxDecoration(
    color: color ?? AppColors.card,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(
      color: borderColor ?? const Color(0x0D1A1410),
      width: 0.5,
    ),
    boxShadow: shadows ??
        [
          const BoxShadow(
            color: Color(0x0A1A1410),
            blurRadius: 24,
            offset: Offset(0, 6),
          ),
          const BoxShadow(
            color: Color(0x041A1410),
            blurRadius: 1,
            offset: Offset(0, 1),
          ),
        ],
  );
}
