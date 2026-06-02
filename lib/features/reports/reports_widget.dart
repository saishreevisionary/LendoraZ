import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/supabase_service.dart';
import '../../core/network/providers.dart';

class ReportsWidget extends ConsumerStatefulWidget {
  const ReportsWidget({super.key});

  @override
  ConsumerState<ReportsWidget> createState() => _ReportsWidgetState();
}

class _ReportsWidgetState extends ConsumerState<ReportsWidget> {
  String _selectedReportType = 'collections'; // collections, profits, agents, default
  DateTimeRange? _selectedDateRange;
  bool _isExporting = false;

  final List<Map<String, dynamic>> _reportTypes = [
    {
      'id': 'collections',
      'title': 'Daily Collections Ledger',
      'description': 'Itemized collections, payment modes, and agent mapping logs.',
      'icon': Icons.description_outlined,
    },
    {
      'id': 'profits',
      'title': 'Revenue & Profit Reports',
      'description': 'Summary of interest collections, late fees, and operational payouts.',
      'icon': Icons.insights,
    },
    {
      'id': 'agents',
      'title': 'Agent Field Performance',
      'description': 'Target completions, commute distances, and collection efficiency.',
      'icon': Icons.badge_outlined,
    },
    {
      'id': 'risk',
      'title': 'Risk & Default Summary',
      'description': 'List of accounts flagged as high-risk, missed cycle counts, and aging ledgers.',
      'icon': Icons.warning_amber_rounded,
    }
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reports & Analytics Centre',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Text('Export financial reports and audits', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),

          // Date Range Selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.glassDecoration(context: context, borderOpacity: 0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Audit Period Range', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      _selectedDateRange == null
                          ? 'All Time Records'
                          : '${_selectedDateRange!.start.toString().substring(0, 10)}  to  ${_selectedDateRange!.end.toString().substring(0, 10)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.date_range, size: 16),
                  label: const Text('Pick Dates'),
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2025),
                      lastDate: DateTime(2027),
                    );
                    if (picked != null) {
                      setState(() => _selectedDateRange = picked);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Report Types list
          Expanded(
            child: ListView.builder(
              itemCount: _reportTypes.length,
              itemBuilder: (context, idx) {
                final rep = _reportTypes[idx];
                final isSelected = _selectedReportType == rep['id'];

                return GestureDetector(
                  onTap: () => setState(() => _selectedReportType = rep['id']),
                  child: Card(
                    color: isDark ? AppTheme.darkCard : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isSelected ? AppTheme.primaryBlue : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                        width: isSelected ? 2.0 : 1.0,
                      ),
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: (isSelected ? AppTheme.primaryBlue : Colors.grey).withValues(alpha: 0.1),
                            child: Icon(rep['icon'], color: isSelected ? AppTheme.primaryBlue : Colors.grey),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(rep['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 4),
                                Text(rep['description'], style: const TextStyle(color: Colors.grey, fontSize: 11)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Export Actions
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Export to PDF', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: _isExporting ? null : () => _triggerExport('PDF'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.neonGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.table_chart_outlined),
                  label: const Text('Export to Excel', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: _isExporting ? null : () => _triggerExport('Excel'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _triggerExport(String format) async {
    setState(() => _isExporting = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Formatting transaction ledger databases...'),
              Text('Securing signatures in vault schemas...', style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        );
      },
    );

    // Simulate audit calculations delay
    await Future.delayed(const Duration(milliseconds: 2500));

    if (mounted) {
      Navigator.pop(context); // Close loading dialog
      setState(() => _isExporting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully compiled and saved $_selectedReportType report in $format format.'),
          backgroundColor: AppTheme.neonGreen,
        ),
      );
    }
  }
}
