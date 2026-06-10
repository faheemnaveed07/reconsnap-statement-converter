import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/categorization/transaction_categorizer.dart';
import '../../../core/diagnostics/conversion_outcome.dart';
import '../../../core/diagnostics/diagnostics_store.dart';
import '../../../core/models/bank.dart';
import '../../../core/models/conversion_job.dart';
import '../../../core/models/statement_transaction.dart';
import '../../../core/ocr/ml_kit_ocr_recognizer.dart';
import '../../../core/ocr/ocr_document_extractor.dart';
import '../../../core/ocr/ocr_legibility.dart';
import '../../../core/ocr/ocr_recognizer.dart';
import '../../../core/ocr/pdf_rasterizer.dart';
import '../../../core/parsing/classification/document_classifier.dart';
import '../../../core/parsing/mock_statement_parser.dart';
import '../../../core/parsing/on_device_pdf_text_extractor.dart';
import '../../../core/parsing/positioned/positioned_models.dart';
import '../../../core/parsing/positioned/positioned_pdf_extractor.dart';
import '../../../core/parsing/statement_parser.dart';
import '../../../core/parsing/templated_statement_parser.dart';
import '../../../core/parsing/text/statement_text_extractor.dart';
import '../../../core/parsing/text/transaction_line_parser.dart';
import '../../../core/services/conversion_history_store.dart';
import '../../../core/services/conversion_preference_store.dart';
import '../../../core/services/review_prompter.dart';
import '../../../core/services/statement_exporter.dart';
import '../../../core/validation/validation_engine.dart';
import '../../billing/presentation/entitlements_controller.dart';

final validationEngineProvider = Provider((ref) => const ValidationEngine());

/// One entry point for all export formats (CSV, Excel, OFX, QuickBooks/Xero).
final statementExporterProvider = Provider((ref) => StatementExporter());

/// Asks for an app-store review after a few successful conversions.
final reviewPrompterProvider = Provider((ref) => ReviewPrompter());

/// Privacy-safe log of conversion outcomes (no statement content).
final diagnosticsStoreProvider = Provider((ref) => DiagnosticsStore());

/// Rule-based accounting categorizer applied to each parsed transaction.
final transactionCategorizerProvider = Provider(
  (ref) => const TransactionCategorizer(),
);

/// Persists conversion history across app restarts.
final conversionHistoryStoreProvider = Provider(
  (ref) => ConversionHistoryStore(),
);

/// Persists parser/date-format preferences across restarts.
final conversionPreferenceStoreProvider = Provider(
  (ref) => ConversionPreferenceStore(),
);

/// The user's parsing preferences (default bank, statement date format). Loaded
/// on first read; updated from Account. The parser provider watches this so a
/// date-format change takes effect on the next conversion.
final conversionPreferencesProvider =
    NotifierProvider<ConversionPreferencesController, ConversionPreferences>(
      ConversionPreferencesController.new,
    );

class ConversionPreferencesController extends Notifier<ConversionPreferences> {
  @override
  ConversionPreferences build() {
    _restore();
    return const ConversionPreferences();
  }

  Future<void> _restore() async {
    state = await ref.read(conversionPreferenceStoreProvider).load();
  }

  void setDayFirst(bool dayFirst) {
    state = state.copyWith(dayFirst: dayFirst);
    ref.read(conversionPreferenceStoreProvider).save(state);
  }

  void setDefaultBank(String? bankId) {
    state = bankId == null
        ? state.copyWith(clearBank: true)
        : state.copyWith(defaultBankId: bankId);
    ref.read(conversionPreferenceStoreProvider).save(state);
  }
}

/// Mock parser used by the "Run demo conversion" affordance.
final mockStatementParserProvider = Provider<StatementParser>(
  (ref) => const MockStatementParser(),
);

/// On-device extractor — the default. Provides positioned words for the
/// column-aware bank templates; needs no server and never sends the PDF off the
/// device.
final positionedPdfExtractorProvider = Provider<PositionedPdfExtractor>(
  (ref) => const OnDevicePdfTextExtractor(),
);

