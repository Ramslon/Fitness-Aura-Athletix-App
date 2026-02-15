import 'package:flutter/material.dart';
import 'package:fitness_aura_athletix/presentation/widgets/exercise_log_dialog.dart';
import 'package:fitness_aura_athletix/presentation/widgets/local_image_placeholder.dart';
import 'package:fitness_aura_athletix/presentation/widgets/exercise_grid_card.dart';
import 'package:fitness_aura_athletix/presentation/widgets/rest_timer_bottom_sheet.dart';
import 'package:fitness_aura_athletix/presentation/widgets/muscle_fatigue_indicator.dart';
import 'package:fitness_aura_athletix/presentation/widgets/simple_progress_summary_dialog.dart';
import 'package:fitness_aura_athletix/presentation/widgets/warmup_recommendations_card.dart';
import 'package:fitness_aura_athletix/services/workout_session_service.dart';
import 'package:fitness_aura_athletix/services/exercise_form_tips_service.dart';
import 'package:fitness_aura_athletix/presentation/widgets/daily_workout_analysis_card.dart';
import 'package:fitness_aura_athletix/presentation/widgets/daily_workout_analysis_details_sheet.dart';

class AbsWorkouts extends StatefulWidget {
  const AbsWorkouts({Key? key}) : super(key: key);

  @override
  State<AbsWorkouts> createState() => _AbsWorkoutsState();

