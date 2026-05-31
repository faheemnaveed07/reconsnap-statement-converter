import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../app/config/app_config.dart';
import '../../../core/models/bank.dart';
import '../../../core/models/conversion_job.dart';
import '../../../core/models/statement_transaction.dart';
import '../../../core/parsing/digital_pdf_statement_parser.dart';
import '../../../core/parsing/mock_statement_parser.dart';
import '../../../core/parsing/remote_pdf_text_extractor.dart';
import '../../../core/parsing/statement_parser.dart';
import '../../../core/parsing/text/statement_text_extractor.dart';
import '../../../core/services/csv_export_service.dart';
import '../../../core/validation/validation_engine.dart';

final validationEngineProvider = Provider((ref) => const ValidationEngine());
final csvExportServiceProvider = Provider((ref) => CsvExportService());

/// Mock parser used by the "Run demo conversion" affordance.
final mockStatementParserProvider = Provider<StatementParser>(
  (ref) => const MockStatementParser(),
);

/// Text extractor backed by the ReconSnap API (local dev server by default).
final statementTextExtractorProvider = Provider<StatementTextExtractor>((ref) {
  final extractor = RemotePdfTextExtractor(baseUrl: AppConfig.apiBaseUrl);
  ref.onDispose(extractor.dispose);
  return extractor;
});

/// Real parser for digital PDFs.
final digitalStatementParserProvider = Provider<StatementParser>(
  (ref) => DigitalPdfStatementParser(
    extractor: ref.watch(statementTextExtractorProvider),
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
  ConversionState build() => ConversionState.initial();

  void selectBank(Bank bank) {
    state = state.copyWith(selectedBank: bank);
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
  }

  void updateTransaction(StatementTransaction updated) {
    final transactions = state.transactions
        .map(
          (transaction) => transaction.id == updated.id ? updated : transaction,
        )
        .toList();
    final report = ref.read(validationEngineProvider).validate(transactions);
    final job = state.activeJob;

    state = state.copyWith(
      transactions: transactions,
      activeJob: job == null
          ? null
          : ConversionJob(
              id: job.id,
              filename: job.filename,
              bank: job.bank,
              transactions: transactions,
              validationReport: report,
              createdAt: job.createdAt,
            ),
    );
  }
}
