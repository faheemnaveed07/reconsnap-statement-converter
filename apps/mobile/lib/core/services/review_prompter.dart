import 'dart:convert';
import 'dart:io';

import 'package:in_app_review/in_app_review.dart';
import 'package:path_provider/path_provider.dart';

/// Where ReconSnap can be shared from. Placeholder until the store listing is
/// live; update with the real Play/App Store URL at launch.
const appShareUrl = 'https://reconsnap.app';

/// Thin seam over the platform review API so the prompt policy is testable
/// without a store.
abstract interface class ReviewLauncher {
  Future<bool> isAvailable();
  Future<void> requestReview();
}

class StoreReviewLauncher implements ReviewLauncher {
  StoreReviewLauncher([InAppReview? review])
    : _review = review ?? InAppReview.instance;
  final InAppReview _review;

  @override
  Future<bool> isAvailable() => _review.isAvailable();

  @override
  Future<void> requestReview() => _review.requestReview();
}

/// Asks for an app-store review at a genuinely positive moment (after a few
/// successful conversions), at most once. The "when" policy is deterministic
/// and persisted, so it survives restarts and is unit-testable; the platform
/// call is injected.
class ReviewPrompter {
  ReviewPrompter({
    ReviewLauncher? launcher,
    Future<File> Function()? fileLocator,
    this.threshold = 2,
  }) : _launcher = launcher ?? StoreReviewLauncher(),
       _fileLocator = fileLocator ?? _defaultFile;

  final ReviewLauncher _launcher;
  final Future<File> Function() _fileLocator;

  /// Successful conversions before the first (and only) review request.
  final int threshold;

  static Future<File> _defaultFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/review_state.json');
  }

  /// Records a positive event; asks for a review once the threshold is reached,
  /// then never again. Failures are swallowed — a review prompt must never
  /// disrupt the conversion flow.
  Future<void> recordPositiveEventAndMaybeAsk() async {
    try {
      final state = await _load();
      final count = (state['count'] as int) + 1;
      final prompted = state['prompted'] as bool;

      if (!prompted && count >= threshold && await _launcher.isAvailable()) {
        await _launcher.requestReview();
        await _save(count, true);
      } else {
        await _save(count, prompted);
      }
    } catch (_) {
      // Best-effort.
    }
  }

  Future<Map<String, dynamic>> _load() async {
    try {
      final file = await _fileLocator();
      if (!await file.exists()) return {'count': 0, 'prompted': false};
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return {
        'count': (json['count'] as num?)?.toInt() ?? 0,
        'prompted': (json['prompted'] as bool?) ?? false,
      };
    } catch (_) {
      return {'count': 0, 'prompted': false};
    }
  }

  Future<void> _save(int count, bool prompted) async {
    final file = await _fileLocator();
    await file.writeAsString(
      jsonEncode({'count': count, 'prompted': prompted}),
    );
  }
}
