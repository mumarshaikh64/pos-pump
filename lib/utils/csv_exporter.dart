import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import '../models/entry_model.dart';
import 'package:intl/intl.dart';

class CsvExporter {
  static Future<String> exportToCsv(List<EntryModel> entries) async {
    List<List<dynamic>> rows = [];

    // Type 1 Headers
    rows.add([
      'TYPE',
      'DATE',
      'DETAILS',
      'VEHICLE NUMBER',
      'DIESEL EXPENSE',
      'AUTOS / OTHER EXPENSE',
      'TOTAL EXPENSE',
      'RATE PER TON',
      'TOTAL TON',
      'EARNINGS',
      'FINAL PROFIT',
    ]);

    for (var entry in entries) {
      List<dynamic> row = [];
      row.add(entry.type == 1 ? 'Trip Entry' : 'Load Report');
      row.add(DateFormat('yyyy-MM-dd').format(entry.date));
      row.add(entry.details);
      row.add(entry.vehicleNumber);
      row.add(entry.dieselExpense);
      row.add(entry.otherExpense);
      row.add(entry.totalExpense);
      row.add(entry.ratePerTon ?? '');
      row.add(entry.totalTon ?? '');
      row.add(entry.earnings);
      row.add(entry.profit);

      rows.add(row);
    }

    String csv = const ListToCsvConverter().convert(rows);

    final directory = await getApplicationDocumentsDirectory();
    final path =
        '${directory.path}/transport_pos_export_${DateTime.now().millisecondsSinceEpoch}.csv';

    final File file = File(path);
    await file.writeAsString(csv);

    return path;
  }
}
