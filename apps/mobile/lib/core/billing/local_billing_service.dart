import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'billing_service.dart';
import 'entitlements.dart';

/// On-device [BillingService] used during development and tests.
///
/// Persists entitlements to a JSON file (same posture as conversion history)
/// and "grants" purchases locally so the whole paywall + gating flow can be
/// built and validated with no store account. Swap for a RevenueCat-backed
/// implementation at launch; nothing else changes.
class LocalBillingService implements BillingService {
  LocalBillingService({Future<File> Function()? fileLocator})
    : _fileLocator = fileLocator ?? _defaultFile;

  final Future<File> Function() _fileLocator;

  static Future<File> _defaultFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/entitlements.json');
  }

  @override
  Future<Entitlements> load() async {
    try {
      final file = await _fileLocator();
      if (!await file.exists()) return const Entitlements();
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return const Entitlements();
      return Entitlements.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const Entitlements();
    }
  }

  @override
  Future<Entitlements> purchase(BillingProduct product) async {
    final current = await load();
    final updated = switch (product) {
      BillingProduct.credits10 => current.copyWith(
        paidCredits: current.paidCredits + 10,
      ),
      BillingProduct.proMonthly ||
      BillingProduct.proYearly => current.copyWith(isPro: true),
    };
    await _save(updated);
    return updated;
  }

  @override
  Future<Entitlements> restore() async => load();

  @override
  Future<Entitlements> consumeOne() async {
    final updated = (await load()).consumeOne();
    await _save(updated);
    return updated;
  }

  Future<void> _save(Entitlements e) async {
    try {
      await (await _fileLocator()).writeAsString(jsonEncode(e.toJson()));
    } catch (_) {
      // Best-effort; a failed write must not crash a conversion or purchase.
    }
  }
}
