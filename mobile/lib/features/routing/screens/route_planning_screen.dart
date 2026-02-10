import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/services/location_search_service.dart';
import '../providers/routing_provider.dart';
import '../../map/providers/map_provider.dart';

class RoutePlanningScreen extends ConsumerStatefulWidget {
  const RoutePlanningScreen({super.key});

  @override
  ConsumerState<RoutePlanningScreen> createState() => _RoutePlanningScreenState();
}

class _RoutePlanningScreenState extends ConsumerState<RoutePlanningScreen> {
  String? _originText;
  String? _destinationText;
  final List<String> _waypointTexts = [];
  final List<LatLng> _waypoints = [];

  LatLng? _origin;
  LatLng? _destination;

  bool _avoidTolls = false;
  bool _avoidFerries = false;
  bool _includeRestStops = true;

  @override
  Widget build(BuildContext context) {
    final routingState = ref.watch(routingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan Route'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Route inputs
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Origin
                _LocationInput(
                  text: _originText,
                  icon: Icons.trip_origin,
                  iconColor: Colors.green,
                  hint: 'Starting point',
                  onTap: () => _selectLocation('origin'),
                ),
                const SizedBox(height: 8),

                // Waypoints
                ..._waypointTexts.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _LocationInput(
                      text: entry.value,
                      icon: Icons.circle,
                      iconColor: Colors.orange,
                      hint: 'Waypoint ${entry.key + 1}',
                      onTap: () => _selectLocation('waypoint_${entry.key}'),
                      onRemove: () => _removeWaypoint(entry.key),
                    ),
                  );
                }),

                // Add waypoint button
                if (_waypointTexts.length < 5)
                  TextButton.icon(
                    onPressed: _addWaypoint,
                    icon: const Icon(Icons.add),
                    label: const Text('Add stop'),
                  ),

                // Destination
                _LocationInput(
                  text: _destinationText,
                  icon: Icons.location_on,
                  iconColor: Colors.red,
                  hint: 'Destination',
                  onTap: () => _selectLocation('destination'),
                ),
              ],
            ),
          ),

          // Truck profile settings
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Vehicle Profile',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _ProfileChip(label: 'Height', value: '4.0m', onTap: () {}),
                        const SizedBox(width: 8),
                        _ProfileChip(label: 'Weight', value: '40t', onTap: () {}),
                        const SizedBox(width: 8),
                        _ProfileChip(label: 'Length', value: '16.5m', onTap: () {}),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _ProfileChip(label: 'Width', value: '2.55m', onTap: () {}),
                        const SizedBox(width: 8),
                        _ProfileChip(label: 'Axles', value: '5', onTap: () {}),
                        const SizedBox(width: 8),
                        _ProfileChip(label: 'Hazmat', value: 'None', onTap: () {}),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Route options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Avoid tolls'),
                    value: _avoidTolls,
                    onChanged: (value) => setState(() => _avoidTolls = value),
                  ),
                  SwitchListTile(
                    title: const Text('Avoid ferries'),
                    value: _avoidFerries,
                    onChanged: (value) => setState(() => _avoidFerries = value),
                  ),
                  SwitchListTile(
                    title: const Text('Include rest stops'),
                    subtitle: const Text('Auto-plan EC 561 compliant breaks'),
                    value: _includeRestStops,
                    onChanged: (value) => setState(() => _includeRestStops = value),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // Route preview (if calculated)
          if (routingState.currentRoute != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          routingState.currentRoute!.formattedDistance,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        Text(
                          '${routingState.currentRoute!.formattedDuration} • ${routingState.currentRoute!.requiredBreaks} breaks needed',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _startNavigation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Start'),
                  ),
                ],
              ),
            ),

          // Calculate route button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_origin != null && _destination != null && !routingState.isCalculating)
                    ? _calculateRoute
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: routingState.isCalculating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Calculate Route'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectLocation(String field) async {
    final fieldType = field.startsWith('waypoint') ? 'waypoint' : field;
    final result = await context.push<SearchResult>('/search-location/$fieldType');

    if (result != null && mounted) {
      setState(() {
        if (field == 'origin') {
          _origin = result.location;
          _originText = result.name;
        } else if (field == 'destination') {
          _destination = result.location;
          _destinationText = result.name;
        } else if (field.startsWith('waypoint_')) {
          final index = int.parse(field.split('_')[1]);
          if (index < _waypoints.length) {
            _waypoints[index] = result.location;
            _waypointTexts[index] = result.name;
          }
        }
      });
    }
  }

  void _addWaypoint() {
    setState(() {
      _waypointTexts.add('');
      _waypoints.add(const LatLng(0, 0));
    });
    _selectLocation('waypoint_${_waypointTexts.length - 1}');
  }

  void _removeWaypoint(int index) {
    setState(() {
      _waypointTexts.removeAt(index);
      _waypoints.removeAt(index);
    });
  }

  Future<void> _calculateRoute() async {
    if (_origin == null || _destination == null) return;

    final routingNotifier = ref.read(routingProvider.notifier);

    routingNotifier.setOrigin(_origin!);
    routingNotifier.setDestination(_destination!);
    routingNotifier.setAvoidTolls(_avoidTolls);
    routingNotifier.setAvoidFerries(_avoidFerries);
    routingNotifier.setIncludeRestStops(_includeRestStops);

    // Add waypoints
    for (final waypoint in _waypoints) {
      if (waypoint.latitude != 0 && waypoint.longitude != 0) {
        routingNotifier.addWaypoint(waypoint);
      }
    }

    await routingNotifier.calculateRoute();
  }

  void _startNavigation() {
    final routingState = ref.read(routingProvider);
    if (routingState.currentRoute != null) {
      // Set the route on the map and start navigation
      ref.read(mapProvider.notifier).startNavigation(routingState.currentRoute!);
      context.go('/');
    }
  }
}

class _LocationInput extends StatelessWidget {
  final String? text;
  final IconData icon;
  final Color iconColor;
  final String hint;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const _LocationInput({
    this.text,
    required this.icon,
    required this.iconColor,
    required this.hint,
    required this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text ?? hint,
                style: TextStyle(
                  color: text != null ? Colors.black : Colors.grey,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onRemove != null)
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: onRemove,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileChip extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _ProfileChip({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
