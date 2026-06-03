import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Platform Overview',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        Text(
          'Global server administration and tenant configurations.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
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
        _buildSAKPICard(
          title: 'Total Companies',
          value: totalCompVal,
          subtitle: 'Active: $activeCompVal',
          icon: Icons.business,
          color: AppTheme.primaryBlue,
        ),
        _buildSAKPICard(
          title: 'Total Users',
          value: totalUsersVal,
          subtitle: '+14% this month',
          icon: Icons.people_alt,
          color: AppTheme.primaryCyan,
        ),
        _buildSAKPICard(
          title: 'Monthly Revenue',
          value: revenueVal,
          subtitle: 'Target: ₹10L',
          icon: Icons.monetization_on,
          color: AppTheme.neonGreen,
        ),
        _buildSAKPICard(
          title: 'Subscriptions Due',
          value: subsDueVal,
          subtitle: 'Suspended/Inactive',
          icon: Icons.receipt_long,
          color: AppTheme.warningOrange,
        ),
      ],
    );
  }

  Widget _buildSAKPICard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
              Icon(icon, color: color, size: 18),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthAndStorage(BuildContext context) {
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
          const Text('System Health & Storage', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.dns, color: AppTheme.neonGreen, size: 16),
              const SizedBox(width: 8),
              const Text('Supabase API Status:', style: TextStyle(color: Colors.grey, fontSize: 13)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppTheme.neonGreen.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                child: const Text('HEALTHY (99.9% Uptime)', style: TextStyle(color: AppTheme.neonGreen, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Global Storage Consumption (185 GB / 500 GB)', style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const LinearProgressIndicator(
              value: 0.37,
              backgroundColor: Colors.black26,
              color: AppTheme.primaryBlue,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureToggles(BuildContext context, SupabaseService service) {
    final toggles = service.featureToggles;

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
          const Text('Global Feature Toggles', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _buildToggleRow(
            'AI Analytics Suite', 
            'Enable predictive cash flow models platform-wide.', 
            toggles['ai_analytics'] ?? true,
            (val) => service.toggleFeature('ai_analytics', val),
          ),
          _buildToggleRow(
            'SMS / WhatsApp Gateway', 
            'Chargeable API messaging integration.', 
            toggles['whatsapp_gateway'] ?? true,
            (val) => service.toggleFeature('whatsapp_gateway', val),
          ),
          _buildToggleRow(
            'Multi-Currency Support', 
            'Allows non-INR standard currencies.', 
            toggles['multi_currency'] ?? false,
            (val) => service.toggleFeature('multi_currency', val),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow(String title, String desc, bool val, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      value: val,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      activeColor: AppTheme.primaryCyan,
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      subtitle: Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 11)),
    );
  }

  Widget _buildCompaniesPanel(BuildContext context, SupabaseService service) {
    final companies = service.getCompanies();

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
              const Text('Company Tenants', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Company', style: TextStyle(fontSize: 12)),
                onPressed: () => _showAddCompanyDialog(context, service),
              ),
            ],
          ),
          const SizedBox(height: 12),
          companies.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'No companies registered. Click Add Company to start.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: companies.length,
                  separatorBuilder: (context, index) => const Divider(color: Colors.white12),
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
                      title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: const Text('Plan: Enterprise (Max 100 Agents)', style: TextStyle(color: Colors.grey, fontSize: 11)),
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
                            icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
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
    );
  }

  void _showAddCompanyDialog(BuildContext context, SupabaseService service) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.darkCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.darkBorder),
          ),
          title: const Text('Add Company Tenant', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: nameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Company Name',
              labelStyle: const TextStyle(color: Colors.grey),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.darkBorder),
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
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
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
