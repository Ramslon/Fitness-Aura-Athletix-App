class WorkoutHistorySummary {
  final int totalWorkoutCount;
  final int workoutsThisWeek;
  final int currentStreakDays;
  final Map<DateTime, int> last7DayCounts;

  WorkoutHistorySummary._({
    required this.totalWorkoutCount,
    required this.workoutsThisWeek,
    required this.currentStreakDays,
    required this.last7DayCounts,
  });

  factory WorkoutHistorySummary({
    required Iterable<DateTime> workoutDates,
    required Iterable<DateTime> exerciseRecordDates,
    DateTime? now,
  }) {
    final today = _dayStart(now ?? DateTime.now());
    final workouts = workoutDates.map(_dayStart).toList(growable: false);
    final useWorkoutEntries = workouts.isNotEmpty;
    final exerciseDays = exerciseRecordDates.map(_dayStart).toSet();
    final activityDates = (useWorkoutEntries
            ? workouts
            : exerciseDays)
        .where((date) => !date.isAfter(today))
        .toList(growable: false);

    final firstDay = today.subtract(const Duration(days: 6));
    final counts = <DateTime, int>{
      for (var offset = 0; offset < 7; offset++)
        firstDay.add(Duration(days: offset)): 0,
    };

    if (useWorkoutEntries) {
      for (final date in workouts) {
        if (!date.isBefore(firstDay) && !date.isAfter(today)) {
          counts.update(date, (count) => count + 1, ifAbsent: () => 0);
        }
      }
    } else {
      for (final date in activityDates) {
        if (!date.isBefore(firstDay) && !date.isAfter(today)) {
          counts.update(date, (_) => 1, ifAbsent: () => 1);
        }
      }
    }

    final latestDay = activityDates.isEmpty
        ? null
        : activityDates.reduce((a, b) => a.isAfter(b) ? a : b);
    var streak = 0;
    if (latestDay != null &&
        !latestDay.isBefore(today.subtract(const Duration(days: 1)))) {
      final activeDays = activityDates.toSet();
      var cursor = latestDay;
      while (activeDays.contains(cursor)) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      }
    }

    return WorkoutHistorySummary._(
      totalWorkoutCount: useWorkoutEntries ? workouts.length : exerciseDays.length,
      workoutsThisWeek: counts.values.fold(0, (sum, count) => sum + count),
      currentStreakDays: streak,
      last7DayCounts: Map.unmodifiable(counts),
    );
  }

  static DateTime _dayStart(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
