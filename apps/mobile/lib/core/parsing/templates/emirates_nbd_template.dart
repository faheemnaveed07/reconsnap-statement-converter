import '../positioned/positioned_models.dart';
import '../text/parsed_statement.dart';
import 'bank_statement_template.dart';
import 'column_statement_parser.dart';

/// Template for Emirates NBD retail/business "Statement of Account" PDFs.
///
/// Layout (confirmed from a real statement): columns Date | Description | Debit
/// | Credit | Balance, DD/MM/YYYY dates, a `Cr`/`Dr` suffix on the balance,
/// rows in reverse-chronological order, and multi-line descriptions. All of
/// that is handled by the shared [ColumnStatementParser]; this class only
/// supplies the configuration and the fingerprint that recognises the bank.
class EmiratesNbdTemplate implements BankStatementTemplate {
  const EmiratesNbdTemplate({
    ColumnStatementParser parser = const ColumnStatementParser(),
  }) : _parser = parser;

  final ColumnStatementParser _parser;

  @override
  String get bankId => 'ae_emirates_nbd';

  @override
  String get displayName => 'Emirates NBD';

  static const _config = ColumnTableConfig(dayFirst: true);

  /// Strings that reliably appear on an Emirates NBD statement (header logo
  /// text and the licensed-entity line in the footer).
  static const _fingerprints = ['emirates nbd', 'emiratesnbd', 'p.j.s.c'];

  @override
  double matchScore(ExtractedDocument doc) {
    final text = doc.fullText.toLowerCase();
    if (text.contains('emirates nbd') || text.contains('emiratesnbd')) {
      return 0.95;
    }
    if (_fingerprints.any(text.contains)) return 0.6;
    return 0;
  }

  @override
  ParsedStatement parse(ExtractedDocument doc, {required String currency}) =>
      _parser.parse(doc, _config, currency: currency);
}
