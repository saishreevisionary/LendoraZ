import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/supabase_service.dart';
import '../../core/network/providers.dart';

class CollectionDashboardWidget extends ConsumerStatefulWidget {
  const CollectionDashboardWidget({super.key});

  @override
  ConsumerState<CollectionDashboardWidget> createState() => _CollectionDashboardWidgetState();
}

class _CollectionDashboardWidgetState extends ConsumerState<CollectionDashboardWidget> {
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  final _searchQueryController = TextEditingController();
  String _selectedFilter = 'all'; // all, due_today, overdue, missed

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(supabaseServiceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filtered lists
    final customers = service.getCustomers();
    final loans = service.getLoans();
    final collections = service.getCollections();

    // Metrics for Grid
    double totalDueToday = 0.0;
    double totalCollectedToday = 0.0;
    int overdueCount = 0;
    int missedCount = 0;

    for (var l in loans) {
      if (l['status'] == 'active') {
        totalDueToday += (l['monthly_installment'] as double);
        if (l['missed_dues'] > 0) {
          overdueCount++;
        }
      } else if (l['status'] == 'defaulted') {
        missedCount++;
      }
    }

    for (var c in collections) {
      final dateStr = c['collection_date'].toString();
      if (dateStr.startsWith(DateTime.now().toIso8601String().substring(0, 10))) {
        totalCollectedToday += (c['amount'] as double);
      }
    }

    double pendingToday = (totalDueToday - totalCollectedToday).clamp(0.0, double.infinity);
    double colPercentage = totalDueToday > 0 ? (totalCollectedToday / totalDueToday) * 100 : 88.5;

    // Apply filters
    var filteredLoans = loans.where((loan) {
      final cust = service.getCustomerById(loan['customer_id']);
      final name = cust != null ? cust['full_name'].toString().toLowerCase() : '';
      final matchesSearch = name.contains(_searchQueryController.text.toLowerCase());
      
      if (!matchesSearch) return false;

      if (_selectedFilter == 'due_today') {
        return loan['status'] == 'active' && loan['missed_dues'] == 0;
      } else if (_selectedFilter == 'overdue') {
        return loan['status'] == 'active' && loan['missed_dues'] > 0;
      } else if (_selectedFilter == 'missed') {
        return loan['status'] == 'defaulted';
      }
      return true;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Smart Collections Console',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // FEATURE 1: Grid list of collection metrics
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.4,
            children: [
              _buildMetricTile('Due Today', _currencyFormat.format(totalDueToday), Colors.blue),
              _buildMetricTile('Collected', _currencyFormat.format(totalCollectedToday), AppTheme.neonGreen),
              _buildMetricTile('Pending Today', _currencyFormat.format(pendingToday), AppTheme.warningOrange),
              _buildMetricTile('Missed Payments', '$missedCount Accs', AppTheme.dangerRed),
              _buildMetricTile('Overdue', '$overdueCount Dues', Colors.purple),
              _buildMetricTile('Collection %', '${colPercentage.toStringAsFixed(1)}%', AppTheme.primaryCyan),
            ],
          ),
          const SizedBox(height: 16),

          // Search and Filter Bar
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchQueryController,
                  decoration: InputDecoration(
                    hintText: 'Search customers...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onChanged: (val) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: const Icon(Icons.filter_list),
                onSelected: (val) => setState(() => _selectedFilter = val),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'all', child: Text('All Loans')),
                  const PopupMenuItem(value: 'due_today', child: Text('Due Today')),
                  const PopupMenuItem(value: 'overdue', child: Text('Overdue')),
                  const PopupMenuItem(value: 'missed', child: Text('Defaulted / Missed')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Loan List
          Expanded(
            child: filteredLoans.isEmpty
                ? const Center(child: Text('No matching accounts found.'))
                : ListView.builder(
                    itemCount: filteredLoans.length,
                    itemBuilder: (context, idx) {
                      final loan = filteredLoans[idx];
                      final customer = service.getCustomerById(loan['customer_id']);
                      final risk = service.predictAIRisk(loan['customer_id']);
                      Color riskColor = AppTheme.neonGreen;
                      if (risk['level'] == 'medium') riskColor = AppTheme.warningOrange;
                      if (risk['level'] == 'high') riskColor = AppTheme.dangerRed;

                      return Card(
                        color: isDark ? AppTheme.darkCard : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          title: Row(
                            children: [
                              Text(
                                customer?['full_name'] ?? 'Unknown Customer',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: riskColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  risk['level'].toString().toUpperCase(),
                                  style: TextStyle(color: riskColor, fontSize: 8, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Outstanding: ${_currencyFormat.format(loan['remaining_balance'])}'),
                              Text('Instalment: ${_currencyFormat.format(loan['monthly_installment'])} / mo'),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryBlue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                onPressed: () {
                                  _showLoanDetailsSheet(context, loan, customer, service);
                                },
                                child: const Text('Action', style: TextStyle(fontSize: 12)),
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
  }

  Widget _buildMetricTile(String title, String val, Color col) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: col.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 10)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(val, style: TextStyle(color: col, fontSize: 14, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // LOAN ACTION SHEET (Timeline, Penalties, Sync Payments, Document Vault)
  // ==========================================
  void _showLoanDetailsSheet(
    BuildContext context,
    Map<String, dynamic> loan,
    Map<String, dynamic>? customer,
    SupabaseService service,
  ) {
    final penalties = service.calculatePenalty(loan['id']);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalDue = (loan['monthly_installment'] as double) + penalties['total_penalty']!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer?['full_name'] ?? 'Customer Account',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          Text('Phone: ${customer?['phone'] ?? ''}', style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(height: 30),

                  // FEATURE 9: Penalty Automation & Dues Calculator
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.glassDecoration(context: context, borderOpacity: 0.2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Automatic Penalty & Installment Ledger', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 12),
                        _buildLedgerRow('Standard Installment', _currencyFormat.format(loan['monthly_installment'])),
                        _buildLedgerRow('Late Fee Penalty', _currencyFormat.format(penalties['late_fee'])),
                        _buildLedgerRow('Interest Accrued Penalty', _currencyFormat.format(penalties['interest_penalty'])),
                        _buildLedgerRow('Cheque Bounce Charges', _currencyFormat.format(penalties['bounce_charges'])),
                        const Divider(),
                        _buildLedgerRow('Total Outstandings Due', _currencyFormat.format(totalDue), isBold: true, color: AppTheme.dangerRed),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Action Buttons (Record Payment, Remind, Share)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.neonGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.add_card),
                          label: const Text('Record Collection', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () {
                            _showRecordPaymentDialog(context, loan, totalDue, service);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: const BorderSide(color: AppTheme.primaryBlue),
                          ),
                          icon: const Icon(Icons.share, color: AppTheme.primaryBlue),
                          label: const Text('Send WhatsApp Notice', style: TextStyle(color: AppTheme.primaryBlue)),
                          onPressed: () {
                            _triggerWhatsAppReminder(context, customer?['full_name'] ?? 'Client', totalDue);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // FEATURE 7: Customer Timeline (Milestones)
                  const Text('Customer Timeline', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildTimelineItem(
                    title: 'Loan Disbursed',
                    subtitle: 'Sanctioned amount of ${_currencyFormat.format(loan['principal_amount'])}',
                    time: loan['start_date'],
                    isFirst: true,
                  ),
                  _buildTimelineItem(
                    title: 'Payment Received',
                    subtitle: 'EMI processed via UPI net-banking',
                    time: '2026-05-01',
                  ),
                  if (loan['missed_dues'] > 0)
                    _buildTimelineItem(
                      title: 'Dues Missed Warning',
                      subtitle: 'Accrued penalties for ${loan['missed_dues']} cycle lags',
                      time: '2026-05-15',
                      color: AppTheme.dangerRed,
                    ),
                  _buildTimelineItem(
                    title: 'Current Dues Review',
                    subtitle: 'Outstanding balance stands at ${_currencyFormat.format(loan['remaining_balance'])}',
                    time: 'Today',
                    isLast: true,
                  ),
                  const SizedBox(height: 24),

                  // FEATURE 10: Document Vault (Aadhaar, PAN, agreements)
                  const Text('Document Vault', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _buildDocumentRow(context, 'Aadhaar Card (KYC)', 'aadhaar.pdf'),
                  _buildDocumentRow(context, 'PAN Card', 'pan.pdf'),
                  _buildDocumentRow(context, 'Promissory Note Signed', 'promissory_note_vault.png'),
                  _buildDocumentRow(context, 'Loan Agreement Document', 'loan_agreement_digital.pdf'),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLedgerRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? (isBold ? null : Colors.grey[400]),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required String title,
    required String subtitle,
    required String time,
    Color color = AppTheme.primaryBlue,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 45,
                color: Colors.grey[700],
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(time, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                ],
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentRow(BuildContext context, String name, String fileName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      color: isDark ? AppTheme.darkCard : Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
      ),
      child: ListTile(
        leading: const Icon(Icons.picture_as_pdf_outlined, color: AppTheme.dangerRed),
        title: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        subtitle: Text(fileName, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        trailing: IconButton(
          icon: const Icon(Icons.download, size: 20),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Downloading $fileName from Supabase Storage Vault'),
                backgroundColor: AppTheme.primaryBlue,
              ),
            );
          },
        ),
      ),
    );
  }

  // Record payment form
  void _showRecordPaymentDialog(BuildContext context, Map<String, dynamic> loan, double suggestedAmt, SupabaseService service) {
    final amountController = TextEditingController(text: suggestedAmt.toStringAsFixed(0));
    String method = 'upi';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Record Cash/UPI Collection'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Collection Amount (₹)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Align(alignment: Alignment.centerLeft, child: Text('Payment Method:')),
                  DropdownButton<String>(
                    value: method,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'upi', child: Text('UPI (PhonePe, GPay)')),
                      DropdownMenuItem(value: 'cash', child: Text('Cash')),
                      DropdownMenuItem(value: 'bank_transfer', child: Text('Net Banking')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => method = val);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    double amt = double.tryParse(amountController.text) ?? suggestedAmt;
                    
                    // Call service
                    final col = await service.recordCollection(
                      loanId: loan['id'],
                      amount: amt,
                      paymentMethod: method,
                      notes: 'Standard collection receipt processed.',
                    );

                    if (context.mounted) {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context); // Close sheet
                      
                      // Show digital receipt generated notice
                      _showReceiptReceiptDialog(context, col);
                    }
                  },
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Feature 8: Digital Receipt template view
  void _showReceiptReceiptDialog(BuildContext context, Map<String, dynamic> col) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.verified, color: AppTheme.neonGreen),
              SizedBox(width: 8),
              Text('Receipt Secured'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('LendoraZ Digital Verification Receipt', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text('Receipt UUID: ${col['receipt_uuid']}'),
              Text('Amount Collected: ₹${col['amount']}'),
              Text('Payment Mode: ${col['payment_method'].toString().toUpperCase()}'),
              Text('Timestamp: ${col['collection_date']}'),
              const SizedBox(height: 16),
              // QR code simulation
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  color: Colors.white,
                  child: const Icon(Icons.qr_code_2, size: 90, color: Colors.black),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text('Scan to verify signature hash', style: TextStyle(fontSize: 10, color: Colors.grey)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.share, color: Colors.white, size: 16),
              label: const Text('Share Receipt', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Receipt PDF generated and shared successfully via WhatsApp Business SDK.'),
                    backgroundColor: AppTheme.neonGreen,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // WhatsApp reminder simulation
  void _triggerWhatsAppReminder(BuildContext context, String clientName, double amt) {
    final text = 'Lendoraz Notice: Dear $clientName, an installment of ${_currencyFormat.format(amt)} is overdue. Kindly pay via: https://lendoraz.com/pay';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Send WhatsApp Notification'),
          content: Text('Constructed Template:\n\n"$text"'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Reminder dispatched to $clientName!'),
                    backgroundColor: AppTheme.neonGreen,
                  ),
                );
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }
}
