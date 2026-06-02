import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// ReconSnap brand palette.
///
/// A restrained fintech system: a deep ink/navy brand colour, a single trust
/// green for success/validation, and a calibrated neutral scale for text,
/// borders, and surfaces. Semantic colours (amber/red) are reserved for
/// warnings and risk so they carry real meaning in the UI.
class ReconSnapColors {
  // Brand
  static const ink = Color(0xFF0B1B2B); // primary brand / headings
  static const inkSoft = Color(0xFF1D2F40); // gradient partner
  static const accentGreen = Color(0xFF0E9F6E);
  static const accentGreenDark = Color(0xFF057A52);
  static const actionBlue = Color(0xFF2563EB);

  // Neutrals
  static const ink900 = Color(0xFF0B1B2B);
  static const ink700 = Color(0xFF334155);
  static const mutedInk = Color(0xFF64748B);
  static const ink400 = Color(0xFF94A3B8);
  static const border = Color(0xFFE6EBF1);
  static const subtle = Color(0xFFEEF2F6);
  static const surface = Color(0xFFF6F8FB);
  static const card = Color(0xFFFFFFFF);

  // Semantic
  static const warningAmber = Color(0xFFB7791F);
  static const warningSurface = Color(0xFFFEF6E7);
  static const riskRed = Color(0xFFD92D20);
  static const riskSurface = Color(0xFFFEF1F0);
  static const successSurface = Color(0xFFE7F7F0);

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [ink, inkSoft],
  );
}

class ReconSnapTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: ReconSnapColors.accentGreen,
      primary: ReconSnapColors.ink,
      onPrimary: Colors.white,
      secondary: ReconSnapColors.accentGreen,
      surface: ReconSnapColors.card,
      onSurface: ReconSnapColors.ink900,
      error: ReconSnapColors.riskRed,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: ReconSnapColors.surface,
      fontFamily: 'Roboto',
      splashFactory: InkSparkle.splashFactory,
      textTheme: _textTheme,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: ReconSnapColors.surface,
        foregroundColor: ReconSnapColors.ink900,
        titleTextStyle: TextStyle(
          color: ReconSnapColors.ink900,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: ReconSnapColors.card,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.all(AppRadius.lg),
          side: const BorderSide(color: ReconSnapColors.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ReconSnapColors.ink,
          foregroundColor: Colors.white,
          disabledBackgroundColor: ReconSnapColors.ink400,
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.all(AppRadius.md),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ReconSnapColors.ink900,
          backgroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
          side: const BorderSide(color: ReconSnapColors.border, width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.all(AppRadius.md),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ReconSnapColors.actionBlue,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: ReconSnapColors.subtle,
        selectedColor: ReconSnapColors.ink,
        side: BorderSide.none,
        labelStyle: const TextStyle(
          color: ReconSnapColors.ink700,
          fontWeight: FontWeight.w600,
          fontSize: 12.5,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.all(AppRadius.pill),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: ReconSnapColors.border,
        thickness: 1,
        space: 1,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: ReconSnapColors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ReconSnapColors.ink900,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.all(AppRadius.md),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: const TextStyle(color: ReconSnapColors.mutedInk),
        border: OutlineInputBorder(
          borderRadius: AppRadius.all(AppRadius.md),
          borderSide: const BorderSide(color: ReconSnapColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.all(AppRadius.md),
          borderSide: const BorderSide(color: ReconSnapColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.all(AppRadius.md),
          borderSide: const BorderSide(
            color: ReconSnapColors.actionBlue,
            width: 1.6,
          ),
        ),
      ),
    );
  }

  static const TextTheme _textTheme = TextTheme(
    displaySmall: TextStyle(
      fontSize: 30,
      height: 1.1,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.6,
      color: ReconSnapColors.ink900,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      height: 1.15,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.4,
      color: ReconSnapColors.ink900,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      height: 1.2,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.2,
      color: ReconSnapColors.ink900,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      height: 1.25,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.1,
      color: ReconSnapColors.ink900,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: ReconSnapColors.ink900,
    ),
    bodyLarge: TextStyle(
      fontSize: 15.5,
      height: 1.45,
      color: ReconSnapColors.ink700,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      height: 1.45,
      color: ReconSnapColors.mutedInk,
    ),
    bodySmall: TextStyle(
      fontSize: 12.5,
      height: 1.4,
      color: ReconSnapColors.mutedInk,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: ReconSnapColors.ink900,
    ),
  );
}
