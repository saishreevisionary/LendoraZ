import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/supabase_service.dart';
import '../../core/network/providers.dart';

class GoldLoanWidget extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  const GoldLoanWidget({super.key, required this.scrollController});

  @override
  ConsumerState<GoldLoanWidget> createState() => _GoldLoanWidgetState();
}

class _GoldLoanWidgetState extends ConsumerState<GoldLoanWidget> {
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  
  // Gold Valuation inputs
  double _weight = 10.0;
  int _purity = 22;
  double _calculatedValuation = 0.0;
  double _ltvLimit = 0.0; // 75% standard LTV

  final double _goldRatePerGram24K = 7200.0; // Current mock gold price index

  @override
  void initState() {
    super.initState();
    _recalculateValuation();
  }

  void _recalculateValuation() {
    double purityFactor = _purity / 24.0;
    double rawValue = _weight * _goldRatePerGram24K * purityFactor;
    setState(() {
      _calculatedValuation = rawValue;
      _ltvLimit = rawValue * 0.75; // Standard regulatory Loan-To-Value constraint
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(supabaseServiceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final goldLoans = service.getGoldLoans();

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(20),
      children: [
        // Header
        const Row(
          children: [
            Icon(Icons.gavel, color: AppTheme.goldPremium, size: 28),
            SizedBox(width: 8),
            Text('Gold Loan Valuation Desk', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),

        // Interactive Valuation Tool
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.glassDecoration(context: context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Interactive Appraisal Calculator', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 16),

              // Weight slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Gold Weight: ${_weight.toStringAsFixed(1)} grams', style: const TextStyle(fontSize: 13)),
                  const Icon(Icons.scale, color: AppTheme.goldPremium, size: 18),
                ],
              ),
              Slider(
                value: _weight,
                min: 5,
                max: 500,
                divisions: 99,
                activeColor: AppTheme.goldPremium,
                onChanged: (val) {
                  setState(() => _weight = val);
                  _recalculateValuation();
                },
              ),

              // Purity options
              const Text('Purity (Karats):', style: TextStyle(fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [18, 20, 22, 24].map((karat) {
                  final isSelected = _purity == karat;
                  return ChoiceChip(
                    label: Text('$karat K'),
                    selected: isSelected,
                    selectedColor: AppTheme.goldPremium,
                    onSelected: (val) {
                      if (val) {
                        setState(() => _purity = karat);
                        _recalculateValuation();
                      }
                    },
                  );
                }).toList(),
              ),
              const Divider(height: 30),

              // Appraisals Output
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Market Appraisal:', style: TextStyle(fontSize: 13)),
                  Text(_currencyFormat.format(_calculatedValuation), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Max Allowed Loan LTV (75%):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  Text(_currencyFormat.format(_ltvLimit), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.neonGreen)),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.goldPremium,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add_photo_alternate_outlined, color: Colors.black),
                label: const Text('Capture Ornament & Pledge', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  // Simulate image attach and pledge creation
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Ornament appraisal locked at ${_currencyFormat.format(_ltvLimit)}. Uploaded to Supabase Document Vault.'),
                      backgroundColor: AppTheme.neonGreen,
                    ),
                  );
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Active gold loans portfolio
        const Text('Active Pledges Log', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: goldLoans.length,
          itemBuilder: (context, idx) {
            final gl = goldLoans[idx];
            return Card(
              color: isDark ? AppTheme.darkCard : Colors.white,
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    // Mock product image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        gl['item_images'][0],
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 70,
                          height: 70,
                          color: AppTheme.goldPremium.withValues(alpha: 0.1),
                          child: const Icon(Icons.image, color: AppTheme.goldPremium),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Ornament ref: M${gl['id'].substring(5)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.goldPremium.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text('${gl['purity_karats']}K Purity', style: const TextStyle(color: AppTheme.goldPremium, fontSize: 8, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Net Weight: ${gl['weight_grams']}g', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          Text('Valuation: ${_currencyFormat.format(gl['valuation_amount'])}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
