import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/providers.dart';
import '../../../core/widgets/kpi_card.dart';
import '../../../core/widgets/dashboard_section.dart';

class AccountantDashboard extends ConsumerWidget {
  const AccountantDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(supabaseServiceProvider);
    final NumberFormat currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    // Fetch payments/ledger stats
    final collections = service.getCollections();
    double totalRevenue = 0.0;
    for (var c in collections) {
      if (c['status'] == 'success') {
        totalRevenue += (c['amount'] as double);
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 20),
          _buildMetricsGrid(context, totalRevenue, collections.length, currencyFormat),
          const SizedBox(height: 24),
          _buildRecentPayments(context, collections, currencyFormat),
          const SizedBox(height: 24),
          _buildPendingVerifications(context),
          const SizedBox(height: 24),
          _buildFinancialReports(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Financial Ledger',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        Text(
          'Verify transaction entries, audit cash receipts, and download ledgers.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isDark ? Colors.grey : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsGrid(BuildContext context, double totalRev, int transactionCount, NumberFormat fmt) {
    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 1,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: MediaQuery.of(context).size.width > 600 ? 1.6 : 3.2,
      children: [
        KpiCard(
          title: 'Total Revenue',
          value: fmt.format(totalRev),
          subtitle: 'Accrued payments',
          icon: Icons.account_balance_wallet,
          color: AppTheme.neonGreen,
        ),
        KpiCard(
          title: 'Total Transactions',
          value: '$transactionCount',
          subtitle: 'Payments processed',
          icon: Icons.analytics,
          color: AppTheme.primaryCyan,
        ),
        KpiCard(
          title: 'Pending Ledger Audit',
          value: '0',
          subtitle: 'All items reconciled',
          icon: Icons.verified_user,
          color: AppTheme.primaryBlue,
        ),
      ],
    );
  }

  Widget _buildRecentPayments(BuildContext context, List<Map<String, dynamic>> collections, NumberFormat fmt) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DashboardSectionCard(
      title: 'Recent Collections Feed',
      action: const Icon(Icons.receipt_long, color: AppTheme.primaryCyan, size: 16),
      padding: const EdgeInsets.all(20),
      child: collections.isEmpty
          ? Text('No recent collections registered.', style: TextStyle(color: isDark ? Colors.grey : const Color(0xFF64748B), fontSize: 12))
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: collections.length.clamp(0, 2),
              separatorBuilder: (context, index) => Divider(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
              itemBuilder: (context, idx) {
                final c = collections[idx];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Colors.white10,
                    child: Icon(Icons.payment, color: AppTheme.neonGreen, size: 16),
                  ),
                  title: Text(
                    'Payment Received: ${fmt.format(c['amount'])}',
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Text(
                    'Method: ${c['payment_method'].toString().toUpperCase()} | Status: ${c['status']}',
                    style: TextStyle(
                      color: isDark ? Colors.grey : const Color(0xFF64748B),
                      fontSize: 10,
                    ),
                  ),
                  trailing: TextButton(
                    onPressed: () {},
                    child: const Text('Export PDF', style: TextStyle(fontSize: 11)),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildPendingVerifications(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DashboardSectionCard(
      title: 'Reconcile Suspense Transactions',
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'All cash & digital collections are matched and fully verified with ledger entries.',
              style: TextStyle(
                color: isDark ? Colors.grey : const Color(0xFF64748B),
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppTheme.neonGreen.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: const Text('100% RECONCILED', style: TextStyle(color: AppTheme.neonGreen, fontSize: 8, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialReports(BuildContext context) {
    return DashboardSectionCard(
      title: 'Export Financial Records',
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildExportButton(context, Icons.text_snippet_outlined, 'P&L Statement'),
          _buildExportButton(context, Icons.account_balance, 'Bank Ledger'),
          _buildExportButton(context, Icons.document_scanner, 'Tax Reports'),
        ],
      ),
    );
  }

  Widget _buildExportButton(BuildContext context, IconData icon, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Card(
        color: isDark ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFF8FAFC),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE2E8F0)),
        ),
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Column(
              children: [
                Icon(icon, color: AppTheme.primaryCyan, size: 20),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
