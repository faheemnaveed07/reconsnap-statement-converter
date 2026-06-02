import 'dart:convert';
import 'dart:ui';

import 'package:syncfusion_flutter_pdf/pdf.dart';

/// A synthetic Emirates NBD "Statement of Account" that reproduces the real
/// layout's quirks (from high-res screenshots of a real statement):
///   - separate Debit / Credit columns
///   - rows newest-first (reverse chronological)
///   - multi-line descriptions; the date/amounts only on the first line
///   - decimal amounts embedded in descriptions (e.g. `7.49,AED`) that must NOT
///     be read as the transaction amount
///   - a `Cr` suffix on every balance
///   - a simulated page break: period banner + repeated table header + footer
///     disclaimer between transaction blocks
///
/// Balances are the *correct* reconciling values (the screenshot's
/// `68,0006.43` is an image artefact; the real figure is `58,006.43`).
///
/// One source of truth: both the committed stress test and the fixture
/// generator build the PDF and the ground truth from [enbdSampleRows].

class EnbdSampleRow {
  const EnbdSampleRow({
    required this.drawnDate,
    required this.date,
    required this.descLine1,
    required this.descMore,
    required this.truthDescription,
    required this.balance,
    this.debit,
    this.credit,
  });

  final String drawnDate; // as printed, e.g. "16/06/2024"
  final DateTime date;
  final String descLine1;
  final List<String> descMore; // continuation lines
  final String truthDescription; // distinctive tokens for ground-truth match
  final double balance;
  final double? debit;
  final double? credit;
}

/// Oldest → newest (chronological truth). The PDF draws them reversed.
final enbdSampleRows = <EnbdSampleRow>[
  EnbdSampleRow(
    drawnDate: '16/06/2024',
    date: DateTime(2024, 6, 16),
    descLine1: 'CARD NO.443913XXXXXX8386 DUBAI TAXI DUBAI AE',
    descMore: ['672611XX XX-XX-2024 343451'],
    truthDescription: 'DUBAI TAXI',
    debit: 17.00,
    balance: 57034.17,
  ),
  EnbdSampleRow(
    drawnDate: '16/06/2024',
    date: DateTime(2024, 6, 16),
    descLine1: 'CARD NO.443913XXXXXX8386 METRO TAXI DUBAI',
    descMore: ['AE 676605XX XX-XX-2024 899242'],
    truthDescription: 'METRO TAXI',
    debit: 22.00,
    balance: 57012.17,
  ),
  EnbdSampleRow(
    drawnDate: '18/06/2024',
    date: DateTime(2024, 6, 18),
    descLine1: 'MOBILE BANKING TRANSFER FROM',
    descMore: ['AE65026000101587 92831 01 111', 'REFNO:-0F532687BFC4'],
    truthDescription: 'MOBILE BANKING TRANSFER',
    credit: 600.00,
    balance: 57612.17,
  ),
  EnbdSampleRow(
    drawnDate: '19/06/2024',
    date: DateTime(2024, 6, 19),
    descLine1: 'CARD NO.443913XXXXXX8386 GOOGLE*GOOGLE',
    descMore: ['STORAGE G CO/HELPPAY#:US 734304 16-06-2024', '7.49,AED'],
    truthDescription: 'GOOGLE STORAGE',
    debit: 7.64, // NOT the 7.49 in the description
    balance: 57604.53,
  ),
  EnbdSampleRow(
    drawnDate: '20/06/2024',
    date: DateTime(2024, 6, 20),
    descLine1: 'RMA TT REF: EPHCOR17203Y9W9P 4C0B274F1C83',
    descMore: ['EMMANUE L ASHUBANG'],
    truthDescription: 'RMA TT REF',
    debit: 100.00,
    balance: 57504.53,
  ),
  EnbdSampleRow(
    drawnDate: '20/06/2024',
    date: DateTime(2024, 6, 20),
    descLine1: 'IPI TT REF: MBA0003133091622 EMMANUEL',
    descMore: ['ASHUBANG AFU NGCHWI 111'],
    truthDescription: 'IPI TT REF',
    credit: 525.00,
    balance: 58029.53,
  ),
  EnbdSampleRow(
    drawnDate: '20/06/2024',
    date: DateTime(2024, 6, 20),
    descLine1: 'CARD NO.443913XXXXXX8386 LuluHypermarket',
    descMore: ['QUSAIS Dubai AE 441040XX XX-XX-2024 991649'],
    truthDescription: 'LuluHypermarket',
    debit: 23.10,
    balance: 58006.43,
  ),
];

double get enbdOpeningBalance =>
    enbdSampleRows.first.balance -
    ((enbdSampleRows.first.credit ?? 0) - (enbdSampleRows.first.debit ?? 0));

double get enbdClosingBalance => enbdSampleRows.last.balance;

