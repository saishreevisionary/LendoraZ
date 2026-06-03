import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/animations.dart';
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Finance CRM Workspace',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: () => _showAddLeadDialog(context, service),
                    borderRadius: BorderRadius.circular(12),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF2563EB), // Modern Royal Blue
                            Color(0xFF0D9488), // Modern Teal/Cyan
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.add_rounded, size: 16, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Add Lead',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Manage credit approval pipeline stages',
                style: TextStyle(color: Colors.grey, fontSize: 13),
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
                                final card = CRMLeadCard(
                                  lead: lead,
                                  stageColor: colColor,
                                  currencyFormat: _currencyFormat,
                                  index: leadIdx,
                                  onCall: () => _callLead(context, lead),
                                  onMove: () => _showMoveLeadDialog(context, lead, service),
                                  onConvert: () => _showConvertConfirmationDialog(context, lead, service),
                                  onDelete: () => _showDeleteConfirmDialog(context, lead, service),
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
                try {
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
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Conversion failed: $e'),
                        backgroundColor: AppTheme.dangerRed,
                        duration: const Duration(seconds: 6),
                      ),
                    );
                  }
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
                try {
                  await service.deleteLead(lead['id'].toString());
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lead for ${lead['full_name']} has been deleted.'),
                        backgroundColor: AppTheme.dangerRed,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Deletion failed: $e'),
                        backgroundColor: AppTheme.dangerRed,
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
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
                try {
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Lead successfully registered and added to pipeline.'),
                        backgroundColor: AppTheme.neonGreen,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to save lead: $e'),
                        backgroundColor: AppTheme.dangerRed,
                        duration: const Duration(seconds: 6),
                      ),
                    );
                  }
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

class CRMLeadCard extends StatefulWidget {
  final Map<String, dynamic> lead;
  final Color stageColor;
  final NumberFormat currencyFormat;
  final VoidCallback onCall;
  final VoidCallback onMove;
  final VoidCallback onConvert;
  final VoidCallback onDelete;
  final int index;

  const CRMLeadCard({
    super.key,
    required this.lead,
    required this.stageColor,
    required this.currencyFormat,
    required this.onCall,
    required this.onMove,
    required this.onConvert,
    required this.onDelete,
    required this.index,
  });

  @override
  State<CRMLeadCard> createState() => _CRMLeadCardState();
}

class _CRMLeadCardState extends State<CRMLeadCard> {
  bool _isHovered = false;

  IconData _getStageIcon(String stage) {
    switch (stage) {
      case 'new_lead': return Icons.new_releases_outlined;
      case 'contacted': return Icons.phone_in_talk_outlined;
      case 'interested': return Icons.thumb_up_alt_outlined;
      case 'approved': return Icons.check_circle_outline;
      case 'rejected': return Icons.cancel_outlined;
      case 'converted': return Icons.stars_outlined;
      default: return Icons.help_outline;
    }
  }

  String _getStageTitle(String stage) {
    switch (stage) {
      case 'new_lead': return 'New';
      case 'contacted': return 'Contact';
      case 'interested': return 'Interested';
      case 'approved': return 'Approved';
      case 'rejected': return 'Rejected';
      case 'converted': return 'Converted';
      default: return stage;
    }
  }

