import '../positioned/positioned_models.dart';
import '../text/parsed_statement.dart';

/// A bank-specific statement template.
///
/// Each launch bank (Emirates NBD first, then FAB / ADCB / Mashreq / DIB)
/// provides one. A template knows how to (a) recognise its own statements and
/// (b) parse them by column position. The registry picks the highest
/// [matchScore] template; the chosen template's [parse] does the column-aware
/// extraction. Most templates are thin configuration over the shared
/// [ColumnStatementParser] — only genuinely unusual layouts need custom code.
abstract interface class BankStatementTemplate {
  /// Stable id, aligned with `Bank.id` (e.g. `ae_emirates_nbd`).
  String get bankId;

  String get displayName;

  /// Confidence in `[0, 1]` that this template matches [doc], from header /
  /// fingerprint text. 0 means "not my statement".
  double matchScore(ExtractedDocument doc);

  /// Parses [doc] into reconciled rows. Returns an empty [ParsedStatement] with
  /// a warning rather than throwing when the table can't be located, so the
  /// orchestrator can fall back or report cleanly.
  ParsedStatement parse(ExtractedDocument doc, {required String currency});
}
