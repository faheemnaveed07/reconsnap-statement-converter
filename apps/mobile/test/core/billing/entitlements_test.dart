import 'package:flutter_test/flutter_test.dart';
import 'package:reconsnap_statement_converter/core/billing/entitlements.dart';

void main() {
  test('free allowance is available before any purchase', () {
    const e = Entitlements();
    expect(e.availableCredits, Entitlements.freeAllowance);
    expect(e.canConvert, isTrue);
    expect(e.isPro, isFalse);
  });

  test('consume spends free credits first, then paid', () {
    var e = const Entitlements(paidCredits: 2);
    expect(e.availableCredits, Entitlements.freeAllowance + 2);

    // Exhaust the free allowance.
    for (var i = 0; i < Entitlements.freeAllowance; i++) {
      e = e.consumeOne();
    }
    expect(e.freeRemaining, 0);
    expect(e.paidCredits, 2);

    e = e.consumeOne();
    expect(e.paidCredits, 1);
  });

  test('out of credits blocks conversion', () {
    var e = Entitlements(freeUsed: Entitlements.freeAllowance);
    expect(e.availableCredits, 0);
    expect(e.canConvert, isFalse);
    // Consuming when empty is a no-op, never negative.
    e = e.consumeOne();
    expect(e.paidCredits, 0);
  });

  test('pro is unlimited and never consumes', () {
    const e = Entitlements(isPro: true);
    expect(e.availableCredits, isNull);
    expect(e.canConvert, isTrue);
    expect(e.consumeOne(), same(e));
  });

  test('json round-trip', () {
    const e = Entitlements(isPro: false, freeUsed: 3, paidCredits: 7);
    final back = Entitlements.fromJson(e.toJson());
    expect(back.freeUsed, 3);
    expect(back.paidCredits, 7);
    expect(back.isPro, isFalse);
  });
}
