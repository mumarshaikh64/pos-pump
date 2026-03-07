import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/entry_model.dart';
import '../providers/entry_provider.dart';
import 'package:intl/intl.dart';
import 'add_entry_screen.dart';
import '../utils/pdf_exporter.dart';

class EntryDetailScreen extends StatelessWidget {
  final EntryModel entry;

  const EntryDetailScreen({super.key, required this.entry});

  void _deleteEntry(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Entry',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to delete this entry? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Provider.of<EntryProvider>(
                context,
                listen: false,
              ).deleteEntry(entry.id!);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final bool isProfit = entry.profit >= 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Light modern background
      appBar: AppBar(
        title: Text(entry.type == 1
            ? 'Trip Details'
            : entry.type == 2
                ? 'Load Details'
                : 'Supply Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Print to PDF',
            onPressed: () => PdfExporter.printEntry(entry),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Entry',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEntryScreen(entryToEdit: entry),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            tooltip: 'Delete Entry',
            onPressed: () => _deleteEntry(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          children: [
            // Vehicle Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: entry.type == 1
                          ? Colors.blue[50]
                          : Colors.purple[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      entry.type == 1
                          ? Icons.local_shipping_rounded
                          : entry.type == 2
                              ? Icons.monitor_weight_rounded
                              : Icons.inventory_2_rounded,
                      size: 40,
                      color: entry.type == 1
                          ? Colors.blueAccent
                          : entry.type == 2
                              ? Colors.purpleAccent
                              : Colors.tealAccent,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    entry.vehicleNumber,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat(
                      'EEEE, dd MMM yyyy • HH:mm a',
                    ).format(entry.date),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (entry.partyName != null && entry.partyName!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'MR/MRS: ${entry.partyName}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ],
                  if (entry.details.isNotEmpty && entry.type != 3) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.notes, color: Colors.grey[400], size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entry.details,
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (entry.type == 3) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildBadge(
                          label: 'Slip: ${entry.slipNumber ?? "-"}',
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        _buildBadge(
                          label: 'Material: ${entry.material ?? "-"}',
                          color: Colors.blue,
                        ),
                        if (entry.siteName != null && entry.siteName!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          _buildBadge(
                            label: 'Site: ${entry.siteName}',
                            color: Colors.purple,
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Financial Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildFinancialCard(
                    title: entry.type == 3 ? 'Total Amount' : 'Total Earnings',
                    amount: currencyFormat.format(entry.earnings),
                    icon: Icons.arrow_upward_rounded,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildFinancialCard(
                    title: 'Total Expenses',
                    amount: currencyFormat.format(entry.totalExpense),
                    icon: Icons.arrow_downward_rounded,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Detailed Breakdown
            _buildDetailedBreakdown(currencyFormat),

            const SizedBox(height: 20),

            // Final Profit Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isProfit
                      ? [const Color(0xFF10B981), const Color(0xFF059669)]
                      : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (isProfit ? Colors.green : Colors.red).withOpacity(
                      0.3,
                    ),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isProfit ? 'NET PROFIT' : 'NET LOSS',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currencyFormat.format(entry.profit.abs()),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isProfit ? Icons.verified_rounded : Icons.warning_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialCard({
    required String title,
    required String amount,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            amount,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedBreakdown(NumberFormat format) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Expenses Breakdown',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          _buildRow('Diesel Expense', format.format(entry.dieselExpense)),
          _buildRow(
            entry.type == 1 ? 'Autos Expense' : 'Other Expense',
            format.format(entry.otherExpense),
          ),

          if (entry.type != 1) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1),
            ),
            Text(
              entry.type == 2 ? 'Load Metrics' : 'Supply Metrics',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            _buildRow(
              entry.type == 3 ? 'Total CFT/TON' : 'Total Tons/CFT',
              '${entry.totalTon ?? 0}',
            ),
            _buildRow('Rate', format.format(entry.ratePerTon ?? 0)),
          ],
        ],
      ),
    );
  }

  Widget _buildBadge({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }
}
