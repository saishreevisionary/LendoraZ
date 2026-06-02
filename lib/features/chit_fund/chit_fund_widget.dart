import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/supabase_service.dart';
import '../../core/network/providers.dart';

class ChitFundWidget extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  const ChitFundWidget({super.key, required this.scrollController});

  @override
  ConsumerState<ChitFundWidget> createState() => _ChitFundWidgetState();
}

class _ChitFundWidgetState extends ConsumerState<ChitFundWidget> {
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  final _bidAmountController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(supabaseServiceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chits = service.getChitFunds();

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(20),
      children: [
        // Header
        const Row(
          children: [
            Icon(Icons.groups, color: AppTheme.primaryBlue, size: 28),
            SizedBox(width: 8),
            Text('Chit Fund Desk', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),

        // Chit Groups List
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: chits.length,
          itemBuilder: (context, idx) {
            final group = chits[idx];
            final members = group['members'] as List<Map<String, dynamic>>;
            final auctions = group['auctions'] as List<Map<String, dynamic>>;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Group details card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.glassDecoration(context: context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(group['group_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.neonGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('ACTIVE', style: TextStyle(color: AppTheme.neonGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildDetailCol('Total Value', _currencyFormat.format(group['total_value'])),
                          _buildDetailCol('EMI / Member', _currencyFormat.format(group['contribution_monthly'])),
                          _buildDetailCol('Auction Month', '${group['current_auction_month']} / ${group['duration_months']}'),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Members (${group['max_members']})', style: const TextStyle(fontWeight: FontWeight.bold)),
                          TextButton(
                            onPressed: () {
                              _showMembersDialog(context, members);
                            },
                            child: const Text('View All Members'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 44),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          _showLiveAuctionDialog(context, group, service);
                        },
                        child: const Text('Start Bidding Auction', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Auction History
                const Text('Auction History Log', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: auctions.length,
                  itemBuilder: (context, aIdx) {
                    final auction = auctions[aIdx];
                    return Card(
                      color: isDark ? AppTheme.darkCard : Colors.white,
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.purple.withValues(alpha: 0.1),
                          child: Text('M${auction['month']}', style: const TextStyle(color: Colors.purple, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        title: Text('Winner: ${auction['winner']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text('Bid: ${_currencyFormat.format(auction['bid'])}'),
                        trailing: Text('Dividend: +${_currencyFormat.format(auction['dividend'])} / member', style: const TextStyle(color: AppTheme.neonGreen, fontSize: 11)),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildDetailCol(String label, String val) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  void _showMembersDialog(BuildContext context, List<Map<String, dynamic>> members) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Group Members Ledger'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: members.length,
              itemBuilder: (context, idx) {
                final m = members[idx];
                final isPaid = m['status'] == 'paid';
                return ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(m['name']),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isPaid ? AppTheme.neonGreen : AppTheme.dangerRed).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isPaid ? 'PAID' : 'UNPAID',
                      style: TextStyle(color: isPaid ? AppTheme.neonGreen : AppTheme.dangerRed, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            )
          ],
        );
      },
    );
  }

  void _showLiveAuctionDialog(BuildContext context, Map<String, dynamic> group, SupabaseService service) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Live Auction Bid Portal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter bid discount amount for this month\'s dividend distributions (Max limit: 40% of chit value).'),
              const SizedBox(height: 16),
              TextField(
                controller: _bidAmountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Bid Discount Amount (₹)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                double bid = double.tryParse(_bidAmountController.text) ?? 0.0;
                double dividend = bid / group['max_members'];
                
                // Add to auctions list
                setState(() {
                  final auctions = group['auctions'] as List<Map<String, dynamic>>;
                  auctions.insert(0, {
                    'month': group['current_auction_month'],
                    'winner': 'Ravi Kumar',
                    'bid': bid,
                    'dividend': dividend,
                  });
                  group['current_auction_month'] = group['current_auction_month'] + 1;
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Auction won by Ravi Kumar. Dividend of ${_currencyFormat.format(dividend)} credited to members.'),
                    backgroundColor: AppTheme.neonGreen,
                  ),
                );
              },
              child: const Text('Process Dividend Winner'),
            ),
          ],
        );
      },
    );
  }
}