  static final List<_Exercise> _exercises = [
    _Exercise(
      id: 'jumping_jacks',
      title: 'Jumping Jacks',
      description: 'A quick warm-up to elevate heart rate and prep the core.',
      image: null,
      setsReps: '30s \u2022 Warm-up',
    ),
    _Exercise(
      id: 'sit_ups',
      title: 'Sit-ups',
      description: 'Classic core move emphasizing trunk flexion and control.',
      image: null,
      setsReps: '15 reps \u2022 Core',
    ),
    _Exercise(
      id: 'leg_in_and_outs',
      title: 'Leg In & Outs',
      description: 'Tuck and extend legs to challenge lower abs and hip flexors.',
      image: null,
      setsReps: '20 reps \u2022 Core',
    ),
    _Exercise(
      id: 'one_down_two_ups',
      title: 'One Down Two Ups',
      description: 'Lower one leg then lift twice with control to build endurance.',
      image: null,
      setsReps: '12 reps/side \u2022 Core',
    ),
    _Exercise(
      id: 'abdominal_crunches',
      title: 'Abdominal Crunches',
      description: 'Short-range crunch focusing on upper ab engagement.',
      image: null,
      setsReps: '20 reps \u2022 Core',
    ),
    _Exercise(
      id: 'bicycle_crunches',
      title: 'Bicycle Crunches',
      description: 'Alternating elbow-to-knee motion for abs and obliques.',
      image: null,
      setsReps: '30 reps \u2022 Core',
    ),
    _Exercise(
      id: 'crunches_leg_raised',
      title: 'Crunches with Leg Raised',
      description: 'Crunch while keeping legs raised to increase core demand.',
      image: null,
      setsReps: '15 reps \u2022 Core',
    ),
    _Exercise(
      id: 'knee_to_elbow_crunches',
      title: 'Knee to Elbow Crunches',
      description: 'Drive knee toward elbow to emphasize rotation and obliques.',
      image: null,
      setsReps: '20 reps/side \u2022 Core',
    ),
    _Exercise(
      id: 'leg_raises',
      title: 'Leg Raises',
      description: 'Lift legs with a braced core to target lower abs.',
      image: null,
      setsReps: '15 reps \u2022 Core',
    ),
    _Exercise(
      id: 'crunch_kicks',
      title: 'Crunch Kicks',
      description: 'Crunch and kick forward to challenge the entire midsection.',
      image: null,
      setsReps: '20 reps \u2022 Core',
    ),
    _Exercise(
      id: 'russian_twists',
      title: 'Russian Twists',
      description: 'Rotate side-to-side with control for oblique strength.',
      image: null,
      setsReps: '30 reps \u2022 Core',
    ),
    _Exercise(
      id: 'heel_touch',
      title: 'Heel Touch',
      description: 'Side-to-side reach to hit the obliques and serratus.',
      image: null,
      setsReps: '30 reps \u2022 Core',
    ),
    _Exercise(
      id: 'heel_to_the_heaven',
      title: 'Heel to the Heaven',
      description: 'Lift hips upward with legs extended to fire the lower abs.',
      image: null,
      setsReps: '15 reps \u2022 Core',
    ),
    _Exercise(
      id: 'mountain_climbers',
      title: 'Mountain Climbers',
      description: 'Fast knee drives to build core stability and conditioning.',
      image: null,
      setsReps: '30s \u2022 Warm-up',
    ),
    _Exercise(
      id: 'crossover_crunch',
      title: 'Crossover Crunch',
      description: 'Crunch across the body to emphasize the obliques.',
      image: null,
      setsReps: '20 reps \u2022 Core',
    ),
    _Exercise(
      id: 'plank',
      title: 'Plank',
      description: 'Isometric hold to build full-core stability and bracing.',
      image: null,
      setsReps: '45s \u2022 Stability',
    ),
    _Exercise(
      id: 'cobra_stretch',
      title: 'Cobra Stretch',
      description: 'Gentle stretch for the front body and abdominal wall.',
      image: null,
      setsReps: '30s \u2022 Stretch',
    ),
    _Exercise(
      id: 'crunch_90_90',
      title: '90/90 Crunch',
      description: 'Crunch with hips and knees at 90/90 to reduce hip flexor strain.',
      image: null,
      setsReps: '20 reps \u2022 Core',
    ),
    _Exercise(
      id: 'flutter_kicks',
      title: 'Flutter Kicks',
      description: 'Alternating straight-leg kicks for lower abs endurance.',
      image: null,
      setsReps: '30s \u2022 Core',
    ),
    _Exercise(
      id: 'lying_twist_stretch_left',
      title: 'Lying Twist Stretch (Left)',
      description: 'Spinal twist stretch to relax the lower back and hips.',
      image: null,
      setsReps: '30s \u2022 Stretch',
    ),
    _Exercise(
      id: 'lying_twist_stretch_right',
      title: 'Lying Twist Stretch (Right)',
      description: 'Spinal twist stretch to relax the lower back and hips.',
      image: null,
      setsReps: '30s \u2022 Stretch',
    ),
    _Exercise(
      id: 'oblique_v_ups_left',
      title: 'Oblique V-Ups (Left)',
      description: 'Side-focused V-up to target the obliques and lateral core.',
      image: null,
      setsReps: '15 reps \u2022 Core',
    ),
    _Exercise(
      id: 'oblique_v_ups_right',
      title: 'Oblique V-Ups (Right)',
      description: 'Side-focused V-up to target the obliques and lateral core.',
      image: null,
      setsReps: '15 reps \u2022 Core',
    ),
    _Exercise(
      id: 'oblique_crossover_crunch_left',
      title: 'Oblique Crossover Crunch (Left)',
      description: 'Cross-body crunch variation emphasizing the obliques.',
      image: null,
      setsReps: '15 reps \u2022 Core',
    ),
    _Exercise(
      id: 'oblique_crossover_crunch_right',
      title: 'Oblique Crossover Crunch (Right)',
      description: 'Cross-body crunch variation emphasizing the obliques.',
      image: null,
      setsReps: '15 reps \u2022 Core',
    ),
    _Exercise(
      id: 'push_up_and_rotation',
      title: 'Push-up and Rotation',
      description: 'Push-up then rotate into a reach to train core anti-rotation.',
      image: null,
      setsReps: '10 reps/side \u2022 Core',
    ),
    _Exercise(
      id: 'reverse_crunches',
      title: 'Reverse Crunches',
      description: 'Curl hips toward ribs to emphasize the lower abs.',
      image: null,
      setsReps: '20 reps \u2022 Core',
    ),
    _Exercise(
      id: 'side_plank_left',
      title: 'Side Plank (Left)',
      description: 'Lateral plank hold to build oblique and hip stability.',
      image: null,
      setsReps: '30s \u2022 Stability',
    ),
    _Exercise(
      id: 'side_plank_right',
      title: 'Side Plank (Right)',
      description: 'Lateral plank hold to build oblique and hip stability.',
      image: null,
      setsReps: '30s \u2022 Stability',
    ),
    _Exercise(
      id: 'spine_lumbar_twist_stretch_left',
      title: 'Spine Lumbar Twist Stretch (Left)',
      description: 'Gentle lumbar twist to release tightness after core work.',
      image: null,
      setsReps: '30s \u2022 Stretch',
    ),
    _Exercise(
      id: 'spine_lumbar_twist_stretch_right',
      title: 'Spine Lumbar Twist Stretch (Right)',
      description: 'Gentle lumbar twist to release tightness after core work.',
      image: null,
      setsReps: '30s \u2022 Stretch',
    ),
    _Exercise(
      id: 'sit_up_twist',
      title: 'Sit Up Twist',
      description: 'Sit-up with rotation to recruit obliques and deep core.',
      image: null,
      setsReps: '20 reps \u2022 Core',
    ),
    _Exercise(
      id: 'seated_abs_clockwise_circles',
      title: 'Seated Abs Clockwise Circles',
      description: 'Seated circular motion to challenge core control and endurance.',
      image: null,
      setsReps: '30s \u2022 Core',
    ),
    _Exercise(
      id: 'seated_abs_counter_clockwise_circles',
      title: 'Seated Abs Counter Clockwise Circles',
      description: 'Reverse circles to balance control and anti-rotation strength.',
      image: null,
      setsReps: '30s \u2022 Core',
    ),
    _Exercise(
      id: 'seated_in_and_outs',
      title: 'Seated In and Outs',
      description: 'Tuck and extend legs while seated to hit lower abs.',
      image: null,
      setsReps: '20 reps \u2022 Core',
    ),
    _Exercise(
      id: 'side_plank_knee_crunch_left',
      title: 'Side Plank Knee Crunch (Left)',
      description: 'Side plank with knee drive to intensify oblique activation.',
      image: null,
      setsReps: '15 reps \u2022 Core',
    ),
    _Exercise(
      id: 'side_plank_knee_crunch_right',
      title: 'Side Plank Knee Crunch (Right)',
      description: 'Side plank with knee drive to intensify oblique activation.',
      image: null,
      setsReps: '15 reps \u2022 Core',
    ),
    _Exercise(
      id: 'v_crunch',
      title: 'V Crunch',
      description: 'Bring knees and chest together to create a strong V-shape.',
      image: null,
      setsReps: '15 reps \u2022 Core',
    ),
    _Exercise(
      id: 'x_man_crunch',
      title: 'X Man Crunch',
      description: 'Cross-body crunch pattern to hit abs and obliques together.',
      image: null,
      setsReps: '20 reps \u2022 Core',
    ),
    _Exercise(
      id: 'v_hold',
      title: 'V-Hold',
      description: 'Static V-sit hold to build deep core endurance.',
      image: null,
      setsReps: '30s \u2022 Stability',
    ),
  ];
}

