import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/supabase_service.dart';
import '../../../core/network/providers.dart';
import '../../../core/widgets/kpi_card.dart';
import '../../../core/widgets/dashboard_section.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Operations Center',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        Text(
          'Track field agents, review overdue payments, and process new leads.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isDark ? Colors.grey : const Color(0xFF64748B),
          ),
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
        KpiCard(
          title: 'Today\'s Collections',
          value: fmt.format(collectedToday),
          subtitle: 'Expected: ₹45,000',
          icon: Icons.payments,
          color: AppTheme.neonGreen,
        ),
        KpiCard(
          title: 'Risk Alerts',
          value: '$alertCount',
          subtitle: 'High-risk accounts active',
          icon: Icons.warning_amber_rounded,
          color: AppTheme.dangerRed,
        ),
        KpiCard(
          title: 'New Leads',
          value: '$leadCount',
          subtitle: 'Unassigned prospects',
          icon: Icons.contact_page_outlined,
          color: AppTheme.primaryCyan,
        ),
      ],
    );
  }

  Widget _buildActiveAlerts(BuildContext context, List<Map<String, dynamic>> alerts, SupabaseService service) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DashboardSectionCard(
      title: 'Active Overdue Risk Alerts',
      action: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: AppTheme.dangerRed.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
        child: Text('${alerts.length} Active', style: const TextStyle(color: AppTheme.dangerRed, fontSize: 10, fontWeight: FontWeight.bold)),
      ),
      padding: const EdgeInsets.all(20),
      child: alerts.isEmpty
          ? Text('No active risk alerts at this time.', style: TextStyle(color: isDark ? Colors.grey : const Color(0xFF64748B), fontSize: 13))
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: alerts.length,
              separatorBuilder: (context, index) => Divider(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
              itemBuilder: (context, idx) {
                final a = alerts[idx];
                final customer = service.getCustomerById(a['customer_id']);

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.dangerRed,
                    child: Icon(Icons.priority_high, color: Colors.white, size: 16),
                  ),
                  title: Text(
                    customer?['full_name'] ?? 'Unknown Customer',
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    '${a['missed_dues_count']} payments missed in a row.',
                    style: TextStyle(
                      color: isDark ? Colors.grey : const Color(0xFF64748B),
                      fontSize: 11,
                    ),
                  ),
                  trailing: TextButton(
                    onPressed: () {},
                    child: const Text('Reassign Agent', style: TextStyle(fontSize: 12, color: AppTheme.primaryCyan)),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildAgentActivities(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DashboardSectionCard(
      title: 'Field Agent Status',
      padding: const EdgeInsets.all(20),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const CircleAvatar(
          backgroundColor: AppTheme.primaryBlue,
          child: Icon(Icons.person, color: Colors.white),
        ),
        title: Text(
          'Rohan Naik (Agent)',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          'Checked In: 09:15 AM | East Bengaluru',
          style: TextStyle(
            color: isDark ? Colors.grey : const Color(0xFF64748B),
            fontSize: 11,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: AppTheme.neonGreen.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
          child: const Text('ON DUTY', style: TextStyle(color: AppTheme.neonGreen, fontSize: 9, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildLeadsPanel(BuildContext context, List<Map<String, dynamic>> leads) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DashboardSectionCard(
      title: 'Incoming CRM Leads',
      action: TextButton(
        onPressed: () {},
        child: const Text('View All', style: TextStyle(fontSize: 12)),
      ),
      padding: const EdgeInsets.all(20),
      child: leads.isEmpty
          ? Text('No unassigned leads.', style: TextStyle(color: isDark ? Colors.grey : const Color(0xFF64748B), fontSize: 13))
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: leads.length.clamp(0, 2),
              separatorBuilder: (context, index) => Divider(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
              itemBuilder: (context, idx) {
                final l = leads[idx];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    l['full_name'],
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    'Requested: ₹${l['requested_amount']?.toString() ?? "0"}',
                    style: TextStyle(
                      color: isDark ? Colors.grey : const Color(0xFF64748B),
                      fontSize: 11,
                    ),
                  ),
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
    );
  }
}
