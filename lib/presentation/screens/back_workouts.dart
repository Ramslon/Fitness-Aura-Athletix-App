import 'package:flutter/material.dart';
import 'package:fitness_aura_athletix/presentation/widgets/exercise_log_dialog.dart';
import 'package:fitness_aura_athletix/presentation/widgets/local_image_placeholder.dart';
import 'package:fitness_aura_athletix/presentation/widgets/exercise_grid_card.dart';
import 'package:fitness_aura_athletix/presentation/widgets/rest_timer_bottom_sheet.dart';
import 'package:fitness_aura_athletix/services/workout_session_service.dart';
import 'package:fitness_aura_athletix/presentation/widgets/daily_workout_analysis_card.dart';
import 'package:fitness_aura_athletix/presentation/widgets/daily_workout_analysis_details_sheet.dart';

class BackWorkouts extends StatefulWidget {
  const BackWorkouts({Key? key}) : super(key: key);

  @override
  State<BackWorkouts> createState() => _BackWorkoutsState();

  static final List<_Exercise> _exercises = [
    _Exercise(
      id: 'bend_over_rows',
      title: 'Barbell Bent-Over Rows',
      description:
          'Barbell bent-over rows build thickness across the middle back.',
      image: 'assets/images/back_bend_over_rows.png',
      setsReps: '1–5 sets x 6-10 reps',
    ),
    _Exercise(
      id: 'dumbbell_rows',
      title: 'Dumbbell Rows',
      description:
          'Single-arm dumbbell rows for unilateral strength and balance.',
      image: 'assets/images/back_dumbbell_rows.png',
      setsReps: '1–5 sets x 8-12 reps',
    ),
    _Exercise(
      id: 'deadlift',
      title: 'Deadlift',
      description:
          'Deadlifts load the entire posterior chain and build overall strength.',
      image: 'assets/images/back_deadlift.png',
      setsReps: '1–5 sets x 3-6 reps',
    ),
    _Exercise(
      id: 'pull_ups',
      title: 'Pull-ups / Chin-ups',
      description: 'Bodyweight pulling movement to develop lats and grip.',
      image: 'assets/images/back_pullups.png',
      setsReps: '1–5 sets x max reps',
    ),
    _Exercise(
      id: 'tbar_row',
      title: 'T-Bar Row',
      description: 'T-bar rows target thickness in the mid-back and lats.',
      image: 'assets/images/back_tbar_row.png',
      setsReps: '1–5 sets x 6-10 reps',
    ),
    _Exercise(
      id: 'lat_pull_down',
      title: 'Lat Pulldowns',
      description: 'Lat pulldowns for wide upper-back development.',
      image: 'assets/images/back_lat_pull_down.png',
      setsReps: '1–5 sets x 8-12 reps',
    ),
    _Exercise(
      id: 'seated_row',
      title: 'Seated Cable Row',
      description:
          'Seated rows emphasize the mid-back and scapular retraction.',
      image: 'assets/images/back_seated_row.png',
      setsReps: '1–5 sets x 8-12 reps',
    ),
    _Exercise(
      id: 'single_arm_rows',
      title: 'Dumbbell Single-Arm Rows',
      description: 'Single-arm rows for stability and unilateral strength.',
      image: 'assets/images/back_single_arm_rows.png',
      setsReps: '1–5 sets x 8-12 reps',
    ),
    _Exercise(
      id: 'reverse_flys',
      title: 'Reverse Flys',
      description: 'Reverse flys target rear delts and upper back posture.',
      image: 'assets/images/back_reverse_flys.png',
      setsReps: '1–5 sets x 12-15 reps',
    ),
    _Exercise(
      id: 'bent_arm_pullovers',
      title: 'Bent-Arm Dumbbell Pullovers',
      description: 'Pullovers hit the lats and chest depending on arm path.',
      image: 'assets/images/back_bent_arm_pullovers.png',
      setsReps: '1–5 sets x 8-12 reps',
    ),
  ];
}

class _BackWorkoutsState extends State<BackWorkouts> {
  Future<void> _finishWorkout(BuildContext context) async {
    final analysis = await WorkoutSessionService.instance.endAndAnalyze(
      expectedBodyPart: 'Back',
    );

    if (!mounted) return;
    if (analysis == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active Back workout to finish yet.')),
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
    final accent = Colors.blueGrey.shade700;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Back Workouts'),
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
          itemCount: BackWorkouts._exercises.length,
          itemBuilder: (context, index) {
            final ex = BackWorkouts._exercises[index];
            return ExerciseGridCard(
              id: ex.id,
              title: ex.title,
              setsReps: ex.setsReps,
              bodyPart: 'Back',
              assetPath: ex.image,
              accent: accent,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BackExerciseDetail(exercise: ex),
                ),
              ),
              onPick: () async {
                final restSeconds = await showDialog<int>(
                  context: context,
                  builder: (ctx) => ExerciseLogDialog(
                    exerciseName: ex.title,
                    bodyPart: 'Back',
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
                          bodyPart: 'Back',
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


