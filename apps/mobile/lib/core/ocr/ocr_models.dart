/// Provider-neutral OCR results, so the OCR→document mapping is testable without
/// the ML Kit plugin and so swapping the OCR backend touches nothing downstream.
class OcrWord {
  const OcrWord({
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
