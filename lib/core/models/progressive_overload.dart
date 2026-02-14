/// Represents progressive overload metrics for tracking improvements
class ProgressiveOverloadMetrics {
  final String exerciseName;
  final String bodyPart;
  final double previousWeight;
  final double currentWeight;
  final int previousReps;
  final int currentReps;
  final int previousSets;
  final int currentSets;
  /// Training load score.
  ///
  /// - Weighted exercises: kg*reps across sets.
  /// - Non-weight exercises: time-under-tension seconds if provided, otherwise total reps.
  final int previousVolume;
  final int currentVolume;
  final DateTime lastPerformedDate;
  final DateTime previousPerformedDate;

  ProgressiveOverloadMetrics({
    required this.exerciseName,
    required this.bodyPart,
    required this.previousWeight,
    required this.currentWeight,
    required this.previousReps,
    required this.currentReps,
    required this.previousSets,
    required this.currentSets,
    required this.previousVolume,
    required this.currentVolume,
    required this.lastPerformedDate,
    required this.previousPerformedDate,
  });

  bool get hasWeightIncrease => currentWeight > previousWeight;
  bool get hasRepIncrease => currentReps > previousReps;
  bool get hasSetIncrease => currentSets > previousSets;
  bool get hasVolumeIncrease => currentVolume > previousVolume;

  double get weightIncreasePercentage =>
      previousWeight == 0 ? 0 : ((currentWeight - previousWeight) / previousWeight * 100);
  double get repIncreasePercentage =>
      previousReps == 0 ? 0 : ((currentReps - previousReps) / previousReps * 100);
  double get volumeIncreasePercentage =>
      previousVolume == 0 ? 0 : ((currentVolume - previousVolume) / previousVolume * 100);

  int get daysSincePreviousWorkout => lastPerformedDate.difference(previousPerformedDate).inDays;
}

/// Tracks workout frequency per muscle group
class MuscleGroupFrequency {
  final String muscleGroup; // Body part
  final int workoutCountLastWeek;
  final int workoutCountLastMonth;
  final double averageFrequencyPerWeek;
  final DateTime lastWorkoutDate;

  MuscleGroupFrequency({
    required this.muscleGroup,
    required this.workoutCountLastWeek,
    required this.workoutCountLastMonth,
    required this.averageFrequencyPerWeek,
    required this.lastWorkoutDate,
  });
}
