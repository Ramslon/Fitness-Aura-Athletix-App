import 'package:flutter/material.dart';
import 'package:fitness_aura_athletix/presentation/widgets/exercise_log_dialog.dart';
import 'package:fitness_aura_athletix/presentation/widgets/local_image_placeholder.dart';

class AbsWorkouts extends StatelessWidget {
  const AbsWorkouts({Key? key}) : super(key: key);

  static final List<_Exercise> _exercises = [
    _Exercise(
      id: 'crunches',
      title: 'Crunches',
      description:
          'Classic crunches target upper abdominals with a shortened range of motion.',
      image: 'assets/images/abs_crunches.png',
      setsReps: '3 sets x 12-15 reps',
    ),
    _Exercise(
      id: 'cable_crunch',
      title: 'Cable Crunch',
      description:
          'Cable crunch provides constant tension throughout the movement.',
      image: 'assets/images/abs_cable_crunch.png',
      setsReps: '3 sets x 12-15 reps',
    ),
    _Exercise(
      id: 'decline_sit_ups',
      title: 'Decline Sit-ups',
      description:
          'Sit-ups on an incline bench increase resistance for greater abs activation.',
      image: 'assets/images/abs_decline_situps.png',
      setsReps: '3 sets x 10-15 reps',
    ),
    _Exercise(
      id: 'weighted_crunch',
      title: 'Weighted Crunch',
      description:
          'Adding weight to crunches increases difficulty and promotes hypertrophy.',
      image: 'assets/images/abs_weighted_crunch.png',
      setsReps: '3 sets x 10-12 reps',
    ),
    _Exercise(
      id: 'machine_crunch',
      title: 'Machine Crunch',
      description:
          'Machine crunch provides guided movement and adjustable resistance.',
      image: 'assets/images/abs_machine_crunch.png',
      setsReps: '3 sets x 12-15 reps',
    ),
    _Exercise(
      id: 'captain_chair_knee_raise',
      title: 'Captain Chair Knee Raise',
      description:
          'Knee raise on captain\'s chair targets lower abs effectively.',
      image: 'assets/images/abs_captain_chair.png',
      setsReps: '3 sets x 12-15 reps',
    ),
    _Exercise(
      id: 'ab_wheel_crunch',
      title: 'Ab Wheel Crunch',
      description:
          'Ab wheel crunch is a variation that targets upper and mid abdominals.',
      image: 'assets/images/abs_ab_wheel_crunch.png',
      setsReps: '3 sets x 8-12 reps',
    ),
    _Exercise(
      id: 'incline_treadmill_walk',
      title: 'Incline Treadmill Walk',
      description: 'Walking on an incline engages core and abdominal muscles.',
      image: 'assets/images/abs_incline_walk.png',
      setsReps: '3 sets x 10-15 minutes',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Abs Workouts')),
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
                  builder: (_) => AbsExerciseDetail(exercise: ex),
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
                        child: LocalImagePlaceholder(
                          id: ex.id,
                          assetPath: ex.image,
                          fit: BoxFit.cover,
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

class AbsExerciseDetail extends StatelessWidget {
  final _Exercise exercise;

  const AbsExerciseDetail({Key? key, required this.exercise}) : super(key: key);

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
              child: LocalImagePlaceholder(
                id: exercise.id,
                assetPath: exercise.image,
                fit: BoxFit.cover,
                height: 240,
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
                      await showDialog(
                        context: context,
                        builder: (ctx) => ExerciseLogDialog(
                          exerciseName: exercise.title,
                          bodyPart: 'Abs',
                        ),
                      );
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Log Exercise'),
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
