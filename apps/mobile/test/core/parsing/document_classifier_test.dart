import 'package:flutter_test/flutter_test.dart';
import 'package:reconsnap_statement_converter/core/parsing/classification/document_classifier.dart';
import 'package:reconsnap_statement_converter/core/parsing/positioned/positioned_models.dart';

/// Builds an [ExtractedDocument] from plain text lines, assigning each word an
/// increasing X so word-position logic still works.
ExtractedDocument _doc(List<String> lines) {
  final positioned = <PositionedLine>[];
  for (final line in lines) {
    final tokens = line.split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
    var x = 20.0;
    final words = <PositionedWord>[];
    for (final tok in tokens) {
      words.add(
        PositionedWord(
          text: tok,
          left: x,
          top: 0,
          right: x + tok.length * 6,
          bottom: 10,
        ),
      );
      x += tok.length * 6 + 30;
    }
    if (words.isNotEmpty) {
      positioned.add(PositionedLine(words: words, pageIndex: 0));
    }
  }
  return ExtractedDocument(lines: positioned, numPages: 1, encrypted: false);
}

void main() {
  const classifier = DocumentClassifier();

  test('account statement: a date/debit/credit/balance header', () {
    final doc = _doc([
      'Emirates NBD Statement of Account',
      'Date Description Debit Credit Balance',
      '01/06/2024 Salary 0.00 3000.00 8000.00',
    ]);
    expect(classifier.classify(doc).kind, DocumentKind.accountStatement);
  });

  test('annual report rejected', () {
    final doc = _doc([
      'Emirates NBD Group',
      'Consolidated statement of financial position',
      'Notes to the financial statements',
      'For the year ended 31 December 2025',
      'Independent auditor report to the shareholders',
    ]);
    expect(classifier.classify(doc).kind, DocumentKind.annualReport);
  });

  test('enrolment form rejected', () {
    final doc = _doc([
      'eStatements of Account request',
      'Please send me electronically generated statements',
      'Terms and conditions for providing eStatement',
      'Signature(s) of Account holder',
      'Office use only attach photocopy',
    ]);
    expect(classifier.classify(doc).kind, DocumentKind.form);
  });

  test('broken-font gibberish rejected as unreadable', () {
    final doc = _doc([
      '1FSTPO TUBUFQFOTJPO 1FSTPO# BUUFOEBODF BMMPXBODF',
      'QSJWBUF PDDVQBUJPOBM QFOTJPO GPS QFSTPO',
      'NS BOE NST F TNJUI DPVQMF KPJOU DMBJN',
      'TUBUFQFOTJPO QFSTPO BVHVTU TFQUFNCFS PDUPCFS',
    ]);
    expect(classifier.classify(doc).kind, DocumentKind.unreadable);
  });
}
