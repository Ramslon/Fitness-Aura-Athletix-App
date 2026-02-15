import 'package:fitness_aura_athletix/core/models/exercise.dart';

class PrCelebrationService {
  static bool isNewPr({
    required ExerciseRecord current,
    required List<ExerciseRecord> previous,
  }) {
    if (previous.isEmpty) return false;

    final previousBest = previous
        .map((e) => e.progressScore)
        .fold<double>(0, (max, v) => v > max ? v : max);

    return current.progressScore > previousBest;
  }
}
