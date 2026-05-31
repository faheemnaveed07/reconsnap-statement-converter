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
      ['Date', 'Description', 'Debit', 'Credit', 'Balance', 'Confidence'],
      ...transactions.map(
        (transaction) => [
          _dateFormat.format(transaction.date),
          transaction.description,
          _formatAmount(transaction.debit),
          _formatAmount(transaction.credit),
          _formatAmount(transaction.balance),
          '${(transaction.confidence * 100).toStringAsFixed(0)}%',
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
    final safeName = filename.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final file = File('${directory.path}/$safeName.csv');
    return file.writeAsString(buildCsv(transactions));
  }

  String _formatAmount(double? amount) {
    if (amount == null) return '';
    return amount.toStringAsFixed(2);
  }
}
