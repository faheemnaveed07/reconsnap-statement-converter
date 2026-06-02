import 'dart:convert';

import 'package:http/http.dart' as http;

import 'text/statement_text_extractor.dart';

/// [StatementTextExtractor] backed by the ReconSnap extraction API.
///
/// Posts the PDF to `POST {baseUrl}/extract` as multipart form data and maps
/// the response (and error status codes) onto the typed result/exceptions the
/// rest of the app understands. The [http.Client] is injectable so the
/// status-code mapping can be unit-tested without a network or server.
class RemotePdfTextExtractor implements StatementTextExtractor {
  RemotePdfTextExtractor({
    required this.baseUrl,
    http.Client? client,
    this.timeout = const Duration(seconds: 45),
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final Duration timeout;
  final http.Client _client;

  @override
  Future<ExtractedText> extract({
    required List<int> bytes,
    required String filename,
    String? password,
  }) async {
    final uri = Uri.parse('$baseUrl/extract');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: filename),
      );
    if (password != null && password.isNotEmpty) {
      request.fields['password'] = password;
    }

    final http.Response response;
    try {
      final streamed = await _client.send(request).timeout(timeout);
      response = await http.Response.fromStream(streamed);
    } catch (error) {
      throw ExtractionException('Could not reach the conversion service.');
    }

    switch (response.statusCode) {
      case 200:
        return _parseSuccess(response.body);
      case 422:
        throw PasswordRequiredException(_detail(response.body));
      case 413:
        throw ExtractionException('File is too large (max 25 MB).');
      default:
        throw ExtractionException(
          _detail(
            response.body,
            fallback: 'Conversion failed (${response.statusCode}).',
          ),
        );
    }
  }

  ExtractedText _parseSuccess(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final extracted = ExtractedText(
      fullText: (json['full_text'] as String?) ?? '',
      numPages: (json['num_pages'] as num?)?.toInt() ?? 0,
      encrypted: (json['encrypted'] as bool?) ?? false,
      needsOcr: (json['needs_ocr'] as bool?) ?? false,
    );
    if (extracted.needsOcr) {
      throw const OcrNotSupportedException();
    }
    return extracted;
  }

  String _detail(String body, {String fallback = 'Password required.'}) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final detail = json['detail'];
      if (detail is String && detail.isNotEmpty) return detail;
    } catch (_) {
      // Non-JSON body; fall through to the default.
    }
    return fallback;
  }

  void dispose() => _client.close();
}
