import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_tokens.dart';

/// ReconSnap brand palette — **Editorial Ledger** edition.
///
/// A trust-first identity that feels like a well-made ledger, not a startup: a
/// warm paper canvas, near-black ink, a single terracotta accent for human
/// emphasis, and a calm moss green reserved *exclusively* for "verified /
/// reconciled". Hierarchy comes from typographic scale, weight and white space —
/// never from gradients, glow, or a wall of icons. Money is always set in mono
/// with tabular lining figures so columns align to the cent.
///
/// Discipline rules (enforced by convention across screens):
///   • Moss means *verified only*. A screen with no verification has no green.
///   • One terracotta moment per screen. Accents stop being accents if repeated.
///   • Status colour always pairs with text or an icon — never colour alone.
///   • Depth = a hairline border + the paper. No gradients/glow/glass/shadows.
class ReconSnapColors {
  // ── Core palette ────────────────────────────────────────────────────
  /// Canvas. Warm off-white — calmer than zinc grey.
  static const paper = Color(0xFFFDFDF9);

  /// Text, primary buttons, the wordmark. A near-black desaturated charcoal.
  static const ink = Color(0xFF232929);

  /// The single human accent — brand, emphasis, links. Used sparingly.
  static const terracotta = Color(0xFF8C4F3C);

  /// Reserved for "verified / reconciled" fills and large elements. Nothing
  /// else. Pale, so pair with [mossDeep] for any text.
  static const moss = Color(0xFFA7B9AC);

  // ── Functional extension (earth tones tuned to paper) ───────────────
  /// Verified text/icons — contrast-safe moss for "reconciled" copy.
  static const mossDeep = Color(0xFF5F7A66);

  /// Needs review / warning.
  static const ochre = Color(0xFF9A6B22);

  /// Failed / error. A red that belongs on paper.
  static const brick = Color(0xFF8E3B30);

  // ── Ink tints (structure: muted text, borders, fills) ───────────────
  static const ink900 = ink; // headings / primary text
  static const ink700 = Color(0xFF3C4441); // body
  static const mutedInk = Color(0xFF6B7270); // captions / meta
  static const ink400 = Color(0xFF9AA09C); // faint / chevrons / disabled
  static const border = Color(0xFFE6E5DC); // hairline on paper
  static const outline = Color(0xFFD5D4C8); // stronger stroke

  // ── Surfaces (warm paper tiers) ─────────────────────────────────────
  /// Card surface — a hair lighter/cleaner than the canvas.
  static const card = Color(0xFFFFFFFD);
  static const containerLowest = Color(0xFFFFFFFD);
  static const containerLow = Color(0xFFF7F6EF); // inset blocks / fields
  static const container = Color(0xFFF1F0E7); // chips / subtle fills
  static const containerHigh = Color(0xFFEAE9DD);
  static const containerHighest = Color(0xFFE2E1D4);
  static const subtle = container;

  // ── Tinted status surfaces (muted, on-paper) ────────────────────────
  static const verifiedSurface = Color(0xFFEBF0EC); // moss tint
  static const reviewSurface = Color(0xFFF5EEDD); // ochre tint
  static const failSurface = Color(0xFFF6E7E3); // brick tint
  static const accentSurface = Color(0xFFF4E9E3); // terracotta tint

  // ── Primary (ink on paper) ──────────────────────────────────────────
  static const primary = ink;
  static const onPrimary = paper;
  static const primaryContainer = Color(0xFF2E3633);
  static const onPrimaryContainer = Color(0xFFE6E5DC);
  static const inkSoft = Color(0xFF2E3633);

  // ── Legacy semantic aliases (kept so screens compile during migration;
  //    all now resolve to the editorial palette, not the old fintech one) ──
  static const surface = paper;
  static const accentGreen = mossDeep; // "verified"
  static const accentGreenDark = mossDeep;
  static const secondaryContainer = verifiedSurface;
  static const onSecondaryContainer = mossDeep;
  static const secondaryFixed = moss;
  static const actionBlue = terracotta; // info → terracotta (no blue)
  static const infoSurface = accentSurface;
  static const successSurface = verifiedSurface;
  static const warningAmber = ochre;
  static const warningSurface = reviewSurface;
  static const riskRed = brick;
  static const riskSurface = failSurface;
  static const onRiskContainer = brick;

  /// Back-compat for the retired dark hero panel / brand mark. Flat ink — no
  /// real gradient (kept only so old call-sites resolve until rewritten).
  static const heroGradient = LinearGradient(colors: [ink, ink]);
}

class ReconSnapTheme {
  // The product is a single warm-paper system; both getters resolve here.
  static ThemeData get dark => light;

