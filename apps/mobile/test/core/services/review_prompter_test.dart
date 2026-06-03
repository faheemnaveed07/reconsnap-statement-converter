import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:reconsnap_statement_converter/core/services/review_prompter.dart';

class _FakeLauncher implements ReviewLauncher {
  _FakeLauncher({this.available = true});
  final bool available;
  int requests = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<void> requestReview() async => requests++;
}

void main() {
  Future<(ReviewPrompter, _FakeLauncher, Directory)> make({
    bool available = true,
  }) async {
    final dir = await Directory.systemTemp.createTemp('reconsnap_review');
    final file = File('${dir.path}/review_state.json');
    final launcher = _FakeLauncher(available: available);
    final prompter = ReviewPrompter(
      launcher: launcher,
      fileLocator: () async => file,
      threshold: 2,
    );
    return (prompter, launcher, dir);
  }

  test('asks once at the threshold, then never again', () async {
    final (prompter, launcher, dir) = await make();

    await prompter.recordPositiveEventAndMaybeAsk(); // count 1
    expect(launcher.requests, 0);

    await prompter.recordPositiveEventAndMaybeAsk(); // count 2 → ask
    expect(launcher.requests, 1);

    await prompter.recordPositiveEventAndMaybeAsk(); // count 3 → no
    await prompter.recordPositiveEventAndMaybeAsk();
    expect(launcher.requests, 1);

    await dir.delete(recursive: true);
  });

  test('never asks when the platform review API is unavailable', () async {
    final (prompter, launcher, dir) = await make(available: false);

    await prompter.recordPositiveEventAndMaybeAsk();
    await prompter.recordPositiveEventAndMaybeAsk();
    await prompter.recordPositiveEventAndMaybeAsk();
    expect(launcher.requests, 0);

    await dir.delete(recursive: true);
  });
}
