import 'package:flutter/material.dart';
import 'package:fitness_aura_athletix/core/models/exercise.dart';
import 'package:fitness_aura_athletix/core/models/progressive_overload.dart';
import 'package:fitness_aura_athletix/services/storage_service.dart';

class AchievementsMotivationScreen extends StatefulWidget {
  const AchievementsMotivationScreen({super.key});

  @override
  State<AchievementsMotivationScreen> createState() =>
      _AchievementsMotivationScreenState();
}

class _AchievementsMotivationScreenState
    extends State<AchievementsMotivationScreen> {
  bool _loading = true;

  List<_PrAlert> _prAlerts = const [];
  int _currentStreakDays = 0;
  int _workoutsThisWeek = 0;
  List<_Badge> _badges = const [];
  List<_OverloadStreak> _overloadStreaks = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final storage = StorageService();
    final records = await storage.loadExerciseRecords();
    final streak = await storage.currentStreak();
    final week = await storage.workoutsThisWeek();
    final overloadMetrics = await storage.getProgressiveOverloadMetrics();

    final prAlerts = _computeRecentPersonalRecords(records, daysBack: 14);
    final badges = _computeBadges(streakDays: streak, workoutsThisWeek: week);
    final overloadStreaks = _computeOverloadStreaks(records, overloadMetrics);

    setState(() {
      _prAlerts = prAlerts;
      _currentStreakDays = streak;
      _workoutsThisWeek = week;
      _badges = badges;
      _overloadStreaks = overloadStreaks;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PRs, Achievements & Motivation')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _sectionHeader('New Personal Records'),
                  const SizedBox(height: 8),
                  if (_prAlerts.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'No new PRs yet. Log workouts to unlock PR alerts.',
                        ),
                      ),
                    )
                  else
                    ..._prAlerts.map(
                      (p) => Card(
                        child: ListTile(
                          leading: Text(
                            p.emoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                          title: Text(p.titleText),
                          subtitle: Text(p.subtitleText),
                        ),
                      ),
                    ),
                  const SizedBox(height: 18),

                  _sectionHeader('Consistency'),
                  const SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.local_fire_department),
                      title: Text('Current streak: $_currentStreakDays days'),
                      subtitle: Text('Workouts this week: $_workoutsThisWeek'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_badges.isEmpty)
                    const SizedBox.shrink()
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _badges
                          .map(
                            (b) => Chip(
                              label: Text(b.label),
                              avatar: Text(b.emoji),
                            ),
                          )
                          .toList(),
                    ),
                  const SizedBox(height: 18),

                  _sectionHeader('Progressive Overload Streaks'),
                  const SizedBox(height: 8),
                  if (_overloadStreaks.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'No overload streaks yet. Keep increasing reps/weight/sets to build streaks.',
                        ),
                      ),
                    )
                  else
                    ..._overloadStreaks
                        .take(10)
                        .map(
                          (s) => Card(
                            child: ListTile(
                              leading: const Icon(Icons.trending_up),
                              title: Text(
                                '${s.exerciseName} — ${s.streak} streak',
                              ),
                              subtitle: Text(
                                '${s.bodyPart} • ${s.lastImprovementText}',
                              ),
                            ),
                          ),
                        ),
                ],
              ),
            ),
    );
  }

  static Widget _sectionHeader(String title) {
    return Text(title, style: const TextStyle(fontWeight: FontWeight.bold));
  }
}

class _PrAlert {
  final String exerciseName;
  final String bodyPart;
  final _PrType type;
  final double value;
  final double delta;
  final DateTime date;

  _PrAlert({
    required this.exerciseName,
    required this.bodyPart,
    required this.type,
    required this.value,
    required this.delta,
    required this.date,
  });

  String get dateText {
    final d = date;
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String get emoji {
    switch (type) {
      case _PrType.weight:
        return '🏋️';
      case _PrType.reps:
        return '🔁';
      case _PrType.volume:
        return '📊';
    }
  }

  String get titleText {
    switch (type) {
      case _PrType.weight:
        return '${exerciseName} — ${value.toStringAsFixed(1)} kg';
      case _PrType.reps:
        return '${exerciseName} — ${value.toStringAsFixed(0)} reps';
      case _PrType.volume:
        return '${exerciseName} — ${value.toStringAsFixed(0)} volume';
    }
  }

  String get subtitleText {
    switch (type) {
      case _PrType.weight:
        return '${bodyPart} • ${dateText} • +${delta.toStringAsFixed(1)} kg PR';
      case _PrType.reps:
        return '${bodyPart} • ${dateText} • +${delta.toStringAsFixed(0)} reps PR';
      case _PrType.volume:
        return '${bodyPart} • ${dateText} • +${delta.toStringAsFixed(0)} volume PR';
    }
  }
}

enum _PrType { weight, reps, volume }

class _Badge {
  final String label;
  final String emoji;

  const _Badge({required this.label, required this.emoji});
}

class _OverloadStreak {
  final String exerciseName;
  final String bodyPart;
  final int streak;
  final DateTime? lastImprovementDate;

  const _OverloadStreak({
    required this.exerciseName,
    required this.bodyPart,
    required this.streak,
    required this.lastImprovementDate,
  });

