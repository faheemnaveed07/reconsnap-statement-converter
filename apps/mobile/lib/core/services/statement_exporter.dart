import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/statement_transaction.dart';
import 'csv_export_service.dart';
import 'ofx_export_service.dart';
import 'xlsx_export_service.dart';

/// The formats a converted statement can be exported to. Mirrors what
/// accountants need to get data into their tools (and what competitors offer).
enum ExportFormat { xlsx, csvDetailed, csvAccounting, ofx }

extension ExportFormatInfo on ExportFormat {
  String get label => switch (this) {
    ExportFormat.xlsx => 'Excel (.xlsx)',
    ExportFormat.csvDetailed => 'CSV — detailed',
    ExportFormat.csvAccounting => 'QuickBooks / Xero (.csv)',
    ExportFormat.ofx => 'OFX (.ofx)',
  };

  String get description => switch (this) {
    ExportFormat.xlsx => 'Spreadsheet with amounts as numbers.',
    ExportFormat.csvDetailed => 'Date, Description, Debit, Credit, Balance.',
    ExportFormat.csvAccounting => 'Signed-amount CSV for direct import.',
    ExportFormat.ofx => 'For QuickBooks Online and banking software.',
  };

  String get extension => switch (this) {
    ExportFormat.xlsx => 'xlsx',
    ExportFormat.csvDetailed || ExportFormat.csvAccounting => 'csv',
    ExportFormat.ofx => 'ofx',
  };

  /// Suffix that disambiguates same-extension exports in the shared file name.
  String get fileSuffix => switch (this) {
    ExportFormat.csvAccounting => '-quickbooks-xero',
    _ => '',
  };

  String get mimeType => switch (this) {
    ExportFormat.xlsx =>
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    ExportFormat.csvDetailed || ExportFormat.csvAccounting => 'text/csv',
    ExportFormat.ofx => 'application/x-ofx',
  };
}

/// One entry point for all export formats, so the UI just picks a format and
/// shares the resulting file.
class StatementExporter {
  StatementExporter({
    CsvExportService? csv,
    XlsxExportService? xlsx,
    OfxExportService? ofx,
  }) : _csv = csv ?? CsvExportService(),
       _xlsx = xlsx ?? XlsxExportService(),
       _ofx = ofx ?? OfxExportService();

  final CsvExportService _csv;
  final XlsxExportService _xlsx;
  final OfxExportService _ofx;

  /// Builds the export bytes/text for [format] as a string ([ExportFormat.xlsx]
  /// is binary and handled by [export]).
  String buildText(ExportFormat format, List<StatementTransaction> txns) {
    return switch (format) {
      ExportFormat.csvDetailed => _csv.buildCsv(txns),
      ExportFormat.csvAccounting => _csv.buildAccountingCsv(txns),
      ExportFormat.ofx => _ofx.buildOfx(txns),
      ExportFormat.xlsx => throw ArgumentError('xlsx is binary; use export()'),
    };
  }

  /// Writes the export to a temp file and returns it (ready to share).
  Future<File> export(
    ExportFormat format, {
    required String sourceFilename,
    required List<StatementTransaction> transactions,
  }) async {
    if (format == ExportFormat.xlsx) {
      return _xlsx.writeXlsx(
        filename: sourceFilename,
        transactions: transactions,
      );
    }
    final name = exportFilename(format, sourceFilename);
    if (format == ExportFormat.ofx) {
      return _ofx.writeOfx(filename: name, transactions: transactions);
    }
    final dir = await getTemporaryDirectory();
    return File(
      '${dir.path}/$name',
    ).writeAsString(buildText(format, transactions));
  }

  /// `sample_statement.pdf` → e.g. `sample_statement-quickbooks-xero.csv`.
  static String exportFilename(ExportFormat format, String source) {
    final base = source
        .replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '')
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final safe = base.isEmpty ? 'statement' : base;
    return '$safe${format.fileSuffix}.${format.extension}';
  }
}
