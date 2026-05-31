/// Parsing helpers for the money amounts that appear in bank statements.
///
/// Statements are inconsistent: `1,234.56`, `1.234,56` (European), `(50.00)`
/// for negatives, and trailing `CR` / `DR` markers all show up. These helpers
/// normalise that noise into plain doubles so the line parser can stay focused
/// on layout rather than number formatting.
class Money {
  Money._();

  /// Matches a money-looking token. We require either a decimal part or a
  /// thousands separator so that bare integers (reference numbers, dates) are
  /// not mistaken for amounts.
  static final RegExp token = RegExp(
    r'\(?-?\d{1,3}(?:,\d{3})+(?:\.\d{1,2})?\)?(?:\s?(?:CR|DR|Cr|Dr))?'
    r'|\(?-?\d+\.\d{2}\)?(?:\s?(?:CR|DR|Cr|Dr))?',
  );

  /// Parses a single money token (already isolated) into a signed double.
  /// Returns null when the token is not a valid amount.
  ///
  /// Sign rules:
  ///   - Parentheses `(50.00)` and a leading `-` mean negative.
  ///   - A trailing `DR` marker means negative, `CR` means positive.
  static double? parse(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return null;

    var sign = 1.0;

    final upper = s.toUpperCase();
    if (upper.endsWith('CR')) {
      s = s.substring(0, s.length - 2).trim();
    } else if (upper.endsWith('DR')) {
      sign = -1.0;
      s = s.substring(0, s.length - 2).trim();
    }

    if (s.startsWith('(') && s.endsWith(')')) {
      sign = -1.0;
      s = s.substring(1, s.length - 1).trim();
    }
    if (s.startsWith('-')) {
      sign = -1.0;
      s = s.substring(1).trim();
    }

    s = s.replaceAll(',', '');
    final value = double.tryParse(s);
    if (value == null) return null;
    return sign * value;
  }

  /// Returns every money token found in [line], in order of appearance.
  static List<({String raw, double value, int start, int end})> findAll(
    String line,
  ) {
    final out = <({String raw, double value, int start, int end})>[];
    for (final match in token.allMatches(line)) {
      final value = parse(match.group(0)!);
      if (value == null) continue;
      out.add((
        raw: match.group(0)!,
        value: value,
        start: match.start,
        end: match.end,
      ));
    }
    return out;
  }
}
