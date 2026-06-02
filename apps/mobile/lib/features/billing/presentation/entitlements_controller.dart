import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/billing/billing_service.dart';
import '../../../core/billing/entitlements.dart';
import '../../../core/billing/local_billing_service.dart';

/// The billing backend. Swap [LocalBillingService] for a RevenueCat-backed
/// implementation at launch — the rest of the app depends only on
/// [BillingService].
final billingServiceProvider = Provider<BillingService>(
  (ref) => LocalBillingService(),
);

final entitlementsProvider =
    NotifierProvider<EntitlementsController, Entitlements>(
      EntitlementsController.new,
    );

/// Holds the current [Entitlements] and exposes purchase/restore/consume.
///
/// Starts from the free allowance and loads persisted state asynchronously so
/// app start is never blocked. The conversion flow calls [consumeOne] on a
/// successful real conversion; the UI calls [purchase]/[restore].
class EntitlementsController extends Notifier<Entitlements> {
  BillingService get _service => ref.read(billingServiceProvider);

  @override
  Entitlements build() {
    _restore();
    return const Entitlements();
  }

  Future<void> _restore() async {
    state = await _service.load();
  }

  Future<void> consumeOne() async {
    state = await _service.consumeOne();
  }

  Future<void> purchase(BillingProduct product) async {
    state = await _service.purchase(product);
  }

  Future<void> restorePurchases() async {
    state = await _service.restore();
  }
}
