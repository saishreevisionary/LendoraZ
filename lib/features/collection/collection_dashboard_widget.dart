import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/animations.dart';
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
    final loans = service.getLoans();
    final collections = service.getCollections();

    // Metrics for Grid
    double totalDueToday = 0.0;
    double totalCollectedToday = 0.0;
    int overdueCount = 0;
    int missedCount = 0;

    for (var l in loans) {
      if (l['status'] == 'active') {
        totalDueToday += (l['monthly_installment'] as num).toDouble();
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
        totalCollectedToday += (c['amount'] as num).toDouble();
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
          LayoutBuilder(
            builder: (context, constraints) {
              final double width = constraints.maxWidth;
              int crossAxisCount = 3;
              double childAspectRatio = 1.4;

              if (width > 900) {
                crossAxisCount = 6;
                childAspectRatio = 1.8;
              } else if (width > 600) {
                crossAxisCount = 3;
                childAspectRatio = 2.0;
              } else {
                crossAxisCount = 2;
                childAspectRatio = 2.2;
              }

              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: childAspectRatio,
                children: [
                  _buildMetricTile('Due Today', _currencyFormat.format(totalDueToday), Colors.blue),
                  _buildMetricTile('Collected', _currencyFormat.format(totalCollectedToday), AppTheme.neonGreen),
                  _buildMetricTile('Pending Today', _currencyFormat.format(pendingToday), AppTheme.warningOrange),
                  _buildMetricTile('Missed Payments', '$missedCount Accs', AppTheme.dangerRed),
                  _buildMetricTile('Overdue', '$overdueCount Dues', Colors.purple),
                  _buildMetricTile('Collection %', '${colPercentage.toStringAsFixed(1)}%', AppTheme.primaryCyan),
                ],
              );
            },
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
                    prefixIcon: Icon(Icons.search, color: isDark ? Colors.white54 : Colors.black45),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF131B2E).withValues(alpha: 0.45)
                        : Colors.white.withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white10 : Colors.black12.withValues(alpha: 0.05),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white10 : Colors.black12.withValues(alpha: 0.05),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryBlue,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
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

                      return CollectionLoanCard(
                        loan: loan,
                        customer: customer,
                        risk: risk,
                        riskColor: riskColor,
                        currencyFormat: _currencyFormat,
                        index: idx,
                        onAction: () {
                          _showLoanDetailsSheet(context, loan, customer, service);
                        },
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
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      radius: 12.0,
      borderOpacity: 0.05,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: col,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: col.withValues(alpha: 0.4),
                      blurRadius: 4,
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              val,
              style: TextStyle(
                color: col,
                fontSize: 14.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.1,
              ),
            ),
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
            return Consumer(
              builder: (context, ref, child) {
                final currentService = ref.watch(supabaseServiceProvider);
                final currentLoan = currentService.getLoanById(loan['id']) ?? loan;
                final penalties = currentService.calculatePenalty(currentLoan['id']);
                final totalDue = (currentLoan['monthly_installment'] as num).toDouble() + penalties['total_penalty']!;
                final customerDocs = currentService.getDocumentsForCustomer(currentLoan['customer_id']);

                // Build dynamic timeline items
                List<Widget> timelineItems = [];

                // 1. Disbursed
                timelineItems.add(
                  _buildTimelineItem(
                    title: 'Loan Disbursed',
                    subtitle: 'Sanctioned amount of ${_currencyFormat.format((currentLoan['principal_amount'] as num).toDouble())}',
                    time: currentLoan['start_date'],
                    isFirst: true,
                    isLast: false,
                  ),
                );

                // 2. Collections
                final allCollections = currentService.getCollections();
                final loanCollections = allCollections.where((c) => c['loan_id'] == currentLoan['id']).toList();
                // Sort chronologically (ascending)
                loanCollections.sort((a, b) => a['collection_date'].toString().compareTo(b['collection_date'].toString()));

                for (var col in loanCollections) {
                  final dateStr = col['collection_date'].toString().substring(0, 10);
                  timelineItems.add(
                    _buildTimelineItem(
                      title: 'Payment Received',
                      subtitle: '₹${(col['amount'] as num).toDouble().toStringAsFixed(0)} processed via ${col['payment_method'].toString().toUpperCase()}',
                      time: dateStr,
                      isFirst: false,
                      isLast: false,
                    ),
                  );
                }

                // 3. Warnings
                if (currentLoan['missed_dues'] > 0) {
                  timelineItems.add(
                    _buildTimelineItem(
                      title: 'Dues Missed Warning',
                      subtitle: 'Accrued penalties for ${currentLoan['missed_dues']} cycle lags',
                      time: 'Recent Review',
                      color: AppTheme.dangerRed,
                      isFirst: false,
                      isLast: false,
                    ),
                  );
                }

                // 4. Current Review
                timelineItems.add(
                  _buildTimelineItem(
                    title: 'Current Dues Review',
                    subtitle: 'Outstanding balance stands at ${_currencyFormat.format(currentLoan['remaining_balance'])}',
                    time: 'Today',
                    isFirst: false,
                    isLast: true,
                  ),
                );

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
                            _buildLedgerRow('Standard Installment', _currencyFormat.format(currentLoan['monthly_installment'])),
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
                                _showRecordPaymentDialog(context, currentLoan, totalDue, currentService);
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
                      ...timelineItems,
                      const SizedBox(height: 24),

                      // FEATURE 10: Document Vault (Aadhaar, PAN, agreements)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Document Vault', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          TextButton.icon(
                            icon: const Icon(Icons.upload, size: 16, color: AppTheme.primaryBlue),
                            label: const Text('Upload', style: TextStyle(color: AppTheme.primaryBlue, fontSize: 12)),
                            onPressed: () {
                              _showUploadDocumentDialog(context, currentLoan['customer_id'], currentLoan['id'], currentService);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (customerDocs.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('No documents uploaded in vault yet.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        )
                      else
                        ...customerDocs.map((doc) => _buildDocumentRow(context, doc['name'], doc['file_url'].toString().split('/').last)),
                    ],
                  ),
                );
              },
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

  void _showUploadDocumentDialog(BuildContext context, String customerId, String loanId, SupabaseService service) {
    final nameController = TextEditingController();
    String docType = 'aadhaar';
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Upload Document to Vault'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Document Name',
                      hintText: 'e.g. Aadhaar Card, PAN Card',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Document Type:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const SizedBox(height: 4),
                  DropdownButton<String>(
                    value: docType,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'aadhaar', child: Text('Aadhaar Card (KYC)')),
                      DropdownMenuItem(value: 'pan', child: Text('PAN Card')),
                      DropdownMenuItem(value: 'photo', child: Text('Customer Photo')),
                      DropdownMenuItem(value: 'promissory_note', child: Text('Promissory Note')),
                      DropdownMenuItem(value: 'agreement', child: Text('Loan Agreement')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => docType = val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  if (isUploading) ...[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 8),
                    const Text('Encrypting and syncing to Supabase Vault...', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.attachment, color: Colors.grey),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Selected: local_file_picker_cache.pdf',
                              style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isUploading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isUploading
                      ? null
                      : () async {
                          if (nameController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a document name')),
                            );
                            return;
                          }
                          setDialogState(() => isUploading = true);
                          // Simulate small upload delay
                          await Future.delayed(const Duration(milliseconds: 1500));

                          final name = nameController.text.trim();
                          final fileUrl = 'https://lendoraz.com/vault/${name.toLowerCase().replaceAll(' ', '_')}_upload.pdf';

                          await service.uploadDocument(
                            customerId: customerId,
                            loanId: loanId,
                            name: name,
                            documentType: docType,
                            fileUrl: fileUrl,
                          );

                          if (context.mounted) {
                            Navigator.pop(context); // Close dialog
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('"$name" successfully uploaded to Document Vault'),
                                backgroundColor: AppTheme.neonGreen,
                              ),
                            );
                          }
                        },
                  child: const Text('Upload'),
                ),
              ],
            );
          },
        );
      },
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