/// The orchestrating parser. Exposed concretely so the OCR path can reuse its
/// `parseExtracted` core on an image-derived document. Rebuilds when the
/// date-format preference changes, so both the bank templates and the generic
/// fallback honour day-first vs month-first.
final templatedStatementParserProvider = Provider<TemplatedStatementParser>((
  ref,
) {
  final dayFirst = ref.watch(
    conversionPreferencesProvider.select((p) => p.dayFirst),
  );
  return TemplatedStatementParser(
    extractor: ref.watch(positionedPdfExtractorProvider),
    dayFirst: dayFirst,
    genericParser: TransactionLineParser(dayFirst: dayFirst),
  );
});

/// Real parser for digital PDFs: document-type gate → bank-specific column
/// template (Emirates NBD today) → generic balance-reconciling fallback.
final digitalStatementParserProvider = Provider<StatementParser>(
  (ref) => ref.watch(templatedStatementParserProvider),
);

/// On-device OCR (ML Kit) for photos and scans — no upload.
final ocrRecognizerProvider = Provider<OcrRecognizer>((ref) {
  final recognizer = MlKitOcrRecognizer();
  ref.onDispose(recognizer.dispose);
  return recognizer;
});

final ocrDocumentExtractorProvider = Provider(
  (ref) => OcrDocumentExtractor(ref.watch(ocrRecognizerProvider)),
);

/// Renders scanned (no-text-layer) PDFs to images so they can enter OCR.
final pdfRasterizerProvider = Provider<PdfRasterizer>(
  (ref) => const PrintingPdfRasterizer(),
);

final conversionControllerProvider =
    NotifierProvider<ConversionController, ConversionState>(
      ConversionController.new,
    );

class ConversionState {
  const ConversionState({
    required this.selectedBank,
    required this.status,
    required this.filename,
    required this.transactions,
    required this.activeJob,
    required this.history,
    this.warnings = const [],
    this.pendingBytes,
    this.errorMessage,
    this.processingMessage,
    this.failureCause,
    this.scanLegibility,
  });

  factory ConversionState.initial() {
    return ConversionState(
      selectedBank: launchBanks[0],
      status: ConversionStatus.idle,
      filename: null,
      transactions: const [],
      activeJob: null,
      history: const [],
    );
  }

  final Bank selectedBank;
  final ConversionStatus status;
  final String? filename;
  final List<StatementTransaction> transactions;
  final ConversionJob? activeJob;
  final List<ConversionJob> history;
  final List<String> warnings;

  /// Bytes of the file currently being processed, kept so a password can be
  /// supplied and the conversion retried without re-picking the file.
  final List<int>? pendingBytes;
  final String? errorMessage;

  /// The real, current pipeline stage shown while processing (e.g. "Reading
  /// text from your scan"). Updated at actual stage boundaries — never a
  /// fabricated checklist. Null when not processing.
  final String? processingMessage;

  /// The typed cause of a failure, so the UI can offer a *next action tied to
  /// the cause* instead of a single generic "try another file". Cleared on each
  /// new attempt (mirrors [errorMessage]).
  final ConversionOutcomeType? failureCause;

  /// How legible the OCR'd scan was, when this conversion came from a photo/scan.
  /// Surfaced as an honest trust signal on the Result; null for digital PDFs or
  /// when there was no basis to judge. Cleared on each new attempt.
  final ScanLegibility? scanLegibility;

