import 'package:flutter/material.dart';

import 'package:fitness_aura_athletix/core/models/exercise.dart';
import 'package:fitness_aura_athletix/services/storage_service.dart';

enum OverloadTrend { improved, maintained, regressed }
enum FatigueSignal { fresh, moderate, high }

class DailyWorkoutAnalysis {
  final DateTime date;
  final String workoutName;
  final String bodyPart;
  final int durationMinutes;
  final int exercisesCompleted;
  final double totalVolume;
  final int? caloriesBurned;

  final OverloadTrend overloadTrend;
  final double? volumeChangePercent;
  final List<String> overloadDetails;

  final Map<String, double> volumeByMuscleGroup;
  final List<String> undertrainedWarnings;

  final FatigueSignal fatigue;

  final List<String> prsAndMilestones;
  final int? consistencyStreakDays;

  final List<String> aiSuggestions;

  const DailyWorkoutAnalysis({
    required this.date,
    required this.workoutName,
    required this.bodyPart,
    required this.durationMinutes,
    required this.exercisesCompleted,
    required this.totalVolume,
    required this.caloriesBurned,
    required this.overloadTrend,
    required this.volumeChangePercent,
    required this.overloadDetails,
    required this.volumeByMuscleGroup,
    required this.undertrainedWarnings,
    required this.fatigue,
    required this.prsAndMilestones,
    required this.consistencyStreakDays,
    required this.aiSuggestions,
  });
}

class WorkoutSessionKey {
  final DateTime day;
  final String bodyPart;

  const WorkoutSessionKey({required this.day, required this.bodyPart});

  String get cacheKey => '${day.toIso8601String()}|$bodyPart';
}

class WorkoutAnalysisIndex {
  final List<ExerciseRecord> all;
  final Map<String, List<ExerciseRecord>> sessionsByKey;
  final Map<String, List<DateTime>> daysByBodyPart;
  final Map<String, Map<String, List<ExerciseRecord>>> byBodyPartByExercise;
  final Map<String, DateTime> lastByBodyPart;

  const WorkoutAnalysisIndex({
    required this.all,
    required this.sessionsByKey,
    required this.daysByBodyPart,
    required this.byBodyPartByExercise,
    required this.lastByBodyPart,
  });
}

