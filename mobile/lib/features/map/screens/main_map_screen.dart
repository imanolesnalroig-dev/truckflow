import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/bottom_nav_bar.dart';

class MainMapScreen extends ConsumerStatefulWidget {
  final Widget? child;

  const MainMapScreen({super.key, this.child});

  @override
  ConsumerState<MainMapScreen> createState() => _MainMapScreenState();
}

class _MainMapScreenState extends ConsumerState<MainMapScreen> {
  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/parking')) return 1;
    if (location.startsWith('/compliance')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _getSelectedIndex(context);

    // For non-map tabs, show the child directly with bottom nav
    if (widget.child != null && selectedIndex != 0) {
      return Scaffold(
        body: widget.child,
        bottomNavigationBar: TruckFlowBottomNavBar(currentIndex: selectedIndex),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Map placeholder - will be Mapbox
          Container(
            color: Colors.grey[200],
            child: const Center(
              child: Text(
                'Map View\n(Mapbox integration pending)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ),
          ),

          // Top bar - Speed & driving time
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // Current speed
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('0', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                        Text('km/h', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(width: 24),
                    // Speed limit
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.red, width: 3),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text('80', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const Spacer(),
                    // Driving time remaining
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('4:30', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Text('until break', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Search bar
          Positioned(
            bottom: 160,
            left: 16,
            right: 16,
            child: Card(
              child: InkWell(
                onTap: () {
                  // Navigate to route planning
                },
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: Colors.grey),
                      SizedBox(width: 12),
                      Text('Where to?', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Quick action buttons
          Positioned(
            bottom: 80,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'parking',
                  onPressed: () {},
                  child: const Icon(Icons.local_parking),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'fuel',
                  onPressed: () {},
                  backgroundColor: Colors.orange,
                  child: const Icon(Icons.local_gas_station),
                ),
              ],
            ),
          ),

          // Report hazard button
          Positioned(
            bottom: 80,
            left: 16,
            child: FloatingActionButton.extended(
              heroTag: 'hazard',
              onPressed: () {
                _showHazardReportSheet(context);
              },
              backgroundColor: Colors.red,
              icon: const Icon(Icons.warning),
              label: const Text('Report'),
            ),
          ),

          // Child widget (for nested routes)
          if (widget.child != null) widget.child!,
        ],
      ),
      bottomNavigationBar: TruckFlowBottomNavBar(currentIndex: selectedIndex),
    );
  }

  void _showHazardReportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Report Hazard', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _HazardButton(icon: '👮', label: 'Police', onTap: () {}),
                _HazardButton(icon: '📸', label: 'Camera', onTap: () {}),
                _HazardButton(icon: '🚗', label: 'Accident', onTap: () {}),
                _HazardButton(icon: '🚧', label: 'Road Works', onTap: () {}),
                _HazardButton(icon: '🚫', label: 'Closed', onTap: () {}),
                _HazardButton(icon: '⚠️', label: 'Hazard', onTap: () {}),
                _HazardButton(icon: '🌧️', label: 'Weather', onTap: () {}),
                _HazardButton(icon: '🛂', label: 'Border', onTap: () {}),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _HazardButton extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;

  const _HazardButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
