import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/supabase_service.dart';
import '../../../core/network/providers.dart';

class ManagerDashboard extends ConsumerWidget {
  const ManagerDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(supabaseServiceProvider);
    final NumberFormat currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    // Fetch operational stats
    final alerts = service.getAlerts().where((a) => a['status'] == 'active').toList();
    final leads = service.getLeads().where((l) => l['status'] == 'new_lead').toList();
    final collections = service.getCollections();
    
    double todayCollected = 0.0;
    for (var c in collections) {
      if (c['collection_date'].toString().startsWith(DateTime.now().toIso8601String().substring(0, 10))) {
        todayCollected += (c['amount'] as double);
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 20),
          _buildMetricsGrid(context, todayCollected, alerts.length, leads.length, currencyFormat),
          const SizedBox(height: 24),
          _buildActiveAlerts(context, alerts, service),
          const SizedBox(height: 24),
          _buildAgentActivities(context),
          const SizedBox(height: 24),
          _buildLeadsPanel(context, leads),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Operations Center',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        Text(
          'Track field agents, review overdue payments, and process new leads.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildMetricsGrid(BuildContext context, double collectedToday, int alertCount, int leadCount, NumberFormat fmt) {
    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 1,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: MediaQuery.of(context).size.width > 600 ? 1.6 : 3.0,
      children: [
        _buildKPICard(
          title: 'Today\'s Collections',
          value: fmt.format(collectedToday),
          subtitle: 'Expected: ₹45,000',
          icon: Icons.payments,
          color: AppTheme.neonGreen,
        ),
        _buildKPICard(
          title: 'Risk Alerts',
          value: '$alertCount',
          subtitle: 'High-risk accounts active',
          icon: Icons.warning_amber_rounded,
          color: AppTheme.dangerRed,
        ),
        _buildKPICard(
          title: 'New Leads',
          value: '$leadCount',
          subtitle: 'Unassigned prospects',
          icon: Icons.contact_page_outlined,
          color: AppTheme.primaryCyan,
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
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 10)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveAlerts(BuildContext context, List<Map<String, dynamic>> alerts, SupabaseService service) {
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
              const Text('Active Overdue Risk Alerts', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppTheme.dangerRed.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                child: Text('${alerts.length} Active', style: const TextStyle(color: AppTheme.dangerRed, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (alerts.isEmpty)
            const Text('No active risk alerts at this time.', style: TextStyle(color: Colors.grey, fontSize: 13))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: alerts.length,
              separatorBuilder: (context, index) => const Divider(color: Colors.white12),
              itemBuilder: (context, idx) {
                final a = alerts[idx];
                final customer = service.getCustomerById(a['customer_id']);

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.dangerRed,
                    child: Icon(Icons.priority_high, color: Colors.white, size: 16),
                  ),
                  title: Text(customer?['full_name'] ?? 'Unknown Customer', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text('${a['missed_dues_count']} payments missed in a row.', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  trailing: TextButton(
                    onPressed: () {},
                    child: const Text('Reassign Agent', style: TextStyle(fontSize: 12, color: AppTheme.primaryCyan)),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAgentActivities(BuildContext context) {
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
          const Text('Field Agent Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              backgroundColor: AppTheme.primaryBlue,
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: const Text('Rohan Naik (Agent)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: const Text('Checked In: 09:15 AM | East Bengaluru', style: TextStyle(color: Colors.grey, fontSize: 11)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: AppTheme.neonGreen.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
              child: const Text('ON DUTY', style: TextStyle(color: AppTheme.neonGreen, fontSize: 9, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeadsPanel(BuildContext context, List<Map<String, dynamic>> leads) {
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
              const Text('Incoming CRM Leads', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              TextButton(
                onPressed: () {},
                child: const Text('View All', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (leads.isEmpty)
            const Text('No unassigned leads.', style: TextStyle(color: Colors.grey, fontSize: 13))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: leads.length.clamp(0, 2),
              separatorBuilder: (context, index) => const Divider(color: Colors.white12),
              itemBuilder: (context, idx) {
                final l = leads[idx];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l['full_name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text('Requested: ₹${l['requested_amount']?.toString() ?? "0"}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () {},
                    child: const Text('Assign', style: TextStyle(fontSize: 11, color: Colors.white)),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
