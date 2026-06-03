import '../models/bank.dart';
import 'classification/document_classifier.dart';
import 'positioned/positioned_pdf_extractor.dart';
import 'statement_parser.dart';
import 'templates/bank_template_registry.dart';
import 'text/parsed_statement.dart';
import 'text/statement_text_extractor.dart';
import 'text/transaction_line_parser.dart';

/// Thrown when the uploaded PDF is not a parseable account statement (an annual
/// report, a form, or unreadable text). The controller maps [message] to a
/// clear user-facing explanation instead of a generic failure.
class UnsupportedDocumentException implements Exception {
  const UnsupportedDocumentException(this.kind, this.message);
  final DocumentKind kind;
  final String message;
  @override
  String toString() => 'UnsupportedDocumentException($kind): $message';
}

/// The real digital-PDF parser used by the app.
///
/// Pipeline: extract positioned words → classify the document (reject anything
/// that isn't a statement) → detect the bank and run its column-aware template
/// → fall back to the generic [TransactionLineParser] when no template matches.
/// Correctness-first: it would rather reject or flag than emit confidently
/// wrong rows.
class TemplatedStatementParser implements StatementParser {
  const TemplatedStatementParser({
    required PositionedPdfExtractor extractor,
    BankTemplateRegistry registry = const BankTemplateRegistry(),
    DocumentClassifier classifier = const DocumentClassifier(),
    TransactionLineParser genericParser = const TransactionLineParser(),
  }) : _extractor = extractor,
       _registry = registry,
       _classifier = classifier,
       _generic = genericParser;

  final PositionedPdfExtractor _extractor;
  final BankTemplateRegistry _registry;
  final DocumentClassifier _classifier;
  final TransactionLineParser _generic;

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

    final doc = await _extractor.extractDocument(
      bytes: bytes,
      filename: input.filename,
      password: input.password,
    );

    final classification = _classifier.classify(doc);
    if (classification.kind != DocumentKind.accountStatement &&
        classification.kind != DocumentKind.unknown) {
      throw UnsupportedDocumentException(
        classification.kind,
        classification.reason ?? 'This file is not an account statement.',
      );
    }

    final template = _registry.detect(doc, hintBankId: input.bank.id);

    // Auto-detect the bank from the statement's own fingerprint: when a template
    // matches, the document's bank wins over the user's manual selection (and the
    // currency follows it).
    var bank = input.bank;
    final notes = <String>[];
    if (template != null) {
      final detected = _bankById(template.bankId);
      if (detected != null) {
        bank = detected;
        if (detected.id != input.bank.id) {
          notes.add('Auto-detected ${detected.name} from the statement.');
        }
      }
    }

    final currency = _currencyByCountry[bank.countryCode] ?? 'AED';
    final ParsedStatement parsed;
    final String version;
    if (template != null) {
      parsed = template.parse(doc, currency: currency);
      version = '${template.bankId}-v1';
    } else {
      // No bank template matched — fall back to the generic balance-reconciling
      // parser over the flattened text.
      parsed = _generic.parse(doc.fullText, currency: currency);
      version = 'generic-v2';
    }

    return ParseResult(
      bank: bank,
      transactions: parsed.transactions,
      parserVersion: version,
      warnings: [...notes, ...parsed.warnings],
    );
  }

  static Bank? _bankById(String id) {
    for (final b in launchBanks) {
      if (b.id == id) return b;
    }
    return null;
  }
}
