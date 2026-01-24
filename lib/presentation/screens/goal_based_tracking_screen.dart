import 'package:flutter/material.dart';
import 'package:fitness_aura_athletix/core/models/goal.dart';
import 'package:fitness_aura_athletix/core/models/coach_suggestion.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final goals = await StorageService().loadGoals();
    final active = await StorageService().getActiveGoal();
    final suggestions = active == null
        ? <CoachSuggestion>[]
        : await StorageService().getGoalBasedSuggestions(active);

    setState(() {
      _goals = goals..sort((a, b) => b.createdAt.compareTo(a.createdAt));
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
          title: const Text('Create Goal'),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goal-Based Tracking'),
        actions: [
          IconButton(
            onPressed: _showCreateGoalDialog,
            icon: const Icon(Icons.add),
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
                  const Text(
                    'Quick goals',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton(
                        onPressed: _createPresetBench100,
                        child: const Text('Increase bench to 100kg'),
                      ),
                      ElevatedButton(
                        onPressed: _createPresetGrowLegs,
                        child: const Text('Grow legs'),
                      ),
                      ElevatedButton(
                        onPressed: _createPresetFixShoulders,
                        child: const Text('Fix weak shoulders'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Your goals',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_goals.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('No goals yet. Tap + to add one.'),
                      ),
                    )
                  else
                    ..._goals.map(
                      (g) => Card(
                        child: ListTile(
                          title: Text(g.title),
                          subtitle: Text(_goalSubtitle(g)),
                          leading: Radio<String>(
                            value: g.id,
                            groupValue: _active?.id,
                            onChanged: (_) => _setActive(g),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _deleteGoal(g),
                          ),
                          onTap: () => _setActive(g),
                        ),
                      ),
                    ),
                  const SizedBox(height: 18),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Suggestions',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_active == null)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'Select a goal to see tailored suggestions.',
                        ),
                      ),
                    )
                  else if (_suggestions.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'No suggestions yet. Log more workouts for better guidance.',
                        ),
                      ),
                    )
                  else
                    ..._suggestions.map(
                      (s) => Card(
                        child: ListTile(
                          title: Text(s.suggestion),
                          subtitle: Text(s.rationale),
                        ),
                      ),
                    ),
                ],
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
