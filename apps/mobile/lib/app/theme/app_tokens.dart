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
/// subtle so the UI reads as calm and precise rather than heavy.
class AppShadows {
  const AppShadows._();

  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0F101828),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
    BoxShadow(
      color: Color(0x14101828),
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> raised = [
    BoxShadow(
      color: Color(0x1A101828),
      blurRadius: 28,
      offset: Offset(0, 14),
    ),
  ];
}
