import '../positioned/positioned_models.dart';

/// One logical column and the header keywords that identify it.
class ColumnSpec {
  const ColumnSpec({required this.key, required this.keywords});

  /// Canonical key: `date`, `description`, `debit`, `credit`, `balance`.
  final String key;

  /// Lower-case header words that identify this column (e.g. `debit`,
  /// `withdrawal`). Matched against header words with non-letters stripped, so
  /// bilingual headers (Arabic + English) still resolve via the English label.
  final List<String> keywords;
}

/// The horizontal band a column occupies, derived from header word positions.
class ColumnBand {
  const ColumnBand(this.key, this.left, this.right);
  final String key;
  final double left;
  final double right;
  bool contains(double x) => x >= left && x < right;
}

/// Maps words to columns by horizontal position.
///
/// Once a PDF is flattened the Debit/Credit/Balance column structure is lost in
/// plain text — a card number in the description looks just like an amount. By
/// keeping each word's X position and assigning it to the band under the right
/// header, amounts are read from their actual column and stray numbers in the
/// description are ignored. This is what makes separate Debit/Credit columns,
/// reverse-ordered rows, and multi-line descriptions parseable.
class ColumnLayout {
  const ColumnLayout(this.bands, {required this.headerLineIndex});

  final List<ColumnBand> bands;

  /// Index into the document's line list where the header row was found, so the
  /// caller can parse only the rows that follow it.
  final int headerLineIndex;

  String? _bandKeyFor(double x) {
    for (final band in bands) {
      if (band.contains(x)) return band.key;
    }
    return null;
  }

  bool has(String key) => bands.any((b) => b.key == key);

  /// The text of [line] within column [key], left-to-right. Empty if none.
  String cell(PositionedLine line, String key) {
    final words = [...line.words]..sort((a, b) => a.left.compareTo(b.left));
    final out = <String>[];
    for (final w in words) {
      if (_bandKeyFor(w.centerX) == key) out.add(w.text);
    }
    return out.join(' ');
  }

  static String _normalize(String s) =>
      s.toLowerCase().replaceAll(RegExp('[^a-z]'), '');

  /// Finds the header row and builds the column layout from the X centres of
  /// the matched header words. [requireAll] columns must all be present; at
  /// least one of [requireAny] must be present (e.g. debit *or* credit).
  /// Returns null when no qualifying header row exists.
  static ColumnLayout? detect(
    List<PositionedLine> lines,
    List<ColumnSpec> specs, {
    required Set<String> requireAll,
    required Set<String> requireAny,
  }) {
    for (var i = 0; i < lines.length; i++) {
      final anchors = _anchorsForLine(lines[i], specs);
      if (anchors == null) continue;
      if (!requireAll.every(anchors.containsKey)) continue;
      if (requireAny.isNotEmpty && !requireAny.any(anchors.containsKey)) {
        continue;
      }

      final entries = anchors.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      final bands = <ColumnBand>[];
      for (var c = 0; c < entries.length; c++) {
        final left = c == 0
            ? double.negativeInfinity
            : (entries[c - 1].value + entries[c].value) / 2;
        final right = c == entries.length - 1
            ? double.infinity
            : (entries[c].value + entries[c + 1].value) / 2;
        bands.add(ColumnBand(entries[c].key, left, right));
      }
      return ColumnLayout(bands, headerLineIndex: i);
    }
    return null;
  }

  /// Maps each column key to the X centre of its header word on [line], or null
  /// if the line matched no column keywords at all.
  static Map<String, double>? _anchorsForLine(
    PositionedLine line,
    List<ColumnSpec> specs,
  ) {
    final anchors = <String, double>{};
    for (final spec in specs) {
      for (final w in line.words) {
        final t = _normalize(w.text);
        if (t.isEmpty) continue;
        if (spec.keywords.any((k) => t == k)) {
          anchors[spec.key] = w.centerX;
          break;
        }
      }
    }
    return anchors.isEmpty ? null : anchors;
  }
}
