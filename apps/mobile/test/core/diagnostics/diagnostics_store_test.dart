import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:reconsnap_statement_converter/core/diagnostics/conversion_outcome.dart';
import 'package:reconsnap_statement_converter/core/diagnostics/diagnostics_store.dart';

void main() {
  Future<(DiagnosticsStore, Directory)> make() async {
    final dir = await Directory.systemTemp.createTemp('reconsnap_diag');
    return (
      DiagnosticsStore(fileLocator: () async => File('${dir.path}/d.json')),
      dir,
    );
  }

  ConversionOutcome outcome(ConversionOutcomeType type, {int n = 0}) =>
      ConversionOutcome(
        at: DateTime(2024, 6, 20, 10, n),
        type: type,
        bankId: 'ae_emirates_nbd',
        parserVersion: 'ae_emirates_nbd-v1',
        transactionCount: n,
        reconciled: true,
      );

  test('records newest-first and round-trips without content', () async {
    final (store, dir) = await make();
    await store.record(outcome(ConversionOutcomeType.success, n: 1));
    await store.record(outcome(ConversionOutcomeType.needsPassword, n: 2));

    final all = await store.load();
    expect(all.first.type, ConversionOutcomeType.needsPassword); // newest first
    expect(all.last.type, ConversionOutcomeType.success);
    expect(all.first.bankId, 'ae_emirates_nbd');

    await dir.delete(recursive: true);
  });

  test('caps the log at maxEntries', () async {
    final (store, dir) = await make();
    for (var i = 0; i < DiagnosticsStore.maxEntries + 5; i++) {
      await store.record(outcome(ConversionOutcomeType.success, n: i % 60));
    }
    expect((await store.load()).length, DiagnosticsStore.maxEntries);
    await dir.delete(recursive: true);
  });

  test('clear empties the log', () async {
    final (store, dir) = await make();
    await store.record(outcome(ConversionOutcomeType.failed));
    await store.clear();
    expect(await store.load(), isEmpty);
    await dir.delete(recursive: true);
  });
}
