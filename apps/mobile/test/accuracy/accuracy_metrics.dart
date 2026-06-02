import 'dart:convert';

import 'package:reconsnap_statement_converter/core/models/statement_transaction.dart';

/// One expected (ground-truth) transaction for a real statement.
class ExpectedTxn {
  ExpectedTxn({
    required this.date,
    this.debit,
    this.credit,
    this.balance,
    this.description = '',
  });

  final DateTime date;
  final double? debit;
  final double? credit;
  final double? balance;
  final String description;

  bool get isDebit => (debit ?? 0) != 0;
  double get magnitude => (debit ?? 0) != 0 ? debit! : (credit ?? 0);

  factory ExpectedTxn.fromJson(Map<String, dynamic> j) => ExpectedTxn(
    date: DateTime.parse(j['date'] as String),
    debit: (j['debit'] as num?)?.toDouble(),
    credit: (j['credit'] as num?)?.toDouble(),
    balance: (j['balance'] as num?)?.toDouble(),
    description: (j['description'] as String?) ?? '',
  );
}

/// The hand-verified truth for one statement PDF.
class GroundTruth {
  GroundTruth({
    required this.bankId,
    required this.currency,
    required this.transactions,
    this.openingBalance,
    this.closingBalance,
  });

  final String bankId;
  final String currency;
  final double? openingBalance;
  final double? closingBalance;
  final List<ExpectedTxn> transactions;

  factory GroundTruth.fromJson(Map<String, dynamic> j) => GroundTruth(
    bankId: j['bankId'] as String,
    currency: (j['currency'] as String?) ?? 'AED',
    openingBalance: (j['openingBalance'] as num?)?.toDouble(),
    closingBalance: (j['closingBalance'] as num?)?.toDouble(),
    transactions: (j['transactions'] as List<dynamic>)
        .map((e) => ExpectedTxn.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  static GroundTruth parse(String jsonStr) =>
      GroundTruth.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
}

/// The measured accuracy of one statement against its ground truth.
///
/// The headline number for a trust product is **silentErrors**, not recall:
/// a row we got wrong but presented with high confidence is far more damaging
/// than a row we flagged for review. The goal is silentErrors == 0.
class AccuracyReport {
  AccuracyReport(this.label);

  final String label;

  int expectedCount = 0;
  int actualCount = 0;
  int matched = 0; // expected rows found in the output (by date + magnitude)
  int extraRows = 0; // output rows matching no expected row (phantoms)

  int directionCorrect = 0; // matched rows with correct debit-vs-credit
  int balanceComparable = 0;
  int balanceCorrect = 0;
  int descriptionComparable = 0;
  int descriptionCorrect = 0;

  int flaggedRows = 0; // output rows below the review-confidence threshold
  int silentErrors = 0; // wrong rows that were NOT flagged (confidence high)

  bool? closingReconciled; // parser closing vs expected closing (null if N/A)

  double get recall => expectedCount == 0 ? 1 : matched / expectedCount;
  double get directionAccuracy => matched == 0 ? 1 : directionCorrect / matched;
  double get balanceAccuracy =>
      balanceComparable == 0 ? 1 : balanceCorrect / balanceComparable;
  double get reviewBurden => actualCount == 0 ? 0 : flaggedRows / actualCount;

  String format() {
    String pct(double v) => '${(v * 100).toStringAsFixed(1)}%';
    final lines = [
      '── $label',
      '   rows: expected=$expectedCount actual=$actualCount '
          'matched=$matched extra=$extraRows missing=${expectedCount - matched}',
      '   recall=${pct(recall)} direction=${pct(directionAccuracy)} '
          'balance=${pct(balanceAccuracy)}',
      '   description≈ ${descriptionComparable == 0 ? "n/a" : pct(descriptionCorrect / descriptionComparable)}',
      '   reviewBurden=${pct(reviewBurden)} flagged=$flaggedRows',
      '   closingReconciled=${closingReconciled ?? "n/a"}',
      '   >>> SILENT ERRORS (wrong + unflagged) = $silentErrors',
    ];
    return lines.join('\n');
  }
}

/// Compares parser output against ground truth.
///
/// Rows are matched on (date, magnitude) — fields *not* used for matching
/// (debit-vs-credit direction, balance, description) are then scored, so a
/// reversed-order or column-swapped row shows up as a direction error rather
/// than hiding. [reviewThreshold] is the confidence below which the app flags a
/// row for human review.
AccuracyReport compareToGroundTruth(
  String label,
  GroundTruth truth,
  List<StatementTransaction> actual, {
  double reviewThreshold = 0.9,
  double eps = 0.02,
}) {
  final report = AccuracyReport(label)
    ..expectedCount = truth.transactions.length
    ..actualCount = actual.length;

  final unusedActual = [...actual];
  final matchedActual = <StatementTransaction>{};

  for (final e in truth.transactions) {
    StatementTransaction? hit;
    for (final a in unusedActual) {
      final aMag = (a.debit ?? 0) != 0 ? a.debit! : (a.credit ?? 0);
      if (a.date.year == e.date.year &&
          a.date.month == e.date.month &&
          a.date.day == e.date.day &&
          (aMag - e.magnitude).abs() <= eps) {
        hit = a;
        break;
      }
    }
    if (hit == null) continue;
    unusedActual.remove(hit);
    matchedActual.add(hit);
    report.matched++;

    final aIsDebit = (hit.debit ?? 0) != 0;
    final directionOk = aIsDebit == e.isDebit;
    if (directionOk) report.directionCorrect++;

    var balanceOk = true;
    if (e.balance != null && hit.balance != null) {
      report.balanceComparable++;
      balanceOk = (hit.balance! - e.balance!).abs() <= eps;
      if (balanceOk) report.balanceCorrect++;
    }

    var descOk = true;
    if (e.description.trim().isNotEmpty) {
      report.descriptionComparable++;
      descOk = _descriptionMatches(e.description, hit.description);
      if (descOk) report.descriptionCorrect++;
    }

    // A matched row that is wrong on any scored field, yet presented with high
    // confidence, is a silent error — the worst outcome for a trust product.
    final wrong = !directionOk || !balanceOk || !descOk;
    if (wrong && hit.confidence >= reviewThreshold) report.silentErrors++;
  }

  report.extraRows = unusedActual.length;
  // An unexpected (phantom) row presented confidently is also a silent error.
  for (final a in unusedActual) {
    if (a.confidence >= reviewThreshold) report.silentErrors++;
  }

  report.flaggedRows = actual
      .where((a) => a.confidence < reviewThreshold)
      .length;

  if (truth.closingBalance != null) {
    final sorted = [...actual]..sort((a, b) => a.date.compareTo(b.date));
    final actualClosing = sorted
        .lastWhere((t) => t.balance != null, orElse: () => _noBalance)
        .balance;
    report.closingReconciled =
        actualClosing != null &&
        (actualClosing - truth.closingBalance!).abs() <= eps;
  }

  return report;
}

final _noBalance = StatementTransaction(
  id: '_',
  date: DateTime(2000),
  description: '',
);

/// Lenient description match: token overlap (Jaccard) ≥ 0.3, since the OCR/text
/// layer often reorders or truncates words.
bool _descriptionMatches(String expected, String actual) {
  Set<String> tokens(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
      .split(RegExp(r'\s+'))
      .where((t) => t.length >= 3)
      .toSet();
  final e = tokens(expected);
  final a = tokens(actual);
  if (e.isEmpty) return true;
  final overlap = e.intersection(a).length;
  return overlap / e.length >= 0.3;
}
