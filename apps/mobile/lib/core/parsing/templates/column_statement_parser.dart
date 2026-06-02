import 'package:uuid/uuid.dart';

import '../../models/statement_transaction.dart';
import '../column/column_mapper.dart';
import '../positioned/positioned_models.dart';
import '../text/money.dart';
import '../text/parsed_statement.dart';
import '../text/statement_date.dart';

/// Data-driven description of a column-table statement. New banks are usually
/// just a different [ColumnTableConfig] (column synonyms, date order), not new
/// code — which is how this scales to FAB / ADCB / Mashreq / DIB.
class ColumnTableConfig {
  const ColumnTableConfig({
    this.columns = defaultColumns,
    this.dayFirst = true,
    this.noiseMarkers = defaultNoiseMarkers,
    this.maxContinuationLines = 3,
  });

  final List<ColumnSpec> columns;

  /// Day-first date interpretation (UAE/GCC/UK). false for US statements.
  final bool dayFirst;

  /// Lower-case substrings on a non-transaction line (page footers, disclaimers,
  /// repeated page headers, period banners) that should be *skipped* rather than
  /// folded into the previous row's description. Crucial for multi-page
  /// statements, where this boilerplate repeats between transaction blocks.
  final List<String> noiseMarkers;

  /// A real row's description spans at most a few lines. Capping how many lines
  /// we append after a date row stops a repeated page-header/account block from
  /// polluting the previous transaction when markers miss it.
  final int maxContinuationLines;

  static const defaultColumns = <ColumnSpec>[
    ColumnSpec(key: 'date', keywords: ['date']),
    ColumnSpec(
      key: 'description',
      keywords: [
        'description',
        'details',
        'particulars',
        'narration',
        'transaction',
        'remarks',
      ],
    ),
    ColumnSpec(
      key: 'debit',
      keywords: ['debit', 'withdrawal', 'withdrawals', 'dr', 'paidout'],
    ),
    ColumnSpec(
      key: 'credit',
      keywords: ['credit', 'deposit', 'deposits', 'cr', 'paidin'],
    ),
    ColumnSpec(key: 'balance', keywords: ['balance']),
  ];

  static const defaultNoiseMarkers = <String>[
    'electronically generated',
    'confirmation of the correctness',
    'computer generated',
    'statement of account for the period',
    'page ', // "Page 2 of 11"
    'licensed by the central bank',
    'head office',
    'registered details',
    'paid up capital',
    'commercial registration',
    'tax registration',
    'www.',
  ];
}

/// Accumulates a transaction while we read its (possibly multi-line) description.
class _RowBuilder {
  _RowBuilder({
    required this.date,
    required this.description,
    required this.debit,
    required this.credit,
    required this.balance,
    required this.sourceLine,
  });

  DateTime date;
  String description;
  double? debit;
  double? credit;
  double? balance;
  int sourceLine;

  double get signed => (credit ?? 0) - (debit ?? 0);
}