  static ThemeData get light {
    const scheme = ColorScheme.light(
      primary: ReconSnapColors.primary,
      onPrimary: ReconSnapColors.onPrimary,
      primaryContainer: ReconSnapColors.primaryContainer,
      onPrimaryContainer: ReconSnapColors.onPrimaryContainer,
      secondary: ReconSnapColors.mossDeep,
      onSecondary: Colors.white,
      secondaryContainer: ReconSnapColors.verifiedSurface,
      onSecondaryContainer: ReconSnapColors.mossDeep,
      tertiary: ReconSnapColors.terracotta,
      onTertiary: Colors.white,
      surface: ReconSnapColors.paper,
      onSurface: ReconSnapColors.ink900,
      onSurfaceVariant: ReconSnapColors.ink700,
      outline: ReconSnapColors.outline,
      outlineVariant: ReconSnapColors.border,
      error: ReconSnapColors.brick,
      onError: Colors.white,
      errorContainer: ReconSnapColors.failSurface,
      onErrorContainer: ReconSnapColors.brick,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: ReconSnapColors.paper,
      fontFamily: GoogleFonts.inter().fontFamily,
      splashFactory: InkSparkle.splashFactory,
      textTheme: _buildTextTheme(),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: ReconSnapColors.paper,
        foregroundColor: ReconSnapColors.ink900,
        titleTextStyle: serif(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: ReconSnapColors.card,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.all(AppRadius.md),
          side: const BorderSide(color: ReconSnapColors.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          // Primary CTA — ink on paper. Calm, high-contrast, modern.
          backgroundColor: ReconSnapColors.ink,
          foregroundColor: ReconSnapColors.onPrimary,
          disabledBackgroundColor: ReconSnapColors.container,
          disabledForegroundColor: ReconSnapColors.ink400,
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.all(AppRadius.md),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          // Secondary: paper surface, hairline border, ink text.
          foregroundColor: ReconSnapColors.ink900,
          backgroundColor: ReconSnapColors.card,
          minimumSize: const Size.fromHeight(50),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
          side: const BorderSide(color: ReconSnapColors.outline, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.all(AppRadius.md),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          // Quiet text links carry the single terracotta accent.
          foregroundColor: ReconSnapColors.terracotta,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: ReconSnapColors.container,
        selectedColor: ReconSnapColors.ink,
        side: BorderSide.none,
        labelStyle: const TextStyle(
          color: ReconSnapColors.ink700,
          fontWeight: FontWeight.w600,
          fontSize: 12,
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
        backgroundColor: ReconSnapColors.paper,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ReconSnapColors.ink,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.all(AppRadius.md),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ReconSnapColors.containerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        hintStyle: const TextStyle(color: ReconSnapColors.mutedInk),
        labelStyle: const TextStyle(color: ReconSnapColors.mutedInk),
        border: OutlineInputBorder(
          borderRadius: AppRadius.all(AppRadius.md),
          borderSide: const BorderSide(color: ReconSnapColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.all(AppRadius.md),
          borderSide: const BorderSide(color: ReconSnapColors.border),
        ),
        // Focus ring uses the terracotta accent.
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.all(AppRadius.md),
          borderSide: const BorderSide(
            color: ReconSnapColors.terracotta,
            width: 1.6,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.all(AppRadius.md),
          borderSide: const BorderSide(color: ReconSnapColors.brick),
        ),
      ),
    );
  }

  /// Editorial serif — the human voice. Page titles, display headlines, the
  /// reconciliation verdict. Warm, considered, authoritative. Ship target is
  /// Fraunces/Newsreader; we use **Lora**, which reads the same intent.
  static TextStyle serif({
    double fontSize = 24,
    FontWeight fontWeight = FontWeight.w600,
    Color color = ReconSnapColors.ink900,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.lora(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  /// Monospace — the proof. Every figure: currency, balances, dates,
  /// transaction IDs, the reconciliation delta. Tabular lining figures so
  /// columns align. **Money is never set in the sans.** Ship face: JetBrains
  /// Mono.
  static TextStyle mono({
    double fontSize = 13,
    FontWeight fontWeight = FontWeight.w500,
    Color color = ReconSnapColors.ink900,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      fontFeatures: const [
        FontFeature.tabularFigures(),
        FontFeature.liningFigures(),
      ],
    );
  }

  /// Tracked uppercase eyebrow / label — the grotesque sans doing metadata.
  static TextStyle eyebrow({
    double fontSize = 11,
    Color color = ReconSnapColors.mutedInk,
    FontWeight fontWeight = FontWeight.w700,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: fontSize * 0.14,
      height: 1.2,
    );
  }

  /// Text theme: serif carries display/titles (the human moments); the
  /// grotesque sans carries body, labels and controls (the machine).
  static TextTheme _buildTextTheme() {
    final base = GoogleFonts.interTextTheme();
    return base.copyWith(
      // Serif — display & titles.
      displaySmall: serif(
        fontSize: 34,
        height: 1.12,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      headlineSmall: serif(
        fontSize: 24,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.24,
      ),
      titleLarge: serif(
        fontSize: 18,
        height: 1.3,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
      ),
      // Sans — section titles, body, labels.
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        height: 1.4,
        fontWeight: FontWeight.w700,
        color: ReconSnapColors.ink900,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: ReconSnapColors.ink900,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        height: 1.55,
        color: ReconSnapColors.ink700,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        height: 1.5,
        color: ReconSnapColors.ink700,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        height: 1.4,
        color: ReconSnapColors.mutedInk,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: ReconSnapColors.ink900,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 11,
        height: 1.3,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
        color: ReconSnapColors.mutedInk,
      ),
    );
  }
}
