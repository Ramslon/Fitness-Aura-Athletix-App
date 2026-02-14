import 'package:flutter/material.dart';
import 'package:fitness_aura_athletix/presentation/widgets/exercise_log_dialog.dart';
import 'package:fitness_aura_athletix/presentation/widgets/local_image_placeholder.dart';
import 'package:fitness_aura_athletix/presentation/widgets/exercise_grid_card.dart';
import 'package:fitness_aura_athletix/presentation/widgets/rest_timer_bottom_sheet.dart';
import 'package:fitness_aura_athletix/presentation/widgets/warmup_recommendations_card.dart';
import 'package:fitness_aura_athletix/services/workout_session_service.dart';
import 'package:fitness_aura_athletix/presentation/widgets/daily_workout_analysis_card.dart';
import 'package:fitness_aura_athletix/presentation/widgets/daily_workout_analysis_details_sheet.dart';

class ChestWorkouts extends StatefulWidget {
  const ChestWorkouts({Key? key}) : super(key: key);

  @override
  State<ChestWorkouts> createState() => _ChestWorkoutsState();

  static final List<_Exercise> _exercises = [
    _Exercise(
      id: 'flat_bench_press',
      title: 'Flat Bench Press',
      description:
          'Barbell flat bench press — compound pressing movement for overall chest strength.',
      image: 'assets/images/chest_flat_bench.png',
      setsReps: '1–5 sets x 6-10 reps',
    ),
    _Exercise(
      id: 'incline_bench_press',
      title: 'Incline Bench Press',
      description: 'Incline bench press focuses upper chest and front delts.',
      image: 'assets/images/chest_incline_bench.png',
      setsReps: '1–5 sets x 6-10 reps',
    ),
    _Exercise(
      id: 'decline_bench_press',
      title: 'Decline Bench Press',
      description: 'Decline bench targets lower chest fibers.',
      image: 'assets/images/chest_decline_bench.png',
      setsReps: '1–5 sets x 6-10 reps',
    ),
    _Exercise(
      id: 'dumbbell_flies',
      title: 'Dumbbell Flies',
      description:
          'Dumbbell flies isolate the chest and create stretch at the bottom of the movement.',
      image: 'assets/images/chest_dumbbell_flies.png',
      setsReps: '1–5 sets x 10-15 reps',
    ),
    _Exercise(
      id: 'pullovers',
      title: 'Pullovers',
      description:
          'Dumbbell pullovers work the chest and lats depending on arm path.',
      image: 'assets/images/chest_pullovers.png',
      setsReps: '1–5 sets x 8-12 reps',
    ),
    _Exercise(
      id: 'dips',
      title: 'Dips',
      description:
          'Parallel-bar dips (lean forward) emphasize the lower chest and triceps.',
      image: 'assets/images/chest_dips.png',
      setsReps: '1–5 sets x 8-12 reps',
    ),
    _Exercise(
      id: 'flat_dumbbell_press',
      title: 'Flat Dumbbell Press',
      description:
          'Dumbbell press allows a greater range of motion and balanced loading.',
      image: 'assets/images/chest_flat_dumbbell_press.png',
      setsReps: '1–5 sets x 8-12 reps',
    ),
    _Exercise(
      id: 'incline_dumbbell_press',
      title: 'Incline Dumbbell Press',
      description: 'Upper chest emphasis with dumbbells for stability work.',
      image: 'assets/images/chest_incline_dumbbell_press.png',
      setsReps: '1–5 sets x 8-12 reps',
    ),
    _Exercise(
      id: 'decline_dumbbell_press',
      title: 'Decline Dumbbell Press',
      description: 'Targets lower chest with dumbbell stability demands.',
      image: 'assets/images/chest_decline_dumbbell_press.png',
      setsReps: '1–5 sets x 8-12 reps',
    ),
  ];
}

class _ChestWorkoutsState extends State<ChestWorkouts> {
  Future<void> _finishWorkout(BuildContext context) async {
    final analysis = await WorkoutSessionService.instance.endAndAnalyze(
      expectedBodyPart: 'Chest',
    );

    if (!mounted) return;
    if (analysis == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active Chest workout to finish yet.')),
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
    final accent = Colors.red.shade400;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chest Workouts'),
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
            const WarmupRecommendationsCard(bodyPart: 'Chest'),
            const SizedBox(height: 10),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.74,
                ),
                itemCount: ChestWorkouts._exercises.length,
                itemBuilder: (context, index) {
                  final ex = ChestWorkouts._exercises[index];
                  return ExerciseGridCard(
                    id: ex.id,
                    title: ex.title,
                    setsReps: ex.setsReps,
                    bodyPart: 'Chest',
                    assetPath: ex.image,
                    accent: accent,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ExerciseDetail(exercise: ex)),
                    ),
                    onPick: () async {
                      final restSeconds = await showDialog<int>(
                        context: context,
                        builder: (ctx) => ExerciseLogDialog(
                          exerciseName: ex.title,
                          bodyPart: 'Chest',
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
                          bodyPart: 'Chest',
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


