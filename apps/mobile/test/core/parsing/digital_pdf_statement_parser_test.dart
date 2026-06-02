import 'package:flutter_test/flutter_test.dart';
import 'package:reconsnap_statement_converter/core/models/bank.dart';
import 'package:reconsnap_statement_converter/core/parsing/digital_pdf_statement_parser.dart';
import 'package:reconsnap_statement_converter/core/parsing/statement_parser.dart';
import 'package:reconsnap_statement_converter/core/parsing/text/statement_text_extractor.dart';

class _FakeExtractor implements StatementTextExtractor {
  _FakeExtractor(this.text);
  final String text;
  List<int>? lastBytes;
  String? lastPassword;

  @override
  Future<ExtractedText> extract({
    required List<int> bytes,
    required String filename,
    String? password,
  }) async {
    lastBytes = bytes;
    lastPassword = password;
    return ExtractedText(
      fullText: text,
      numPages: 1,
      encrypted: password != null,
      needsOcr: false,
    );
  }
}

const _bank = Bank(
  id: 'ae_emirates_nbd',
  name: 'Emirates NBD',
  countryCode: 'AE',
  supportLevel: BankSupportLevel.beta,
);

void main() {
  group('DigitalPdfStatementParser', () {
    test('extracts, parses and tags currency from the bank country', () async {
      final extractor = _FakeExtractor('''
01/05/2026 Opening Balance 5,000.00
02/05/2026 Card settlement 120.50 4,879.50
03/05/2026 Client transfer 2,400.00 7,279.50
''');
      final parser = DigitalPdfStatementParser(extractor: extractor);

      final result = await parser.parse(
        ParseInput(
          filename: 's.pdf',
          bank: _bank,
          bytes: [1, 2, 3],
          password: 'pw',
        ),
      );

      expect(result.transactions, hasLength(2));
      expect(result.transactions.every((t) => t.currency == 'AED'), isTrue);
      expect(result.parserVersion, 'digital-v1');
      // Bytes and password are forwarded to the extractor.
      expect(extractor.lastBytes, [1, 2, 3]);
      expect(extractor.lastPassword, 'pw');
    });

    test('throws when no bytes are provided', () async {
      final parser = DigitalPdfStatementParser(extractor: _FakeExtractor(''));
      expect(
        () => parser.parse(ParseInput(filename: 's.pdf', bank: _bank)),
        throwsA(isA<ExtractionException>()),
      );
    });
  });
}
