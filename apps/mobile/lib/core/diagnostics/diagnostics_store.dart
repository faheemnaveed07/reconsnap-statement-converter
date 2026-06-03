import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'conversion_outcome.dart';

/// On-device, capped log of conversion outcomes (newest first).
///
/// Same posture as the other stores: a missing/corrupt file reads as empty,
/// writes are best-effort, and nothing here ever leaves the device unless the
/// user explicitly shares it. No statement content is stored — see
/// [ConversionOutcome].
class DiagnosticsStore {
  DiagnosticsStore({Future<File> Function()? fileLocator})
    : _fileLocator = fileLocator ?? _defaultFile;

  final Future<File> Function() _fileLocator;

  static const maxEntries = 50;

  static Future<File> _defaultFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/diagnostics.json');
  }

  Future<List<ConversionOutcome>> load() async {
    try {
      final file = await _fileLocator();
      if (!await file.exists()) return const [];
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return const [];
      return (jsonDecode(raw) as List<dynamic>)
          .map((e) => ConversionOutcome.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> record(ConversionOutcome outcome) async {
    try {
      final entries = [outcome, ...await load()].take(maxEntries).toList();
      await (await _fileLocator()).writeAsString(
        jsonEncode(entries.map((e) => e.toJson()).toList()),
      );
    } catch (_) {
      // Best-effort; diagnostics must never disrupt a conversion.
    }
  }

  Future<void> clear() async {
    try {
      final file = await _fileLocator();
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}
