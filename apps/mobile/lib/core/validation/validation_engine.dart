import '../models/statement_transaction.dart';
import '../models/validation_report.dart';

class ValidationEngine {
  const ValidationEngine({this.tolerance = 0.01});

  final double tolerance;

  ValidationReport validate(List<StatementTransaction> transactions) {
    final sorted = [...transactions]..sort((a, b) => a.date.compareTo(b.date));
    final openingBalance = _openingBalance(sorted);
    final closingBalance = _closingBalance(sorted);
    final totalDebits = sorted.totalDebits;
    final totalCredits = sorted.totalCredits;
    final expectedClosingBalance = openingBalance == null
        ? null
        : openingBalance + totalCredits - totalDebits;
    final issues = <ValidationIssue>[];

    if (sorted.isEmpty) {
      issues.add(
        const ValidationIssue(
          title: 'No transactions found',
          message: 'The parser did not return any transaction rows.',
          severity: ValidationSeverity.fail,
        ),
      );
    }

    if (openingBalance == null || closingBalance == null) {
      issues.add(
        const ValidationIssue(
          title: 'Balance check incomplete',
          message:
              'Opening or closing balance is missing, so the statement cannot be fully reconciled yet.',
        ),
      );
    }

    if (expectedClosingBalance != null && closingBalance != null) {
      final delta = (expectedClosingBalance - closingBalance).abs();
      if (delta > tolerance) {
        issues.add(
          ValidationIssue(
            title: 'Closing balance mismatch',
            message:
                'Expected closing balance differs by ${delta.toStringAsFixed(2)}.',
            severity: ValidationSeverity.fail,
          ),
        );
      }
    }

    final lowConfidenceRows = sorted
        .where((transaction) => transaction.confidence < 0.85)
        .length;
    if (lowConfidenceRows > 0) {
      issues.add(
        ValidationIssue(
          title: 'Review low-confidence rows',
          message: '$lowConfidenceRows rows need manual review before export.',
        ),
      );
    }

    return ValidationReport(
      openingBalance: openingBalance,
      closingBalance: closingBalance,
      totalDebits: totalDebits,
      totalCredits: totalCredits,
      expectedClosingBalance: expectedClosingBalance,
      issues: issues,
    );
  }

  double? _openingBalance(List<StatementTransaction> transactions) {
    if (transactions.isEmpty) return null;
    final first = transactions.first;
    final firstBalance = first.balance;
    if (firstBalance == null) return null;
    return firstBalance - first.signedAmount;
  }

  double? _closingBalance(List<StatementTransaction> transactions) {
    if (transactions.isEmpty) return null;
    return transactions.last.balance;
  }
}
