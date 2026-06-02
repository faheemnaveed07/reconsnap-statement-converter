import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:reconsnap_statement_converter/core/models/bank.dart';
import 'package:reconsnap_statement_converter/core/models/conversion_job.dart';
import 'package:reconsnap_statement_converter/core/models/statement_transaction.dart';
import 'package:reconsnap_statement_converter/core/models/validation_report.dart';
import 'package:reconsnap_statement_converter/core/services/conversion_history_store.dart';

ConversionJob _job(String id) {
  return ConversionJob(
    id: id,
    filename: 'sample_statement.pdf',
    bank: launchBanks.first,
    transactions: [
      StatementTransaction(
        id: '$id-t1',
        date: DateTime(2026, 5, 2),
        description: 'Card settlement',
        debit: 120.50,
        balance: 4879.50,
        currency: 'AED',
        confidence: 0.98,
        sourceLine: 4,
      ),
    ],
    validationReport: const ValidationReport(
      openingBalance: 5000,
      closingBalance: 4879.50,
      totalDebits: 120.50,
      totalCredits: 0,
      expectedClosingBalance: 4879.50,
      issues: [
        ValidationIssue(
          title: 'Review low-confidence rows',
          message: '1 row needs manual review.',
          severity: ValidationSeverity.warning,
        ),
      ],
    ),
    createdAt: DateTime(2026, 5, 31, 23, 42),
  );
}

void main() {
  test('ConversionJob survives a JSON round-trip', () {
    final original = _job('job-1');
    final restored = ConversionJob.fromJson(original.toJson());

    expect(restored.id, original.id);
    expect(restored.filename, original.filename);
    expect(restored.bank.id, original.bank.id);
    expect(restored.bank.supportLevel, original.bank.supportLevel);
    expect(restored.createdAt, original.createdAt);
    expect(restored.transactions.single, original.transactions.single);
    expect(restored.validationReport.closingBalance, 4879.50);
    expect(
      restored.validationReport.issues.single.severity,
      ValidationSeverity.warning,
    );
  });

  test('store persists and reloads history from disk', () async {
    final dir = await Directory.systemTemp.createTemp('reconsnap_history_test');
    final file = File('${dir.path}/history.json');
    final store = ConversionHistoryStore(fileLocator: () async => file);

    expect(await store.load(), isEmpty);

    await store.save([_job('a'), _job('b')]);
    final reloaded = await store.load();

    expect(reloaded.map((j) => j.id), ['a', 'b']);
    await dir.delete(recursive: true);
  });

  test('load returns empty (not throw) for a corrupt file', () async {
    final dir = await Directory.systemTemp.createTemp('reconsnap_history_bad');
    final file = File('${dir.path}/history.json');
    await file.writeAsString('{ not valid json');
    final store = ConversionHistoryStore(fileLocator: () async => file);

    expect(await store.load(), isEmpty);
    await dir.delete(recursive: true);
  });

  test('save caps history at maxEntries', () async {
    final dir = await Directory.systemTemp.createTemp('reconsnap_history_cap');
    final file = File('${dir.path}/history.json');
    final store = ConversionHistoryStore(fileLocator: () async => file);

    final many = List.generate(
      ConversionHistoryStore.maxEntries + 10,
      (i) => _job('job-$i'),
    );
    await store.save(many);

    expect((await store.load()).length, ConversionHistoryStore.maxEntries);
    await dir.delete(recursive: true);
  });
}
