import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/entry_provider.dart';
import '../models/entry_model.dart';
import 'package:intl/intl.dart';

class AddEntryScreen extends StatefulWidget {
  final EntryModel? entryToEdit;

  const AddEntryScreen({super.key, this.entryToEdit});

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  int _entryType = 1; // 1 = Trip Entry, 2 = Load / Ton Report
  DateTime _selectedDate = DateTime.now();

  // Controllers
  final _detailsCtrl = TextEditingController();
  final _vehicleCtrl = TextEditingController();
  final _dieselCtrl = TextEditingController();
  final _otherExpenseCtrl =
      TextEditingController(); // Autos for Type 1, Other for Type 2
  final _earningsCtrl = TextEditingController(); // Manual for Type 1
  final _ratePerTonCtrl = TextEditingController();
  final _totalTonCtrl = TextEditingController();
  final _slipCtrl = TextEditingController();
  final _materialCtrl = TextEditingController();

  // Calculated values
  double _totalExpense = 0;
  double _totalEarnings = 0;
  double _finalProfit = 0;

  @override
  void initState() {
    super.initState();
    if (widget.entryToEdit != null) {
      final e = widget.entryToEdit!;
      _entryType = e.type;
      _selectedDate = e.date;
      _detailsCtrl.text = e.details;
      _vehicleCtrl.text = e.vehicleNumber;
      _dieselCtrl.text = e.dieselExpense.toString();
      _otherExpenseCtrl.text = e.otherExpense.toString();
      _earningsCtrl.text = e.earnings.toString();
      _ratePerTonCtrl.text = e.ratePerTon?.toString() ?? '';
      _totalTonCtrl.text = e.totalTon?.toString() ?? '';
      _slipCtrl.text = e.slipNumber ?? '';
      _materialCtrl.text = e.material ?? '';
      _calculateTotals();
    }
  }

  @override
  void dispose() {
    _detailsCtrl.dispose();
    _vehicleCtrl.dispose();
    _dieselCtrl.dispose();
    _otherExpenseCtrl.dispose();
    _earningsCtrl.dispose();
    _ratePerTonCtrl.dispose();
    _totalTonCtrl.dispose();
    _slipCtrl.dispose();
    _materialCtrl.dispose();
    super.dispose();
  }

