import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/entry_provider.dart';
import '../models/entry_model.dart';
import '../utils/pdf_exporter.dart';

class EntryRowControllers {
  DateTime date = DateTime.now();
  final vehicleCtrl = TextEditingController();
  final detailsCtrl = TextEditingController();
  final dieselCtrl = TextEditingController();
  final otherExpCtrl = TextEditingController();
  final earningsCtrl = TextEditingController();
  final rateCtrl = TextEditingController();
  final tonsCtrl = TextEditingController();
  final slipCtrl = TextEditingController();
  final materialCtrl = TextEditingController();
  
  // Computed values
  double get totalExpense => (double.tryParse(dieselCtrl.text) ?? 0) + (double.tryParse(otherExpCtrl.text) ?? 0);
  double get calculatedEarnings => (double.tryParse(rateCtrl.text) ?? 0) * (double.tryParse(tonsCtrl.text) ?? 0);
  double get tripEarnings => double.tryParse(earningsCtrl.text) ?? 0;

  void dispose() {
    vehicleCtrl.dispose();
    detailsCtrl.dispose();
    dieselCtrl.dispose();
    otherExpCtrl.dispose();
    earningsCtrl.dispose();
    rateCtrl.dispose();
    tonsCtrl.dispose();
    slipCtrl.dispose();
    materialCtrl.dispose();
  }
}

class BatchAddEntriesScreen extends StatefulWidget {
  const BatchAddEntriesScreen({super.key});

  @override
  State<BatchAddEntriesScreen> createState() => _BatchAddEntriesScreenState();
}

class _BatchAddEntriesScreenState extends State<BatchAddEntriesScreen> {
  final _personNameCtrl = TextEditingController();
  final _siteNameCtrl = TextEditingController();
  int _entryType = 1; // 1 = Trip Entry, 2 = Load / Ton Report, 3 = Supply
  List<EntryRowControllers> _rows = [];

  @override
  void initState() {
    super.initState();
    // Initialize with 100 empty rows
    for (int i = 0; i < 100; i++) {
      _rows.add(EntryRowControllers()..date = DateTime.now());
    }
  }

