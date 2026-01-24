/// Represents muscle balance analysis and warnings
class MuscleBalanceAnalysis {
  final String muscleGroup;
  final int weeklyFrequency;
  final double volumeThisWeek;
  final double averageVolumePerSession;
  final String? warning;
  final bool isUnderTrained;
  final bool hasImbalance;

  MuscleBalanceAnalysis({
    required this.muscleGroup,
    required this.weeklyFrequency,
    required this.volumeThisWeek,
    required this.averageVolumePerSession,
    this.warning,
    required this.isUnderTrained,
    required this.hasImbalance,
  });
}

/// Represents recommended training frequency for muscle groups
class MuscleTrainingRecommendation {
  final String muscleGroup;
  final int currentFrequency;
  final int recommendedFrequency;
  final double volumeDifference; // Positive = exceeds recommended
  final String recommendation;
  final double volumeBalance; // Ratio compared to other muscles

  MuscleTrainingRecommendation({
    required this.muscleGroup,
    required this.currentFrequency,
    required this.recommendedFrequency,
    required this.volumeDifference,
    required this.recommendation,
    required this.volumeBalance,
  });
}

/// Tracks muscle group imbalances
class MuscleImbalanceWarning {
  final String? primaryMuscle; // e.g., "Chest"
  final String? secondaryMuscle; // e.g., "Back"
  final double volumeRatio; // primaryVolume / secondaryVolume
  final String warning;
  final String suggestion;
  final bool isCritical; // True if ratio > 1.5

  MuscleImbalanceWarning({
    required this.primaryMuscle,
    required this.secondaryMuscle,
    required this.volumeRatio,
    required this.warning,
    required this.suggestion,
    required this.isCritical,
  });
}
