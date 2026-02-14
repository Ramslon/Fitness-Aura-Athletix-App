import 'package:flutter/material.dart';
import 'package:fitness_aura_athletix/presentation/widgets/exercise_log_dialog.dart';
import 'package:fitness_aura_athletix/presentation/widgets/local_image_placeholder.dart';
import 'package:fitness_aura_athletix/presentation/widgets/exercise_grid_card.dart';
import 'package:fitness_aura_athletix/presentation/widgets/rest_timer_bottom_sheet.dart';
import 'package:fitness_aura_athletix/presentation/widgets/warmup_recommendations_card.dart';
import 'package:fitness_aura_athletix/services/workout_session_service.dart';
import 'package:fitness_aura_athletix/presentation/widgets/daily_workout_analysis_card.dart';
import 'package:fitness_aura_athletix/presentation/widgets/daily_workout_analysis_details_sheet.dart';

class CoreWorkouts extends StatefulWidget {
  const CoreWorkouts({Key? key}) : super(key: key);

  @override
  State<CoreWorkouts> createState() => _CoreWorkoutsState();

  static final List<_Exercise> _exercises = [
    _Exercise(
      id: 'plank',
      title: 'Plank',
      description:
          'Front plank is a fundamental isometric core exercise for building stability and strength.',
      image: 'assets/images/core_plank.png',
      setsReps: '1–5 sets x 30-60 seconds',
    ),
    _Exercise(
      id: 'dead_bug',
      title: 'Dead Bug',
      description:
          'Dead bug targets deep core stabilizers and improves coordination.',
      image: 'assets/images/core_dead_bug.png',
      setsReps: '1–5 sets x 10 reps',
    ),
    _Exercise(
      id: 'bird_dog',
      title: 'Bird Dog',
      description:
          'Bird dog strengthens core and improves stability through opposite limb extension.',
      image: 'assets/images/core_bird_dog.png',
      setsReps: '1–5 sets x 10 reps per side',
    ),
    _Exercise(
      id: 'pallof_press',
      title: 'Pallof Press',
      description:
          'Cable or band Pallof press resists rotational force for anti-rotation strength.',
      image: 'assets/images/core_pallof_press.png',
      setsReps: '1–5 sets x 10 reps per side',
    ),
    _Exercise(
      id: 'ab_wheel_rollout',
      title: 'Ab Wheel Rollout',
      description:
          'Ab wheel rollout is an advanced core exercise targeting rectus abdominis.',
      image: 'assets/images/core_ab_wheel.png',
      setsReps: '1–5 sets x 8-12 reps',
    ),
    _Exercise(
      id: 'cable_wood_chop',
      title: 'Cable Wood Chop',
      description:
          'Rotational movement that strengthens obliques and transverse abdominis.',
      image: 'assets/images/core_wood_chop.png',
      setsReps: '1–5 sets x 10 reps per side',
    ),
    _Exercise(
      id: 'side_plank',
      title: 'Side Plank',
      description: 'Side plank targets obliques and lateral core muscles.',
      image: 'assets/images/core_side_plank.png',
      setsReps: '1–5 sets x 30-45 seconds per side',
    ),
    _Exercise(
      id: 'hanging_leg_raise',
      title: 'Hanging Leg Raise',
      description:
          'Hanging leg raise is excellent for lower abs and hip flexors.',
      image: 'assets/images/core_hanging_leg_raise.png',
      setsReps: '1–5 sets x 8-12 reps',
    ),
  ];
}

class _CoreWorkoutsState extends State<CoreWorkouts> {
  Future<void> _finishWorkout(BuildContext context) async {
    final analysis = await WorkoutSessionService.instance.endAndAnalyze(
      expectedBodyPart: 'Core',
    );

    if (!mounted) return;
    if (analysis == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active Core workout to finish yet.')),
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
    final accent = Colors.deepOrange.shade400;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Core Workouts'),
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
        child: Column(
          children: [
            const WarmupRecommendationsCard(bodyPart: 'Core'),
            const SizedBox(height: 10),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.74,
                ),
                itemCount: CoreWorkouts._exercises.length,
                itemBuilder: (context, index) {
                  final ex = CoreWorkouts._exercises[index];
                  return ExerciseGridCard(
                    id: ex.id,
                    title: ex.title,
                    setsReps: ex.setsReps,
                    bodyPart: 'Core',
                    assetPath: ex.image,
                    accent: accent,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CoreExerciseDetail(exercise: ex),
                      ),
                    ),
                    onPick: () async {
                      final restSeconds = await showDialog<int>(
                        context: context,
                        builder: (ctx) => ExerciseLogDialog(
                          exerciseName: ex.title,
                          bodyPart: 'Core',
                        ),
                      );
                      if (!mounted) return;
                      if (restSeconds != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${ex.title} logged successfully!'),
                          ),
                        );
                        await showRestTimerBottomSheet(
                          context,
                          seconds: restSeconds,
                        );
                        setState(() {});
                      }
                    },
                  );
                },
              ),
            ),
          ],
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

class CoreExerciseDetail extends StatelessWidget {
  final _Exercise exercise;

  const CoreExerciseDetail({Key? key, required this.exercise})
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
                      final restSeconds = await showDialog<int>(
                        context: context,
                        builder: (ctx) => ExerciseLogDialog(
                          exerciseName: exercise.title,
                          bodyPart: 'Core',
                        ),
                      );
                      if (!context.mounted) return;
                      if (restSeconds != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${exercise.title} logged successfully!',
                            ),
                          ),
                        );
                        await showRestTimerBottomSheet(
                          context,
                          seconds: restSeconds,
                        );
                      }
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