  ConversionState copyWith({
    Bank? selectedBank,
    ConversionStatus? status,
    String? filename,
    List<StatementTransaction>? transactions,
    ConversionJob? activeJob,
    List<ConversionJob>? history,
    List<String>? warnings,
    List<int>? pendingBytes,
    String? errorMessage,
    String? processingMessage,
    ConversionOutcomeType? failureCause,
    ScanLegibility? scanLegibility,
  }) {
    return ConversionState(
      selectedBank: selectedBank ?? this.selectedBank,
      status: status ?? this.status,
      filename: filename ?? this.filename,
      transactions: transactions ?? this.transactions,
      activeJob: activeJob ?? this.activeJob,
      history: history ?? this.history,
      warnings: warnings ?? this.warnings,
      pendingBytes: pendingBytes ?? this.pendingBytes,
      errorMessage: errorMessage,
      processingMessage: processingMessage ?? this.processingMessage,
      failureCause: failureCause,
      scanLegibility: scanLegibility,
    );
  }
}

class ConversionController extends Notifier<ConversionState> {
  static const _uuid = Uuid();

  // An OCR'd document held back at the low-legibility gate, so "Convert anyway"
  // can parse it without re-running OCR.
  ExtractedDocument? _pendingOcrDoc;
  String? _pendingOcrFilename;
  String _pendingOcrVersionSuffix = '+ocr';
  ScanLegibility? _pendingLegibility;

  @override
  ConversionState build() {
    _restoreHistory();
    _restoreDefaultBank();
    return ConversionState.initial();
  }

  /// Pre-selects the user's preferred default bank, if set, so the confirm step
  /// on a new conversion defaults to it. Best-effort and async.
  Future<void> _restoreDefaultBank() async {
    final prefs = await ref.read(conversionPreferenceStoreProvider).load();
    final id = prefs.defaultBankId;
    if (id == null) return;
    for (final bank in launchBanks) {
      if (bank.id == id) {
        state = state.copyWith(selectedBank: bank);
        return;
      }
    }
  }

  /// Loads persisted history after construction and folds it into state. Runs
  /// async so app startup is never blocked on disk I/O.
  Future<void> _restoreHistory() async {
    final saved = await ref.read(conversionHistoryStoreProvider).load();
    if (saved.isEmpty) return;
    // Keep anything converted while the load was in flight ahead of the
    // restored entries.
    state = state.copyWith(history: [...state.history, ...saved]);
  }

  void _persistHistory() {
    ref.read(conversionHistoryStoreProvider).save(state.history);
  }

  void selectBank(Bank bank) {
    state = state.copyWith(selectedBank: bank);
  }

  /// Re-opens a past conversion (e.g. tapped in History) as the active job so
  /// the preview/validation/export screens show it.
  void openJob(ConversionJob job) {
    state = state.copyWith(
      selectedBank: job.bank,
      status: ConversionStatus.ready,
      filename: job.filename,
      transactions: job.transactions,
      warnings: const [],
      activeJob: job,
      errorMessage: null,
    );
  }

  /// Runs a real conversion against the extraction API + digital parser.
  /// Handles password-protected and scanned PDFs as distinct, recoverable
  /// states rather than generic failures.
  Future<void> startConversion({
    required List<int> bytes,
    required String filename,
    String? password,
  }) async {
    state = state.copyWith(
      status: ConversionStatus.processing,
      filename: filename,
      pendingBytes: bytes,
      errorMessage: null,
      processingMessage: 'Reading and reconciling your statement',
    );

    final parser = ref.read(digitalStatementParserProvider);
    final validator = ref.read(validationEngineProvider);

    try {
      final result = await parser.parse(
        ParseInput(
          filename: filename,
          bank: state.selectedBank,
          bytes: bytes,
          password: password,
        ),
      );

      if (result.transactions.isEmpty) {
        _fail(
          ConversionOutcomeType.noTransactions,
          'No transactions were detected. The layout may not be supported yet.',
        );
        return;
      }

      _completeWith(result, validator, filename);
      _record(
        ConversionOutcomeType.success,
        parserVersion: result.parserVersion,
        count: result.transactions.length,
        reconciled: state.activeJob?.validationReport.isPassed,
      );
      // A successful real conversion spends one credit (the demo is free).
      ref.read(entitlementsProvider.notifier).consumeOne();
    } on PasswordRequiredException {
      _record(ConversionOutcomeType.needsPassword);
      state = state.copyWith(
        status: ConversionStatus.needsPassword,
        errorMessage: null,
      );
    } on UnsupportedDocumentException catch (e) {
      // Not an account statement (annual report, form, unreadable text) — tell
      // the user why instead of showing a generic failure.
      _fail(
        e.kind == DocumentKind.unreadable
            ? ConversionOutcomeType.unreadable
            : ConversionOutcomeType.notAStatement,
        e.message,
      );
    } on OcrNotSupportedException {
      // Scanned PDF (no text layer) — rasterise its pages and run OCR through
      // the same pipeline instead of giving up.
      await _convertScannedPdf(bytes, filename, password);
    } on ExtractionException catch (e) {
      _fail(ConversionOutcomeType.failed, e.message);
    } catch (_) {
      _fail(
        ConversionOutcomeType.failed,
        'Conversion failed. Please try another file.',
      );
    }
  }

