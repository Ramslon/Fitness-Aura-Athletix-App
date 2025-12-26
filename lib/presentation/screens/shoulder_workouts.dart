import 'package:flutter/material.dart';
import 'package:fitness_aura_athletix/services/storage_service.dart';
import 'package:fitness_aura_athletix/presentation/widgets/local_image_placeholder.dart';

class ShoulderWorkouts extends StatelessWidget {
  const ShoulderWorkouts({Key? key}) : super(key: key);

  static final List<_Exercise> _exercises = [
    _Exercise(
      id: 'military_barbell_press',
      title: 'Military Barbell Press',
      description: 'Standing barbell press for overall shoulder strength.',
      image: 'assets/images/shoulder_military_barbell_press.png',
      setsReps: '4 sets x 5-8 reps',
    ),
    _Exercise(
      id: 'overhead_dumbbell_press',
      title: 'Overhead Dumbbell Press',
      description: 'Unilateral pressing to address imbalances.',
      image: 'assets/images/shoulder_overhead_dumbbell_press.png',
      setsReps: '3 sets x 8-12 reps',
    ),
    _Exercise(
      id: 'arnold_press',
      title: 'Arnold Press',
      description: 'Rotational press that hits all deltoid heads.',
      image: 'assets/images/shoulder_arnold_press.png',
      setsReps: '3 sets x 8-12 reps',
    ),
    _Exercise(
      id: 'lateral_raises',
      title: 'Lateral Raises',
      description: 'Isolation movement for the medial deltoid.',
      image: 'assets/images/shoulder_lateral_raises.png',
      setsReps: '3 sets x 12-15 reps',
    ),
    _Exercise(
      id: 'front_raises',
      title: 'Front Raises',
      description: 'Targets the anterior deltoid for shoulder shape.',
      image: 'assets/images/shoulder_front_raises.png',
      setsReps: '3 sets x 10-12 reps',
    ),
    _Exercise(
      id: 'rear_delt_fly',
      title: 'Rear Delt Fly',
      description: 'Posterior deltoid work for posture and balance.',
      image: 'assets/images/shoulder_rear_delt_fly.png',
      setsReps: '3 sets x 12-15 reps',
    ),
    _Exercise(
      id: 'upright_row',
      title: 'Upright Row',
      description: 'Compound movement for traps and medial delts.',
      image: 'assets/images/shoulder_upright_row.png',
      setsReps: '3 sets x 8-12 reps',
    ),
    _Exercise(
      id: 'shrugs',
      title: 'Shrugs',
      description: 'Trap-builder for upper back thickness.',
      image: 'assets/images/shoulder_shrugs.png',
      setsReps: '4 sets x 8-12 reps',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shoulder Workouts')),
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
                MaterialPageRoute(builder: (_) => ShoulderExerciseDetail(exercise: ex)),
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
                        child: LocalImagePlaceholder(id: ex.id, assetPath: ex.image, fit: BoxFit.cover),
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

class ShoulderExerciseDetail extends StatelessWidget {
  final _Exercise exercise;

  const ShoulderExerciseDetail({Key? key, required this.exercise}) : super(key: key);

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
              child: LocalImagePlaceholder(id: exercise.id, assetPath: exercise.image, fit: BoxFit.cover, height: 240),
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
                          int duration = 20;
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
                                    onChanged: (v) => setState(() => duration = int.tryParse(v) ?? 20),
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
                        workoutType: 'shoulders',
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
