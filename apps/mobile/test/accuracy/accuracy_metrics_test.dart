import 'package:flutter_test/flutter_test.dart';
import 'package:reconsnap_statement_converter/core/models/statement_transaction.dart';

import 'accuracy_metrics.dart';

StatementTransaction _tx({
  required int day,
  double? debit,
  double? credit,
  double? balance,
  String description = 'desc',
  double confidence = 0.99,
}) {
  return StatementTransaction(
    id: '$day',
    date: DateTime(2024, 6, day),
    description: description,
    debit: debit,
    credit: credit,
    balance: balance,
    confidence: confidence,
  );
}

GroundTruth _truth() => GroundTruth(
  bankId: 'ae_emirates_nbd',
  currency: 'AED',
  closingBalance: 7300.00,
  transactions: [
    ExpectedTxn(
      date: DateTime(2024, 6, 1),
      credit: 3000,
      balance: 8000,
      description: 'Salary credit',
    ),
    ExpectedTxn(
      date: DateTime(2024, 6, 5),
      debit: 700,
      balance: 7300,
      description: 'ATM withdrawal',
    ),
  ],
);

void main() {
  test('perfect parse scores 100% and zero silent errors', () {
    final report = compareToGroundTruth('perfect', _truth(), [
      _tx(day: 1, credit: 3000, balance: 8000, description: 'Salary credit'),
      _tx(day: 5, debit: 700, balance: 7300, description: 'ATM withdrawal'),
    ]);

    expect(report.recall, 1.0);
    expect(report.directionAccuracy, 1.0);
    expect(report.balanceAccuracy, 1.0);
    expect(report.silentErrors, 0);
    expect(report.closingReconciled, isTrue);
  });

  test('wrong direction at high confidence is a SILENT error', () {
    final report = compareToGroundTruth('swapped', _truth(), [
      _tx(day: 1, credit: 3000, balance: 8000, description: 'Salary credit'),
      // Expected a debit, parser produced a credit, but confident.
      _tx(day: 5, credit: 700, balance: 7300, description: 'ATM withdrawal'),
    ]);

    expect(report.directionAccuracy, 0.5);
    expect(report.silentErrors, 1);
  });

  test('wrong direction but flagged for review is NOT a silent error', () {
    final report = compareToGroundTruth('flagged', _truth(), [
      _tx(day: 1, credit: 3000, balance: 8000, description: 'Salary credit'),
      _tx(
        day: 5,
        credit: 700,
        balance: 7300,
        description: 'ATM withdrawal',
        confidence: 0.5,
      ),
    ]);

    expect(report.silentErrors, 0);
    expect(report.flaggedRows, 1);
  });

  test('a missing row lowers recall', () {
    final report = compareToGroundTruth('missing', _truth(), [
      _tx(day: 1, credit: 3000, balance: 8000, description: 'Salary credit'),
    ]);

    expect(report.matched, 1);
    expect(report.recall, 0.5);
  });

  test('a confident phantom row counts as a silent error', () {
    final report = compareToGroundTruth('phantom', _truth(), [
      _tx(day: 1, credit: 3000, balance: 8000, description: 'Salary credit'),
      _tx(day: 5, debit: 700, balance: 7300, description: 'ATM withdrawal'),
      _tx(day: 9, debit: 9.99, balance: 7290, description: 'phantom'),
    ]);

    expect(report.extraRows, 1);
    expect(report.silentErrors, 1);
  });
}