  /// Scanned-PDF path: rasterise the pages to images, OCR them, then run the
  /// same classify → template → reconcile pipeline. Called when the digital
  /// extractor finds no text layer.
  Future<void> _convertScannedPdf(
    List<int> bytes,
    String filename,
    String? password,
  ) async {
    final rasterizer = ref.read(pdfRasterizerProvider);
    final ocr = ref.read(ocrDocumentExtractorProvider);
    final parser = ref.read(templatedStatementParserProvider);
    final validator = ref.read(validationEngineProvider);

    try {
      state = state.copyWith(processingMessage: 'Rendering the scanned pages');
      final pages = await rasterizer.rasterizeToImageFiles(
        bytes,
        password: password,
      );
      if (pages.isEmpty) {
        _fail(
          ConversionOutcomeType.needsOcr,
          "Couldn't read this scanned PDF. Try a clearer scan or a digital "
          'PDF export.',
        );
        return;
      }

      state = state.copyWith(
        processingMessage: 'Reading text from the scan (OCR)',
      );
      final extraction = await ocr.extractMany(pages);

      // Catch a poor scan before parsing — let the user retake, upload the PDF,
      // or convert anyway, rather than failing late with a generic message.
      if (extraction.legibility.isPoor) {
        _gateLowLegibility(extraction, filename, '+ocrpdf');
        return;
      }

      state = state.copyWith(processingMessage: 'Reconciling transactions');
      final result = parser.parseExtracted(
        extraction.document,
        state.selectedBank,
      );

      if (result.transactions.isEmpty) {
        _fail(
          ConversionOutcomeType.noTransactions,
          'No transactions were detected in this scanned statement.',
        );
        return;
      }

      _completeWith(result, validator, filename);
      state = state.copyWith(scanLegibility: extraction.legibility.level);
      _record(
        ConversionOutcomeType.success,
        parserVersion: '${result.parserVersion}+ocrpdf',
        count: result.transactions.length,
        reconciled: state.activeJob?.validationReport.isPassed,
      );
      ref.read(entitlementsProvider.notifier).consumeOne();
    } on UnsupportedDocumentException catch (e) {
      _fail(
        e.kind == DocumentKind.unreadable
            ? ConversionOutcomeType.unreadable
            : ConversionOutcomeType.notAStatement,
        e.message,
      );
    } catch (_) {
      _fail(
        ConversionOutcomeType.failed,
        "Couldn't read this scanned PDF. Try a clearer scan or a digital "
        'PDF export.',
      );
    }
  }

  /// Holds a poorly-legible OCR result at a recoverable decision point instead
  /// of parsing it blind. The user can retake, upload the PDF, or convert
  /// anyway (which parses the already-OCR'd document, no re-scan).
  void _gateLowLegibility(
    OcrExtraction extraction,
    String filename,
    String versionSuffix,
  ) {
    _pendingOcrDoc = extraction.document;
    _pendingOcrFilename = filename;
    _pendingOcrVersionSuffix = versionSuffix;
    _pendingLegibility = extraction.legibility.level;
    state = state.copyWith(
      status: ConversionStatus.lowLegibility,
      scanLegibility: extraction.legibility.level,
      errorMessage: null,
    );
  }

