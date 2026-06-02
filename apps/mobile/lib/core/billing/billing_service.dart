import 'entitlements.dart';

/// The purchasable products. Kept abstract so the IDs map onto store products
/// (App Store / Play) when the real billing backend is wired in.
enum BillingProduct { credits10, proMonthly, proYearly }

extension BillingProductInfo on BillingProduct {
  String get title => switch (this) {
    BillingProduct.credits10 => '10 conversions',
    BillingProduct.proMonthly => 'Pro — monthly',
    BillingProduct.proYearly => 'Pro — yearly',
  };

  String get subtitle => switch (this) {
    BillingProduct.credits10 => 'One-off credit pack. Never expires.',
    BillingProduct.proMonthly => 'Unlimited conversions, billed monthly.',
    BillingProduct.proYearly => 'Unlimited conversions, best value.',
  };

  /// Placeholder price labels until store products are configured. The real
  /// localized price comes from the store at launch.
  String get priceLabel => switch (this) {
    BillingProduct.credits10 => r'$4.99',
    BillingProduct.proMonthly => r'$9.99/mo',
    BillingProduct.proYearly => r'$79.99/yr',
  };

  bool get isSubscription =>
      this == BillingProduct.proMonthly || this == BillingProduct.proYearly;
}

/// Abstraction over the billing backend. `LocalBillingService` implements it for
/// development and tests; a RevenueCat/`in_app_purchase` implementation slots in
/// at launch without touching the UI or the conversion flow.
abstract interface class BillingService {
  Future<Entitlements> load();

  /// Grants the product's entitlement and persists it. (In the real impl this
  /// runs after the store confirms the purchase.)
  Future<Entitlements> purchase(BillingProduct product);

  /// Re-applies previously purchased entitlements (store "Restore purchases").
  Future<Entitlements> restore();

  /// Spends one conversion credit and persists the result.
  Future<Entitlements> consumeOne();
}
