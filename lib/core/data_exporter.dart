import 'dart:convert';
import '../data/models/caffeine_entry.dart';

class DataExporter {
  /// Export entries to CSV string.
  String exportToCsv(List<CaffeineEntry> entries) {
    final buffer = StringBuffer();
    buffer.writeln('id,drink_name,mg_amount,consumed_at,notes');
    for (final e in entries) {
      final notes = (e.notes ?? '').replaceAll('"', '""');
      final name = e.drinkName.replaceAll('"', '""');
      buffer.writeln(
          '"${e.id}","$name",${e.mgAmount.toStringAsFixed(1)},"${e.consumedAt.toIso8601String()}","$notes"');
    }
    return buffer.toString();
  }

  /// Export entries to JSON string.
  String exportToJson(List<CaffeineEntry> entries) {
    final list = entries
        .map((e) => {
              'id': e.id,
              'drink_name': e.drinkName,
              'mg_amount': e.mgAmount,
              'consumed_at': e.consumedAt.toIso8601String(),
              'notes': e.notes,
            })
        .toList();
    return const JsonEncoder.withIndent('  ').convert(list);
  }
}
