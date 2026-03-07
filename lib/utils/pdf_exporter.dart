import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/entry_model.dart';
import 'package:intl/intl.dart';

class PdfExporter {
  static final _currencyFormat = NumberFormat.currency(
    symbol: 'Rs. ',
    decimalDigits: 0,
  );
  static final _dateFormat = DateFormat('dd MMM yyyy');

  static Future<void> printEntry(EntryModel entry) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "Noman Khattak & Co",
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              if (entry.partyName != null && entry.partyName!.isNotEmpty) ...[
                pw.Text(
                  "MR/MRS: ${entry.partyName}",
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
              ],
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  if (entry.siteName != null && entry.siteName!.isNotEmpty)
                    pw.Text(
                      "Site: ${entry.siteName}",
                      style: pw.TextStyle(fontSize: 13, color: PdfColors.grey800, fontWeight: pw.FontWeight.bold),
                    )
                  else
                    pw.SizedBox(),
                  pw.Text(
                    "Date: ${_dateFormat.format(entry.date)}",
                    style: pw.TextStyle(fontSize: 13, color: PdfColors.grey800, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                "Type: ${entry.type == 1
                    ? 'Trip Entry'
                    : entry.type == 2
                    ? 'Load Report'
                    : 'Material Supply'}",
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              _buildRow("Vehicle Number", entry.vehicleNumber),
              _buildRow("Date", _dateFormat.format(entry.date)),
              if (entry.type == 3) ...[
                _buildRow("Slip Number", entry.slipNumber ?? "-"),
                _buildRow("Material", entry.material ?? "-"),
              ],
              _buildRow("Details", entry.details),
              pw.SizedBox(height: 20),
              pw.Text(
                "Expenses",
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Divider(),
              _buildRow(
                "Diesel Expense",
                _currencyFormat.format(entry.dieselExpense),
              ),
              _buildRow(
                entry.type == 1 ? "Autos Expense" : "Other Expense",
                _currencyFormat.format(entry.otherExpense),
              ),
              pw.Divider(),
              _buildRow(
                "Total Expense",
                _currencyFormat.format(entry.totalExpense),
                isBold: true,
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                "Earnings",
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Divider(),
              if (entry.type != 1) ...[
                _buildRow(
                  entry.type == 3 ? "Rate" : "Rate Per Ton",
                  _currencyFormat.format(entry.ratePerTon ?? 0),
                ),
                _buildRow(
                  entry.type == 3 ? "Total CFT / TON" : "Total Ton / CFT",
                  "${entry.totalTon ?? 0}",
                ),
              ],
              _buildRow(
                entry.type == 1 ? "Trip Earnings" : "Total Earnings",
                _currencyFormat.format(entry.earnings),
                isBold: true,
              ),
              pw.SizedBox(height: 20),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                color: entry.profit >= 0 ? PdfColors.green50 : PdfColors.red50,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      "Final Profit / Balance",
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      _currencyFormat.format(entry.profit),
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: entry.profit >= 0
                            ? PdfColors.green
                            : PdfColors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name:
          'Entry_${entry.vehicleNumber}_${_dateFormat.format(entry.date)}.pdf',
    );
  }

  static Future<void> printReportTable(
    List<EntryModel> entries,
    String title, {
    bool isUnifiedMode = false,
  }) async {
    if (entries.isEmpty) return;

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async {
        final pdf = pw.Document();

        double totalEarnings = 0;
        double totalExpenses = 0;
        double totalProfit = 0;
        double totalTons = 0;
        double totalRates = 0;

        final tableHeaders = <String>[];
        final tableData = <List<String>>[];
        final alignments = <int, pw.Alignment>{};

        // Determine if we have mixed vehicles or types to decide on columns
        final isSingleVehicle = entries.every(
          (e) => e.vehicleNumber == entries.first.vehicleNumber,
        );
        final isSingleType = entries.every((e) => e.type == entries.first.type);
        final firstType = entries.first.type;

        // If in Unified Mode (Monthly/All), we definitely want Vehicle # and Type shown
        final showTypeCol = isUnifiedMode || !isSingleType;

        tableHeaders.add('Date');
        tableHeaders.add('Vehicle #');
        if (showTypeCol) tableHeaders.add('Type');
        if (firstType != 3 || !isSingleType) tableHeaders.add('Details');

        // Column optimization: if all are the same type, we can show specific columns like "Diesel"
        final isType1 = isSingleType && firstType == 1;
        final isType2 = isSingleType && firstType == 2;
        final isType3 = isSingleType && firstType == 3;

        if (isType1) {
          tableHeaders.addAll([
            'Diesel',
            'Autos',
            'Total Exp',
            'Earnings',
            'Profit',
          ]);
        } else if (isType2) {
          tableHeaders.addAll([
            'Diesel',
            'Other',
            'Total Exp',
            'Rate/Ton',
            'Tons',
            'Earnings',
            'Profit',
          ]);
        } else if (isType3) {
          tableHeaders.addAll([
            'Slip No',
            'Material',
            'Rate',
            'CFT/TON',
            'Amount',
          ]);
        } else {
          // Mixed types or forced unified: Show generic financial columns
          tableHeaders.addAll(['Earnings', 'Expenses', 'Profit']);
        }

        for (var e in entries) {
          totalEarnings += e.earnings;
          totalExpenses += e.totalExpense;
          totalProfit += e.profit;
          totalTons += (e.totalTon ?? 0);
          totalRates += (e.ratePerTon ?? 0);

          final row = <String>[];
          row.add(_dateFormat.format(e.date));
          row.add(e.vehicleNumber);
          if (showTypeCol) {
            row.add(
              e.type == 1
                  ? 'Trip'
                  : e.type == 2
                  ? 'Load'
                  : 'Supply',
            );
          }
          if (e.type != 3 || (isUnifiedMode && !isSingleType)) {
            row.add(e.details);
          }

          if (isType1) {
            row.addAll([
              _currencyFormat.format(e.dieselExpense),
              _currencyFormat.format(e.otherExpense),
              _currencyFormat.format(e.totalExpense),
              _currencyFormat.format(e.earnings),
              _currencyFormat.format(e.profit),
            ]);
          } else if (isType2) {
            row.addAll([
              _currencyFormat.format(e.dieselExpense),
              _currencyFormat.format(e.otherExpense),
              _currencyFormat.format(e.totalExpense),
              _currencyFormat.format(e.ratePerTon ?? 0),
              (e.totalTon ?? 0).toString(),
              _currencyFormat.format(e.earnings),
              _currencyFormat.format(e.profit),
            ]);
          } else if (isType3) {
            row.addAll([
              e.slipNumber ?? "-",
              e.material ?? "-",
              _currencyFormat.format(e.ratePerTon ?? 0),
              (e.totalTon ?? 0).toString(),
              _currencyFormat.format(e.earnings),
            ]);
          } else {
            row.addAll([
              _currencyFormat.format(e.earnings),
              _currencyFormat.format(e.totalExpense),
              _currencyFormat.format(e.profit),
            ]);
          }
          tableData.add(row);
        }

        for (int i = 0; i < tableHeaders.length; i++) {
          final h = tableHeaders[i];
          if (h == 'Date' ||
              h == 'Details' ||
              h == 'Type' ||
              h == 'Vehicle #' ||
              h == 'Slip No' ||
              h == 'Material') {
            alignments[i] = pw.Alignment.centerLeft;
          } else if (h == 'Tons' || h == 'CFT/TON') {
            alignments[i] = pw.Alignment.center;
          } else {
            alignments[i] = pw.Alignment.centerRight;
          }
        }

        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(24),
            build: (pw.Context context) {
              return [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.symmetric(vertical: 10),
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(
                            color: PdfColors.blue900,
                            width: 2,
                          ),
                        ),
                      ),
                      child: pw.Text(
                        "Noman Khattak & Co",
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      title.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        if (entries.any((e) => e.siteName != null && e.siteName!.isNotEmpty))
                          pw.Text(
                            "Site: ${entries.firstWhere((e) => e.siteName != null && e.siteName!.isNotEmpty).siteName}",
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey800,
                            ),
                          )
                        else
                          pw.SizedBox(),
                        pw.Text(
                          "Report Date: ${_dateFormat.format(DateTime.now())}",
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 10),
                  ],
                ),
                pw.SizedBox(height: 10),
                if (isSingleVehicle && !isType2 && !isType3)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 8),
                    child: pw.Text(
                      "Vehicle Number: ${entries.first.vehicleNumber}",
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                  ),

                // Highlighted Summary Section
                if (isType1 || (!isType2 && !isType3))
                  pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue50,
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(8),
                      ),
                      border: pw.Border.all(color: PdfColors.blue200),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryBox(
                          "Total Earnings",
                          totalEarnings,
                          PdfColors.blue800,
                        ),
                        _buildSummaryBox(
                          "Total Expenses",
                          totalExpenses,
                          PdfColors.red800,
                        ),
                        _buildSummaryBox(
                          "Total Profit",
                          totalProfit,
                          totalProfit >= 0
                              ? PdfColors.green800
                              : PdfColors.red800,
                        ),
                      ],
                    ),
                  ),
                if (isType1 || (!isType2 && !isType3)) pw.SizedBox(height: 16),

                // Actual Data Table
                pw.TableHelper.fromTextArray(
                  headers: tableHeaders,
                  data: tableData,
                  border: pw.TableBorder.all(
                    color: PdfColors.grey300,
                    width: 0.5,
                  ),
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    fontSize: 10,
                  ),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.blue800,
                  ),
                  cellHeight: 24,
                  cellAlignments: alignments,
                  cellStyle: const pw.TextStyle(fontSize: 9),
                  rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
                  oddRowDecoration: const pw.BoxDecoration(
                    color: PdfColors.grey50,
                  ),
                ),
                if (isType2 || isType3) ...[
                  pw.SizedBox(height: 10),
                  pw.Container(
                    alignment: pw.Alignment.centerRight,
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.blue50,
                      border: pw.Border(
                        top: pw.BorderSide(color: PdfColors.blue800, width: 2),
                      ),
                    ),
                    child: pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        _buildFooterStat("TOTAL RATE", _currencyFormat.format(totalRates)),
                        pw.SizedBox(width: 20),
                        _buildFooterStat("TOTAL CFT/TON", totalTons.toString()),
                        pw.SizedBox(width: 20),
                        pw.Text(
                          "TOTAL AMOUNT: ",
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          _currencyFormat.format(totalEarnings),
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ];
            },
          ),
        );
        return pdf.save();
      },
      name: '${title.replaceAll(' ', '_')}.pdf',
    );
  }

  static pw.Widget _buildFooterStat(String label, String value) {
    return pw.Row(
      children: [
        pw.Text(
          "$label: ",
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue700),
        ),
      ],
    );
  }

  static pw.Widget _buildSummaryBox(
    String label,
    double amount,
    PdfColor color,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          _currencyFormat.format(amount),
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildRow(
    String label,
    String value, {
    bool isBold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                color: PdfColors.grey700,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              value,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
