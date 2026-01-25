import 'package:flutter/material.dart';
import 'package:fitness_aura_athletix/presentation/widgets/exercise_log_dialog.dart';
import 'package:fitness_aura_athletix/presentation/widgets/local_image_placeholder.dart';
import 'package:fitness_aura_athletix/presentation/widgets/exercise_grid_card.dart';
import 'package:fitness_aura_athletix/services/workout_session_service.dart';
import 'package:fitness_aura_athletix/presentation/widgets/daily_workout_analysis_card.dart';
import 'package:fitness_aura_athletix/presentation/widgets/daily_workout_analysis_details_sheet.dart';

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
  Future<void> _finishWorkout(BuildContext context) async {
    final analysis = await WorkoutSessionService.instance.endAndAnalyze(
      expectedBodyPart: 'Shoulders',
    );

    if (!mounted) return;
    if (analysis == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active Shoulders workout to finish yet.'),
        ),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: DailyWorkoutAnalysisCard(
              analysis: analysis,
              onTap: () => DailyWorkoutAnalysisDetailsSheet.show(
                ctx,
                analysis: analysis,
              ),
              onLongPress: () => DailyWorkoutAnalysisDetailsSheet.show(
                ctx,
                analysis: analysis,
              ),
              onViewDetails: () => DailyWorkoutAnalysisDetailsSheet.show(
                ctx,
                analysis: analysis,
              ),
            ),
          ),
        );
      },
    );

    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final accent = Colors.orange.shade400;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shoulder Workouts'),
        actions: [
          IconButton(
            tooltip: 'Finish workout',
            onPressed: () => _finishWorkout(context),
            icon: const Icon(Icons.flag_circle),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.74,
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
                final saved = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => ExerciseLogDialog(
                    exerciseName: ex.title,
                    bodyPart: 'Shoulders',
                  ),
                );
                if (!mounted) return;
                if (saved == true) setState(() {});
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


