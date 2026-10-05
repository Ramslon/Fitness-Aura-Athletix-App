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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Bodyweight saved.')));
  }

  Future<void> _markDeloadCompleted() async {
    await AchievementService().markDeloadCompleted();
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Deload marked completed.')));
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

  Widget _sectionHeader(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: scheme.primary, size: 20),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _personalRecordCard(BuildContext context, _PrAlert record) {
    final scheme = Theme.of(context).colorScheme;
    final detail = switch (record.type) {
      _PrType.weight => '+${record.delta.toStringAsFixed(1)} kg personal best',
      _PrType.reps => '+${record.delta.toStringAsFixed(0)} reps personal best',
      _PrType.volume =>
        '+${record.delta.toStringAsFixed(0)} volume personal best',
    };
    final value = switch (record.type) {
      _PrType.weight => '${record.value.toStringAsFixed(1)} kg',
      _PrType.reps => '${record.value.toStringAsFixed(0)} reps',
      _PrType.volume => '${record.value.toStringAsFixed(0)} volume',
    };

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: scheme.tertiary.withValues(alpha: 0.26)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: scheme.tertiary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(record.icon, color: scheme.tertiary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.exerciseName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${record.bodyPart} · ${record.dateText}',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    detail,
                    style: TextStyle(
                      color: scheme.tertiary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyNotice(
    BuildContext context, {
    required IconData icon,
    required String message,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(icon, color: scheme.onSurfaceVariant, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final grouped = _groupedAchievements();
    final next = _nextAchievement();
    final earnedCount = _achievements.where((a) => a.isEarned).length;

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
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: LinearGradient(
                            colors: [
                              scheme.primary.withValues(alpha: 0.20),
                              scheme.tertiary.withValues(alpha: 0.10),
                              scheme.surfaceContainerHighest.withValues(
                                alpha: 0.48,
                              ),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: scheme.primary.withValues(alpha: 0.20),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: scheme.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Icon(
                                Icons.emoji_events_rounded,
                                color: scheme.primary,
                                size: 29,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Every rep moves you forward',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: scheme.onSurface,
                                          fontWeight: FontWeight.w900,
                                        ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    'Celebrate new records, build consistency, and keep your next milestone in sight.',
                                    style: TextStyle(
                                      color: scheme.onSurfaceVariant,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _OverviewMetric(
                              icon: Icons.emoji_events_outlined,
                              value: '$earnedCount',
                              label: 'BADGES EARNED',
                              color: scheme.tertiary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _OverviewMetric(
                              icon: Icons.local_fire_department_outlined,
                              value: '$_currentStreakDays',
                              label: 'DAY STREAK',
                              color: scheme.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _OverviewMetric(
                              icon: Icons.calendar_today_outlined,
                              value: '$_workoutsThisWeek',
                              label: 'THIS WEEK',
                              color: scheme.secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),
                      _sectionHeader(
                        context,
                        title: 'Personal records',
                        subtitle: 'Recent bests from the last 14 days',
                        icon: Icons.military_tech_rounded,
                      ),
                      const SizedBox(height: 12),
                      if (_prAlerts.isEmpty)
                        _emptyNotice(
                          context,
                          icon: Icons.fitness_center_outlined,
                          message:
                              'No new records yet. Keep logging your workouts and your next PR will show up here.',
                        )
                      else
                        ..._prAlerts.map(
                          (record) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _personalRecordCard(context, record),
                          ),
                        ),
                      const SizedBox(height: 16),
                      _sectionHeader(
                        context,
                        title: 'Achievements',
                        subtitle:
                            '$earnedCount of ${_achievements.length} badges earned',
                        icon: Icons.workspace_premium_outlined,
                      ),
                      const SizedBox(height: 12),
                      Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Personalize your milestones',
                                style: TextStyle(
                                  color: scheme.onSurface,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Bodyweight is used to calculate relative strength achievements.',
                                style: TextStyle(
                                  color: scheme.onSurfaceVariant,
                                  fontSize: 12,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _bodyWeightController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      decoration: const InputDecoration(
                                        labelText: 'Bodyweight (kg)',
                                        hintText: 'e.g. 75.0',
                                        prefixIcon: Icon(
                                          Icons.monitor_weight_outlined,
                                        ),
                                      ),
                                      onSubmitted: (_) => _saveBodyWeight(),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  FilledButton(
                                    onPressed: _savingBodyWeight
                                        ? null
                                        : _saveBodyWeight,
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size(52, 52),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                      ),
                                    ),
                                    child: _savingBodyWeight
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.save_outlined),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              OutlinedButton.icon(
                                onPressed: _markDeloadCompleted,
                                icon: const Icon(Icons.restart_alt_rounded),
                                label: const Text('Mark deload completed'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      for (final category in AchievementCategory.values) ...[
                        if (grouped[category]?.isNotEmpty == true) ...[
                          Padding(
                            padding: const EdgeInsets.only(left: 2, bottom: 10),
                            child: Row(
                              children: [
                                Icon(
                                  category.icon,
                                  size: 18,
                                  color: scheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  category.title,
                                  style: TextStyle(
                                    color: scheme.onSurface,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${grouped[category]!.where((a) => a.isEarned).length}/${grouped[category]!.length}',
                                  style: TextStyle(
                                    color: scheme.onSurfaceVariant,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...grouped[category]!.map(
                            (achievement) =>
                                AchievementBadgeTile(progress: achievement),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],
                      const SizedBox(height: 8),
                      _sectionHeader(
                        context,
                        title: 'Your next milestone',
                        subtitle: 'A small target to keep progress moving',
                        icon: Icons.flag_outlined,
                      ),
                      const SizedBox(height: 12),
                      Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      next?.definition.title ??
                                          'All achievements earned',
                                      style: TextStyle(
                                        color: scheme.onSurface,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '$_currentStreakDays day streak',
                                    style: TextStyle(
                                      color: scheme.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              if (next != null) ...[
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(99),
                                  child: LinearProgressIndicator(
                                    value: next.fraction,
                                    minHeight: 8,
                                    color: scheme.primary,
                                    backgroundColor:
                                        scheme.surfaceContainerHighest,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  next.progressText,
                                  style: TextStyle(
                                    color: scheme.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                              ] else ...[
                                const SizedBox(height: 8),
                                Text(
                                  'All badges are yours. Keep building strength and consistency.',
                                  style: TextStyle(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Text(
                                'This week: $_workoutsThisWeek sessions. Consistency beats intensity spikes.',
                                style: TextStyle(
                                  color: scheme.onSurfaceVariant,
                                  fontSize: 12,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),
                      _sectionHeader(
                        context,
                        title: 'Progressive overload',
                        subtitle: 'Exercises where you are building momentum',
                        icon: Icons.trending_up_rounded,
                      ),
                      const SizedBox(height: 12),
                      if (_overloadStreaks.isEmpty)
                        _emptyNotice(
                          context,
                          icon: Icons.insights_outlined,
                          message:
                              'No improving streaks yet. Log progressive sessions to track your momentum here.',
                        )
                      else
                        ..._overloadStreaks
                            .take(10)
                            .map(
                              (streak) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Card(
                                  margin: EdgeInsets.zero,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 15,
                                      vertical: 5,
                                    ),
                                    leading: Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: scheme.primary.withValues(
                                          alpha: 0.13,
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(
                                        Icons.trending_up_rounded,
                                        color: scheme.primary,
                                      ),
                                    ),
                                    title: Text(
                                      streak.exerciseName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${streak.bodyPart} · ${streak.lastImprovementText}',
                                    ),
                                    trailing: Text(
                                      '${streak.streak}×',
                                      style: TextStyle(
                                        color: scheme.primary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                      if (_motivation != null) ...[
                        const SizedBox(height: 16),
                        _sectionHeader(
                          context,
                          title: 'Motivation',
                          subtitle:
                              'A little perspective for your next session',
                          icon: Icons.bolt_rounded,
                        ),
                        const SizedBox(height: 12),
                        _MotivationEngineCard(result: _motivation!),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _OverviewMetric({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 13),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 7),
          Text(
            value,
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.45,
            ),
          ),
        ],
      ),
    );
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

    final w = r.effectiveWeightKg;
    final volume = r.volumeLoadKg;
    final isRecent = r.dateRecorded.isAfter(cutoff);

    // Weight PR
    if (w > prevBestWeight) {
      if (isRecent) {
        alerts.add(
          _PrAlert(
            exerciseName: r.exerciseName,
            bodyPart: r.bodyPart,
            type: _PrType.weight,
            value: w,
            delta: (w - prevBestWeight),
            date: r.dateRecorded,
          ),
        );
      }
      bestWeightBefore[key] = w;
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
      final curVol = cur.volumeLoadKg;
      final prevVol = prev.volumeLoadKg;
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
