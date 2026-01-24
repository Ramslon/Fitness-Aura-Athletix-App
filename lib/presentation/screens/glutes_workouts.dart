import 'package:flutter/material.dart';
import 'package:fitness_aura_athletix/presentation/widgets/exercise_log_dialog.dart';
import 'package:fitness_aura_athletix/presentation/widgets/local_image_placeholder.dart';

class GlutesWorkouts extends StatelessWidget {
  const GlutesWorkouts({Key? key}) : super(key: key);

  static final List<_Exercise> _exercises = [
    _Exercise(
      id: 'barbell_squat',
      title: 'Barbell Squat',
      description:
          'Heavy compound movement that targets glutes, quads, and hamstrings.',
      image: 'assets/images/glutes_barbell_squat.png',
      setsReps: '4 sets x 6-8 reps',
    ),
    _Exercise(
      id: 'glute_bridge',
      title: 'Glute Bridge',
      description:
          'Bodyweight or weighted glute bridge focuses on glute activation and isolation.',
      image: 'assets/images/glutes_glute_bridge.png',
      setsReps: '3 sets x 12-15 reps',
    ),
    _Exercise(
      id: 'hip_thrust',
      title: 'Barbell Hip Thrust',
      description:
          'Hip thrust is one of the most effective exercises for glute hypertrophy.',
      image: 'assets/images/glutes_hip_thrust.png',
      setsReps: '3 sets x 8-12 reps',
    ),
    _Exercise(
      id: 'rumanian_deadlift',
      title: 'Romanian Deadlift',
      description:
          'RDL targets glutes and hamstrings with emphasis on the posterior chain.',
      image: 'assets/images/glutes_romanian_deadlift.png',
      setsReps: '3 sets x 8-10 reps',
    ),
    _Exercise(
      id: 'leg_press',
      title: 'Leg Press',
      description:
          'Machine leg press allows heavy loading and targets all leg muscles including glutes.',
      image: 'assets/images/glutes_leg_press.png',
      setsReps: '3 sets x 8-12 reps',
    ),
    _Exercise(
      id: 'bulgarian_split_squat',
      title: 'Bulgarian Split Squat',
      description:
          'Single-leg variation that isolates each glute and improves balance.',
      image: 'assets/images/glutes_bulgarian_split_squat.png',
      setsReps: '3 sets x 10 reps per leg',
    ),
    _Exercise(
      id: 'cable_glute_kickback',
      title: 'Cable Glute Kickback',
      description:
          'Cable kickback provides constant tension for glute isolation.',
      image: 'assets/images/glutes_cable_kickback.png',
      setsReps: '3 sets x 12-15 reps per side',
    ),
    _Exercise(
      id: 'leg_curl',
      title: 'Leg Curl',
      description: 'Machine leg curl targets hamstrings and lower glutes.',
      image: 'assets/images/glutes_leg_curl.png',
      setsReps: '3 sets x 10-12 reps',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Glutes Workouts')),
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
                  builder: (_) => GlutesExerciseDetail(exercise: ex),
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

class GlutesExerciseDetail extends StatelessWidget {
  final _Exercise exercise;

  const GlutesExerciseDetail({Key? key, required this.exercise})
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
                          bodyPart: 'Glutes',
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
