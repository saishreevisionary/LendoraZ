import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/supabase_service.dart';
import '../../../core/network/providers.dart';
import '../../../core/widgets/kpi_card.dart';
import '../../../core/widgets/dashboard_section.dart';

class CollectionAgentDashboard extends ConsumerWidget {
  final VoidCallback onStartRoute;
  final VoidCallback onQuickCollect;

  const CollectionAgentDashboard({
    super.key,
    required this.onStartRoute,
    required this.onQuickCollect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(supabaseServiceProvider);
    final NumberFormat currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    // Fetch collections and targets
    final collections = service.getCollections();
    double myCollected = 0.0;
    for (var c in collections) {
      if (c['collection_date'].toString().startsWith(DateTime.now().toIso8601String().substring(0, 10))) {
        myCollected += (c['amount'] as double);
      }
    }

    final myCustomers = service.getCustomers();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeBanner(context, service),
          const SizedBox(height: 20),
          _buildAgentMetrics(context, myCollected, currencyFormat),
          const SizedBox(height: 24),
          _buildQuickActionButtons(context),
          const SizedBox(height: 24),
          _buildRouteSection(context),
          const SizedBox(height: 24),
          _buildAssignedCustomers(context, myCustomers, currencyFormat),
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner(BuildContext context, SupabaseService service) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, ${service.currentUserName.split(' ')[0]}',
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Keep it simple. You have 3 collections to complete today.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentMetrics(BuildContext context, double collected, NumberFormat fmt) {
    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 1,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: MediaQuery.of(context).size.width > 600 ? 1.6 : 3.0,
      children: [
        KpiCard(
          title: 'Today\'s Target',
          value: fmt.format(40000),
          icon: Icons.flag_rounded,
          color: AppTheme.primaryCyan,
        ),
        KpiCard(
          title: 'Collected Today',
          value: fmt.format(collected),
          icon: Icons.check_circle_rounded,
          color: AppTheme.neonGreen,
        ),
        KpiCard(
          title: 'Pending Dues',
          value: fmt.format(23536),
          icon: Icons.hourglass_empty_rounded,
          color: AppTheme.warningOrange,
        ),
      ],
    );
  }

  Widget _buildQuickActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Record Payment', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: onQuickCollect,
          ),
        ),
      ],
    );
  }

  Widget _buildRouteSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DashboardSectionCard(
      title: 'Today\'s Optimized Route',
      action: const Icon(Icons.navigation, color: AppTheme.primaryCyan, size: 16),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '3 stops in Indiranagar & HSR Layout (Estimated: 42 mins)',
            style: TextStyle(
              color: isDark ? Colors.grey : const Color(0xFF64748B),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
              foregroundColor: AppTheme.primaryCyan,
              side: const BorderSide(color: AppTheme.primaryCyan),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              minimumSize: const Size.fromHeight(40),
            ),
            onPressed: onStartRoute,
            child: const Text('Open Route Planner', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignedCustomers(BuildContext context, List<Map<String, dynamic>> customers, NumberFormat fmt) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DashboardSectionCard(
      title: 'My Assigned Customers',
      padding: const EdgeInsets.all(20),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: customers.length,
        separatorBuilder: (context, index) => Divider(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
        itemBuilder: (context, idx) {
          final c = customers[idx];
          final riskColor = c['risk_level'] == 'high' 
              ? AppTheme.dangerRed 
              : (c['risk_level'] == 'medium' ? AppTheme.warningOrange : AppTheme.neonGreen);

          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
              child: Text(c['full_name'].substring(0, 1), style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
            ),
            title: Text(
              c['full_name'],
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            subtitle: Text(
              c['address'],
              style: TextStyle(
                color: isDark ? Colors.grey : const Color(0xFF64748B),
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(color: riskColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    c['risk_level'].toUpperCase(), 
                    style: TextStyle(color: riskColor, fontSize: 8, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Due: ₹23,536',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
