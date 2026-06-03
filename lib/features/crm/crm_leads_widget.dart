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
  void dispose() {
    _newLeadNameController.dispose();
    _newLeadPhoneController.dispose();
    _newLeadAmountController.dispose();
    super.dispose();
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

                return DragTarget<Map<String, dynamic>>(
                  onWillAcceptWithDetails: (details) => details.data['status'] != stage,
                  onAcceptWithDetails: (details) async {
                    final lead = details.data;
                    if (stage == 'converted') {
                      _showConvertConfirmationDialog(context, lead, service);
                    } else {
                      await service.updateLeadStatus(lead['id'], stage);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Moved ${lead['full_name']} to ${_getStageTitle(stage)}'),
                            backgroundColor: colColor,
                          ),
                        );
                      }
                    }
                  },
                  builder: (context, candidateData, rejectedData) {
                    final isOver = candidateData.isNotEmpty;
                    return Container(
                      width: 280,
                      margin: const EdgeInsets.only(right: 16, bottom: 8),
                      decoration: BoxDecoration(
                        color: isOver
                            ? colColor.withValues(alpha: isDark ? 0.08 : 0.05)
                            : (isDark ? const Color(0xFF0F1524) : Colors.grey[100]),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isOver ? colColor : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                          width: isOver ? 2.0 : 1.0,
                        ),
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
                                final card = Card(
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
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                lead['full_name'],
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            PopupMenuButton<String>(
                                              padding: EdgeInsets.zero,
                                              icon: const Icon(Icons.more_vert, size: 18),
                                              onSelected: (val) {
                                                if (val == 'move') {
                                                  _showMoveLeadDialog(context, lead, service);
                                                } else if (val == 'call') {
                                                  _callLead(context, lead);
                                                } else if (val == 'convert') {
                                                  _showConvertConfirmationDialog(context, lead, service);
                                                } else if (val == 'delete') {
                                                  _showDeleteConfirmDialog(context, lead, service);
                                                }
                                              },
                                              itemBuilder: (context) => [
                                                const PopupMenuItem(
                                                  value: 'call',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.phone, size: 16, color: AppTheme.neonGreen),
                                                      SizedBox(width: 8),
                                                      Text('Call Applicant'),
                                                    ],
                                                  ),
                                                ),
                                                const PopupMenuItem(
                                                  value: 'move',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.drive_file_move, size: 16, color: AppTheme.primaryBlue),
                                                      SizedBox(width: 8),
                                                      Text('Move Stage'),
                                                    ],
                                                  ),
                                                ),
                                                if (lead['status'] != 'converted')
                                                  const PopupMenuItem(
                                                    value: 'convert',
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.person_add, size: 16, color: AppTheme.goldPremium),
                                                        SizedBox(width: 8),
                                                        Text('Convert Customer'),
                                                      ],
                                                    ),
                                                  ),
                                                const PopupMenuItem(
                                                  value: 'delete',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.delete, size: 16, color: AppTheme.dangerRed),
                                                      SizedBox(width: 8),
                                                      Text('Delete Lead'),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text('Requested: ${_currencyFormat.format(lead['requested_amount'])}', style: const TextStyle(color: AppTheme.primaryCyan, fontSize: 11, fontWeight: FontWeight.bold)),
                                        Text('Phone: ${lead['phone']}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                                        if (lead['notes'] != null) ...[
                                          const SizedBox(height: 6),
                                          Text(lead['notes'], style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 10, fontStyle: FontStyle.italic)),
                                        ],
                                      ],
                                    ),
                                  ),
                                );

                                return LongPressDraggable<Map<String, dynamic>>(
                                  data: lead,
                                  feedback: Material(
                                    type: MaterialType.transparency,
                                    child: SizedBox(
                                      width: 260,
                                      child: card,
                                    ),
                                  ),
                                  childWhenDragging: Opacity(
                                    opacity: 0.3,
                                    child: card,
                                  ),
                                  child: card,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _callLead(BuildContext context, Map<String, dynamic> lead) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling lead ${lead['full_name']}...'),
        backgroundColor: AppTheme.primaryBlue,
      ),
    );
  }

  void _showConvertConfirmationDialog(BuildContext context, Map<String, dynamic> lead, SupabaseService service) {
    final loanAmountController = TextEditingController(text: (lead['requested_amount'] ?? 50000.0).toString());
    final interestRateController = TextEditingController(text: '12.0');
    final termMonthsController = TextEditingController(text: '12');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.person_add, color: AppTheme.goldPremium),
              const SizedBox(width: 8),
              Text('Convert ${lead['full_name']}'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Converting this lead will automatically register them as a customer and issue an active loan.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: loanAmountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Principal Loan Amount (₹)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: interestRateController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Annual Interest Rate (%)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: termMonthsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Term Duration (Months)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldPremium,
                foregroundColor: Colors.black,
              ),
              onPressed: () async {
                final amt = double.tryParse(loanAmountController.text) ?? (lead['requested_amount'] ?? 50000.0);
                final rate = double.tryParse(interestRateController.text) ?? 12.0;
                final term = int.tryParse(termMonthsController.text) ?? 12;

                await service.convertLeadToCustomer(
                  lead: lead,
                  loanAmount: amt,
                  interestRate: rate,
                  termMonths: term,
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lead converted! Customer profile & Loan issued for ${lead['full_name']}.'),
                      backgroundColor: AppTheme.neonGreen,
                    ),
                  );
                }
              },
              child: const Text('Issue Loan & Convert'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, Map<String, dynamic> lead, SupabaseService service) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete CRM Lead'),
          content: Text('Are you sure you want to permanently delete the lead for ${lead['full_name']}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed, foregroundColor: Colors.white),
              onPressed: () async {
                await service.deleteLead(lead['id']);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lead for ${lead['full_name']} has been deleted.'),
                      backgroundColor: AppTheme.dangerRed,
                    ),
                  );
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
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
              onPressed: () async {
                final amt = double.tryParse(_newLeadAmountController.text) ?? 50000.0;
                await service.addLead(
                  fullName: _newLeadNameController.text.trim(),
                  phone: _newLeadPhoneController.text.trim(),
                  requestedAmount: amt,
                  notes: 'Manually entered credit lead.',
                );
                _clearLeadInputs();
                if (context.mounted) {
                  Navigator.pop(context);
                }
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
                onTap: () async {
                  if (st == 'converted') {
                    Navigator.pop(context);
                    _showConvertConfirmationDialog(context, lead, service);
                  } else {
                    await service.updateLeadStatus(lead['id'], st);
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
