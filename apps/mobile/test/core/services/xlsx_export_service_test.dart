import 'package:flutter_test/flutter_test.dart';
import 'package:reconsnap_statement_converter/core/models/statement_transaction.dart';
import 'package:reconsnap_statement_converter/core/services/xlsx_export_service.dart';

void main() {
  final transactions = [
    StatementTransaction(
      id: '1',
      date: DateTime(2026, 5, 2),
      description: 'Card settlement',
      debit: 120.50,
      balance: 4879.50,
      confidence: 0.98,
    ),
    StatementTransaction(
      id: '2',
      date: DateTime(2026, 5, 12),
      description: 'Salary credit',
      credit: 3500,
      balance: 10516.34,
      confidence: 0.98,
    ),
  ];

  test('derives a clean .xlsx export name from the source filename', () {
    expect(
      XlsxExportService.xlsxFilename('sample_statement.pdf'),
      'sample_statement.xlsx',
    );
    expect(
      XlsxExportService.xlsxFilename('Emirates NBD May.PDF'),
      'Emirates_NBD_May.xlsx',
    );
    expect(XlsxExportService.xlsxFilename(''), 'statement.xlsx');
  });

  test('produces a valid non-empty xlsx (zip) stream', () {
    final bytes = XlsxExportService().buildXlsx(transactions);
    // .xlsx is a zip archive — it must start with the PK signature.
    expect(bytes.length, greaterThan(0));
    expect(bytes[0], 0x50); // 'P'
    expect(bytes[1], 0x4B); // 'K'
  });
}
