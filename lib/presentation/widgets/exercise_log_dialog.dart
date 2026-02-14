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
  late TextEditingController _timeUnderTensionController;
  late TextEditingController _tempoController;
  late TextEditingController _difficultyVariationController;
  late TextEditingController _restTimeController;
  late TextEditingController _notesController;

  late List<TextEditingController> _setWeightControllers;
  late List<TextEditingController> _setRepsControllers;

  static const int _maxSets = 5;

  bool _usesWeight = true;
  int _sets = 3;

  bool _didPrefill = false;
  int? _suggestedSetIndex;

  late DateTime _performedOn;

  String _difficulty = 'Moderate';

  @override
  void initState() {
    super.initState();
    _performedOn = DateTime.now();
    _weightController = TextEditingController(text: '0');
    _timeUnderTensionController = TextEditingController(text: '');
    _tempoController = TextEditingController(text: '');
    _difficultyVariationController = TextEditingController(text: '');
    _restTimeController = TextEditingController(text: '60');
    _notesController = TextEditingController();

    _setWeightControllers = List<TextEditingController>.generate(
      _maxSets,
      (_) => TextEditingController(text: '0'),
    );

    _setRepsControllers = List<TextEditingController>.generate(
      _maxSets,
      (_) => TextEditingController(text: '10'),
    );

    // Heuristic: auto-disable weight input for likely bodyweight movements.
    if (_isLikelyBodyweight(widget.exerciseName)) {
      _usesWeight = false;
      _weightController.text = '0';
    }

    // Smart auto-fill from last time.
    _prefillFromLastRecord();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _timeUnderTensionController.dispose();
    _tempoController.dispose();
    _difficultyVariationController.dispose();
    _restTimeController.dispose();
    _notesController.dispose();
    for (final c in _setWeightControllers) {
      c.dispose();
    }
    for (final c in _setRepsControllers) {
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

  int _parsedSetsClamped() => _sets.clamp(1, _maxSets);

  Future<void> _prefillFromLastRecord() async {
    try {
      final records = await StorageService().loadExerciseRecords();
      final matching = records
          .where((r) => r.exerciseName == widget.exerciseName)
          .toList()
        ..sort((a, b) => b.dateRecorded.compareTo(a.dateRecorded));
      if (matching.isEmpty) return;
      if (!mounted) return;

      final last = matching.first;
      if (_didPrefill) return;

      setState(() {
        _didPrefill = true;

        _difficulty = last.difficulty;
        _restTimeController.text = last.restTime.toString();

        final usesWeight = last.effectiveWeightKg > 0;
        _usesWeight = usesWeight;
        if (!usesWeight) {
          _weightController.text = '0';
        } else {
          _weightController.text = last.effectiveWeightKg.toStringAsFixed(1);
        }

        final sets = last.sets.clamp(1, _maxSets);
        _sets = sets;

        final repsBySet = last.setReps;
        for (var i = 0; i < sets; i++) {
          final reps = repsBySet != null && i < repsBySet.length
              ? repsBySet[i]
              : last.repsPerSet;
          _setRepsControllers[i].text = reps.toString();
        }

        if (usesWeight) {
          final weightsBySet = last.setWeightsKg;
          for (var i = 0; i < sets; i++) {
            final w = weightsBySet != null && i < weightsBySet.length
                ? weightsBySet[i]
                : last.effectiveWeightKg;
            _setWeightControllers[i].text = w.toStringAsFixed(1);
          }
        }

        if (!usesWeight) {
          if (last.timeUnderTensionSeconds != null) {
            _timeUnderTensionController.text =
                last.timeUnderTensionSeconds.toString();
          }
          _tempoController.text = last.tempo ?? '';
          _difficultyVariationController.text = last.difficultyVariation ?? '';
        }

        // Simple suggestion: if last time was easy, bump last set.
        _suggestedSetIndex = null;
        if (last.difficulty.toLowerCase() == 'easy') {
          final idx = sets - 1;
          if (idx >= 0) {
            if (usesWeight) {
              final current =
                  double.tryParse(_setWeightControllers[idx].text) ??
                      last.effectiveWeightKg;
              _setWeightControllers[idx].text =
                  (current + 2.5).toStringAsFixed(1);
            } else {
              final current = int.tryParse(_setRepsControllers[idx].text) ??
                  last.repsPerSet;
              _setRepsControllers[idx].text = (current + 1).toString();
            }
            _suggestedSetIndex = idx;
          }
        }
      });
    } catch (_) {
      // Best-effort only.
    }
  }

  Future<void> _pickPerformedOnDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initial = DateTime(
      _performedOn.year,
      _performedOn.month,
      _performedOn.day,
    );

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(today) ? today : initial,
      firstDate: DateTime(now.year - 5, 1, 1),
      lastDate: today,
    );

    if (picked == null) return;
    if (!mounted) return;
    setState(() {
      _performedOn = picked;
    });
  }

  Future<void> _saveExercise() async {
    final sets = _parsedSetsClamped();
    final restTime = int.tryParse(_restTimeController.text) ?? 60;
    final notes = _notesController.text.trim();

    final timeUnderTensionSeconds = int.tryParse(
      _timeUnderTensionController.text.trim(),
    );
    final tempo = _tempoController.text.trim();
    final difficultyVariation = _difficultyVariationController.text.trim();

    final setReps = <int>[];
    for (var i = 0; i < sets; i++) {
      final r = int.tryParse(_setRepsControllers[i].text) ?? 10;
      setReps.add(r);
    }
    final repsPerSet = setReps.isNotEmpty ? setReps.first : 10;

    final List<double>? setWeightsKg;
    final double weight;

    if (!_usesWeight) {
      weight = 0.0;
      setWeightsKg = null;
    } else {
      final weights = <double>[];
      for (var i = 0; i < sets; i++) {
        final w = double.tryParse(_setWeightControllers[i].text) ??
            (double.tryParse(_weightController.text) ?? 0.0);
        weights.add(w);
      }
      setWeightsKg = weights;
      var maxW = 0.0;
      for (final w in weights) {
        if (w > maxW) maxW = w;
      }
      weight = maxW;
    }

    final now = DateTime.now();
    final performedAt = DateTime(
      _performedOn.year,
      _performedOn.month,
      _performedOn.day,
      now.hour,
      now.minute,
      now.second,
      now.millisecond,
      now.microsecond,
    );

    final record = ExerciseRecord(
      id: '${widget.exerciseName}_${DateTime.now().millisecondsSinceEpoch}',
      exerciseName: widget.exerciseName,
      bodyPart: widget.bodyPart,
      weight: weight,
      setWeightsKg: setWeightsKg,
      setReps: setReps,
      sets: sets,
      repsPerSet: repsPerSet,
      timeUnderTensionSeconds: _usesWeight
          ? null
          : (timeUnderTensionSeconds != null && timeUnderTensionSeconds > 0
            ? timeUnderTensionSeconds
            : null),
      tempo: _usesWeight ? null : (tempo.isEmpty ? null : tempo),
      difficultyVariation:
          _usesWeight ? null : (difficultyVariation.isEmpty ? null : difficultyVariation),
      restTime: restTime,
      difficulty: _difficulty,
      notes: notes.isEmpty ? null : notes,
      dateRecorded: performedAt,
    );

    await StorageService().saveExerciseRecord(record);
    ExerciseInsights.invalidateCache();
    DailyWorkoutAnalysisEngine.invalidateCache();
    await WorkoutSessionService.instance.markExerciseLogged(record.bodyPart);
    if (!mounted) return;

    Navigator.pop<int>(context, restTime);
  }

  void _onDeleteSet(int index) {
    final sets = _parsedSetsClamped();
    if (sets <= 1) return;

    setState(() {
      for (var i = index; i < sets - 1; i++) {
        _setRepsControllers[i].text = _setRepsControllers[i + 1].text;
        _setWeightControllers[i].text = _setWeightControllers[i + 1].text;
      }
      _setRepsControllers[sets - 1].text = '10';
      _setWeightControllers[sets - 1].text = _usesWeight ? '0' : '0';
      _sets = (sets - 1).clamp(1, _maxSets);
      if (_suggestedSetIndex != null && _suggestedSetIndex! >= _sets) {
        _suggestedSetIndex = null;
      }
    });
  }

  void _onDuplicateSet(int index) {
    final sets = _parsedSetsClamped();
    if (sets >= _maxSets) return;

    setState(() {
      for (var i = sets; i > index + 1; i--) {
        _setRepsControllers[i].text = _setRepsControllers[i - 1].text;
        _setWeightControllers[i].text = _setWeightControllers[i - 1].text;
      }
      _setRepsControllers[index + 1].text = _setRepsControllers[index].text;
      _setWeightControllers[index + 1].text =
          _setWeightControllers[index].text;
      _sets = (sets + 1).clamp(1, _maxSets);
      if (_suggestedSetIndex != null && _suggestedSetIndex! >= index + 1) {
        _suggestedSetIndex = _suggestedSetIndex! + 1;
      }
    });
  }

  void _copyLastSet() {
    final sets = _parsedSetsClamped();
    if (sets >= _maxSets) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum is 5 sets.')),
      );
      return;
    }

    setState(() {
      _setRepsControllers[sets].text = _setRepsControllers[sets - 1].text;
      _setWeightControllers[sets].text = _setWeightControllers[sets - 1].text;
      _sets = (sets + 1).clamp(1, _maxSets);
      if (_suggestedSetIndex != null && _suggestedSetIndex! >= sets) {
        _suggestedSetIndex = _suggestedSetIndex! + 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sets = _parsedSetsClamped();
    final dateLabel = MaterialLocalizations.of(context).formatMediumDate(
      _performedOn,
    );

    return AlertDialog(
      title: Text('Log ${widget.exerciseName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: _pickPerformedOnDate,
              icon: const Icon(Icons.calendar_today),
              label: Text('Workout date: $dateLabel'),
            ),
            const SizedBox(height: 12),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Track weight'),
              subtitle: const Text('Turn off for bodyweight exercises.'),
              value: _usesWeight,
              onChanged: (v) {
                setState(() {
                  _usesWeight = v;
                  if (!v) {
                    _weightController.text = '0';
                  }
                });
              },
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<int>(
              value: sets,
              decoration: const InputDecoration(
                labelText: 'Sets',
                border: OutlineInputBorder(),
              ),
              items: List<DropdownMenuItem<int>>.generate(
                _maxSets,
                (i) {
                  final v = i + 1;
                  return DropdownMenuItem<int>(value: v, child: Text('$v'));
                },
              ),
              onChanged: (value) {
                setState(() {
                  _sets = (value ?? 3).clamp(1, _maxSets);
                });
              },
            ),
            const SizedBox(height: 12),

            Column(
              children: List<Widget>.generate(sets, (i) {
                final suggested = _suggestedSetIndex == i;
                return Padding(
                  padding: EdgeInsets.only(bottom: i == sets - 1 ? 0 : 10),
                  child: Dismissible(
                    key: ValueKey('set_$i'),
                    direction: DismissDirection.horizontal,
                    confirmDismiss: (direction) async {
                      if (direction == DismissDirection.endToStart) {
                        _onDeleteSet(i);
                      } else {
                        _onDuplicateSet(i);
                      }
                      return false;
                    },
                    background: Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      child: const Row(
                        children: [
                          Icon(Icons.copy),
                          SizedBox(width: 8),
                          Text('Duplicate'),
                        ],
                      ),
                    ),
                    secondaryBackground: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('Delete'),
                          SizedBox(width: 8),
                          Icon(Icons.delete),
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _setRepsControllers[i],
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: suggested
                                  ? 'Set ${i + 1} reps (suggested)'
                                  : 'Set ${i + 1} reps',
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        if (_usesWeight) const SizedBox(width: 10),
                        if (_usesWeight)
                          Expanded(
                            child: TextField(
                              controller: _setWeightControllers[i],
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: InputDecoration(
                                labelText: suggested
                                    ? 'Set ${i + 1} kg (suggested)'
                                    : 'Set ${i + 1} kg',
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: _copyLastSet,
                child: const Text('Copy Last Set'),
              ),
            ),
            const SizedBox(height: 12),
            if (!_usesWeight)
              TextField(
                controller: _timeUnderTensionController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Time under tension (seconds, total)',
                  border: OutlineInputBorder(),
                ),
              ),
            if (!_usesWeight) const SizedBox(height: 12),
            if (!_usesWeight)
              TextField(
                controller: _tempoController,
                decoration: const InputDecoration(
                  labelText: 'Tempo (optional, e.g., 3-1-1)',
                  border: OutlineInputBorder(),
                ),
              ),
            if (!_usesWeight) const SizedBox(height: 12),
            if (!_usesWeight)
              TextField(
                controller: _difficultyVariationController,
                decoration: const InputDecoration(
                  labelText: 'Difficulty variation (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            if (!_usesWeight) const SizedBox(height: 12),
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
