import 'dart:math';

import 'package:fitness_aura_athletix/core/models/exercise.dart';

enum MotivationType {
  performanceBased,
  effortBased,
  comebackBased,
  nearGoal,
}

enum MotivationTone {
  encouraging,
  neutral,
  challenging,
}

class MotivationResult {
  final MotivationType type;
  final MotivationTone tone;
  final String message;
  final String? insight;

  const MotivationResult({
    required this.type,
    required this.tone,
    required this.message,
    this.insight,
  });
}

class MotivationEngine {
  MotivationEngine._();
  static final MotivationEngine _instance = MotivationEngine._();
  factory MotivationEngine() => _instance;

  MotivationResult generate({
    required List<ExerciseRecord> records,
    required int currentStreakDays,
    required int workoutsThisWeek,
    DateTime? now,
  }) {
    final tNow = now ?? DateTime.now();

    final lastWorkout = _lastWorkoutDate(records);
    final daysSinceWorkout = lastWorkout == null
        ? 999
        : tNow.difference(lastWorkout).inDays.clamp(0, 999);

    final tone = _toneFor(
      workoutsThisWeek: workoutsThisWeek,
      currentStreakDays: currentStreakDays,
      daysSinceWorkout: daysSinceWorkout,
    );

    if (records.isEmpty) {
      return MotivationResult(
        type: MotivationType.comebackBased,
        tone: MotivationTone.encouraging,
        message: 'Start with one session. Consistency begins today.',
        insight: 'No logs yet — the engine adapts once you track workouts.',
      );
    }

    final isComeback = daysSinceWorkout >= 7;
    if (isComeback) {
      return MotivationResult(
        type: MotivationType.comebackBased,
        tone: MotivationTone.encouraging,
        message: _applyTone(
          base: 'Welcome back. Consistency restarts today.',
          tone: tone,
        ),
        insight: 'Last workout was $daysSinceWorkout days ago.',
      );
    }

    final near = _findNearGoal(records, now: tNow);
    if (near != null) {
      final deltaText = near.deltaPercent == null
          ? ''
          : ' You are ${near.deltaPercent!.toStringAsFixed(1)}% away.';
      return MotivationResult(
        type: MotivationType.nearGoal,
        tone: tone,
        message: _applyTone(
          base: 'One more session to beat your ${near.exerciseName} PR.$deltaText',
          tone: tone,
        ),
        insight: 'Recent top set is close to your best.',
      );
    }

    final perf = _findPerformance(records, now: tNow);
    if (perf != null) {
      final pct = max(0, perf.percentChange).clamp(0, 999);
      return MotivationResult(
        type: MotivationType.performanceBased,
        tone: tone,
        message: _applyTone(
          base: 'Your ${perf.bodyPart.toLowerCase()} strength is up ${pct.toStringAsFixed(0)}% this month.',
          tone: tone,
        ),
        insight: 'Compared last 30 days vs previous 30 days.',
      );
    }

    final effort = _findEffort(records, now: tNow);
    return MotivationResult(
      type: MotivationType.effortBased,
      tone: tone,
      message: _applyTone(
        base: effort ?? 'You trained anyway — discipline beats motivation.',
        tone: tone,
      ),
      insight: 'Based on recent difficulty + consistency.',
    );
  }

  MotivationTone _toneFor({
    required int workoutsThisWeek,
    required int currentStreakDays,
    required int daysSinceWorkout,
  }) {
    // 🔴 Low consistency → encouraging
    if (daysSinceWorkout >= 7 || workoutsThisWeek <= 0 || currentStreakDays < 3) {
      return MotivationTone.encouraging;
    }

    // 🟢 High momentum → challenging
    if (workoutsThisWeek >= 5 || currentStreakDays >= 14) {
      return MotivationTone.challenging;
    }

    // 🟡 Normal → neutral
    return MotivationTone.neutral;
  }

  DateTime? _lastWorkoutDate(List<ExerciseRecord> records) {
    if (records.isEmpty) return null;
    DateTime best = records.first.dateRecorded;
    for (final r in records) {
      if (r.dateRecorded.isAfter(best)) best = r.dateRecorded;
    }
    return best;
  }

  String _applyTone({required String base, required MotivationTone tone}) {
    switch (tone) {
      case MotivationTone.encouraging:
        return base;
      case MotivationTone.neutral:
        return base;
      case MotivationTone.challenging:
        // Keep it short and non-childish; add a nudge.
        return '$base Raise the standard next session.';
    }
  }

