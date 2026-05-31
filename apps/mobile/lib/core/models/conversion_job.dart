import 'bank.dart';
import 'statement_transaction.dart';
import 'validation_report.dart';

enum ConversionStatus { idle, selecting, processing, needsPassword, ready, failed }

class ConversionJob {
  const ConversionJob({
    required this.id,
    required this.filename,
    required this.bank,
    required this.transactions,
    required this.validationReport,
    required this.createdAt,
    this.status = ConversionStatus.ready,
  });

  final String id;
  final String filename;
  final Bank bank;
  final List<StatementTransaction> transactions;
  final ValidationReport validationReport;
  final DateTime createdAt;
  final ConversionStatus status;
}
