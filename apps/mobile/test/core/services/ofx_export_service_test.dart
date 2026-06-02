import 'package:flutter_test/flutter_test.dart';
import 'package:reconsnap_statement_converter/core/models/statement_transaction.dart';
import 'package:reconsnap_statement_converter/core/services/ofx_export_service.dart';

void main() {
  final txns = [
    StatementTransaction(
      id: 'a',
      date: DateTime(2024, 6, 20),
      description: 'Lulu & Co <Dubai>',
      debit: 23.10,
      balance: 58006.43,
      currency: 'AED',
    ),
    StatementTransaction(
      id: 'b',
      date: DateTime(2024, 6, 20),
      description: 'Salary credit',
      credit: 525.00,
      balance: 58029.53,
      currency: 'AED',
    ),
  ];

  test('emits a valid OFX 1.x document with signed, typed transactions', () {
    final ofx = OfxExportService().buildOfx(txns);

    expect(ofx, startsWith('OFXHEADER:100'));
    expect(ofx, contains('<OFX>'));
    expect(ofx, contains('<CURDEF>AED'));

    // Two transactions.
    expect('<STMTTRN>'.allMatches(ofx).length, 2);

    // Debit is negative + typed DEBIT; credit is positive + typed CREDIT.
    expect(ofx, contains('<TRNTYPE>DEBIT'));
    expect(ofx, contains('<TRNAMT>-23.10'));
    expect(ofx, contains('<TRNTYPE>CREDIT'));
    expect(ofx, contains('<TRNAMT>525.00'));

    // Posted date is yyyymmdd; ledger balance is the last balance.
    expect(ofx, contains('<DTPOSTED>20240620'));
    expect(ofx, contains('<BALAMT>58029.53'));

    // SGML-unsafe characters are neutralised in free text.
    expect(ofx, isNot(contains('<Dubai>')));
    expect(ofx, contains('Lulu and Co'));
  });
}