  _NearGoal? _findNearGoal(List<ExerciseRecord> records, {required DateTime now}) {
    // Look for an exercise where the most recent top estimated 1RM is within ~3% of all-time best.
    final byExercise = <String, List<ExerciseRecord>>{};
    for (final r in records) {
      byExercise.putIfAbsent(r.exerciseName, () => []).add(r);
    }

    _NearGoal? best;
    for (final e in byExercise.entries) {
      final name = e.key;
      final list = e.value;
      list.sort((a, b) => a.dateRecorded.compareTo(b.dateRecorded));

      double allTimeBest = 0;
      for (final r in list) {
        allTimeBest = max(allTimeBest, _estimate1Rm(r.weight, r.repsPerSet));
      }

      // Recent window: last 21 days
      final cutoff = now.subtract(const Duration(days: 21));
      double recentBest = 0;
      for (final r in list) {
        if (r.dateRecorded.isBefore(cutoff)) continue;
        recentBest = max(recentBest, _estimate1Rm(r.weight, r.repsPerSet));
      }

      if (allTimeBest <= 0 || recentBest <= 0) continue;
      if (recentBest >= allTimeBest) continue; // already at PR

      final deltaPct = (1 - (recentBest / allTimeBest)) * 100;
      if (deltaPct <= 0 || deltaPct > 3.5) continue;

      final candidate = _NearGoal(
        exerciseName: name,
        deltaPercent: deltaPct,
      );

      if (best == null || (candidate.deltaPercent ?? 999) < (best.deltaPercent ?? 999)) {
        best = candidate;
      }
    }

    return best;
  }

  _Performance? _findPerformance(List<ExerciseRecord> records, {required DateTime now}) {
    // Find the best month-over-month strength improvement by body part.
    // Compare max estimated 1RM in last 30d vs previous 30d.
    final last30Cutoff = now.subtract(const Duration(days: 30));
    final prev30Cutoff = now.subtract(const Duration(days: 60));

    final maxLast30ByPart = <String, double>{};
    final maxPrev30ByPart = <String, double>{};

    for (final r in records) {
      final part = r.bodyPart.trim();
      final oneRm = _estimate1Rm(r.weight, r.repsPerSet);

      if (r.dateRecorded.isAfter(last30Cutoff)) {
        maxLast30ByPart[part] = max(maxLast30ByPart[part] ?? 0, oneRm);
      } else if (r.dateRecorded.isAfter(prev30Cutoff)) {
        maxPrev30ByPart[part] = max(maxPrev30ByPart[part] ?? 0, oneRm);
      }
    }

    _Performance? best;
    for (final e in maxLast30ByPart.entries) {
      final part = e.key;
      final last = e.value;
      final prev = maxPrev30ByPart[part] ?? 0;
      if (prev <= 0 || last <= 0) continue;

      final pct = ((last - prev) / prev) * 100;
      if (pct < 3) continue; // avoid noise

      final candidate = _Performance(bodyPart: part, percentChange: pct);
      if (best == null || candidate.percentChange > best.percentChange) {
        best = candidate;
      }
    }

    return best;
  }

  String? _findEffort(List<ExerciseRecord> records, {required DateTime now}) {
    // Use last session difficulty as an effort proxy.
    final last = _mostRecent(records);
    if (last == null) return null;

    final diff = last.difficulty.toLowerCase();
    if (diff.contains('hard')) {
      return 'You trained despite fatigue—discipline beats motivation.';
    }
    if (diff.contains('moderate')) {
      return 'Solid work. Consistency compounds when the sessions feel normal.';
    }
    if (diff.contains('easy')) {
      return 'You made it look easy. Keep the pace and add intent next session.';
    }
    return null;
  }

  ExerciseRecord? _mostRecent(List<ExerciseRecord> records) {
    if (records.isEmpty) return null;
    ExerciseRecord best = records.first;
    for (final r in records) {
      if (r.dateRecorded.isAfter(best.dateRecorded)) best = r;
    }
    return best;
  }

  double _estimate1Rm(double weight, int reps) {
    // Epley formula (rough): 1RM = w * (1 + reps/30)
    final r = reps.clamp(1, 30);
    return weight * (1 + (r / 30.0));
  }
}

class _NearGoal {
  final String exerciseName;
  final double? deltaPercent;

  const _NearGoal({required this.exerciseName, required this.deltaPercent});
}

class _Performance {
  final String bodyPart;
  final double percentChange;

  const _Performance({required this.bodyPart, required this.percentChange});
}
