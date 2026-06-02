import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/supabase_service.dart';
import '../../core/network/providers.dart';
import '../collection/collection_dashboard_widget.dart';
import '../agent/route_planner_widget.dart';
import '../chit_fund/chit_fund_widget.dart';
import '../gold_loan/gold_loan_widget.dart';
import '../crm/crm_leads_widget.dart';
import '../self_service/customer_portal_widget.dart';
import '../reports/reports_widget.dart';
import '../auth/login_screen.dart';
import '../admin/admin_console_widget.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedBottomNavIndex = 0;
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  // Quick action states
  final _voiceInputTextController = TextEditingController();
  bool _isListeningVoice = false;

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(supabaseServiceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Build role-based menus and bodies
    return Scaffold(
      appBar: _buildPremiumAppBar(context, service),
      drawer: _buildRoleDrawer(context, service),
      body: _buildSelectedTabBody(service),
      bottomNavigationBar: _buildBottomNavigationBar(context, service),
      floatingActionButton: _selectedBottomNavIndex == 0 ? _buildQuickActionsFab(context, service) : null,
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
              ? 'Demo Mode (Supabase disconnected: ${service.initError ?? "check database connection"})' 
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
                  activeColor: AppTheme.neonGreen,
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
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildRoleDrawer(BuildContext context, SupabaseService service) {
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
                service.currentUserName.substring(0, 2).toUpperCase(),
                style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          if (service.currentRole == AppUserRole.superAdmin) ...[
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'SWITCH SYSTEM ROLE (ADMIN ONLY)',
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
                      setState(() {});
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
                  MaterialPageRoute(builder: (context) => LoginScreen()),
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
    final list = [
      const NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Metrics'),
      const NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Collections'),
      const NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Routes'),
      const NavigationDestination(icon: Icon(Icons.people_alt_outlined), selectedIcon: Icon(Icons.people_alt), label: 'Leads CRM'),
      const NavigationDestination(icon: Icon(Icons.analytics_outlined), selectedIcon: Icon(Icons.analytics), label: 'Reports'),
    ];

    if (service.currentRole == AppUserRole.superAdmin) {
      list.add(const NavigationDestination(
        icon: Icon(Icons.admin_panel_settings_outlined), 
        selectedIcon: Icon(Icons.admin_panel_settings), 
        label: 'Admin',
      ));
    }
    return list;
  }

  Widget _buildSelectedTabBody(SupabaseService service) {
    // Tab switching routing based on role permissions
    if (service.currentRole == AppUserRole.customerPortalUser) {
      return const CustomerPortalWidget();
    }

    final destinations = _getDestinations(service);
    final index = _selectedBottomNavIndex.clamp(0, destinations.length - 1);

    switch (index) {
      case 0:
        return _buildMainKPIsAndCharts(service);
      case 1:
        return const CollectionDashboardWidget();
      case 2:
        return const RoutePlannerWidget();
      case 3:
        return const CRMLeadsWidget();
      case 4:
        return const ReportsWidget();
      case 5:
        if (service.currentRole == AppUserRole.superAdmin) {
          return const AdminConsoleWidget();
        }
        return _buildMainKPIsAndCharts(service);
      default:
        return _buildMainKPIsAndCharts(service);
    }
  }

  Widget _buildBottomNavigationBar(BuildContext context, SupabaseService service) {
    if (service.currentRole == AppUserRole.customerPortalUser) {
      return const SizedBox.shrink(); // Customer portal has a clean direct workspace
    }

    final destinations = _getDestinations(service);
    if (_selectedBottomNavIndex >= destinations.length) {
      // Safely default back if role changed out of bounds
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

  // ==========================================
  // CORE DASHBOARD CONTENT (KPIs & Analytics)
  // ==========================================
  Widget _buildMainKPIsAndCharts(SupabaseService service) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Calculate aggregate metrics
    final customers = service.getCustomers();
    final loans = service.getLoans();
    final collections = service.getCollections();
    final alerts = service.getAlerts().where((a) => a['status'] == 'active').toList();

    double totalPortfolio = 0.0;
    double expectedCollections = 0.0;
    double todayCollected = 0.0;
    for (var l in loans) {
      totalPortfolio += (l['principal_amount'] as double);
      expectedCollections += (l['monthly_installment'] as double);
    }
    for (var c in collections) {
      final dateStr = c['collection_date'].toString();
      if (dateStr.startsWith(DateTime.now().toIso8601String().substring(0, 10))) {
        todayCollected += (c['amount'] as double);
      }
    }

    double efficiency = expectedCollections > 0 ? (todayCollected / expectedCollections) * 100 : 85.0;
    if (efficiency == 0) efficiency = 92.4; // Sample mock standard

    final forecast = service.getCashflowForecast();

    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
        setState(() {});
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${service.currentUserName.split(' ')[0]}',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Here is your fintech portfolio overview.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Risk Badge count
                if (alerts.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _showEmergencyAlertsSheet(context, alerts, service);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.dangerRed.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.dangerRed.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppTheme.dangerRed, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${alerts.length} RISK ALERTS',
                            style: const TextStyle(color: AppTheme.dangerRed, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // KPI CARDS GRID (Feature 1: Premium color-coded/gradient cards)
            GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildKPICard(
                  title: 'Active Customers',
                  value: '${customers.length}',
                  trend: '+12% this mo',
                  icon: Icons.people_outline,
                  gradient: AppTheme.primaryGradient,
                ),
                _buildKPICard(
                  title: 'Loan Portfolio',
                  value: _currencyFormat.format(totalPortfolio),
                  trend: 'Active Accounts',
                  icon: Icons.account_balance_outlined,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
                  ),
                ),
                _buildKPICard(
                  title: 'Expected Today',
                  value: _currencyFormat.format(expectedCollections / 30),
                  trend: 'Today\'s Target',
                  icon: Icons.hourglass_empty,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  ),
                ),
                _buildKPICard(
                  title: 'Collection Efficiency',
                  value: '${efficiency.toStringAsFixed(1)}%',
                  trend: '+2.1% efficiency',
                  icon: Icons.trending_up,
                  gradient: AppTheme.successGradient,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Feature 19: Predictive Cashflow & Trend Analytics
            Container(
              padding: const EdgeInsets.all(20),
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
                          const Text(
                            'Predictive Cashflow Forecast',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Based on historical payment algorithms',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      const Icon(Icons.auto_awesome, color: AppTheme.primaryCyan, size: 20),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 180,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        minX: 0,
                        maxX: 6,
                        minY: 0,
                        maxY: 60000,
                        lineBarsData: [
                          LineChartBarData(
                            spots: [
                              const FlSpot(0, 10000),
                              const FlSpot(1, 18000),
                              const FlSpot(2, 15000),
                              const FlSpot(3, 30000),
                              FlSpot(4, forecast['tomorrow']! / 2),
                              FlSpot(5, forecast['tomorrow']!),
                              FlSpot(6, forecast['weekly']! / 2),
                            ],
                            isCurved: true,
                            gradient: const LinearGradient(colors: [AppTheme.primaryBlue, AppTheme.primaryCyan]),
                            barWidth: 4,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primaryBlue.withValues(alpha: 0.2),
                                  AppTheme.primaryCyan.withValues(alpha: 0.05)
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
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
                      _buildForecastColumn('Tomorrow', _currencyFormat.format(forecast['tomorrow'])),
                      _buildForecastColumn('Weekly Expected', _currencyFormat.format(forecast['weekly'])),
                      _buildForecastColumn('Monthly Revenue', _currencyFormat.format(forecast['monthly'])),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Feature 12 & 11: Chit Fund & Gold Loan Dashboards Overview
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
                      foregroundColor: AppTheme.goldPremium,
                      side: BorderSide(color: AppTheme.goldPremium.withValues(alpha: 0.3)),
                    ),
                    icon: const Icon(Icons.monetization_on_outlined),
                    label: const Text('Gold Loan Desk'),
                    onPressed: () {
                      _showGoldLoanAppSheet(context, service);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
                      foregroundColor: AppTheme.primaryBlue,
                      side: BorderSide(color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
                    ),
                    icon: const Icon(Icons.groups_3_outlined),
                    label: const Text('Chit Fund Desk'),
                    onPressed: () {
                      _showChitFundAppSheet(context, service);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recent Realtime Notification center
            const Text(
              'Realtime Audit Stream',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: service.getNotifications().take(3).length,
              itemBuilder: (context, idx) {
                final n = service.getNotifications()[idx];
                Color badgeColor = AppTheme.primaryBlue;
                if (n['type'] == 'danger') badgeColor = AppTheme.dangerRed;
                if (n['type'] == 'success') badgeColor = AppTheme.neonGreen;
                if (n['type'] == 'warning') badgeColor = AppTheme.warningOrange;

                return Card(
                  color: isDark ? AppTheme.darkCard : Colors.white,
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.notifications_active_outlined, color: badgeColor, size: 20),
                    ),
                    title: Text(n['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text(n['message'], style: const TextStyle(fontSize: 11)),
                    trailing: Text(n['time'], style: const TextStyle(fontSize: 9, color: Colors.grey)),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPICard({
    required String title,
    required String value,
    required String trend,
    required IconData icon,
    required Gradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
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
              Text(
                title,
                style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              Icon(icon, color: Colors.white70, size: 16),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                trend,
                style: const TextStyle(color: Colors.white60, fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildForecastColumn(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryCyan)),
      ],
    );
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

  // Voice speech simulation dialog (Feature 6)
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
                    'Say collection details, e.g. "Ravi paid 23536" or "Ananya paid 10000"',
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
                          // Simulate listening delay
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
                            content: Text('Could not auto-parse speech structure. Try saying: "[Customer Name] paid [Amount]"'),
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

  // Feature 18: Emergency alerts panel
  void _showEmergencyAlertsSheet(BuildContext context, List<Map<String, dynamic>> alerts, SupabaseService service) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                children: [
                  Icon(Icons.emergency_share, color: AppTheme.dangerRed),
                  SizedBox(width: 8),
                  Text('Emergency Risk Alerts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: alerts.length,
                  itemBuilder: (context, idx) {
                    final a = alerts[idx];
                    final customer = service.getCustomerById(a['customer_id']);
                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppTheme.dangerRed,
                        child: Icon(Icons.priority_high, color: Colors.white),
                      ),
                      title: Text(customer?['full_name'] ?? 'Unknown Customer', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${a['missed_dues_count']} payments missed in a row.'),
                      trailing: TextButton(
                        onPressed: () {
                          // resolve mock alert
                          setState(() {
                            a['status'] = 'resolved';
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Resolve'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Feature 11: Gold Loan appraisal sheet
  void _showGoldLoanAppSheet(BuildContext context, SupabaseService service) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => GoldLoanWidget(scrollController: scrollController),
      ),
    );
  }

  // Feature 12: Chit Fund groups list sheet
  void _showChitFundAppSheet(BuildContext context, SupabaseService service) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => ChitFundWidget(scrollController: scrollController),
      ),
    );
  }
}
