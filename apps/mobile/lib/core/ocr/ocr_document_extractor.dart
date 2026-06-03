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

  /// OCRs several page images (a rasterised scanned PDF) into one document,
  /// preserving page order so multi-page templates still reconcile.
  Future<ExtractedDocument> extractMany(List<String> imagePaths) async {
    final results = <OcrResult>[];
    for (final path in imagePaths) {
      results.add(await _recognizer.recognizeFile(path));
    }
    final doc = toDocumentFromPages(results);
    if (doc.lines.isEmpty) throw const OcrFailedException();
    return doc;
  }

  /// Pure mapping from a single-page OCR result to a positioned document.
  static ExtractedDocument toDocument(OcrResult result) =>
      toDocumentFromPages([result]);

  /// Pure mapping from multiple OCR pages. Word boxes become positioned words;
  /// the X positions are what let column detection work, and page order is kept.
  static ExtractedDocument toDocumentFromPages(List<OcrResult> pages) {
    final lines = <PositionedLine>[];
    for (var page = 0; page < pages.length; page++) {
      for (final line in pages[page].lines) {
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
          lines.add(PositionedLine(words: words, pageIndex: page));
        }
      }
    }
    return ExtractedDocument(
      lines: lines,
      numPages: pages.isEmpty ? 1 : pages.length,
      encrypted: false,
    );
  }
}
