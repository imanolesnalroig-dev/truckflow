import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile header
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[300],
                    child: const Icon(Icons.person, size: 50, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Jan Kowalski',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Driver since 2018',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  // Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatItem(value: '152', label: 'Reports'),
                      _StatItem(value: '47', label: 'Reviews'),
                      _StatItem(value: '3.2k', label: 'Km tracked'),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(),

            // Contribution level
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.amber[100],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.star, color: Colors.amber),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Gold Contributor',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text('Top 15% of drivers'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: 0.7,
                          backgroundColor: Colors.grey[200],
                          valueColor: const AlwaysStoppedAnimation(Colors.amber),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '350/500 points to Platinum',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Menu items
            _MenuItem(
              icon: Icons.local_shipping,
              title: 'My Vehicle',
              subtitle: 'Manage truck profile',
              onTap: () {},
            ),
            _MenuItem(
              icon: Icons.history,
              title: 'Trip History',
              subtitle: 'View past routes',
              onTap: () {},
            ),
            _MenuItem(
              icon: Icons.bookmark,
              title: 'Saved Places',
              subtitle: 'Favorite locations',
              onTap: () {},
            ),
            _MenuItem(
              icon: Icons.download,
              title: 'Offline Maps',
              subtitle: 'Manage downloaded regions',
              onTap: () {},
            ),
            const Divider(),
            _MenuItem(
              icon: Icons.language,
              title: 'Language',
              subtitle: 'English',
              onTap: () {},
            ),
            _MenuItem(
              icon: Icons.dark_mode,
              title: 'Appearance',
              subtitle: 'System default',
              onTap: () {},
            ),
            _MenuItem(
              icon: Icons.notifications,
              title: 'Notifications',
              subtitle: 'Alerts and reminders',
              onTap: () {},
            ),
            const Divider(),
            _MenuItem(
              icon: Icons.help_outline,
              title: 'Help & Support',
              onTap: () {},
            ),
            _MenuItem(
              icon: Icons.info_outline,
              title: 'About TruckFlow',
              onTap: () {},
            ),
            _MenuItem(
              icon: Icons.logout,
              title: 'Sign Out',
              titleColor: Colors.red,
              onTap: () {
                _showSignOutDialog(context);
              },
            ),
            const SizedBox(height: 24),
            // App version
            Text(
              'Version 1.0.0',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/onboarding');
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.titleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title, style: TextStyle(color: titleColor)),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
