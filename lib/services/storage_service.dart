import 'dart:convert';
import 'dart:isolate';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fitness_aura_athletix/core/models/exercise.dart';
import 'package:fitness_aura_athletix/core/models/progressive_overload.dart';
import 'package:fitness_aura_athletix/core/models/muscle_balance.dart';
import 'package:fitness_aura_athletix/core/models/coach_suggestion.dart';
import 'package:fitness_aura_athletix/core/models/volume_load.dart';
import 'package:fitness_aura_athletix/core/models/goal.dart';
import 'package:fitness_aura_athletix/services/exercise_records_store.dart';
import 'package:fitness_aura_athletix/services/auth_service.dart';

/// Simple StorageService to persist daily workout entries.
/// Each entry is stored as a JSON object with:
///  - id: unique string
///  - date: ISO8601 date
///  - workoutType: string (e.g., 'arm', 'chest')
///  - durationMinutes: int
///  - notes: optional string
class StorageService {
  static const _kEntriesKey = 'workout_entries_v1';
  static const _kGoalsKey = 'goals_v1';
  static const _kActiveGoalIdKey = 'active_goal_id_v1';

  StorageService._();
  static final StorageService _instance = StorageService._();
  factory StorageService() => _instance;

  Future<SharedPreferences> get _prefs async =>
      await SharedPreferences.getInstance();

  final FlutterSecureStorage _secure = const FlutterSecureStorage();
  final AuthService _authService = AuthService();

  Future<String> _scopedKey(String baseKey) async {
    final isGuest = await _authService.isGuestMode();
    final uid = _authService.currentUser?.uid;
    final scope = isGuest ? 'guest' : (uid ?? 'anonymous');
    return '${baseKey}_$scope';
  }

