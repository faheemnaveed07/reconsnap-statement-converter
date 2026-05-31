import 'package:flutter/material.dart';

class ReconSnapColors {
  static const ink = Color(0xFF102033);
  static const mutedInk = Color(0xFF667085);
  static const surface = Color(0xFFF7F9FB);
  static const card = Color(0xFFFFFFFF);
  static const border = Color(0xFFDCE3EA);
  static const accentGreen = Color(0xFF0E9F6E);
  static const actionBlue = Color(0xFF2563EB);
  static const warningAmber = Color(0xFFB7791F);
  static const riskRed = Color(0xFFD92D20);
}

class ReconSnapTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: ReconSnapColors.accentGreen,
      primary: ReconSnapColors.ink,
      secondary: ReconSnapColors.accentGreen,
      surface: ReconSnapColors.surface,
      error: ReconSnapColors.riskRed,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: ReconSnapColors.surface,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: ReconSnapColors.surface,
        foregroundColor: ReconSnapColors.ink,
        titleTextStyle: TextStyle(
          color: ReconSnapColors.ink,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: ReconSnapColors.card,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: ReconSnapColors.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ReconSnapColors.ink,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ReconSnapColors.ink,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: ReconSnapColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: ReconSnapColors.ink,
        labelStyle: const TextStyle(color: ReconSnapColors.ink),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: ReconSnapColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: ReconSnapColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: ReconSnapColors.actionBlue),
        ),
      ),
    );
  }
}
