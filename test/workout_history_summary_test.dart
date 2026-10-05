import 'package:fitness_aura_athletix/core/models/workout_history_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 10, 5, 13);

  test('uses calendar days for weekly session totals', () {
    final summary = WorkoutHistorySummary(
      now: today,
      workoutDates: [
        DateTime(2026, 9, 29, 23, 59),
        DateTime(2026, 10, 5, 8),
        DateTime(2026, 10, 5, 12),
        DateTime(2026, 9, 28, 18),
        DateTime(2026, 10, 6, 9),
      ],
      exerciseRecordDates: const [],
    );

    expect(summary.totalWorkoutCount, 5);
    expect(summary.workoutsThisWeek, 3);
    expect(summary.last7DayCounts, hasLength(7));
    expect(summary.last7DayCounts[DateTime(2026, 10, 5)], 2);
    expect(summary.last7DayCounts[DateTime(2026, 9, 29)], 1);
  });

  test('keeps a streak active through the day after last workout', () {
    final summary = WorkoutHistorySummary(
      now: today,
      workoutDates: [DateTime(2026, 10, 3, 20), DateTime(2026, 10, 4, 6)],
      exerciseRecordDates: const [],
    );

    expect(summary.currentStreakDays, 2);
  });

  test('breaks a streak after a missed day', () {
    final summary = WorkoutHistorySummary(
      now: today,
      workoutDates: [DateTime(2026, 10, 1), DateTime(2026, 10, 3)],
      exerciseRecordDates: const [],
    );

    expect(summary.currentStreakDays, 0);
  });

  test('uses unique exercise activity days when no workout entries exist', () {
    final summary = WorkoutHistorySummary(
      now: today,
      workoutDates: const [],
      exerciseRecordDates: [
        DateTime(2026, 10, 3, 8),
        DateTime(2026, 10, 3, 18),
        DateTime(2026, 10, 4, 9),
      ],
    );

    expect(summary.totalWorkoutCount, 2);
    expect(summary.workoutsThisWeek, 2);
    expect(summary.currentStreakDays, 2);
    expect(summary.last7DayCounts[DateTime(2026, 10, 3)], 1);
    expect(summary.last7DayCounts[DateTime(2026, 10, 4)], 1);
  });
}
