import '../models/bank.dart';
import '../models/statement_transaction.dart';

class ParseInput {
  const ParseInput({
    required this.filename,
    required this.bank,
    this.password,
    this.bytes,
  });

  final String filename;
  final Bank bank;
  final String? password;

  /// Raw PDF bytes. Required by real parsers; the mock parser ignores it.
  final List<int>? bytes;
}

class ParseResult {
  const ParseResult({
    required this.bank,
    required this.transactions,
    required this.parserVersion,
    this.warnings = const [],
  });

  final Bank bank;
  final List<StatementTransaction> transactions;
  final String parserVersion;

  /// Non-fatal notes from parsing (e.g. lines that could not be reconciled).
  final List<String> warnings;
}

abstract interface class StatementParser {
  Future<ParseResult> parse(ParseInput input);
}
