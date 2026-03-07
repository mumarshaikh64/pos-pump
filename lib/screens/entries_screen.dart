import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/entry_provider.dart';
import '../models/entry_model.dart';
import 'package:intl/intl.dart';
import 'entry_detail_screen.dart';
import '../utils/pdf_exporter.dart';
import 'batch_add_entries_screen.dart';

class EntriesScreen extends StatefulWidget {
  const EntriesScreen({super.key});

  @override
  State<EntriesScreen> createState() => _EntriesScreenState();
}

class _EntriesScreenState extends State<EntriesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    Provider.of<EntryProvider>(context, listen: false).searchEntries(query);
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
      Provider.of<EntryProvider>(
        context,
        listen: false,
      ).applyDateFilter(range.start, range.end);
    }
  }

  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _searchCtrl.clear();
    });
    Provider.of<EntryProvider>(context, listen: false).loadEntries();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(
          0xFFF1F5F9,
        ), // Light background for contrast
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          shadowColor: Colors.black.withOpacity(0.1),
          centerTitle: false,
          title: const Text(
            'All Entries',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(135),
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
                      onChanged: _onSearchChanged,
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
                _buildFilterBar(),
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

            return TabBarView(
              children: [
                _buildEntriesTable(provider.entries, 1, context),
                _buildEntriesTable(provider.entries, 2, context),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BatchAddEntriesScreen()),
            );
          },
          backgroundColor: Colors.blueAccent,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Add Entry (Sheet)',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          elevation: 4,
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
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
              if (_startDate != null || _searchCtrl.text.isNotEmpty) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: _clearFilters,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.clear, color: Colors.red, size: 18),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEntriesTable(
    List<EntryModel> entries,
    int type,
    BuildContext context,
  ) {
    final filtered = entries.where((e) => e.type == type).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No ${type == 1 ? "Trip Entries" : "Load Reports"} found.',
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

    final isTrip = type == 1;

    return Padding(
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
              dataRowColor: WidgetStateProperty.resolveWith(
                (states) => Colors.white,
              ),
              headingTextStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF334155),
                fontSize: 13,
              ),
              dataTextStyle: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              dividerThickness: 1,
              horizontalMargin: 20,
              columnSpacing: 28,
              columns: [
                const DataColumn(label: Text('DATE')),
                const DataColumn(label: Text('VEHICLE #')),
                const DataColumn(label: Text('DETAILS')),
                const DataColumn(label: Text('DIESEL'), numeric: true),
                DataColumn(
                  label: Text(isTrip ? 'AUTOS EXP' : 'OTHER EXP'),
                  numeric: true,
                ),
                const DataColumn(
                  label: Text('TOTAL EXP', style: TextStyle(color: Colors.red)),
                  numeric: true,
                ),
                if (!isTrip)
                  const DataColumn(label: Text('RATE/TON'), numeric: true),
                if (!isTrip)
                  const DataColumn(label: Text('TONS'), numeric: true),
                const DataColumn(
                  label: Text('EARNINGS', style: TextStyle(color: Colors.teal)),
                  numeric: true,
                ),
                const DataColumn(label: Text('PROFIT')),
                const DataColumn(label: Text('ACTIONS')),
              ],
              rows: List<DataRow>.generate(filtered.length, (index) {
                final entry = filtered[index];
                return _buildDataRow(entry, context, isTrip, index);
              }),
            ),
          ),
        ),
      ),
    );
  }

  DataRow _buildDataRow(
    EntryModel entry,
    BuildContext context,
    bool isTrip,
    int index,
  ) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final isStripe = index % 2 == 1;

    return DataRow(
      color: WidgetStateProperty.resolveWith(
        (states) =>
            isStripe ? const Color(0xFFF8FAFC).withOpacity(0.6) : Colors.white,
      ),
      cells: [
        DataCell(
          Text(
            DateFormat('dd MMM yyyy').format(entry.date),
            style: const TextStyle(color: Colors.black87),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.blue[100]!),
            ),
            child: Text(
              entry.vehicleNumber,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 140,
            child: Text(
              entry.details.isNotEmpty ? entry.details : '-',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey[600],
                fontStyle: entry.details.isEmpty
                    ? FontStyle.italic
                    : FontStyle.normal,
              ),
            ),
          ),
        ),
        DataCell(Text(currencyFormat.format(entry.dieselExpense))),
        DataCell(Text(currencyFormat.format(entry.otherExpense))),
        DataCell(
          Text(
            currencyFormat.format(entry.totalExpense),
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (!isTrip)
          DataCell(
            Text(
              entry.ratePerTon != null
                  ? currencyFormat.format(entry.ratePerTon)
                  : '-',
            ),
          ),
        if (!isTrip)
          DataCell(
            Text(entry.totalTon != null ? entry.totalTon.toString() : '-'),
          ),
        DataCell(
          Text(
            currencyFormat.format(entry.earnings),
            style: const TextStyle(
              color: Colors.teal,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: entry.profit >= 0 ? Colors.green[50] : Colors.red[50],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: entry.profit >= 0
                    ? Colors.green[200]!
                    : Colors.red[200]!,
              ),
            ),
            child: Text(
              currencyFormat.format(entry.profit),
              style: TextStyle(
                color: entry.profit >= 0 ? Colors.green[700] : Colors.red[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.remove_red_eye_outlined,
                  color: Colors.blueAccent,
                  size: 20,
                ),
                tooltip: 'View Details',
                splashRadius: 24,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EntryDetailScreen(entry: entry),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.print_outlined,
                  color: Colors.grey,
                  size: 20,
                ),
                tooltip: 'Print',
                splashRadius: 24,
                onPressed: () {
                  PdfExporter.printEntry(entry);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