  /// Proceeds with a conversion the user accepted despite a poor scan. Parses
  /// the document captured at the gate — no second OCR pass.
  Future<void> continueWithLowLegibility() async {
    final doc = _pendingOcrDoc;
    final filename = _pendingOcrFilename;
    if (doc == null || filename == null) return;
    final validator = ref.read(validationEngineProvider);
    state = state.copyWith(
      status: ConversionStatus.processing,
      processingMessage: 'Reconciling transactions',
    );
    try {
      final parser = ref.read(templatedStatementParserProvider);
      final result = parser.parseExtracted(doc, state.selectedBank);
      if (result.transactions.isEmpty) {
        _fail(
          ConversionOutcomeType.noTransactions,
          'No transactions were detected in this scan. Try a clearer photo, or '
          'upload the PDF instead.',
        );
        return;
      }
      _completeWith(result, validator, filename);
      state = state.copyWith(scanLegibility: _pendingLegibility);
      _record(
        ConversionOutcomeType.success,
        parserVersion: '${result.parserVersion}$_pendingOcrVersionSuffix',
        count: result.transactions.length,
        reconciled: state.activeJob?.validationReport.isPassed,
      );
      ref.read(entitlementsProvider.notifier).consumeOne();
    } on UnsupportedDocumentException catch (e) {
      _fail(
        e.kind == DocumentKind.unreadable
            ? ConversionOutcomeType.unreadable
            : ConversionOutcomeType.notAStatement,
        e.message,
      );
    } catch (_) {
      _fail(
        ConversionOutcomeType.failed,
        'Conversion failed. Please try another image.',
      );
    }
  }

  /// Moves to a failed state with a typed [cause] so the UI can offer a
  /// recoverable next action tied to *why* it failed, not a generic dead end.
  void _fail(ConversionOutcomeType cause, String message) {
    _record(cause);
    state = state.copyWith(
      status: ConversionStatus.failed,
      errorMessage: message,
      failureCause: cause,
    );
  }

  /// Logs a privacy-safe outcome (no statement content) for the failure-coverage
  /// flywheel. Fire-and-forget; never blocks or breaks the conversion.
  void _record(
    ConversionOutcomeType type, {
    String? parserVersion,
    int count = 0,
    bool? reconciled,
  }) {
    ref
        .read(diagnosticsStoreProvider)
        .record(
          ConversionOutcome(
            at: DateTime.now(),
            type: type,
            bankId: state.selectedBank.id,
            parserVersion: parserVersion,
            transactionCount: count,
            reconciled: reconciled,
          ),
        );
  }

  /// Retries the in-flight conversion with a user-supplied password.
  Future<void> submitPassword(String password) async {
    final bytes = state.pendingBytes;
    final filename = state.filename;
    if (bytes == null || filename == null) return;
    await startConversion(bytes: bytes, filename: filename, password: password);
  }

