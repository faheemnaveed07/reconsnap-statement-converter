import 'ocr_models.dart';

/// Recognises text (with word bounding boxes) from an image file.
///
/// The bounding boxes are the whole point: they let an OCR'd scan flow through
/// the same column-aware parsing pipeline as a digital PDF. `MlKitOcrRecognizer`
/// implements this on-device; a fake implements it in tests.
abstract interface class OcrRecognizer {
  Future<OcrResult> recognizeFile(String imagePath);
  Future<void> dispose();
}

/// Thrown when an image yields no usable text (blurry photo, blank page).
class OcrFailedException implements Exception {
  const OcrFailedException([
    this.message =
        "Couldn't read text from this image. Try a clearer, well-lit photo of "
        'the full statement.',
  ]);
  final String message;
  @override
  String toString() => 'OcrFailedException: $message';
}
