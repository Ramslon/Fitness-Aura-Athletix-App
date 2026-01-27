import 'package:flutter/material.dart';
import 'package:fitness_aura_athletix/core/models/achievement.dart';
import 'package:fitness_aura_athletix/core/models/exercise.dart';
import 'package:fitness_aura_athletix/core/models/progressive_overload.dart';
import 'package:fitness_aura_athletix/presentation/widgets/achievement_badge_tile.dart';
import 'package:fitness_aura_athletix/services/achievement_service.dart';
import 'package:fitness_aura_athletix/services/motivation_engine.dart';
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
  List<AchievementProgress> _achievements = const [];
  List<_OverloadStreak> _overloadStreaks = const [];
  MotivationResult? _motivation;

  final _bodyWeightController = TextEditingController();
  bool _savingBodyWeight = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _bodyWeightController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final storage = StorageService();
    final records = await storage.loadExerciseRecords();
    final streak = await storage.currentStreak();
    final week = await storage.workoutsThisWeek();
    final overloadMetrics = await storage.getProgressiveOverloadMetrics();

    final achievements = await AchievementService().computeAll();
    final bodyWeight = await AchievementService().loadBodyWeightKg();
    if (bodyWeight != null) {
      _bodyWeightController.text = bodyWeight.toStringAsFixed(1);
    }

    final prAlerts = _computeRecentPersonalRecords(records, daysBack: 14);
    final overloadStreaks = _computeOverloadStreaks(records, overloadMetrics);
    final motivation = MotivationEngine().generate(
      records: records,
      currentStreakDays: streak,
      workoutsThisWeek: week,
    );

    setState(() {
      _prAlerts = prAlerts;
      _currentStreakDays = streak;
      _workoutsThisWeek = week;
      _achievements = achievements;
      _overloadStreaks = overloadStreaks;
      _motivation = motivation;
      _loading = false;
    });
  }

  Future<void> _saveBodyWeight() async {
    final raw = _bodyWeightController.text.trim();
    final v = double.tryParse(raw);
    if (v == null || v <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid bodyweight in kg.')),
      );
      return;
    }

    setState(() => _savingBodyWeight = true);
    await AchievementService().saveBodyWeightKg(v);
    await _load();
    if (!mounted) return;
    setState(() => _savingBodyWeight = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bodyweight saved.')),
    );
  }

  Future<void> _markDeloadCompleted() async {
    await AchievementService().markDeloadCompleted();
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Deload marked completed.')),
    );
  }

  Map<AchievementCategory, List<AchievementProgress>> _groupedAchievements() {
    final map = <AchievementCategory, List<AchievementProgress>>{};
    for (final a in _achievements) {
      map.putIfAbsent(a.definition.category, () => []).add(a);
    }
    for (final e in map.entries) {
      e.value.sort((a, b) {
        if (a.isEarned != b.isEarned) return a.isEarned ? 1 : -1;
        return b.fraction.compareTo(a.fraction);
      });
    }
    return map;
  }

  AchievementProgress? _nextAchievement() {
    final pending = _achievements.where((a) => !a.isEarned).toList();
    if (pending.isEmpty) return null;
    pending.sort((a, b) => b.fraction.compareTo(a.fraction));
    return pending.first;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final grouped = _groupedAchievements();
    final next = _nextAchievement();

    return Scaffold(
      appBar: AppBar(
        title: const Text('PRs, Achievements & Motivation'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
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
                          leading: Icon(p.icon, color: scheme.primary),
                          title: Text(p.titleText),
                          subtitle: Text(p.subtitleText),
                        ),
                      ),
                    ),
                  const SizedBox(height: 18),

                  _sectionHeader('Achievements'),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Achievement settings',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _bodyWeightController,
                                  keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  decoration: const InputDecoration(
                                    labelText: 'Bodyweight (kg)',
                                    hintText: 'e.g. 75.0',
                                  ),
                                  onSubmitted: (_) => _saveBodyWeight(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                tooltip: 'Save bodyweight',
                                onPressed: _savingBodyWeight ? null : _saveBodyWeight,
                                icon: _savingBodyWeight
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.save_outlined),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _markDeloadCompleted,
                              icon: const Icon(Icons.restart_alt_outlined),
                              label: const Text('Mark deload completed'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  for (final category in AchievementCategory.values) ...[
                    if (grouped[category]?.isNotEmpty == true) ...[
                      Row(
                        children: [
                          Icon(category.icon, size: 18, color: scheme.onSurface.withValues(alpha: 0.80)),
                          const SizedBox(width: 8),
                          Text(
                            category.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...grouped[category]!.map((a) => AchievementBadgeTile(progress: a)),
                      const SizedBox(height: 14),
                    ],
                  ],

                  _sectionHeader('Motivation'),
                  const SizedBox(height: 8),

                  if (_motivation != null) ...[
                    _MotivationEngineCard(result: _motivation!),
                    const SizedBox(height: 10),
                  ],

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.bolt_outlined),
                              const SizedBox(width: 8),
                              const Text(
                                'Next badge',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const Spacer(),
                              Text(
                                'Streak: $_currentStreakDays d',
                                style: TextStyle(
                                  color: scheme.onSurface.withValues(alpha: 0.70),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (next == null)
                            const Text('All achievements earned. Keep pushing your training quality.')
                          else ...[
                            Text(
                              next.definition.title,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 6),
                            LinearProgressIndicator(
                              value: next.fraction,
                              minHeight: 8,
                              backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              next.progressText,
                              style: TextStyle(
                                color: scheme.onSurface.withValues(alpha: 0.72),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Text(
                            'This week: $_workoutsThisWeek sessions. Consistency beats intensity spikes.',
                            style: TextStyle(
                              color: scheme.onSurface.withValues(alpha: 0.72),
                            ),
                          ),
                        ],
                      ),
                    ),
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

  IconData get icon {
    switch (type) {
      case _PrType.weight:
        return Icons.fitness_center_outlined;
      case _PrType.reps:
        return Icons.repeat;
      case _PrType.volume:
        return Icons.stacked_bar_chart_outlined;
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

class _MotivationEngineCard extends StatelessWidget {
  final MotivationResult result;

  const _MotivationEngineCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final type = result.type;
    final tone = result.tone;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_typeIcon(type), color: scheme.primary),
                const SizedBox(width: 8),
                const Text(
                  'Motivation Engine',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                _Chip(text: _typeLabel(type)),
                const SizedBox(width: 8),
                _Chip(text: _toneLabel(tone)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              result.message,
              style: const TextStyle(fontSize: 14, height: 1.35),
            ),
            if (result.insight != null) ...[
              const SizedBox(height: 8),
              Text(
                result.insight!,
                style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.65),
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static IconData _typeIcon(MotivationType type) {
    switch (type) {
      case MotivationType.performanceBased:
        return Icons.insights_outlined;
      case MotivationType.effortBased:
        return Icons.fitness_center_outlined;
      case MotivationType.comebackBased:
        return Icons.restart_alt_outlined;
      case MotivationType.nearGoal:
        return Icons.flag_outlined;
    }
  }

  static String _typeLabel(MotivationType type) {
    switch (type) {
      case MotivationType.performanceBased:
        return 'Performance';
      case MotivationType.effortBased:
        return 'Effort';
      case MotivationType.comebackBased:
        return 'Comeback';
      case MotivationType.nearGoal:
        return 'Near-goal';
    }
  }

  static String _toneLabel(MotivationTone tone) {
    switch (tone) {
      case MotivationTone.encouraging:
        return 'Encouraging';
      case MotivationTone.neutral:
        return 'Neutral';
      case MotivationTone.challenging:
        return 'Challenging';
    }
  }
}

class _Chip extends StatelessWidget {
  final String text;

  const _Chip({required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: scheme.onSurface.withValues(alpha: 0.80),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
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
