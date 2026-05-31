import '../../models/statement_transaction.dart';

/// Outcome of running [TransactionLineParser] over the raw text of a
/// statement. Carries the structured rows plus human-readable warnings that
/// the UI can surface (e.g. lines that looked like transactions but could not
/// be reconciled against the running balance).
class ParsedStatement {
  const ParsedStatement({
    required this.transactions,
    this.warnings = const [],
    this.openingBalance,
    this.closingBalance,
  });

  final List<StatementTransaction> transactions;
  final List<String> warnings;

  /// First balance the parser could anchor to (if any).
  final double? openingBalance;

  /// Last balance seen on the statement (if any).
  final double? closingBalance;

  bool get isEmpty => transactions.isEmpty;
}
