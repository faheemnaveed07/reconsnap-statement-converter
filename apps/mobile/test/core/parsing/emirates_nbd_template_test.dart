import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:reconsnap_statement_converter/core/models/bank.dart';
import 'package:reconsnap_statement_converter/core/parsing/on_device_pdf_text_extractor.dart';
import 'package:reconsnap_statement_converter/core/parsing/statement_parser.dart';
import 'package:reconsnap_statement_converter/core/parsing/templated_statement_parser.dart';
import 'package:reconsnap_statement_converter/core/parsing/templates/emirates_nbd_template.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Column X positions mimicking a real Emirates NBD statement layout.
const _xDate = 40.0;
const _xDesc = 120.0;
const _xDebit = 330.0;
const _xCredit = 410.0;
const _xBalance = 480.0;

void _cell(PdfGraphics g, PdfFont font, String text, double x, double y) {
  g.drawString(text, font, bounds: Rect.fromLTWH(x, y, 220, 16));
}

/// Builds an Emirates NBD-style statement: separate Debit/Credit columns,
/// rows newest-first (reverse chronological), a multi-line description with a
/// phantom amount, and a `Cr` balance suffix.
List<int> _buildEnbdPdf() {
  final doc = PdfDocument();
  final page = doc.pages.add();
  final g = page.graphics;
  final font = PdfStandardFont(PdfFontFamily.courier, 10);

  _cell(g, font, 'Emirates NBD Bank (P.J.S.C.) - Statement of Account', 40, 12);

  // Header row.
  _cell(g, font, 'Date', _xDate, 50);
  _cell(g, font, 'Description', _xDesc, 50);
  _cell(g, font, 'Debit', _xDebit, 50);
  _cell(g, font, 'Credit', _xCredit, 50);
  _cell(g, font, 'Balance', _xBalance, 50);

  // Rows, newest first.
  _cell(g, font, '08/06/2024', _xDate, 80);
  _cell(g, font, 'Transfer in', _xDesc, 80);
  _cell(g, font, '1,200.00', _xCredit, 80);
  _cell(g, font, '8,500.00 Cr', _xBalance, 80);

  _cell(g, font, '05/06/2024', _xDate, 110);
  _cell(g, font, 'ATM withdrawal', _xDesc, 110);
  _cell(g, font, '500.00', _xDebit, 110);
  _cell(g, font, '7,300.00 Cr', _xBalance, 110);

  _cell(g, font, '03/06/2024', _xDate, 140);
  _cell(g, font, 'CARD 4439 Lulu', _xDesc, 140);
  _cell(g, font, '200.00', _xDebit, 140);
  _cell(g, font, '7,800.00 Cr', _xBalance, 140);
  // Continuation line: phantom amount placed at the left so it stays in the
  // description column.
  _cell(g, font, '7.49AED QUSAIS Dubai', _xDesc, 156);

  _cell(g, font, '01/06/2024', _xDate, 186);
  _cell(g, font, 'Salary credit', _xDesc, 186);
  _cell(g, font, '3,000.00', _xCredit, 186);
  _cell(g, font, '8,000.00 Cr', _xBalance, 186);

  // Footer disclaimer — must not be parsed as a row.
  _cell(g, font, 'This is an electronically generated statement.', 40, 220);

  final bytes = doc.saveSync();
  doc.dispose();
  return bytes;
}

Bank get _enbd => launchBanks.firstWhere((b) => b.id == 'ae_emirates_nbd');

void main() {
  test(
    'Emirates NBD template: columns, reverse order, multiline, reconcile',
    () async {
      final extractor = const OnDevicePdfTextExtractor();
      final doc = await extractor.extractDocument(
        bytes: _buildEnbdPdf(),
        filename: 'enbd.pdf',
      );
      final parsed = const EmiratesNbdTemplate().parse(doc, currency: 'AED');

      expect(parsed.transactions.length, 4);

      // Normalised to ascending chronological order.
      final dates = parsed.transactions.map((t) => t.date.day).toList();
      expect(dates, [1, 3, 5, 8]);

      // Explicit debit/credit columns, read by position.
      final byDay = {for (final t in parsed.transactions) t.date.day: t};
      expect(byDay[1]!.credit, 3000.00);
      expect(byDay[1]!.debit, isNull);
      expect(
        byDay[3]!.debit,
        200.00,
      ); // NOT the phantom 7.49 in the description
      expect(byDay[5]!.debit, 500.00);
      expect(byDay[8]!.credit, 1200.00);

      // Multi-line description stitched, phantom amount kept as text only.
      expect(byDay[3]!.description, contains('Lulu'));
      expect(byDay[3]!.description, contains('QUSAIS'));

      // Reconciliation: opening/closing and high confidence.
      expect(parsed.openingBalance, 5000.00);
      expect(parsed.closingBalance, 8500.00);
      expect(parsed.transactions.every((t) => t.confidence >= 0.9), isTrue);
      expect(parsed.warnings, isEmpty);
    },
  );

  test('orchestrator routes Emirates NBD to its template', () async {
    final parser = const TemplatedStatementParser(
      extractor: OnDevicePdfTextExtractor(),
    );
    final result = await parser.parse(
      ParseInput(filename: 'enbd.pdf', bank: _enbd, bytes: _buildEnbdPdf()),
    );

    expect(result.parserVersion, 'ae_emirates_nbd-v1');
    expect(result.transactions.length, 4);
  });
}
