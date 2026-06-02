import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:reconsnap_statement_converter/core/services/first_run_store.dart';

void main() {
  test('isSeen flips after markSeen and persists', () async {
    final dir = await Directory.systemTemp.createTemp('reconsnap_firstrun');
    final file = File('${dir.path}/onboarding_seen');
    final store = FirstRunStore(fileLocator: () async => file);

    expect(await store.isSeen(), isFalse);
    await store.markSeen();
    expect(await store.isSeen(), isTrue);

    // A fresh instance reading the same file still sees it.
    final reopened = FirstRunStore(fileLocator: () async => file);
    expect(await reopened.isSeen(), isTrue);

    await dir.delete(recursive: true);
  });
}
