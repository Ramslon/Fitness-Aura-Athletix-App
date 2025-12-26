import 'package:flutter/material.dart';
import 'package:fitness_aura_athletix/services/storage_service.dart';
import 'package:fitness_aura_athletix/presentation/widgets/local_image_placeholder.dart';

class BackWorkouts extends StatelessWidget {
  const BackWorkouts({Key? key}) : super(key: key);

  static final List<_Exercise> _exercises = [
    _Exercise(
      id: 'bend_over_rows',
      title: 'Barbell Bent-Over Rows',
      description:
          'Barbell bent-over rows build thickness across the middle back.',
      image: 'assets/images/back_bend_over_rows.png',
      setsReps: '4 sets x 6-10 reps',
    ),
    _Exercise(
      id: 'dumbbell_rows',
      title: 'Dumbbell Rows',
      description:
          'Single-arm dumbbell rows for unilateral strength and balance.',
      image: 'assets/images/back_dumbbell_rows.png',
      setsReps: '4 sets x 8-12 reps',
    ),
    _Exercise(
      id: 'deadlift',
      title: 'Deadlift',
      description:
          'Deadlifts load the entire posterior chain and build overall strength.',
      image: 'assets/images/back_deadlift.png',
      setsReps: '3-4 sets x 3-6 reps',
    ),
    _Exercise(
      id: 'pull_ups',
      title: 'Pull-ups / Chin-ups',
      description: 'Bodyweight pulling movement to develop lats and grip.',
      image: 'assets/images/back_pullups.png',
      setsReps: '3 sets x max reps',
    ),
    _Exercise(
      id: 'tbar_row',
      title: 'T-Bar Row',
      description: 'T-bar rows target thickness in the mid-back and lats.',
      image: 'assets/images/back_tbar_row.png',
      setsReps: '4 sets x 6-10 reps',
    ),
    _Exercise(
      id: 'lat_pull_down',
      title: 'Lat Pulldowns',
      description: 'Lat pulldowns for wide upper-back development.',
      image: 'assets/images/back_lat_pull_down.png',
      setsReps: '4 sets x 8-12 reps',
    ),
    _Exercise(
      id: 'seated_row',
      title: 'Seated Cable Row',
      description:
          'Seated rows emphasize the mid-back and scapular retraction.',
      image: 'assets/images/back_seated_row.png',
      setsReps: '4 sets x 8-12 reps',
    ),
    _Exercise(
      id: 'single_arm_rows',
      title: 'Dumbbell Single-Arm Rows',
      description: 'Single-arm rows for stability and unilateral strength.',
      image: 'assets/images/back_single_arm_rows.png',
      setsReps: '3 sets x 8-12 reps',
    ),
    _Exercise(
      id: 'reverse_flys',
      title: 'Reverse Flys',
      description: 'Reverse flys target rear delts and upper back posture.',
      image: 'assets/images/back_reverse_flys.png',
      setsReps: '3 sets x 12-15 reps',
    ),
    _Exercise(
      id: 'bent_arm_pullovers',
      title: 'Bent-Arm Dumbbell Pullovers',
      description: 'Pullovers hit the lats and chest depending on arm path.',
      image: 'assets/images/back_bent_arm_pullovers.png',
      setsReps: '3 sets x 8-12 reps',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Back Workouts')),
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
                MaterialPageRoute(
                  builder: (_) => BackExerciseDetail(exercise: ex),
                ),
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
                        child: LocalImagePlaceholder(id: ex.id, assetPath: ex.image, fit: BoxFit.cover),
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

class BackExerciseDetail extends StatelessWidget {
  final _Exercise exercise;

  const BackExerciseDetail({Key? key, required this.exercise})
    : super(key: key);

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
                          return StatefulBuilder(
                            builder: (c, setState) {
                              return AlertDialog(
                                title: Text('Mark "${exercise.title}" done'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextFormField(
                                      initialValue: duration.toString(),
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Duration (minutes)',
                                      ),
                                      onChanged: (v) => setState(
                                        () => duration = int.tryParse(v) ?? 30,
                                      ),
                                    ),
                                    TextFormField(
                                      initialValue: notes,
                                      decoration: const InputDecoration(
                                        labelText: 'Notes (optional)',
                                      ),
                                      onChanged: (v) =>
                                          setState(() => notes = v),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(ctx, {
                                      'duration': duration,
                                      'notes': notes,
                                    }),
                                    child: const Text('Save'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );

                      if (result == null) return;
                      final entry = WorkoutEntry(
                        id: '${exercise.id}_${DateTime.now().millisecondsSinceEpoch}',
                        date: DateTime.now(),
                        workoutType: 'back',
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
