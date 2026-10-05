import 'package:flutter/material.dart';
import 'package:fitness_aura_athletix/core/models/goal.dart';
import 'package:fitness_aura_athletix/core/models/coach_suggestion.dart';
import 'package:fitness_aura_athletix/core/models/exercise.dart';
import 'package:fitness_aura_athletix/presentation/widgets/premium_feature_offer_card.dart';
import 'package:fitness_aura_athletix/services/storage_service.dart';

class GoalBasedTrackingScreen extends StatefulWidget {
  const GoalBasedTrackingScreen({super.key});

  @override
  State<GoalBasedTrackingScreen> createState() =>
      _GoalBasedTrackingScreenState();
}

class _GoalBasedTrackingScreenState extends State<GoalBasedTrackingScreen> {
  bool _loading = true;
  List<Goal> _goals = [];
  Goal? _active;
  List<CoachSuggestion> _suggestions = [];
  List<ExerciseRecord> _records = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final goals = await StorageService().loadGoals();
    final records = await StorageService().loadExerciseRecords();
    final active = await StorageService().getActiveGoal();
    final suggestions = active == null
        ? <CoachSuggestion>[]
        : await StorageService().getGoalBasedSuggestions(active);

    if (!mounted) return;
    setState(() {
      _goals = goals..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _records = records;
      _active = active;
      _suggestions = suggestions;
      _loading = false;
    });
  }

  Future<void> _setActive(Goal goal) async {
    await StorageService().setActiveGoal(goal.id);
    await _load();
  }

  Future<void> _deleteGoal(Goal goal) async {
    await StorageService().deleteGoal(goal.id);
    await _load();
  }

  Future<void> _createPresetBench100() async {
    final goal = Goal(
      id: 'goal_bench_100_${DateTime.now().millisecondsSinceEpoch}',
      type: GoalType.strengthTarget,
      title: 'Increase bench press to 100kg',
      exerciseName: 'Bench Press',
      targetWeightKg: 100,
      createdAt: DateTime.now(),
    );
    await StorageService().saveGoal(goal);
    await StorageService().setActiveGoal(goal.id);
    await _load();
  }

  Future<void> _createPresetGrowLegs() async {
    final goal = Goal(
      id: 'goal_grow_legs_${DateTime.now().millisecondsSinceEpoch}',
      type: GoalType.growMuscle,
      title: 'Grow legs',
      focusMuscleGroup: 'Legs',
      createdAt: DateTime.now(),
    );
    await StorageService().saveGoal(goal);
    await StorageService().setActiveGoal(goal.id);
    await _load();
  }

  Future<void> _createPresetFixShoulders() async {
    final goal = Goal(
      id: 'goal_fix_shoulders_${DateTime.now().millisecondsSinceEpoch}',
      type: GoalType.fixWeakness,
      title: 'Fix weak shoulders',
      focusMuscleGroup: 'Shoulders',
      createdAt: DateTime.now(),
    );
    await StorageService().saveGoal(goal);
    await StorageService().setActiveGoal(goal.id);
    await _load();
  }

  Future<void> _showCreateGoalDialog() async {
    GoalType type = GoalType.strengthTarget;
    final titleController = TextEditingController(
      text: 'Increase bench press to 100kg',
    );
    final exerciseController = TextEditingController(text: 'Bench Press');
    final targetController = TextEditingController(text: '100');
    String focusGroup = 'Legs';

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          icon: Icon(
            Icons.flag_rounded,
            color: Theme.of(ctx).colorScheme.primary,
          ),
          title: const Text('Create a goal'),
          contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
          content: StatefulBuilder(
            builder: (context, setLocalState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<GoalType>(
                      value: type,
                      decoration: const InputDecoration(labelText: 'Goal type'),
                      items: const [
                        DropdownMenuItem(
                          value: GoalType.strengthTarget,
                          child: Text('Strength target'),
                        ),
                        DropdownMenuItem(
                          value: GoalType.growMuscle,
                          child: Text('Grow muscle'),
                        ),
                        DropdownMenuItem(
                          value: GoalType.fixWeakness,
                          child: Text('Fix weakness'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setLocalState(() => type = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Goal title',
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (type == GoalType.strengthTarget) ...[
                      TextField(
                        controller: exerciseController,
                        decoration: const InputDecoration(
                          labelText: 'Exercise name',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: targetController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Target weight (kg)',
                        ),
                      ),
                    ] else ...[
                      DropdownButtonFormField<String>(
                        value: focusGroup,
                        decoration: const InputDecoration(
                          labelText: 'Muscle group',
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Legs', child: Text('Legs')),
                          DropdownMenuItem(
                            value: 'Shoulders',
                            child: Text('Shoulders'),
                          ),
                          DropdownMenuItem(value: 'Core', child: Text('Core')),
                          DropdownMenuItem(
                            value: 'Chest',
                            child: Text('Chest'),
                          ),
                          DropdownMenuItem(value: 'Back', child: Text('Back')),
                          DropdownMenuItem(value: 'Arms', child: Text('Arms')),
                          DropdownMenuItem(
                            value: 'Glutes',
                            child: Text('Glutes'),
                          ),
                          DropdownMenuItem(value: 'Abs', child: Text('Abs')),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          setLocalState(() => focusGroup = v);
                        },
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final now = DateTime.now();
                final goal = Goal(
                  id: 'goal_${now.millisecondsSinceEpoch}',
                  type: type,
                  title: titleController.text.trim().isEmpty
                      ? 'Goal'
                      : titleController.text.trim(),
                  exerciseName: type == GoalType.strengthTarget
                      ? exerciseController.text.trim()
                      : null,
                  targetWeightKg: type == GoalType.strengthTarget
                      ? double.tryParse(targetController.text.trim())
                      : null,
                  focusMuscleGroup: type == GoalType.strengthTarget
                      ? null
                      : focusGroup,
                  createdAt: now,
                );
                await StorageService().saveGoal(goal);
                await StorageService().setActiveGoal(goal.id);
                if (mounted) Navigator.pop(ctx);
                await _load();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    titleController.dispose();
    exerciseController.dispose();
    targetController.dispose();
  }

  Widget _sectionHeading(
    BuildContext context, {
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
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
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _quickGoal(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String detail,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 208,
      child: Material(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: scheme.primary, size: 21),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.add_circle_outline_rounded,
                  color: scheme.primary,
                  size: 19,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _goalCard(BuildContext context, Goal goal) {
    final scheme = Theme.of(context).colorScheme;
    final active = _active?.id == goal.id;
    final (icon, label) = switch (goal.type) {
      GoalType.strengthTarget => (Icons.fitness_center_rounded, 'STRENGTH'),
      GoalType.growMuscle => (Icons.trending_up_rounded, 'BUILD MUSCLE'),
      GoalType.fixWeakness => (Icons.track_changes_rounded, 'FOCUS AREA'),
    };

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: active
              ? scheme.primary.withValues(alpha: 0.75)
              : scheme.outlineVariant.withValues(alpha: 0.55),
          width: active ? 1.4 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => _setActive(goal),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (active ? scheme.primary : scheme.secondary)
                      .withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: active ? scheme.primary : scheme.secondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: (active ? scheme.primary : scheme.secondary)
                            .withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        active ? 'ACTIVE · $label' : label,
                        style: TextStyle(
                          color: active ? scheme.primary : scheme.secondary,
                          fontSize: 9,
                          letterSpacing: 0.6,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      goal.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _goalSubtitle(goal),
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Delete ${goal.title}',
                onPressed: () => _deleteGoal(goal),
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _suggestionCard(BuildContext context, CoachSuggestion suggestion) {
    final scheme = Theme.of(context).colorScheme;
    final icon = switch (suggestion.type) {
      SuggestionType.increaseWeight => Icons.fitness_center_rounded,
      SuggestionType.increaseReps => Icons.trending_up_rounded,
      SuggestionType.increaseSets => Icons.add_chart_rounded,
      SuggestionType.accessoryExercise => Icons.add_circle_outline_rounded,
      SuggestionType.deload => Icons.self_improvement_rounded,
      SuggestionType.technique => Icons.tips_and_updates_outlined,
    };

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: scheme.tertiary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: scheme.tertiary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.exerciseName,
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    suggestion.suggestion,
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    suggestion.rationale,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _estimatedOneRepMax(ExerciseRecord record) {
    var best = 0.0;
    if (record.hasSetWeights && record.hasSetReps) {
      final count = record.setWeightsKg!.length < record.setReps!.length
          ? record.setWeightsKg!.length
          : record.setReps!.length;
      for (var i = 0; i < count; i++) {
        final reps = record.setReps![i];
        if (reps > 0 && reps <= 12) {
          final estimate = record.setWeightsKg![i] * (1 + reps / 30);
          if (estimate > best) best = estimate;
        }
      }
      return best;
    }

    final reps = record.repsPerSet;
    if (record.weight > 0 && reps > 0 && reps <= 12) {
      return record.weight * (1 + reps / 30);
    }
    return 0;
  }

  Widget _advancedGoalInsights(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final goal = _active;
    if (goal == null) {
      return Text(
        'Set an active goal to see a personalized strength estimate or recent focus-area activity.',
        style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
      );
    }

    if (goal.type == GoalType.strengthTarget &&
        goal.exerciseName != null &&
        goal.exerciseName!.trim().isNotEmpty) {
      final matching = _records.where(
        (record) =>
            record.exerciseName.trim().toLowerCase() ==
            goal.exerciseName!.trim().toLowerCase(),
      );
      var estimatedMax = 0.0;
      for (final record in matching) {
        final estimate = _estimatedOneRepMax(record);
        if (estimate > estimatedMax) estimatedMax = estimate;
      }

      if (estimatedMax <= 0) {
        return Text(
          'Log a weighted set of ${goal.exerciseName} with 1–12 reps to build an estimated-strength trend toward your target.',
          style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
        );
      }

      final target = goal.targetWeightKg;
      final gap = target == null ? null : (target - estimatedMax).clamp(0, double.infinity);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estimated ${goal.exerciseName} 1RM',
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${estimatedMax.toStringAsFixed(1)} kg',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w900,
                ),
          ),
          if (target != null) ...[
            const SizedBox(height: 4),
            Text(
              gap == 0
                  ? 'Your estimated max has reached the ${target.toStringAsFixed(0)} kg target.'
                  : '${gap!.toStringAsFixed(1)} kg to the ${target.toStringAsFixed(0)} kg target.',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            'Estimate uses the Epley formula from logged sets of 12 reps or fewer; it is a training estimate, not a tested max.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      );
    }

    final focus = goal.focusMuscleGroup?.toLowerCase();
    final cutoff = DateTime.now().subtract(const Duration(days: 28));
    final recentRecords = _records.where(
      (record) =>
          record.dateRecorded.isAfter(cutoff) &&
          (focus == null || record.bodyPart.toLowerCase() == focus),
    );
    final activeDays = recentRecords
        .map(
          (record) => DateTime(
            record.dateRecorded.year,
            record.dateRecorded.month,
            record.dateRecorded.day,
          ),
        )
        .toSet()
        .length;
    final label = goal.focusMuscleGroup ?? 'all training';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent $label training',
          style: TextStyle(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '$activeDays active ${activeDays == 1 ? 'day' : 'days'} in the last 28 days',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Use this as a consistency check for your current ${goal.type == GoalType.growMuscle ? 'muscle-building' : 'focus-area'} goal.',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goal-Based Tracking'),
        actions: [
          IconButton(
            tooltip: 'Create goal',
            onPressed: _showCreateGoalDialog,
            icon: const Icon(Icons.add_rounded),
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
                              scheme.primary.withValues(alpha: 0.18),
                              scheme.surfaceContainerHighest.withValues(
                                alpha: 0.55,
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
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: scheme.primary.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Icon(
                                Icons.flag_rounded,
                                color: scheme.primary,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Train with a clear target',
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
                                    'Choose a focus and get coaching suggestions shaped around your training.',
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
                      const SizedBox(height: 24),
                      _sectionHeading(
                        context,
                        title: 'Quick start',
                        subtitle: 'Add a goal with one tap',
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 76,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _quickGoal(
                              context,
                              icon: Icons.fitness_center_rounded,
                              title: 'Bench press',
                              detail: 'Reach 100 kg',
                              onTap: _createPresetBench100,
                            ),
                            const SizedBox(width: 10),
                            _quickGoal(
                              context,
                              icon: Icons.directions_run_rounded,
                              title: 'Build legs',
                              detail: 'Grow leg strength',
                              onTap: _createPresetGrowLegs,
                            ),
                            const SizedBox(width: 10),
                            _quickGoal(
                              context,
                              icon: Icons.track_changes_rounded,
                              title: 'Shoulders',
                              detail: 'Focus on weak areas',
                              onTap: _createPresetFixShoulders,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 26),
                      _sectionHeading(
                        context,
                        title: 'Your goals',
                        subtitle: _goals.isEmpty
                            ? 'Create a goal to personalize your training'
                            : '${_goals.length} ${_goals.length == 1 ? 'goal' : 'goals'} · tap one to set your active focus',
                        trailing: TextButton.icon(
                          onPressed: _showCreateGoalDialog,
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Add'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_goals.isEmpty)
                        Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.flag_outlined,
                                  color: scheme.onSurfaceVariant,
                                  size: 28,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    'No goals yet. Pick a quick start above or create a custom goal.',
                                    style: TextStyle(
                                      color: scheme.onSurfaceVariant,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ..._goals.map(
                          (goal) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _goalCard(context, goal),
                          ),
                        ),
                      const SizedBox(height: 16),
                      _sectionHeading(
                        context,
                        title: 'Coach insights',
                        subtitle: _active == null
                            ? 'Choose an active goal to see tailored advice'
                            : 'Recommendations for ${_active!.title}',
                        trailing: Icon(
                          Icons.auto_awesome_rounded,
                          color: scheme.tertiary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_active == null)
                        Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Text(
                              'Select one of your goals to see training suggestions tailored to that focus.',
                              style: TextStyle(
                                color: scheme.onSurfaceVariant,
                                height: 1.35,
                              ),
                            ),
                          ),
                        )
                      else if (_suggestions.isEmpty)
                        Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.insights_outlined,
                                  color: scheme.tertiary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Log more workouts to unlock useful guidance for this goal.',
                                    style: TextStyle(
                                      color: scheme.onSurfaceVariant,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ..._suggestions.map(
                          (suggestion) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _suggestionCard(context, suggestion),
                          ),
                        ),
                      const SizedBox(height: 10),
                      PremiumFeatureOfferCard(
                        title: 'Advanced goal planning',
                        description:
                            'Turn your active target into a more structured training plan with deeper progress context.',
                        icon: Icons.flag_rounded,
                        benefits: const [
                          'Projected strength milestones based on logged lifts.',
                          'More detailed weekly focus and goal-progress insights.',
                          'Advanced coach guidance for your selected goal.',
                        ],
                        unlockedContent: _advancedGoalInsights(context),
                        onAccessChanged: _load,
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  static String _goalSubtitle(Goal g) {
    switch (g.type) {
      case GoalType.strengthTarget:
        final target = g.targetWeightKg == null
            ? ''
            : ' → ${g.targetWeightKg!.toStringAsFixed(0)}kg';
        return '${g.exerciseName ?? 'Exercise'}$target';
      case GoalType.growMuscle:
        return 'Focus: ${g.focusMuscleGroup ?? 'Muscle'}';
      case GoalType.fixWeakness:
        return 'Fix: ${g.focusMuscleGroup ?? 'Muscle'}';
    }
  }
}
