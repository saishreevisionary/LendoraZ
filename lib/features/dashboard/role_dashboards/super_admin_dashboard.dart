import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/animations.dart';
import '../../../core/network/supabase_service.dart';
import '../../../core/network/providers.dart';

class SuperAdminDashboard extends ConsumerWidget {
  const SuperAdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(supabaseServiceProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 20),
          _buildMetricsGrid(context, service),
          const SizedBox(height: 24),
          _buildHealthAndStorage(context),
          const SizedBox(height: 24),
          _buildFeatureToggles(context, service),
          const SizedBox(height: 24),
          _buildCompaniesPanel(context, service),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SlideFadeIn(
          delay: 0,
          child: Text(
            'Platform Overview',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ),
        SlideFadeIn(
          delay: 50,
          child: Text(
            'Global server administration and tenant configurations.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.grey : const Color(0xFF475569),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsGrid(BuildContext context, SupabaseService service) {
    final companies = service.getCompanies();
    final activeCompanies = companies.where((c) => c['status']?.toString() == 'active').length;
    final totalUsersCount = service.getAllUsers().length;

    final String totalCompVal = '${companies.length}';
    final String activeCompVal = '$activeCompanies';
    final String totalUsersVal = '$totalUsersCount';

    // Revenue calculation: ₹2.5L default base or ₹25k per active company
    final double revenueLakhs = service.isDemoMode 
        ? 8.4 
        : (activeCompanies * 0.25);
    final String revenueVal = revenueLakhs > 0 
        ? '₹${revenueLakhs.toStringAsFixed(revenueLakhs % 1 == 0 ? 0 : 1)}L' 
        : '₹0';

    // Subscriptions due calculation: count of suspended/inactive companies, default to 6 in demo
    final int suspendedCount = companies.where((c) => c['status']?.toString() != 'active').length;
    final String subsDueVal = service.isDemoMode ? '6' : '$suspendedCount';

    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        SlideFadeIn(
          delay: 100,
          child: _buildSAKPICard(
            context,
            title: 'Total Companies',
            value: totalCompVal,
            subtitle: 'Active: $activeCompVal',
            icon: Icons.business,
            color: AppTheme.primaryBlue,
          ),
        ),
        SlideFadeIn(
          delay: 150,
          child: _buildSAKPICard(
            context,
            title: 'Total Users',
            value: totalUsersVal,
            subtitle: '+14% this month',
            icon: Icons.people_alt,
            color: AppTheme.primaryCyan,
          ),
        ),
        SlideFadeIn(
          delay: 200,
          child: _buildSAKPICard(
            context,
            title: 'Monthly Revenue',
            value: revenueVal,
            subtitle: 'Target: ₹10L',
            icon: Icons.monetization_on,
            color: AppTheme.neonGreen,
          ),
        ),
        SlideFadeIn(
          delay: 250,
          child: _buildSAKPICard(
            context,
            title: 'Subscriptions Due',
            value: subsDueVal,
            subtitle: 'Suspended/Inactive',
            icon: Icons.receipt_long,
            color: AppTheme.warningOrange,
          ),
        ),
      ],
    );
  }

