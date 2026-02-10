import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/location_provider.dart';

class LocationDetailScreen extends ConsumerWidget {
  final String locationId;

  const LocationDetailScreen({super.key, required this.locationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationAsync = ref.watch(locationDetailProvider(locationId));
    final reviewsAsync = ref.watch(locationReviewsProvider(locationId));
    final aiSummaryAsync = ref.watch(locationAiSummaryProvider(locationId));

    return Scaffold(
      body: locationAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text('Failed to load location', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(locationDetailProvider(locationId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (location) {
          if (location == null) {
            return const Center(child: Text('Location not found'));
          }

          return CustomScrollView(
            slivers: [
              // Header image
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    location.name,
                    style: const TextStyle(fontSize: 16),
                  ),
                  background: Container(
                    color: Colors.grey[300],
                    child: Icon(
                      _getLocationIcon(location.locationType),
                      size: 80,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () => _shareLocation(context, location),
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
                                Text(
                                  location.name,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_formatLocationType(location.locationType)} ${location.address != null ? '• ${location.address}' : ''}',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                          if (location.avgRating != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _getRatingColor(location.avgRating!).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.star, color: _getRatingColor(location.avgRating!), size: 20),
                                  const SizedBox(width: 4),
                                  Text(
                                    location.avgRating!.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _getRatingColor(location.avgRating!),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${location.totalReviews} reviews',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                      const SizedBox(height: 16),

                      // Quick actions
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _navigateToLocation(context, location),
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
                      aiSummaryAsync.when(
                        loading: () => _buildAiSummaryLoading(),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (summary) {
                          if (summary == null || summary.isEmpty) {
                            if (location.totalReviews < 3) {
                              return _buildAiSummaryPlaceholder(location.totalReviews);
                            }
                            return const SizedBox.shrink();
                          }
                          return _buildAiSummaryCard(summary);
                        },
                      ),
                      const SizedBox(height: 24),

                      // Info section
                      const Text(
                        'Information',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      if (location.avgWaitingTimeMin != null)
                        _InfoRow(
                          icon: Icons.timer,
                          title: 'Avg wait time',
                          value: '${location.avgWaitingTimeMin} minutes',
                        ),
                      _InfoRow(
                        icon: Icons.location_on,
                        title: 'Coordinates',
                        value: '${location.lat.toStringAsFixed(4)}, ${location.lng.toStringAsFixed(4)}',
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
                      reviewsAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (_, __) => const Text('Failed to load reviews'),
                        data: (reviews) {
                          if (reviews.isEmpty) {
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  children: [
                                    Icon(Icons.rate_review, size: 48, color: Colors.grey[400]),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No reviews yet',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Be the first to review this location!',
                                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return Column(
                            children: reviews.take(3).map((review) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _ReviewCard(review: review),
                              );
                            }).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // Add review button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _showAddReviewSheet(context, ref),
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
          );
        },
      ),
    );
  }

  Widget _buildAiSummaryCard(String summary) {
    return Card(
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
                const Spacer(),
                Icon(Icons.info_outline, size: 16, color: Colors.blue[400]),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              summary,
              style: TextStyle(color: Colors.blue[900], height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiSummaryLoading() {
    return Card(
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
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.blue[400],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Generating summary...',
                  style: TextStyle(color: Colors.blue[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiSummaryPlaceholder(int currentReviews) {
    final needed = 3 - currentReviews;
    return Card(
      color: Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'AI Summary',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              needed == 1
                  ? 'Need 1 more review to generate AI summary'
                  : 'Need $needed more reviews to generate AI summary',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getLocationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'warehouse':
        return Icons.warehouse;
      case 'factory':
        return Icons.factory;
      case 'port':
        return Icons.directions_boat;
      case 'terminal':
        return Icons.local_shipping;
      default:
        return Icons.location_on;
    }
  }

  String _formatLocationType(String type) {
    return type[0].toUpperCase() + type.substring(1).toLowerCase();
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.0) return Colors.green;
    if (rating >= 3.0) return Colors.orange;
    return Colors.red;
  }

  void _navigateToLocation(BuildContext context, LocationDetail location) {
    context.push('/route');
  }

  void _shareLocation(BuildContext context, LocationDetail location) {
    // Would share location details
  }

  void _showAddReviewSheet(BuildContext context, WidgetRef ref) {
    int selectedRating = 4;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
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
                        index < selectedRating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                      onPressed: () {
                        setState(() => selectedRating = index + 1);
                      },
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
                    onPressed: () {
                      Navigator.pop(context);
                      ref.invalidate(locationReviewsProvider(locationId));
                      ref.invalidate(locationDetailProvider(locationId));
                    },
                    child: const Text('Submit Review'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
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

class _ReviewCard extends StatelessWidget {
  final LocationReview review;

  const _ReviewCard({required this.review});

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
                  child: Text(
                    review.reviewerName?.isNotEmpty == true
                        ? review.reviewerName![0].toUpperCase()
                        : '?',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.reviewerName ?? 'Anonymous',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          Text(
                            review.timeAgo,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          if (review.reviewerCountry != null) ...[
                            const SizedBox(width: 4),
                            Text(
                              '• ${review.reviewerCountry}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < review.overallRating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 16,
                    );
                  }),
                ),
              ],
            ),
            if (review.comment != null && review.comment!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(review.comment!),
            ],
            if (review.actualWaitingTimeMin != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Wait time: ${review.actualWaitingTimeMin} min',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
