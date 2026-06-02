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

  Map<String, dynamic> toJson() => {
    'id': id,
    'filename': filename,
    'bank': bank.toJson(),
    'transactions': transactions.map((t) => t.toJson()).toList(),
    'validationReport': validationReport.toJson(),
    'createdAt': createdAt.toIso8601String(),
    'status': status.name,
  };

  factory ConversionJob.fromJson(Map<String, dynamic> json) {
    return ConversionJob(
      id: json['id'] as String,
      filename: json['filename'] as String,
      bank: Bank.fromJson(json['bank'] as Map<String, dynamic>),
      transactions: (json['transactions'] as List<dynamic>? ?? [])
          .map((e) => StatementTransaction.fromJson(e as Map<String, dynamic>))
          .toList(),
      validationReport: ValidationReport.fromJson(
        json['validationReport'] as Map<String, dynamic>,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: ConversionStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => ConversionStatus.ready,
      ),
    );
  }
}
