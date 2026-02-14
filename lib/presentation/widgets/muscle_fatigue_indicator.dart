import 'package:flutter/material.dart';
import 'package:fitness_aura_athletix/core/models/exercise.dart';
import 'package:fitness_aura_athletix/services/storage_service.dart';

enum MuscleFatigueState { fresh, trainedRecently, overworked }

class MuscleFatigueIndicator extends StatelessWidget {
  final String bodyPart;

  const MuscleFatigueIndicator({
    Key? key,
    required this.bodyPart,
  }) : super(key: key);

  static MuscleFatigueState _computeState(
    List<ExerciseRecord> all,
    String bodyPart,
  ) {
    final key = bodyPart.toLowerCase();
    final now = DateTime.now();

    final records = all
        .where((r) => r.bodyPart.toLowerCase() == key)
        .toList()
      ..sort((a, b) => b.dateRecorded.compareTo(a.dateRecorded));

    if (records.isEmpty) return MuscleFatigueState.fresh;

    final latest = records.first;
    final daysSinceLatest = now.difference(latest.dateRecorded).inDays;

    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final weekRecords = records.where((r) => r.dateRecorded.isAfter(sevenDaysAgo));

    var weekScore = 0.0;
    for (final r in weekRecords) {
      weekScore += r.progressScore;
    }

    final frequentHeavy = records
        .take(6)
        .where((r) => r.difficulty.toLowerCase().contains('hard'))
        .length >=
        3;

    if (daysSinceLatest <= 1 && (weekScore >= 1800 || frequentHeavy)) {
      return MuscleFatigueState.overworked;
    }
    if (daysSinceLatest <= 3) return MuscleFatigueState.trainedRecently;
    return MuscleFatigueState.fresh;
  }

  static Color _stateColor(MuscleFatigueState state) {
    switch (state) {
      case MuscleFatigueState.fresh:
        return const Color(0xFF2EE59D);
      case MuscleFatigueState.trainedRecently:
        return const Color(0xFFFFD166);
      case MuscleFatigueState.overworked:
        return const Color(0xFFFF5C5C);
    }
  }

  static String _stateLabel(MuscleFatigueState state) {
    switch (state) {
      case MuscleFatigueState.fresh:
        return 'Fresh';
      case MuscleFatigueState.trainedRecently:
        return 'Trained recently';
      case MuscleFatigueState.overworked:
        return 'Overworked';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ExerciseRecord>>(
      future: StorageService().loadExerciseRecords(),
      builder: (context, snapshot) {
        final records = snapshot.data ?? const <ExerciseRecord>[];
        final state = _computeState(records, bodyPart);
        final color = _stateColor(state);

        Widget legendDot(Color c, String label) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: c, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Muscle Fatigue Indicator',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.accessibility_new,
                          size: 48,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.30),
                        ),
                        Positioned(
                          right: 2,
                          top: 2,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                              border: Border.all(
                                color: Colors.black.withValues(alpha: 0.18),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '$bodyPart: ${_stateLabel(state)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    legendDot(const Color(0xFF2EE59D), 'Green → fresh'),
                    legendDot(const Color(0xFFFFD166), 'Yellow → trained recently'),
                    legendDot(const Color(0xFFFF5C5C), 'Red → overworked'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