  @override
  void dispose() {
    _personNameCtrl.dispose();
    _siteNameCtrl.dispose();
    for (var row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  void _removeRow(int index) {
    if (_rows.length > 1) {
      setState(() {
        _rows[index].dispose();
        _rows.removeAt(index);
      });
    }
  }

  Future<void> _pickDate(int index) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _rows[index].date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() => _rows[index].date = date);
    }
  }

  List<EntryModel> _getValidatedEntries({String? batchId}) {
    final entries = <EntryModel>[];
    final personName = _personNameCtrl.text.trim();
    final siteName = _siteNameCtrl.text.trim();

    for (var row in _rows) {
      final vNum = row.vehicleCtrl.text.trim();
      // Skip empty rows
      if (vNum.isEmpty &&
          row.dieselCtrl.text.isEmpty &&
          row.otherExpCtrl.text.isEmpty &&
          row.earningsCtrl.text.isEmpty &&
          row.detailsCtrl.text.isEmpty &&
          row.slipCtrl.text.isEmpty) {
        continue;
      }

      double diesel = double.tryParse(row.dieselCtrl.text) ?? 0;
      double other = double.tryParse(row.otherExpCtrl.text) ?? 0;
      double totalExpense = diesel + other;
      double earnings = 0;
      double? ratePerTon;
      double? totalTon;

      if (_entryType == 1) {
        earnings = double.tryParse(row.earningsCtrl.text) ?? 0;
      } else {
        ratePerTon = double.tryParse(row.rateCtrl.text) ?? 0;
        totalTon = double.tryParse(row.tonsCtrl.text) ?? 0;
        earnings = ratePerTon * totalTon;
      }

      double profit = earnings - totalExpense;

      String finalDetails = row.detailsCtrl.text.trim();
      if (personName.isNotEmpty) {
        finalDetails = finalDetails.isEmpty
            ? 'Party: $personName'
            : 'Party: $personName | $finalDetails';
      }

      entries.add(
        EntryModel(
          type: _entryType,
          date: row.date,
          details: finalDetails,
          vehicleNumber: vNum.isEmpty ? 'N/A' : vNum,
          dieselExpense: diesel,
          otherExpense: other,
          totalExpense: totalExpense,
          earnings: earnings,
          ratePerTon: ratePerTon,
          totalTon: totalTon,
          profit: profit,
          slipNumber: _entryType == 3 ? row.slipCtrl.text.trim() : null,
          material: _entryType == 3 ? row.materialCtrl.text.trim() : null,
          partyName: personName.isNotEmpty ? personName : null,
          siteName: _entryType == 3 && siteName.isNotEmpty ? siteName : null,
          batchId: batchId,
        ),
      );
    }
    return entries;
  }

  void _saveAll({bool thenPrint = false}) async {
    final String? batchId = _rows.where((r) => r.vehicleCtrl.text.isNotEmpty).length > 1 
        ? "BATCH_${DateTime.now().millisecondsSinceEpoch}" 
        : null;

    final entries = _getValidatedEntries(batchId: batchId);
    if (entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No valid entries to save.')),
      );
      return;
    }

    final provider = Provider.of<EntryProvider>(context, listen: false);
    for (var entry in entries) {
      await provider.addEntry(entry);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully saved ${entries.length} entries!')),
      );
      
      if (thenPrint) {
        String title = _personNameCtrl.text.trim().isNotEmpty 
            ? _personNameCtrl.text.trim()
            : "Transport Report";
        await PdfExporter.printReportTable(entries, title);
      }
      
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Batch Add Entries'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          _buildTopHeader(),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTableHeader(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _rows.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _rows.length) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24.0),
                            child: Center(
                              child: TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    for (int i = 0; i < 50; i++) {
                                      _rows.add(EntryRowControllers()..date = DateTime.now());
                                    }
                                  });
                                },
                                icon: const Icon(Icons.add_circle_outline),
                                label: const Text('Add 50 More Rows'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.blueAccent,
                                ),
                              ),
                            ),
                          );
                        }
                        return _buildTableRow(index);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: _personNameCtrl,
              decoration: InputDecoration(
                labelText: 'Person / Party Name',
                prefixIcon: const Icon(Icons.person_outline),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (_entryType == 3) ...[
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _siteNameCtrl,
                decoration: InputDecoration(
                  labelText: 'Site Name',
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(width: 24),
          Expanded(
            flex: 3,
            child: SegmentedButton<int>(
              style: SegmentedButton.styleFrom(
                backgroundColor: Colors.grey[50],
                selectedBackgroundColor: Colors.blue[50],
                selectedForegroundColor: Colors.blueAccent,
              ),
              segments: const [
                ButtonSegment(
                  value: 1,
                  label: Text('Trip Entries', style: TextStyle(fontWeight: FontWeight.bold)),
                  icon: Icon(Icons.local_shipping_outlined),
                ),
                ButtonSegment(
                  value: 2,
                  label: Text('Load/Ton', style: TextStyle(fontWeight: FontWeight.bold)),
                  icon: Icon(Icons.monitor_weight_outlined),
                ),
                ButtonSegment(
                  value: 3,
                  label: Text('Supply', style: TextStyle(fontWeight: FontWeight.bold)),
                  icon: Icon(Icons.inventory_2_outlined),
                ),
              ],
              selected: {_entryType},
              onSelectionChanged: (Set<int> newSelection) {
                setState(() {
                  _entryType = newSelection.first;
                });
              },
            ),
          ),
          const SizedBox(width: 24),
          ElevatedButton.icon(
            onPressed: () => _saveAll(thenPrint: true),
            icon: const Icon(Icons.print_rounded),
            label: const Text('Save & Print Sheet', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const SizedBox(width: 40), // Index & Date picker space
          _headerCell('DATE', flex: 2),
          _headerCell('VEHICLE #', flex: 2),
          if (_entryType == 1) ...[
            _headerCell('DETAILS', flex: 2),
            _headerCell('DIESEL', flex: 2),
            _headerCell('AUTOS', flex: 2),
            _headerCell('TOTAL EXP', flex: 2, isHighlight: true),
            _headerCell('EARNINGS', flex: 2),
            _headerCell('PROFIT', flex: 2, isHighlight: true),
          ] else if (_entryType == 2) ...[
             _headerCell('DETAILS', flex: 2),
             _headerCell('DIESEL', flex: 2),
             _headerCell('OTHER', flex: 2),
             _headerCell('TOTAL EXP', flex: 2, isHighlight: true),
             _headerCell('RATE/TON', flex: 2),
             _headerCell('TONS', flex: 2),
             _headerCell('EARNINGS', flex: 2, isHighlight: true),
             _headerCell('PROFIT', flex: 2, isHighlight: true),
          ] else ...[
             _headerCell('SLIP NO', flex: 2),
             _headerCell('MATERIAL', flex: 2),
             _headerCell('RATE', flex: 2),
             _headerCell('CFT/TON', flex: 2),
             _headerCell('AMOUNT', flex: 2, isHighlight: true),
          ],
          const SizedBox(width: 40), // Remove button space
        ],
      ),
    );
  }

  Widget _headerCell(String label, {required int flex, bool isHighlight = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: TextStyle(
          fontWeight: isHighlight ? FontWeight.w900 : FontWeight.bold, 
          color: isHighlight ? Colors.blue[900] : const Color(0xFF334155), 
          fontSize: isHighlight ? 12 : 11
        ),
      ),
    );
  }

  Widget _buildTableRow(int index) {
    final row = _rows[index];
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        color: index % 2 == 1 ? const Color(0xFFF8FAFC).withOpacity(0.5) : Colors.white,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text('${index + 1}', style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: () => _pickDate(index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.grey[50],
                ),
                child: Text(DateFormat('dd MMM yy').format(row.date)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _cellField(row.vehicleCtrl, flex: 2),
          const SizedBox(width: 8),
          if (_entryType == 1) ...[
            _cellField(row.detailsCtrl, flex: 2),
            const SizedBox(width: 8),
            _cellField(row.dieselCtrl, flex: 2, isNumber: true),
            const SizedBox(width: 8),
            _cellField(row.otherExpCtrl, flex: 2, isNumber: true),
            const SizedBox(width: 8),
            _computedCell(row.totalExpense, flex: 2, color: Colors.red[700]!),
            const SizedBox(width: 8),
            _cellField(row.earningsCtrl, flex: 2, isNumber: true),
            const SizedBox(width: 8),
            _computedCell(row.tripEarnings - row.totalExpense, flex: 2, 
                color: (row.tripEarnings - row.totalExpense) >= 0 ? Colors.green[700]! : Colors.red[700]!),
          ] else if (_entryType == 2) ...[
            _cellField(row.detailsCtrl, flex: 2),
             const SizedBox(width: 8),
            _cellField(row.dieselCtrl, flex: 2, isNumber: true),
            const SizedBox(width: 8),
            _cellField(row.otherExpCtrl, flex: 2, isNumber: true),
            const SizedBox(width: 8),
            _computedCell(row.totalExpense, flex: 2, color: Colors.red[700]!),
            const SizedBox(width: 8),
            _cellField(row.rateCtrl, flex: 2, isNumber: true),
            const SizedBox(width: 8),
            _cellField(row.tonsCtrl, flex: 2, isNumber: true),
            const SizedBox(width: 8),
            _computedCell(row.calculatedEarnings, flex: 2, color: Colors.teal[700]!),
            const SizedBox(width: 8),
            _computedCell(row.calculatedEarnings - row.totalExpense, flex: 2, 
                color: (row.calculatedEarnings - row.totalExpense) >= 0 ? Colors.green[700]! : Colors.red[700]!),
          ] else ...[
            _cellField(row.slipCtrl, flex: 2),
            const SizedBox(width: 8),
            _cellField(row.materialCtrl, flex: 2),
            const SizedBox(width: 8),
            _cellField(row.rateCtrl, flex: 2, isNumber: true),
            const SizedBox(width: 8),
            _cellField(row.tonsCtrl, flex: 2, isNumber: true),
            const SizedBox(width: 8),
            _computedCell(row.calculatedEarnings, flex: 2, color: Colors.teal[700]!),
          ],
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
            onPressed: () => _removeRow(index),
            tooltip: 'Remove Row',
          ),
        ],
      ),
    );
  }

  Widget _cellField(TextEditingController ctrl, {required int flex, bool isNumber = false}) {
    return Expanded(
      flex: flex,
      child: TextField(
        controller: ctrl,
        keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        onChanged: (v) {
          // Rebuild to update computed values (Total Expense, Profit, etc)
          setState(() {});
        },
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Colors.blueAccent),
          ),
        ),
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  Widget _computedCell(double value, {required int flex, required Color color}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        alignment: Alignment.centerRight,
        child: Text(
          value == 0 ? '-' : NumberFormat.currency(symbol: '₹', decimalDigits: 0).format(value),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
