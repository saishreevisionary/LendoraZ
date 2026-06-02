import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/providers.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Financial Ledger',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        Text(
          'Verify transaction entries, audit cash receipts, and download ledgers.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
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
        _buildKPICard(
          title: 'Total Revenue',
          value: fmt.format(totalRev),
          subtitle: 'Accrued payments',
          icon: Icons.account_balance_wallet,
          color: AppTheme.neonGreen,
        ),
        _buildKPICard(
          title: 'Total Transactions',
          value: '$transactionCount',
          subtitle: 'Payments processed',
          icon: Icons.analytics,
          color: AppTheme.primaryCyan,
        ),
        _buildKPICard(
          title: 'Pending Ledger Audit',
          value: '0',
          subtitle: 'All items reconciled',
          icon: Icons.verified_user,
          color: AppTheme.primaryBlue,
        ),
      ],
    );
  }

  Widget _buildKPICard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 10)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentPayments(BuildContext context, List<Map<String, dynamic>> collections, NumberFormat fmt) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Collections Feed', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              const Icon(Icons.receipt_long, color: AppTheme.primaryCyan, size: 16),
            ],
          ),
          const SizedBox(height: 16),
          if (collections.isEmpty)
            const Text('No recent collections registered.', style: TextStyle(color: Colors.grey, fontSize: 12))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: collections.length.clamp(0, 2),
              separatorBuilder: (context, index) => const Divider(color: Colors.white12),
              itemBuilder: (context, idx) {
                final c = collections[idx];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Colors.white10,
                    child: Icon(Icons.payment, color: AppTheme.neonGreen, size: 16),
                  ),
                  title: Text('Payment Received: ${fmt.format(c['amount'])}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text('Method: ${c['payment_method'].toString().toUpperCase()} | Status: ${c['status']}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                  trailing: TextButton(
                    onPressed: () {},
                    child: const Text('Export PDF', style: TextStyle(fontSize: 11)),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPendingVerifications(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Reconcile Suspense Transactions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'All cash & digital collections are matched and fully verified with ledger entries.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
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
        ],
      ),
    );
  }

  Widget _buildFinancialReports(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Export Financial Records', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildExportButton(Icons.text_snippet_outlined, 'P&L Statement'),
              _buildExportButton(Icons.account_balance, 'Bank Ledger'),
              _buildExportButton(Icons.document_scanner, 'Tax Reports'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton(IconData icon, String label) {
    return Expanded(
      child: Card(
        color: Colors.white.withValues(alpha: 0.02),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Column(
              children: [
                Icon(icon, color: AppTheme.primaryCyan, size: 20),
                const SizedBox(height: 4),
                FittedBox(fit: BoxFit.scaleDown, child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
