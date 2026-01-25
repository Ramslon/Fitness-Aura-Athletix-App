import 'package:flutter/material.dart';
import 'package:fitness_aura_athletix/services/storage_service.dart';
import 'package:fitness_aura_athletix/services/ai_gym_workout_plan.dart';

class DailyWorkoutAnalysisScreen extends StatefulWidget {
  const DailyWorkoutAnalysisScreen({super.key});

  @override
  State<DailyWorkoutAnalysisScreen> createState() =>
      _DailyWorkoutAnalysisScreenState();
}

class _DailyWorkoutAnalysisScreenState
    extends State<DailyWorkoutAnalysisScreen> {
  bool _loading = true;
  List<WorkoutEntry> _todayEntries = [];
  String _analysis = '';
  final TextEditingController _noteController = TextEditingController();
  DateTime? _currentDate;

  @override
  void initState() {
    super.initState();
    _loadTodayEntries();
  }

  Future<void> _loadTodayEntries() async {
    setState(() => _loading = true);
    final all = await StorageService().loadEntries();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todays = all.where((e) {
      final d = DateTime(e.date.year, e.date.month, e.date.day);
      return d.year == today.year &&
          d.month == today.month &&
          d.day == today.day;
    }).toList();

    // load saved analysis note for today
    final savedNote = await StorageService().loadAnalysisNoteForDate(today);

    // ask AI service for analysis (fallback to local heuristic if AI returns empty)
    final ai = await AiGymWorkoutPlan().analyze(todays);

    setState(() {
      _todayEntries = todays;
      _analysis = ai.isNotEmpty ? ai : _buildAnalysis(todays);
      _noteController.text = savedNote ?? '';
      _currentDate = today;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String _buildAnalysis(List<WorkoutEntry> entries) {
    if (entries.isEmpty)
      return 'No workout recorded for today. Log a session to get an analysis.';

    final totalMinutes = entries.fold<int>(0, (s, e) => s + e.durationMinutes);
    final types = <String, int>{};
    for (final e in entries) {
      types[e.workoutType] = (types[e.workoutType] ?? 0) + 1;
    }

    final buffer = StringBuffer();
    buffer.writeln(
      'Total time: $totalMinutes minutes across ${entries.length} entries.',
    );
    buffer.writeln('Workout types: ${types.keys.join(', ')}.');

    if (totalMinutes < 20) {
      buffer.writeln(
        'Session was short — consider adding 10–20 minutes of compound lifts or mobility.',
      );
    } else if (totalMinutes < 45) {
      buffer.writeln(
        'Good session length — keep progressive overload and ensure protein intake.',
      );
    } else {
      buffer.writeln(
        'Excellent session volume today. Watch recovery and sleep quality.',
      );
    }

    if (types.length == 1) {
      buffer.writeln(
        'Focus seems single-muscle — add at least one compound movement for balanced strength.',
      );
    }

    // Lightweight actionable tip
    buffer.writeln(
      'Tip: hydrate, log perceived exertion, and update next session targets.',
    );

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Workout Analysis')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Today',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _todayEntries.isEmpty
                                ? 'No workouts logged'
                                : '${_todayEntries.length} entries',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _todayEntries.isEmpty
                        ? Center(
                            child: Text(
                              'No workout data for today. Start a session from the home screen.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.70),
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _todayEntries.length,
                            itemBuilder: (context, i) {
                              final e = _todayEntries[i];
                              return Card(
                                child: ListTile(
                                  leading: const Icon(Icons.fitness_center),
                                  title: Text(
                                    '${e.workoutType} — ${e.durationMinutes} min',
                                  ),
                                  subtitle: e.notes != null
                                      ? Text(e.notes!)
                                      : null,
                                  trailing: Text(
                                    '${e.date.hour.toString().padLeft(2, '0')}:${e.date.minute.toString().padLeft(2, '0')}',
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Analysis',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(_analysis),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Notes editor
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Analysis Notes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _noteController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              hintText:
                                  'Add personal notes or save AI analysis here',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (_currentDate == null) return;
                                    await StorageService()
                                        .saveAnalysisNoteForDate(
                                          _currentDate!,
                                          _noteController.text.trim(),
                                        );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Saved analysis note'),
                                      ),
                                    );
                                  },
                                  child: const Text('Save Note'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () async {
                                    if (_currentDate == null) return;
                                    await StorageService()
                                        .saveAnalysisNoteForDate(
                                          _currentDate!,
                                          _analysis,
                                        );
                                    _noteController.text = _analysis;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Saved AI analysis as note',
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text('Save AI Analysis'),
                                ),
                              ),
                            ],
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
                          onPressed: _loadTodayEntries,
                          child: const Text('Refresh'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Done'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
