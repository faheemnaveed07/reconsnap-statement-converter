import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'ocr_models.dart';
import 'ocr_recognizer.dart';

/// On-device OCR via Google ML Kit (no upload — preserves the privacy posture).
///
/// ML Kit returns blocks → lines → elements, each with a bounding box. We map
/// each element to an [OcrWord] so the downstream column parser sees real word
/// positions. Device-only (the plugin has no host implementation), so this
/// class is exercised on a device, not in unit tests; the pure mapping lives in
/// [OcrDocumentExtractor.toDocument] and is tested there.
class MlKitOcrRecognizer implements OcrRecognizer {
  MlKitOcrRecognizer([TextRecognizer? recognizer])
    : _recognizer =
          recognizer ?? TextRecognizer(script: TextRecognitionScript.latin);

  final TextRecognizer _recognizer;

  @override
  Future<OcrResult> recognizeFile(String imagePath) async {
    final recognized = await _recognizer.processImage(
      InputImage.fromFilePath(imagePath),
    );

    final lines = <OcrLine>[];
    for (final block in recognized.blocks) {
      for (final line in block.lines) {
        final words = <OcrWord>[];
        for (final element in line.elements) {
          final box = element.boundingBox;
          words.add(
            OcrWord(
              text: element.text,
              left: box.left,
              top: box.top,
              right: box.right,
              bottom: box.bottom,
              confidence: element.confidence,
            ),
          );
        }
        if (words.isNotEmpty) lines.add(OcrLine(words));
      }
    }
    return OcrResult(lines);
  }

  @override
  Future<void> dispose() => _recognizer.close();
}
