import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/entry_provider.dart';
import '../models/entry_model.dart';
import '../utils/csv_exporter.dart';
import '../utils/pdf_exporter.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isExporting = false;
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _searchCtrl = TextEditingController();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: 'Rs. ',
    decimalDigits: 0,
  );

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.blueAccent),
          ),
          child: child!,
        );
      },
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (range != null) {
      setState(() {
        _startDate = range.start;
        _endDate = range.end;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _searchQuery = '';
      _searchCtrl.clear();
    });
  }

  Future<void> _exportData(
    BuildContext context,
    List<EntryModel> entries,
  ) async {
    setState(() => _isExporting = true);
    try {
      final path = await CsvExporter.exportToCsv(entries);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            content: Text(
              'Successfully exported!\nPath: $path',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            content: Text(
              'Export failed: $e',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9), // Light modern background
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          shadowColor: Colors.black.withOpacity(0.1),
          title: const Text('Reports'),
          centerTitle: false,
          actions: [
            Consumer<EntryProvider>(
              builder: (ctx, provider, _) {
                List<EntryModel> entriesToExport = _getFilteredEntries(
                  provider.entries,
                );
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Row(
                    children: [
                      Tooltip(
                        message: 'Print PDF Report',
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.picture_as_pdf, size: 20),
                          label: const Text(
                            'PDF',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onPressed: _isExporting || entriesToExport.isEmpty
                              ? null
                              : () async {
                                  // Determine current tab context
                                  final activeTab = DefaultTabController.of(
                                    ctx,
                                  ).index;
                                  final isTripReport = activeTab == 0;

                                  final filtered = entriesToExport
                                      .where(
                                        (e) => e.type == (isTripReport ? 1 : 2),
                                      )
                                      .toList();

                                  if (filtered.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'No entries in current tab to print',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  String title = isTripReport
                                      ? 'Trip Entries Report'
                                      : 'Load / Ton Reports';
                                  if (_searchQuery.isNotEmpty) {
                                    title += ' - Query: "$_searchQuery"';
                                  }
                                  if (_startDate != null) {
                                    title +=
                                        ' (${DateFormat('dd MMM').format(_startDate!)} to ${DateFormat('dd MMM').format(_endDate!)})';
                                  }

                                  await PdfExporter.printReportTable(
                                    filtered,
                                    title,
                                    isUnifiedMode: false,
                                  );
                                },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: 'Export CSV',
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: _isExporting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.file_download, size: 20),
                          label: const Text(
                            'CSV',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onPressed: _isExporting || entriesToExport.isEmpty
                              ? null
                              : () => _exportData(context, entriesToExport),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(140.0),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search Vehicle or Details...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                _buildDateFilterBar(),
                Container(
                  color: Colors.white,
                  child: const TabBar(
                    indicatorColor: Colors.blueAccent,
                    indicatorWeight: 3,
                    labelColor: Colors.blueAccent,
                    unselectedLabelColor: Colors.grey,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.local_shipping_outlined, size: 20),
                            SizedBox(width: 8),
                            Text('Trip Entries'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.monitor_weight_outlined, size: 20),
                            SizedBox(width: 8),
                            Text('Load / Ton Reports'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        body: Consumer<EntryProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.blueAccent),
              );
            }

            if (provider.entries.isEmpty) {
              return _buildEmptyState(
                'No entries labels available for reports.',
              );
            }

            List<EntryModel> filteredEntries = _getFilteredEntries(
              provider.entries,
            );

            return TabBarView(
              children: [
                _buildReportTable(filteredEntries, 1),
                _buildReportTable(filteredEntries, 2),
              ],
            );
          },
        ),
      ),
    );
  }

  List<EntryModel> _getFilteredEntries(List<EntryModel> allEntries) {
    List<EntryModel> results = allEntries;

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      results = results.where((e) {
        return e.vehicleNumber.toLowerCase().contains(query) ||
            e.details.toLowerCase().contains(query);
      }).toList();
    }

    if (_startDate != null && _endDate != null) {
      results = results.where((e) {
        final date = DateTime(e.date.year, e.date.month, e.date.day);
        return (date.isAtSameMomentAs(_startDate!) ||
                date.isAfter(_startDate!)) &&
            (date.isAtSameMomentAs(_endDate!) || date.isBefore(_endDate!));
      }).toList();
    }

    return results;
  }

  Widget _buildReportTable(List<EntryModel> entries, int type) {
    final filtered = entries.where((e) => e.type == type).toList();

    if (filtered.isEmpty) {
      return _buildEmptyState(
        'No ${type == 1 ? "Trip Entries" : "Load Reports"} found.',
      );
    }

    final isTrip = type == 1;

    // Summary Totals
    double totalExp = 0;
    double totalEarn = 0;
    double totalProf = 0;
    for (var e in filtered) {
      totalExp += e.totalExpense;
      totalEarn += e.earnings;
      totalProf += e.profit;
    }

    final isSingleVehicle = filtered.every(
      (e) => e.vehicleNumber == filtered.first.vehicleNumber,
    );
    final vehicleNum = isSingleVehicle ? filtered.first.vehicleNumber : null;

    return Column(
      children: [
        // Top Summary Bar
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          color: Colors.blue[50],
          child: Column(
            children: [
              if (vehicleNum != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.directions_car,
                        color: Colors.blue[800],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Vehicle: $vehicleNum',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildReportColumn(
                    'Expenses',
                    _currencyFormat.format(totalExp),
                    Colors.red[700]!,
                  ),
                  _buildReportColumn(
                    'Earnings',
                    _currencyFormat.format(totalEarn),
                    Colors.blue[700]!,
                  ),
                  _buildReportColumn(
                    'Profit',
                    _currencyFormat.format(totalProf),
                    totalProf >= 0 ? Colors.green[700]! : Colors.red[700]!,
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.grey[200]!),
              ),
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.resolveWith(
                      (states) => const Color(0xFFF8FAFC),
                    ),
                    columns: [
                      const DataColumn(label: Text('DATE')),
                      const DataColumn(label: Text('VEHICLE #')),
                      const DataColumn(label: Text('DETAILS')),
                      const DataColumn(label: Text('DIESEL'), numeric: true),
                      DataColumn(
                        label: Text(isTrip ? 'AUTOS EXP' : 'OTHER EXP'),
                        numeric: true,
                      ),
                      const DataColumn(label: Text('TOTAL EXP'), numeric: true),
                      if (!isTrip)
                        const DataColumn(
                          label: Text('RATE/TON'),
                          numeric: true,
                        ),
                      if (!isTrip)
                        const DataColumn(label: Text('TONS'), numeric: true),
                      const DataColumn(label: Text('EARNINGS'), numeric: true),
                      const DataColumn(label: Text('PROFIT')),
                    ],
                    rows: filtered.map((e) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(DateFormat('dd MMM yyyy').format(e.date)),
                          ),
                          DataCell(
                            Text(
                              e.vehicleNumber,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 120,
                              child: Text(
                                e.details,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(_currencyFormat.format(e.dieselExpense)),
                          ),
                          DataCell(
                            Text(_currencyFormat.format(e.otherExpense)),
                          ),
                          DataCell(
                            Text(
                              _currencyFormat.format(e.totalExpense),
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                          if (!isTrip)
                            DataCell(
                              Text(_currencyFormat.format(e.ratePerTon ?? 0)),
                            ),
                          if (!isTrip)
                            DataCell(Text((e.totalTon ?? 0).toString())),
                          DataCell(
                            Text(
                              _currencyFormat.format(e.earnings),
                              style: const TextStyle(color: Colors.teal),
                            ),
                          ),
                          DataCell(
                            Text(
                              _currencyFormat.format(e.profit),
                              style: TextStyle(
                                color: e.profit >= 0
                                    ? Colors.green[700]
                                    : Colors.red[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.filter_alt_outlined,
                color: Colors.grey[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _startDate == null
                    ? 'All Time'
                    : '${DateFormat('MMM dd').format(_startDate!)} - ${DateFormat('MMM dd').format(_endDate!)}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _startDate == null
                      ? Colors.grey[700]
                      : Colors.blueAccent,
                ),
              ),
            ],
          ),
          Row(
            children: [
              TextButton.icon(
                icon: Icon(
                  Icons.calendar_month,
                  color: _startDate != null
                      ? Colors.blueAccent
                      : Colors.grey[700],
                  size: 18,
                ),
                label: Text(
                  'Filter Date',
                  style: TextStyle(
                    color: _startDate != null
                        ? Colors.blueAccent
                        : Colors.grey[700],
                  ),
                ),
                onPressed: _pickDateRange,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  backgroundColor: _startDate != null
                      ? Colors.blue[50]
                      : Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              if (_startDate != null || _searchQuery.isNotEmpty) ...[
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.refresh, color: Colors.red, size: 18),
                  label: const Text(
                    'Reset',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    backgroundColor: Colors.red[50],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pie_chart_outline_rounded,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportColumn(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
      ],
    );
  }
}

class VehicleSummary {
  double totalExpense = 0;
  double totalEarnings = 0;
  double totalProfit = 0;
  int entryCount = 0;
}

class MonthlySummary {
  double totalExpense = 0;
  double totalEarnings = 0;
  double totalProfit = 0;
  int entryCount = 0;
}
