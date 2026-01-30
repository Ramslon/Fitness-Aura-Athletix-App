import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitness_aura_athletix/core/models/achievement.dart';
import 'package:fitness_aura_athletix/core/models/exercise.dart';
import 'package:fitness_aura_athletix/core/models/muscle_balance.dart';
import 'package:fitness_aura_athletix/services/storage_service.dart';

class AchievementService {
  static const _kEarnedKey = 'achievements_earned_v1';
  static const _kBodyWeightKey = 'body_weight_kg';

  AchievementService._();
  static final AchievementService _instance = AchievementService._();
  factory AchievementService() => _instance;

  static const List<String> _requiredMuscleGroups = [
    'Chest',
    'Back',
    'Legs',
    'Shoulders',
    'Arms',
    'Core',
    'Glutes',
    'Abs',
  ];

  static const List<AchievementDefinition> definitions = [
    // Consistency
    AchievementDefinition(
      id: 'streak_7',
      category: AchievementCategory.consistency,
      title: '7-day streak',
      description: 'Train on 7 consecutive days.',
      progressLabel: 'days',
      target: 7,
      icon: Icons.local_fire_department_outlined,
    ),
    AchievementDefinition(
      id: 'streak_30',
      category: AchievementCategory.consistency,
      title: '30-day streak',
      description: 'Train on 30 consecutive days.',
      progressLabel: 'days',
      target: 30,
      icon: Icons.calendar_month_outlined,
    ),
    AchievementDefinition(
      id: 'workouts_100',
      category: AchievementCategory.consistency,
      title: '100 workouts logged',
      description: 'Log 100 workout days.',
      progressLabel: 'workouts',
      target: 100,
      icon: Icons.checklist_outlined,
    ),

    // Strength
    AchievementDefinition(
      id: 'first_pr',
      category: AchievementCategory.strength,
      title: 'First PR',
      description: 'Beat a previous best (weight, reps, or volume).',
      progressLabel: 'PRs',
      target: 1,
      icon: Icons.emoji_events_outlined,
    ),
    AchievementDefinition(
      id: 'strength_gain_10pct',
      category: AchievementCategory.strength,
      title: '+10% strength gain',
      description: 'Improve best weight by 10% (30-day window).',
      progressLabel: '%',
      target: 10,
      icon: Icons.trending_up,
    ),
    AchievementDefinition(
      id: 'squat_2xbw',
      category: AchievementCategory.strength,
      title: 'Double bodyweight squat',
      description: 'Best squat ≥ 2× bodyweight (set bodyweight on this screen).',
      progressLabel: '×BW',
      target: 2,
      icon: Icons.square_foot_outlined,
    ),

    // Balance
    AchievementDefinition(
      id: 'all_groups_weekly',
      category: AchievementCategory.balance,
      title: 'All muscle groups trained weekly',
      description: 'Train each major group at least once in 7 days.',
      progressLabel: 'groups',
      target: 8,
      icon: Icons.dashboard_customize_outlined,
    ),
    AchievementDefinition(
      id: 'weak_point_improvement',
      category: AchievementCategory.balance,
      title: 'Weak-point improvement',
      description: 'Bring your least-trained group up to 2 sessions this week.',
      progressLabel: 'sessions',
      target: 2,
      icon: Icons.tune_outlined,
    ),

    // Discipline
    AchievementDefinition(
      id: 'rest_days_respected',
      category: AchievementCategory.discipline,
      title: 'Rest days respected',
      description: 'Train 3–6 days this week (at least one rest day).',
      progressLabel: 'goal',
      target: 1,
      icon: Icons.bedtime_outlined,
    ),
    AchievementDefinition(
      id: 'deload_completed',
      category: AchievementCategory.discipline,
      title: 'Deload completed',
      description: 'Mark a deload week completed (manual).',
      progressLabel: 'goal',
      target: 1,
      icon: Icons.restart_alt_outlined,
    ),
  ];

  Future<double?> loadBodyWeightKg() async {
    final raw = await StorageService().loadStringSetting(_kBodyWeightKey);
    if (raw == null) return null;
    final v = double.tryParse(raw.trim());
    if (v == null || v <= 0) return null;
    return v;
  }

