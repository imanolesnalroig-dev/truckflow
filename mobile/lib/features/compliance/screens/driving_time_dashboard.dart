import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DrivingTimeDashboard extends ConsumerWidget {
  const DrivingTimeDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driving Time'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // Show history
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current status card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Current Status',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'DRIVING',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Time until break
                    _TimeDisplay(
                      label: 'Until required break',
                      hours: 4,
                      minutes: 30,
                      status: TimeStatus.ok,
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    // Control buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.coffee),
                            label: const Text('Start Break'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.hotel),
                            label: const Text('Start Rest'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Daily limits
            const Text(
              'Daily Limits',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _ProgressRow(
                      label: 'Daily driving',
                      current: 4.5,
                      max: 9,
                      unit: 'hours',
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    _ProgressRow(
                      label: 'Extended days used',
                      current: 1,
                      max: 2,
                      unit: 'this week',
                      color: Colors.orange,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Weekly limits
            const Text(
              'Weekly Limits',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _ProgressRow(
                      label: 'This week',
                      current: 32,
                      max: 56,
                      unit: 'hours',
                      color: Colors.purple,
                    ),
                    const SizedBox(height: 16),
                    _ProgressRow(
                      label: 'Bi-weekly total',
                      current: 58,
                      max: 90,
                      unit: 'hours',
                      color: Colors.teal,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Rest requirements
            const Text(
              'Rest Requirements',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  _RestTile(
                    title: 'Daily rest',
                    requirement: '11h (or 9h reduced)',
                    status: 'Completed: 10h 30m',
                    isComplete: true,
                  ),
                  const Divider(height: 1),
                  _RestTile(
                    title: 'Weekly rest',
                    requirement: '45h (or 24h reduced)',
                    status: 'Due in 3 days',
                    isComplete: false,
                  ),
                  const Divider(height: 1),
                  _RestTile(
                    title: 'Break',
                    requirement: '45min after 4.5h driving',
                    status: '4h 30m until required',
                    isComplete: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // EC 561/2006 info
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tracking compliance with EC Regulation 561/2006. '
                        'This is for guidance only - always verify with official records.',
                        style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum TimeStatus { ok, warning, critical }

class _TimeDisplay extends StatelessWidget {
  final String label;
  final int hours;
  final int minutes;
  final TimeStatus status;

  const _TimeDisplay({
    required this.label,
    required this.hours,
    required this.minutes,
    required this.status,
  });

  Color get _color {
    switch (status) {
      case TimeStatus.ok:
        return Colors.green;
      case TimeStatus.warning:
        return Colors.orange;
      case TimeStatus.critical:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600])),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '$hours',
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: _color),
            ),
            Text('h ', style: TextStyle(fontSize: 24, color: _color)),
            Text(
              '$minutes',
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: _color),
            ),
            Text('m', style: TextStyle(fontSize: 24, color: _color)),
          ],
        ),
      ],
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final double current;
  final double max;
  final String unit;
  final Color color;

  const _ProgressRow({
    required this.label,
    required this.current,
    required this.max,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = current / max;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(
              '${current.toStringAsFixed(current % 1 == 0 ? 0 : 1)} / ${max.toStringAsFixed(0)} $unit',
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

class _RestTile extends StatelessWidget {
  final String title;
  final String requirement;
  final String status;
  final bool isComplete;

  const _RestTile({
    required this.title,
    required this.requirement,
    required this.status,
    required this.isComplete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        isComplete ? Icons.check_circle : Icons.access_time,
        color: isComplete ? Colors.green : Colors.grey,
      ),
      title: Text(title),
      subtitle: Text(requirement),
      trailing: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          color: isComplete ? Colors.green : Colors.grey[600],
        ),
      ),
    );
  }
}