class _AbsWorkoutsState extends State<AbsWorkouts> {
  Future<void> _finishWorkout(BuildContext context) async {
    final analysis = await WorkoutSessionService.instance.endAndAnalyze(
      expectedBodyPart: 'Abs',
    );

    if (!mounted) return;
    if (analysis == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active Abs workout to finish yet.')),
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
    final accent = Colors.amber.shade500;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Abs Workouts'),
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
            const MuscleFatigueIndicator(bodyPart: 'Abs'),
            const SizedBox(height: 10),
            const WarmupRecommendationsCard(bodyPart: 'Abs'),
            const SizedBox(height: 10),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.74,
                ),
                itemCount: AbsWorkouts._exercises.length,
                itemBuilder: (context, index) {
                  final ex = AbsWorkouts._exercises[index];
                  return ExerciseGridCard(
                    id: ex.id,
                    title: ex.title,
                    setsReps: ex.setsReps,
                    bodyPart: 'Abs',
                    assetPath: ex.image,
                    accent: accent,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AbsExerciseDetail(exercise: ex),
                      ),
                    ),
                    onPick: () async {
                      final restSeconds = await showDialog<int>(
                        context: context,
                        builder: (ctx) => ExerciseLogDialog(
                          exerciseName: ex.title,
                          bodyPart: 'Abs',
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
  final String? image;
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
                  const SizedBox(height: 8),
                  Card(
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                      title: const Text(
                        'Tip',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: const Text('Form cue for this exercise'),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          child: Text(
                            ExerciseFormTipsService.tipFor(
                              exerciseId: exercise.id,
                              title: exercise.title,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final restSeconds = await showDialog<int>(
                        context: context,
                        builder: (ctx) => ExerciseLogDialog(
                          exerciseName: exercise.title,
                          bodyPart: 'Abs',
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