  Future<List<Map<String, dynamic>>> _readEntriesRaw() async {
    final prefs = await _prefs;
    final key = await _scopedKey(_kEntriesKey);
    final s = prefs.getString(key);
    if (s == null || s.isEmpty) return [];
    final List<dynamic> list = jsonDecode(s);
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> _writeEntriesRaw(List<Map<String, dynamic>> entries) async {
    final prefs = await _prefs;
    final key = await _scopedKey(_kEntriesKey);
    await prefs.setString(key, jsonEncode(entries));
  }

  Future<List<WorkoutEntry>> loadEntries() async {
    final raw = await _readEntriesRaw();
    return raw.map((m) => WorkoutEntry.fromMap(m)).toList();
  }

  // Goal tracking
  Future<List<Goal>> loadGoals() async {
    final prefs = await _prefs;
    final key = await _scopedKey(_kGoalsKey);
    final s = prefs.getString(key);
    if (s == null || s.isEmpty) return [];
    final List<dynamic> list = jsonDecode(s);
    return list
        .cast<Map<String, dynamic>>()
        .map((m) => Goal.fromMap(m))
        .toList();
  }

  Future<void> saveGoal(Goal goal) async {
    final prefs = await _prefs;
    final goals = await loadGoals();
    goals.removeWhere((g) => g.id == goal.id);
    goals.add(goal);
    final key = await _scopedKey(_kGoalsKey);
    await prefs.setString(
      key,
      jsonEncode(goals.map((g) => g.toMap()).toList()),
    );
  }

  Future<void> deleteGoal(String id) async {
    final prefs = await _prefs;
    final goals = await loadGoals();
    goals.removeWhere((g) => g.id == id);
    final goalsKey = await _scopedKey(_kGoalsKey);
    await prefs.setString(
      goalsKey,
      jsonEncode(goals.map((g) => g.toMap()).toList()),
    );
    final activeKey = await _scopedKey(_kActiveGoalIdKey);
    final active = prefs.getString(activeKey);
    if (active == id) {
      await prefs.remove(activeKey);
    }
  }

  Future<void> setActiveGoal(String goalId) async {
    final prefs = await _prefs;
    final key = await _scopedKey(_kActiveGoalIdKey);
    await prefs.setString(key, goalId);
  }

  Future<Goal?> getActiveGoal() async {
    final prefs = await _prefs;
    final key = await _scopedKey(_kActiveGoalIdKey);
    final id = prefs.getString(key);
    if (id == null || id.isEmpty) return null;
    final goals = await loadGoals();
    try {
      return goals.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<CoachSuggestion>> getGoalBasedSuggestions(Goal goal) async {
    final now = DateTime.now();
    final suggestions = <CoachSuggestion>[];

    if (goal.type == GoalType.strengthTarget) {
      final name = goal.exerciseName ?? 'Bench Press';
      final target = goal.targetWeightKg ?? 100;
      final records = await loadExerciseRecords();
      final relevant =
          records
              .where(
                (r) =>
                    r.exerciseName.toLowerCase().contains(name.toLowerCase()) ||
                    name.toLowerCase().contains(r.exerciseName.toLowerCase()),
              )
              .toList()
            ..sort((a, b) => b.dateRecorded.compareTo(a.dateRecorded));

      double currentBest = 0;
      ExerciseRecord? latest;
      for (final r in relevant) {
        latest ??= r;
        final w = r.effectiveWeightKg;
        if (w > currentBest) currentBest = w;
      }

      final remaining = (target - currentBest).clamp(0, target);
      suggestions.add(
        CoachSuggestion(
          id: 'goal_${goal.id}_progress',
          exerciseName: name,
          bodyPart: 'Chest',
          type: SuggestionType.technique,
          suggestion:
              '🎯 Target: ${target.toStringAsFixed(0)} kg (current best: ${currentBest.toStringAsFixed(0)} kg)',
          rationale: remaining > 0
              ? 'You are ${remaining.toStringAsFixed(0)} kg away. Keep progressive overload steady.'
              : 'Goal achieved. Maintain with consistent technique and volume.',
          priority: 1.0,
          suggestedDate: now,
          currentValue: '${currentBest.toStringAsFixed(0)} kg',
          recommendedValue: '${target.toStringAsFixed(0)} kg',
        ),
      );

      if (latest != null) {
        final easy = latest.difficulty.toLowerCase() == 'easy';
        final nextWeight = easy ? latest.weight + 2.5 : latest.weight;
        final nextReps = easy ? latest.repsPerSet + 1 : latest.repsPerSet + 2;
        suggestions.add(
          CoachSuggestion(
            id: 'goal_${goal.id}_next',
            exerciseName: latest.exerciseName,
            bodyPart: latest.bodyPart,
            type: easy
                ? SuggestionType.increaseWeight
                : SuggestionType.increaseReps,
            suggestion: easy
                ? '⬆️ Next session: try ${nextWeight.toStringAsFixed(1)} kg'
                : '📈 Next session: aim for ${nextReps} reps (same weight)',
            rationale: easy
                ? 'Your last session felt Easy. A small jump keeps progress moving.'
                : 'If the last session felt Moderate/Hard, add reps first, then add load.',
            priority: 0.85,
            suggestedDate: now,
            currentValue: '${latest.weight.toStringAsFixed(1)} kg',
            recommendedValue: easy
                ? '${nextWeight.toStringAsFixed(1)} kg'
                : '${nextReps} reps',
          ),
        );
      } else {
        suggestions.add(
          CoachSuggestion(
            id: 'goal_${goal.id}_log',
            exerciseName: name,
            bodyPart: 'Chest',
            type: SuggestionType.technique,
            suggestion: '📝 Log your bench sessions to track progress',
            rationale:
                'Goal suggestions improve as you log sets/reps/weight for bench movements.',
            priority: 0.7,
            suggestedDate: now,
          ),
        );
      }

      // Accessory support
      suggestions.add(
        CoachSuggestion(
          id: 'goal_${goal.id}_accessory',
          exerciseName: 'Accessory Work',
          bodyPart: 'Chest',
          type: SuggestionType.accessoryExercise,
          suggestion: '💪 Add 2-3 chest/triceps accessories after bench',
          rationale:
              'Accessories build volume to support a stronger bench press goal.',
          priority: 0.65,
          suggestedDate: now,
        ),
      );
    }

    if (goal.type == GoalType.growMuscle) {
      final group = goal.focusMuscleGroup ?? 'Legs';
      final summary = await getBodyLoadSummary();
      final muscleVol = summary.volumeByMuscle[group] ?? 0;
      suggestions.add(
        CoachSuggestion(
          id: 'goal_${goal.id}_volume',
          exerciseName: '$group Volume',
          bodyPart: group,
          type: SuggestionType.increaseSets,
          suggestion:
              '➕ Build $group volume (current: ${muscleVol.toStringAsFixed(0)} kg total load)',
          rationale:
              'Growing $group is driven by consistent weekly volume and progressive overload.',
          priority: 0.9,
          suggestedDate: now,
        ),
      );

      final accessories = await getAccessorySuggestions();
      final groupAccessories = accessories
          .where((a) => a.muscleGroup.toLowerCase() == group.toLowerCase())
          .toList();
      for (final a in groupAccessories.take(2)) {
        suggestions.add(
          CoachSuggestion(
            id: 'goal_${goal.id}_acc_${a.suggestedExercise}',
            exerciseName: a.suggestedExercise,
            bodyPart: group,
            type: SuggestionType.accessoryExercise,
            suggestion:
                '💪 ${a.suggestedExercise}: ${a.recommendedSets} x ${a.recommendedReps}',
            rationale: a.reason,
            priority: 0.75,
            suggestedDate: now,
          ),
        );
      }
    }

    if (goal.type == GoalType.fixWeakness) {
      final group = goal.focusMuscleGroup ?? 'Shoulders';
      final freq = await getMuscleGroupFrequency();
      final match = freq
          .where((f) => f.muscleGroup.toLowerCase() == group.toLowerCase())
          .toList();
      final weeklyCount = match.isNotEmpty
          ? match.first.workoutCountLastWeek
          : 0;
      suggestions.add(
        CoachSuggestion(
          id: 'goal_${goal.id}_freq',
          exerciseName: '$group Frequency',
          bodyPart: group,
          type: SuggestionType.technique,
          suggestion:
              '🎯 Train $group 2x/week (this week: $weeklyCount sessions)',
          rationale:
              'Weak areas improve fastest with higher frequency and good technique.',
          priority: 0.95,
          suggestedDate: now,
        ),
      );

      final accessories = await getAccessorySuggestions();
      final groupAccessories = accessories
          .where((a) => a.muscleGroup.toLowerCase() == group.toLowerCase())
          .toList();
      for (final a in groupAccessories.take(2)) {
        suggestions.add(
          CoachSuggestion(
            id: 'goal_${goal.id}_weak_${a.suggestedExercise}',
            exerciseName: a.suggestedExercise,
            bodyPart: group,
            type: SuggestionType.accessoryExercise,
            suggestion:
                '💪 ${a.suggestedExercise}: ${a.recommendedSets} x ${a.recommendedReps}',
            rationale: a.reason,
            priority: 0.8,
            suggestedDate: now,
          ),
        );
      }
    }

    return suggestions..sort((a, b) => b.priority.compareTo(a.priority));
  }

  Future<void> saveEntry(WorkoutEntry entry) async {
    final entries = await loadEntries();
    entries.removeWhere((e) => e.id == entry.id);
    entries.add(entry);
    await _writeEntriesRaw(entries.map((e) => e.toMap()).toList());
  }

  Future<void> deleteEntry(String id) async {
    final entries = await loadEntries();
    entries.removeWhere((e) => e.id == id);
    await _writeEntriesRaw(entries.map((e) => e.toMap()).toList());
  }

  /// Returns number of workouts in the last 7 days (including today)
  Future<int> workoutsThisWeek() async {
    final entries = await loadEntries();
    if (entries.isEmpty) {
      // Fallback: derive workout days from exercise logs.
      final records = await loadExerciseRecords();
      final now = DateTime.now();
      final weekAgo = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 6));
      final days = records
          .map((r) => DateTime(r.dateRecorded.year, r.dateRecorded.month, r.dateRecorded.day))
          .toSet();
      return days.where((d) => !d.isBefore(weekAgo)).length;
    }
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 6));
    final count = entries
        .where((e) => e.date.isAfter(weekAgo) || _isSameDay(e.date, weekAgo))
        .length;
    return count;
  }

  /// Returns current streak (consecutive days with at least one entry)
  Future<int> currentStreak() async {
    final entries = await loadEntries();
    if (entries.isEmpty) {
      // Fallback: derive streak from exercise logs.
      final records = await loadExerciseRecords();
      if (records.isEmpty) return 0;
      final dates = records
          .map((r) => DateTime(r.dateRecorded.year, r.dateRecorded.month, r.dateRecorded.day))
          .toSet()
          .toList()
        ..sort((a, b) => b.compareTo(a));

      int streak = 0;
      DateTime cursor = DateTime.now();
      while (true) {
        final day = DateTime(cursor.year, cursor.month, cursor.day);
        final found = dates.any(
          (d) => d.year == day.year && d.month == day.month && d.day == day.day,
        );
        if (found) {
          streak++;
          cursor = cursor.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }
      return streak;
    }
    final dates =
        entries
            .map((e) => DateTime(e.date.year, e.date.month, e.date.day))
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));

    int streak = 0;
    DateTime cursor = DateTime.now();
    while (true) {
      final day = DateTime(cursor.year, cursor.month, cursor.day);
      final found = dates.any(
        (d) => d.year == day.year && d.month == day.month && d.day == day.day,
      );
      if (found) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Persist a short analysis note for the given date (uses ISO yyyy-MM-dd keying).
  Future<void> saveAnalysisNoteForDate(DateTime date, String note) async {
    final prefs = await _prefs;
    final key = _analysisKey;
    final raw = prefs.getString(key);
    final Map<String, dynamic> map = raw == null || raw.isEmpty
        ? {}
        : Map<String, dynamic>.from(jsonDecode(raw));
    map[_dateKey(date)] = note;
    await prefs.setString(key, jsonEncode(map));
  }

  /// Load the saved analysis note for a given date, or null if none.
  Future<String?> loadAnalysisNoteForDate(DateTime date) async {
    final prefs = await _prefs;
    final key = _analysisKey;
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    final Map<String, dynamic> map = Map<String, dynamic>.from(jsonDecode(raw));
    return map[_dateKey(date)] as String?;
  }

  String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static const _analysisKey = 'daily_analysis_notes_v1';

  // Generic settings helpers
  static const _kSettingsPrefix = 'app_setting_';

  Future<void> saveStringSetting(String key, String value) async {
    final prefs = await _prefs;
    await prefs.setString('$_kSettingsPrefix$key', value);
  }

  Future<String?> loadStringSetting(String key) async {
    final prefs = await _prefs;
    return prefs.getString('$_kSettingsPrefix$key');
  }

  Future<void> saveBoolSetting(String key, bool value) async {
    final prefs = await _prefs;
    await prefs.setBool('$_kSettingsPrefix$key', value);
  }

  Future<bool?> loadBoolSetting(String key) async {
    final prefs = await _prefs;
    return prefs.getBool('$_kSettingsPrefix$key');
  }

  // Secure storage helpers (for API keys and secrets). Keys are namespaced with
  // 'secure_' prefix when written to the secure storage provider.

  Future<void> saveSecureString(String key, String value) async {
    await _secure.write(key: 'secure_$key', value: value);
  }

  Future<String?> loadSecureString(String key) async {
    return await _secure.read(key: 'secure_$key');
  }

  Future<void> deleteSecureString(String key) async {
    await _secure.delete(key: 'secure_$key');
  }

  Future<bool> hasSecureString(String key) async {
    final v = await loadSecureString(key);
    return v != null && v.isNotEmpty;
  }

  // Exercise tracking methods
  // Cache to avoid repeatedly loading/parsing records.
  List<ExerciseRecord>? _exerciseRecordsCache;

  Future<List<ExerciseRecord>> loadExerciseRecords() async {
    final prefs = await _prefs;
    final cached = _exerciseRecordsCache;
    if (cached != null) return List<ExerciseRecord>.from(cached);

    final decoded = await loadExerciseRecordsV2(prefs);
    _exerciseRecordsCache = decoded;
    return List<ExerciseRecord>.from(decoded);
  }

  Future<void> saveExerciseRecord(ExerciseRecord record) async {
    final prefs = await _prefs;
    final records = await loadExerciseRecords();
    records.removeWhere((e) => e.id == record.id);
    records.add(record);

    await writeExerciseRecordsV2(prefs, records);
    _exerciseRecordsCache = List<ExerciseRecord>.from(records);
  }

  Future<void> deleteExerciseRecord(String id) async {
    final prefs = await _prefs;
    final records = await loadExerciseRecords();
    records.removeWhere((e) => e.id == id);

    await writeExerciseRecordsV2(prefs, records);
    _exerciseRecordsCache = List<ExerciseRecord>.from(records);
  }

  Future<List<ExerciseRecord>> getExerciseRecordsByBodyPart(
    String bodyPart,
  ) async {
    final records = await loadExerciseRecords();
    return records.where((r) => r.bodyPart == bodyPart).toList()
      ..sort((a, b) => b.dateRecorded.compareTo(a.dateRecorded));
  }

  Future<List<ExerciseRecord>> getExerciseRecordsByDate(DateTime date) async {
    final records = await loadExerciseRecords();
    return records.where((r) {
      final same =
          r.dateRecorded.year == date.year &&
          r.dateRecorded.month == date.month &&
          r.dateRecorded.day == date.day;
      return same;
    }).toList()..sort((a, b) => b.dateRecorded.compareTo(a.dateRecorded));
  }

  // Progressive Overload Tracking
  Future<List<ProgressiveOverloadMetrics>>
  getProgressiveOverloadMetrics() async {
    final records = await loadExerciseRecords();
    if (records.isEmpty) return [];

    final metrics = <ProgressiveOverloadMetrics>[];
    final groupedByExercise = <String, List<ExerciseRecord>>{};

    // Group records by exercise name
    for (final record in records) {
      groupedByExercise.putIfAbsent(record.exerciseName, () => []);
      groupedByExercise[record.exerciseName]!.add(record);
    }

    // For each exercise, find the latest and previous records to calculate improvements
    for (final exerciseName in groupedByExercise.keys) {
      final exerciseRecords = groupedByExercise[exerciseName]!
        ..sort((a, b) => b.dateRecorded.compareTo(a.dateRecorded));

      if (exerciseRecords.length >= 2) {
        final latest = exerciseRecords[0];
        final previous = exerciseRecords[1];

        final latestVolume = latest.progressScore.toInt();
        final previousVolume = previous.progressScore.toInt();

        metrics.add(
          ProgressiveOverloadMetrics(
            exerciseName: exerciseName,
            bodyPart: latest.bodyPart,
            previousWeight: previous.effectiveWeightKg,
            currentWeight: latest.effectiveWeightKg,
            previousReps: previous.repsPerSet,
            currentReps: latest.repsPerSet,
            previousSets: previous.sets,
            currentSets: latest.sets,
            previousVolume: previousVolume,
            currentVolume: latestVolume,
            lastPerformedDate: latest.dateRecorded,
            previousPerformedDate: previous.dateRecorded,
          ),
        );
      }
    }

    return metrics;
  }

  Future<List<MuscleGroupFrequency>> getMuscleGroupFrequency() async {
    final records = await loadExerciseRecords();
    if (records.isEmpty) return [];

    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final monthAgo = now.subtract(const Duration(days: 30));

    final groupedByMuscle = <String, List<ExerciseRecord>>{};

    // Group records by body part
    for (final record in records) {
      groupedByMuscle.putIfAbsent(record.bodyPart, () => []);
      groupedByMuscle[record.bodyPart]!.add(record);
    }

    final frequency = <MuscleGroupFrequency>[];

    for (final muscle in groupedByMuscle.keys) {
      final muscleRecords = groupedByMuscle[muscle]!;
      final weekCount = muscleRecords
          .where((r) => r.dateRecorded.isAfter(weekAgo))
          .length;
      final monthCount = muscleRecords
          .where((r) => r.dateRecorded.isAfter(monthAgo))
          .length;
      final lastWorkout = muscleRecords.reduce(
        (a, b) => a.dateRecorded.isAfter(b.dateRecorded) ? a : b,
      );

      frequency.add(
        MuscleGroupFrequency(
          muscleGroup: muscle,
          workoutCountLastWeek: weekCount,
          workoutCountLastMonth: monthCount,
          averageFrequencyPerWeek: monthCount > 0 ? (monthCount / 4.3) : 0,
          lastWorkoutDate: lastWorkout.dateRecorded,
        ),
      );
    }

    return frequency..sort(
      (a, b) => b.workoutCountLastWeek.compareTo(a.workoutCountLastWeek),
    );
  }

  // Muscle Balance Analysis
  Future<List<MuscleBalanceAnalysis>> getMuscleBalanceAnalysis() async {
    final records = await loadExerciseRecords();
    if (records.isEmpty) return [];

    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    final muscleData = <String, List<ExerciseRecord>>{};

    // Group records by muscle and filter to this week
    for (final record in records) {
      if (record.dateRecorded.isAfter(weekAgo)) {
        muscleData.putIfAbsent(record.bodyPart, () => []);
        muscleData[record.bodyPart]!.add(record);
      }
    }

    // Recommended frequencies based on training science
    const recommendedFrequencies = {
      'Chest': 2,
      'Back': 2,
      'Legs': 2,
      'Shoulders': 2,
      'Arms': 2,
      'Core': 3,
      'Glutes': 2,
      'Abs': 3,
    };

    final analysis = <MuscleBalanceAnalysis>[];
    final totalVolume = muscleData.entries.fold<double>(0, (sum, entry) {
      final volume = entry.value.fold<double>(
        0,
        (s, r) => s + r.volumeLoadKg,
      );
      return sum + volume;
    });

    for (final muscle in muscleData.keys) {
      final records = muscleData[muscle]!;
      final frequency = records.length;
      final volume = records.fold<double>(
        0,
        (s, r) => s + r.volumeLoadKg,
      );
      final recommendedFreq = recommendedFrequencies[muscle] ?? 2;
      final avgVolume = frequency > 0 ? volume / frequency : 0;

      String? warning;
      bool isUnderTrained = false;
      bool hasImbalance = false;

      // Check if under-trained
      if (frequency < recommendedFreq) {
        isUnderTrained = true;
        warning =
            '⚠️ $muscle trained $frequency× this week. Recommended: $recommendedFreq–${recommendedFreq + 1}×';
      }

      analysis.add(
        MuscleBalanceAnalysis(
          muscleGroup: muscle,
          weeklyFrequency: frequency,
          volumeThisWeek: volume,
          averageVolumePerSession: avgVolume.toDouble(),
          warning: warning,
          isUnderTrained: isUnderTrained,
          hasImbalance: false, // Will be calculated in balance check
        ),
      );
    }

    return analysis
      ..sort((a, b) => b.weeklyFrequency.compareTo(a.weeklyFrequency));
  }

  Future<List<MuscleTrainingRecommendation>>
  getMuscleTrainingRecommendations() async {
    final analysis = await getMuscleBalanceAnalysis();
    const recommendedFrequencies = {
      'Chest': 2,
      'Back': 2,
      'Legs': 2,
      'Shoulders': 2,
      'Arms': 2,
      'Core': 3,
      'Glutes': 2,
      'Abs': 3,
    };

    final recommendations = <MuscleTrainingRecommendation>[];
    final totalVolume = analysis.fold<double>(
      0,
      (sum, a) => sum + a.volumeThisWeek,
    );
    final avgVolumePerMuscle =
        totalVolume / (analysis.length > 0 ? analysis.length : 1);

    for (final muscle in analysis) {
      final recommendedFreq = recommendedFrequencies[muscle.muscleGroup] ?? 2;
      final volumeDiff = muscle.volumeThisWeek - (avgVolumePerMuscle);
      final volumeBalance = avgVolumePerMuscle > 0
          ? muscle.volumeThisWeek / avgVolumePerMuscle
          : 1.0;

      String recommendation;
      if (muscle.weeklyFrequency < recommendedFreq) {
        recommendation =
            'Add ${recommendedFreq - muscle.weeklyFrequency} more session(s) for ${muscle.muscleGroup}';
      } else if (muscle.weeklyFrequency > recommendedFreq + 1) {
        recommendation =
            '${muscle.muscleGroup} is being trained frequently; consider deload week';
      } else {
        recommendation = '${muscle.muscleGroup} training frequency is optimal';
      }

      recommendations.add(
        MuscleTrainingRecommendation(
          muscleGroup: muscle.muscleGroup,
          currentFrequency: muscle.weeklyFrequency,
          recommendedFrequency: recommendedFreq,
          volumeDifference: volumeDiff,
          recommendation: recommendation,
          volumeBalance: volumeBalance,
        ),
      );
    }

    return recommendations
      ..sort((a, b) => a.currentFrequency.compareTo(b.currentFrequency));
  }

  Future<List<MuscleImbalanceWarning>> getMuscleImbalanceWarnings() async {
    final analysis = await getMuscleBalanceAnalysis();
    if (analysis.length < 2) return [];

    final warnings = <MuscleImbalanceWarning>[];

    // Define muscle pairs to check for balance
    const balancePairs = [
      ('Chest', 'Back'),
      ('Shoulders', 'Back'),
      ('Legs', 'Back'),
      ('Core', 'Glutes'),
    ];

    for (final pair in balancePairs) {
      final primary = analysis.firstWhere(
        (m) => m.muscleGroup == pair.$1,
        orElse: () => MuscleBalanceAnalysis(
          muscleGroup: pair.$1,
          weeklyFrequency: 0,
          volumeThisWeek: 0,
          averageVolumePerSession: 0,
          isUnderTrained: false,
          hasImbalance: false,
        ),
      );

      final secondary = analysis.firstWhere(
        (m) => m.muscleGroup == pair.$2,
        orElse: () => MuscleBalanceAnalysis(
          muscleGroup: pair.$2,
          weeklyFrequency: 0,
          volumeThisWeek: 0,
          averageVolumePerSession: 0,
          isUnderTrained: false,
          hasImbalance: false,
        ),
      );

      final ratio = secondary.volumeThisWeek > 0
          ? primary.volumeThisWeek / secondary.volumeThisWeek
          : 0;

      if (secondary.volumeThisWeek > 0 && ratio > 1.3) {
        final isCritical = ratio > 1.5;
        warnings.add(
          MuscleImbalanceWarning(
            primaryMuscle: pair.$1,
            secondaryMuscle: pair.$2,
            volumeRatio: ratio.toDouble(),
            warning:
                '⚠️ ${pair.$1} volume is ${(ratio * 100 - 100).toStringAsFixed(0)}% higher than ${pair.$2} → imbalance risk',
            suggestion:
                'Increase ${pair.$2} training volume or decrease ${pair.$1}',
            isCritical: isCritical,
          ),
        );
      }
    }

    return warnings;
  }

  // Volume & Load Calculations
  Future<List<VolumeLoadData>> getVolumeLoadData() async {
    final records = await loadExerciseRecords();
    if (records.isEmpty) return [];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last7Start = now.subtract(const Duration(days: 6));
    final last14Start = now.subtract(const Duration(days: 13));
    final last30Start = now.subtract(const Duration(days: 29));
    final last60Start = now.subtract(const Duration(days: 59));

    final grouped = <String, List<ExerciseRecord>>{};
    for (final r in records)
      grouped.putIfAbsent(r.exerciseName, () => []).add(r);

    final result = <VolumeLoadData>[];

    for (final name in grouped.keys) {
      final list = grouped[name]!;

      // Today volume
      final todayVol = list
          .where(
            (r) =>
                DateTime(
                  r.dateRecorded.year,
                  r.dateRecorded.month,
                  r.dateRecorded.day,
                ) ==
                today,
          )
          .fold<double>(0, (s, r) => s + r.volumeLoadKg);

      // Last session: find most recent date before today
      final previousDates = list
          .map(
            (r) => DateTime(
              r.dateRecorded.year,
              r.dateRecorded.month,
              r.dateRecorded.day,
            ),
          )
          .toSet()
          .where((d) => d.isBefore(today))
          .toList();
      previousDates.sort((a, b) => b.compareTo(a));
      double lastSessionVol = 0;
      if (previousDates.isNotEmpty) {
        final lastDate = previousDates.first;
        lastSessionVol = list
            .where(
              (r) =>
                  DateTime(
                    r.dateRecorded.year,
                    r.dateRecorded.month,
                    r.dateRecorded.day,
                  ) ==
                  lastDate,
            )
            .fold<double>(0, (s, r) => s + r.volumeLoadKg);
      }

      // Week vs last week (7 day windows)
      final weekVol = list
          .where((r) => r.dateRecorded.isAfter(last7Start))
          .fold<double>(0, (s, r) => s + r.volumeLoadKg);
      final lastWeekVol = list
          .where(
            (r) =>
                r.dateRecorded.isAfter(last14Start) &&
                r.dateRecorded.isBefore(last7Start),
          )
          .fold<double>(0, (s, r) => s + r.volumeLoadKg);

      // Month vs last month (30 day windows)
      final monthVol = list
          .where((r) => r.dateRecorded.isAfter(last30Start))
          .fold<double>(0, (s, r) => s + r.volumeLoadKg);
      final lastMonthVol = list
          .where(
            (r) =>
                r.dateRecorded.isAfter(last60Start) &&
                r.dateRecorded.isBefore(last30Start),
          )
          .fold<double>(0, (s, r) => s + r.volumeLoadKg);

      result.add(
        VolumeLoadData(
          exerciseName: name,
          bodyPart: list.first.bodyPart,
          todayVolume: todayVol,
          lastSessionVolume: lastSessionVol,
          weekVolume: weekVol,
          lastWeekVolume: lastWeekVol,
          monthVolume: monthVol,
          lastMonthVolume: lastMonthVol,
        ),
      );
    }

    return result..sort((a, b) => b.weekVolume.compareTo(a.weekVolume));
  }

  Future<BodyLoadSummary> getBodyLoadSummary() async {
    final records = await loadExerciseRecords();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterdayStart = today.subtract(const Duration(days: 1));
    final weekStart = now.subtract(const Duration(days: 6));
    final lastWeekStart = now.subtract(const Duration(days: 13));
    final monthStart = now.subtract(const Duration(days: 29));
    final lastMonthStart = now.subtract(const Duration(days: 59));

    double totalToday = 0,
        totalYesterday = 0,
        totalWeek = 0,
        totalLastWeek = 0,
        totalMonth = 0,
        totalLastMonth = 0;
    final volByMuscle = <String, double>{};

    for (final r in records) {
      final vol = r.volumeLoadKg;
      final d = DateTime(
        r.dateRecorded.year,
        r.dateRecorded.month,
        r.dateRecorded.day,
      );
      if (d == today) totalToday += vol;
      if (d == yesterdayStart) totalYesterday += vol;
      if (r.dateRecorded.isAfter(weekStart)) totalWeek += vol;
      if (r.dateRecorded.isAfter(lastWeekStart) &&
          r.dateRecorded.isBefore(weekStart))
        totalLastWeek += vol;
      if (r.dateRecorded.isAfter(monthStart)) totalMonth += vol;
      if (r.dateRecorded.isAfter(lastMonthStart) &&
          r.dateRecorded.isBefore(monthStart))
        totalLastMonth += vol;

      volByMuscle.update(r.bodyPart, (v) => v + vol, ifAbsent: () => vol);
    }

    return BodyLoadSummary(
      totalTodayVolume: totalToday,
      totalYesterdayVolume: totalYesterday,
      totalWeekVolume: totalWeek,
      totalLastWeekVolume: totalLastWeek,
      totalMonthVolume: totalMonth,
      totalLastMonthVolume: totalLastMonth,
      volumeByMuscle: volByMuscle,
    );
  }

  // Smart Coach Suggestions
  Future<List<CoachSuggestion>> getCoachSuggestions() async {
    final records = await loadExerciseRecords();
    if (records.isEmpty) return [];

    final suggestions = <CoachSuggestion>[];
    final groupedByExercise = <String, List<ExerciseRecord>>{};

    // Group records by exercise name
    for (final record in records) {
      groupedByExercise.putIfAbsent(record.exerciseName, () => []);
      groupedByExercise[record.exerciseName]!.add(record);
    }

    // Analyze each exercise for suggestions
    for (final exerciseName in groupedByExercise.keys) {
      final exerciseRecords = groupedByExercise[exerciseName]!
        ..sort((a, b) => b.dateRecorded.compareTo(a.dateRecorded));

      if (exerciseRecords.isEmpty) continue;

      final latest = exerciseRecords[0];
      final previousRecords = exerciseRecords.length > 1
          ? exerciseRecords.sublist(1)
          : [];

      // Check for weight increase opportunity
      if (previousRecords.isNotEmpty) {
        final previous = previousRecords[0];

        // If completed all reps at same weight consistently, suggest weight increase
        if (latest.weight == previous.weight &&
            latest.repsPerSet == latest.sets) {
          final completionRate =
              previousRecords
                  .take(3)
                  .where((r) => r.repsPerSet >= latest.repsPerSet)
                  .length /
              (previousRecords.length > 3 ? 3 : previousRecords.length)
                  .toDouble();

          if (completionRate >= 0.66) {
            final suggestedWeight = (latest.weight + 2.5);
            suggestions.add(
              CoachSuggestion(
                id: '${exerciseName}_weight_${DateTime.now().millisecondsSinceEpoch}',
                exerciseName: exerciseName,
                bodyPart: latest.bodyPart,
                type: SuggestionType.increaseWeight,
                suggestion:
                    '⬆️ Increase weight to ${suggestedWeight.toStringAsFixed(1)} kg',
                rationale:
                    'You\'ve been consistently hitting ${latest.repsPerSet} reps. Time to challenge yourself with more weight!',
                priority: 0.9,
                suggestedDate: DateTime.now(),
                currentValue: '${latest.weight} kg',
                recommendedValue: '${suggestedWeight.toStringAsFixed(1)} kg',
              ),
            );
          }
        }
      }

      // Check for rep increase opportunity
      if (latest.difficulty.toLowerCase() == 'easy' &&
          previousRecords.isNotEmpty) {
        final suggestedReps = latest.repsPerSet + 2;
        suggestions.add(
          CoachSuggestion(
            id: '${exerciseName}_reps_${DateTime.now().millisecondsSinceEpoch}',
            exerciseName: exerciseName,
            bodyPart: latest.bodyPart,
            type: SuggestionType.increaseReps,
            suggestion: '📈 Increase reps to ${suggestedReps}',
            rationale:
                'You rated this as Easy. Push for ${suggestedReps} reps to increase volume and strength endurance.',
            priority: 0.7,
            suggestedDate: DateTime.now(),
            currentValue: '${latest.repsPerSet} reps',
            recommendedValue: '${suggestedReps} reps',
          ),
        );
      }

      // Check for set increase opportunity
      if (latest.difficulty.toLowerCase() == 'easy' &&
          latest.weight ==
              (previousRecords.isNotEmpty ? previousRecords[0].weight : 0)) {
        final suggestedSets = latest.sets + 1;
        suggestions.add(
          CoachSuggestion(
            id: '${exerciseName}_sets_${DateTime.now().millisecondsSinceEpoch}',
            exerciseName: exerciseName,
            bodyPart: latest.bodyPart,
            type: SuggestionType.increaseSets,
            suggestion: '➕ Add 1 extra set (${latest.sets} → ${suggestedSets})',
            rationale:
                'This exercise feels easy. Adding a set will increase total volume for better gains.',
            priority: 0.6,
            suggestedDate: DateTime.now(),
            currentValue: '${latest.sets} sets',
            recommendedValue: '${suggestedSets} sets',
          ),
        );
      }
    }

    return suggestions..sort((a, b) => b.priority.compareTo(a.priority));
  }

  Future<List<AccessorySuggestion>> getAccessorySuggestions() async {
    final analysis = await getMuscleBalanceAnalysis();
    final suggestions = <AccessorySuggestion>[];

    // Accessory exercise recommendations map
    final accessoryMap = {
      'Chest': [
        AccessorySuggestion(
          muscleGroup: 'Chest',
          suggestedExercise: 'Cable Flyes',
          benefit: 'Isolates chest, improves mind-muscle connection',
          reason: 'Complement heavy compound movements',
          recommendedSets: 3,
          recommendedReps: '12-15',
        ),
        AccessorySuggestion(
          muscleGroup: 'Chest',
          suggestedExercise: 'Push-ups',
          benefit: 'Functional chest development, stabilizer activation',
          reason: 'Excellent finishing exercise',
          recommendedSets: 3,
          recommendedReps: 'max reps',
        ),
      ],
      'Back': [
        AccessorySuggestion(
          muscleGroup: 'Back',
          suggestedExercise: 'Face Pulls',
          benefit: 'Rear delt and upper back strength, postural correction',
          reason: 'Prevents shoulder impingement',
          recommendedSets: 3,
          recommendedReps: '12-15',
        ),
        AccessorySuggestion(
          muscleGroup: 'Back',
          suggestedExercise: 'Barbell Rows',
          benefit: 'Thickness and strength in mid-back',
          reason: 'Compound movement for overall back mass',
          recommendedSets: 4,
          recommendedReps: '6-10',
        ),
      ],
      'Shoulders': [
        AccessorySuggestion(
          muscleGroup: 'Shoulders',
          suggestedExercise: 'Cable Raises',
          benefit: 'Lateral deltoid isolation, shoulder width',
          reason: 'Complements pressing movements',
          recommendedSets: 3,
          recommendedReps: '12-15',
        ),
        AccessorySuggestion(
          muscleGroup: 'Shoulders',
          suggestedExercise: 'Shrugs',
          benefit: 'Trap development, upper back strength',
          reason: 'Simple but effective shoulder accessory',
          recommendedSets: 3,
          recommendedReps: '10-12',
        ),
      ],
      'Legs': [
        AccessorySuggestion(
          muscleGroup: 'Legs',
          suggestedExercise: 'Leg Extensions',
          benefit: 'Quad isolation, knee stability',
          reason: 'Finisher after heavy compounds',
          recommendedSets: 3,
          recommendedReps: '12-15',
        ),
        AccessorySuggestion(
          muscleGroup: 'Legs',
          suggestedExercise: 'Walking Lunges',
          benefit: 'Unilateral strength, stability',
          reason: 'Great accessory for lower body',
          recommendedSets: 3,
          recommendedReps: '10 per leg',
        ),
      ],
      'Arms': [
        AccessorySuggestion(
          muscleGroup: 'Arms',
          suggestedExercise: 'Dumbbell Curls',
          benefit: 'Bicep isolation and control',
          reason: 'Classic accessory for arm development',
          recommendedSets: 3,
          recommendedReps: '8-12',
        ),
        AccessorySuggestion(
          muscleGroup: 'Arms',
          suggestedExercise: 'Rope Extensions',
          benefit: 'Tricep isolation, long head activation',
          reason: 'Pairs well with pressing movements',
          recommendedSets: 3,
          recommendedReps: '10-12',
        ),
      ],
      'Core': [
        AccessorySuggestion(
          muscleGroup: 'Core',
          suggestedExercise: 'Ab Wheel Rollout',
          benefit: 'Deep core strength, anti-extension',
          reason: 'Advanced core stability exercise',
          recommendedSets: 3,
          recommendedReps: '8-12',
        ),
        AccessorySuggestion(
          muscleGroup: 'Core',
          suggestedExercise: 'Pallof Press',
          benefit: 'Anti-rotation strength, stability',
          reason: 'Functional core strength',
          recommendedSets: 3,
          recommendedReps: '10 per side',
        ),
      ],
      'Glutes': [
        AccessorySuggestion(
          muscleGroup: 'Glutes',
          suggestedExercise: 'Glute Kickbacks',
          benefit: 'Glute isolation and activation',
          reason: 'Excellent glute accessory',
          recommendedSets: 3,
          recommendedReps: '12-15',
        ),
        AccessorySuggestion(
          muscleGroup: 'Glutes',
          suggestedExercise: 'Cable Pull-throughs',
          benefit: 'Posterior chain and glute activation',
          reason: 'Functional glute development',
          recommendedSets: 3,
          recommendedReps: '10-12',
        ),
      ],
      'Abs': [
        AccessorySuggestion(
          muscleGroup: 'Abs',
          suggestedExercise: 'Hanging Knee Raises',
          benefit: 'Lower abs and core stability',
          reason: 'Dynamic ab development',
          recommendedSets: 3,
          recommendedReps: '8-12',
        ),
        AccessorySuggestion(
          muscleGroup: 'Abs',
          suggestedExercise: 'Weighted Crunches',
          benefit: 'Progressive abs training',
          reason: 'Adds resistance for better gains',
          recommendedSets: 3,
          recommendedReps: '10-15',
        ),
      ],
    };

    // Add suggestions for under-trained muscles
    for (final muscle in analysis) {
      if (muscle.isUnderTrained &&
          accessoryMap.containsKey(muscle.muscleGroup)) {
        final accessorySuggestionList = accessoryMap[muscle.muscleGroup]!;
        if (accessorySuggestionList.isNotEmpty) {
          suggestions.add(accessorySuggestionList[0]);
        }
      }
    }

    return suggestions;
  }
}

class WorkoutEntry {
  final String id;
  final DateTime date;
  final String workoutType;
  final int durationMinutes;
  final String? notes;

  WorkoutEntry({
    required this.id,
    required this.date,
    required this.workoutType,
    required this.durationMinutes,
    this.notes,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'date': date.toIso8601String(),
    'workoutType': workoutType,
    'durationMinutes': durationMinutes,
    'notes': notes,
  };

  factory WorkoutEntry.fromMap(Map<String, dynamic> m) => WorkoutEntry(
    id: m['id'] as String,
    date: DateTime.parse(m['date'] as String),
    workoutType: m['workoutType'] as String,
    durationMinutes: (m['durationMinutes'] as num).toInt(),
    notes: m['notes'] as String?,
  );
}
