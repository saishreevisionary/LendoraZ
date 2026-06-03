import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/animations.dart';
import '../../../core/network/supabase_service.dart';
import '../../../core/network/providers.dart';

class CustomerDashboard extends ConsumerWidget {
  const CustomerDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(supabaseServiceProvider);
    final NumberFormat currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    // Fetch customer's loan
    final myLoans = service.getLoans();
    Map<String, dynamic>? activeLoan;
    if (myLoans.isNotEmpty) {
      activeLoan = myLoans.first;
    }

    final double outstanding = activeLoan != null ? (activeLoan['remaining_balance'] as double) : 0.0;
    final double principal = activeLoan != null ? (activeLoan['principal_amount'] as double) : 0.0;
    final double paid = activeLoan != null ? (activeLoan['paid_balance'] as double) : 0.0;
    final double progress = principal > 0 ? (paid / principal) : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, service),
          const SizedBox(height: 20),
          _buildActiveLoanOverview(context, outstanding, paid, progress, currencyFormat),
          const SizedBox(height: 24),
          if (activeLoan != null) _buildDueDetails(context, activeLoan, currencyFormat),
          const SizedBox(height: 24),
          _buildDocumentVault(context),
          const SizedBox(height: 24),
          _buildReceiptsList(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, SupabaseService service) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SlideFadeIn(
          delay: 0,
          child: Text(
            'Customer Portal',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ),
        SlideFadeIn(
          delay: 50,
          child: Text(
            'Track your loan balances, due schedules, and download billing receipts.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.grey : const Color(0xFF475569),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveLoanOverview(BuildContext context, double outstanding, double paid, double progress, NumberFormat fmt) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SlideFadeIn(
      delay: 100,
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        borderOpacity: 0.15,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Loan Overview', 
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A), 
                fontWeight: FontWeight.bold, 
                fontSize: 16
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Outstanding Balance', 
                      style: TextStyle(color: isDark ? Colors.grey : const Color(0xFF64748B), fontSize: 11)
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fmt.format(outstanding), 
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A), 
                        fontSize: 24, 
                        fontWeight: FontWeight.w900
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Total Paid', 
                      style: TextStyle(color: isDark ? Colors.grey : const Color(0xFF64748B), fontSize: 11)
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fmt.format(paid), 
                      style: const TextStyle(color: AppTheme.neonGreen, fontSize: 18, fontWeight: FontWeight.bold)
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Loan Payoff Progress: ${(progress * 100).toStringAsFixed(1)}%', 
                  style: TextStyle(color: isDark ? Colors.grey : const Color(0xFF64748B), fontSize: 12)
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: isDark ? Colors.black26 : const Color(0xFFE2E8F0),
                color: AppTheme.primaryBlue,
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDueDetails(BuildContext context, Map<String, dynamic> loan, NumberFormat fmt) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SlideFadeIn(
      delay: 150,
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        borderOpacity: 0.15,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Next Installment Schedule', 
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A), 
                fontWeight: FontWeight.bold, 
                fontSize: 15
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Due Date', 
                      style: TextStyle(color: isDark ? Colors.grey : const Color(0xFF64748B), fontSize: 11)
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loan['due_date'].toString(), 
                      style: const TextStyle(color: AppTheme.warningOrange, fontSize: 16, fontWeight: FontWeight.bold)
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'EMI Amount', 
                      style: TextStyle(color: isDark ? Colors.grey : const Color(0xFF64748B), fontSize: 11)
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fmt.format(loan['monthly_installment']), 
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A), 
                        fontSize: 16, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                minimumSize: const Size.fromHeight(40),
              ),
              onPressed: () {},
              child: const Text('Pay Due Online', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentVault(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SlideFadeIn(
      delay: 200,
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        borderOpacity: 0.15,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Document Vault', 
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A), 
                fontWeight: FontWeight.bold, 
                fontSize: 15
              ),
            ),
            const SizedBox(height: 12),
            ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildDocItem(context, 'Signed Loan Agreement.pdf', '02 Jun 2026'),
                Divider(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                _buildDocItem(context, 'Aadhaar Verification Proof.pdf', '01 Jun 2026'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocItem(BuildContext context, String name, String date) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.file_present, color: AppTheme.primaryCyan),
      title: Text(
        name, 
        style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF1E293B), 
          fontSize: 13, 
          fontWeight: FontWeight.bold
        )
      ),
      subtitle: Text(
        'Uploaded: $date', 
        style: TextStyle(color: isDark ? Colors.grey : const Color(0xFF64748B), fontSize: 10)
      ),
      trailing: IconButton(
        icon: Icon(Icons.download, color: isDark ? Colors.grey : const Color(0xFF64748B), size: 20),
        onPressed: () {},
      ),
    );
  }

  Widget _buildReceiptsList(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SlideFadeIn(
      delay: 250,
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        borderOpacity: 0.15,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Digital Receipts', 
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A), 
                fontWeight: FontWeight.bold, 
                fontSize: 15
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.verified, color: AppTheme.neonGreen),
              title: Text(
                'EMI Payment Receipt #9938', 
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF1E293B), 
                  fontSize: 13, 
                  fontWeight: FontWeight.bold
                )
              ),
              subtitle: Text(
                'Amount: ₹23,536 | Date: 02 Jun 2026', 
                style: TextStyle(color: isDark ? Colors.grey : const Color(0xFF64748B), fontSize: 10)
              ),
              trailing: TextButton(
                onPressed: () {},
                child: const Text('View PDF', style: TextStyle(fontSize: 11)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
