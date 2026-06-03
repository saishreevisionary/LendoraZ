
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/supabase_service.dart';
import '../../../core/network/providers.dart';
import '../../../core/widgets/kpi_card.dart';
import '../../../core/widgets/dashboard_section.dart';

class SuperAdminDashboard extends ConsumerWidget {
  const SuperAdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(supabaseServiceProvider);
    final isDark = service.themeMode == ThemeMode.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, isDark),
          const SizedBox(height: 24),
          _buildMetricsGrid(context, service, isDark),
          const SizedBox(height: 24),
          _buildHealthAndStorage(context, isDark),
          const SizedBox(height: 24),
          _buildFeatureToggles(context, service, isDark),
          const SizedBox(height: 24),
          _buildCompaniesPanel(context, service, isDark),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
          child: Text(
            'Platform Overview',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1.0,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Global server administration and tenant configurations.',
          style: GoogleFonts.inter(
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsGrid(BuildContext context, SupabaseService service, bool isDark) {
    final companies = service.getCompanies();
    final activeCompanies = companies.where((c) => c['status']?.toString() == 'active').length;
    final totalUsersCount = service.getAllUsers().length;

    final String totalCompVal = '${companies.length}';
    final String activeCompVal = '$activeCompanies';
    final String totalUsersVal = '$totalUsersCount';

    // Revenue calculation: ₹8.4L default base in demo, or ₹25k per active company in live
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
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: MediaQuery.of(context).size.width > 600 ? 1.4 : 1.15,
      children: [
        KpiCard(
          title: 'Total Companies',
          value: totalCompVal,
          icon: Icons.business_rounded,
          color: AppTheme.primaryBlue,
          trendWidget: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Active: $activeCompVal',
              style: GoogleFonts.inter(
                color: AppTheme.primaryBlue,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        KpiCard(
          title: 'Total Users',
          value: totalUsersVal,
          icon: Icons.people_alt_rounded,
          color: AppTheme.primaryCyan,
          trendWidget: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_upward_rounded, size: 8, color: Color(0xFF10B981)),
                const SizedBox(width: 2),
                Text(
                  '+14% this month',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF10B981),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        KpiCard(
          title: 'Monthly Revenue',
          value: revenueVal,
          icon: Icons.monetization_on_rounded,
          color: AppTheme.neonGreen,
          trendWidget: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.neonGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Target: ₹10L',
              style: GoogleFonts.inter(
                color: AppTheme.neonGreen,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        KpiCard(
          title: 'Subscriptions Due',
          value: subsDueVal,
          icon: Icons.receipt_long_rounded,
          color: AppTheme.warningOrange,
          trendWidget: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.warningOrange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Suspended/Inactive',
              style: GoogleFonts.inter(
                color: AppTheme.warningOrange,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHealthAndStorage(BuildContext context, bool isDark) {
    return DashboardSectionCard(
      title: 'System Health & Storage',
      action: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'HEALTHY (99.9% Uptime)',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF047857),
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storage_rounded, color: AppTheme.primaryBlue, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Global Storage Consumption',
                  style: GoogleFonts.inter(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Spacer(),
              Text(
                '185 GB / 500 GB (37%)',
                style: GoogleFonts.inter(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 8,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: 0.37,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureToggles(BuildContext context, SupabaseService service, bool isDark) {
    final toggles = service.featureToggles;

    return DashboardSectionCard(
      title: 'Global Feature Toggles',
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildToggleRow(
            context,
            'AI Analytics Suite', 
            'Enable predictive cash flow models platform-wide.', 
            toggles['ai_analytics'] ?? true,
            (val) => service.toggleFeature('ai_analytics', val),
            isDark,
          ),
          const Divider(color: Colors.white10),
          _buildToggleRow(
            context,
            'SMS / WhatsApp Gateway', 
            'Chargeable API messaging integration.', 
            toggles['whatsapp_gateway'] ?? true,
            (val) => service.toggleFeature('whatsapp_gateway', val),
            isDark,
          ),
          const Divider(color: Colors.white10),
          _buildToggleRow(
            context,
            'Multi-Currency Support', 
            'Allows non-INR standard currencies.', 
            toggles['multi_currency'] ?? false,
            (val) => service.toggleFeature('multi_currency', val),
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow(BuildContext context, String title, String desc, bool val, ValueChanged<bool> onChanged, bool isDark) {
    return SwitchListTile(
      value: val,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      activeThumbColor: AppTheme.primaryCyan,
      title: Text(
        title, 
        style: GoogleFonts.plusJakartaSans(
          color: isDark ? Colors.white : const Color(0xFF0F172A), 
          fontSize: 14, 
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        desc, 
        style: GoogleFonts.inter(
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), 
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildCompaniesPanel(BuildContext context, SupabaseService service, bool isDark) {
    final companies = service.getCompanies();

    return DashboardSectionCard(
      title: 'Company Tenants',
      action: ElevatedButton.icon(
        icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
        label: Text(
          'Add Company',
          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryBlue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          elevation: 0,
        ),
        onPressed: () => _showAddCompanyDialog(context, service, isDark),
      ),
      padding: const EdgeInsets.all(20),
      child: companies.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No companies registered. Click Add Company to start.',
                  style: GoogleFonts.inter(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: companies.length,
              separatorBuilder: (context, index) => Divider(
                color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06),
                thickness: 1.0,
              ),
              itemBuilder: (context, idx) {
                final comp = companies[idx];
                final name = comp['name'] ?? 'Unknown Company';
                final status = comp['status'] ?? 'active';
                final isSuspended = status == 'suspended' || status == 'inactive';
                final badgeColor = isSuspended ? AppTheme.dangerRed : AppTheme.neonGreen;

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryBlue.withValues(alpha: 0.8),
                          AppTheme.primaryCyan.withValues(alpha: 0.8),
                        ],
                      ),
                      border: Border.all(color: Colors.white24, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        name.isNotEmpty ? name.substring(0, 2).toUpperCase() : 'CO',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    name, 
                    style: GoogleFonts.plusJakartaSans(
                      color: isDark ? Colors.white : const Color(0xFF0F172A), 
                      fontWeight: FontWeight.w800, 
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    'Plan: Enterprise (Max 100 Agents)', 
                    style: GoogleFonts.inter(
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), 
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
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
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: badgeColor.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _PulseDotLocal(isActive: !isSuspended),
                              const SizedBox(width: 6),
                              Text(
                                status.toUpperCase(),
                                style: GoogleFonts.inter(
                                  color: badgeColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert_rounded, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), size: 20),
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onSelected: (val) async {
                          try {
                            await service.updateCompanyStatus(comp['id'], val);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to update status: $e'),
                                  backgroundColor: AppTheme.dangerRed,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            }
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'active',
                            child: Text(
                              'Activate Tenant',
                              style: GoogleFonts.inter(
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'suspended',
                            child: Text(
                              'Suspend Tenant',
                              style: GoogleFonts.inter(
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'inactive',
                            child: Text(
                              'Deactivate Tenant',
                              style: GoogleFonts.inter(
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  void _showAddCompanyDialog(BuildContext context, SupabaseService service, bool isDark) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          title: Text(
            'Add Company Tenant', 
            style: GoogleFonts.plusJakartaSans(
              color: isDark ? Colors.white : const Color(0xFF0F172A), 
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: nameController,
            style: GoogleFonts.inter(color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              labelText: 'Company Name',
              labelStyle: GoogleFonts.inter(color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
              filled: true,
              fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel', 
                style: GoogleFonts.inter(color: const Color(0xFF64748B), fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
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
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to add tenant: $e'),
                          backgroundColor: AppTheme.dangerRed,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                  }
                }
              },
              child: Text(
                'Add Tenant', 
                style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PulseDotLocal extends StatefulWidget {
  final bool isActive;
  const _PulseDotLocal({required this.isActive});

  @override
  State<_PulseDotLocal> createState() => _PulseDotLocalState();
}

class _PulseDotLocalState extends State<_PulseDotLocal> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}
