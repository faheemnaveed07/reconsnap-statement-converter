import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/services/statement_exporter.dart';

/// Export framed as a *destination* ("where's this going?") rather than a file
/// format. The user thinks in tools; we map the tool to the right
/// [ExportFormat] under the hood. This also surfaces OFX/QuickBooks/Xero as
/// first-class — the formats accountants actually pay for.
enum ExportDestination { excel, quickbooks, xero, banking, otherCsv }

extension ExportDestinationInfo on ExportDestination {
  String get label => switch (this) {
    ExportDestination.excel => 'Excel / Google Sheets',
    ExportDestination.quickbooks => 'QuickBooks',
    ExportDestination.xero => 'Xero',
    ExportDestination.banking => 'Banking software',
    ExportDestination.otherCsv => 'Other (CSV)',
  };

  String get subtitle => switch (this) {
    ExportDestination.excel => 'A spreadsheet with amounts as numbers (.xlsx).',
    ExportDestination.quickbooks => 'Signed-amount CSV ready for import.',
    ExportDestination.xero => 'Signed-amount CSV ready for import.',
    ExportDestination.banking => 'OFX for QuickBooks Online & banking apps.',
    ExportDestination.otherCsv => 'Date, Description, Debit, Credit, Balance.',
  };

  IconData get icon => switch (this) {
    ExportDestination.excel => Icons.grid_on_rounded,
    ExportDestination.quickbooks => Icons.account_balance_wallet_outlined,
    ExportDestination.xero => Icons.cloud_outlined,
    ExportDestination.banking => Icons.sync_alt_rounded,
    ExportDestination.otherCsv => Icons.table_rows_rounded,
  };

  /// One-line description of the column mapping the destination will see.
  String get mappingNote => switch (this) {
    ExportDestination.excel =>
      'Date, Description, Debit, Credit, Balance — amounts as numbers.',
    ExportDestination.quickbooks || ExportDestination.xero =>
      'Date, Description, signed Amount — dates as DD/MM/YYYY.',
    ExportDestination.banking => 'Standard OFX bank-transaction records.',
    ExportDestination.otherCsv =>
      'Date, Description, Debit, Credit, Balance — dates as DD/MM/YYYY.',
  };

  ExportFormat get format => switch (this) {
    ExportDestination.excel => ExportFormat.xlsx,
    ExportDestination.quickbooks ||
    ExportDestination.xero => ExportFormat.csvAccounting,
    ExportDestination.banking => ExportFormat.ofx,
    ExportDestination.otherCsv => ExportFormat.csvDetailed,
  };
}

/// Remembers the user's last export destination so a repeat user (e.g. always
/// Xero) doesn't re-choose every time. A tiny marker file — same on-device
/// posture as the rest of the app.
class ExportPreferenceStore {
  ExportPreferenceStore({Future<File> Function()? fileLocator})
    : _fileLocator = fileLocator ?? _defaultFile;

  final Future<File> Function() _fileLocator;

  static Future<File> _defaultFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/export_destination');
  }

  Future<ExportDestination?> load() async {
    try {
      final file = await _fileLocator();
      if (!await file.exists()) return null;
      final name = (await file.readAsString()).trim();
      for (final d in ExportDestination.values) {
        if (d.name == name) return d;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> save(ExportDestination destination) async {
    try {
      await (await _fileLocator()).writeAsString(destination.name);
    } catch (_) {
      // Best-effort; worst case the user re-picks next time.
    }
  }
}

final exportPreferenceStoreProvider = Provider(
  (ref) => ExportPreferenceStore(),
);

/// The remembered export destination, loaded on first read and updated when the
/// user exports. Null until loaded / never set.
final exportDestinationProvider =
    NotifierProvider<ExportDestinationController, ExportDestination?>(
      ExportDestinationController.new,
    );

class ExportDestinationController extends Notifier<ExportDestination?> {
  @override
  ExportDestination? build() {
    _restore();
    return null;
  }

  Future<void> _restore() async {
    final saved = await ref.read(exportPreferenceStoreProvider).load();
    if (saved != null) state = saved;
  }

  void remember(ExportDestination destination) {
    state = destination;
    ref.read(exportPreferenceStoreProvider).save(destination);
  }
}
