import 'package:uuid/uuid.dart';

import '../../models/statement_transaction.dart';
import 'money.dart';
import 'parsed_statement.dart';
import 'statement_date.dart';

/// Turns the raw text of a (digital) PDF statement into structured
/// transactions.
///
/// The hard part of statement parsing is that, once a PDF is flattened to
/// text, the debit/credit column structure is lost — you just get a date, a
/// description, and a row of numbers. This parser recovers the missing
/// structure using the **running balance**: when a line carries both an amount
/// and a balance, the sign of `balance - previousBalance` tells us whether the
/// amount was a debit or a credit, and the magnitude lets us cross-check the
/// amount we read. That same reconciliation drives the per-row confidence
/// score, so low-confidence rows can be flagged for review instead of silently
/// shipped — which is the trust feature ReconSnap is built around.
class TransactionLineParser {
  const TransactionLineParser({this.dayFirst = true, Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  /// Day-first date interpretation (UAE/GCC/UK). Set false for US statements.
  final bool dayFirst;
  final Uuid _uuid;

  /// Descriptions that mark a balance anchor rather than a real transaction
  /// (opening balance, balance brought forward, etc.). When one of these lines
  /// carries a single amount we treat that amount as the running balance so the
  /// following rows can be reconciled, instead of emitting a phantom debit.
  static final RegExp _balanceAnchor = RegExp(
    r'opening balance|balance brought forward|brought forward'
    r'|balance b/?f|b/?f balance|balance forward|opening',
    caseSensitive: false,
  );

  ParsedStatement parse(String text, {String currency = 'AED'}) {
    final lines = const LineSplitter().split(text);
    final transactions = <StatementTransaction>[];
    final warnings = <String>[];

    double? runningBalance;
    double? openingBalance;
    double? closingBalance;
    var lineNo = 0;

    for (final rawLine in lines) {
      lineNo++;
      final line = rawLine.trimRight();
      if (line.trim().isEmpty) continue;

      final dateMatch = StatementDate.leading(line, dayFirst: dayFirst);
      if (dateMatch == null) continue;

      final rest = line.substring(dateMatch.length);
      final amounts = Money.findAll(rest);
      if (amounts.isEmpty) continue;

      // Description is the text between the date and the first money token.
      final firstAmountStart = amounts.first.start;
      final description = rest.substring(0, firstAmountStart).trim();
      if (description.isEmpty) {
        // A date followed only by numbers is almost always a summary/total row.
        warnings.add('Line $lineNo skipped: no description.');
        continue;
      }

      // A balance-anchor line (e.g. "Opening Balance  5,000.00") sets the
      // running balance and is not itself a transaction.
      if (amounts.length == 1 && _balanceAnchor.hasMatch(description)) {
        runningBalance = amounts.first.value;
        openingBalance ??= amounts.first.value;
        closingBalance = amounts.first.value;
        continue;
      }

      // Convention across most layouts: the right-most number is the balance.
      final hasBalance = amounts.length >= 2;
      final balance = hasBalance ? amounts.last.value : null;
      final amountTokens = hasBalance
          ? amounts.sublist(0, amounts.length - 1)
          : amounts;

      final resolved = _resolveAmount(
        amountTokens: amountTokens.map((a) => a.value).toList(),
        balance: balance,
        runningBalance: runningBalance,
      );

      if (resolved == null) {
        warnings.add('Line $lineNo: could not determine debit/credit.');
        continue;
      }

      openingBalance ??= runningBalance ?? balance;
      transactions.add(
        StatementTransaction(
          id: _uuid.v4(),
          date: dateMatch.date,
          description: _collapseWhitespace(description),
          debit: resolved.debit,
          credit: resolved.credit,
          balance: balance,
          currency: currency,
          confidence: resolved.confidence,
          sourceLine: lineNo,
        ),
      );

      if (balance != null) {
        runningBalance = balance;
        closingBalance = balance;
      }
    }

    return ParsedStatement(
      transactions: transactions,
      warnings: warnings,
      openingBalance: openingBalance,
      closingBalance: closingBalance,
    );
  }

  /// Decides whether the row is a debit or credit and how confident we are.
  _ResolvedAmount? _resolveAmount({
    required List<double> amountTokens,
    required double? balance,
    required double? runningBalance,
  }) {
    // The balance delta is the most reliable signal when we have both a
    // previous balance and a current one.
    if (balance != null && runningBalance != null) {
      final delta = balance - runningBalance;
      final magnitude = delta.abs();
      // Find the token that best matches the delta magnitude.
      final picked = _closest(amountTokens, magnitude);
      final isCredit = delta >= 0;
      final amount = picked ?? magnitude;
      // Confidence reflects how well the read amount matches the balance move.
      final mismatch = picked == null ? magnitude : (picked - magnitude).abs();
      final confidence = mismatch <= 0.01
          ? 0.98
          : mismatch <= 1.0
          ? 0.8
          : 0.55;
      return _ResolvedAmount(
        debit: isCredit ? null : amount,
        credit: isCredit ? amount : null,
        confidence: confidence,
      );
    }

    // No balance to reconcile against. Use sign of a single signed amount, or
    // fall back to treating it as a debit with reduced confidence.
    if (amountTokens.length == 1) {
      final value = amountTokens.first;
      if (value < 0) {
        return _ResolvedAmount(debit: value.abs(), confidence: 0.85);
      }
      // Ambiguous: positive amount, no balance, no sign marker.
      return _ResolvedAmount(debit: value, confidence: 0.45);
    }

    return null;
  }

  static double? _closest(List<double> values, double target) {
    if (values.isEmpty) return null;
    double? best;
    var bestDiff = double.infinity;
    for (final v in values) {
      final diff = (v.abs() - target).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        best = v.abs();
      }
    }
    return best;
  }

  static String _collapseWhitespace(String input) =>
      input.replaceAll(RegExp(r'\s+'), ' ').trim();
}

class _ResolvedAmount {
  const _ResolvedAmount({this.debit, this.credit, required this.confidence});

  final double? debit;
  final double? credit;
  final double confidence;
}

/// Minimal line splitter that handles `\n`, `\r\n`, and `\r`.
class LineSplitter {
  const LineSplitter();

  List<String> split(String text) =>
      text.split(RegExp(r'\r\n|\r|\n'));
}
