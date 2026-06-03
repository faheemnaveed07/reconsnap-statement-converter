import 'package:flutter_test/flutter_test.dart';
import 'package:reconsnap_statement_converter/core/models/bank.dart';
import 'package:reconsnap_statement_converter/core/ocr/ocr_document_extractor.dart';
import 'package:reconsnap_statement_converter/core/ocr/ocr_models.dart';
import 'package:reconsnap_statement_converter/core/parsing/on_device_pdf_text_extractor.dart';
import 'package:reconsnap_statement_converter/core/parsing/templated_statement_parser.dart';

// Column X positions mirroring an Emirates NBD layout.
OcrWord _w(String text, double x, double y, [double w = 0]) {
  final width = w == 0 ? text.length * 6.0 : w;
  return OcrWord(text: text, left: x, top: y, right: x + width, bottom: y + 12);
}

OcrLine _row(
  String date,
  String desc,
  double y, {
  String? debit,
  String? credit,
  required String balance,
}) {
  return OcrLine([
    _w(date, 30, y),
    _w(desc, 90, y),
    if (debit != null) _w(debit, 560, y),
    if (credit != null) _w(credit, 645, y),
    _w(balance, 730, y),
    _w('Cr', 800, y),
  ]);
}

/// A synthetic OCR result for an Emirates NBD statement: fingerprint line,
/// header, then 3 rows newest-first with separate Debit/Credit columns.
OcrResult _enbdOcr() {
  return OcrResult([
    OcrLine([
      _w('Emirates', 30, 10),
      _w('NBD', 110, 10),
      _w('Statement', 160, 10),
      _w('of', 240, 10),
      _w('Account', 270, 10),
    ]),
    OcrLine([
      _w('Date', 30, 40),
      _w('Description', 90, 40),
      _w('Debit', 560, 40),
      _w('Credit', 645, 40),
      _w('Balance', 730, 40),
    ]),
    _row('20/06/2024', 'Office', 70, debit: '100.00', balance: '1,500.00'),
    _row('18/06/2024', 'Salary', 100, credit: '600.00', balance: '1,600.00'),
    _row('16/06/2024', 'Taxi', 130, debit: '17.00', balance: '1,000.00'),
  ]);
}

void main() {
  test('OCR mapping preserves word boxes and drops empties', () {
    final doc = OcrDocumentExtractor.toDocument(
      OcrResult([
        OcrLine([
          _w('Hello', 10, 10),
          const OcrWord(text: '  ', left: 0, top: 0, right: 0, bottom: 0),
        ]),
        const OcrLine([]),
      ]),
    );
    expect(doc.lines.length, 1);
    expect(doc.lines.first.words.length, 1);
    expect(doc.lines.first.words.first.text, 'Hello');
    expect(doc.lines.first.words.first.centerX, 10 + (5 * 6) / 2);
  });

  test('multi-page OCR merges in page order with page indices', () {
    final doc = OcrDocumentExtractor.toDocumentFromPages([
      OcrResult([
        OcrLine([_w('page0', 10, 10)]),
      ]),
      OcrResult([
        OcrLine([_w('page1', 10, 10)]),
      ]),
    ]);

    expect(doc.numPages, 2);
    expect(doc.lines.map((l) => l.text), ['page0', 'page1']);
    expect(doc.lines[0].pageIndex, 0);
    expect(doc.lines[1].pageIndex, 1);
  });

  test('an OCR statement flows through the column pipeline and reconciles', () {
    final doc = OcrDocumentExtractor.toDocument(_enbdOcr());

    // User picked a different bank; the fingerprint auto-corrects to ENBD.
    final wrongBank = launchBanks.firstWhere((b) => b.id != 'ae_emirates_nbd');
    final result = const TemplatedStatementParser(
      extractor: OnDevicePdfTextExtractor(),
    ).parseExtracted(doc, wrongBank);

    expect(result.parserVersion, 'ae_emirates_nbd-v1');
    expect(result.bank.id, 'ae_emirates_nbd'); // auto-detected
    expect(result.transactions.length, 3);

    // Normalised to ascending and reconciled via the running balance.
    final byDay = {for (final t in result.transactions) t.date.day: t};
    expect(byDay[16]!.debit, 17.00);
    expect(byDay[18]!.credit, 600.00);
    expect(byDay[20]!.debit, 100.00);
    expect(result.transactions.every((t) => t.confidence >= 0.9), isTrue);
  });
}
