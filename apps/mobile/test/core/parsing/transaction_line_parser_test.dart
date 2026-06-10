import 'package:flutter_test/flutter_test.dart';
import 'package:reconsnap_statement_converter/core/parsing/text/money.dart';
import 'package:reconsnap_statement_converter/core/parsing/text/statement_date.dart';
import 'package:reconsnap_statement_converter/core/parsing/text/transaction_line_parser.dart';

void main() {
  group('Money', () {
    test('parses grouped, decimal, CR/DR and parenthesised amounts', () {
      expect(Money.parse('1,234.56'), closeTo(1234.56, 1e-9));
      expect(Money.parse('49.00'), closeTo(49.0, 1e-9));
      expect(Money.parse('(50.00)'), closeTo(-50.0, 1e-9));
      expect(Money.parse('2,400.00 CR'), closeTo(2400.0, 1e-9));
      expect(Money.parse('120.50 DR'), closeTo(-120.50, 1e-9));
    });

    test('findAll returns tokens in order and ignores bare integers', () {
      final found = Money.findAll('Ref 100245 paid 1,200.00 bal 5,000.00');
      expect(found.map((e) => e.value), [1200.0, 5000.0]);
    });
  });

  group('StatementDate', () {
    test('reads day-first numeric dates', () {
      final r = StatementDate.leading('03/04/2026 Payment 10.00');
      expect(r, isNotNull);
      expect(r!.date, DateTime(2026, 4, 3));
    });

    test('reads textual dates', () {
      expect(
        StatementDate.leading('02 May 2026 Card 5.00')!.date,
        DateTime(2026, 5, 2),
      );
      expect(
        StatementDate.leading('May 2, 2026 Card 5.00')!.date,
        DateTime(2026, 5, 2),
      );
    });

    test('disambiguates when a component exceeds 12', () {
      expect(
        StatementDate.leading('25/12/2026 x 1.00')!.date,
        DateTime(2026, 12, 25),
      );
    });

    test('returns null for non-date lines', () {
      expect(StatementDate.leading('Opening Balance 1,000.00'), isNull);
    });
  });

  group('TransactionLineParser', () {
    const parser = TransactionLineParser();

    test('reconciles debit/credit from the running balance', () {
      const text = '''
Account Statement - Emirates NBD
Date        Description                 Amount      Balance
01/05/2026  Opening Balance                         5,000.00
02/05/2026  Card settlement             120.50      4,879.50
03/05/2026  Client transfer Blue Palm   2,400.00    7,279.50
08/05/2026  Subscription payment        49.00       7,230.50
''';

      final result = parser.parse(text);
      // Opening Balance line has no description token before the amount? It
      // does ("Opening Balance"), but only one number and no prior balance, so
      // it is kept as a low-confidence debit anchor. The three real rows must
      // reconcile cleanly.
      final reconciled = result.transactions
          .where((t) => t.confidence >= 0.95)
          .toList();
      expect(reconciled.length, 3);

      final settlement = reconciled.firstWhere(
        (t) => t.description.contains('Card'),
      );
      expect(settlement.debit, closeTo(120.50, 1e-9));
      expect(settlement.credit, isNull);

      final transfer = reconciled.firstWhere(
        (t) => t.description.contains('Blue Palm'),
      );
      expect(transfer.credit, closeTo(2400.0, 1e-9));
      expect(transfer.debit, isNull);

      expect(result.closingBalance, closeTo(7230.50, 1e-9));
    });

    test('flags a row whose amount disagrees with the balance move', () {
      // Amount says 100.00 but the balance dropped by 150.00.
      const text = '''
01/06/2026  Opening                                 1,000.00
02/06/2026  Suspicious charge           100.00      850.00
''';
      final result = parser.parse(text);
      final row = result.transactions.firstWhere(
        (t) => t.description == 'Suspicious charge',
      );
      // It is still recorded, but confidence is reduced so the UI can flag it.
      expect(row.confidence, lessThan(0.8));
    });

    test('collapses messy whitespace in descriptions', () {
      const text = '02/05/2026   Pay\t\t  ROLL   transfer   5.00   95.00';
      // Needs a prior balance to reconcile; add an opening line.
      final result = const TransactionLineParser().parse(
        '01/05/2026 Opening 100.00\n$text',
      );
      final row = result.transactions.last;
      expect(row.description, 'Pay ROLL transfer');
    });

    test('honours the dayFirst preference for ambiguous dates', () {
      const text = '01/01/2026 Opening 100.00\n03/04/2026 Payment 10.00 90.00';
      final dayFirst = const TransactionLineParser(dayFirst: true).parse(text);
      expect(dayFirst.transactions.last.date, DateTime(2026, 4, 3));

      final monthFirst = const TransactionLineParser(
        dayFirst: false,
      ).parse(text);
      expect(monthFirst.transactions.last.date, DateTime(2026, 3, 4));
    });
  });
}
