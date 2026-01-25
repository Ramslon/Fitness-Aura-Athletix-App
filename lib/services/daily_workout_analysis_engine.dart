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

  static Future<DailyWorkoutAnalysis?> latestAnalysis() async {
    final all = await StorageService().loadExerciseRecords();
    if (all.isEmpty) return null;
    all.sort((a, b) => b.dateRecorded.compareTo(a.dateRecorded));
    final latest = all.first;
    return analyzeForDayAndBodyPart(dayStart(latest.dateRecorded), latest.bodyPart);
  }

  static Future<DailyWorkoutAnalysis?> analyzeForDayAndBodyPart(
    DateTime day,
    String bodyPart,
  ) async {
    final all = await StorageService().loadExerciseRecords();
    return analyzeFromRecords(all, day: day, bodyPart: bodyPart);
  }

  static DailyWorkoutAnalysis? analyzeFromRecords(
    List<ExerciseRecord> all, {
    required DateTime day,
    required String bodyPart,
  }) {
    final targetDay = dayStart(day);

    final session =
        all
            .where(
              (r) =>
                  r.bodyPart == bodyPart &&
                  dayStart(r.dateRecorded) == targetDay,
            )
            .toList()
          ..sort((a, b) => a.dateRecorded.compareTo(b.dateRecorded));

    if (session.isEmpty) return null;

    final start = session.first.dateRecorded;
    final end = session.last.dateRecorded;
    final durationMinutes =
        end.isAfter(start) ? end.difference(start).inMinutes : 0;

    final uniqueExercises = session.map((e) => e.exerciseName).toSet();

    final totalVolume = session.fold<double>(0, (s, r) => s + volumeOf(r));

    // Optional calories estimate (very rough): ~6 kcal/min.
    final caloriesBurned = durationMinutes > 0 ? (durationMinutes * 6) : null;

    // Previous session (same bodyPart): most recent day < target day.
    final prevCandidates =
        all
            .where(
              (r) =>
                  r.bodyPart == bodyPart &&
                  dayStart(r.dateRecorded).isBefore(targetDay),
            )
            .toList()
          ..sort((a, b) => b.dateRecorded.compareTo(a.dateRecorded));

    DateTime? prevDay;
    if (prevCandidates.isNotEmpty) {
      prevDay = dayStart(prevCandidates.first.dateRecorded);
    }

    final prevSession =
        prevDay == null
            ? <ExerciseRecord>[]
            : all
                .where(
                  (r) =>
                      r.bodyPart == bodyPart &&
                      dayStart(r.dateRecorded) == prevDay,
                )
                .toList();

    final prevTotalVolume = prevSession.fold<double>(
      0,
      (s, r) => s + volumeOf(r),
    );

    final volumeChangePercent =
        prevTotalVolume > 0
            ? ((totalVolume - prevTotalVolume) / prevTotalVolume) * 100
            : null;

    // Progressive overload details by exercise: compare latest set vs previous.
    final overloadDetails = <String>[];
    for (final ex in uniqueExercises) {
      final curr =
          session.where((r) => r.exerciseName == ex).toList()
            ..sort((a, b) => b.dateRecorded.compareTo(a.dateRecorded));
      final prev =
          prevSession.where((r) => r.exerciseName == ex).toList()
            ..sort((a, b) => b.dateRecorded.compareTo(a.dateRecorded));

      if (curr.isEmpty || prev.isEmpty) continue;
      final c = curr.first;
      final p = prev.first;

      if (c.weight > p.weight + 0.01) {
        overloadDetails.add(
          '+${(c.weight - p.weight).toStringAsFixed(1)}kg on $ex',
        );
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

    // Muscle group impact: MVP uses bodyPart as primary group.
    final volumeByMuscle = <String, double>{bodyPart: totalVolume};

    // Undertrained warning: any bodyPart not trained in >= 5 days.
    final lastByPart = <String, DateTime>{};
    for (final r in all) {
      final existing = lastByPart[r.bodyPart];
      if (existing == null || r.dateRecorded.isAfter(existing)) {
        lastByPart[r.bodyPart] = r.dateRecorded;
      }
    }

    final now = DateTime.now();
    final undertrained = <String>[];
    for (final entry in lastByPart.entries) {
      final days = now.difference(entry.value).inDays;
      if (days >= 5) {
        undertrained.add('${entry.key} hasn\'t been trained in ${days} days');
      }
    }

    // Fatigue: rule-based score.
    int fatigueScore = 0;
    final latestDifficulty = session.last.difficulty.toLowerCase();
    if (latestDifficulty.contains('hard')) fatigueScore += 1;
    if ((volumeChangePercent ?? 0) > 20) fatigueScore += 1;

    final daysSincePrev = prevDay == null
        ? 99
        : targetDay.difference(prevDay).inDays;
    if (daysSincePrev <= 1) fatigueScore += 1;

    final fatigue = switch (fatigueScore) {
      0 => FatigueSignal.fresh,
      1 => FatigueSignal.moderate,
      _ => FatigueSignal.high,
    };

    // PRs & milestones
    final prs = <String>[];
    for (final ex in uniqueExercises) {
      final currMaxWeight = session
          .where((r) => r.exerciseName == ex)
          .fold<double>(0, (m, r) => r.weight > m ? r.weight : m);

      final prevMaxWeight = all
          .where(
            (r) =>
                r.exerciseName == ex &&
                (dayStart(r.dateRecorded).isBefore(targetDay)),
          )
          .fold<double>(0, (m, r) => r.weight > m ? r.weight : m);

      if (currMaxWeight > prevMaxWeight + 0.01 && prevMaxWeight > 0) {
        prs.add('New PR: $ex ${currMaxWeight.toStringAsFixed(1)}kg');
      }
    }

    // Streak
    // (This depends on WorkoutEntry in the old flow, but we can still show it
    // using existing method. If no entries exist, the streak will be 0.)
    // Note: We keep it async outside; callers can inject.

    // AI suggestions (rule-based MVP)
    final suggestions = _buildSuggestions(
      bodyPart: bodyPart,
      session: session,
      prevSession: prevSession,
      volumeChangePercent: volumeChangePercent,
      fatigue: fatigue,
      undertrained: undertrained,
      all: all,
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

  static String _workoutTitle(String bodyPart) {
    // Display-friendly naming.
    return '${bodyPart.toUpperCase()} DAY';
  }

  static List<String> _buildSuggestions({
    required String bodyPart,
    required List<ExerciseRecord> session,
    required List<ExerciseRecord> prevSession,
    required double? volumeChangePercent,
    required FatigueSignal fatigue,
    required List<String> undertrained,
    required List<ExerciseRecord> all,
  }) {
    final suggestions = <String>[];

    // 1) Load progression / plateau detection (same weight & reps for 3 sessions)
    final byExercise = <String, List<ExerciseRecord>>{};
    for (final r in all.where((r) => r.bodyPart == bodyPart)) {
      byExercise.putIfAbsent(r.exerciseName, () => <ExerciseRecord>[]);
      byExercise[r.exerciseName]!.add(r);
    }
    for (final e in byExercise.entries) {
      final list = e.value..sort((a, b) => b.dateRecorded.compareTo(a.dateRecorded));
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

    // 2) Volume adjustment
    final v = volumeChangePercent ?? 0;
    if (v >= 15) {
      suggestions.add(
        'Volume increased by ${v.toStringAsFixed(0)}% today. Keep it steady next session.',
      );
    }

    // 3) Exercise selection advice (simple complement mapping)
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

    // 4) Recovery advice
    if (fatigue == FatigueSignal.high) {
      suggestions.add(
        'High fatigue detected. Reduce intensity tomorrow or take a rest day.',
      );
    }

    // 5) Consistency feedback
    if (undertrained.isNotEmpty) {
      suggestions.add(undertrained.first);
    }

    // Keep 1–3, short.
    return suggestions;
  }

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
