import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';

import '../models/statement_transaction.dart';

/// Builds an accountant-ready `.xlsx` workbook from extracted transactions.
///
/// Mirrors [CsvExportService] but writes amounts as **real numbers** with a
/// money format, and the date as a real date — so the file opens in Excel /
/// Google Sheets ready to sum and filter, not as a wall of text.
class XlsxExportService {
  XlsxExportService({DateFormat? dateFormat})
    : _dateFormat = dateFormat ?? DateFormat('yyyy-MM-dd');

  final DateFormat _dateFormat;

  static const _headers = [
    'Date',
    'Description',
    'Debit',
    'Credit',
    'Balance',
    'Confidence',
  ];
  static const _moneyFormat = r'#,##0.00';

  /// Produces the raw `.xlsx` bytes. Kept separate from file I/O so it can be
  /// unit-tested without touching disk.
  List<int> buildXlsx(List<StatementTransaction> transactions) {
    final workbook = Workbook();
    try {
      final sheet = workbook.worksheets[0];
      sheet.name = 'Transactions';

      for (var col = 0; col < _headers.length; col++) {
        final cell = sheet.getRangeByIndex(1, col + 1);
        cell.setText(_headers[col]);
        cell.cellStyle.bold = true;
      }

      for (var i = 0; i < transactions.length; i++) {
        final t = transactions[i];
        final row = i + 2; // row 1 is the header

        sheet.getRangeByIndex(row, 1).setText(_dateFormat.format(t.date));
        sheet.getRangeByIndex(row, 2).setText(t.description);
        _money(sheet.getRangeByIndex(row, 3), t.debit);
        _money(sheet.getRangeByIndex(row, 4), t.credit);
        _money(sheet.getRangeByIndex(row, 5), t.balance);
        sheet
            .getRangeByIndex(row, 6)
            .setText('${(t.confidence * 100).toStringAsFixed(0)}%');
      }

      for (var col = 1; col <= _headers.length; col++) {
        sheet.autoFitColumn(col);
      }

      return workbook.saveAsStream();
    } finally {
      workbook.dispose();
    }
  }

  Future<File> writeXlsx({
    required String filename,
    required List<StatementTransaction> transactions,
  }) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/${xlsxFilename(filename)}');
    return file.writeAsBytes(buildXlsx(transactions), flush: true);
  }

  void _money(Range cell, double? amount) {
    if (amount == null) return;
    cell.setNumber(amount);
    cell.numberFormat = _moneyFormat;
  }

  /// Maps a source filename like `sample_statement.pdf` to `sample_statement.xlsx`.
  static String xlsxFilename(String source) {
    final withoutExt = source.replaceAll(
      RegExp(r'\.pdf$', caseSensitive: false),
      '',
    );
    final safe = withoutExt.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return '${safe.isEmpty ? 'statement' : safe}.xlsx';
  }
}
