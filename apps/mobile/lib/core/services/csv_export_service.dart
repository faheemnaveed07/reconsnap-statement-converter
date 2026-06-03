import 'dart:io';

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../models/statement_transaction.dart';

class CsvExportService {
  CsvExportService({DateFormat? dateFormat})
    : _dateFormat = dateFormat ?? DateFormat('yyyy-MM-dd');

  final DateFormat _dateFormat;

  String buildCsv(List<StatementTransaction> transactions) {
    final rows = [
      [
        'Date',
        'Description',
        'Category',
        'Debit',
        'Credit',
        'Balance',
        'Confidence',
      ],
      ...transactions.map(
        (transaction) => [
          _dateFormat.format(transaction.date),
          transaction.description,
          transaction.category ?? '',
          _formatAmount(transaction.debit),
          _formatAmount(transaction.credit),
          _formatAmount(transaction.balance),
          '${(transaction.confidence * 100).toStringAsFixed(0)}%',
        ],
      ),
    ];

    return Csv().encode(rows);
  }

  /// CSV shaped for QuickBooks Online / Xero bank-statement import: three
  /// columns — Date, Description, Amount — with a single **signed** amount
  /// (credit positive, debit negative). This is the 3-column layout both tools
  /// accept; the import wizard maps the columns and date format.
  String buildAccountingCsv(List<StatementTransaction> transactions) {
    final rows = [
      ['Date', 'Description', 'Amount'],
      ...transactions.map(
        (t) => [
          _dateFormat.format(t.date),
          t.description,
          t.signedAmount.toStringAsFixed(2),
        ],
      ),
    ];
    return Csv().encode(rows);
  }

  Future<File> writeCsv({
    required String filename,
    required List<StatementTransaction> transactions,
  }) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/${csvFilename(filename)}');
    return file.writeAsString(buildCsv(transactions));
  }

  /// Maps a source filename like `sample_statement.pdf` to a clean export name
  /// like `sample_statement.csv`. The `.pdf` extension is dropped (rather than
  /// sanitised into `_pdf`) so the shared file reads naturally.
  static String csvFilename(String source) {
    final withoutExt = source.replaceAll(
      RegExp(r'\.pdf$', caseSensitive: false),
      '',
    );
    final safe = withoutExt.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return '${safe.isEmpty ? 'statement' : safe}.csv';
  }

  String _formatAmount(double? amount) {
    if (amount == null) return '';
    return amount.toStringAsFixed(2);
  }
}
