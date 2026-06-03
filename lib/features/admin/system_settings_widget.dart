import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/providers.dart';
import '../../core/widgets/dashboard_section.dart';

class SystemSettingsWidget extends ConsumerStatefulWidget {
  const SystemSettingsWidget({super.key});

  @override
  ConsumerState<SystemSettingsWidget> createState() => _SystemSettingsWidgetState();
}

class _SystemSettingsWidgetState extends ConsumerState<SystemSettingsWidget> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _settings = [];
  final Map<String, TextEditingController> _settingsControllers = {};

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    for (var controller in _settingsControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(supabaseServiceProvider);
      final settings = await service.getSystemSettings();
      
      for (var setting in settings) {
        final key = setting['key'] as String;
        final value = setting['value'] as String;
        if (!_settingsControllers.containsKey(key)) {
          _settingsControllers[key] = TextEditingController(text: value);
        } else {
          _settingsControllers[key]!.text = value;
        }
      }

      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load system settings: $e'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    }
  }

  Future<void> _saveSetting(String key) async {
    final newValue = _settingsControllers[key]?.text.trim() ?? '';
    if (newValue.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final service = ref.read(supabaseServiceProvider);
      await service.updateSystemSetting(key, newValue);
      await _loadSettings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Setting "$key" successfully saved.'),
            backgroundColor: AppTheme.neonGreen,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save setting: $e'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(supabaseServiceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading && _settings.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
          : RefreshIndicator(
              onRefresh: _loadSettings,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Global Settings',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                    ),
                    Text(
                      'Configure platform parameters and system rules.',
                      style: TextStyle(
                        color: isDark ? Colors.grey : const Color(0xFF64748B),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Database Settings list
                    ..._settings.map((setting) {
                      final key = setting['key'] as String;
                      final desc = setting['description'] as String? ?? 'System configuration parameter';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: DashboardSectionCard(
                          title: key.toUpperCase().replaceAll('_', ' '),
                          subtitle: desc,
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _settingsControllers[key],
                                  style: TextStyle(
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    fontSize: 14,
                                  ),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: AppTheme.primaryBlue),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: () => _saveSetting(key),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryBlue,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.all(12),
                                  minimumSize: const Size(44, 44),
                                ),
                                child: const Icon(Icons.save_outlined, color: Colors.white, size: 18),
                              )
                            ],
                          ),
                        ),
                      );
                    }),
                    
                    const SizedBox(height: 12),
                    DashboardSectionCard(
                      title: 'Account Details',
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAccountRow(context, 'Full Name', service.currentUserName),
                          Divider(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                          _buildAccountRow(context, 'Email Address', service.currentUserEmail),
                          Divider(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                          _buildAccountRow(context, 'Status', 'Active Profile'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAccountRow(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.grey : const Color(0xFF64748B),
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
