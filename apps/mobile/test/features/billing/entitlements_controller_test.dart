import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reconsnap_statement_converter/core/billing/billing_service.dart';
import 'package:reconsnap_statement_converter/core/billing/entitlements.dart';
import 'package:reconsnap_statement_converter/core/billing/local_billing_service.dart';
import 'package:reconsnap_statement_converter/features/billing/presentation/entitlements_controller.dart';

void main() {
  test(
    'gating: consume to zero blocks, purchase re-enables, pro is unlimited',
    () async {
      final dir = await Directory.systemTemp.createTemp('reconsnap_ctrl');
      final file = File('${dir.path}/entitlements.json');
      final container = ProviderContainer(
        overrides: [
          billingServiceProvider.overrideWithValue(
            LocalBillingService(fileLocator: () async => file),
          ),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(entitlementsProvider.notifier);

      // Starts with the free allowance and can convert.
      expect(
        container.read(entitlementsProvider).availableCredits,
        Entitlements.freeAllowance,
      );
      expect(container.read(entitlementsProvider).canConvert, isTrue);

      // Spend every free conversion → gated.
      for (var i = 0; i < Entitlements.freeAllowance; i++) {
        await controller.consumeOne();
      }
      expect(container.read(entitlementsProvider).canConvert, isFalse);

      // Buying a pack re-enables conversions.
      await controller.purchase(BillingProduct.credits10);
      expect(container.read(entitlementsProvider).canConvert, isTrue);
      expect(container.read(entitlementsProvider).availableCredits, 10);

      // Going Pro is unlimited.
      await controller.purchase(BillingProduct.proYearly);
      expect(container.read(entitlementsProvider).isPro, isTrue);
      expect(container.read(entitlementsProvider).availableCredits, isNull);

      await dir.delete(recursive: true);
    },
  );
}
