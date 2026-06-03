import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/supabase_service.dart';
import '../../core/network/providers.dart';

class AdminConsoleWidget extends ConsumerStatefulWidget {
  const AdminConsoleWidget({super.key});

  @override
  ConsumerState<AdminConsoleWidget> createState() => _AdminConsoleWidgetState();
}

class _AdminConsoleWidgetState extends ConsumerState<AdminConsoleWidget> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<Map<String, dynamic>> _profiles = [];
  List<Map<String, dynamic>> _auditLogs = [];


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(supabaseServiceProvider);
      final profiles = await service.getAllProfiles();
      final logs = await service.getAuditLogs();

      setState(() {
        _profiles = profiles;
        _auditLogs = logs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load admin data: $e'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    }
  }

  Future<void> _updateUserRoleAndStatus(String id, AppUserRole role, String status) async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(supabaseServiceProvider);
      await service.updateUserProfileRole(userId: id, newRole: role, status: status);
      await _loadAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User profile updated successfully.'),
            backgroundColor: AppTheme.neonGreen,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update user: $e'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // TabBar headers
        Container(
          color: isDark ? Colors.black26 : Colors.white,
          child: TabBar(
            controller: _tabController,
            isScrollable: false,
            indicatorColor: AppTheme.primaryBlue,
            labelColor: AppTheme.primaryBlue,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(icon: Icon(Icons.people_outline), text: 'Users'),
              Tab(icon: Icon(Icons.history_toggle_off), text: 'Audit Logs'),
              Tab(icon: Icon(Icons.storage_outlined), text: 'DB Status'),
            ],
          ),
        ),

        // Tabs Content
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildUserManagementTab(isDark),
                    _buildAuditLogsTab(isDark),
                    _buildDatabaseStatusTab(isDark),
                  ],
                ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB BUILDERS
  // ==========================================

  Widget _buildUserManagementTab(bool isDark) {
    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _profiles.length,
        itemBuilder: (context, idx) {
          final profile = _profiles[idx];
          final userId = profile['id'] as String;
          final email = profile['email'] as String? ?? 'No email';
          final name = profile['full_name'] as String? ?? 'No Name';
          final roleStr = profile['role'] as String? ?? 'collection_agent';
          final status = profile['status'] as String? ?? 'active';

          // Resolve AppUserRole enum
          AppUserRole selectedRole = AppUserRole.collectionAgent;
          for (var r in AppUserRole.values) {
            if (roleStr.toLowerCase().replaceAll('_', '') == r.name.toLowerCase().replaceAll('_', '')) {
              selectedRole = r;
              break;
            }
          }

          final bool isSuspended = status == 'suspended';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.glassDecoration(context: context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          email,
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSuspended ? AppTheme.dangerRed.withValues(alpha: 0.1) : AppTheme.neonGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSuspended ? AppTheme.dangerRed.withValues(alpha: 0.3) : AppTheme.neonGreen.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isSuspended ? AppTheme.dangerRed : AppTheme.neonGreen,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.shield_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    const Text('Role: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<AppUserRole>(
                          value: selectedRole,
                          isDense: true,
                          dropdownColor: Theme.of(context).cardColor,
                          items: AppUserRole.values.map((role) {
                            return DropdownMenuItem<AppUserRole>(
                              value: role,
                              child: Text(role.displayName, style: const TextStyle(fontSize: 13)),
                            );
                          }).toList(),
                          onChanged: (newRole) {
                            if (newRole != null) {
                              _updateUserRoleAndStatus(userId, newRole, status);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.block_outlined, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        const Text('Status Switch:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    Switch(
                      value: status == 'active',
                      activeThumbColor: AppTheme.neonGreen,
                      inactiveThumbColor: AppTheme.dangerRed,
                      inactiveTrackColor: AppTheme.dangerRed.withValues(alpha: 0.2),
                      onChanged: (active) {
                        _updateUserRoleAndStatus(userId, selectedRole, active ? 'active' : 'suspended');
                      },
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

  Widget _buildAuditLogsTab(bool isDark) {
    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: _auditLogs.isEmpty
          ? const Center(child: Text('No audit logs recorded yet.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _auditLogs.length,
              itemBuilder: (context, idx) {
                final log = _auditLogs[idx];
                final action = log['action'] as String? ?? 'ACTION';
                final actorName = log['users']?['full_name'] as String? ?? 'System';
                final timestampStr = log['created_at'] as String? ?? '';
                final details = log['details'] as Map<String, dynamic>? ?? {};

                DateTime timestamp = DateTime.now();
                if (timestampStr.isNotEmpty) {
                  timestamp = DateTime.parse(timestampStr).toLocal();
                }

                Color actionColor = AppTheme.primaryBlue;
                if (action.contains('SUSPEND') || action.contains('DELETE') || action.contains('FAIL')) {
                  actionColor = AppTheme.dangerRed;
                } else if (action.contains('SYNC') || action.contains('CREATE')) {
                  actionColor = AppTheme.neonGreen;
                } else if (action.contains('UPDATE')) {
                  actionColor = AppTheme.warningOrange;
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: actionColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                action,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: actionColor,
                                ),
                              ),
                            ),
                            Text(
                              DateFormat('dd MMM yyyy, hh:mm a').format(timestamp),
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        RichText(
                          text: TextSpan(
                            style: Theme.of(context).textTheme.bodyMedium,
                            children: [
                              const TextSpan(text: 'Triggered by: ', style: TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(text: actorName, style: const TextStyle(color: AppTheme.primaryBlue)),
                            ],
                          ),
                        ),
                        if (details.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              details.toString(),
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.grey),
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }



  Widget _buildDatabaseStatusTab(bool isDark) {
    // Generate some mock/active count numbers for admin viewing
    final service = ref.read(supabaseServiceProvider);
    
    final customerCount = service.getCustomers().length;
    final loanCount = service.getLoans().length;
    final collectionCount = service.getCollections().length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Supabase Database Console',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 4),
          const Text(
            'Check real-time row counts and trigger definitions status.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 20),
          
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              _buildDBStatCard('public.users', '${_profiles.length}', Icons.people_outline, AppTheme.primaryBlue),
              _buildDBStatCard('public.customers', '$customerCount', Icons.assignment_ind_outlined, AppTheme.primaryCyan),
              _buildDBStatCard('public.loans', '$loanCount', Icons.credit_card_outlined, AppTheme.neonGreen),
              _buildDBStatCard('public.collections', '$collectionCount', Icons.receipt_long_outlined, AppTheme.warningOrange),
            ],
          ),

          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.glassDecoration(context: context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.bolt, color: AppTheme.warningOrange),
                    SizedBox(width: 8),
                    Text(
                      'PostgreSQL Trigger Status',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTriggerLogItem('on_auth_user_created', 'ACTIVE', 'Copies newly created auth.users to public.users'),
                _buildTriggerLogItem('on_collection_inserted', 'ACTIVE', 'Recalculates loan balance and penalities'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDBStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              const Icon(Icons.dns_outlined, color: Colors.grey, size: 16),
            ],
          ),
          Text(
            value,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildTriggerLogItem(String name, String status, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: AppTheme.neonGreen, size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'monospace')),
                    Text(status, style: const TextStyle(color: AppTheme.neonGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
