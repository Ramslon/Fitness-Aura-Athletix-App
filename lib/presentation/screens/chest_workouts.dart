import 'package:flutter/material.dart';
import 'package:fitness_aura_athletix/services/storage_service.dart';

class ChestWorkouts extends StatelessWidget {
  const ChestWorkouts({Key? key}) : super(key: key);

  static final List<_Exercise> _exercises = [
    _Exercise(
      id: 'flat_bench_press',
      title: 'Flat Bench Press',
      description:
          'Barbell flat bench press — compound pressing movement for overall chest strength.',
      image: 'assets/images/chest_flat_bench.png',
      setsReps: '4 sets x 6-10 reps',
    ),
    _Exercise(
      id: 'incline_bench_press',
      title: 'Incline Bench Press',
      description: 'Incline bench press focuses upper chest and front delts.',
      image: 'assets/images/chest_incline_bench.png',
      setsReps: '4 sets x 6-10 reps',
    ),
    _Exercise(
      id: 'decline_bench_press',
      title: 'Decline Bench Press',
      description: 'Decline bench targets lower chest fibers.',
      image: 'assets/images/chest_decline_bench.png',
      setsReps: '3 sets x 6-10 reps',
    ),
    _Exercise(
      id: 'dumbbell_flies',
      title: 'Dumbbell Flies',
      description:
          'Dumbbell flies isolate the chest and create stretch at the bottom of the movement.',
      image: 'assets/images/chest_dumbbell_flies.png',
      setsReps: '3 sets x 10-15 reps',
    ),
    _Exercise(
      id: 'pullovers',
      title: 'Pullovers',
      description:
          'Dumbbell pullovers work the chest and lats depending on arm path.',
      image: 'assets/images/chest_pullovers.png',
      setsReps: '3 sets x 8-12 reps',
    ),
    _Exercise(
      id: 'dips',
      title: 'Dips',
      description:
          'Parallel-bar dips (lean forward) emphasize the lower chest and triceps.',
      image: 'assets/images/chest_dips.png',
      setsReps: '3 sets x 8-12 reps',
    ),
    _Exercise(
      id: 'flat_dumbbell_press',
      title: 'Flat Dumbbell Press',
      description:
          'Dumbbell press allows a greater range of motion and balanced loading.',
      image: 'assets/images/chest_flat_dumbbell_press.png',
      setsReps: '4 sets x 8-12 reps',
    ),
    _Exercise(
      id: 'incline_dumbbell_press',
      title: 'Incline Dumbbell Press',
      description: 'Upper chest emphasis with dumbbells for stability work.',
      image: 'assets/images/chest_incline_dumbbell_press.png',
      setsReps: '4 sets x 8-12 reps',
    ),
    _Exercise(
      id: 'decline_dumbbell_press',
      title: 'Decline Dumbbell Press',
      description: 'Targets lower chest with dumbbell stability demands.',
      image: 'assets/images/chest_decline_dumbbell_press.png',
      setsReps: '3 sets x 8-12 reps',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chest Workouts')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.82,
          ),
          itemCount: _exercises.length,
          itemBuilder: (context, index) {
            final ex = _exercises[index];
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ExerciseDetail(exercise: ex)),
              ),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: Image.asset(
                          ex.image,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => _imageFallback(ex.title),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ex.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            ex.setsReps,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Exercise {
  final String id;
  final String title;
  final String description;
  final String image;
  final String setsReps;

  const _Exercise({
    required this.id,
    required this.title,
    required this.description,
    required this.image,
    required this.setsReps,
  });
}

class ExerciseDetail extends StatelessWidget {
  final _Exercise exercise;

  const ExerciseDetail({Key? key, required this.exercise}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(exercise.title)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 240,
              child: Image.asset(
                exercise.image,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) =>
                    _imageFallback(exercise.title, large: true),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    exercise.setsReps,
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    exercise.description,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await showDialog<Map<String, dynamic>>(
                        context: context,
                        builder: (ctx) {
                          int duration = 30;
                          String notes = exercise.title;
                          return StatefulBuilder(builder: (c, setState) {
                            return AlertDialog(
                              title: Text('Mark "${exercise.title}" done'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextFormField(
                                    initialValue: duration.toString(),
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(labelText: 'Duration (minutes)'),
                                    onChanged: (v) => setState(() => duration = int.tryParse(v) ?? 30),
                                  ),
                                  TextFormField(
                                    initialValue: notes,
                                    decoration: const InputDecoration(labelText: 'Notes (optional)'),
                                    onChanged: (v) => setState(() => notes = v),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                ElevatedButton(
                                    onPressed: () => Navigator.pop(ctx, {'duration': duration, 'notes': notes}),
                                    child: const Text('Save')),
                              ],
                            );
                          });
                        },
                      );

                      if (result == null) return;
                      final entry = WorkoutEntry(
                        id: '${exercise.id}_${DateTime.now().millisecondsSinceEpoch}',
                        date: DateTime.now(),
                        workoutType: 'chest',
                        durationMinutes: (result['duration'] as int),
                        notes: (result['notes'] as String?),
                      );
                      await StorageService().saveEntry(entry);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${exercise.title} marked as done'),
                        ),
                      );
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Mark as Done'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _imageFallback(String title, {bool large = false}) {
  final initials = _initialsFromTitle(title);
  return Container(
    color: Colors.grey.shade200,
    alignment: Alignment.center,
    child: Container(
      width: large ? 120 : 56,
      height: large ? 120 : 56,
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: large ? 28 : 16,
          color: Colors.blueGrey.shade700,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}

String _initialsFromTitle(String title) {
  final parts = title.split(RegExp(r'\s+'))..removeWhere((s) => s.isEmpty);
  if (parts.isEmpty) return '';
  if (parts.length == 1)
    return parts.first
        .substring(0, parts.first.length >= 2 ? 2 : 1)
        .toUpperCase();
  return (parts[0][0] + parts[1][0]).toUpperCase();
}
