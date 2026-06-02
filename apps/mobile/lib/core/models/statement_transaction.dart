import 'package:collection/collection.dart';

class StatementTransaction {
  const StatementTransaction({
    required this.id,
    required this.date,
    required this.description,
    this.debit,
    this.credit,
    this.balance,
    this.currency = 'AED',
    this.confidence = 1,
    this.sourcePage,
    this.sourceLine,
    this.notes,
  });

  final String id;
  final DateTime date;
  final String description;
  final double? debit;
  final double? credit;
  final double? balance;
  final String currency;
  final double confidence;
  final int? sourcePage;
  final int? sourceLine;
  final String? notes;

  double get signedAmount => (credit ?? 0) - (debit ?? 0);

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'description': description,
    'debit': debit,
    'credit': credit,
    'balance': balance,
    'currency': currency,
    'confidence': confidence,
    'sourcePage': sourcePage,
    'sourceLine': sourceLine,
    'notes': notes,
  };

  factory StatementTransaction.fromJson(Map<String, dynamic> json) {
    return StatementTransaction(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      description: json['description'] as String,
      debit: (json['debit'] as num?)?.toDouble(),
      credit: (json['credit'] as num?)?.toDouble(),
      balance: (json['balance'] as num?)?.toDouble(),
      currency: json['currency'] as String? ?? 'AED',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1,
      sourcePage: (json['sourcePage'] as num?)?.toInt(),
      sourceLine: (json['sourceLine'] as num?)?.toInt(),
      notes: json['notes'] as String?,
    );
  }

  StatementTransaction copyWith({
    String? id,
    DateTime? date,
    String? description,
    double? debit,
    double? credit,
    double? balance,
    String? currency,
    double? confidence,
    int? sourcePage,
    int? sourceLine,
    String? notes,
  }) {
    return StatementTransaction(
      id: id ?? this.id,
      date: date ?? this.date,
      description: description ?? this.description,
      debit: debit ?? this.debit,
      credit: credit ?? this.credit,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      confidence: confidence ?? this.confidence,
      sourcePage: sourcePage ?? this.sourcePage,
      sourceLine: sourceLine ?? this.sourceLine,
      notes: notes ?? this.notes,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is StatementTransaction &&
        other.id == id &&
        other.date == date &&
        other.description == description &&
        other.debit == debit &&
        other.credit == credit &&
        other.balance == balance &&
        other.currency == currency &&
        other.confidence == confidence &&
        other.sourcePage == sourcePage &&
        other.sourceLine == sourceLine &&
        other.notes == notes;
  }

  @override
  int get hashCode => Object.hash(
    id,
    date,
    description,
    debit,
    credit,
    balance,
    currency,
    confidence,
    sourcePage,
    sourceLine,
    notes,
  );
}

extension StatementTransactionList on List<StatementTransaction> {
  double get totalDebits => map((row) => row.debit ?? 0).sum;

  double get totalCredits => map((row) => row.credit ?? 0).sum;
}
