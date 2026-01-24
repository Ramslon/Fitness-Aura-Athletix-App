/// Represents a smart improvement suggestion from the AI coach
class CoachSuggestion {
  final String id;
  final String exerciseName;
  final String bodyPart;
  final SuggestionType type;
  final String suggestion;
  final String rationale;
  final double priority; // 0-1, higher = more important
  final DateTime suggestedDate;
  final String? currentValue; // Current weight, reps, sets
  final String? recommendedValue; // Recommended weight, reps, sets

  CoachSuggestion({
    required this.id,
    required this.exerciseName,
    required this.bodyPart,
    required this.type,
    required this.suggestion,
    required this.rationale,
    required this.priority,
    required this.suggestedDate,
    this.currentValue,
    this.recommendedValue,
  });

  String get emoji {
    switch (type) {
      case SuggestionType.increaseWeight:
        return '⬆️';
      case SuggestionType.increaseReps:
        return '📈';
      case SuggestionType.increaseSets:
        return '➕';
      case SuggestionType.accessoryExercise:
        return '💪';
      case SuggestionType.deload:
        return '🛑';
      case SuggestionType.technique:
        return '🎯';
    }
  }
}

enum SuggestionType {
  increaseWeight,
  increaseReps,
  increaseSets,
  accessoryExercise,
  deload,
  technique,
}

/// Accessory exercise recommendation
class AccessorySuggestion {
  final String muscleGroup;
  final String suggestedExercise;
  final String benefit;
  final String reason;
  final int recommendedSets;
  final String recommendedReps;

  AccessorySuggestion({
    required this.muscleGroup,
    required this.suggestedExercise,
    required this.benefit,
    required this.reason,
    required this.recommendedSets,
    required this.recommendedReps,
  });
}
