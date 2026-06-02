import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/supabase_service.dart';
import '../../core/network/providers.dart';

class CRMLeadsWidget extends ConsumerStatefulWidget {
  const CRMLeadsWidget({super.key});

  @override
  ConsumerState<CRMLeadsWidget> createState() => _CRMLeadsWidgetState();
}

class _CRMLeadsWidgetState extends ConsumerState<CRMLeadsWidget> {
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  final _newLeadNameController = TextEditingController();
  final _newLeadPhoneController = TextEditingController();
  final _newLeadAmountController = TextEditingController();

  final List<String> _stages = [
    'new_lead',
    'contacted',
    'interested',
    'approved',
    'rejected',
    'converted',
  ];

  String _getStageTitle(String stage) {
    switch (stage) {
      case 'new_lead': return 'New Lead';
      case 'contacted': return 'Contacted';
      case 'interested': return 'Interested';
      case 'approved': return 'Approved';
      case 'rejected': return 'Rejected';
      case 'converted': return 'Converted';
      default: return stage;
    }
  }

  Color _getStageColor(String stage) {
    switch (stage) {
      case 'new_lead': return AppTheme.primaryBlue;
      case 'contacted': return AppTheme.primaryCyan;
      case 'interested': return AppTheme.warningOrange;
      case 'approved': return AppTheme.neonGreen;
      case 'rejected': return AppTheme.dangerRed;
      case 'converted': return Colors.purple;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(supabaseServiceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final leads = service.getLeads();

    return Padding(
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
                      'Finance CRM Workspace',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Text(
                      'Manage credit approval pipeline stages',
                      style: TextStyle(color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Add Lead'),
                onPressed: () {
                  _showAddLeadDialog(context, service);
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Kanban Horizontal Board Columns
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _stages.length,
              itemBuilder: (context, colIdx) {
                final stage = _stages[colIdx];
                final stageLeads = leads.where((l) => l['status'] == stage).toList();
                final colColor = _getStageColor(stage);

                return Container(
                  width: 280,
                  margin: const EdgeInsets.only(right: 16, bottom: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F1524) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                  ),
                  child: Column(
                    children: [
                      // Stage Title Bar
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: colColor.withValues(alpha: 0.5), width: 2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _getStageTitle(stage),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: colColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                              child: Text(
                                '${stageLeads.length}',
                                style: TextStyle(color: colColor, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Leads cards in stage
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: stageLeads.length,
                          itemBuilder: (context, leadIdx) {
                            final lead = stageLeads[leadIdx];
                            return Card(
                              color: isDark ? AppTheme.darkCard : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                              ),
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(lead['full_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text('Requested: ${_currencyFormat.format(lead['requested_amount'])}', style: const TextStyle(color: AppTheme.primaryCyan, fontSize: 11, fontWeight: FontWeight.bold)),
                                    Text('Phone: ${lead['phone']}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                                    if (lead['notes'] != null) ...[
                                      const SizedBox(height: 6),
                                      Text(lead['notes'], style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 10, fontStyle: FontStyle.italic)),
                                    ],
                                    const Divider(),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Move stage button
                                        TextButton.icon(
                                          style: TextButton.styleFrom(padding: EdgeInsets.zero),
                                          icon: const Icon(Icons.arrow_forward, size: 14),
                                          label: const Text('Move', style: TextStyle(fontSize: 10)),
                                          onPressed: () {
                                            _showMoveLeadDialog(context, lead, service);
                                          },
                                        ),
                                        // WhatsApp call action
                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          icon: const Icon(Icons.phone_in_talk, color: AppTheme.neonGreen, size: 16),
                                          onPressed: () {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Calling lead ${lead['full_name']}...'),
                                                backgroundColor: AppTheme.primaryBlue,
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddLeadDialog(BuildContext context, SupabaseService service) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Register CRM Lead'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _newLeadNameController,
                decoration: const InputDecoration(labelText: 'Applicant Full Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _newLeadPhoneController,
                decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _newLeadAmountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Required Loan Capital (₹)', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _clearLeadInputs();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final amt = double.tryParse(_newLeadAmountController.text) ?? 50000.0;
                service.getLeads().insert(0, {
                  'id': 'lead-${DateTime.now().millisecond}',
                  'full_name': _newLeadNameController.text,
                  'phone': _newLeadPhoneController.text,
                  'requested_amount': amt,
                  'status': 'new_lead',
                  'notes': 'Manually entered credit lead.',
                });
                _clearLeadInputs();
                setState(() {});
                Navigator.pop(context);
              },
              child: const Text('Add to Pipeline'),
            ),
          ],
        );
      },
    );
  }

  void _clearLeadInputs() {
    _newLeadNameController.clear();
    _newLeadPhoneController.clear();
    _newLeadAmountController.clear();
  }

  void _showMoveLeadDialog(BuildContext context, Map<String, dynamic> lead, SupabaseService service) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Transition Lead Stage'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _stages.map((st) {
              return ListTile(
                title: Text(_getStageTitle(st)),
                trailing: lead['status'] == st ? const Icon(Icons.check, color: AppTheme.primaryBlue) : null,
                onTap: () {
                  service.updateLeadStatus(lead['id'], st);
                  Navigator.pop(context);
                  setState(() {});
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
