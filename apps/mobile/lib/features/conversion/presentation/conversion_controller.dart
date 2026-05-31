import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/bank.dart';
import '../../../core/models/conversion_job.dart';
import '../../../core/models/statement_transaction.dart';
import '../../../core/parsing/mock_statement_parser.dart';
import '../../../core/parsing/statement_parser.dart';
import '../../../core/services/csv_export_service.dart';
import '../../../core/validation/validation_engine.dart';

final validationEngineProvider = Provider((ref) => const ValidationEngine());
final statementParserProvider = Provider<StatementParser>(
  (ref) => const MockStatementParser(),
);
final csvExportServiceProvider = Provider((ref) => CsvExportService());

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
  final String? errorMessage;

  ConversionState copyWith({
    Bank? selectedBank,
    ConversionStatus? status,
    String? filename,
    List<StatementTransaction>? transactions,
    ConversionJob? activeJob,
    List<ConversionJob>? history,
    String? errorMessage,
  }) {
    return ConversionState(
      selectedBank: selectedBank ?? this.selectedBank,
      status: status ?? this.status,
      filename: filename ?? this.filename,
      transactions: transactions ?? this.transactions,
      activeJob: activeJob ?? this.activeJob,
      history: history ?? this.history,
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

  Future<void> startMockConversion({String? filename}) async {
    final parser = ref.read(statementParserProvider);
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
      final report = validator.validate(result.transactions);
      final job = ConversionJob(
        id: _uuid.v4(),
        filename: selectedFilename,
        bank: result.bank,
        transactions: result.transactions,
        validationReport: report,
        createdAt: DateTime.now(),
      );

      state = state.copyWith(
        status: ConversionStatus.ready,
        transactions: result.transactions,
        activeJob: job,
        history: [job, ...state.history],
      );
    } catch (error) {
      state = state.copyWith(
        status: ConversionStatus.failed,
        errorMessage: 'Conversion failed. Please try another file.',
      );
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
