import 'package:flutter/material.dart';
import 'package:fitness_aura_athletix/core/models/exercise.dart';
import 'package:fitness_aura_athletix/services/storage_service.dart';
import 'package:fitness_aura_athletix/presentation/widgets/exercise_insights.dart';
import 'package:fitness_aura_athletix/services/workout_session_service.dart';
import 'package:fitness_aura_athletix/services/daily_workout_analysis_engine.dart';

class ExerciseLogDialog extends StatefulWidget {
  final String exerciseName;
  final String bodyPart;

  const ExerciseLogDialog({
    Key? key,
    required this.exerciseName,
    required this.bodyPart,
  }) : super(key: key);

  @override
  State<ExerciseLogDialog> createState() => _ExerciseLogDialogState();
}

class _ExerciseLogDialogState extends State<ExerciseLogDialog> {
  late TextEditingController _weightController;
  late TextEditingController _setsController;
  late TextEditingController _repsController;
  late TextEditingController _restTimeController;
  late TextEditingController _notesController;

  late List<TextEditingController> _setWeightControllers;

  bool _usesWeight = true;
  bool _useProgressiveSetWeights = false;

  String _difficulty = 'Moderate';

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(text: '0');
    _setsController = TextEditingController(text: '3');
    _repsController = TextEditingController(text: '10');
    _restTimeController = TextEditingController(text: '60');
    _notesController = TextEditingController();

    _setWeightControllers = List<TextEditingController>.generate(
      4,
      (_) => TextEditingController(text: '0'),
    );

    // Heuristic: auto-disable weight input for likely bodyweight movements.
    if (_isLikelyBodyweight(widget.exerciseName)) {
      _usesWeight = false;
      _weightController.text = '0';
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _restTimeController.dispose();
    _notesController.dispose();
    for (final c in _setWeightControllers) {
      c.dispose();
    }
    super.dispose();
  }

  static bool _isLikelyBodyweight(String name) {
    final n = name.toLowerCase();
    const keywords = <String>[
      'push-up',
      'push up',
      'pull-up',
      'pull up',
      'chin-up',
      'chin up',
      'plank',
      'burpee',
      'crunch',
      'sit-up',
      'sit up',
      'mountain climber',
      'jumping jack',
      'lunge',
      'bodyweight',
      'body weight',
      'air squat',
      'pistol squat',
      'leg raise',
    ];
    return keywords.any(n.contains);
  }

  int _parsedSetsClamped() {
    final sets = int.tryParse(_setsController.text) ?? 3;
    if (_useProgressiveSetWeights) return sets.clamp(1, 4);
    return sets.clamp(1, 99);
  }

  void _applyProgressiveDefaultsIfNeeded() {
    if (!_useProgressiveSetWeights) return;
    final sets = _parsedSetsClamped();
    // Prefer 3–4 sets when using progressive weights.
    if (sets < 3) {
      _setsController.text = '3';
    } else if (sets > 4) {
      _setsController.text = '4';
    }
  }

  Future<void> _saveExercise() async {
    final sets = _parsedSetsClamped();
    final reps = int.tryParse(_repsController.text) ?? 10;
    final restTime = int.tryParse(_restTimeController.text) ?? 60;
    final notes = _notesController.text.trim();

    final List<double>? setWeightsKg;
    final double weight;

    if (!_usesWeight) {
      weight = 0.0;
      setWeightsKg = null;
    } else if (_useProgressiveSetWeights) {
      final weights = <double>[];
      for (var i = 0; i < sets; i++) {
        final w = double.tryParse(_setWeightControllers[i].text) ?? 0.0;
        weights.add(w);
      }
      setWeightsKg = weights;
      // Keep the top weight as the summary for back-compat.
      var maxW = 0.0;
      for (final w in weights) {
        if (w > maxW) maxW = w;
      }
      weight = maxW;
    } else {
      weight = double.tryParse(_weightController.text) ?? 0.0;
      setWeightsKg = null;
    }

    final record = ExerciseRecord(
      id: '${widget.exerciseName}_${DateTime.now().millisecondsSinceEpoch}',
      exerciseName: widget.exerciseName,
      bodyPart: widget.bodyPart,
      weight: weight,
      setWeightsKg: setWeightsKg,
      sets: sets,
      repsPerSet: reps,
      restTime: restTime,
      difficulty: _difficulty,
      notes: notes.isEmpty ? null : notes,
      dateRecorded: DateTime.now(),
    );

    await StorageService().saveExerciseRecord(record);
    ExerciseInsights.invalidateCache();
    DailyWorkoutAnalysisEngine.invalidateCache();
    await WorkoutSessionService.instance.markExerciseLogged(record.bodyPart);
    if (!mounted) return;

    Navigator.pop(context, true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${widget.exerciseName} logged successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sets = _parsedSetsClamped();

    return AlertDialog(
      title: Text('Log ${widget.exerciseName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Track weight'),
              subtitle: const Text('Turn off for bodyweight exercises.'),
              value: _usesWeight,
              onChanged: (v) {
                setState(() {
                  _usesWeight = v;
                  if (!v) {
                    _useProgressiveSetWeights = false;
                    _weightController.text = '0';
                  }
                });
              },
            ),
            const SizedBox(height: 12),

            if (_usesWeight)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Progressive weight (3–4 sets)'),
                subtitle: const Text('Increase weight each set (up to set 4).'),
                value: _useProgressiveSetWeights,
                onChanged: (v) {
                  setState(() {
                    _useProgressiveSetWeights = v;
                    _applyProgressiveDefaultsIfNeeded();
                  });
                },
              ),
            if (_usesWeight) const SizedBox(height: 8),

            if (_usesWeight && !_useProgressiveSetWeights)
              TextField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  border: OutlineInputBorder(),
                ),
              ),
            if (_usesWeight && _useProgressiveSetWeights)
              Column(
                children: List<Widget>.generate(sets, (i) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: i == sets - 1 ? 0 : 10),
                    child: TextField(
                      controller: _setWeightControllers[i],
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Set ${i + 1} weight (kg)',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  );
                }),
              ),

            if (_usesWeight) const SizedBox(height: 12),
            TextField(
              controller: _setsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Sets',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) {
                if (_useProgressiveSetWeights) {
                  setState(() {
                    _applyProgressiveDefaultsIfNeeded();
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _repsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Reps per set',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _restTimeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Rest time (seconds)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _difficulty,
              items: [
                'Easy',
                'Moderate',
                'Hard',
              ].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
              onChanged: (value) {
                setState(() => _difficulty = value ?? 'Moderate');
              },
              decoration: const InputDecoration(
                labelText: 'Difficulty / RPE',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _saveExercise, child: const Text('Save')),
      ],
    );
  }
}
