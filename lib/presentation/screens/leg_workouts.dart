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

class LegWorkouts extends StatefulWidget {
  const LegWorkouts({Key? key}) : super(key: key);

  @override
  State<LegWorkouts> createState() => _LegWorkoutsState();

  static final List<_Exercise> _exercises = [
    _Exercise(
      id: 'barbell_back_squat',
      title: 'Barbell Back Squat',
      description: 'Classic compound squat for overall leg strength.',
      image: 'assets/images/leg_back_squat.png',
      setsReps: '1–5 sets x 5-8 reps',
    ),
    _Exercise(
      id: 'goblet_squat',
      title: 'Goblet Squat',
      description: 'Goblet squat for squat pattern and quad development.',
      image: 'assets/images/leg_goblet_squat.png',
      setsReps: '1–5 sets x 8-12 reps',
    ),
    _Exercise(
      id: 'front_squat',
      title: 'Front Squat',
      description: 'Front-loaded squat emphasizing quads and upright torso.',
      image: 'assets/images/leg_front_squat.png',
      setsReps: '1–5 sets x 5-8 reps',
    ),
    _Exercise(
      id: 'sumo_squat',
      title: 'Sumo Squat',
      description: 'Wider stance squat targeting inner quads and glutes.',
      image: 'assets/images/leg_sumo_squat.png',
      setsReps: '1–5 sets x 8-12 reps',
    ),

    // Deadlift variations
    _Exercise(
      id: 'romanian_deadlift',
      title: 'Romanian Deadlift',
      description: 'RDL focuses hamstrings and glute-hamstring tie-in.',
      image: 'assets/images/leg_romanian_deadlift.png',
      setsReps: '1–5 sets x 6-10 reps',
    ),
    _Exercise(
      id: 'conventional_deadlift',
      title: 'Conventional Deadlift',
      description: 'Heavy posterior chain builder for overall strength.',
      image: 'assets/images/leg_conventional_deadlift.png',
      setsReps: '1–5 sets x 3-6 reps',
    ),

    // Lunges
    _Exercise(
      id: 'walking_lunge',
      title: 'Walking Lunges',
      description: 'Walking lunges build unilateral strength and balance.',
      image: 'assets/images/leg_walking_lunge.png',
      setsReps: '1–5 sets x 10-12 steps',
    ),
    _Exercise(
      id: 'reverse_lunge',
      title: 'Reverse Lunge',
      description: 'Reverse lunges are knee-friendly and focus glutes.',
      image: 'assets/images/leg_reverse_lunge.png',
      setsReps: '1–5 sets x 8-12 reps',
    ),
    _Exercise(
      id: 'bulgarian_split_squat',
      title: 'Bulgarian Split Squat',
      description: 'Single-leg squat variation for quad and glute strength.',
      image: 'assets/images/leg_bulgarian_split.png',
      setsReps: '1–5 sets x 8-10 reps',
    ),

    // Extensions & curls
    _Exercise(
      id: 'leg_extensions',
      title: 'Leg Extensions',
      description: 'Isolate quads with leg extension machine.',
      image: 'assets/images/leg_extensions.png',
      setsReps: '1–5 sets x 10-15 reps',
    ),
    _Exercise(
      id: 'leg_press_calves',
      title: 'Leg Press Calves',
      description:
          'Leg press calf raises to load calves with controlled range of motion.',
      image: 'assets/images/leg_press_calves.png',
      setsReps: '1–5 sets x 12-20 reps',
    ),
    _Exercise(
      id: 'leg_press',
      title: 'Leg Press',
      description: 'Machine leg press for quad-focused lower body strength.',
      image: 'assets/images/leg_press.png',
      setsReps: '1–5 sets x 8-12 reps',
    ),
    _Exercise(
      id: 'hamstring_curls',
      title: 'Hamstring Curls',
      description: 'Machine or swiss ball hamstring curls for posterior chain.',
      image: 'assets/images/leg_hamstring_curls.png',
      setsReps: '1–5 sets x 10-15 reps',
    ),

    // Glutes
    _Exercise(
      id: 'glute_bridges',
      title: 'Glute Bridges',
      description: 'Glute bridges and hip thrusts for glute development.',
      image: 'assets/images/leg_glute_bridges.png',
      setsReps: '1–5 sets x 8-12 reps',
    ),
    _Exercise(
      id: 'donkey_kickbacks',
      title: 'Donkey Kickbacks',
      description:
          'Bodyweight kickback variation to isolate and activate the glutes.',
      image: 'assets/images/leg_donkey_kickbacks.png',
      setsReps: '1–5 sets x 12-20 reps per side',
    ),
    _Exercise(
      id: 'fire_hydrant',
      title: 'Fire Hydrant',
      description:
          'Glute medius focused movement to improve hip stability and shape.',
      image: 'assets/images/leg_fire_hydrant.png',
      setsReps: '1–5 sets x 12-20 reps per side',
    ),
    _Exercise(
      id: 'bodyweight_squat',
      title: 'Bodyweight Squats',
      description:
          'Foundational squat pattern for glute and lower-body endurance.',
      image: 'assets/images/leg_bodyweight_squat.png',
      setsReps: '1–5 sets x 15-25 reps',
    ),
    _Exercise(
      id: 'step_ups',
      title: 'Step-Ups',
      description:
          'Unilateral movement that targets glutes while improving balance.',
      image: 'assets/images/leg_step_ups.png',
      setsReps: '1–5 sets x 10-12 reps per leg',
    ),
    _Exercise(
      id: 'hip_thrusts',
      title: 'Hip Thrusts',
      description:
          'Hip thrust variation focused on glute power and full lockout.',
      image: 'assets/images/leg_hip_thrusts.png',
      setsReps: '1–5 sets x 10-15 reps',
    ),
    _Exercise(
      id: 'walking_lunges',
      title: 'Walking Lunges',
      description:
          'Dynamic lunge variation for glute, quad, and balance development.',
      image: 'assets/images/leg_walking_lunges.png',
      setsReps: '1–5 sets x 10-14 steps per leg',
    ),
    _Exercise(
      id: 'single_leg_glute_bridge',
      title: 'Single Leg Glute Bridge',
      description:
          'Single-leg bridge variation to strengthen each glute independently.',
      image: 'assets/images/leg_single_leg_glute_bridge.png',
      setsReps: '1–5 sets x 10-15 reps per side',
    ),
    _Exercise(
      id: 'squat_pulse',
      title: 'Squat Pulse',
      description:
          'High-tension squat pulse for glute burn and lower-body endurance.',
      image: 'assets/images/leg_squat_pulse.png',
      setsReps: '1–5 sets x 15-30 pulses',
    ),
    _Exercise(
      id: 'barbell_hip_thrust',
      title: 'Barbell Hip Thrust',
      description:
          'Loaded hip thrust for maximal glute strength and hypertrophy.',
      image: 'assets/images/leg_barbell_hip_thrust.png',
      setsReps: '1–5 sets x 6-12 reps',
    ),
    _Exercise(
      id: 'sumo_squat_glute',
      title: 'Sumo Squat',
      description: 'Wide-stance squat emphasizing glutes and inner thighs.',
      image: 'assets/images/leg_sumo_squat_glute.png',
      setsReps: '1–5 sets x 10-15 reps',
    ),
    _Exercise(
      id: 'weighted_step_ups',
      title: 'Weighted Step-Ups',
      description:
          'Loaded step-up progression for glute strength and unilateral control.',
      image: 'assets/images/leg_weighted_step_ups.png',
      setsReps: '1–5 sets x 8-12 reps per leg',
    ),
    _Exercise(
      id: 'crusty_lunges',
      title: 'Crusty Lunges',
      description:
          'Lunge variation that challenges glute control and lower-body stability.',
      image: 'assets/images/leg_crusty_lunges.png',
      setsReps: '1–5 sets x 10-12 reps per leg',
    ),

    // Calves
    _Exercise(
      id: 'standing_calf_raises',
      title: 'Standing Calf Raises',
      description:
          'Classic calf movement emphasizing the gastrocnemius through full range.',
      image: 'assets/images/leg_standing_calf_raises.png',
      setsReps: '1–5 sets x 12-20 reps',
    ),
    _Exercise(
      id: 'seated_calf_raises',
      title: 'Seated Calf Raises',
      description:
          'Bent-knee calf raise variation that targets the soleus more directly.',
      image: 'assets/images/leg_seated_calf_raises.png',
      setsReps: '1–5 sets x 12-20 reps',
    ),
    _Exercise(
      id: 'donkey_calf_raises',
      title: 'Donkey Calf Raises',
      description:
          'Hip-hinged calf raise variation for deep stretch and strong contraction.',
      image: 'assets/images/leg_donkey_calf_raises.png',
      setsReps: '1–5 sets x 10-15 reps',
    ),
    _Exercise(
      id: 'single_leg_calf_raises',
      title: 'Single-Leg Calf Raises',
      description:
          'Unilateral calf raises to improve balance, control, and side-to-side symmetry.',
      image: 'assets/images/leg_single_leg_calf_raises.png',
      setsReps: '1–5 sets x 10-15 reps per side',
    ),
    _Exercise(
      id: 'barbell_squat_calves',
      title: 'Barbell Squat Calves',
      description:
          'Calf-focused movement performed with barbell-loaded squat positioning.',
      image: 'assets/images/leg_barbell_squat_calves.png',
      setsReps: '1–5 sets x 10-15 reps',
    ),
  ];
}

