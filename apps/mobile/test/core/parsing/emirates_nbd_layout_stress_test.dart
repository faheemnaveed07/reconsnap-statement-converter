import 'package:flutter_test/flutter_test.dart';
import 'package:reconsnap_statement_converter/core/models/bank.dart';
import 'package:reconsnap_statement_converter/core/parsing/on_device_pdf_text_extractor.dart';
import 'package:reconsnap_statement_converter/core/parsing/statement_parser.dart';
import 'package:reconsnap_statement_converter/core/parsing/templated_statement_parser.dart';
import 'package:reconsnap_statement_converter/core/parsing/templates/emirates_nbd_template.dart';

import '../../accuracy/accuracy_metrics.dart';
import '../../accuracy/enbd_sample_layout.dart';

/// Stress-tests the Emirates NBD template against a synthetic statement that
/// reproduces the real layout's quirks. This is NOT an accuracy claim on real
/// statements — it proves the template handles the structure we can see in the
/// screenshots (reverse order, separate columns, multi-line descriptions,
/// description-embedded amounts, Cr balances, and page-break boilerplate).
Bank _enbd() => launchBanks.firstWhere((b) => b.id == 'ae_emirates_nbd');

void main() {
  test(
    'parses the Emirates NBD layout, reconciles, zero silent errors',
    () async {
      final doc = await const OnDevicePdfTextExtractor().extractDocument(
        bytes: buildEnbdSamplePdf(),
        filename: 'enbd.pdf',
      );
      final parsed = const EmiratesNbdTemplate().parse(doc, currency: 'AED');

      // All 7 rows, none dropped, no page-break boilerplate captured as a row.
      expect(parsed.transactions.length, enbdSampleRows.length);

      // Normalised to ascending chronological order across the simulated pages.
      expect(parsed.transactions.map((t) => t.date.day).toList(), [
        16,
        16,
        18,
        19,
        20,
        20,
        20,
      ]);

      // Reconciles end to end.
      expect(parsed.openingBalance, closeTo(enbdOpeningBalance, 0.001));
      expect(parsed.closingBalance, closeTo(enbdClosingBalance, 0.001));
      expect(parsed.warnings, isEmpty);

      // The Google row's debit is the column value, NOT the 7.49 in its text.
      final google = parsed.transactions.firstWhere(
        (t) => t.description.toLowerCase().contains('google'),
      );
      expect(google.debit, 7.64);
      expect(google.description, contains('7.49')); // kept as description text

      // Multi-line description stitched.
      expect(google.description.toLowerCase(), contains('storage'));
    },
  );

  test(
    'measured against ground truth: recall 100%, zero silent errors',
    () async {
      final result =
          await const TemplatedStatementParser(
            extractor: OnDevicePdfTextExtractor(),
          ).parse(
            ParseInput(
              filename: 'enbd.pdf',
              bank: _enbd(),
              bytes: buildEnbdSamplePdf(),
            ),
          );

      final truth = GroundTruth.parse(enbdSampleGroundTruthJson());
      final report = compareToGroundTruth(
        'enbd-sample',
        truth,
        result.transactions,
      );

      expect(result.parserVersion, 'ae_emirates_nbd-v1');
      expect(report.recall, 1.0);
      expect(report.directionAccuracy, 1.0);
      expect(report.balanceAccuracy, 1.0);
      expect(report.silentErrors, 0);
      expect(report.closingReconciled, isTrue);
    },
  );
}
