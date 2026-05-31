import 'package:flutter_test/flutter_test.dart';
import 'package:reconsnap_statement_converter/core/models/statement_transaction.dart';
import 'package:reconsnap_statement_converter/core/validation/validation_engine.dart';

void main() {
  test('passes when opening plus credits minus debits equals closing', () {
    final report = const ValidationEngine().validate([
      StatementTransaction(
        id: '1',
        date: DateTime(2026, 5, 1),
        description: 'Debit',
        debit: 100,
        balance: 900,
      ),
      StatementTransaction(
        id: '2',
        date: DateTime(2026, 5, 2),
        description: 'Credit',
        credit: 50,
        balance: 950,
      ),
    ]);

    expect(report.openingBalance, 1000);
    expect(report.closingBalance, 950);
    expect(report.isPassed, isTrue);
  });

  test('fails when closing balance does not match transaction totals', () {
    final report = const ValidationEngine().validate([
      StatementTransaction(
        id: '1',
        date: DateTime(2026, 5, 1),
        description: 'Debit',
        debit: 100,
        balance: 900,
      ),
      StatementTransaction(
        id: '2',
        date: DateTime(2026, 5, 2),
        description: 'Credit',
        credit: 50,
        balance: 940,
      ),
    ]);

    expect(report.isPassed, isFalse);
  });
}
