import 'package:flutter/material.dart';
import 'package:fitness_aura_athletix/presentation/widgets/exercise_log_dialog.dart';
import 'package:fitness_aura_athletix/presentation/widgets/local_image_placeholder.dart';
import 'package:fitness_aura_athletix/presentation/widgets/exercise_grid_card.dart';

class ShoulderWorkouts extends StatefulWidget {
  const ShoulderWorkouts({Key? key}) : super(key: key);

  @override
  State<ShoulderWorkouts> createState() => _ShoulderWorkoutsState();

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
}

class _ShoulderWorkoutsState extends State<ShoulderWorkouts> {
  @override
  Widget build(BuildContext context) {
    final accent = Colors.orange.shade400;
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
          itemCount: ShoulderWorkouts._exercises.length,
          itemBuilder: (context, index) {
            final ex = ShoulderWorkouts._exercises[index];
            return ExerciseGridCard(
              id: ex.id,
              title: ex.title,
              setsReps: ex.setsReps,
              bodyPart: 'Shoulders',
              assetPath: ex.image,
              accent: accent,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ShoulderExerciseDetail(exercise: ex),
                ),
              ),
              onPick: () async {
                await showDialog(
                  context: context,
                  builder: (ctx) => ExerciseLogDialog(
                    exerciseName: ex.title,
                    bodyPart: 'Shoulders',
                  ),
                );
                if (!mounted) return;
                setState(() {});
              },
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

class ShoulderExerciseDetail extends StatelessWidget {
  final _Exercise exercise;

  const ShoulderExerciseDetail({Key? key, required this.exercise})
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
                          bodyPart: 'Shoulders',
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

Widget _imageFallback(String title, {bool large = false}) {
  final initials = _initialsFromTitle(title);
  return Container(
    color: Colors.transparent,
    alignment: Alignment.center,
    child: Container(
      width: large ? 120 : 56,
      height: large ? 120 : 56,
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: large ? 28 : 16,
          color: Colors.white.withOpacity(0.80),
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
