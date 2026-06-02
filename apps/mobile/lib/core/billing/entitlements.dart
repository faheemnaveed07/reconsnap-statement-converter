/// What the user is currently entitled to convert.
///
/// Deliberately simple and provider-agnostic so the same model works behind a
/// local (dev/test) billing implementation today and RevenueCat / in_app_purchase
/// at launch. Metering is per *conversion* in v1 (one statement = one credit);
/// the unit can later become pages without changing callers.
class Entitlements {
  const Entitlements({
    this.isPro = false,
    this.freeUsed = 0,
    this.paidCredits = 0,
  });

  /// Active unlimited subscription.
  final bool isPro;

  /// How many of the free-tier conversions have been used.
  final int freeUsed;

  /// Purchased one-off conversion credits remaining.
  final int paidCredits;

  /// Conversions included free, before any purchase.
  static const freeAllowance = 5;

  int get freeRemaining =>
      (freeAllowance - freeUsed).clamp(0, freeAllowance).toInt();

  /// Total conversions available now (free + paid). Null means unlimited (Pro).
  int? get availableCredits => isPro ? null : freeRemaining + paidCredits;

  bool get canConvert => isPro || freeRemaining > 0 || paidCredits > 0;

  /// Spends one conversion: Pro is free, then free-tier, then paid credits.
  Entitlements consumeOne() {
    if (isPro) return this;
    if (freeRemaining > 0) return copyWith(freeUsed: freeUsed + 1);
    if (paidCredits > 0) return copyWith(paidCredits: paidCredits - 1);
    return this;
  }

  Entitlements copyWith({bool? isPro, int? freeUsed, int? paidCredits}) {
    return Entitlements(
      isPro: isPro ?? this.isPro,
      freeUsed: freeUsed ?? this.freeUsed,
      paidCredits: paidCredits ?? this.paidCredits,
    );
  }

  Map<String, dynamic> toJson() => {
    'isPro': isPro,
    'freeUsed': freeUsed,
    'paidCredits': paidCredits,
  };

  factory Entitlements.fromJson(Map<String, dynamic> json) => Entitlements(
    isPro: (json['isPro'] as bool?) ?? false,
    freeUsed: (json['freeUsed'] as num?)?.toInt() ?? 0,
    paidCredits: (json['paidCredits'] as num?)?.toInt() ?? 0,
  );
}
