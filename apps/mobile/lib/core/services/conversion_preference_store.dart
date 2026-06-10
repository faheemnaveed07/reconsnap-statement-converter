import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// User preferences that shape *how* a statement is parsed and pre-filled.
///
/// Persisted on-device (same posture as the rest of the app). Kept tiny and
/// provider-agnostic. The defaults match the launch market: UAE/GCC day-first
/// dates, no forced bank.
class ConversionPreferences {
  const ConversionPreferences({this.defaultBankId, this.dayFirst = true});

  /// The bank pre-selected when confirming a new conversion (null = none).
  final String? defaultBankId;

  /// Statement date interpretation: day-first (DD/MM, UAE/GCC/UK) when true,
  /// month-first (MM/DD, US) when false. Drives the parser.
  final bool dayFirst;

  ConversionPreferences copyWith({
    String? defaultBankId,
    bool clearBank = false,
    bool? dayFirst,
  }) {
    return ConversionPreferences(
      defaultBankId: clearBank ? null : (defaultBankId ?? this.defaultBankId),
      dayFirst: dayFirst ?? this.dayFirst,
    );
  }

  Map<String, dynamic> toJson() => {
    'defaultBankId': defaultBankId,
    'dayFirst': dayFirst,
  };

  factory ConversionPreferences.fromJson(Map<String, dynamic> json) =>
      ConversionPreferences(
        defaultBankId: json['defaultBankId'] as String?,
        dayFirst: (json['dayFirst'] as bool?) ?? true,
      );
}

/// Persists [ConversionPreferences] to a small on-device JSON file. A
/// missing/unreadable file simply means "defaults" — never a crash.
class ConversionPreferenceStore {
  ConversionPreferenceStore({Future<File> Function()? fileLocator})
    : _fileLocator = fileLocator ?? _defaultFile;

  final Future<File> Function() _fileLocator;

  static Future<File> _defaultFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/conversion_preferences.json');
  }

  Future<ConversionPreferences> load() async {
    try {
      final file = await _fileLocator();
      if (!await file.exists()) return const ConversionPreferences();
      final json = jsonDecode(await file.readAsString());
      return ConversionPreferences.fromJson(json as Map<String, dynamic>);
    } catch (_) {
      return const ConversionPreferences();
    }
  }

  Future<void> save(ConversionPreferences prefs) async {
    try {
      await (await _fileLocator()).writeAsString(jsonEncode(prefs.toJson()));
    } catch (_) {
      // Best-effort; worst case the user re-sets next time.
    }
  }
}
