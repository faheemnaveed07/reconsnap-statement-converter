enum ValidationSeverity { pass, warning, fail }

class ValidationIssue {
  const ValidationIssue({
    required this.title,
    required this.message,
    this.severity = ValidationSeverity.warning,
  });

  final String title;
  final String message;
  final ValidationSeverity severity;

  Map<String, dynamic> toJson() => {
    'title': title,
    'message': message,
    'severity': severity.name,
  };

  factory ValidationIssue.fromJson(Map<String, dynamic> json) {
    return ValidationIssue(
      title: json['title'] as String,
      message: json['message'] as String,
      severity: ValidationSeverity.values.firstWhere(
        (s) => s.name == json['severity'],
        orElse: () => ValidationSeverity.warning,
      ),
    );
  }
}

class ValidationReport {
  const ValidationReport({
    required this.openingBalance,
    required this.closingBalance,
    required this.totalDebits,
    required this.totalCredits,
    required this.expectedClosingBalance,
    required this.issues,
  });

  final double? openingBalance;
  final double? closingBalance;
  final double totalDebits;
  final double totalCredits;
  final double? expectedClosingBalance;
  final List<ValidationIssue> issues;

  bool get hasOpeningAndClosing =>
      openingBalance != null && closingBalance != null;

  bool get isPassed => issues
      .where((issue) => issue.severity == ValidationSeverity.fail)
      .isEmpty;

  bool get hasWarnings => issues
      .where((issue) => issue.severity == ValidationSeverity.warning)
      .isNotEmpty;

  Map<String, dynamic> toJson() => {
    'openingBalance': openingBalance,
    'closingBalance': closingBalance,
    'totalDebits': totalDebits,
    'totalCredits': totalCredits,
    'expectedClosingBalance': expectedClosingBalance,
    'issues': issues.map((issue) => issue.toJson()).toList(),
  };

  factory ValidationReport.fromJson(Map<String, dynamic> json) {
    return ValidationReport(
      openingBalance: (json['openingBalance'] as num?)?.toDouble(),
      closingBalance: (json['closingBalance'] as num?)?.toDouble(),
      totalDebits: (json['totalDebits'] as num?)?.toDouble() ?? 0,
      totalCredits: (json['totalCredits'] as num?)?.toDouble() ?? 0,
      expectedClosingBalance: (json['expectedClosingBalance'] as num?)
          ?.toDouble(),
      issues: (json['issues'] as List<dynamic>? ?? [])
          .map((e) => ValidationIssue.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