  Future<void> saveBodyWeightKg(double kg) async {
    await StorageService().saveStringSetting(_kBodyWeightKey, kg.toString());
  }

  Future<void> markDeloadCompleted() async {
    final earned = await _loadEarned();
    if (!earned.containsKey('deload_completed')) {
      earned['deload_completed'] = DateTime.now();
      await _saveEarned(earned);
    }
  }

  Future<List<AchievementProgress>> computeAll() async {
    final earned = await _loadEarned();

    final storage = StorageService();
    final records = await storage.loadExerciseRecords();
    final balance = await storage.getMuscleBalanceAnalysis();

    // Build a robust "workout day" set from exercise logs.
    final trainingDays = <DateTime>{};
    for (final r in records) {
      trainingDays.add(DateTime(r.dateRecorded.year, r.dateRecorded.month, r.dateRecorded.day));
    }

    final streakDays = _computeStreakFromDays(trainingDays);
    final workoutsLogged = trainingDays.length;
    final workoutsThisWeek = _countDaysInWindow(trainingDays, daysBackInclusive: 6);

    final prCount = _countPrEvents(records);
    final strengthGainPct = _max30DayStrengthGainPercent(records);

    final bodyWeight = await loadBodyWeightKg();
    final squatBest = _bestSquatWeight(records);
    final squatBwRatio = (bodyWeight == null || bodyWeight <= 0) ? 0.0 : (squatBest / bodyWeight);

    final coveredGroups = _coveredRequiredGroupsThisWeek(records);
    final coveredCount = coveredGroups.length;

    final minWeeklyFreq = _minWeeklyFrequency(balance);
    final restRespected = workoutsThisWeek >= 3 && workoutsThisWeek <= 6;

    final computed = <AchievementProgress>[];

    for (final def in definitions) {
      double current = 0;
      switch (def.id) {
        case 'streak_7':
          current = streakDays.toDouble();
          break;
        case 'streak_30':
          current = streakDays.toDouble();
          break;
        case 'workouts_100':
          current = workoutsLogged.toDouble();
          break;
        case 'first_pr':
          current = prCount.toDouble();
          break;
        case 'strength_gain_10pct':
          current = strengthGainPct;
          break;
        case 'squat_2xbw':
          current = squatBwRatio;
          break;
        case 'all_groups_weekly':
          current = coveredCount.toDouble();
          break;
        case 'weak_point_improvement':
          current = minWeeklyFreq.toDouble();
          break;
        case 'rest_days_respected':
          current = restRespected ? 1 : 0;
          break;
        case 'deload_completed':
          current = earned.containsKey('deload_completed') ? 1 : 0;
          break;
      }

      final alreadyEarnedAt = earned[def.id];
      final shouldEarn = current >= def.target;
      if (alreadyEarnedAt == null && shouldEarn) {
        earned[def.id] = DateTime.now();
      }

      computed.add(
        AchievementProgress(
          definition: def,
          current: current,
          earnedAt: earned[def.id],
        ),
      );
    }

    await _saveEarned(earned);
    return computed;
  }

