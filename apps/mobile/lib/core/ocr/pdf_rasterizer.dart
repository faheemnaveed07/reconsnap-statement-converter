import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

/// Renders the pages of a (scanned, no-text-layer) PDF to image files, so a
/// scanned PDF can enter the same on-device OCR pipeline as a photo.
abstract interface class PdfRasterizer {
  /// Returns temp image-file paths, one per page (capped). Empty if the PDF
  /// could not be rendered.
  Future<List<String>> rasterizeToImageFiles(
    List<int> pdfBytes, {
    String? password,
    int maxPages = 15,
    double dpi = 200,
  });
}

/// On-device rasteriser via the `printing` plugin (platform PDF renderers).
/// Device-only; the merge/parse logic it feeds is unit-tested separately.
class PrintingPdfRasterizer implements PdfRasterizer {
  const PrintingPdfRasterizer();

  @override
  Future<List<String>> rasterizeToImageFiles(
    List<int> pdfBytes, {
    String? password,
    int maxPages = 15,
    double dpi = 200,
  }) async {
    final data = _decryptIfNeeded(pdfBytes, password);
    final dir = await getTemporaryDirectory();
    final paths = <String>[];

    var i = 0;
    await for (final page in Printing.raster(data, dpi: dpi)) {
      if (i >= maxPages) break;
      final png = await page.toPng();
      final file = File('${dir.path}/scan_page_$i.png');
      await file.writeAsBytes(png);
      paths.add(file.path);
      i++;
    }
    return paths;
  }

  /// The platform renderers can't open an encrypted PDF, but we already have the
  /// password — strip the encryption in memory first (Syncfusion is already a
  /// dependency).
  static Uint8List _decryptIfNeeded(List<int> bytes, String? password) {
    final data = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    if (password == null || password.isEmpty) return data;
    try {
      final doc = sf.PdfDocument(inputBytes: data, password: password);
      doc.security.userPassword = '';
      doc.security.ownerPassword = '';
      final decrypted = Uint8List.fromList(doc.saveSync());
      doc.dispose();
      return decrypted;
    } catch (_) {
      return data;
    }
  }
}
