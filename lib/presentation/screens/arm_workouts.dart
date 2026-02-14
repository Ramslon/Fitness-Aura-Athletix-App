import 'package:flutter/material.dart';
import 'package:fitness_aura_athletix/presentation/widgets/exercise_log_dialog.dart';
import 'package:fitness_aura_athletix/presentation/widgets/local_image_placeholder.dart';
import 'package:fitness_aura_athletix/presentation/widgets/exercise_grid_card.dart';
import 'package:fitness_aura_athletix/presentation/widgets/rest_timer_bottom_sheet.dart';
import 'package:fitness_aura_athletix/presentation/widgets/muscle_fatigue_indicator.dart';
import 'package:fitness_aura_athletix/presentation/widgets/simple_progress_summary_dialog.dart';
import 'package:fitness_aura_athletix/presentation/widgets/warmup_recommendations_card.dart';
import 'package:fitness_aura_athletix/services/workout_session_service.dart';
import 'package:fitness_aura_athletix/presentation/widgets/daily_workout_analysis_card.dart';
import 'package:fitness_aura_athletix/presentation/widgets/daily_workout_analysis_details_sheet.dart';

class ArmWorkouts extends StatefulWidget {
  const ArmWorkouts({Key? key}) : super(key: key);

  @override
  State<ArmWorkouts> createState() => _ArmWorkoutsState();

  static final List<_Exercise> _exercises = [
    // Biceps
    _Exercise(
      id: 'dumbbell_bicep_curls',
      title: 'Dumbbell Bicep Curls',
      description: 'Classic dumbbell curls for biceps peak and control.',
      image: 'assets/images/arm_dumbbell_bicep_curls.png',
      setsReps: '1–5 sets x 8-12 reps',
    ),
    _Exercise(
      id: 'hammer_curls',
      title: 'Hammer Curls',
      description: 'Hammer curls emphasize brachialis and forearms.',
      image: 'assets/images/arm_hammer_curls.png',
      setsReps: '1–5 sets x 8-12 reps',
    ),
    _Exercise(
      id: 'concentration_curls',
      title: 'Concentration Curls',
      description: 'Strict unilateral curl for peak contraction.',
      image: 'assets/images/arm_concentration_curls.png',
      setsReps: '1–5 sets x 8-10 reps',
    ),
    _Exercise(
      id: 'barbell_curls',
      title: 'Barbell Curls',
      description: 'Barbell curls for heavy loading and mass.',
      image: 'assets/images/arm_barbell_curls.png',
      setsReps: '1–5 sets x 6-10 reps',
    ),
    _Exercise(
      id: 'preacher_curls',
      title: 'Preacher Curls',
      description: 'Preacher bench isolates the biceps and prevents cheating.',
      image: 'assets/images/arm_preacher_curls.png',
      setsReps: '1–5 sets x 8-12 reps',
    ),

    // Triceps
    _Exercise(
      id: 'overhead_tricep_extension',
      title: 'Overhead Tricep Extension',
      description: 'Overhead extension targets the long head of the triceps.',
      image: 'assets/images/arm_overhead_tricep_extension.png',
      setsReps: '1–5 sets x 8-12 reps',
    ),
    _Exercise(
      id: 'tricep_kickbacks',
      title: 'Tricep Kickbacks',
      description: 'Kickbacks for isolating the lateral head of triceps.',
      image: 'assets/images/arm_tricep_kickbacks.png',
      setsReps: '1–5 sets x 10-12 reps',
    ),
    _Exercise(
      id: 'tricep_dips',
      title: 'Tricep Dips',
      description: 'Bodyweight dips (or weighted) for triceps and chest.',
      image: 'assets/images/arm_tricep_dips.png',
      setsReps: '1–5 sets x 8-15 reps',
    ),
    _Exercise(
      id: 'cross_grip',
      title: 'Cross Grip Tricep Press',
      description: 'Cross-grip pressing emphasizes triceps differently.',
      image: 'assets/images/arm_cross_grip.png',
      setsReps: '1–5 sets x 6-10 reps',
    ),
    _Exercise(
      id: 'skull_crusher',
      title: 'Skull Crushers',
      description: 'Lying triceps extensions (skull crushers) for mass.',
      image: 'assets/images/arm_skull_crusher.png',
      setsReps: '1–5 sets x 8-12 reps',
    ),
  ];
}

class _ArmWorkoutsState extends State<ArmWorkouts> {
  Future<void> _finishWorkout(BuildContext context) async {
    final analysis = await WorkoutSessionService.instance.endAndAnalyze(
      expectedBodyPart: 'Arms',
    );

    if (!mounted) return;
    if (analysis == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active Arms workout to finish yet.')),
      );
      return;
    }

    await showSimpleProgressSummaryDialog(context, analysis: analysis);
    if (!mounted) return;

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
    final accent = Colors.indigo.shade400;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arm Workouts'),
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
            const MuscleFatigueIndicator(bodyPart: 'Arms'),
            const SizedBox(height: 10),
            const WarmupRecommendationsCard(bodyPart: 'Arms'),
            const SizedBox(height: 10),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.74,
                ),
                itemCount: ArmWorkouts._exercises.length,
                itemBuilder: (context, index) {
                  final ex = ArmWorkouts._exercises[index];
                  return ExerciseGridCard(
                    id: ex.id,
                    title: ex.title,
                    setsReps: ex.setsReps,
                    bodyPart: 'Arms',
                    assetPath: ex.image,
                    accent: accent,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ArmExerciseDetail(exercise: ex),
                      ),
                    ),
                    onPick: () async {
                      final restSeconds = await showDialog<int>(
                        context: context,
                        builder: (ctx) => ExerciseLogDialog(
                          exerciseName: ex.title,
                          bodyPart: 'Arms',
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

class ArmExerciseDetail extends StatelessWidget {
  final _Exercise exercise;

  const ArmExerciseDetail({Key? key, required this.exercise}) : super(key: key);

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
                          bodyPart: 'Arms',
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


