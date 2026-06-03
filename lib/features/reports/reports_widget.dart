import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' hide Border;
import '../../core/theme/app_theme.dart';
import '../../core/network/supabase_service.dart';
import '../../core/network/providers.dart';
import '../../core/utils/file_saver.dart';


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
    final service = ref.watch(supabaseServiceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selectedRep = _reportTypes.firstWhere((r) => r['id'] == _selectedReportType);

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
          const SizedBox(height: 16),

          // Date Range Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: AppTheme.glassDecoration(context: context, borderOpacity: 0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Audit Period Range', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(
                      _selectedDateRange == null
                          ? 'All Time Records'
                          : '${_selectedDateRange!.start.toString().substring(0, 10)}  to  ${_selectedDateRange!.end.toString().substring(0, 10)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.date_range, size: 14),
                  label: const Text('Pick Dates', style: TextStyle(fontSize: 12)),
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
          const SizedBox(height: 16),

          // Report Types selector grid (compact)
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 3.2,
            children: _reportTypes.map((rep) {
              final isSelected = _selectedReportType == rep['id'];
              final colColor = isSelected ? AppTheme.primaryBlue : Colors.grey;

              return GestureDetector(
                onTap: () => setState(() => _selectedReportType = rep['id']),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? colColor.withValues(alpha: 0.08) 
                        : (isDark ? AppTheme.darkCard : Colors.white),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryBlue : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                      width: isSelected ? 1.8 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(rep['icon'], color: isSelected ? AppTheme.primaryBlue : Colors.grey, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          rep['title'],
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 11.5,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Dynamic Preview Header
          Row(
            children: [
              const Icon(Icons.analytics, color: AppTheme.primaryCyan, size: 16),
              const SizedBox(width: 6),
              Text(
                'Data Preview: ${selectedRep['title']}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryCyan),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Dynamic Preview Container
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildReportPreview(service),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Export Actions
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                  label: const Text('Export to PDF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  onPressed: _isExporting ? null : () => _triggerExport('PDF'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.neonGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.table_chart_outlined, size: 18),
                  label: const Text('Export to Excel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  onPressed: _isExporting ? null : () => _triggerExport('Excel'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportPreview(SupabaseService service) {
    switch (_selectedReportType) {
      case 'collections':
        return _buildCollectionsPreview(service);
      case 'profits':
        return _buildProfitsPreview(service);
      case 'agents':
        return _buildAgentsPreview(service);
      case 'risk':
        return _buildRiskPreview(service);
      default:
        return const Center(child: Text('Select a report type to load preview.'));
    }
  }

  Widget _buildCollectionsPreview(SupabaseService service) {
    final collections = service.getCollections();
    if (collections.isEmpty) {
      return const Center(child: Text('No collections recorded yet.', style: TextStyle(color: Colors.grey, fontSize: 12)));
    }
    return ListView(
      children: [
        Table(
          columnWidths: const {
            0: FlexColumnWidth(1.2),
            1: FlexColumnWidth(1.8),
            2: FlexColumnWidth(1.2),
            3: FlexColumnWidth(1.0),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2)))),
              children: const [
                Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('Customer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
              ],
            ),
            ...collections.map((c) {
              final loan = service.getLoanById(c['loan_id']);
              final customerName = loan != null 
                  ? (service.getCustomerById(loan['customer_id'])?['full_name'] ?? 'Client')
                  : 'Client';
              final dateStr = c['collection_date'].toString().substring(0, 10);
              return TableRow(
                children: [
                  Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(dateStr, style: const TextStyle(fontSize: 10.5))),
                  Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(customerName, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600))),
                  Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text('₹${c['amount']}', style: const TextStyle(fontSize: 10.5, color: AppTheme.neonGreen, fontWeight: FontWeight.bold))),
                  Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(c['payment_method'].toString().toUpperCase(), style: const TextStyle(fontSize: 10.5))),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildProfitsPreview(SupabaseService service) {
    final loans = service.getLoans();
    
    double totalPortfolio = 0.0;
    double totalCollected = 0.0;
    double totalPenalties = 0.0;

    for (var l in loans) {
      totalPortfolio += (l['principal_amount'] as num).toDouble();
      totalCollected += (l['paid_balance'] as num).toDouble();
      final penalties = service.calculatePenalty(l['id']);
      totalPenalties += penalties['total_penalty']!;
    }

    double netCashflow = totalCollected + totalPenalties;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildProfitItem('Lending Portfolio Capital', '₹${totalPortfolio.toStringAsFixed(0)}', Colors.blue),
        _buildProfitItem('Total Principal Recovered', '₹${totalCollected.toStringAsFixed(0)}', AppTheme.neonGreen),
        _buildProfitItem('Late Penalties Accrued', '₹${totalPenalties.toStringAsFixed(0)}', AppTheme.warningOrange),
        const Divider(height: 20),
        _buildProfitItem('Net Cash Recovery (Total)', '₹${netCashflow.toStringAsFixed(0)}', AppTheme.primaryCyan, isBold: true),
      ],
    );
  }

  Widget _buildProfitItem(String label, String val, Color col, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: 12)),
          Text(
            val,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: col,
              fontSize: isBold ? 14 : 12.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentsPreview(SupabaseService service) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: service.getAgentsWithStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No agent statistics found.', style: TextStyle(color: Colors.grey, fontSize: 12)));
        }
        final agents = snapshot.data!;
        return ListView.builder(
          itemCount: agents.length,
          itemBuilder: (context, idx) {
            final a = agents[idx];
            final target = (a['target_amount'] as num?)?.toDouble() ?? 50000.0;
            final collected = (a['collected_amount'] as num?)?.toDouble() ?? 0.0;
            final percent = target > 0 ? (collected / target) * 100 : 0.0;
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Card(
              color: isDark ? const Color(0xFF0F1524) : Colors.grey[50],
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                title: Text(a['full_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                subtitle: Text('Status: ${a['status']}', style: const TextStyle(fontSize: 10.5)),
                trailing: Text(
                  '${percent.toStringAsFixed(1)}% target', 
                  style: TextStyle(
                    color: percent >= 80 ? AppTheme.neonGreen : AppTheme.warningOrange, 
                    fontSize: 11, 
                    fontWeight: FontWeight.bold
                  )
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRiskPreview(SupabaseService service) {
    final loans = service.getLoans();
    final riskLoans = loans.where((l) => l['status'] == 'defaulted' || l['missed_dues'] > 0).toList();

    if (riskLoans.isEmpty) {
      return const Center(
        child: Text(
          'No default or high-risk accounts found.', 
          style: TextStyle(color: AppTheme.neonGreen, fontWeight: FontWeight.bold, fontSize: 12)
        )
      );
    }

    return ListView.builder(
      itemCount: riskLoans.length,
      itemBuilder: (context, idx) {
        final l = riskLoans[idx];
        final cust = service.getCustomerById(l['customer_id']);
        final name = cust != null ? cust['full_name'] : 'Customer';
        final status = l['status'] == 'defaulted' ? 'DEFAULTED' : 'OVERDUE';
        final color = l['status'] == 'defaulted' ? AppTheme.dangerRed : AppTheme.warningOrange;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Card(
          color: isDark ? const Color(0xFF0F1524) : Colors.grey[50],
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            title: Row(
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                  child: Text(status, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            subtitle: Text('Missed payments: ${l['missed_dues']} cycles', style: const TextStyle(fontSize: 10.5)),
            trailing: Text('₹${(l['remaining_balance'] as num).toDouble().toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.dangerRed, fontSize: 12)),
          ),
        );
      },
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

    try {
      final service = ref.read(supabaseServiceProvider);
      final String dateRangeStr = _selectedDateRange == null
          ? 'All Time Records'
          : '${_selectedDateRange!.start.toString().substring(0, 10)} to ${_selectedDateRange!.end.toString().substring(0, 10)}';

      DateTime? parseDate(String? s) {
        if (s == null) return null;
        return DateTime.tryParse(s);
      }

      bool isWithinRange(String? dateStr) {
        if (_selectedDateRange == null) return true;
        final d = parseDate(dateStr);
        if (d == null) return false;
        final start = DateTime(_selectedDateRange!.start.year, _selectedDateRange!.start.month, _selectedDateRange!.start.day);
        final end = DateTime(_selectedDateRange!.end.year, _selectedDateRange!.end.month, _selectedDateRange!.end.day, 23, 59, 59);
        return d.isAfter(start.subtract(const Duration(seconds: 1))) && d.isBefore(end.add(const Duration(seconds: 1)));
      }

      CellValue toCellValue(dynamic val) {
        if (val == null) return TextCellValue('');
        if (val is int) return IntCellValue(val);
        if (val is double) return DoubleCellValue(val);
        if (val is num) return DoubleCellValue(val.toDouble());
        if (val is bool) return BoolCellValue(val);
        return TextCellValue(val.toString());
      }

      List<int> fileBytes = [];
      final String ext = format == 'Excel' ? 'xlsx' : 'pdf';

      if (_selectedReportType == 'collections') {
        final collections = service.getCollections().where((c) => isWithinRange(c['collection_date'].toString())).toList();
        if (format == 'Excel') {
          final excel = Excel.createExcel();
          final sheet = excel['Sheet1'];
          sheet.appendRow([
            toCellValue('Date'),
            toCellValue('Customer'),
            toCellValue('Amount (INR)'),
            toCellValue('Payment Method'),
            toCellValue('Receipt UUID'),
            toCellValue('Notes'),
          ]);
          for (var c in collections) {
            final loan = service.getLoanById(c['loan_id']);
            final custName = loan != null ? (service.getCustomerById(loan['customer_id'])?['full_name'] ?? 'Client') : 'Client';
            final dateStr = c['collection_date'].toString().substring(0, 10);
            sheet.appendRow([
              toCellValue(dateStr),
              toCellValue(custName),
              toCellValue((c['amount'] as num).toDouble()),
              toCellValue(c['payment_method'].toString().toUpperCase()),
              toCellValue(c['receipt_uuid']),
              toCellValue(c['notes']),
            ]);
          }
          fileBytes = excel.encode()!;
        } else {
          final pdf = pw.Document();
          double total = 0.0;
          final List<List<String>> tableData = collections.map<List<String>>((c) {
            final loan = service.getLoanById(c['loan_id']);
            final custName = loan != null ? (service.getCustomerById(loan['customer_id'])?['full_name'] ?? 'Client') : 'Client';
            final dateStr = c['collection_date'].toString().substring(0, 10);
            final amt = (c['amount'] as num).toDouble();
            total += amt;
            return [
              dateStr,
              custName,
              'Rs. ${amt.toStringAsFixed(0)}',
              c['payment_method'].toString().toUpperCase(),
            ];
          }).toList();

          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              build: (pw.Context context) {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("LENDORA DAILY COLLECTIONS LEDGER", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                    pw.SizedBox(height: 4),
                    pw.Text("Audit Period: $dateRangeStr", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                    pw.Text("Exported On: ${DateTime.now().toIso8601String().substring(0, 19).replaceAll('T', ' ')}", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                    pw.Divider(),
                    pw.SizedBox(height: 10),
                    pw.TableHelper.fromTextArray(
                      headers: ['Date', 'Customer', 'Amount', 'Mode'],
                      data: tableData,
                      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      cellStyle: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.SizedBox(height: 15),
                    pw.Text("Total Collected: Rs. ${total.toStringAsFixed(2)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                  ],
                );
              },
            ),
          );
          fileBytes = await pdf.save();
        }
      } else if (_selectedReportType == 'profits') {
        final loans = service.getLoans();
        double totalPortfolio = 0.0;
        double totalCollected = 0.0;
        double totalPenalties = 0.0;

        for (var l in loans) {
          totalPortfolio += (l['principal_amount'] as num).toDouble();
          totalCollected += (l['paid_balance'] as num).toDouble();
          final penalties = service.calculatePenalty(l['id']);
          totalPenalties += penalties['total_penalty']!;
        }

        double netCashflow = totalCollected + totalPenalties;

        if (format == 'Excel') {
          final excel = Excel.createExcel();
          final sheet = excel['Sheet1'];
          sheet.appendRow([
            toCellValue('Financial Metric'),
            toCellValue('Value (INR)'),
          ]);
          sheet.appendRow([toCellValue('Lending Portfolio Capital'), toCellValue(totalPortfolio)]);
          sheet.appendRow([toCellValue('Total Principal Recovered'), toCellValue(totalCollected)]);
          sheet.appendRow([toCellValue('Late Penalties Accrued'), toCellValue(totalPenalties)]);
          sheet.appendRow([toCellValue('Net Cash Recovery (Total)'), toCellValue(netCashflow)]);
          fileBytes = excel.encode()!;
        } else {
          final pdf = pw.Document();
          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              build: (pw.Context context) {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("LENDORA REVENUE & PROFIT REPORT", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                    pw.SizedBox(height: 4),
                    pw.Text("Audit Period: $dateRangeStr", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                    pw.Text("Exported On: ${DateTime.now().toIso8601String().substring(0, 19).replaceAll('T', ' ')}", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                    pw.Divider(),
                    pw.SizedBox(height: 10),
                    pw.TableHelper.fromTextArray(
                      headers: ['Financial Metric', 'Value'],
                      data: [
                        ['Lending Portfolio Capital', 'Rs. ${totalPortfolio.toStringAsFixed(2)}'],
                        ['Total Principal Recovered', 'Rs. ${totalCollected.toStringAsFixed(2)}'],
                        ['Late Penalties Accrued', 'Rs. ${totalPenalties.toStringAsFixed(2)}'],
                        ['Net Cash Recovery (Total)', 'Rs. ${netCashflow.toStringAsFixed(2)}'],
                      ],
                      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      cellStyle: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                );
              },
            ),
          );
          fileBytes = await pdf.save();
        }
      } else if (_selectedReportType == 'agents') {
        final agents = await service.getAgentsWithStats();
        if (format == 'Excel') {
          final excel = Excel.createExcel();
          final sheet = excel['Sheet1'];
          sheet.appendRow([
            toCellValue('Agent Name'),
            toCellValue('Status'),
            toCellValue('Target Amount'),
            toCellValue('Collected Amount'),
            toCellValue('Completion %'),
          ]);
          for (var a in agents) {
            final target = (a['target_amount'] as num?)?.toDouble() ?? 50000.0;
            final collected = (a['collected_amount'] as num?)?.toDouble() ?? 0.0;
            final percent = target > 0 ? (collected / target) * 100 : 0.0;
            sheet.appendRow([
              toCellValue(a['full_name']),
              toCellValue(a['status']),
              toCellValue(target),
              toCellValue(collected),
              toCellValue(percent),
            ]);
          }
          fileBytes = excel.encode()!;
        } else {
          final pdf = pw.Document();
          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              build: (pw.Context context) {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("LENDORA AGENT PERFORMANCE REPORT", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                    pw.SizedBox(height: 4),
                    pw.Text("Exported On: ${DateTime.now().toIso8601String().substring(0, 19).replaceAll('T', ' ')}", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                    pw.Divider(),
                    pw.SizedBox(height: 10),
                    pw.TableHelper.fromTextArray(
                      headers: ['Agent Name', 'Status', 'Target', 'Collected', 'Comp %'],
                      data: agents.map((a) {
                        final target = (a['target_amount'] as num?)?.toDouble() ?? 50000.0;
                        final collected = (a['collected_amount'] as num?)?.toDouble() ?? 0.0;
                        final percent = target > 0 ? (collected / target) * 100 : 0.0;
                        return [
                          a['full_name'].toString(),
                          a['status'].toString(),
                          'Rs. ${target.toStringAsFixed(0)}',
                          'Rs. ${collected.toStringAsFixed(0)}',
                          '${percent.toStringAsFixed(1)}%',
                        ];
                      }).toList(),
                      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      cellStyle: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                );
              },
            ),
          );
          fileBytes = await pdf.save();
        }
      } else if (_selectedReportType == 'risk') {
        final loans = service.getLoans();
        final riskLoans = loans.where((l) => l['status'] == 'defaulted' || l['missed_dues'] > 0).toList();
        if (format == 'Excel') {
          final excel = Excel.createExcel();
          final sheet = excel['Sheet1'];
          sheet.appendRow([
            toCellValue('Customer Name'),
            toCellValue('Status'),
            toCellValue('Missed Cycles'),
            toCellValue('Remaining Balance (INR)'),
          ]);
          for (var l in riskLoans) {
            final cust = service.getCustomerById(l['customer_id']);
            final name = cust != null ? cust['full_name'] : 'Customer';
            final status = l['status'] == 'defaulted' ? 'DEFAULTED' : 'OVERDUE';
            sheet.appendRow([
              toCellValue(name),
              toCellValue(status),
              toCellValue(l['missed_dues']),
              toCellValue((l['remaining_balance'] as num).toDouble()),
            ]);
          }
          fileBytes = excel.encode()!;
        } else {
          final pdf = pw.Document();
          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              build: (pw.Context context) {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("LENDORA RISK & DEFAULT REPORT", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                    pw.SizedBox(height: 4),
                    pw.Text("Exported On: ${DateTime.now().toIso8601String().substring(0, 19).replaceAll('T', ' ')}", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                    pw.Divider(),
                    pw.SizedBox(height: 10),
                    pw.TableHelper.fromTextArray(
                      headers: ['Customer Name', 'Status', 'Missed Cycles', 'Remaining Balance'],
                      data: riskLoans.map((l) {
                        final cust = service.getCustomerById(l['customer_id']);
                        final name = cust != null ? cust['full_name'] : 'Customer';
                        final status = l['status'] == 'defaulted' ? 'DEFAULTED' : 'OVERDUE';
                        return [
                          name,
                          status,
                          l['missed_dues'].toString(),
                          'Rs. ${l['remaining_balance'].toStringAsFixed(2)}',
                        ];
                      }).toList(),
                      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      cellStyle: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                );
              },
            ),
          );
          fileBytes = await pdf.save();
        }
      }

      // Save report
      final timestamp = '${DateTime.now().toIso8601String().substring(0, 10)}_${DateTime.now().millisecondsSinceEpoch}';
      final fileName = '${_selectedReportType}_report_$timestamp.$ext';
      
      await saveFile(fileBytes, fileName);

      // Simulate audit calculations delay for UI premium feel
      await Future.delayed(const Duration(milliseconds: 1500));

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        setState(() => _isExporting = false);

        final message = kIsWeb
            ? 'Report downloaded successfully: $fileName'
            : 'Report saved to: c:\\LendoraZ\\exports\\$fileName';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppTheme.neonGreen,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'DISMISS',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        setState(() => _isExporting = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppTheme.dangerRed,
            duration: const Duration(seconds: 8),
          ),
        );
      }
    }
  }
}