class DailyWorkoutAnalysisEngine {
  static DateTime dayStart(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  static double volumeOf(ExerciseRecord r) => r.weight * r.sets * r.repsPerSet;

  /// Groups records into (day + bodyPart) sessions. MVP grouping: one session per
  /// day/bodyPart.
  static Map<String, List<ExerciseRecord>> groupSessions(
    List<ExerciseRecord> all,
  ) {
    final map = <String, List<ExerciseRecord>>{};
    for (final r in all) {
      final d = dayStart(r.dateRecorded);
      final key = '${d.toIso8601String()}|${r.bodyPart}';
      map.putIfAbsent(key, () => <ExerciseRecord>[]);
      map[key]!.add(r);
    }
    for (final k in map.keys) {
      map[k]!.sort((a, b) => a.dateRecorded.compareTo(b.dateRecorded));
    }
    return map;
  }

  static WorkoutAnalysisIndex buildIndex(List<ExerciseRecord> all) {
    final sessionsByKey = groupSessions(all);

    final daysByBodyPart = <String, Set<DateTime>>{};
    final lastByBodyPart = <String, DateTime>{};
    final byBodyPartByExercise = <String, Map<String, List<ExerciseRecord>>>{};

    for (final r in all) {
      final d = dayStart(r.dateRecorded);
      daysByBodyPart.putIfAbsent(r.bodyPart, () => <DateTime>{});
      daysByBodyPart[r.bodyPart]!.add(d);

      final last = lastByBodyPart[r.bodyPart];
      if (last == null || r.dateRecorded.isAfter(last)) {
        lastByBodyPart[r.bodyPart] = r.dateRecorded;
      }

      byBodyPartByExercise.putIfAbsent(r.bodyPart, () => <String, List<ExerciseRecord>>{});
      byBodyPartByExercise[r.bodyPart]!.putIfAbsent(r.exerciseName, () => <ExerciseRecord>[]);
      byBodyPartByExercise[r.bodyPart]![r.exerciseName]!.add(r);
    }

    // Normalize days ordering (newest first)
    final daysByBodyPartSorted = <String, List<DateTime>>{};
    for (final e in daysByBodyPart.entries) {
      final list = e.value.toList()..sort((a, b) => b.compareTo(a));
      daysByBodyPartSorted[e.key] = list;
    }

    // Normalize exercise lists ordering (newest first)
    for (final bp in byBodyPartByExercise.keys) {
      for (final ex in byBodyPartByExercise[bp]!.keys) {
        byBodyPartByExercise[bp]![ex]!
            .sort((a, b) => b.dateRecorded.compareTo(a.dateRecorded));
      }
    }

    return WorkoutAnalysisIndex(
      all: all,
      sessionsByKey: sessionsByKey,
      daysByBodyPart: daysByBodyPartSorted,
      byBodyPartByExercise: byBodyPartByExercise,
      lastByBodyPart: lastByBodyPart,
    );
  }

  static List<WorkoutSessionKey> sessionKeys(
    WorkoutAnalysisIndex index, {
    String? bodyPart,
  }) {
    final keys = <WorkoutSessionKey>[];
    if (bodyPart != null) {
      final days = index.daysByBodyPart[bodyPart] ?? const <DateTime>[];
      for (final d in days) {
        keys.add(WorkoutSessionKey(day: d, bodyPart: bodyPart));
      }
      return keys;
    }

    for (final e in index.daysByBodyPart.entries) {
      for (final d in e.value) {
        keys.add(WorkoutSessionKey(day: d, bodyPart: e.key));
      }
    }
    keys.sort((a, b) => b.day.compareTo(a.day));
    return keys;
  }

  static DailyWorkoutAnalysis? analyzeFromIndex(
    WorkoutAnalysisIndex index, {
    required DateTime day,
    required String bodyPart,
  }) {
    final targetDay = dayStart(day);
    final sessionKey = WorkoutSessionKey(day: targetDay, bodyPart: bodyPart);
    final session = (index.sessionsByKey[sessionKey.cacheKey] ?? const <ExerciseRecord>[])
        .toList()
      ..sort((a, b) => a.dateRecorded.compareTo(b.dateRecorded));
    if (session.isEmpty) return null;

    // Previous session day for this bodyPart
    final days = index.daysByBodyPart[bodyPart] ?? const <DateTime>[];
    final i = days.indexWhere((d) => d == targetDay);
    final prevDay = (i >= 0 && i + 1 < days.length) ? days[i + 1] : null;

    final prevKey = prevDay == null ? null : WorkoutSessionKey(day: prevDay, bodyPart: bodyPart);
    final prevSession = (prevKey == null
            ? const <ExerciseRecord>[]
            : (index.sessionsByKey[prevKey.cacheKey] ?? const <ExerciseRecord>[]))
        .toList()
      ..sort((a, b) => a.dateRecorded.compareTo(b.dateRecorded));

    return _analyzeSession(
      index: index,
      targetDay: targetDay,
      bodyPart: bodyPart,
      session: session,
      prevDay: prevDay,
      prevSession: prevSession,
    );
  }

  static DailyWorkoutAnalysis _analyzeSession({
    required WorkoutAnalysisIndex index,
    required DateTime targetDay,
    required String bodyPart,
    required List<ExerciseRecord> session,
    required DateTime? prevDay,
    required List<ExerciseRecord> prevSession,
  }) {
    final start = session.first.dateRecorded;
    final end = session.last.dateRecorded;
    final durationMinutes = end.isAfter(start) ? end.difference(start).inMinutes : 0;

    final uniqueExercises = session.map((e) => e.exerciseName).toSet();
    final totalVolume = session.fold<double>(0, (s, r) => s + volumeOf(r));
    final caloriesBurned = durationMinutes > 0 ? (durationMinutes * 6) : null;

    final prevTotalVolume = prevSession.fold<double>(0, (s, r) => s + volumeOf(r));
    final volumeChangePercent = prevTotalVolume > 0
        ? ((totalVolume - prevTotalVolume) / prevTotalVolume) * 100
        : null;

    final overloadDetails = <String>[];
    for (final ex in uniqueExercises) {
      final curr = session.where((r) => r.exerciseName == ex).toList()
        ..sort((a, b) => b.dateRecorded.compareTo(a.dateRecorded));
      final prev = prevSession.where((r) => r.exerciseName == ex).toList()
        ..sort((a, b) => b.dateRecorded.compareTo(a.dateRecorded));
      if (curr.isEmpty || prev.isEmpty) continue;
      final c = curr.first;
      final p = prev.first;

      if (c.weight > p.weight + 0.01) {
        overloadDetails.add('+${(c.weight - p.weight).toStringAsFixed(1)}kg on $ex');
      } else if (c.repsPerSet > p.repsPerSet) {
        overloadDetails.add('+${c.repsPerSet - p.repsPerSet} reps on $ex');
      } else if (volumeOf(c) > volumeOf(p) + 0.01) {
        overloadDetails.add('Volume up on $ex');
      }
    }

    final OverloadTrend trend;
    if (prevTotalVolume <= 0) {
      trend = OverloadTrend.improved;
    } else if (totalVolume >= prevTotalVolume * 1.03 || overloadDetails.isNotEmpty) {
      trend = OverloadTrend.improved;
    } else if (totalVolume <= prevTotalVolume * 0.97) {
      trend = OverloadTrend.regressed;
    } else {
      trend = OverloadTrend.maintained;
    }

    final volumeByMuscle = <String, double>{bodyPart: totalVolume};

    final now = DateTime.now();
    final undertrained = <String>[];
    for (final entry in index.lastByBodyPart.entries) {
      final daysAgo = now.difference(entry.value).inDays;
      if (daysAgo >= 5) {
        undertrained.add('${entry.key} hasn\'t been trained in $daysAgo days');
      }
    }

    int fatigueScore = 0;
    final latestDifficulty = session.last.difficulty.toLowerCase();
    if (latestDifficulty.contains('hard')) fatigueScore += 1;
    if ((volumeChangePercent ?? 0) > 20) fatigueScore += 1;

    final daysSincePrev = prevDay == null ? 99 : targetDay.difference(prevDay).inDays;
    if (daysSincePrev <= 1) fatigueScore += 1;

    final fatigue = switch (fatigueScore) {
      0 => FatigueSignal.fresh,
      1 => FatigueSignal.moderate,
      _ => FatigueSignal.high,
    };

    final prs = <String>[];
    for (final ex in uniqueExercises) {
      final currMaxWeight = session
          .where((r) => r.exerciseName == ex)
          .fold<double>(0, (m, r) => r.weight > m ? r.weight : m);

      // Use pre-indexed per-exercise list (newest first) to find historical max before today.
      final list = index.byBodyPartByExercise[bodyPart]?[ex] ?? const <ExerciseRecord>[];
      double prevMaxWeight = 0;
      for (final r in list) {
        if (dayStart(r.dateRecorded).isBefore(targetDay) && r.weight > prevMaxWeight) {
          prevMaxWeight = r.weight;
        }
      }

      if (currMaxWeight > prevMaxWeight + 0.01 && prevMaxWeight > 0) {
        prs.add('New PR: $ex ${currMaxWeight.toStringAsFixed(1)}kg');
      }
    }

    final suggestions = _buildSuggestionsIndexed(
      index: index,
      bodyPart: bodyPart,
      volumeChangePercent: volumeChangePercent,
      fatigue: fatigue,
      undertrained: undertrained,
    );

    return DailyWorkoutAnalysis(
      date: targetDay,
      workoutName: _workoutTitle(bodyPart),
      bodyPart: bodyPart,
      durationMinutes: durationMinutes,
      exercisesCompleted: uniqueExercises.length,
      totalVolume: totalVolume,
      caloriesBurned: caloriesBurned,
      overloadTrend: trend,
      volumeChangePercent: volumeChangePercent,
      overloadDetails: overloadDetails.take(3).toList(),
      volumeByMuscleGroup: volumeByMuscle,
      undertrainedWarnings: undertrained.take(2).toList(),
      fatigue: fatigue,
      prsAndMilestones: prs.take(3).toList(),
      consistencyStreakDays: null,
      aiSuggestions: suggestions.take(3).toList(),
    );
  }

  static List<String> _buildSuggestionsIndexed({
    required WorkoutAnalysisIndex index,
    required String bodyPart,
    required double? volumeChangePercent,
    required FatigueSignal fatigue,
    required List<String> undertrained,
  }) {
    final suggestions = <String>[];

    // Plateau detection using indexed per-exercise lists.
    final byExercise = index.byBodyPartByExercise[bodyPart] ?? const <String, List<ExerciseRecord>>{};
    for (final e in byExercise.entries) {
      final list = e.value;
      if (list.length < 3) continue;
      final a = list[0];
      final b = list[1];
      final c = list[2];
      final same = a.weight == b.weight &&
          a.repsPerSet == b.repsPerSet &&
          b.weight == c.weight &&
          b.repsPerSet == c.repsPerSet;
      if (same) {
        suggestions.add(
          'You\'ve hit the same reps for 2–3 sessions. Try +2.5kg next time (or +1 rep).',
        );
        break;
      }
    }

    final v = volumeChangePercent ?? 0;
    if (v >= 15) {
      suggestions.add(
        'Volume increased by ${v.toStringAsFixed(0)}% today. Keep it steady next session.',
      );
    }

    final complement = switch (bodyPart.toLowerCase()) {
      'legs' => 'Add hamstring isolation next leg day (e.g., RDL/leg curl).',
      'glutes' => 'Add a hamstring or quad accessory to balance the posterior chain.',
      'core' => 'Add anti-rotation work next time (e.g., Pallof press).',
      'abs' => 'Add lower-abs or oblique work next time (e.g., leg raises/wood chops).',
      'back' => 'Include a vertical pull (pull-ups/lat pulldown) if missing.',
      'chest' => 'Add an incline press if your upper chest is lagging.',
      'arms' => 'Balance biceps + triceps volume (1–2 movements each).',
      'shoulders' => 'Add rear-delt work for shoulder balance and posture.',
      _ => 'Keep exercise selection balanced and progressive.',
    };
    suggestions.add(complement);

    if (fatigue == FatigueSignal.high) {
      suggestions.add('High fatigue detected. Reduce intensity tomorrow or take a rest day.');
    }

    if (undertrained.isNotEmpty) {
      suggestions.add(undertrained.first);
    }

    return suggestions;
  }

  static Future<WorkoutAnalysisIndex> loadIndex() async {
    final records = await StorageService().loadExerciseRecords();
    return buildIndex(records);
  }

  static Future<DailyWorkoutAnalysis?> latestAnalysisCached() async {
    if (_latestFuture != null) return _latestFuture!;
    _latestFuture = _computeLatest();
    return _latestFuture!;
  }

  static Future<DailyWorkoutAnalysis?> _computeLatest() async {
    final records = await StorageService().loadExerciseRecords();
    if (records.isEmpty) return null;
    // Find latest without sorting
    ExerciseRecord latest = records.first;
    for (final r in records.skip(1)) {
      if (r.dateRecorded.isAfter(latest.dateRecorded)) {
        latest = r;
      }
    }
    final index = buildIndex(records);
    return analyzeFromIndex(
      index,
      day: dayStart(latest.dateRecorded),
      bodyPart: latest.bodyPart,
    );
  }

  static void invalidateCache() {
    _latestFuture = null;
  }

  static Future<DailyWorkoutAnalysis?>? _latestFuture;

  static Future<DailyWorkoutAnalysis?> latestAnalysis() async {
    // Back-compat: use cached latest.
    final f = await latestAnalysisCached();
    return f;
  }

  static Future<DailyWorkoutAnalysis?> analyzeForDayAndBodyPart(
    DateTime day,
    String bodyPart,
  ) async {
    final records = await StorageService().loadExerciseRecords();
    final index = buildIndex(records);
    return analyzeFromIndex(index, day: day, bodyPart: bodyPart);
  }

  static DailyWorkoutAnalysis? analyzeFromRecords(
    List<ExerciseRecord> all, {
    required DateTime day,
    required String bodyPart,
  }) {
    final index = buildIndex(all);
    return analyzeFromIndex(index, day: day, bodyPart: bodyPart);
  }

  static String _workoutTitle(String bodyPart) {
    // Display-friendly naming.
    return '${bodyPart.toUpperCase()} DAY';
  }

  // Note: _buildSuggestions moved to indexed version for performance.

  static Color trendColor(OverloadTrend trend, ColorScheme scheme) {
    return switch (trend) {
      OverloadTrend.improved => const Color(0xFF2EE59D),
      OverloadTrend.maintained => const Color(0xFFFFD166),
      OverloadTrend.regressed => const Color(0xFFFF5C5C),
    };
  }

  static String trendLabel(OverloadTrend trend) {
    return switch (trend) {
      OverloadTrend.improved => '↑ Strength Improved',
      OverloadTrend.maintained => '→ Maintained',
      OverloadTrend.regressed => '↓ Regressed',
    };
  }

  static String fatigueLabel(FatigueSignal f) {
    return switch (f) {
      FatigueSignal.fresh => '🟢 Fresh',
      FatigueSignal.moderate => '🟡 Moderate fatigue',
      FatigueSignal.high => '🔴 High fatigue',
    };
  }
}
