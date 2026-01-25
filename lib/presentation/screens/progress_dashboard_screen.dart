import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fitness_aura_athletix/services/storage_service.dart';
import 'package:fitness_aura_athletix/core/models/progressive_overload.dart';
import 'package:fitness_aura_athletix/core/models/muscle_balance.dart';
import 'package:fitness_aura_athletix/core/models/coach_suggestion.dart';
// charts_flutter is incompatible with the current Flutter SDK; use a simple
// built-in bar visualization instead to avoid build errors.
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

class ProgressDashboardScreen extends StatefulWidget {
  const ProgressDashboardScreen({super.key});

  @override
  State<ProgressDashboardScreen> createState() =>
      _ProgressDashboardScreenState();
}

class _ProgressDashboardScreenState extends State<ProgressDashboardScreen> {
  bool _loading = true;
  List<WorkoutEntry> _entries = [];
  int _totalWorkouts = 0;
  int _totalMinutes = 0;
  int _streak = 0;
  int _thisWeek = 0;
  Map<String, int> _last7DaysCounts = {};
  List<ProgressiveOverloadMetrics> _overloadMetrics = [];
  List<MuscleGroupFrequency> _muscleFrequency = [];
  List<MuscleBalanceAnalysis> _muscleBalance = [];
  List<MuscleImbalanceWarning> _imbalanceWarnings = [];
  List<CoachSuggestion> _coachSuggestions = [];
  List<AccessorySuggestion> _accessorySuggestions = [];

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    setState(() => _loading = true);
    final entries = await StorageService().loadEntries();
    final streak = await StorageService().currentStreak();
    final week = await StorageService().workoutsThisWeek();
    final overload = await StorageService().getProgressiveOverloadMetrics();
    final muscleFreq = await StorageService().getMuscleGroupFrequency();
    final muscleBalance = await StorageService().getMuscleBalanceAnalysis();
    final imbalanceWarnings = await StorageService()
        .getMuscleImbalanceWarnings();
    final coachSuggestions = await StorageService().getCoachSuggestions();
    final accessorySuggestions = await StorageService()
        .getAccessorySuggestions();

