import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/providers.dart';

class CustomerPortalWidget extends ConsumerStatefulWidget {
  const CustomerPortalWidget({super.key});

  @override
  ConsumerState<CustomerPortalWidget> createState() => _CustomerPortalWidgetState();
}

class _CustomerPortalWidgetState extends ConsumerState<CustomerPortalWidget> {
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(supabaseServiceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Customer profile & loans (Mock customer 'cust-1' represents Ravi Kumar in portal)
    final customer = service.getCustomerById('cust-1');
    final custLoans = service.getLoans().where((l) => l['customer_id'] == 'cust-1').toList();
    final collections = service.getCollections().where((c) => c['loan_id'] == 'loan-1').toList();

    if (custLoans.isEmpty) {
      return const Center(child: Text('No active loan records found.'));
    }

    final loan = custLoans.first;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting & Profile
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, ${customer?['full_name']}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Text('Customer Self-Service Hub', style: TextStyle(color: Colors.grey)),
                ],
              ),
              CircleAvatar(
                backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                child: const Icon(Icons.person, color: AppTheme.primaryBlue),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Total Loan Outstanding Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Outstanding Balance', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Icon(Icons.security, color: Colors.white70, size: 18),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _currencyFormat.format(loan['remaining_balance']),
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildBalanceSub('EMI Instalment', _currencyFormat.format(loan['monthly_installment'])),
                    _buildBalanceSub('Due Date', loan['due_date']),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Actions Panel (Pay Online, Statement Download)
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
                  icon: const Icon(Icons.payment),
                  label: const Text('Pay Dues Online', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Redirecting to Supabase Stripe checkout gateway...'),
                        backgroundColor: AppTheme.primaryBlue,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: AppTheme.primaryBlue),
                  ),
                  icon: const Icon(Icons.download, color: AppTheme.primaryBlue),
                  label: const Text('Download Statement', style: TextStyle(color: AppTheme.primaryBlue)),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Downloading loan account statement PDF...'),
                        backgroundColor: AppTheme.neonGreen,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Repayments history
          const Text('Your Repayment History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          collections.isEmpty
              ? const Center(child: Text('No previous payments logged.'))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: collections.length,
                  itemBuilder: (context, idx) {
                    final c = collections[idx];
                    return Card(
                      color: isDark ? AppTheme.darkCard : Colors.white,
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.greenAccent,
                          child: Icon(Icons.check, color: Colors.green),
                        ),
                        title: Text('Payment Credited', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text('Ref: ${c['id']} via ${c['payment_method'].toString().toUpperCase()}'),
                        trailing: Text(
                          _currencyFormat.format(c['amount']),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.neonGreen),
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildBalanceSub(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}
