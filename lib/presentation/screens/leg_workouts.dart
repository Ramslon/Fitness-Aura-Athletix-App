import 'package:flutter/material.dart';
import 'package:fitness_aura_athletix/services/storage_service.dart';

class LegWorkouts extends StatelessWidget {
  const LegWorkouts({Key? key}) : super(key: key);

  static final List<_Exercise> _exercises = [
    _Exercise(
      id: 'barbell_back_squat',
      title: 'Barbell Back Squat',
      description: 'Classic compound squat for overall leg strength.',
      image: 'assets/images/leg_back_squat.png',
      setsReps: '4 sets x 5-8 reps',
    ),
    _Exercise(
      id: 'goblet_squat',
      title: 'Goblet Squat',
      description: 'Goblet squat for squat pattern and quad development.',
      image: 'assets/images/leg_goblet_squat.png',
      setsReps: '3 sets x 8-12 reps',
    ),
    _Exercise(
      id: 'front_squat',
      title: 'Front Squat',
      description: 'Front-loaded squat emphasizing quads and upright torso.',
      image: 'assets/images/leg_front_squat.png',
      setsReps: '3-4 sets x 5-8 reps',
    ),
    _Exercise(
      id: 'sumo_squat',
      title: 'Sumo Squat',
      description: 'Wider stance squat targeting inner quads and glutes.',
      image: 'assets/images/leg_sumo_squat.png',
      setsReps: '3 sets x 8-12 reps',
    ),

    // Deadlift variations
    _Exercise(
      id: 'romanian_deadlift',
      title: 'Romanian Deadlift',
      description: 'RDL focuses hamstrings and glute-hamstring tie-in.',
      image: 'assets/images/leg_romanian_deadlift.png',
      setsReps: '3 sets x 6-10 reps',
    ),
    _Exercise(
      id: 'conventional_deadlift',
      title: 'Conventional Deadlift',
      description: 'Heavy posterior chain builder for overall strength.',
      image: 'assets/images/leg_conventional_deadlift.png',
      setsReps: '3-4 sets x 3-6 reps',
    ),

    // Lunges
    _Exercise(
      id: 'walking_lunge',
      title: 'Walking Lunges',
      description: 'Walking lunges build unilateral strength and balance.',
      image: 'assets/images/leg_walking_lunge.png',
      setsReps: '3 sets x 10-12 steps',
    ),
    _Exercise(
      id: 'reverse_lunge',
      title: 'Reverse Lunge',
      description: 'Reverse lunges are knee-friendly and focus glutes.',
      image: 'assets/images/leg_reverse_lunge.png',
      setsReps: '3 sets x 8-12 reps',
    ),
    _Exercise(
      id: 'bulgarian_split_squat',
      title: 'Bulgarian Split Squat',
      description: 'Single-leg squat variation for quad and glute strength.',
      image: 'assets/images/leg_bulgarian_split.png',
      setsReps: '3 sets x 8-10 reps',
    ),

    // Extensions & curls
    _Exercise(
      id: 'leg_extensions',
      title: 'Leg Extensions',
      description: 'Isolate quads with leg extension machine.',
      image: 'assets/images/leg_extensions.png',
      setsReps: '3 sets x 10-15 reps',
    ),
    _Exercise(
      id: 'hamstring_curls',
      title: 'Hamstring Curls',
      description: 'Machine or swiss ball hamstring curls for posterior chain.',
      image: 'assets/images/leg_hamstring_curls.png',
      setsReps: '3 sets x 10-15 reps',
    ),

    // Glutes
    _Exercise(
      id: 'glute_bridges',
      title: 'Glute Bridges',
      description: 'Glute bridges and hip thrusts for glute development.',
      image: 'assets/images/leg_glute_bridges.png',
      setsReps: '3-4 sets x 8-12 reps',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leg Workouts')),
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
                MaterialPageRoute(builder: (_) => LegExerciseDetail(exercise: ex)),
              ),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
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
                          Text(ex.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text(ex.setsReps, style: const TextStyle(color: Colors.black54, fontSize: 12)),
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

  const _Exercise({required this.id, required this.title, required this.description, required this.image, required this.setsReps});
}

class LegExerciseDetail extends StatelessWidget {
  final _Exercise exercise;

  const LegExerciseDetail({Key? key, required this.exercise}) : super(key: key);

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
                errorBuilder: (c, e, s) => _imageFallback(exercise.title, large: true),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(exercise.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(exercise.setsReps, style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 12),
                  Text(exercise.description, style: const TextStyle(fontSize: 16)),
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
                                ElevatedButton(onPressed: () => Navigator.pop(ctx, {'duration': duration, 'notes': notes}), child: const Text('Save')),
                              ],
                            );
                          });
                        },
                      );

                      if (result == null) return;
                      final entry = WorkoutEntry(
                        id: '${exercise.id}_${DateTime.now().millisecondsSinceEpoch}',
                        date: DateTime.now(),
                        workoutType: 'legs',
                        durationMinutes: (result['duration'] as int),
                        notes: (result['notes'] as String?),
                      );
                      await StorageService().saveEntry(entry);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${exercise.title} marked as done')));
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
      child: Text(initials, style: TextStyle(fontSize: large ? 28 : 16, color: Colors.blueGrey.shade700, fontWeight: FontWeight.bold)),
    ),
  );
}

String _initialsFromTitle(String title) {
  final parts = title.split(RegExp(r'\s+'))..removeWhere((s) => s.isEmpty);
  if (parts.isEmpty) return '';
  if (parts.length == 1) return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
  return (parts[0][0] + parts[1][0]).toUpperCase();
}
