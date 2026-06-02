import '../column/column_mapper.dart';
import '../positioned/positioned_models.dart';
import '../templates/column_statement_parser.dart';
import '../text/money.dart';
import '../text/statement_date.dart';

enum DocumentKind {
  /// A bank account statement — the only kind we parse.
  accountStatement,

  /// A corporate/annual financial report (balance sheet, income statement…).
  annualReport,

  /// A form or letter (e.g. an eStatement enrolment request).
  form,

  /// Text extraction produced gibberish (non-standard font / encoding).
  unreadable,

  /// Couldn't be confidently classified.
  unknown,
}

class DocumentClassification {
  const DocumentClassification(this.kind, {this.reason});
  final DocumentKind kind;
  final String? reason;
}

/// Decides whether a PDF is actually an account statement before we try to
/// parse it. This stops the app from emitting nonsense rows from an annual
/// report or a form, and from silently failing on a broken-font scan — it tells
/// the user *why* instead.
class DocumentClassifier {
  const DocumentClassifier();

  static const _reportMarkers = [
    'statement of financial position',
    'statement of cash flows',
    'income statement',
    'balance sheet',
    'comprehensive income',
    'notes to the',
    'for the year ended',
    'independent auditor',
    'shareholders',
    'annual report',
  ];

  static const _formMarkers = [
    'terms and conditions',
    'i/we',
    'please send',
    'authorized signatory',
    'office use only',
    'attach photocopy',
    'signature(s) of account',
    'account opening',
  ];

  /// Common words that appear in any real English statement; their total
  /// absence from a sizeable document means the text is gibberish.
  static const _readableMarkers = [
    'the ',
    ' and ',
    'account',
    'balance',
    'date',
    'statement',
    'total',
    ' to ',
    ' of ',
  ];

  DocumentClassification classify(ExtractedDocument doc) {
    final text = doc.fullText;
    final lower = text.toLowerCase();

    if (_looksUnreadable(lower)) {
      return const DocumentClassification(
        DocumentKind.unreadable,
        reason:
            "This PDF's text couldn't be read — it may use a non-standard font "
            'or be a scan. OCR support is coming soon.',
      );
    }

    // A located transaction-table header, or several date+amount rows, is a
    // strong and precise statement signal — trust it over keyword markers.
    final hasTable =
        ColumnLayout.detect(
          doc.lines,
          ColumnTableConfig.defaultColumns,
          requireAll: {'date', 'balance'},
          requireAny: {'debit', 'credit'},
        ) !=
        null;
    final txnRows = _dateAmountRowCount(doc);
    if (hasTable || txnRows >= 5) {
      return const DocumentClassification(DocumentKind.accountStatement);
    }

    if (_countMarkers(lower, _reportMarkers) >= 2) {
      return const DocumentClassification(
        DocumentKind.annualReport,
        reason:
            'This looks like a financial/annual report, not an account '
            'statement.',
      );
    }
    if (_countMarkers(lower, _formMarkers) >= 2) {
      return const DocumentClassification(
        DocumentKind.form,
        reason: 'This looks like a form or letter, not an account statement.',
      );
    }

    return const DocumentClassification(DocumentKind.unknown);
  }

  bool _looksUnreadable(String lower) {
    // Enough text to judge, yet not one common English word/marker in it → the
    // text layer is almost certainly mis-encoded (broken font).
    if (lower.replaceAll(RegExp(r'\s'), '').length < 80) return false;
    return !_readableMarkers.any(lower.contains);
  }

  int _dateAmountRowCount(ExtractedDocument doc) {
    var count = 0;
    for (final line in doc.lines) {
      final t = line.text;
      if (StatementDate.leading(t) != null && Money.findAll(t).isNotEmpty) {
        count++;
      }
    }
    return count;
  }

  int _countMarkers(String lower, List<String> markers) =>
      markers.where(lower.contains).length;
}