  Widget _buildSAKPICard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassCard(
      padding: const EdgeInsets.all(14),
      borderOpacity: 0.15,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title, 
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : const Color(0xFF64748B), 
                  fontSize: 11, 
                  fontWeight: FontWeight.bold
                ),
              ),
              Icon(icon, color: color, size: 18),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value, 
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F172A), 
                  fontSize: 22, 
                  fontWeight: FontWeight.w900
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle, 
                style: TextStyle(
                  color: color.withValues(alpha: 0.8), 
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthAndStorage(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SlideFadeIn(
      delay: 300,
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        borderOpacity: 0.15,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Health & Storage', 
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A), 
                fontWeight: FontWeight.bold, 
                fontSize: 16
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.dns, color: AppTheme.neonGreen, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Supabase API Status:', 
                  style: TextStyle(color: isDark ? Colors.grey : const Color(0xFF64748B), fontSize: 13)
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppTheme.neonGreen.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                  child: const Text('HEALTHY (99.9% Uptime)', style: TextStyle(color: AppTheme.neonGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Global Storage Consumption (185 GB / 500 GB)', 
              style: TextStyle(color: isDark ? Colors.grey : const Color(0xFF64748B), fontSize: 12)
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: 0.37,
                backgroundColor: isDark ? Colors.black26 : const Color(0xFFE2E8F0),
                color: AppTheme.primaryBlue,
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureToggles(BuildContext context, SupabaseService service) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final toggles = service.featureToggles;

    return SlideFadeIn(
      delay: 350,
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        borderOpacity: 0.15,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Global Feature Toggles', 
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A), 
                fontWeight: FontWeight.bold, 
                fontSize: 16
              ),
            ),
            const SizedBox(height: 12),
            _buildToggleRow(
              context,
              'AI Analytics Suite', 
              'Enable predictive cash flow models platform-wide.', 
              toggles['ai_analytics'] ?? true,
              (val) => service.toggleFeature('ai_analytics', val),
            ),
            _buildToggleRow(
              context,
              'SMS / WhatsApp Gateway', 
              'Chargeable API messaging integration.', 
              toggles['whatsapp_gateway'] ?? true,
              (val) => service.toggleFeature('whatsapp_gateway', val),
            ),
            _buildToggleRow(
              context,
              'Multi-Currency Support', 
              'Allows non-INR standard currencies.', 
              toggles['multi_currency'] ?? false,
              (val) => service.toggleFeature('multi_currency', val),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleRow(BuildContext context, String title, String desc, bool val, ValueChanged<bool> onChanged) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SwitchListTile(
      value: val,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      activeThumbColor: AppTheme.primaryCyan,
      title: Text(
        title, 
        style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF1E293B), 
          fontSize: 14, 
          fontWeight: FontWeight.bold
        )
      ),
      subtitle: Text(desc, style: TextStyle(color: isDark ? Colors.grey : const Color(0xFF64748B), fontSize: 11)),
    );
  }

  Widget _buildCompaniesPanel(BuildContext context, SupabaseService service) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final companies = service.getCompanies();

    return SlideFadeIn(
      delay: 400,
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        borderOpacity: 0.15,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Company Tenants', 
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A), 
                    fontWeight: FontWeight.bold, 
                    fontSize: 16
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Company', style: TextStyle(fontSize: 12)),
                  onPressed: () => _showAddCompanyDialog(context, service),
                ),
              ],
            ),
            const SizedBox(height: 12),
            companies.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'No companies registered. Click Add Company to start.',
                        style: TextStyle(color: isDark ? Colors.grey : const Color(0xFF64748B), fontSize: 13),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: companies.length,
                    separatorBuilder: (context, index) => Divider(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                    itemBuilder: (context, idx) {
                      final comp = companies[idx];
                      final name = comp['name'] ?? 'Unknown Company';
                      final status = comp['status'] ?? 'active';
                      final isSuspended = status == 'suspended' || status == 'inactive';
                      final badgeColor = isSuspended ? AppTheme.dangerRed : AppTheme.neonGreen;

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.15),
                          child: Text(
                            name.isNotEmpty ? name.substring(0, 2).toUpperCase() : 'CO',
                            style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          name, 
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF1E293B), 
                            fontWeight: FontWeight.bold, 
                            fontSize: 14
                          ),
                        ),
                        subtitle: Text(
                          'Plan: Enterprise (Max 100 Agents)', 
                          style: TextStyle(color: isDark ? Colors.grey : const Color(0xFF64748B), fontSize: 11)
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () async {
                                final newStatus = isSuspended ? 'active' : 'suspended';
                                try {
                                  await service.updateCompanyStatus(comp['id'], newStatus);
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to update status: $e'),
                                        backgroundColor: AppTheme.dangerRed,
                                      ),
                                    );
                                  }
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: badgeColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: TextStyle(color: badgeColor, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert, color: isDark ? Colors.grey : const Color(0xFF64748B), size: 20),
                              onSelected: (val) async {
                                try {
                                  await service.updateCompanyStatus(comp['id'], val);
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to update status: $e'),
                                        backgroundColor: AppTheme.dangerRed,
                                      ),
                                    );
                                  }
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'active', child: Text('Activate Tenant')),
                                const PopupMenuItem(value: 'suspended', child: Text('Suspend Tenant')),
                                const PopupMenuItem(value: 'inactive', child: Text('Deactivate Tenant')),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  void _showAddCompanyDialog(BuildContext context, SupabaseService service) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
          ),
          title: Text(
            'Add Company Tenant', 
            style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.bold)
          ),
          content: TextField(
            controller: nameController,
            style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
            decoration: InputDecoration(
              labelText: 'Company Name',
              labelStyle: TextStyle(color: isDark ? Colors.grey : const Color(0xFF64748B)),
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: isDark ? Colors.grey : const Color(0xFF64748B))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  try {
                    await service.addCompany(nameController.text.trim());
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Registered tenant: ${nameController.text}'),
                          backgroundColor: AppTheme.neonGreen,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to add tenant: $e'),
                          backgroundColor: AppTheme.dangerRed,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Add Tenant', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
