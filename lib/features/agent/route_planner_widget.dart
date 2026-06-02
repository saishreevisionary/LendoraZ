import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/providers.dart';

class RoutePlannerWidget extends ConsumerStatefulWidget {
  const RoutePlannerWidget({super.key});

  @override
  ConsumerState<RoutePlannerWidget> createState() => _RoutePlannerWidgetState();
}

class _RoutePlannerWidgetState extends ConsumerState<RoutePlannerWidget> {
  bool _showHeatmap = false;
  String _selectedRouteType = 'optimized'; // optimized (Optimal Dues), shortest (Shortest Path)

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(supabaseServiceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final customers = service.getCustomers();
    final loans = service.getLoans();

    // 1. Filter customers who have valid coordinates
    final validCustomers = customers.where((c) {
      final geo = c['geo_location'];
      return geo != null && geo['lat'] != null && geo['lng'] != null;
    }).toList();

    // 2. Sort customers based on selected routing mode
    if (_selectedRouteType == 'optimized') {
      // Sort by highest remaining balance (Optimal Dues first)
      validCustomers.sort((c1, c2) {
        final l1 = loans.firstWhere((l) => l['customer_id'] == c1['id'], orElse: () => {});
        final l2 = loans.firstWhere((l) => l['customer_id'] == c2['id'], orElse: () => {});
        final dues1 = (l1['remaining_balance'] as num?)?.toDouble() ?? 0.0;
        final dues2 = (l2['remaining_balance'] as num?)?.toDouble() ?? 0.0;
        return dues2.compareTo(dues1);
      });
    } else {
      // Nearest-neighbor route planning starting from Base Station (12.9719, 77.5937)
      final unvisited = List<Map<String, dynamic>>.from(validCustomers);
      final visited = <Map<String, dynamic>>[];
      double currentLat = 12.9719;
      double currentLng = 77.5937;

      while (unvisited.isNotEmpty) {
        Map<String, dynamic>? closest;
        double minD = double.maxFinite;
        int closestIdx = -1;

        for (int i = 0; i < unvisited.length; i++) {
          final c = unvisited[i];
          final lat = (c['geo_location']['lat'] as num).toDouble();
          final lng = (c['geo_location']['lng'] as num).toDouble();
          
          final dx = (lng - currentLng) * 111.0 * cos(lat * pi / 180.0);
          final dy = (lat - currentLat) * 111.0;
          final d = sqrt(dx * dx + dy * dy);

          if (d < minD) {
            minD = d;
            closest = c;
            closestIdx = i;
          }
        }

        if (closest != null) {
          visited.add(closest);
          currentLat = (closest['geo_location']['lat'] as num).toDouble();
          currentLng = (closest['geo_location']['lng'] as num).toDouble();
          unvisited.removeAt(closestIdx);
        } else {
          break;
        }
      }
      validCustomers.clear();
      validCustomers.addAll(visited);
    }

    // 3. Normalize coordinates for the custom vector painter bounding box
    const baseLat = 12.9719;
    const baseLng = 77.5937;

    double minLat = baseLat;
    double maxLat = baseLat;
    double minLng = baseLng;
    double maxLng = baseLng;

    for (var c in validCustomers) {
      final lat = (c['geo_location']['lat'] as num).toDouble();
      final lng = (c['geo_location']['lng'] as num).toDouble();
      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lng < minLng) minLng = lng;
      if (lng > maxLng) maxLng = lng;
    }

    final latRange = (maxLat - minLat == 0) ? 0.015 : (maxLat - minLat);
    final lngRange = (maxLng - minLng == 0) ? 0.015 : (maxLng - minLng);

    // Points normalized to [0.0, 1.0] range
    final List<Offset> normalizedPoints = [];
    final List<double> weights = [];

    // Add base station as first coordinate
    normalizedPoints.add(Offset(
      (baseLng - minLng) / lngRange,
      1.0 - (baseLat - minLat) / latRange,
    ));
    weights.add(0.0);

    for (var c in validCustomers) {
      final lat = (c['geo_location']['lat'] as num).toDouble();
      final lng = (c['geo_location']['lng'] as num).toDouble();
      normalizedPoints.add(Offset(
        (lng - minLng) / lngRange,
        1.0 - (lat - minLat) / latRange,
      ));

      // Calculate weight based on loan amount (for heat map size/intensity)
      final l = loans.firstWhere((l) => l['customer_id'] == c['id'], orElse: () => {});
      final balance = (l['remaining_balance'] as num?)?.toDouble() ?? 0.0;
      weights.add(balance / 500000.0); // scaled relative to 500k max
    }

    // Calculate total commute distance and time dynamically
    double totalDistance = 0.0;
    double curLat = baseLat;
    double curLng = baseLng;