  double _getProgress(String stage) {
    switch (stage) {
      case 'new_lead': return 0.16;
      case 'contacted': return 0.33;
      case 'interested': return 0.50;
      case 'approved': return 0.80;
      case 'converted': return 1.0;
      case 'rejected': return 0.0;
      default: return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stage = widget.lead['status'] ?? 'new_lead';
    final IconData stageIcon = _getStageIcon(stage);
    
    // Tinted card bg matching the stage color
    final Color cardBg = isDark
        ? Color.lerp(AppTheme.darkCard, widget.stageColor, 0.06)!
        : Color.lerp(Colors.white, widget.stageColor, 0.045)!;

    final Color borderCol = _isHovered
        ? widget.stageColor.withValues(alpha: 0.6)
        : (isDark ? widget.stageColor.withValues(alpha: 0.15) : widget.stageColor.withValues(alpha: 0.2));

    final cardContent = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: borderCol,
            width: _isHovered ? 1.5 : 1.0,
          ),
          boxShadow: [
            if (_isHovered)
              BoxShadow(
                color: widget.stageColor.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 5),
                spreadRadius: 1,
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left indicator bar with top-to-bottom gradient
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.stageColor,
                        widget.stageColor.withValues(alpha: 0.5),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name and Action Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Avatar Badge with visual gradient ring
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    widget.stageColor,
                                    widget.stageColor.withValues(alpha: 0.7),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: widget.stageColor.withValues(alpha: 0.25),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1.5),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                widget.lead['full_name'] != null && widget.lead['full_name'].isNotEmpty
                                    ? widget.lead['full_name'][0].toUpperCase()
                                    : 'L',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            
                            // Title & Stage Badge
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.lead['full_name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      letterSpacing: 0.1,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  // Small Stage Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: widget.stageColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(stageIcon, size: 9, color: widget.stageColor),
                                        const SizedBox(width: 3),
                                        Text(
                                          _getStageTitle(stage).toUpperCase(),
                                          style: TextStyle(
                                            color: widget.stageColor,
                                            fontSize: 7.5,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Pop Up Menu
                            PopupMenuButton<String>(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.more_vert, size: 18),
                              onSelected: (val) {
                                if (val == 'move') {
                                  widget.onMove();
                                } else if (val == 'call') {
                                  widget.onCall();
                                } else if (val == 'convert') {
                                  widget.onConvert();
                                } else if (val == 'delete') {
                                  widget.onDelete();
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
                                if (widget.lead['status'] != 'converted')
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
                        const SizedBox(height: 10),
                        
                        // Amount Badge & Phone Quick Call
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Requested amount chip
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                              decoration: BoxDecoration(
                                color: widget.stageColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.account_balance_wallet_outlined,
                                    size: 11,
                                    color: widget.stageColor,
                                  ),
                                  const SizedBox(width: 4.5),
                                  Text(
                                    widget.currencyFormat.format(widget.lead['requested_amount']),
                                    style: TextStyle(
                                      color: widget.stageColor,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Phone & Call Quick Action
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.phone_outlined, size: 11, color: isDark ? Colors.white38 : Colors.black38),
                                const SizedBox(width: 4),
                                Text(
                                  widget.lead['phone'] ?? 'No phone',
                                  style: TextStyle(
                                    color: isDark ? Colors.white54 : Colors.black54,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: widget.onCall,
                                  borderRadius: BorderRadius.circular(4),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.neonGreen.withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.phone,
                                      size: 10,
                                      color: AppTheme.neonGreen,
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),

                        // Notes Bubble if available
                        if (widget.lead['notes'] != null && widget.lead['notes'].toString().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF161E2E) : Colors.white.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark ? Colors.white10 : widget.stageColor.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 10,
                                  color: isDark ? Colors.white38 : Colors.black38,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    widget.lead['notes'],
                                    style: TextStyle(
                                      color: isDark ? Colors.white60 : Colors.black54,
                                      fontSize: 9.5,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        
                        // Progress bar at the very bottom
                        if (stage != 'rejected') ...[
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: _getProgress(stage),
                              backgroundColor: isDark ? Colors.white10 : Colors.black12.withValues(alpha: 0.04),
                              valueColor: AlwaysStoppedAnimation<Color>(widget.stageColor),
                              minHeight: 2.5,
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return SlideFadeIn(
      delay: widget.index * 60, // staggered animation delay!
      duration: const Duration(milliseconds: 400),
      slideOffset: 0.08,
      child: AnimatedScale(
        scale: _isHovered ? 1.025 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: cardContent,
      ),
    );
  }
}

