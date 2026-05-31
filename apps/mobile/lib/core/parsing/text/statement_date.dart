/// Date detection for statement lines.
///
/// Bank statements use a handful of common formats. We detect a leading date
/// token on a line and normalise it to a [DateTime]. The day/month order is
/// configurable because `03/04/2026` is ambiguous (UK vs US); the parser
/// defaults to day-first, which matches the UAE/GCC/UK launch markets.
class StatementDate {
  StatementDate._();

  static const _months = {
    'jan': 1,
    'feb': 2,
    'mar': 3,
    'apr': 4,
    'may': 5,
    'jun': 6,
    'jul': 7,
    'aug': 8,
    'sep': 9,
    'sept': 9,
    'oct': 10,
    'nov': 11,
    'dec': 12,
  };

  /// Numeric date like `03/04/2026`, `03-04-26`, `2026/04/03`.
  static final RegExp _numeric = RegExp(
    r'^(\d{1,4})[/\-.](\d{1,2})[/\-.](\d{2,4})',
  );

  /// Textual month like `03 Apr 2026` or `Apr 3, 2026`.
  static final RegExp _textual = RegExp(
    r'^(\d{1,2})\s+([A-Za-z]{3,4})\.?\s+(\d{2,4})'
    r'|^([A-Za-z]{3,4})\.?\s+(\d{1,2}),?\s+(\d{2,4})',
    caseSensitive: false,
  );

  /// Attempts to read a date from the start of [line]. Returns the parsed date
  /// and the number of characters consumed, or null if no leading date.
  static ({DateTime date, int length})? leading(
    String line, {
    bool dayFirst = true,
  }) {
    final trimmed = line.trimLeft();
    final offset = line.length - trimmed.length;

    final textual = _textual.firstMatch(trimmed);
    if (textual != null) {
      final date = _fromTextual(textual);
      if (date != null) {
        return (date: date, length: offset + textual.end);
      }
    }

    final numeric = _numeric.firstMatch(trimmed);
    if (numeric != null) {
      final date = _fromNumeric(numeric, dayFirst: dayFirst);
      if (date != null) {
        return (date: date, length: offset + numeric.end);
      }
    }

    return null;
  }

  static DateTime? _fromTextual(RegExpMatch m) {
    // Either group set 1-3 (day month year) or 4-6 (month day year) matched.
    if (m.group(1) != null) {
      final day = int.parse(m.group(1)!);
      final month = _months[m.group(2)!.toLowerCase()];
      final year = _normaliseYear(int.parse(m.group(3)!));
      if (month == null) return null;
      return _build(year, month, day);
    }
    final month = _months[m.group(4)!.toLowerCase()];
    final day = int.parse(m.group(5)!);
    final year = _normaliseYear(int.parse(m.group(6)!));
    if (month == null) return null;
    return _build(year, month, day);
  }

  static DateTime? _fromNumeric(RegExpMatch m, {required bool dayFirst}) {
    final a = int.parse(m.group(1)!);
    final b = int.parse(m.group(2)!);
    final c = int.parse(m.group(3)!);

    // `2026/04/03` => year first.
    if (m.group(1)!.length == 4) {
      return _build(_normaliseYear(a), b, c);
    }

    final year = _normaliseYear(c);
    final first = a;
    final second = b;
    // If one component is clearly > 12 it must be the day, which disambiguates.
    if (first > 12 && second <= 12) return _build(year, second, first);
    if (second > 12 && first <= 12) return _build(year, first, second);
    return dayFirst
        ? _build(year, second, first)
        : _build(year, first, second);
  }

  static int _normaliseYear(int year) {
    if (year >= 100) return year;
    // Two-digit year: assume 2000s for <= 79, else 1900s.
    return year <= 79 ? 2000 + year : 1900 + year;
  }

  static DateTime? _build(int year, int month, int day) {
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    final date = DateTime(year, month, day);
    // Reject overflow (e.g. 31 Feb -> 3 Mar).
    if (date.month != month || date.day != day) return null;
    return date;
  }
}
