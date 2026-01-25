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

  String _difficulty = 'Moderate';

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(text: '0');
    _setsController = TextEditingController(text: '3');
    _repsController = TextEditingController(text: '10');
    _restTimeController = TextEditingController(text: '60');
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _restTimeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveExercise() async {
    final weight = double.tryParse(_weightController.text) ?? 0.0;
    final sets = int.tryParse(_setsController.text) ?? 3;
    final reps = int.tryParse(_repsController.text) ?? 10;
    final restTime = int.tryParse(_restTimeController.text) ?? 60;
    final notes = _notesController.text.trim();

    final record = ExerciseRecord(
      id: '${widget.exerciseName}_${DateTime.now().millisecondsSinceEpoch}',
      exerciseName: widget.exerciseName,
      bodyPart: widget.bodyPart,
      weight: weight,
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
    return AlertDialog(
      title: Text('Log ${widget.exerciseName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            const SizedBox(height: 12),
            TextField(
              controller: _setsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Sets',
                border: OutlineInputBorder(),
              ),
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
