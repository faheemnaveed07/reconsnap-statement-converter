import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Remembers whether the user has completed first-run onboarding.
///
/// A tiny marker file (same on-device posture as the rest of the app). A
/// missing/unreadable marker simply means "not seen yet", so onboarding shows
/// — never a crash.
class FirstRunStore {
  FirstRunStore({Future<File> Function()? fileLocator})
    : _fileLocator = fileLocator ?? _defaultFile;

  final Future<File> Function() _fileLocator;

  static Future<File> _defaultFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/onboarding_seen');
  }

  Future<bool> isSeen() async {
    try {
      return await (await _fileLocator()).exists();
    } catch (_) {
      return false;
    }
  }

  Future<void> markSeen() async {
    try {
      await (await _fileLocator()).writeAsString('1');
    } catch (_) {
      // Best-effort; worst case onboarding shows again.
    }
  }
}
