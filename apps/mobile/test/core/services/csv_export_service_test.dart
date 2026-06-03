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

    expect(
      csv,
      contains('Date,Description,Category,Debit,Credit,Balance,Confidence'),
    );
    expect(csv, contains('2026-05-01,Client payment,,,250.00,1250.00,90%'));
  });

  test('derives a clean .csv export name from the source filename', () {
    expect(
      CsvExportService.csvFilename('sample_statement.pdf'),
      'sample_statement.csv',
    );
    expect(
      CsvExportService.csvFilename('Emirates NBD May.PDF'),
      'Emirates_NBD_May.csv',
    );
    expect(CsvExportService.csvFilename(''), 'statement.csv');
  });
}
