import 'package:flutter/material.dart';

class WeeklyCheckinCard extends StatelessWidget {
  final int workoutsThisWeek;
  final int weeklyGoal;
  final double volumePercent;
  final String recoveryLabel;

  const WeeklyCheckinCard({
    Key? key,
    required this.workoutsThisWeek,
    this.weeklyGoal = 5,
    required this.volumePercent,
    required this.recoveryLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final volText = '${volumePercent >= 0 ? '+' : ''}${volumePercent.toStringAsFixed(0)}%';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Check-in',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            Text('Workouts: $workoutsThisWeek/$weeklyGoal'),
            const SizedBox(height: 4),
            Text('Volume: $volText'),
            const SizedBox(height: 4),
            Text('Recovery: $recoveryLabel'),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: (workoutsThisWeek / weeklyGoal).clamp(0, 1),
                minHeight: 8,
                backgroundColor: scheme.onSurface.withValues(alpha: 0.10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
