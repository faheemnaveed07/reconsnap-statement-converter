/// What happened on a conversion attempt — for the failure-coverage flywheel.
enum ConversionOutcomeType {
  success,
  noTransactions,
  notAStatement, // annual report / form
  unreadable, // broken font / non-statement text
  needsOcr, // scanned
  needsPassword,
  failed,
}

/// A single conversion outcome record.
///
/// PRIVACY: this captures *only* non-content signals — never a description,
/// amount, balance, account number, or any bytes from the statement. It exists
/// so we (and the user, who shares it voluntarily) can see *which layouts fail*
/// without ever seeing the user's financial data.
class ConversionOutcome {
  const ConversionOutcome({
    required this.at,
    required this.type,
    required this.bankId,
    this.parserVersion,
    this.transactionCount = 0,
    this.reconciled,
  });

  final DateTime at;
  final ConversionOutcomeType type;

  /// The user-selected bank id (not sensitive).
  final String bankId;
  final String? parserVersion;
  final int transactionCount;
  final bool? reconciled;

  Map<String, dynamic> toJson() => {
    'at': at.toIso8601String(),
    'type': type.name,
    'bankId': bankId,
    'parserVersion': parserVersion,
    'transactionCount': transactionCount,
    'reconciled': reconciled,
  };

  factory ConversionOutcome.fromJson(Map<String, dynamic> json) {
    return ConversionOutcome(
      at: DateTime.parse(json['at'] as String),
      type: ConversionOutcomeType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => ConversionOutcomeType.failed,
      ),
      bankId: json['bankId'] as String? ?? 'unknown',
      parserVersion: json['parserVersion'] as String?,
      transactionCount: (json['transactionCount'] as num?)?.toInt() ?? 0,
      reconciled: json['reconciled'] as bool?,
    );
  }

  String get label => switch (type) {
    ConversionOutcomeType.success => 'Converted',
    ConversionOutcomeType.noTransactions => 'No transactions found',
    ConversionOutcomeType.notAStatement => 'Not a statement',
    ConversionOutcomeType.unreadable => 'Unreadable text',
    ConversionOutcomeType.needsOcr => 'Scan (OCR needed)',
    ConversionOutcomeType.needsPassword => 'Password required',
    ConversionOutcomeType.failed => 'Failed',
  };

  bool get isSuccess => type == ConversionOutcomeType.success;
}