  /// Converts a photo or scanned image via on-device OCR, then runs the exact
  /// same classify → template → reconcile pipeline as a digital PDF.
  Future<void> startImageConversion({
    required String imagePath,
    required String filename,
  }) async {
    state = state.copyWith(
      status: ConversionStatus.processing,
      filename: filename,
      errorMessage: null,
      processingMessage: 'Reading text from your photo (OCR)',
    );

    final extractor = ref.read(ocrDocumentExtractorProvider);
    final parser = ref.read(templatedStatementParserProvider);
    final validator = ref.read(validationEngineProvider);

    try {
      final extraction = await extractor.extract(imagePath);

      // Catch a poor scan before parsing — let the user retake, upload the PDF,
      // or convert anyway, rather than failing late with a generic message.
      if (extraction.legibility.isPoor) {
        _gateLowLegibility(extraction, filename, '+ocr');
        return;
      }

      state = state.copyWith(processingMessage: 'Reconciling transactions');
      final result = parser.parseExtracted(
        extraction.document,
        state.selectedBank,
      );

      if (result.transactions.isEmpty) {
        _fail(
          ConversionOutcomeType.noTransactions,
          'No transactions were detected. Try a clearer photo of the full '
          'statement, or upload the PDF instead.',
        );
        return;
      }

      _completeWith(result, validator, filename);
      state = state.copyWith(scanLegibility: extraction.legibility.level);
      _record(
        ConversionOutcomeType.success,
        parserVersion: '${result.parserVersion}+ocr',
        count: result.transactions.length,
        reconciled: state.activeJob?.validationReport.isPassed,
      );
      ref.read(entitlementsProvider.notifier).consumeOne();
    } on OcrFailedException catch (e) {
      _fail(ConversionOutcomeType.unreadable, e.message);
    } on UnsupportedDocumentException catch (e) {
      _fail(
        e.kind == DocumentKind.unreadable
            ? ConversionOutcomeType.unreadable
            : ConversionOutcomeType.notAStatement,
        e.message,
      );
    } catch (_) {
      _fail(
        ConversionOutcomeType.failed,
        'Conversion failed. Please try another image.',
      );
    }
  }

  Future<void> startMockConversion({String? filename}) async {
    final parser = ref.read(mockStatementParserProvider);
    final validator = ref.read(validationEngineProvider);
    final selectedFilename = filename ?? 'emirates-nbd-may-2026.pdf';

    state = state.copyWith(
      status: ConversionStatus.processing,
      filename: selectedFilename,
      errorMessage: null,
      processingMessage: 'Preparing a sample result',
    );

    try {
      final result = await parser.parse(
        ParseInput(filename: selectedFilename, bank: state.selectedBank),
      );
      _completeWith(result, validator, selectedFilename);
    } catch (_) {
      _fail(
        ConversionOutcomeType.failed,
        'Conversion failed. Please try another file.',
      );
    }
  }

  void _completeWith(
    ParseResult result,
    ValidationEngine validator,
    String filename,
  ) {
    final categorizer = ref.read(transactionCategorizerProvider);
    final transactions = [
      for (final t in result.transactions)
        t.category != null
            ? t
            : t.copyWith(category: categorizer.categorize(t)),
    ];

    final report = validator.validate(transactions);
    final job = ConversionJob(
      id: _uuid.v4(),
      filename: filename,
      bank: result.bank,
      transactions: transactions,
      validationReport: report,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      status: ConversionStatus.ready,
      transactions: transactions,
      warnings: result.warnings,
      activeJob: job,
      history: [job, ...state.history],
    );
    _persistHistory();
    // Only ask for a review after a genuinely good outcome — a fully reconciled
    // result with nothing flagged. Never prompt on a flagged or off-by result;
    // the moment must be one the user is happy with.
    final flagged = transactions.where((t) => t.confidence < 0.80).isNotEmpty;
    if (report.isPassed && !flagged) {
      ref.read(reviewPrompterProvider).recordPositiveEventAndMaybeAsk();
    }
  }

  void updateTransaction(StatementTransaction updated) {
    final transactions = state.transactions
        .map(
          (transaction) => transaction.id == updated.id ? updated : transaction,
        )
        .toList();
    final report = ref.read(validationEngineProvider).validate(transactions);
    final job = state.activeJob;

    if (job == null) {
      state = state.copyWith(transactions: transactions);
      return;
    }

    final updatedJob = ConversionJob(
      id: job.id,
      filename: job.filename,
      bank: job.bank,
      transactions: transactions,
      validationReport: report,
      createdAt: job.createdAt,
    );

    state = state.copyWith(
      transactions: transactions,
      activeJob: updatedJob,
      // Keep the matching history entry in sync with the correction.
      history: [
        for (final entry in state.history)
          entry.id == updatedJob.id ? updatedJob : entry,
      ],
    );
    _persistHistory();
  }
}
