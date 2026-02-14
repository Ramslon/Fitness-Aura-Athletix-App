import 'package:flutter/material.dart';
import 'package:fitness_aura_athletix/services/daily_workout_analysis_engine.dart';

Future<void> showSimpleProgressSummaryDialog(
  BuildContext context, {
  required DailyWorkoutAnalysis analysis,
}) {
  final lines = <String>[];

  if (analysis.prsAndMilestones.isNotEmpty) {
    lines.addAll(analysis.prsAndMilestones.take(2));
  }
  if (analysis.overloadDetails.isNotEmpty) {
    for (final d in analysis.overloadDetails.take(2)) {
      final exists = lines.any((x) => x.toLowerCase() == d.toLowerCase());
      if (!exists) lines.add(d);
    }
  }

  if (analysis.volumeChangePercent != null) {
    final v = analysis.volumeChangePercent!;
    lines.add('Volume: ${v >= 0 ? '+' : ''}${v.toStringAsFixed(0)}%');
  }

  final uniqueLines = lines.take(4).toList(growable: false);

  return showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('Great Session 💪'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${analysis.bodyPart} workout summary',
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            if (uniqueLines.isEmpty)
              const Text('Solid consistency today. Keep progressing!')
            else
              ...uniqueLines.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('• $line'),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Nice'),
          ),
        ],
      );
    },
  );
}
