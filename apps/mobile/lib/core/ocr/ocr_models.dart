/// Provider-neutral OCR results, so the OCR→document mapping is testable without
/// the ML Kit plugin and so swapping the OCR backend touches nothing downstream.
class OcrWord {
  const OcrWord({
    required this.text,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    this.confidence,
  });

  final String text;
  final double left;
  final double top;
  final double right;
  final double bottom;

  /// The OCR engine's confidence in this word, `[0, 1]`, or null when the
  /// backend doesn't report it. Used only to assess overall scan legibility —
  /// never to fabricate a per-row number.
  final double? confidence;
}

class OcrLine {
  const OcrLine(this.words);
  final List<OcrWord> words;
}

class OcrResult {
  const OcrResult(this.lines);
  final List<OcrLine> lines;

  bool get isEmpty => lines.every((l) => l.words.isEmpty);
}
