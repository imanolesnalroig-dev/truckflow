import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ParkingScreen extends ConsumerStatefulWidget {
  const ParkingScreen({super.key});

  @override
  ConsumerState<ParkingScreen> createState() => _ParkingScreenState();
}

class _ParkingScreenState extends ConsumerState<ParkingScreen> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Truck Parking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () {
              // Toggle map view
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search parking areas...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),

          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _selectedFilter == 'all',
                  onTap: () => setState(() => _selectedFilter = 'all'),
                ),
                _FilterChip(
                  label: 'Free',
                  selected: _selectedFilter == 'free',
                  onTap: () => setState(() => _selectedFilter = 'free'),
                ),
                _FilterChip(
                  label: 'Secured',
                  selected: _selectedFilter == 'secured',
                  onTap: () => setState(() => _selectedFilter = 'secured'),
                ),
                _FilterChip(
                  label: 'With services',
                  selected: _selectedFilter == 'services',
                  onTap: () => setState(() => _selectedFilter = 'services'),
                ),
                _FilterChip(
                  label: 'Available now',
                  selected: _selectedFilter == 'available',
                  onTap: () => setState(() => _selectedFilter = 'available'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Parking list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                _ParkingCard(
                  name: 'Autohof Burgau',
                  distance: '12 km',
                  occupancy: 0.65,
                  totalSpaces: 85,
                  freeSpaces: 30,
                  price: '€12/night',
                  amenities: ['shower', 'restaurant', 'wifi', 'security'],
                  rating: 4.2,
                ),
                SizedBox(height: 12),
                _ParkingCard(
                  name: 'Shell Station A8',
                  distance: '18 km',
                  occupancy: 0.90,
                  totalSpaces: 40,
                  freeSpaces: 4,
                  price: 'Free',
                  amenities: ['fuel', 'shop'],
                  rating: 3.5,
                ),
                SizedBox(height: 12),
                _ParkingCard(
                  name: 'Rasthof München-West',
                  distance: '25 km',
                  occupancy: 0.45,
                  totalSpaces: 120,
                  freeSpaces: 66,
                  price: '€15/night',
                  amenities: ['shower', 'restaurant', 'wifi', 'security', 'fuel'],
                  rating: 4.5,
                ),
                SizedBox(height: 12),
                _ParkingCard(
                  name: 'Industrial Area P3',
                  distance: '8 km',
                  occupancy: 0.20,
                  totalSpaces: 30,
                  freeSpaces: 24,
                  price: 'Free',
                  amenities: [],
                  rating: 2.8,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddParkingSheet(context);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Parking'),
      ),
    );
  }

  void _showAddParkingSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Parking Area',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g., Shell Station A8',
                ),
              ),
              const SizedBox(height: 12),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Approximate spaces',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(height: 12),
              const Text('Type'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(label: const Text('Free'), selected: true, onSelected: (_) {}),
                  ChoiceChip(label: const Text('Paid'), selected: false, onSelected: (_) {}),
                  ChoiceChip(label: const Text('Secured'), selected: false, onSelected: (_) {}),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Add at Current Location'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _ParkingCard extends StatelessWidget {
  final String name;
  final String distance;
  final double occupancy;
  final int totalSpaces;
  final int freeSpaces;
  final String price;
  final List<String> amenities;
  final double rating;

  const _ParkingCard({
    required this.name,
    required this.distance,
    required this.occupancy,
    required this.totalSpaces,
    required this.freeSpaces,
    required this.price,
    required this.amenities,
    required this.rating,
  });

  Color get _occupancyColor {
    if (occupancy < 0.5) return Colors.green;
    if (occupancy < 0.8) return Colors.orange;
    return Colors.red;
  }

  IconData _getAmenityIcon(String amenity) {
    switch (amenity) {
      case 'shower':
        return Icons.shower;
      case 'restaurant':
        return Icons.restaurant;
      case 'wifi':
        return Icons.wifi;
      case 'security':
        return Icons.security;
      case 'fuel':
        return Icons.local_gas_station;
      case 'shop':
        return Icons.shopping_cart;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          // Navigate to parking detail
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          distance,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(rating.toString()),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        price,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: price == 'Free' ? Colors.green : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Occupancy bar
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: occupancy,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation(_occupancyColor),
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$freeSpaces/$totalSpaces free',
                    style: TextStyle(
                      color: _occupancyColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (amenities.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: amenities
                      .map((a) => Icon(_getAmenityIcon(a), size: 20, color: Colors.grey[600]))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
