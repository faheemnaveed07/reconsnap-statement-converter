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
}
