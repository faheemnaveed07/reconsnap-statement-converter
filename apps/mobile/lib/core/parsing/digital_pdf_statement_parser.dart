import 'statement_parser.dart';
import 'text/statement_text_extractor.dart';
import 'text/transaction_line_parser.dart';

/// Real parser for digital (text-layer) PDFs.
///
/// Composes two pieces that are each tested in isolation:
///   1. a [StatementTextExtractor] that turns PDF bytes into clean text, and
///   2. a [TransactionLineParser] that turns that text into reconciled rows.
///
/// This class is deliberately thin — it just wires them together and maps the
/// statement's country to a currency. Extraction/transport failures surface as
/// the typed exceptions from [StatementTextExtractor] so the controller/UI can
/// react (prompt for a password, explain OCR is unsupported, etc.).
class DigitalPdfStatementParser implements StatementParser {
  const DigitalPdfStatementParser({
    required StatementTextExtractor extractor,
    TransactionLineParser lineParser = const TransactionLineParser(),
  }) : _extractor = extractor,
       _lineParser = lineParser;

  final StatementTextExtractor _extractor;
  final TransactionLineParser _lineParser;

  static const _currencyByCountry = {
    'AE': 'AED',
    'SA': 'SAR',
    'QA': 'QAR',
    'KW': 'KWD',
    'BH': 'BHD',
    'OM': 'OMR',
    'GB': 'GBP',
    'CA': 'CAD',
    'US': 'USD',
  };

  @override
  Future<ParseResult> parse(ParseInput input) async {
    final bytes = input.bytes;
    if (bytes == null) {
      throw const ExtractionException('No file data was provided.');
    }

    final extracted = await _extractor.extract(
      bytes: bytes,
      filename: input.filename,
      password: input.password,
    );

    final currency = _currencyByCountry[input.bank.countryCode] ?? 'AED';
    final parsed = _lineParser.parse(extracted.fullText, currency: currency);

    return ParseResult(
      bank: input.bank,
      transactions: parsed.transactions,
      parserVersion: 'digital-v1',
      warnings: parsed.warnings,
    );
  }
}
