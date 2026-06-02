import 'dart:math' as math;

/// A single word and its bounding box on the page.
///
/// Coordinates are in PDF points. The exact units don't matter to the parser —
/// only the *relative* horizontal position of words matters, because that is
/// how columns (Date / Description / Debit / Credit / Balance) are recovered
/// after a PDF is flattened, where a plain text dump loses column structure.
class PositionedWord {
  const PositionedWord({
    required this.text,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final String text;
  final double left;
  final double top;
  final double right;
  final double bottom;

  double get centerX => (left + right) / 2;
  double get centerY => (top + bottom) / 2;
}

/// A line of words that share roughly the same vertical position (one visual
/// row of the page).
class PositionedLine {
  PositionedLine({required this.words, required this.pageIndex})
    : assert(words.isNotEmpty);

  final List<PositionedWord> words;
  final int pageIndex;

  double get top => words.map((w) => w.top).reduce(math.min);
  double get bottom => words.map((w) => w.bottom).reduce(math.max);

  /// Words joined left-to-right into a single string.
  String get text {
    final ordered = [...words]..sort((a, b) => a.left.compareTo(b.left));
    return ordered.map((w) => w.text).join(' ');
  }
}

/// A whole extracted PDF: positioned lines in reading order across all pages,
/// plus the metadata the rest of the pipeline already depends on.
///
/// Carrying both the positioned lines *and* a flat [fullText] lets a bank
/// template parse by column position while the generic line parser (and the
/// document classifier) can still work off plain text.
class ExtractedDocument {
  const ExtractedDocument({
    required this.lines,
    required this.numPages,
    required this.encrypted,
  });

  final List<PositionedLine> lines;
  final int numPages;
  final bool encrypted;

  String get fullText => lines.map((l) => l.text).join('\n');
}