  String get lastImprovementText {
    if (lastImprovementDate == null) return 'No recent improvement recorded';
    final d = lastImprovementDate!;
    return 'Last improvement: ${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}

List<_PrAlert> _computeRecentPersonalRecords(
  List<ExerciseRecord> records, {
  int daysBack = 14,
}) {
  if (records.isEmpty) return [];

  final sorted = [...records]
    ..sort((a, b) => a.dateRecorded.compareTo(b.dateRecorded));
  final cutoff = DateTime.now().subtract(Duration(days: daysBack));

  final bestWeightBefore = <String, double>{};
  final bestRepsBefore = <String, int>{};
  final bestVolumeBefore = <String, double>{};
  final alerts = <_PrAlert>[];

  for (final r in sorted) {
    final key = r.exerciseName.toLowerCase().trim();
    final prevBestWeight = bestWeightBefore[key] ?? 0;
    final prevBestReps = bestRepsBefore[key] ?? 0;
    final prevBestVolume = bestVolumeBefore[key] ?? 0;

    final volume = r.weight * r.sets * r.repsPerSet;
    final isRecent = r.dateRecorded.isAfter(cutoff);

    // Weight PR
    if (r.weight > prevBestWeight) {
      if (isRecent) {
        alerts.add(
          _PrAlert(
            exerciseName: r.exerciseName,
            bodyPart: r.bodyPart,
            type: _PrType.weight,
            value: r.weight,
            delta: (r.weight - prevBestWeight),
            date: r.dateRecorded,
          ),
        );
      }
      bestWeightBefore[key] = r.weight;
    }

    // Rep PR (best repsPerSet)
    if (r.repsPerSet > prevBestReps) {
      if (isRecent) {
        alerts.add(
          _PrAlert(
            exerciseName: r.exerciseName,
            bodyPart: r.bodyPart,
            type: _PrType.reps,
            value: r.repsPerSet.toDouble(),
            delta: (r.repsPerSet - prevBestReps).toDouble(),
            date: r.dateRecorded,
          ),
        );
      }
      bestRepsBefore[key] = r.repsPerSet;
    }

    // Volume PR (weight * sets * reps)
    if (volume > prevBestVolume) {
      if (isRecent) {
        alerts.add(
          _PrAlert(
            exerciseName: r.exerciseName,
            bodyPart: r.bodyPart,
            type: _PrType.volume,
            value: volume,
            delta: (volume - prevBestVolume),
            date: r.dateRecorded,
          ),
        );
      }
      bestVolumeBefore[key] = volume;
    }
  }

  alerts.sort((a, b) => b.date.compareTo(a.date));
  return alerts.take(10).toList();
}

List<_Badge> _computeBadges({
  required int streakDays,
  required int workoutsThisWeek,
}) {
  final badges = <_Badge>[];

  if (streakDays >= 3)
    badges.add(const _Badge(label: '3-day streak', emoji: '🔥'));
  if (streakDays >= 7)
    badges.add(const _Badge(label: '7-day streak', emoji: '🏅'));
  if (streakDays >= 14)
    badges.add(const _Badge(label: '14-day streak', emoji: '💎'));
  if (streakDays >= 30)
    badges.add(const _Badge(label: '30-day streak', emoji: '👑'));

  if (workoutsThisWeek >= 3)
    badges.add(const _Badge(label: '3 workouts this week', emoji: '✅'));
  if (workoutsThisWeek >= 5)
    badges.add(const _Badge(label: '5 workouts this week', emoji: '💪'));

  return badges;
}

List<_OverloadStreak> _computeOverloadStreaks(
  List<ExerciseRecord> records,
  List<ProgressiveOverloadMetrics> metrics,
) {
  if (records.isEmpty) return [];

  // Group records by exercise for streak computation.
  final byExercise = <String, List<ExerciseRecord>>{};
  for (final r in records) {
    byExercise.putIfAbsent(r.exerciseName, () => []);
    byExercise[r.exerciseName]!.add(r);
  }

  int streakFor(List<ExerciseRecord> rs) {
    // Streak defined as consecutive sessions (from newest backwards)
    // where volume increases compared to previous session.
    final sorted = [...rs]
      ..sort((a, b) => b.dateRecorded.compareTo(a.dateRecorded));
    if (sorted.length < 2) return 0;

    int streak = 0;
    for (int i = 0; i < sorted.length - 1; i++) {
      final cur = sorted[i];
      final prev = sorted[i + 1];
      final curVol = cur.weight * cur.sets * cur.repsPerSet;
      final prevVol = prev.weight * prev.sets * prev.repsPerSet;
      if (curVol > prevVol) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  final result = <_OverloadStreak>[];
  for (final entry in byExercise.entries) {
    final rs = entry.value;
    if (rs.length < 2) continue;
    final latest =
        (rs..sort((a, b) => b.dateRecorded.compareTo(a.dateRecorded))).first;

    final s = streakFor(rs);
    if (s <= 0) continue;

    // Last improvement date is the latest record date if streak>0.
    result.add(
      _OverloadStreak(
        exerciseName: latest.exerciseName,
        bodyPart: latest.bodyPart,
        streak: s,
        lastImprovementDate: latest.dateRecorded,
      ),
    );
  }

  // Sort by streak desc, then most recent improvement.
  result.sort((a, b) {
    final byStreak = b.streak.compareTo(a.streak);
    if (byStreak != 0) return byStreak;
    final ad = a.lastImprovementDate ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bd = b.lastImprovementDate ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bd.compareTo(ad);
  });

  return result;
}