  void _calculateTotals() {
    double diesel = double.tryParse(_dieselCtrl.text) ?? 0;
    double other = double.tryParse(_otherExpenseCtrl.text) ?? 0;

    _totalExpense = diesel + other;

    if (_entryType == 1) {
      _totalEarnings = double.tryParse(_earningsCtrl.text) ?? 0;
    } else {
      double rate = double.tryParse(_ratePerTonCtrl.text) ?? 0;
      double tons = double.tryParse(_totalTonCtrl.text) ?? 0;
      _totalEarnings = rate * tons;
    }

    _finalProfit = _totalEarnings - _totalExpense;
    setState(() {});
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
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
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  void _saveEntry() {
    if (_formKey.currentState!.validate()) {
      _calculateTotals(); // Ensure latest calculation

      final entry = EntryModel(
        id: widget.entryToEdit?.id,
        type: _entryType,
        date: _selectedDate,
        details: _detailsCtrl.text.trim(),
        vehicleNumber: _vehicleCtrl.text.trim(),
        dieselExpense: double.tryParse(_dieselCtrl.text) ?? 0,
        otherExpense: double.tryParse(_otherExpenseCtrl.text) ?? 0,
        totalExpense: _totalExpense,
        earnings: _totalEarnings,
        ratePerTon: _entryType != 1
            ? double.tryParse(_ratePerTonCtrl.text)
            : null,
        totalTon: _entryType != 1 ? double.tryParse(_totalTonCtrl.text) : null,
        profit: _finalProfit,
        slipNumber: _entryType == 3 ? _slipCtrl.text.trim() : null,
        material: _entryType == 3 ? _materialCtrl.text.trim() : null,
      );

      final provider = Provider.of<EntryProvider>(context, listen: false);
      if (widget.entryToEdit == null) {
        provider.addEntry(entry);
      } else {
        provider.updateEntry(entry);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Light modern background
      appBar: AppBar(
        title: Text(widget.entryToEdit == null ? 'Add Entry' : 'Edit Entry'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SegmentedButton<int>(
                style: SegmentedButton.styleFrom(
                  backgroundColor: Colors.white,
                  selectedBackgroundColor: Colors.blue[50],
                  selectedForegroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(8),
                ),
                segments: const [
                  ButtonSegment(
                    value: 1,
                    label: Text(
                      'Trip Entry',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    icon: Icon(Icons.local_shipping_outlined),
                  ),
                  ButtonSegment(
                    value: 2,
                    label: Text(
                      'Load/Ton',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    icon: Icon(Icons.monitor_weight_outlined),
                  ),
                  ButtonSegment(
                    value: 3,
                    label: Text(
                      'Supply',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    icon: Icon(Icons.inventory_2_outlined),
                  ),
                ],
                selected: {_entryType},
                onSelectionChanged: (Set<int> newSelection) {
                  setState(() {
                    _entryType = newSelection.first;
                    _calculateTotals();
                  });
                },
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionContainer(
              title: 'Primary Details',
              icon: Icons.info_outline,
              child: Column(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat(
                                    'dd MMM yyyy',
                                  ).format(_selectedDate),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                            Icon(Icons.calendar_month, color: Colors.blue[400]),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _vehicleCtrl,
                    label: 'Vehicle Number',
                    icon: Icons.directions_car_outlined,
                  ),
                  const SizedBox(height: 16),
                  if (_entryType == 3) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _slipCtrl,
                            label: 'Slip Number',
                            icon: Icons.confirmation_number_outlined,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller: _materialCtrl,
                            label: 'Material',
                            icon: Icons.category_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_entryType != 3)
                    _buildTextField(
                      controller: _detailsCtrl,
                      label: 'Details (Optional)',
                      icon: Icons.notes,
                      maxLines: 2,
                      isRequired: false,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionContainer(
              title: 'Expenses',
              icon: Icons.money_off_csred_outlined,
              iconColor: Colors.red,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _dieselCtrl,
                          label: 'Diesel Expense',
                          icon: Icons.local_gas_station_outlined,
                          isNumber: true,
                          onChanged: (_) => _calculateTotals(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _otherExpenseCtrl,
                          label: _entryType == 1 ? 'Autos Exp.' : 'Other Exp.',
                          icon: Icons.receipt_long_outlined,
                          isNumber: true,
                          onChanged: (_) => _calculateTotals(),
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Divider(height: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Expense:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        '₹${_totalExpense.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Colors.red,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionContainer(
              title: 'Earnings',
              icon: Icons.payments_outlined,
              iconColor: Colors.teal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_entryType == 1) ...[
                    _buildTextField(
                      controller: _earningsCtrl,
                      label: 'Trip Earnings',
                      icon: Icons.attach_money,
                      isNumber: true,
                      onChanged: (_) => _calculateTotals(),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _ratePerTonCtrl,
                            label: 'Rate Per Ton',
                            icon: Icons.price_change_outlined,
                            isNumber: true,
                            onChanged: (_) => _calculateTotals(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller: _totalTonCtrl,
                            label: _entryType == 3 ? 'Total CFT/TON' : 'Total Ton/CFT',
                            icon: Icons.scale_outlined,
                            isNumber: true,
                            onChanged: (_) => _calculateTotals(),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Divider(height: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Earnings:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        '₹${_totalEarnings.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Colors.teal,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: _finalProfit >= 0
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: (_finalProfit >= 0 ? Colors.green : Colors.red)
                        .withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Final Profit / Balance',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '₹${_finalProfit.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _saveEntry,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: Colors.blue.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                widget.entryToEdit == null ? 'SAVE ENTRY' : 'UPDATE ENTRY',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionContainer({
    required String title,
    required IconData icon,
    Color? iconColor,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(icon, color: iconColor ?? Colors.blueAccent, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(16.0), child: child),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isNumber = false,
    bool isRequired = true,
    int maxLines = 1,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      maxLines: maxLines,
      onChanged: onChanged,
      validator: isRequired
          ? (val) => val == null || val.isEmpty ? 'Required' : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600]),
        prefixIcon: Icon(icon, color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        ),
      ),
    );
  }
}