class _LegWorkoutsState extends State<LegWorkouts> {
  Future<void> _finishWorkout(BuildContext context) async {
    final analysis = await WorkoutSessionService.instance.endAndAnalyze(
      expectedBodyPart: 'Legs',
    );

    if (!mounted) return;
    if (analysis == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active Legs workout to finish yet.')),
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
    final accent = Colors.teal.shade400;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leg Workouts'),
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
            const MuscleFatigueIndicator(bodyPart: 'Legs'),
            const SizedBox(height: 10),
            const WarmupRecommendationsCard(bodyPart: 'Legs'),
            const SizedBox(height: 10),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.74,
                ),
                itemCount: LegWorkouts._exercises.length,
                itemBuilder: (context, index) {
                  final ex = LegWorkouts._exercises[index];
                  return ExerciseGridCard(
                    id: ex.id,
                    title: ex.title,
                    setsReps: ex.setsReps,
                    bodyPart: 'Legs',
                    assetPath: ex.image,
                    accent: accent,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LegExerciseDetail(exercise: ex),
                      ),
                    ),
                    onPick: () async {
                      final restSeconds = await showDialog<int>(
                        context: context,
                        builder: (ctx) => ExerciseLogDialog(
                          exerciseName: ex.title,
                          bodyPart: 'Legs',
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

class LegExerciseDetail extends StatelessWidget {
  final _Exercise exercise;

  const LegExerciseDetail({Key? key, required this.exercise}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(exercise.title)),
      body: _BodyPartWorkoutCard(exercise: exercise),
    );
  }
}

class _BodyPartWorkoutCard extends StatelessWidget {
  final _Exercise exercise;

  const _BodyPartWorkoutCard({Key? key, required this.exercise})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
                        bodyPart: 'Legs',
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
    );
  }
}
