import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/entry_provider.dart';
import 'package:intl/intl.dart';
import 'add_entry_screen.dart';
import 'entry_detail_screen.dart';
import '../utils/backup_service.dart';
import '../utils/google_drive_service.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.1),
        title: const Text('Dashboard'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.blueAccent),
            tooltip: 'Sign In to Google Drive',
            onPressed: () async {
              final success = await GoogleDriveService().signIn();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? 'Successfully connected to Google Drive!' : 'Failed to connect Google Drive.')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.cloud_upload_outlined, color: Colors.black87),
            tooltip: 'Backup to Google Drive',
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Starting backup to Google Drive...')),
              );
              await BackupService().autoBackup();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Backup process completed.')),
                );
              }
            },
          ),
        ],
      ),
      body: Consumer<EntryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent),
            );
          }

          final currencyFormat = NumberFormat.currency(
            symbol: '₹',
            decimalDigits: 0,
          );

          return RefreshIndicator(
            onRefresh: () async {
              await provider.loadEntries();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Net Profit',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currencyFormat.format(provider.totalProfit),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Earnings',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  currencyFormat.format(provider.totalEarnings),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Expenses',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  currencyFormat.format(
                                    provider.totalOverallExpense,
                                  ),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Quick Stats',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryCards(context, provider, currencyFormat),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Entries',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        label: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildRecentEntriesList(context, provider, currencyFormat),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEntryScreen()),
          );
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSummaryCards(
    BuildContext context,
    EntryProvider provider,
    NumberFormat format,
  ) {
    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.4,
      children: [
        _buildStatCard(
          context,
          'Total Entries',
          provider.totalEntries.toString(),
          Icons.list_alt_rounded,
          const Color(0xFF6366F1),
        ),
        _buildStatCard(
          context,
          'Total Diesel',
          format.format(provider.totalDieselExpense),
          Icons.local_gas_station_rounded,
          const Color(0xFFF59E0B),
        ),
        _buildStatCard(
          context,
          'Other Exp',
          format.format(provider.totalOtherExpenses),
          Icons.receipt_long_rounded,
          const Color(0xFFEF4444),
        ),
        _buildStatCard(
          context,
          'Avg Profit/Entry',
          provider.totalEntries > 0
              ? format.format(provider.totalProfit / provider.totalEntries)
              : '₹0',
          Icons.trending_up_rounded,
          const Color(0xFF10B981),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentEntriesList(
    BuildContext context,
    EntryProvider provider,
    NumberFormat format,
  ) {
    if (provider.entries.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Icon(Icons.inbox_rounded, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              'No entries yet',
              style: TextStyle(
                color: Colors.grey[500],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    final recentEntries = provider.entries.take(5).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: recentEntries.length,
        separatorBuilder: (context, index) =>
            Divider(height: 1, color: Colors.grey[100]),
        itemBuilder: (context, index) {
          final entry = recentEntries[index];
          final isProfit = entry.profit >= 0;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EntryDetailScreen(entry: entry),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: entry.type == 1
                            ? Colors.blue[50]
                            : Colors.purple[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        entry.type == 1
                            ? Icons.local_shipping_rounded
                            : Icons.monitor_weight_rounded,
                        color: entry.type == 1
                            ? Colors.blueAccent
                            : Colors.purpleAccent,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.vehicleNumber,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('dd MMM yyyy, HH:mm').format(entry.date),
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          format.format(entry.profit),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: isProfit
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            entry.type == 1 ? 'Trip' : 'Load',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
