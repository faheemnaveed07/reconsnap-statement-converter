import 'package:flutter_test/flutter_test.dart';
import 'package:reconsnap_statement_converter/core/models/statement_transaction.dart';
import 'package:reconsnap_statement_converter/core/services/csv_export_service.dart';
import 'package:reconsnap_statement_converter/core/services/statement_exporter.dart';

void main() {
  final txns = [
    StatementTransaction(
      id: 'a',
      date: DateTime(2024, 6, 20),
      description: 'Lulu',
      debit: 23.10,
      balance: 58006.43,
    ),
    StatementTransaction(
      id: 'b',
      date: DateTime(2024, 6, 20),
      description: 'Salary',
      credit: 525.00,
      balance: 58029.53,
    ),
  ];

  test('accounting CSV uses a single signed amount', () {
    final csv = CsvExportService().buildAccountingCsv(txns);
    expect(csv, contains('Date,Description,Amount'));
    expect(csv, contains('2024-06-20,Lulu,-23.10')); // debit negative
    expect(csv, contains('2024-06-20,Salary,525.00')); // credit positive
  });

  test(
    'export filenames carry the right extension and disambiguating suffix',
    () {
      expect(
        StatementExporter.exportFilename(ExportFormat.xlsx, 'enbd.pdf'),
        'enbd.xlsx',
      );
      expect(
        StatementExporter.exportFilename(ExportFormat.csvDetailed, 'enbd.pdf'),
        'enbd.csv',
      );
      expect(
        StatementExporter.exportFilename(
          ExportFormat.csvAccounting,
          'enbd.pdf',
        ),
        'enbd-quickbooks-xero.csv',
      );
      expect(
        StatementExporter.exportFilename(ExportFormat.ofx, 'enbd.pdf'),
        'enbd.ofx',
      );
    },
  );

  test('buildText dispatches to the right format', () {
    final exporter = StatementExporter();
    expect(
      exporter.buildText(ExportFormat.csvDetailed, txns),
      contains('Debit,Credit,Balance'),
    );
    expect(
      exporter.buildText(ExportFormat.csvAccounting, txns),
      contains('Date,Description,Amount'),
    );
    expect(exporter.buildText(ExportFormat.ofx, txns), startsWith('OFXHEADER'));
  });
}
