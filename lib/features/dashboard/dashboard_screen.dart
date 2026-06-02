import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/supabase_service.dart';
import '../../core/network/providers.dart';

// Import features
import '../collection/collection_dashboard_widget.dart';
import '../agent/route_planner_widget.dart';
import '../crm/crm_leads_widget.dart';
import '../self_service/customer_portal_widget.dart';
import '../reports/reports_widget.dart';
import '../auth/login_screen.dart';
import '../admin/admin_console_widget.dart';
import '../admin/system_settings_widget.dart';

// Import role dashboards
import 'role_dashboards/super_admin_dashboard.dart';
import 'role_dashboards/owner_dashboard.dart';
import 'role_dashboards/manager_dashboard.dart';
import 'role_dashboards/agent_dashboard.dart';
import 'role_dashboards/accountant_dashboard.dart';
import 'role_dashboards/customer_dashboard.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedBottomNavIndex = 0;

  // Quick action states
  final _voiceInputTextController = TextEditingController();
  bool _isListeningVoice = false;

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(supabaseServiceProvider);

    return Scaffold(
      appBar: _buildPremiumAppBar(context, service),
      drawer: _buildRoleDrawer(context, service),
      body: _buildSelectedTabBody(service),
      bottomNavigationBar: _buildBottomNavigationBar(context, service),
      floatingActionButton: _shouldShowQuickActionsFab(service) 
          ? _buildQuickActionsFab(context, service) 
          : null,
    );
  }

  // ==========================================
  // Premium Layout Builders
  // ==========================================
  PreferredSizeWidget _buildPremiumAppBar(BuildContext context, SupabaseService service) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LendoraZ',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
          Text(
            'Role: ${service.currentRole.displayName}',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontSize: 10,
              color: AppTheme.primaryBlue,
            ),
          ),
        ],
      ),
      actions: [
        // Offline / Online / Demo Mode Switcher with Indicator
        Tooltip(
          message: service.isDemoMode 
              ? 'Demo Mode (Supabase disconnected)' 
              : (service.isOffline ? 'Offline Mode (Local Sync Queue Active)' : 'Online Mode (Connected to Supabase)'),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: service.isDemoMode 
                      ? AppTheme.warningOrange 
                      : (service.isOffline ? AppTheme.warningOrange : AppTheme.neonGreen),
                  boxShadow: [
                    BoxShadow(
                      color: (service.isDemoMode 
                              ? AppTheme.warningOrange 
                              : (service.isOffline ? AppTheme.warningOrange : AppTheme.neonGreen))
                          .withValues(alpha: 0.5),
                      blurRadius: 6,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                service.isDemoMode 
                    ? 'DEMO' 
                    : (service.isOffline ? 'OFFLINE' : 'ONLINE'),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: service.isDemoMode 
                      ? AppTheme.warningOrange 
                      : (service.isOffline ? AppTheme.warningOrange : AppTheme.neonGreen),
                ),
              ),
              if (!service.isDemoMode) ...[
                Switch(
                  value: !service.isOffline,
                  onChanged: (_) => service.toggleNetworkMode(),
                  activeThumbColor: AppTheme.neonGreen,
                  inactiveThumbColor: AppTheme.warningOrange,
                  inactiveTrackColor: AppTheme.warningOrange.withValues(alpha: 0.2),
                ),
              ] else ...[
                const SizedBox(width: 12),
              ],
            ],
          ),
        ),
        // Sync trigger if queue exists
        if (service.offlineQueue.isNotEmpty)
          IconButton(
            icon: const Badge(
              label: Text('!'),
              child: Icon(Icons.sync_problem, color: AppTheme.warningOrange),
            ),
            onPressed: () => service.syncOfflineQueue(),
          ),
        // Theme Switcher Button
        IconButton(
          tooltip: 'Toggle Theme Mode',
          icon: Icon(
            service.themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
            color: Colors.grey,
            size: 20,
          ),
          onPressed: () => service.toggleThemeMode(),
        ),
        // Logout Button
        IconButton(
          tooltip: 'Log Out',
          icon: const Icon(Icons.logout, color: Colors.grey, size: 20),
          onPressed: () async {
            await service.signOut();
            if (context.mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            }
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildRoleDrawer(BuildContext context, SupabaseService service) {
    // Determine if user has switch role permissions (Super Admin original logins or Demo mode)
    final bool canSwitchRoles = service.isDemoMode || service.currentUserEmail == 'admin@lendoraz.com';

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
            ),
            accountName: Text(
              service.currentUserName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: Text(service.currentUserEmail),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                service.currentUserName.isNotEmpty ? service.currentUserName.substring(0, 2).toUpperCase() : 'US',
                style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          if (canSwitchRoles) ...[
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'SWITCH SYSTEM ROLE (TESTING ONLY)',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: AppUserRole.values.map((role) {
                  final isSelected = service.currentRole == role;
                  return ListTile(
                    leading: Icon(
                      Icons.verified_user,
                      color: isSelected ? AppTheme.primaryBlue : Colors.grey,
                    ),
                    title: Text(
                      role.displayName,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppTheme.primaryBlue : null,
                      ),
                    ),
                    trailing: isSelected ? const Icon(Icons.check_circle, color: AppTheme.primaryBlue) : null,
                    onTap: () {
                      service.switchRole(role);
                      Navigator.pop(context);
                      setState(() => _selectedBottomNavIndex = 0);
                    },
                  );
                }).toList(),
              ),
            ),
          ] else ...[
            const Spacer(),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  'Security Level: High (RLS Active)',
                  style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log Out'),
            onTap: () async {
              Navigator.pop(context);
              await service.signOut();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  List<NavigationDestination> _getDestinations(SupabaseService service) {
    switch (service.currentRole) {
      case AppUserRole.superAdmin:
        return const [
          NavigationDestination(icon: Icon(Icons.admin_panel_settings_outlined), selectedIcon: Icon(Icons.admin_panel_settings), label: 'Admin'),
          NavigationDestination(icon: Icon(Icons.business_outlined), selectedIcon: Icon(Icons.business), label: 'Companies'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ];
      case AppUserRole.companyOwner:
      case AppUserRole.manager:
        return const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.people_alt_outlined), selectedIcon: Icon(Icons.people_alt), label: 'CRM Leads'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Collections'),
          NavigationDestination(icon: Icon(Icons.analytics_outlined), selectedIcon: Icon(Icons.analytics), label: 'Reports'),
        ];
      case AppUserRole.collectionAgent:
        return const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Route'),
          NavigationDestination(icon: Icon(Icons.payment_outlined), selectedIcon: Icon(Icons.payment), label: 'Collect'),
          NavigationDestination(icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications), label: 'Alerts'),
        ];
      case AppUserRole.accountant:
        return const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Payments'),
          NavigationDestination(icon: Icon(Icons.receipt_outlined), selectedIcon: Icon(Icons.receipt), label: 'Receipts'),
          NavigationDestination(icon: Icon(Icons.analytics_outlined), selectedIcon: Icon(Icons.analytics), label: 'Reports'),
        ];
      case AppUserRole.customer:
        return const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: 'History'),
          NavigationDestination(icon: Icon(Icons.receipt_outlined), selectedIcon: Icon(Icons.receipt), label: 'Receipts'),
        ];
    }
  }

  Widget _buildSelectedTabBody(SupabaseService service) {
    final destinations = _getDestinations(service);
    final index = _selectedBottomNavIndex.clamp(0, destinations.length - 1);

    switch (service.currentRole) {
      case AppUserRole.superAdmin:
        switch (index) {
          case 0: return const SuperAdminDashboard();
          case 1: return const AdminConsoleWidget();
          case 2: return const SystemSettingsWidget();
          default: return const SuperAdminDashboard();
        }
      case AppUserRole.companyOwner:
        switch (index) {
          case 0: return const CompanyOwnerDashboard();
          case 1: return const CRMLeadsWidget();
          case 2: return const CollectionDashboardWidget();
          case 3: return const ReportsWidget();
          default: return const CompanyOwnerDashboard();
        }
      case AppUserRole.manager:
        switch (index) {
          case 0: return const ManagerDashboard();
          case 1: return const CRMLeadsWidget();
          case 2: return const CollectionDashboardWidget();
          case 3: return const ReportsWidget();
          default: return const ManagerDashboard();
        }
      case AppUserRole.collectionAgent:
        switch (index) {
          case 0: 
            return CollectionAgentDashboard(
              onStartRoute: () => setState(() => _selectedBottomNavIndex = 1),
              onQuickCollect: () => setState(() => _selectedBottomNavIndex = 2),
            );
          case 1: return const RoutePlannerWidget();
          case 2: return const CollectionDashboardWidget();
          case 3: return _buildNotificationFeed(service);
          default: 
            return CollectionAgentDashboard(
              onStartRoute: () => setState(() => _selectedBottomNavIndex = 1),
              onQuickCollect: () => setState(() => _selectedBottomNavIndex = 2),
            );
        }
      case AppUserRole.accountant:
        switch (index) {
          case 0: return const AccountantDashboard();
          case 1: return const CollectionDashboardWidget();
          case 2: return const Center(child: Text('Receipts Manager Panel', style: TextStyle(color: Colors.white)));
          case 3: return const ReportsWidget();
          default: return const AccountantDashboard();
        }
      case AppUserRole.customer:
        switch (index) {
          case 0: return const CustomerDashboard();
          case 1: return const CustomerPortalWidget();
          case 2: return const Center(child: Text('Download Receipts Panel', style: TextStyle(color: Colors.white)));
          default: return const CustomerDashboard();
        }
    }
  }

  Widget _buildBottomNavigationBar(BuildContext context, SupabaseService service) {
    final destinations = _getDestinations(service);
    if (_selectedBottomNavIndex >= destinations.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _selectedBottomNavIndex = 0);
      });
    }

    return NavigationBar(
      selectedIndex: _selectedBottomNavIndex >= destinations.length ? 0 : _selectedBottomNavIndex,
      onDestinationSelected: (idx) => setState(() => _selectedBottomNavIndex = idx),
      destinations: destinations,
    );
  }

  Widget _buildNotificationFeed(SupabaseService service) {
    final alerts = service.getAlerts().where((a) => a['status'] == 'active').toList();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: alerts.length,
      itemBuilder: (context, idx) {
        final a = alerts[idx];
        final customer = service.getCustomerById(a['customer_id']);
        return Card(
          color: AppTheme.darkCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const Icon(Icons.warning, color: AppTheme.dangerRed),
            title: Text(customer?['full_name'] ?? 'Risk Alert', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text('Missed Dues Count: ${a['missed_dues_count']}'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: AppTheme.dangerRed.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
              child: const Text('HIGH RISK', style: TextStyle(color: AppTheme.dangerRed, fontSize: 8, fontWeight: FontWeight.bold)),
            ),
          ),
        );
      },
    );
  }

  bool _shouldShowQuickActionsFab(SupabaseService service) {
    // Only Agent gets the Voice recording entries directly as quick FAB action
    return service.currentRole == AppUserRole.collectionAgent && _selectedBottomNavIndex == 0;
  }

  // ==========================================
  // FLOATING QUICK ACTIONS MENU
  // ==========================================
  Widget _buildQuickActionsFab(BuildContext context, SupabaseService service) {
    return FloatingActionButton.extended(
      icon: const Icon(Icons.mic, color: Colors.white),
      label: const Text('Voice Entry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      backgroundColor: AppTheme.primaryBlue,
      onPressed: () {
        _showVoiceEntryDialog(context, service);
      },
    );
  }

  // Voice speech simulation dialog
  void _showVoiceEntryDialog(BuildContext context, SupabaseService service) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.mic, color: AppTheme.primaryBlue),
                  SizedBox(width: 8),
                  Text('Voice Receipt Input'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Say collection details, e.g. "Ravi Kumar paid 23536" or "Ananya Sharma paid 10000"',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isListeningVoice ? AppTheme.primaryBlue.withValues(alpha: 0.1) : Colors.transparent,
                    ),
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: _isListeningVoice ? AppTheme.primaryBlue : Colors.grey[800],
                      child: IconButton(
                        icon: const Icon(Icons.mic, size: 32, color: Colors.white),
                        onPressed: () async {
                          setDialogState(() => _isListeningVoice = true);
                          await Future.delayed(const Duration(milliseconds: 2000));
                          if (context.mounted) {
                            setDialogState(() {
                              _isListeningVoice = false;
                              _voiceInputTextController.text = "Ravi Kumar paid 23536";
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _voiceInputTextController,
                    decoration: InputDecoration(
                      hintText: 'Recognized speech goes here...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _voiceInputTextController.clear();
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
                  onPressed: () async {
                    if (_voiceInputTextController.text.isNotEmpty) {
                      final nlp = service.parseVoiceCollection(_voiceInputTextController.text);
                      if (nlp['success']) {
                        await service.recordCollection(
                          loanId: nlp['loan_id'],
                          amount: nlp['amount'],
                          paymentMethod: 'upi',
                          notes: 'Voice Entry: "${nlp['raw_text']}"',
                        );
                        _voiceInputTextController.clear();
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Auto-parsed: Recorded ₹${nlp['amount']} for ${nlp['customer']}'),
                              backgroundColor: AppTheme.neonGreen,
                            ),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Could not auto-parse speech. Try saying: "[Customer Name] paid [Amount]"'),
                            backgroundColor: AppTheme.dangerRed,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Confirm Entry', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
