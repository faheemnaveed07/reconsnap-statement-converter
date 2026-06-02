import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:reconsnap_statement_converter/core/billing/billing_service.dart';
import 'package:reconsnap_statement_converter/core/billing/entitlements.dart';
import 'package:reconsnap_statement_converter/core/billing/local_billing_service.dart';

void main() {
  Future<(LocalBillingService, Directory)> makeService() async {
    final dir = await Directory.systemTemp.createTemp('reconsnap_billing');
    final file = File('${dir.path}/entitlements.json');
    return (LocalBillingService(fileLocator: () async => file), dir);
  }

  test('fresh install loads the free allowance', () async {
    final (service, dir) = await makeService();
    final e = await service.load();
    expect(e.availableCredits, Entitlements.freeAllowance);
    await dir.delete(recursive: true);
  });

  test('purchasing a credit pack persists and reloads', () async {
    final (service, dir) = await makeService();
    await service.purchase(BillingProduct.credits10);
    final reloaded = await service.load();
    expect(reloaded.paidCredits, 10);
    await dir.delete(recursive: true);
  });

  test('purchasing Pro persists unlimited', () async {
    final (service, dir) = await makeService();
    await service.purchase(BillingProduct.proMonthly);
    final reloaded = await service.load();
    expect(reloaded.isPro, isTrue);
    expect(reloaded.availableCredits, isNull);
    await dir.delete(recursive: true);
  });

  test('consume persists across reloads', () async {
    final (service, dir) = await makeService();
    await service.consumeOne();
    await service.consumeOne();
    final reloaded = await service.load();
    expect(reloaded.freeRemaining, Entitlements.freeAllowance - 2);
    await dir.delete(recursive: true);
  });

  test('corrupt file falls back to free allowance', () async {
    final dir = await Directory.systemTemp.createTemp('reconsnap_billing_bad');
    final file = File('${dir.path}/entitlements.json')
      ..writeAsStringSync('{ not json');
    final service = LocalBillingService(fileLocator: () async => file);
    expect((await service.load()).availableCredits, Entitlements.freeAllowance);
    await dir.delete(recursive: true);
  });
}
