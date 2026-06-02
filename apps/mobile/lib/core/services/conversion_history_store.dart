import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/conversion_job.dart';

/// Persists conversion history to a JSON file in the app's documents directory
/// so past conversions survive an app restart.
///
/// The store is deliberately forgiving: a missing or corrupt file loads as an
/// empty history rather than crashing the app, and writes are best-effort. The
/// file location is injectable so the (de)serialisation can be unit-tested
/// against a temp file without platform channels.
class ConversionHistoryStore {
  ConversionHistoryStore({Future<File> Function()? fileLocator})
    : _fileLocator = fileLocator ?? _defaultFile;

  final Future<File> Function() _fileLocator;

  /// Cap the persisted history so the file stays small over time.
  static const maxEntries = 50;

  static Future<File> _defaultFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/conversion_history.json');
  }

  Future<List<ConversionJob>> load() async {
    try {
      final file = await _fileLocator();
      if (!await file.exists()) return const [];
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return const [];
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => ConversionJob.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Corrupt or unreadable history must never block the app from starting.
      return const [];
    }
  }

  Future<void> save(List<ConversionJob> jobs) async {
    try {
      final file = await _fileLocator();
      final capped = jobs.take(maxEntries).toList();
      final encoded = jsonEncode(capped.map((j) => j.toJson()).toList());
      await file.writeAsString(encoded);
    } catch (_) {
      // Best-effort: a failed write should not surface as a user-facing error.
    }
  }
}
