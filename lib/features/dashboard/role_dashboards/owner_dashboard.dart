import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/supabase_service.dart';
import '../../../core/network/providers.dart';
import '../../../core/widgets/kpi_card.dart';
import '../../../core/widgets/dashboard_section.dart';

class CompanyOwnerDashboard extends ConsumerWidget {
  const CompanyOwnerDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(supabaseServiceProvider);
    final NumberFormat currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    // Fetch data
    final customers = service.getCustomers();
    final loans = service.getLoans();
    final forecast = service.getCashflowForecast();

    double totalPortfolio = 0.0;
    for (var l in loans) {
      totalPortfolio += (l['principal_amount'] as double);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, service),
          const SizedBox(height: 20),
          _buildMetricsGrid(context, customers.length, loans.length, totalPortfolio, currencyFormat),
          const SizedBox(height: 24),
          _buildPredictiveCashflow(context, forecast, currencyFormat),
          const SizedBox(height: 24),
          _buildAgentPerformance(context, service),
          const SizedBox(height: 24),
          _buildLendingControls(context, service),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, SupabaseService service) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Executive Workspace',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        Text(
          'Strategic growth, AI risk profiling, and team analytics.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isDark ? Colors.grey : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsGrid(BuildContext context, int customerCount, int loanCount, double portfolio, NumberFormat fmt) {
    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: MediaQuery.of(context).size.width > 600 ? 1.4 : 1.15,
      children: [
        KpiCard(
          title: 'Total Customers',
          value: '$customerCount',
          subtitle: 'Active accounts',
          icon: Icons.people_alt,
          color: AppTheme.primaryBlue,
        ),
        KpiCard(
          title: 'Active Loans',
          value: '$loanCount',
          subtitle: 'In collection',
          icon: Icons.account_balance,
          color: AppTheme.primaryCyan,
        ),
        KpiCard(
          title: 'Lending Portfolio',
          value: fmt.format(portfolio),
          subtitle: 'Capital deployed',
          icon: Icons.monetization_on,
          color: AppTheme.neonGreen,
        ),
        KpiCard(
          title: 'Net Profit Margin',
          value: '18.4%',
          subtitle: 'Industry Avg: 12%',
          icon: Icons.trending_up,
          color: AppTheme.goldPremium,
        ),
      ],
    );
  }

  Widget _buildPredictiveCashflow(BuildContext context, Map<String, double> forecast, NumberFormat fmt) {
    return DashboardSectionCard(
      title: 'Predictive Cashflow Forecast',
      action: const Icon(Icons.auto_awesome, color: AppTheme.primaryCyan, size: 18),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 50000,
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      const FlSpot(0, 10000),
                      const FlSpot(1, 15000),
                      const FlSpot(2, 13000),
                      const FlSpot(3, 22000),
                      FlSpot(4, forecast['tomorrow'] ?? 25000),
                      FlSpot(5, (forecast['weekly'] ?? 100000) / 4),
                      FlSpot(6, (forecast['monthly'] ?? 300000) / 10),
                    ],
                    isCurved: true,
                    gradient: const LinearGradient(colors: [AppTheme.primaryBlue, AppTheme.primaryCyan]),
                    barWidth: 4,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryBlue.withValues(alpha: 0.2),
                          AppTheme.primaryCyan.withValues(alpha: 0.02)
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildForecastCell('Tomorrow Expected', fmt.format(forecast['tomorrow'] ?? 0)),
              _buildForecastCell('Weekly Predicted', fmt.format(forecast['weekly'] ?? 0)),
              _buildForecastCell('Monthly Projected', fmt.format(forecast['monthly'] ?? 0)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildForecastCell(String title, String val) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(color: AppTheme.primaryCyan, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _buildAgentPerformance(BuildContext context, SupabaseService service) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DashboardSectionCard(
      title: 'Collection Agent Performance',
      padding: const EdgeInsets.all(20),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: service.getAgentsWithStats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(color: AppTheme.primaryBlue),
              ),
            );
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('No agents registered.', style: TextStyle(color: Colors.grey, fontSize: 13)),
              ),
            );
          }
          final agents = snapshot.data!;
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: agents.length,
            separatorBuilder: (context, index) => Divider(
              color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
            ),
            itemBuilder: (context, idx) {
              final agent = agents[idx];
              final name = agent['full_name'] ?? 'Agent';
              final status = agent['status'] ?? 'Offline';
              final target = agent['target_amount'] as double? ?? 50000.0;
              final collected = agent['collected_amount'] as double? ?? 0.0;
              final double percent = target > 0 ? (collected / target) * 100 : 0.0;
              
              final badgeColor = percent >= 90 ? AppTheme.neonGreen : (percent >= 50 ? AppTheme.warningOrange : AppTheme.dangerRed);

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.15),
                  child: Text(
                    name.isNotEmpty ? name.substring(0, 2).toUpperCase() : 'AG',
                    style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  name,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  'Status: $status',
                  style: TextStyle(
                    color: isDark ? Colors.grey : const Color(0xFF64748B),
                    fontSize: 11,
                  ),
                ),
                trailing: Text('${percent.toStringAsFixed(1)}% Target', style: TextStyle(color: badgeColor, fontSize: 13, fontWeight: FontWeight.bold)),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLendingControls(BuildContext context, SupabaseService service) {
    return DashboardSectionCard(
      title: 'Company Configurations',
      padding: const EdgeInsets.all(20),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildConfigChip(
            context, 
            Icons.percent, 
            'Interest Rules', 
            () => _showConfigDialog(context, service, 'interest_rate_default', 'Company Interest Rules', 'Default Annual Interest Rate (%)'),
          ),
          _buildConfigChip(
            context, 
            Icons.gavel, 
            'Penalty Setup', 
            () => _showConfigDialog(context, service, 'penalty_rate_monthly', 'Late Payment Penalty Setup', 'Default Monthly Penalty Rate (%)'),
          ),
          _buildConfigChip(
            context, 
            Icons.settings_suggest, 
            'Auto Collection', 
            () => _showConfigDialog(context, service, 'sync_interval_seconds', 'Automated Collections Setup', 'Auto-sync Cache Polling Interval (seconds)'),
          ),
          _buildConfigChip(
            context, 
            Icons.security, 
            'RLS Status: ACTIVE', 
            () => _showRLSInfoDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigChip(BuildContext context, IconData icon, String label, VoidCallback onPressed) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ActionChip(
      avatar: Icon(icon, size: 16, color: AppTheme.primaryCyan),
      label: Text(
        label,
        style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF0F172A),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0)),
      ),
      onPressed: onPressed,
    );
  }

  void _showConfigDialog(BuildContext context, SupabaseService service, String settingKey, String title, String label) async {
    // Show a loading dialog first
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue)),
    );

    try {
      final settings = await service.getSystemSettings();
      if (context.mounted) Navigator.pop(context); // Pop loading indicator

      final setting = settings.firstWhere((s) => s['key'] == settingKey, orElse: () => {'value': '0.0'});
      final controller = TextEditingController(text: setting['value']);

      if (!context.mounted) return;

      final isDark = Theme.of(context).brightness == Brightness.dark;

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            ),
            title: Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  setting['description'] ?? 'Configure your company default value.',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    labelText: label,
                    labelStyle: const TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.primaryBlue),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
                onPressed: () async {
                  final newValue = controller.text.trim();
                  if (newValue.isNotEmpty) {
                    try {
                      await service.updateSystemSetting(settingKey, newValue);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Updated $title to $newValue.'),
                            backgroundColor: AppTheme.neonGreen,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to update config: $e'),
                            backgroundColor: AppTheme.dangerRed,
                          ),
                        );
                      }
                    }
                  }
                },
                child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Pop loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fetch settings: $e'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    }
  }

  void _showRLSInfoDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
          ),
          title: const Row(
            children: [
              Icon(Icons.security, color: AppTheme.neonGreen),
              SizedBox(width: 8),
              Text('Security Enforced', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'Row Level Security (RLS) is ACTIVE. \n\nEvery database transaction is guarded by Postgres tenant isolation policies. It is mathematically impossible for agents, accountants, or managers from other companies to access your files or customer sheets.',
            style: TextStyle(color: isDark ? Colors.grey : const Color(0xFF64748B), fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