  Future<Map<String, DateTime>> _loadEarned() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kEarnedKey);
    if (raw == null || raw.isEmpty) return {};

    try {
      final map = Map<String, dynamic>.from(jsonDecode(raw));
      final out = <String, DateTime>{};
      for (final e in map.entries) {
        final v = e.value;
        if (v is int) out[e.key] = DateTime.fromMillisecondsSinceEpoch(v);
      }
      return out;
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveEarned(Map<String, DateTime> earned) async {
    final prefs = await SharedPreferences.getInstance();
    final map = <String, int>{};
    for (final e in earned.entries) {
      map[e.key] = e.value.millisecondsSinceEpoch;
    }
    await prefs.setString(_kEarnedKey, jsonEncode(map));
  }

  static int _countDaysInWindow(Set<DateTime> days, {required int daysBackInclusive}) {
    if (days.isEmpty) return 0;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysBackInclusive));
    return days.where((d) => !d.isBefore(start)).length;
  }

  static int _computeStreakFromDays(Set<DateTime> days) {
    if (days.isEmpty) return 0;

    final normalizedDays = days
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet();

    int streak = 0;
    DateTime cursor = DateTime.now();

    while (true) {
      final day = DateTime(cursor.year, cursor.month, cursor.day);
      if (normalizedDays.contains(day)) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
        continue;
      }
      break;
    }

    return streak;
  }

  static int _countPrEvents(List<ExerciseRecord> records) {
    if (records.isEmpty) return 0;

    final sorted = [...records]..sort((a, b) => a.dateRecorded.compareTo(b.dateRecorded));

    final bestWeight = <String, double>{};
    final bestReps = <String, int>{};
    final bestVolume = <String, double>{};

    int prs = 0;

    for (final r in sorted) {
      final key = r.exerciseName.toLowerCase().trim();

      final w = r.effectiveWeightKg;

      final prevW = bestWeight[key] ?? 0;
      final prevR = bestReps[key] ?? 0;
      final prevV = bestVolume[key] ?? 0;
      final v = r.volumeLoadKg;

      // Only count a PR if there was a previous baseline.
      if (prevW > 0 && w > prevW) prs++;
      if (prevR > 0 && r.repsPerSet > prevR) prs++;
      if (prevV > 0 && v > prevV) prs++;

      if (w > prevW) bestWeight[key] = w;
      if (r.repsPerSet > prevR) bestReps[key] = r.repsPerSet;
      if (v > prevV) bestVolume[key] = v;
    }

    return prs;
  }

  static double _max30DayStrengthGainPercent(List<ExerciseRecord> records) {
    if (records.isEmpty) return 0;

    final now = DateTime.now();
    final recentStart = now.subtract(const Duration(days: 30));
    final prevStart = now.subtract(const Duration(days: 60));

    final byExercise = <String, List<ExerciseRecord>>{};
    for (final r in records) {
      final key = r.exerciseName.toLowerCase().trim();
      byExercise.putIfAbsent(key, () => []).add(r);
    }

    double bestGainPct = 0;

    for (final list in byExercise.values) {
      double prevBest = 0;
      double recentBest = 0;

      for (final r in list) {
        if (r.dateRecorded.isAfter(prevStart) && r.dateRecorded.isBefore(recentStart)) {
          final w = r.effectiveWeightKg;
          if (w > prevBest) prevBest = w;
        }
        if (r.dateRecorded.isAfter(recentStart)) {
          final w = r.effectiveWeightKg;
          if (w > recentBest) recentBest = w;
        }
      }

      if (prevBest > 0 && recentBest > 0) {
        final gainPct = ((recentBest / prevBest) - 1) * 100;
        if (gainPct > bestGainPct) bestGainPct = gainPct;
      }
    }

    return bestGainPct.clamp(0, 1000);
  }

  static double _bestSquatWeight(List<ExerciseRecord> records) {
    double best = 0;
    for (final r in records) {
      final name = r.exerciseName.toLowerCase();
      final w = r.effectiveWeightKg;
      if (name.contains('squat') && w > best) best = w;
    }
    return best;
  }

  static Set<String> _coveredRequiredGroupsThisWeek(List<ExerciseRecord> records) {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 7));

    final coveredLower = <String>{};
    for (final r in records) {
      if (!r.dateRecorded.isAfter(start)) continue;
      coveredLower.add(r.bodyPart.toLowerCase().trim());
    }

    final covered = <String>{};
    for (final g in _requiredMuscleGroups) {
      if (coveredLower.contains(g.toLowerCase())) covered.add(g);
    }
    return covered;
  }

  static int _minWeeklyFrequency(List<MuscleBalanceAnalysis> balanceAnalysis) {
    final freqByGroup = <String, int>{};
    for (final a in balanceAnalysis) {
      freqByGroup[a.muscleGroup.trim()] = a.weeklyFrequency;
    }

    int minFreq = 1 << 30;
    for (final g in _requiredMuscleGroups) {
      final v = freqByGroup[g] ?? 0;
      if (v < minFreq) minFreq = v;
    }

    if (minFreq == (1 << 30)) return 0;
    return minFreq;
  }
}
