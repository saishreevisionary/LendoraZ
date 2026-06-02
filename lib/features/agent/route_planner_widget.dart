import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/supabase_service.dart';
import '../../core/network/providers.dart';

class RoutePlannerWidget extends ConsumerStatefulWidget {
  const RoutePlannerWidget({super.key});

  @override
  ConsumerState<RoutePlannerWidget> createState() => _RoutePlannerWidgetState();
}

class _RoutePlannerWidgetState extends ConsumerState<RoutePlannerWidget> {
  bool _showHeatmap = false;
  String _selectedRouteType = 'optimized'; // optimized, shortest
  double _totalDistance = 8.4; // km

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(supabaseServiceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final customers = service.getCustomers();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _showHeatmap ? 'Collection Heat Map' : 'Smart Route Optimization',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            _showHeatmap
                ? 'Density visualization of collections vs default zones'
                : 'Optimized travel paths for daily field agents',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),

          // Controls Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Route Planner'),
                    selected: !_showHeatmap,
                    onSelected: (val) => setState(() => _showHeatmap = !val),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Heat Map'),
                    selected: _showHeatmap,
                    onSelected: (val) => setState(() => _showHeatmap = val),
                  ),
                ],
              ),
              if (!_showHeatmap)
                DropdownButton<String>(
                  value: _selectedRouteType,
                  items: const [
                    DropdownMenuItem(value: 'optimized', child: Text('Optimal Dues')),
                    DropdownMenuItem(value: 'shortest', child: Text('Shortest Path')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedRouteType = val;
                        _totalDistance = val == 'optimized' ? 8.4 : 11.2;
                      });
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Map Rendering Canvas
          Container(
            height: 240,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F1524) : Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: CustomPaint(
                    size: const Size(double.infinity, 240),
                    painter: MapVectorPainter(
                      showHeatmap: _showHeatmap,
                      isOptimized: _selectedRouteType == 'optimized',
                      isDark: isDark,
                    ),
                  ),
                ),
                // Legend Overlay
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black54 : Colors.white70,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _showHeatmap
                          ? [
                              _buildLegendItem(AppTheme.neonGreen, 'High Recovery Area'),
                              _buildLegendItem(AppTheme.dangerRed, 'High Defaults Area'),
                            ]
                          : [
                              _buildLegendItem(AppTheme.primaryBlue, 'Agent Base'),
                              _buildLegendItem(AppTheme.primaryCyan, 'Collection Target'),
                            ],
                    ),
                  ),
                ),
                // Location overlay card
                if (!_showHeatmap)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black87 : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Est. Distance: $_totalDistance km', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                          const Text('Avg. Commute: 32 mins', style: TextStyle(color: Colors.grey, fontSize: 10)),
                        ],
                      ),
                    ),
                  )
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Agent Management & Assignment details
          const Text('Field Agents Status & Target Tracker', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          
          _buildAgentListCard(
            context,
            name: 'Rohan Naik',
            status: 'On Duty (GPS Active)',
            lastCheckIn: '09:15 AM',
            target: '₹50,000',
            collected: '₹23,536',
            efficiency: 47,
          ),
          const SizedBox(height: 10),
          _buildAgentListCard(
            context,
            name: 'Manoj Kumar',
            status: 'Offline',
            lastCheckIn: 'Yesterday',
            target: '₹40,000',
            collected: '₹0',
            efficiency: 0,
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color col, String txt) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: col, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(txt, style: const TextStyle(fontSize: 9, color: Colors.grey)),
      ],
    );
  }

  Widget _buildAgentListCard(
    BuildContext context, {
    required String name,
    required String status,
    required String lastCheckIn,
    required String target,
    required String collected,
    required double efficiency,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      color: isDark ? AppTheme.darkCard : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                      child: Text(name[0], style: const TextStyle(color: AppTheme.primaryBlue)),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(status, style: TextStyle(color: status.contains('Active') ? AppTheme.neonGreen : Colors.grey, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
                Text('In: $lastCheckIn', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAgentStat('Monthly Target', target),
                _buildAgentStat('Collected Today', collected),
                _buildAgentStat('Completion Rate', '${efficiency.toStringAsFixed(0)}%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgentStat(String label, String val) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}

// Map Custom Painter for High-fidelity map visual simulation
class MapVectorPainter extends CustomPainter {
  final bool showHeatmap;
  final bool isOptimized;
  final bool isDark;

  MapVectorPainter({required this.showHeatmap, required this.isOptimized, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paintBase = Paint()
      ..color = isDark ? const Color(0xFF1E293B) : Colors.grey[400]!
      ..strokeWidth = 1.0;

    // Draw some random grid line networks to simulate streets
    final listPoints = [
      [Offset(0, size.height * 0.2), Offset(size.width, size.height * 0.3)],
      [Offset(size.width * 0.2, 0), Offset(size.width * 0.3, size.height)],
      [Offset(0, size.height * 0.8), Offset(size.width, size.height * 0.7)],
      [Offset(size.width * 0.7, 0), Offset(size.width * 0.6, size.height)],
      [Offset(size.width * 0.1, size.height * 0.5), Offset(size.width * 0.9, size.height * 0.4)],
    ];

    for (var pts in listPoints) {
      canvas.drawLine(pts[0], pts[1], paintBase);
    }

    if (showHeatmap) {
      // Draw Heatmap glowing zones
      final paintGreenZone = Paint()
        ..color = AppTheme.neonGreen.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
      final paintRedZone = Paint()
        ..color = AppTheme.dangerRed.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);

      canvas.drawCircle(Offset(size.width * 0.25, size.height * 0.45), 50, paintGreenZone);
      canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.35), 65, paintRedZone);
      canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.75), 45, paintGreenZone);
    } else {
      // Draw path line
      final pathPaint = Paint()
        ..color = isOptimized ? AppTheme.primaryCyan : Colors.purple
        ..strokeWidth = 3.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final path = Path()
        ..moveTo(size.width * 0.15, size.height * 0.15)
        ..lineTo(size.width * 0.3, size.height * 0.35)
        ..lineTo(size.width * 0.6, size.height * 0.25)
        ..lineTo(size.width * 0.8, size.height * 0.7);

      canvas.drawPath(path, pathPaint);

      // Draw stops / pins
      final stopPaint = Paint()..color = AppTheme.primaryBlue;
      final targetPaint = Paint()..color = AppTheme.primaryCyan;

      canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.15), 8, stopPaint); // Base
      canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.35), 6, targetPaint); // Stop 1
      canvas.drawCircle(Offset(size.width * 0.6, size.height * 0.25), 6, targetPaint); // Stop 2
      canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.7), 6, targetPaint); // Stop 3
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
