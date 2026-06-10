import 'ocr_models.dart';

/// How readable a scan/photo is, judged from the OCR engine's own per-word
/// confidence. Coarse on purpose — the user sees "good / fair / poor", never a
/// fabricated percentage. `null` (unknown) is a first-class outcome: when the
/// backend reports no confidence and enough text was recovered, we say nothing
/// rather than invent a reading.
enum ScanLegibility { good, fair, poor }

extension ScanLegibilityLabel on ScanLegibility {
  String get label => switch (this) {
    ScanLegibility.good => 'Good',
    ScanLegibility.fair => 'Fair',
    ScanLegibility.poor => 'Poor',
  };
}

class LegibilityAssessment {
  const LegibilityAssessment({
    required this.level,
    required this.wordCount,
    this.meanConfidence,
  });

  /// null = no basis to judge (unknown) — don't surface or gate.
  final ScanLegibility? level;
  final int wordCount;
  final double? meanConfidence;

  bool get isPoor => level == ScanLegibility.poor;

  static const unknown = LegibilityAssessment(level: null, wordCount: 0);
}

/// Thresholds are deliberately coarse and documented here so the read-out can be
/// trusted: too little recovered text is poor regardless; otherwise the mean of
/// the engine's per-word confidence buckets into good (≥0.80) / fair (≥0.60) /
/// poor. When fewer than half the words carry a confidence we return unknown
/// rather than guess.
LegibilityAssessment assessLegibility(List<OcrResult> pages) {
  final words = [
    for (final page in pages)
      for (final line in page.lines)
        for (final w in line.words)
          if (w.text.trim().isNotEmpty) w,
  ];
  final wordCount = words.length;

  // Very little text recovered means the scan is unreadable, whatever the
  // confidence numbers say.
  if (wordCount < 12) {
    return LegibilityAssessment(
      level: ScanLegibility.poor,
      wordCount: wordCount,
    );
  }

  final confidences = [
    for (final w in words)
      if (w.confidence != null) w.confidence!,
  ];

  // Need confidence on a reasonable share of the words to judge honestly.
  if (confidences.length < wordCount * 0.5) {
    return LegibilityAssessment(level: null, wordCount: wordCount);
  }

  final mean = confidences.reduce((a, b) => a + b) / confidences.length;
  final level = mean >= 0.80
      ? ScanLegibility.good
      : mean >= 0.60
      ? ScanLegibility.fair
      : ScanLegibility.poor;
  return LegibilityAssessment(
    level: level,
    wordCount: wordCount,
    meanConfidence: mean,
  );
}