/// Parses a statement by column position rather than by guessing from flattened
/// text. Reads Debit/Credit from their own columns (so card numbers in the
/// description are never mistaken for amounts), stitches multi-line
/// descriptions, normalises reverse-chronological ordering, and uses the
/// running balance only to *validate* each row — flagging, never silently
/// "fixing", anything that doesn't reconcile.
class ColumnStatementParser {
  const ColumnStatementParser({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  /// Balance-match tolerance, to absorb currency rounding.
  static const _eps = 0.02;

  ParsedStatement parse(
    ExtractedDocument doc,
    ColumnTableConfig config, {
    required String currency,
  }) {
    final layout = ColumnLayout.detect(
      doc.lines,
      config.columns,
      requireAll: {'date', 'balance'},
      requireAny: {'debit', 'credit'},
    );
    if (layout == null) {
      return const ParsedStatement(
        transactions: [],
        warnings: ['Could not locate the transaction table header.'],
      );
    }

    final warnings = <String>[];
    final rows = _extractRows(doc, layout, config);
    if (rows.isEmpty) {
      return const ParsedStatement(
        transactions: [],
        warnings: ['No transaction rows were found under the table header.'],
      );
    }

    final ascending = _toAscending(rows);
    return _reconcile(ascending, currency: currency, warnings: warnings);
  }

  List<_RowBuilder> _extractRows(
    ExtractedDocument doc,
    ColumnLayout layout,
    ColumnTableConfig config,
  ) {
    final rows = <_RowBuilder>[];
    _RowBuilder? current;
    var continuation = 0;

    for (var i = layout.headerLineIndex + 1; i < doc.lines.length; i++) {
      final line = doc.lines[i];
      final dateCell = layout.cell(line, 'date').trim();
      final dm = StatementDate.leading(dateCell, dayFirst: config.dayFirst);

      if (dm != null) {
        if (current != null) rows.add(current);
        current = _RowBuilder(
          date: dm.date,
          description: layout.cell(line, 'description').trim(),
          debit: Money.amountIn(layout.cell(line, 'debit')),
          credit: Money.amountIn(layout.cell(line, 'credit')),
          balance: Money.amountIn(layout.cell(line, 'balance')),
          sourceLine: i + 1,
        );
        continuation = 0;
        continue;
      }

      // A line with no date is a continuation of the current row's description,
      // or boilerplate that repeats on page breaks. Skip boilerplate; don't
      // break, so transactions on later pages are still collected.
      if (current == null) continue;
      if (_isNoise(line.text.toLowerCase(), config)) continue;
      if (++continuation > config.maxContinuationLines) continue;

      final descText = layout.cell(line, 'description').trim();
      if (descText.isNotEmpty) {
        current.description = '${current.description} $descText'.trim();
      }
    }
    if (current != null) rows.add(current);

    // A row with no amount and no balance is not a transaction.
    rows.removeWhere(
      (r) => r.debit == null && r.credit == null && r.balance == null,
    );
    return rows;
  }

  /// Chooses the orientation (as-extracted vs reversed) whose balances better
  /// match the signed amounts, so newest-first statements reconcile correctly.
  List<_RowBuilder> _toAscending(List<_RowBuilder> rows) {
    if (rows.length < 2) return rows;
    final asIs = _consistencyScore(rows);
    final reversed = rows.reversed.toList();
    return _consistencyScore(reversed) > asIs ? reversed : rows;
  }

  /// Counts adjacent pairs where `balance[j] ≈ balance[j-1] + signed(row[j])`.
  int _consistencyScore(List<_RowBuilder> rows) {
    var score = 0;
    for (var j = 1; j < rows.length; j++) {
      final prev = rows[j - 1].balance;
      final cur = rows[j].balance;
      if (prev == null || cur == null) continue;
      if ((cur - (prev + rows[j].signed)).abs() <= _eps) score++;
    }
    return score;
  }

  ParsedStatement _reconcile(
    List<_RowBuilder> rows, {
    required String currency,
    required List<String> warnings,
  }) {
    final transactions = <StatementTransaction>[];
    double? opening;
    double? closing;

    for (var j = 0; j < rows.length; j++) {
      final r = rows[j];
      double confidence;

      if (j == 0) {
        opening = r.balance != null ? r.balance! - r.signed : null;
        confidence = (r.debit != null || r.credit != null) ? 0.9 : 0.6;
      } else {
        final prev = rows[j - 1].balance;
        if (prev != null && r.balance != null) {
          final reconciles = (r.balance! - (prev + r.signed)).abs() <= _eps;
          confidence = reconciles ? 0.99 : 0.5;
          if (!reconciles) {
            warnings.add(
              'Row ${r.sourceLine} (${_short(r.description)}) did not '
              'reconcile against the running balance.',
            );
          }
        } else {
          confidence = 0.6;
        }
      }

      // Neither debit nor credit is suspicious — keep the row but flag it.
      if (r.debit == null && r.credit == null && confidence > 0.4) {
        confidence = 0.4;
      }
      if (r.balance != null) closing = r.balance;

      transactions.add(
        StatementTransaction(
          id: _uuid.v4(),
          date: r.date,
          description: r.description.isEmpty
              ? '(no description)'
              : r.description,
          debit: r.debit,
          credit: r.credit,
          balance: r.balance,
          currency: currency,
          confidence: confidence,
          sourceLine: r.sourceLine,
        ),
      );
    }

    return ParsedStatement(
      transactions: transactions,
      warnings: warnings,
      openingBalance: opening,
      closingBalance: closing,
    );
  }

  static bool _isNoise(String lower, ColumnTableConfig config) {
    if (config.noiseMarkers.any(lower.contains)) return true;
    // A repeated table header on a page break (Date … Debit/Credit … Balance).
    return lower.contains('date') &&
        lower.contains('balance') &&
        (lower.contains('debit') || lower.contains('credit'));
  }

  static String _short(String s) =>
      s.length <= 40 ? s : '${s.substring(0, 40)}…';
}
