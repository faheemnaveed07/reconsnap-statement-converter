import 'package:uuid/uuid.dart';

import '../models/statement_transaction.dart';
import 'statement_parser.dart';

class MockStatementParser implements StatementParser {
  const MockStatementParser();

  static const _uuid = Uuid();

  @override
  Future<ParseResult> parse(ParseInput input) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));

    final rows = [
      StatementTransaction(
        id: _uuid.v4(),
        date: DateTime(2026, 5, 2),
        description: 'Opening card settlement',
        debit: 120.50,
        balance: 4879.50,
        confidence: 0.97,
        sourcePage: 1,
        sourceLine: 8,
      ),
      StatementTransaction(
        id: _uuid.v4(),
        date: DateTime(2026, 5, 3),
        description: 'Client transfer - Blue Palm Trading',
        credit: 2400,
        balance: 7279.50,
        confidence: 0.96,
        sourcePage: 1,
        sourceLine: 11,
      ),
      StatementTransaction(
        id: _uuid.v4(),
        date: DateTime(2026, 5, 4),
        description: 'Office supplies - needs review',
        debit: 214.16,
        balance: 7065.34,
        confidence: 0.72,
        sourcePage: 1,
        sourceLine: 16,
      ),
      StatementTransaction(
        id: _uuid.v4(),
        date: DateTime(2026, 5, 8),
        description: 'Subscription payment',
        debit: 49,
        balance: 7016.34,
        confidence: 0.91,
        sourcePage: 2,
        sourceLine: 4,
      ),
    ];

    return ParseResult(
      bank: input.bank,
      transactions: rows,
      parserVersion: 'mock-ae-template-v0',
    );
  }
}
