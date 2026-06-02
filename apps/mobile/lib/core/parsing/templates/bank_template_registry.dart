import '../positioned/positioned_models.dart';
import 'bank_statement_template.dart';
import 'emirates_nbd_template.dart';

/// Holds the known bank templates and picks the one that best matches a
/// document. New banks are added to [defaultTemplates] (FAB, ADCB, Mashreq,
/// DIB) as their templates are built.
class BankTemplateRegistry {
  const BankTemplateRegistry([this.templates = defaultTemplates]);

  final List<BankStatementTemplate> templates;

  static const defaultTemplates = <BankStatementTemplate>[
    EmiratesNbdTemplate(),
  ];

  /// Minimum confidence before we trust a template over the generic parser.
  static const _threshold = 0.5;

  /// The best-matching template above the confidence threshold, or null to let
  /// the caller fall back to generic parsing. The user's selected bank
  /// ([hintBankId]) gets a small nudge to break ties, but cannot promote a
  /// template whose fingerprint is absent.
  BankStatementTemplate? detect(ExtractedDocument doc, {String? hintBankId}) {
    BankStatementTemplate? best;
    var bestScore = 0.0;
    for (final template in templates) {
      var score = template.matchScore(doc);
      if (score > 0 && hintBankId != null && template.bankId == hintBankId) {
        score += 0.05;
      }
      if (score > bestScore) {
        bestScore = score;
        best = template;
      }
    }
    return bestScore >= _threshold ? best : null;
  }
}
