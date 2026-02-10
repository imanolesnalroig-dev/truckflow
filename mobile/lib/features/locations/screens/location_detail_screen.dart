import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocationDetailScreen extends ConsumerWidget {
  final String locationId;

  const LocationDetailScreen({super.key, required this.locationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mock data - would come from API
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header image
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.warehouse, size: 80, color: Colors.grey),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.bookmark_border),
                onPressed: () {},
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and rating
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'DHL Distribution Center Munich',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Warehouse • Munich, Germany',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.star, color: Colors.green, size: 20),
                            SizedBox(width: 4),
                            Text(
                              '4.2',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Quick actions
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.directions),
                          label: const Text('Navigate'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.phone),
                          label: const Text('Call'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // AI Summary
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.auto_awesome, color: Colors.blue[700]),
                              const SizedBox(width: 8),
                              Text(
                                'AI Summary',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Fast loading times (avg 45min). Staff speaks German and English. '
                            'Limited parking for waiting trucks. Best to arrive early morning. '
                            'Clean restrooms available.',
                            style: TextStyle(color: Colors.blue[900]),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Info section
                  const Text(
                    'Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.access_time,
                    title: 'Loading hours',
                    value: 'Mon-Fri 06:00-22:00, Sat 08:00-14:00',
                  ),
                  _InfoRow(
                    icon: Icons.timer,
                    title: 'Avg wait time',
                    value: '45 minutes',
                  ),
                  _InfoRow(
                    icon: Icons.local_parking,
                    title: 'Truck parking',
                    value: '10 spaces (often full)',
                  ),
                  _InfoRow(
                    icon: Icons.height,
                    title: 'Max height',
                    value: '4.2m',
                  ),
                  _InfoRow(
                    icon: Icons.language,
                    title: 'Languages',
                    value: 'German, English',
                  ),
                  const SizedBox(height: 24),

                  // Amenities
                  const Text(
                    'Amenities',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _AmenityChip(icon: Icons.wc, label: 'Restrooms'),
                      _AmenityChip(icon: Icons.wifi, label: 'WiFi'),
                      _AmenityChip(icon: Icons.coffee, label: 'Vending'),
                      _AmenityChip(icon: Icons.local_parking, label: 'Parking'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Reviews section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Driver Reviews',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('See all'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Review cards
                  const _ReviewCard(
                    author: 'Jan K.',
                    date: '2 days ago',
                    rating: 5,
                    comment: 'Very fast unloading, staff was helpful. Parking available if you arrive before 8am.',
                  ),
                  const SizedBox(height: 12),
                  const _ReviewCard(
                    author: 'Mihai R.',
                    date: '1 week ago',
                    rating: 3,
                    comment: 'Long wait time today, 2 hours. Usually faster. Good facilities though.',
                  ),
                  const SizedBox(height: 24),

                  // Add review button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _showAddReviewSheet(context);
                      },
                      icon: const Icon(Icons.rate_review),
                      label: const Text('Write a Review'),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddReviewSheet(BuildContext context) {
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
                'Write a Review',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('Rating'),
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < 4 ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () {},
                  );
                }),
              ),
              const SizedBox(height: 12),
              const TextField(
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Your experience',
                  hintText: 'Share details about loading time, staff, facilities...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Quick tags:',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ActionChip(label: const Text('Fast loading'), onPressed: () {}),
                  ActionChip(label: const Text('Friendly staff'), onPressed: () {}),
                  ActionChip(label: const Text('Clean facilities'), onPressed: () {}),
                  ActionChip(label: const Text('Long wait'), onPressed: () {}),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Submit Review'),
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                Text(value),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AmenityChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _AmenityChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final String author;
  final String date;
  final int rating;
  final String comment;

  const _ReviewCard({
    required this.author,
    required this.date,
    required this.rating,
    required this.comment,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[300],
                  child: Text(author[0]),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(author, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(date, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 16,
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(comment),
          ],
        ),
      ),
    );
  }
}
