import '../parsing/positioned/positioned_models.dart';
import 'ocr_models.dart';
import 'ocr_recognizer.dart';

/// Turns an image (photo or scan) into the same [ExtractedDocument] of
/// positioned words that the digital-PDF extractor produces — so the document
/// classifier, bank templates, and balance reconciliation all apply unchanged.
class OcrDocumentExtractor {
  const OcrDocumentExtractor(this._recognizer);

  final OcrRecognizer _recognizer;

  Future<ExtractedDocument> extract(String imagePath) async {
    final result = await _recognizer.recognizeFile(imagePath);
    final doc = toDocument(result);
    if (doc.lines.isEmpty) throw const OcrFailedException();
    return doc;
  }

  /// Pure mapping from OCR output to a positioned document. Word boxes become
  /// positioned words; the X positions are what let column detection work.
  static ExtractedDocument toDocument(OcrResult result) {
    final lines = <PositionedLine>[];
    for (final line in result.lines) {
      final words = <PositionedWord>[];
      for (final w in line.words) {
        if (w.text.trim().isEmpty) continue;
        words.add(
          PositionedWord(
            text: w.text,
            left: w.left,
            top: w.top,
            right: w.right,
            bottom: w.bottom,
          ),
        );
      }
      if (words.isNotEmpty) {
        lines.add(PositionedLine(words: words, pageIndex: 0));
      }
    }
    return ExtractedDocument(lines: lines, numPages: 1, encrypted: false);
  }
}
