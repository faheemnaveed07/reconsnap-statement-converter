import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/bank.dart';
import '../../../core/models/conversion_job.dart';
import '../../../core/models/statement_transaction.dart';
import '../../../core/parsing/mock_statement_parser.dart';
import '../../../core/parsing/on_device_pdf_text_extractor.dart';
import '../../../core/parsing/positioned/positioned_pdf_extractor.dart';
import '../../../core/parsing/statement_parser.dart';
import '../../../core/parsing/templated_statement_parser.dart';
import '../../../core/parsing/text/statement_text_extractor.dart';
import '../../../core/services/conversion_history_store.dart';
import '../../../core/services/csv_export_service.dart';
import '../../../core/services/xlsx_export_service.dart';
import '../../../core/validation/validation_engine.dart';

final validationEngineProvider = Provider((ref) => const ValidationEngine());
final csvExportServiceProvider = Provider((ref) => CsvExportService());
final xlsxExportServiceProvider = Provider((ref) => XlsxExportService());

/// Persists conversion history across app restarts.
final conversionHistoryStoreProvider = Provider(
  (ref) => ConversionHistoryStore(),
);

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

/// Real parser for digital PDFs: document-type gate → bank-specific column
/// template (Emirates NBD today) → generic balance-reconciling fallback.
final digitalStatementParserProvider = Provider<StatementParser>(
  (ref) => TemplatedStatementParser(
    extractor: ref.watch(positionedPdfExtractorProvider),
  ),
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
    );
  }
}

class ConversionController extends Notifier<ConversionState> {
  static const _uuid = Uuid();

  @override
  ConversionState build() {
    _restoreHistory();
    return ConversionState.initial();
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
        state = state.copyWith(
          status: ConversionStatus.failed,
          errorMessage:
              'No transactions were detected. The layout may not be supported yet.',
        );
        return;
      }

      _completeWith(result, validator, filename);
    } on PasswordRequiredException {
      state = state.copyWith(
        status: ConversionStatus.needsPassword,
        errorMessage: null,
      );
    } on UnsupportedDocumentException catch (e) {
      // Not an account statement (annual report, form, unreadable text) — tell
      // the user why instead of showing a generic failure.
      state = state.copyWith(
        status: ConversionStatus.failed,
        errorMessage: e.message,
      );
    } on OcrNotSupportedException catch (e) {
      state = state.copyWith(
        status: ConversionStatus.failed,
        errorMessage: e.message,
      );
    } on ExtractionException catch (e) {
      state = state.copyWith(
        status: ConversionStatus.failed,
        errorMessage: e.message,
      );
    } catch (_) {
      state = state.copyWith(
        status: ConversionStatus.failed,
        errorMessage: 'Conversion failed. Please try another file.',
      );
    }
  }

  /// Retries the in-flight conversion with a user-supplied password.
  Future<void> submitPassword(String password) async {
    final bytes = state.pendingBytes;
    final filename = state.filename;
    if (bytes == null || filename == null) return;
    await startConversion(bytes: bytes, filename: filename, password: password);
  }

  Future<void> startMockConversion({String? filename}) async {
    final parser = ref.read(mockStatementParserProvider);
    final validator = ref.read(validationEngineProvider);
    final selectedFilename = filename ?? 'emirates-nbd-may-2026.pdf';

    state = state.copyWith(
      status: ConversionStatus.processing,
      filename: selectedFilename,
      errorMessage: null,
    );

    try {
      final result = await parser.parse(
        ParseInput(filename: selectedFilename, bank: state.selectedBank),
      );
      _completeWith(result, validator, selectedFilename);
    } catch (_) {
      state = state.copyWith(
        status: ConversionStatus.failed,
        errorMessage: 'Conversion failed. Please try another file.',
      );
    }
  }

  void _completeWith(
    ParseResult result,
    ValidationEngine validator,
    String filename,
  ) {
    final report = validator.validate(result.transactions);
    final job = ConversionJob(
      id: _uuid.v4(),
      filename: filename,
      bank: result.bank,
      transactions: result.transactions,
      validationReport: report,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      status: ConversionStatus.ready,
      transactions: result.transactions,
      warnings: result.warnings,
      activeJob: job,
      history: [job, ...state.history],
    );
    _persistHistory();
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
