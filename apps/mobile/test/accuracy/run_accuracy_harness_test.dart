import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:reconsnap_statement_converter/core/models/bank.dart';
import 'package:reconsnap_statement_converter/core/parsing/on_device_pdf_text_extractor.dart';
import 'package:reconsnap_statement_converter/core/parsing/statement_parser.dart';
import 'package:reconsnap_statement_converter/core/parsing/templated_statement_parser.dart';

import 'accuracy_metrics.dart';

/// Measures the real pipeline against hand-verified ground truth.
///
/// Drop real (anonymised) statements into `test/fixtures/accuracy/` as pairs:
///   `name.pdf` + `name.expected.json`   (see docs/ACCURACY.md)
/// Both are git-ignored. Run:
///   flutter test test/accuracy/run_accuracy_harness_test.dart
///
/// When no fixtures exist it skips with guidance instead of failing, so it is
/// safe to keep in CI before any real data has been collected.
void main() {
  test('parser accuracy over real statement fixtures', () async {
    final dir = Directory('test/fixtures/accuracy');
    final pdfs = dir.existsSync()
        ? (dir.listSync().whereType<File>().where(
            (f) => f.path.toLowerCase().endsWith('.pdf'),
          )).toList()
        : <File>[];

    if (pdfs.isEmpty) {
      markTestSkipped(
        'No accuracy fixtures yet. Add <name>.pdf + <name>.expected.json to '
        'test/fixtures/accuracy/ (see docs/ACCURACY.md) to measure accuracy.',
      );
      return;
    }

    const parser = TemplatedStatementParser(
      extractor: OnDevicePdfTextExtractor(),
    );
    final reports = <AccuracyReport>[];

    for (final pdf in pdfs..sort((a, b) => a.path.compareTo(b.path))) {
      final name = pdf.path.split('/').last;
      final truthFile = File(
        pdf.path.replaceFirst(RegExp(r'\.pdf$'), '.expected.json'),
      );
      if (!truthFile.existsSync()) {
        stderr.writeln('SKIP $name — no .expected.json sibling');
        continue;
      }

      final truth = GroundTruth.parse(await truthFile.readAsString());
      final bank = _bankFor(truth.bankId);

      try {
        final result = await parser.parse(
          ParseInput(
            filename: name,
            bank: bank,
            bytes: await pdf.readAsBytes(),
          ),
        );
        final report = compareToGroundTruth(
          '$name (${result.parserVersion})',
          truth,
          result.transactions,
        );
        reports.add(report);
        stderr.writeln(report.format());
      } catch (e) {
        stderr.writeln('── $name\n   PARSE FAILED: $e');
      }
    }

    if (reports.isEmpty) return;

    final totalSilent = reports.fold(0, (s, r) => s + r.silentErrors);
    final avgRecall =
        reports.fold(0.0, (s, r) => s + r.recall) / reports.length;
    stderr.writeln('\n================ AGGREGATE ================');
    stderr.writeln(
      'fixtures=${reports.length} '
      'avgRecall=${(avgRecall * 100).toStringAsFixed(1)}% '
      'TOTAL SILENT ERRORS=$totalSilent',
    );

    // The trust gate: never present a wrong row as correct. Recall/accuracy
    // thresholds are reviewed from the printed report and locked once a real
    // baseline exists; silent errors must always be zero.
    expect(
      totalSilent,
      0,
      reason: 'Wrong rows were presented at high confidence — see report.',
    );
  });
}

Bank _bankFor(String bankId) {
  for (final b in launchBanks) {
    if (b.id == bankId) return b;
  }
  return Bank(
    id: bankId,
    name: bankId,
    countryCode: 'AE',
    supportLevel: BankSupportLevel.requested,
  );
}
