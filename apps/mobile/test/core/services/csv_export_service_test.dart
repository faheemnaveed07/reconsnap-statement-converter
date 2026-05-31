import 'package:flutter_test/flutter_test.dart';
import 'package:reconsnap_statement_converter/core/models/statement_transaction.dart';
import 'package:reconsnap_statement_converter/core/services/csv_export_service.dart';

void main() {
  test('builds accountant-readable CSV columns', () {
    final csv = CsvExportService().buildCsv([
      StatementTransaction(
        id: '1',
        date: DateTime(2026, 5, 1),
        description: 'Client payment',
        credit: 250,
        balance: 1250,
        confidence: 0.9,
      ),
    ]);

    expect(csv, contains('Date,Description,Debit,Credit,Balance,Confidence'));
    expect(csv, contains('2026-05-01,Client payment,,250.00,1250.00,90%'));
  });
}
