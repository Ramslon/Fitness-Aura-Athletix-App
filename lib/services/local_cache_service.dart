import 'package:fitness_aura_athletix/presentation/widgets/exercise_insights.dart';
import 'package:fitness_aura_athletix/services/daily_workout_analysis_engine.dart';
import 'package:fitness_aura_athletix/services/workout_session_service.dart';

/// Clears in-memory caches when auth scope changes.
class LocalCacheService {
  LocalCacheService._();
  static final LocalCacheService _instance = LocalCacheService._();
  factory LocalCacheService() => _instance;

  Future<void> clearTransientCaches() async {
    ExerciseInsights.invalidateCache();
    DailyWorkoutAnalysisEngine.invalidateCache();
    await WorkoutSessionService.instance.clear();
  }
}