// Column X positions (PDF points). Spread wide on a landscape page so the long
// descriptions stay inside the Description band — mirroring the real statement,
// where Description is a wide column and Debit/Credit/Balance sit far right.
const _xDate = 30.0;
const _xDesc = 90.0;
const _xDebit = 560.0;
const _xCredit = 645.0;
const _xBalance = 730.0;

void _cell(
  PdfGraphics g,
  PdfFont font,
  String text,
  double x,
  double y, [
  double w = 100,
]) {
  // Wide bounds avoid accidental wrapping; glyph positions are what matter.
  g.drawString(text, font, bounds: Rect.fromLTWH(x, y, w, 12));
}

String _money(double v) {
  final neg = v < 0;
  final s = v.abs().toStringAsFixed(2);
  final dot = s.indexOf('.');
  final intPart = s.substring(0, dot);
  final dec = s.substring(dot);
  final buf = StringBuffer();
  for (var i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
    buf.write(intPart[i]);
  }
  return '${neg ? '-' : ''}$buf$dec';
}

void _drawRow(PdfGraphics g, PdfFont font, EnbdSampleRow r, double y) {
  _cell(g, font, r.drawnDate, _xDate, y, 80);
  _cell(g, font, r.descLine1, _xDesc, y, 440);
  if (r.debit != null) _cell(g, font, _money(r.debit!), _xDebit, y);
  if (r.credit != null) _cell(g, font, _money(r.credit!), _xCredit, y);
  _cell(g, font, '${_money(r.balance)} Cr', _xBalance, y);
  for (var i = 0; i < r.descMore.length; i++) {
    _cell(g, font, r.descMore[i], _xDesc, y + 11 * (i + 1), 440);
  }
}

void _drawHeaderRow(PdfGraphics g, PdfFont font, double y) {
  _cell(g, font, 'Date', _xDate, y);
  _cell(g, font, 'Description', _xDesc, y);
  _cell(g, font, 'Debit', _xDebit, y);
  _cell(g, font, 'Credit', _xCredit, y);
  _cell(g, font, 'Balance', _xBalance, y);
}

/// Builds the synthetic statement PDF bytes.
List<int> buildEnbdSamplePdf() {
  final doc = PdfDocument();
  doc.pageSettings.orientation = PdfPageOrientation.landscape;
  final page = doc.pages.add();
  final g = page.graphics;
  final font = PdfStandardFont(PdfFontFamily.courier, 8);

  // Account header block.
  _cell(g, font, 'Emirates NBD Bank (P.J.S.C.)   Statement of Account', 40, 18);
  _cell(g, font, 'Currency AED   Account No 1015802689201', 40, 36);
  _cell(
    g,
    font,
    'IBAN AE210260001015802689201   Account type CURRENT ACCOUNT',
    40,
    54,
  );
  _cell(
    g,
    font,
    'STATEMENT OF ACCOUNT FOR THE PERIOD OF 21-03-2024 to 21-06-2024   Page 1 of 11',
    40,
    80,
  );

  _drawHeaderRow(g, font, 104);

  final reversed = enbdSampleRows.reversed.toList();
  var y = 126.0;
  for (var idx = 0; idx < reversed.length; idx++) {
    // Simulate a page break midway: period banner + repeated header.
    if (idx == 4) {
      _cell(
        g,
        font,
        'STATEMENT OF ACCOUNT FOR THE PERIOD OF 21-03-2024 to 21-06-2024   Page 2 of 11',
        40,
        y,
      );
      y += 16;
      _drawHeaderRow(g, font, y);
      y += 18;
    }
    final r = reversed[idx];
    _drawRow(g, font, r, y);
    y += 14.0 * (1 + r.descMore.length) + 8;
  }

  // Footer disclaimer block (must be skipped, not parsed).
  _cell(
    g,
    font,
    'Confirmation of the correctness of the statement as rendered will be assumed',
    40,
    y + 6,
  );
  _cell(
    g,
    font,
    'Emirates NBD Bank (P.J.S.C.) is licensed by the Central Bank of the UAE',
    40,
    y + 22,
  );
  _cell(
    g,
    font,
    'This is an electronically generated statement, hence, does not require a signature',
    40,
    y + 38,
  );

  final bytes = doc.saveSync();
  doc.dispose();
  return bytes;
}

/// The hand-verified ground truth for [buildEnbdSamplePdf], as the JSON the
/// accuracy harness consumes.
String enbdSampleGroundTruthJson() {
  String two(int v) => v.toString().padLeft(2, '0');
  return const JsonEncoder.withIndent('  ').convert({
    'bankId': 'ae_emirates_nbd',
    'currency': 'AED',
    'openingBalance': enbdOpeningBalance,
    'closingBalance': enbdClosingBalance,
    'transactions': [
      for (final r in enbdSampleRows)
        {
          'date': '${r.date.year}-${two(r.date.month)}-${two(r.date.day)}',
          if (r.debit != null) 'debit': r.debit,
          if (r.credit != null) 'credit': r.credit,
          'balance': r.balance,
          'description': r.truthDescription,
        },
    ],
  });
}