    final now = DateTime.now();
    final last7 = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      final key =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      return {'date': d, 'key': key};
    });

    final counts = <String, int>{};
    for (final item in last7) counts[item['key'] as String] = 0;

    for (final e in entries) {
      final d = DateTime(e.date.year, e.date.month, e.date.day);
      final key =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      if (counts.containsKey(key)) counts[key] = counts[key]! + 1;
    }

    setState(() {
      _entries = entries;
      _totalWorkouts = entries.length;
      _totalMinutes = entries.fold<int>(0, (s, e) => s + e.durationMinutes);
      _streak = streak;
      _thisWeek = week;
      _last7DaysCounts = counts.map((k, v) => MapEntry(k, v));
      _overloadMetrics = overload;
      _muscleFrequency = muscleFreq;
      _muscleBalance = muscleBalance;
      _imbalanceWarnings = imbalanceWarnings;
      _coachSuggestions = coachSuggestions;
      _accessorySuggestions = accessorySuggestions;
      _loading = false;
    });
  }

  Widget _metricCard(String title, String value, {Color? color}) {
    return Card(
      color: color ?? Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressiveOverloadSection() {
    if (_overloadMetrics.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '📊 Progressive Overload Tracking',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'Log more exercises to track improvements',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 Progressive Overload Tracking',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ..._overloadMetrics.take(5).map((metric) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metric.exerciseName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Row(
                      children: [
                        if (metric.hasWeightIncrease)
                          Flexible(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Chip(
                                avatar: const Text('🔼'),
                                label: Text(
                                  '${metric.weightIncreasePercentage.toStringAsFixed(1)}% weight',
                                ),
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.18),
                              ),
                            ),
                          ),
                        if (metric.hasRepIncrease)
                          Flexible(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Chip(
                                avatar: const Text('🔁'),
                                label: Text(
                                  '+${metric.currentReps - metric.previousReps} reps',
                                ),
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.secondary.withOpacity(0.18),
                              ),
                            ),
                          ),
                        if (metric.hasVolumeIncrease)
                          Flexible(
                            child: Chip(
                              avatar: const Text('📈'),
                              label: Text(
                                '${metric.volumeIncreasePercentage.toStringAsFixed(1)}% volume',
                              ),
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.tertiary.withOpacity(0.18),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMuscleFrequencySection() {
    if (_muscleFrequency.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🔁 Workout Frequency per Muscle',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'Start logging exercises to track frequency',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🔁 Workout Frequency per Muscle',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ..._muscleFrequency.map((freq) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          freq.muscleGroup,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Avg: ${freq.averageFrequencyPerWeek.toStringAsFixed(1)}x/week',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Chip(
                          label: Text(
                            '${freq.workoutCountLastWeek}x this week',
                          ),
                          backgroundColor: Colors.purple.shade100,
                        ),
                        const SizedBox(width: 8),
                        Chip(
                          label: Text(
                            '${freq.workoutCountLastMonth}x this month',
                          ),
                          backgroundColor: Colors.indigo.shade100,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMuscleBalanceSection() {
    if (_muscleBalance.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🎯 Targeted Body Part Analysis',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'Log exercises to analyze muscle balance',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🎯 Targeted Body Part Analysis',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                ..._muscleBalance.map((muscle) {
                  final isOptimal =
                      muscle.weeklyFrequency >= 2 && !muscle.isUnderTrained;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              muscle.muscleGroup,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            Chip(
                              avatar: Text(
                                muscle.weeklyFrequency >= 2 ? '✅' : '⚠️',
                              ),
                              label: Text(
                                '${muscle.weeklyFrequency}x this week',
                              ),
                              backgroundColor: isOptimal
                                  ? Colors.green.shade100
                                  : Colors.orange.shade100,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Volume: ${muscle.volumeThisWeek.toStringAsFixed(0)} kg',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  Text(
                                    'Per Session: ${muscle.averageVolumePerSession.toStringAsFixed(0)} kg',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (muscle.warning != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              border: Border.all(color: Colors.orange.shade300),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              muscle.warning!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        ],
                        if (muscle != _muscleBalance.last)
                          const Divider(height: 16),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
        if (_imbalanceWarnings.isNotEmpty) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '⚠️ Muscle Imbalance Warnings',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._imbalanceWarnings.map((warning) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Container(
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: warning.isCritical
                              ? Colors.red.shade50
                              : Colors.orange.shade50,
                          border: Border.all(
                            color: warning.isCritical
                                ? Colors.red.shade300
                                : Colors.orange.shade300,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              warning.warning ?? 'Muscle Imbalance',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: warning.isCritical
                                    ? Colors.red
                                    : Colors.orange,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              warning.suggestion,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ratio: ${warning.volumeRatio.toStringAsFixed(2)}:1',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCoachSuggestionsSection() {
    if (_coachSuggestions.isEmpty && _accessorySuggestions.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🤖 Your Personal Coach',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'Keep logging exercises to get personalized suggestions!',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        if (_coachSuggestions.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🤖 Your Personal Coach',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  ..._coachSuggestions.take(5).map((suggestion) {
                    final colorScheme = {
                      SuggestionType.increaseWeight: Colors.blue.shade50,
                      SuggestionType.increaseReps: Colors.green.shade50,
                      SuggestionType.increaseSets: Colors.purple.shade50,
                      SuggestionType.accessoryExercise: Colors.orange.shade50,
                      SuggestionType.deload: Colors.red.shade50,
                      SuggestionType.technique: Colors.amber.shade50,
                    };

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Container(
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: colorScheme[suggestion.type],
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  suggestion.emoji,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        suggestion.exerciseName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        suggestion.suggestion,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (suggestion.currentValue != null)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        suggestion.currentValue!,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      if (suggestion.recommendedValue != null)
                                        Text(
                                          '→ ${suggestion.recommendedValue}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                    ],
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              suggestion.rationale,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        if (_accessorySuggestions.isNotEmpty) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '💪 Recommended Accessories',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  ..._accessorySuggestions.map((accessory) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Container(
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          border: Border.all(color: Colors.teal.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        accessory.suggestedExercise,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        accessory.benefit,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Chip(
                                  label: Text(
                                    '${accessory.recommendedSets}x${accessory.recommendedReps}',
                                  ),
                                  backgroundColor: Colors.teal.shade100,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Why: ${accessory.reason}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.teal,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progress Dashboard')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _metricCard(
                            'Total Workouts',
                            '$_totalWorkouts',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _metricCard(
                            'Total Minutes',
                            '$_totalMinutes min',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _metricCard(
                            'Current Streak',
                            '$_streak days',
                            color: Colors.orange.shade50,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _metricCard(
                            'This Week',
                            '$_thisWeek workouts',
                            color: Colors.blue.shade50,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _buildProgressiveOverloadSection(),
                    const SizedBox(height: 12),
                    _buildMuscleFrequencySection(),
                    const SizedBox(height: 12),
                    _buildMuscleBalanceSection(),
                    const SizedBox(height: 12),
                    _buildCoachSuggestionsSection(),
                    const SizedBox(height: 18),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Last 7 Days',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextButton.icon(
                                  onPressed: _exportCsv,
                                  icon: const Icon(Icons.share),
                                  label: const Text('Export CSV'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(height: 200, child: _buildChart()),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Workout History',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            _entries.isEmpty
                                ? const Center(
                                    child: Text('No workout history yet.'),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: _entries.length,
                                    itemBuilder: (context, i) {
                                      final e = _entries.reversed.toList()[i];
                                      return ListTile(
                                        leading: const Icon(
                                          Icons.fitness_center,
                                        ),
                                        title: Text(
                                          '${e.workoutType} — ${e.durationMinutes} min',
                                        ),
                                        subtitle: Text(
                                          '${e.date.toLocal().toString().split(' ').first}',
                                        ),
                                      );
                                    },
                                  ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                            ),
                            onPressed: _loadMetrics,
                            child: const Text('Refresh'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  List<Widget> _buildLast7Bars() {
    final entries = _last7DaysCounts.entries.toList();
    final maxCount = entries
        .map((e) => e.value)
        .fold<int>(0, (p, c) => c > p ? c : p);
    final now = DateTime.now();
    final labels = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return '${['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][d.weekday % 7]}';
    });

    return List.generate(entries.length, (i) {
      final count = entries[i].value;
      final height = maxCount == 0 ? 8.0 : (8.0 + (120.0 * (count / maxCount)));
      return Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('$count', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 6),
            Container(
              width: 18,
              height: height,
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 8),
            Text(labels[i], style: const TextStyle(fontSize: 12)),
          ],
        ),
      );
    });
  }

  Widget _buildChart() {
    // Simple in-widget bar chart using existing counts to avoid external
    // chart package incompatibilities.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: _buildLast7Bars(),
    );
  }

  Future<void> _exportCsv() async {
    try {
      final rows = <String>['date,count'];
      // Ensure deterministic ordering
      final orderedKeys = _last7DaysCounts.keys.toList()..sort();
      for (final k in orderedKeys) {
        rows.add('$k,${_last7DaysCounts[k]}');
      }
      final csv = rows.join('\n');

      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/progress_${DateTime.now().toIso8601String()}.csv',
      );
      await file.writeAsString(csv);

      // Use share_plus to share the CSV file
      await SharePlus.instance.share(
        ShareParams(
          text: 'Progress data (last 7 days)',
          files: [XFile(file.path)],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }
}

class _DayCount {
  final String day;
  final int count;
  _DayCount(this.day, this.count);
}
