import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../models/statement_transaction.dart';

/// Exports transactions as OFX (Open Financial Exchange) — the format banks use
/// for "download to Quicken/QuickBooks", and which QuickBooks Online, Xero and
/// most accounting tools import directly.
///
/// We emit OFX 1.0.2 (SGML), which has the broadest import compatibility. Each
/// transaction carries a signed amount (credit positive, debit negative), a
/// type, a posted date, and a stable FITID so re-imports de-duplicate.
class OfxExportService {
  OfxExportService({DateFormat? dateFormat})
    : _date = dateFormat ?? DateFormat('yyyyMMdd');

  final DateFormat _date;

  String buildOfx(List<StatementTransaction> transactions) {
    final currency = transactions
        .map((t) => t.currency)
        .firstWhere((c) => c.isNotEmpty, orElse: () => 'AED');
    final dates = transactions.map((t) => t.date).toList()..sort();
    final start = dates.isEmpty ? DateTime.now() : dates.first;
    final end = dates.isEmpty ? DateTime.now() : dates.last;

    final buf = StringBuffer()
      ..writeln('OFXHEADER:100')
      ..writeln('DATA:OFXSGML')
      ..writeln('VERSION:102')
      ..writeln('SECURITY:NONE')
      ..writeln('ENCODING:USASCII')
      ..writeln('CHARSET:1252')
      ..writeln('COMPRESSION:NONE')
      ..writeln('OLDFILEUID:NONE')
      ..writeln('NEWFILEUID:NONE')
      ..writeln()
      ..writeln('<OFX>')
      ..writeln('<SIGNONMSGSRSV1><SONRS>')
      ..writeln('<STATUS><CODE>0<SEVERITY>INFO</STATUS>')
      ..writeln('<DTSERVER>${_date.format(end)}')
      ..writeln('<LANGUAGE>ENG')
      ..writeln('</SONRS></SIGNONMSGSRSV1>')
      ..writeln('<BANKMSGSRSV1><STMTTRNRS>')
      ..writeln('<TRNUID>1')
      ..writeln('<STATUS><CODE>0<SEVERITY>INFO</STATUS>')
      ..writeln('<STMTRS>')
      ..writeln('<CURDEF>$currency')
      ..writeln(
        '<BANKACCTFROM><BANKID>RECONSNAP<ACCTID>STATEMENT'
        '<ACCTTYPE>CHECKING</BANKACCTFROM>',
      )
      ..writeln('<BANKTRANLIST>')
      ..writeln('<DTSTART>${_date.format(start)}')
      ..writeln('<DTEND>${_date.format(end)}');

    for (final t in transactions) {
      final amount = t.signedAmount;
      buf
        ..writeln('<STMTTRN>')
        ..writeln('<TRNTYPE>${amount < 0 ? 'DEBIT' : 'CREDIT'}')
        ..writeln('<DTPOSTED>${_date.format(t.date)}')
        ..writeln('<TRNAMT>${amount.toStringAsFixed(2)}')
        ..writeln('<FITID>${t.id}')
        ..writeln('<NAME>${_sanitize(t.description, 32)}')
        ..writeln('<MEMO>${_sanitize(t.description, 255)}')
        ..writeln('</STMTTRN>');
    }

    buf.writeln('</BANKTRANLIST>');
    final closing = transactions.isNotEmpty ? transactions.last.balance : null;
    if (closing != null) {
      buf
        ..writeln('<LEDGERBAL>')
        ..writeln('<BALAMT>${closing.toStringAsFixed(2)}')
        ..writeln('<DTASOF>${_date.format(end)}')
        ..writeln('</LEDGERBAL>');
    }
    buf
      ..writeln('</STMTRS>')
      ..writeln('</STMTTRNRS></BANKMSGSRSV1>')
      ..writeln('</OFX>');

    return buf.toString();
  }

  Future<File> writeOfx({
    required String filename,
    required List<StatementTransaction> transactions,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    return file.writeAsString(buildOfx(transactions));
  }

  /// OFX 1.x is SGML; `<` and `&` in free text would break parsers.
  static String _sanitize(String s, int maxLen) {
    final cleaned = s
        .replaceAll('&', 'and')
        .replaceAll('<', '(')
        .replaceAll('>', ')')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned.length <= maxLen ? cleaned : cleaned.substring(0, maxLen);
  }
}
