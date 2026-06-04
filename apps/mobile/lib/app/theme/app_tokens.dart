import 'package:flutter/material.dart';

/// Design tokens — the single source of truth for spacing, corner radii, and
/// elevation. Screens reference these instead of hard-coding magic numbers so
/// the product stays visually consistent as it grows.
class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 28;
  static const double xxxl = 40;

  /// Standard page gutter.
  static const EdgeInsets page = EdgeInsets.fromLTRB(20, 16, 20, 32);
}

class AppRadius {
  const AppRadius._();

  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
  static const double pill = 999;

  static BorderRadius all(double r) => BorderRadius.circular(r);
}

/// Soft, layered shadows tuned for a light fintech surface — deliberately
/// subtle so the UI reads as calm and precise rather than heavy. Premium depth
/// comes from *stacking* a tight contact shadow under a wide ambient one.
class AppShadows {
  const AppShadows._();

  /// Pills / small chips — a single whisper-soft shadow.
  static const List<BoxShadow> soft = [
    BoxShadow(color: Color(0x0D101828), blurRadius: 8, offset: Offset(0, 2)),
  ];

  /// Primary content cards: a crisp contact shadow + a soft ambient lift.
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0F1A2540), blurRadius: 1, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0F1A2540), blurRadius: 3, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x141A2540), blurRadius: 24, offset: Offset(0, 12)),
  ];

  /// Tactile buttons — a tinted, directional shadow so they read as pressable.
  static const List<BoxShadow> button = [
    BoxShadow(color: Color(0x2B0B1B2B), blurRadius: 16, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x140B1B2B), blurRadius: 2, offset: Offset(0, 1)),
  ];

  /// Hero / elevated surfaces.
  static const List<BoxShadow> raised = [
    BoxShadow(color: Color(0x24101828), blurRadius: 36, offset: Offset(0, 18)),
    BoxShadow(color: Color(0x0F101828), blurRadius: 2, offset: Offset(0, 1)),
  ];
}

/// Subtle overlay gradients that give flat surfaces depth without colour shifts.
class AppGradients {
  const AppGradients._();

  /// A faint top-down sheen for elevated dark cards — a subtle inner glow that
  /// lifts the surface off the canvas just enough to feel crafted.
  static const LinearGradient cardSheen = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF17212F), Color(0xFF121A28)],
  );
}
