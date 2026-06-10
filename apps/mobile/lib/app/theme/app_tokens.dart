import 'package:flutter/material.dart';

/// Design tokens — the single source of truth for spacing, corner radii, and
/// elevation. Screens reference these instead of hard-coding magic numbers so
/// the product stays visually consistent as it grows.
///
/// Values follow the **Financial Interface** system: a strict 4px baseline
/// grid, "professional-soft" 4–24px radii, and minimal depth — in dark mode
/// hierarchy comes from tonal layers and low-contrast outlines, not heavy
/// shadows ("Swiss-style minimalism / Stealth Authority").
class AppSpacing {
  const AppSpacing._();

  /// 4px baseline grid.
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  /// Extra step for the rare oversized gap.
  static const double xxxl = 64;

  /// Horizontal page gutter.
  static const double gutter = 24;

  /// Standard page padding (mobile side margins = 16).
  static const EdgeInsets page = EdgeInsets.fromLTRB(16, 16, 16, 32);
}

/// "Professional-soft" shape language — an 8px standard radius across primary
/// containers, buttons and inputs; tighter for tags, looser for large surfaces.
class AppRadius {
  const AppRadius._();

  static const double sm = 4; // tags, checkboxes, small chips
  static const double md = 8; // DEFAULT — buttons, inputs, cards
  static const double lg = 16; // modals, feature hero
  static const double xl = 24; // large hero surfaces
  static const double pill = 999;

  static BorderRadius all(double r) => BorderRadius.circular(r);
}

/// Depth comes from a hairline border on the warm paper canvas — not from
/// shadows. The brand discipline is explicit: **no gradients, glow,
/// glassmorphism, or floating shadows.** The only place a shadow is permitted is
/// a transient floating surface (a modal sheet or menu lifting off the page),
/// and even there it is a barely-there diffusion. Cards, buttons and pills carry
/// no shadow at all — the border and the paper do the work.
class AppShadows {
  const AppShadows._();

  /// No elevation. Flat surfaces are the default — the hairline border carries
  /// every card and button. Kept as an empty list so call-sites read clearly.
  static const List<BoxShadow> none = [];

  /// Back-compat aliases — all flat now. Depth = border + paper.
  static const List<BoxShadow> soft = none;
  static const List<BoxShadow> card = none;
  static const List<BoxShadow> button = none;

  /// The single allowed lift: a transient modal sheet / menu floating off the
  /// page. A soft, low-opacity ink diffusion — never used on in-page content.
  static const List<BoxShadow> raised = [
    BoxShadow(color: Color(0x14232929), blurRadius: 28, offset: Offset(0, 14)),
  ];
}
