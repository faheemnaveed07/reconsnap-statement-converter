import '../models/bank.dart';
import '../models/statement_transaction.dart';

class ParseInput {
  const ParseInput({required this.filename, required this.bank, this.password});

  final String filename;
  final Bank bank;
  final String? password;
}

class ParseResult {
  const ParseResult({
    required this.bank,
    required this.transactions,
    required this.parserVersion,
  });

  final Bank bank;
  final List<StatementTransaction> transactions;
  final String parserVersion;
}

abstract interface class StatementParser {
  Future<ParseResult> parse(ParseInput input);
}