    for (var c in validCustomers) {
      final lat = (c['geo_location']['lat'] as num).toDouble();
      final lng = (c['geo_location']['lng'] as num).toDouble();
      
      final dx = (lng - curLng) * 111.0 * cos(lat * pi / 180.0);
      final dy = (lat - curLat) * 111.0;
      totalDistance += sqrt(dx * dx + dy * dy);

      curLat = lat;
      curLng = lng;
    }
    
    if (totalDistance == 0.0) totalDistance = 8.4;
    final commuteMins = (totalDistance / 22.0 * 60.0).round(); // approx 22km/h speed

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
                      points: normalizedPoints,
                      weights: weights,
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
                              _buildLegendItem(AppTheme.neonGreen, 'Low Risk (Dues < 150k)'),
                              _buildLegendItem(AppTheme.dangerRed, 'High Risk (Dues > 300k)'),
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
                          Text('Est. Distance: ${totalDistance.toStringAsFixed(1)} km', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                          Text('Avg. Commute: $commuteMins mins', style: const TextStyle(color: Colors.grey, fontSize: 10)),
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

          FutureBuilder<List<Map<String, dynamic>>>(
            future: service.getAgentsWithStats(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final agents = snapshot.data ?? [];
              if (agents.isEmpty) {
                return const Text('No active agents registered in database.', style: TextStyle(color: Colors.grey));
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: agents.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final agent = agents[index];
                  final double target = agent['target_amount'] ?? 50000.0;
                  final double collected = agent['collected_amount'] ?? 0.0;
                  final double efficiency = target > 0 ? (collected / target * 100) : 0.0;

                  return _buildAgentListCard(
                    context,
                    name: agent['full_name'] ?? 'Agent',
                    status: agent['status'] ?? 'Offline',
                    lastCheckIn: agent['last_check_in'] ?? 'N/A',
                    target: '₹${(target).toStringAsFixed(0)}',
                    collected: '₹${(collected).toStringAsFixed(0)}',
                    efficiency: efficiency,
                  );
                },
              );
            },
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
  final List<Offset> points;
  final List<double> weights;
  final bool isDark;

  MapVectorPainter({
    required this.showHeatmap,
    required this.points,
    required this.weights,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw map background street grid network
    final paintBase = Paint()
      ..color = isDark ? const Color(0xFF1E293B) : Colors.grey[400]!
      ..strokeWidth = 1.0;

    final gridPoints = [
      [Offset(0, size.height * 0.2), Offset(size.width, size.height * 0.35)],
      [Offset(size.width * 0.2, 0), Offset(size.width * 0.35, size.height)],
      [Offset(0, size.height * 0.8), Offset(size.width, size.height * 0.65)],
      [Offset(size.width * 0.75, 0), Offset(size.width * 0.55, size.height)],
      [Offset(size.width * 0.1, size.height * 0.5), Offset(size.width * 0.9, size.height * 0.45)],
      [Offset(0, size.height * 0.5), Offset(size.width, size.height * 0.8)],
    ];

    for (var pts in gridPoints) {
      canvas.drawLine(pts[0], pts[1], paintBase);
    }

    if (points.isEmpty) return;

    // Map normalized points [0, 1] to canvas scale coordinates
    final canvasPoints = points.map((p) => Offset(
      24 + p.dx * (size.width - 48),
      24 + p.dy * (size.height - 48),
    )).toList();

    if (showHeatmap) {
      // Draw Heatmap glowing density circles
      for (int i = 1; i < canvasPoints.length; i++) {
        final pos = canvasPoints[i];
        final w = weights[i]; // relative balance size (0.0 to 1.0)
        
        final double radius = 30 + w * 45;
        final Color col = w > 0.6 
            ? AppTheme.dangerRed.withValues(alpha: 0.25)
            : AppTheme.neonGreen.withValues(alpha: 0.3);

        final paintZone = Paint()
          ..color = col
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);

        canvas.drawCircle(pos, radius, paintZone);
      }
    } else {
      // Draw path line connecting the optimized stops
      final pathPaint = Paint()
        ..color = AppTheme.primaryCyan
        ..strokeWidth = 3.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final path = Path();
      path.moveTo(canvasPoints[0].dx, canvasPoints[0].dy);
      for (int i = 1; i < canvasPoints.length; i++) {
        path.lineTo(canvasPoints[i].dx, canvasPoints[i].dy);
      }

      canvas.drawPath(path, pathPaint);

      // Draw Base point and stops
      final stopPaint = Paint()..color = AppTheme.primaryBlue;
      final targetPaint = Paint()..color = AppTheme.primaryCyan;

      // Base Station (Amit Varma Base)
      canvas.drawCircle(canvasPoints[0], 9, stopPaint);

      // Collection stops
      for (int i = 1; i < canvasPoints.length; i++) {
        canvas.drawCircle(canvasPoints[i], 7, targetPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
