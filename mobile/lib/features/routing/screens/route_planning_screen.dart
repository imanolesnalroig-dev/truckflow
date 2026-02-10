import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RoutePlanningScreen extends StatefulWidget {
  const RoutePlanningScreen({super.key});

  @override
  State<RoutePlanningScreen> createState() => _RoutePlanningScreenState();
}

class _RoutePlanningScreenState extends State<RoutePlanningScreen> {
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final List<TextEditingController> _waypointControllers = [];

  @override
  Widget build(BuildContext context) {
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
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Origin
                _LocationInput(
                  controller: _originController,
                  icon: Icons.trip_origin,
                  iconColor: Colors.green,
                  hint: 'Starting point',
                  onTap: () => _selectLocation('origin'),
                ),
                const SizedBox(height: 8),

                // Waypoints
                ..._waypointControllers.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _LocationInput(
                      controller: entry.value,
                      icon: Icons.circle,
                      iconColor: Colors.orange,
                      hint: 'Waypoint ${entry.key + 1}',
                      onTap: () => _selectLocation('waypoint_${entry.key}'),
                      onRemove: () => _removeWaypoint(entry.key),
                    ),
                  );
                }),

                // Add waypoint button
                if (_waypointControllers.length < 5)
                  TextButton.icon(
                    onPressed: _addWaypoint,
                    icon: const Icon(Icons.add),
                    label: const Text('Add stop'),
                  ),

                // Destination
                _LocationInput(
                  controller: _destinationController,
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
                    value: false,
                    onChanged: (value) {},
                  ),
                  SwitchListTile(
                    title: const Text('Avoid ferries'),
                    value: false,
                    onChanged: (value) {},
                  ),
                  SwitchListTile(
                    title: const Text('Include rest stops'),
                    subtitle: const Text('Auto-plan EC 561 compliant breaks'),
                    value: true,
                    onChanged: (value) {},
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // Calculate route button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _calculateRoute,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Calculate Route'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectLocation(String field) {
    // TODO: Open location search
  }

  void _addWaypoint() {
    setState(() {
      _waypointControllers.add(TextEditingController());
    });
  }

  void _removeWaypoint(int index) {
    setState(() {
      _waypointControllers[index].dispose();
      _waypointControllers.removeAt(index);
    });
  }

  void _calculateRoute() {
    // TODO: Calculate route via Valhalla
    context.pop();
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    for (final controller in _waypointControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}

class _LocationInput extends StatelessWidget {
  final TextEditingController controller;
  final IconData icon;
  final Color iconColor;
  final String hint;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const _LocationInput({
    required this.controller,
    required this.icon,
    required this.iconColor,
    required this.hint,
    required this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: controller,
            readOnly: true,
            onTap: onTap,
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        if (onRemove != null)
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: onRemove,
          ),
      ],
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
