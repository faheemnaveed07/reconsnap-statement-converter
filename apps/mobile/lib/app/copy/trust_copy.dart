/// Canonical trust & privacy copy — **one true sentence, used verbatim** on
/// every surface that mentions the data path (onboarding, upload, processing,
/// paywall, settings). The product's single most sensitive promise must read
/// identically everywhere; this file is the only source of truth for it.
///
/// The real data path is verified in code: digital PDFs are read by
/// `OnDevicePdfTextExtractor` and photos/scans by on-device ML Kit OCR. No
/// network call is made during a conversion — `RemotePdfTextExtractor` exists in
/// the tree but is wired nowhere. So the accurate statement is **fully
/// on-device**. If the data path ever changes, change it here once.
class TrustCopy {
  const TrustCopy._();

  /// The one-liner. Use verbatim on every privacy surface.
  static const oneLine =
      'Your statement is read and reconciled entirely on your device. '
      'It is never uploaded, and we never ask for bank logins.';

  /// A shorter form for tight spaces (pills, processing footer, captions).
  /// Same meaning, same promise.
  static const short = 'Read and reconciled on your device. Never uploaded.';

  /// The reconciliation guarantee — the real differentiator. Leads onboarding
  /// and the paywall instead of an unprovable accuracy number.
  static const reconcileGuarantee =
      'Every row is reconciled against the running balance, or flagged for your review.';
}
