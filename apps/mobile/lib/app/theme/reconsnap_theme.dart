import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_tokens.dart';

/// ReconSnap brand palette — **dark executive** edition.
///
/// A deep charcoal-navy canvas, silver/white text, and a single refined **gold**
/// accent reserved for primary actions and trust seals. Validation green is kept
/// as a *semantic* colour (reconciled / passed); amber and red stay for warning
/// and risk. Gold is used sparingly so the system reads premium, not gaudy.
class ReconSnapColors {
  // Brand navy (hero / seals / brand mark)
  static const ink = Color(0xFF0E1726);
  static const inkSoft = Color(0xFF1B2A44);

  // Premium accent
  static const gold = Color(0xFFCBA35A);
  static const goldSoft = Color(0xFFE3C485);

  // Validation / semantic
  static const accentGreen = Color(0xFF34D399);
  static const accentGreenDark = Color(0xFF34D399);
  static const actionBlue = Color(0xFF6AA8FF);

  // Text scale (light on dark)
  static const ink900 = Color(0xFFEEF3F9); // primary text / headings
  static const ink700 = Color(0xFFB8C4D4); // secondary text / icons
  static const mutedInk = Color(0xFF8A99AD); // body / captions
  static const ink400 = Color(0xFF5C6B82); // faint / chevrons

  // Surfaces
  static const surface = Color(0xFF0A0F1A); // scaffold canvas
  static const card = Color(0xFF131C2B); // elevated card
  static const subtle = Color(0xFF1A2333); // chips / inset blocks
  static const border = Color(0xFF273247); // hairline

  // Semantic surfaces (dark tints)
  static const warningAmber = Color(0xFFE0A93B);
  static const warningSurface = Color(0xFF2A2210);
  static const riskRed = Color(0xFFF26B66);
  static const riskSurface = Color(0xFF2A1514);
  static const successSurface = Color(0xFF0F2A20);
  static const infoSurface = Color(0xFF13233F);

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [ink, inkSoft],
  );

  /// Reserved for premium accents (seals, the upgrade marker).
  static const goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [goldSoft, gold],
  );
}

class ReconSnapTheme {
  static ThemeData get light => dark; // single source; app uses the dark system

  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: ReconSnapColors.gold,
      onPrimary: ReconSnapColors.ink,
      secondary: ReconSnapColors.accentGreen,
      onSecondary: ReconSnapColors.ink,
      surface: ReconSnapColors.card,
      onSurface: ReconSnapColors.ink900,
      error: ReconSnapColors.riskRed,
      onError: ReconSnapColors.ink,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: ReconSnapColors.surface,
      fontFamily: GoogleFonts.manrope().fontFamily,
      splashFactory: InkSparkle.splashFactory,
      // Manrope over the calibrated size/weight scale below; hierarchy intact.
      textTheme: GoogleFonts.manropeTextTheme(_textTheme),
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
          // Gold primary action = the executive accent, used everywhere a
          // primary CTA appears. Dark navy text keeps AA contrast on gold.
          backgroundColor: ReconSnapColors.gold,
          foregroundColor: ReconSnapColors.ink,
          disabledBackgroundColor: ReconSnapColors.border,
          disabledForegroundColor: ReconSnapColors.ink400,
          minimumSize: const Size.fromHeight(54),
          elevation: 4,
          shadowColor: ReconSnapColors.gold.withValues(alpha: 0.45),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
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
          backgroundColor: ReconSnapColors.card,
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
          side: const BorderSide(color: ReconSnapColors.border, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.all(AppRadius.md),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ReconSnapColors.goldSoft,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: ReconSnapColors.subtle,
        selectedColor: ReconSnapColors.gold,
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
        backgroundColor: ReconSnapColors.inkSoft,
        contentTextStyle: const TextStyle(
          color: ReconSnapColors.ink900,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.all(AppRadius.md),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ReconSnapColors.card,
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
          borderSide: const BorderSide(color: ReconSnapColors.gold, width: 1.6),
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
