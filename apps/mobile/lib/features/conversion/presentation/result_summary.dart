import 'package:intl/intl.dart';

import '../../../core/models/conversion_job.dart';
import '../../../core/models/validation_report.dart';

/// A row at or above this confidence is "auto-verified by balance"; below it the
/// row is flagged for the user's eyes. Surfaced as the denominator everywhere so
/// the score can be decomposed ("44 of 47 rows verified — 3 need review").
const double kVerifyThreshold = 0.80;

final _money = NumberFormat('#,##0.00');

/// Formats a figure the way it appears across the app — grouped, two decimals,
/// always set in mono. Negatives keep a leading minus.
String formatMoney(num value) => _money.format(value);

/// Per-conversion verdict, derived entirely from data the engine already
/// produces (confidence + the balance reconciliation). No fabricated numbers.
extension JobVerdict on ConversionJob {
  int get rowCount => transactions.length;

  /// Rows the running-balance reconciliation verified on its own.
  int get verifiedCount =>
      transactions.where((t) => t.confidence >= kVerifyThreshold).length;

  /// Rows that need the user's eyes (low confidence).
  int get flaggedCount => rowCount - verifiedCount;

  /// True only when the balance reconciles *and* no row is flagged — the
  /// strongest, fully-honest verdict.
  bool get fullyReconciled => validationReport.isPassed && flaggedCount == 0;

  /// A short, true status line for Home/History (e.g. "47/47 rows reconciled"
  /// or "3 of 47 rows need review").
  String get verdictLabel {
    if (flaggedCount == 0 && validationReport.isPassed) {
      return '$verifiedCount/$rowCount rows reconciled';
    }
    if (!validationReport.isPassed) {
      final off = validationReport.reconciliationDelta;
      if (off != null && off.abs() >= 0.005) {
        return 'Off by ${formatMoney(off.abs())} — needs review';
      }
    }
    return '$flaggedCount of $rowCount rows need review';
  }
}

extension ReconciliationMath on ValidationReport {
  /// computed closing = opening + credits − debits. Null if we have no opening.
  double? get computedClosing {
    final open = openingBalance;
    if (open == null) return null;
    return open + totalCredits - totalDebits;
  }

  /// The reconciliation delta to the cent: computed closing − stated closing.
  /// Null when either side is unknown. ~0 means it reconciles exactly.
  double? get reconciliationDelta {
    final computed = computedClosing;
    final stated = closingBalance;
    if (computed == null || stated == null) return null;
    return computed - stated;
  }

  /// True when the computed closing matches the statement's stated closing to
  /// the cent.
  bool get reconcilesToTheCent {
    final delta = reconciliationDelta;
    return delta != null && delta.abs() < 0.005;
  }
}