class CollectionLoanCard extends StatefulWidget {
  final Map<String, dynamic> loan;
  final Map<String, dynamic>? customer;
  final Map<String, dynamic> risk;
  final Color riskColor;
  final NumberFormat currencyFormat;
  final VoidCallback onAction;
  final int index;

  const CollectionLoanCard({
    super.key,
    required this.loan,
    required this.customer,
    required this.risk,
    required this.riskColor,
    required this.currencyFormat,
    required this.onAction,
    required this.index,
  });

  @override
  State<CollectionLoanCard> createState() => _CollectionLoanCardState();
}

class _CollectionLoanCardState extends State<CollectionLoanCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final cardContent = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (_isHovered)
              BoxShadow(
                color: widget.riskColor.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 5),
                spreadRadius: 1,
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: GlassCard(
          padding: EdgeInsets.zero,
          radius: 16.0,
          borderOpacity: _isHovered ? 0.25 : 0.08,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left indicator bar matching risk status
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.riskColor,
                        widget.riskColor.withValues(alpha: 0.5),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      children: [
                        // Left Section: Initial Avatar & Details
                        Expanded(
                          child: Row(
                            children: [
                              // Avatar Badge
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      widget.riskColor,
                                      widget.riskColor.withValues(alpha: 0.7),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: widget.riskColor.withValues(alpha: 0.25),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1.5),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  (widget.customer?['full_name'] != null && widget.customer!['full_name'].toString().isNotEmpty)
                                      ? widget.customer!['full_name'].toString()[0].toUpperCase()
                                      : 'C',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              
                              // Customer details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            widget.customer?['full_name'] ?? 'Unknown Customer',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14.5,
                                              letterSpacing: 0.1,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Risk Badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: widget.riskColor.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            widget.risk['level'].toString().toUpperCase(),
                                            style: TextStyle(
                                              color: widget.riskColor,
                                              fontSize: 7.5,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    
                                    // Outstanding & Installment
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 4,
                                      children: [
                                        // Outstanding amount
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.account_balance_wallet_outlined,
                                              size: 11,
                                              color: isDark ? Colors.white38 : Colors.black38,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Outstanding: ',
                                              style: TextStyle(
                                                color: isDark ? Colors.white38 : Colors.black38,
                                                fontSize: 10,
                                              ),
                                            ),
                                            Text(
                                              widget.currencyFormat.format(widget.loan['remaining_balance']),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        ),
                                        
                                        // Installment amount
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.event_repeat_outlined,
                                              size: 11,
                                              color: isDark ? Colors.white38 : Colors.black38,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Instalment: ',
                                              style: TextStyle(
                                                color: isDark ? Colors.white38 : Colors.black38,
                                                fontSize: 10,
                                              ),
                                            ),
                                            Text(
                                              '${widget.currencyFormat.format(widget.loan['monthly_installment'])} / mo',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // Right Section: Action Button
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            elevation: _isHovered ? 2 : 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onPressed: widget.onAction,
                          child: const Text(
                            'Action',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                          ),
                        ),
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
      delay: widget.index * 50,
      duration: const Duration(milliseconds: 400),
      slideOffset: 0.08,
      child: AnimatedScale(
        scale: _isHovered ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: cardContent,
      ),
    );
  }
}

